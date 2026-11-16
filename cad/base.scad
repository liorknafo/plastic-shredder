// base.scad -- 18 mm plywood base plate, the bin cabinet below it, the drawer with its printed pull handle, and the FIXED SCREEN under the blades.  World frame.
//   -D 'part="base_plate"|"cabinet"|"base_2d"|"cabinet_2d"|"drawer_handle"|"screen"|"screen_2d"|"bom"|"world"'
//
// ONE SOURCE FOR 3D AND DXF.  Every plywood panel is a 2D module (p_*_2d, base_2d) in its own (u, v) frame.  The 3D part extrudes that
//   module and the DXF sheet (cabinet_2d, base_2d) uses the same module, so the drawing and the model cannot diverge.
//
// SCREEN (2026-11-15: replaces the vibrating screen, the wire-mesh grid, the fixed upper front panel, the drawer switch and the side skirts)
//   One aluminium block (6061 / 6082) machined on the CNC4030, x SCREEN_END_GAP .. chamber_L - SCREEN_END_GAP.  Its cross-section (y, z) is a "W":
//     top     two arcs R_TIP + SCREEN_GAP (36) round the shaft axes, meeting in a ridge between the shafts (y = 0, z = -19.9) and rising on the outer sides to the
//             combs' underside (z = -5) at |y| = 65.6; from there flat WINGS against the combs out to the combs' outer edge (|y| = 80.5);
//     bottom  FLAT at z = -(R_TIP + SCREEN_GAP + SCREEN_T) = -46 (inside the base plate's cut-out); each hole relieved Ø SCREEN_RELIEF_D from below so its Ø5 land is SCREEN_T.
//   Holes Ø5 (SCREEN_HOLE_D) on an 8 mm hex pattern (SCREEN_HOLE_PITCH), drilled vertically (z, up from the flat bottom) where the top is no steeper than
//   SCREEN_HOLE_SLOPE (50 deg): 14 rows, hole centres |y| 6.9 .. 48.5.  Fines fall through into the drawer bin; oversize stays and the teeth drag it round to the combs and back into the bite.
//   Held by 4 x M4 x 16 socket screws from BELOW (counterbores in the wings) into tapped holes in the combs' underside (|y| = SCREEN_SCREW_Y, x = L/3, 2L/3).
//   Pockets in the wing tops clear the M5 heads of the wall screws (|y| = 71, x = 20, L/2, L-20).  The base plate's cut-out is |y| <= BASE_CUT_Y (83), so with the
//   drawer out the 4 screws are reached from below and the screen drops out for cleaning.
//   The screen is the guard from below: round openings 4 < e <= 6 need >= 5 mm to the hazard (ISO 13857 Table 4); every hole is >= 8 long + the 2 mm gap.
// BASE   the shredder box sits on it at z = -35 on 8 M6 feet (y = +-65, in the bottom edges of the inner and outer layers; slots +-2 mm in x).
// CABINET  under the base, x -30 .. chamber_L+30, y -110 .. 110: two sides, back, floor (18 mm ply); the side panels hang on 6 screws through the base plate.
//   The drawer (full-height front + 10 mm ply bin) slides in from the front (-y).  The cabinet is only a dust box now: nothing in it can reach the blades
//   (the screen is screwed on, a tool is needed to remove it).
include <common.scad>
include <joints.scad>

BASE_NX = -30;  BASE_X0 = BASE_NX;  BASE_X1 = chamber_L + 30 + 40;
BASE_Y0 = -115;  BASE_Y1 = 110;
BASE_Z1 = -PLATE_H / 2;  BASE_Z0 = BASE_Z1 - BASE_T;
FOOT_SLOT = 2;                                                       // +-2 mm in x   (the 8 foot screws: foot_screw_xy() in joints.scad, shared with plate.scad)

