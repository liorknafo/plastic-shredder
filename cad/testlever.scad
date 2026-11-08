// testlever.scad -- BLADE TORQUE TEST LEVER: proves that a mild-steel blade's hex bore takes T_LIMIT (the most the shafts may ever see; params.py).
//   Every torque / mass in the echo lines and PNG labels is computed from T_LIMIT, TEST_WEIGHT_KG, TEST_WEIGHT_ARM: no number is typed in.
//   -D 'part="world"|"lever"|"lever_2d"|"bom"'      PNG: -D 'labels=true' -D 'cam=[rx,ry,rz]' (text and the detail inset face that camera)
//
// SET-UP  The test shaft (the real shaft B, 42CrMo4) is held in a vise by two hex flats (jaws on the +-y flats).  ONE blade (variant 0) sits on
//   the hex next to the drive-side Ø25 journal; the lever turns on that journal (Ø25.2 hole); a Ø12 hardened dowel pin (or the plain shank of an
//   M12 12.9 bolt) pressed into the lever bears on the STRAIGHT HOOK FACE of one tooth; TEST_WEIGHT_KG hangs from the Ø10.5 hole at TEST_WEIGHT_ARM from the
//   pivot: TEST_WEIGHT_KG x 9.81 x TEST_WEIGHT_ARM + the lever's own ~5 N*m = T_LIMIT on the hex bore (PNG label / echo give the numbers).
// TURN DIRECTION  The lever turns OPPOSITE to the blade's cutting rotation (the direction in which plastic loads the hook face).  The blade is shown
//   in shaft B's orientation, which cuts POSITIVE about +x (counter-clockwise seen from the free end, looking back along -x); the lever turns
//   NEGATIVE about +x (CLOCKWISE seen from the free end): its +y end, with the weight, goes DOWN.
// ANGLE AT CONTACT  The lever is HORIZONTAL (0 deg, pointing +y) when the pin meets the face, so the weight acts on the full 500 mm.  The tooth tip
//   is TEST_BLADE_ROT = -30 deg (30 deg below horizontal; the hex flats face +-y, a hex vertex lies under every tooth tip); the pin centre is
//   test_pin_psi = 10.17 deg ahead of that tip, i.e. -19.83 deg (19.8 deg below horizontal) at radius TEST_PIN_R = 32 from the pivot, so the pin
//   hole is 10.85 mm below the lever centreline.  The pin touches the face at R32.54 (the straight part of the face spans R29.53-34).
// PIN RADIUS  Smallest pivot-to-pin radius at which a Ø12 pin clears the blade root and the gullet fillet and touches the straight face:
//   30.9995 (design/build.py, pin_analysis).  TEST_PIN_R = that + 1.0, rounded up to 0.5 = 32.0.  Clearance at 32: 0.18 mm to the fillet, 1.0 to the root.
// LEVER  Mild-steel flat 50 x 10, 540 long, from the stock list (50 x 10 x 1100): pivot Ø25.2 (25 from the end), pin hole Ø12 (reamed for the
//   pressed dowel; tap M12 instead for a bolt), weight hole Ø10.5 at 500 from the pivot.  STL = flat (thickness along z), DXF = outline + 3 holes.
include <common.scad>
use <blade.scad>
use <shaft.scad>

part = "world";
labels = false;
cam = [70, 0, 55];

// ---------------------------------------------------------------- layout (x along the shaft, as on the machine; shaft B drive-side journal at x < hex_x0)
TL_BX0 = hex_x0;                                // blade near face = start of the hex section (1.5), blade x in [1.5, 9.5]
TL_LX1 = TL_BX0 - TEST_BLADE_GAP;               // lever face toward the blade (0.5), all of the lever is on the Ø25 journal
TL_LX0 = TL_LX1 - TEST_LEVER_T;                 // lever back face (-9.5)
TL_PIN_X0 = TL_LX0;                             // pin sits in the lever's full thickness (flush with the back face)
TL_PIN_L = TEST_LEVER_T + TEST_PIN_PROJ;        // 19: pin tip at x = 9.5, flush with the blade's far face
TL_VX0 = 24;  TL_VX1 = 104;                     // vise jaws grip the hex over x = 24 .. 104 (placeholder)
PIN_YZ = TEST_PIN_R * [cos(test_pin_deg), sin(test_pin_deg)];          // pin centre in the world (lever at TEST_LEVER_DEG)
PIN_LEVER = TEST_PIN_R * [cos(test_pin_deg - TEST_LEVER_DEG), sin(test_pin_deg - TEST_LEVER_DEG)];   // the same in the lever's own frame (pivot at the origin, lever along +x)

