"""drive.py -- the drive: gearbox (foot-mounted, NRV063-VS placeholder) on two slotted rails, output shaft, TL350 torque
limiter, #40 chain (swept band), idler chain tensioner, motor + pulleys + V-belt, belt guard (two printed halves, lapped,
on feet), drive deck + legs + hold-down (leg angles, foot angles, floor anchors) (cad/drive.scad).  World frame.

DIRECTION.  Shaft A turns NEGATIVE about +x.  Chain from sprocket A (15T) straight down to the TL350 30T sprocket on the
  gearbox output (2:1 speed-up).  The run that moves toward A is the TIGHT run (-y side); the +y run is SLACK.  The
  tensioner idler is on the +y (slack) run, INSIDE the loop.
TL350 to the manufacturer's layout (tl350.py): hub flange end toward the housing, 3 mm gap (a spacer on the shaft), the
  sprocket 12 mm from the flange-end face, springs and adjusting nut on the outboard end.
OUTPUT SHAFT  Ø25 h6 from the bought 4140 bar: through the hollow output hub, keyway 8 x 4 along the hub (gearbox key) and
  8 x 4 under the TL hub (TL key); DIN 471 circlip against the housing's far face; the TL is clamped between the 3 mm
  spacer on the housing face and a Ø35 x 5 stop collar (2 grub screws) on the outboard side.
RAILS  two flats 50 x 10 under the foot rows, slots (+-6 mm along x) for the feet, M8 deck bolts outside the flange, on
  4 spacer blocks (rail + spacer = SUBPLATE_T = 20).
HOLD-DOWN  uplift path: gearbox feet -> rails (M8 through-bolts) -> deck -> 4 top angles (40x40x4, 2 x M8 through the
  deck, 2 x M8 through the leg) -> legs -> 4 foot angles (2 x M8 through the leg, 2 x M8 anchors each) -> floor.
CHAIN TENSIONER  an idler sprocket (#40 15T, bought) on an M10 bolt in a slot (+-TENS_TRAVEL along y) of a 10 mm flat
  upright, welded to a base plate bolted to the deck.

HARDWARE BODIES.  A bolt placeholder of the .scad is washer + head + shank + washer + nut as overlapping solids (the
shank runs through solid washers and a solid nut).  Here every bolt (head + shank), washer and nut is a body of its own:
the washers and nuts are the same solids with the shank cut out, so the bodies of one bolt fill exactly the .scad's union.
"""
from common import *
from joints import *              # + drive_geom: every constant of the drive
from placeholders import *
from tl350 import *


# ---------------- gearbox, output shaft, torque limiter
def cyl_xx(y, z, r, x0, x1):
    return translate([x0, y, z], rotate([0, 90, 0], cylinder(r=r, h=x1 - x0)))


def gb_housing():
    return difference(
        translate([GB_X0, GB_Y0, GB_Z0], cube([GB_HUB_L, GB_BOX[1], GB_BOX[2]])),
        cyl_xx(YA, ZO, JOURNAL_D / 2 + 0.01, GB_X0 - 1, GB_X1 + 1))                      # hollow output hub Ø25 H7 through the housing


def gb_flange():
    return translate([GB_XC - GB_FLANGE[0] / 2, YA - GB_FLANGE[1] / 2, GB_FZ0], difference(
        cube(GB_FLANGE),
        [translate([p[0] - (GB_XC - GB_FLANGE[0] / 2), p[1] - (YA - GB_FLANGE[1] / 2), -1], cylinder(d=9, h=GB_FLANGE[2] + 2))
         for p in gb_foot_pts()]))                                                       # 4 x Ø9 feet


def gearbox_ph():
    return part("Gearbox NRV063", gb_housing(), gb_flange())


def worm_ph():
    """Solid Ø19, both sides (VS)."""
    return translate([XG, GB_Y0 - GB_WORM_STUB, ZW], rotate([-90, 0, 0], cylinder(d=19, h=GB_BOX[1] + 2 * GB_WORM_STUB)))


def keyway_cut(x0, x1):
    """Keyway 8 x 4, closed ends with the Ø8 cutter's radius, on top (+z).  (The .scad hulls the two end cylinders: an obround prism.)"""
    return translate([0, 0, JOURNAL_D / 2 - SHAFT_KEY_D], linear_extrude(SHAFT_KEY_D + 1, hull(
        [translate([x, 0], circle(d=SHAFT_KEY_W)) for x in (x0 + SHAFT_KEY_W / 2, x1 - SHAFT_KEY_W / 2)])))


def output_shaft_local():
    """Axis on the x axis."""
    return difference(
        translate([OUT_X0, 0, 0], rotate([0, 90, 0], cylinder(d=JOURNAL_D, h=OUT_X1 - OUT_X0))),
        translate([GB_X0 - CIRCLIP_GROOVE_W, 0, 0], rotate([0, 90, 0], difference(     # DIN 471 groove Ø23.9 x 1.3 against the housing's far face
            cylinder(d=JOURNAL_D + 2, h=CIRCLIP_GROOVE_W),
            translate([0, 0, -1], cylinder(d=CIRCLIP_GROOVE_D, h=CIRCLIP_GROOVE_W + 2))))),
        keyway_cut(GBKEY_X0, GBKEY_X1),                 # gearbox key
        keyway_cut(TLKEY_X0, TLKEY_X1))                 # TL key


def output_shaft_ph():
    return translate([0, YA, ZO], part("Output shaft", output_shaft_local()))


# the bought / made parts that hold the TL on the shaft (seated placeholders): circlip, 3 mm spacer on the housing face, stop collar
def circlip_ph():
    return translate([0, YA, ZO], part("Circlip DIN 471 25", seat_x(CIRCLIP_OD, CIRCLIP_GROOVE_D, GB_X0 - CIRCLIP_T, CIRCLIP_T)))


def out_spacer_ph():
    return translate([0, YA, ZO], part("Output shaft spacer", seat_x(OUT_SPACER_D, JOURNAL_D, GB_X1, TL_GB_GAP)))


def stop_collar_ph():
    return translate([0, YA, ZO], part("Stop collar", seat_x(TL_COLLAR_D, JOURNAL_D, TL_COLLAR_X0, TL_COLLAR_T)))


def shaft_hw_ph():
    return union(circlip_ph(), out_spacer_ph(), stop_collar_ph())


def tl_ph():
    return translate([TL_X0, YA, ZO], part("Torque limiter TL350-2", tl350_l()))


def tl_plate_ph():
    """The sprocket's tooth plate alone."""
    return translate([TL_X0, YA, ZO], tl_plate_l())


def stop_collar_part():
    """Stop collar, turned from the Ø55 bar, 2 x M6 grub screws (tap drill Ø5) at 90 deg.

    NOTE: with TL_COLLAR_T = 5 the Ø5 holes are exactly as high as the collar is thick: they touch both end faces along
    a line, which is not a solid.  SolidCraft builds one such hole and refuses the second; it builds with a thicker
    collar or a smaller hole.  The tree is the .scad's, unchanged (the assembly uses stop_collar_ph(), a plain ring).
    """
    return difference(
        cylinder(d=TL_COLLAR_D, h=TL_COLLAR_T),
        translate([0, 0, -1], cylinder(d=JOURNAL_D, h=TL_COLLAR_T + 2)),
        [rotate([0, 0, a], translate([0, 0, TL_COLLAR_T / 2], rotate([0, 90, 0], cylinder(d=5, h=TL_COLLAR_D / 2 + 1)))) for a in (0, 90)])


