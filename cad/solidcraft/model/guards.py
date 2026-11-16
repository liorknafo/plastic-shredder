"""guards.py -- DRIVE-END GUARD (gear band + hood), free-end cover: printed, PETG (cad/guards.scad).  World frame.

(The side skirts under the combs are gone: the fixed screen's wings close that space.  The chain and its guard are
gone too: pin coupling.)
DRIVE-END GUARD  three printed parts (they fit the MK3S, 250 x 210 x 210):
    gear_band the two-lobe tube round both gears, CAPTURED between the drive cap's outer face and the outboard plate's
              gear-side face (0.3 mm each end), located by C-shaped ears that hug the inner face and the ends of the 2
              pillars (0.3 mm).  Fitted before the outboard plate.
    the HOOD  a closed can round shaft A's drive end (the TL350, its sprocket plate, the pins and the pin flange's disc),
              its end wall on the OUTBOARD plate's outer face (X_HOOD), its outer end wall round the pin flange's hub,
              which a tube carries on to the gearbox housing face (the housing closes it); B's sleeve, end cap and M10
              head in their own bulge.  Built as (solid) - (cavity): the cavity is everything that turns grown
              GUARD_CLEAR (3 mm), the wall PRINT_WALL (3 mm).  Split at the horizontal seam through the shaft axes
              (DG_SEAM_Z = 0) into dg_upper and dg_lower: each half has its own 2 x M5 x 12 into ob2 (HOOD_SCREW_PTS)
              and 4 seam ears with M4 x 20 + nuts (dg_ear_pts) on the can's +-y walls.  The 4 long M8 tie screws and
              their hardened washers pass through CLEARANCE pockets: they clamp steel only, never the hood.
FREE-END COVER  3 mm plate on the free cap with the same 4 holes and a hollow bump over each shaft end (collar, thrust
        bearing, crinkle washers, end cap, M10 head, 3 mm clear).
"""
from common import *
from joints import *

L = chamber_L
GW = PRINT_WALL
GC = GUARD_CLEAR
GUARD_FLANGE = 4                                               # hood wings on the outboard plate's outer face, x in [X_HOOD - 4, X_HOOD]
X_HOOD = x_ob_out                                              # the hood butts on the outboard plate's outer face
CAP_R = 15
HEAD_R = 8
SLV_R = GEAR_SPACER_D / 2                                      # 15 (outer sleeve)
GEAR_R = GEAR_module * (GEAR_z + 2) / 2                        # 34
X_CAP_OUT_B = x_sprocket_in - END_WASHER_T
X_HEAD_OUT_B = X_CAP_OUT_B - 10                                # M10 head 10 tall


def cyl_x(y, r, x0, x1, z=0):
    return translate([x0, y, z], rotate([0, 90, 0], cylinder(r=r, h=x1 - x0)))


# ---------------------------------------------------------------- drive-end guard
# stage table of B's rotating parts and A's sleeve outside the outboard plate: [y, r_part, x_inboard, x_outboard]
# (x_inboard > x_outboard); cavity = r_part + GC, x grown GC at the OUTBOARD end only (a stage starting within GC + 0.5
# of the plate runs on to the plate face X_HOOD); solid = cavity grown GW.
DG_STAGES = [
    [shaft_y("A"), SLV_R, X_HOOD + 1, x_spA_in],                          # A's outer sleeve (between the plate and the TL350)
    [shaft_y("B"), SLV_R, X_HOOD + 1, x_sprocket_in],                     # B's outer sleeve (to B's end cap)
    [shaft_y("B"), CAP_R, x_sprocket_in + 0.01, X_CAP_OUT_B],             # B end cap
    [shaft_y("B"), HEAD_R, X_CAP_OUT_B + 0.01, X_HEAD_OUT_B],             # B M10 head
]
# the CAN round A: radius = the biggest turning radius (tooth plate 63.85, flange disc 60, the pins' outer edge 54.5) + GC;
# from the plate face to GC beyond the flange disc's back
DG_R = max(SPA_OD_ / 2, PF_D / 2, PIN_R + PIN_D / 2) + GC
DG_X_OUT = PF_X1 - GC                                          # the can's cavity ends here (outboard)
DG_HUB_R = PF_HUB_D / 2 + GC                                   # the tube round the flange's hub and the spacer, on to the housing face
DG_END_X0 = GB_X1 + 0.01                                       # ... ends 0.01 off the housing face (the housing closes it)
assert DG_END_X0 < DG_X_OUT - GW, "the hub tube must reach out of the can"
TIE_HEAD_X = X_HOOD - 1.6 * TIE_WASHERS - 8                    # outer end of the M8 socket heads
TIE_POCKET_R = [8.5, 7.5]                                      # pocket radius round the washer stack / the head (0.5 / 1 mm clear)


