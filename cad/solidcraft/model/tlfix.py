"""tlfix.py -- TORQUE-LIMITER SETTING FIXTURE: the TL350-2 on a keyed stub clamped in a vise, a CHAIN WHIP lever with a weight (cad/tlfix.scad).

WHAT IT DOES  The TL350-2 (manufacturer's layout, tl350.py) sits on the Ø25 end of a stub made from the Ø30 bar; the
  Ø30 end (two vise flats, 22 across) is clamped in a vise.  The stub's Ø25 pin CONTINUES beyond the TL's adjusting
  nut (TLFIX_PIN_L); the chain-whip LEVER (flat 50 x 10 x 600) PIVOTS on that pin (Ø25.2 bore) = on the TL axis.
  A short piece of #40 chain is wrapped round the TL's 30T sprocket; both of its ends are bolted to two LUGS (20 x 20)
  that stand on the lever's inner face and reach back to the chain plane, 100 mm from the axis.  A weight hangs from a
  hole 500 mm from the axis:  T = W x 9.81 x 0.5 m + the lever's own moment M_lever, so
  W = (TL_SET_AT_TL - M_lever) / 0.5 / 9.81  (computed below from the lever's geometry).
GEOMETRY  Stub axis = x axis.  The Ø30 shoulder is at x = 0, the vise end runs to +x, the Ø25 pin to -x.  The TL sits
  flange end against the shoulder and runs to -x (nut end at x = -62); its sprocket plate is 12 mm from the flange-end
  face (chain plane x = -12).  The lever is 5 mm beyond the nut, pointing +y, horizontal when the TL starts to slip.

Not translated (picture only): the labels and leader lines (view_xf, label3, tlf_labels), rig() and the BOM echo lines.
"""
from common import *
from tl350 import *

# ---------------------------------------------------------------- numbers
TL_PD = tl_sprocket_pd
TL_R = TL_PD / 2
TL_OD = TL_PD + SPROCKET_OD_EXTRA
G = 9.81
RHO = 7.85e-6                                                        # steel, kg/mm3
ATT_Y = 100                                                          # the two chain-end bolts: 100 from the axis,
ATT_DZ = 15                                                          # +-15 off the lever's centre line
# ---------------------------------------------------------------- stub (Ø25 pin through the TL and on beyond the nut, Ø30 shoulder, vise end)
XS = 0                                                               # shoulder
STUB_DIA = STUB_D - 0.013                                            # h6: 24.987
FIX_PIN_L = TL_L + TLFIX_PIN_L                                       # Ø25 length: TL hub + the pin beyond the nut
X_TIP = XS - FIX_PIN_L
X_END = XS + STUB_END_L
FLAT_X0 = XS + 10
FLAT_X1 = FLAT_X0 + STUB_FLAT_L                                      # vise flats x = 10 .. 50
KEY_W_ = SHAFT_KEY_W
KEY_D_ = SHAFT_KEY_D


def stub_solid():
    return difference(
        union(translate([X_TIP, 0, 0], rotate([0, 90, 0], cylinder(d=STUB_DIA, h=FIX_PIN_L))),      # flush with the shoulder
              translate([XS, 0, 0], rotate([0, 90, 0], cylinder(d=STUB_END_D, h=STUB_END_L)))),
        # two flats, 22 across (facing +-y)
        [translate([FLAT_X0, s * (STUB_FLAT_AF / 2 + 10) - 10, -20], cube([STUB_FLAT_L, 20, 40])) for s in (-1, 1)],
        # keyway 8 x 4 x 56, closed ends: an obround prism along z (the .scad hulls two cylinders)
        translate([0, 0, STUB_DIA / 2 - KEY_D_], linear_extrude(KEY_D_ + 1, hull(
            translate([x, 0], circle(d=KEY_W_)) for x in (XS - TL_L + TL_KEY_END + KEY_W_ / 2, XS - TL_KEY_END - KEY_W_ / 2)))))