def output_shaft_2d():
    """2D drawing of the output shaft (side view with the keyway and the groove, plan view with the keyway slots; 1:1 mm;
    x = along the shaft from the far end)."""
    L = OUT_X1 - OUT_X0
    R = JOURNAL_D / 2
    g0 = GB_X0 - CIRCLIP_GROOVE_W - OUT_X0
    keys = [[GBKEY_X0, GBKEY_X1], [TLKEY_X0, TLKEY_X1]]

    def groove_notches():
        return [translate([g0, CIRCLIP_GROOVE_D / 2 if s > 0 else -R - 1], square([CIRCLIP_GROOVE_W, R - CIRCLIP_GROOVE_D / 2 + 1])) for s in (-1, 1)]

    return union(
        difference(                                                                              # side view (key side up)
            translate([0, -R], square([L, 2 * R])),
            groove_notches(),
            [translate([k[0] - OUT_X0, R - SHAFT_KEY_D], square([k[1] - k[0], SHAFT_KEY_D + 1])) for k in keys]),
        translate([0, -2 * R - 15], difference(                                                  # plan view: the two keyway slots and the groove notches
            translate([0, -R], square([L, 2 * R])),
            groove_notches(),
            [hull([translate([x, 0], circle(d=SHAFT_KEY_W)) for x in (k[0] - OUT_X0 + SHAFT_KEY_W / 2, k[1] - OUT_X0 - SHAFT_KEY_W / 2)])
             for k in keys])))


# ---------------- gearbox rails (2 x flat 50 x 10, slotted along x) on 4 spacer blocks; the feet bolt through the slots, the rails bolt down through the deck
def rail_local_2d():
    """x relative to the housing centre, y relative to the rail centre line."""
    half = GB_RAIL_BOLT_DX + GB_RAIL_END
    return difference(
        translate([-half, -GB_RAIL_W / 2], square([2 * half, GB_RAIL_W])),
        [translate([sx * GB_FOOT[0] / 2, -RAIL_FOOT_DY], hull([translate([d, 0], circle(d=9)) for d in (-GB_RAIL_SLOT, GB_RAIL_SLOT)]))
         for sx in (-1, 1)],                                                                     # slots 9 x 21 (rail A; rail B is its mirror image)
        [translate([sx * GB_RAIL_BOLT_DX, 0], circle(d=9)) for sx in (-1, 1)])                   # deck bolts


def gb_rail_at(i):
    """Rail B = rail A mirrored (OpenSCAD's mirror([0, 0, 0]) of rail A is the identity)."""
    rail = linear_extrude(GB_RAIL_T, rail_local_2d())
    return translate([GB_XC, RAIL_YC[i], RAIL_Z0], mirror([0, i, 0], rail) if i else rail)


def gb_spacer_part():
    """Part frame: 18 x 50 x 10, Ø9 in the middle."""
    return difference(
        cube([GB_SPACER_L, GB_RAIL_W, RAIL_SPACER_T]),
        translate([GB_SPACER_L / 2, GB_RAIL_W / 2, -1], cylinder(d=9, h=RAIL_SPACER_T + 2)))


def gb_spacers():
    return union(translate([p[0] - GB_SPACER_L / 2, p[1] - GB_RAIL_W / 2, DECK_TOP], part("Rail spacer block", gb_spacer_part())) for p in RAIL_BOLT_PTS)


def gb_rails():
    return union(part(f"Gearbox rail {'AB'[i]}", gb_rail_at(i)) for i in (0, 1))


def gb_mount():
    return union(gb_rails(), gb_spacers())


# ---------------- motor, pulleys, belt (placeholders)
MOTOR_WELD = 0.01      # in the .scad the Ø120 body only TOUCHES the top of its foot plate, along a line (tangent): no solid.
#                        Here the foot plate is this much higher, so that it runs into the body and the motor is one solid.


def motor_ph():
    return part("Motor",
                translate([XM, Y_HF, ZM], rotate([-90, 0, 0], cylinder(d=MOTOR_D, h=MOTOR_LEN))),
                translate([XM - MOTOR_FOOT[0] / 2, Y_HF + (MOTOR_LEN - MOTOR_FOOT[1]) / 2, DECK_TOP],
                          cube([MOTOR_FOOT[0], MOTOR_FOOT[1], MOTOR_FOOT[2] + MOTOR_WELD])))


def pulley_ph(x, d, bore):
    """Bored to its shaft."""
    return translate([x, Y_HF - PUL_Y0 - PUL_W, ZM], rotate([-90, 0, 0], difference(
        cylinder(d=d, h=PUL_W), translate([0, 0, -1], cylinder(d=bore + 0.1, h=PUL_W + 2)))))


def pulleys_ph():
    return union(pulley_ph(XG, GEARBOX_PULLEY_D, 19), pulley_ph(XM, MOTOR_PULLEY_D, 12))


def motor_shaft_ph():
    return translate([XM, Y_HF - PUL_Y0 - PUL_W, ZM], rotate([-90, 0, 0], cylinder(d=12, h=PUL_Y0 + PUL_W + 5)))


def belt_ph():
    """A 3 mm thick stadium loop round the two pulleys."""
    return translate([0, Y_HF - PUL_Y0 - PUL_W / 2 - BELT_WIDTH / 2, 0], rotate([-90, 0, 0], linear_extrude(BELT_WIDTH, difference(
        hull(translate([XG, -ZM], circle(d=GEARBOX_PULLEY_D + 6)), translate([XM, -ZM], circle(d=MOTOR_PULLEY_D + 6))),
        hull(translate([XG, -ZM], circle(d=GEARBOX_PULLEY_D)), translate([XM, -ZM], circle(d=MOTOR_PULLEY_D)))))))


# ---------------- drive deck: REAL 18 mm plywood under the motor, the rails and the tensioner base, on 4 timber legs (45 x 45)
# Outline = motor foot / rails / tensioner base + margins, stretched toward -y so that the belt guard's four feet land on it.
# Holes: 8 x Ø4.2 pilots (belt guard feet), 8 x Ø5.5 (leg screws), 4 x Ø9 (rail bolts), 4 x Ø9 (tensioner base bolts),
# 8 x Ø9 (top-angle bolts).  The motor's own slots are not drilled.
assert DECK_LEG_LEN >= DRIVE_LEG_MIN, f"drive deck legs too short ({DECK_LEG_LEN} < {DRIVE_LEG_MIN}): CHAIN_CD too long for the floor"
assert DECK_X1 < -30


def bg_foot_screw_uw():
    """The ONE definition of the foot screw positions (guard frame u, w)."""
    return [[uc + du, BG_W + BG_FOOT_REACH / 2] for uc in BG_FOOT_U for du in (-BG_FOOT_DU, BG_FOOT_DU)]


