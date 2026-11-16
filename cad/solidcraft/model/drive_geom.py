"""drive_geom.py -- constants and small functions of the drive: gearbox, pin flange, motor, jaw coupling, rails, deck,
hold-down (cad/drive_geom.scad).  Values only.  World frame.

LAYOUT (no belt, no chain):
  TL350        on shaft A's drive end, FLIPPED: nut end inward at x_spA_in (-135), flange end outward at
               x_sprocket_out (-197); its 30T sprocket plate at X_CM (-185)
  pin flange   (made, 6061) on the gearbox output shaft, COAXIAL with shaft A: its disc face PF_GAP outside the TL's
               flange-end face, a pocket over A's end cap + M10 head, 4 dowel pins Ø8 pressed through the disc,
               reaching through 4 holes drilled in the TL's sprocket plate (the pins drive the plate)
  gearbox      output axis = shaft A's axis (y = YA, z = 0); housing face (output side) at GB_X1 = the flange hub's
               end - TL_GB_GAP (a Ø36 spacer); GB_HUB_L wide along x; worm axis along y, 63 below; foot flange on two
               slotted rails (50 x 10 flats) on spacer blocks on the deck
  motor        on the deck, COAXIAL with the worm's -y input shaft, joined to it by a jaw coupling; the +y stub has its
               own printed cap
  hold-down    rails -> deck -> 4 legs, each fixed to the deck by a top angle and to the floor by a foot angle
"""
from common import *

HW_GAP = 0.01                                      # hardware placeholders sit 0.01 off every contact face
YA = -C / 2                                        # shaft A = gearbox output axis y
X_CM = x_cm                                        # the TL's sprocket plate (centre member) on A
SPA_OD_ = sprocket_A_pd + SPROCKET_OD_EXTRA        # its tooth-tip OD: 127.7
ZO = 0                                             # gearbox output axis height = shaft A's axis
ZW = ZO - WORM_AXIS_DROP                           # worm axis
# ---- pin flange along x (outward = -x): disc face PF_X0, disc back PF_X1, pocket bottom PF_PK_X, keyed bore to the hub end PF_HUB_X
PF_X0 = x_sprocket_out - PF_GAP
PF_X1 = PF_X0 - PF_T
PF_PK_X = x_sprocket_out - END_WASHER_T - 10 - PF_POCKET_CLEAR       # pocket bottom: 2 beyond A's M10 head
PF_HUB_X = PF_PK_X - PF_KEY_L                                        # hub end (toward the gearbox)
PIN_X0 = PF_X1                                                       # the pins: flush with the disc's back, tips toward A
PIN_X1 = PIN_X0 + PIN_L
PIN_PTS = [[PIN_R * cos(a), PIN_R * sin(a)] for a in range(45, 360, int(360 / PIN_N))]   # (y, z) offsets from A's axis
assert PF_PK_X < PF_X1 and PF_HUB_X < PF_PK_X, "the pocket is deeper than the disc; the bore follows it"
assert PIN_X1 >= X_CM + SPROCKET_T / 2 + 1, "the pins reach >= 1 mm past the sprocket plate"
assert PIN_R - PIN_D / 2 - TL_D / 2 >= 1.5, "the pins pass >= 1.5 mm outside the TL350's Ø89 body"
assert PIN_R - PIN_HOLE_D / 2 - TL_D / 2 >= 1.5 and tl_sprocket_root_d / 2 - (PIN_R + PIN_HOLE_D / 2) >= 1.5, \
    "the holes stay >= 1.5 mm inside the plate band (Ø89 body .. tooth root)"
