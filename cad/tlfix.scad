// tlfix.scad -- TORQUE-LIMITER SETTING FIXTURE: the TL350-2 on a keyed stub clamped in a vise, a CHAIN WHIP lever with a weight.  (Replaces the belt-slip test.)
//   -D 'part="world"|"stub"|"stub_2d"|"lever"|"lever_2d"|"bom"'      for the PNG: -D 'labels=true' (labels face the camera given by -D 'cam=[rx,ry,rz]')
//
// WHAT IT DOES  The TL350-2 (manufacturer's layout, tl350.scad) sits on the Ø25 end of a stub made from your Ø30 bar; the Ø30 end (two vise flats, 22 across) is clamped in a vise.  The
//   stub's Ø25 pin CONTINUES beyond the TL's adjusting nut (TLFIX_PIN_L); the chain-whip LEVER (flat 50 x 10 x 600) PIVOTS on that pin (Ø25.2 bore) = on the TL axis.  A short piece of
//   #40 chain is wrapped round the TL's 30T sprocket; both of its ends are bolted to two LUGS (20 x 20) that stand on the lever's inner face and reach back to the chain plane, 100 mm
//   from the axis.  A weight hangs from a hole 500 mm from the axis.  The torque on the TL is  T = W x 9.81 x 0.5 m + the lever's own moment M_lever, so
//   W = (TL_SET_AT_TL - M_lever) / 0.5 / 9.81  (computed below from the lever's geometry); you tighten the TL's spring nut (spanner on its rim, the lever is 5 mm beyond it) until it just
//   slips with the lever horizontal.
// GEOMETRY  Stub axis = x axis.  The Ø30 shoulder is at x = 0, the vise end runs to +x, the Ø25 pin to -x.  The TL sits flange end against the shoulder and runs to -x (nut end at
//   x = -62); its sprocket plate is 12 mm from the flange-end face (chain plane x = -12).  The lever is 5 mm beyond the nut, pointing +y, horizontal when the TL starts to slip.
include <common.scad>
include <tl350.scad>

labels = false;
cam = [62, 0, 195];
part = "world";
function r1(v) = round(10 * v) / 10;

// ---------------------------------------------------------------- numbers
TL_PD = tl_sprocket_pd;  TL_R = TL_PD / 2;  TL_OD = TL_PD + SPROCKET_OD_EXTRA;
G = 9.81;  RHO = 7.85e-6;                                           // steel, kg/mm3
ATT_Y = 100;  ATT_DZ = 15;                                          // the two chain-end bolts: 100 from the axis, +-15 off the lever's centre line
// ---------------------------------------------------------------- stub (Ø25 pin through the TL and on beyond the nut, Ø30 shoulder, vise end)
XS = 0;                                                             // shoulder
STUB_DIA = STUB_D - 0.013;                                          // h6: 24.987
FIX_PIN_L = TL_L + TLFIX_PIN_L;                                     // Ø25 length: TL hub + the pin beyond the nut
X_TIP = XS - FIX_PIN_L;  X_END = XS + STUB_END_L;
FLAT_X0 = XS + 10;  FLAT_X1 = FLAT_X0 + STUB_FLAT_L;                // vise flats x = 10 .. 50
KEY_W_ = SHAFT_KEY_W;  KEY_D_ = SHAFT_KEY_D;
module stub_solid() {
    $fn = 96;
    difference() {
        union() {
            translate([X_TIP, 0, 0]) rotate([0, 90, 0]) cylinder(d = STUB_DIA, h = FIX_PIN_L + 0.01);
            translate([XS, 0, 0]) rotate([0, 90, 0]) cylinder(d = STUB_END_D, h = STUB_END_L);
        }
        for (s = [-1, 1]) translate([FLAT_X0, s * (STUB_FLAT_AF / 2 + 10) - 10, -20]) cube([STUB_FLAT_L, 20, 40]);           // two flats, 22 across (facing +-y)
        hull() for (x = [XS - TL_L + TL_KEY_END + KEY_W_ / 2, XS - TL_KEY_END - KEY_W_ / 2]) translate([x, 0, STUB_DIA / 2 - KEY_D_]) cylinder(d = KEY_W_, h = KEY_D_ + 1, $fn = 32);   // keyway 8 x 4 x 56, closed ends
    }
}
// ---------------------------------------------------------------- TL350 on the stub: flange end against the shoulder, running to -x (the layout of tl350.scad, mirrored)
TL_X0 = XS;  TL_X1 = XS - TL_L;                                     // flange-end face .. nut end
X_CP = XS - TL_CM_OFFSET;                                           // chain plane (sprocket mid-plane)
module tl_body_fix()  mirror([1, 0, 0]) tl350_body_l();
module tl_plate_fix() mirror([1, 0, 0]) tl_plate_l();
module tl_fix_ph() { tl_body_fix(); tl_plate_fix(); }
module key_ph() translate([XS - TL_L + TL_KEY_END + 0.05, -KEY_W_ / 2 + 0.05, STUB_DIA / 2 - KEY_D_ + 0.05]) cube([TL_L - 2 * TL_KEY_END - 0.1, KEY_W_ - 0.1, 7.5]);       // 8 x 7 x 56 key (placeholder)