def bg_foot_pts():
    """The same in the world (x, y): deck pilots."""
    return [[XG - q[0], Y_HF - q[1]] for q in bg_foot_screw_uw()]


def deck_leg_screw_xy():
    """Leg screws, 17 mm in from the leg centre toward the deck middle."""
    return [[c[0] + dx, c[1] + (17 if c[1] < 0 else -17)] for c in DECK_LEG_C for dx in (-10, 10)]


def drive_deck_2d():
    return difference(
        translate([DECK_X0, DECK_Y0], square([DECK_X1 - DECK_X0, DECK_Y1 - DECK_Y0])),
        [translate(p, circle(d=4.2)) for p in bg_foot_pts()],                  # M5 wood screw pilots (belt guard feet)
        [translate(p, circle(d=5.5)) for p in deck_leg_screw_xy()],            # M5 leg screws (pilots Ø3.5 in the timber, deck_legs())
        [translate(p, circle(d=9)) for p in RAIL_BOLT_PTS],                    # rail bolts
        [translate(p, circle(d=9)) for p in TENS_BOLT_PTS],                    # tensioner base bolts
        [translate(p, circle(d=9)) for p in TOPANG_DECK_PTS])                  # top-angle bolts


def drive_deck():
    return part("Drive deck", translate([0, 0, DECK_Z0], linear_extrude(DECK_T, drive_deck_2d())))


def legpts(c, pts):
    return [q for q in pts if abs(q[0] - c[0]) <= LEG_SECTION / 2 + 0.01 and abs(q[1] - c[1]) <= LEG_SECTION / 2 + 0.01]


def leg_name(c):
    """Which corner of the deck: the motor is at the -x end, the belt (front) side is -y."""
    return f"{'motor' if leg_sx(c) > 0 else 'gearbox'} end, {'front' if leg_sy(c) < 0 else 'back'}"


def deck_legs():
    """(The .scad cuts every leg with the pilots of all four legs; only the leg's own two are cut here.)"""
    return union(part(f"Deck leg ({leg_name(c)})", difference(
        translate([c[0] - LEG_SECTION / 2, c[1] - LEG_SECTION / 2, DRIVE_FLOOR_Z], cube([LEG_SECTION, LEG_SECTION, DECK_LEG_LEN])),
        [translate([p[0], p[1], DECK_Z0 - 30], cylinder(d=3.5, h=31)) for p in legpts(c, deck_leg_screw_xy())],   # pilots for the leg screws, from the top
        [translate([p[0], c[1] - LEG_SECTION / 2 - 1, TOPANG_LEG_Z], rotate([-90, 0, 0], cylinder(d=9, h=LEG_SECTION + 2)))
         for p in legpts(c, TOPANG_LEG_PTS)],                                                                      # top-angle bolts (along y)
        [translate([c[0] - LEG_SECTION / 2 - 1, p[1], FOOTANG_LEG_Z], rotate([0, 90, 0], cylinder(d=9, h=LEG_SECTION + 2)))
         for p in legpts(c, FOOTANG_LEG_PTS)])) for c in DECK_LEG_C)                                               # foot-angle bolts (along x)


def deck_ph():
    return drive_deck()                                                         # what the guard checks see


# ---------------- leg angles: 40 x 40 x 4 steel angle.  Part frame: corner at the origin, length along +x, vertical flange
# y' 0..4 / z 0..40, horizontal flange z 0..4 / y' 0..40.
# Holes: horizontal flange 2 x Ø9 (x = L/2 +-11, y' = 22), vertical flange 2 x Ø9 (x = L/2 +-11, z = 22).
def leg_angle():
    return difference(
        union(cube([ANG_L, ANG_T, ANG_W]), cube([ANG_L, ANG_W, ANG_T])),
        [translate([ANG_L / 2 + d, 22, -1], cylinder(d=9, h=ANG_T + 2)) for d in (-11, 11)],
        [translate([ANG_L / 2 + d, -1, 22], rotate([-90, 0, 0], cylinder(d=9, h=ANG_T + 2))) for d in (-11, 11)])


def top_angle_at(c):
    """Corner at the top, flange under the deck pointing out (+-y)."""
    sy = leg_sy(c)
    return multmatrix([[1, 0, 0, c[0] - ANG_L / 2], [0, sy, 0, c[1] + sy * (LEG_SECTION / 2 + HW_GAP)], [0, 0, -1, DECK_Z0 - HW_GAP], [0, 0, 0, 1]],
                      part(f"Top angle ({leg_name(c)})", leg_angle()))


def foot_angle_at(c):
    """Corner at the floor, flange on the floor pointing inward (+-x)."""
    sx = leg_sx(c)
    return multmatrix([[0, sx, 0, c[0] + sx * (LEG_SECTION / 2 + HW_GAP)], [1, 0, 0, c[1] - ANG_L / 2], [0, 0, 1, DRIVE_FLOOR_Z + HW_GAP], [0, 0, 0, 1]],
                      part(f"Foot angle ({leg_name(c)})", leg_angle()))


def top_angles():
    return union(top_angle_at(c) for c in DECK_LEG_C)


def foot_angles():
    return union(foot_angle_at(c) for c in DECK_LEG_C)


# (floor_ph(), the ghost floor / bench top slab, is a picture only: not translated.)


# ---------------- hardware placeholders: M8 hex bolts (washer + head on the near side, washer + nut on the far side), generic along a local +w axis
# local frame: origin on the bearing face of the head side, +w toward the nut; grip = clamped thickness; wd/wt = head-side washer, wd2/wt2 = nut-side washer
def orient(d, *ch):
    d = list(d)
    if d == [0, 0, -1]:
        return rotate([180, 0, 0], *ch)
    if d == [0, 1, 0]:
        return rotate([-90, 0, 0], *ch)
    if d == [0, -1, 0]:
        return rotate([90, 0, 0], *ch)
    if d == [1, 0, 0]:
        return rotate([0, 90, 0], *ch)
    if d == [-1, 0, 0]:
        return rotate([0, -90, 0], *ch)
    return union(*ch)


def m8_ph(grip, wd=16, wt=1.6, wd2=16, wt2=1.6, name="M8 bolt"):
    """`name` = the bolt's body name.  Bodies: the bolt (head + shank), two washers and the nut (bored by the shank)."""
    shank = translate([0, 0, -HW_GAP - wt - 5.3 + 0.01],
                      cylinder(d=8, h=5.3 + wt + HW_GAP + grip + HW_GAP + wt2 + HW_GAP + 6.8 + 0.5))                 # shank to 0.5 mm past the nut
    return union(
        part(f"M8 washer {wd:g} x {wt:g}", difference(translate([0, 0, -HW_GAP - wt], cylinder(d=wd, h=wt)), shank)),   # washer under the head
        part(name, translate([0, 0, -HW_GAP - wt - 5.3], cylinder(d=14.4, h=5.3, fn=6)), shank),                     # head + shank
        part(f"M8 washer {wd2:g} x {wt2:g}", difference(translate([0, 0, grip + HW_GAP], cylinder(d=wd2, h=wt2)), shank)),   # washer under the nut
        part("M8 nut", difference(translate([0, 0, grip + HW_GAP + wt2 + HW_GAP], cylinder(d=14.4, h=6.8, fn=6)), shank)))    # nut


