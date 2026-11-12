"""interlock.py -- the safety interlock hardware as PLACEHOLDERS with honest envelopes: a switch and its MATCHING
coded metal actuator (cad/interlock.scad).
  hopper lid : Pizzato FS 3096D024-F7 guard-locking switch + its jointed actuator VF KEYF7   (params HSW_*, HACT_*)
  drawer     : Omron D4NS-2AF plain safety switch + D4DS-K2 key                              (params DSW_*, DACT_*)
EVERY DIMENSION IS APPROXIMATE: drill to the manufacturer's 2D drawing.  The printed parts carry flat pads with pilot holes only.

TEMPLATE.  The OpenSCAD file was `include`d by hopper.scad and base.scad, each with its own IL_* values.  Here
`interlock(...)` returns everything the template defined (constants and functions) for one set of values:

    globals().update(interlock(HSW_BODY, HSW_HOLE_SPACING, HSW_SLOT, HSW_SCREW, HACT_SIZE, HACT_BLADE_T, HACT_BLADE_L,
                               HACT_HOLE_SPACING, HACT_SCREW))

SWITCH frame S = (a, b, c):  a = out of the mounting face (0 at the face, SW_D at the far face), b = along the body from
  the head end face (b = 0) to the rear (SW_L), c = across (centred, +-SW_W/2).  The actuator slot opens in the head end
  face at b = 0.  Two mounting holes (spacing apart, centred on b) go through the body along a.
ACTUATOR frame A = (a, b, c):  a = out of its mounting face (0 .. ACT_H), b = along it from the TIP (b = 0) to the tail
  (ACT_L), c = across (centred).  Blade (thin, ACT_BL long from the tip, full width) centred in the height; mounting
  block behind it with two holes (spacing apart, centred on the block) along a.
ENGAGED (lid / drawer closed): the blade centre plane is the slot centre plane, the tip is INTERLOCK_IN deep in the slot:
  S <- A:  a_s = a_a + A_OFF,  b_s = INTERLOCK_IN - travel - b_a,  c_s = -c_a
"""
from common import *


