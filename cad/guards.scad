// guards.scad -- DRIVE-END GUARD, free-end cover (printed, PETG).  World frame.
// Export: -D 'part="dg_upper"|"dg_lower"|"free_end_cover"|"gear_band"' (print pose); part="world" = assembled.
// (The side skirts under the combs are gone, 2026-11-15: the fixed screen's wings close that space.  The chain and its guard are gone too: pin coupling.)
// DRIVE-END GUARD  three printed parts (they fit the MK3S, 250 x 210 x 210):
//     gear_band the two-lobe tube round both gears, CAPTURED between the drive cap's outer face and the outboard plate's gear-side face (0.3 mm each end), located
//               by C-shaped ears that hug the inner face and the ends of the 2 pillars (0.3 mm).  Fitted before the outboard plate.
//     the HOOD  a closed can round shaft A's drive end (the TL350, its sprocket plate, the pins and the pin flange's disc), its end wall on the OUTBOARD plate's outer face
//               (X_HOOD), its outer end wall round the pin flange's hub, which a tube carries on to the gearbox housing face (the housing closes it); B's sleeve, end cap and
//               M10 head in their own bulge.  Built as (solid) - (cavity): the cavity is everything that turns grown GUARD_CLEAR (3 mm), the wall PRINT_WALL (3 mm).
//               Split at the horizontal seam through the shaft axes (DG_SEAM_Z = 0) into dg_upper and dg_lower, so it closes round the shafts and the flange after
//               assembly: each half has its own 2 x M5 x 12 into ob2 (HOOD_SCREW_PTS) and 4 seam ears with M4 x 20 + nuts (dg_ear_pts) on the can's +-y walls.
//               The 4 long M8 tie screws (joints.scad guard_hole_yz) and their hardened washers pass through Ø17 CLEARANCE holes: they clamp steel only, never the hood.
// FREE-END COVER  3 mm plate on the free cap with the same 4 holes and a hollow bump over each shaft end (collar, thrust bearing, crinkle washers, end cap, M10 head, 3 mm clear).
include <common.scad>
include <joints.scad>
include <placeholders.scad>

L = chamber_L;
GW = PRINT_WALL;  GC = GUARD_CLEAR;
GUARD_FLANGE = 4;                                              // hood wings on the outboard plate's outer face, x in [X_HOOD - 4, X_HOOD]
X_HOOD = x_ob_out;                                             // the hood butts on the outboard plate's outer face
CAP_R = 15;  HEAD_R = 8;
SLV_R = GEAR_SPACER_D / 2;  GEAR_R = GEAR_module * (GEAR_z + 2) / 2;   // 15 (outer sleeve) / 34
X_CAP_OUT_B = x_sprocket_in - END_WASHER_T;
X_HEAD_OUT_B = X_CAP_OUT_B - 10;                               // M10 head 10 tall

module cyl_x(y, r, x0, x1, fn = 96, z = 0) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = fn);