def m8_at(p, d, grip, wd=16, wt=1.6, wd2=16, wt2=1.6, name="M8 bolt"):
    return translate(p, orient(d, m8_ph(grip, wd, wt, wd2, wt2, name)))


def gb_foot_bolts_ph():
    """Flange 8 + rail 10, nut under the rail."""
    return union(m8_at([p[0], p[1], GB_FZ1], [0, 0, -1], GB_FLANGE[2] + GB_RAIL_T, name="M8 gearbox foot bolt") for p in gb_foot_pts())


def rail_bolts_ph():
    """M8 x 55 through rail, spacer, deck; Ø24 penny washer + nut under the deck."""
    return union(m8_at([p[0], p[1], RAIL_Z1], [0, 0, -1], GB_RAIL_T + RAIL_SPACER_T + DECK_T, 16, 1.6, BIG_WASHER_D, BIG_WASHER_T,
                       name="M8 x 55 rail bolt") for p in RAIL_BOLT_PTS)


def topang_deck_bolts_ph():
    """Head + Ø20 washer on the deck, nut under the angle."""
    return union(m8_at([p[0], p[1], DECK_Z1], [0, 0, -1], DECK_T + HW_GAP + ANG_T, 20, 2, 16, 1.6, name="M8 top-angle deck bolt")
                 for p in TOPANG_DECK_PTS)


def topang_leg_bolts_ph():
    return union(m8_at([p[0], p[1] + leg_sy(c) * (HW_GAP + ANG_T), TOPANG_LEG_Z], [0, -leg_sy(c), 0], ANG_T + HW_GAP + LEG_SECTION, 16, 1.6, 20, 2,
                       name="M8 top-angle leg bolt") for c in DECK_LEG_C for p in legpts(c, TOPANG_LEG_PTS))


def footang_leg_bolts_ph():
    return union(m8_at([p[0] + leg_sx(c) * (HW_GAP + ANG_T), p[1], FOOTANG_LEG_Z], [-leg_sx(c), 0, 0], ANG_T + HW_GAP + LEG_SECTION, 16, 1.6, 20, 2,
                       name="M8 foot-angle leg bolt") for c in DECK_LEG_C for p in legpts(c, FOOTANG_LEG_PTS))


def anchors_ph():
    """M8 anchor: hex head + washer on the foot angle's flange, shank down through the angle into the floor."""
    shank = translate([0, 0, -ANG_T - 2 * HW_GAP - FLOOR_T], cylinder(d=DECK_ANCHOR_D, h=ANG_T + 2 * HW_GAP + FLOOR_T + 1.7))
    return union(translate([p[0], p[1], DRIVE_FLOOR_Z + HW_GAP + ANG_T + HW_GAP],
                           part("M8 washer 16 x 1.6", difference(cylinder(d=16, h=1.6), shank)),
                           part("M8 floor anchor", translate([0, 0, 1.6], cylinder(d=14.4, h=5.3, fn=6)), shank)) for p in ANCHOR_PTS)


def holddown_hw_ph():
    return union(topang_deck_bolts_ph(), topang_leg_bolts_ph(), footang_leg_bolts_ph(), anchors_ph())


# the old name used by the tensioner base bolts: M8 from above through the part at ztop and the deck
def m8_nut_washer_under(p, shank=None):
    """Nut + washer under the deck (bored by `shank`, the bolt they sit on, when it is given)."""
    return translate([p[0], p[1], DECK_Z0 - HW_GAP - 1.6 - 8 - HW_GAP],
                     part("M8 nut", difference(cylinder(d=14.4, h=8, fn=6), shank)),
                     part("M8 washer 16 x 1.6", difference(translate([0, 0, 8 + HW_GAP], cylinder(d=16, h=1.6)), shank)))


def m8_bolt(p, ztop):
    """Washer 1.6 + head 5.3 on the part top at ztop, shank (Ø8) down through part + deck to the nut under the deck."""
    z0 = DECK_Z0 - 8 - 1.6 - 4
    shank = translate([p[0], p[1], z0], cylinder(d=8, h=ztop + HW_GAP + 1.6 + 5.3 - z0))
    under = DECK_Z0 - HW_GAP - 1.6 - 8 - HW_GAP                                      # the shank in the frame of m8_nut_washer_under
    return union(
        part("M8 tensioner base bolt", translate([p[0], p[1], ztop + HW_GAP + 1.6], cylinder(d=14.4, h=5.3, fn=6)), shank),
        part("M8 washer 16 x 1.6", difference(translate([p[0], p[1], ztop + HW_GAP], cylinder(d=16, h=1.6)), shank)),
        m8_nut_washer_under(p, translate([-p[0], -p[1], -under], shank)))


def tens_bolts_ph():
    return union(m8_bolt(p, TENS_BASE_Z1) for p in TENS_BOLT_PTS)


# ---------------- chain: a band (width CHAIN_ENV_W over the pins, link plate height CHAIN_ENV_H) round the pitch circles of A, the TL sprocket and the idler.
# All three circles are inside the loop, so the path is the convex hull of the three pitch circles.  ty = idler offset along its slot (mm), grow = extra clearance all round.
def chain_band2d(ty=0, grow=0):
    return difference(offset(hull(chain_circles2d(ty)), delta=CHAIN_ENV_H / 2 + grow),
                      offset(hull(chain_circles2d(ty)), delta=-(CHAIN_ENV_H / 2 + grow)))


def chain_band(ty=0, grow=0):
    return axial(X_CHAIN - CHAIN_ENV_W / 2 - grow, linear_extrude(CHAIN_ENV_W + 2 * grow, chain_band2d(ty, grow)))


def chain_swept(grow=0):
    """Idler anywhere in its slot: the .scad's union of chain_band(ty, grow) for ty = -TENS_TRAVEL, 0, TENS_TRAVEL.

    The three bands share most of their faces (a join of them fails), and each step of the idler (TENS_TRAVEL) is less than
    the band's thickness, so there is no gap between one band and the next: their union is ONE band, outside = the outside
    of the band at +TENS_TRAVEL, inside = the inside of the band at -TENS_TRAVEL.  That band is built here.
    """
    half = CHAIN_ENV_H / 2 + grow
    assert TENS_TRAVEL <= 2 * half, "the chain bands at -TENS_TRAVEL, 0, +TENS_TRAVEL must overlap"
    return axial(X_CHAIN - CHAIN_ENV_W / 2 - grow, linear_extrude(CHAIN_ENV_W + 2 * grow, difference(
        offset(hull(chain_circles2d(TENS_TRAVEL)), delta=half),
        offset(hull(chain_circles2d(-TENS_TRAVEL)), delta=-half))))