# ---------------------------------------------------------------- TL350 on the stub: flange end against the shoulder, running to -x (the layout of tl350.py, mirrored)
TL_X0 = XS
TL_X1 = XS - TL_L                                                    # flange-end face .. nut end
X_CP = XS - TL_CM_OFFSET                                             # chain plane (sprocket mid-plane)


def tl_body_fix():
    return mirror([1, 0, 0], tl350_body_l())


def tl_plate_fix():
    return mirror([1, 0, 0], tl_plate_l())


def tl_fix_ph():
    return union(tl_body_fix(), tl_plate_fix())


def key_ph():
    """8 x 7 x 56 key (placeholder)."""
    return translate([XS - TL_L + TL_KEY_END + 0.05, -KEY_W_ / 2 + 0.05, STUB_DIA / 2 - KEY_D_ + 0.05],
                     cube([TL_L - 2 * TL_KEY_END - 0.1, KEY_W_ - 0.1, 7.5]))


# ---------------------------------------------------------------- lever (pivots on the pin), lugs, chain
LEVER_Y0 = -TEST_LEVER_PIVOT_END
LEVER_Y1 = LEVER_Y0 + TLFIX_LEVER_L                                  # pivot 25 from the short end: y = -25 .. 575, horizontal, +y
LEV_X1 = XS - TL_L - TLFIX_LEVER_GAP
LEV_X0 = LEV_X1 - TLFIX_LEVER_T                                      # lever 5 mm beyond the nut: x = -77 .. -67
LUG_X0 = LEV_X1
LUG_X1 = X_CP - CHAIN_ENV_W / 2 - TLFIX_LUG_GAP                      # lug from the lever's inner face to 2.4 mm off the chain's edge


def lever_holes():
    return [[ATT_Y, ATT_DZ, 6.6], [ATT_Y, -ATT_DZ, 6.6], [TLFIX_ARM, 0, 10.5]]       # (y, z, d): 2 chain bolts, weight


def lever_2d():
    """(y, z) outline, world coordinates."""
    return difference(translate([LEVER_Y0, -TLFIX_LEVER_W / 2], square([TLFIX_LEVER_L, TLFIX_LEVER_W])),
                      circle(d=TLFIX_PIVOT_D),                                         # pivot bore on the Ø25 pin
                      [translate([h[0], h[1]], circle(d=h[2])) for h in lever_holes()])


def lever():
    return axial(LEV_X0, linear_extrude(TLFIX_LEVER_T, lever_2d()))


def lug_part():
    """Part frame: 20 (y) x 20 (z) x length (x) ... exported lying along x."""
    return difference(cube([LUG_X1 - LUG_X0, TLFIX_LUG[0], TLFIX_LUG[1]]),
                      translate([-1, TLFIX_LUG[0] / 2, TLFIX_LUG[1] / 2], rotate([0, 90, 0], cylinder(d=6.6, h=LUG_X1 - LUG_X0 + 2))))


def lugs():
    return union(translate([LUG_X0, ATT_Y - TLFIX_LUG[0] / 2, s * ATT_DZ - TLFIX_LUG[1] / 2], part("TL fixture lug", lug_part()))
                 for s in (-1, 1))


# the lever's own moment about the TL axis (horizontal, weight side +y): lever (with its holes), 2 lugs, 2 M6 bolts, half of each chain tail
CH_KG_MM = 0.41e-3                                                   # #40 chain, kg per mm
LEV_VOL = TLFIX_LEVER_L * TLFIX_LEVER_W * TLFIX_LEVER_T


def disc_v(d):
    return PI * d * d / 4 * TLFIX_LEVER_T


def sum_m(l, i=0):
    return sum(e[0] for e in l[i:])


def sum_my(l, i=0):
    return sum(e[0] * e[1] for e in l[i:])


