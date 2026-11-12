// hopper.scad -- collar + funnel + lid (printed, PETG), world frame.  Export: -D 'part="collar"|"funnel"|"lid"' (print pose),
// -D 'part="world"' (assembled, closed).
//
// COLLAR  rests on the wall tops (z = 55) and on the inner end-plate layers' top edges (z = 35).  Its inner faces continue the
//   chamber: x = 0 and x = chamber_L from z = 35, |y| = 66 from z = 55, up to HOPPER_SPLIT_Z.  It is fixed with eight M5 socket screws (M5x75 end, M5x55 wall) (heads in Ø9 pockets in the collar top face, covered by the funnel flange) into the new tapped holes.
//   SPEC PROBLEM: the screw holes sit only 5 mm from the chamber faces, so a 3 mm wall round a Ø5.5 hole (or a Ø9 head pocket)
//   cannot stay behind the face.  Each of the eight screws therefore has a 15.5 mm wide pillar that is BUMP = 2.5 mm proud of
//   the nominal face into the throat (it is above z = 35, outside every blade envelope).  Everything else is on the nominal faces.
// FUNNEL  132.2 x 132 inner throat at z = HOPPER_SPLIT_Z flaring to 180 x 180 inner at z = HOPPER_TOP_Z; M4 flange bolts to the collar.
// LID     hinged at +y (M5 pin through printed knuckles), 10 mm overlap all round, handle at -x.  INTERLOCK: the Pizzato FS 3096D024-F7 guard-locking
//   switch (interlock.scad, APPROXIMATE envelope HSW_*: 42 x 38 x 112, drill to Pizzato's 2D drawing) sits on the flat PAD on the +x side of the funnel (2 x Ø3.3 pilots for
//   its M4 screws, 22 apart); its jointed actuator VF KEYF7 (HACT_*, approx.) is screwed (2 x M5, ~30 apart) to the flat face of a small printed LID ACTUATOR PAD
//   (part lid_act_pad) that is bolted to the lid ear (2 x M4 into heat-set inserts in the pad, from under the ear).  The blade passes through a slot in the ear
//   and enters the switch head INTERLOCK_IN = 12 mm when the lid is down; after ~7 deg of opening it is out (checks C17).  There is NO printed tongue.
//   (Locked with no power: wiring, not CAD.)
//   Why a separate pad: the actuator's mounting block must sit ABOVE the tip, i.e. above the lid plate; printed as one piece the lid
//   (printed top face down so that nothing needs support) would have to stand on that tower.
include <common.scad>
// the lid switch = Pizzato FS 3096D024-F7 + VF KEYF7 (all approximate); interlock.scad is a template built from these values
IL_SW_BODY = HSW_BODY;  IL_SW_HOLE_SPACING = HSW_HOLE_SPACING;  IL_SW_SLOT = HSW_SLOT;  IL_SW_SCREW = HSW_SCREW;
IL_ACT_SIZE = HACT_SIZE;  IL_ACT_BLADE_T = HACT_BLADE_T;  IL_ACT_BLADE_L = HACT_BLADE_L;  IL_ACT_HOLE_SPACING = HACT_HOLE_SPACING;  IL_ACT_SCREW = HACT_SCREW;
include <interlock.scad>