// ---------------------------------------------------------------- design rules (fail the render, not just the log)
assert(abs(norm(PIN_LEVER) - TEST_PIN_R) < 1e-9);
assert(TEST_LEVER_W / 2 - abs(PIN_LEVER[1]) - TEST_PIN_D / 2 >= 6, "pin hole needs >= 6 mm of steel to the lever edge");
assert(TEST_PIN_R - TEST_LEVER_PIVOT_D / 2 - TEST_PIN_D / 2 >= 6, "pin hole needs >= 6 mm of steel to the pivot hole");
TEST_PIN_F_ = T_LIMIT * 1000 / TEST_PIN_R;
assert(abs(test_pin_F - TEST_PIN_F_) < 0.01);
assert(abs(test_pin_sigma - TEST_PIN_F_ * (T_BLADE / 2 + 1) * 32 / (PI * pow(TEST_PIN_D, 3))) < 0.01);

// ---------------------------------------------------------------- the lever (2D, pivot at the origin, lever along +x)
module lever_2d_p() {
    $fn = 96;
    difference() {
        translate([-TEST_LEVER_PIVOT_END, -TEST_LEVER_W / 2]) square([TEST_LEVER_L, TEST_LEVER_W]);
        circle(d = TEST_LEVER_PIVOT_D);
        translate(PIN_LEVER) circle(d = TEST_PIN_D);
        translate([TEST_WEIGHT_ARM, 0]) circle(d = TEST_WEIGHT_HOLE_D);
    }
}
module lever_2d() translate([TEST_LEVER_PIVOT_END, 0]) lever_2d_p();          // part frame: end of the bar at x = 0, pivot at x = 25
module lever_flat() linear_extrude(TEST_LEVER_T) lever_2d();                  // STL: flat on z = 0

// ---------------------------------------------------------------- the rig (world frame)
module tl_turn(a) rotate([a, 0, 0]) children();                               // a < 0 turns the lever the way the test loads it (about the shaft axis)
module tl_lever() rotate([TEST_LEVER_DEG, 0, 0]) axial(TL_LX0) linear_extrude(TEST_LEVER_T) lever_2d_p();
module tl_pin(grow = 0) translate([TL_PIN_X0, PIN_YZ[0], PIN_YZ[1]]) rotate([0, 90, 0]) cylinder(d = TEST_PIN_D + 2 * grow, h = TL_PIN_L, $fn = 96);
module tl_blade() axial(TL_BX0) rotate([0, 0, TEST_BLADE_ROT]) blade(0);
module tl_shaft() rotate([TEST_BLADE_ROT, 0, 0]) shaft_local("B");           // hex vertex under every tooth tip; flats face +-y
module tl_vise_ph() {                                                         // jaws on the +-y flats, body under them
    for (s = [-1, 1]) translate([TL_VX0, s > 0 ? HEX_AF / 2 : -HEX_AF / 2 - 30, -35]) cube([TL_VX1 - TL_VX0, 30, 50]);
    translate([TL_VX0 - 5, -60, -85]) cube([TL_VX1 - TL_VX0 + 10, 120, 50]);
}
// the straight hook face of tooth 0 (tip at TEST_BLADE_ROT): a strip 1 mm deep on the material side, along the face only
module tl_face_probe() axial(TL_BX0 - 1) rotate([0, 0, TEST_BLADE_ROT]) linear_extrude(T_BLADE + 2) {
    h = HOOK_DEG;  nrm = [-sin(h), cos(h)];  tip = [R_TIP, 0];  e = tip + hook_face_len * [-cos(h), -sin(h)];
    polygon([tip, e, e - nrm, tip - nrm]);
}
// weight (steel cylinder of TEST_WEIGHT_KG) on a shackle bolted through the Ø10.5 hole
TL_WH = TEST_WEIGHT_KG / (7.85e-6 * PI * 75 * 75);                           // height of a Ø150 steel cylinder of that mass
module tl_weight_ph() translate([(TL_LX0 + TL_LX1) / 2, TEST_WEIGHT_ARM * cos(TEST_LEVER_DEG), TEST_WEIGHT_ARM * sin(TEST_LEVER_DEG)]) {
    rotate([0, 90, 0]) translate([0, 0, -14]) cylinder(d = 10, h = 28, $fn = 32);                      // M10 bolt through the hole
    for (s = [-1, 1]) translate([s * (TEST_LEVER_T / 2 + 2.2) - 1.6, -7, -45]) cube([3.2, 14, 53]);   // shackle legs
    translate([-(TEST_LEVER_T / 2 + 3.8), -7, -47]) cube([TEST_LEVER_T + 7.6, 14, 4]);                 // shackle bow
    translate([0, 0, -150]) cylinder(d = 8, h = 105, $fn = 24);                                        // rod
    translate([0, 0, -150 - TL_WH]) cylinder(d = 150, h = TL_WH, $fn = 64);                            // the TEST_WEIGHT_KG weight
}

