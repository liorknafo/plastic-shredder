"""hopper.py -- collar + funnel + lid (printed, PETG), world frame (cad/hopper.scad).

COLLAR  rests on the wall tops (z = 55) and on the inner end-plate layers' top edges (z = 35).  Its inner faces continue
  the chamber: x = 0 and x = chamber_L from z = 35, |y| = 66 from z = 55, up to HOPPER_SPLIT_Z.  It is fixed with eight M5
  socket screws (M5x75 end, M5x55 wall; heads in Ø9 pockets in the collar top face, covered by the funnel flange).
  SPEC PROBLEM: the screw holes sit only 5 mm from the chamber faces, so a 3 mm wall round a Ø5.5 hole (or a Ø9 head
  pocket) cannot stay behind the face.  Each of the eight screws therefore has a 15.5 mm wide pillar that is BUMP = 2.5 mm
  proud of the nominal face into the throat (above z = 35, outside every blade envelope).
FUNNEL  132.2 x 132 inner throat at z = HOPPER_SPLIT_Z flaring to 180 x 180 inner at z = HOPPER_TOP_Z; M4 flange bolts
  to the collar.
LID     hinged at +y (M5 pin through printed knuckles), 10 mm overlap all round, handle at -x.  INTERLOCK: the Pizzato
  FS 3096D024-F7 guard-locking switch (interlock.py, APPROXIMATE envelope HSW_*) sits on the flat PAD on the +x side of
  the funnel (2 x Ø3.3 pilots for its M4 screws, 22 apart); its jointed actuator VF KEYF7 (HACT_*, approx.) is screwed
  (2 x M5, ~30 apart) to the flat face of a small printed LID ACTUATOR PAD that is bolted to the lid ear (2 x M4 into
  heat-set inserts in the pad, from under the ear).  The blade passes through a slot in the ear and enters the switch
  head INTERLOCK_IN = 12 mm when the lid is down; after ~7 deg of opening it is out.  There is NO printed tongue.
  Why a separate pad: the actuator's mounting block must sit ABOVE the tip, i.e. above the lid plate; printed as one
  piece the lid (printed top face down, no support) would have to stand on that tower.
"""
from common import *
from interlock import interlock

# the lid switch = Pizzato FS 3096D024-F7 + VF KEYF7 (all approximate); interlock.py is a template built from these values
globals().update(interlock(HSW_BODY, HSW_HOLE_SPACING, HSW_SLOT, HSW_SCREW,
                           HACT_SIZE, HACT_BLADE_T, HACT_BLADE_L, HACT_HOLE_SPACING, HACT_SCREW))

L = chamber_L
XC = L / 2
ZS = HOPPER_SPLIT_Z
ZT = HOPPER_TOP_Z
W = PRINT_WALL
FT = PRINT_FLANGE
HW = wall_inner_y                                                   # 66
CFT = 7                                                             # collar flange thickness (nut pockets)
FL_X = 18                                                           # flange reaches x in [-18, L+18], |y| <= 82
FL_Y = 82
BUMP = 2.5
HEAD_D = 9
HEAD_DEPTH = 6
PIN_Z = ZT - 7                                                      # hinge axis (along x), 7 below the rim top: the knuckles never reach the lid plate
PIN_Y = 103
KN_R = 6
PAD_X = XC + 102                                                    # vertical face of the interlock-switch pad (+x side)
LID_T = 3
SW_TOP = ZT + LID_T + 0.5 + INTERLOCK_IN - ACT_BL                   # switch head end face: the actuator block then clears the lid top by 0.5
SW_Z0 = SW_TOP - SW_L                                               # 186.5 (112 long switch)
PAD_Z = [SW_Z0 - 1, SW_TOP + 1]
HPAD_W = HSW_PAD_W                                                  # width (y) of the funnel switch pad: 48 for the 42 wide body


def hop_world(*ch):
    """Switch frame S (a, b, c) of interlock.py -> world: a -> +x (out of the funnel pad), b -> -z (head end face at
    the top), c -> +y."""
    return multmatrix([[1, 0, 0, PAD_X], [0, 0, 1, 0], [0, -1, 0, SW_TOP], [0, 0, 0, 1]], *ch)


