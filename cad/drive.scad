// drive.scad -- the drive: gearbox (foot-mounted, NRV063-VS placeholder) on two slotted rails, its output COAXIAL with shaft A, output shaft, PIN FLANGE (made) whose 4 dowel pins
// drive the TL350's own 30T sprocket plate (the TL350 is on shaft A: placeholders.scad), motor COAXIAL with the worm + jaw coupling, coupling guard + stub cap (printed),
// drive deck + legs + hold-down (leg angles, foot angles, floor anchors).  World frame.  (2026-11-15: no belt, no chain.)
//   -D 'part="gb_rail"|"gb_rail_2d"|"gb_spacer"|"leg_angle"|"output_shaft"|"output_shaft_2d"|"pin_flange"|"pin_flange_2d"|"sprocket_drill_2d"|
//        "cpl_guard"|"stub_cap"|"drive_deck"|"drive_deck_2d"|"bom"|"world"'
//
// PIN COUPLING  the TL350 on A is flipped (flange end outward), so its sprocket plate is 12 mm in from A's outer end.  The pin flange (6061, keyed on the output shaft) has its
//   disc face 2 mm outside the TL's flange-end face, a pocket over A's end cap and M10 head, and 4 hardened dowels Ø8 x 32 pressed through the disc; they reach through 4 Ø8.5
//   holes the user drills in the sprocket plate (PCD 101, between the TL's Ø89 body and the tooth root).  Torque only: no radial load on the gearbox or on shaft A.
// OUTPUT SHAFT  Ø25 h6, made from the bought 4140 bar: through the hollow output hub (GB_HUB_L), keyway 8 x 4 along the hub (gearbox key) and 8 x 4 under the pin flange's bore;
//   DIN 471 circlip against the housing's far face; the Ø36 spacer and the pin flange (key + M6 grub screw) on the other side.
// RAILS  two flats 50 x 10 under the foot rows, slots (+-6 mm along x) for the feet, M8 deck bolts outside the flange, on 4 spacer blocks (rail + spacer = SUBPLATE_T = 20: same heights).
// HOLD-DOWN  gearbox feet -> rails (M8 through-bolts) -> deck -> 4 top angles (40x40x4, 2 x M8 through the deck, 2 x M8 through the leg) -> legs ->
//   4 foot angles (2 x M8 through the leg, 2 x M8 anchors each) -> floor.
include <common.scad>
include <joints.scad>
include <placeholders.scad>
include <tl350.scad>

