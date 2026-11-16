"""base.py -- 18 mm plywood base plate, the bin cabinet below it, the drawer with its printed pull handle, and the FIXED
SCREEN under the blades (cad/base.scad).  World frame.

ONE SOURCE FOR 3D AND DXF.  Every plywood panel is a 2D function (p_*_2d, base_2d) in its own (u, v) frame.  The 3D part
  extrudes that function and the DXF sheet (cabinet_2d, base_2d) uses the same one, so drawing and model cannot diverge.

SCREEN (replaces the vibrating screen, the wire-mesh grid, the fixed upper front panel, the drawer switch and the side
  skirts).  One aluminium block (6061 / 6082) machined on the CNC4030, x SCREEN_END_GAP .. chamber_L - SCREEN_END_GAP.
  Its cross-section (y, z) is a "W":
    top     two arcs R_TIP + SCREEN_GAP (36) round the shaft axes, meeting in a ridge between the shafts (y = 0,
            z = -19.9) and rising on the outer sides to the combs' underside (z = -5) at |y| = 65.6; from there flat
            WINGS against the combs out to the combs' outer edge (|y| = 80.5);
    bottom  FLAT at z = -(R_TIP + SCREEN_GAP + SCREEN_T) = -46 (inside the base plate's cut-out); each hole relieved
            Ø SCREEN_RELIEF_D from below so its Ø5 land is SCREEN_T.
  Holes Ø5 (SCREEN_HOLE_D) on an 8 mm hex pattern, drilled vertically (z, up from the flat bottom) where the top is no steeper than
  SCREEN_HOLE_SLOPE (50 deg): two bands under the shafts.  Held by 4 x M4 x 16 socket screws from BELOW (counterbores in
  the wings) into tapped holes in the combs' underside (|y| = SCREEN_SCREW_Y, x = L/3, 2L/3).  Pockets in the wing tops
  clear the M5 heads of the wall screws (|y| = 71, x = 20, L/2, L-20).
BASE   the shredder box sits on it at z = -35 on 8 M6 feet (y = +-65, in the bottom edges of the inner and outer layers;
  slots +-2 mm in x).  Cut-out |y| <= BASE_CUT_Y under the chamber: the screen and its screws are reached from below.
CABINET  under the base, x -30 .. chamber_L + 30, y -110 .. 110: two sides, back, floor (18 mm ply); the side panels hang
  on 6 screws through the base plate.  The drawer (full-height front + 10 mm ply bin) slides in from the front (-y).
  The cabinet is only a dust box: nothing in it can reach the blades (the screen is screwed on).
"""
from common import *
from joints import *              # foot_screw_xy() ...; also every name of drive_geom

BASE_NX = -30
BASE_X0 = BASE_NX
BASE_X1 = chamber_L + 30 + 40
BASE_Y0 = -115
BASE_Y1 = 110
BASE_Z1 = -PLATE_H / 2
BASE_Z0 = BASE_Z1 - BASE_T
FOOT_SLOT = 2                                      # +-2 mm in x (the 8 foot screws: foot_screw_xy() in joints.py, shared with the end plates)

# ---------------- cabinet constants
CAB_X0 = -30
CAB_X1 = chamber_L + 30
CAB_T = 18
CAB_Y0 = -110
CAB_Y1 = 110
CAB_ZT = BASE_Z0                                   # underside of the base
CAB_FLOOR_TOP = -350
CAB_ZB = CAB_FLOOR_TOP - CAB_T                     # -368
DR_T = 10
DR_W = 154
DR_Y0 = CAB_Y0 + CAB_T
DR_L = 176
DR_Z0 = CAB_FLOOR_TOP + 2
BIN_TOP_CLEAR = 4                                  # bin top under the base plate's underside
DR_H = CAB_ZT - BIN_TOP_CLEAR - DR_Z0              # 291
DRF_ZT = CAB_ZT - DRF_GAP                          # top of the full-height drawer front: 1 mm under the base plate
DRF_H = DRF_ZT - CAB_ZB
BIN_FLOOR = DR_Z0 + DR_T
CAB_XC = (CAB_X0 + CAB_X1) / 2
CAB_W = CAB_X1 - CAB_X0                            # 192.2
CAB_H = CAB_ZT - CAB_ZB                            # 315
CAB_SIDE_W = CAB_Y1 - DR_Y0                        # 202
HANG_X = [CAB_X0 + CAB_T / 2, CAB_X1 - CAB_T / 2]  # cabinet side panels hang on 6 screws
HANG_Y = [-80, 0, 80]


