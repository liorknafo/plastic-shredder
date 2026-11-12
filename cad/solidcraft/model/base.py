"""base.py -- 18 mm plywood base plate, the bin cabinet below it, the drawer with its printed pull handle and interlock
pads, the fixed safety grid (cad/base.scad).  World frame.

ONE SOURCE FOR 3D AND DXF.  Every plywood panel is a 2D function (p_*_2d, base_2d) in its own (u, v) frame.  The 3D part
  extrudes that function and the DXF sheet (cabinet_2d, base_2d) uses the same one, so drawing and model cannot diverge.

BASE   the shredder box sits on it at z = -35 on 8 M6 feet (y = +-65, in the bottom edges of the inner and outer layers;
  slots +-2 mm in x).  A plain rectangle: x -30 .. chamber_L + 70, y -115 .. 110 (it carries the machine and the cabinet's
  6 hang screws).  The drive is OUTSIDE the cabinet on the -x side on its own deck: nothing of it is anchored to the base.
CABINET  under the base, x -30 .. chamber_L + 30, y -110 .. 110; the drawer bin slides in from the front (-y).  The side
  panels hang on 6 screws through the base plate (set from the top BEFORE the machine goes on: the end plates cover the heads).
FIXED UPPER FRONT PANEL  18 mm ply in the plane of the drawer front (y = CAB_Y0 .. DR_Y0, the full width), from the underside
  of the base plate (face contact) DOWN to UFRONT_ZB, at or below the underside of the lower grid cleats (GRID_ZL).  SCREWED
  on: 4 x M4 x 45 from the top of the base plate into its top edge, 2 x 2 M4 x 45 through its face into the front edges of
  the side panels.  It keeps the space ABOVE the mesh closed when the drawer is out: the opening the drawer leaves is
  entirely UNDER the mesh.
DRAWER FRONT  18 mm panel in the same plane, the full width, from the bottom of the cabinet up to UFRONT_GAP (1 mm) under the
  fixed panel (z = DRF_ZT).  NO opening: the pull handle is a printed part on its outside, held by 2 x M4 x 22 screws that
  come from INSIDE the bin through two Ø4.5 holes into heat-set inserts in the handle.
DRAWER INTERLOCK  the Omron D4NS-2AF plain safety switch (interlock.py, APPROXIMATE envelope DSW_*: drill to the Omron
  drawing) on a flat 10 mm PAD on the OUTSIDE of the free-end side panel at the front (slot facing the front), and its
  D4DS-K2 key (DACT_*) on a flat printed PAD on the end face of the drawer front.  Both pads sit at DRAWER_SW_Z.  The key
  enters the head slot INTERLOCK_IN = 12 mm with the drawer closed and is out after 12 mm of travel.  No printed tongue.
SAFETY GRID  (the real protection from below): a sheet of 1" welded wire mesh (GRID_PITCH, GRID_WIRE) across the WHOLE inside
  of the cabinet at GRID_Z, resting on 20 x 20 cleats (lower set) and held down by a second set (upper set), screwed from
  outside through the side and back panels.  The front cleats are rails that span the cabinet, end-screwed through the side
  panels (1 mm clear of the fixed panel and of the drawer front).  The bin's top stays GRID_BIN_CLEAR under the lower cleats.

OPENINGS (Ø16 finger test, checks C9 / C30).  Everything that is open in the cabinet / drawer / base, with its size:
  base plate   outlet cut-out 132.2 x 110 -> into the cabinet only; 8 foot slots 10.6 x 6.6 (closed by the end plates, filled
               by M6 screws); 6 x Ø5 hang holes and 4 x Ø5 holes for the fixed panel's top screws, each filled by its screw
  cabinet      34 x Ø4.5 holes for the grid cleat screws (14 per side panel, 6 in the back), each filled by its screw
  fixed front  4 x Ø4.5 holes (2 per side panel), each filled by its M4 screw; with the drawer REMOVED the only opening left
               is x = -12 .. 144.2, z = floor .. UFRONT_ZB: entirely UNDER the mesh (C30)
  grid         mesh clear openings 23.4 x 23.4 (<= 30: ISO 13857 Table 4 gives 120 mm safety distance), edge gap 1 mm
  drawer       front: 2 x Ø4.5 (filled by the M4 screws, covered by the handle); bin: closed box; the gap between the drawer
               front and the fixed panel is 1 mm; all other joints are face contacts (C9a)
"""
from common import *
from joints import *              # foot_screw_xy() ...; also every name of drive_geom
from interlock import interlock

# the drawer switch = Omron D4NS-2AF + D4DS-K2 key (all approximate); interlock.py is a template built from these values
globals().update(interlock(DSW_BODY, DSW_HOLE_SPACING, DSW_SLOT, DSW_SCREW,
                           DACT_SIZE, DACT_BLADE_T, DACT_BLADE_L, DACT_HOLE_SPACING, DACT_SCREW))


def _along(p, d, k):
    """p + k * d (OpenSCAD's vector arithmetic)."""
    return [a + k * b for a, b in zip(p, d)]


def _each(name, node):
    """Every piece of a template union (one screw = head + shank) as a part of its own."""
    return union(part(name, c) for c in (node.ch if node.kind == "union" else [node]))


