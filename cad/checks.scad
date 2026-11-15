// checks.scad -- interference checks. Each check builds an INTERSECTION; it passes when the result is empty
// (OpenSCAD prints "Current top level object is empty." and exits 1 without writing a file).
// Selected with -D 'check="..."' (+ -D angle=, -D sh=, -D k=, -D a=, -D b=). Driven by build.sh.
//
//   C1   A rotating set  ^  B rotating set, at -D angle=0,5,..,115          expect EMPTY
//   C2   swept envelopes of blades/spacers of shaft sh  ^  (combs + walls + inner layers + collar + funnel + screen + drive-end guard + free-end cover)   EMPTY
//   C3   blade k of shaft sh  ^  its shaft (angle 0);  C3x: spacers + sleeves + collared sleeves ^ shaft        EMPTY
//   C4   all sleeves (clamp + collared)  ^  inner / outer / cap layers (both ends, the new bores)            EMPTY
//   C5   pair (a, b) of {combs, walls, plate layers, hopper, screen, guards, base plate, deck, sub-plate, coupling guard ...}   EMPTY
//   C6   shaft A rotating set ^ shaft B blades+spacers shifted by dx = +-0.17 (angle 0..115 step 15) EMPTY (ctl: dx = 0.25 hits)
//   C20  bearings / seals / thrust / crinkle washers / collared sleeves: vs the plate layers (a), vs each other (b: every pair of the stack), and the stack is gap-free (c: each
//        neighbour pair touches: probe grown 0.05 -> NON-empty, control: part moved 0.5 away -> empty)
//   C21  the TL350 on A (body + its 30T tooth plate, swept) grown 4.9 mm  ^  shaft B's gear, hub, collar, thrust, end cap, M10 head: EMPTY (>= 5 mm); ctl: grown 11.5 hits
//   C23  gearbox + output shaft + pin flange + motor + coupling vs deck / cabinet / base plate / each other
//   C24  drive-end guard  ^  every moving part grown 2.9 mm (>= 3 mm clear: gears, hubs, collars, thrust bearings, caps, heads, the TL350 and its plate, pins, pin flange, spacer):
//        EMPTY; ctl: grown 3.5 hits; and ^ every static drive part (gearbox, worm shaft, rails, coupling guard, deck, motor): EMPTY
//   C2c  free-end M10 end caps + heads + collars + thrust washers grown 2.9 ^ free-end cover  EMPTY (ctl: grown 3.5 hits)
//   C25  torque-limiter setting fixture (tlfix.scad): chain wrap vs stub / vise / TL body, lever vs chain / TL / vise / bench, weight vs bench, TL on the stub
//   C26  design asserts: motor coaxial with the worm, deck outside the cabinet (ctl: a wrong value must fail)
//   C17  hopper lid interlock;  C14 blade torque test lever
//   C16  joint alignment: for every bolted joint one bolt shank (thread core) through the hole of part 1 and the hole of part 2 touches neither part
//        (holes come from the SAME coordinate function: joints.scad, hang_screw_xy, dg_ear_pts ...); control: shank moved 4 mm sideways must hit
//   C40  FIXED SCREEN (base.scad): (a) 2 mm under the blade-tip circles (envelopes grown 1.9 miss it, grown 2.3 hit it); (b) clear of combs, walls, plates, base, cabinet, drawer
//        (closed and pulled out), wall-screw heads; (c) its wings bear on the combs; (d) in plan no opening of 5.2 mm or more under the chamber except the Ø5 holes; (e) every hole
//        lies over the drawer bin; (f) the 4 counterbores are reached from below past the base plate; (g) asserts: hole length + gap >= 5 (ISO 13857), it comes out through the drawer opening
//   C41  COUPLING GUARD + STUB CAP (drive.scad): >= 3 mm round the coupling, the bare motor shaft and the unused worm stub; clear of motor, gearbox, rails, deck, drive-end guard; feet on the deck
//   C42  PIN COUPLING (drive.scad, placeholders.scad): pins >= 1.5 mm outside the TL350's body, in their drilled holes with play, holes inside the plate band, flange clear of the
//        TL350 / A's end cap + M10 head / shaft A, the gearbox output coaxial with shaft A
//   *ctl positive controls: the same test with a deliberate fault, which must be NON-empty (or, where said, EMPTY / error), proving the test can see an overlap.
include <common.scad>
include <joints.scad>
include <tl350.scad>
use <stack.scad>
use <plate.scad>
use <shaft.scad>
use <comb.scad>
use <wall.scad>
use <hopper.scad>
use <guards.scad>
use <drive.scad>
use <base.scad>
use <placeholders.scad>
use <tlfix.scad>
use <testlever.scad>

check = "C1";
angle = 0;
goff = 0;               // C31off: extra turn of gear B (deg)
sh = "A";
k = 0;
a = 0;
b = 1;
dx = 0.17;               // C6: axial shift of shaft B's blades + spacers
en = "drive";            // C20: end
oi = 0;                  // C20: object index
GCHK = 2.9;              // guard clearance test: parts grown by this (the guards are built 3.0 away: 0.1 mm of facet tolerance)

// ---- C2 helpers: swept envelope = disc of radius R_TIP over each blade's x-range, disc of SPACER_OD/2 over each spacer
module envelope(sh, extra = 0) {
    translate([0, shaft_y(sh), 0]) {
        for (i = [0 : N_BLADES - 1]) axial(blade_x0(sh, i)) cylinder(r = R_TIP + extra, h = T_BLADE, $fn = 96);
        if (sh == "B") axial(END_CLEAR) cylinder(r = SPACER_OD / 2, h = end_spacer_B, $fn = 96);
        for (i = [0 : N_BLADES - 1])
            if (sh == "A" || i < N_BLADES - 1)
                axial(blade_x0(sh, i) + T_BLADE) cylinder(r = SPACER_OD / 2, h = T_SPACER, $fn = 96);
    }
}
module obstacles() {
    comb("A"); comb("B"); wall(1); wall(-1);
    plates([0], ["drive", "free"]);
    collar(); funnel(); screen(); drive_end_guard(); free_end_cover();
}
// free-end rotors, swept as cylinders (bearing inner ring face .. M10 head), grown by g
module free_env(g = 0) for (s = ["A", "B"]) {
    y = shaft_y(s);
    cylx(COLLAR_OD / 2 + g, x_collar_in_free - g, x_collar_out_free + g, y);
    cylx(THRUST_D / 2 + g, x_cap_out_free + CRINKLE_stack_h - g, x_collar_in_free + g, y);
    cylx(CRINKLE_D / 2 + g, x_cap_out_free - g, x_cap_out_free + CRINKLE_stack_h + g, y);
    cylx(15 + g, x_collar_out_free - g, x_collar_out_free + END_WASHER_T + g, y);
    cylx(8 + g, x_collar_out_free + END_WASHER_T - g, x_collar_out_free + END_WASHER_T + 10 + g, y);
}
module b_shifted(d, ang) rot_frame("B", ang) translate([d, 0, 0]) { blades_of("B"); spacers_of("B"); }

