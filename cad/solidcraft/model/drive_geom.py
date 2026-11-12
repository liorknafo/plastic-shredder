"""drive_geom.py -- constants and small functions of the drive: gearbox, torque limiter, chain, idler tensioner,
motor, belt, rails, deck, hold-down (cad/drive_geom.scad).  Values and 2D helpers only.  World frame.

LAYOUT (default CHAIN_CD = 150):
  chain plane  x = X_CHAIN = middle of sprocket A's tooth plate (the plate is at the OUTER end of the hub)
  gearbox      housing face (output side) at GB_X1 = X_CHAIN - TL_CM_OFFSET - TL_GB_GAP; the housing is GB_HUB_L wide
               along x (hollow output hub), output axis y = -C/2 (shaft A's y), z = -CHAIN_CD; worm axis along y, 63
               below it; foot flange on two slotted rails (50 x 10 flats) on spacer blocks on the deck
  TL350        flange end 3 mm (TL_GB_GAP, a spacer on the shaft) from the housing face, the sprocket (centre member)
               12 mm (TL_CM_OFFSET) from the flange-end face = in the chain plane, then friction pack, pressure plate,
               disc springs and the adjusting nut on the outboard end; stop collar behind it
  motor        on the deck, axis at the worm axis height (horizontal belt), BELT_CENTRE_DIST toward -x, pulley side -y
  tensioner    idler sprocket (#40 15T) INSIDE the loop on the slack (+y) side; upright with its column OUTSIDE the rails
  hold-down    rails -> deck -> 4 legs, each fixed to the deck by a top angle and to the floor by a foot angle
"""
from common import *