// ---------------- gearbox, output shaft, pin flange
module cyl_xx(y, z, r, x0, x1, fn = 64) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = fn);
module gb_housing() difference() {
    translate([GB_X0, GB_Y0, GB_Z0]) cube([GB_HUB_L, GB_BOX[1], GB_BOX[2]]);
    cyl_xx(YA, ZO, JOURNAL_D / 2 + 0.01, GB_X0 - 1, GB_X1 + 1);                                  // hollow output hub Ø25 H7 through the housing
}
module gb_flange()  translate([GB_XC - GB_FLANGE[0] / 2, YA - GB_FLANGE[1] / 2, GB_FZ0]) difference() {
    cube(GB_FLANGE);
    for (p = gb_foot_pts()) translate([p[0] - (GB_XC - GB_FLANGE[0] / 2), p[1] - (YA - GB_FLANGE[1] / 2), -1]) cylinder(d = 9, h = GB_FLANGE[2] + 2, $fn = 24);   // 4 x Ø9 feet
}
module gearbox_ph() { gb_housing(); gb_flange(); }
module worm_ph()    translate([XG, GB_Y0 - GB_WORM_STUB, ZW]) rotate([-90, 0, 0]) cylinder(d = 19, h = GB_BOX[1] + 2 * GB_WORM_STUB, $fn = 48);   // solid Ø19, both sides (VS)
// keyway 8 x 4, closed ends with the Ø8 cutter's radius, on top (+z)
module keyway_cut(x0, x1) hull() for (x = [x0 + SHAFT_KEY_W / 2, x1 - SHAFT_KEY_W / 2]) translate([x, 0, JOURNAL_D / 2 - SHAFT_KEY_D]) cylinder(d = SHAFT_KEY_W, h = SHAFT_KEY_D + 1, $fn = 32);
module output_shaft_local() difference() {          // axis on the x axis
    translate([OUT_X0, 0, 0]) rotate([0, 90, 0]) cylinder(d = JOURNAL_D, h = OUT_X1 - OUT_X0, $fn = 64);
    translate([GB_X0 - CIRCLIP_GROOVE_W, 0, 0]) rotate([0, 90, 0]) difference() {          // DIN 471 groove Ø23.9 x 1.3 against the housing's far face
        cylinder(d = JOURNAL_D + 2, h = CIRCLIP_GROOVE_W, $fn = 64);
        translate([0, 0, -1]) cylinder(d = CIRCLIP_GROOVE_D, h = CIRCLIP_GROOVE_W + 2, $fn = 64);
    }
    keyway_cut(GBKEY_X0, GBKEY_X1);                 // gearbox key
    keyway_cut(PFKEY_X0, PFKEY_X1);                 // pin-flange key
}
module output_shaft_ph() translate([0, YA, ZO]) output_shaft_local();
// the parts that hold the output shaft (seated placeholders): circlip on the far face, Ø36 spacer on the output face
module circlip_ph()     translate([0, YA, ZO]) seat_x(CIRCLIP_OD, CIRCLIP_GROOVE_D, GB_X0 - CIRCLIP_T, CIRCLIP_T);
module out_spacer_ph()  translate([0, YA, ZO]) seat_x(OUT_SPACER_D, JOURNAL_D, GB_X1, TL_GB_GAP);
module shaft_hw_ph() { circlip_ph(); out_spacer_ph(); }
// ---- the PIN FLANGE (made, 6061-T6; part frame: axis on +z, z = 0 at the disc face, the hub toward +z): disc, pocket, keyed bore, 4 pin holes, M6 grub screw over the key
module pin_flange_local() difference() {
    union() {
        cylinder(d = PF_D, h = PF_T, $fn = 128);
        cylinder(d = PF_HUB_D, h = PF_X0 - PF_HUB_X, $fn = 96);
    }
    translate([0, 0, -1]) cylinder(d = PF_POCKET_D, h = PF_X0 - PF_PK_X + 1, $fn = 96);                       // pocket over A's end cap + M10 head
    translate([0, 0, PF_X0 - PF_PK_X - 0.01]) cylinder(d = JOURNAL_D + 0.02, h = PF_KEY_L + 1, $fn = 64);        // Ø25 H7 bore
    translate([-SHAFT_KEY_W / 2, 0, PF_X0 - PF_PK_X - 0.01]) cube([SHAFT_KEY_W, JOURNAL_D / 2 + 3.3, PF_KEY_L + 1]);   // 8 mm keyway, 3.3 deep in the hub (broached)
    for (q = PIN_PTS) translate([q[0], q[1], -1]) cylinder(d = PIN_D, h = PF_T + 2, $fn = 32);                  // pin holes (reamed: press fit)
    translate([0, 0, PF_X0 - PF_PK_X + PF_KEY_L / 2]) rotate([-90, 0, 0]) cylinder(d = 5, h = PF_HUB_D, $fn = 20);   // M6 grub screw over the key (tap drill Ø5)
}
module axis_to_x() multmatrix([[0, 0, -1, 0], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) children();         // a rotation: part +z -> world -x, part x -> world -y, part y -> world z (the key on top)
module pin_flange() translate([PF_X0, YA, ZO]) axis_to_x() pin_flange_local();
module pins_ph(g = 0) for (q = PIN_PTS) translate([PIN_X0 + FIT, YA + q[0], ZO + q[1]]) rotate([0, 90, 0]) cylinder(d = PIN_D - 2 * FIT + 2 * g, h = PIN_L - 2 * FIT, $fn = 32);   // seated in the flange (FIT off the hole)
module pin_coupling_ph() { pin_flange(); pins_ph(); }
// 2D drawing of the pin flange: face view (pocket, pin holes) and, beside it, a half section
module pin_flange_2d() {
    difference() { circle(d = PF_D, $fn = 128); circle(d = PF_POCKET_D, $fn = 96); for (q = PIN_PTS) translate(q) circle(d = PIN_D, $fn = 32); }
    translate([PF_D, 0]) projection(cut = true) rotate([90, 0, 0]) pin_flange_local();
}
// 1:1 drilling template for the TL350's sprocket plate: tooth-tip circle, root circle, the TL's Ø89 body, the 4 Ø8.5 holes and their centre cross
module sprocket_drill_2d() {
    for (d = [SPA_OD_, tl_sprocket_root_d, TL_D]) difference() { circle(d = d + 0.5, $fn = 192); circle(d = d - 0.5, $fn = 192); }
    for (q = PIN_PTS) translate(q) { difference() { circle(d = PIN_HOLE_D, $fn = 48); circle(d = PIN_HOLE_D - 1, $fn = 48); } square([12, 0.4], center = true); square([0.4, 12], center = true); }
    square([20, 0.4], center = true); square([0.4, 20], center = true);
}
// 2D drawing of the output shaft (side view with the keyway and the groove, plan view with the keyway slots; 1:1 mm; x = along the shaft from the far end)
module output_shaft_2d() {
    L = OUT_X1 - OUT_X0;  R = JOURNAL_D / 2;  g0 = GB_X0 - CIRCLIP_GROOVE_W - OUT_X0;
    difference() {                                                                               // side view (key side up)
        translate([0, -R]) square([L, 2 * R]);
        for (s = [-1, 1]) translate([g0, s > 0 ? CIRCLIP_GROOVE_D / 2 : -R - 1]) square([CIRCLIP_GROOVE_W, R - CIRCLIP_GROOVE_D / 2 + 1]);
        for (k = [[GBKEY_X0, GBKEY_X1], [PFKEY_X0, PFKEY_X1]]) translate([k[0] - OUT_X0, R - SHAFT_KEY_D]) square([k[1] - k[0], SHAFT_KEY_D + 1]);
    }
    translate([0, -2 * R - 15]) difference() {                                                   // plan view: the two keyway slots and the groove notches
        translate([0, -R]) square([L, 2 * R]);
        for (s = [-1, 1]) translate([g0, s > 0 ? CIRCLIP_GROOVE_D / 2 : -R - 1]) square([CIRCLIP_GROOVE_W, R - CIRCLIP_GROOVE_D / 2 + 1]);
        for (k = [[GBKEY_X0, GBKEY_X1], [PFKEY_X0, PFKEY_X1]]) hull() for (x = [k[0] - OUT_X0 + SHAFT_KEY_W / 2, k[1] - OUT_X0 - SHAFT_KEY_W / 2]) translate([x, 0]) circle(d = SHAFT_KEY_W, $fn = 32);
    }
}

// ---------------- gearbox rails (2 x flat 50 x 10, slotted along x) on 4 spacer blocks; the feet bolt through the slots, the rails bolt down through the deck
module rail_local_2d() {            // x relative to the housing centre, y relative to the rail centre line
    half = GB_RAIL_BOLT_DX + GB_RAIL_END;
    difference() {
        translate([-half, -GB_RAIL_W / 2]) square([2 * half, GB_RAIL_W]);
        for (sx = [-1, 1]) translate([sx * GB_FOOT[0] / 2, -RAIL_FOOT_DY]) hull() for (d = [-GB_RAIL_SLOT, GB_RAIL_SLOT]) translate([d, 0]) circle(d = 9, $fn = 24);     // slots 9 x 21 (rail A; rail B is its mirror image)
        for (sx = [-1, 1]) translate([sx * GB_RAIL_BOLT_DX, 0]) circle(d = 9, $fn = 24);                                                                       // deck bolts
    }
}
module gb_rail_at(i) translate([GB_XC, RAIL_YC[i], RAIL_Z0]) mirror([0, i, 0]) linear_extrude(GB_RAIL_T) rail_local_2d();        // rail B = rail A mirrored
module gb_spacer_part() difference() {          // part frame: 18 x 50 x 10, Ø9 in the middle
    cube([GB_SPACER_L, GB_RAIL_W, RAIL_SPACER_T]);
    translate([GB_SPACER_L / 2, GB_RAIL_W / 2, -1]) cylinder(d = 9, h = RAIL_SPACER_T + 2, $fn = 24);
}
module gb_spacers() for (p = RAIL_BOLT_PTS) translate([p[0] - GB_SPACER_L / 2, p[1] - GB_RAIL_W / 2, DECK_TOP]) gb_spacer_part();
module gb_rails() for (i = [0, 1]) gb_rail_at(i);
module gb_mount() { gb_rails(); gb_spacers(); }

// ---------------- motor + jaw coupling (placeholders): the motor stands on the deck, its shaft coaxial with the worm's -y stub
module motor_ph() {
    translate([XM, Y_MF, ZM]) rotate([90, 0, 0]) cylinder(d = MOTOR_D, h = MOTOR_LEN, $fn = 64);                     // body, front face at Y_MF, toward -y
    translate([XM - MOTOR_FOOT[0] / 2, MFOOT_Y[0], DECK_TOP]) cube([MOTOR_FOOT[0], MFOOT_Y[1] - MFOOT_Y[0], MOTOR_FOOT[2]]);
}
module motor_shaft_ph() translate([XM, Y_MF, ZM]) rotate([-90, 0, 0]) cylinder(d = MOTOR_SHAFT_D, h = MOTOR_SHAFT_L, $fn = 48);   // out of the face up to the spider
module coupling_ph() {
    translate([XG, Y_WS, ZW]) rotate([-90, 0, 0]) difference() { cylinder(d = CPL_D, h = CPL_hub_L, $fn = 64); translate([0, 0, -1]) cylinder(d = 19.1, h = CPL_hub_L + 2, $fn = 48); }   // worm-side hub on the stub
    translate([XG, CPL_Y_M0, ZW]) rotate([-90, 0, 0]) difference() { cylinder(d = CPL_D, h = CPL_hub_L, $fn = 64); translate([0, 0, -1]) cylinder(d = MOTOR_SHAFT_D + 0.1, h = CPL_hub_L + 2, $fn = 48); }   // motor-side hub
    translate([XG, Y_WS - CPL_gap + 0.5, ZW]) rotate([-90, 0, 0]) cylinder(d = CPL_D - 6, h = CPL_gap - 1, $fn = 64);                      // spider (+ the jaws)
}
module coupling_env(g = 0) translate([XG, CPL_Y_M0 - g, ZW]) rotate([-90, 0, 0]) cylinder(d = CPL_D + 2 * g, h = CPL_Y_W1 - CPL_Y_M0 + 2 * g, $fn = 96);   // the whole coupling as a cylinder
module stub_env(g = 0) translate([XG, Y_HF2 - 0.01, ZW]) rotate([-90, 0, 0]) cylinder(d = 19 + 2 * g, h = GB_WORM_STUB + 0.01 + g, $fn = 64);              // the unused +y worm stub
module motor_shaft_env(g = 0) translate([XG, Y_MF - 0.01, ZW]) rotate([-90, 0, 0]) cylinder(d = MOTOR_SHAFT_D + 2 * g, h = CPL_Y_M0 - Y_MF + 0.01, $fn = 48);   // the bare motor shaft between the face and the hub

// ---------------- coupling guard + stub cap (printed PETG): a box (top, two sides, two end walls) open at the bottom, standing on the deck on two feet (2 x M5 x 20 wood
// screws each).  The end walls have U-notches round the shafts (open UPWARD, so the box is lowered over the shafts); the motor face and the
// housing face close the notches from outside (CG_END_GAP).  The stub cap is the same box over the +y stub, its far end wall closed.
module cg_box(y0, y1, notch0, notch1, feet = [-1, 1], iw = CG_IW) {       // notch = radius of the U-notch in that end wall (0: closed wall); iw = inner half-width = inner height over the axis
    difference() {
        union() {
            translate([XG - iw - CG_W, y0, DECK_TOP]) cube([2 * (iw + CG_W), y1 - y0, ZW + iw + CG_W - DECK_TOP]);
            for (sx = feet) translate([sx > 0 ? XG + iw + CG_W - 0.01 : XG - iw - CG_W - CG_FOOT_REACH + 0.01, (y0 + y1) / 2 - CG_FOOT_W / 2, DECK_TOP])
                cube([CG_FOOT_REACH, CG_FOOT_W, CG_FOOT_T]);                                                       // the feet
        }
        translate([XG - iw, y0 + CG_W, DECK_TOP - 1]) cube([2 * iw, y1 - y0 - 2 * CG_W, ZW + iw - DECK_TOP + 1]);   // inside (open at the bottom)
        for (e = [[y0, notch0], [y1 - CG_W, notch1]]) if (e[1] > 0)                                                  // U-notch round the shaft, open upward
            translate([XG, e[0] - 1, ZW]) rotate([-90, 0, 0]) { cylinder(r = e[1], h = CG_W + 2, $fn = 48); translate([-e[1], -(iw + CG_W) - 1, 0]) cube([2 * e[1], iw + CG_W + 1, CG_W + 2]); }
        for (q = cg_foot_pts(y0, y1, feet, iw)) translate([q[0], q[1], DECK_TOP - 1]) cylinder(d = 5.5, h = CG_FOOT_T + 2, $fn = 24);   // M5 clearance in the feet
    }
}
function cg_foot_pts(y0, y1, feet = [-1, 1], iw = CG_IW) = [for (sx = feet, dy = [-10, 10]) [XG + sx * (iw + CG_W + CG_FOOT_REACH / 2), (y0 + y1) / 2 + dy]];
CG2_IW = 19 / 2 + GUARD_CLEAR;                                                                        // the stub cap is only as big as the bare Ø19 stub needs
CG2_FEET = [-1];                                                                                       // the stub cap's foot only on the -x side
module cpl_guard() cg_box(CG_Y0, CG_Y1, MOTOR_SHAFT_D / 2 + GUARD_CLEAR, 19 / 2 + GUARD_CLEAR);
module stub_cap()  cg_box(CG2_Y0, CG2_Y1, 19 / 2 + GUARD_CLEAR - 0.001, 0, CG2_FEET, CG2_IW);          // the far end wall is closed
module drive_guards_low() { cpl_guard(); stub_cap(); }
function cg_all_foot_pts() = concat(cg_foot_pts(CG_Y0, CG_Y1), cg_foot_pts(CG2_Y0, CG2_Y1, CG2_FEET, CG2_IW));
module cg_foot_shanks() for (p = cg_all_foot_pts()) translate([p[0], p[1], DECK_Z0 + 2]) cylinder(d = 4, h = DECK_T + CG_FOOT_T + 4, $fn = 16);   // M5 wood screw core: foot Ø5.5 + deck pilot Ø4.2
module cg_screws_ph() for (p = cg_all_foot_pts()) translate([p[0], p[1], DECK_TOP + CG_FOOT_T + 0.01]) { cylinder(d = 9.5, h = 3.5, $fn = 24); translate([0, 0, -20]) cylinder(d = 3.6, h = 20, $fn = 16); }

// ---------------- drive deck: REAL 18 mm plywood under the motor and the rails, on 4 timber legs (45 x 45)
// Outline = motor foot / rails / guards + margins.
// Holes: 6 x Ø4.2 pilots (coupling guard + stub cap feet), 8 x Ø5.5 (leg screws), 4 x Ø9 (rail bolts), 8 x Ø9 (top-angle bolts).  The motor's own slots are not drilled.
assert(DECK_LEG_LEN >= DRIVE_LEG_MIN, str("drive deck legs too short (", DECK_LEG_LEN, " < ", DRIVE_LEG_MIN, ")"));
assert(DECK_X1 < -30);
function deck_leg_screw_xy() = [for (c = DECK_LEG_C, dx = [-10, 10]) [c[0] + dx, c[1] + (c[1] < 0 ? 17 : -17)]];   // leg screws, 17 mm in from the leg centre toward the deck middle
module drive_deck_2d() difference() {
    translate([DECK_X0, DECK_Y0]) square([DECK_X1 - DECK_X0, DECK_Y1 - DECK_Y0]);
    for (p = cg_all_foot_pts()) translate(p) circle(d = 4.2, $fn = 24);                     // M5 wood screw pilots (coupling guard + stub cap feet)
    for (p = deck_leg_screw_xy()) translate(p) circle(d = 5.5, $fn = 24);                   // M5 leg screws (pilots Ø3.5 in the timber, deck_legs())
    for (p = RAIL_BOLT_PTS) translate(p) circle(d = 9, $fn = 24);                           // rail bolts
    for (p = TOPANG_DECK_PTS) translate(p) circle(d = 9, $fn = 24);                         // top-angle bolts
}
module drive_deck() translate([0, 0, DECK_Z0]) linear_extrude(DECK_T) drive_deck_2d();
function legpts(c, pts) = [for (q = pts) if (abs(q[0] - c[0]) <= LEG_SECTION / 2 + 0.01 && abs(q[1] - c[1]) <= LEG_SECTION / 2 + 0.01) q];
module deck_legs() for (c = DECK_LEG_C) difference() {
    translate([c[0] - LEG_SECTION / 2, c[1] - LEG_SECTION / 2, DRIVE_FLOOR_Z]) cube([LEG_SECTION, LEG_SECTION, DECK_LEG_LEN]);
    for (p = deck_leg_screw_xy()) translate([p[0], p[1], DECK_Z0 - 30]) cylinder(d = 3.5, h = 31, $fn = 16);   // pilots for the leg screws, from the top
    for (p = legpts(c, TOPANG_LEG_PTS)) translate([p[0], c[1] - LEG_SECTION / 2 - 1, TOPANG_LEG_Z]) rotate([-90, 0, 0]) cylinder(d = 9, h = LEG_SECTION + 2, $fn = 24);     // top-angle bolts (along y)
    for (p = legpts(c, FOOTANG_LEG_PTS)) translate([c[0] - LEG_SECTION / 2 - 1, p[1], FOOTANG_LEG_Z]) rotate([0, 90, 0]) cylinder(d = 9, h = LEG_SECTION + 2, $fn = 24);     // foot-angle bolts (along x)
}
module deck_ph() drive_deck();                                                              // what the guard checks see

// ---------------- leg angles: 40 x 40 x 4 steel angle, 60 long.  Part frame: corner at the origin, length along +x, vertical flange y' 0..4 / z 0..40, horizontal flange z 0..4 / y' 0..40.
// Holes: horizontal flange 2 x Ø9 (x = L/2 +-11, y' = 22), vertical flange 2 x Ø9 (x = L/2 +-11, z = 22).
module leg_angle() difference() {
    union() { cube([ANG_L, ANG_T, ANG_W]); cube([ANG_L, ANG_W, ANG_T]); }
    for (d = [-11, 11]) translate([ANG_L / 2 + d, 22, -1]) cylinder(d = 9, h = ANG_T + 2, $fn = 24);
    for (d = [-11, 11]) translate([ANG_L / 2 + d, -1, 22]) rotate([-90, 0, 0]) cylinder(d = 9, h = ANG_T + 2, $fn = 24);
}
module top_angle_at(c) { sy = leg_sy(c);                                       // corner at the top, flange under the deck pointing out (+-y)
    multmatrix([[1, 0, 0, c[0] - ANG_L / 2], [0, sy, 0, c[1] + sy * (LEG_SECTION / 2 + HW_GAP)], [0, 0, -1, DECK_Z0 - HW_GAP], [0, 0, 0, 1]]) leg_angle(); }
module foot_angle_at(c) { sx = leg_sx(c);                                      // corner at the floor, flange on the floor pointing inward (+-x)
    multmatrix([[0, sx, 0, c[0] + sx * (LEG_SECTION / 2 + HW_GAP)], [1, 0, 0, c[1] - ANG_L / 2], [0, 0, 1, DRIVE_FLOOR_Z + HW_GAP], [0, 0, 0, 1]]) leg_angle(); }
module top_angles() for (c = DECK_LEG_C) top_angle_at(c);
module foot_angles() for (c = DECK_LEG_C) foot_angle_at(c);
module floor_ph() difference() {                                               // ghost floor / bench top (picture and the anchor joint check only)
    translate([DECK_X0 - 60, DECK_Y0 - 60, GROUND_Z - FLOOR_T]) cube([min(DECK_X1 + 60, -34) - (DECK_X0 - 60), DECK_Y1 - DECK_Y0 + 120, FLOOR_T]);
    for (p = ANCHOR_PTS) translate([p[0], p[1], GROUND_Z - FLOOR_T - 1]) cylinder(d = 8.5, h = FLOOR_T + 2, $fn = 24);
}

// ---------------- hardware placeholders: M8 hex bolts (washer + head on the near side, washer + nut on the far side), generic along a local +w axis
// local frame: origin on the bearing face of the head side, +w toward the nut; grip = clamped thickness; wd/wt = head-side washer, wd2/wt2 = nut-side washer
module orient(d) {
    if (d == [0, 0, -1]) rotate([180, 0, 0]) children();
    else if (d == [0, 1, 0]) rotate([-90, 0, 0]) children();
    else if (d == [0, -1, 0]) rotate([90, 0, 0]) children();
    else if (d == [1, 0, 0]) rotate([0, 90, 0]) children();
    else if (d == [-1, 0, 0]) rotate([0, -90, 0]) children();
    else children();
}
module m8_ph(grip, wd = 16, wt = 1.6, wd2 = 16, wt2 = 1.6) {
    translate([0, 0, -HW_GAP - wt]) cylinder(d = wd, h = wt, $fn = 32);                                     // washer under the head
    translate([0, 0, -HW_GAP - wt - 5.3]) cylinder(d = 14.4, h = 5.3, $fn = 6);                             // head
    translate([0, 0, -HW_GAP - wt - 5.3 + 0.01]) cylinder(d = 8, h = 5.3 + wt + HW_GAP + grip + HW_GAP + wt2 + HW_GAP + 6.8 + 0.5, $fn = 20);   // shank to 0.5 mm past the nut
    translate([0, 0, grip + HW_GAP]) cylinder(d = wd2, h = wt2, $fn = 32);                                  // washer under the nut
    translate([0, 0, grip + HW_GAP + wt2 + HW_GAP]) cylinder(d = 14.4, h = 6.8, $fn = 6);                   // nut
}
module m8_at(p, d, grip, wd = 16, wt = 1.6, wd2 = 16, wt2 = 1.6) translate(p) orient(d) m8_ph(grip, wd, wt, wd2, wt2);
module gb_foot_bolts_ph() for (p = gb_foot_pts()) m8_at([p[0], p[1], GB_FZ1], [0, 0, -1], GB_FLANGE[2] + GB_RAIL_T);                                  // M8 x 30: flange 8 + rail 10, nut under the rail
module rail_bolts_ph() for (p = RAIL_BOLT_PTS) m8_at([p[0], p[1], RAIL_Z1], [0, 0, -1], GB_RAIL_T + RAIL_SPACER_T + DECK_T, 16, 1.6, BIG_WASHER_D, BIG_WASHER_T);   // M8 x 55 through rail, spacer, deck; Ø24 penny washer + nut under the deck
module topang_deck_bolts_ph() for (p = TOPANG_DECK_PTS) m8_at([p[0], p[1], DECK_Z1], [0, 0, -1], DECK_T + HW_GAP + ANG_T, 20, 2, 16, 1.6);           // head + Ø20 washer on the deck, nut under the angle
module topang_leg_bolts_ph() for (c = DECK_LEG_C) for (p = legpts(c, TOPANG_LEG_PTS)) m8_at([p[0], p[1] + leg_sy(c) * (HW_GAP + ANG_T), TOPANG_LEG_Z], [0, -leg_sy(c), 0], ANG_T + HW_GAP + LEG_SECTION, 16, 1.6, 20, 2);
module footang_leg_bolts_ph() for (c = DECK_LEG_C) for (p = legpts(c, FOOTANG_LEG_PTS)) m8_at([p[0] + leg_sx(c) * (HW_GAP + ANG_T), p[1], FOOTANG_LEG_Z], [-leg_sx(c), 0, 0], ANG_T + HW_GAP + LEG_SECTION, 16, 1.6, 20, 2);
module anchors_ph() for (p = ANCHOR_PTS) translate([p[0], p[1], DRIVE_FLOOR_Z + HW_GAP + ANG_T + HW_GAP]) {              // M8 anchor: hex head + washer on the foot angle's flange, shank down through the angle into the floor
    cylinder(d = 16, h = 1.6, $fn = 32);
    translate([0, 0, 1.6]) cylinder(d = 14.4, h = 5.3, $fn = 6);
    translate([0, 0, -ANG_T - 2 * HW_GAP - FLOOR_T]) cylinder(d = DECK_ANCHOR_D, h = ANG_T + 2 * HW_GAP + FLOOR_T + 1.7, $fn = 20);
}
module holddown_hw_ph() { topang_deck_bolts_ph(); topang_leg_bolts_ph(); footang_leg_bolts_ph(); anchors_ph(); }
// ---------------- swept envelopes of the moving parts (full cylinders: any angle), every dimension grown by g (radially, and along x at both ends)
module cylx(r, x0, x1, y = 0, z = 0) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = 96);
module drive_end_env(g = 0, sprocket = true, shafts = ["A", "B"], sleeves = true) for (s = shafts) {   // sleeves = false: without the two Ø30 sleeves that pass through the outboard plate
    y = shaft_y(s);
    cylx(GEAR_module * (GEAR_z + 2) / 2 + g, x_gear_out - g, x_gear_in + g, y);                 // gear teeth (OD 66)
    cylx(GEAR_HUB_D / 2 + g, x_gear_hub_out - g, x_gear_out + g, y);                            // gear hub
    if (sleeves) {
        cylx(GEAR_SPACER_D / 2 + g, x_ob_ring_in - g, x_gear_hub_out + g, y);                   // sleeve: gear hub -> outboard bearing
        cylx(GEAR_SPACER_D / 2 + g, (s == "A" ? x_spA_in : x_sprocket_in) - g, x_ob_ring_out + g, y);   // sleeve: outboard bearing -> sprocket hub (A) / end cap (B)
    }
    cylx(COLLAR_OD / 2 + g, x_collar_out_drive - g, x_collar_in_drive + g, y);                  // collar
    cylx(THRUST_D / 2 + g, x_collar_in_drive - g, x_cap_out_drive + g, y);                      // thrust bearing
    xe = end_x_drive(s);
    cylx(15 + g, xe - END_WASHER_T - g, xe + g, y);                                             // end cap
    cylx(8 + g, xe - END_WASHER_T - 10 - g, xe - END_WASHER_T + g, y);                          // M10 head
    if (s == "A" && sprocket) {
        cylx(TL_D / 2 + g, x_sprocket_out - g, x_spA_in + g, y);                                // the TL350 body (flange, pack, plate, springs, nut)
        cylx(SPA_OD_ / 2 + g, X_CM - SPROCKET_T / 2 - g, X_CM + SPROCKET_T / 2 + g, y);        // its 30T tooth plate
    }
}
module sprocket_a_env(grow = 0) translate([0, YA, 0]) {      // the TL350 on A: body + tooth plate as plain cylinders (swept over any angle)
    axial(x_sprocket_out - grow) cylinder(d = TL_D + 2 * grow, h = TL_L + 2 * grow, $fn = 64);
    axial(X_CM - SPROCKET_T / 2 - grow) cylinder(d = SPA_OD_ + 2 * grow, h = SPROCKET_T + 2 * grow, $fn = 96);
}
module pf_env(g = 0) {         // the pin flange (disc + hub), its pins, the spacer, all swept, grown by g
    cylx(PF_D / 2 + g, PF_X1 - g, PF_X0 + g, YA, ZO);
    cylx(PF_HUB_D / 2 + g, PF_HUB_X - g, PF_X1 + g, YA, ZO);
    cylx(OUT_SPACER_D / 2 + g, GB_X1 - g, PF_HUB_X + g, YA, ZO);
    cylx(PIN_R + PIN_D / 2 + g, PF_X0 - g, PIN_X1 + g, YA, ZO);                                 // the pins' ring (their outer edge), from the disc face to their tips
}
module drive_gearbox_ph() { gearbox_ph(); worm_ph(); output_shaft_ph(); shaft_hw_ph(); gb_mount(); }