// ---------------- cabinet constants
CAB_X0 = -30;  CAB_X1 = chamber_L + 30;  CAB_T = 18;  CAB_Y0 = -110;  CAB_Y1 = 110;
CAB_ZT = BASE_Z0;                                                    // underside of the base
CAB_FLOOR_TOP = -350;  CAB_ZB = CAB_FLOOR_TOP - CAB_T;               // -368
DR_T = 10;  DR_W = 154;  DR_Y0 = CAB_Y0 + CAB_T;  DR_L = 176;  DR_Z0 = CAB_FLOOR_TOP + 2;
BIN_TOP_CLEAR = 4;                                                   // bin top under the base plate's underside
DR_H = CAB_ZT - BIN_TOP_CLEAR - DR_Z0;                               // 291
DRF_ZT = CAB_ZT - DRF_GAP;                                           // top of the full-height drawer front: 1 mm under the base plate
DRF_H = DRF_ZT - CAB_ZB;
BIN_FLOOR = DR_Z0 + DR_T;
CAB_XC = (CAB_X0 + CAB_X1) / 2;
CAB_W = CAB_X1 - CAB_X0;  CAB_H = CAB_ZT - CAB_ZB;  CAB_SIDE_W = CAB_Y1 - DR_Y0;       // 192.2, 315, 202
HANG_X = [CAB_X0 + CAB_T / 2, CAB_X1 - CAB_T / 2];  HANG_Y = [-80, 0, 80];              // cabinet side panels hang on 6 screws
function hang_screw_xy() = [for (x = HANG_X, y = HANG_Y) [x, y]];                       // the ONE definition: base-plate Ø5 holes AND the pilots in the panel tops
HANG_PILOT_D = 3.3;  HANG_PILOT_DEPTH = 25;                                             // M4 x 45 screws: 18 plywood + 25 into the panel edge
assert(CAB_ZB == GROUND_Z);
assert(HANDLE_Z + HANDLE_H / 2 <= DRF_ZT - 5 && HANDLE_Z - HANDLE_H / 2 >= CAB_ZB + 5, "the pull handle must lie fully on the drawer front");

// ---------------- the SCREEN: constants
SC_RS = R_TIP + SCREEN_GAP;                     // 36: top arcs
SC_RB = SC_RS + SCREEN_T;                       // 46: the flat bottom's depth below the axes
SC_ZT = -5;                                     // the combs' underside (comb.scad: 10 thick, centred on z = 0)
SC_YW = comb_edge_y + COMB_W;                   // 80.5: the wings' outer faces = the combs' outer edges
SC_X0 = SCREEN_END_GAP;  SC_X1 = chamber_L - SCREEN_END_GAP;
SC_ZMIN = -SC_RB;                               // lowest point (under each shaft)
SC_YMEET = C / 2 + sqrt(SC_RS * SC_RS - SC_ZT * SC_ZT);          // 65.65: where the top arc meets the combs' underside
SC_DH = SC_RS * sin(SCREEN_HOLE_SLOPE) - SCREEN_HOLE_D / 2;     // hole centres within this of a shaft axis (in y): the hole stays where the top is <= 50 deg steep
SC_HOLE_XM = 2;                                                  // hole edge >= this from the screen's ends
SCREEN_SCREW_X = [chamber_L / 3, 2 * chamber_L / 3];
WALL_SCREW_X = [20, chamber_L / 2, chamber_L - 20];  WALL_SCREW_Y = 71;
assert(abs(SC_YW - (comb_edge_y + COMB_W)) < 1e-9 && SC_YMEET < comb_slot_bottom_y, "screen: the arc meets the comb underside inside the comb, short of its slot bottoms");
assert(BASE_CUT_Y >= SC_YW + 2 && BASE_CUT_Y <= CAB_Y1 - CAB_T - 5, "base plate cut-out: wider than the screen, inside the cabinet");
assert(SC_ZMIN > CAB_ZT + 5, "the screen's lowest point stays above the base plate's underside");
assert(SCREEN_T + SCREEN_GAP >= 5, "ISO 13857 Table 4: round openings 4 < e <= 6 need >= 5 mm to the hazard");
function sc_top(y) = let (d = abs(y) - C / 2) abs(d) < SC_RS ? min(SC_ZT, -sqrt(SC_RS * SC_RS - d * d)) : SC_ZT;
// hole centres: hex pattern, rows along x (pitch P), rows SCREEN_HOLE_PITCH*sin(60) apart in y, symmetric about y = 0 and centred in x
function screen_holes() = let (P = SCREEN_HOLE_PITCH, dy = P * sin(60), r = SCREEN_HOLE_D / 2,
                               xa = SC_X0 + SC_HOLE_XM + r, xb = SC_X1 - SC_HOLE_XM - r, n0 = floor((xb - xa) / P), x0 = (xa + xb - n0 * P) / 2,
                               nj = floor((C / 2 + SC_DH) / dy))
    [for (j = [-nj : nj]) let (y = j * dy, d = abs(y) - C / 2) if (abs(d) <= SC_DH)
        let (odd = abs(j) % 2 == 1) for (i = [0 : odd ? n0 - 1 : n0]) [x0 + (odd ? P / 2 : 0) + i * P, y]];