L = chamber_L;  XC = L / 2;  ZS = HOPPER_SPLIT_Z;  ZT = HOPPER_TOP_Z;
W = PRINT_WALL;  FT = PRINT_FLANGE;  HW = wall_inner_y;              // HW = 66
CFT = 7;                                                             // collar flange thickness (nut pockets)
FL_X = 18;  FL_Y = 82;                                               // flange reaches x in [-18, L+18], |y| <= 82
BUMP = 2.5;  HEAD_D = 9;  HEAD_DEPTH = 6;
PIN_Z = ZT - 7;  PIN_Y = 103;  KN_R = 6;   // axis 7 below the rim top so the knuckles never reach the lid plate (z 305..308)                                 // hinge axis (along x)
PAD_X = XC + 102;                                                    // vertical face of the interlock-switch pad (+x side)
LID_T = 3;
SW_TOP = ZT + LID_T + 0.5 + INTERLOCK_IN - ACT_BL;                   // switch head end face: the actuator block (b = INTERLOCK_IN - ACT_BL above it) then clears the lid top by 0.5
SW_Z0 = SW_TOP - SW_L;                                               // 186.5 (112 long switch)
PAD_Z = [SW_Z0 - 1, SW_TOP + 1];
HPAD_W = HSW_PAD_W;                                                  // width (y) of the funnel switch pad: 48 for the 42 wide body
// switch frame S (a, b, c) of interlock.scad -> world: a -> +x (out of the funnel pad), b -> -z (head end face at the top), c -> +y
module hop_world() multmatrix([[1, 0, 0, PAD_X], [0, 0, 1, 0], [0, -1, 0, SW_TOP], [0, 0, 0, 1]]) children();
LIDPAD_B = [INTERLOCK_IN - ACT_L - 2, SW_TOP - (ZT + LID_T)];        // lid actuator pad (tower) extent along b: -58 .. -9.5 (world z 357 .. 308 = the lid ear's top)
LIDPAD_A = [-1, A_OFF];                                              // 10 thick, its flat face at a = A_OFF carries the actuator
LIDPAD_SCREW_A = (LIDPAD_A[0] + LIDPAD_A[1]) / 2;                    // the 2 x M4 that hold it on the ear: at a = 4, c = +-9
LIDPAD_SCREW_C = 9;
function lid_ear_screw_xy() = [for (s = [-1, 1]) [PAD_X + LIDPAD_SCREW_A, s * LIDPAD_SCREW_C]];   // world (x, y), the ONE definition for the ear holes and the pad's inserts
assert(SW_Z0 > PAD_Z[0] && SW_TOP < PAD_Z[1]);

// funnel inner half sizes at height z (x about XC, y about 0)
function fx(z) = XC + (HOPPER_TOP_IN / 2 - XC) * (z - ZS) / (ZT - ZS);
function fy(z) = HW + (HOPPER_TOP_IN / 2 - HW) * (z - ZS) / (ZT - ZS);
module slab(hx, hy, z) translate([XC - hx, -hy, z]) cube([2 * hx, 2 * hy, 0.01]);
module loft(off, z0, z1) hull() { slab(fx(z0) + off, fy(z0) + off, z0); slab(fx(z1) + off, fy(z1) + off, z1 - 0.01); }

END_SCREW_X = [-5, L + 5];                                           // centred in the inner layers
// M4 flange bolts (x, y)
BOLTS = concat([for (x = [12, XC, L - 12], s = [-1, 1]) [x, s * 72]],
               [for (e = [-8.5, L + 8.5], y = [-57, -20, 20, 57]) [e, y]]);
module flange_box(z0, t) translate([-FL_X, -FL_Y, z0]) cube([L + 2 * FL_X, 2 * FL_Y, t]);

