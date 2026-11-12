"""tl350.py -- the Tsubaki TL350-2 friction torque limiter to the MANUFACTURER'S layout, in its own frame (cad/tl350.scad).

Frame: axis on the x axis, x = 0 at the hub FLANGE-END face, the hub runs to +x for TL_L = 62 (the adjusting-nut end).
Stack (x from the flange-end face):
  0 .. 8 flange | 8 .. 16 friction pack (linings 8 .. 8.4 and 15.6 .. 16, sprocket plate between them) |
  16 .. 24 pressure plate | 24 .. 50 disc springs | 50 .. 62 adjusting nut
Every part is modelled seated with 0.01 mm on every face and Ø25.02 over the Ø25 shaft (like the other bought parts).
"""
from common import *

TL_FIT = 0.01
TL_LIN_L = TL_CM_OFFSET - SPROCKET_T / 2 - TL_FLANGE_T                 # friction lining each side of the sprocket plate (0.4)
TL_PRESS_X0 = TL_CM_OFFSET + SPROCKET_T / 2 + TL_LIN_L                 # 16
TL_SPRING_X0 = TL_PRESS_X0 + TL_PRESS_T
TL_NUT_X0 = TL_SPRING_X0 + TL_SPRING_L


def tlt(od, x0, len, id=None):
    id = TL_HUB_D if id is None else id
    return translate([x0 + TL_FIT, 0, 0], rotate([0, 90, 0], difference(
        cylinder(d=od - 2 * TL_FIT, h=len - 2 * TL_FIT),
        translate([0, 0, -1], cylinder(d=id + 2 * TL_FIT, h=len + 2)))))


def tl_flange_l():
    return tlt(TL_D, 0, TL_FLANGE_T)


def tl_pack_l():
    """Friction linings."""
    return union(tlt(TL_PACK_D, TL_FLANGE_T, TL_LIN_L), tlt(TL_PACK_D, TL_CM_OFFSET + SPROCKET_T / 2, TL_LIN_L))


def tl_plate_l():
    """The sprocket's tooth plate."""
    return tlt(tl_sprocket_pd + SPROCKET_OD_EXTRA, TL_CM_OFFSET - SPROCKET_T / 2, SPROCKET_T)


def tl_press_l():
    return tlt(TL_D, TL_PRESS_X0, TL_PRESS_T)


def tl_spring_l():
    return tlt(TL_D, TL_SPRING_X0, TL_SPRING_L)


def tl_nut_l():
    return tlt(TL_D, TL_NUT_X0, TL_L - TL_NUT_X0)


def tl_hub_l():
    return tlt(TL_HUB_D, 0, TL_L, JOURNAL_D)


def tl350_l():
    return union(tl_flange_l(), tl_pack_l(), tl_plate_l(), tl_press_l(), tl_spring_l(), tl_nut_l(), tl_hub_l())


def tl350_body_l():
    """Everything except the sprocket's tooth plate."""
    return union(tl_flange_l(), tl_pack_l(), tl_press_l(), tl_spring_l(), tl_nut_l(), tl_hub_l())