LIDPAD_B = [INTERLOCK_IN - ACT_L - 2, SW_TOP - (ZT + LID_T)]        # lid actuator pad (tower) along b: -58 .. -9.5 (world z 356.5 .. 308 = the lid ear's top)
LIDPAD_A = [-1, A_OFF]                                              # its flat face at a = A_OFF carries the actuator
LIDPAD_SCREW_A = (LIDPAD_A[0] + LIDPAD_A[1]) / 2                    # the 2 x M4 that hold it on the ear: c = +-9
LIDPAD_SCREW_C = 9


def lid_ear_screw_xy():
    """World (x, y): the ONE definition for the ear holes and the pad's inserts."""
    return [[PAD_X + LIDPAD_SCREW_A, s * LIDPAD_SCREW_C] for s in (-1, 1)]


assert SW_Z0 > PAD_Z[0] and SW_TOP < PAD_Z[1]


# funnel inner half sizes at height z (x about XC, y about 0)
def fx(z):
    return XC + (HOPPER_TOP_IN / 2 - XC) * (z - ZS) / (ZT - ZS)


def fy(z):
    return HW + (HOPPER_TOP_IN / 2 - HW) * (z - ZS) / (ZT - ZS)


def slab(hx, hy, z):
    """A thin slab: what hopper.scad hulls in loft().  Not used here (loft is a prismoid)."""
    return translate([XC - hx, -hy, z], cube([2 * hx, 2 * hy, 0.01]))


def rect(hx, hy):
    """Corners of the centred rectangle |x| <= hx, |y| <= hy."""
    return [(-hx, -hy), (hx, -hy), (hx, hy), (-hx, hy)]


def loft(off, z0, z1):
    """hull() of slab(.., z0) and slab(.., z1 - 0.01): the straight-sided frustum between the two rectangles."""
    return translate([XC, 0, z0], prismoid(rect(fx(z0) + off, fy(z0) + off), rect(fx(z1) + off, fy(z1) + off), z1 - z0))


END_SCREW_X = [-5, L + 5]                                           # centred in the inner layers
# M4 flange bolts (x, y)
BOLTS = ([[x, s * 72] for x in (12, XC, L - 12) for s in (-1, 1)]
         + [[e, y] for e in (-8.5, L + 8.5) for y in (-57, -20, 20, 57)])


def flange_box(z0, t):
    return translate([-FL_X, -FL_Y, z0], cube([L + 2 * FL_X, 2 * FL_Y, t]))


# ------------------------------------------------------------------ collar
def collar():
    return difference(
        union(
            [translate([x0, -76, 35], cube([10, 152, 20])) for x0 in (-10, L)],                     # end blocks on the plate tops
            [translate([x0, -(HW + W), 35], cube([W, 2 * (HW + W), ZS - 35])) for x0 in (-W, L)],   # end skins (inner face x = 0 / L)
            [[translate([0, HW if s > 0 else -76, 55], cube([L, 10, 14])),                          # side feet on the wall tops
              translate([0, HW if s > 0 else -(HW + W), 55], cube([L, W, ZS - 55]))]                # side skins
             for s in (-1, 1)],
            flange_box(ZS - CFT, CFT),
            # screw pillars (BUMP proud of the faces)
            [translate([-13 if xs < 0 else L - BUMP, s * TOP_HOLE_Y - 7.75, 35], cube([13 + BUMP, 15.5, ZS - 35]))
             for xs in END_SCREW_X for s in (-1, 1)],
            [translate([x - 7.75, HW - BUMP if s > 0 else -76, 55], cube([15.5, 76 - HW + BUMP, ZS - 55]))
             for x in (WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X) for s in (-1, 1)]),
        # throat (cut everything inside the nominal faces EXCEPT the pillars)
        difference(
            translate([0, -HW, 34], cube([L, 2 * HW, ZS - 34 + 1])),
            [translate([-1 if xs < 0 else L - BUMP, s * TOP_HOLE_Y - 7.75, 34], cube([1 + BUMP, 15.5, ZS - 34 + 1]))
             for xs in END_SCREW_X for s in (-1, 1)],
            [translate([x - 7.75, HW - BUMP if s > 0 else -HW - 0.001, 34], cube([15.5, BUMP, ZS - 34 + 1]))
             for x in (WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X) for s in (-1, 1)]),
        # end screws
        [[translate([xs, y, 34], cylinder(d=5.5, h=ZS - 33)),
          translate([xs, y, ZS - HEAD_DEPTH], cylinder(d=HEAD_D, h=HEAD_DEPTH + 1))]
         for xs in END_SCREW_X for y in (-TOP_HOLE_Y, TOP_HOLE_Y)],
        # side screws
        [[translate([x, y, 54], cylinder(d=5.5, h=ZS - 53)),
          translate([x, y, ZS - HEAD_DEPTH], cylinder(d=HEAD_D, h=HEAD_DEPTH + 1))]
         for x in (WALL_TOP_HOLE_X, L - WALL_TOP_HOLE_X) for y in (-WALL_TOP_HOLE_Y, WALL_TOP_HOLE_Y)],
        # M4 flange bolts + hex nut pockets (7 AF) from below
        [[translate([p[0], p[1], ZS - CFT - 1], cylinder(d=4.5, h=CFT + 2)),
          translate([p[0], p[1], ZS - CFT - 1], cylinder(d=8.3, h=1 + 3.4, fn=6))]
         for p in BOLTS])


