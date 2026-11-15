// placeholders.scad -- assembly-only stand-ins (bearings, seals, thrust / crinkle washers, sprocket, M10 end screws). Not exported,
// except the end cap.  Everything that sits on a shaft is in the shaft-local frame (axis on the x axis).
//
// FIT.  Bought parts that sit in a bore or on a sleeve (bearings, seals, thrust washers, crinkle washers, gears, sprocket) are modelled seated
// with FIT = 0.01 mm on every surface (OD smaller, ID larger, faces shorter), so the interference checks see true overlaps only and
// not the zero-thickness sheets that touching faces make.  The real (machined) parts - plate layers, sleeves, collared sleeves, shafts - are exact.
include <common.scad>
include <tl350.scad>
use <gear.scad>

FIT = 0.01;
GEAR_OD = GEAR_module * (GEAR_z + 2);       // 68.0

module tube_x(od, id, x0, L) axial(x0) difference() {
    cylinder(d = od, h = L, $fn = 96);
    translate([0, 0, -1]) cylinder(d = id, h = L + 2, $fn = 96);
}
// seated placeholder: shrunk by FIT on every surface
module seat_x(od, id, x0, L) tube_x(od - 2 * FIT, id + 2 * FIT, x0 + FIT, L - 2 * FIT);

// ---- gears: the BOUGHT m4 z15 gear (gear.scad: real involute teeth with backlash, bore Ø25, keyway) next to the collar, its hub outboard (x_gear_hub_out .. x_gear_out).
// Seated like the other bought parts: FIT (0.01) off every face and the bore.  Tooth phase: A has a tooth centred on +y (toward B) at angle 0; for an ODD z, B's gap at
// 180 deg already faces it (for an even z B would be turned half a pitch): the teeth mesh at angle = 0.  (In the shop: shaft B is turned until its gear meshes before its
// key goes in: the blades of A and B run in different slots, so their relative angle does not matter.)
function gear_phase(sh) = sh == "B" && GEAR_z % 2 == 0 ? 180 / GEAR_z : 0;
module gear_ph(sh = "A") {
    axial(x_gear_out + FIT) gear_solid(GEAR_cut_extra, gear_phase(sh), 2 * FIT, gear_face - 2 * FIT);
    axial(x_gear_hub_out + FIT) gear_hub_solid(2 * FIT, GEAR_HUB_L - 2 * FIT);
}
// the two Ø30 sleeves (made, Ø55 bar, bore Ø25.05) either side of the OUTBOARD bearing's inner ring: gear hub -> ring (gear_spacer_L), ring -> the TL350 (A: ob_sleeve_A_L,
// longer, so the TL350 passes outside B's end) / end cap (B: ob_sleeve_L)
module gear_spacer_ph() seat_x(GEAR_SPACER_D, GEAR_bore, x_ob_ring_in, gear_spacer_L);
module ob_sleeve_ph(sh) if (sh == "A") seat_x(GEAR_SPACER_D, GEAR_bore, x_spA_in, ob_sleeve_A_L); else seat_x(GEAR_SPACER_D, GEAR_bore, x_sprocket_in, ob_sleeve_L);
// the same gear, un-shrunk (mesh checks)
module gear_exact(sh = "A", extra = GEAR_cut_extra, ph = 0) axial(x_gear_out) gear_solid(extra, gear_phase(sh) + ph, 0, gear_face);

// ---- the TL350 on shaft A, FLIPPED (2026-11-15, no chain): flange-end face at x_sprocket_out (outward), nut end at x_spA_in; its 30T sprocket (the centre member) is driven by
// the pin flange's 4 pins through 4 holes drilled in its plate (PIN_HOLE_D on PIN_R; the pins at 45, 135, 225, 315 deg)
module tl_on_a() translate([x_sprocket_out, 0, 0]) children();
module tl_pin_holes() for (a = [45 : 360 / PIN_N : 359]) translate([x_sprocket_out + TL_CM_OFFSET - SPROCKET_T, PIN_R * cos(a), PIN_R * sin(a)]) rotate([0, 90, 0]) cylinder(d = PIN_HOLE_D, h = 2 * SPROCKET_T, $fn = 32);
module sprocket_hub_ph()  tl_on_a() tl_hub_l();
module sprocket_disc_ph() difference() { tl_on_a() tl_plate_l(); tl_pin_holes(); }
module sprocket_ph()      { tl_on_a() tl350_body_l(); sprocket_disc_ph(); }

// ---- NA4905 needle roller bearing (inner ring 25 x 30 x 17; Ø3 rollers 30..36; outer ring 36..42 = the INNER_HOLE_D shoulder).  end = "drive" | "free" | "ob" (outboard plate)
function brg_x0(end) = end == "drive" ? x_inner_ring_out_drive : end == "ob" ? x_ob_ring_out : chamber_L + LAYER_T;       // lowest-x face: -27 / -106.5 / L+10
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
// clamp points: A drive: the TL350 hub's outer face (x_sprocket_out); B drive: the outer sleeve's outer face (x_sprocket_in); free ends: the collar's outer face
module end_screw_free()      end_screw_at(x_collar_out_free, 1);
module end_screw_drive(sh)   end_screw_at(end_x_drive(sh), -1);
// the end cap alone (without screw) at a clamp point (for envelopes)
function end_x_drive(sh) = sh == "A" ? x_sprocket_out : x_sprocket_in;
