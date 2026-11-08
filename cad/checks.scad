// checks.scad -- interference checks. Each check builds an INTERSECTION; it passes when the result is empty
// (OpenSCAD prints "Current top level object is empty." and exits 1 without writing a file).
// Selected with -D 'check="..."' (+ -D angle=, -D sh=, -D k=, -D a=, -D b=). Driven by build.sh.
//
//   C1   A rotating set  ^  B rotating set, at -D angle=0,5,..,115          expect EMPTY
//   C2   swept envelopes of blades/spacers of shaft sh  ^  (combs + walls + inner layers + collar + funnel + skirts + drive-end guard + free-end cover)   EMPTY
//   C3   blade k of shaft sh  ^  its shaft (angle 0);  C3x: spacers + sleeves + collared sleeves ^ shaft        EMPTY
//   C4   all sleeves (clamp + collared)  ^  inner / outer / cap layers (both ends, the new bores)            EMPTY
//   C5   pair (a, b) of {combs, walls, plate layers, hopper, skirts, guards, base plate, deck, sub-plate, tensioner ...}   EMPTY
//   C6   shaft A rotating set ^ shaft B blades+spacers shifted by dx = +-0.17 (angle 0..115 step 15) EMPTY (ctl: dx = 0.25 hits)
//   C20  bearings / seals / thrust / crinkle washers / collared sleeves: vs the plate layers (a), vs each other (b: every pair of the stack), and the stack is gap-free (c: each
//        neighbour pair touches: probe grown 0.05 -> NON-empty, control: part moved 0.5 away -> empty)
//   C21  sprocket A (teeth OD + hub, swept) grown 4.9 mm  ^  shaft B's gear, hub, collar, thrust, end cap, M10 head: EMPTY (>= 5 mm); ctl: grown 11.5 hits
//   C22  the chain (a swept band round A, the TL sprocket and the idler at both ends of its slot)  ^  B's drive parts, A's hub / caps, TL body, plates, cabinet, base plate, deck, sub-plate,
//        gearbox, motor, belt guard, tensioner upright / base, deck legs: EMPTY; ctl: chain moved 30 mm toward B hits
//   C23  gearbox + TL + sub-plate + motor + belt vs deck / cabinet / base plate / each other
//   C24  drive-end guard + chain guard  ^  every moving part grown 2.9 mm (>= 3 mm clear: gears, hubs, collars, thrust bearings, caps, heads, sprocket A, chain at both idler ends, TL, idler, boss):
//        EMPTY; ctl: grown 3.5 hits; and ^ every static drive part (gearbox, worm shaft, sub-plate, tensioner upright / base / bolt, belt guard, deck, motor): EMPTY
//   C2c  free-end M10 end caps + heads + collars + thrust washers grown 2.9 ^ free-end cover  EMPTY (ctl: grown 3.5 hits)
//   C25  torque-limiter setting fixture (tlfix.scad): chain wrap vs stub / vise / TL body, lever vs chain / TL / vise / bench, weight vs bench, TL on the stub
//   C26  design asserts: the three tooth plates in ONE chain plane, belt horizontal, wrap angles, idler pushes the slack run outward (ctl: a wrong value must fail)
//   C8e  belt guard half A ^ half B (lap clearance 0.3; ctl: B shifted 0.5 up must hit)                   EMPTY
//   C9a  free space of the cabinet shell (sides, back, floor, FIXED upper front, drawer front) eroded by a 4 mm cube    EMPTY (no gap >= 4 mm; ctl: Ø16 hole in the drawer front / in the fixed front must show)
//   C30  FIXED UPPER FRONT PANEL (base.scad): with the drawer (front + bin) REMOVED, the space above the grid is still closed to the outside:
//        (a) the shell's free space eroded by a 4 mm cube has nothing from the underside of the lower cleats (GRID_ZL) up; ctl: panel bottom raised 30 mm / panel absent -> non-empty
//        (b) the 4 mm cube cannot pass between the fixed panel and the front rail (the 1 mm slot); ctl: grid set 6 mm further back -> non-empty
//        (c) the panel touches the base plate, (d) the side panels' front edges (no gap > 0.04; ctl: 0.5 mm away -> empty); (e) the drawer front (closed and pulled out 0 .. 180) clears it; ctl: raised 1.5 mm hits
//        (f) assert: panel bottom <= GRID_ZL (ctl: raised 30 mm fails the assert); (g) the opening left by the drawer is entirely under the lower cleats
//   C10  drawer interlock;  C17  hopper lid interlock;  C11 belt guard feet on the deck, lap >= 15 mm;  C14 blade torque test lever
//   C29  FIXED SAFETY GRID (base.scad): (a) mesh top >= 120 mm under the blade-tip envelope (assert + the 120 mm reach slab above the mesh misses the blades), (b) Ø16 finger probes
//        through every cell reach at most 120 above the mesh = they cannot touch a blade, (c) mesh + cleats clear of the cabinet panels, drawer front, base plate, skirts, and of the bin
//        closed and pulled out, (d) edge gap: no 10 mm cube fits between the cut sheet and the walls, (e) the clear opening is <= 30 mm; each with a control
//   C16  joint alignment: for every bolted joint one bolt shank (thread core) through the hole of part 1 and the hole of part 2 touches neither part
//        (holes come from the SAME coordinate function: joints.scad, hang_screw_xy, dg_ear_pts ...); control: shank moved 4 mm sideways must hit
//   *ctl positive controls: the same test with a deliberate fault, which must be NON-empty (or, where said, EMPTY / error), proving the test can see an overlap.
include <common.scad>
include <joints.scad>
use <stack.scad>
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
travel = 0;              // C10: drawer pulled out by this much (mm)
half = 0;                // C11: belt guard half
u0 = 0;  u1 = 0;         // C11: probe slab limits (guard u)
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
    collar(); funnel(); skirt(1); skirt(-1); drive_end_guard(); free_end_cover();
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
C20_DRIVE = ["seal", "bearing_outer", "rollers", "inner_ring", "thrust", "clamp_sleeve", "collared_sleeve", "gear", "gear_spacer", "end_cap_screw", "sprocket_A"];
C20_FREE  = ["seal", "bearing_outer", "rollers", "inner_ring", "crinkle", "thrust", "clamp_sleeve", "collared_sleeve", "end_cap_screw"];
module c20_obj(end, i) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) {
    if (end == "drive") {
        if (i == 0) seal_ph("drive"); else if (i == 1) bearing_outer_ph("drive"); else if (i == 2) bearing_rollers_ph("drive"); else if (i == 3) bearing_inner_ph("drive");
        else if (i == 4) thrust_ph("drive"); else if (i == 5) clamp_sleeve("drive", s); else if (i == 6) collar_sleeve("drive");
        else if (i == 7) gear_ph(s); else if (i == 8) gear_spacer_ph(); else if (i == 9) end_screw_drive(s);
        else if (i == 10 && s == "A") sprocket_ph();
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
    plates([0, 1, 2], [end]);
}

// ---- C5 helper: object i = 0 comb A, 1 comb B, 2 wall A, 3 wall B, 4..6 drive inner/outer/cap, 7..9 free inner/outer/cap
C5_NAMES = ["comb_A", "comb_B", "wall_A", "wall_B", "drive_inner", "drive_outer", "drive_cap", "free_inner", "free_outer", "free_cap",
            "collar", "funnel", "lid", "skirt_A", "skirt_B", "dg_upper", "dg_lower", "free_cover", "base_plate",
            "lid_pad", "drawer_pad", "drawer_act_pad", "drive_deck", "gb_mount", "tens_upright", "tens_base", "grid_mesh", "grid_cleats_low", "grid_cleats_up", "upper_front"];
module obj(i) {
    if (i == 0) comb("A");
    else if (i == 1) comb("B");
    else if (i == 2) wall(-1);
    else if (i == 3) wall(1);
    else if (i < 10) plate_one(i < 7 ? "drive" : "free", (i - 4) % 3);
    else if (i == 10) collar();
    else if (i == 11) funnel();
    else if (i == 12) lid();
    else if (i == 13) skirt(-1);
    else if (i == 14) skirt(1);
    else if (i == 15) dg_upper();
    else if (i == 16) dg_lower();
    else if (i == 17) free_end_cover();
    else if (i == 18) base_plate();
    else if (i == 19) lid_pad();
    else if (i == 20) drawer_pad();
    else if (i == 21) drawer_act_pad();
    else if (i == 22) drive_deck();
    else if (i == 23) gb_mount();
    else if (i == 24) tens_upright();
    else if (i == 25) tens_base();
    else if (i == 26) grid_mesh();
    else if (i == 27) grid_cleats(0);
    else if (i == 28) grid_cleats(1);
    else upper_front();
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
  : i == 13 ? [[0, -85, -35], [chamber_L, 12, 30]]                                                              // skirt A
  : i == 14 ? [[0, 73, -35], [chamber_L, 12, 30]]                                                               // skirt B
  : i == 15 ? dg_upper_box()
  : i == 16 ? dg_lower_box()
  : i == 17 ? [[chamber_L + 30, -85, -35], [3, 170, 70]]                                                        // free-end cover plate (the bumps are shrunk with it: fine)
  : i == 18 ? base_box()                                                                                        // base plate
  : i == 19 ? lid_pad_box()
  : i == 20 ? drawer_pad_box()
  : i == 21 ? drawer_act_pad_box()
  : i == 22 ? (let (g = deck_geom()) [[g[0], g[2], g[4]], [g[1] - g[0], g[3] - g[2], g[5] - g[4]]])
  : i == 23 ? gb_mount_box()
  : i == 24 ? tens_upright_box()
  : i == 25 ? tens_base_box()
  : i == 26 ? grid_box()
  : i == 29 ? ufront_box()
  : grid_cleat_box(i == 27 ? 0 : 1);
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
    else if (j == "bgfoot") bg_foot_shanks();
    else if (j == "gbfoot") gbfoot_shanks();
    else if (j == "topdeck") topdeck_shanks();
    else if (j == "topleg") topleg_shanks();
    else if (j == "footleg") footleg_shanks();
    else if (j == "anchor") anchor_shanks();
    else if (j == "subbolt") subbolt_shanks();
    else if (j == "tbase") tbase_shanks();
    else if (j == "taxle0") tens_axle_shanks(0);
    else if (j == "taxlep") tens_axle_shanks(TENS_TRAVEL);
    else if (j == "taxlem") tens_axle_shanks(-TENS_TRAVEL);
    else if (j == "gseam") dgseam_shanks();
    else if (j == "gcapd") gcap_drive_shanks();
    else if (j == "gcapf") gcap_free_shanks();
    else if (j == "handle") handle_shanks();
    else if (j == "dsw") drawer_sw_shanks();
    else if (j == "dpad") drawer_pad_shanks();
    else if (j == "dact") drawer_act_shanks();
    else if (j == "dactpad") drawer_act_pad_shanks();
    else if (j == "hsw") hop_switch_shanks();
    else if (j == "hact") hop_actuator_shanks();
    else if (j == "hlid") lid_screw_shanks();
    else if (j == "gcl") grid_screw_shanks();
    else if (j == "uftop") uf_top_shanks();
    else if (j == "ufface") uf_face_shanks();
    else assert(false, str("unknown joint ", j));
}
module joint_parts(j) {
    if (j == "foot") { base_plate(); plates([0, 1], ["drive", "free"]); }
    else if (j == "hang") { base_plate(); cabinet_panels(); }
    else if (j == "dleg") { drive_deck(); deck_legs(); }
    else if (j == "bgfoot") { belt_guard(0); belt_guard(1); drive_deck(); }
    else if (j == "gbfoot") { gb_flange(); gb_rails(); }
    else if (j == "subbolt") { gb_mount(); drive_deck(); }
    else if (j == "topdeck") { top_angles(); drive_deck(); }
    else if (j == "topleg") { top_angles(); deck_legs(); }
    else if (j == "footleg") { foot_angles(); deck_legs(); }
    else if (j == "anchor") { foot_angles(); floor_ph(); }
    else if (j == "tbase") { tens_base(); drive_deck(); }
    else if (j == "taxle0" || j == "taxlep" || j == "taxlem") tens_upright();
    else if (j == "gseam") { dg_upper(); dg_lower(); }
    else if (j == "gcapd") { drive_end_guard(); plate_one("drive", 2); }
    else if (j == "gcapf") { free_end_cover(); plate_one("free", 2); }
    else if (j == "handle") { drawer_front(); handle_world(); }
    else if (j == "dsw") { drawer_switch_ph(); drawer_pad(); }
    else if (j == "dpad") { drawer_pad(); cabinet_panels(); }
    else if (j == "dact") { drawer_actuator(0); drawer_act_pad(); }
    else if (j == "dactpad") { drawer_act_pad(); drawer_front(); }
    else if (j == "hsw") { switch_ph(); funnel(); }
    else if (j == "hact") { hop_actuator(); lid_pad(); }
    else if (j == "hlid") { lid(); lid_pad(); }
    else if (j == "gcl") { cabinet_panels(); grid_cleats(0); grid_cleats(1); }
    else if (j == "uftop") { base_plate(); upper_front(); }                  // fixed front panel: top screws through the base plate into its top edge
    else if (j == "ufface") { upper_front(); cabinet_shell_panels(); }       // fixed front panel: face screws into the side panels' front edges
}

// ---- drive helpers
module static_drive() { gearbox_ph(); worm_ph(); output_shaft_ph(); shaft_hw_ph(); gb_mount(); tens_upright(); tens_base(); belt_guard(0); belt_guard(1); motor_ph(); pulleys_ph(); belt_ph(); }
module building() { plates(); comb("A"); comb("B"); wall(1); wall(-1); collar(); funnel(); skirt(1); skirt(-1); base_plate(); cabinet_panels(); drawer_panels(); free_end_cover(); }
module chain_statics() { building(); drive_deck(); deck_legs(); static_drive(); drive_end_guard(); }
module moving_drive_env(g) { drive_end_env(g); chain_drive_env(g); free_env(g); }

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
else if (check == "C20a") intersection() { union() { for (e = ["drive", "free"]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) { seal_ph(e); bearing_ph(e); thrust_ph(e); } for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) crinkle_ph(); } plates(); }
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
else if (check == "C20c10") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("A"), 0]) sprocket_ph(); translate([0, shaft_y("A"), 0]) gear_spacer_ph(); }                                                   // sprocket hub ^ gear spacer sleeve
else if (check == "C20c11") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("A"), 0]) end_screw_drive("A"); translate([0, shaft_y("A"), 0]) sprocket_ph(); }                                          // end cap A ^ sprocket hub face
else if (check == "C20c12") intersection() { translate([0.04, 0, 0]) translate([0, shaft_y("B"), 0]) end_screw_drive("B"); translate([0, shaft_y("B"), 0]) gear_spacer_ph(); }                                          // end cap B ^ gear spacer sleeve
else if (check == "C20c13") intersection() { translate([-0.04, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) end_screw_free(); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("free"); }             // free end cap ^ collar
else if (check == "C20cctl") intersection() { translate([0.04 - 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_inner_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) clamp_sleeve("drive", s); }   // control: ring 0.5 mm away from the sleeve: no contact (EMPTY)
else if (check == "C20c3ctl") intersection() { translate([-0.04 + 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) thrust_ph("drive"); for (s = ["A", "B"]) rot_frame(s, 0) collar_sleeve("drive"); }  // control: thrust 0.5 mm off the collar (EMPTY)
else if (check == "C20sctl") intersection() { translate([0.05 - 0.5, 0, 0]) for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) bearing_outer_ph("drive"); plates([0], ["drive"]); }                                    // control: outer ring 0.5 mm off its shoulder (EMPTY)
// ---- C21: sprocket A (teeth OD, hub, swept) >= 5 mm from shaft B's parts
else if (check == "C21") intersection() { sprocket_a_env(4.9); drive_end_env(0, false, ["B"]); }
else if (check == "C21ctl") intersection() { sprocket_a_env(11.5); drive_end_env(0, false, ["B"]); }
// ---- C22: the chain
else if (check == "C22a") intersection() { chain_swept(2.9); chain_statics(); }
else if (check == "C22actl") intersection() { translate([0, 0, 0]) translate([85, 0, 0]) chain_swept(0); plates(); }              // chain moved 85 mm toward the machine: into the drive plates
else if (check == "C22b") intersection() { chain_swept(2.9); drive_end_env(0, false); }                   // both shafts' drive parts (gears, hubs, collars, thrust, end caps, heads; not A's own sprocket) clear the band by 2.9
else if (check == "C22bctl") intersection() { translate([0, 40, 0]) chain_swept(0); drive_end_env(0, false, ["B"]); }                                     // chain 40 mm toward B: hits B's end cap / head
else if (check == "C22c") { intersection() { chain_swept(0); tl_env_body_only(); } for (ty = [-TENS_TRAVEL, 0, TENS_TRAVEL]) intersection() { chain_band(ty, 0); idler_hw_env(ty); } }                                  // the chain clears the TL body, collar, idler spacer and bolt (the sprocket plates are the engaged parts)
else if (check == "C22cctl") intersection() { translate([0, 15, 0]) chain_swept(0); tl_env_body_only(); }                      // control: chain 15 mm off to the side cuts the TL body
// ---- C23: gearbox + TL + motor + belt vs the rest
else if (check == "C23a") intersection() { union() { gearbox_ph(); worm_ph(); output_shaft_ph(); tl_ph(); shaft_hw_ph(); }; union() { building(); drive_deck(); deck_legs(); tens_upright(); tens_base(); motor_ph(); pulleys_ph(); belt_ph(); } }
else if (check == "C23actl") intersection() { translate([195, 0, 0]) union() { gearbox_ph(); tl_ph(); shaft_hw_ph(); }; cabinet_panels(); }                    // gearbox 195 mm toward the machine: into the cabinet
else if (check == "C23b") intersection() { union() { motor_ph(); pulleys_ph(); motor_shaft_ph(); belt_ph(); }; union() { building(); deck_legs(); tens_upright(); tens_base(); gearbox_ph(); gb_mount(); tl_ph(); shaft_hw_ph(); } }
else if (check == "C23c") intersection() { translate([0, 0, -0.01]) drive_deck(); union() { motor_ph(); gb_mount(); tens_base(); belt_guard(0); belt_guard(1); gearbox_ph(); pulleys_ph(); belt_ph(); } }     // deck vs everything on it (nudged: contact only)
else if (check == "C23cctl") intersection() { translate([0, 0, 3]) drive_deck(); union() { motor_ph(); gb_mount(); } }
else if (check == "C23d") intersection() { union() { deck_legs(); translate([0, 0, -0.01]) drive_deck(); }; union() { building(); gearbox_ph(); gb_mount(); tens_upright(); tens_base(); tl_ph(); shaft_hw_ph(); drive_end_guard(); } }
else if (check == "C23e") intersection() { union() { rail_bolts_ph(); gb_foot_bolts_ph(); tens_bolts_ph(); tens_bolt_ph(0); tens_idler_ph(0); }; union() { gb_flange(); gb_housing(); gb_mount(); drive_deck(); tens_base(); tens_upright(); } }       // hardware seated, 0.01 off every face
else if (check == "C23ectl") intersection() { translate([3, 0, 0]) union() { rail_bolts_ph(); gb_foot_bolts_ph(); tens_bolts_ph(); }; union() { gb_flange(); gb_mount(); drive_deck(); tens_base(); } }
else if (check == "C23f") intersection() { tens_idler_ph(0); tens_upright(); }          // idler + spacer 0.01 off the upright face
else if (check == "C23fctl") intersection() { translate([1, 0, 0]) tens_idler_ph(0); tens_upright(); }
// ---- C24: the drive-end / chain guard
else if (check == "C24a") intersection() { moving_drive_env(GCHK); drive_end_guard(); }
else if (check == "C24actl") intersection() { moving_drive_env(3.5); drive_end_guard(); }
else if (check == "C24b") intersection() { drive_end_guard(); union() { translate([-0.01, 0, 0]) gearbox_ph(); worm_ph(); gb_mount(); drive_deck(); deck_legs(); tens_bolts_ph(); tens_bolt_ph(0); belt_guard(0); belt_guard(1); motor_ph(); pulleys_ph(); belt_ph(); cabinet_panels(); base_plate(); } }
else if (check == "C24c") intersection() { drive_end_guard(); union() { for (bx = tens_upright_boxes()) grow_box(bx, GCHK); grow_box(tens_base_box(), 1); } }     // the window is 3 mm all round the head plate
else if (check == "C24cctl") intersection() { drive_end_guard(); for (bx = tens_upright_boxes()) grow_box(bx, 3.4); }
else if (check == "C2g") intersection() { drive_end_env(GCHK); drive_end_guard(); }
else if (check == "C2gctl") intersection() { drive_end_env(GCHK); translate([4, 0, 0]) drive_end_guard(); }
else if (check == "C2c") intersection() { free_env(GCHK); free_end_cover(); }
else if (check == "C2cctl") intersection() { free_env(3.5); free_end_cover(); }
else if (check == "C6") intersection() { rotating_set("A", angle); b_shifted(dx, angle); }
else if (check == "C8b") intersection() { union() { belt_guard(0); belt_guard(1); }; union() { translate([0, 0.01, -0.01]) drive_deck(); base_plate(); tens_upright(); tens_base(); } }   // deck nudged 0.01: the guard feet touch the deck top
else if (check == "C8c") intersection() { union() { belt_guard(0); belt_guard(1); }; translate([0, 0.01, 0]) union() { gb_housing(); gb_mount(); gb_flange(); } }   // housing / rails nudged 0.01 into the guard: sees overlaps, ignores the touching face
else if (check == "C8d") intersection() { union() { belt_guard(0); belt_guard(1); }; union() { pulleys_ph(); belt_ph(); translate([0, 0.01, 0]) motor_ph(); } }   // motor nudged 0.01: its front face touches the guard back
else if (check == "C8ctl") intersection() { union() { belt_guard(0); belt_guard(1); }; translate([0, -0.5, 0]) gb_housing(); }
else if (check == "C8e") intersection() { belt_guard(0); translate([-0.01, 0, 0]) belt_guard(1); }          // B nudged 0.01 away along u: A's end face touches B's shoulder
else if (check == "C8ectl") intersection() { belt_guard(0); translate([-0.01, 0, 0.5]) belt_guard(1); }
else if (check == "C9a") erode4() cab_shell_free();
else if (check == "C9actl") erode4() cab_shell_free(16);
else if (check == "C9actl2") erode4() cab_shell_free(0, 16);                                                       // control: Ø16 hole in the FIXED upper front must show
// ---- C30: the fixed upper front panel: with the drawer (front + bin) removed the space above the grid is closed to the outside
else if (check == "C30a") intersection() { erode4() cab_shell_free_nodrawer(0); above_mesh_slab(); }              // no 4 mm cube of free shell space from the lower cleats' underside up (eroded first, then cut: the cut must not hide a gap)
else if (check == "C30actl") intersection() { erode4() cab_shell_free_nodrawer(30); above_mesh_slab(); }          // control: panel bottom raised 30 mm (ends 8.9 mm above the mesh underside): must show
else if (check == "C30actl2") intersection() { erode4() cab_shell_free_nodrawer(1000); above_mesh_slab(); }       // control: panel absent (the old open front above the grid): must show
else if (check == "C30a2") intersection() { erode4() cab_shell_free_nodrawer(0); below_grid_slab(); }             // INFORMATION: the drawer opening (shell free space) is under the lower cleats: non-empty, and only there
else if (check == "C30b") erode4() rail_slot_free(0);                                                              // the slot between the fixed panel and the front rail is 1 mm: no 4 mm cube
else if (check == "C30bctl") erode4() rail_slot_free(6);                                                           // control: grid set 6 mm further back leaves a 7 mm slot: must show
else if (check == "C30c") intersection() { translate([0, 0, 0.04]) upper_front(); base_plate(); }                  // the panel's top edge touches the base plate (0.04 further up = overlap)
else if (check == "C30cctl") intersection() { translate([0, 0, 0.04 - 0.5]) upper_front(); base_plate(); }         // control: 0.5 mm lower: no contact
else if (check == "C30d") intersection() { translate([0, 0.04, 0]) upper_front(); cabinet_shell_panels(); }        // its back face touches both side panels' front edges
else if (check == "C30dctl") intersection() { translate([0, 0.04 - 0.5, 0]) upper_front(); cabinet_shell_panels(); }   // control: 0.5 mm further forward: no contact
else if (check == "C30e") for (t = [0 : 10 : 180]) intersection() { upper_front(); drawer_moved_ph(t); }          // the drawer (front, bin, handle) closed and pulled out 0 .. 180 clears the fixed panel
else if (check == "C30ectl") intersection() { upper_front(); translate([0, 0, 1.5]) drawer_moved_ph(0); }          // control: the drawer front raised 1.5 mm (of its 1 mm gap) hits it
else if (check == "C30f") { assert(uf_zb() <= grid_zl(), "the fixed upper front panel must reach down to or below the underside of the lower grid cleats"); assert(uf_zb() - drf_zt() == uf_gap() && drf_zt() >= bin_top()); }
else if (check == "C30fctl") { assert(uf_zb() + 30 <= grid_zl(), "control: a fixed panel whose bottom edge is 30 mm higher must fail the assert"); }
else if (check == "C10a") intersection() { drawer_blade(travel); sw_slot_from(10); }                          // travel = 0: blade >= 10 mm in the slot (nonempty); travel = 3: only 9 (empty)
else if (check == "C10b") for (t = [0 : 1 : 15]) intersection() { drawer_actuator(t); drawer_switch_ph(); }   // the WHOLE actuator clears the switch (slot walls included) over the travel 0 .. 15: EMPTY
else if (check == "C10bctl") intersection() { translate([1.4, 0, 0]) drawer_actuator(0); drawer_switch_ph(); }   // control: actuator 1.4 mm sideways (blade 3 in a 5 slot) must hit the slot wall
else if (check == "C10c") intersection() { drawer_blade(travel); drawer_switch_env(); }                       // travel = 12: completely out (empty); travel = 5: still in (nonempty)
else if (check == "C10d") intersection() { translate([0.01, 0, 0]) union() { drawer_act_pad_moved(0); drawer_actuator(0); drawer_actuator_screws_ph(0); }   // nudged 0.01 off the side panel face
                                           union() { drawer_pad(); drawer_switch_ph(); drawer_switch_screws_ph(); cabinet_panels(); base_plate(); } }   // actuator + pad clear of the static parts
else if (check == "C11feet") intersection() { translate([0, 0, -0.01]) belt_guard(half); drive_deck(); }       // guard nudged 0.01 into the deck: the feet touch it (nonempty)
else if (check == "C11lap") intersection() { translate([0, 0, 0.4]) belt_guard(0); belt_guard(1); bg_probe_slab(u0, u1); }   // A lifted 0.4: overlaps B's sleeve only where the lap is (nonempty inside, empty outside)
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
// ---- C26: chain plane, belt, wraps, idler (the three tooth plates and the chain are cut by one thin slab at x = X_CHAIN)
else if (check == "C26a1") intersection() { chain_slab(0); translate([0, YA, 0]) sprocket_disc_ph(); }          // sprocket A's tooth plate is in the chain plane
else if (check == "C26a2") intersection() { chain_slab(0); tl_plate_ph(); }                                    // the TL350's tooth plate (the centre member, 12 mm from the flange end) is cut by it
else if (check == "C26a3") intersection() { chain_slab(0); tens_idler_ph(0); }                                 // the idler's tooth plate
else if (check == "C26a4") intersection() { chain_slab(0); chain_band(0); }                                    // the chain
else if (check == "C26actl") intersection() { chain_slab(-14); union() { translate([0, YA, 0]) sprocket_disc_ph(); tens_idler_ph(0); chain_band(0); } }   // control: a slab 8 mm off the plane cuts none of them (EMPTY)
else if (check == "C26b") { assert(abs(motor_axis_z() - worm_axis()[1]) < 1e-9, "motor axis height = worm axis height (belt horizontal)"); }
else if (check == "C26bctl") { assert(abs(motor_axis_z() + 5 - worm_axis()[1]) < 1e-9, "control: a motor 5 mm lower must fail the horizontal-belt test"); }
else if (check == "C26c") { assert(RT > RA && chain_wrap_deg() > 120 && chain_wrap_deg() < 180, "wrap angle on sprocket A between 120 and 180 deg"); }
else if (check == "C26d") { assert(idler_push(0) > 0 && idler_inside(0), "the idler sits inside the loop and pushes the slack run outward"); }
else if (check == "C26dctl") { assert(idler_push(-30) > 0, "control: an idler 30 mm too far in does not push the slack run outward"); }
else if (check == "C26e") { assert(DECK_X1 < -30 && DECK_Z1 < -53, "the drive deck is outside and below the cabinet (starts at x = -30)"); }
// ---- C27: hold-down against chain uplift (leg angles, bolts, anchors) -- the path rails -> deck -> top angles -> legs -> foot angles -> floor
else if (check == "C27a") intersection() { union() { top_angles(); foot_angles(); }; union() { drive_deck(); deck_legs(); gb_mount(); tens_base(); motor_ph(); floor_ph(); belt_guard(0); belt_guard(1); } }          // angles sit 0.01 off every face
else if (check == "C27actl") intersection() { translate([0, 0, 0.5]) top_angles(); drive_deck(); }                                                    // control: top angles 0.5 mm up hit the deck
else if (check == "C27b") intersection() { holddown_hw_ph(); union() { drive_deck(); deck_legs(); top_angles(); foot_angles(); floor_ph(); gb_mount(); } }  // bolts pass their holes (Ø8 in Ø9), washers / heads / nuts sit 0.01 off the faces
else if (check == "C27bctl") intersection() { translate([2, 0, 0]) holddown_hw_ph(); union() { drive_deck(); deck_legs(); top_angles(); foot_angles(); } }   // control: all bolts 2 mm sideways hit
else if (check == "C27c") intersection() { union() { top_angles(); foot_angles(); holddown_hw_ph(); }; union() { gearbox_ph(); worm_ph(); tl_ph(); shaft_hw_ph(); output_shaft_ph(); motor_ph(); pulleys_ph(); belt_ph(); tens_upright(); tens_base(); building(); drive_end_guard(); } }
else if (check == "C27d") { assert(len(ANCHOR_PTS) == 2 * len(DECK_LEG_C) && len(TOPANG_DECK_PTS) == DECK_ANGLE_DECK_BOLTS * len(DECK_LEG_C) && len(TOPANG_LEG_PTS) == DECK_ANGLE_LEG_BOLTS * len(DECK_LEG_C)
                            && len(FOOTANG_LEG_PTS) == FOOT_ANGLE_LEG_BOLTS * len(DECK_LEG_C) && len(RAIL_BOLT_PTS) == 4, "hold-down: 2 + 2 + 2 + 2 bolts and anchors per leg, 4 rail bolts");
                            echo(str("C27d anchors: ", len(ANCHOR_PTS), " x ", DECK_ANCHOR, " at ", [for (p = ANCHOR_PTS) [round(10 * p[0]) / 10, round(10 * p[1]) / 10]])); }
// ---- C28: gearbox output shaft: fits, circlip, axial retention (spacer - TL - collar), keyways, length
else if (check == "C28a") intersection() { output_shaft_ph(); union() { gearbox_ph(); tl_ph(); shaft_hw_ph(); } }                                  // Ø25 shaft in the Ø25.02 hub, TL bore, spacer, collar, circlip groove
else if (check == "C28b") intersection() { translate([0.05, 0, 0]) circlip_ph(); gearbox_ph(); }                                                      // circlip lies on the housing's far face: 0.05 further = in the housing
else if (check == "C28bctl") intersection() { translate([-0.4, 0, 0]) circlip_ph(); gearbox_ph(); }                                                   // control: 0.4 mm off the face: no contact (EMPTY)
else if (check == "C28c1") intersection() { translate([0, 0, 0]) translate([-0.04, 0, 0]) out_spacer_ph(); gearbox_ph(); }                           // spacer on the housing face
else if (check == "C28c2") intersection() { translate([-0.04, 0, 0]) tl_ph(); out_spacer_ph(); }                                                      // TL hub on the spacer
else if (check == "C28c3") intersection() { translate([-0.04, 0, 0]) stop_collar_ph(); tl_ph(); }                                                     // collar on the TL hub's outboard end
else if (check == "C28cctl") intersection() { translate([-0.04 + 0.5, 0, 0]) tl_ph(); out_spacer_ph(); }                                              // control: TL 0.5 mm off the spacer (EMPTY)
else if (check == "C28d") intersection() { output_shaft_ph(); translate([(GBKEY_X0 + GBKEY_X1) / 2 - 1, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }   // gearbox keyway is cut there (EMPTY)
else if (check == "C28dctl") intersection() { output_shaft_ph(); translate([GB_X1 - 3, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }         // control: 3 mm before the hub's end the shaft is solid
else if (check == "C28e") intersection() { output_shaft_ph(); translate([(TLKEY_X0 + TLKEY_X1) / 2 - 1, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }    // TL keyway
else if (check == "C28ectl") intersection() { output_shaft_ph(); translate([TL_X1 + 1, YA - 3, ZO + JOURNAL_D / 2 - SHAFT_KEY_D + 0.5]) cube([2, 6, SHAFT_KEY_D - 1]); }        // control: beyond the TL key
else if (check == "C28f") { assert(abs((OUT_X1 - OUT_X0) - (CIRCLIP_EDGE + CIRCLIP_GROOVE_W + GB_HUB_L + TL_GB_GAP + TL_L + TL_COLLAR_T + SHAFT_OUT_END)) < 1e-9, "shaft length = far circlip + hub + gap + TL + collar + 3");
                            echo(str("C28f shaft length ", OUT_X1 - OUT_X0, " = ", CIRCLIP_EDGE, " + ", CIRCLIP_GROOVE_W, " + hub ", GB_HUB_L, " + gap ", TL_GB_GAP, " + TL ", TL_L, " + collar ", TL_COLLAR_T, " + ", SHAFT_OUT_END, ";  GB_OHL_ARM = ", GB_OHL_ARM)); }
else if (check == "C28fctl") { assert(abs((OUT_X1 - OUT_X0) + 1 - (CIRCLIP_EDGE + CIRCLIP_GROOVE_W + GB_HUB_L + TL_GB_GAP + TL_L + TL_COLLAR_T + SHAFT_OUT_END)) < 1e-9, "control: a shaft 1 mm short must fail"); }
else if (check == "C28g") { assert(abs(GB_OHL_ARM - (TL_GB_GAP + TL_CM_OFFSET)) < 1e-9 && abs(X_CHAIN - x_chain) < 1e-9 && abs(TL_X0 + TL_CM_OFFSET - x_chain) < 1e-9, "chain plane = housing face + TL_GB_GAP + TL_CM_OFFSET = shaft A's sprocket plane"); }
else if (check == "C28gctl") { assert(abs(GB_OHL_ARM + 1 - (TL_GB_GAP + TL_CM_OFFSET)) < 1e-9, "control: a 1 mm wrong overhang must fail"); }
else if (check == "C28h") { assert(abs((TL_X1 - TL_X0) - TL_L) < 1e-9 && TL_X1 < -30 && TL_COLLAR_X1 + SHAFT_OUT_END + DG_CLR < CAB_X0_CHK, "TL350 and its shaft end stay outside the cabinet (x < -30) with the guard"); }
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
// ---- C29: the fixed safety grid
else if (check == "C29a") { assert(GRID_Z <= -R_TIP - GRID_MIN_DIST, "grid top must be >= 120 mm under the blade-tip envelope"); intersection() { translate([0, 0, -GRID_MIN_DIST]) blade_envs(); grid_mesh(); } }   // the blade envelopes moved 120 down miss the real mesh
else if (check == "C29actl") intersection() { translate([0, 0, -GRID_MIN_DIST - 20]) blade_envs(); grid_mesh(); }                  // control: moved 140 down (= a mesh 20 mm higher than allowed) they hit it
else if (check == "C29actl2") { assert(GRID_Z + 40 <= -R_TIP - GRID_MIN_DIST, "control: a grid 40 mm higher must fail the 120 mm assert"); }
else if (check == "C29b") intersection() { grid_probes(FINGER_D, GRID_MIN_DIST); blade_envs(); }                                 // Ø16 through any cell: its tip is 120 above the mesh = 16 below the blades
else if (check == "C29b2") intersection() { grid_probes(FINGER_D, GRID_MIN_DIST); grid_mesh(); }                                // INFORMATION: the Ø16 finger passes every cell untouched (empty) - what protects is the 120 mm, not the mesh
else if (check == "C29b2ctl") intersection() { grid_probes(GRID_PITCH - GRID_WIRE + 2, GRID_MIN_DIST); grid_mesh(); }             // control: a probe 2 mm wider than the clear opening is stopped by the wires (must hit)
else if (check == "C29bctl") intersection() { grid_probes(FINGER_D, GRID_MIN_DIST + 25); blade_envs(); }                         // control: a probe 25 mm longer reaches the blades (must hit)
else if (check == "C29c1") intersection() { grid_set(0.01); union() { cabinet_panels(); drawer_front(); base_plate(); skirt(1); skirt(-1); } }             // cleats touch the walls: shrunk 0.01
else if (check == "C29c1ctl") intersection() { translate([-3, 0, 0]) grid_set(0.01); cabinet_panels(); }                                           // control: grid 3 mm toward the drive-end wall (must hit)
else if (check == "C29c2") for (t = [0 : 10 : 180]) intersection() { grid_set(0.01); translate([0, 0, 3.9]) drawer_moved_ph(t); }                // drawer closed and pulled out 0 .. 180, raised by 3.9 mm (of the 4.1 clearance): still clear
else if (check == "C29c2ctl") for (t = [0 : 10 : 180]) intersection() { grid_set(0.01); translate([0, 0, 4.5]) drawer_moved_ph(t); }           // control: raised by 4.5 hits the lower cleats
else if (check == "C29c3ctl") intersection() { grid_set(0.01); translate([0, 0, 100]) drawer_moved_ph(0); }                                         // control: the old 250 high bin (top 100 higher) hits the grid
else if (check == "C29d") erode_h(GRID_MAX_EDGE_GAP / 2) grid_edge_free(0);                                                                         // no 10 mm cube fits between the sheet and the walls
else if (check == "C29dctl") erode_h(GRID_MAX_EDGE_GAP / 2) grid_edge_free(12);                                                                     // control: a sheet 12 mm smaller each side leaves room for it
else if (check == "C29h") linear_extrude(1) offset(r = -GRID_MAX_OPEN / 2) grid_free_2d();                                       // no Ø30 disc (hand / arm) fits in ANY opening of the plan: stopped everywhere
else if (check == "C29hctl") linear_extrude(1) offset(r = -FINGER_D / 2) grid_free_2d();                                          // control: the Ø16 finger does fit in the cells (must be non-empty)
else if (check == "C29g") intersection() { grid_mesh(); translate([-50, -150, GRID_Z + 0.001]) cube([400, 300, 10]); }             // nothing of the mesh above GRID_Z
else if (check == "C29gctl") intersection() { grid_mesh(); translate([-50, -150, GRID_Z - 0.3]) cube([400, 300, 10]); }           // control: the wires do reach GRID_Z (must hit)
else if (check == "C29e") { assert(GRID_PITCH - GRID_WIRE <= GRID_MAX_OPEN, "grid: clear opening must be <= 30 mm"); }
else if (check == "C29ectl") { assert(40 - GRID_WIRE <= GRID_MAX_OPEN, "control: a 40 mm pitch mesh must fail"); }
// ---- C31: the MADE gears in mesh (gear.scad: involute teeth, backlash).  A turns -angle, B +angle (as assembly.scad); tooth phase set so they mesh at angle = 0
else if (check == "C31") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); }
else if (check == "C31ctl_cd") intersection() { rot_frame("A", angle) gear_exact("A"); translate([0, -0.3, 0]) rot_frame("B", angle) gear_exact("B"); }              // centre distance 0.3 short: must hit
else if (check == "C31ctl_nobl") intersection() { rot_frame("A", angle) gear_exact("A", 0); rot_frame("B", angle) gear_exact("B", 0, 0.5); }                       // no backlash + B 0.5 deg off: must hit
else if (check == "C31ctl_phase") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B", GEAR_cut_extra, 180 / GEAR_z); }    // tooth meets tooth (phase wrong by half a pitch): must hit
else if (check == "C31off") intersection() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B", GEAR_cut_extra, goff); }               // B turned goff deg off the conjugate position: free inside +-0.139 deg (= half the backlash 0.1456 mm on r 30), hits outside
// ---- C32: both real gears clear of the plates, the drive-end / chain guard and the chain band; C32s: gear B clear of sprocket A
else if (check == "C32") intersection() { union() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); }
                                          union() { plates(); drive_end_guard(); chain_swept(0); } }
else if (check == "C32s") intersection() { rot_frame("B", angle) gear_exact("B"); sprocket_a_env(0); }                                                                  // gear B vs sprocket A (gear A sits against A's own sprocket hub: contact, C20c10)
else if (check == "C32ctl") intersection() { translate([10, 0, 0]) union() { rot_frame("A", angle) gear_exact("A"); rot_frame("B", angle) gear_exact("B"); } plates(); }   // gears 10 mm toward the plates: must hit
else assert(false, str("unknown check ", check));

// ---- small helpers used above
DG_CLR = 6;  CAB_X0_CHK = -30;       // guard end wall (3 + 3 clearance) and the cabinet's x0
module chain_slab(dx) translate([X_CHAIN + dx - 0.1, -500, -800]) cube([0.2, 1000, 1000]);
module grow_box(bx, g) translate(bx[0] - [g, g, g]) cube(bx[1] + 2 * [g, g, g]);
module tl_env_body_only() { cylx(TL_D / 2, TL_X0, TL_X1, YA, ZO); cylx(TL_COLLAR_D / 2, TL_COLLAR_X0, TL_COLLAR_X1, YA, ZO); cylx(OUT_SPACER_D / 2, GB_X1, TL_X0, YA, ZO); }
module idler_hw_env(ty) { y = tens_y(ty); cylx(TENS_SPACER_D / 2, TL_PL1, TENS_UP_X0, y, TENS_Z); cylx(TENS_WASHER_D / 2, TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3, TL_PL0 - 0.5, y, TENS_Z); }
function chain_wrap_deg() = 180 - 2 * asin((RT - RA) / CHAIN_CD);     // wrap on the small sprocket (A), degrees
function idler_push(ty) = tens_y(ty) + TENS_R - run_y(TENS_Z);       // how far the idler's chain line is outside the straight +y run (mm)
function idler_inside(ty) = tens_y(ty) < run_y(TENS_Z);              // the idler centre is inside the loop