def hang_screw_xy():
    """The ONE definition: base-plate Ø5 holes AND the pilots in the panel tops."""
    return [[x, y] for x in HANG_X for y in HANG_Y]


HANG_PILOT_D = 3.3                                 # M4 x 45 screws: 18 plywood + 25 into the panel edge
HANG_PILOT_DEPTH = 25
assert CAB_ZB == GROUND_Z
assert HANDLE_Z + HANDLE_H / 2 <= DRF_ZT - 5 and HANDLE_Z - HANDLE_H / 2 >= CAB_ZB + 5, "the pull handle must lie fully on the drawer front"

# ---------------- the SCREEN: constants
SC_RS = R_TIP + SCREEN_GAP                         # 36: top arcs
SC_RB = SC_RS + SCREEN_T                           # 46: the flat bottom's depth below the axes
SC_ZT = -5                                         # the combs' underside (comb.py: 10 thick, centred on z = 0)
SC_YW = comb_edge_y + COMB_W                       # 80.5: the wings' outer faces = the combs' outer edges
SC_X0 = SCREEN_END_GAP
SC_X1 = chamber_L - SCREEN_END_GAP
SC_ZMIN = -SC_RB                                   # lowest point (under each shaft)
SC_YMEET = C / 2 + sqrt(SC_RS * SC_RS - SC_ZT * SC_ZT)          # 65.65: where the top arc meets the combs' underside
SC_DH = SC_RS * sin(SCREEN_HOLE_SLOPE) - SCREEN_HOLE_D / 2      # hole centres within this of a shaft axis (in y): the top is <= 50 deg steep there
SC_HOLE_XM = 2                                     # hole edge >= this from the screen's ends
SCREEN_SCREW_X = [chamber_L / 3, 2 * chamber_L / 3]
WALL_SCREW_X = [20, chamber_L / 2, chamber_L - 20]
WALL_SCREW_Y = 71
assert abs(SC_YW - (comb_edge_y + COMB_W)) < 1e-9 and SC_YMEET < comb_slot_bottom_y, "screen: the arc meets the comb underside inside the comb"
assert SC_YW + 2 <= BASE_CUT_Y <= CAB_Y1 - CAB_T - 5, "base plate cut-out: wider than the screen, inside the cabinet"
assert SC_ZMIN > CAB_ZT + 5, "the screen's lowest point stays above the base plate's underside"
assert SCREEN_T + SCREEN_GAP >= 5, "ISO 13857 Table 4: round openings 4 < e <= 6 need >= 5 mm to the hazard"


def sc_top(y):
    d = abs(y) - C / 2
    return min(SC_ZT, -sqrt(SC_RS * SC_RS - d * d)) if abs(d) < SC_RS else SC_ZT


def screen_holes():
    """Hole centres: hex pattern, rows along x (pitch P), rows P * sin(60) apart in y, symmetric about y = 0 and centred in x."""
    P, r = SCREEN_HOLE_PITCH, SCREEN_HOLE_D / 2
    dy = P * sin(60)
    xa, xb = SC_X0 + SC_HOLE_XM + r, SC_X1 - SC_HOLE_XM - r
    n0 = floor((xb - xa) / P)
    x0 = (xa + xb - n0 * P) / 2
    nj = floor((C / 2 + SC_DH) / dy)
    out = []
    for j in range(-nj, nj + 1):
        y = j * dy
        if abs(abs(y) - C / 2) <= SC_DH:
            odd = abs(j) % 2 == 1
            out += [[x0 + (P / 2 if odd else 0) + i * P, y] for i in range(n0 if odd else n0 + 1)]
    return out


# ---------------- 2D outlines: the ONLY definition of each panel (3D parts and DXF both use these)
def base_2d():
    return difference(
        translate([BASE_X0, BASE_Y0], square([BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0])),
        translate([0, -BASE_CUT_Y], square([chamber_L, 2 * BASE_CUT_Y])),                        # cut-out under the chamber: the screen and its screws, from below
        [hull(translate([p[0] + dx, p[1]], circle(d=6.6)) for dx in (-FOOT_SLOT, FOOT_SLOT)) for p in foot_screw_xy()],   # M6 feet (end plates)
        [translate(p, circle(d=5)) for p in hang_screw_xy()])                                    # cabinet hang screws, centred on the panel edges