// ---------------------------------------------------------------- lever (pivots on the pin), lugs, chain
LEVER_Y0 = -TEST_LEVER_PIVOT_END;  LEVER_Y1 = LEVER_Y0 + TLFIX_LEVER_L;        // pivot 25 from the short end: y = -25 .. 575, horizontal, +y
LEV_X1 = XS - TL_L - TLFIX_LEVER_GAP;  LEV_X0 = LEV_X1 - TLFIX_LEVER_T;         // lever 5 mm beyond the nut: x = -77 .. -67
LUG_X0 = LEV_X1;  LUG_X1 = X_CP - CHAIN_ENV_W / 2 - TLFIX_LUG_GAP;              // lug from the lever's inner face to 2.4 mm off the chain's edge
function lever_holes() = [[ATT_Y, ATT_DZ, 6.6], [ATT_Y, -ATT_DZ, 6.6], [TLFIX_ARM, 0, 10.5]];       // (y, z, d): 2 chain bolts, weight
module lever_2d() difference() {            // (y, z) outline, world coordinates
    translate([LEVER_Y0, -TLFIX_LEVER_W / 2]) square([TLFIX_LEVER_L, TLFIX_LEVER_W]);
    circle(d = TLFIX_PIVOT_D, $fn = 96);                                                    // pivot bore on the Ø25 pin
    for (h = lever_holes()) translate([h[0], h[1]]) circle(d = h[2], $fn = 64);
}
module lever() axial(LEV_X0) linear_extrude(TLFIX_LEVER_T) lever_2d();
module lug_part() difference() {           // part frame: 20 (y) x 20 (z) x length (x) ... exported lying along x
    cube([LUG_X1 - LUG_X0, TLFIX_LUG[0], TLFIX_LUG[1]]);
    translate([-1, TLFIX_LUG[0] / 2, TLFIX_LUG[1] / 2]) rotate([0, 90, 0]) cylinder(d = 6.6, h = LUG_X1 - LUG_X0 + 2, $fn = 24);
}
module lugs() for (s = [-1, 1]) translate([LUG_X0, ATT_Y - TLFIX_LUG[0] / 2, s * ATT_DZ - TLFIX_LUG[1] / 2]) lug_part();
// the lever's own moment about the TL axis (horizontal, weight side +y): lever (with its holes), 2 lugs, 2 M6 bolts, half of each chain tail
CH_KG_MM = 0.41e-3;                                                 // #40 chain, kg per mm
LEV_VOL = TLFIX_LEVER_L * TLFIX_LEVER_W * TLFIX_LEVER_T;
function disc_v(d) = PI * d * d / 4 * TLFIX_LEVER_T;
LEV_M = [ [LEV_VOL * RHO, (LEVER_Y0 + LEVER_Y1) / 2],                // lever blank at its centre
          [-disc_v(TLFIX_PIVOT_D) * RHO, 0], [-2 * disc_v(6.6) * RHO, ATT_Y], [-disc_v(10.5) * RHO, TLFIX_ARM],      // minus the holes
          [2 * (TLFIX_LUG[0] * TLFIX_LUG[1] - PI * 3.3 * 3.3) * (LUG_X1 - LUG_X0) * RHO, ATT_Y],               // 2 lugs
          [2 * (PI * 9 * (TLFIX_LEVER_T + LUG_X1 - LUG_X0 + 12) + 6 * 6 * 3.5 * 1.1) * RHO, ATT_Y],              // 2 M6 bolts through lever + lug into the chain end (shank + head)
          [2 * CH_KG_MM * 40, ATT_Y * 0.8] ];                        // half of each ~80 mm chain tail hangs on the lever
