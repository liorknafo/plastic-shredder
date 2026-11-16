"""placeholders.py -- stand-ins for the bought parts on the shafts: bearings, seals, thrust / crinkle washers,
the gears, the TL350 on shaft A, M10 end screws (cad/placeholders.scad).  Only the end cap is a made part.
Everything that sits on a shaft is in the shaft-local frame (axis on the x axis).

FIT.  Bought parts that sit in a bore or on a sleeve are modelled seated with FIT = 0.01 mm on every surface (OD
smaller, ID larger, faces shorter), so interference checks see true overlaps only and not touching faces.
The made parts - plate layers, sleeves, collared sleeves, shafts - are exact.
"""
from common import *
from gear import gear_solid, gear_hub_solid
from tl350 import tl_hub_l, tl_plate_l, tl350_body_l

FIT = 0.01
GEAR_OD = GEAR_module * (GEAR_z + 2)        # 68.0


def tube_x(od, id, x0, L):
    return axial(x0, difference(cylinder(d=od, h=L),
                                translate([0, 0, -1], cylinder(d=id, h=L + 2))))


def seat_x(od, id, x0, L):
    """Seated placeholder: shrunk by FIT on every surface."""
    return tube_x(od - 2 * FIT, id + 2 * FIT, x0 + FIT, L - 2 * FIT)


# ---- gears: the BOUGHT m4 z15 gear (gear.py) next to the collar, its hub outboard (x_gear_hub_out .. x_gear_out).
# Seated like the other bought parts: FIT off every face and the bore.  Tooth phase: A has a tooth centred on +y
# (toward B) at angle 0; for an ODD z, B's gap at 180 deg already faces it (for an even z B would be turned half a
# pitch): the teeth mesh at angle = 0.
def gear_phase(sh):
    return 180 / GEAR_z if sh == "B" and int(GEAR_z) % 2 == 0 else 0


def gear_ph(sh="A"):
    return union(axial(x_gear_out + FIT, gear_solid(GEAR_cut_extra, gear_phase(sh), 2 * FIT, gear_face - 2 * FIT)),
                 axial(x_gear_hub_out + FIT, gear_hub_solid(2 * FIT, GEAR_HUB_L - 2 * FIT)))


def gear_spacer_ph():
    """The Ø30 sleeve (made, Ø55 bar, bore Ø25.05) between the gear hub and the OUTBOARD bearing's inner ring."""
    return seat_x(GEAR_SPACER_D, GEAR_bore, x_ob_ring_in, gear_spacer_L)


def ob_sleeve_ph(sh):
    """The sleeve from the outboard bearing's inner ring to the TL350 (A: ob_sleeve_A_L, longer, so the TL350 passes
    outside B's end) / the end cap (B: ob_sleeve_L)."""
    if sh == "A":
        return seat_x(GEAR_SPACER_D, GEAR_bore, x_spA_in, ob_sleeve_A_L)
    return seat_x(GEAR_SPACER_D, GEAR_bore, x_sprocket_in, ob_sleeve_L)


def gear_exact(sh="A", extra=None, ph=0):
    """The same gear, un-shrunk (mesh checks)."""
    return axial(x_gear_out, gear_solid(GEAR_cut_extra if extra is None else extra, gear_phase(sh) + ph, 0, gear_face))


# ---- the TL350 on shaft A, FLIPPED (no chain): flange-end face at x_sprocket_out (outward), nut end at x_spA_in; its
# 30T sprocket (the centre member) is driven by the pin flange's 4 pins through 4 holes drilled in its plate
# (PIN_HOLE_D on PIN_R; the pins at 45, 135, 225, 315 deg)
def tl_on_a(*ch):
    return translate([x_sprocket_out, 0, 0], *ch)


