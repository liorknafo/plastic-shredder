#!/usr/bin/env python3
"""parts.py -- the made parts one by one, each in its own part frame, as native SolidCraft bodies.

    python3 parts.py                  build every part and compare it with its OpenSCAD STL (parts_reference.json)
    python3 parts.py blade shaft      only parts whose name contains a word
    python3 parts.py -m gear          only the parts model/gear.py defines (its PARTS)
    python3 parts.py --compare        also lay each OpenSCAD STL over its native part and compare the two surfaces
                                      (SolidCraft's inspect.compare, 0.05 mm): the STLs are read from git (OLD_COMMIT),
                                      except for the parts in FINE (the screen), which OpenSCAD renders afresh from their
                                      .scad source with fine circles (needs OpenSCAD); their volume is compared too
    python3 parts.py --dxf            also build the flat parts' outlines as DXF (into build/, not cad/dxf) and check them
                                      against the old DXFs (the screen: against its holes worked out from design/params.py)
    python3 parts.py --check          exit with an error when a part does not match parts_reference.json
    python3 parts.py --freeze         make what was built the new parts_reference.json (after a deliberate change)
    python3 parts.py --export         also write cad/step/<name>.step, cad/stl/<name>.stl and cad/dxf/<name>.dxf

A module of model/ lists its parts as PARTS = {name: builder} (the names are the file names in cad/stl and cad/step)
and the outlines of its flat parts as PARTS_2D = {name: builder} (cad/dxf).
Needs SolidCraft 0.40 (`solidcraft-cli` on PATH, or SOLIDCRAFT_CLI).  Standard library only.
"""
import importlib
import json
import math
import os
import re
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
sys.path[:0] = [HERE, os.path.join(HERE, "model")]
from scq import Script, linear_extrude # noqa: E402
from check import BUILD, CLI, compare, freeze  # noqa: E402

OLD_COMMIT = "727b848"               # the last commit whose cad/stl/*.stl and cad/dxf came from OpenSCAD (reference.py measures it)
COMPARE_TOL = 0.05                   # mm: the old meshes are polygons inside the true circles (0.013 mm at R25, $fn 96)
NOT_EXPORTED = set()                 # (format, part) pairs not written to cad/<format>
OPENSCAD = os.environ.get("OPENSCAD") or shutil.which("openscad") or "/opt/homebrew/bin/openscad"
# Parts compared with a fresh OpenSCAD render of their .scad source at fine resolution instead of the old STL:
# {part: (scad file, -D value, the first and the one-past-last module of the part's own code there)}.
# The screen: its 6 wall-screw pockets (Ø11, $fn 32) cut the steep end of the R36 top arcs ($fn 192) at a grazing angle,
# which magnifies the old mesh's facets there to 0.145 mm, more than COMPARE_TOL.  Rendered with the circles fine
# (fine_fn) the OpenSCAD screen is identical to the native one within COMPARE_TOL, and its volume is a reference tight
# enough to see a 0.05 mm change of the holes' diameter (FINE_VOL_TOL).
FINE = {"screen": ("base.scad", 'part="screen"', "module screen_profile_2d", "module screen_screws_ph")}
FINE_VOL_TOL = 0.0003                # relative: the render's 128-gon holes are 0.008 % short; Ø5.05 holes would be -0.3 %
FINE_COM_TOL = 0.05                  # mm


def fine_fn(line, fn):
    """The $fn of a circle in the fine render: the screen's top arcs 1536, the pockets 512, everything else >= 128."""
    return 1536 if fn == 192 else 512 if "screen_pockets" in line else max(fn, 128)