def _stage_x1(st, solid):
    if st[2] > X_HOOD - GC - 0.5:
        return X_HOOD if solid else X_HOOD + 1
    return st[2] + 0.05


def dg_solid():
    return union(
        [cyl_x(st[0], st[1] + GC + GW, st[3] - GC - GW, _stage_x1(st, True)) for st in DG_STAGES],
        cyl_x(YA, DG_R + GW, DG_X_OUT - GW, X_HOOD),                                   # the can (its plate-side end wall = the wing thickness)
        cyl_x(YA, DG_HUB_R + GW, DG_END_X0, DG_X_OUT - GW + 0.01),                     # the hub tube
        [translate([X_HOOD - GUARD_FLANGE, 62 if s > 0 else -OB_L / 2, -35], cube([GUARD_FLANGE, OB_L / 2 - 62, 70]))
         for s in (-1, 1)],                                                            # wings on the outboard plate's outer face
        dg_ears(),
        [cyl_x(p[0], TIE_POCKET_R[0] + GW, TIE_HEAD_X - 1 - GW, X_HOOD, p[1]) for p in guard_hole_yz()])   # bosses round the tie screws' heads


def dg_cavity():
    return union(
        [cyl_x(st[0], st[1] + GC, st[3] - GC, _stage_x1(st, False)) for st in DG_STAGES],
        cyl_x(YA, DG_R, DG_X_OUT, X_HOOD - GUARD_FLANGE),                              # inside the can
        cyl_x(YA, DG_HUB_R, DG_END_X0 - 1, DG_X_OUT + 0.01),                           # inside the hub tube, open to the housing face
        [c for p in guard_hole_yz() for c in (                                         # pockets round the tie screws' washers and heads
            cyl_x(p[0], TIE_POCKET_R[0], X_HOOD - 1.6 * TIE_WASHERS - 0.5, X_HOOD + 1, p[1]),
            cyl_x(p[0], TIE_POCKET_R[1], TIE_HEAD_X - 1, X_HOOD - 1, p[1]))],
        [translate([X_HOOD - 6, p[0], p[1]], rotate([0, 90, 0], cylinder(d=5.5, h=8))) for p in HOOD_SCREW_PTS],   # the hood's own M5 screws into ob2
        dg_ear_holes())


# seam ears on the can's -y and +y walls (outboard of B's bulge), 2 on each side
DG_EAR_L = 12
DG_EAR_W = 16
DG_EAR_XS = [x_spA_in - 12, DG_X_OUT - GW + DG_EAR_L / 2 + 2]


def dg_ear_pts():
    return [[xs, YA + sy * (DG_R + GW + DG_EAR_W / 2 - 0.5)] for xs in DG_EAR_XS for sy in (-1, 1)]


def dg_ears():
    return union(translate([p[0] - DG_EAR_L / 2, p[1] - DG_EAR_W / 2, DG_SEAM_Z - DG_FLANGE_T],
                           cube([DG_EAR_L, DG_EAR_W, 2 * DG_FLANGE_T])) for p in dg_ear_pts())


def dg_hole_pts():
    """M4 holes 2 mm outward of the ear's middle (nut clear of the wall)."""
    return [[p[0], p[1] + (-2 if p[1] < YA else 2)] for p in dg_ear_pts()]


def dg_ear_holes():
    return union(translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 1], cylinder(d=4.5, h=2 * DG_FLANGE_T + 2)) for p in dg_hole_pts())


def dg_whole():
    return difference(dg_solid(), dg_cavity())


DG_BIG = 1000


def dg_upper():
    return intersection(dg_whole(), translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z], cube([DG_BIG, DG_BIG, DG_BIG])))


def dg_lower():
    return intersection(dg_whole(), translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z - DG_BIG], cube([DG_BIG, DG_BIG, DG_BIG])))


def drive_end_guard():
    return union(part("Drive-end hood, upper half", dg_upper()),
                 part("Drive-end hood, lower half", dg_lower()),
                 part("Gear band", gear_band()))


# ---------------------------------------------------------------- the gear band (printed): two lobes round the gears + ears round the pillars
BAND_X0 = x_ob_in + 0.3
BAND_X1 = x_cap_out_drive - 0.3
BAND_R = GEAR_R + GC


def band_lobes_2d(r):
    return union(translate([shaft_y(s), 0], circle(r=r)) for s in ("A", "B"))


