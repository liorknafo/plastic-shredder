// gear.scad -- the BOUGHT spur gear (module 4, z = 15, 20 deg, hardened teeth) as modelled: real involute teeth, the bore re-bored Ø25 with the broached 8 mm keyway, and its hub.
// All 2D profiles are in the gear's own (u, v) plane, tooth 0 centred on +u.
//
// BACKLASH.  A bought gear's teeth are made a little thin (tooth-thickness tolerance); the model represents that as a cut `extra` (GEAR_cut_extra = 0.10 mm) deeper
// than standard on BOTH gears: a rack-shaped cutter moved radially in by `extra` is a profile shift x = -extra / m, so each tooth is thinner at the pitch circle by
// 2 * extra * tan(alpha) = 0.0728 mm; two such gears in mesh have 0.1456 mm of circumferential backlash (calc s.6, check C31off).  Measure your gears' backlash on the 60.00 mm
// centre distance before fitting.  Below the base circle the flank is a radial line down to the root circle.
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

// bore Ø25 (+ clearance `bd_extra`) with the broached 8 mm keyway, 3.3 above the bore surface (corner R = GEAR_KEY_TOOL_D / 2, nearly sharp).  Keyway on +v (the shaft keyways are on +z = +v).
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

// the teeth, gear_face thick, axis = +w (local frame, w = 0 at the face toward the hub)
module gear_solid(extra = GEAR_cut_extra, phase = 0, bd_extra = 0, L = gear_face) linear_extrude(L) gear_2d(extra, phase, bd_extra);

// the hub (bought; APPROXIMATE size until the listing is chosen): GEAR_HUB_D x GEAR_HUB_L, the same bore + keyway
module gear_hub_solid(bd_extra = 0, L = GEAR_HUB_L) linear_extrude(L) difference() { circle(d = GEAR_HUB_D, $fn = 96); bore_keyway_2d(bd_extra); }
// the whole bought gear in its own frame: hub w = 0 .. GEAR_HUB_L, teeth w = GEAR_HUB_L .. GEAR_HUB_L + gear_face (on the machine the hub is OUTBOARD)
module gear_part(phase = 0) { gear_hub_solid(); translate([0, 0, GEAR_HUB_L]) gear_solid(GEAR_cut_extra, phase); }

// standalone render:  -D 'part="gear"|"gear_B"|"profile_2d"'
part = "none";
if (part == "gear") gear_part();                                      // gear A: a tooth centred on the keyway
if (part == "gear_B") gear_part(GEAR_z % 2 == 0 ? 180 / GEAR_z : 0);  // gear B: the same part for an odd tooth count
if (part == "profile_2d") gear_2d();