LEV_M = [[LEV_VOL * RHO, (LEVER_Y0 + LEVER_Y1) / 2],                 # lever blank at its centre
         [-disc_v(TLFIX_PIVOT_D) * RHO, 0], [-2 * disc_v(6.6) * RHO, ATT_Y], [-disc_v(10.5) * RHO, TLFIX_ARM],       # minus the holes
         [2 * (TLFIX_LUG[0] * TLFIX_LUG[1] - PI * 3.3 * 3.3) * (LUG_X1 - LUG_X0) * RHO, ATT_Y],                      # 2 lugs
         [2 * (PI * 9 * (TLFIX_LEVER_T + LUG_X1 - LUG_X0 + 12) + 6 * 6 * 3.5 * 1.1) * RHO, ATT_Y],                   # 2 M6 bolts through lever + lug into the chain end (shank + head)
         [2 * CH_KG_MM * 40, ATT_Y * 0.8]]                           # half of each ~80 mm chain tail hangs on the lever
LEVER_KG = sum_m(LEV_M)
LEVER_NM = G * sum_my(LEV_M) / 1000
W_KG = (TL_SET_AT_TL - LEVER_NM) / (TLFIX_ARM / 1000) / G            # hanging weight
# chain: tangent geometry from the attach points P = (ATT_Y, +-ATT_DZ) to the pitch circle, wrapping the far (-y) side
PD_ = norm([ATT_Y, ATT_DZ])
TG_ANG = atan2(ATT_DZ, ATT_Y) + acos(TL_R / PD_)                     # polar angle of the upper tangent point


def tp(a):
    return [TL_R * cos(a), TL_R * sin(a)]


def chain_wrap2d(grow=0):
    hw = CHAIN_ENV_H / 2 + grow
    fan = [TG_ANG + 4 * i for i in range(int(floor((360 - 2 * TG_ANG) / 4)) + 1)]         # [TG_ANG : 4 : 360 - TG_ANG]
    return union(
        # ring sector from TG_ANG round through 180 deg to -TG_ANG
        intersection(difference(circle(r=TL_R + hw), circle(r=TL_R - hw)),
                     polygon([[0, 0]] + [[200 * cos(a), 200 * sin(a)] for a in fan]
                             + [[200 * cos(360 - TG_ANG), 200 * sin(360 - TG_ANG)]])),
        # the two straight tails
        [hull(translate(tp(s * TG_ANG), circle(r=hw)), translate([ATT_Y, s * ATT_DZ], circle(r=hw))) for s in (-1, 1)])


def chain_fix(grow=0):
    return axial(X_CP - CHAIN_ENV_W / 2 - grow, linear_extrude(CHAIN_ENV_W + 2 * grow, chain_wrap2d(grow)))


CH_ARC = (360 - 2 * TG_ANG) / 360 * PI * TL_PD                       # chain on the sprocket
CH_TAIL = sqrt(PD_ * PD_ - TL_R * TL_R)                              # each free tail
CH_LINKS = ceil((CH_ARC + 2 * CH_TAIL) / CHAIN_pitch)


def chain_bolts_ph():
    """M6 x 70: head on the lever's outer face, shank through lever + lug into the chain's end pins."""
    return union(translate([LEV_X0 - 0.01, ATT_Y, h], rotate([0, 90, 0], rotate([180, 0, 0], part(
        "M6 x 70 chain-end bolt",
        cylinder(d=10, h=4, fn=6),
        rotate([180, 0, 0], cylinder(d=6, h=TLFIX_LEVER_T + (LUG_X1 - LUG_X0) + 12))))))
        for h in (ATT_DZ, -ATT_DZ))


# weight on a shackle through the Ø10.5 hole (steel cylinder of W_KG, Ø150)
WH = W_KG / (7.85e-6 * PI * 75 * 75)