# ---------------- sprocket A, idler, tensioner (rotating sprockets, as full discs)
def sprocket_a_env(grow=0):
    """Hub + tooth plate of sprocket A as plain cylinders (swept over any angle)."""
    return translate([0, YA, 0],
                     axial(x_sprocket_out - grow, cylinder(d=SPROCKET_A_hub_D + 2 * grow, h=SPROCKET_A_hub_L + 2 * grow)),
                     axial(x_sprocket_out - grow, cylinder(d=SPA_OD_ + 2 * grow, h=SPROCKET_T + 2 * grow)))


def tens_idler_ph(ty=0):
    """Idler assembly at slot offset ty: disc (tooth plate OD 67.3 x 7.2 in the chain plane) + spacer tube to the upright."""
    return translate([0, tens_y(ty), TENS_Z],
                     axial(TL_PL0, part("Idler sprocket #40 15T", difference(
                         cylinder(d=SPA_OD_, h=SPROCKET_T), translate([0, 0, -1], cylinder(d=10.2, h=SPROCKET_T + 2))))),      # idler sprocket
                     axial(TL_PL1, part("Idler spacer tube", difference(
                         cylinder(d=TENS_SPACER_D, h=TENS_UP_X0 - TL_PL1 - HW_GAP),
                         translate([0, 0, -1], cylinder(d=10.2, h=TENS_UP_X0 - TL_PL1 + 2))))))                                # spacer tube (0.01 short of the upright)


def tens_bolt_ph(ty=0):
    """M10 bolt, washer under the head, washer 0.5 behind the idler, nut.  The shank is flush under the head (the .scad
    pushes it 0.01 into the head); the hole in the washers and the nut keeps that overshoot."""
    x_head = TENS_UP_X1 + HW_GAP + TENS_WASHER_T
    x_end = TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3
    shank = axial(x_end, cylinder(d=TENS_AXLE_D, h=x_head - x_end))
    hole = axial(x_end, cylinder(d=TENS_AXLE_D, h=x_head - x_end + 0.01))
    washer = f"M10 washer {TENS_WASHER_D:g} x {TENS_WASHER_T:g}"
    return translate([0, tens_y(ty), TENS_Z],
                     part("M10 idler axle bolt", axial(x_head, cylinder(d=TENS_HEAD_D, h=TENS_HEAD_H_, fn=6)), shank),                    # M10 head + shank
                     part(washer, difference(axial(TENS_UP_X1 + HW_GAP, cylinder(d=TENS_WASHER_D, h=TENS_WASHER_T)), hole)),                # washer under the head
                     part(washer, difference(axial(TL_PL0 - 0.5 - TENS_WASHER_T, cylinder(d=TENS_WASHER_D, h=TENS_WASHER_T)), hole)),       # washer 0.5 behind the idler
                     part("M10 nut", difference(axial(TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H, cylinder(d=TENS_HEAD_D, h=TENS_NUT_H, fn=6)), hole)))   # nut


def tens_upright_2d():
    """(y, z); x-thickness TENS_T.  L-shape: HEAD plate (carries the slot ALONG y for the M10 axle) + COLUMN down to the base, outside the chain guard."""
    return difference(
        union(translate([TENS_HEAD_Y0, TENS_HEAD_Z0], square([TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_HEAD_Z0])),
              translate([TENS_COL_Y0, TENS_BASE_Z1], square([TENS_COL_W, TENS_UP_Z1 - TENS_BASE_Z1]))),
        hull([translate([TENS_Y0 + s * TENS_TRAVEL, TENS_Z], circle(d=TENS_SLOT_W)) for s in (-1, 1)]))


def tens_upright():
    return part("Tensioner upright", axial(TENS_UP_X0, linear_extrude(TENS_T, tens_upright_2d())))


def tens_base_2d():
    """(x, y); 10 thick."""
    return difference(
        translate([TENS_BASE_X0, TENS_BASE_Y0], square([TENS_BASE[0], TENS_BASE_Y])),
        [translate(p, circle(d=9)) for p in TENS_BOLT_PTS])


def tens_base():
    return part("Tensioner base plate", translate([0, 0, TENS_BASE_Z0], linear_extrude(TENS_BASE_Z1 - TENS_BASE_Z0, tens_base_2d())))


# ---------------- swept envelopes of the moving parts (full cylinders: any angle), every dimension grown by g (radially, and along x at both ends)
def cylx(r, x0, x1, y=0, z=0):
    return translate([x0, y, z], rotate([0, 90, 0], cylinder(r=r, h=x1 - x0)))


def drive_end_env(g=0, sprocket=True, shafts=("A", "B")):
    def one(s):
        y = shaft_y(s)
        xe = end_x_drive(s)
        return union(
            cylx(GEAR_module * (GEAR_z + 2) / 2 + g, x_gear_out - g, x_gear_in + g, y),                 # gear (4 layers, OD 63.0; no hub)
            cylx(GEAR_SPACER_D / 2 + g, x_gear_hub_out - g, x_gear_out + g, y),                         # gear spacer sleeve
            cylx(COLLAR_OD / 2 + g, x_collar_out_drive - g, x_collar_in_drive + g, y),                  # collar
            cylx(THRUST_D / 2 + g, x_collar_in_drive - g, x_cap_out_drive + g, y),                      # thrust bearing
            cylx(15 + g, xe - END_WASHER_T - g, xe + g, y),                                             # end cap
            cylx(8 + g, xe - END_WASHER_T - 10 - g, xe - END_WASHER_T + g, y),                          # M10 head
            [cylx(SPROCKET_A_hub_D / 2 + g, x_sprocket_out - g, x_sprocket_in + g, y),                  # sprocket hub
             cylx(SPA_OD_ / 2 + g, x_sprocket_out - g, x_sprocket_out + SPROCKET_T + g, y)]             # tooth plate
            if s == "A" and sprocket else None)

    return union(one(s) for s in shafts)


def tl_env(g=0):
    """TL350 body, tooth plate, spacer, stop collar, shaft end (static, but the guard hugs it)."""
    return union(cylx(TL_D / 2 + g, TL_X0 - g, TL_X1 + g, YA, ZO),
                 cylx(TL_OD_ / 2 + g, TL_PL0 - g, TL_PL1 + g, YA, ZO),
                 cylx(OUT_SPACER_D / 2 + g, GB_X1 - g, TL_X0 + g, YA, ZO),
                 cylx(TL_COLLAR_D / 2 + g, TL_COLLAR_X0 - g, TL_COLLAR_X1 + g, YA, ZO),
                 cylx(JOURNAL_D / 2 + g, TL_COLLAR_X0 - g, OUT_X1 + g, YA, ZO))


def idler_env(g=0, ty=0):
    """Idler sprocket, spacer, bolt head / washers / nut, shank, at slot offset ty."""
    y = tens_y(ty)
    return union(cylx(SPA_OD_ / 2 + g, TL_PL0 - g, TL_PL1 + g, y, TENS_Z),
                 cylx(TENS_SPACER_D / 2 + g, TL_PL1 - g, TENS_UP_X0 + g, y, TENS_Z),
                 cylx(TENS_WASHER_D / 2 + g, TENS_UP_X1 - g, TENS_UP_X1 + TENS_WASHER_T + TENS_HEAD_H_ + 0.02 + g, y, TENS_Z),     # washer + head (head Ø16 inside)
                 cylx(TENS_WASHER_D / 2 + g, TL_PL0 - 0.5 - TENS_WASHER_T - TENS_NUT_H - 3 - g, TL_PL0 - g, y, TENS_Z))            # washer, nut, bolt end behind the idler