// ---------------------------------------------------------------- colours and labels (PNG only)
C_RED = "#c82829"; C_ORANGE = "#f5871f"; C_YELLOW = "#eab700"; C_GREEN = "#718c00";
C_AQUA = "#3e999f"; C_BLUE = "#4271ae"; C_PURPLE = "#8959a8"; C_GRAY = "#8e908c"; C_DARK = "#4d4d4c";
module view_xf() rotate([0, 0, cam[2]]) rotate([0, cam[1], 0]) rotate([cam[0], 0, 0]) children();
module tl_label(txt, target, off = [0, 40], size = 10, col = "#222222", line = true, ha = "auto") {
    if (labels) color(col) translate(target) view_xf() {
        if (line) hull() { sphere(1.0, $fn = 8); translate([off[0], off[1], 200]) sphere(0.8, $fn = 8); }
        al = ha == "auto" ? (off[0] >= 0 ? "left" : "right") : ha;
        translate([off[0] + (al == "left" ? 3 : -3), off[1], 200]) linear_extrude(1.5) text(txt, size = size, halign = al, valign = "center");
    }
}
// a block of text lines (left aligned at off), the first line only gets the leader; cols[i] colours line i
module tl_note(lines, cols, target, off, size = 8, gap = 1.6) {
    for (i = [0 : len(lines) - 1]) tl_label(lines[i], target, [off[0], off[1] - i * size * gap], size, cols[i], false, "left");
}
// dimension line along the lever (above its top edge): pivot to weight hole
module tl_dim() if (labels) color("#222222") {
    z = TEST_LEVER_W / 2 + 10;  x = (TL_LX0 + TL_LX1) / 2;
    translate([x - 0.5, 0, z - 0.5]) cube([1, TEST_WEIGHT_ARM, 1]);
    for (y = [0, TEST_WEIGHT_ARM]) translate([x - 0.5, y - 0.5, z - 8]) cube([1, 1, 16]);
}
// curved arrow in the blade plane (world y, z) at radius r from the shaft axis, from angle a0 to a1 (deg), head at a1; x = position along the shaft
module tl_arc_arrow(x, a0, a1, r, w, col) color(col) axial(x) {
    s = a1 > a0 ? 1 : -1;
    linear_extrude(1.5) {
        polygon(concat([for (a = [a0 : s * 2 : a1 - s * 8]) (r + w / 2) * [cos(a), sin(a)]], [for (a = [a1 - s * 8 : -s * 2 : a0]) (r - w / 2) * [cos(a), sin(a)]]));
        polygon([(r + 2.2 * w) * [cos(a1 - s * 9), sin(a1 - s * 9)], (r - 2.2 * w) * [cos(a1 - s * 9), sin(a1 - s * 9)], r * [cos(a1 + s * 4), sin(a1 + s * 4)]]);
    }
}