def band_2d():
    def ear(sy):                                     # C-ear round the pillar's inner face and its two ends
        y0, h = PILLAR_Y0 - 0.3 - 2.5, PILLAR[1] / 2 + 0.3 + 2.5
        return translate([y0 - 6 if sy > 0 else -(PILLAR_Y0 + PILLAR[0] - 4), -h], square([PILLAR[0] - 4 + 2.8 + 6, 2 * h]))

    return difference(
        union(band_lobes_2d(BAND_R + GW), [ear(sy) for sy in (-1, 1)]),
        band_lobes_2d(BAND_R),
        [translate([PILLAR_Y0 - 0.3 if sy > 0 else -(PILLAR_Y0 + PILLAR[0] + 1), -PILLAR[1] / 2 - 0.3],
                   square([PILLAR[0] + 1.3, PILLAR[1] + 0.6])) for sy in (-1, 1)])            # the pillar + 0.3


def gear_band():
    return axial(BAND_X0, linear_extrude(BAND_X1 - BAND_X0, band_2d()))


def dgseam_shanks():
    """M4 core through both ears."""
    return union(translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 3], cylinder(d=4, h=2 * DG_FLANGE_T + 6)) for p in dg_hole_pts())


def gcap_drive_shanks():
    """M8 tie screw core: wing, plate, standoff Ø9, cap + outer layer tapped Ø6.8 (ends 1 short of the hole bottom)."""
    return union(translate([X_HOOD - 4 + 1, p[0], p[1]], rotate([0, 90, 0], cylinder(d=TIE_D - 1.4, h=-10 - (X_HOOD - 4 + 1) - 2)))
                 for p in guard_hole_yz())


# ---------------------------------------------------------------- free-end cover
XF = L + 30                                                    # free cap outer face
COVER_T = 3
# stages [r_part, x_in, x_out] on each shaft: collar / thrust / crinkle (R23.5), end cap (R15), M10 head (R8)
X_COL_OUT = x_collar_out_free                                  # L + 40
FC_STAGES = [[THRUST_D / 2, XF, X_COL_OUT], [CAP_R, X_COL_OUT + 0.01, X_COL_OUT + END_WASHER_T],
             [HEAD_R, X_COL_OUT + END_WASHER_T + 0.01, X_COL_OUT + END_WASHER_T + 10]]


def free_end_cover():
    return difference(
        union(translate([XF, -85, -35], cube([COVER_T, 170, 70])),
              [cyl_x(y, st[0] + GC + GW, st[1], st[2] + GC + GW) for y in (-C / 2, C / 2) for st in FC_STAGES]),
        [cyl_x(y, st[0] + GC, st[1] - 1, st[2] + GC) for y in (-C / 2, C / 2) for st in FC_STAGES],
        [translate([XF - 1, p[0], p[1]], rotate([0, 90, 0], cylinder(d=TIE_D + 1, h=COVER_T + 2))) for p in guard_hole_yz()])


def tie_hardware(g=0):
    """The tie screws' hardware outside ob2: 3 hardened washers Ø16 x 1.6 + the M8 socket head Ø13 x 8."""
    return union(translate([X_HOOD, p[0], p[1]], rotate([0, -90, 0],
                     cylinder(d=16 + 2 * g, h=1.6 * TIE_WASHERS + g),
                     translate([0, 0, 1.6 * TIE_WASHERS], cylinder(d=13 + 2 * g, h=8 + g)))) for p in guard_hole_yz())


def hood_screw_shanks():
    """M5 core: wing Ø5.5 + ob2 tapped Ø4.2."""
    return union(translate([X_HOOD - 3, p[0], p[1]], rotate([0, 90, 0], cylinder(d=3.9, h=3 + 9))) for p in HOOD_SCREW_PTS)


def gcap_free_shanks():
    return union(translate([XF - 6, p[0], p[1]], rotate([0, 90, 0], cylinder(d=TIE_D - 1.4, h=14))) for p in guard_hole_yz())


# the printed parts of this file in their print pose (parts.py)
PARTS = {
    "dg_upper": lambda: translate([0, 0, -DG_SEAM_Z], dg_upper()),                             # seam face down
    "dg_lower": lambda: translate([0, 0, DG_SEAM_Z], rotate([180, 0, 0], dg_lower())),         # turned over: seam face down
    "free_end_cover": lambda: translate([0, 0, -XF], rotate([0, -90, 0], free_end_cover())),   # plate face down
    "gear_band": lambda: translate([0, 0, -BAND_X0], rotate([0, -90, 0], gear_band())),        # standing on its end
}