// ---------------- 2D outlines: the ONLY definition of each panel (3D parts and DXF both use these)
module base_2d() {
    difference() {
        translate([BASE_X0, BASE_Y0]) square([BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0]);
        translate([0, -BASE_CUT_Y]) square([chamber_L, 2 * BASE_CUT_Y]);                       // cut-out under the chamber: the screen and its screws, from below
        for (p = foot_screw_xy()) hull() for (dx = [-FOOT_SLOT, FOOT_SLOT]) translate([p[0] + dx, p[1]]) circle(d = 6.6, $fn = 32);   // M6 feet (end plates)
        for (p = hang_screw_xy()) translate(p) circle(d = 5, $fn = 24);                         // cabinet hang screws, centred on the panel edges
    }
}
module p_side_2d()  square([CAB_SIDE_W, CAB_H]);                         // u = y - DR_Y0 (front edge at u = 0), v = z - CAB_ZB
module p_back_2d()  square([CAB_W - 2 * CAB_T, CAB_H]);                 // u = x - (CAB_X0 + CAB_T)
module p_floor_2d() square([CAB_W, CAB_SIDE_W]);                         // u = x - CAB_X0, v = y - DR_Y0
function handle_screw_xz() = [for (s = [-1, 1]) [CAB_XC + s * HANDLE_SCREW_DX, HANDLE_Z]];       // the ONE definition (world x, z): drawer-front holes AND handle inserts
HANDLE_PTS = [for (p = handle_screw_xz()) [p[0] - CAB_X0, p[1] - CAB_ZB]];                      // in the drawer-front frame
module p_front_2d()                                                      // drawer front: u = x - CAB_X0, v = z - CAB_ZB
    difference() {
        square([CAB_W, DRF_H]);
        for (p = HANDLE_PTS) translate(p) circle(d = HANDLE_HOLE_D, $fn = 32);
    }
module p_dbottom_2d() square([DR_W, DR_L]);
module p_dside_2d()   square([DR_L, DR_H - DR_T]);
module p_dback_2d()   square([DR_W - 2 * DR_T, DR_H - DR_T]);

// ---------------- placement: extrusions of the 2D modules above
module yz_panel(x0, y0, z0, t) axial(x0) translate([y0, z0]) linear_extrude(t) children();                // panel in the y-z plane, x0 .. x0+t
module xz_panel(x0, y1, z0, t) multmatrix([[1, 0, 0, x0], [0, 0, -1, y1], [0, 1, 0, z0], [0, 0, 0, 1]])  // panel in the x-z plane, y1-t .. y1
    linear_extrude(t) children();
module xy_panel(x0, y0, z0, t) translate([x0, y0, z0]) linear_extrude(t) children();                     // panel in the x-y plane, z0 .. z0+t

