"""testlever.py -- BLADE TORQUE TEST LEVER: proves that a mild-steel blade's hex bore takes T_LIMIT (cad/testlever.scad).

SET-UP  The test shaft (the real shaft B) is held in a vise by two hex flats (jaws on the +-y flats).  ONE blade
  (variant 0) sits on the hex next to the drive-side Ø25 journal; the lever turns on that journal (Ø25.2 hole); a Ø12
  hardened dowel pin pressed into the lever bears on the STRAIGHT HOOK FACE of one tooth; TEST_WEIGHT_KG hangs from the
  Ø10.5 hole at TEST_WEIGHT_ARM from the pivot.
TURN DIRECTION  The lever turns OPPOSITE to the blade's cutting rotation: NEGATIVE about +x, its +y end goes DOWN.
ANGLE AT CONTACT  The lever is HORIZONTAL (0 deg, pointing +y) when the pin meets the face.  The tooth tip is at
  TEST_BLADE_ROT = -30 deg; the pin centre is test_pin_psi ahead of it (test_pin_deg) at radius TEST_PIN_R from the
  pivot, so the pin hole is 10.85 mm below the lever centreline.
LEVER  Mild-steel flat 50 x 10, 540 long: pivot Ø25.2 (25 from the end), pin hole Ø12, weight hole Ø10.5 at 500 from
  the pivot.  Part = flat (thickness along z), DXF = outline + 3 holes.

Not translated (picture only): the labels, leaders, dimension line, arrows and the magnified detail inset (view_xf,
tl_label, tl_note, tl_dim, tl_arc_arrow, tl_detail_content, tl_detail, tl_leader, tl_labels), rig() and the echo lines.
"""
from common import *
from blade import blade
from shaft import shaft_local

# ---------------------------------------------------------------- layout (x along the shaft, as on the machine; shaft B drive-side journal at x < hex_x0)
TL_BX0 = hex_x0                                 # blade near face = start of the hex section (1.5), blade x in [1.5, 9.5]
TL_LX1 = TL_BX0 - TEST_BLADE_GAP                # lever face toward the blade (0.5), all of the lever is on the Ø25 journal
TL_LX0 = TL_LX1 - TEST_LEVER_T                  # lever back face (-9.5)
TL_PIN_X0 = TL_LX0                              # pin sits in the lever's full thickness (flush with the back face)
TL_PIN_L = TEST_LEVER_T + TEST_PIN_PROJ         # 19: pin tip at x = 9.5, flush with the blade's far face
TL_VX0 = 24
TL_VX1 = 104                                    # vise jaws grip the hex over x = 24 .. 104 (placeholder)
PIN_YZ = [TEST_PIN_R * cos(test_pin_deg), TEST_PIN_R * sin(test_pin_deg)]          # pin centre in the world (lever at TEST_LEVER_DEG)
PIN_LEVER = [TEST_PIN_R * cos(test_pin_deg - TEST_LEVER_DEG),                      # the same in the lever's own frame
             TEST_PIN_R * sin(test_pin_deg - TEST_LEVER_DEG)]                      # (pivot at the origin, lever along +x)

# ---------------------------------------------------------------- design rules (fail the build, not just the log)
assert abs(norm(PIN_LEVER) - TEST_PIN_R) < 1e-9
assert TEST_LEVER_W / 2 - abs(PIN_LEVER[1]) - TEST_PIN_D / 2 >= 6, "pin hole needs >= 6 mm of steel to the lever edge"
assert TEST_PIN_R - TEST_LEVER_PIVOT_D / 2 - TEST_PIN_D / 2 >= 6, "pin hole needs >= 6 mm of steel to the pivot hole"
TEST_PIN_F_ = T_LIMIT * 1000 / TEST_PIN_R
assert abs(test_pin_F - TEST_PIN_F_) < 0.01
assert abs(test_pin_sigma - TEST_PIN_F_ * (T_BLADE / 2 + 1) * 32 / (PI * pow(TEST_PIN_D, 3))) < 0.01


# ---------------------------------------------------------------- the lever (2D, pivot at the origin, lever along +x)
def lever_2d_p():
    return difference(translate([-TEST_LEVER_PIVOT_END, -TEST_LEVER_W / 2], square([TEST_LEVER_L, TEST_LEVER_W])),
                      circle(d=TEST_LEVER_PIVOT_D),
                      translate(PIN_LEVER, circle(d=TEST_PIN_D)),
                      translate([TEST_WEIGHT_ARM, 0], circle(d=TEST_WEIGHT_HOLE_D)))