// DETAIL inset: the contact seen along the shaft from the free end (x -> toward the viewer), vise removed, magnified, billboarded to the camera
INS_K = 3.2;
module tl_detail_content() {
    color(C_GRAY) intersection() { tl_shaft(); translate([-30, -60, -60]) cube([70, 120, 120]); }
    color(C_ORANGE) tl_blade();
    color(C_BLUE) intersection() { tl_lever(); translate([-20, -60, -60]) cube([40, 120, 120]); }
    color(C_RED) tl_pin();
    tl_arc_arrow(TL_PIN_X0 + TL_PIN_L + 0.5, -6, -38, 44, 2.2, C_RED);                 // the lever turns this way (clockwise seen from the free end)
    tl_arc_arrow(TL_PIN_X0 + TL_PIN_L + 0.5, 110, 160, 44, 2.2, "#b86a10");           // the blade's cutting rotation: the opposite way
}
// the inset is placed so that ITS pin tip sits at the screen offset `off` from the real pin tip: the leader runs from the real pin to the magnified one
module tl_detail(off) translate([TL_PIN_X0 + TL_PIN_L, PIN_YZ[0], PIN_YZ[1]]) view_xf() translate([off[0], off[1], 200]) scale(INS_K)
    multmatrix([[0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 0], [0, 0, 0, 1]])           // screen (right, up, toward) = world (y, z, x)
    translate([0, -PIN_YZ[0], -PIN_YZ[1]]) tl_detail_content();
module tl_leader(off, col = "#222222") if (labels) color(col) translate([TL_PIN_X0 + TL_PIN_L, PIN_YZ[0], PIN_YZ[1]]) view_xf()
    hull() { sphere(1.0, $fn = 8); translate([off[0], off[1], 200]) sphere(0.8, $fn = 8); }
function r1(v) = round(10 * v) / 10;

module rig() {
    color(C_GRAY) tl_shaft();
    color(C_ORANGE) tl_blade();
    color(C_BLUE) tl_lever();
    color(C_RED) tl_pin();
    color("#555555", 0.35) tl_vise_ph();
    color(C_DARK) tl_weight_ph();
}

// ---------------------------------------------------------------- build log
LEVER_KG = TEST_LEVER_L * TEST_LEVER_W * TEST_LEVER_T * 7.85e-6;
LEVER_NM = LEVER_KG * 9.81 * (TEST_LEVER_L / 2 - TEST_LEVER_PIVOT_END) / 1000;                  // the lever's own moment about the pivot (~5)
WEIGHT_NM = TEST_WEIGHT_KG * 9.81 * TEST_WEIGHT_ARM / 1000;
TEST_TOTAL_NM = WEIGHT_NM + LEVER_NM;                                                          // on the hex bore: must come out at T_LIMIT
assert(abs(TEST_TOTAL_NM - T_LIMIT) < 1.0, "TEST_WEIGHT_KG must give T_LIMIT at the hex bore");
echo(str("TEST LEVER: TEST_PIN_R=", TEST_PIN_R, " (smallest radius ", test_pin_Rmin, " + 1.0, rounded up to 0.5), pin D", TEST_PIN_D,
         ", lever at ", TEST_LEVER_DEG, " deg (horizontal), tooth tip at ", TEST_BLADE_ROT, " deg, pin centre at ", test_pin_deg,
         " deg = ", test_pin_psi, " deg ahead of the tip, contact at R", test_pin_contact_r));
echo(str("TEST LEVER: pin force F = ", T_LIMIT * 1000, " / ", TEST_PIN_R, " = ", round(TEST_PIN_F_), " N;  pin bending stress (9 mm cantilever, load at ",
         T_BLADE / 2 + 1, " mm) = ", round(10 * test_pin_sigma) / 10, " MPa;  steel round the pin hole ", round(10 * test_pin_edge_steel) / 10, " (edge) / ",
         round(10 * test_pin_ring_steel) / 10, " (pivot hole)"));
echo(str("TEST LEVER: weight ", TEST_WEIGHT_KG, " kg x 9.81 x ", TEST_WEIGHT_ARM / 1000, " m = ", round(10 * TEST_WEIGHT_KG * 9.81 * TEST_WEIGHT_ARM / 1000) / 10,
         " N*m;  the lever itself (", round(10 * LEVER_KG) / 10, " kg, centre ", TEST_LEVER_L / 2 - TEST_LEVER_PIVOT_END, " mm from the pivot) adds ",
         round(10 * LEVER_KG * 9.81 * (TEST_LEVER_L / 2 - TEST_LEVER_PIVOT_END) / 1000) / 10, " N*m, the hanger a little more"));