# ------------------------------------------------------------------ funnel
def knuckles_funnel():
    """hull() of the web on the rim and the knuckle cylinder (top at z = 304 < lid 305), both 25 long along x:
    the 2D hull in the (y, z) plane, extruded along x."""
    return union(axial(XC + s * 57.5 - 12.5, linear_extrude(25, hull(
        translate([93, PIN_Z - KN_R], square([4, 2 * KN_R - 1])),
        translate([PIN_Y, PIN_Z], circle(r=KN_R))))) for s in (-1, 1))


def funnel():
    return difference(
        union(
            difference(loft(W, ZS, ZT), loft(0, ZS - 1, ZT + 1)),
            difference(flange_box(ZS, FT), translate([0, -HW, ZS - 1], cube([L, 2 * HW, FT + 2]))),          # bottom flange
            difference(translate([XC - 95, -95, ZT - 4], cube([190, 190, 4])),                              # top rim
                       translate([XC - HOPPER_TOP_IN / 2, -HOPPER_TOP_IN / 2, ZT - 5], cube([HOPPER_TOP_IN, HOPPER_TOP_IN, 6]))),
            # interlock pad on +x: vertical face at PAD_X, 45 deg underside back to the slanted wall.  hull() of three
            # boxes HPAD_W wide in y: the 2D hull in the (x, z) plane, extruded along y (-HPAD_W/2 .. HPAD_W/2)
            translate([0, HPAD_W / 2, 0], rotate([90, 0, 0], linear_extrude(HPAD_W, hull(
                translate([XC + fx(PAD_Z[0] - 22) + W - 1, PAD_Z[0] - 22], square([1, 1])),
                translate([PAD_X - 0.01, PAD_Z[0]], square([0.01, PAD_Z[1] - PAD_Z[0]])),
                translate([XC + fx(PAD_Z[1]) + W - 1, PAD_Z[1] - 1], square([1, 1])))))),
            knuckles_funnel()),
        [translate([p[0], p[1], ZS - 1], cylinder(d=4.5, h=FT + 2)) for p in BOLTS],
        hop_world(sw_pad_pilots()),                    # 2 x Ø3.3 pilots for the switch's M4 screws, HSW_HOLE_SPACING (22) apart
        translate([XC - 120, PIN_Y, PIN_Z], rotate([0, 90, 0], cylinder(d=5.3, h=240))),
        loft(0, ZS - 1, ZT + 1))                       # keep the throat clear of the pad block