def chain_drive_env(g=0):
    return union(tl_env(g), [idler_env(g, ty) for ty in (-TENS_TRAVEL, 0, TENS_TRAVEL)], chain_swept(g))


def tensioner_ph(ty=0):
    return union(tens_upright(), tens_base(), tens_idler_ph(ty), tens_bolt_ph(ty))


def drive_gearbox_ph():
    return union(gearbox_ph(), worm_ph(), output_shaft_ph(), tl_ph(), shaft_hw_ph(), gb_mount())


# ---------------- belt guard: two printed halves with a 16 mm LAP, bolted to the deck by 2 feet each
# u runs from the gearbox pulley axis toward the motor (world -x), v = world z - ZW, w = distance in front of the housing (-y).
# LAP     the gearbox half (A) runs on to u = U1 = 141 with a 6 mm thicker roof in the lap zone (room for 6 mm deep heat-set
#         inserts); the motor half (B) has a sleeve over A for u = 125 .. 141 (0.3 mm gap, 2.7 mm walls, open at the back)
#         ending in a solid shoulder that butts against A's end face.  3 x M4 x 8 go through B's sleeve roof (Ø4.5) into
#         3 x Ø5.6 x 6 inserts in A's roof pad.  The screws are on the front (roof) face: the guard comes apart from outside.
# FEET    each half has two printed feet: a 36 x 4 flange on the deck in front of the guard roof (2 x M5 x 20 wood screws
#         into the 18 mm plywood deck, blind, reachable from above) carried by 3 mm ribs with a gusset, merged into the
#         guard's lower wall.
BG_R1 = GEARBOX_PULLEY_D / 2 + BELT_GUARD_CLEAR
BG_R2 = MOTOR_PULLEY_D / 2 + BELT_GUARD_CLEAR
BG_SPLIT = BELT_CENTRE_DIST / 2
BG_LAP = BG_LAP_LEN
BG_U1 = BG_SPLIT + BG_LAP                                       # lap zone u = 125 .. 141
BG_PAD = 6                                                      # roof pad of A in the lap zone (inserts live here)
BG_SLV = 2.7                                                    # sleeve wall
BG_RS_IN = BG_WALL + BG_LAP_CLEAR                               # sleeve inner / outer offset from the cavity: 3.3 / 6.0
BG_RS_OUT = BG_RS_IN + BG_SLV
BG_WS_IN = BG_W + BG_PAD + BG_LAP_CLEAR                         # sleeve roof inner / outer w: 58.3 / 61.0
BG_WS_OUT = BG_WS_IN + BG_SLV
BG_SCREW_V = [-24, 0, 24]
BG_SCREW_U = BG_SPLIT + BG_LAP / 2
BG_FOOT_U = [15, 95, 180, 245]                                  # foot centres (u): feet 0, 1 on half A, feet 2, 3 on half B
BG_FOOT_VF = DECK_TOP - ZW                                      # v of the deck top, -70
BG_FOOT_DU = 8
BG_FOOT_RIB = 3
BG_FOOT_W0 = 12
assert BG_LAP >= 15


def bg_cavity2d():
    return hull(circle(r=BG_R1), translate([BELT_CENTRE_DIST, 0], circle(r=BG_R2)))


def bg_ring2d(t):
    return hull(circle(r=BG_R1 + t), translate([BELT_CENTRE_DIST, 0], circle(r=BG_R2 + t)))


def bg_shell2d():
    return bg_ring2d(BG_WALL)


def bg_vbot(u):
    """Outer bottom of the hull."""
    R0, R1 = BG_R1 + BG_WALL, BG_R2 + BG_WALL
    sa = (R0 - R1) / BELT_CENTRE_DIST
    return (u * sa - R0) / sqrt(1 - sa * sa)


def bg_whole_uvw():
    """Whole guard in the (u, v, w) frame: w = 0 at the housing face."""
    return difference(
        linear_extrude(BG_W, bg_shell2d()),
        translate([0, 0, BG_BACK], linear_extrude(BG_W - BG_BACK - BG_WALL, bg_cavity2d())),
        translate([0, 0, -1], cylinder(d=30, h=BG_BACK + 2)),                                # gearbox input shaft (Ø19 stub)
        translate([BELT_CENTRE_DIST, 0, -1], cylinder(d=28, h=BG_BACK + 2)))                 # motor shaft


def bg_slab(u0, u1):
    return translate([u0, -200, -1], cube([u1 - u0, 400, 200]))


def bg_foot(uc):
    """One mounting foot (flange + 3 ribs + gussets) at u = uc, in the uvw frame."""
    vf = BG_FOOT_VF
    w1 = BG_W + BG_FOOT_REACH
    vb = bg_vbot(uc)
    return difference(
        union(translate([uc - BG_FOOT_W / 2, vf, BG_FOOT_W0], cube([BG_FOOT_W, BG_FOOT_T, w1 - BG_FOOT_W0])),            # flange on the deck
              [multmatrix([[0, 0, 1, uc + du * (BG_FOOT_W / 2 - BG_FOOT_RIB / 2) - BG_FOOT_RIB / 2], [0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 0, 1]],
                          linear_extrude(BG_FOOT_RIB, polygon([[BG_FOOT_W0, vf], [w1, vf], [BG_W, vb + 1], [BG_W, -10], [BG_FOOT_W0, -10]])))
               for du in (-1, 0, 1)]),                                                                                    # 3 ribs + gussets (polygon in w, v; extruded along u)
        # keep the guard cavity clear: nothing of the rib may enter the wall's inside
        translate([0, 0, -1], linear_extrude(BG_W + 2, bg_ring2d(BG_WALL - 1.2))),
        [translate([q[0], vf - 1, q[1]], rotate([-90, 0, 0],                                                              # M5 clearance + countersink
                                                cylinder(d=5.5, h=BG_FOOT_T + 2),
                                                translate([0, 0, BG_FOOT_T - 1.6 + 1], cylinder(d1=5.5, d2=10.5, h=1.61))))
         for q in bg_foot_screw_uw() if abs(q[0] - uc) < BG_FOOT_DU + 0.01])


# KEEP-OUT: the chain guard (dg_lower: hull of the chain circles grown GUARD_CLEAR + PRINT_WALL, from the housing face) and the
# chain itself cross the gearbox half's round cap, because the TL350 sprocket is only 15 mm from the housing face and the Ø68
# pulley sits at the housing's middle.  The cap is cut away there (0.3 mm off the chain guard's outside); the chain guard's wall
# closes the opening.
def bg_keepout_world():
    return axial(GB_X1 - 0.3, linear_extrude(60, chain_hull2d(GUARD_CLEAR + PRINT_WALL + 0.3)))


