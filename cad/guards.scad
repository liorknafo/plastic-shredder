// guards.scad -- lower side skirts, DRIVE-END GUARD (+ chain guard), free-end cover (printed, PETG).  World frame.
// Export: -D 'part="skirt_A"|"skirt_B"|"dg_upper"|"dg_lower"|"free_end_cover"' (print pose); part="world" = assembled.
//
// SKIRT   closes |y| 80.5..85 below the comb (z -35..-5) over the chamber length x 0..chamber_L.  An L: the wall plus a 4 mm flange under the comb,
//         3 x M4 x 12 into the tapped holes in the comb underside (|y| = SKIRT_HOLE_Y).
// DRIVE-END GUARD  one printed shell, built as (solid) - (cavity) from a stage table, in two parts that fit the MK3S (250 x 210 x 210) and bolt together at the seam z = DG_SEAM_Z:
//     dg_upper  the hood round both gears, B's end cap + M10 head, A's sprocket (hub, tooth plate) + end cap + head, and the top of the CHAIN TUBE;
//               two wings on the drive cap face (4 x M5 into the cap, joints.scad guard_hole_yz) carry the whole guard
//     dg_lower  the rest of the CHAIN TUBE (the run down to the TL350), the TL TUBE from the gearbox housing face (the housing closes it) over the whole TL350, the stop
//               collar and the shaft end (closed 3 mm beyond them), the bump for the idler's nut, a window in the +y wall for the tensioner's head plate.
//     The cavity is everything that moves, grown by GUARD_CLEAR (3 mm) in every direction; the wall is PRINT_WALL (3 mm) outside it.  The chain tube cavity is the hull of
//     the three pitch circles (A, TL, idler at both ends of its slot) grown by half the link height + 3.  Seam: four 12 x 24 x 4 ears (2 on the back wall, 2 on the front wall),
//     2 x M4 x 20 + nuts... see dg_ear_pts().
// FREE-END COVER  3 mm plate on the free cap with the same 4 holes and a hollow bump over each shaft end (collar, thrust bearing, crinkle washers, end cap, M10 head, 3 mm clear).
include <common.scad>
include <joints.scad>
include <placeholders.scad>

L = chamber_L;
GW = PRINT_WALL;  GC = GUARD_CLEAR;
GUARD_FLANGE = 4;                                              // wings on the cap face, x in [-34, -30]
CAP_R = 15;  HEAD_R = 8;
HUB_A_R = SPROCKET_A_hub_D / 2;  HUB_G_R = GEAR_SPACER_D / 2;  GEAR_R = GEAR_module * (GEAR_z + 2) / 2;   // 19.5 / 18 / 31.5 (gear spacer sleeve)
X_CAP_OUT_A = x_sprocket_out - END_WASHER_T;                   // outer face of A's end cap
X_CAP_OUT_B = x_gear_hub_out - END_WASHER_T;
X_HEAD_OUT_A = X_CAP_OUT_A - 10;  X_HEAD_OUT_B = X_CAP_OUT_B - 10;     // M10 head 10 tall

module cyl_x(y, r, x0, x1, fn = 96, z = 0) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = fn);

module skirt_B() {
    difference() {
        union() {
            translate([0, 80.5, -35]) cube([L, 4.5, 30]);
            translate([0, 73, -9]) cube([L, 12, 4]);
        }
        for (x = [20, L / 2, L - 20]) translate([x, SKIRT_HOLE_Y, -10]) cylinder(d = 4.5, h = 6, $fn = 32);
    }
}
module skirt(sgn) mirror([0, sgn < 0 ? 1 : 0, 0]) skirt_B();