def fine_stl(name, build):
    """The OpenSCAD part `name` (FINE) rendered with fine circles from a patched copy of its .scad file -> (STL path,
    [the files to delete afterwards]).  Raises when the patch or the render fails."""
    scad, define, first, last = FINE[name]
    src = open(os.path.join(CAD, scad)).read()
    a, b = src.index(first), src.index(last)
    lines = src[a:b].split("\n")
    fns = [int(m) for ln in lines for m in re.findall(r"\$fn = (\d+)", ln)]
    assert fns.count(192) == 1 and sum("screen_pockets" in ln and "$fn = 32" in ln for ln in lines) == 1, \
        f"{scad}: the screen's arcs ($fn 192) or pockets ($fn 32) are not where fine_stl() expects them"
    seg = "\n".join(re.sub(r"\$fn = (\d+)", lambda m: f"$fn = {fine_fn(ln, int(m.group(1)))}", ln) for ln in lines)
    fine = os.path.join(build, "fine")
    os.makedirs(fine, exist_ok=True)
    tmp_scad, stl = os.path.join(fine, f"{name}.scad"), os.path.join(fine, f"{name}.stl")   # the mesh body is named after the file
    open(tmp_scad, "w").write(src[:a] + seg + src[b:])
    r = subprocess.run([OPENSCAD, "--backend=manifold", "-D", define, "--export-format", "binstl", "-o", stl, tmp_scad],
                       capture_output=True, text=True, env=dict(os.environ, OPENSCADPATH=CAD))
    bad = [ln for ln in r.stderr.splitlines() if ln.startswith(("WARNING", "ERROR"))]
    if r.returncode != 0 or bad or not os.path.exists(stl):
        raise RuntimeError(f"OpenSCAD render of {scad} {define} failed: {(bad or [r.stderr.strip()[-200:]])[0]}")
    return stl, [tmp_scad, stl]