HW_GAP = 0.01                                      # hardware placeholders sit 0.01 off every contact face
YA = -C / 2                                        # shaft A / chain plane / gearbox output axis y
X_CHAIN = x_sprocket_out + SPROCKET_T / 2          # chain plane (tooth plate centre)
RA = sprocket_A_pd / 2                             # pitch radii: sprocket A (15T), TL sprocket (30T)
RT = tl_sprocket_pd / 2
SPA_OD_ = sprocket_A_pd + SPROCKET_OD_EXTRA
TL_OD_ = tl_sprocket_pd + SPROCKET_OD_EXTRA
ZO = -CHAIN_CD                                     # TL / gearbox output axis height
ZW = ZO - WORM_AXIS_DROP                           # worm axis
# ---- gearbox housing along x: its width = the hollow output hub (GB_HUB_L), output face at GB_X1 (the +x side)
GB_X1 = X_CHAIN - TL_CM_OFFSET - TL_GB_GAP
GB_X0 = GB_X1 - GB_HUB_L
GB_XC = (GB_X0 + GB_X1) / 2
GB_Y0 = YA - GB_BOX[1] / 2
GB_Y1 = YA + GB_BOX[1] / 2
GB_OHL_ARM = X_CHAIN - GB_X1                       # overhang: housing face to the chain plane (15)
# ---- TL350 along x (flange end toward the housing)
TL_X0 = GB_X1 + TL_GB_GAP
TL_X1 = TL_X0 + TL_L                               # flange-end face .. outboard end of the hub (-116.8 .. -54.8)
TL_PL0 = X_CHAIN - SPROCKET_T / 2                  # tooth plate x range
TL_PL1 = X_CHAIN + SPROCKET_T / 2
TL_COLLAR_X0 = TL_X1                               # stop collar on the outboard side
TL_COLLAR_X1 = TL_COLLAR_X0 + TL_COLLAR_T
# ---- output shaft Ø25 h6 (bought 4140 bar): far circlip groove .. end 3 mm beyond the collar
OUT_X1 = TL_COLLAR_X1 + SHAFT_OUT_END
OUT_X0 = GB_X0 - CIRCLIP_GROOVE_W - CIRCLIP_EDGE
GBKEY_X0 = GB_X0 + GB_KEY_END                      # gearbox keyway 8 x 4 (along the hollow hub)
GBKEY_X1 = GB_X1 - GB_KEY_END
TLKEY_X0 = TL_X0 + TL_KEY_END                      # TL keyway 8 x 4 (under the TL hub)
TLKEY_X1 = TL_X1 - TL_KEY_END
assert abs(TL_X0 + TL_CM_OFFSET - X_CHAIN) < 1e-9, "TL centre member must be in the chain plane"
assert GBKEY_X1 > GBKEY_X0 and TLKEY_X1 > TLKEY_X0 and TLKEY_X1 < TL_X1 and GBKEY_X1 < GB_X1, "keyways inside the hubs"
# ---- vertical stack: the motor stands on the deck (axis 70 above it) at the worm axis height; rails on spacer blocks
MOTOR_D = 120                                      # PLACEHOLDER: salvaged motor, measure it
MOTOR_LEN = 160
MOTOR_FOOT = [150, 110, 10]
DECK_TOP = ZW - MOTOR_D / 2 - MOTOR_FOOT[2]        # -283
RAIL_SPACER_T = SUBPLATE_T - GB_RAIL_T             # 10: rail + spacer = the old 20 mm sub-plate height
RAIL_Z0 = DECK_TOP + RAIL_SPACER_T
RAIL_Z1 = RAIL_Z0 + GB_RAIL_T
GB_FZ0 = RAIL_Z1                                   # foot flange
GB_FZ1 = GB_FZ0 + GB_FLANGE[2]
GB_Z0 = GB_FZ1                                     # housing box
GB_Z1 = GB_Z0 + GB_BOX[2]
assert abs((ZO - GB_FZ0) - GB_BELOW_OUT) < 1e-6, "GB_BELOW_OUT must equal the foot height that keeps the belt horizontal"
assert GB_Z1 > ZO + 20 and GB_Z0 < ZW - 10, "the housing envelope must hold the output axis and the worm axis"
# ---- worm input shafts, pulleys, motor, belt
XG = GB_XC                                         # worm axis x = middle of the housing
Y_HF = GB_Y0                                       # housing face on the -y side (the pulley side, away from the machine)
PUL_W = 2 * BELT_WIDTH                             # pulley 26 wide, 8 mm in front of the housing face
PUL_Y0 = 8
XM = XG - BELT_CENTRE_DIST                         # motor axis (horizontal belt)
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
RAIL_BOLT_PTS = [[GB_XC + sx * GB_RAIL_BOLT_DX, yc] for sx in (-1, 1) for yc in RAIL_YC]   # 4 x M8 through rail + spacer + deck
# ---- chain: tangent line of the slack (+y) run and the idler
TG_NZ = (RT - RA) / CHAIN_CD                      # normal of the +y external tangent (A above, TL below)
TG_NY = sqrt(1 - TG_NZ * TG_NZ)


def run_y(z):
    """y of the straight +y run at height z."""
    return YA + (RA - TG_NZ * z) / TG_NY