LEVER_KG = sum_m(LEV_M);
LEVER_NM = G * sum_my(LEV_M) / 1000;
function sum_m(l, i = 0) = i >= len(l) ? 0 : l[i][0] + sum_m(l, i + 1);
function sum_my(l, i = 0) = i >= len(l) ? 0 : l[i][0] * l[i][1] + sum_my(l, i + 1);
W_KG = (TL_SET_AT_TL - LEVER_NM) / (TLFIX_ARM / 1000) / G;          // hanging weight
// chain: tangent geometry from the attach points P = (ATT_Y, +-ATT_DZ) to the pitch circle, wrapping the far (-y) side
PD_ = norm([ATT_Y, ATT_DZ]);
TG_ANG = atan2(ATT_DZ, ATT_Y) + acos(TL_R / PD_);                   // polar angle of the upper tangent point
function tp(a) = TL_R * [cos(a), sin(a)];
module chain_wrap2d(grow = 0) {
    hw = CHAIN_ENV_H / 2 + grow;
    difference() {                                                  // ring sector from TG_ANG round through 180 deg to -TG_ANG
        intersection() {
            difference() { circle(r = TL_R + hw, $fn = 128); circle(r = TL_R - hw, $fn = 128); }
            polygon(concat([[0, 0]], [for (a = [TG_ANG : 4 : 360 - TG_ANG]) 200 * [cos(a), sin(a)]], [200 * [cos(360 - TG_ANG), sin(360 - TG_ANG)]]));
        }
    }
    for (s = [-1, 1]) hull() { translate(tp(s * TG_ANG)) circle(r = hw, $fn = 24); translate([ATT_Y, s * ATT_DZ]) circle(r = hw, $fn = 24); }   // the two straight tails
}
module chain_fix(grow = 0) axial(X_CP - CHAIN_ENV_W / 2 - grow) linear_extrude(CHAIN_ENV_W + 2 * grow) chain_wrap2d(grow);
CH_ARC = (360 - 2 * TG_ANG) / 360 * PI * TL_PD;                     // chain on the sprocket
CH_TAIL = sqrt(PD_ * PD_ - TL_R * TL_R);                            // each free tail
CH_LINKS = ceil((CH_ARC + 2 * CH_TAIL) / CHAIN_pitch);
// M6 x 70: head on the lever's outer face, shank through lever + lug into the chain's end pins
module chain_bolts_ph() for (h = [ATT_DZ, -ATT_DZ]) translate([LEV_X0 - 0.01, ATT_Y, h]) rotate([0, 90, 0]) rotate([180, 0, 0]) { cylinder(d = 10, h = 4, $fn = 6); rotate([180, 0, 0]) cylinder(d = 6, h = TLFIX_LEVER_T + (LUG_X1 - LUG_X0) + 12, $fn = 20); }
// weight on a shackle through the Ø10.5 hole (steel cylinder of W_KG, Ø150)
WH = W_KG / (7.85e-6 * PI * 75 * 75);
module weight_ph() translate([(LEV_X0 + LEV_X1) / 2, TLFIX_ARM, 0]) {
    rotate([0, 90, 0]) translate([0, 0, -14]) cylinder(d = 10, h = 28, $fn = 32);
    for (s = [-1, 1]) translate([s * (TLFIX_LEVER_T / 2 + 2.2) - 1.6, -7, -45]) cube([3.2, 14, 53]);
    translate([-(TLFIX_LEVER_T / 2 + 3.8), -7, -47]) cube([TLFIX_LEVER_T + 7.6, 14, 4]);
    translate([0, 0, -150]) cylinder(d = 8, h = 105, $fn = 24);
    translate([0, 0, -150 - WH]) cylinder(d = 150, h = WH, $fn = 64);
}
// ---------------------------------------------------------------- vise (placeholder blocks), stand, bench
module vise_ph() {
    for (s = [-1, 1]) translate([FLAT_X0 + 1, s > 0 ? STUB_FLAT_AF / 2 : -STUB_FLAT_AF / 2 - 30, -30]) cube([STUB_FLAT_L - 2, 30, 40]);   // jaws 30 thick, faces on the flats
    translate([FLAT_X0 - 5, -41, VISE_TOP]) cube([STUB_FLAT_L + 10, 82, -30 - VISE_TOP]);                                                   // body 50 x 82 x 42
}
VISE_TOP = -72;  BENCH_Z1 = -200;  BENCH_T = 30;
module stand_ph() translate([FLAT_X0 - 5, -45, BENCH_Z1]) cube([STUB_FLAT_L + 10, 90, VISE_TOP - BENCH_Z1]);
module bench_ph() translate([-120, -250, BENCH_Z1 - BENCH_T]) cube([240, 440, BENCH_T]);      // the weight hangs at y = 500: free of the bench