module base_plate() translate([0, 0, BASE_Z0]) linear_extrude(BASE_T) base_2d();
function HANGX(free_end) = free_end ? HANG_X[1] : HANG_X[0];
module cab_side(free_end) difference() {
    yz_panel(free_end ? CAB_X1 - CAB_T : CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_side_2d();
    for (p = hang_screw_xy()) if (abs(p[0] - HANGX(free_end)) < 0.01)                                  // pilots for the hang screws, in the top edge
        translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH]) cylinder(d = HANG_PILOT_D, h = HANG_PILOT_DEPTH + 1, $fn = 20);
}
module cabinet_back() xz_panel(CAB_X0 + CAB_T, CAB_Y1, CAB_ZB, CAB_T) p_back_2d();
module cabinet_shell_panels() {
    cab_side(false);                                                                                    // side (drive end)
    cab_side(true);                                                                                     // side (free end)
    cabinet_back();                                                                                     // back
    xy_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_floor_2d();                                               // floor
}
module cabinet_panels() cabinet_shell_panels();
module drawer_front() xz_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_front_2d();
DR_X0 = CAB_XC - DR_W / 2;  DR_X1 = CAB_XC + DR_W / 2;
module drawer_bin() {
    xy_panel(DR_X0, DR_Y0, DR_Z0, DR_T) p_dbottom_2d();                                                // bottom
    yz_panel(DR_X0, DR_Y0, DR_Z0 + DR_T, DR_T) p_dside_2d();                                           // sides
    yz_panel(DR_X1 - DR_T, DR_Y0, DR_Z0 + DR_T, DR_T) p_dside_2d();
    xz_panel(DR_X0 + DR_T, DR_Y0 + DR_L, DR_Z0 + DR_T, DR_T) p_dback_2d();                             // back
}
module drawer_panels() { drawer_front(); drawer_bin(); }

// ---------------- drawer pull handle (printed, PETG): an edge pull, back plate + shelf + lip; fingers go in from below.
// Local frame (u = distance in front of the drawer front, v = z - HANDLE_Z, w = along the width, 0 .. HANDLE_W)
HANDLE_SHELF_T = 8;  HANDLE_LIP_T = 6;  HANDLE_LIP_H = 18;
module handle_local() {
    ht = HANDLE_H / 2;  d1 = HANDLE_BACK_T + HANDLE_LIP_D;
    difference() {
        linear_extrude(HANDLE_W) {
            translate([0, -ht]) square([HANDLE_BACK_T, HANDLE_H]);                                     // back plate
            translate([0, ht - HANDLE_SHELF_T]) square([d1, HANDLE_SHELF_T]);                           // shelf
            translate([d1 - HANDLE_LIP_T, ht - HANDLE_LIP_H]) square([HANDLE_LIP_T, HANDLE_LIP_H]);     // lip
        }
        for (p = handle_screw_xz()) translate([-0.01, 0, CAB_XC + HANDLE_W / 2 - p[0]]) rotate([0, 90, 0])   // M4 heat-set inserts from the back face
            cylinder(d = INSERT_D, h = INSERT_DEPTH + 0.01, $fn = 32);
    }
}
// u -> -y (away from the cabinet), v -> z, w -> -x (a proper rotation)
module handle_world() multmatrix([[0, 0, -1, CAB_XC + HANDLE_W / 2], [-1, 0, 0, CAB_Y0], [0, 1, 0, HANDLE_Z], [0, 0, 0, 1]]) handle_local();
module handle_screws_ph() for (p = handle_screw_xz())  // 2 x M4 x 22 from inside the bin (head against the back of the drawer front)
    translate([p[0], DR_Y0 + 3, p[1]]) rotate([90, 0, 0]) {
        cylinder(d = 7, h = 3, $fn = 24);
        translate([0, 0, 3]) cylinder(d = 4, h = 22, $fn = 20);                // 22 under the head: 18 panel + 4 of the 6 mm insert
    }
module drawer_moved_ph(t, dz = 0) translate([0, -t, dz]) { drawer_panels(); handle_world(); handle_screws_ph(); }     // the drawer (front, bin, handle) pulled out by t (dz: raised, for controls)