def tl_pin_holes():
    return union(translate([x_sprocket_out + TL_CM_OFFSET - SPROCKET_T, PIN_R * cos(a), PIN_R * sin(a)],
                           rotate([0, 90, 0], cylinder(d=PIN_HOLE_D, h=2 * SPROCKET_T)))
                 for a in range(45, 360, int(360 / PIN_N)))


def sprocket_hub_ph():
    return tl_on_a(tl_hub_l())


def sprocket_disc_ph():
    return difference(tl_on_a(tl_plate_l()), tl_pin_holes())


def sprocket_ph():
    return union(tl_on_a(tl350_body_l()), sprocket_disc_ph())


# ---- NA4905 needle roller bearing (inner ring 25 x 30 x 17; Ø3 rollers 30..36; outer ring 36..42).
# end = "drive" | "free" | "ob" (outboard plate)
def brg_x0(end):
    """Lowest-x face: -27 / -106.5 / L+10."""
    return x_inner_ring_out_drive if end == "drive" else x_ob_ring_out if end == "ob" else chamber_L + LAYER_T


def bearing_inner_ph(end):
    return seat_x(BEARING_F, BEARING_d, brg_x0(end), BEARING_B)


def bearing_rollers_ph(end):
    return seat_x(INNER_HOLE_D, BEARING_F, brg_x0(end), BEARING_B)


def bearing_outer_ph(end):
    return seat_x(BEARING_D, INNER_HOLE_D, brg_x0(end), BEARING_B)


def bearing_ph(end):
    return union(bearing_inner_ph(end), bearing_rollers_ph(end), bearing_outer_ph(end))


# ---- oil seal TC 30x42x7 in the inner-layer counterbore (flush with the chamber face)
def seal_x0(end):
    return -SEAL_B if end == "drive" else chamber_L


def seal_ph(end):
    return seat_x(SEAL_D, SEAL_d, seal_x0(end), SEAL_B)


# ---- thrust bearing AXK3047 + 2 AS (30/47, 4) round the collared sleeve
def thrust_x0(end):
    return x_collar_in_drive if end == "drive" else x_cap_out_free + CRINKLE_stack_h


def thrust_ph(end):
    return seat_x(THRUST_D, THRUST_d, thrust_x0(end), THRUST_T)


def crinkle_ph():
    """Crinkle (wave) washer stack 30/39, 2 mm, free end only, on the cap face."""
    return seat_x(CRINKLE_D, CRINKLE_d, x_cap_out_free, CRINKLE_stack_h)


def end_cap():
    """End CAP Ø30 x END_WASHER_T with a Ø10.5 hole, mild steel (the real, exported part)."""
    return difference(cylinder(d=30, h=END_WASHER_T),
                      translate([0, 0, -1], cylinder(d=10.5, h=END_WASHER_T + 2)))


def end_screw_geom():
    """M10 x END_SCREW_LEN socket screw (head Ø16 x 10) + end cap.  Local w = 0 at the clamped face, +w outward."""
    return union(end_cap(),
                 translate([0, 0, END_WASHER_T], cylinder(d=16, h=10)),                                   # socket head
                 translate([0, 0, END_WASHER_T - END_SCREW_LEN], cylinder(d=8.4, h=END_SCREW_LEN)))       # shank at the thread core


def end_screw_at(x_face, dir):
    """Sits FIT (0.01) off the face it clamps."""
    if dir > 0:
        return axial(x_face + FIT, end_screw_geom())
    return axial(x_face - FIT, rotate([180, 0, 0], end_screw_geom()))


def end_x_drive(sh):
    """Clamp points: A drive: the TL350 hub's outer face (x_sprocket_out); B drive: the outer sleeve's outer face (x_sprocket_in)."""
    return x_sprocket_out if sh == "A" else x_sprocket_in


def end_screw_free():
    return end_screw_at(x_collar_out_free, 1)


def end_screw_drive(sh):
    return end_screw_at(end_x_drive(sh), -1)


PARTS = {"end_cap": end_cap}
