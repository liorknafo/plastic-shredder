// comb.scad -- stripper comb (10 thick bar, slotted for that shaft's blades). World frame (see common.scad).
include <common.scad>

COMB_T = 10;
SLOT_Y_END = comb_slot_bottom_y;         // 67: 3 mm past the blade tip (clears the R3 cutter corners)
COMB_END_HOLE_D = 5;   COMB_END_HOLE_L = 15;   // M6 tapped, both end faces
COMB_THRU_D = 5.5;                                 // wall-screw through holes (vertical)
COMB_THRU_X = [20, chamber_L / 2, chamber_L - 20];

module comb(sh = "B") {
    $fn = 48;
    s = shaft_sign(sh);                         // +1 = B side (+y), -1 = A side (-y)
    lo = comb_y_lo(sh);
    difference() {
        translate([0, lo, -COMB_T / 2]) cube([chamber_L, COMB_W, COMB_T]);
        // one slot per blade of this shaft, from the edge facing the shaft out to |y| = 65
        for (k = [0 : N_BLADES - 1]) {
            xc = blade_xc(sh, k);
            ya = s * (comb_edge_y - 1);          // starts 1 mm inside the edge (cutter overshoot)
            yb = s * SLOT_Y_END;
            // a slot ending within 1 mm of a comb end runs out through that end (no sliver)
            x0 = xc - comb_slot_w / 2 < 1 ? -1 : xc - comb_slot_w / 2;
            x1 = xc + comb_slot_w / 2 > chamber_L - 1 ? chamber_L + 1 : xc + comb_slot_w / 2;
            translate([x0, min(ya, yb), -COMB_T / 2 - 1])
                cube([x1 - x0, abs(yb - ya), COMB_T + 2]);
        }
        // M6 tapped holes into both end faces at |y| = COMB_SCREW_Y, z = 0
        translate([-1, s * COMB_SCREW_Y, 0]) rotate([0, 90, 0]) cylinder(d = COMB_END_HOLE_D, h = COMB_END_HOLE_L + 1);
        translate([chamber_L - COMB_END_HOLE_L, s * COMB_SCREW_Y, 0]) rotate([0, 90, 0]) cylinder(d = COMB_END_HOLE_D, h = COMB_END_HOLE_L + 1);
        // M4 tapped holes up into the underside (lower side skirt), 8 deep
        for (x = COMB_THRU_X) translate([x, s * SKIRT_HOLE_Y, -COMB_T / 2 - 1]) cylinder(d = 3.3, h = SKIRT_HOLE_DEPTH + 1);
        // vertical wall-screw holes at |y| = 71
        for (x = COMB_THRU_X) translate([x, s * 71, -COMB_T / 2 - 1]) cylinder(d = COMB_THRU_D, h = COMB_T + 2);
    }
}

// Part frame for export: lying flat, x along the length, y = 0 at the bar edge on the -y side, z in [0, 10].
module comb_part(sh = "B") translate([0, -comb_y_lo(sh), COMB_T / 2]) comb(sh);

// standalone: -D 'sh="A"' ; -D flat=true gives the 2D top-view outline (for DXF)
sh = "B";
flat = false;
if (flat) projection() comb_part(sh); else comb_part(sh);
