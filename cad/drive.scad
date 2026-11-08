// drive.scad -- the drive: gearbox (foot-mounted, NRV063-VS placeholder) on two slotted rails, output shaft, TL350 torque limiter, #40 chain (swept band), idler chain tensioner,
// motor + pulleys + V-belt, belt guard (two printed halves, lapped, on feet), drive deck + legs + hold-down (leg angles, foot angles, floor anchors).  World frame.
//   -D 'part="gb_rail"|"gb_rail_2d"|"gb_spacer"|"gb_spacer_2d"|"leg_angle"|"tens_upright"|"tens_base"|"tens_upright_2d"|"tens_base_2d"|"output_shaft"|"output_shaft_2d"|"stop_collar"|
//        "belt_guard_a"|"belt_guard_b"|"drive_deck"|"drive_deck_2d"|"bom"|"world"'
//
// DIRECTION.  Shaft A turns NEGATIVE about +x.  Chain from sprocket A (15T) straight down to the TL350 30T sprocket on the gearbox output (2:1 speed-up).  The run that
//   moves toward A is the TIGHT run (-y side: A's -y flank moves up); the +y run moves away from A = SLACK.  The tensioner idler is on the +y (slack) run, INSIDE the loop.
// TL350 to the manufacturer's layout (tl350.scad): hub flange end toward the housing, 3 mm gap (a spacer on the shaft), the sprocket 12 mm from the flange-end face, springs
//   and adjusting nut on the outboard end.  GB_OHL_ARM = housing face to chain plane = 15.
// OUTPUT SHAFT  Ø25 h6, made from the bought 4140 bar: through the hollow output hub (GB_HUB_L), keyway 8 x 4 along the hub (gearbox key) and 8 x 4 under the TL hub (TL key); DIN 471 circlip
//   against the housing's far face; the TL is clamped between the 3 mm spacer on the housing face and a Ø35 x 5 stop collar (2 grub screws) on the outboard side.
// RAILS  two flats 50 x 10 under the foot rows, slots (+-6 mm along x) for the feet, M8 deck bolts outside the flange, on 4 spacer blocks (rail + spacer = SUBPLATE_T = 20: same heights).
// HOLD-DOWN  uplift path: gearbox feet -> rails (M8 through-bolts) -> deck -> 4 top angles (40x40x4, 2 x M8 through the deck, 2 x M8 through the leg) -> legs ->
//   4 foot angles (2 x M8 through the leg, 2 x M8 anchors each) -> floor.
// CHAIN TENSIONER (my choice): an idler sprocket (#40 15T, bought) on an M10 bolt in a slot (+-TENS_TRAVEL along y) of a 10 mm flat upright, welded to a base plate bolted to the deck.
include <common.scad>
include <joints.scad>
include <placeholders.scad>
include <tl350.scad>

