"""spacer.py -- round spacer tube (cad/spacer.scad).  Part frame: axis along +Z, one end on Z = 0."""
from common import *


def spacer(t=None):
    t = T_SPACER if t is None else t
    return difference(cylinder(d=SPACER_OD, h=t),
                      translate([0, 0, -1], cylinder(d=SPACER_BORE, h=t + 2)))


PARTS = {"spacer": lambda: spacer(T_SPACER),
         "end_spacer_B": lambda: spacer(end_spacer_B)}      # the 8.2 end spacer of shaft B