// ---------------------------------------------------------------- colours, labels
C_RED = "#c82829"; C_ORANGE = "#f5871f"; C_YELLOW = "#eab700"; C_GREEN = "#718c00";
C_AQUA = "#3e999f"; C_BLUE = "#4271ae"; C_PURPLE = "#8959a8"; C_GRAY = "#8e908c"; C_DARK = "#4d4d4c";
module view_xf() rotate([0, 0, cam[2]]) rotate([0, cam[1], 0]) rotate([cam[0], 0, 0]) children();
module label3(txt, target, off = [0, 40], size = 12, col = "#222222", leader = true, ha = "auto") {
    if (labels) color(col) translate(target) view_xf() {
        if (leader) hull() { sphere(1.2, $fn = 8); translate([off[0], off[1], 200]) sphere(0.9, $fn = 8); }
        al = ha == "auto" ? (off[0] >= 0 ? "left" : "right") : ha;
        translate([off[0] + (al == "left" ? 3 : -3), off[1], 200]) linear_extrude(1.5) text(txt, size = size, halign = al, valign = "center");
    }
}
module rig() {
    color(C_BLUE) stub_solid();
    color(C_YELLOW) key_ph();
    color(C_GRAY, 0.9) tl_fix_ph();
    color(C_ORANGE) chain_fix();
    color(C_RED) lever();
    color(C_PURPLE) lugs();
    color(C_DARK) { chain_bolts_ph(); weight_ph(); }
    color("#555555") { vise_ph(); stand_ph(); }
    color("#e0c9a6") bench_ph();
}
module tlf_labels() if (labels) {
    label3("TL350-2 (hub 62, Ø89; 30T sprocket 12 from the flange end)", [X_CP, -TL_R, -10], [-60, -150], 20, "#555555");
    label3(str("#40 chain, ", CH_LINKS, " links, ", round(360 - 2 * TG_ANG), " deg round the sprocket"), [X_CP, -TL_R - 5, 25], [-60, 230], 20, "#b86a10");
    label3("STUB Ø25 h6 + key / Ø30 end, 2 flats", [XS + 40, 0, 14], [120, 300], 20, C_BLUE);
    label3("VISE on the 2 flats", [FLAT_X0 + 20, 20, -60], [140, -170], 20, "#444444");
    label3("LEVER PIVOTS on the Ø25 pin beyond the nut (Ø25.2 bore)", [(LEV_X0 + LEV_X1) / 2, 0, 25], [-150, 190], 20, C_RED);
    label3(str("2 x M6 chain ends on the lugs, ", ATT_Y, " mm from the axis"), [LUG_X0 + 15, ATT_Y, 25], [-150, 120], 20, C_RED);
    label3(str("WEIGHT W = ", r1(W_KG), " kg at ", TLFIX_ARM, " mm"), [(LEV_X0 + LEV_X1) / 2, TLFIX_ARM, -170], [-190, -40], 24, "#222222");
    label3(str("LEVER's own moment M_lever = ", r1(LEVER_NM), " N*m"), [(LEV_X0 + LEV_X1) / 2, 250, 25], [-190, 60], 22, "#000000");
    label3(str("T = ", r1(W_KG), " kg x 9.81 x 0.5 m + ", r1(LEVER_NM), " = ", r1(W_KG * G * TLFIX_ARM / 1000 + LEVER_NM), " N*m = TL_SET_AT_TL"), [(LEV_X0 + LEV_X1) / 2, 380, 30], [-190, -90], 22, "#000000");
}