def compare_surfaces(names, build, got):
    """Each native part against its old STL (or, for the parts in FINE, a fine OpenSCAD render of its .scad source,
    surface and volume), surface to surface.  Returns the number that differ."""
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=HERE, capture_output=True, text=True).stdout.strip()
    old = os.path.join(build, "old_stl")
    os.makedirs(old, exist_ok=True)
    bad = 0
    print(f"{'part':24s} {'max dev mm':>10s} {'mean mm':>8s}  verdict")
    for name in names:
        temp = []
        if name in FINE:
            try:
                stl, temp = fine_stl(name, build)
            except (RuntimeError, AssertionError, OSError) as e:
                print(f"{name:24s}  FAILED: {e}")
                bad += 1
                continue
            vol_ok, vol_note = fine_volume(name, stl, build, got)
            bad += not vol_ok
            print(f"{name:24s}  against a fine OpenSCAD render of {FINE[name][0]}: {vol_note}")
        else:
            stl = os.path.join(old, name + ".stl")
            r = subprocess.run(["git", "show", f"{OLD_COMMIT}:cad/stl/{name}.stl"], cwd=root, capture_output=True)
            if r.returncode != 0:
                print(f"{name:24s}  (no old STL)")
                continue
            open(stl, "wb").write(r.stdout)
        steps = one_part_steps(name, build)
        steps += [{"command": "file.insert_mesh", "params": {"path": stl, "name": "old"}},
                  {"command": "inspect.compare", "params": {"a": name, "b": name + " (2)", "tolerance": COMPARE_TOL}}]
        script, out = os.path.join(build, "compare.json"), os.path.join(build, "compare_out.json")
        json.dump(steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--results", "--quiet", "--json-out", out], capture_output=True, text=True)
        for f in temp:
            os.remove(f)
        if r.returncode != 0:
            print(f"{name:24s}  FAILED: {r.stderr.strip()[-160:]}")
            bad += 1
            continue
        res = json.load(open(out))
        c = (res.get("results", res) if isinstance(res, dict) else res)[-1]
        dev = max(c["deviation"]["a_to_b"]["max_mm"], c["deviation"]["b_to_a"]["max_mm"])
        mean = max(c["deviation"]["a_to_b"]["mean_mm"], c["deviation"]["b_to_a"]["mean_mm"])
        bad += not c["identical"]
        print(f"{name:24s} {dev:10.4f} {mean:8.4f}  {c['verdict']}")
    return bad


def fine_volume(name, stl, build, got):
    """The native part's volume and centre of mass against the fine render's -> (ok, note)."""
    out = os.path.join(build, "fine_eval.json")
    r = subprocess.run([CLI, "eval", stl, "--json-out", out], capture_output=True, text=True)
    if r.returncode != 0:
        return False, f"measuring the render FAILED: {r.stderr.strip()[-160:]}"
    bs = json.load(open(out))["bodies"]
    os.remove(out)
    v = sum(b["volume_mm3"] for b in bs)
    com = [sum(b["volume_mm3"] * b["center_of_mass"][i] for b in bs) / v for i in range(3)]
    g = got[name]
    dv, dc = (g["volume_mm3"] - v) / v, math.dist(g["center_of_mass"], com)
    ok = all(b["closed"] for b in bs) and g["closed"] and abs(dv) <= FINE_VOL_TOL and dc <= FINE_COM_TOL
    return ok, (f"volume {g['volume_mm3']:.1f} / {v:.1f} mm3 ({100 * dv:+.4f} %, limit {100 * FINE_VOL_TOL:.2f} %), "
                f"centre of mass {dc:.4f} mm apart" + ("" if ok else "  CHECK"))


def polyline_points(v, closed):
    """Points on an LWPOLYLINE [(x, y, bulge)]: its vertices and 25 points along each bulge arc."""
    pts = []
    for i, (x0, y0, b) in enumerate(v):
        pts.append((x0, y0))
        x1, y1 = v[(i + 1) % len(v)][:2]
        if b and (i + 1 < len(v) or closed):          # a bulge: tan(sweep / 4) of the arc to the next vertex
            ang, chord = 4 * math.atan(b), math.hypot(x1 - x0, y1 - y0)
            r = chord / (2 * math.sin(ang / 2))
            a0 = math.atan2(y1 - y0, x1 - x0) + math.pi / 2 - ang / 2
            cx, cy = x0 - r * math.cos(a0 - math.pi), y0 - r * math.sin(a0 - math.pi)
            a = math.atan2(y0 - cy, x0 - cx)
            pts.extend((cx + abs(r) * math.cos(a + ang * k / 24), cy + abs(r) * math.sin(a + ang * k / 24)) for k in range(25))
    return pts


def dxf_entities(text):
    """The entity types of a DXF and the extent [x0, y0, x1, y1] of its LWPOLYLINEs (bulge arcs included) and CIRCLEs."""
    lines = text.splitlines()
    pairs = [(lines[i].strip(), lines[i + 1].strip()) for i in range(0, len(lines) - 1, 2)]      # group code, value
    start = next((i for i, p in enumerate(pairs) if p == ("2", "ENTITIES")), 0)
    end = next((i for i in range(start, len(pairs)) if pairs[i] == ("0", "ENDSEC")), len(pairs))
    pairs = pairs[start + 1:end]
    ents, pts, cur = [], [], None

    def close():
        if not cur:
            return
        if cur["type"] == "CIRCLE" and "r" in cur:
            pts.extend([(cur["x"][0] - cur["r"], cur["y"][0] - cur["r"]), (cur["x"][0] + cur["r"], cur["y"][0] + cur["r"])])
        elif cur["type"] == "LWPOLYLINE":
            pts.extend(polyline_points(list(zip(cur["x"], cur["y"], cur["b"] + [0.0] * len(cur["x"]))), cur["closed"]))

    for code, val in pairs:
        if code == "0":
            close()
            cur = {"type": val, "x": [], "y": [], "b": [], "closed": False} if val in ("LWPOLYLINE", "CIRCLE", "LINE", "ARC") else None
            if cur:
                ents.append(val)
        elif cur:
            if code == "10":
                cur["x"].append(float(val))
                cur["b"] += [0.0] * (len(cur["x"]) - 1 - len(cur["b"]))
            elif code == "20":
                cur["y"].append(float(val))
            elif code == "42":
                cur["b"].append(float(val))
            elif code == "40":
                cur["r"] = float(val)
            elif code == "70":
                cur["closed"] = bool(int(val) & 1)
    close()
    return ents, ([min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)] if pts else [0, 0, 0, 0])