// ---------------- accessors for checks.scad / guards.scad (variables of a `use`d file are not visible)
function deck_geom() = [DECK_X0, DECK_X1, DECK_Y0, DECK_Y1, DECK_Z0, DECK_Z1];
function worm_axis() = [XG, ZW];
function motor_axis_z() = ZM;
function motor_axis_x() = XM;
function cg_box_pts() = [[XG - CG_IW - CG_W - CG_FOOT_REACH, CG_Y0, DECK_TOP], [2 * (CG_IW + CG_W + CG_FOOT_REACH), CG_Y1 - CG_Y0, CG_ZT - DECK_TOP]];
function gb_mount_box() = [[RAIL_X0, RAIL_Y_LO, DECK_TOP], [RAIL_X1 - RAIL_X0, RAIL_Y_HI - RAIL_Y_LO, SUBPLATE_T]];

// ---------------- joint alignment shanks (checks.scad C16): a bolt shank through the hole of part 1 AND the hole of part 2; it must touch neither part's material
module deck_leg_shanks() for (p = deck_leg_screw_xy()) translate([p[0], p[1], DECK_Z0 - 29]) cylinder(d = 3.3, h = DECK_T + 31, $fn = 16);          // M5 wood screw core: deck Ø5.5 + leg pilot Ø3.5
module gbfoot_shanks() for (p = gb_foot_pts()) translate([p[0], p[1], RAIL_Z0 - 3]) cylinder(d = 8, h = GB_RAIL_T + GB_FLANGE[2] + 6, $fn = 24);     // M8: flange Ø9 + rail slot 9
module subbolt_shanks() for (p = RAIL_BOLT_PTS) translate([p[0], p[1], DECK_Z0 - 3]) cylinder(d = 8, h = DECK_T + SUBPLATE_T + 6, $fn = 24);        // M8: rail Ø9 + spacer Ø9 + deck Ø9
module topdeck_shanks() for (p = TOPANG_DECK_PTS) translate([p[0], p[1], DECK_Z0 - ANG_T - 3]) cylinder(d = 8, h = DECK_T + ANG_T + 6, $fn = 24);        // M8: deck Ø9 + top angle Ø9
module topleg_shanks() for (c = DECK_LEG_C) for (p = legpts(c, TOPANG_LEG_PTS)) translate([p[0], p[1] + leg_sy(c) * (ANG_T + 3), TOPANG_LEG_Z]) orient([0, -leg_sy(c), 0]) cylinder(d = 8, h = ANG_T + LEG_SECTION + 6, $fn = 24);
module footleg_shanks() for (c = DECK_LEG_C) for (p = legpts(c, FOOTANG_LEG_PTS)) translate([p[0] + leg_sx(c) * (ANG_T + 3), p[1], FOOTANG_LEG_Z]) orient([-leg_sx(c), 0, 0]) cylinder(d = 8, h = ANG_T + LEG_SECTION + 6, $fn = 24);
module anchor_shanks() for (p = ANCHOR_PTS) translate([p[0], p[1], GROUND_Z - FLOOR_T - 3]) cylinder(d = 8, h = FLOOR_T + ANG_T + 6 + 0.02, $fn = 24);    // M8 anchor: foot angle Ø9 + floor hole Ø8.5
function r1_(v) = round(10 * v) / 10;
function anchor_pts_r() = [for (p = ANCHOR_PTS) [r1_(p[0]), r1_(p[1])]];