BASE_NX = -30
BASE_X0 = BASE_NX
BASE_X1 = chamber_L + 30 + 40
BASE_Y0 = -115
BASE_Y1 = 110                                      # y1 = the cabinet's back (CAB_Y1): the hang screws at y = 80 need plywood under them
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
DR_L = 160
DR_Z0 = CAB_FLOOR_TOP + 2
# ---------------- fixed safety grid: constants (functions further down).  The bin must slide in UNDER the lower cleats, so its height follows GRID_Z.
GRID_LAYER = GRID_WIRE - 0.1                       # the two crossed wire layers overlap 0.1 mm (the weld): no tangent-only contact in the model
GRID_T = GRID_WIRE + GRID_LAYER                    # 3.9 thick
GRID_ZB = GRID_Z - GRID_T                          # underside of the mesh = top of the lower cleats (-173.9)
GRID_ZL = GRID_ZB - GRID_CLEAT                     # underside of the lower cleats (-193.9)
DR_H = floor(GRID_ZL - GRID_BIN_CLEAR - DR_Z0)     # bin height 150: its top (-198) stays GRID_BIN_CLEAR under the lower cleats
BIN_FLOOR = DR_Z0 + DR_T                           # -338: 303 below the outlet plane (z = -35)
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
assert BASE_Z1 - BIN_FLOOR >= 300
assert CAB_ZB == GROUND_Z
# ---------------- the fixed upper front panel and the (short) sliding drawer front: both derived from the grid, nothing typed in
UFRONT_ZB = floor(GRID_ZL - UFRONT_BELOW)          # bottom edge of the fixed panel: -195, UFRONT_BELOW under the lower cleats (GRID_ZL = -193.9)
UFRONT_H = CAB_ZT - UFRONT_ZB                      # 142: from the underside of the base (face contact) down to UFRONT_ZB
DRF_ZT = UFRONT_ZB - UFRONT_GAP                    # top of the drawer front: -196
DRF_H = DRF_ZT - CAB_ZB                            # 172
UF_SCREW_Y = (CAB_Y0 + DR_Y0) / 2                  # the top screws go down the middle of the panel's thickness (y = -101)
UF_TOP_X = [CAB_X0 + 30 + i * (CAB_W - 60) / 3 for i in range(4)]     # 4 screws, 30 mm in from the ends, evenly spaced


def uf_top_xy():
    """The ONE definition: base-plate Ø5 holes AND the pilots in the panel's top edge."""
    return [[x, UF_SCREW_Y] for x in UF_TOP_X]


UF_FACE_X = [CAB_X0 + CAB_T / 2, CAB_X1 - CAB_T / 2]
UF_FACE_Z = [CAB_ZT - 47, CAB_ZT - 77]             # through the face into the side panels' front edges (clear of the hang pilots z > -78 and of the grid screws z < -150)


def uf_face_xz():
    """The ONE definition: Ø4.5 holes in the panel AND the pilots in the side panels."""
    return [[x, z] for x in UF_FACE_X for z in UF_FACE_Z]


assert UFRONT_ZB <= GRID_ZL, "the fixed upper front panel must reach down to or below the underside of the lower grid cleats"
assert 0 < UFRONT_GAP < 4, "gap between the fixed panel and the drawer front: > 0 and < 4 mm (C9a)"
assert CAB_ZB + DRF_H >= DR_Z0 + DR_H, "the drawer front must cover the bin"
assert BASE_Y0 <= CAB_Y0 and BASE_Y1 >= CAB_Y0 + CAB_T, "the base plate must cover the top edge of the fixed panel (top screws)"

# ---------------- fixed safety grid: geometry.  ONE definition for the 3D mesh, the DXF, the checks and the screw holes in the plywood.
GRID_IX0 = CAB_X0 + CAB_T                          # the inside of the cabinet: x -12 .. 144.2, y -92 .. 92
GRID_IX1 = CAB_X1 - CAB_T
GRID_IY0 = DR_Y0
GRID_IY1 = CAB_Y1 - CAB_T
GRID_WX = GRID_IX1 - GRID_IX0                      # 156.2 x 184
GRID_WY = GRID_IY1 - GRID_IY0
GRID_NX = floor((GRID_WX - GRID_WIRE - 2 * GRID_EDGE_GAP) / GRID_PITCH) + 1     # wires running along y (their x positions): 7
GRID_NY = floor((GRID_WY - GRID_WIRE - 2 * GRID_EDGE_GAP) / GRID_PITCH) + 1     # wires running along x (their y positions): 8
GRID_LX = (GRID_NX - 1) * GRID_PITCH + GRID_WIRE   # CUT SIZE of the sheet: 154.4 x 179.8
GRID_LY = (GRID_NY - 1) * GRID_PITCH + GRID_WIRE
GRID_GX = (GRID_WX - GRID_LX) / 2                  # gap sheet to wall: 0.9 (x), 2.1 (y)
GRID_GY = (GRID_WY - GRID_LY) / 2
GRID_X0 = CAB_XC - GRID_LX / 2
GRID_Y0 = (GRID_IY0 + GRID_IY1) / 2 - GRID_LY / 2
GRID_FCLR = 1                                      # the front rail stands 1 mm clear of the fixed upper front panel and of the drawer front (inner face y = -92)
GRID_FY = GRID_IY0 + GRID_FCLR
GRID_PD = 17                                       # pilot depth in the cleat for the M4 x 35 (18 plywood + 17)
assert GRID_PITCH - GRID_WIRE <= GRID_MAX_OPEN, \
    "grid: the clear opening must be <= 30 mm (ISO 13857 Table 4: 120 mm distance for square openings 20 < e <= 30)"
assert GRID_Z <= -R_TIP - GRID_MIN_DIST, "grid: its top must be >= 120 mm below the lowest point of the blade-tip envelope (z = -R_TIP)"
assert GRID_GX >= GRID_EDGE_GAP - 1e-9 and GRID_GY >= GRID_EDGE_GAP - 1e-9 and GRID_GX < GRID_MAX_EDGE_GAP and GRID_GY < GRID_MAX_EDGE_GAP, \
    "grid: the sheet must clear the walls by >= GRID_EDGE_GAP and leave an edge gap < 10 mm"
assert DR_Z0 + DR_H + GRID_BIN_CLEAR <= GRID_ZL + 1e-9 and DR_H >= 100, "the bin must stay under the lower cleats and at least 100 high"


def grid_xs():
    """x of the wires that run along y."""
    return [CAB_XC + (i - (GRID_NX - 1) / 2) * GRID_PITCH for i in range(GRID_NX)]


def grid_ys():
    """y of the wires that run along x."""
    return [(GRID_IY0 + GRID_IY1) / 2 + (j - (GRID_NY - 1) / 2) * GRID_PITCH for j in range(GRID_NY)]