// ---------------------------------------------------------------- drive-end guard
// stage table of B's rotating parts and A's sleeve outside the outboard plate: [y, r_part, x_inboard, x_outboard]  (x_inboard > x_outboard); cavity = r_part + GC, x grown GC at the
// OUTBOARD end only (a stage starting within GC + 0.5 of the plate runs on to the plate face X_HOOD: B's end cap is only OB_GAP = 2 from it); solid = cavity grown GW.
DG_STAGES = [
    [shaft_y("A"), SLV_R, X_HOOD + 1, x_spA_in],                          // A's outer sleeve (between the plate and the TL350)
    [shaft_y("B"), SLV_R, X_HOOD + 1, x_sprocket_in],                     // B's outer sleeve (to B's end cap)
    [shaft_y("B"), CAP_R, x_sprocket_in + 0.01, X_CAP_OUT_B],             // B end cap
    [shaft_y("B"), HEAD_R, X_CAP_OUT_B + 0.01, X_HEAD_OUT_B]              // B M10 head
];
// the CAN round A: radius = the biggest turning radius (tooth plate 63.85, flange disc 60, the pins' outer edge 54.5) + GC; from the plate face to GC beyond the flange disc's back
DG_R = max(SPA_OD_ / 2, PF_D / 2, PIN_R + PIN_D / 2) + GC;
DG_X_OUT = PF_X1 - GC;                                                     // the can's cavity ends here (outboard)
DG_HUB_R = PF_HUB_D / 2 + GC;                                              // the tube round the flange's hub and the spacer, on to the housing face
DG_END_X0 = GB_X1 + 0.01;                                                  // ... ends 0.01 off the housing face (the housing closes it)
assert(DG_END_X0 < DG_X_OUT - GW, "the hub tube must reach out of the can");
module dg_solid() {
    for (st = DG_STAGES) cyl_x(st[0], st[1] + GC + GW, st[3] - GC - GW, st[2] > X_HOOD - GC - 0.5 ? X_HOOD : st[2] + 0.05);
    cyl_x(YA, DG_R + GW, DG_X_OUT - GW, X_HOOD);                                                                        // the can (its plate-side end wall = the wing thickness)
    cyl_x(YA, DG_HUB_R + GW, DG_END_X0, DG_X_OUT - GW + 0.01);                                                          // the hub tube
    for (s = [-1, 1]) translate([X_HOOD - GUARD_FLANGE, s > 0 ? 62 : -OB_L / 2, -35]) cube([GUARD_FLANGE, OB_L / 2 - 62, 70]);   // wings on the outboard plate's outer face (to its end: room round the Ø9 holes)
    dg_ears();
    for (p = guard_hole_yz()) cyl_x(p[0], TIE_POCKET_R[0] + GW, TIE_HEAD_X - 1 - GW, X_HOOD, 64, p[1]);     // bosses round the tie screws' heads
}
TIE_HEAD_X = X_HOOD - 1.6 * TIE_WASHERS - 8;                                  // outer end of the M8 socket heads
TIE_POCKET_R = [8.5, 7.5];                                                    // pocket radius round the washer stack / the head (0.5 / 1 mm clear)
module dg_cavity() {
    for (st = DG_STAGES) cyl_x(st[0], st[1] + GC, st[3] - GC, st[2] > X_HOOD - GC - 0.5 ? X_HOOD + 1 : st[2] + 0.05);
    cyl_x(YA, DG_R, DG_X_OUT, X_HOOD - GUARD_FLANGE);                                                                    // inside the can
    cyl_x(YA, DG_HUB_R, DG_END_X0 - 1, DG_X_OUT + 0.01);                                                                 // inside the hub tube, open to the housing face
    for (p = guard_hole_yz()) {                                                                                        // pockets round the tie screws' washers and heads: the hood never touches them
        cyl_x(p[0], TIE_POCKET_R[0], X_HOOD - 1.6 * TIE_WASHERS - 0.5, X_HOOD + 1, 64, p[1]);
        cyl_x(p[0], TIE_POCKET_R[1], TIE_HEAD_X - 1, X_HOOD - 1, 64, p[1]);
    }
    for (p = HOOD_SCREW_PTS) translate([X_HOOD - 6, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 5.5, h = 8, $fn = 24);              // the hood's own M5 screws into ob2
    dg_ear_holes();
}
// seam ears on the can's -y and +y walls (outboard of B's bulge), 2 on each side
DG_EAR_L = 12;  DG_EAR_W = 16;
DG_EAR_XS = [x_spA_in - 12, DG_X_OUT - GW + DG_EAR_L / 2 + 2];
function dg_ear_pts() = [for (xs = DG_EAR_XS, sy = [-1, 1]) [xs, YA + sy * (DG_R + GW + DG_EAR_W / 2 - 0.5)]];
module dg_ears() for (p = dg_ear_pts()) translate([p[0] - DG_EAR_L / 2, p[1] - DG_EAR_W / 2, DG_SEAM_Z - DG_FLANGE_T]) cube([DG_EAR_L, DG_EAR_W, 2 * DG_FLANGE_T]);
function dg_hole_pts() = [for (p = dg_ear_pts()) [p[0], p[1] + (p[1] < YA ? -2 : 2)]];        // M4 holes 2 mm outward of the ear's middle (nut clear of the wall)
module dg_ear_holes() for (p = dg_hole_pts()) translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 1]) cylinder(d = 4.5, h = 2 * DG_FLANGE_T + 2, $fn = 24);
module dg_whole() difference() { dg_solid(); dg_cavity(); }
DG_BIG = 1000;
module dg_upper() intersection() { dg_whole(); translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z]) cube([DG_BIG, DG_BIG, DG_BIG]); }
module dg_lower() intersection() { dg_whole(); translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z - DG_BIG]) cube([DG_BIG, DG_BIG, DG_BIG]); }
module drive_end_guard() { dg_upper(); dg_lower(); gear_band(); }
// ---------------------------------------------------------------- the gear band (printed): two lobes round the gears + ears round the 4 standoffs
BAND_X0 = x_ob_in + 0.3;  BAND_X1 = x_cap_out_drive - 0.3;  BAND_R = GEAR_R + GC;
module band_lobes_2d(r) for (s = ["A", "B"]) translate([shaft_y(s), 0]) circle(r = r, $fn = 96);
module band_2d() difference() {
    union() {
        band_lobes_2d(BAND_R + GW);
        for (sy = [-1, 1]) let (y0 = PILLAR_Y0 - 0.3 - 2.5, h = PILLAR[1] / 2 + 0.3 + 2.5)      // C-ear round the pillar's inner face and its two ends
            translate([sy > 0 ? y0 - 6 : -(PILLAR_Y0 + PILLAR[0] - 4), -h]) square([PILLAR[0] - 4 + 2.8 + 6, 2 * h]);
    }
    band_lobes_2d(BAND_R);
    for (sy = [-1, 1]) translate([sy > 0 ? PILLAR_Y0 - 0.3 : -(PILLAR_Y0 + PILLAR[0] + 1), -PILLAR[1] / 2 - 0.3]) square([PILLAR[0] + 1.3, PILLAR[1] + 0.6]);   // the pillar + 0.3
}
module gear_band() axial(BAND_X0) linear_extrude(BAND_X1 - BAND_X0) band_2d();
module dgseam_shanks() for (p = dg_hole_pts()) translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 3]) cylinder(d = 4, h = 2 * DG_FLANGE_T + 6, $fn = 16);       // M4 core through both ears
module gcap_drive_shanks() for (p = guard_hole_yz()) translate([X_HOOD - 4 + 1, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = TIE_D - 1.4, h = -10 - (X_HOOD - 4 + 1) - 2, $fn = 16);   // M8 tie screw core: wing, plate, standoff Ø9, cap + outer layer tapped Ø6.8 (ends 1 short of the hole bottom)
function dg_box_(z0, z1) = [[DG_END_X0, YA - DG_R - GW - DG_EAR_W, z0], [X_HOOD - DG_END_X0, OB_L / 2 - (YA - DG_R - GW - DG_EAR_W), z1 - z0]];   // x, y, z: bbox (C5 shrink)
function dg_upper_box() = dg_box_(DG_SEAM_Z, DG_SEAM_Z + DG_R + GW);
function dg_lower_box() = dg_box_(DG_SEAM_Z - DG_R - GW, DG_SEAM_Z);

// ---------------------------------------------------------------- free-end cover
XF = L + 30;                                                   // free cap outer face
COVER_T = 3;
// stages [r_part, x_in, x_out] on each shaft: collar/thrust/crinkle (R23.5), end cap (R15), M10 head (R8)
X_COL_OUT = x_collar_out_free;                                 // L + 40
FC_STAGES = [[THRUST_D / 2, XF, X_COL_OUT], [CAP_R, X_COL_OUT + 0.01, X_COL_OUT + END_WASHER_T], [HEAD_R, X_COL_OUT + END_WASHER_T + 0.01, X_COL_OUT + END_WASHER_T + 10]];
module free_end_cover() {
    $fn = 64;
    difference() {
        union() {
            translate([XF, -85, -35]) cube([COVER_T, 170, 70]);
            for (y = [-C / 2, C / 2], st = FC_STAGES) cyl_x(y, st[0] + GC + GW, st[1], st[2] + GC + GW, 64);
        }
        for (y = [-C / 2, C / 2], st = FC_STAGES) cyl_x(y, st[0] + GC, st[1] - 1, st[2] + GC, 64);
        for (p = guard_hole_yz()) translate([XF - 1, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = TIE_D + 1, h = COVER_T + 2, $fn = 32);
    }
}
// the tie screws' hardware outside ob2: 3 hardened washers Ø16 x 1.6 + the M8 socket head Ø13 x 8 (checks: the hood must not touch it)
module tie_hardware(g = 0) for (p = guard_hole_yz()) translate([X_HOOD, p[0], p[1]]) rotate([0, -90, 0]) {
    cylinder(d = 16 + 2 * g, h = 1.6 * TIE_WASHERS + g, $fn = 48);
    translate([0, 0, 1.6 * TIE_WASHERS]) cylinder(d = 13 + 2 * g, h = 8 + g, $fn = 48);
}
module hood_screw_shanks() for (p = HOOD_SCREW_PTS) translate([X_HOOD - 3, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 3.9, h = 3 + 9, $fn = 16);   // M5 core: wing Ø5.5 + ob2 tapped Ø4.2
module gcap_free_shanks() for (p = guard_hole_yz()) translate([XF - 6, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = TIE_D - 1.4, h = 14, $fn = 16);

part = "world";
if (part == "dg_upper") translate([0, 0, -DG_SEAM_Z]) dg_upper();                                    // seam face down
else if (part == "dg_lower") translate([0, 0, DG_SEAM_Z]) rotate([180, 0, 0]) dg_lower();                // turned over: seam face down
else if (part == "free_end_cover") translate([0, 0, -XF]) rotate([0, -90, 0]) free_end_cover();         // plate face down
else if (part == "gear_band") translate([0, 0, -BAND_X0]) rotate([0, -90, 0]) translate([0, 0, 0]) gear_band();   // standing on its end (every layer is the same profile)
else if (part == "world") { drive_end_guard(); free_end_cover(); }
