"""stack.py -- places the made parts: blade / spacer stacks, sleeves, rotating sets (cad/stack.scad)."""
from common import *
from blade import blade
from spacer import spacer
from shaft import shaft_local
from sleeve import sleeve, collared


# ---- shaft-local frame: axis on the x axis, y = z = 0.  (Wrap in rot_frame() to put it in the machine.)
def blade_placed(sh, k):
    """Blade k of shaft sh, turned in its own 2D frame by blade_rot(k) BEFORE mapping to world:
    B: (u, v, w) -> (y, z, x)     A (turned over): (u, v, w) -> (y, -z, -x)  [the blade keeps its x slab]"""
    x0 = blade_x0(sh, k)
    b = part(f"Blade {sh}{k + 1} (variant {blade_variant(k)})", rotate([0, 0, blade_rot(k)], blade(blade_variant(k))))
    if sh == "B":
        return multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], b)
    return multmatrix([[0, 0, -1, x0 + T_BLADE], [1, 0, 0, 0], [0, -1, 0, 0], [0, 0, 0, 1]], b)


def blades_of(sh):
    return union(blade_placed(sh, k) for k in range(N_BLADES))


def spacers_of(sh):
    return union(axial(END_CLEAR, part("End spacer B", spacer(end_spacer_B))) if sh == "B" else None,
                 [axial(blade_x0(sh, k) + T_BLADE, part(f"Spacer {sh}{k + 1}", spacer(T_SPACER)))
                  for k in range(N_BLADES) if sh == "A" or k < N_BLADES - 1])


def clamp_sleeves_of(sh):
    """The two clamp sleeves at the stack ends (drive end, free end)."""
    return union(axial(-LAYER_T, part(f"Clamp sleeve {sh} (drive end)", sleeve(sleeve_L_drive))),
                 axial(sleeve_free_x0(sh), part(f"Clamp sleeve {sh} (free end)", sleeve(sleeve_free_L(sh)))))


def collar_free_local():
    return collared(collar_body_L_free)                       # local +z -> world -x


def collared_sleeves_of(sh):
    """The collared sleeves (part of the clamp chain, next to the bearing inner rings): collar outermost.
    Drive: body x -34 .. -27, collar -38 .. -34.  Free: mirrored, the collar is at the higher x."""
    return union(axial(x_collar_out_drive, part(f"Collared sleeve {sh} (drive end)", collared(collar_body_L_drive))),
                 translate([x_collar_out_free, 0, 0], rotate([0, -90, 0], part(f"Collared sleeve {sh} (free end)", collar_free_local()))))


def all_sleeves_of(sh):
    return union(clamp_sleeves_of(sh), collared_sleeves_of(sh))


# ---- machine frame
def rot_frame(sh, angle, *ch):
    return translate([0, shaft_y(sh), 0], rotate([shaft_sign(sh) * angle, 0, 0], *ch))


def rotating_set(sh, angle=0):
    """Everything that turns with one shaft and is a made part of the cutting set (no gears, no placeholders)."""
    return rot_frame(sh, angle, shaft_local(sh), blades_of(sh), spacers_of(sh), clamp_sleeves_of(sh), collared_sleeves_of(sh))