// ---------------------------------------------------------------- drive-end guard
// stage table of the rotating parts: [y, r_part, x_inboard, x_outboard]  (x_inboard > x_outboard); cavity = r_part + GC, x grown GC at the OUTBOARD end only
// (inboard it runs on to the cap face); solid = cavity grown GW.
DG_STAGES = [
    for (s = ["A", "B"]) each [
        [shaft_y(s), GEAR_R, -29, x_gear_out],                            // gear (4 layers; and the collar / thrust bearing inside)
        [shaft_y(s), HUB_G_R, x_gear_out + 0.01, x_gear_hub_out],         // gear spacer sleeve
    ],
    [shaft_y("B"), CAP_R, x_gear_hub_out + 0.01, X_CAP_OUT_B],            // B end cap
    [shaft_y("B"), HEAD_R, X_CAP_OUT_B + 0.01, X_HEAD_OUT_B],             // B M10 head
    [shaft_y("A"), HUB_A_R, x_gear_hub_out + 0.01, x_sprocket_out],       // sprocket A hub (the tooth plate is inside the chain tube)
    [shaft_y("A"), CAP_R, x_sprocket_out + 0.01, X_CAP_OUT_A],            // A end cap
    [shaft_y("A"), HEAD_R, X_CAP_OUT_A + 0.01, X_HEAD_OUT_A]              // A M10 head
];
// chain tube (x range of the cavity) and the TL tube
DG_CT_X0 = X_CHAIN - CHAIN_ENV_W / 2 - GC;  DG_CT_X1 = max(GUARD_FRONT_X, TENS_HEAD_X1 + GC + 0.2);     // -116.8 .. -70 (the front wall stays 3 mm clear of the idler bolt head when the sprocket hub is longer)
DG_TL_XE = OUT_X1 + GC;                                                     // TL tube cavity ends here (3 mm beyond the shaft end / stop collar)
DG_TL_R = TL_D / 2 + GC;
DG_BOT = ZO - (RT + CHAIN_ENV_H / 2 + GC + GW);                              // underside of the chain tube round the TL sprocket
DG_END_X0 = DG_CT_X0 - GW;                                                 // back face of the chain tube's 3 mm back wall = the housing face (the housing closes the TL tube; they touch)
assert(DG_END_X0 >= GB_X1 - 1e-6, "the guard's back wall must not enter the gearbox housing");
DG_NUT_X0 = TL_PL0 - 0.5 - 1.6 - 8 - 3 - GC;                              // bump for the idler's washer / nut / bolt end (they stick out behind the chain tube)