part = "world";
if (part == "gb_rail") translate([-RAIL_X0, -RAIL_Y_LO, -RAIL_Z0]) gb_rail_at(0);
else if (part == "gb_rail_2d") translate([-RAIL_X0, -RAIL_Y_LO]) translate([GB_XC, RAIL_YC[0]]) rail_local_2d();
else if (part == "gb_spacer") gb_spacer_part();
else if (part == "leg_angle") leg_angle();
else if (part == "output_shaft") translate([-OUT_X0, 0, 0]) output_shaft_local();
else if (part == "output_shaft_2d") output_shaft_2d();
else if (part == "pin_flange") pin_flange_local();                     // disc face down
else if (part == "pin_flange_2d") pin_flange_2d();
else if (part == "sprocket_drill_2d") sprocket_drill_2d();
else if (part == "cpl_guard") translate([-(XG - CG_IW - CG_W - CG_FOOT_REACH), -CG_Y0, -DECK_TOP]) cpl_guard();     // standing on its feet (the 60 mm roof is a bridge)
else if (part == "stub_cap") translate([-(XG - CG2_IW - CG_W - CG_FOOT_REACH), -CG2_Y0, -DECK_TOP]) stub_cap();
else if (part == "bom") {
    echo(str("BOM pin coupling: TL350 on A flipped (flange end out at x = ", x_sprocket_out, ", sprocket plate at x = ", X_CM, "); pin flange 6061 disc Ø", PF_D, " x ", PF_T,
              " + hub Ø", PF_HUB_D, " (overall ", PF_X0 - PF_HUB_X, "), pocket Ø", PF_POCKET_D, " x ", PF_X0 - PF_PK_X, ", bore Ø25 H7 x ", PF_KEY_L, " + 8 mm keyway + M6 grub screw; ",
              PIN_N, " dowels Ø", PIN_D, " x ", PIN_L, " on PCD ", 2 * PIN_R, " (tips ", PIN_X1 - (X_CM + SPROCKET_T / 2), " past the plate); sprocket holes Ø", PIN_HOLE_D,
              " at (y, z) ", [for (q = PIN_PTS) [round(100 * q[0]) / 100, round(100 * q[1]) / 100]], "; gearbox housing face x = ", GB_X1, ", housing x ", GB_X0, " .. ", GB_X1));
    echo(str("BOM deck: ", DECK_PLY_T, " mm plywood ", DECK_X1 - DECK_X0, " x ", DECK_Y1 - DECK_Y0, "  (x ", DECK_X0, " .. ", DECK_X1, ", y ", DECK_Y0, " .. ", DECK_Y1, ", top z = ", DECK_Z1, "); legs 4 x ", LEG_SECTION, " x ", LEG_SECTION, " x ", DECK_LEG_LEN, " timber, floor z = ", DRIVE_FLOOR_Z, " (bench / cabinet underside z = ", GROUND_Z, ")"));
    echo(str("BOM gearbox rails: 2 x flat 50 x 10 x ", RAIL_X1 - RAIL_X0, " (mild steel, from the 50 x 10 stock), 2 slots 9 x ", 9 + 2 * GB_RAIL_SLOT, " along x (+-", GB_RAIL_SLOT, " mm axial adjustment) for the gearbox feet + 2 x Ø9 deck holes each; 4 spacer blocks 50 x 10 x ", GB_SPACER_L, " (Ø9 hole); 4 x M8 x 40 foot bolts (flange, rail slot, washer + nut under the rail), 4 x M8 x 55 rail bolts through rail, spacer, deck (Ø24 penny washer + nut under the deck)"));
    echo(str("BOM output shaft: Ø25 h6 x ", OUT_X1 - OUT_X0, " from the bought 4140 bar: circlip groove Ø", CIRCLIP_GROOVE_D, " x ", CIRCLIP_GROOVE_W, " at the housing's far face (DIN 471 25 mm circlip), keyway 8 x 4 x ", GBKEY_X1 - GBKEY_X0, " in the ", GB_HUB_L, " mm hollow hub (gearbox key), keyway 8 x 4 x ", PFKEY_X1 - PFKEY_X0, " under the pin flange (its key); spacer Ø", OUT_SPACER_D, " x ", TL_GB_GAP));
    echo(str("BOM hold-down: the gearbox's reaction torque (at most T_LIMIT ", T_LIMIT, " N*m) lifts one foot row.  Load path: gearbox feet -> 2 rails -> 4 x M8 rail bolts -> deck -> ", len(DECK_LEG_C), " top angles (40x40x4 x ", ANG_L, ", ", DECK_ANGLE_DECK_BOLTS, " x M8 through the deck + ", DECK_ANGLE_LEG_BOLTS, " x M8 through the leg each) -> legs -> ", len(DECK_LEG_C), " foot angles (", FOOT_ANGLE_LEG_BOLTS, " x M8 through the leg each) -> ", len(ANCHOR_PTS), " x ", DECK_ANCHOR, " anchors (floor wedge / drop-in anchors or coach screws into the bench)"));
    echo(str("DECK_ANCHORS n = ", len(ANCHOR_PTS), ", positions (x, y) = ", anchor_pts_r(), ", floor z = ", DRIVE_FLOOR_Z, "; rail bolts n = ", len(RAIL_BOLT_PTS), " at ", [for (p = RAIL_BOLT_PTS) [r1_(p[0]), r1_(p[1])]]));
    echo(str("BOM motor + coupling: motor COAXIAL with the worm (axis x = ", XM, ", z = ", ZM, "), front face y = ", Y_MF, "; jaw coupling ", CPL_D, " OD, hubs ", CPL_hub_L, " + spider ", CPL_gap,
              ", bores 19 (worm) and ", MOTOR_SHAFT_D, " (motor, ESTIMATE: measure); coupling guard (printed) ", 2 * (CG_IW + CG_W), " x ", CG_Y1 - CG_Y0, " x ", CG_ZT - DECK_TOP,
              " and a stub cap over the unused +y worm stub, 4 + 2 x M5 x 20 wood screws into the deck"));
}
else if (part == "drive_deck") translate([-DECK_X0, -DECK_Y0, -DECK_Z0]) drive_deck();
else if (part == "drive_deck_2d") translate([-DECK_X0, -DECK_Y0]) drive_deck_2d();
else if (part == "world") { drive_gearbox_ph(); pin_coupling_ph(); gb_foot_bolts_ph(); rail_bolts_ph(); motor_ph(); motor_shaft_ph(); coupling_ph(); deck_ph(); deck_legs(); top_angles(); foot_angles(); holddown_hw_ph(); floor_ph();
                            cpl_guard(); stub_cap(); cg_screws_ph(); }