// ------------------------------------------------------------------ collar
module collar() {
    $fn = 48;
    difference() {
        union() {
            for (x0 = [-10, L]) translate([x0, -76, 35]) cube([10, 152, 20]);                   // end blocks on the plate tops
            for (x0 = [-W, L]) translate([x0, -(HW + W), 35]) cube([W, 2 * (HW + W), ZS - 35]);   // end skins (inner face x = 0 / L)
            for (s = [-1, 1]) {
                translate([0, s > 0 ? HW : -76, 55]) cube([L, 10, 14]);                           // side feet on the wall tops
                translate([0, s > 0 ? HW : -(HW + W), 55]) cube([L, W, ZS - 55]);                 // side skins
            }
            flange_box(ZS - CFT, CFT);
            // screw pillars (BUMP proud of the faces)
            for (xs = END_SCREW_X, s = [-1, 1])
                translate([xs < 0 ? -13 : L - BUMP, s * TOP_HOLE_Y - 7.75, 35]) cube([13 + BUMP, 15.5, ZS - 35]);
            for (x = [WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X], s = [-1, 1])
                translate([x - 7.75, s > 0 ? HW - BUMP : -76, 55]) cube([15.5, 76 - HW + BUMP, ZS - 55]);
        }
        // throat (cut everything inside the nominal faces EXCEPT the pillars: cut first, pillars re-added below)
        difference() {
            translate([0, -HW, 34]) cube([L, 2 * HW, ZS - 34 + 1]);
            for (xs = END_SCREW_X, s = [-1, 1])
                translate([xs < 0 ? -1 : L - BUMP, s * TOP_HOLE_Y - 7.75, 34]) cube([1 + BUMP, 15.5, ZS - 34 + 1]);
            for (x = [WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X], s = [-1, 1])
                translate([x - 7.75, s > 0 ? HW - BUMP : -HW - 0.001, 34]) cube([15.5, BUMP, ZS - 34 + 1]);
        }
        // end screws
        for (xs = END_SCREW_X, y = [-TOP_HOLE_Y, TOP_HOLE_Y]) {
            translate([xs, y, 34]) cylinder(d = 5.5, h = ZS - 33);
            translate([xs, y, ZS - HEAD_DEPTH]) cylinder(d = HEAD_D, h = HEAD_DEPTH + 1);
        }
        // side screws
        for (x = [WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X], y = [-WALL_TOP_HOLE_Y, WALL_TOP_HOLE_Y]) {
            translate([x, y, 54]) cylinder(d = 5.5, h = ZS - 53);
            translate([x, y, ZS - HEAD_DEPTH]) cylinder(d = HEAD_D, h = HEAD_DEPTH + 1);
        }
        // M4 flange bolts + hex nut pockets (7 AF) from below
        for (p = BOLTS) {
            translate([p[0], p[1], ZS - CFT - 1]) cylinder(d = 4.5, h = CFT + 2);
            translate([p[0], p[1], ZS - CFT - 1]) cylinder(d = 8.3, h = 1 + 3.4, $fn = 6);
        }
    }
}

// ------------------------------------------------------------------ funnel
module knuckles_funnel() for (s = [-1, 1])
    translate([XC + s * 57.5 - 12.5, 0, 0]) hull() {
        translate([0, 93, PIN_Z - KN_R]) cube([25, 4, 2 * KN_R - 1]);                         // web on the rim (top at z = 304 < lid 305)
        translate([0, PIN_Y, PIN_Z]) rotate([0, 90, 0]) cylinder(r = KN_R, h = 25, $fn = 48);
    }
module funnel() {
    $fn = 48;
    difference() {
        union() {
            difference() { loft(W, ZS, ZT); loft(0, ZS - 1, ZT + 1); }
            difference() { flange_box(ZS, FT); translate([0, -HW, ZS - 1]) cube([L, 2 * HW, FT + 2]); }   // bottom flange
            difference() {                                                                                   // top rim
                translate([XC - 95, -95, ZT - 4]) cube([190, 190, 4]);
                translate([XC - HOPPER_TOP_IN / 2, -HOPPER_TOP_IN / 2, ZT - 5]) cube([HOPPER_TOP_IN, HOPPER_TOP_IN, 6]);
            }
            // interlock pad on +x: vertical face at PAD_X, 45 deg underside back to the slanted wall
            hull() {
                translate([XC + fx(PAD_Z[0] - 22) + W - 1, -HPAD_W / 2, PAD_Z[0] - 22]) cube([1, HPAD_W, 1]);
                translate([PAD_X - 0.01, -HPAD_W / 2, PAD_Z[0]]) cube([0.01, HPAD_W, PAD_Z[1] - PAD_Z[0]]);
                translate([XC + fx(PAD_Z[1]) + W - 1, -HPAD_W / 2, PAD_Z[1] - 1]) cube([1, HPAD_W, 1]);
            }
            knuckles_funnel();
        }
        for (p = BOLTS) translate([p[0], p[1], ZS - 1]) cylinder(d = 4.5, h = FT + 2);
        hop_world() sw_pad_pilots();                   // 2 x Ø3.3 pilots for the switch's M4 screws, HSW_HOLE_SPACING (22) apart
        translate([XC - 120, PIN_Y, PIN_Z]) rotate([0, 90, 0]) cylinder(d = 5.3, h = 240, $fn = 24);
        loft(0, ZS - 1, ZT + 1);                       // keep the throat clear of the pad block
    }
}

