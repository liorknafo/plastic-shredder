// interlock.scad -- the safety interlock hardware as PLACEHOLDERS with honest envelopes: a switch and its MATCHING coded metal actuator.
//   hopper lid : Pizzato FS 3096D024-F7 guard-locking switch + its jointed actuator VF KEYF7   (design/params.py HSW_*, HACT_*)
//   drawer     : Omron D4NS-2AF plain safety switch + D4DS-K2 key                              (design/params.py DSW_*, DACT_*)
// EVERY DIMENSION IS APPROXIMATE: drill to the manufacturer's 2D drawing.  The printed parts carry flat pads with pilot holes only.
//
// TEMPLATE.  `include` it from a part file (hopper.scad, base.scad); `include` is textual, so every includer gets its OWN copy of everything below, built from the
// IL_* values THAT FILE sets first (hopper.scad: the Pizzato, base.scad: the Omron).  Before the include the includer must define
//   IL_SW_BODY [w, depth, length], IL_SW_HOLE_SPACING, IL_SW_SLOT [thickness, width, depth], IL_SW_SCREW [d, hole, head Ø, head h, pilot Ø],
//   IL_ACT_SIZE [height, width, length tip to tail], IL_ACT_BLADE_T, IL_ACT_BLADE_L, IL_ACT_HOLE_SPACING, IL_ACT_SCREW.
// (Nothing outside this file may read SW_BODY / SW_SLOT / ACT_SIZE ... of params.scad any more: those are the superseded generic envelope.)
//
// SWITCH frame S = (a, b, c):  a = out of the mounting face (0 at the face, SW_D at the far face), b = along the body from the head end
//   face (b = 0) to the rear (SW_L), c = across (centred, +-SW_W/2).  The actuator slot opens in the head end face at b = 0.
//   Two mounting holes (spacing apart, centred on b) go through the body along a: screws from the far face into the pad.
// ACTUATOR frame A = (a, b, c):  a = out of its mounting face (0 .. ACT_H), b = along it from the TIP (b = 0) to the tail (ACT_L),
//   c = across (centred).  Blade (thin, ACT_BLADE_L long from the tip, full width) centred in the height; mounting block behind it
//   with two holes (spacing apart, centred on the block) along a.
// ENGAGED (lid / drawer closed): the blade centre plane is the slot centre plane, the tip is INTERLOCK_IN deep in the slot:
//   S <- A:  a_s = a_a + A_OFF,  b_s = INTERLOCK_IN - travel - b_a,  c_s = -c_a      (a proper rotation + translation; travel = how far the
//   moving part has been pulled away from the switch).
SW_W = IL_SW_BODY[0];  SW_D = IL_SW_BODY[1];  SW_L = IL_SW_BODY[2];
ACT_H = IL_ACT_SIZE[0];  ACT_W = IL_ACT_SIZE[1];  ACT_L = IL_ACT_SIZE[2];
ACT_BT = IL_ACT_BLADE_T;  ACT_BL = IL_ACT_BLADE_L;
A_OFF = SW_D / 2 - ACT_H / 2;                                  // mounting plane of the actuator in the switch frame when engaged
SCREW_D = 4;  SCREW_HEAD_D = 7;  SCREW_HEAD_H = 3;  HOLE_D = 4.5;   // plain M4 (the lid pad's own screws, the drawer pads' hardware)
// the switch's own screws and the actuator's own screws: [d, clearance hole, head Ø, head h, pilot Ø]
SWS_D = IL_SW_SCREW[0];  SWS_HOLE = IL_SW_SCREW[1];  SWS_HEAD_D = IL_SW_SCREW[2];  SWS_HEAD_H = IL_SW_SCREW[3];  SWS_PILOT = IL_SW_SCREW[4];
ACS_D = IL_ACT_SCREW[0];  ACS_HOLE = IL_ACT_SCREW[1];  ACS_HEAD_D = IL_ACT_SCREW[2];  ACS_HEAD_H = IL_ACT_SCREW[3];  ACS_PILOT = IL_ACT_SCREW[4];
SWS_PDEPTH = SWS_D >= 5 ? 10 : PILOT_DEPTH;                    // pilot depth in the pad (thread-forming: ~2 d)
ACS_PDEPTH = ACS_D >= 5 ? 10 : PILOT_DEPTH;
SHANK_D = PILOT_D - 0.3;                                       // thread core of an M4 (used by the pad alignment checks); the switch / actuator shanks below use their own pilots
assert(INTERLOCK_IN >= 10 && INTERLOCK_IN < IL_SW_SLOT[2] && INTERLOCK_IN < ACT_BL && INTERLOCK_IN <= INTERLOCK_OUT_TRAVEL,
       "blade must go in >= 10 mm, less than the slot depth and the blade length, and be out within INTERLOCK_OUT_TRAVEL");