// ---------------- the SCREEN
module screen_profile_2d() intersection() {                    // (y, z) cross-section
    difference() {
        translate([-SC_YW, SC_ZMIN - 1]) square([2 * SC_YW, SC_ZT - SC_ZMIN + 1]);
        for (s = [-1, 1]) translate([s * C / 2, 0]) circle(r = SC_RS, $fn = 192);          // the top arcs
    }
    translate([-SC_YW, SC_ZMIN]) square([2 * SC_YW, SC_ZT - SC_ZMIN]);                    // flat bottom (2026-11-15: no curved underside, one 3D side only)
}
module screen_body() axial(SC_X0) linear_extrude(SC_X1 - SC_X0) screen_profile_2d();
module screen_screw_cuts() for (x = SCREEN_SCREW_X, s = [-1, 1]) translate([x, s * SCREEN_SCREW_Y, 0]) {
    translate([0, 0, SC_ZMIN - 1]) cylinder(d = SCREEN_SCREW[1], h = SC_ZT - SC_ZMIN + 2, $fn = 24);                        // M4 clearance
    translate([0, 0, SC_ZMIN - 1]) cylinder(d = SCREEN_SCREW[4], h = (SC_ZT - SCREEN_SCREW_LAND) - SC_ZMIN + 1, $fn = 32);  // counterbore from below up to the land
}
module screen_pockets() for (x = WALL_SCREW_X, s = [-1, 1]) translate([x, s * WALL_SCREW_Y, SC_ZT - SCREEN_POCKET[1]]) cylinder(d = SCREEN_POCKET[0], h = SCREEN_POCKET[1] + 1, $fn = 32);
module screen_hole_cuts(d = SCREEN_HOLE_D) for (h = screen_holes()) {
    translate([h[0], h[1], SC_ZMIN - 2]) cylinder(d = d, h = SC_ZT - SC_ZMIN + 4, $fn = 24);
    if (sc_relief_top(h[1]) > SC_ZMIN + 0.5) translate([h[0], h[1], SC_ZMIN - 2]) cylinder(d = SCREEN_RELIEF_D, h = sc_relief_top(h[1]) - SC_ZMIN + 2, $fn = 24);   // relief from below
}
// top of a hole's relief: SCREEN_T below the LOWEST point of the top across the hole (so the Ø5 land is >= SCREEN_T everywhere; the same depth for a whole row)
function sc_relief_top(y) = min([for (dy = [-SCREEN_HOLE_D / 2, 0, SCREEN_HOLE_D / 2]) sc_top(y + dy)]) - SCREEN_T;
module screen(holes = true) difference() {
    screen_body();
    if (holes) screen_hole_cuts();
    screen_screw_cuts();
    screen_pockets();
}
module screen_screws_ph() for (x = SCREEN_SCREW_X, s = [-1, 1]) translate([x, s * SCREEN_SCREW_Y, SC_ZT - SCREEN_SCREW_LAND - 0.01]) {   // M4 x 16 socket head, head on the land
    translate([0, 0, -SCREEN_SCREW[3]]) cylinder(d = SCREEN_SCREW[2], h = SCREEN_SCREW[3], $fn = 24);
    cylinder(d = SCREEN_SCREW[0] - 0.7, h = 16, $fn = 16);                                                                           // shank at the thread core
}
module wall_screws_ph() for (x = WALL_SCREW_X, s = [-1, 1]) translate([x, s * WALL_SCREW_Y, SC_ZT - 0.01]) {    // M5 x 16 socket head from below through the comb into the wall
    translate([0, 0, -WALL_SCREW_HEAD[1]]) cylinder(d = WALL_SCREW_HEAD[0], h = WALL_SCREW_HEAD[1], $fn = 24);
    cylinder(d = 4.1, h = 16, $fn = 16);
}
module screen_shanks() for (x = SCREEN_SCREW_X, s = [-1, 1]) translate([x, s * SCREEN_SCREW_Y, SC_ZT - SCREEN_SCREW_LAND - 1]) cylinder(d = SCREEN_SCREW[0] - 0.8, h = SCREEN_SCREW_LAND + SCREEN_TAP_DEPTH, $fn = 16);   // C16: M4 core through the wing's Ø4.5 and the comb's tapped Ø3.3
// 2D drawing: the cross-section with the hole axes, and the plan with the hole pattern, the screws and the pockets
module screen_2d() {
    screen_profile_2d();
    translate([0, SC_ZMIN - SC_YW - 15]) projection() screen();     // plan below the section, 15 mm clear of it (it used to overlap the section)
}
module screen_plan_2d(d = SCREEN_HOLE_D) projection() difference() { screen_body(); screen_hole_cuts(d); }   // plan (z projection) of the screen with its holes (d: control)
module screen_holes_plan_2d() for (h = screen_holes()) translate(h) circle(d = SCREEN_HOLE_D, $fn = 24);
module screen_cb_reach(dy = 0) for (x = SCREEN_SCREW_X, s = [-1, 1]) translate([x, s * SCREEN_SCREW_Y + dy, SC_ZMIN - 80]) cylinder(d = SCREEN_SCREW[4], h = 80 - 0.01, $fn = 32);   // a socket key's way up to each counterbore
function sc_bot(y) = max(SC_ZMIN, sc_relief_top(y));     // bottom of the Ø5 part of a hole at y
function screen_min_hole_len() = min([for (h = screen_holes(), dy = [-SCREEN_HOLE_D / 2, 0, SCREEN_HOLE_D / 2]) sc_top(h[1] + dy) - sc_bot(h[1] + dy)]);
function screen_out_ok() = (SC_X1 - SC_X0 < CAB_W - 2 * CAB_T - 2) && (SC_ZT - SC_ZMIN < CAB_ZT - CAB_FLOOR_TOP - 2);    // it drops into the cabinet and slides out of the drawer opening
function chamber_iy() = wall_inner_y;
module screen_cover_2d() translate([SC_X0, -SC_YW]) square([SC_X1 - SC_X0, 2 * SC_YW]);   // plan of the screen's outline
function screen_box() = [[SC_X0, -SC_YW, SC_ZMIN], [SC_X1 - SC_X0, 2 * SC_YW, SC_ZT - SC_ZMIN]];
function screen_dims() = [SC_X1 - SC_X0, 2 * SC_YW, SC_ZT - SC_ZMIN, len(screen_holes()), SC_ZMIN, SC_YMEET];