// erosion of a solid by a 4 mm cube (every point that has a 4 mm cube round it inside the solid); the corner test is a necessary condition
module erode4() {
    intersection_for (dx = [-2, 2], dy = [-2, 2], dz = [-2, 2]) translate([dx, dy, dz]) children();
}
module erode_h(h) {       // erosion by a cube of side 2h
    intersection_for (dx = [-h, h], dy = [-h, h], dz = [-h, h]) translate([dx, dy, dz]) children();
}
module blade_envs() { envelope("A"); envelope("B"); }   // both swept blade-tip envelopes (lowest point z = -R_TIP)

// ---- C4 helper
module all_sleeves() {
    for (s = ["A", "B"]) rot_frame(s, 0) { clamp_sleeves_of(s); collared_sleeves_of(s); }
}

// ---- C20 helpers: the bearing / seal / thrust / sleeve stack of one end, shafts A and B together.  Object lists per end (index = oi).
C20_DRIVE = ["seal", "bearing_outer", "rollers", "inner_ring", "thrust", "clamp_sleeve", "collared_sleeve", "gear", "gear_spacer", "end_cap_screw", "sprocket_A",
             "ob_bearing_outer", "ob_rollers", "ob_inner_ring", "ob_sleeve"];
C20_FREE  = ["seal", "bearing_outer", "rollers", "inner_ring", "crinkle", "thrust", "clamp_sleeve", "collared_sleeve", "end_cap_screw"];
module c20_obj(end, i) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) {
    if (end == "drive") {
        if (i == 0) seal_ph("drive"); else if (i == 1) bearing_outer_ph("drive"); else if (i == 2) bearing_rollers_ph("drive"); else if (i == 3) bearing_inner_ph("drive");
        else if (i == 4) thrust_ph("drive"); else if (i == 5) clamp_sleeve("drive", s); else if (i == 6) collar_sleeve("drive");
        else if (i == 7) gear_ph(s); else if (i == 8) gear_spacer_ph(); else if (i == 9) end_screw_drive(s);
        else if (i == 10 && s == "A") sprocket_ph();
        else if (i == 11) bearing_outer_ph("ob"); else if (i == 12) bearing_rollers_ph("ob"); else if (i == 13) bearing_inner_ph("ob"); else if (i == 14) ob_sleeve_ph(s);
    } else {
        if (i == 0) seal_ph("free"); else if (i == 1) bearing_outer_ph("free"); else if (i == 2) bearing_rollers_ph("free"); else if (i == 3) bearing_inner_ph("free");
        else if (i == 4) crinkle_ph(); else if (i == 5) thrust_ph("free"); else if (i == 6) clamp_sleeve("free", s); else if (i == 7) collar_sleeve("free");
        else if (i == 8) end_screw_free();
    }
}
module c20_all_but(end, i) {
    n = end == "drive" ? len(C20_DRIVE) : len(C20_FREE);
    for (j = [0 : n - 1]) if (j != i) c20_obj(end, j);
    for (s = ["A", "B"]) rot_frame(s, 0) shaft_local(s);
    plates([0, 1, 2, 3, 4], [end]);
}

// ---- C5 helper: object i = 0 comb A, 1 comb B, 2 wall A, 3 wall B, 4..6 drive inner/outer/cap, 7..9 free inner/outer/cap
C5_NAMES = ["comb_A", "comb_B", "wall_A", "wall_B", "drive_inner", "drive_outer", "drive_cap", "free_inner", "free_outer", "free_cap",
            "collar", "funnel", "lid", "screen", "dg_upper", "dg_lower", "free_cover", "base_plate",
            "lid_pad", "drive_deck", "gb_mount", "cpl_guard", "stub_cap"];
module obj(i) {
    if (i == 0) comb("A");
    else if (i == 1) comb("B");
    else if (i == 2) wall(-1);
    else if (i == 3) wall(1);
    else if (i < 10) plate_one(i < 7 ? "drive" : "free", (i - 4) % 3);
    else if (i == 10) collar();
    else if (i == 11) funnel();
    else if (i == 12) lid();
    else if (i == 13) screen();
    else if (i == 14) dg_upper();
    else if (i == 15) dg_lower();
    else if (i == 16) free_end_cover();
    else if (i == 17) base_plate();
    else if (i == 18) lid_pad();
    else if (i == 19) drive_deck();
    else if (i == 20) gb_mount();
    else if (i == 21) cpl_guard();
    else stub_cap();
}

// Touching faces: manifold returns a zero-thickness sheet for exactly coincident faces instead of "empty", so the
// second operand of every C5 pair is shrunk by SHRINK on each side (about its bounding-box centre). Any real
// overlap deeper than 0.01 mm still shows up (see C5ctl).
SHRINK = 0.01;
function obj_box(i) =               // [min corner, size]
    i == 0 ? [[0, comb_y_lo("A"), -5], [chamber_L, COMB_W, 10]]
  : i == 1 ? [[0, comb_y_lo("B"), -5], [chamber_L, COMB_W, 10]]
  : i == 2 ? [[0, -(wall_inner_y + 10), 5], [chamber_L, 10, WALL_H]]
  : i == 3 ? [[0, wall_inner_y, 5], [chamber_L, 10, WALL_H]]
  : i < 10 ? (let (l = (i - 4) % 3, drive = i < 7)
    [[drive ? -LAYER_T * (l + 1) : chamber_L + LAYER_T * l, -PLATE_L / 2, -PLATE_H / 2], [LAYER_T, PLATE_L, PLATE_H]])
  : i == 10 ? [[-18, -82, 35], [chamber_L + 36, 164, HOPPER_SPLIT_Z - 35]]                                  // collar
  : i == 11 ? [[-29, -95, HOPPER_SPLIT_Z], [chamber_L / 2 + 102 + 29, 203, HOPPER_TOP_Z + 6 - HOPPER_SPLIT_Z]]   // funnel
  : i == 12 ? lid_box()                                                                                         // lid
  : i == 13 ? screen_box()
  : i == 14 ? dg_upper_box()
  : i == 15 ? dg_lower_box()
  : i == 16 ? [[chamber_L + 30, -85, -35], [3, 170, 70]]                                                        // free-end cover plate (the bumps are shrunk with it: fine)
  : i == 17 ? base_box()                                                                                        // base plate
  : i == 18 ? lid_pad_box()
  : i == 19 ? (let (g = deck_geom()) [[g[0], g[2], g[4]], [g[1] - g[0], g[3] - g[2], g[5] - g[4]]])
  : i == 20 ? gb_mount_box()
  : cg_box_pts();                                                                                               // the two guard boxes (C5 only pairs them with things far away)