def bg_keepout_uvw():
    """World (x, y, z) -> guard frame (u, v, w)."""
    return multmatrix([[-1, 0, 0, XG], [0, 0, 1, -ZW], [0, -1, 0, Y_HF], [0, 0, 0, 1]], bg_keepout_world())


def bg_half_uvw(h):
    """h = 0: gearbox half A, h = 1: motor half B.  The pieces of a half meet on exact shared faces (the .scad overlaps them by 0.01)."""
    if h == 0:
        return difference(
            union(intersection(bg_whole_uvw(), bg_slab(-200, BG_U1)),
                  intersection(translate([0, 0, BG_W], linear_extrude(BG_PAD, bg_shell2d())),              # roof pad in the lap zone
                               bg_slab(BG_SPLIT, BG_U1)),
                  [bg_foot(BG_FOOT_U[i]) for i in (0, 1)]),
            [translate([BG_SCREW_U, v, BG_W + BG_PAD - INSERT_DEPTH], cylinder(d=INSERT_D, h=INSERT_DEPTH + 1)) for v in BG_SCREW_V],   # M4 heat-set inserts
            bg_keepout_uvw())
    return difference(
        union(intersection(bg_whole_uvw(), bg_slab(BG_U1 + BG_SLV, 400)),
              intersection(difference(linear_extrude(BG_WS_OUT, bg_ring2d(BG_RS_OUT)),                     # shoulder: solid, butts against A's end face
                                      translate([0, 0, BG_BACK], linear_extrude(BG_W - BG_BACK - BG_WALL, bg_cavity2d()))),
                           bg_slab(BG_U1, BG_U1 + BG_SLV)),
              intersection(difference(linear_extrude(BG_WS_OUT, bg_ring2d(BG_RS_OUT)),                     # sleeve over A: open at the back
                                      translate([0, 0, -1], linear_extrude(BG_WS_IN + 1, bg_ring2d(BG_RS_IN)))),
                           bg_slab(BG_SPLIT, BG_U1)),
              [bg_foot(BG_FOOT_U[i]) for i in (2, 3)]),
        [translate([BG_SCREW_U, v, BG_WS_IN - 1], cylinder(d=4.5, h=BG_SLV + 2)) for v in BG_SCREW_V])                   # M4 clearance holes


def bg_uvw_to_world(*ch):
    return multmatrix([[-1, 0, 0, XG], [0, 0, -1, Y_HF], [0, 1, 0, ZW], [0, 0, 0, 1]], *ch)


def belt_guard(h):
    return bg_uvw_to_world(part("Belt guard, motor half (B)" if h else "Belt guard, gearbox half (A)", bg_half_uvw(h)))


def belt_guard_hw_ph():
    return bg_uvw_to_world(
        [translate([BG_SCREW_U, v, BG_WS_OUT], part("M4 x 10 button head screw",                                # (shank flush under the head: no 0.01 weld)
                                                    cylinder(d=7.5, h=2.4), translate([0, 0, -10], cylinder(d=4, h=10))))
         for v in BG_SCREW_V],
        [translate([q[0], BG_FOOT_VF + BG_FOOT_T, q[1]], rotate([90, 0, 0], part("M5 x 20 wood screw (CSK)",
                                                                                 translate([0, 0, -3], cylinder(d=9.5, h=3)), cylinder(d=5, h=20 + 0))))
         for q in bg_foot_screw_uw()])


# ---------------- check helper: a thin slab across the guard at u0 .. u1, in world coordinates
def bg_probe_slab(u0, u1):
    return bg_uvw_to_world(translate([u0, -300, -10], cube([u1 - u0, 600, 300])))


# ---------------- accessors for checks / guards
def deck_geom():
    return [DECK_X0, DECK_X1, DECK_Y0, DECK_Y1, DECK_Z0, DECK_Z1]


def worm_axis():
    return [XG, ZW]


def motor_axis_z():
    return ZM


def gb_mount_box():
    return [[RAIL_X0, RAIL_Y_LO, DECK_TOP], [RAIL_X1 - RAIL_X0, RAIL_Y_HI - RAIL_Y_LO, SUBPLATE_T]]


def tens_upright_box():
    """Bounding box (C5 shrink centre)."""
    return [[TENS_UP_X0, TENS_HEAD_Y0, TENS_BASE_Z1], [TENS_T, TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_BASE_Z1]]


def tens_upright_boxes():
    return [[[TENS_UP_X0, TENS_HEAD_Y0, TENS_HEAD_Z0], [TENS_T, TENS_COL_Y1 - TENS_HEAD_Y0, TENS_UP_Z1 - TENS_HEAD_Z0]],        # head plate
            [[TENS_UP_X0, TENS_COL_Y0, TENS_BASE_Z1], [TENS_T, TENS_COL_W, TENS_HEAD_Z0 - TENS_BASE_Z1]]]                      # column


def tens_base_box():
    return [[TENS_BASE_X0, TENS_BASE_Y0, TENS_BASE_Z0], [TENS_BASE[0], TENS_BASE_Y, TENS_BASE_Z1 - TENS_BASE_Z0]]


# ---------------- joint alignment shanks (checks C16): a bolt shank through the hole of part 1 AND the hole of part 2; it must touch neither part's material
def bg_foot_shanks():
    """M5 wood screw core: guard foot Ø5.5 + deck pilot Ø4.2."""
    return union(translate([p[0], p[1], DECK_Z0 + 2], cylinder(d=4, h=DECK_T + BG_FOOT_T + 4)) for p in bg_foot_pts())


def deck_leg_shanks():
    """M5 wood screw core: deck Ø5.5 + leg pilot Ø3.5."""
    return union(translate([p[0], p[1], DECK_Z0 - 29], cylinder(d=3.3, h=DECK_T + 31)) for p in deck_leg_screw_xy())


def gbfoot_shanks():
    """M8: flange Ø9 + rail slot 9."""
    return union(translate([p[0], p[1], RAIL_Z0 - 3], cylinder(d=8, h=GB_RAIL_T + GB_FLANGE[2] + 6)) for p in gb_foot_pts())


def subbolt_shanks():
    """M8: rail Ø9 + spacer Ø9 + deck Ø9."""
    return union(translate([p[0], p[1], DECK_Z0 - 3], cylinder(d=8, h=DECK_T + SUBPLATE_T + 6)) for p in RAIL_BOLT_PTS)


def tbase_shanks():
    """M8: base Ø9 + deck Ø9."""
    return union(translate([p[0], p[1], DECK_Z0 - 3], cylinder(d=8, h=DECK_T + (TENS_BASE_Z1 - TENS_BASE_Z0) + 6)) for p in TENS_BOLT_PTS)


def tens_axle_shanks(ty=0):
    """M10 through the slot (ty = +-10: slot end)."""
    return translate([0, tens_y(ty), TENS_Z], axial(TENS_UP_X0 - 3, cylinder(d=TENS_AXLE_D, h=TENS_T + 6)))


def topdeck_shanks():
    """M8: deck Ø9 + top angle Ø9."""
    return union(translate([p[0], p[1], DECK_Z0 - ANG_T - 3], cylinder(d=8, h=DECK_T + ANG_T + 6)) for p in TOPANG_DECK_PTS)