module cabinet() { cabinet_panels(); drawer_panels(); handle_world(); handle_screws_ph(); }

// ---------------- panel outlines, laid out on a sheet (mm).  Every outline is the SAME module the 3D part extrudes.
module cabinet_2d() {
    sz = CAB_H;  sy = CAB_SIDE_W;
    p_side_2d();                                                                          // side x2
    translate([sy + 10, 0]) p_side_2d();
    translate([0, sz + 10]) p_back_2d();                                                  // back
    translate([2 * sy + 20, 0]) p_floor_2d();                                             // floor
    translate([2 * sy + 20, sy + 10]) p_front_2d();                                       // drawer front (full height): only the 2 x Ø4.5 handle screw holes
    translate([0, 2 * sz + 20]) p_dbottom_2d();                                           // drawer bottom
    for (i = [0, 1]) translate([DR_W + 10 + i * (DR_L + 10), 2 * sz + 20]) p_dside_2d();   // drawer sides
    translate([DR_W + 10 + 2 * (DR_L + 10), 2 * sz + 20]) p_dback_2d();                    // drawer back
}

// ---------------- check helpers (checks.scad only sees modules / functions, not variables)
module bin_inner_plan_2d(inset = 0) translate([DR_X0 + DR_T + inset, DR_Y0 + DR_T + inset]) square([DR_W - 2 * DR_T - 2 * inset, DR_L - 2 * DR_T - 2 * inset]);
function drawer_inner_top() = max(DR_Z0 + DR_H, HANDLE_Z + 3.5);   // highest point of the drawer inside the cabinet: the bin top (or the pull's screw heads)
function cab_zt() = CAB_ZT;
module foot_screw_shanks() for (p = foot_screw_xy()) translate([p[0], p[1], BASE_Z0 - 3]) cylinder(d = 4.9, h = BASE_T + 14, $fn = 20);   // M6 core: base slot 6.6 + plate hole Ø5 x 12 deep (ends 11 mm up the hole)
module hang_shanks() for (p = hang_screw_xy()) translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH + 1]) cylinder(d = HANG_PILOT_D - 0.2, h = HANG_PILOT_DEPTH + BASE_T + 2, $fn = 16);   // M4 core: base Ø5 + panel pilot Ø3.3
module handle_shanks() for (p = handle_screw_xz()) translate([p[0], DR_Y0 + 2, p[1]]) rotate([90, 0, 0]) cylinder(d = 4, h = CAB_T + 2 + 5, $fn = 20);   // M4: front Ø4.5 + handle insert Ø5.6 (6 deep)
function base_box() = [[BASE_X0, BASE_Y0, BASE_Z0], [BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, BASE_T]];