def grid_cleat_boxes():
    """Cleats: 20 x 20 timber on the four walls, lower set under the mesh, upper set on top; plan boxes [x0, y0, x1, y1].
    The FRONT "wall" is the drawer front, which slides out: the front cleat is a rail that spans the cabinet and is
    end-screwed through the side panels, GRID_FCLR clear of the drawer front."""
    c = GRID_CLEAT
    return [[GRID_IX0, GRID_FY, GRID_IX1, GRID_FY + c],                      # front rail
            [GRID_IX0, GRID_IY1 - c, GRID_IX1, GRID_IY1],                    # back
            [GRID_IX0, GRID_FY + c, GRID_IX0 + c, GRID_IY1 - c],             # drive-end side
            [GRID_IX1 - c, GRID_FY + c, GRID_IX1, GRID_IY1 - c]]             # free-end side


GRID_CLEAT_NAMES = ["front rail", "back cleat", "side cleat (drive end)", "side cleat (free end)"]     # the parts, in the order of grid_cleat_boxes()


def grid_level_z(level):
    return GRID_ZB - GRID_CLEAT / 2 if level == 0 else GRID_Z + GRID_CLEAT / 2       # mid-height of the lower (0) / upper (1) cleats


def grid_screws(level):
    """The screws: [[point on the cleat's wall face], [direction into the cabinet]]; M4 x 35 from OUTSIDE through a Ø4.5
    hole in the plywood into a Ø3 pilot in the cleat."""
    z, c = grid_level_z(level), GRID_CLEAT
    return ([[[GRID_IX0 if w == 0 else GRID_IX1, y, z + dz], [1 if w == 0 else -1, 0, 0]]                 # end grain of the front rail / back cleat, 2 per end
             for w in (0, 1) for y in (GRID_FY + c / 2, GRID_IY1 - c / 2) for dz in (-5, 5)]
            + [[[GRID_IX0 if w == 0 else GRID_IX1, y, z], [1 if w == 0 else -1, 0, 0]] for w in (0, 1) for y in (-48, 0, 48)]   # the side cleats
            + [[[x, GRID_IY1, z], [0, -1, 0]] for x in (CAB_XC - 50, CAB_XC, CAB_XC + 50)])                # the back cleat, through the back panel


def grid_screw_box(s):
    """Index in grid_cleat_boxes() of the cleat that screw s goes into (the box that holds the middle of its pilot)."""
    p = _along(s[0], s[1], GRID_PD / 2)
    return next(i for i, b in enumerate(grid_cleat_boxes()) if b[0] <= p[0] <= b[2] and b[1] <= p[1] <= b[3])


def grid_side_holes():
    """(u, v) in p_side_2d."""
    return [[s[0][1] - DR_Y0, s[0][2] - CAB_ZB] for lv in (0, 1) for s in grid_screws(lv) if s[1][0] == 1]


def grid_back_holes():
    """(u, v) in p_back_2d."""
    return [[s[0][0] - (CAB_X0 + CAB_T), s[0][2] - CAB_ZB] for lv in (0, 1) for s in grid_screws(lv) if s[1][1] == -1]


# ---------------- 2D outlines: the ONLY definition of each panel (3D parts and DXF both use these)
def base_2d():
    return difference(
        translate([BASE_X0, BASE_Y0], square([BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0])),
        translate([0, -55], square([chamber_L, 110])),                                           # outlet cut-out
        [hull(translate([p[0] + dx, p[1]], circle(d=6.6)) for dx in (-FOOT_SLOT, FOOT_SLOT)) for p in foot_screw_xy()],   # M6 feet (end plates)
        [translate(p, circle(d=5)) for p in hang_screw_xy()],                                    # cabinet hang screws, centred on the panel edges
        [translate(p, circle(d=5)) for p in uf_top_xy()])                                        # the fixed upper front panel's top screws, down the middle of its thickness


def p_side_2d():
    """u = y - DR_Y0 (front edge at u = 0), v = z - CAB_ZB;  14 x Ø4.5 for the grid cleat screws."""
    return difference(square([CAB_SIDE_W, CAB_H]),
                      [translate(p, circle(d=GRID_SCREW[1])) for p in grid_side_holes()])


def p_back_2d():
    """u = x - (CAB_X0 + CAB_T);  6 x Ø4.5 for the back cleats."""
    return difference(square([CAB_W - 2 * CAB_T, CAB_H]),
                      [translate(p, circle(d=GRID_SCREW[1])) for p in grid_back_holes()])


def p_floor_2d():
    return square([CAB_W, CAB_SIDE_W])                                                           # u = x - CAB_X0, v = y - DR_Y0


def handle_screw_xz():
    """The ONE definition (world x, z): drawer-front holes AND handle inserts."""
    return [[CAB_XC + s * HANDLE_SCREW_DX, HANDLE_Z] for s in (-1, 1)]


HANDLE_PTS = [[p[0] - CAB_X0, p[1] - CAB_ZB] for p in handle_screw_xz()]                         # in the drawer-front frame


def p_front_2d(test_hole_d=0):
    """Drawer front: u = x - CAB_X0, v = z - CAB_ZB.  test_hole_d only for the C9 control."""
    return difference(square([CAB_W, DRF_H]),
                      [translate(p, circle(d=HANDLE_HOLE_D)) for p in HANDLE_PTS],
                      translate([CAB_W / 2, DRF_H / 2], circle(d=test_hole_d)) if test_hole_d > 0 else None)


def p_ufront_2d(raise_=0):
    """Fixed upper front panel: u = x - CAB_X0, v = z - UFRONT_ZB.  raise_ (`raise` in the .scad) only for the C30
    control (bottom edge raised)."""
    return difference(translate([0, raise_], square([CAB_W, UFRONT_H - raise_])),
                      [translate([p[0] - CAB_X0, p[1] - UFRONT_ZB], circle(d=HANDLE_HOLE_D)) for p in uf_face_xz()])   # 4 x Ø4.5 for the M4 screws into the side panels


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