assert PF_D / 2 - (PIN_R + PIN_D / 2) >= 5, "pin holes >= 5 mm inside the flange disc's edge"
# ---- gearbox housing along x: its width = the hollow output hub (GB_HUB_L), output face at GB_X1 (the +x side, toward A)
GB_X1 = PF_HUB_X - TL_GB_GAP
GB_X0 = GB_X1 - GB_HUB_L
GB_XC = (GB_X0 + GB_X1) / 2
GB_Y0 = YA - GB_BOX[1] / 2
GB_Y1 = YA + GB_BOX[1] / 2
# ---- output shaft Ø25 h6 (bought 4140 bar): far circlip groove .. 1 mm short of the pin flange's pocket bottom
OUT_X1 = PF_PK_X - PF_SHAFT_RECESS
OUT_X0 = GB_X0 - CIRCLIP_GROOVE_W - CIRCLIP_EDGE
GBKEY_X0 = GB_X0 + GB_KEY_END                      # gearbox keyway 8 x 4 (along the hollow hub)
GBKEY_X1 = GB_X1 - GB_KEY_END
PFKEY_X0 = PF_HUB_X + TL_KEY_END                   # pin-flange keyway 8 x 4 (under the flange's bore)
PFKEY_X1 = OUT_X1 - TL_KEY_END
assert GBKEY_X1 > GBKEY_X0 and PFKEY_X1 > PFKEY_X0 and GBKEY_X1 < GB_X1, "keyways inside the hubs"
# ---- vertical stack: the motor stands on the deck (axis 70 above it) at the worm axis height (coaxial with the worm);
#      rails stand on spacer blocks on the deck
MOTOR_D = 120                                      # PLACEHOLDER: salvaged motor, measure it
MOTOR_LEN = 160
MOTOR_FOOT = [150, 110, 10]
DECK_TOP = ZW - MOTOR_D / 2 - MOTOR_FOOT[2]        # -133
RAIL_SPACER_T = SUBPLATE_T - GB_RAIL_T             # 10: rail + spacer = the old 20 mm sub-plate height
RAIL_Z0 = DECK_TOP + RAIL_SPACER_T
RAIL_Z1 = RAIL_Z0 + GB_RAIL_T
GB_FZ0 = RAIL_Z1                                   # foot flange
GB_FZ1 = GB_FZ0 + GB_FLANGE[2]
GB_Z0 = GB_FZ1                                     # housing box
GB_Z1 = GB_Z0 + GB_BOX[2]
assert abs((ZO - GB_FZ0) - GB_BELOW_OUT) < 1e-6, "GB_BELOW_OUT must equal the foot height that puts the worm axis at the motor axis height"
assert GB_Z1 > ZO + 20 and GB_Z0 < ZW - 10, "the housing envelope must hold the output axis and the worm axis"
# ---- worm input shafts, jaw coupling, motor (coaxial with the worm's -y stub)
XG = GB_XC                                         # worm axis x = middle of the housing
Y_HF = GB_Y0                                       # housing face on the -y side (the motor side, away from the machine)
Y_HF2 = GB_Y1                                      # housing face on the +y side (the second, unused stub: capped)
Y_WS = Y_HF - GB_WORM_STUB                         # end of the -y worm stub
CPL_Y_W1 = Y_WS + CPL_hub_L                        # coupling: worm-side hub Y_WS .. CPL_Y_W1, spider Y_WS - gap .. Y_WS,
CPL_Y_M0 = Y_WS - CPL_gap - CPL_hub_L              #   motor-side hub CPL_Y_M0 .. Y_WS - gap
Y_MF = Y_WS - CPL_gap - MOTOR_SHAFT_L              # the motor's front face (its shaft end meets the spider)
XM = XG                                            # motor axis: coaxial with the worm
ZM = ZW


# ---- rails: two 50 x 10 flats under the foot rows, slots along x, M8 deck bolts outside the flange, spacer blocks
def gb_foot_pts():
    """4 x Ø9 feet = the slot centres."""
    return [[GB_XC + sx * GB_FOOT[0] / 2, YA + sy * GB_FOOT[1] / 2] for sx in (-1, 1) for sy in (-1, 1)]