def p_side_2d():
    return square([CAB_SIDE_W, CAB_H])                                                           # u = y - DR_Y0 (front edge at u = 0), v = z - CAB_ZB


def p_back_2d():
    return square([CAB_W - 2 * CAB_T, CAB_H])                                                    # u = x - (CAB_X0 + CAB_T)


def p_floor_2d():
    return square([CAB_W, CAB_SIDE_W])                                                           # u = x - CAB_X0, v = y - DR_Y0


def handle_screw_xz():
    """The ONE definition (world x, z): drawer-front holes AND handle inserts."""
    return [[CAB_XC + s * HANDLE_SCREW_DX, HANDLE_Z] for s in (-1, 1)]


HANDLE_PTS = [[p[0] - CAB_X0, p[1] - CAB_ZB] for p in handle_screw_xz()]                         # in the drawer-front frame


def p_front_2d():
    """Drawer front: u = x - CAB_X0, v = z - CAB_ZB."""
    return difference(square([CAB_W, DRF_H]), [translate(p, circle(d=HANDLE_HOLE_D)) for p in HANDLE_PTS])


def p_dbottom_2d():
    return square([DR_W, DR_L])


def p_dside_2d():
    return square([DR_L, DR_H - DR_T])


def p_dback_2d():
    return square([DR_W - 2 * DR_T, DR_H - DR_T])


# ---------------- placement: extrusions of the 2D functions above
def yz_panel(x0, y0, z0, t, *ch):
    """Panel in the y-z plane, x0 .. x0 + t."""
    return axial(x0, translate([y0, z0], linear_extrude(t, *ch)))


def xz_panel(x0, y1, z0, t, *ch):
    """Panel in the x-z plane, y1 - t .. y1."""
    return multmatrix([[1, 0, 0, x0], [0, 0, -1, y1], [0, 1, 0, z0], [0, 0, 0, 1]], linear_extrude(t, *ch))


def xy_panel(x0, y0, z0, t, *ch):
    """Panel in the x-y plane, z0 .. z0 + t."""
    return translate([x0, y0, z0], linear_extrude(t, *ch))


def base_plate():
    return part("Base plate", translate([0, 0, BASE_Z0], linear_extrude(BASE_T, base_2d())))


def base_plate():
    return part("Base plate", translate([0, 0, BASE_Z0], linear_extrude(BASE_T, base_2d())))


def HANGX(free_end):
    return HANG_X[1] if free_end else HANG_X[0]


def cab_side(free_end):
    return difference(
        yz_panel(CAB_X1 - CAB_T if free_end else CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_side_2d()),
        [translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH], cylinder(d=HANG_PILOT_D, h=HANG_PILOT_DEPTH + 1))             # pilots for the hang screws, in the top edge
         for p in hang_screw_xy() if abs(p[0] - HANGX(free_end)) < 0.01])


def cabinet_back():
    return xz_panel(CAB_X0 + CAB_T, CAB_Y1, CAB_ZB, CAB_T, p_back_2d())


def cabinet_shell_panels():
    return union(part("Cabinet side panel (drive end)", cab_side(False)),
                 part("Cabinet side panel (free end)", cab_side(True)),
                 part("Cabinet back panel", cabinet_back()),
                 part("Cabinet floor panel", xy_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_floor_2d())))


def cabinet_panels():
    return cabinet_shell_panels()


def drawer_front():
    return part("Drawer front panel", xz_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_front_2d()))


DR_X0 = CAB_XC - DR_W / 2
DR_X1 = CAB_XC + DR_W / 2


def drawer_bin():
    return union(part("Drawer bin bottom", xy_panel(DR_X0, DR_Y0, DR_Z0, DR_T, p_dbottom_2d())),                          # bottom
                 part("Drawer bin side (drive end)", yz_panel(DR_X0, DR_Y0, DR_Z0 + DR_T, DR_T, p_dside_2d())),           # sides
                 part("Drawer bin side (free end)", yz_panel(DR_X1 - DR_T, DR_Y0, DR_Z0 + DR_T, DR_T, p_dside_2d())),
                 part("Drawer bin back", xz_panel(DR_X0 + DR_T, DR_Y0 + DR_L, DR_Z0 + DR_T, DR_T, p_dback_2d())))         # back


def drawer_panels():
    return union(drawer_front(), drawer_bin())


