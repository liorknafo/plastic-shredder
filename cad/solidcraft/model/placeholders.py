"""placeholders.py -- stand-ins for the bought parts on the shafts: bearings, seals, thrust / crinkle washers,
sprocket, M10 end screws (cad/placeholders.scad).  Only the end cap is a made part.
Everything that sits on a shaft is in the shaft-local frame (axis on the x axis).

FIT.  Bought parts that sit in a bore or on a sleeve are modelled seated with FIT = 0.01 mm on every surface (OD
smaller, ID larger, faces shorter), so interference checks see true overlaps only and not touching faces.
The made parts - plate layers, sleeves, collared sleeves, shafts - are exact.
"""
from common import *
from gear import gear_solid

FIT = 0.01
GEAR_OD = GEAR_module * (GEAR_z + 2)        # 63.0
SPA_OD = sprocket_A_pd + SPROCKET_OD_EXTRA  # 67.3 (#40 15T tooth tips)


def tube_x(od, id, x0, L):
    return axial(x0, difference(cylinder(d=od, h=L),
                                translate([0, 0, -1], cylinder(d=id, h=L + 2))))


def seat_x(od, id, x0, L):
    """Seated placeholder: shrunk by FIT on every surface."""
    return tube_x(od - 2 * FIT, id + 2 * FIT, x0 + FIT, L - 2 * FIT)


# ---- gears: the MADE gear (gear.py), face = 4 layers = gear_face, no hub (a plain sleeve follows it), next to the collar.
# Tooth phase: A has a tooth centred on +y (toward B) at angle 0; B is turned half a pitch (180 / z) so that its gap
# faces A (z is even): the teeth mesh at angle = 0.
def gear_phase(sh):
    return 180 / GEAR_z if sh == "B" else 0


def gear_ph(sh="A"):
    return axial(x_gear_out + FIT, gear_solid(GEAR_cut_extra, gear_phase(sh), 2 * FIT, gear_face - 2 * FIT))


def gear_spacer_ph():
    """Gear spacer sleeve (made: Ø55 bar) between the gear's outer face and the sprocket hub (A) / end cap (B)."""
    return seat_x(GEAR_SPACER_D, GEAR_bore, x_gear_hub_out, gear_spacer_L)


def gear_exact(sh="A", extra=None, ph=0):
    """The same gear, un-shrunk (mesh checks)."""
    return axial(x_gear_out, gear_solid(GEAR_cut_extra if extra is None else extra, gear_phase(sh) + ph, 0, gear_face))


# ---- sprocket on shaft A: hub Ø39 x 22.4, tooth plate (OD 67.3 x 7.2) at the OUTER end of the hub
def sprocket_hub_ph():
    return seat_x(SPROCKET_A_hub_D, JOURNAL_D, x_sprocket_out, SPROCKET_A_hub_L)


def sprocket_disc_ph():
    return seat_x(SPA_OD, JOURNAL_D, x_sprocket_out, SPROCKET_T)


def sprocket_ph():
    return union(sprocket_hub_ph(), sprocket_disc_ph())


# ---- NA4905 needle roller bearing (inner ring 25 x 30 x 17; Ø3 rollers 30..36; outer ring 36..42).  end = "drive" | "free"
def brg_x0(end):
    return x_inner_ring_out_drive if end == "drive" else chamber_L + LAYER_T       # outer-face-first: -27 / L+10


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
    return x_sprocket_out if sh == "A" else x_gear_hub_out


def end_screw_free():
    return end_screw_at(x_collar_out_free, 1)


def end_screw_drive(sh):
    return end_screw_at(end_x_drive(sh), -1)


PARTS = {"end_cap": end_cap}