module shrunk(i) {
    bx = obj_box(i);
    c = bx[0] + bx[1] / 2;
    translate(c) scale([for (s = bx[1]) 1 - 2 * SHRINK / s]) translate(-c) obj(i);
}

// ---- C14 helpers: the blade torque test lever (testlever.scad).  Pin tangent to the hook face: direction of the face normal (toward the gullet) = test_face_nrm_deg
module tl_nudge(d) translate([0, d * cos(test_face_nrm_deg), d * sin(test_face_nrm_deg)]) children();      // d > 0 moves away from the face, d < 0 into it
module tl_pin_sweep(a1) for (a = [0 : 1 : a1]) rotate([a, 0, 0]) tl_pin();                                // pin turned back off the face (positive about +x)

// ---- C16 joint tables: shanks and the two parts that carry the holes
joint = "foot";
module joint_shanks(j) {
    if (j == "foot") foot_screw_shanks();
    else if (j == "hang") hang_shanks();
    else if (j == "dleg") deck_leg_shanks();
    else if (j == "cgfoot") cg_foot_shanks();
    else if (j == "gbfoot") gbfoot_shanks();
    else if (j == "topdeck") topdeck_shanks();
    else if (j == "topleg") topleg_shanks();
    else if (j == "footleg") footleg_shanks();
    else if (j == "anchor") anchor_shanks();
    else if (j == "subbolt") subbolt_shanks();
    else if (j == "gseam") dgseam_shanks();
    else if (j == "gcapd") gcap_drive_shanks();
    else if (j == "gcapf") gcap_free_shanks();
    else if (j == "handle") handle_shanks();
    else if (j == "hsw") hop_switch_shanks();
    else if (j == "hact") hop_actuator_shanks();
    else if (j == "hlid") lid_screw_shanks();
    else if (j == "screen") screen_shanks();
    else if (j == "hood") hood_screw_shanks();
    else assert(false, str("unknown joint ", j));
}
module joint_parts(j) {
    if (j == "foot") { base_plate(); plates([0, 1], ["drive", "free"]); }
    else if (j == "hang") { base_plate(); cabinet_panels(); }
    else if (j == "dleg") { drive_deck(); deck_legs(); }
    else if (j == "cgfoot") { cpl_guard(); stub_cap(); drive_deck(); }
    else if (j == "gbfoot") { gb_flange(); gb_rails(); }
    else if (j == "subbolt") { gb_mount(); drive_deck(); }
    else if (j == "topdeck") { top_angles(); drive_deck(); }
    else if (j == "topleg") { top_angles(); deck_legs(); }
    else if (j == "footleg") { foot_angles(); deck_legs(); }
    else if (j == "anchor") { foot_angles(); floor_ph(); }
    else if (j == "gseam") { dg_upper(); dg_lower(); }
    else if (j == "gcapd") { dg_upper(); dg_lower(); plates([1, 2, 3, 4], ["drive"]); standoffs(); }   // long M8 tie screws: hood wing, ob2, ob1, standoff, cap, outer layer
    else if (j == "gcapf") { free_end_cover(); plate_one("free", 2); }
    else if (j == "handle") { drawer_front(); handle_world(); }
    else if (j == "hsw") { switch_ph(); funnel(); }
    else if (j == "hact") { hop_actuator(); lid_pad(); }
    else if (j == "hlid") { lid(); lid_pad(); }
    else if (j == "screen") { screen(); comb("A"); comb("B"); }             // the screen: M4 from below through the wings into the combs
    else if (j == "hood") { dg_upper(); dg_lower(); plates([4], ["drive"]); }   // hood wings: M5 into ob2
}
// ---- drive helpers
module static_drive() { gearbox_ph(); worm_ph(); output_shaft_ph(); shaft_hw_ph(); gb_mount(); cpl_guard(); stub_cap(); motor_ph(); motor_shaft_ph(); coupling_ph(); }
module building() { plates(); standoffs(); comb("A"); comb("B"); wall(1); wall(-1); collar(); funnel(); screen(); base_plate(); cabinet_panels(); drawer_panels(); free_end_cover(); }
module moving_drive_env(g) { drive_end_env(g); pf_env(g); free_env(g); }