TENS_Z = ZO / 2                                   # idler height (middle of the run)
TENS_R = RA                                       # idler = #40 15T, same as sprocket A
TENS_Y0 = run_y(TENS_Z) + TENS_DELTA - TENS_R     # nominal idler centre y (inside the loop)
# upright on the machine side of the chain plane: back face 10 mm from the idler.  Its COLUMN stands outside the rails;
# the head plate (TENS_HEAD_H high, under the top) carries the slot over the TL350 body.
TENS_UP_X0 = TL_PL1 + 10
TENS_UP_X1 = TENS_UP_X0 + TENS_T
TENS_GUARD_Y = TENS_Y0 + TENS_TRAVEL + TENS_R + CHAIN_ENV_H / 2 + GUARD_CLEAR + PRINT_WALL   # outer face of the chain guard's +y wall at the idler
TENS_COL_W = 30                                   # column: 30 wide x 10 thick (ripped from the 50 x 10 flat)
TENS_COL_Y0 = max(RAIL_Y_HI, TENS_GUARD_Y) + TENS_COL_GAP
TENS_COL_Y1 = TENS_COL_Y0 + TENS_COL_W
TENS_HEAD_Y0 = TENS_Y0 - TENS_TRAVEL - 15         # the head plate's -y end (slot end + 15)
TENS_SLOT_L = 2 * TENS_TRAVEL + 10.5
TENS_SLOT_W = 10.5
TENS_BASE_Z0 = DECK_TOP                           # base plate 10 thick on the deck
TENS_BASE_Z1 = DECK_TOP + 10
TENS_UP_Z1 = TENS_Z + 20                          # top of the upright
TENS_HEAD_Z0 = TENS_UP_Z1 - TENS_HEAD_H           # underside of the head plate (-95)
TENS_BASE_X1 = TENS_UP_X1
TENS_BASE_X0 = TENS_BASE_X1 - TENS_BASE[0]
TENS_BASE_Y = 40
TENS_BASE_Y0 = (TENS_COL_Y0 + TENS_COL_Y1) / 2 - TENS_BASE_Y / 2
TENS_BASE_Y1 = TENS_BASE_Y0 + TENS_BASE_Y
TENS_BOLT_PTS = [[TENS_BASE_X0 + x, (TENS_COL_Y0 + TENS_COL_Y1) / 2 + sy * 14] for x in (8, 22) for sy in (-1, 1)]   # 4 x M8 down into the deck
assert TENS_HEAD_Z0 > ZO + TL_D / 2 + GUARD_CLEAR + PRINT_WALL, "tensioner head plate must clear the TL guard tube"
assert TENS_BASE_Y0 > RAIL_Y_HI + 2, "tensioner base plate clear of the rails"
# ---- deck: motor foot, rails, tensioner base + margins
DECK_X0 = XM - MOTOR_FOOT[0] / 2 - DECK_MARGIN
DECK_X1 = max(RAIL_X1 + DECK_RAIL_MARGIN, TENS_BASE_X1 + DECK_MARGIN)
DECK_T = DECK_PLY_T
DECK_Z1 = DECK_TOP
DECK_Z0 = DECK_TOP - DECK_T
BG_BACK = 3
BG_WALL = PRINT_WALL
BG_W = PUL_Y0 + PUL_W + 15 + BG_WALL              # belt guard depth in front of the housing: 52
MFOOT_Y = [Y_HF + (MOTOR_LEN - MOTOR_FOOT[1]) / 2, Y_HF + (MOTOR_LEN + MOTOR_FOOT[1]) / 2]
DECK_FEET_Y = Y_HF - (BG_W + BG_FOOT_REACH)
DECK_Y0 = DECK_FEET_Y - 12
DECK_Y1 = max(MFOOT_Y[1], RAIL_Y_HI, TENS_BASE_Y1) + DECK_MARGIN + 8      # + 8: the back legs' top-angle bolt washers clear the tensioner base
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


# ---- chain geometry helpers (2D, plane y-z): all three pitch circles are inside the loop, so the chain path is their convex hull
def tens_y(ty):
    return TENS_Y0 + ty                           # idler centre y at slot offset ty


def chain_circles2d(ty):
    return union(translate([YA, 0], circle(r=RA)),
                 translate([YA, ZO], circle(r=RT)),
                 translate([tens_y(ty), TENS_Z], circle(r=TENS_R)))


def chain_hull2d(grow=0):
    """The area enclosed by the chain, grown by half the link plate height + grow; any idler position in its slot."""
    return offset(hull(chain_circles2d(-TENS_TRAVEL), chain_circles2d(TENS_TRAVEL)), delta=CHAIN_ENV_H / 2 + grow)


TENS_SPACER_D = 14                                # idler hardware: spacer tube, M10 washers / head / nut
TENS_WASHER_D = 20
TENS_HEAD_D = 16
TENS_HEAD_H_ = 6.4
TENS_NUT_H = 8
TENS_WASHER_T = 1.6
TENS_HEAD_X1 = TENS_UP_X1 + HW_GAP + TENS_WASHER_T + TENS_HEAD_H_      # outer face of the idler bolt head (-73.2 default)
SUBBOLT_PTS = RAIL_BOLT_PTS                       # old name used by joints