// ---------------- print / machining poses
module drawer_handle_print() multmatrix([[0, 0, -1, HANDLE_W], [0, 1, 0, HANDLE_H / 2], [1, 0, 0, 0], [0, 0, 0, 1]]) handle_local();   // back face down, shelf up
module screen_part() translate([-SC_X0, SC_YW, -SC_ZMIN]) screen();       // as machined: x along the block, the wings' top faces up (z = -SC_ZMIN - 5)

part = "world";
if (part == "base_plate") base_plate();
else if (part == "base_2d") base_2d();
else if (part == "cabinet_2d") cabinet_2d();
else if (part == "cabinet") { cabinet_panels(); drawer_panels(); }
else if (part == "drawer_handle") drawer_handle_print();
else if (part == "screen") screen_part();
else if (part == "screen_2d") screen_2d();
else if (part == "bom") {
    echo(str("BOM base plate: 18 mm plywood ", BASE_X1 - BASE_X0, " x ", BASE_Y1 - BASE_Y0, " (x ", BASE_X0, " .. ", BASE_X1, ", y ", BASE_Y0, " .. ", BASE_Y1, "), cut-out ", chamber_L, " x ", 2 * BASE_CUT_Y,
              " under the chamber; 6 x M4 x 45 hang screws (Ø5 holes, Ø", HANG_PILOT_D, " x ", HANG_PILOT_DEPTH, " pilots in the cabinet side panels)"));
    echo(str("BOM drawer: full-height front ", CAB_W, " x ", DRF_H, " (18 mm ply, ", DRF_GAP, " mm under the base plate), pull handle (printed), 2 x M4 x 22 + 2 heat-set inserts M4; bin (10 mm ply) sides ", DR_L, " x ", DR_H - DR_T,
              ", back ", DR_W - 2 * DR_T, " x ", DR_H - DR_T, ", bottom ", DR_W, " x ", DR_L, ": ", DR_H, " high, its top ", BIN_TOP_CLEAR, " mm under the base plate"));
    echo(str("BOM SCREEN: aluminium 6061 / 6082 block, finished ", SC_X1 - SC_X0, " x ", 2 * SC_YW, " x ", SC_ZT - SC_ZMIN, " (stock about ", ceil(SC_X1 - SC_X0 + 4), " x ", ceil(2 * SC_YW + 4), " x ", ceil(SC_ZT - SC_ZMIN + 3),
              "); top arcs R", SC_RS, ", flat bottom ", SC_ZT - SC_ZMIN, " below the wing tops, Ø", SCREEN_RELIEF_D, " reliefs from below; top arcs round the shaft axes (y = +-", C / 2, "), wall ", SCREEN_T, "; ", len(screen_holes()), " holes Ø", SCREEN_HOLE_D, " on a ", SCREEN_HOLE_PITCH,
              " hex pattern where the top is <= ", SCREEN_HOLE_SLOPE, " deg steep; 4 x M4 x 16 socket screws from below (Ø", SCREEN_SCREW[1], " + Ø", SCREEN_SCREW[4], " counterbore, ", SCREEN_SCREW_LAND, " land) into the combs (tapped M4 x ",
              SCREEN_TAP_DEPTH, " at |y| = ", SCREEN_SCREW_Y, ", x = ", SCREEN_SCREW_X, "); 6 pockets Ø", SCREEN_POCKET[0], " x ", SCREEN_POCKET[1], " for the wall screws' heads"));
}
else if (part == "world") { base_plate(); cabinet(); screen(); screen_screws_ph(); }