def weight_ph():
    return translate(
        [(LEV_X0 + LEV_X1) / 2, TLFIX_ARM, 0],
        rotate([0, 90, 0], translate([0, 0, -14], cylinder(d=10, h=28))),
        [translate([s * (TLFIX_LEVER_T / 2 + 2.2) - 1.6, -7, -45], cube([3.2, 14, 53])) for s in (-1, 1)],
        translate([-(TLFIX_LEVER_T / 2 + 3.8), -7, -47], cube([TLFIX_LEVER_T + 7.6, 14, 4])),
        translate([0, 0, -150], cylinder(d=8, h=105)),
        translate([0, 0, -150 - WH], cylinder(d=150, h=WH)))


# ---------------------------------------------------------------- vise (placeholder blocks), stand, bench
VISE_TOP = -72
BENCH_Z1 = -200
BENCH_T = 30


def vise_ph():
    return union(
        # jaws 30 thick, faces on the flats
        [translate([FLAT_X0 + 1, STUB_FLAT_AF / 2 if s > 0 else -STUB_FLAT_AF / 2 - 30, -30], cube([STUB_FLAT_L - 2, 30, 40]))
         for s in (-1, 1)],
        translate([FLAT_X0 - 5, -41, VISE_TOP], cube([STUB_FLAT_L + 10, 82, -30 - VISE_TOP])))        # body 50 x 82 x 42


def stand_ph():
    return translate([FLAT_X0 - 5, -45, BENCH_Z1], cube([STUB_FLAT_L + 10, 90, VISE_TOP - BENCH_Z1]))


def bench_ph():
    return translate([-120, -250, BENCH_Z1 - BENCH_T], cube([240, 440, BENCH_T]))      # the weight hangs at y = 500: free of the bench


# ---------------------------------------------------------------- DXF of the stub: side view, top view (flats), both end views, 1:1 mm
def stub_2d():
    L1, L2, r1_, r2 = FIX_PIN_L, STUB_END_L, STUB_DIA / 2, STUB_END_D / 2
    k0, k1 = TLFIX_PIN_L + TL_KEY_END, L1 - TL_KEY_END

    def side():
        return union(translate([0, -r1_], square([L1, 2 * r1_])), translate([L1, -r2], square([L2, 2 * r2])))

    return union(
        difference(side(), translate([k0, r1_ - KEY_D_], square([k1 - k0, KEY_D_ + 1]))),
        translate([0, -50], difference(
            side(),
            [translate([L1 + 10, STUB_FLAT_AF / 2 if s > 0 else -r2 - 1], square([STUB_FLAT_L, r2 - STUB_FLAT_AF / 2 + 1]))
             for s in (-1, 1)])),
        translate([0, -100], difference(
            translate([0, -r1_], square([L1, 2 * r1_])),
            hull(translate([x, 0], circle(d=KEY_W_)) for x in (k0 + KEY_W_ / 2, k1 - KEY_W_ / 2)))),
        translate([L1 + L2 + 45, 0], difference(
            circle(d=STUB_END_D),
            [translate([-20, STUB_FLAT_AF / 2 if s > 0 else -STUB_FLAT_AF / 2 - 20], square([40, 20])) for s in (-1, 1)])),
        translate([L1 + L2 + 45, -50], difference(
            circle(d=STUB_DIA),
            translate([-KEY_W_ / 2, r1_ - KEY_D_], square([KEY_W_, KEY_D_ + 1])))))


# ---------------------------------------------------------------- the made parts, each in its part frame (parts.py)
def stub_part():
    """Part frame: tip at x = 0, axis on the x axis."""
    return translate([-X_TIP, 0, 0], stub_solid())


def lever_part_2d():
    """Part frame: short end at x = 0, the bar in y = 0 .. TLFIX_LEVER_W (the DXF outline)."""
    return translate([-LEVER_Y0, TLFIX_LEVER_W / 2], lever_2d())


def lever_part():
    return linear_extrude(TLFIX_LEVER_T, lever_part_2d())


PARTS = {"tl_stub": stub_part,
         "tl_lever": lever_part,
         "tl_lug": lug_part}
PARTS_2D = {"tl_stub": stub_2d,                                      # the DXF outlines (cad/build.sh `dxf`), 2D trees
            "tl_lever": lever_part_2d}
