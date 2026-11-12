"""common.py -- layout helpers shared by every part (cad/common.scad).

World frame: x along the shafts (x = 0 inner face of the drive-end plate), y across (A at -C/2, B at +C/2), z up.
"""
from scq import *
from p import *

N_BLADES = int(N_SLOTS / 2)        # blades per shaft (= spacers per shaft)


def axial(x0, *ch):
    """Local frame (u, v, w) -> world: x = x0 + w, y = u, z = v.  For every "axial part": w runs along the shaft."""
    return multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], *ch)


# ---- layout of the cutting stacks
def shaft_y(sh):
    return -C / 2 if sh == "A" else C / 2


def shaft_sign(sh):
    return -1 if sh == "A" else 1                                      # rotation direction about +x


def stack_x0(sh):
    return END_CLEAR + (0 if sh == "A" else end_spacer_B)               # x of the first blade


def blade_pitch():
    return T_BLADE + T_SPACER


def blade_x0(sh, k):
    return stack_x0(sh) + k * blade_pitch()                             # blade k: x in [x0, x0 + T_BLADE]


def blade_xc(sh, k):
    return blade_x0(sh, k) + T_BLADE / 2


def blade_variant(k):
    return int(k % BLADE_VARIANTS)


def blade_rot(k):
    """Rotation of blade k in its own 2D frame: j*60 - v*STAGGER, j = -floor(k/4) (deg)."""
    return -floor(k / BLADE_VARIANTS) * 60 - blade_variant(k) * STAGGER_DEG


def sleeve_free_x0(sh):
    return END_CLEAR + (stack_A if sh == "A" else stack_B)


def sleeve_free_L(sh):
    return sleeve_L_free_A if sh == "A" else sleeve_L_free_B


def shaft_x_start(sh):
    return shaft_end_A_drive if sh == "A" else shaft_end_B_drive


def comb_y_lo(sh):
    return comb_edge_y if sh == "B" else -(comb_edge_y + COMB_W)        # y span of a comb bar: [lo, hi]


def comb_y_hi(sh):
    return comb_edge_y + COMB_W if sh == "B" else -comb_edge_y


# ---- the assembly's bodies: Body(name, builder, colour, opacity).  `builder()` returns the CSG tree of that group
# in the machine frame (angle 0, lid closed, drawer closed).  Every `part(...)` in it becomes a body of its own.
RED, ORANGE, YELLOW, GREEN = "#c82829", "#f5871f", "#eab700", "#718c00"       # the Tomorrow palette of cad/assembly.scad
AQUA, BLUE, PURPLE, GRAY, DARK = "#3e999f", "#4271ae", "#8959a8", "#8e908c", "#4d4d4c"
PRINT, METAL = "#e69138", "#b0b4b8"


class Body:
    def __init__(self, name, node, color, opacity=1.0):
        self.name, self.node, self.color, self.opacity = name, node, color, opacity