// ---------------- gearbox, output shaft, torque limiter
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
    keyway_cut(TLKEY_X0, TLKEY_X1);                 // TL key
}
module output_shaft_ph() translate([0, YA, ZO]) output_shaft_local();
// the bought / made parts that hold the TL on the shaft (seated placeholders): circlip, 3 mm spacer on the housing face, stop collar
module circlip_ph()     translate([0, YA, ZO]) seat_x(CIRCLIP_OD, CIRCLIP_GROOVE_D, GB_X0 - CIRCLIP_T, CIRCLIP_T);
module out_spacer_ph()  translate([0, YA, ZO]) seat_x(OUT_SPACER_D, JOURNAL_D, GB_X1, TL_GB_GAP);
module stop_collar_ph() translate([0, YA, ZO]) seat_x(TL_COLLAR_D, JOURNAL_D, TL_COLLAR_X0, TL_COLLAR_T);
module shaft_hw_ph() { circlip_ph(); out_spacer_ph(); stop_collar_ph(); }
module tl_ph() translate([TL_X0, YA, ZO]) tl350_l();
module tl_plate_ph() translate([TL_X0, YA, ZO]) tl_plate_l();      // the sprocket's tooth plate alone
// stop collar, turned from the Ø55 bar, 2 x M6 grub screws (tap drill Ø5) at 90 deg
module stop_collar_part() difference() {
    cylinder(d = TL_COLLAR_D, h = TL_COLLAR_T, $fn = 64);
    translate([0, 0, -1]) cylinder(d = JOURNAL_D, h = TL_COLLAR_T + 2, $fn = 48);
    for (a = [0, 90]) rotate([0, 0, a]) translate([0, 0, TL_COLLAR_T / 2]) rotate([0, 90, 0]) cylinder(d = 5, h = TL_COLLAR_D / 2 + 1, $fn = 20);
}
// 2D drawing of the output shaft (side view with the keyway and the groove, plan view with the keyway slots; 1:1 mm; x = along the shaft from the far end)
module output_shaft_2d() {
    L = OUT_X1 - OUT_X0;  R = JOURNAL_D / 2;  g0 = GB_X0 - CIRCLIP_GROOVE_W - OUT_X0;
    difference() {                                                                               // side view (key side up)
        translate([0, -R]) square([L, 2 * R]);
        for (s = [-1, 1]) translate([g0, s > 0 ? CIRCLIP_GROOVE_D / 2 : -R - 1]) square([CIRCLIP_GROOVE_W, R - CIRCLIP_GROOVE_D / 2 + 1]);
        for (k = [[GBKEY_X0, GBKEY_X1], [TLKEY_X0, TLKEY_X1]]) translate([k[0] - OUT_X0, R - SHAFT_KEY_D]) square([k[1] - k[0], SHAFT_KEY_D + 1]);
    }
    translate([0, -2 * R - 15]) difference() {                                                   // plan view: the two keyway slots and the groove notches
        translate([0, -R]) square([L, 2 * R]);
        for (s = [-1, 1]) translate([g0, s > 0 ? CIRCLIP_GROOVE_D / 2 : -R - 1]) square([CIRCLIP_GROOVE_W, R - CIRCLIP_GROOVE_D / 2 + 1]);
        for (k = [[GBKEY_X0, GBKEY_X1], [TLKEY_X0, TLKEY_X1]]) hull() for (x = [k[0] - OUT_X0 + SHAFT_KEY_W / 2, k[1] - OUT_X0 - SHAFT_KEY_W / 2]) translate([x, 0]) circle(d = SHAFT_KEY_W, $fn = 32);
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

// ---------------- motor, pulleys, belt (placeholders)
module motor_ph() {
    translate([XM, Y_HF, ZM]) rotate([-90, 0, 0]) cylinder(d = MOTOR_D, h = MOTOR_LEN, $fn = 64);
    translate([XM - MOTOR_FOOT[0] / 2, Y_HF + (MOTOR_LEN - MOTOR_FOOT[1]) / 2, DECK_TOP]) cube(MOTOR_FOOT);
}
module pulley_ph(x, d, bore) translate([x, Y_HF - PUL_Y0 - PUL_W, ZM]) rotate([-90, 0, 0]) difference() { cylinder(d = d, h = PUL_W, $fn = 64); translate([0, 0, -1]) cylinder(d = bore + 0.1, h = PUL_W + 2, $fn = 48); }   // bored to its shaft
module pulleys_ph() { pulley_ph(XG, GEARBOX_PULLEY_D, 19); pulley_ph(XM, MOTOR_PULLEY_D, 12); }
module motor_shaft_ph() translate([XM, Y_HF - PUL_Y0 - PUL_W, ZM]) rotate([-90, 0, 0]) cylinder(d = 12, h = PUL_Y0 + PUL_W + 5, $fn = 48);
module belt_ph() {     // a 3 mm thick stadium loop round the two pulleys
    translate([0, Y_HF - PUL_Y0 - PUL_W / 2 - BELT_WIDTH / 2, 0]) rotate([-90, 0, 0]) linear_extrude(BELT_WIDTH)
        difference() {
            hull() { translate([XG, -ZM]) circle(d = GEARBOX_PULLEY_D + 6, $fn = 64); translate([XM, -ZM]) circle(d = MOTOR_PULLEY_D + 6, $fn = 64); }
            hull() { translate([XG, -ZM]) circle(d = GEARBOX_PULLEY_D, $fn = 64); translate([XM, -ZM]) circle(d = MOTOR_PULLEY_D, $fn = 64); }
        }
}
// ---------------- drive deck: REAL 18 mm plywood under the motor, the rails and the tensioner base, on 4 timber legs (45 x 45)
// Outline = motor foot / rails / tensioner base + margins, stretched toward -y so that the belt guard's four feet land on it.
// Holes: 8 x Ø4.2 pilots (belt guard feet), 8 x Ø5.5 (leg screws), 4 x Ø9 (rail bolts), 4 x Ø9 (tensioner base bolts), 8 x Ø9 (top-angle bolts).  The motor's own slots are not drilled.
assert(DECK_LEG_LEN >= DRIVE_LEG_MIN, str("drive deck legs too short (", DECK_LEG_LEN, " < ", DRIVE_LEG_MIN, "): CHAIN_CD too long for the floor"));
assert(DECK_X1 < -30);
function bg_foot_screw_uw() = [for (uc = BG_FOOT_U, du = [-BG_FOOT_DU, BG_FOOT_DU]) [uc + du, BG_W + BG_FOOT_REACH / 2]];   // the ONE definition of the foot screw positions (guard frame u, w)
function bg_foot_pts() = [for (q = bg_foot_screw_uw()) [XG - q[0], Y_HF - q[1]]];                                  // the same in the world (x, y): deck pilots
function deck_leg_screw_xy() = [for (c = DECK_LEG_C, dx = [-10, 10]) [c[0] + dx, c[1] + (c[1] < 0 ? 17 : -17)]];   // leg screws, 17 mm in from the leg centre toward the deck middle
module drive_deck_2d() difference() {
    translate([DECK_X0, DECK_Y0]) square([DECK_X1 - DECK_X0, DECK_Y1 - DECK_Y0]);
    for (p = bg_foot_pts()) translate(p) circle(d = 4.2, $fn = 24);                         // M5 wood screw pilots (belt guard feet)
    for (p = deck_leg_screw_xy()) translate(p) circle(d = 5.5, $fn = 24);                   // M5 leg screws (pilots Ø3.5 in the timber, deck_legs())
    for (p = RAIL_BOLT_PTS) translate(p) circle(d = 9, $fn = 24);                           // rail bolts
    for (p = TENS_BOLT_PTS) translate(p) circle(d = 9, $fn = 24);                           // tensioner base bolts
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
// the old name used by the tensioner base bolts: M8 from above through the part at ztop and the deck
module m8_nut_washer_under(p) translate([p[0], p[1], DECK_Z0 - HW_GAP - 1.6 - 8 - HW_GAP]) { cylinder(d = 14.4, h = 8, $fn = 6); translate([0, 0, 8 + HW_GAP]) cylinder(d = 16, h = 1.6, $fn = 32); }   // nut + washer under the deck
module m8_bolt(p, ztop) {       // washer 1.6 + head 5.3 on the part top at ztop, shank (Ø8) down through part + deck to the nut under the deck
    translate([p[0], p[1], DECK_Z0 - 8 - 1.6 - 4]) cylinder(d = 8, h = ztop + HW_GAP + 1.6 + 5.3 - (DECK_Z0 - 8 - 1.6 - 4), $fn = 20);
    translate([p[0], p[1], ztop + HW_GAP]) cylinder(d = 16, h = 1.6, $fn = 32);
    translate([p[0], p[1], ztop + HW_GAP + 1.6]) cylinder(d = 14.4, h = 5.3, $fn = 6);
    m8_nut_washer_under(p);
}
module tens_bolts_ph() for (p = TENS_BOLT_PTS) m8_bolt(p, TENS_BASE_Z1);

// ---------------- chain: a band (width CHAIN_ENV_W over the pins, link plate height CHAIN_ENV_H) round the pitch circles of A, the TL sprocket and the idler.
// All three circles are inside the loop, so the path is the convex hull of the three pitch circles.  ty = idler offset along its slot (mm), grow = extra clearance all round.
module chain_band2d(ty = 0, grow = 0) difference() {
    offset(delta = CHAIN_ENV_H / 2 + grow) hull() chain_circles2d(ty);
    offset(delta = -(CHAIN_ENV_H / 2 + grow)) hull() chain_circles2d(ty);
}
module chain_band(ty = 0, grow = 0) axial(X_CHAIN - CHAIN_ENV_W / 2 - grow) linear_extrude(CHAIN_ENV_W + 2 * grow) chain_band2d(ty, grow);
module chain_swept(grow = 0) for (ty = [-TENS_TRAVEL, 0, TENS_TRAVEL]) chain_band(ty, grow);     // idler anywhere in its slot

// ---------------- sprocket A, idler, tensioner (rotating sprockets, as full discs)
module sprocket_a_env(grow = 0) translate([0, YA, 0]) {      // hub + tooth plate of sprocket A as plain cylinders (swept over any angle)
    axial(x_sprocket_out - grow) cylinder(d = SPROCKET_A_hub_D + 2 * grow, h = SPROCKET_A_hub_L + 2 * grow, $fn = 64);
    axial(x_sprocket_out - grow) cylinder(d = SPA_OD_ + 2 * grow, h = SPROCKET_T + 2 * grow, $fn = 96);
}
// idler assembly at slot offset ty: disc (tooth plate OD 67.3 x 7.2 in the chain plane) + spacer tube to the upright + M10 bolt, washer, nut
module tens_idler_ph(ty = 0) translate([0, tens_y(ty), TENS_Z]) {
    axial(TL_PL0) difference() { cylinder(d = SPA_OD_, h = SPROCKET_T, $fn = 96); translate([0, 0, -1]) cylinder(d = 10.2, h = SPROCKET_T + 2, $fn = 24); }      // idler sprocket
    axial(TL_PL1) difference() { cylinder(d = TENS_SPACER_D, h = TENS_UP_X0 - TL_PL1 - HW_GAP, $fn = 32); translate([0, 0, -1]) cylinder(d = 10.2, h = TENS_UP_X0 - TL_PL1 + 2, $fn = 24); }   // spacer tube (0.01 short of the upright)
}
module tens_bolt_ph(ty = 0) translate([0, tens_y(ty), TENS_Z]) {
    x_head = TENS_UP_X1 + HW_GAP + TENS_WASHER_T;
    axial(x_head) cylinder(d = TENS_HEAD_D, h = TENS_HEAD_H_, $fn = 6);                                            // M10 head
    axial(TENS_UP_X1 + HW_GAP) cylinder(d = TENS_WASHER_D, h = TENS_WASHER_T, $fn = 32);                          // washer under the head
    axial(TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3) cylinder(d = TENS_AXLE_D, h = x_head - (TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3) + 0.01, $fn = 24);   // shank
    axial(TL_PL0 - 0.5 - TENS_WASHER_T) cylinder(d = TENS_WASHER_D, h = TENS_WASHER_T, $fn = 32);                  // washer 0.5 behind the idler
    axial(TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H) cylinder(d = TENS_HEAD_D, h = TENS_NUT_H, $fn = 6);          // nut
}
module tens_upright_2d() difference() {     // (y, z); x-thickness TENS_T.  L-shape: HEAD plate (carries the slot ALONG y for the M10 axle) + COLUMN down to the base, outside the chain guard
    union() {
        translate([TENS_HEAD_Y0, TENS_HEAD_Z0]) square([TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_HEAD_Z0]);
        translate([TENS_COL_Y0, TENS_BASE_Z1]) square([TENS_COL_W, TENS_UP_Z1 - TENS_BASE_Z1]);
    }
    hull() for (s = [-1, 1]) translate([TENS_Y0 + s * TENS_TRAVEL, TENS_Z]) circle(d = TENS_SLOT_W, $fn = 32);
}
module tens_upright() axial(TENS_UP_X0) linear_extrude(TENS_T) tens_upright_2d();
module tens_base_2d() difference() {        // (x, y); 10 thick
    translate([TENS_BASE_X0, TENS_BASE_Y0]) square([TENS_BASE[0], TENS_BASE_Y]);
    for (p = TENS_BOLT_PTS) translate(p) circle(d = 9, $fn = 24);
}
module tens_base() translate([0, 0, TENS_BASE_Z0]) linear_extrude(TENS_BASE_Z1 - TENS_BASE_Z0) tens_base_2d();
module tens_bolts_ph() for (p = TENS_BOLT_PTS) m8_bolt(p, TENS_BASE_Z1);
// ---------------- swept envelopes of the moving parts (full cylinders: any angle), every dimension grown by g (radially, and along x at both ends)
module cylx(r, x0, x1, y = 0, z = 0) translate([x0, y, z]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = 96);
module drive_end_env(g = 0, sprocket = true, shafts = ["A", "B"]) for (s = shafts) {
    y = shaft_y(s);
    cylx(GEAR_module * (GEAR_z + 2) / 2 + g, x_gear_out - g, x_gear_in + g, y);                 // gear (4 layers, OD 63.0; no hub)
    cylx(GEAR_SPACER_D / 2 + g, x_gear_hub_out - g, x_gear_out + g, y);                         // gear spacer sleeve
    cylx(COLLAR_OD / 2 + g, x_collar_out_drive - g, x_collar_in_drive + g, y);                  // collar
    cylx(THRUST_D / 2 + g, x_collar_in_drive - g, x_cap_out_drive + g, y);                      // thrust bearing
    xe = end_x_drive(s);
    cylx(15 + g, xe - END_WASHER_T - g, xe + g, y);                                             // end cap
    cylx(8 + g, xe - END_WASHER_T - 10 - g, xe - END_WASHER_T + g, y);                          // M10 head
    if (s == "A" && sprocket) {
        cylx(SPROCKET_A_hub_D / 2 + g, x_sprocket_out - g, x_sprocket_in + g, y);               // sprocket hub
        cylx(SPA_OD_ / 2 + g, x_sprocket_out - g, x_sprocket_out + SPROCKET_T + g, y);          // tooth plate
    }
}
module tl_env(g = 0) {         // TL350 body, tooth plate, spacer, stop collar, shaft end (static, but the guard hugs it)
    cylx(TL_D / 2 + g, TL_X0 - g, TL_X1 + g, YA, ZO);
    cylx(TL_OD_ / 2 + g, TL_PL0 - g, TL_PL1 + g, YA, ZO);
    cylx(OUT_SPACER_D / 2 + g, GB_X1 - g, TL_X0 + g, YA, ZO);
    cylx(TL_COLLAR_D / 2 + g, TL_COLLAR_X0 - g, TL_COLLAR_X1 + g, YA, ZO);
    cylx(JOURNAL_D / 2 + g, TL_COLLAR_X0 - g, OUT_X1 + g, YA, ZO);
}
module idler_env(g = 0, ty = 0) {   // idler sprocket, spacer, bolt head / washers / nut, shank, at slot offset ty
    y = tens_y(ty);
    cylx(SPA_OD_ / 2 + g, TL_PL0 - g, TL_PL1 + g, y, TENS_Z);
    cylx(TENS_SPACER_D / 2 + g, TL_PL1 - g, TENS_UP_X0 + g, y, TENS_Z);
    cylx(TENS_WASHER_D / 2 + g, TENS_UP_X1 - g, TENS_UP_X1 + TENS_WASHER_T + TENS_HEAD_H_ + 0.02 + g, y, TENS_Z);    // washer + head (head Ø16 inside)
    cylx(TENS_WASHER_D / 2 + g, TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3 - g, TL_PL0 - g, y, TENS_Z);         // washer, nut, bolt end behind the idler
}
module chain_drive_env(g = 0) { tl_env(g); for (ty = [-TENS_TRAVEL, 0, TENS_TRAVEL]) idler_env(g, ty); chain_swept(g); }
module tensioner_ph(ty = 0) { tens_upright(); tens_base(); tens_idler_ph(ty); tens_bolt_ph(ty); }
module drive_gearbox_ph() { gearbox_ph(); worm_ph(); output_shaft_ph(); tl_ph(); shaft_hw_ph(); gb_mount(); }

// ---------------- belt guard: two printed halves with a 16 mm LAP, bolted to the deck by 2 feet each
// u runs from the gearbox pulley axis toward the motor (world -x), v = world z - ZW, w = distance in front of the housing (-y).
// LAP     the gearbox half (A) runs on to u = U1 = 141 with a 6 mm thicker roof in the lap zone (room for 6 mm deep heat-set inserts); the
//         motor half (B) has a sleeve over A for u = 125 .. 141 (0.3 mm gap, 2.7 mm walls, open at the back) ending in a solid shoulder
//         that butts against A's end face.  3 x M4 x 8 go through B's sleeve roof (Ø4.5) into 3 x Ø5.6 x 6 inserts in A's roof pad.  The
//         screws are on the front (roof) face, so the guard comes apart from outside.
// FEET    each half has two printed feet: a 36 x 4 flange on the deck in front of the guard roof (2 x M5 x 20 wood screws into the 18 mm plywood
//         deck, blind, reachable from above) carried by two 3 mm ribs with a gusset, merged into the guard's lower wall.
BG_R1 = GEARBOX_PULLEY_D / 2 + BELT_GUARD_CLEAR;  BG_R2 = MOTOR_PULLEY_D / 2 + BELT_GUARD_CLEAR;
BG_SPLIT = BELT_CENTRE_DIST / 2;  BG_LAP = BG_LAP_LEN;  BG_U1 = BG_SPLIT + BG_LAP;                 // lap zone u = 125 .. 141
BG_PAD = 6;                                                     // roof pad of A in the lap zone (inserts live here)
BG_SLV = 2.7;                                                   // sleeve wall
BG_RS_IN = BG_WALL + BG_LAP_CLEAR;  BG_RS_OUT = BG_RS_IN + BG_SLV;      // sleeve inner / outer offset from the cavity: 3.3 / 6.0
BG_WS_IN = BG_W + BG_PAD + BG_LAP_CLEAR;  BG_WS_OUT = BG_WS_IN + BG_SLV;   // sleeve roof inner / outer w: 58.3 / 61.0
BG_SCREW_V = [-24, 0, 24];  BG_SCREW_U = BG_SPLIT + BG_LAP / 2;
BG_FOOT_U = [15, 95, 180, 245];                                  // foot centres (u): feet 0, 1 on half A, feet 2, 3 on half B
BG_FOOT_VF = DECK_TOP - ZW;                                      // v of the deck top, -70
BG_FOOT_DU = 8;  BG_FOOT_RIB = 3;  BG_FOOT_W0 = 12;
assert(BG_LAP >= 15);
module bg_cavity2d() hull() { circle(r = BG_R1, $fn = 96); translate([BELT_CENTRE_DIST, 0]) circle(r = BG_R2, $fn = 96); }
module bg_ring2d(t) hull() { circle(r = BG_R1 + t, $fn = 96); translate([BELT_CENTRE_DIST, 0]) circle(r = BG_R2 + t, $fn = 96); }
module bg_shell2d() bg_ring2d(BG_WALL);
function bg_vbot(u) = let (R0 = BG_R1 + BG_WALL, R1 = BG_R2 + BG_WALL, sa = (R0 - R1) / BELT_CENTRE_DIST) (u * sa - R0) / sqrt(1 - sa * sa);   // outer bottom of the hull
// whole guard in the (u, v, w) frame: w = 0 at the housing face
module bg_whole_uvw() {
    difference() {
        linear_extrude(BG_W) bg_shell2d();
        translate([0, 0, BG_BACK]) linear_extrude(BG_W - BG_BACK - BG_WALL) bg_cavity2d();
        translate([0, 0, -1]) cylinder(d = 30, h = BG_BACK + 2, $fn = 48);                            // gearbox input shaft (Ø19 stub)
        translate([BELT_CENTRE_DIST, 0, -1]) cylinder(d = 28, h = BG_BACK + 2, $fn = 48);           // motor shaft
    }
}
module bg_slab(u0, u1) translate([u0, -200, -1]) cube([u1 - u0, 400, 200]);
// one mounting foot (flange + 2 ribs + gussets) at u = uc, in the uvw frame
module bg_foot(uc) {
    vf = BG_FOOT_VF;  w1 = BG_W + BG_FOOT_REACH;  vb = bg_vbot(uc);
    difference() {
        union() {
            translate([uc - BG_FOOT_W / 2, vf, BG_FOOT_W0]) cube([BG_FOOT_W, BG_FOOT_T, w1 - BG_FOOT_W0]);            // flange on the deck
            for (du = [-1, 0, 1])                                                                                      // 3 ribs + gussets (polygon in w, v; extruded along u)
                multmatrix([[0, 0, 1, uc + du * (BG_FOOT_W / 2 - BG_FOOT_RIB / 2) - BG_FOOT_RIB / 2], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]])
                    linear_extrude(BG_FOOT_RIB) polygon([[BG_FOOT_W0, vf], [w1, vf], [BG_W, vb + 1], [BG_W, -10], [BG_FOOT_W0, -10]]);
        }
        // keep the guard cavity clear: nothing of the rib may enter the wall's inside
        translate([0, 0, -1]) linear_extrude(BG_W + 2) bg_ring2d(BG_WALL - 1.2);
        for (q = bg_foot_screw_uw()) if (abs(q[0] - uc) < BG_FOOT_DU + 0.01) translate([q[0], vf - 1, q[1]]) rotate([-90, 0, 0]) {   // M5 clearance + countersink
            cylinder(d = 5.5, h = BG_FOOT_T + 2, $fn = 24);
            translate([0, 0, BG_FOOT_T - 1.6 + 1]) cylinder(d1 = 5.5, d2 = 10.5, h = 1.61, $fn = 24);
        }
    }
}
// KEEP-OUT: the chain guard (dg_lower: hull of the chain circles grown GUARD_CLEAR + PRINT_WALL, from the housing face) and the chain itself cross the gearbox half's round cap, because the TL350
// sprocket is only 15 mm from the housing face and the Ø68 pulley sits at the housing's middle.  The cap is cut away there (0.3 mm off the chain guard's outside); the chain guard's wall closes the opening.
module bg_keepout_world() axial(GB_X1 - 0.3) linear_extrude(60) chain_hull2d(GUARD_CLEAR + PRINT_WALL + 0.3);
module bg_keepout_uvw() multmatrix([[-1, 0, 0, XG], [0, 0, 1, -ZW], [0, -1, 0, Y_HF], [0, 0, 0, 1]]) bg_keepout_world();     // world (x, y, z) -> guard frame (u, v, w)
module bg_half_uvw(h) {      // h = 0: gearbox half A, h = 1: motor half B
    if (h == 0) difference() {
        union() {
            intersection() { bg_whole_uvw(); bg_slab(-200, BG_U1); }
            intersection() {                                                      // roof pad in the lap zone
                translate([0, 0, BG_W - 0.01]) linear_extrude(BG_PAD + 0.01) bg_shell2d();
                bg_slab(BG_SPLIT, BG_U1);
            }
            for (i = [0, 1]) bg_foot(BG_FOOT_U[i]);
        }
        for (v = BG_SCREW_V) translate([BG_SCREW_U, v, BG_W + BG_PAD - INSERT_DEPTH]) cylinder(d = INSERT_D, h = INSERT_DEPTH + 1, $fn = 32);   // M4 heat-set inserts
        bg_keepout_uvw();
    } else difference() {
        union() {
            intersection() { bg_whole_uvw(); bg_slab(BG_U1 + BG_SLV - 0.01, 400); }
            intersection() {                                                      // shoulder: solid, butts against A's end face
                difference() {
                    linear_extrude(BG_WS_OUT) bg_ring2d(BG_RS_OUT);
                    translate([0, 0, BG_BACK]) linear_extrude(BG_W - BG_BACK - BG_WALL) bg_cavity2d();
                }
                bg_slab(BG_U1, BG_U1 + BG_SLV);
            }
            intersection() {                                                      // sleeve over A: open at the back
                difference() {
                    linear_extrude(BG_WS_OUT) bg_ring2d(BG_RS_OUT);
                    translate([0, 0, -1]) linear_extrude(BG_WS_IN + 1) bg_ring2d(BG_RS_IN);
                }
                bg_slab(BG_SPLIT, BG_U1);
            }
            for (i = [2, 3]) bg_foot(BG_FOOT_U[i]);
        }
        for (v = BG_SCREW_V) translate([BG_SCREW_U, v, BG_WS_IN - 1]) cylinder(d = 4.5, h = BG_SLV + 2, $fn = 24);       // M4 clearance holes
    }
}
module bg_uvw_to_world() multmatrix([[-1, 0, 0, XG], [0, 0, -1, Y_HF], [0, 1, 0, ZW], [0, 0, 0, 1]]) children();
module belt_guard(h) bg_uvw_to_world() bg_half_uvw(h);
module belt_guard_hw_ph() bg_uvw_to_world() {
    for (v = BG_SCREW_V) translate([BG_SCREW_U, v, BG_WS_OUT]) { cylinder(d = 7.5, h = 2.4, $fn = 24); translate([0, 0, -10]) cylinder(d = 4, h = 10.01, $fn = 16); }   // M4 x 10 button head screws
    for (q = bg_foot_screw_uw()) translate([q[0], BG_FOOT_VF + BG_FOOT_T, q[1]]) rotate([90, 0, 0])
        { translate([0, 0, -3]) cylinder(d = 9.5, h = 3, $fn = 24); cylinder(d = 5, h = 20 + 0, $fn = 16); }                                    // M5 x 20 wood screws (CSK)
}
// ---------------- check helper: a thin slab across the guard at u0 .. u1, in world coordinates
module bg_probe_slab(u0, u1) bg_uvw_to_world() translate([u0, -300, -10]) cube([u1 - u0, 600, 300]);

// ---------------- accessors for checks.scad / guards.scad (variables of a `use`d file are not visible)
function deck_geom() = [DECK_X0, DECK_X1, DECK_Y0, DECK_Y1, DECK_Z0, DECK_Z1];
function worm_axis() = [XG, ZW];
function motor_axis_z() = ZM;
function gb_mount_box() = [[RAIL_X0, RAIL_Y_LO, DECK_TOP], [RAIL_X1 - RAIL_X0, RAIL_Y_HI - RAIL_Y_LO, SUBPLATE_T]];
function tens_upright_box() = [[TENS_UP_X0, TENS_HEAD_Y0, TENS_BASE_Z1], [TENS_T, TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_BASE_Z1]];     // bounding box (C5 shrink centre)
function tens_upright_boxes() = [[[TENS_UP_X0, TENS_HEAD_Y0, TENS_HEAD_Z0], [TENS_T, TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_HEAD_Z0]],        // head plate
                                 [[TENS_UP_X0, TENS_COL_Y0, TENS_BASE_Z1], [TENS_T, TENS_COL_W, TENS_HEAD_Z0 - TENS_BASE_Z1]]];                     // column
function tens_base_box() = [[TENS_BASE_X0, TENS_BASE_Y0, TENS_BASE_Z0], [TENS_BASE[0], TENS_BASE_Y, TENS_BASE_Z1 - TENS_BASE_Z0]];

// ---------------- joint alignment shanks (checks.scad C16): a bolt shank through the hole of part 1 AND the hole of part 2; it must touch neither part's material
module bg_foot_shanks() for (p = bg_foot_pts()) translate([p[0], p[1], DECK_Z0 + 2]) cylinder(d = 4, h = DECK_T + BG_FOOT_T + 4, $fn = 16);        // M5 wood screw core: guard foot Ø5.5 + deck pilot Ø4.2
module deck_leg_shanks() for (p = deck_leg_screw_xy()) translate([p[0], p[1], DECK_Z0 - 29]) cylinder(d = 3.3, h = DECK_T + 31, $fn = 16);          // M5 wood screw core: deck Ø5.5 + leg pilot Ø3.5
module gbfoot_shanks() for (p = gb_foot_pts()) translate([p[0], p[1], RAIL_Z0 - 3]) cylinder(d = 8, h = GB_RAIL_T + GB_FLANGE[2] + 6, $fn = 24);     // M8: flange Ø9 + rail slot 9
module subbolt_shanks() for (p = RAIL_BOLT_PTS) translate([p[0], p[1], DECK_Z0 - 3]) cylinder(d = 8, h = DECK_T + SUBPLATE_T + 6, $fn = 24);        // M8: rail Ø9 + spacer Ø9 + deck Ø9
module tbase_shanks() for (p = TENS_BOLT_PTS) translate([p[0], p[1], DECK_Z0 - 3]) cylinder(d = 8, h = DECK_T + (TENS_BASE_Z1 - TENS_BASE_Z0) + 6, $fn = 24);   // M8: base Ø9 + deck Ø9
module tens_axle_shanks(ty = 0) translate([0, tens_y(ty), TENS_Z]) axial(TENS_UP_X0 - 3) cylinder(d = TENS_AXLE_D, h = TENS_T + 6, $fn = 24);          // M10 through the slot (ty = +-10: slot end)
module topdeck_shanks() for (p = TOPANG_DECK_PTS) translate([p[0], p[1], DECK_Z0 - ANG_T - 3]) cylinder(d = 8, h = DECK_T + ANG_T + 6, $fn = 24);        // M8: deck Ø9 + top angle Ø9
module topleg_shanks() for (c = DECK_LEG_C) for (p = legpts(c, TOPANG_LEG_PTS)) translate([p[0], p[1] + leg_sy(c) * (ANG_T + 3), TOPANG_LEG_Z]) orient([0, -leg_sy(c), 0]) cylinder(d = 8, h = ANG_T + LEG_SECTION + 6, $fn = 24);
module footleg_shanks() for (c = DECK_LEG_C) for (p = legpts(c, FOOTANG_LEG_PTS)) translate([p[0] + leg_sx(c) * (ANG_T + 3), p[1], FOOTANG_LEG_Z]) orient([-leg_sx(c), 0, 0]) cylinder(d = 8, h = ANG_T + LEG_SECTION + 6, $fn = 24);
module anchor_shanks() for (p = ANCHOR_PTS) translate([p[0], p[1], GROUND_Z - FLOOR_T - 3]) cylinder(d = 8, h = FLOOR_T + ANG_T + 6 + 0.02, $fn = 24);    // M8 anchor: foot angle Ø9 + floor hole Ø8.5
module bg_lap_u() echo(str("BG lap u = ", BG_SPLIT, " .. ", BG_U1, "  length ", BG_LAP));
function r1_(v) = round(10 * v) / 10;
function anchor_pts_r() = [for (p = ANCHOR_PTS) [r1_(p[0]), r1_(p[1])]];

part = "world";
if (part == "gb_rail") translate([-RAIL_X0, -RAIL_Y_LO, -RAIL_Z0]) gb_rail_at(0);
else if (part == "gb_rail_2d") translate([-RAIL_X0, -RAIL_Y_LO]) translate([GB_XC, RAIL_YC[0]]) rail_local_2d();
else if (part == "gb_spacer") gb_spacer_part();
else if (part == "leg_angle") leg_angle();
else if (part == "tens_upright") translate([-TENS_HEAD_Y0, -TENS_BASE_Z1, 0]) linear_extrude(TENS_T) tens_upright_2d();
else if (part == "tens_upright_2d") translate([-TENS_HEAD_Y0, -TENS_BASE_Z1]) tens_upright_2d();
else if (part == "tens_base") translate([-TENS_BASE_X0, -TENS_BASE_Y0, -TENS_BASE_Z0]) tens_base();
else if (part == "tens_base_2d") translate([-TENS_BASE_X0, -TENS_BASE_Y0]) tens_base_2d();
else if (part == "output_shaft") { echo(str("GB_OHL_ARM = ", GB_OHL_ARM)); translate([-OUT_X0, 0, 0]) output_shaft_local(); }
else if (part == "output_shaft_2d") output_shaft_2d();
else if (part == "stop_collar") stop_collar_part();
else if (part == "belt_guard_a" || part == "belt_guard_b")
    // print pose: back wall (w = 0 .. BG_BACK) face down; u along x
    translate([200, 200, 0]) bg_half_uvw(part == "belt_guard_a" ? 0 : 1);
else if (part == "bom") {
    echo(str("GB_OHL_ARM = ", GB_OHL_ARM, "  (gearbox housing face x = ", GB_X1, " to chain plane x = ", X_CHAIN, " = TL_GB_GAP ", TL_GB_GAP, " + TL_CM_OFFSET ", TL_CM_OFFSET, "; housing ", GB_HUB_L, " wide, x ", GB_X0, " .. ", GB_X1, ")"));
    echo(str("BOM deck: ", DECK_PLY_T, " mm plywood ", DECK_X1 - DECK_X0, " x ", DECK_Y1 - DECK_Y0, "  (x ", DECK_X0, " .. ", DECK_X1, ", y ", DECK_Y0, " .. ", DECK_Y1, ", top z = ", DECK_Z1, "); legs 4 x ", LEG_SECTION, " x ", LEG_SECTION, " x ", DECK_LEG_LEN, " timber, floor z = ", DRIVE_FLOOR_Z, " (bench / cabinet underside z = ", GROUND_Z, ")"));
    echo(str("BOM gearbox rails: 2 x flat 50 x 10 x ", RAIL_X1 - RAIL_X0, " (mild steel, from the 50 x 10 stock), 2 slots 9 x ", 9 + 2 * GB_RAIL_SLOT, " along x (+-", GB_RAIL_SLOT, " mm chain alignment) for the gearbox feet + 2 x Ø9 deck holes each; 4 spacer blocks 50 x 10 x ", GB_SPACER_L, " (Ø9 hole); 4 x M8 x 40 foot bolts (flange, rail slot, washer + nut under the rail), 4 x M8 x 55 rail bolts through rail, spacer, deck (Ø24 penny washer + nut under the deck)"));
    echo(str("BOM output shaft: Ø25 h6 x ", OUT_X1 - OUT_X0, " from the bought 4140 bar: circlip groove Ø", CIRCLIP_GROOVE_D, " x ", CIRCLIP_GROOVE_W, " at the housing's far face (DIN 471 25 mm circlip), keyway 8 x 4 x ", GBKEY_X1 - GBKEY_X0, " in the ", GB_HUB_L, " mm hollow hub (gearbox key), keyway 8 x 4 x ", TLKEY_X1 - TLKEY_X0, " under the TL hub (TL key); spacer Ø", OUT_SPACER_D, " x ", TL_GB_GAP, "; stop collar Ø", TL_COLLAR_D, " x ", TL_COLLAR_T, " + 2 grub screws; shaft end ", SHAFT_OUT_END, " beyond the collar"));
    echo(str("BOM TL350-2: flange end ", TL_GB_GAP, " mm off the housing (x ", TL_X0, "), sprocket mid-plane x ", X_CHAIN, " (", TL_CM_OFFSET, " from the flange-end face), nut end x ", TL_X1, "; hub ", TL_L, " x Ø", TL_HUB_D, ", outer Ø", TL_D));
    echo(str("BOM hold-down: chain uplift at the limiter limit ", CHAIN_UPLIFT_LIMIT_N, " N (design ", CHAIN_UPLIFT_DESIGN_N, " N).  Load path: gearbox feet -> 2 rails -> 4 x M8 rail bolts -> deck -> ", len(DECK_LEG_C), " top angles (40x40x4 x ", ANG_L, ", ", DECK_ANGLE_DECK_BOLTS, " x M8 through the deck + ", DECK_ANGLE_LEG_BOLTS, " x M8 through the leg each) -> legs -> ", len(DECK_LEG_C), " foot angles (", FOOT_ANGLE_LEG_BOLTS, " x M8 through the leg each) -> ", len(ANCHOR_PTS), " x ", DECK_ANCHOR, " anchors (floor wedge / drop-in anchors or coach screws into the bench)"));
    echo(str("DECK_ANCHORS n = ", len(ANCHOR_PTS), ", positions (x, y) = ", anchor_pts_r(), ", floor z = ", DRIVE_FLOOR_Z, "; rail bolts n = ", len(RAIL_BOLT_PTS), " at ", [for (p = RAIL_BOLT_PTS) [r1_(p[0]), r1_(p[1])]]));
    echo(str("BOM tensioner: L-shaped upright (head plate 40 x 10 x ", TENS_COL_Y1 - TENS_HEAD_Y0, " with slot ", TENS_SLOT_L, " x ", TENS_SLOT_W, " at z = ", TENS_Z, " welded to a column 30 x 10 x ", TENS_UP_Z1 - TENS_BASE_Z1, " flats), base 10 mm x ", TENS_BASE[0], " x ", TENS_BASE_Y, "; chain ", CHAIN_ENV_W, " wide, idler nominal y = ", TENS_Y0, " (slack run pushed out ", TENS_DELTA, ")"));
    echo(str("BOM idler sprocket (BOUGHT): ", IDLER_NAME, " on an M10 bolt, ", TENS_UP_X0 - TL_PL1, " mm spacer tube; not made"));
    echo(str("BOM belt guard: lap ", BG_LAP, " mm, 3 x M4 x 8 into M4 heat-set inserts (", INSERT_D, " x ", INSERT_DEPTH, " in half A), 8 x M5 x 20 wood screws (2 per foot, 2 feet per half) into the deck"));
}
else if (part == "drive_deck") translate([-DECK_X0, -DECK_Y0, -DECK_Z0]) drive_deck();
else if (part == "drive_deck_2d") translate([-DECK_X0, -DECK_Y0]) drive_deck_2d();
else if (part == "world") { drive_gearbox_ph(); gb_foot_bolts_ph(); rail_bolts_ph(); motor_ph(); pulleys_ph(); belt_ph(); deck_ph(); deck_legs(); top_angles(); foot_angles(); holddown_hw_ph(); floor_ph();
                            tensioner_ph(); tens_bolts_ph(); chain_band(0); belt_guard(0); belt_guard(1); belt_guard_hw_ph(); }