RAIL_YC = [YA - GB_RAIL_W / 2, YA + GB_RAIL_W / 2]        # rail centre lines: together they cover the flange's y footprint
RAIL_FOOT_DY = GB_FOOT[1] / 2 - GB_RAIL_W / 2             # foot bolt row, from the rail's centre line toward its outer edge (13)
RAIL_X0 = GB_XC - GB_RAIL_BOLT_DX - GB_RAIL_END
RAIL_X1 = GB_XC + GB_RAIL_BOLT_DX + GB_RAIL_END
RAIL_Y_LO = RAIL_YC[0] - GB_RAIL_W / 2
RAIL_Y_HI = RAIL_YC[1] + GB_RAIL_W / 2
RAIL_BOLT_PTS = [[GB_XC + sx * GB_RAIL_BOLT_DX, yc] for sx in (-1, 1) for yc in RAIL_YC]   # 4 x M8 through rail + spacer + deck (the hold-down path)
# ---- coupling guard (printed): a box over the coupling from the motor face to the housing face, end walls notched
#      round the shafts; a cap box over the +y stub
CG_IW = CPL_D / 2 + GUARD_CLEAR                    # inner half-width (x) and inner height above the axis: 30
CG_W = PRINT_WALL
CG_Y0 = Y_MF + CG_END_GAP                          # the coupling guard's ends
CG_Y1 = Y_HF - CG_END_GAP
CG2_Y0 = Y_HF2 + CG_END_GAP                        # the stub cap's ends (its far end wall is closed)
CG2_Y1 = Y_HF2 + GB_WORM_STUB + GUARD_CLEAR + CG_W
CG_ZT = ZW + CG_IW + CG_W                          # top of both boxes
MOTOR_SHAFT_D = 12                                 # ESTIMATE from the photo: measure (the coupling hub is bored to it)
# ---- deck: motor foot, rails, coupling guard + margins
MFOOT_Y = [Y_MF - (MOTOR_LEN + MOTOR_FOOT[1]) / 2, Y_MF - (MOTOR_LEN - MOTOR_FOOT[1]) / 2]   # the motor's foot, centred under its body (y)
DECK_X0 = min(XM - MOTOR_FOOT[0] / 2, RAIL_X0) - DECK_MARGIN
DECK_X1 = RAIL_X1 + DECK_RAIL_MARGIN
DECK_T = DECK_PLY_T
DECK_Z1 = DECK_TOP
DECK_Z0 = DECK_TOP - DECK_T
DECK_Y0 = min(MFOOT_Y[0], Y_MF - MOTOR_LEN) - DECK_MARGIN
DECK_Y1 = max(RAIL_Y_HI, CG2_Y1) + DECK_MARGIN + 8      # + 8: room for the back legs' top-angle washers
# ---- legs (45 x 45 timber), top angles on the OUTER-y faces, foot angles on the INNER-x faces (2 anchors each)
LEG_INSET_X = 5
LEG_INSET_Y = DECK_LEG_INSET_Y
DECK_LEG_C = [[x, y] for x in (DECK_X0 + LEG_INSET_X + LEG_SECTION / 2, DECK_X1 - LEG_INSET_X - LEG_SECTION / 2)
              for y in (DECK_Y0 + LEG_INSET_Y + LEG_SECTION / 2, DECK_Y1 - LEG_INSET_Y - LEG_SECTION / 2)]
DECK_LEG_LEN = DECK_Z0 - GROUND_Z                 # the deck legs stand on the SAME floor as the cabinet (GROUND_Z)
DRIVE_FLOOR_Z = DECK_Z0 - DECK_LEG_LEN


def leg_sy(c):
    return -1 if c[1] < (DECK_Y0 + DECK_Y1) / 2 else 1     # outward y direction of the leg


def leg_sx(c):
    return 1 if c[0] < (DECK_X0 + DECK_X1) / 2 else -1     # inward x direction of the leg


ANG_T = DECK_ANGLE[2]
ANG_W = DECK_ANGLE[0]
ANG_L = DECK_ANGLE_L
TOPANG_DECK_PTS = [[c[0] + dx, c[1] + leg_sy(c) * (LEG_SECTION / 2 + HW_GAP + 22)] for c in DECK_LEG_C for dx in (-11, 11)]   # 8 x M8: deck <-> top angle (vertical)
TOPANG_LEG_Z = DECK_Z0 - HW_GAP - 22
TOPANG_LEG_PTS = [[c[0] + dx, c[1] + leg_sy(c) * LEG_SECTION / 2] for c in DECK_LEG_C for dx in (-11, 11)]                  # 8 x M8: top angle <-> leg (along y)
FOOTANG_LEG_Z = DRIVE_FLOOR_Z + HW_GAP + 22
FOOTANG_LEG_PTS = [[c[0] + leg_sx(c) * LEG_SECTION / 2, c[1] + dy] for c in DECK_LEG_C for dy in (-11, 11)]                 # 8 x M8: foot angle <-> leg (along x)
ANCHOR_PTS = [[c[0] + leg_sx(c) * (LEG_SECTION / 2 + HW_GAP + 22), c[1] + dy] for c in DECK_LEG_C for dy in (-11, 11)]      # 8 x M8 floor anchors
FLOOR_T = 6                                       # ghost floor / bench top slab under the drive


SUBBOLT_PTS = RAIL_BOLT_PTS                       # old name used by joints