def dxf_loops(text):
    """The entities of a DXF's ENTITIES section: [{"type", "layer", "closed", "v": [(x, y, bulge)], "circle": (cx, cy, d)
    or None}].  A circle is a CIRCLE or a closed LWPOLYLINE of two half circles (bulges +-1), as SolidCraft writes them."""
    lines = text.splitlines()
    pairs = [(lines[i].strip(), lines[i + 1].strip()) for i in range(0, len(lines) - 1, 2)]
    start = pairs.index(("2", "ENTITIES"))
    end = pairs.index(("0", "ENDSEC"), start)
    ents, cur = [], None
    for code, val in pairs[start + 1:end]:
        if code == "0":
            cur = {"type": val, "layer": None, "closed": False, "v": [], "r": None}
            ents.append(cur)
        elif code == "8":
            cur["layer"] = val
        elif code == "70":
            cur["closed"] = bool(int(val) & 1)
        elif code == "10":
            cur["v"].append([float(val), None, 0.0])
        elif code == "20":
            cur["v"][-1][1] = float(val)
        elif code == "42":
            cur["v"][-1][2] = float(val)
        elif code == "40":
            cur["r"] = float(val)
    for e in ents:
        v = e["v"]
        if e["type"] == "CIRCLE" and e["r"] is not None and len(v) == 1:
            e["circle"] = (v[0][0], v[0][1], 2 * e["r"])
        elif (e["type"] == "LWPOLYLINE" and e["closed"] and len(v) == 2
              and all(abs(abs(b) - 1) < 1e-9 for _, _, b in v) and v[0][2] == v[1][2]):
            e["circle"] = ((v[0][0] + v[1][0]) / 2, (v[0][1] + v[1][1]) / 2, math.dist(v[0][:2], v[1][:2]))
        else:
            e["circle"] = None
    return ents


def screen_drawing_expected():
    """What the screen's DXF must hold, worked out here from design/params.py (p.py) and NOT from model/base.py: the
    formulas of cad/base.scad (screen_holes(), screen_2d(), the screen constants), restated.  Returns the extents of
    the cross-section [y0, z0, y1, z1] and of the plan outline [x0, y0, x1, y1], and the circles [(x, y, d)] of the
    plan, all in the drawing's coordinates (the plan is drawn 15 mm below the section)."""
    from p import (C, R_TIP, SCREEN_GAP, SCREEN_T, SCREEN_HOLE_D, SCREEN_HOLE_PITCH, SCREEN_HOLE_SLOPE,
                   SCREEN_END_GAP, SCREEN_SCREW, SCREEN_SCREW_Y, chamber_L, comb_edge_y, COMB_W)
    x0, x1 = SCREEN_END_GAP, chamber_L - SCREEN_END_GAP          # the block's ends
    yw = comb_edge_y + COMB_W                                     # the wings' outer faces
    zt, zmin = -5.0, -(R_TIP + SCREEN_GAP + SCREEN_T)             # the combs' underside (10 thick, centred on z = 0); the flat bottom
    off = zmin - yw - 15                                          # the plan's offset in the drawing
    P, r = SCREEN_HOLE_PITCH, SCREEN_HOLE_D / 2
    dy = P * math.sin(math.radians(60))                           # hex rows
    dh = (R_TIP + SCREEN_GAP) * math.sin(math.radians(SCREEN_HOLE_SLOPE)) - r      # rows within dh of a shaft axis (in y)
    xa, xb = x0 + 2 + r, x1 - 2 - r                               # hole edges >= 2 from the ends (SC_HOLE_XM)
    n0 = math.floor((xb - xa) / P)
    xs = (xa + xb - n0 * P) / 2
    nj = math.floor((C / 2 + dh) / dy)
    holes = [(xs + (P / 2 if j % 2 else 0) + i * P, j * dy + off, SCREEN_HOLE_D)
             for j in range(-nj, nj + 1) if abs(abs(j * dy) - C / 2) <= dh for i in range(n0 if j % 2 else n0 + 1)]
    screws = [(x, s * SCREEN_SCREW_Y + off, SCREEN_SCREW[1]) for x in (chamber_L / 3, 2 * chamber_L / 3) for s in (-1, 1)]
    return [-yw, zmin, yw, zt], [x0, off - yw, x1, off + yw], holes + screws