module dg_solid() {
    for (st = DG_STAGES) cyl_x(st[0], st[1] + GC + GW, st[3] - GC - GW, st[2] > -29.5 ? -30 : st[2] + 0.05);
    axial(DG_END_X0) linear_extrude(DG_CT_X1 + GW - DG_END_X0) chain_hull2d(GC + GW);                              // chain tube (hull of A, TL, idler); back wall on the housing face
    cyl_x(YA, DG_TL_R + GW, DG_END_X0, DG_TL_XE + GW, 96, ZO);                                                       // TL tube over the whole TL350, collar and shaft end
    axial(DG_NUT_X0 - GW) linear_extrude(DG_CT_X0 - DG_NUT_X0 + GW + 0.02) hull() for (t = [-TENS_TRAVEL, TENS_TRAVEL]) translate([tens_y(t), TENS_Z]) circle(r = TENS_WASHER_D / 2 + GC + GW, $fn = 48);   // idler nut bump
    for (s = [-1, 1]) translate([-30 - GUARD_FLANGE, s > 0 ? 62 : -85, -35]) cube([GUARD_FLANGE, 23, 70]);          // wings on the cap face
    dg_ears();
}
module dg_cavity() {
    for (st = DG_STAGES) cyl_x(st[0], st[1] + GC, st[3] - GC, st[2] > -29.5 ? -29 : st[2] + 0.05);
    axial(DG_CT_X0) linear_extrude(DG_CT_X1 - DG_CT_X0) chain_hull2d(GC);
    cyl_x(YA, DG_TL_R, DG_END_X0 - 1, DG_TL_XE, 96, ZO);                                                              // TL tube cavity, open to the housing face
    axial(DG_NUT_X0) linear_extrude(DG_CT_X0 - DG_NUT_X0 + 0.02) hull() for (t = [-TENS_TRAVEL, TENS_TRAVEL]) translate([tens_y(t), TENS_Z]) circle(r = TENS_WASHER_D / 2 + GC, $fn = 48);
    for (p = guard_hole_yz()) translate([-36, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 5.5, h = 8, $fn = 32);
    // window for the tensioner's head plate through the +y wall, 3 mm all round it (the column stands outside the guard)
    translate([TENS_UP_X0 - GC, 0, TENS_HEAD_Z0 - GC]) cube([TENS_T + 2 * GC, TENS_COL_Y0 + 2, TENS_UP_Z1 - TENS_HEAD_Z0 + 2 * GC]);
    dg_ear_holes();
}
// seam ears: on the back wall (outer face x = DG_CT_X0 - GW) and on the front wall (outer face x = DG_CT_X1 + GW)
DG_EAR_L = 12;  DG_EAR_W = 16;
function dg_ear_pts() = [for (xs = [DG_CT_X0 - GW - DG_EAR_L / 2, DG_CT_X1 + GW + DG_EAR_L / 2], yy = [YA - 46, YA - 24]) [xs, yy]];     // on the -y half of the walls (the idler nut bump is on the +y side of the seam)
module dg_ears() for (p = dg_ear_pts()) translate([p[0] - DG_EAR_L / 2 + (p[0] < X_CHAIN ? 0.5 : -0.5), p[1] - DG_EAR_W / 2, DG_SEAM_Z - DG_FLANGE_T]) cube([DG_EAR_L, DG_EAR_W, 2 * DG_FLANGE_T]);
module dg_ear_holes() for (p = dg_ear_pts()) translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 1]) cylinder(d = 4.5, h = 2 * DG_FLANGE_T + 2, $fn = 24);
module dg_whole() difference() { dg_solid(); dg_cavity(); }
DG_BIG = 1000;
module dg_upper() intersection() { dg_whole(); translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z]) cube([DG_BIG, DG_BIG, DG_BIG]); }
module dg_lower() intersection() { dg_whole(); translate([-DG_BIG / 2, -DG_BIG / 2, DG_SEAM_Z - DG_BIG]) cube([DG_BIG, DG_BIG, DG_BIG]); }
module drive_end_guard() { dg_upper(); dg_lower(); }
function dg_ear_shank_pts() = dg_ear_pts();
module dgseam_shanks() for (p = dg_ear_pts()) translate([p[0], p[1], DG_SEAM_Z - DG_FLANGE_T - 3]) cylinder(d = 4, h = 2 * DG_FLANGE_T + 6, $fn = 16);       // M4 core through both ears
module gcap_drive_shanks() for (p = guard_hole_yz()) translate([-36, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 4, h = 14, $fn = 16);                    // M5 core: guard Ø5.5 + cap tapped Ø4.2
function dg_upper_box() = [[X_HEAD_OUT_A - GC - GW, -85, DG_SEAM_Z], [-30 - (X_HEAD_OUT_A - GC - GW), 170, 40 - DG_SEAM_Z]];     // x, y, z: bbox of the upper part (C5 shrink)
function dg_lower_box() = let (x0 = DG_CT_X0 - GW - DG_EAR_L, x1 = DG_TL_XE + GW) [[x0, YA - 80, DG_BOT], [x1 - x0, 160, DG_SEAM_Z - DG_BOT]];

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
        for (p = guard_hole_yz()) translate([XF - 1, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 5.5, h = COVER_T + 2, $fn = 32);
    }
}
module gcap_free_shanks() for (p = guard_hole_yz()) translate([XF - 6, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = 4, h = 14, $fn = 16);

part = "world";
if (part == "skirt_B") translate([0, 35, 85]) rotate([-90, 0, 0]) skirt_B();                              // outer face down
else if (part == "skirt_A") translate([L, 0, 0]) mirror([1, 0, 0]) translate([0, 35, 85]) rotate([-90, 0, 0]) skirt_B();   // mirror image of B
else if (part == "dg_upper") translate([0, 0, -DG_SEAM_Z]) dg_upper();                                    // seam face down
else if (part == "dg_lower") translate([0, 0, DG_SEAM_Z]) rotate([180, 0, 0]) dg_lower();                // turned over: seam face down
else if (part == "free_end_cover") translate([0, 0, -XF]) rotate([0, -90, 0]) free_end_cover();         // plate face down
else if (part == "world") { skirt(1); skirt(-1); drive_end_guard(); free_end_cover(); }