UF_PILOT_D = 3.3                                   # M4 x 45: 18 plywood + 25 into the edge (like the hang screws)
UF_PILOT_DEPTH = 25


def HANGX(free_end):
    return HANG_X[1] if free_end else HANG_X[0]


def cab_side(free_end):
    return difference(
        yz_panel(CAB_X1 - CAB_T if free_end else CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_side_2d()),
        [translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH], cylinder(d=HANG_PILOT_D, h=HANG_PILOT_DEPTH + 1))             # pilots for the hang screws, in the top edge
         for p in hang_screw_xy() if abs(p[0] - HANGX(free_end)) < 0.01],
        [translate([p[0], DR_Y0 - 1, p[1]], rotate([-90, 0, 0], cylinder(d=UF_PILOT_D, h=UF_PILOT_DEPTH + 1)))            # pilots for the fixed front panel's face screws, in the front edge
         for p in uf_face_xz() if abs(p[0] - HANGX(free_end)) < 0.01],
        [translate([CAB_X1 + 1, q[0], q[1]], rotate([0, -90, 0], cylinder(d=4, h=15))) for q in sw_pad_screw_yz()]       # pilots for the switch pad screws, from the outer face
        if free_end else None)


def cabinet_shell_panels():
    return union(part("Cabinet side panel (drive end)", cab_side(False)),
                 part("Cabinet side panel (free end)", cab_side(True)),
                 part("Cabinet back panel", xz_panel(CAB_X0 + CAB_T, CAB_Y1, CAB_ZB, CAB_T, p_back_2d())),
                 part("Cabinet floor panel", xy_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_floor_2d())))


def cabinet_panels():
    """+ the FIXED upper front panel (the drawer front is a separate, sliding part)."""
    return union(cabinet_shell_panels(), upper_front())


def drawer_front(test_hole_d=0):
    """Closes the opening below the fixed upper panel, no slot."""
    return part("Drawer front panel", difference(
        xz_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T, p_front_2d(test_hole_d)),
        [translate([CAB_X1 + 1, q[0], q[1]], rotate([0, -90, 0], cylinder(d=3, h=15))) for q in act_pad_screw_yz()]))    # pilots for the actuator-pad screws, in the end face


def upper_front(raise_=0):
    """FIXED panel: base plate (face contact) down to UFRONT_ZB; raise_ only for the C30 control."""
    return part("Fixed upper front panel", difference(
        xz_panel(CAB_X0, DR_Y0, UFRONT_ZB, CAB_T, p_ufront_2d(raise_)),
        [translate([p[0], p[1], CAB_ZT - UF_PILOT_DEPTH], cylinder(d=UF_PILOT_D, h=UF_PILOT_DEPTH + 1)) for p in uf_top_xy()]))   # pilots for the top screws, in the top edge


def upper_front_screws_ph():
    """8 x M4 x 45 pan head (placeholder, visual only)."""
    return union(
        [translate([p[0], p[1], BASE_Z1], part("M4 x 45 pan head screw (fixed front panel)",                 # head on top of the base plate, shank down through it into the pilot
                                               cylinder(d=7, h=3),
                                               translate([0, 0, -(BASE_T + UF_PILOT_DEPTH - 1)], cylinder(d=4, h=BASE_T + UF_PILOT_DEPTH - 1))))
         for p in uf_top_xy()],
        [translate([p[0], CAB_Y0 - 3, p[1]], rotate([-90, 0, 0], part("M4 x 45 pan head screw (fixed front panel)",
                                                                      cylinder(d=7, h=3),
                                                                      translate([0, 0, 3], cylinder(d=4, h=CAB_T + UF_PILOT_DEPTH - 1)))))
         for p in uf_face_xz()])


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


# ---------------- drawer interlock: real switch (interlock.py, approximate envelope) on the PAD on the free-end side panel,
# coded actuator on the PAD on the end face of the drawer front.
# Switch frame S (a, b, c) -> world: a -> +x, b -> +y (head end face at the front), c -> +z.
SW_X0 = CAB_X1 + SW_PAD_T                          # switch mounting face = pad outer face
SW_Y0 = CAB_Y0 + 2 + ACT_L - INTERLOCK_IN          # head end face of the switch = slot mouth (-70): the actuator's tail then lies 2 mm behind the drawer front's outer face
SW_YC = SW_Y0 + SW_L / 2


def sw_world(*ch):
    return translate([SW_X0, SW_Y0, DRAWER_SW_Z], *ch)


DPAD_B = [SW_L / 2 + s * 35 for s in (-1, 1)]      # the 2 x M5 wood screws that hold the switch pad on the side panel (b positions)


def sw_pad_screw_yz():
    return [[SW_Y0 + b, DRAWER_SW_Z] for b in DPAD_B]                                             # world (y, z)


APAD_B = [INTERLOCK_IN - ACT_L - 2, INTERLOCK_IN - ACT_BL + 3]     # actuator pad extent along b: -40 .. -5 (world y -110 .. -75)
APAD_BR = DR_Y0 - SW_Y0                            # b of the side panels' front edge (-22): beyond it the pad overhangs the panel face, 1 mm clear
APAD_SCREW_B = CAB_Y0 + CAB_T / 2 - SW_Y0          # the 2 x M4 wood screws into the drawer-front end face: middle of its 18 mm thickness (b = -17)


def act_pad_screw_yz():
    return [[SW_Y0 + APAD_SCREW_B, DRAWER_SW_Z + c] for c in (-8, 8)]                             # world (y, z)