assert(IL_SW_SLOT[0] > ACT_BT && IL_SW_SLOT[1] > ACT_W, "slot must be larger than the blade");
assert(ACT_L - ACT_BL >= IL_ACT_HOLE_SPACING + ACS_HOLE + 4, "the actuator block must be long enough for its two holes (>= 2 mm of material beyond each)");

function sw_hole_b() = [for (s = [-1, 1]) SW_L / 2 + s * IL_SW_HOLE_SPACING / 2];
function act_hole_b() = [for (s = [-1, 1]) (ACT_BL + ACT_L) / 2 + s * IL_ACT_HOLE_SPACING / 2];
// 4x4 matrix: actuator frame -> switch frame, drawer / lid pulled away by `travel`
function act_to_sw(travel = 0) = [[1, 0, 0, A_OFF], [0, -1, 0, INTERLOCK_IN - travel], [0, 0, -1, 0], [0, 0, 0, 1]];

// ---------------------------------------------------------------- switch (switch frame)
module sw_body_env() translate([0, 0, -SW_W / 2]) cube([SW_D, SW_L, SW_W]);                          // whole body, slot not cut
module sw_slot() translate([SW_D / 2 - IL_SW_SLOT[0] / 2, -1, -IL_SW_SLOT[1] / 2]) cube([IL_SW_SLOT[0], IL_SW_SLOT[2] + 1, IL_SW_SLOT[1]]);
module sw_ph() difference() {
    sw_body_env();
    sw_slot();
    for (b = sw_hole_b()) translate([-1, b, 0]) rotate([0, 90, 0]) cylinder(d = SWS_HOLE, h = SW_D + 2, $fn = 24);
}
module sw_screws_ph() for (b = sw_hole_b()) translate([SW_D, b, 0]) {                                // pan-head screws from the far face
    rotate([0, 90, 0]) cylinder(d = SWS_HEAD_D, h = SWS_HEAD_H, $fn = 24);
    rotate([0, -90, 0]) cylinder(d = SWS_D, h = SW_D + SWS_PDEPTH - 1, $fn = 20);
}
module sw_shanks(d = SWS_PILOT - 0.3) for (b = sw_hole_b()) translate([SW_D + 1, b, 0]) rotate([0, -90, 0]) cylinder(d = d, h = SW_D + SWS_PDEPTH, $fn = 20);
module sw_pad_pilots() for (b = sw_hole_b()) translate([0.01, b, 0]) rotate([0, -90, 0]) cylinder(d = SWS_PILOT, h = SWS_PDEPTH + 0.01, $fn = 20);   // into the pad, from its face a = 0

// ---------------------------------------------------------------- actuator (actuator frame)
module act_ph() difference() {
    union() {
        translate([0, ACT_BL, -ACT_W / 2]) cube([ACT_H, ACT_L - ACT_BL, ACT_W]);                         // mounting block
        translate([ACT_H / 2 - ACT_BT / 2, 0, -ACT_W / 2]) cube([ACT_BT, ACT_BL + 0.01, ACT_W]);          // blade
    }
    for (b = act_hole_b()) translate([-1, b, 0]) rotate([0, 90, 0]) cylinder(d = ACS_HOLE, h = ACT_H + 2, $fn = 24);
}
module act_screws_ph() for (b = act_hole_b()) translate([ACT_H, b, 0]) {
    rotate([0, 90, 0]) cylinder(d = ACS_HEAD_D, h = ACS_HEAD_H, $fn = 24);
    rotate([0, -90, 0]) cylinder(d = ACS_D, h = ACT_H + ACS_PDEPTH - 1, $fn = 20);
}
module act_shanks(d = ACS_PILOT - 0.3) for (b = act_hole_b()) translate([ACT_H + 1, b, 0]) rotate([0, -90, 0]) cylinder(d = d, h = ACT_H + ACS_PDEPTH, $fn = 20);
module act_pad_pilots() for (b = act_hole_b()) translate([0.01, b, 0]) rotate([0, -90, 0]) cylinder(d = ACS_PILOT, h = ACS_PDEPTH + 0.01, $fn = 20);

// the actuator placed in the switch frame, engaged (travel = 0)
module act_in_sw(travel = 0) multmatrix(act_to_sw(travel)) children();

// the three envelopes the checks compare (all in the switch frame)
module blade_env(travel = 0) act_in_sw(travel) translate([ACT_H / 2 - ACT_BT / 2, 0, -ACT_W / 2]) cube([ACT_BT, ACT_BL, ACT_W]);   // the part that enters the head
module sw_rest() difference() { sw_ph(); }                                                                                              // body with slot (material only)