def topleg_shanks():
    return union(translate([p[0], p[1] + leg_sy(c) * (ANG_T + 3), TOPANG_LEG_Z], orient([0, -leg_sy(c), 0], cylinder(d=8, h=ANG_T + LEG_SECTION + 6)))
                 for c in DECK_LEG_C for p in legpts(c, TOPANG_LEG_PTS))


def footleg_shanks():
    return union(translate([p[0] + leg_sx(c) * (ANG_T + 3), p[1], FOOTANG_LEG_Z], orient([-leg_sx(c), 0, 0], cylinder(d=8, h=ANG_T + LEG_SECTION + 6)))
                 for c in DECK_LEG_C for p in legpts(c, FOOTANG_LEG_PTS))


def anchor_shanks():
    """M8 anchor: foot angle Ø9 + floor hole Ø8.5."""
    return union(translate([p[0], p[1], GROUND_Z - FLOOR_T - 3], cylinder(d=8, h=FLOOR_T + ANG_T + 6 + 0.02)) for p in ANCHOR_PTS)


def r1_(v):
    return round(10 * v) / 10


def anchor_pts_r():
    return [[r1_(p[0]), r1_(p[1])] for p in ANCHOR_PTS]


# ---------------- the standalone renders of drive.scad (-D 'part="..."'): made parts in their part frames, print poses, 2D layouts, the whole drive
def drive_part(sel="world"):
    """`sel` is the .scad's `part` variable ("bom" only echoes text: not here; "world" is without the ghost floor)."""
    if sel == "gb_rail":
        return translate([-RAIL_X0, -RAIL_Y_LO, -RAIL_Z0], gb_rail_at(0))
    if sel == "gb_rail_2d":
        return translate([-RAIL_X0, -RAIL_Y_LO], translate([GB_XC, RAIL_YC[0]], rail_local_2d()))
    if sel == "gb_spacer":
        return gb_spacer_part()
    if sel == "leg_angle":
        return leg_angle()
    if sel == "tens_upright":
        return translate([-TENS_HEAD_Y0, -TENS_BASE_Z1, 0], linear_extrude(TENS_T, tens_upright_2d()))
    if sel == "tens_upright_2d":
        return translate([-TENS_HEAD_Y0, -TENS_BASE_Z1], tens_upright_2d())
    if sel == "tens_base":
        return translate([-TENS_BASE_X0, -TENS_BASE_Y0, -TENS_BASE_Z0], tens_base())
    if sel == "tens_base_2d":
        return translate([-TENS_BASE_X0, -TENS_BASE_Y0], tens_base_2d())
    if sel == "output_shaft":
        return translate([-OUT_X0, 0, 0], output_shaft_local())
    if sel == "output_shaft_2d":
        return output_shaft_2d()
    if sel == "stop_collar":
        return stop_collar_part()
    if sel in ("belt_guard_a", "belt_guard_b"):
        return translate([200, 200, 0], bg_half_uvw(0 if sel == "belt_guard_a" else 1))      # print pose: back wall (w = 0 .. BG_BACK) face down; u along x
    if sel == "drive_deck":
        return translate([-DECK_X0, -DECK_Y0, -DECK_Z0], drive_deck())
    if sel == "drive_deck_2d":
        return translate([-DECK_X0, -DECK_Y0], drive_deck_2d())
    if sel == "world":
        return union(drive_gearbox_ph(), gb_foot_bolts_ph(), rail_bolts_ph(), motor_ph(), pulleys_ph(), belt_ph(), deck_ph(), deck_legs(),
                     top_angles(), foot_angles(), holddown_hw_ph(), tensioner_ph(), tens_bolts_ph(), chain_band(0),
                     belt_guard(0), belt_guard(1), belt_guard_hw_ph())
    return None


# ---------------- the bodies of the assembly
BODIES = {
    "Frame": [
        Body("Worm gearbox NRV063", lambda: gearbox_ph(), GRAY, 0.6),
        Body("Gearbox + rail + tensioner bolts", lambda: union(gb_foot_bolts_ph(), rail_bolts_ph(), tens_bolts_ph(), tens_bolt_ph()), DARK),
        Body("Gearbox rails", lambda: gb_mount(), METAL),
        Body("Chain idler sprocket", lambda: tens_idler_ph(), ORANGE, 0.9),
        Body("Chain tensioner", lambda: union(tens_upright(), tens_base()), RED),
        Body("Chain #40", lambda: chain_band(0), "#444444", 0.9),
        Body("Motor", lambda: motor_ph(), DARK),
        Body("V-belt", lambda: belt_ph(), "#222222", 0.8),
        Body("Belt guard", lambda: union(belt_guard(0), belt_guard(1)), PRINT, 0.55),
        Body("Belt guard hardware", lambda: belt_guard_hw_ph(), DARK),
        Body("Drive deck + legs", lambda: union(drive_deck(), deck_legs()), "#c8a46e", 0.85),
        Body("Leg angles", lambda: union(top_angles(), foot_angles()), METAL),
        Body("Deck + leg bolts", lambda: union(topang_deck_bolts_ph(), topang_leg_bolts_ph(), footang_leg_bolts_ph()), DARK),
        Body("Floor anchors", lambda: anchors_ph(), RED),
    ],
    "Torque limiter + output shaft": [
        Body("Output shaft 4140", lambda: output_shaft_ph(), "#2b6cb0"),
        Body("Torque limiter TL350", lambda: tl_ph(), "#8e6fb0"),
        Body("Circlip, spacer, stop collar", lambda: shaft_hw_ph(), YELLOW),
    ],
    "Worm + gearbox pulley": [
        Body("Worm", lambda: worm_ph(), DARK),
        Body("Gearbox pulley", lambda: pulley_ph(XG, GEARBOX_PULLEY_D, 19), DARK),
    ],
    "Motor shaft + pulley": [
        Body("Motor shaft", lambda: motor_shaft_ph(), DARK),
        Body("Motor pulley", lambda: pulley_ph(XM, MOTOR_PULLEY_D, 12), DARK),
    ],
}


# the made parts of this file as the old pipeline exported them (parts.py) and the outlines of the flat ones
PARTS = {name: (lambda name=name: drive_part(name)) for name in (
    "output_shaft", "belt_guard_a", "belt_guard_b", "drive_deck", "gb_rail", "gb_spacer", "leg_angle",
    "tens_upright", "tens_base")}
# A part of the old list that is not a valid solid as designed (parts.py says so instead of building it).
NOT_BUILT = {"stop_collar": "the two Ø5 tap-drill holes for the M6 grub screws are as wide as the collar is thick "
                            "(TL_COLLAR_T = 5), so they touch both faces along a line: not a solid (the old STL was an "
                            "open mesh too).  It needs a thicker collar or smaller screws; stop_collar_part() holds the design as it is."}
PARTS_2D = {name: (lambda name=name: drive_part(name + "_2d")) for name in (
    "drive_deck", "gb_rail", "output_shaft", "tens_upright", "tens_base")}
