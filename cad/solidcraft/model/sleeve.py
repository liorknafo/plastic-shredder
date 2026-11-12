"""sleeve.py -- clamp sleeves (OD 30 = SLEEVE_OD, also the oil-seal running surface) and the COLLARED sleeves (cad/sleeve.scad).

Part frame: axis along +Z from 0.  Collared sleeve: collar (OD COLLAR_OD x COLLAR_T) at z = 0, then the Ø30 body.
"""
from common import *


def tube(od, id, L):
    return difference(cylinder(d=od, h=L),
                      translate([0, 0, -1], cylinder(d=id, h=L + 2)))


def sleeve(L):
    return tube(SLEEVE_OD, SLEEVE_ID, L)


def collared(Lb):
    """Collar first (z 0 .. COLLAR_T), body after it: one turned part, bored through."""
    return difference(union(cylinder(d=COLLAR_OD, h=COLLAR_T),
                            translate([0, 0, COLLAR_T], cylinder(d=SLEEVE_OD, h=Lb))),
                      translate([0, 0, -1], cylinder(d=SLEEVE_ID, h=COLLAR_T + Lb + 2)))


PARTS = {"sleeve_drive": lambda: sleeve(sleeve_L_drive),
         "sleeve_free_A": lambda: sleeve(sleeve_L_free_A),
         "sleeve_free_B": lambda: sleeve(sleeve_L_free_B),
         "collar_sleeve_drive": lambda: collared(collar_body_L_drive),
         "collar_sleeve_free": lambda: collared(collar_body_L_free),
         "gear_spacer": lambda: tube(GEAR_SPACER_D, SLEEVE_ID, gear_spacer_L)}
