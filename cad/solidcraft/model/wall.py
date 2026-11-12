"""wall.py -- front / back chamber wall, 50 x 10 flat on edge (cad/wall.scad).

The two walls are mirror images (all holes are on y = +-71, the mid-plane).
"""
from common import *

WALL_T = 10
WALL_END_HOLE_D = 4.2                    # M5 tapped
WALL_HOLE_L = 12
WALL_Z0 = 5                              # sits on top of the comb bar (z = 5)


def wall_part():
    """Part frame: x = length 0..chamber_L, y = height 0..WALL_H (world z - 5), z = thickness 0..10 (world |y| - wall_inner_y)."""
    def end_hole(zw, e):
        xs = -1 if e == 0 else chamber_L - WALL_HOLE_L
        return translate([xs, zw - WALL_Z0, WALL_T / 2], rotate([0, 90, 0], cylinder(d=WALL_END_HOLE_D, h=WALL_HOLE_L + 1)))

    return difference(
        cube([chamber_L, WALL_H, WALL_T]),
        # end-face holes (both ends) at world z = 14 and 27, mid-thickness
        [end_hole(zw, e) for zw in (14, 27) for e in (0, 1)],
        # bottom-edge holes going up at x = 20, L/2, L-20
        [translate([x, -1, WALL_T / 2], rotate([-90, 0, 0], cylinder(d=WALL_END_HOLE_D, h=WALL_HOLE_L + 1)))
         for x in (20, chamber_L / 2, chamber_L - 20)],
        # hopper-collar holes: top edge, down 12 deep at x = 30 and chamber_L - 30 (|y| = 71 is the mid-plane)
        [translate([x, WALL_H - WALL_HOLE_L, WALL_T / 2], rotate([-90, 0, 0], cylinder(d=WALL_END_HOLE_D, h=WALL_HOLE_L + 1)))
         for x in (WALL_TOP_HOLE_X, chamber_L - WALL_TOP_HOLE_X)])


assert abs(WALL_TOP_HOLE_Y - (wall_inner_y + WALL_T / 2)) < 1e-6


def wall(sgn=1):
    """World placement.  sgn = +1 (B side, +y) or -1 (A side, -y).  The part is symmetric about its mid-plane, so the
    axis swap (part y -> world z, part z -> world |y|, a reflection) gives the same solid as a rotation would."""
    w = multmatrix([[1, 0, 0, 0], [0, 0, 1, wall_inner_y], [0, 1, 0, WALL_Z0], [0, 0, 0, 1]], wall_part())
    return mirror([0, 1, 0], w) if sgn < 0 else w            # OpenSCAD's mirror([0, 0, 0]) is the identity


PARTS = {"wall": wall_part}
