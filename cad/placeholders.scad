// placeholders.scad -- assembly-only stand-ins (bearings, seals, thrust / crinkle washers, sprocket, M10 end screws). Not exported,
// except the end cap.  Everything that sits on a shaft is in the shaft-local frame (axis on the x axis).
//
// FIT.  Bought parts that sit in a bore or on a sleeve (bearings, seals, thrust washers, crinkle washers, gears, sprocket) are modelled seated
// with FIT = 0.01 mm on every surface (OD smaller, ID larger, faces shorter), so the interference checks see true overlaps only and
// not the zero-thickness sheets that touching faces make.  The real (machined) parts - plate layers, sleeves, collared sleeves, shafts - are exact.
include <common.scad>
use <gear.scad>

FIT = 0.01;
GEAR_OD = GEAR_module * (GEAR_z + 2);       // 63.0
SPA_OD = sprocket_A_pd + SPROCKET_OD_EXTRA; // 67.3 (#40 15T tooth tips)

module tube_x(od, id, x0, L) axial(x0) difference() {
    cylinder(d = od, h = L, $fn = 96);
    translate([0, 0, -1]) cylinder(d = id, h = L + 2, $fn = 96);
}
// seated placeholder: shrunk by FIT on every surface
module seat_x(od, id, x0, L) tube_x(od - 2 * FIT, id + 2 * FIT, x0 + FIT, L - 2 * FIT);

// ---- gears: the MADE gear (gear.scad: real involute teeth with backlash, bore Ø25, keyway), face = 4 layers = gear_face, no hub (a plain sleeve follows it), next to the collar.
// Seated like the bought parts: FIT (0.01) off every face and the bore.  Tooth phase: A has a tooth centred on +y (toward B) at angle 0; B is turned half a pitch
// (180 / z) so that its gap faces A (z is even): the teeth mesh at angle = 0.  (In the shop both gears are cut identically; shaft B is turned half a pitch
// relative to A when its key goes in -- the blades of A and B run in different slots, so their relative angle does not matter.)
function gear_phase(sh) = sh == "B" ? 180 / GEAR_z : 0;
module gear_ph(sh = "A") axial(x_gear_out + FIT) gear_solid(GEAR_cut_extra, gear_phase(sh), 2 * FIT, gear_face - 2 * FIT);
// gear spacer sleeve (made: Ø55 bar, OD GEAR_SPACER_D, bore Ø25.05, gear_spacer_L long) between the gear's outer face and the sprocket hub (A) / end cap (B): it keeps the old bought-gear
// length, so the sprocket, chain plane, gearbox and shaft lengths do not move (x_gear_hub_out = outer face of the sleeve).  Seated with FIT like the other stand-ins.
module gear_spacer_ph() seat_x(GEAR_SPACER_D, GEAR_bore, x_gear_hub_out, gear_spacer_L);
// the same gear, un-shrunk (mesh checks)
module gear_exact(sh = "A", extra = GEAR_cut_extra, ph = 0) axial(x_gear_out) gear_solid(extra, gear_phase(sh) + ph, 0, gear_face);

// ---- sprocket on shaft A: hub Ø39 x 22.4 (x_sprocket_out .. x_sprocket_in), tooth plate (OD 67.3 x 7.2) at the OUTER end of the hub
module sprocket_hub_ph()  seat_x(SPROCKET_A_hub_D, JOURNAL_D, x_sprocket_out, SPROCKET_A_hub_L);
module sprocket_disc_ph() seat_x(SPA_OD, JOURNAL_D, x_sprocket_out, SPROCKET_T);
module sprocket_ph()      { sprocket_hub_ph(); sprocket_disc_ph(); }

// ---- NA4905 needle roller bearing (inner ring 25 x 30 x 17; Ø3 rollers 30..36; outer ring 36..42 = the INNER_HOLE_D shoulder).  end = "drive" | "free"
function brg_x0(end) = end == "drive" ? x_inner_ring_out_drive : chamber_L + LAYER_T;       // outer-face-first: -27 / L+10
module bearing_inner_ph(end)   seat_x(BEARING_F, BEARING_d, brg_x0(end), BEARING_B);
module bearing_rollers_ph(end) seat_x(INNER_HOLE_D, BEARING_F, brg_x0(end), BEARING_B);
module bearing_outer_ph(end)   seat_x(BEARING_D, INNER_HOLE_D, brg_x0(end), BEARING_B);
module bearing_ph(end)         { bearing_inner_ph(end); bearing_rollers_ph(end); bearing_outer_ph(end); }
module bearing_drive_ph()      bearing_ph("drive");
module bearing_free_ph()       bearing_ph("free");

// ---- oil seal TC 30x42x7 in the inner-layer counterbore (flush with the chamber face)
function seal_x0(end) = end == "drive" ? -SEAL_B : chamber_L;
module seal_ph(end) seat_x(SEAL_D, SEAL_d, seal_x0(end), SEAL_B);

// ---- thrust bearing AXK3047 + 2 AS (30/47, 4) round the collared sleeve; drive: on the cap face (x -34 .. -30); free: after the crinkle stack
function thrust_x0(end) = end == "drive" ? x_collar_in_drive : x_cap_out_free + CRINKLE_stack_h;
module thrust_ph(end) seat_x(THRUST_D, THRUST_d, thrust_x0(end), THRUST_T);
// ---- crinkle (wave) washer stack 30/39, 2 mm, free end only, on the cap face
module crinkle_ph() seat_x(CRINKLE_D, CRINKLE_d, x_cap_out_free, CRINKLE_stack_h);

// ---- End CAP Ø30 x END_WASHER_T with a Ø10.5 hole, mild steel (the real, exported part)
module end_cap() {
    $fn = 64;
    difference() { cylinder(d = 30, h = END_WASHER_T); translate([0, 0, -1]) cylinder(d = 10.5, h = END_WASHER_T + 2); }
}
// M10 x END_SCREW_LEN socket screw (head Ø16 x 10) + end cap. Local w = 0 at the clamped face, +w outward; shank goes inward.
module end_screw_geom() {
    $fn = 48;
    end_cap();
    translate([0, 0, END_WASHER_T]) cylinder(d = 16, h = 10);                        // socket head
    translate([0, 0, END_WASHER_T - END_SCREW_LEN]) cylinder(d = 8.4, h = END_SCREW_LEN);   // shank drawn at the thread core (M10: 8.4) = it does not 'overlap' the Ø8.5 tapped hole
}
module end_screw_at(x_face, dir) {         // sits FIT (0.01) off the face it clamps
    if (dir > 0) axial(x_face + FIT) end_screw_geom();
    else axial(x_face - FIT) rotate([180, 0, 0]) end_screw_geom();
}
// clamp points: A drive: sprocket hub outer face; B drive: gear outer face (x_gear_hub_out = x_gear_out: no hub); free ends: the collar's outer face
module end_screw_free()      end_screw_at(x_collar_out_free, 1);
module end_screw_drive(sh)   end_screw_at(sh == "A" ? x_sprocket_out : x_gear_hub_out, -1);
// the end cap alone (without screw) at a clamp point (for envelopes)
function end_x_drive(sh) = sh == "A" ? x_sprocket_out : x_gear_hub_out;