# ---------------- drawer pull handle (printed, PETG): an edge pull, back plate + shelf + lip; fingers go in from below.
# Local frame (u = distance in front of the drawer front, v = z - HANDLE_Z, w = along the width, 0 .. HANDLE_W)
HANDLE_SHELF_T = 8
HANDLE_LIP_T = 6
HANDLE_LIP_H = 18


def handle_local():
    ht = HANDLE_H / 2
    d1 = HANDLE_BACK_T + HANDLE_LIP_D
    return difference(
        linear_extrude(HANDLE_W,
                       translate([0, -ht], square([HANDLE_BACK_T, HANDLE_H])),                                  # back plate
                       translate([0, ht - HANDLE_SHELF_T], square([d1, HANDLE_SHELF_T])),                        # shelf
                       translate([d1 - HANDLE_LIP_T, ht - HANDLE_LIP_H], square([HANDLE_LIP_T, HANDLE_LIP_H]))),  # lip
        [translate([-0.01, 0, CAB_XC + HANDLE_W / 2 - p[0]], rotate([0, 90, 0], cylinder(d=INSERT_D, h=INSERT_DEPTH + 0.01)))   # M4 heat-set inserts from the back face
         for p in handle_screw_xz()])


def handle_world():
    """u -> -y (away from the cabinet), v -> z, w -> -x (a proper rotation)."""
    return multmatrix([[0, 0, -1, CAB_XC + HANDLE_W / 2], [-1, 0, 0, CAB_Y0], [0, 1, 0, HANDLE_Z], [0, 0, 0, 1]],
                      part("Drawer pull handle", handle_local()))


def handle_screws_ph():
    """2 x M4 x 22 from inside the bin (head against the back of the drawer front)."""
    return union(translate([p[0], DR_Y0 + 3, p[1]], rotate([90, 0, 0], part("M4 x 22 pan head screw (drawer handle)",
                                                                           cylinder(d=7, h=3),
                                                                           translate([0, 0, 3], cylinder(d=4, h=22)))))   # 22 under the head: 18 panel + 4 of the 6 mm insert
                 for p in handle_screw_xz())


def drawer_moved_ph(t, dz=0):
    """The drawer (front, bin, handle) pulled out by t (dz: raised, for controls)."""
    return translate([0, -t, dz], drawer_panels(), handle_world(), handle_screws_ph())


# ---------------- the SCREEN
def screen_profile_2d():
    """(y, z) cross-section: the two top arcs round the shaft axes, flat wings, flat bottom."""
    return intersection(
        difference(translate([-SC_YW, SC_ZMIN - 1], square([2 * SC_YW, SC_ZT - SC_ZMIN + 1])),
                   [translate([s * C / 2, 0], circle(r=SC_RS)) for s in (-1, 1)]),                 # the top arcs
        translate([-SC_YW, SC_ZMIN], square([2 * SC_YW, SC_ZT - SC_ZMIN])))                       # flat bottom


def screen_body():
    return axial(SC_X0, linear_extrude(SC_X1 - SC_X0, screen_profile_2d()))


def screen_screw_cuts():
    return union(translate([x, s * SCREEN_SCREW_Y, 0],
                           translate([0, 0, SC_ZMIN - 1], cylinder(d=SCREEN_SCREW[1], h=SC_ZT - SC_ZMIN + 2)),                           # M4 clearance
                           translate([0, 0, SC_ZMIN - 1], cylinder(d=SCREEN_SCREW[4], h=(SC_ZT - SCREEN_SCREW_LAND) - SC_ZMIN + 1)))     # counterbore from below up to the land
                 for x in SCREEN_SCREW_X for s in (-1, 1))


def screen_pockets():
    return union(translate([x, s * WALL_SCREW_Y, SC_ZT - SCREEN_POCKET[1]], cylinder(d=SCREEN_POCKET[0], h=SCREEN_POCKET[1] + 1))
                 for x in WALL_SCREW_X for s in (-1, 1))


def sc_relief_top(y):
    """Top of a hole's relief: SCREEN_T below the LOWEST point of the top across the hole (the Ø5 land is >= SCREEN_T
    everywhere; the same depth for a whole row)."""
    return min(sc_top(y + dy) for dy in (-SCREEN_HOLE_D / 2, 0, SCREEN_HOLE_D / 2)) - SCREEN_T