def interlock(IL_SW_BODY, IL_SW_HOLE_SPACING, IL_SW_SLOT, IL_SW_SCREW,
              IL_ACT_SIZE, IL_ACT_BLADE_T, IL_ACT_BLADE_L, IL_ACT_HOLE_SPACING, IL_ACT_SCREW):
    SW_W, SW_D, SW_L = IL_SW_BODY
    ACT_H, ACT_W, ACT_L = IL_ACT_SIZE
    ACT_BT, ACT_BL = IL_ACT_BLADE_T, IL_ACT_BLADE_L
    A_OFF = SW_D / 2 - ACT_H / 2                                  # mounting plane of the actuator in the switch frame when engaged
    SCREW_D, SCREW_HEAD_D, SCREW_HEAD_H, HOLE_D = 4, 7, 3, 4.5    # plain M4 (the lid pad's own screws, the drawer pads' hardware)
    # the switch's own screws and the actuator's own screws: [d, clearance hole, head Ø, head h, pilot Ø]
    SWS_D, SWS_HOLE, SWS_HEAD_D, SWS_HEAD_H, SWS_PILOT = IL_SW_SCREW
    ACS_D, ACS_HOLE, ACS_HEAD_D, ACS_HEAD_H, ACS_PILOT = IL_ACT_SCREW
    SWS_PDEPTH = 10 if SWS_D >= 5 else PILOT_DEPTH                # pilot depth in the pad (thread-forming: ~2 d)
    ACS_PDEPTH = 10 if ACS_D >= 5 else PILOT_DEPTH
    SHANK_D = PILOT_D - 0.3                                       # thread core of an M4
    assert 10 <= INTERLOCK_IN < IL_SW_SLOT[2] and INTERLOCK_IN < ACT_BL and INTERLOCK_IN <= INTERLOCK_OUT_TRAVEL, \
        "blade must go in >= 10 mm, less than the slot depth and the blade length, and be out within INTERLOCK_OUT_TRAVEL"
    assert IL_SW_SLOT[0] > ACT_BT and IL_SW_SLOT[1] > ACT_W, "slot must be larger than the blade"
    assert ACT_L - ACT_BL >= IL_ACT_HOLE_SPACING + ACS_HOLE + 4, "the actuator block must be long enough for its two holes"

    def sw_hole_b():
        return [SW_L / 2 + s * IL_SW_HOLE_SPACING / 2 for s in (-1, 1)]

    def act_hole_b():
        return [(ACT_BL + ACT_L) / 2 + s * IL_ACT_HOLE_SPACING / 2 for s in (-1, 1)]

    def act_to_sw(travel=0):
        """4x4 matrix: actuator frame -> switch frame, drawer / lid pulled away by `travel`."""
        return [[1, 0, 0, A_OFF], [0, -1, 0, INTERLOCK_IN - travel], [0, 0, -1, 0], [0, 0, 0, 1]]

    # ---------------------------------------------------------------- switch (switch frame)
    def sw_body_env():
        return translate([0, 0, -SW_W / 2], cube([SW_D, SW_L, SW_W]))                          # whole body, slot not cut

    def sw_slot():
        return translate([SW_D / 2 - IL_SW_SLOT[0] / 2, -1, -IL_SW_SLOT[1] / 2], cube([IL_SW_SLOT[0], IL_SW_SLOT[2] + 1, IL_SW_SLOT[1]]))

    def sw_ph():
        return difference(sw_body_env(), sw_slot(),
                          [translate([-1, b, 0], rotate([0, 90, 0], cylinder(d=SWS_HOLE, h=SW_D + 2))) for b in sw_hole_b()])

    def sw_screws_ph():
        """Pan-head screws from the far face."""
        return union(translate([SW_D, b, 0],
                               rotate([0, 90, 0], cylinder(d=SWS_HEAD_D, h=SWS_HEAD_H)),
                               rotate([0, -90, 0], cylinder(d=SWS_D, h=SW_D + SWS_PDEPTH - 1))) for b in sw_hole_b())

    def sw_shanks(d=None):
        d = SWS_PILOT - 0.3 if d is None else d
        return union(translate([SW_D + 1, b, 0], rotate([0, -90, 0], cylinder(d=d, h=SW_D + SWS_PDEPTH))) for b in sw_hole_b())

    def sw_pad_pilots():
        """Into the pad, from its face a = 0."""
        return union(translate([0.01, b, 0], rotate([0, -90, 0], cylinder(d=SWS_PILOT, h=SWS_PDEPTH + 0.01))) for b in sw_hole_b())

    # ---------------------------------------------------------------- actuator (actuator frame)
    def act_ph():
        return difference(
            union(translate([0, ACT_BL, -ACT_W / 2], cube([ACT_H, ACT_L - ACT_BL, ACT_W])),                 # mounting block
                  translate([ACT_H / 2 - ACT_BT / 2, 0, -ACT_W / 2], cube([ACT_BT, ACT_BL, ACT_W]))),       # blade
            [translate([-1, b, 0], rotate([0, 90, 0], cylinder(d=ACS_HOLE, h=ACT_H + 2))) for b in act_hole_b()])

    def act_screws_ph():
        return union(translate([ACT_H, b, 0],
                               rotate([0, 90, 0], cylinder(d=ACS_HEAD_D, h=ACS_HEAD_H)),
                               rotate([0, -90, 0], cylinder(d=ACS_D, h=ACT_H + ACS_PDEPTH - 1))) for b in act_hole_b())

    def act_shanks(d=None):
        d = ACS_PILOT - 0.3 if d is None else d
        return union(translate([ACT_H + 1, b, 0], rotate([0, -90, 0], cylinder(d=d, h=ACT_H + ACS_PDEPTH))) for b in act_hole_b())

    def act_pad_pilots():
        return union(translate([0.01, b, 0], rotate([0, -90, 0], cylinder(d=ACS_PILOT, h=ACS_PDEPTH + 0.01))) for b in act_hole_b())

    def act_in_sw(travel, *ch):
        """The actuator placed in the switch frame; travel = 0 is engaged."""
        return multmatrix(act_to_sw(travel), *ch)

    def blade_env(travel=0):
        """The part of the blade that enters the head (switch frame)."""
        return act_in_sw(travel, translate([ACT_H / 2 - ACT_BT / 2, 0, -ACT_W / 2], cube([ACT_BT, ACT_BL, ACT_W])))

    def sw_rest():
        return sw_ph()                                                                           # body with slot (material only)

    return dict(locals())