if (part == "world") { rig(); tlf_labels(); }
else if (part == "stub") translate([-X_TIP, 0, 0]) stub_solid();                      // part frame: tip at x = 0, axis on the x axis
else if (part == "lug") lug_part();
else if (part == "stub_2d") stub_2d();
else if (part == "lever") linear_extrude(TLFIX_LEVER_T) translate([-LEVER_Y0, TLFIX_LEVER_W / 2]) lever_2d();
else if (part == "lever_2d") translate([-LEVER_Y0, TLFIX_LEVER_W / 2]) lever_2d();
else if (part == "bom") {
    echo(str("BOM tlfix: TL350-2 setting ", TL_SET_AT_TL, " N*m (= T_SET ", T_SET, " x chain ratio ", CHAIN_RATIO, ", range ", TL_T_min, " .. ", TL_T_max, "): weight ", r1(W_KG), " kg at ", TLFIX_ARM, " mm; lever's own moment ", r1(LEVER_NM), " N*m"));
    echo(str("TLFIX_WEIGHT_KG = ", r1(W_KG), "  (exact ", W_KG, ")  = (TL_SET_AT_TL ", TL_SET_AT_TL, " - TLFIX_LEVER_NM) / ", TLFIX_ARM / 1000, " m / 9.81"));
    echo(str("TLFIX_LEVER_NM = ", r1(LEVER_NM), "  (exact ", LEVER_NM, ")  lever ", TLFIX_LEVER_L, " x 50 x 10 flat + 2 lugs + 2 M6 bolts + chain tails, ", r1(LEVER_KG), " kg, steel 7.85 g/cm3, about the TL axis (lever horizontal)"));
    echo(str("BOM tlfix: lever 50 x 10 x ", TLFIX_LEVER_L, " flat, PIVOT bore Ø", TLFIX_PIVOT_D, " on the Ø25 pin ", TEST_LEVER_PIVOT_END, " mm from its short end, 2 x Ø6.6 chain-end holes at ", ATT_Y, " mm, Ø10.5 weight hole at ", TLFIX_ARM, " mm; 2 lugs ", TLFIX_LUG[0], " x ", TLFIX_LUG[1], " x ", LUG_X1 - LUG_X0, " (Ø6.6 hole along x); chain #40 x ", CH_LINKS, " links (", round(360 - 2 * TG_ANG), " deg wrap = ", round(CH_ARC), " mm + 2 tails of ", round(CH_TAIL), " mm); stub (Ø25 pin ", FIX_PIN_L, " long, TL on it, pin ", TLFIX_PIN_L, " beyond the nut) from the Ø30 bar"));
}

// ---------------------------------------------------------------- DXF of the stub: side view, top view (flats), both end views, 1:1 mm
module stub_2d() {
    L1 = FIX_PIN_L;  L2 = STUB_END_L;  r1_ = STUB_DIA / 2;  r2 = STUB_END_D / 2;
    k0 = TLFIX_PIN_L + TL_KEY_END;  k1 = L1 - TL_KEY_END;
    difference() {
        union() { translate([0, -r1_]) square([L1, 2 * r1_]); translate([L1, -r2]) square([L2, 2 * r2]); }
        translate([k0, r1_ - KEY_D_]) square([k1 - k0, KEY_D_ + 1]);
    }
    translate([0, -50]) union() {
        difference() {
            union() { translate([0, -r1_]) square([L1, 2 * r1_]); translate([L1, -r2]) square([L2, 2 * r2]); }
            for (s = [-1, 1]) translate([L1 + 10, s > 0 ? STUB_FLAT_AF / 2 : -r2 - 1]) square([STUB_FLAT_L, r2 - STUB_FLAT_AF / 2 + 1]);
        }
    }
    translate([0, -100]) difference() {
        translate([0, -r1_]) square([L1, 2 * r1_]);
        hull() for (x = [k0 + KEY_W_ / 2, k1 - KEY_W_ / 2]) translate([x, 0]) circle(d = KEY_W_, $fn = 32);
    }
    translate([L1 + L2 + 45, 0]) difference() {
        circle(d = STUB_END_D, $fn = 96);
        for (s = [-1, 1]) translate([-20, s > 0 ? STUB_FLAT_AF / 2 : -STUB_FLAT_AF / 2 - 20]) square([40, 20]);
    }
    translate([L1 + L2 + 45, -50]) difference() {
        circle(d = STUB_DIA, $fn = 96);
        translate([-KEY_W_ / 2, r1_ - KEY_D_]) square([KEY_W_, KEY_D_ + 1]);
    }
}