def check_screen_dxf(text):
    """The screen's DXF against screen_drawing_expected(): exactly one cross-section loop and one plan outline (layer
    OUTLINE, their extents within 0.01 mm), and one circle on layer CUT for each hole and screw hole (centre within
    0.001 mm, diameter within 0.01 mm), nothing else.  -> (ok, note)"""
    section, plan, want = screen_drawing_expected()
    ents = dxf_loops(text)
    circles = [e for e in ents if e["circle"] and e["layer"] == "CUT"]
    loops = [e for e in ents if e["type"] == "LWPOLYLINE" and e["closed"] and not e["circle"] and e["layer"] == "OUTLINE"]
    errors = []
    other = len(ents) - len(circles) - len(loops)
    if other:
        errors.append(f"{other} other entities")
    exts = []
    for e in loops:
        pts = polyline_points(e["v"], True)
        exts.append([min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)])
    for label, want_ext in (("cross-section", section), ("plan outline", plan)):
        n = sum(max(abs(a - b) for a, b in zip(ext, want_ext)) < 0.01 for ext in exts)
        if n != 1:
            errors.append(f"{n} {label} loops (extent {[round(v, 3) for v in want_ext]})")
    if len(loops) != 2:
        errors.append(f"{len(loops)} outline loops, not 2")
    left = list(circles)
    missing = []
    for x, y, d in want:
        m = next((c for c in left if math.dist(c["circle"][:2], (x, y)) < 0.001 and abs(c["circle"][2] - d) <= 0.01), None)
        if m is None:
            missing.append((round(x, 3), round(y, 3), d))
        else:
            left.remove(m)
    if missing:
        errors.append(f"{len(missing)} circles missing or moved, e.g. {missing[:2]}")
    if left:
        errors.append(f"{len(left)} unexpected circles, e.g. {[tuple(round(v, 3) for v in c['circle']) for c in left[:2]]}")
    n5 = sum(1 for _, _, d in want if d == want[0][2])
    note = (f"section + plan outline + {n5} x Ø{want[0][2]:g} + {len(want) - n5} x Ø{want[-1][2]:g}, "
            f"as computed from design/params.py")
    return not errors, (note if not errors else "; ".join(errors) + "  CHECK")


# DXFs checked on their own instead of against the old DXF: {name: check(text) -> (ok, note)}.  The old screen drawing
# (727b848) was broken: its plan overlapped the cross-section, which erased 11 holes and clipped 17.
DXF_CHECKS = {"screen": check_screen_dxf}


def merge_dxf(paths, out):
    """One DXF from several that SolidCraft wrote (same header and tables): the entities of all of them, with fresh
    handles, and the extent of all of them."""
    def pairs(path):                                            # [(group code line as written, value)]
        lines = open(path).read().splitlines()
        return [(lines[i], lines[i + 1]) for i in range(0, len(lines) - 1, 2)]

    def find(ps, code, val, start=0):
        return next(i for i in range(start, len(ps)) if ps[i][0].strip() == code and ps[i][1].strip() == val)

    base = pairs(paths[0])
    start = find(base, "2", "ENTITIES") + 1
    end = find(base, "0", "ENDSEC", start)
    seed = int(base[find(base, "9", "$HANDSEED") + 1][1].strip(), 16)
    ents = []
    for path in paths:
        ps = pairs(path)
        a = find(ps, "2", "ENTITIES") + 1
        for code, val in ps[a:find(ps, "0", "ENDSEC", a)]:
            if code.strip() == "5":                             # an entity's own handle
                val = f"{seed:X}"
                seed += 1
            ents.append((code, val))
    merged = base[:start] + ents + base[end:]
    _, ext = dxf_entities("\n".join(f"{c}\n{v}" for c, v in merged))
    out_pairs, var = [], None
    for code, val in merged:
        c = code.strip()
        if c == "9":
            var = val.strip()
        elif c == "0":
            var = None
        elif var == "$HANDSEED" and c == "5":
            val = f"{seed:X}"
        elif var in ("$EXTMIN", "$EXTMAX") and c in ("10", "20"):
            val = repr(round(ext[(0 if c == "10" else 1) + (0 if var == "$EXTMIN" else 2)], 6))
        out_pairs.append((code, val))
    with open(out, "w") as f:
        f.write("".join(f"{c}\n{v}\n" for c, v in out_pairs))
    for path in paths:
        os.remove(path)


