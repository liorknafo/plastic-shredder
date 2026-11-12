"""shaft.py -- Ø25 shaft with a hex section (vertex at +y), gear / sprocket keyways (top, +z) and M10 end holes (cad/shaft.scad)."""
from common import *

KEY_W = 8
KEY_D = 4
END_HOLE_D = 8.5      # M10 tap drill
END_HOLE_L = 25


def keyway(xa, xb):
    """8 wide x 4 deep from the Ø25 surface on the +z side; the cutter extends past the surface."""
    return axial(xa, translate([-KEY_W / 2, JOURNAL_D / 2 - KEY_D, 0], cube([KEY_W, KEY_D + 3, xb - xa])))


def shaft_local(which):
    """Shaft with its axis on the x axis (y = z = 0), in world x positions.

    Keyways: the gear seat (the 4 layers, x_gear_out .. x_gear_in) on both shafts, the sprocket seat on A only.
    """
    xs = shaft_x_start(which)
    return difference(
        union(axial(xs, cylinder(d=JOURNAL_D, h=shaft_end_free - xs)),
              # hex prism across flats HEX_AF, with a vertex on +u = +y
              axial(hex_x0, linear_extrude(hex_x1 - hex_x0, circle(d=HEX_AF / cos(30), fn=6)))),
        keyway(x_gear_out, x_gear_in),
        keyway(x_sprocket_out, x_sprocket_in) if which == "A" else None,
        axial(xs - 1, cylinder(d=END_HOLE_D, h=END_HOLE_L + 1)),
        axial(shaft_end_free - END_HOLE_L, cylinder(d=END_HOLE_D, h=END_HOLE_L + 1)))


def shaft(which):
    """In its world position (axis at y = -C/2 for A, +C/2 for B)."""
    return translate([0, shaft_y(which), 0], shaft_local(which))


def shaft_part(which):
    """Part frame for export: axis along +X, starting at x = 0."""
    return translate([-shaft_x_start(which), 0, 0], shaft_local(which))


PARTS = {"shaft_A": lambda: shaft_part("A"), "shaft_B": lambda: shaft_part("B")}