# ------------------------------------------------------------------ lid (closed pose, world frame)
def lid():
    return difference(
        union(
            translate([XC - 100, -100, ZT], cube([200, 200, 3])),                          # 10 mm overlap round the 180 opening
            translate([XC - 115, -20, ZT], cube([16, 40, 3])),                             # handle tab (-x)
            translate([XC - 115, -20, ZT - 12], cube([4, 40, 12])),                        # handle lip hanging below the tab (printed top-down)
            translate([XC + 99, -SW_PAD_W / 2 - 1, ZT],                                    # ear under the actuator pad (flat, no tongue)
                      cube([PAD_X + A_OFF + ACT_H + 3 - (XC + 99), SW_PAD_W + 2, LID_T])),
            # hinge arm + knuckle: hull() of a box and a cylinder, both 88 long along x: the 2D hull in (y, z), extruded along x
            axial(XC - 44, linear_extrude(88, hull(translate([96, ZT], square([4, 3])),
                                                   translate([PIN_Y, PIN_Z], circle(r=KN_R)))))),
        translate([XC - 112, -9, ZT - 1], cube([10, 18, 5])),                              # finger slot in the handle tab
        translate([PAD_X + SW_D / 2 - HSW_SLOT[0] / 2, -HSW_SLOT[1] / 2, ZT - 1],          # slot for the blade through the ear (same size as the switch slot)
                  cube([HSW_SLOT[0], HSW_SLOT[1], LID_T + 2])),
        [translate([p[0], p[1], ZT - 1], cylinder(d=HOLE_D, h=LID_T + 2)) for p in lid_ear_screw_xy()],   # M4 clearance holes for the pad screws
        translate([XC - 120, PIN_Y, PIN_Z], rotate([0, 90, 0], cylinder(d=5.3, h=240))))


def each(name, tree):
    """Every member of a union (one screw each) as a part of its own."""
    return [part(name, c) for c in (tree.ch if tree.kind == "union" else [tree])]


def switch_ph():
    """The safety switch (placeholder), on the funnel pad."""
    return hop_world(sw_ph())


def switch_env():
    """Body without the slot."""
    return hop_world(sw_body_env())


def switch_slot():
    return hop_world(sw_slot())


def switch_screws_ph():
    return hop_world(each("Lid switch screw M4", sw_screws_ph()))


def lid_pad_s():
    """Lid actuator pad (printed, PETG), switch frame: a block standing on the lid ear.  Flat face at a = A_OFF carries
    the actuator (2 pilots); 2 heat-set insert pockets in its foot take the M4 screws that come from under the ear."""
    return difference(
        translate([LIDPAD_A[0], LIDPAD_B[0], -SW_PAD_W / 2],
                  cube([LIDPAD_A[1] - LIDPAD_A[0], LIDPAD_B[1] - LIDPAD_B[0], SW_PAD_W])),
        act_in_sw(0, act_pad_pilots()),
        [translate([LIDPAD_SCREW_A, LIDPAD_B[1] + 0.01, c], rotate([90, 0, 0], cylinder(d=INSERT_D, h=INSERT_DEPTH + 0.01)))
         for c in (-LIDPAD_SCREW_C, LIDPAD_SCREW_C)])


def lid_pad():
    return hop_world(lid_pad_s())


def lid_pad_screws_ph():
    """M4 x 12 pan head screws from under the ear into the inserts."""
    return union(part("Lid actuator pad screw M4 x 12",
                      translate([p[0], p[1], ZT],
                                translate([0, 0, -2.8], cylinder(d=SCREW_HEAD_D, h=2.8)),
                                cylinder(d=SCREW_D, h=12 - 2.8 + 0.5))) for p in lid_ear_screw_xy())


def hop_actuator():
    """The coded actuator (placeholder), engaged."""
    return hop_world(act_in_sw(0, act_ph()))


def hop_actuator_screws_ph():
    return hop_world(act_in_sw(0, each("Lid actuator screw M5 x 25", act_screws_ph())))


def hop_blade():
    """The blade only."""
    return hop_world(blade_env())


def hop_slot_from(depth):
    """The part of the switch slot deeper than `depth` from the mouth."""
    return hop_world(intersection(sw_slot(), translate([-1, depth, -50], cube([40, 100, 100]))))


def hop_switch_shanks():
    return hop_world(sw_shanks())