def export_dxf(outlines, build, write):
    """The outline of each flat part as DXF: its body's faces in the plane z = 0, projected into a sketch (true arcs,
    closed loops; the outside on layer OUTLINE, the holes on CUT).  `outlines`: name -> builder of a 2D tree (the part is
    that shape) or of a solid lying on z = 0 (its underside).  Checked against the number of loops and the extent of the
    old DXF, or with the check DXF_CHECKS names."""
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=HERE, capture_output=True, text=True).stdout.strip()
    out_dir = os.path.join(CAD, "dxf") if write else os.path.join(build, "dxf")
    os.makedirs(out_dir, exist_ok=True)
    bad = 0
    print(f"{'outline':20s} {'loops':>5s} {'old':>5s}  {'extent':40s} against the old DXF")
    for name, builder in outlines.items():
        tree = builder()
        s = Script()
        body = "outline " + name
        s.build(linear_extrude(1, tree) if tree.dim == 2 else tree, body, split=False)
        n_model = len(s.steps)
        s.step("model.faces", body=body)
        script, res = os.path.join(build, "dxf.json"), os.path.join(build, "dxf_out.json")
        json.dump(s.steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--results", "--quiet", "--json-out", res], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:20s}  FAILED: {r.stderr.strip()[-200:]}")
            bad += 1
            continue
        faces = json.load(open(res))
        faces = (faces.get("results", faces) if isinstance(faces, dict) else faces)[-1]["faces"]
        flat = [f["point"] for f in faces if f.get("plane_normal") and abs(f["plane_normal"][2]) > 0.999999]
        z = 0.0 if tree.dim == 2 else max(p[2] for p in flat)       # a solid: seen from above (blind holes underneath stay out)
        under = [p for p in flat if abs(p[2] - z) < 1e-6]
        path = os.path.join(out_dir, name + ".dxf")
        # One sketch and one DXF per face, merged afterwards: SolidCraft 0.40's joined DXF export keeps a region's outline
        # and its holes but drops islands inside a hole (the concentric rings of sprocket_drill).
        tmp = [os.path.join(build, f"dxf_{name}_{i}.dxf") for i in range(len(under))]
        steps = list(s.steps[:n_model])
        for i, p in enumerate(under):
            steps += [{"command": "sketch.create", "params": {"plane": "XY", "offset": z, "name": f"{name} outline {i + 1}"}},
                      {"command": "sketch.project", "params": {"refs": [{"face": p, "body": body}], "construction": False}},
                      {"command": "sketch.export_dxf", "params": {"path": tmp[i], "join": True, "layers": "roles"}},
                      {"command": "sketch.finish", "params": {}}]
        json.dump(steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--quiet"], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:20s}  FAILED: {r.stderr.strip()[-200:]}")
            bad += 1
            continue
        merge_dxf(tmp, path)
        text = open(path).read()
        ents, ext = dxf_entities(text)
        loops = ents.count("LWPOLYLINE") + ents.count("CIRCLE")
        if name in DXF_CHECKS:                                      # checked on its own, not against the old DXF
            ok, verdict = DXF_CHECKS[name](text)
            bad += not ok
            print(f"{name:20s} {loops:5d} {'-':>5s}  {str([round(v, 3) for v in ext]):40s} {verdict}")
            continue
        r = subprocess.run(["git", "show", f"{OLD_COMMIT}:cad/dxf/{name}.dxf"], cwd=root, capture_output=True, text=True)
        m = re.search(r"\$EXTMIN\s+10\s+(\S+)\s+20\s+(\S+)\s+9\s+\$EXTMAX\s+10\s+(\S+)\s+20\s+(\S+)", r.stdout) if r.returncode == 0 else None
        old_loops = len(re.findall(r"\n\s*0\nLWPOLYLINE", r.stdout)) if r.returncode == 0 else 0
        loose = len(ents) - loops
        if m:
            d = max(abs(a - float(b)) for a, b in zip(ext, m.groups()))
            ok = d < 0.05 and not loose and loops == old_loops
            verdict = f"extent within {d:.3f} mm" + ("" if not loose else f", {loose} loose curves") + ("" if ok else "  CHECK")
        else:
            ok, verdict = not loose, "(no old DXF)"
        bad += not ok
        print(f"{name:20s} {loops:5d} {old_loops:5d}  {str([round(v, 3) for v in ext]):40s} {verdict}")
    return bad