// ------------------------------------------------------------------ lid (closed pose, world frame)
module lid() {
    $fn = 48;
    difference() {
        union() {
            translate([XC - 100, -100, ZT]) cube([200, 200, 3]);                          // 10 mm overlap round the 180 opening
            translate([XC - 115, -20, ZT]) cube([16, 40, 3]);                             // handle tab (-x)
            translate([XC - 115, -20, ZT - 12]) cube([4, 40, 12]);                        // handle lip hanging below the tab (printed top-down)
            translate([XC + 99, -SW_PAD_W / 2 - 1, ZT]) cube([PAD_X + A_OFF + ACT_H + 3 - (XC + 99), SW_PAD_W + 2, LID_T]);   // ear under the actuator pad (flat, no tongue)
            hull() {                                                                      // hinge arm + knuckle
                translate([XC - 44, 96, ZT]) cube([88, 4, 3]);
                translate([XC - 44, PIN_Y, PIN_Z]) rotate([0, 90, 0]) cylinder(r = KN_R, h = 88);
            }
        }
        translate([XC - 112, -9, ZT - 1]) cube([10, 18, 5]);                              // finger slot in the handle tab
        translate([PAD_X + SW_D / 2 - IL_SW_SLOT[0] / 2, -IL_SW_SLOT[1] / 2, ZT - 1]) cube([IL_SW_SLOT[0], IL_SW_SLOT[1], LID_T + 2]);   // slot for the blade through the ear (same size as the switch slot)
        for (p = lid_ear_screw_xy()) translate([p[0], p[1], ZT - 1]) cylinder(d = HOLE_D, h = LID_T + 2, $fn = 24);   // M4 clearance holes for the pad screws
        translate([XC - 120, PIN_Y, PIN_Z]) rotate([0, 90, 0]) cylinder(d = 5.3, h = 240, $fn = 24);
    }
}
module switch_ph() hop_world() sw_ph();                                          // the safety switch (placeholder), on the funnel pad
module switch_env() hop_world() sw_body_env();                                   // body without the slot
module switch_slot() hop_world() sw_slot();
module switch_screws_ph() hop_world() sw_screws_ph();
// lid actuator pad (printed, PETG): a 10 x 35 x 32 block standing on the lid ear.  Flat face at a = A_OFF carries the actuator (2 pilots);
// 2 heat-set insert pockets in its foot take the M4 screws that come from under the ear.
module lid_pad_s() difference() {
    translate([LIDPAD_A[0], LIDPAD_B[0], -SW_PAD_W / 2]) cube([LIDPAD_A[1] - LIDPAD_A[0], LIDPAD_B[1] - LIDPAD_B[0], SW_PAD_W]);
    act_in_sw() act_pad_pilots();
    for (c = [-LIDPAD_SCREW_C, LIDPAD_SCREW_C]) translate([LIDPAD_SCREW_A, LIDPAD_B[1] + 0.01, c]) rotate([90, 0, 0]) cylinder(d = INSERT_D, h = INSERT_DEPTH + 0.01, $fn = 32);
}
module lid_pad() hop_world() lid_pad_s();
module lid_pad_screws_ph() for (p = lid_ear_screw_xy()) translate([p[0], p[1], ZT]) {          // M4 x 12 pan head screws from under the ear into the inserts
    translate([0, 0, -2.8]) cylinder(d = SCREW_HEAD_D, h = 2.8, $fn = 24);
    cylinder(d = SCREW_D, h = 12 - 2.8 + 0.5, $fn = 20);
}
module hop_actuator() hop_world() act_in_sw() act_ph();                          // the coded actuator (placeholder), engaged
module hop_actuator_screws_ph() hop_world() act_in_sw() act_screws_ph();
module hop_blade() hop_world() blade_env();                                      // the blade only
module hop_slot_from(depth) hop_world() intersection() {                          // the part of the switch slot deeper than `depth` from the mouth
    sw_slot();
    translate([-1, depth, -50]) cube([40, 100, 100]);
}
module hop_switch_shanks() hop_world() sw_shanks();
module hop_actuator_shanks() hop_world() act_in_sw() act_shanks();
module lid_screw_shanks() for (p = lid_ear_screw_xy()) translate([p[0], p[1], ZT - 1]) cylinder(d = 4, h = LID_T + 1 + 4, $fn = 20);   // M4: ear Ø4.5 + insert Ø5.6
module hinge_pin_ph() translate([XC - 80, PIN_Y, PIN_Z]) rotate([0, 90, 0]) cylinder(d = 5, h = 160, $fn = 24);
// lid_posed: a = 0 closed; positive a lifts the front edge about the hinge
function lid_pad_box() = [[PAD_X + LIDPAD_A[0], -SW_PAD_W / 2, SW_TOP - LIDPAD_B[1]], [LIDPAD_A[1] - LIDPAD_A[0], SW_PAD_W, LIDPAD_B[1] - LIDPAD_B[0]]];
function lid_box() = [[XC - 115, -100, ZT - 12], [PAD_X + A_OFF + ACT_H + 3 - (XC - 115), 209, 27]];     // [min corner, size] for the C5 shrink
module hinge_rot(a = 0) translate([0, PIN_Y, PIN_Z]) rotate([-a, 0, 0]) translate([0, -PIN_Y, -PIN_Z]) children();
module lid_blade_posed(a = 0) hinge_rot(a) hop_blade();
module lid_posed(a = 0) hinge_rot(a) lid();
module lid_pad_posed(a = 0) hinge_rot(a) lid_pad();
module lid_actuator_posed(a = 0) hinge_rot(a) hop_actuator();
module lid_hw_posed(a = 0) hinge_rot(a) { hop_actuator_screws_ph(); lid_pad_screws_ph(); }