assert INTERLOCK_IN >= 10 and INTERLOCK_IN < IL_SW_SLOT[2] and INTERLOCK_IN <= INTERLOCK_OUT_TRAVEL
assert SW_Y0 + APAD_B[1] < SW_Y0 - 1               # the actuator pad ends >= 1 mm in front of the switch head end face
assert abs(SW_Y0 + APAD_B[0] - CAB_Y0) < 1e-9      # ... and starts flush with the drawer front's outer face
# the interlock pads must lie on the SHORT drawer front (z = CAB_ZB .. DRF_ZT) / on the side panel next to it, above the floor,
# under the handle, clear of the grid cleat screw heads
SW_LOW_GRID_Z = CAB_ZB + min(h[1] for h in grid_side_holes())                                     # lowest grid screw on the side panel's outer face
assert DRAWER_SW_Z + SW_PAD_W / 2 <= DRF_ZT - 2 and DRAWER_SW_Z - SW_PAD_W / 2 >= CAB_FLOOR_TOP, \
    "interlock pads must lie within the drawer front's height, above the floor"
assert DRAWER_SW_Z + SW_PAD_W / 2 <= SW_LOW_GRID_Z - GRID_SCREW[2] / 2 - 2, "the switch pad must clear the grid cleat screw heads on the side panel"
assert DRAWER_SW_Z + SW_PAD_W / 2 <= HANDLE_Z - HANDLE_H / 2 - 2 or DRAWER_SW_Z - SW_PAD_W / 2 >= HANDLE_Z + HANDLE_H / 2 + 2, \
    "interlock pads clear (in z) of the handle"
assert HANDLE_Z + HANDLE_H / 2 <= DRF_ZT - 5 and HANDLE_Z - HANDLE_H / 2 >= CAB_ZB + 5, "the pull handle must lie fully on the drawer front"
# the fixed panel's face-screw pilots (u 0 .. UF_PILOT_DEPTH in the side panels) clear of the grid screw holes, the hang pilots and the switch pad's pilots
assert min(abs(h[1] - (z - CAB_ZB)) for h in grid_side_holes() for z in UF_FACE_Z) >= 10, "fixed-panel face screws clear of the grid cleat screw holes"
assert UF_FACE_Z[0] <= CAB_ZT - HANG_PILOT_DEPTH - 10, "fixed-panel face screws clear of the hang pilots"
assert min(q[0] - DR_Y0 for q in sw_pad_screw_yz()) >= UF_PILOT_DEPTH + 5, "fixed-panel face screws clear of the switch pad pilots"


def drawer_pad():
    """Printed switch pad on the free-end side panel: 10 x 92 x 32 (a, b, c)."""
    return sw_world(part("Drawer switch pad", difference(
        translate([-SW_PAD_T, (SW_L - SW_PAD_L) / 2, -SW_PAD_W / 2], cube([SW_PAD_T, SW_PAD_L, SW_PAD_W])),
        sw_pad_pilots(),                                                                          # 2 x Ø3.3 pilots for the switch's M4 screws, 22 apart
        [translate([0.01, b, 0], rotate([0, -90, 0],                                              # 2 x M5 wood screws into the panel (blind)
                                        cylinder(d=5.5, h=SW_PAD_T + 0.02),
                                        cylinder(d=10, h=4))) for b in DPAD_B])))


def drawer_act_pad():
    """Printed actuator pad on the end face of the drawer front: 19 thick, flat face, no tongue.
    (The .scad pushed the first block 0.01 into the second, a weld: here they share the face b = APAD_BR.)"""
    return sw_world(part("Drawer actuator pad", difference(
        union(translate([-SW_PAD_T, APAD_B[0], -SW_PAD_W / 2], cube([SW_PAD_T + A_OFF, APAD_BR - APAD_B[0], SW_PAD_W])),         # on the drawer front's end face
              translate([-SW_PAD_T + 1, APAD_BR, -SW_PAD_W / 2], cube([SW_PAD_T - 1 + A_OFF, APAD_B[1] - APAD_BR, SW_PAD_W]))),  # overhang past the front edge of the side panel (1 mm clear)
        act_in_sw(0, act_pad_pilots()),                                                           # 2 x Ø3.3 pilots, ACT_HOLE_SPACING apart
        [translate([A_OFF + 0.01, APAD_SCREW_B, c], rotate([0, -90, 0],                           # 2 x M4 wood screws into the drawer-front end face
                                                           cylinder(d=4.5, h=SW_PAD_T + A_OFF + 0.02),
                                                           cylinder(d=8.5, h=4))) for c in (-8, 8)])))


def drawer_switch_ph():
    """The safety switch (placeholder), slot cut."""
    return sw_world(part("Drawer safety switch (Omron D4NS-2AF)", sw_ph()))


def drawer_switch_env():
    return sw_world(sw_body_env())                                                                # body without the slot


def drawer_switch_slot():
    return sw_world(sw_slot())


def drawer_switch_screws_ph():
    return sw_world(_each("M4 pan head screw (drawer switch)", sw_screws_ph()))


# the moving side: travel > 0 = drawer pulled out by that much (-y)
def drawer_act_pad_moved(travel=0):
    return translate([0, -travel, 0], drawer_act_pad())


def drawer_actuator(travel=0):
    """The coded actuator (placeholder)."""
    return translate([0, -travel, 0], sw_world(act_in_sw(0, part("Drawer actuator key (Omron D4DS-K2)", act_ph()))))


def drawer_actuator_screws_ph(travel=0):
    return translate([0, -travel, 0], sw_world(act_in_sw(0, _each("M4 pan head screw (drawer actuator key)", act_screws_ph()))))


def drawer_blade(travel=0):
    """The blade only: the part that enters the head."""
    return translate([0, -travel, 0], sw_world(blade_env()))


def drawer_interlock_ph(travel=0):
    return union(drawer_pad(), drawer_switch_ph(), drawer_act_pad_moved(travel), drawer_actuator(travel))


def cabinet():
    return union(cabinet_panels(), drawer_panels(), handle_world(), drawer_interlock_ph(), grid_mesh(), grid_cleats(0), grid_cleats(1),
                 grid_screws_ph(), upper_front_screws_ph())