def screen_hole_cuts(d=None):
    d = SCREEN_HOLE_D if d is None else d
    out = []
    for h in screen_holes():
        out.append(translate([h[0], h[1], SC_ZMIN - 2], cylinder(d=d, h=SC_ZT - SC_ZMIN + 4)))
        if sc_relief_top(h[1]) > SC_ZMIN + 0.5:                                                  # relief from below
            out.append(translate([h[0], h[1], SC_ZMIN - 2], cylinder(d=SCREEN_RELIEF_D, h=sc_relief_top(h[1]) - SC_ZMIN + 2)))
    return union(out)


SC_ROW_DY = SCREEN_HOLE_PITCH * sin(60)            # the hole rows' spacing in y
SC_SPLIT_ROWS = [3.5, 5.5]                         # split each top arc face between these rows (in row spacings from y = 0)


def screen(holes=True):
    """(SolidCraft only: each top arc face is split between hole rows into bands of at most 47 holes, so that it can be
    meshed; the solid is the same.)"""
    body = difference(screen_body(), screen_hole_cuts() if holes else None, screen_screw_cuts(), screen_pockets())
    if not holes:
        return body
    xm = chamber_L / 2                                                    # between hole columns or not: the point is between rows
    return split_faces(body, [([xm, s * k * SC_ROW_DY, sc_top(s * k * SC_ROW_DY)], [xm, s * k * SC_ROW_DY, 0], [0, 1, 0])
                              for s in (-1, 1) for k in SC_SPLIT_ROWS])


def screen_screws_ph():
    """M4 x 16 socket head, head on the land."""
    return union(translate([x, s * SCREEN_SCREW_Y, SC_ZT - SCREEN_SCREW_LAND - 0.01], part("M4 x 16 socket screw (screen)",
                     translate([0, 0, -SCREEN_SCREW[3]], cylinder(d=SCREEN_SCREW[2], h=SCREEN_SCREW[3])),
                     cylinder(d=SCREEN_SCREW[0] - 0.7, h=16)))                                    # shank at the thread core
                 for x in SCREEN_SCREW_X for s in (-1, 1))


def wall_screws_ph():
    """M5 x 16 socket head from below through the comb into the wall."""
    return union(translate([x, s * WALL_SCREW_Y, SC_ZT - 0.01], part("M5 x 16 socket screw (wall)",
                     translate([0, 0, -WALL_SCREW_HEAD[1]], cylinder(d=WALL_SCREW_HEAD[0], h=WALL_SCREW_HEAD[1])),
                     cylinder(d=4.1, h=16)))
                 for x in WALL_SCREW_X for s in (-1, 1))


def screen_shanks():
    """C16: M4 core through the wing's Ø4.5 and the comb's tapped Ø3.3."""
    return union(translate([x, s * SCREEN_SCREW_Y, SC_ZT - SCREEN_SCREW_LAND - 1], cylinder(d=SCREEN_SCREW[0] - 0.8, h=SCREEN_SCREW_LAND + SCREEN_TAP_DEPTH))
                 for x in SCREEN_SCREW_X for s in (-1, 1))


def screen_plan_proj_2d():
    """projection() of screen(): the outline with what goes through it (the Ø5 holes, the screws' Ø4.5 clearance); the
    blind reliefs, counterbores and pockets do not show in a silhouette."""
    return difference(translate([SC_X0, -SC_YW], square([SC_X1 - SC_X0, 2 * SC_YW])),
                      [translate(h, circle(d=SCREEN_HOLE_D)) for h in screen_holes()],
                      [translate([x, s * SCREEN_SCREW_Y], circle(d=SCREEN_SCREW[1])) for x in SCREEN_SCREW_X for s in (-1, 1)])


def screen_2d():
    """2D drawing: the cross-section, and 15 mm below it (not overlapping) the plan (projection) with the hole pattern and the screws' holes."""
    return union(screen_profile_2d(), translate([0, SC_ZMIN - SC_YW - 15], screen_plan_proj_2d()))     # plan below the section, 15 mm clear of it


def screen_holes_plan_2d():
    return union(translate(h, circle(d=SCREEN_HOLE_D)) for h in screen_holes())


def sc_bot(y):
    """Bottom of the Ø5 part of a hole at y."""
    return max(SC_ZMIN, sc_relief_top(y))


def screen_min_hole_len():
    return min(sc_top(h[1] + dy) - sc_bot(h[1] + dy) for h in screen_holes() for dy in (-SCREEN_HOLE_D / 2, 0, SCREEN_HOLE_D / 2))


