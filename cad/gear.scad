// gear.scad -- the MADE spur gear (module 1.5, z = 40, 20 deg), with real involute teeth, backlash, bore Ø25 and the 8 mm keyway.
// Also: one rough LAYER (the CNC part) and the gear mandrel (lathe part).  All 2D profiles are in the gear's own (u, v) plane, tooth 0 centred on +u.
//
// BACKLASH.  The gear is cut with a form cutter `extra` (GEAR_cut_extra = 0.10 mm) deeper than standard on BOTH gears.  A rack-shaped cutter moved radially in by
// `extra` is a profile shift x = -extra / m, so each tooth gets thinner at the pitch circle by 2 * extra * tan(alpha) = 0.0728 mm (transverse); the base circle,
// the involute flanks and the tip circle (OD 63.0, turned on the lathe) stay as they are.  Two such gears in mesh have a circumferential backlash of
// 2 * 0.0728 = 0.1456 mm (normal backlash 0.1368 mm; see CALC s.6).  Root circle = OD - 2 * (standard 2.25 m + extra) = 56.05.  Below the base circle (r 28.19 > root r 28.025)
// the flank is a radial line down to the root circle.
// Facets: NF points per flank (inscribed in the convex tooth: the polygon is never bigger than the real tooth, so a clearance seen in the model is real).
include <common.scad>

NF = 10;                                            // points per flank, base circle .. tip circle
function inv_deg(a) = tan(a) - a * PI / 180;        // involute function (radians), angle a in degrees
function g_rp(m, z) = m * z / 2;
function g_rb(m, z, alpha) = g_rp(m, z) * cos(alpha);
function g_ra(m, z) = m * (z + 2) / 2;
function g_rr(m, z, extra) = m * (z - 2.5) / 2 - extra;
function g_s(m, alpha, extra) = PI * m / 2 - 2 * extra * tan(alpha);           // tooth thickness on the pitch circle (transverse)
// half angle (deg) of the tooth at radius r
function g_half(m, z, alpha, extra, r) =
    (g_s(m, alpha, extra) / (2 * g_rp(m, z)) + inv_deg(alpha) - inv_deg(acos(g_rb(m, z, alpha) / r))) * 180 / PI;
function pol(r, a) = [r * cos(a), r * sin(a)];

// outline of the whole gear (tooth 0 centred on +u, rotated by `phase` deg)
function gear_pts(m = GEAR_module, z = GEAR_z, alpha = GEAR_alpha, extra = GEAR_cut_extra, phase = 0) =
    let (rb = g_rb(m, z, alpha), ra = g_ra(m, z), rr = g_rr(m, z, extra), r0 = max(rb, rr), pitch = 360 / z,
         hb = g_half(m, z, alpha, extra, r0 + 1e-9),
         rs = [for (i = [0 : NF]) r0 + (ra - r0) * i / NF],
         ha = g_half(m, z, alpha, extra, ra))
    [for (k = [0 : z - 1]) let (c = phase + k * pitch) each concat(
        [pol(rr, c - hb)],
        [for (r = rs) pol(r, c - g_half(m, z, alpha, extra, r < r0 + 1e-6 ? r0 + 1e-9 : r))],
        [pol(ra, c)],
        [for (i = [NF : -1 : 0]) let (r = rs[i]) pol(r, c + g_half(m, z, alpha, extra, r < r0 + 1e-6 ? r0 + 1e-9 : r))],
        [pol(rr, c + hb), pol(rr, c + pitch / 2)])];

module gear_outline(extra = GEAR_cut_extra, phase = 0) polygon(gear_pts(GEAR_module, GEAR_z, GEAR_alpha, extra, phase));

// bore Ø25 (+ clearance `bd_extra`) with the 8 mm keyway, 3.3 above the bore surface, corners rounded with the CNC end mill (GEAR_KEY_TOOL_D / 2).
// Keyway on +v (the shaft keyways are on +z = +v).  The keyway is cut by the Ø3 end mill: its bottom corners have R = GEAR_KEY_TOOL_D / 2.
module bore_keyway_2d(bd_extra = 0) {
    rt = GEAR_KEY_TOOL_D / 2;
    circle(d = GEAR_bore + bd_extra, $fn = 96);
    // slot: from inside the bore to GEAR_bore/2 + GEAR_KEYWAY_H; only its far corners are rounded
    hull() {
        translate([-GEAR_KEY_W / 2, 0]) square([GEAR_KEY_W, 1]);
        for (sx = [-1, 1]) translate([sx * (GEAR_KEY_W / 2 - rt), GEAR_bore / 2 + GEAR_KEYWAY_H - rt]) circle(r = rt, $fn = 32);
    }
}

// the finished gear (one flat 2D shape): teeth + bore + keyway.  `phase` turns the teeth (deg); `bd_extra` makes the bore a bit larger (the assembly uses the placeholders' FIT)
module gear_2d(extra = GEAR_cut_extra, phase = 0, bd_extra = 0)
    difference() { gear_outline(extra, phase); bore_keyway_2d(bd_extra); }

// the finished gear, GEAR_LAYERS layers = gear_face thick, axis = +w (local frame, w = 0 at the face toward the shaft end of the stack)
module gear_solid(extra = GEAR_cut_extra, phase = 0, bd_extra = 0, L = gear_face) linear_extrude(L) gear_2d(extra, phase, bd_extra);

// ONE rough layer as the CNC cuts it: Ø64 outline, bore Ø25 H7 (finished on the CNC), keyway 8 JS9; GEAR_LAYER_T thick
module gear_layer_2d() difference() { circle(d = GEAR_ROUGH_D, $fn = 180); bore_keyway_2d(0); }
module gear_layer() linear_extrude(GEAR_LAYER_T) gear_layer_2d();

// gear mandrel (lathe, from the Ø30 bar): grip Ø30 x grip_L (shoulder at its end), Ø25 g6 seat (4 layers + 2.8) with the 8 mm key keyway, M16 x 1.5 stud, centre drilled
// axis +w; w = 0 at the grip end.  Washer Ø30 x 6 and M16 nut are standard parts (not drawn).
G_GRIP_L = 45;  G_SEAT_L = gear_face + 2.8;  G_THR_L = 24;
module gear_mandrel() {
    $fn = 96;
    difference() {
        union() {
            cylinder(d = 30, h = G_GRIP_L);
            translate([0, 0, G_GRIP_L]) cylinder(d = 25, h = G_SEAT_L);
            translate([0, 0, G_GRIP_L + G_SEAT_L]) cylinder(d = 16, h = G_THR_L);
        }
        // keyway 8 x 4 (on +v), closed at both ends, 40 long, starts 1 mm past the shoulder
        translate([-4, 25 / 2 - 4, G_GRIP_L + 1]) cube([8, 5, 40]);
        translate([0, 0, G_GRIP_L + G_SEAT_L + G_THR_L - 4]) cylinder(d1 = 0, d2 = 5, h = 4.01);   // centre hole for the live centre
    }
}

// standalone render:  -D 'part="layer"|"gear"|"gear_B"|"mandrel"|"layer_2d"|"profile_2d"'
part = "none";
if (part == "layer") gear_layer();
if (part == "gear") gear_solid();                                     // gear A: a tooth centred on the keyway
if (part == "gear_B") gear_solid(GEAR_cut_extra, 180 / GEAR_z);      // gear B: a gap centred on the keyway (same blank, first space cut half a pitch later)
if (part == "mandrel") gear_mandrel();
if (part == "layer_2d") gear_layer_2d();
if (part == "profile_2d") gear_2d();
