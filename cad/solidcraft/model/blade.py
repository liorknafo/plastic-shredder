"""blade.py -- cutter blade: 3 hooked teeth, hex bore with corner reliefs, phase variant v = 0..3 (cad/blade.scad).

Part frame: blade in XY, thickness along +Z from 0.
"""
from common import *


def blade_2d(v=0):
    return difference(polygon(blade_outline_pts),
                      polygon(blade_hex(v)),
                      [translate(p, circle(d=HEX_RELIEF_D)) for p in blade_hex(v)])


def blade(v=0):
    return linear_extrude(T_BLADE, blade_2d(v))


# the made parts of this file, each in its part frame (parts.py)
PARTS = {f"blade_v{v}": (lambda v=v: blade(v)) for v in range(int(BLADE_VARIANTS))}

# the outlines for the CNC (cad/dxf/<name>.dxf)
PARTS_2D = {f"blade_v{v}": (lambda v=v: blade_2d(v)) for v in range(int(BLADE_VARIANTS))}