if (part == "world") {
    rig();
    tl_labels();
}
else if (part == "lever") lever_flat();
else if (part == "lever_2d") lever_2d();
else if (part == "bom") echo(str("BOM testlever: lever flat 50 x 10 x ", TEST_LEVER_L, " (mild steel, from the 50 x 10 stock), Ø", TEST_PIN_D, " hardened dowel pin x ",
                                  TL_PIN_L, " (or M12 12.9 bolt, plain shank), ", TEST_WEIGHT_KG, " kg weight, M10 shackle"));

module tl_labels() {
    // placed for the default camera; anchors are world points, offsets are screen (right, up)
    if (labels) {
        PT = [TL_PIN_X0 + TL_PIN_L, PIN_YZ[0], PIN_YZ[1]];
        DOFF = [190, 185];
        tl_leader(DOFF, C_RED);
        tl_detail(DOFF);
        tl_dim();
        tl_label(str(TEST_WEIGHT_ARM, " mm"), [(TL_LX0 + TL_LX1) / 2, 140, TEST_LEVER_W / 2 + 10], [0, 12], 9, "#222222", false, "center");
        tl_label(str("DETAIL x", INS_K, ": seen from the free end along the shaft, vise removed"), PT, [DOFF[0] - 190, DOFF[1] + 190], 8, C_RED, false, "left");
        tl_label(str("Pin Ø", TEST_PIN_D, " on the STRAIGHT hook face"), PT, [DOFF[0] + 100, DOFF[1] - 10], 8, C_RED, false);
        tl_label("lever turn (opposite)", PT, [DOFF[0] + 100, DOFF[1] - 36], 8, C_RED, false);
        tl_label("blade cutting rotation", PT, [-100, 255], 8, "#b86a10", false);
        tl_label("VISE: jaws on two hex flats", [(TL_VX1 + 5), 0, -60], [60, -45], 9, "#444444");
        tl_label(str("LEVER 50 x 10 x ", TEST_LEVER_L, ", pivots on the Ø25 journal"), [-4, 330, 0], [0, 70], 9, C_BLUE);
        tl_label("BLADE variant 0 on the hex", [5, -24, 10], [-15, 45], 9, "#b86a10");
        tl_note([str("BLADE TORQUE TEST: a mild-steel blade's hex bore under T_LIMIT = ", T_LIMIT, " N*m"),
                 "Lever turns CLOCKWISE seen from the free end (negative about +x):",
                 "OPPOSITE to the blade's cutting rotation (counter-clockwise).",
                 str("Lever HORIZONTAL (", TEST_LEVER_DEG, " deg) at contact, tooth tip ", -TEST_BLADE_ROT, " deg below horizontal,"),
                 str("pin centre ", r1(-test_pin_deg), " deg below horizontal = ", r1(test_pin_psi), " deg ahead of the tip."),
                 str("Pin Ø", TEST_PIN_D, " at R", TEST_PIN_R, " (smallest ", test_pin_Rmin, " + 1.0, rounded up to 0.5);"),
                 str("it touches the straight hook face at R", r1(test_pin_contact_r), " (face spans R", r1(hook_face_end_r), "-", R_TIP, ")."),
                 str("F = ", T_LIMIT * 1000, " / ", TEST_PIN_R, " = ", round(test_pin_F), " N;  pin bending ", round(test_pin_sigma), " MPa (", TEST_PIN_PROJ, " mm cantilever)"),
                 str("WEIGHT ", TEST_WEIGHT_KG, " kg at ", TEST_WEIGHT_ARM, " mm = ", r1(WEIGHT_NM), " N*m + lever ", r1(LEVER_NM), " = ", r1(TEST_TOTAL_NM), " N*m (T_LIMIT ", T_LIMIT, ")")],
                ["#000000", "#c82829", "#c82829", "#222222", "#222222", "#222222", "#222222", "#222222", "#000000"],
                [-4, 0, 0], [-230, -215], 9);
    }
}