def screen_box():
    return [[SC_X0, -SC_YW, SC_ZMIN], [SC_X1 - SC_X0, 2 * SC_YW, SC_ZT - SC_ZMIN]]


def cabinet():
    return union(cabinet_panels(), drawer_panels(), handle_world(), handle_screws_ph())


# ---------------- panel outlines, laid out on a sheet (mm).  Every outline is the SAME function the 3D part extrudes.
def cabinet_2d():
    sz, sy = CAB_H, CAB_SIDE_W
    return union(p_side_2d(),                                                                     # side x2
                 translate([sy + 10, 0], p_side_2d()),
                 translate([0, sz + 10], p_back_2d()),                                            # back
                 translate([2 * sy + 20, 0], p_floor_2d()),                                       # floor
                 translate([2 * sy + 20, sy + 10], p_front_2d()),                                 # drawer front (full height): only the 2 x Ø4.5 handle screw holes
                 translate([0, 2 * sz + 20], p_dbottom_2d()),                                     # drawer bottom
                 [translate([DR_W + 10 + i * (DR_L + 10), 2 * sz + 20], p_dside_2d()) for i in (0, 1)],   # drawer sides
                 translate([DR_W + 10 + 2 * (DR_L + 10), 2 * sz + 20], p_dback_2d()))             # drawer back


# ---------------- check helpers (checks.scad only sees modules / functions, not variables)
def drawer_inner_top():
    """Highest point of the drawer inside the cabinet: the bin top (or the pull's screw heads)."""
    return max(DR_Z0 + DR_H, HANDLE_Z + 3.5)


# joint alignment shanks (checks.scad C16): one shank per bolt, through the hole of part 1 and the hole of part 2
def foot_screw_shanks():
    """M6 core: base slot 6.6 + plate hole Ø5 x 12 deep (ends 11 mm up the hole)."""
    return union(translate([p[0], p[1], BASE_Z0 - 3], cylinder(d=4.9, h=BASE_T + 14)) for p in foot_screw_xy())


def hang_shanks():
    """M4 core: base Ø5 + panel pilot Ø3.3."""
    return union(translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH + 1], cylinder(d=HANG_PILOT_D - 0.2, h=HANG_PILOT_DEPTH + BASE_T + 2)) for p in hang_screw_xy())


def handle_shanks():
    """M4: front Ø4.5 + handle insert Ø5.6 (6 deep)."""
    return union(translate([p[0], DR_Y0 + 2, p[1]], rotate([90, 0, 0], cylinder(d=4, h=CAB_T + 2 + 5))) for p in handle_screw_xz())


def base_box():
    return [[BASE_X0, BASE_Y0, BASE_Z0], [BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, BASE_T]]


# ---------------- print / machining poses
def drawer_handle_print():
    """Back face down, shelf up."""
    return multmatrix([[0, 0, -1, HANDLE_W], [0, 1, 0, HANDLE_H / 2], [1, 0, 0, 0], [0, 0, 0, 1]], handle_local())


def screen_part():
    """As machined: x along the block, the wings' top faces up."""
    return translate([-SC_X0, SC_YW, -SC_ZMIN], screen())


# ---------------- the bodies of the assembly (drawer closed): what cad/assembly.scad shows, one group per colour
BODIES = {
    "Frame": [
        Body("Fixed screen (aluminium)", lambda: part("Screen", screen()), "#9aa5b1"),
        Body("Screen + wall screws", lambda: union(screen_screws_ph(), wall_screws_ph()), DARK),
        Body("Base plate", lambda: base_plate(), "#d9b98a"),
        Body("Cabinet (sides, back, floor)", lambda: cabinet_shell_panels(), "#c8a46e", 0.55),
    ],
    "Drawer": [
        Body("Drawer front + bin", lambda: drawer_panels(), "#bf9000"),
        Body("Handle", lambda: handle_world(), PRINT),
        Body("Handle screws", lambda: handle_screws_ph(), DARK),
    ],
}


# the parts of this file as the OpenSCAD pipeline exported them (parts.py): plywood reference models in the machine
# frame, the screen as machined, the printed handle in its print pose
PARTS = {"base_plate": base_plate,
         "cabinet": lambda: union(cabinet_panels(), drawer_panels()),
         "screen": screen_part,
         "drawer_handle": drawer_handle_print}

PARTS_2D = {"base_plate": base_2d,
            "cabinet_panels": cabinet_2d,
            "screen": screen_2d}       # the cross-section (top) and the plan with the holes and the screws' holes (below)