# ---------------- the fixed safety grid
def grid_wires_2d():
    """Plan of the mesh: the wires (2 mm) at GRID_PITCH; the holes of this shape are the cells."""
    return union([translate([x - GRID_WIRE / 2, GRID_Y0], square([GRID_WIRE, GRID_LY])) for x in grid_xs()],
                 [translate([GRID_X0, y - GRID_WIRE / 2], square([GRID_LX, GRID_WIRE])) for y in grid_ys()])


def grid_sheet_2d():
    return translate([GRID_X0, GRID_Y0], square([GRID_LX, GRID_LY]))                              # the cut sheet's outline


def grid_mesh():
    """Round wire Ø2: the wires along x on top (top surface = GRID_Z), those along y under them, welded at the crossings
    (the layers overlap 0.1 mm): ONE part."""
    return part("Safety grid mesh",
                [translate([x, GRID_Y0, GRID_Z - GRID_WIRE / 2 - GRID_LAYER], rotate([-90, 0, 0], cylinder(d=GRID_WIRE, h=GRID_LY))) for x in grid_xs()],
                [translate([GRID_X0, y, GRID_Z - GRID_WIRE / 2], rotate([0, 90, 0], cylinder(d=GRID_WIRE, h=GRID_LX))) for y in grid_ys()])


def dir_z(d, *ch):
    """Local +z -> the axis direction d (one of +x, -x, -y)."""
    if d[0] == 1:
        return rotate([0, 90, 0], *ch)
    if d[0] == -1:
        return rotate([0, -90, 0], *ch)
    return rotate([90, 0, 0], *ch)


def grid_cleats(level=0, g=0):
    """level 0: lower set (top face under the mesh), 1: upper set (bottom face on the mesh); g > 0: every box shrunk by g
    per face (touching-face checks).  One part per cleat, each with the Ø3 pilots of its own screws (the .scad cut every
    pilot from the union of the four boxes: the same holes)."""
    return union(
        part(f"Grid {GRID_CLEAT_NAMES[i]}, {'lower' if level == 0 else 'upper'} set", difference(
            translate([b[0] + g, b[1] + g, (GRID_ZL if level == 0 else GRID_Z) + g], cube([b[2] - b[0] - 2 * g, b[3] - b[1] - 2 * g, GRID_CLEAT - 2 * g])),
            [translate(_along(s[0], s[1], -0.01), dir_z(s[1], cylinder(d=GRID_SCREW[4], h=GRID_PD + 0.01)))       # Ø3 pilots
             for s in grid_screws(level) if grid_screw_box(s) == i]))
        for i, b in enumerate(grid_cleat_boxes()))


def grid_screws_ph():
    """M4 x 35 pan head, head on the outside."""
    return union(translate(_along(s[0], s[1], -CAB_T), dir_z(s[1], part("M4 x 35 pan head wood screw (grid cleat)",
                                                                       translate([0, 0, -GRID_SCREW[3]], cylinder(d=GRID_SCREW[2], h=GRID_SCREW[3])),
                                                                       cylinder(d=GRID_SCREW[0], h=CAB_T + GRID_PD - 1))))
                 for lv in (0, 1) for s in grid_screws(lv))


def grid_screw_shanks():
    """C16: thread core through the plywood hole and the cleat pilot."""
    return union(translate(_along(s[0], s[1], -(CAB_T + 1)), dir_z(s[1], cylinder(d=GRID_SCREW[4] - 0.2, h=CAB_T + GRID_PD - 1)))
                 for lv in (0, 1) for s in grid_screws(lv))


def cleat_strip_2d(len, holes):
    return difference(square([len, GRID_CLEAT]),
                      [translate([h, GRID_CLEAT / 2], circle(d=GRID_SCREW[4])) for h in holes])


GRID_SIDE_LEN = GRID_IY1 - GRID_FY - 2 * GRID_CLEAT                                               # the side cleats run between the front rail and the back cleat: 143


def grid_cleats_2d():
    """The 8 strips (4 lower, 4 upper), elevation seen from the wall side, with the Ø3 face pilots; the rails also have
    2 end-grain pilots per end."""
    return union(translate([0, lv * 4 * (GRID_CLEAT + 10)],
                           cleat_strip_2d(GRID_WX, []),                                                                    # front rail
                           translate([0, GRID_CLEAT + 10], cleat_strip_2d(GRID_WX, [x - GRID_IX0 for x in (CAB_XC - 50, CAB_XC, CAB_XC + 50)])),   # back cleat
                           [translate([0, (2 + i) * (GRID_CLEAT + 10)], cleat_strip_2d(GRID_SIDE_LEN, [y - (GRID_FY + GRID_CLEAT) for y in (-48, 0, 48)]))   # side cleats
                            for i in (0, 1)])
                 for lv in (0, 1))


# check helpers (checks.scad saw modules only)
def grid_box():
    return [[GRID_X0, GRID_Y0, GRID_ZB], [GRID_LX, GRID_LY, GRID_T]]


def grid_cleat_box(level):
    return [[GRID_IX0, GRID_FY, GRID_ZL if level == 0 else GRID_Z], [GRID_WX, GRID_IY1 - GRID_FY, GRID_CLEAT]]


def grid_set(g=0.01):
    """Mesh + both cleat sets (cleats shrunk by g: they touch the walls)."""
    return union(grid_mesh(), grid_cleats(0, g), grid_cleats(1, g))


def grid_reach(h):
    """The volume over the cabinet from the mesh top up to h above it."""
    return translate([GRID_IX0, GRID_IY0, GRID_Z], cube([GRID_WX, GRID_WY, h]))