part = "world";
lid_angle = 0;
if (part == "collar") translate([FL_X, FL_Y, ZS]) rotate([180, 0, 0]) collar();           // flange face down
else if (part == "funnel") translate([95 - XC, 95, -ZS]) funnel();                          // flange face down
else if (part == "lid") translate([115 - XC, 100, ZT + 3]) rotate([180, 0, 0]) lid();     // top face down
else if (part == "lid_act_pad")      // flat face against the ear down (Z = a + 1), the actuator face (pilots) is the vertical side: lay it on the a = -1 side
    multmatrix([[0, -1, 0, LIDPAD_B[1]], [0, 0, -1, SW_PAD_W / 2], [1, 0, 0, 1], [0, 0, 0, 1]]) lid_pad_s();
else if (part == "world") { collar(); funnel(); lid_posed(lid_angle); lid_pad_posed(lid_angle); lid_actuator_posed(lid_angle); lid_hw_posed(lid_angle); switch_ph(); switch_screws_ph(); hinge_pin_ph(); }
else if (part == "bom") {
    echo(str("BOM hopper lid interlock: 1 x Pizzato FS 3096D024-F7 guard-locking switch (24 V, locked with NO power; Amazon B07HCCFTQB) + its jointed adjustable actuator VF KEYF7 (included). *** ALL DIMENSIONS APPROXIMATE - verify with Pizzato's 2D drawing before drilling: *** switch body about ", SW_W, " x ", SW_L, " (incl. head, actuator entry in the top face) x ", SW_D, " deep, 2 x M4 holes about ", HSW_HOLE_SPACING, " apart along the height; actuator about ", ACT_L - ACT_BL, " x ", ACT_W, " x ", ACT_H, " block + ", ACT_BL, " tongue, 2 x M5 holes about ", HACT_HOLE_SPACING, " apart; funnel pad ", HPAD_W, " wide x ", SW_L + 2, " high with 2 x Ø", SWS_PILOT, " pilots (M4 x 16 into the pad); printed lid actuator pad 12.5 x ", SW_PAD_W, " x ", LIDPAD_B[1] - LIDPAD_B[0], " with 2 x Ø", ACS_PILOT, " pilots (M5 x 25) + 2 x M4 heat-set inserts, held by 2 x M4 x 12 under the lid ear; tongue ", INTERLOCK_IN, " mm in the head when closed, out after about 7 deg of lid opening"));
}
