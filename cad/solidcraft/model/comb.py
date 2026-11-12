"""comb.py -- stripper comb: 10 thick bar, slotted for that shaft's blades (cad/comb.scad).  World frame (see common.py)."""
from common import *

COMB_T = 10
SLOT_Y_END = comb_slot_bottom_y          # 67: 3 mm past the blade tip (clears the R3 cutter corners)
COMB_END_HOLE_D = 5                      # M6 tapped, both end faces
COMB_END_HOLE_L = 15
COMB_THRU_D = 5.5                        # wall-screw through holes (vertical)
COMB_THRU_X = [20, chamber_L / 2, chamber_L - 20]


def comb(sh="B"):
    s = shaft_sign(sh)                   # +1 = B side (+y), -1 = A side (-y)
    lo = comb_y_lo(sh)

    def slot(k):
        """One slot per blade of this shaft, from the edge facing the shaft out to |y| = SLOT_Y_END."""
        xc = blade_xc(sh, k)
        ya = s * (comb_edge_y - 1)       # starts 1 mm inside the edge (cutter overshoot)
        yb = s * SLOT_Y_END
        # a slot ending within 1 mm of a comb end runs out through that end (no sliver)
        x0 = -1 if xc - comb_slot_w / 2 < 1 else xc - comb_slot_w / 2
        x1 = chamber_L + 1 if xc + comb_slot_w / 2 > chamber_L - 1 else xc + comb_slot_w / 2
        return translate([x0, min(ya, yb), -COMB_T / 2 - 1], cube([x1 - x0, abs(yb - ya), COMB_T + 2]))

    return difference(
        translate([0, lo, -COMB_T / 2], cube([chamber_L, COMB_W, COMB_T])),
        [slot(k) for k in range(N_BLADES)],
        # M6 tapped holes into both end faces at |y| = COMB_SCREW_Y, z = 0
        translate([-1, s * COMB_SCREW_Y, 0], rotate([0, 90, 0], cylinder(d=COMB_END_HOLE_D, h=COMB_END_HOLE_L + 1))),
        translate([chamber_L - COMB_END_HOLE_L, s * COMB_SCREW_Y, 0], rotate([0, 90, 0], cylinder(d=COMB_END_HOLE_D, h=COMB_END_HOLE_L + 1))),
        # M4 tapped holes up into the underside (lower side skirt), 8 deep
        [translate([x, s * SKIRT_HOLE_Y, -COMB_T / 2 - 1], cylinder(d=3.3, h=SKIRT_HOLE_DEPTH + 1)) for x in COMB_THRU_X],
        # vertical wall-screw holes at |y| = 71
        [translate([x, s * 71, -COMB_T / 2 - 1], cylinder(d=COMB_THRU_D, h=COMB_T + 2)) for x in COMB_THRU_X])


def comb_part(sh="B"):
    """Part frame for export: lying flat, x along the length, y = 0 at the bar edge on the -y side, z in [0, 10]."""
    return translate([0, -comb_y_lo(sh), COMB_T / 2], comb(sh))


PARTS = {"comb_A": lambda: comb_part("A"), "comb_B": lambda: comb_part("B")}

PARTS_2D = {"comb_A": lambda: comb_part("A")}  # top view of the bar lying flat
