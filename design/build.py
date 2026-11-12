"""Generate cad/params.scad, cad/blade_profile.scad and docs/img/blade.svg from params.py.

Run from the repo root:  python3 design/build.py
Standard library only.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import params as P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# ---------------------------------------------------------------- blade outline
def _pol(r, deg):
    a = math.radians(deg)
    return (r * math.cos(a), r * math.sin(a))


def _rot(p, deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return (p[0] * c - p[1] * s, p[0] * s + p[1] * c)


def tooth_outline(step_deg=1.0):
    """Outline of one tooth period (120 deg), counter-clockwise, tip at angle 0.

    The blade turns counter-clockwise in this drawing (+angle), so the leading
    face is at angle 0 and the tooth body lies at negative angles behind it.
    Order of points (going +angle round the blade):
      back of the tooth (rising spiral) -> tip land -> hooked face down to the
      gullet -> gullet fillet -> root circle -> start of the next tooth's back.
    The period starts where the back leaves the root circle (BACK_START_DEG - 120).
    """
    period = 360.0 / P.TEETH
    a0 = P.BACK_START_DEG - period       # back starts here (root radius)
    a1 = -P.LAND_DEG                     # back reaches the tip radius here
    pts = []
    # back: Archimedean rise from R_ROOT to R_TIP
    n = max(8, int((a1 - a0) / step_deg))
    for i in range(n + 1):
        t = i / n
        # ease-in so the spiral leaves the root circle tangentially
        r = P.R_ROOT + (P.R_TIP - P.R_ROOT) * (t ** 1.3)
        pts.append(_pol(r, a0 + (a1 - a0) * t))
    # land at the tip radius
    for i in range(1, 4):
        pts.append(_pol(P.R_TIP, a1 + (0 - a1) * i / 3))
    # hooked face: line from the tip inward, rotated by HOOK so the tip leads
    tip = (P.R_TIP, 0.0)
    h = math.radians(P.HOOK_DEG)
    d = (-math.cos(h), -math.sin(h))          # inward, lagging (negative angle)
    nrm = (-d[1], d[0])                        # left of d = toward +angle (gullet side)
    if nrm[1] < 0:
        nrm = (-nrm[0], -nrm[1])
    # gullet circle: radius GULLET_R, tangent to the face line (on the gullet side)
    # and tangent (inside) to the root circle, i.e. centre at R_ROOT + GULLET_R.
    rc = P.R_ROOT + P.GULLET_R
    # centre = tip + s*d + GULLET_R*nrm, with |centre| = rc  -> solve for s
    bx, by = tip[0] + P.GULLET_R * nrm[0], tip[1] + P.GULLET_R * nrm[1]
    # |(bx + s dx, by + s dy)|^2 = rc^2
    A = 1.0
    B = 2 * (bx * d[0] + by * d[1])
    Cq = bx * bx + by * by - rc * rc
    s = (-B - math.sqrt(B * B - 4 * A * Cq)) / 2   # first (outer) solution along the face
    if s < 0:
        s = (-B + math.sqrt(B * B - 4 * A * Cq)) / 2
    face_end = (tip[0] + s * d[0], tip[1] + s * d[1])
    centre = (face_end[0] + P.GULLET_R * nrm[0], face_end[1] + P.GULLET_R * nrm[1])
    pts.append(face_end)
    # fillet arc from the face tangency to the root-circle tangency
    ang_start = math.degrees(math.atan2(face_end[1] - centre[1], face_end[0] - centre[0]))
    cang = math.degrees(math.atan2(centre[1], centre[0]))
    ang_end = cang + 180.0                        # point of the fillet nearest the blade centre
    # sweep direction: go the short way that passes "below" (toward the blade centre)
    sweep = (ang_end - ang_start) % 360.0
    if sweep > 180:
        sweep -= 360
    n = max(6, int(abs(sweep) / 6))
    for i in range(1, n + 1):
        a = math.radians(ang_start + sweep * i / n)
        pts.append((centre[0] + P.GULLET_R * math.cos(a), centre[1] + P.GULLET_R * math.sin(a)))
    # root circle on to where the next tooth's back starts
    root_from = cang
    root_to = P.BACK_START_DEG
    n = max(2, int((root_to - root_from) / step_deg))
    for i in range(1, n):
        pts.append(_pol(P.R_ROOT, root_from + (root_to - root_from) * i / n))
    return pts, dict(face_len=s, gullet_centre=centre, root_from_deg=root_from)


def blade_outline():
    tooth, info = tooth_outline()
    period = 360.0 / P.TEETH
    pts = []
    for k in range(P.TEETH):
        pts += [_rot(p, k * period) for p in tooth]
    return pts, info


def _seg_dist(p, a, b):
    vx, vy = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vy) / (vx * vx + vy * vy)))
    return math.hypot(p[0] - a[0] - t * vx, p[1] - a[1] - t * vy)


def pin_analysis(outline, r_pin, pin_R):
    """Torque-test pin on the STRAIGHT hook face of the tooth whose tip is at angle 0 (blade frame).

    The pin circle (radius r_pin) is tangent to the face line on the gullet side. Moving the contact
    point in from the tip raises the pin toward the gullet fillet: Rmin is the smallest pivot-to-pin-centre
    radius at which the circle still clears every other piece of the outline. Returns a dict for pin_R:
    contact distance s from the tip along the face, pin-centre polar angle psi from the tip (deg), contact
    radius, and the clearance of the pin to the rest of the outline.
    """
    h = math.radians(P.HOOK_DEG)
    d = (-math.cos(h), -math.sin(h))
    nrm = (-math.sin(h), math.cos(h))                    # toward +angle: the gullet side
    tip = (P.R_TIP, 0.0)
    _, info = tooth_outline()
    L = info["face_len"]
    face_end = (tip[0] + L * d[0], tip[1] + L * d[1])
    n = len(outline)
    idx = [i for i in range(n) if math.dist(outline[i], tip) < 1e-9 and math.dist(outline[(i + 1) % n], face_end) < 1e-9]
    assert len(idx) == 1, "hook face segment not found in the outline"
    fi = idx[0]

    def centre(s):
        return (tip[0] + s * d[0] + r_pin * nrm[0], tip[1] + s * d[1] + r_pin * nrm[1])

    def clear(s):                                        # distance to every segment except the face itself, minus r_pin
        c = centre(s)
        return min(_seg_dist(c, outline[i], outline[(i + 1) % n]) for i in range(n) if i != fi) - r_pin

    s, s_ok, step = 0.0, None, 0.002
    while s <= L + 1e-12:
        if clear(s) >= -1e-9:
            s_ok = s
        s += step
    assert s_ok is not None, "no pin position on the straight face"
    lo, hi = s_ok, min(L, s_ok + step)
    for _ in range(60):
        m = (lo + hi) / 2
        if clear(m) >= -1e-9:
            lo = m
        else:
            hi = m
    Rmin = math.hypot(*centre(lo))
    # contact for pin_R: |centre(s)| falls as s grows (the pin climbs toward the root), so bisect on [0, lo]
    assert pin_R >= Rmin - 1e-9 and pin_R <= math.hypot(*centre(0.0)), (pin_R, Rmin)
    a, b = 0.0, lo
    for _ in range(80):
        m = (a + b) / 2
        if math.hypot(*centre(m)) > pin_R:
            a = m
        else:
            b = m
    s_c = (a + b) / 2
    c = centre(s_c)
    return dict(Rmin=Rmin, s=s_c, s_max=lo, psi=math.degrees(math.atan2(c[1], c[0])),
                contact_r=math.hypot(tip[0] + s_c * d[0], tip[1] + s_c * d[1]), clear=clear(s_c),
                face_len=L, face_end_r=math.hypot(*face_end))


def test_lever_numbers(outline):
    """Everything the blade torque test lever needs from the blade outline; also asserts the design rules."""
    r_pin = P.TEST_PIN_D / 2
    pin = pin_analysis(outline, r_pin, P.TEST_PIN_R)
    want = math.ceil((pin["Rmin"] + 1.0) / 0.5 - 1e-12) * 0.5
    assert abs(P.TEST_PIN_R - want) < 1e-9, f"TEST_PIN_R must be Rmin {pin['Rmin']:.4f} + 1.0 rounded up to 0.5 = {want}"
    assert pin["contact_r"] >= pin["face_end_r"], "pin must touch the straight part of the hook face"
    phi = P.TEST_BLADE_ROT + pin["psi"] - P.TEST_LEVER_DEG          # pin centre direction relative to the lever centreline
    off = P.TEST_PIN_R * math.sin(math.radians(phi))
    edge = P.TEST_LEVER_W / 2 - abs(off) - r_pin                    # steel between the pin hole and the lever edge
    ring = P.TEST_PIN_R - P.TEST_LEVER_PIVOT_D / 2 - r_pin          # steel between the pin hole and the pivot hole
    assert edge >= 6.0 and ring >= 6.0, (edge, ring)
    F = P.T_LIMIT * 1000.0 / P.TEST_PIN_R
    sigma = F * (P.T_BLADE / 2 + 1.0) * 32.0 / (math.pi * P.TEST_PIN_D ** 3)
    return dict(test_pin_Rmin=pin["Rmin"], test_pin_s=pin["s"], test_pin_psi=pin["psi"],
                test_pin_contact_r=pin["contact_r"], test_pin_clear=pin["clear"], hook_face_len=pin["face_len"],
                hook_face_end_r=pin["face_end_r"], test_pin_off=off, test_pin_edge_steel=edge,
                test_pin_ring_steel=ring, test_pin_F=F, test_pin_sigma=sigma)


def hex_bore(variant):
    """Hex bore points (CCW) and relief-circle centres for one phase variant.

    Variant v puts a hex VERTEX at angle v*STAGGER_DEG from the tooth tip.
    """
    rv = P.HEX_BORE_AF / math.sqrt(3)        # centre to vertex
    phase = variant * P.STAGGER_DEG
    verts = [_pol(rv, phase + 60 * k) for k in range(6)]
    return verts, verts  # relief circles are centred on the vertices


def polygon_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % len(pts)]
        a += x1 * y2 - x2 * y1
    return a / 2


def self_intersects(pts):
    def seg(a, b, c, d):
        def o(p, q, r):
            return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
        return (o(a, b, c) * o(a, b, d) < 0) and (o(c, d, a) * o(c, d, b) < 0)
    n = len(pts)
    for i in range(n):
        for j in range(i + 2, n):
            if i == 0 and j == n - 1:
                continue
            if seg(pts[i], pts[(i + 1) % n], pts[j], pts[(j + 1) % n]):
                return True
    return False


def perimeter(pts):
    return sum(math.dist(pts[i], pts[(i + 1) % len(pts)]) for i in range(len(pts)))


# ---------------------------------------------------------------- writers
def write_params_scad(path, extra=None, values=None):
    """Write cad/params.scad.  With `values` (a dict) also collect every name with its value as written there;
    path None collects only (params_values)."""
    d = P.derived()
    lines = ["// GENERATED by design/build.py from design/params.py -- do not edit by hand.", ""]

    def put(name, val):
        if isinstance(val, str):
            lines.append(f'{name} = "{val}";')
        elif isinstance(val, (list, tuple)):
            val = [round(float(v), 4) for v in val]
            lines.append(f"{name} = [" + ", ".join(str(v) for v in val) + "];")
        else:
            val = round(float(val), 4)
            lines.append(f"{name} = {val};")
        if values is not None:
            values[name] = val

    scalars = ["C", "N_SLOTS", "T_BLADE", "SIDE_CLEAR", "T_SPACER", "END_CLEAR", "R_TIP", "R_ROOT",
               "TEETH", "STAGGER_DEG", "BLADE_VARIANTS", "SPACER_OD", "SPACER_BORE", "HEX_AF",
               "HEX_BORE_AF", "HEX_RELIEF_D", "JOURNAL_D", "PLATE_H", "PLATE_L", "LAYER_T",
               "INNER_HOLE_D", "CAP_HOLE_D", "SEAL_BORE_DEPTH", "CAP_BORE_DEPTH", "COLLAR_OD", "COLLAR_T", "SLEEVE_OD", "SLEEVE_ID", "COMB_W", "COMB_GAP",
               "COMB_SLOT_CLEAR", "COMB_SLOT_PAST_TIP", "COMB_SCREW_Y", "WALL_H", "WALL_GAP",
               "END_WASHER_T", "END_SCREW_LEN", "PRINTER_X", "PRINTER_Y",
               "PRINTER_Z", "PRINT_WALL", "PRINT_FLANGE", "HOPPER_TOP_Z", "HOPPER_TOP_IN", "HOPPER_SPLIT_Z",
               "TOP_HOLE_Y", "TOP_HOLE_DEPTH", "WALL_TOP_HOLE_X", "WALL_TOP_HOLE_Y", "SKIRT_HOLE_Y",
               "SKIRT_HOLE_DEPTH", "GUARD_HOLE_Y", "GUARD_HOLE_Z", "GUARD_CLEAR", "BASE_T",
               "MOTOR_PULLEY_D", "GEARBOX_PULLEY_D", "BELT_CENTRE_DIST", "BELT_WIDTH",
               "BELT_GUARD_CLEAR", "WORM_AXIS_DROP", "GROUND_Z",
               "HANDLE_W", "HANDLE_H", "HANDLE_BACK_T", "HANDLE_LIP_D", "HANDLE_Z", "HANDLE_SCREW_DX", "HANDLE_HOLE_D",
               "INSERT_D", "INSERT_DEPTH", "DRAWER_SW_Z", "UFRONT_BELOW", "UFRONT_GAP", "SW_PAD_L", "SW_PAD_W", "SW_PAD_T", "SW_SCREW_SPACING",
               "INTERLOCK_IN", "INTERLOCK_OUT_TRAVEL", "BG_LAP_LEN", "BG_LAP_CLEAR", "BG_FOOT_W", "BG_FOOT_T",
               "BG_FOOT_REACH", "DECK_PLY_T", "DECK_MARGIN", "LEG_SECTION", "STUB_D", "STUB_L", "STUB_END_D", "STUB_END_L", "STUB_FLAT_AF",
               "STUB_FLAT_L", "STUB_KEY_L",
               "T_LIMIT", "HOOK_DEG", "TEST_PIN_D", "TEST_PIN_R", "TEST_PIN_PROJ", "TEST_BLADE_GAP", "TEST_LEVER_L", "TEST_LEVER_W",
               "TEST_LEVER_T", "TEST_LEVER_PIVOT_END", "TEST_LEVER_PIVOT_D", "TEST_WEIGHT_ARM", "TEST_WEIGHT_HOLE_D",
               "TEST_WEIGHT_KG", "TEST_BLADE_ROT", "TEST_LEVER_DEG",
               "T_SET", "T_OPERATING", "TL_SET_AT_TL", "CHAIN_RATIO", "CHAIN_CD", "SUBPLATE_T", "GB_BOX", "GB_BELOW_OUT",
               "GB_BOSS", "GB_FOOT", "GB_FLANGE", "GB_WORM_STUB", "SPROCKET_T", "SPROCKET_OD_EXTRA", "CHAIN_ENV_W", "CHAIN_ENV_H",
               "DRIVE_LEG_MIN", "TENS_DELTA", "TENS_TRAVEL", "TENS_FLAT_W", "TENS_T", "TENS_BASE", "TENS_AXLE_D", "GUARD_FRONT_X",
               "DG_SEAM_Z", "DG_FLANGE_W", "DG_FLANGE_T", "TLFIX_ARM", "TLFIX_LEVER_L", "TLFIX_LEVER_W", "TLFIX_LEVER_T",
               "TL_HUB_D", "TL_FLANGE_T", "TL_CM_OFFSET", "TL_GB_GAP", "TL_PACK_D", "TL_PRESS_T", "TL_SPRING_L", "GB_HUB_L", "OUT_SPACER_D",
               "SHAFT_KEY_W", "SHAFT_KEY_D", "GB_KEY_END", "TL_KEY_END", "CIRCLIP_GROOVE_D", "CIRCLIP_GROOVE_W", "CIRCLIP_T", "CIRCLIP_OD",
               "CIRCLIP_EDGE", "TL_COLLAR_D", "TL_COLLAR_T", "SHAFT_OUT_END", "GB_RAIL_W", "GB_RAIL_T", "GB_RAIL_SLOT", "GB_RAIL_BOLT_DX",
               "GB_RAIL_END", "GB_SPACER_L", "DECK_RAIL_MARGIN", "CHAIN_UPLIFT_LIMIT_N", "CHAIN_UPLIFT_DESIGN_N", "DECK_ANCHOR_D", "DECK_ANGLE",
               "DECK_ANGLE_L", "DECK_ANGLE_DECK_BOLTS", "DECK_ANGLE_LEG_BOLTS", "FOOT_ANGLE_LEG_BOLTS", "FOOT_ANGLE_ANCHORS", "BIG_WASHER_D",
               "BIG_WASHER_T", "DECK_LEG_INSET_Y", "TENS_HEAD_H", "TENS_COL_GAP", "TLFIX_PIN_L",
               "TLFIX_LEVER_GAP", "TLFIX_PIVOT_D", "TLFIX_LUG", "TLFIX_LUG_GAP",
               "SW_BODY", "SW_HOLE_SPACING", "SW_SLOT", "ACT_SIZE", "ACT_BLADE_T", "ACT_BLADE_L", "ACT_HOLE_SPACING", "PILOT_D", "PILOT_DEPTH",
               # review round 4: Pizzato lid switch, Omron drawer switch, fixed mesh grid
               "HSW_BODY", "HSW_HOLE_SPACING", "HSW_SLOT", "HACT_SIZE", "HACT_BLADE_T", "HACT_BLADE_L", "HACT_HOLE_SPACING", "HSW_SCREW", "HACT_SCREW", "HSW_PAD_W",
               "DSW_BODY", "DSW_HOLE_SPACING", "DSW_SLOT", "DACT_SIZE", "DACT_BLADE_T", "DACT_BLADE_L", "DACT_HOLE_SPACING", "DSW_SCREW", "DACT_SCREW",
               "GRID_PITCH", "GRID_WIRE", "GRID_Z", "GRID_CLEAT", "GRID_MIN_DIST", "GRID_MAX_OPEN", "GRID_EDGE_GAP", "GRID_MAX_EDGE_GAP", "FINGER_D",
               "GRID_BIN_CLEAR", "GRID_SCREW"]
    for s in scalars:
        put(s, getattr(P, s))
    for k, v in P.BEARING.items():
        put("BEARING_" + k, v)
    for k in ("module", "z", "alpha", "bore", "hub_L", "cut_extra"):
        put("GEAR_" + k, P.GEAR[k])
    for k in ("GEAR_LAYER_T", "GEAR_LAYERS", "GEAR_SPACER_D", "GEAR_ROUGH_D", "GEAR_KEY_W", "GEAR_KEYWAY_H", "GEAR_KEY_TOOL_D", "GEAR_KEY_CHAMFER"):
        put(k, getattr(P, k))
    for k in ("d", "D", "B"):
        put("SEAL_" + k, P.SEAL[k])
    for k in ("d", "D", "T"):
        put("THRUST_" + k, P.THRUST[k])
    for k in ("d", "D", "n", "stack_h"):
        put("CRINKLE_" + k, P.CRINKLE[k])
    for k in ("z", "hub_L", "hub_D"):
        put("SPROCKET_A_" + k, P.SPROCKET_A[k])
    for k in ("z", "L", "D", "T_min", "T_max"):
        put("TL_" + k, P.TL[k])
    put("CHAIN_pitch", P.CHAIN["pitch"])
    put("DECK_ANCHOR", P.DECK_ANCHOR)
    put("IDLER_NAME", P.IDLER["name"])
    lines.append("")
    lines.append("// derived")
    for k, v in d.items():
        put(k, v)
    if extra:
        lines.append("")
        lines.append("// blade torque test lever: computed from the blade outline (design/build.py, test_lever_numbers)")
        for k, v in extra.items():
            put(k, v)
    if path is None:
        return
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def write_blade_scad(path, outline):
    lines = ["// GENERATED by design/build.py -- blade outline and hex bores (mm).",
             "// blade_outline(): CCW polygon, tooth tips at 0/120/240 deg, blade turns CCW (+angle).",
             "// blade_hex(v): hex bore vertices for phase variant v (vertex at v*STAGGER_DEG).", ""]
    lines.append("blade_outline_pts = [" + ", ".join(f"[{x:.4f},{y:.4f}]" for x, y in outline) + "];")
    for v in range(P.BLADE_VARIANTS):
        verts, _ = hex_bore(v)
        lines.append(f"blade_hex_{v} = [" + ", ".join(f"[{x:.4f},{y:.4f}]" for x, y in verts) + "];")
    lines.append("function blade_hex(v) = " + " : ".join(
        f"v == {v} ? blade_hex_{v}" for v in range(P.BLADE_VARIANTS - 1)) +
        f" : blade_hex_{P.BLADE_VARIANTS - 1};")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")


def write_svg(path, outline):
    """1:1 drawing of all blade variants (mm units) for checking and printing."""
    pad, gap = 10, 85
    w = pad * 2 + gap * P.BLADE_VARIANTS
    h = 2 * pad + 100
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}mm" height="{h}mm" '
           f'viewBox="0 0 {w} {h}">',
           '<rect width="100%" height="100%" fill="white"/>',
           '<style>text{font:4px sans-serif} .c{fill:none;stroke:#000;stroke-width:0.25}'
           ' .r{fill:none;stroke:#c00;stroke-width:0.2} .g{stroke:#999;stroke-width:0.15;'
           'stroke-dasharray:1 1}</style>']
    for v in range(P.BLADE_VARIANTS):
        cx, cy = pad + gap * v + gap / 2, pad + 45
        def tr(p):
            return f"{cx + p[0]:.3f},{cy - p[1]:.3f}"
        out.append(f'<polygon class="c" points="{" ".join(tr(p) for p in outline)}"/>')
        verts, rel = hex_bore(v)
        out.append(f'<polygon class="c" points="{" ".join(tr(p) for p in verts)}"/>')
        for p in rel:
            out.append(f'<circle class="r" cx="{cx + p[0]:.3f}" cy="{cy - p[1]:.3f}" '
                       f'r="{P.HEX_RELIEF_D / 2}"/>')
        out.append(f'<circle class="g" cx="{cx}" cy="{cy}" r="{P.C - P.R_TIP}"/>')
        out.append(f'<line class="g" x1="{cx}" y1="{cy}" x2="{cx + 40}" y2="{cy}"/>')
        out.append(f'<text x="{cx - 30}" y="{cy + 48}">variant {v}: hex vertex at '
                   f'{v * P.STAGGER_DEG:.0f}° from tip</text>')
    out.append(f'<text x="{pad}" y="{h - 3}">Blade Ø{2 * P.R_TIP:.0f}, {P.TEETH} hooked teeth, '
               f'turns CCW in this view. Dashed: radius of the other shaft\'s overlap '
               f'(R{P.C - P.R_TIP:.0f}). Red: corner reliefs Ø{P.HEX_RELIEF_D}. Scale 1:1.</text>')
    out.append("</svg>")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")


def test_lever_extra(outline):
    tl = test_lever_numbers(outline)
    extra = dict(tl)
    extra["test_pin_deg"] = P.TEST_BLADE_ROT + tl["test_pin_psi"]               # pin-centre direction in the test frame
    extra["test_face_nrm_deg"] = P.TEST_BLADE_ROT + 90.0 + P.HOOK_DEG           # direction of the face normal, toward the gullet
    return tl, extra


def params_values():
    """Every name cad/params.scad defines, with its value as written there (cad/solidcraft/model reads these)."""
    values = {}
    write_params_scad(None, test_lever_extra(blade_outline()[0])[1], values)
    return values


def main():
    outline, info = blade_outline()
    assert polygon_area(outline) > 0, "outline must be CCW"
    assert not self_intersects(outline), "blade outline self-intersects"
    rmin = min(math.hypot(*p) for p in outline)
    rmax = max(math.hypot(*p) for p in outline)
    assert abs(rmax - P.R_TIP) < 1e-6 and rmin >= P.R_ROOT - 1e-6, (rmin, rmax)
    os.makedirs(os.path.join(ROOT, "cad"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "docs", "img"), exist_ok=True)
    tl, extra = test_lever_extra(outline)
    write_params_scad(os.path.join(ROOT, "cad", "params.scad"), extra)
    write_blade_scad(os.path.join(ROOT, "cad", "blade_profile.scad"), outline)
    write_svg(os.path.join(ROOT, "docs", "img", "blade.svg"), outline)
    print(f"blade outline: {len(outline)} pts, perimeter {perimeter(outline):.1f} mm, "
          f"r {rmin:.2f}..{rmax:.2f}, face length {info['face_len']:.2f} mm, "
          f"gullet centre r {math.hypot(*info['gullet_centre']):.2f}")
    print("wrote cad/params.scad, cad/blade_profile.scad, docs/img/blade.svg")
    print(f"test lever: smallest pin-centre radius for a Ø{P.TEST_PIN_D:g} pin on the straight hook face "
          f"{tl['test_pin_Rmin']:.4f} (+1.0, rounded up to 0.5 = TEST_PIN_R {P.TEST_PIN_R:g}); straight face "
          f"R{tl['hook_face_end_r']:.2f}-{P.R_TIP:g}, contact at R{tl['test_pin_contact_r']:.2f}")
    print(f"test lever: pin centre {tl['test_pin_psi']:.2f} deg ahead of the tooth tip = {extra['test_pin_deg']:.2f} deg in the test frame; "
          f"lever at {P.TEST_LEVER_DEG:g} deg, pin hole {tl['test_pin_off']:+.2f} mm off the lever centreline, "
          f"steel round the pin hole {tl['test_pin_edge_steel']:.1f} (edge) / {tl['test_pin_ring_steel']:.1f} (pivot hole)")
    print(f"test lever: pin force F = {P.T_LIMIT * 1000:g} / {P.TEST_PIN_R:g} = {tl['test_pin_F']:.0f} N; "
          f"pin bending stress (cantilever {P.TEST_PIN_PROJ:g} mm, load at {P.T_BLADE / 2 + 1:g} mm) = {tl['test_pin_sigma']:.1f} MPa "
          f"(Ø{P.TEST_PIN_D:g} hardened dowel / 12.9 bolt shank, yield >= 900 MPa)")


if __name__ == "__main__":
    main()