_STEPS = {}


def one_part_steps(name, build):
    return list(_STEPS[name])


MODULES = ["blade", "spacer", "shaft", "sleeve", "placeholders", "gear", "plate", "comb", "wall", "guards", "hopper",
           "base", "drive", "tlfix", "testlever"]


def main():
    args = sys.argv[1:]
    export = "--export" in args
    module = args.pop(args.index("-m") + 1) if "-m" in args else None
    words = [a.lower() for a in args if not a.startswith("-")]
    parts, outlines, not_built = {}, {}, {}
    for name in [module] if module else MODULES:
        try:
            mod = importlib.import_module(name)
        except ModuleNotFoundError as e:
            if e.name != name:
                raise
            continue
        parts.update(getattr(mod, "PARTS", {}))
        outlines.update(getattr(mod, "PARTS_2D", {}))
        not_built.update(getattr(mod, "NOT_BUILT", {}))
    parts = {n: b for n, b in parts.items() if not words or any(w in n.lower() for w in words)}
    outlines = {n: b for n, b in outlines.items() if not words or any(w in n.lower() for w in words)}
    if not parts and not outlines:
        sys.exit("no part matches")
    build = os.path.join(BUILD, "parts_" + (module or "all"))
    os.makedirs(build, exist_ok=True)
    s = Script()
    names = {}
    for name, builder in parts.items():
        n0 = len(s.steps)
        names[name] = s.build(builder(), name, split=False)
        _STEPS[name] = s.steps[n0:]
    if export:
        for sub in ("step", "stl"):
            os.makedirs(os.path.join(CAD, sub), exist_ok=True)
            for name in parts:
                if (sub, name) not in NOT_EXPORTED:
                    s.step("file.export", path=os.path.join(CAD, sub, f"{name}.{sub}"), bodies=[name])
    script, out = os.path.join(build, "parts.json"), os.path.join(build, "parts_eval.json")
    json.dump(s.steps, open(script, "w"))
    t0 = time.time()
    r = subprocess.run([CLI, "eval", script, "--json-out", out], capture_output=True, text=True)
    if r.returncode != 0:
        print((r.stderr or r.stdout)[-3000:])
        sys.exit(f"solidcraft-cli failed ({r.returncode}); script: {script}")
    got = {b["name"]: b for b in json.load(open(out))["bodies"]}
    if "--freeze" in args:
        assert not words and not module, "freeze every part at once"
        freeze(os.path.join(HERE, "parts_reference.json"), "parts", list(parts), names, got,
               "Each made part in its part frame as parts.py --freeze measured it (solidcraft-cli eval): volume, bounding "
               "box, centre of mass.  parts.py compares what it builds with these numbers.")
        return
    ref = json.load(open(os.path.join(HERE, "parts_reference.json")))["parts"]
    bad = compare(list(parts), names, got, ref)
    for name, why in not_built.items():
        if not words or any(w in name.lower() for w in words):
            print(f"{name}: NOT BUILT: {why}")
    if "--compare" in args:
        bad += compare_surfaces(list(parts), build, got)
    if "--dxf" in args or export:
        bad += export_dxf(outlines, build, export)
    print(f"{len(parts)} parts, {len(s.steps)} steps, {time.time() - t0:.1f} s; {bad} differ from the references"
          + ("; exported to cad/step, cad/stl and cad/dxf" if export else ""))
    sys.exit(1 if bad and "--check" in args else 0)


if __name__ == "__main__":
    main()