if (check == "C1") intersection() { rotating_set("A", angle); rotating_set("B", angle); }
else if (check == "C1ctl") intersection() { rotating_set("A", 0); translate([0, -4, 0]) rotating_set("B", 0); }
else if (check == "C2") intersection() { envelope(sh); obstacles(); }
else if (check == "C2ctl") intersection() { envelope(sh, 3); obstacles(); }
else if (check == "C3") intersection() { blade_placed(sh, k); shaft_local(sh); }
else if (check == "C3ctl") intersection() { blade_placed(sh, k); rotate([30, 0, 0]) shaft_local(sh); }
else if (check == "C3x") intersection() { union() { spacers_of(sh); clamp_sleeves_of(sh); collared_sleeves_of(sh); } shaft_local(sh); }
else if (check == "C4") intersection() { all_sleeves(); plates(); }
else if (check == "C4ctl") intersection() { translate([0, 3, 0]) all_sleeves(); plates(); }
else if (check == "C5") intersection() { obj(a); shrunk(b); }
else if (check == "C5ctl") intersection() { translate([-0.5, 0, 0]) comb("B"); shrunk(4); }
else if (check == "C5ctl2") intersection() { translate([-0.05, 0, 0]) comb("B"); shrunk(4); }   // 0.05 mm overlap still seen
// ---- C20: bearings, seals, thrust, crinkle, collared sleeves
else if (check == "C20a") intersection() { union() { for (e = ["drive", "free"]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) { seal_ph(e); bearing_ph(e); thrust_ph(e); } for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) { crinkle_ph(); bearing_ph("ob"); } } plates(); }
else if (check == "C20actl") intersection() { translate([0, 3, 0]) union() { for (e = ["drive", "free"]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_ph(e); } plates(); }
else if (check == "C20b") intersection() { c20_obj(en, oi); c20_all_but(en, oi); }
else if (check == "C20bctl") intersection() { translate([3, 0, 0]) c20_obj("drive", 3); c20_all_but("drive", 3); }                       // inner ring 3 mm toward the chamber: hits the clamp sleeve
// seats: the outer ring is held between the inner-layer shoulder and the cap step: 0.05 mm further either way must overlap the plates
else if (check == "C20s1") intersection() { translate([0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("drive"); plates([0], ["drive"]); }
else if (check == "C20s2") intersection() { translate([-0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("drive"); plates([2], ["drive"]); }
else if (check == "C20s3") intersection() { translate([-0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("free"); plates([0], ["free"]); }
else if (check == "C20s4") intersection() { translate([0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("free"); plates([2], ["free"]); }
// chain of contacts: each neighbour moved 0.04 mm INTO the next one must overlap it (the stack closes up with no gap > 0.04 mm: bearing - inner ring - sleeves - thrust - collar - gears - sprocket - caps)
else if (check == "C20c1") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) clamp_sleeve("drive", s); }          // drive inner ring ^ clamp sleeve
else if (check == "C20c2") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("drive"); }          // drive inner ring ^ collared sleeve
else if (check == "C20c3") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("drive"); }             // thrust ^ collar
else if (check == "C20c3b") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("drive"); plates([2], ["drive"]); }                                                    // thrust ^ drive cap face
else if (check == "C20c4") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("free"); for (s = ["A", "B"]) rot_frame(s, 0) clamp_sleeve("free", s); }        // free inner ring ^ clamp sleeve
else if (check == "C20c5") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("free"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("free"); }           // free inner ring ^ collared sleeve
else if (check == "C20c6") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) crinkle_ph(); plates([2], ["free"]); }                                                           // crinkle stack ^ free cap face
else if (check == "C20c7") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("free"); for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) crinkle_ph(); }            // free thrust ^ crinkle stack
else if (check == "C20c7b") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("free"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("free"); }              // free thrust ^ collar
else if (check == "C20c8") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) gear_ph(s); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("drive"); }               // gear ^ collar
else if (check == "C20c9") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) gear_spacer_ph(); for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) gear_ph(s); }           // gear spacer sleeve ^ gear (outer face)
else if (check == "C20c10") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("A"), 0]) sprocket_ph(); translate([0, shaft_y("A"), 0]) ob_sleeve_ph("A"); }                                                     // sprocket hub ^ outer sleeve
else if (check == "C20c14") intersection() { translate([0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("ob"); for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) gear_spacer_ph(); }       // outboard inner ring ^ inner sleeve
else if (check == "C20c15") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) { bearing_inner_ph("ob"); } for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) ob_sleeve_ph(s); }       // outboard inner ring ^ outer sleeve
else if (check == "C20s5") intersection() { translate([0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("ob"); plates([3], ["drive"]); }       // outboard outer ring held by ob1's step
else if (check == "C20s6") intersection() { translate([-0.05, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("ob"); plates([4], ["drive"]); }      // ... and by ob2's step
else if (check == "C20c11") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("A"), 0]) end_screw_drive("A"); translate([0, shaft_y("A"), 0]) sprocket_ph(); }                                          // end cap A ^ sprocket hub face
else if (check == "C20c12") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("B"), 0]) end_screw_drive("B"); translate([0, shaft_y("B"), 0]) ob_sleeve_ph("B"); }                                            // end cap B ^ outer sleeve
else if (check == "C20c13") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) end_screw_free(); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("free"); }             // free end cap ^ collar
else if (check == "C20cctl") intersection() { translate([0.04 - 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) clamp_sleeve("drive", s); }   // control: ring 0.5 mm away from the sleeve: no contact (EMPTY)
else if (check == "C20c3ctl") intersection() { translate([-0.04 + 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("drive"); }  // control: thrust 0.5 mm off the collar (EMPTY)
else if (check == "C20sctl") intersection() { translate([0.05 - 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("drive"); plates([0], ["drive"]); }                                    // control: outer ring 0.5 mm off its shoulder (EMPTY)
// ---- C21: the TL350 on A (body, tooth plate, swept) >= 5 mm from shaft B's parts
else if (check == "C21") intersection() { sprocket_a_env(4.9); drive_end_env(0, false, ["B"]); }
else if (check == "C21ctl") intersection() { sprocket_a_env(11.5); drive_end_env(0, false, ["B"]); }
// ---- C23: gearbox + TL + motor + coupling vs the rest
else if (check == "C23a") intersection() { union() { gearbox_ph(); worm_ph(); output_shaft_ph(); shaft_hw_ph(); pin_coupling_ph(); }; union() { building(); drive_deck(); deck_legs(); motor_ph(); } }
else if (check == "C23actl") intersection() { translate([300, 0, 0]) union() { gearbox_ph(); shaft_hw_ph(); }; cabinet_panels(); }                    // gearbox 300 mm toward the machine: into the cabinet
else if (check == "C23b") intersection() { union() { motor_ph(); motor_shaft_ph(); coupling_ph(); }; union() { building(); deck_legs(); gearbox_ph(); gb_mount(); shaft_hw_ph(); pin_coupling_ph(); drive_end_guard(); } }
else if (check == "C23c") intersection() { translate([0, 0, -0.01]) drive_deck(); union() { motor_ph(); gb_mount(); cpl_guard(); stub_cap(); gearbox_ph(); coupling_ph(); } }     // deck vs everything on it (nudged: contact only)
else if (check == "C23cctl") intersection() { translate([0, 0, 3]) drive_deck(); union() { motor_ph(); gb_mount(); } }
else if (check == "C23d") intersection() { union() { deck_legs(); translate([0, 0, -0.01]) drive_deck(); }; union() { building(); gearbox_ph(); gb_mount(); shaft_hw_ph(); pin_coupling_ph(); drive_end_guard(); } }
else if (check == "C23e") intersection() { union() { rail_bolts_ph(); gb_foot_bolts_ph(); }; union() { gb_flange(); gb_housing(); gb_mount(); drive_deck(); } }       // hardware seated, 0.01 off every face
else if (check == "C23ectl") intersection() { translate([3, 0, 0]) union() { rail_bolts_ph(); gb_foot_bolts_ph(); }; union() { gb_flange(); gb_mount(); drive_deck(); } }
// ---- C24: the drive-end guard
else if (check == "C24a") intersection() { moving_drive_env(GCHK); drive_end_guard(); }
else if (check == "C24actl") intersection() { moving_drive_env(3.5); drive_end_guard(); }
else if (check == "C24b") intersection() { drive_end_guard(); union() { translate([-0.01, 0, 0]) gearbox_ph(); worm_ph(); gb_mount(); drive_deck(); deck_legs(); cpl_guard(); stub_cap(); motor_ph(); coupling_ph(); cabinet_panels(); base_plate(); tie_hardware(0); } }
else if (check == "C2g") intersection() { drive_end_env(GCHK); drive_end_guard(); }
else if (check == "C2gctl") intersection() { drive_end_env(GCHK); translate([0, 0.5, 0]) drive_end_guard(); }             // the gear band 0.5 mm sideways (its cavity is 3.0 round the gears) must hit
else if (check == "C2c") intersection() { free_env(GCHK); free_end_cover(); }
else if (check == "C2cctl") intersection() { free_env(3.5); free_end_cover(); }
else if (check == "C6") intersection() { rotating_set("A", angle); b_shifted(dx, angle); }
// ---- C35: the OUTBOARD bearing plate, its standoffs and the gear band
else if (check == "C35a") intersection() { standoffs(0.01); union() { plates(); drive_end_guard(); comb("A"); comb("B"); wall(1); wall(-1); collar(); funnel(); screen(); base_plate(); cabinet_panels(); } }   // standoffs between the cap and ob1 (0.01 short each end): nothing else
else if (check == "C35actl") intersection() { standoffs(-0.02); plates([2, 3], ["drive"]); }                                            // control: 0.02 longer each end they overlap the cap AND ob1 (they are clamped face to face)
else if (check == "C35b") intersection() { translate([-0.01, 0, 0]) union() { dg_upper(); dg_lower(); } plates([3, 4], ["drive"]); }   // the hood butts on ob2's outer face (0.01 off: no overlap)
else if (check == "C35bctl") intersection() { translate([0.5, 0, 0]) union() { dg_upper(); dg_lower(); } plates([3, 4], ["drive"]); }  // control: 0.5 toward the machine it is in the plate
else if (check == "C35c") intersection() { gear_band(); union() { plates(); standoffs(); dg_upper(); dg_lower(); collar(); funnel(); base_plate(); screen(); comb("A"); comb("B"); } }       // the gear band: 0.3 from both faces, round the standoffs
else if (check == "C35cctl") intersection() { translate([0.5, 0, 0]) gear_band(); plates([2], ["drive"]); }                               // control: 0.5 toward the cap it hits the cap
else if (check == "C35d") intersection() { drive_end_env(1.9, true, ["A", "B"], false); plates([3, 4], ["drive"]); }                    // gear hub, sprocket hub, B's end cap: >= 1.9 from the outboard plate (OB_GAP = 2)
else if (check == "C35dctl") intersection() { drive_end_env(2.2, true, ["A", "B"], false); plates([3, 4], ["drive"]); }                 // control: grown 2.2 they reach it
else if (check == "C35f") intersection() { tie_hardware(0); union() { dg_upper(); dg_lower(); } }                                         // the tie screws' washers + heads clear the hood: the preload never goes through PETG
else if (check == "C35fctl") intersection() { tie_hardware(1); union() { dg_upper(); dg_lower(); } }                                    // control: washers 2 mm bigger reach the wing
else if (check == "C35e") intersection() { union() { plates([3, 4], ["drive"]); standoffs(); gear_band(); } union() { drive_deck(); deck_legs(); static_drive(); pin_coupling_ph(); } }   // plate, standoffs, band clear of the whole drive
// ---- C40: the FIXED SCREEN
else if (check == "C40a") intersection() { union() { envelope("A", SCREEN_GAP - 0.1); envelope("B", SCREEN_GAP - 0.1); } screen(); }           // 2 mm under the blade-tip circles: grown 1.9 they miss it
else if (check == "C40actl") intersection() { union() { envelope("A", SCREEN_GAP + 0.3); envelope("B", SCREEN_GAP + 0.3); } screen(); }        // control: grown 2.3 they hit it
else if (check == "C40b") intersection() { translate([0, 0, -0.01]) screen(); union() { comb("A"); comb("B"); wall(1); wall(-1); plates(); base_plate(); cabinet_panels(); wall_screws_ph(); for (t = [0 : 20 : 180]) drawer_moved_ph(t); } }   // nudged off the combs
else if (check == "C40bctl") intersection() { translate([0, 0, 0.5]) screen(); union() { comb("A"); comb("B"); } }                               // control: 0.5 up it is in the combs
else if (check == "C40c") intersection() { translate([0, 0, 0.04]) screen(); union() { comb("A"); comb("B"); } }                                  // the wings bear on the combs (0.04 further up = overlap)
else if (check == "C40cctl") intersection() { translate([0, 0, 0.04 - 0.5]) screen(); union() { comb("A"); comb("B"); } }                         // control: 0.46 lower: no contact
else if (check == "C40d") linear_extrude(1) offset(r = -2.6) difference() { translate([0, -chamber_iy()]) square([chamber_L, 2 * chamber_iy()]); screen_plan_2d(); }        // nothing >= 5.2 passes under the chamber but the Ø5 holes
else if (check == "C40dctl") linear_extrude(1) offset(r = -2.6) difference() { translate([0, -chamber_iy()]) square([chamber_L, 2 * chamber_iy()]); screen_plan_2d(5.6); }  // control: Ø5.6 holes are seen
else if (check == "C40e") linear_extrude(1) difference() { screen_holes_plan_2d(); bin_inner_plan_2d(2); }                                          // every hole lies over the bin, 2 mm inside its walls
else if (check == "C40ectl") linear_extrude(1) difference() { screen_holes_plan_2d(); bin_inner_plan_2d(30); }                                      // control: a bin 28 mm smaller each side misses some
else if (check == "C40f") intersection() { screen_cb_reach(0); union() { base_plate(); cabinet_panels(); } }                                       // a socket key reaches every counterbore from below, past the base plate
else if (check == "C40fctl") intersection() { screen_cb_reach(12); base_plate(); }                                                                  // control: screws 12 mm further out are under the base plate
else if (check == "C40g") { assert(screen_min_hole_len() + SCREEN_GAP >= 5, "ISO 13857: hole length + gap >= 5 mm for round openings 4 < e <= 6"); assert(screen_out_ok(), "the screen comes out through the drawer opening");
                            echo(str("C40g shortest hole ", screen_min_hole_len(), " mm (+ ", SCREEN_GAP, " gap); screen ", screen_dims())); }
else if (check == "C40gctl") { assert(screen_min_hole_len() + SCREEN_GAP >= 25, "control: a 25 mm requirement must fail"); }
// ---- C41: the coupling guard and the stub cap
else if (check == "C41a") intersection() { union() { coupling_env(GCHK); motor_shaft_env(GCHK); stub_env(GCHK); } union() { cpl_guard(); stub_cap(); } }   // >= 3 mm round everything that turns
else if (check == "C41actl") intersection() { union() { coupling_env(3.5); stub_env(3.5); } union() { cpl_guard(); stub_cap(); } }                       // control: grown 3.5 they hit
else if (check == "C41b") intersection() { translate([0, 0, 0.01]) union() { cpl_guard(); stub_cap(); } union() { motor_ph(); gearbox_ph(); gb_mount(); drive_deck(); deck_legs(); drive_end_guard(); gb_foot_bolts_ph(); rail_bolts_ph(); } }
else if (check == "C41bctl") intersection() { translate([0, -3, 0.01]) cpl_guard(); motor_ph(); }                                                     // control: 3 mm toward the motor it hits the motor
else if (check == "C41c") intersection() { translate([0, 0, -0.01]) union() { cpl_guard(); stub_cap(); } drive_deck(); }                             // the feet stand on the deck
else if (check == "C14a") intersection() { tl_pin(); tl_blade(); }                                                     // pin tangent to the face, no overlap
else if (check == "C14actl") intersection() { tl_nudge(-0.3) tl_pin(); tl_blade(); }                                  // pin 0.3 mm into the face: must hit
else if (check == "C14b") intersection() { tl_nudge(-0.2) tl_pin(); tl_blade(); tl_face_probe(); }                    // within 0.2 mm of the hook face: 0.2 mm in = overlap on the face strip
else if (check == "C14bctl") intersection() { tl_nudge(0.3 - 0.2) tl_pin(); tl_blade(); tl_face_probe(); }                // control: pin 0.3 mm OFF the face, same 0.2 test: must stay clear
else if (check == "C14c") intersection() { tl_pin_sweep(15); tl_blade(); }                                             // the pin backs off the face freely (0..15 deg)
else if (check == "C14cctl") intersection() { tl_pin_sweep(15); rotate([1, 0, 0]) tl_blade(); }                       // control: blade turned 1 deg onto the pin (its face advances): must hit
else if (check == "C14d") intersection() { tl_lever(); tl_blade(); }
else if (check == "C14dctl") intersection() { translate([1.6, 0, 0]) tl_lever(); tl_blade(); }                          // lever 1.6 mm toward the blade (face gap 1.0): must hit
else if (check == "C14e") intersection() { union() { tl_lever(); tl_pin(); }; tl_vise_ph(); }
else if (check == "C14ectl") intersection() { translate([30, 0, 0]) tl_lever(); tl_vise_ph(); }                        // lever 30 mm toward the vise: must hit
else if (check == "C14f") intersection() { tl_blade(); tl_vise_ph(); }
else if (check == "C14g") intersection() { tl_blade(); tl_shaft(); }                                                   // hex bore clears the hex in the test orientation
else if (check == "C14gctl") intersection() { tl_blade(); rotate([30, 0, 0]) tl_shaft(); }                             // shaft turned 30 deg: must hit
else if (check == "C14h") intersection() { union() { tl_lever(); tl_pin(); }; tl_shaft(); }                            // Ø25.2 pivot hole on the Ø25 journal; pin far from the shaft
else if (check == "C14hctl") intersection() { translate([0, 0.5, 0]) tl_lever(); tl_shaft(); }                          // lever 0.5 mm off-axis: must hit the journal
// ---- C25: torque-limiter setting fixture (tlfix.scad)
else if (check == "C25a") intersection() { chain_fix(GCHK); union() { stub_solid(); vise_ph(); stand_ph(); bench_ph(); tl_body_fix(); key_ph(); } }       // the chain wrap clears the stub, vise, stand, bench and the TL body by >= 3 mm
else if (check == "C25actl") intersection() { chain_fix(15); tl_body_fix(); }                                                  // control: a chain wrap grown 15 mm cuts the TL body
else if (check == "C25b") intersection() { union() { lever(); lugs(); }; union() { chain_fix(0); stub_solid(); vise_ph(); stand_ph(); bench_ph(); tl_body_fix(); tl_plate_fix(); } }  // the lever clears chain, stub, vise, bench, TL
else if (check == "C25bctl") intersection() { translate([3, 0, 0]) lugs(); chain_fix(0); }                                                           // lugs 3 mm toward the chain (gap 2.4): must hit
else if (check == "C25c") intersection() { weight_ph(); union() { bench_ph(); vise_ph(); stand_ph(); } }                                             // the weight hangs free of the bench
else if (check == "C25d") intersection() { union() { tl_body_fix(); tl_plate_fix(); }; union() { stub_solid(); vise_ph(); } }                          // TL bore over the stub, TL clear of the vise (bore Ø25.02 over Ø24.987)
else if (check == "C25dctl") intersection() { union() { tl_body_fix(); tl_plate_fix(); }; translate([0, 0.5, 0]) stub_solid(); }                        // stub 0.5 off-axis: must hit the bore
else if (check == "C25e") intersection() { chain_bolts_ph(); union() { lever(); lugs(); stub_solid(); vise_ph(); bench_ph(); tl_body_fix(); } }          // the M6 bolts pass the lever and lug holes and touch nothing, clear of stub, vise, bench, TL
else if (check == "C25ectl") intersection() { translate([0, 2, 0]) chain_bolts_ph(); union() { lever(); lugs(); } }                              // control: bolts 2 mm off their holes must hit
// balanced position (lever horizontal): lever, lugs, bolts and weight clear the vise, stand, bench, stub (pivot bore Ø25.2 on the Ø24.987 pin) and the TL350
else if (check == "C25f") intersection() { union() { lever(); lugs(); chain_bolts_ph(); weight_ph(); }; union() { stub_solid(); vise_ph(); stand_ph(); bench_ph(); tl_body_fix(); tl_plate_fix(); key_ph(); } }
else if (check == "C25fctl") intersection() { translate([0, 0.5, 0]) lever(); stub_solid(); }                                                       // control: lever 0.5 mm off the pin axis must hit the pin
else if (check == "C25g") intersection() { translate([1, 0, 0]) lever(); tl_body_fix(); }                                                            // the lever is 5 mm clear of the adjusting nut (1 mm nearer: still clear)
else if (check == "C25gctl") intersection() { translate([6, 0, 0]) lever(); tl_body_fix(); }                                                         // control: 6 mm nearer hits the nut
// ---- C26: coaxial motor, deck position
else if (check == "C26b") { assert(abs(motor_axis_z() - worm_axis()[1]) < 1e-9 && abs(motor_axis_x() - worm_axis()[0]) < 1e-9, "the motor is coaxial with the worm (direct coupling)"); }
else if (check == "C26bctl") { assert(abs(motor_axis_z() + 5 - worm_axis()[1]) < 1e-9, "control: a motor 5 mm lower must fail the coaxial test"); }
else if (check == "C26e") { assert(DECK_X1 < -30 && DECK_Z1 < -53, "the drive deck is outside and below the cabinet (starts at x = -30)"); }
// ---- C27: hold-down (leg angles, bolts, anchors) -- the path rails -> deck -> top angles -> legs -> foot angles -> floor
else if (check == "C27a") intersection() { union() { top_angles(); foot_angles(); }; union() { drive_deck(); deck_legs(); gb_mount(); motor_ph(); floor_ph(); cpl_guard(); stub_cap(); } }          // angles sit 0.01 off every face
else if (check == "C27actl") intersection() { translate([0, 0, 0.5]) top_angles(); drive_deck(); }                                                    // control: top angles 0.5 mm up hit the deck
else if (check == "C27b") intersection() { holddown_hw_ph(); union() { drive_deck(); deck_legs(); top_angles(); foot_angles(); floor_ph(); gb_mount(); } }  // bolts pass their holes (Ø8 in Ø9), washers / heads / nuts sit 0.01 off the faces
else if (check == "C27bctl") intersection() { translate([2, 0, 0]) holddown_hw_ph(); union() { drive_deck(); deck_legs(); top_angles(); foot_angles(); } }   // control: all bolts 2 mm sideways hit
else if (check == "C27c") intersection() { union() { top_angles(); foot_angles(); holddown_hw_ph(); }; union() { gearbox_ph(); worm_ph(); shaft_hw_ph(); output_shaft_ph(); pin_coupling_ph(); motor_ph(); coupling_ph(); cpl_guard(); stub_cap(); building(); drive_end_guard(); } }
else if (check == "C27d") { assert(len(ANCHOR_PTS) == 2 * len(DECK_LEG_C) && len(TOPANG_DECK_PTS) == DECK_ANGLE_DECK_BOLTS * len(DECK_LEG_C) && len(TOPANG_LEG_PTS) == DECK_ANGLE_LEG_BOLTS * len(DECK_LEG_C)
                            && len(FOOTANG_LEG_PTS) == FOOT_ANGLE_LEG_BOLTS * len(DECK_LEG_C) && len(RAIL_BOLT_PTS) == 4, "hold-down: 2 + 2 + 2 + 2 bolts and anchors per leg, 4 rail bolts");
                            echo(str("C27d anchors: ", len(ANCHOR_PTS), " x ", DECK_ANCHOR, " at ", [for (p = ANCHOR_PTS) [round(10 * p[0]) / 10, round(10 * p[1]) / 10]])); }
// ---- C28: gearbox output shaft: fits, circlip, axial retention (circlip - housing - spacer - pin flange), keyways, length
else if (check == "C28a") intersection() { output_shaft_ph(); union() { gearbox_ph(); pin_flange(); shaft_hw_ph(); } }                               // Ø25 shaft in the Ø25.02 hub, the flange's bore, spacer, circlip groove
else if (check == "C28b") intersection() { translate([0.05, 0, 0]) circlip_ph(); gearbox_ph(); }                                                      // circlip lies on the housing's far face: 0.05 further = in the housing
else if (check == "C28bctl") intersection() { translate([-0.4, 0, 0]) circlip_ph(); gearbox_ph(); }                                                   // control: 0.4 mm off the face: no contact (EMPTY)
else if (check == "C28c1") intersection() { translate([-0.04, 0, 0]) out_spacer_ph(); gearbox_ph(); }                                                // spacer on the housing face
else if (check == "C28c2") intersection() { translate([-0.04, 0, 0]) pin_flange(); out_spacer_ph(); }                                                 // the pin flange's hub on the spacer
else if (check == "C28cctl") intersection() { translate([-0.04 + 0.5, 0, 0]) pin_flange(); out_spacer_ph(); }                                        // control: flange 0.5 mm off the spacer (EMPTY)
else if (check == "C28d") intersection() { output_shaft_ph(); translate([(GBKEY_X0 + GBKEY_X1) / 2 - 1, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }   // gearbox keyway is cut there (EMPTY)
else if (check == "C28dctl") intersection() { output_shaft_ph(); translate([GB_X1 - 3, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }         // control: 3 mm before the hub's end the shaft is solid
else if (check == "C28e") intersection() { output_shaft_ph(); translate([(PFKEY_X0 + PFKEY_X1) / 2 - 1, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }    // pin-flange keyway
else if (check == "C28ectl") intersection() { output_shaft_ph(); translate([PFKEY_X1 + 0.5, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }        // control: beyond the flange keyway
else if (check == "C28f") { assert(abs((OUT_X1 - OUT_X0) - (CIRCLIP_EDGE + CIRCLIP_GROOVE_W + GB_HUB_L + TL_GB_GAP + PF_KEY_L - PF_SHAFT_RECESS)) < 1e-9, "shaft length = far circlip + hub + spacer + the flange's bore - recess");
                            echo(str("C28f shaft length ", OUT_X1 - OUT_X0, " = ", CIRCLIP_EDGE, " + ", CIRCLIP_GROOVE_W, " + hub ", GB_HUB_L, " + spacer ", TL_GB_GAP, " + flange bore ", PF_KEY_L, " - ", PF_SHAFT_RECESS)); }
else if (check == "C28fctl") { assert(abs((OUT_X1 - OUT_X0) + 1 - (CIRCLIP_EDGE + CIRCLIP_GROOVE_W + GB_HUB_L + TL_GB_GAP + PF_KEY_L - PF_SHAFT_RECESS)) < 1e-9, "control: a shaft 1 mm short must fail"); }
// ---- C42: the pin coupling
else if (check == "C42a") intersection() { pins_ph(1.5); translate([0, YA, 0]) tl_on_a() tl350_body_l(); }                                             // pins grown 1.5 radially miss the TL350's body
else if (check == "C42actl") intersection() { pins_ph(2.5); translate([0, YA, 0]) tl_on_a() tl350_body_l(); }                                          // control: grown 2.5 they hit it (clearance 2.0)
else if (check == "C42b") intersection() { pins_ph(); translate([0, YA, 0]) sprocket_disc_ph(); }                                                      // pins in the drilled holes (0.25 play)
else if (check == "C42bctl") intersection() { translate([0, 0.3, 0]) pins_ph(); translate([0, YA, 0]) sprocket_disc_ph(); }                             // control: 0.3 sideways they hit the hole wall
else if (check == "C42c") { assert(PIN_R - PIN_D / 2 - TL_D / 2 >= 1.5 && PIN_R - PIN_HOLE_D / 2 - TL_D / 2 >= 1.5 && tl_sprocket_root_d / 2 - PIN_R - PIN_HOLE_D / 2 >= 1.5
                                   && PIN_X1 - (x_cm + SPROCKET_T / 2) >= 1, "pins outside the TL's body, holes in the plate band, pin tips past the plate");
                            echo(str("C42c pin edge to the TL body ", PIN_R - PIN_D / 2 - TL_D / 2, ", hole edge to the body ", PIN_R - PIN_HOLE_D / 2 - TL_D / 2, ", hole edge to the tooth root ",
                                     tl_sprocket_root_d / 2 - PIN_R - PIN_HOLE_D / 2, ", pin tip past the plate ", PIN_X1 - (x_cm + SPROCKET_T / 2))); }
else if (check == "C42cctl") { assert(tl_sprocket_root_d / 2 - PIN_R - PIN_HOLE_D / 2 >= 3, "control: a 3 mm band margin must fail"); }
else if (check == "C42d") intersection() { pin_flange(); union() { translate([0, YA, 0]) { sprocket_ph(); end_screw_drive("A"); } rot_frame("A", 0) shaft_local("A"); } }   // the flange clears the TL350, A's end cap + head, shaft A
else if (check == "C42dctl") intersection() { translate([PF_GAP + 0.1, 0, 0]) pin_flange(); translate([0, YA, 0]) sprocket_ph(); }                     // control: 2.1 mm toward A it is in the TL's flange
else if (check == "C42e") intersection() { union() { pin_flange(); output_shaft_ph(); } union() { cylx(15 + 1.9, x_sprocket_out - END_WASHER_T - 1.9, x_sprocket_out, YA); cylx(8 + 1.9, x_sprocket_out - END_WASHER_T - 10 - 1.9, x_sprocket_out - END_WASHER_T + 0.01, YA); } }   // pocket >= 2 mm round A's end cap + head
else if (check == "C42ectl") intersection() { union() { pin_flange(); output_shaft_ph(); } union() { cylx(15 + 3.1, x_sprocket_out - END_WASHER_T - 3.1, x_sprocket_out, YA); cylx(8 + 3.1, x_sprocket_out - END_WASHER_T - 10 - 3.1, x_sprocket_out - END_WASHER_T + 0.01, YA); } }   // control: grown 3.1 they reach the pocket wall (3 radial) and the shaft end (3)
else if (check == "C42g") { assert(abs(ZO) < 1e-9 && abs(YA - shaft_y("A")) < 1e-9, "the gearbox output is coaxial with shaft A"); }
else if (check == "C42gctl") { assert(abs(ZO + 1) < 1e-9, "control: an output 1 mm off must fail"); }
else if (check == "NAMES") echo(C5_NAMES);
else if (check == "C16") intersection() { joint_shanks(joint); union() { joint_parts(joint); } }
else if (check == "C16ctl") intersection() { for (v = [[4, 0, 0], [-4, 0, 0], [0, 4, 0], [0, -4, 0], [0, 0, 4], [0, 0, -4]]) translate(v) joint_shanks(joint); union() { joint_parts(joint); } }
// ---- C17: hopper lid interlock
else if (check == "C17a") intersection() { lid_blade_posed(0); hop_slot_from(10); }                                                                  // lid down: blade >= 10 mm in the slot
else if (check == "C17actl") intersection() { lid_blade_posed(3); hop_slot_from(10); }                                                               // lid 3 deg up (blade 8.4 mm in... < 10): must be EMPTY, see build.sh
else if (check == "C17b") for (a = [0 : 1 : 12]) intersection() { lid_actuator_posed(a); union() { switch_ph(); switch_screws_ph(); } }          // the whole actuator clears the switch for every lid angle 0 .. 12
else if (check == "C17bctl") intersection() { translate([(HSW_SLOT[0] - HACT_BLADE_T) / 2 + 0.4, 0, 0]) lid_actuator_posed(0); switch_ph(); }   // control: actuator sideways by the slot play (1.5) + 0.4 = 1.9 mm must hit the slot wall
else if (check == "C17c") intersection() { lid_blade_posed(9); switch_env(); }                                                                      // lid 9 deg up: blade completely out
else if (check == "C17cctl") intersection() { lid_blade_posed(3); switch_env(); }                                                                   // control: lid 3 deg up: blade still in (must hit)
else if (check == "C17d") for (a = [0 : 2 : 12]) intersection() { union() { lid_pad_posed(a); lid_actuator_posed(a); lid_hw_posed(a); }
                                                                   union() { funnel(); collar(); switch_ph(); switch_screws_ph(); hinge_pin_ph(); } }   // pad, actuator, screws clear of the static hopper parts
// ---- C31: the MADE gears in mesh (gear.scad: involute teeth, backlash).  A turns -angle, B +angle (as assembly.scad); tooth phase set so they mesh at angle = 0
else if (check == "C31") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); }
else if (check == "C31ctl_cd") intersection() { rot_frame("A", angle) gear_exact("A"); translate([0, -0.3, 0]) rot_frame("B", angle) gear_exact("B"); }              // centre distance 0.3 short: must hit
else if (check == "C31ctl_nobl") intersection() { rot_frame("A", angle) gear_exact("A", 0); rot_frame("B", angle) gear_exact("B", 0, 0.5); }                       // no backlash + B 0.5 deg off: must hit
else if (check == "C31ctl_phase") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B", GEAR_cut_extra, 180 / GEAR_z); }    // tooth meets tooth (phase wrong by half a pitch): must hit
else if (check == "C31off") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B", GEAR_cut_extra, goff); }               // B turned goff deg off the conjugate position: free inside +-0.139 deg (= half the backlash 0.1456 mm on r 30), hits outside
// ---- C32: both real gears clear of the plates and the drive-end guard; C32s: gear B clear of the TL350 on A
else if (check == "C32") intersection() { union() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); }
                                          union() { plates(); drive_end_guard(); } }
else if (check == "C32s") intersection() { rot_frame("B", angle) gear_exact("B"); sprocket_a_env(0); }                                                                  // gear B vs sprocket A (gear A sits against A's own sprocket hub: contact, C20c10)
else if (check == "C32ctl") intersection() { translate([10, 0, 0]) union() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); } plates(); }   // gears 10 mm toward the plates: must hit
else assert(false, str("unknown check ", check));

// ---- small helpers used above
DG_CLR = 6;  CAB_X0_CHK = -30;       // guard end wall (3 + 3 clearance) and the cabinet's x0
module grow_box(bx, g) translate(bx[0] - [g, g, g]) cube(bx[1] + 2 * [g, g, g]);