def lever_2d():
    """Part frame: end of the bar at x = 0, pivot at x = 25 (the DXF outline)."""
    return translate([TEST_LEVER_PIVOT_END, 0], lever_2d_p())


def lever_flat():
    """The part: flat on z = 0."""
    return linear_extrude(TEST_LEVER_T, lever_2d())


# ---------------------------------------------------------------- the rig (world frame)
def tl_turn(a, *ch):
    """a < 0 turns the lever the way the test loads it (about the shaft axis)."""
    return rotate([a, 0, 0], *ch)


def tl_lever():
    return rotate([TEST_LEVER_DEG, 0, 0], axial(TL_LX0, linear_extrude(TEST_LEVER_T, lever_2d_p())))


def tl_pin(grow=0):
    return translate([TL_PIN_X0, PIN_YZ[0], PIN_YZ[1]], rotate([0, 90, 0], cylinder(d=TEST_PIN_D + 2 * grow, h=TL_PIN_L)))


def tl_blade():
    return axial(TL_BX0, rotate([0, 0, TEST_BLADE_ROT], blade(0)))


def tl_shaft():
    """Hex vertex under every tooth tip; flats face +-y."""
    return rotate([TEST_BLADE_ROT, 0, 0], shaft_local("B"))


def tl_vise_ph():
    """Jaws on the +-y flats, body under them."""
    return union(
        [translate([TL_VX0, HEX_AF / 2 if s > 0 else -HEX_AF / 2 - 30, -35], cube([TL_VX1 - TL_VX0, 30, 50])) for s in (-1, 1)],
        translate([TL_VX0 - 5, -60, -85], cube([TL_VX1 - TL_VX0 + 10, 120, 50])))


def tl_face_probe():
    """The straight hook face of tooth 0 (tip at TEST_BLADE_ROT): a strip 1 mm deep on the material side, along the face only."""
    h = HOOK_DEG
    nrm = [-sin(h), cos(h)]
    tip = [R_TIP, 0]
    e = [tip[0] - hook_face_len * cos(h), tip[1] - hook_face_len * sin(h)]
    return axial(TL_BX0 - 1, rotate([0, 0, TEST_BLADE_ROT], linear_extrude(T_BLADE + 2, polygon(
        [tip, e, [e[0] - nrm[0], e[1] - nrm[1]], [tip[0] - nrm[0], tip[1] - nrm[1]]]))))


# weight (steel cylinder of TEST_WEIGHT_KG) on a shackle bolted through the Ø10.5 hole
TL_WH = TEST_WEIGHT_KG / (7.85e-6 * PI * 75 * 75)                             # height of a Ø150 steel cylinder of that mass


def tl_weight_ph():
    return translate(
        [(TL_LX0 + TL_LX1) / 2, TEST_WEIGHT_ARM * cos(TEST_LEVER_DEG), TEST_WEIGHT_ARM * sin(TEST_LEVER_DEG)],
        rotate([0, 90, 0], translate([0, 0, -14], cylinder(d=10, h=28))),                                    # M10 bolt through the hole
        [translate([s * (TEST_LEVER_T / 2 + 2.2) - 1.6, -7, -45], cube([3.2, 14, 53])) for s in (-1, 1)],    # shackle legs
        translate([-(TEST_LEVER_T / 2 + 3.8), -7, -47], cube([TEST_LEVER_T + 7.6, 14, 4])),                  # shackle bow
        translate([0, 0, -150], cylinder(d=8, h=105)),                                                       # rod
        translate([0, 0, -150 - TL_WH], cylinder(d=150, h=TL_WH)))                                           # the TEST_WEIGHT_KG weight


# ---------------------------------------------------------------- the numbers of the build log
LEVER_KG = TEST_LEVER_L * TEST_LEVER_W * TEST_LEVER_T * 7.85e-6
LEVER_NM = LEVER_KG * 9.81 * (TEST_LEVER_L / 2 - TEST_LEVER_PIVOT_END) / 1000                  # the lever's own moment about the pivot (~5)
WEIGHT_NM = TEST_WEIGHT_KG * 9.81 * TEST_WEIGHT_ARM / 1000
TEST_TOTAL_NM = WEIGHT_NM + LEVER_NM                                                          # on the hex bore: must come out at T_LIMIT
assert abs(TEST_TOTAL_NM - T_LIMIT) < 1.0, "TEST_WEIGHT_KG must give T_LIMIT at the hex bore"

# ---------------------------------------------------------------- the made part, in its part frame (parts.py)
PARTS = {"test_lever": lever_flat}
PARTS_2D = {"test_lever": lever_2d}                                  # the DXF outline (cad/build.sh `dxf`), a 2D tree