def grid_probes(d, reach):
    """Finger probes of Ø d, one in the middle of every cell, pushed up from far below to `reach` above the mesh top."""
    xs, ys = grid_xs(), grid_ys()
    return union(translate([(xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2, GRID_ZL - 100], cylinder(d=d, h=GRID_Z + reach - (GRID_ZL - 100)))
                 for i in range(GRID_NX - 1) for j in range(GRID_NY - 1))


def grid_edge_free(sh=0):
    """The free space between the cut sheet and the walls (a 40 mm window round the mesh); sh: control, sheet smaller by sh per side."""
    return difference(translate([GRID_IX0, GRID_IY0, GRID_Z - 20], cube([GRID_WX, GRID_WY, 40])),
                      translate([GRID_X0 + sh, GRID_Y0 + sh, GRID_Z - 21], cube([GRID_LX - 2 * sh, GRID_LY - 2 * sh, 42])))


def grid_free_2d():
    """The plan of the cabinet minus the wires: the openings (cells + the thin edge gaps)."""
    return difference(grid_inside_2d(), grid_wires_2d())


def grid_inside_2d():
    return translate([GRID_IX0, GRID_IY0], square([GRID_WX, GRID_WY]))                            # the inside of the cabinet in plan


def grid_cleat_plan_2d():
    return union(translate([b[0], b[1]], square([b[2] - b[0], b[3] - b[1]])) for b in grid_cleat_boxes())


def drawer_moved_ph(t):
    """The drawer (front, bin, handle) pulled out by t."""
    return translate([0, -t, 0], drawer_panels(), handle_world(), handle_screws_ph())


# ---------------- panel outlines, laid out on a sheet (mm).  Every outline is the SAME function the 3D part extrudes.
def cabinet_2d():
    sz, sy = CAB_H, CAB_SIDE_W
    return union(p_side_2d(),                                                                     # side x2
                 translate([sy + 10, 0], p_side_2d()),
                 translate([0, sz + 10], p_back_2d()),                                            # back
                 translate([2 * sy + 20, 0], p_floor_2d()),                                       # floor
                 translate([2 * sy + 20, sy + 10], p_front_2d()),                                 # drawer front (short): only the 2 x Ø4.5 handle screw holes
                 translate([2 * sy + 20, sy + 10 + DRF_H + 10], p_ufront_2d()),                   # FIXED upper front panel: 4 x Ø4.5 face-screw holes (the top-edge pilots are drilled from the base plate)
                 translate([0, 2 * sz + 20], p_dbottom_2d()),                                     # drawer bottom
                 [translate([DR_W + 10 + i * (DR_L + 10), 2 * sz + 20], p_dside_2d()) for i in (0, 1)],   # drawer sides
                 translate([DR_W + 10 + 2 * (DR_L + 10), 2 * sz + 20], p_dback_2d()))             # drawer back


# ---------------- check helpers (checks.scad only saw modules, not variables)
def cab_shell_free(test_hole_d=0, utest_hole_d=0):
    """Free space inside the 18 mm shell of the cabinet (sides, back, floor, fixed upper front, drawer front), drawer closed."""
    return difference(
        translate([CAB_X0, CAB_Y0, CAB_ZB], cube([CAB_W, CAB_Y1 - CAB_Y0, CAB_H])),
        translate([CAB_X0 + CAB_T, DR_Y0, CAB_ZB + CAB_T], cube([CAB_W - 2 * CAB_T, CAB_Y1 - CAB_T - DR_Y0, CAB_H - CAB_T + 1])),   # the inside (open to the base plate above)
        cabinet_shell_panels(),
        upper_front_with_hole(utest_hole_d),
        drawer_front(test_hole_d))


def upper_front_with_hole(d):
    """upper_front(), plus (only for a C9 control) a Ø d hole through its middle."""
    return difference(upper_front(),
                      translate([CAB_XC, CAB_Y0 - 1, (UFRONT_ZB + CAB_ZT) / 2], rotate([-90, 0, 0], cylinder(d=d, h=CAB_T + 2))) if d > 0 else None)


def cab_shell_free_nodrawer(raise_=0):
    """C30: the same shell with the drawer (front AND bin) REMOVED; raise_: control, the fixed panel's bottom edge raised
    by that much (>= UFRONT_H: panel absent)."""
    return difference(
        translate([CAB_X0, CAB_Y0, CAB_ZB], cube([CAB_W, CAB_Y1 - CAB_Y0, CAB_H])),
        translate([CAB_X0 + CAB_T, DR_Y0, CAB_ZB + CAB_T], cube([CAB_W - 2 * CAB_T, CAB_Y1 - CAB_T - DR_Y0, CAB_H - CAB_T + 1])),
        cabinet_shell_panels(),
        upper_front(raise_) if raise_ < UFRONT_H else None)


def above_mesh_slab():
    """Everything from the underside of the lower cleats (below the mesh) up to the base."""
    return translate([CAB_X0 - 10, CAB_Y0 - 10, GRID_ZL], cube([CAB_W + 20, CAB_Y1 - CAB_Y0 + 20, CAB_ZT - GRID_ZL + 10]))


def below_grid_slab():
    """Everything under the lower cleats."""
    return translate([CAB_X0 - 10, CAB_Y0 - 10, CAB_ZB - 10], cube([CAB_W + 20, CAB_Y1 - CAB_Y0 + 20, GRID_ZL - CAB_ZB + 10]))


def grid_zl():
    return GRID_ZL


def uf_zb():
    return UFRONT_ZB


def uf_zt():
    return CAB_ZT


def drf_zt():
    return DRF_ZT


def bin_top():
    return DR_Z0 + DR_H


def uf_gap():
    return UFRONT_GAP


def uf_top_shanks():
    """C16: M4 core: base Ø5 + panel pilot Ø3.3."""
    return union(translate([p[0], p[1], CAB_ZT - UF_PILOT_DEPTH + 1], cylinder(d=UF_PILOT_D - 0.2, h=UF_PILOT_DEPTH + BASE_T + 2)) for p in uf_top_xy())


def uf_face_shanks():
    """C16: panel Ø4.5 + side-panel pilot Ø3.3."""
    return union(translate([p[0], CAB_Y0 - 2, p[1]], rotate([-90, 0, 0], cylinder(d=UF_PILOT_D - 0.2, h=CAB_T + UF_PILOT_DEPTH + 1))) for p in uf_face_xz())


def rail_slot_free(shift=0):
    """C30b: the air between the fixed panel's back face and the front rail, over the height of the grid; shift: control,
    grid set moved back by that much."""
    return difference(translate([GRID_IX0, DR_Y0, GRID_ZL], cube([GRID_WX, GRID_FY + GRID_CLEAT - DR_Y0, GRID_Z + GRID_CLEAT - GRID_ZL])),
                      translate([0, shift, 0], grid_set(0)))


def ufront_box():
    return [[CAB_X0, CAB_Y0, UFRONT_ZB], [CAB_W, CAB_T, UFRONT_H]]


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


def drawer_pad_box():
    return [[CAB_X1, SW_Y0 + (SW_L - SW_PAD_L) / 2, DRAWER_SW_Z - SW_PAD_W / 2], [SW_PAD_T, SW_PAD_L, SW_PAD_W]]


def drawer_act_pad_box():
    return [[CAB_X1, CAB_Y0, DRAWER_SW_Z - SW_PAD_W / 2], [SW_PAD_T + A_OFF, APAD_B[1] - APAD_B[0], SW_PAD_W]]


def drawer_sw_shanks():
    """Switch M4 screws: body Ø4.5 + pad pilots."""
    return sw_world(sw_shanks())


def drawer_pad_shanks():
    """M5 core: pad Ø5.5 + panel pilot Ø4 (14 deep, shank 1 short of the bottom)."""
    return union(translate([SW_X0 + 1, q[0], q[1]], rotate([0, -90, 0], cylinder(d=3.8, h=SW_PAD_T + 13))) for q in sw_pad_screw_yz())


def drawer_act_shanks(travel=0):
    """Actuator M4 screws: block Ø4.5 + pad pilots."""
    return translate([0, -travel, 0], sw_world(act_in_sw(0, act_shanks())))


def drawer_act_pad_shanks():
    """M4 core: pad Ø4.5 + end-face pilot Ø3 (14 deep)."""
    return union(translate([SW_X0 + A_OFF + 1, q[0], q[1]], rotate([0, -90, 0], cylinder(d=2.8, h=SW_PAD_T + A_OFF + 13))) for q in act_pad_screw_yz())


def sw_slot_from(depth):
    """The part of the switch slot deeper than `depth` from the mouth."""
    return intersection(drawer_switch_slot(),
                        translate([SW_X0 - 1, SW_Y0 + depth, DRAWER_SW_Z - 50], cube([40, 50, 100])))


def base_box():
    return [[BASE_X0, BASE_Y0, BASE_Z0], [BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, BASE_T]]


def hole_probe_ph(d, len=300, *ch):
    return union(*ch)                                                                             # (reserved)


# ---------------- print poses (flat face down)
def drawer_handle_print():
    """Back face down, shelf up."""
    return multmatrix([[0, 0, -1, HANDLE_W], [0, 1, 0, HANDLE_H / 2], [1, 0, 0, 0], [0, 0, 0, 1]], handle_local())


def drawer_pad_print():
    """Panel face down, holes open upward."""
    return multmatrix([[0, 1, 0, -(SW_YC - SW_PAD_L / 2)], [0, 0, 1, -(DRAWER_SW_Z - SW_PAD_W / 2)], [1, 0, 0, -CAB_X1], [0, 0, 0, 1]], drawer_pad())


def drawer_act_pad_print():
    """Face against the drawer front down, the actuator face (pilots) up."""
    return multmatrix([[0, 1, 0, -CAB_Y0], [0, 0, 1, -(DRAWER_SW_Z - SW_PAD_W / 2)], [1, 0, 0, -CAB_X1], [0, 0, 0, 1]], drawer_act_pad())


# ---------------- the bodies of the assembly (drawer closed): what cad/assembly.scad showed, one group per colour
BODIES = {
    "Frame": [
        Body("Base plate", lambda: base_plate(), "#d9b98a"),
        Body("Cabinet (sides, back, floor)", lambda: cabinet_shell_panels(), "#c8a46e", 0.55),
        Body("Fixed upper front panel", lambda: upper_front(), "#8c5a2b", 0.8),
        Body("Drawer switch pad", lambda: drawer_pad(), PRINT),
        Body("Drawer switch + screws, front panel screws",
             lambda: union(drawer_switch_ph(), drawer_switch_screws_ph(), upper_front_screws_ph()), DARK),
        Body("Safety grid mesh", lambda: grid_mesh(), "#6b7076"),
        Body("Grid cleats", lambda: union(grid_cleats(0), grid_cleats(1)), "#a67c52"),
        Body("Grid screws", lambda: grid_screws_ph(), DARK),
    ],
    "Drawer": [
        Body("Drawer front + bin", lambda: drawer_panels(), "#bf9000"),
        Body("Handle + actuator pad", lambda: union(handle_world(), drawer_act_pad()), PRINT),
        Body("Handle + actuator screws", lambda: union(handle_screws_ph(), drawer_actuator_screws_ph()), DARK),
        Body("Drawer actuator key", lambda: drawer_actuator(), METAL),
    ],
}


# the parts of this file as the old pipeline exported them (parts.py): plywood / steel reference models in the
# machine frame, printed parts in their print pose
PARTS = {"base_plate": base_plate,
         "cabinet": lambda: union(cabinet_panels(), drawer_panels()),
         "upper_front": upper_front,
         "grid_mesh": grid_mesh,
         "grid_cleats": lambda: union(grid_cleats(0), grid_cleats(1)),
         "drawer_handle": drawer_handle_print,
         "drawer_pad": drawer_pad_print,
         "drawer_act_pad": drawer_act_pad_print}

PARTS_2D = {"base_plate": base_2d,
            "cabinet_panels": cabinet_2d,
            "grid_mesh": grid_wires_2d,        # the welded mesh (wires at 25.4 pitch); its extent is the CUT SIZE of the sheet
            "grid_cleats": grid_cleats_2d}     # the 8 timber cleat strips (4 lower, 4 upper) with the Ø3 pilots