def hop_actuator_shanks():
    return hop_world(act_in_sw(0, act_shanks()))


def lid_screw_shanks():
    """M4: ear Ø4.5 + insert Ø5.6."""
    return union(translate([p[0], p[1], ZT - 1], cylinder(d=4, h=LID_T + 1 + 4)) for p in lid_ear_screw_xy())


def hinge_pin_ph():
    return translate([XC - 80, PIN_Y, PIN_Z], rotate([0, 90, 0], cylinder(d=5, h=160)))


def lid_pad_box():
    return [[PAD_X + LIDPAD_A[0], -SW_PAD_W / 2, SW_TOP - LIDPAD_B[1]],
            [LIDPAD_A[1] - LIDPAD_A[0], SW_PAD_W, LIDPAD_B[1] - LIDPAD_B[0]]]


def lid_box():
    """[min corner, size] for the C5 shrink."""
    return [[XC - 115, -100, ZT - 12], [PAD_X + A_OFF + ACT_H + 3 - (XC - 115), 209, 27]]


# lid_posed: a = 0 closed; positive a lifts the front edge about the hinge
def hinge_rot(a=0, *ch):
    return translate([0, PIN_Y, PIN_Z], rotate([-a, 0, 0], translate([0, -PIN_Y, -PIN_Z], *ch)))


def lid_blade_posed(a=0):
    return hinge_rot(a, hop_blade())


def lid_posed(a=0):
    return hinge_rot(a, lid())


def lid_pad_posed(a=0):
    return hinge_rot(a, lid_pad())


def lid_actuator_posed(a=0):
    return hinge_rot(a, hop_actuator())


def lid_hw_posed(a=0):
    return hinge_rot(a, hop_actuator_screws_ph(), lid_pad_screws_ph())


# ---- the exports of hopper.scad (-D 'part="collar"|"funnel"|"lid"|"lid_act_pad"': print pose; "world": assembled)
def collar_print():
    """Flange face down."""
    return translate([FL_X, FL_Y, ZS], rotate([180, 0, 0], collar()))


def funnel_print():
    """Flange face down."""
    return translate([95 - XC, 95, -ZS], funnel())


def lid_print():
    """Top face down."""
    return translate([115 - XC, 100, ZT + 3], rotate([180, 0, 0], lid()))


def lid_act_pad_print():
    """The actuator face (pilots) is the vertical side: laid on the a = -1 side."""
    return multmatrix([[0, -1, 0, LIDPAD_B[1]], [0, 0, -1, SW_PAD_W / 2], [1, 0, 0, 1], [0, 0, 0, 1]], lid_pad_s())


def world(lid_angle=0):
    return union(collar(), funnel(), lid_posed(lid_angle), lid_pad_posed(lid_angle), lid_actuator_posed(lid_angle),
                 lid_hw_posed(lid_angle), switch_ph(), switch_screws_ph(), hinge_pin_ph())


BODIES = {
    "Frame": [
        Body("Hopper collar + funnel",
             lambda: union(part("Hopper collar", collar()), part("Hopper funnel", funnel())), "#6fa8dc", 0.30),
        Body("Lid guard-lock switch + screws",
             lambda: union(part("Lid guard-lock switch (Pizzato FS 3096D024-F7)", switch_ph()), switch_screws_ph()), DARK, 1),
    ],
    "Lid": [
        Body("Lid + actuator pad",
             lambda: union(part("Hopper lid", lid_posed(0)), part("Lid actuator pad", lid_pad_posed(0))), PRINT, 0.45),
        Body("Lid screws (pad, actuator)", lambda: lid_hw_posed(0), DARK, 1),
        Body("Lid actuator key", lambda: part("Lid actuator key (Pizzato VF KEYF7)", lid_actuator_posed(0)), METAL, 1),
    ],
}


# the printed parts of this file in their print pose (parts.py)
PARTS = {"hopper_collar": collar_print,          # flange face down
         "hopper_funnel": funnel_print,          # flange face down
         "hopper_lid": lid_print,                # top face down
         "hopper_lid_pad": lid_act_pad_print}
