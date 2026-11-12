"""joints.py -- ONE coordinate function per bolted joint that more than one part needs (cad/joints.scad).

Every hole that receives a fastener from another part is placed from the function below, never from a number typed
into the part: change the function and BOTH parts follow.
  foot_screw_xy()    8 x M6: base-plate foot slots  <->  end-plate layers
  guard_hole_yz()    4 x M5: drive-end guard wings / free-end cover  <->  cap layers (tapped)
  gb_foot_pts()      4 x M8: gearbox foot flange  <->  rails (drive_geom)
  SUBBOLT_PTS        4 x M8: rails  <->  drive deck (drive_geom)
  TENS_BOLT_PTS      4 x M8: tensioner base plate  <->  drive deck (drive_geom)
"""
from common import *
from drive_geom import *

FOOT_SCREW_Y = 65                                  # |y| of the M6 feet in the bottom edge of the inner / outer end-plate layers


def layer_centre_x(end, i):
    return -LAYER_T * (i + 0.5) if end == "drive" else chamber_L + LAYER_T * (i + 0.5)     # i = 0 inner, 1 outer


def foot_screw_xy():
    return [[layer_centre_x(e, i), y] for e in ("drive", "free") for i in (0, 1) for y in (-FOOT_SCREW_Y, FOOT_SCREW_Y)]


def guard_hole_yz():
    return [[sy * GUARD_HOLE_Y, sz * GUARD_HOLE_Z] for sy in (-1, 1) for sz in (-1, 1)]
