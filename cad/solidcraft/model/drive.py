"""drive.py -- the drive: gearbox (foot-mounted, NRV063-VS placeholder) on two slotted rails, output shaft, the PIN
FLANGE + 4 dowel pins (the pin coupling to the TL350 on shaft A), motor + jaw coupling, coupling guard + stub cap
(printed), drive deck + legs + hold-down (leg angles, foot angles, floor anchors) (cad/drive.scad).  World frame.

NO BELT, NO CHAIN.  The gearbox's hollow output is COAXIAL with shaft A.  The output shaft carries the pin flange (made,
  6061): its 4 hardened dowels Ø8 reach through 4 holes drilled in the TL350's sprocket plate (the TL350 sits on shaft A,
  flipped: placeholders.sprocket_ph), so the gearbox drives shaft A through the torque limiter, 1:1.
OUTPUT SHAFT  Ø25 h6 from the bought 4140 bar: through the hollow output hub, keyway 8 x 4 along the hub (gearbox key)
  and 8 x 4 under the pin flange's bore (its key); DIN 471 circlip against the housing's far face; a Ø36 spacer between
  the housing face and the flange's hub.
MOTOR  on the deck, COAXIAL with the worm's -y input shaft, joined to it by a jaw coupling; the +y stub has its own
  printed cap.
RAILS  two flats 50 x 10 under the foot rows, slots (+-6 mm along x) for the feet, M8 deck bolts outside the flange, on
  4 spacer blocks (rail + spacer = SUBPLATE_T = 20).
HOLD-DOWN  gearbox feet -> rails (M8 through-bolts) -> deck -> 4 top angles (40x40x4, 2 x M8 through the deck, 2 x M8
  through the leg) -> legs -> 4 foot angles (2 x M8 through the leg, 2 x M8 anchors each) -> floor.

HARDWARE BODIES.  A bolt placeholder of the .scad is washer + head + shank + washer + nut as overlapping solids (the
shank runs through solid washers and a solid nut).  Here every bolt (head + shank), washer and nut is a body of its own:
the washers and nuts are the same solids with the shank cut out, so the bodies of one bolt fill exactly the .scad's union.
"""
from common import *
from joints import *              # + drive_geom: every constant of the drive
from placeholders import *
from tl350 import *


# ---------------- gearbox, output shaft, pin flange
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
        keyway_cut(PFKEY_X0, PFKEY_X1))                 # pin-flange key


def output_shaft_ph():
    return translate([0, YA, ZO], part("Output shaft", output_shaft_local()))


# the bought parts on the output shaft (seated placeholders): circlip, the Ø36 spacer on the housing face
def circlip_ph():
    return translate([0, YA, ZO], part("Circlip DIN 471 25", seat_x(CIRCLIP_OD, CIRCLIP_GROOVE_D, GB_X0 - CIRCLIP_T, CIRCLIP_T)))


def out_spacer_ph():
    return translate([0, YA, ZO], part("Output shaft spacer", seat_x(OUT_SPACER_D, JOURNAL_D, GB_X1, TL_GB_GAP)))


def shaft_hw_ph():
    return union(circlip_ph(), out_spacer_ph())


# ---- the PIN FLANGE (made, 6061-T6; part frame: axis on +z, z = 0 at the disc face, the hub toward +z): disc, pocket,
#      keyed bore, 4 pin holes, M6 grub screw over the key
def pin_flange_local():
    return difference(
        union(cylinder(d=PF_D, h=PF_T),
              cylinder(d=PF_HUB_D, h=PF_X0 - PF_HUB_X)),
        translate([0, 0, -1], cylinder(d=PF_POCKET_D, h=PF_X0 - PF_PK_X + 1)),                               # pocket over A's end cap + M10 head
        translate([0, 0, PF_X0 - PF_PK_X - 0.01], cylinder(d=JOURNAL_D + 0.02, h=PF_KEY_L + 1)),              # Ø25 H7 bore
        translate([-SHAFT_KEY_W / 2, 0, PF_X0 - PF_PK_X - 0.01], cube([SHAFT_KEY_W, JOURNAL_D / 2 + 3.3, PF_KEY_L + 1])),   # 8 mm keyway, 3.3 deep in the hub (broached)
        [translate([q[0], q[1], -1], cylinder(d=PIN_D, h=PF_T + 2)) for q in PIN_PTS],                       # pin holes (reamed: press fit)
        translate([0, 0, PF_X0 - PF_PK_X + PF_KEY_L / 2], rotate([-90, 0, 0], cylinder(d=5, h=PF_HUB_D))))  # M6 grub screw over the key (tap drill Ø5)


def axis_to_x(*ch):
    """A rotation: part +z -> world -x, part x -> world -y, part y -> world z (the key on top)."""
    return multmatrix([[0, 0, -1, 0], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], *ch)


def pin_flange():
    return translate([PF_X0, YA, ZO], axis_to_x(part("Pin flange", pin_flange_local())))


def pins_ph(g=0):
    """Seated in the flange (FIT off the hole)."""
    return union(translate([PIN_X0 + FIT, YA + q[0], ZO + q[1]], rotate([0, 90, 0], part("Dowel pin Ø8 x 32",
                     cylinder(d=PIN_D - 2 * FIT + 2 * g, h=PIN_L - 2 * FIT)))) for q in PIN_PTS)


def pin_coupling_ph():
    return union(pin_flange(), pins_ph())


def pin_flange_section_2d():
    """The .scad's projection(cut = true) rotate([90, 0, 0]) pin_flange_local(): the part cut by the plane through its
    axis on which the keyway and the grub-screw hole start (part y = 0; they lie on its +y side and do not show), in
    (u, v) = (part x, -part z)."""
    T, L = PF_T, PF_X0 - PF_HUB_X                      # disc thickness, overall length
    PK = PF_X0 - PF_PK_X                               # pocket depth
    KB = PK - 0.01                                     # start of the bore
    R, RH, RP, RB = PF_D / 2, PF_HUB_D / 2, PF_POCKET_D / 2, (JOURNAL_D + 0.02) / 2

    def half(sx):
        return polygon([(sx * RP, 0), (sx * R, 0), (sx * R, -T), (sx * RH, -T), (sx * RH, -L), (sx * RB, -L), (sx * RB, -KB),
                        (sx * RP, -KB)])

    return union(half(1), half(-1))


def pin_flange_2d():
    """2D drawing of the pin flange: face view (pocket, pin holes) and, beside it, the half section."""
    return union(
        difference(circle(d=PF_D), circle(d=PF_POCKET_D), [translate(q, circle(d=PIN_D)) for q in PIN_PTS]),
        translate([PF_D, 0], pin_flange_section_2d()))


def sprocket_drill_2d():
    """1:1 drilling template for the TL350's sprocket plate: tooth-tip circle, root circle, the TL's Ø89 body, the 4 Ø8.5
    holes and their centre cross."""
    return union(
        [difference(circle(d=d + 0.5), circle(d=d - 0.5)) for d in (SPA_OD_, tl_sprocket_root_d, TL_D)],
        [translate(q, difference(circle(d=PIN_HOLE_D), circle(d=PIN_HOLE_D - 1)), square([12, 0.4], center=True),
                   square([0.4, 12], center=True)) for q in PIN_PTS],
        square([20, 0.4], center=True), square([0.4, 20], center=True))


def output_shaft_2d():
    """2D drawing of the output shaft (side view with the keyway and the groove, plan view with the keyway slots; 1:1 mm;
    x = along the shaft from the far end)."""
    L = OUT_X1 - OUT_X0
    R = JOURNAL_D / 2
    g0 = GB_X0 - CIRCLIP_GROOVE_W - OUT_X0
    keys = [[GBKEY_X0, GBKEY_X1], [PFKEY_X0, PFKEY_X1]]

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


# ---------------- motor, jaw coupling (placeholders)
MOTOR_WELD = 0.01      # in the .scad the Ø120 body only TOUCHES the top of its foot plate, along a line (tangent): no solid.
#                        Here the foot plate is this much higher, so that it runs into the body and the motor is one solid.


def motor_ph():
    return part("Motor",
                translate([XM, Y_MF, ZM], rotate([90, 0, 0], cylinder(d=MOTOR_D, h=MOTOR_LEN))),           # body, front face at Y_MF, toward -y
                translate([XM - MOTOR_FOOT[0] / 2, MFOOT_Y[0], DECK_TOP],
                          cube([MOTOR_FOOT[0], MFOOT_Y[1] - MFOOT_Y[0], MOTOR_FOOT[2] + MOTOR_WELD])))


def motor_shaft_ph():
    """Out of the face up to the spider."""
    return translate([XM, Y_MF, ZM], rotate([-90, 0, 0], cylinder(d=MOTOR_SHAFT_D, h=MOTOR_SHAFT_L)))


def coupling_ph():
    return union(
        translate([XG, Y_WS, ZW], rotate([-90, 0, 0], part("Jaw coupling hub (worm side)", difference(
            cylinder(d=CPL_D, h=CPL_hub_L), translate([0, 0, -1], cylinder(d=19.1, h=CPL_hub_L + 2)))))),
        translate([XG, CPL_Y_M0, ZW], rotate([-90, 0, 0], part("Jaw coupling hub (motor side)", difference(
            cylinder(d=CPL_D, h=CPL_hub_L), translate([0, 0, -1], cylinder(d=MOTOR_SHAFT_D + 0.1, h=CPL_hub_L + 2)))))),
        translate([XG, Y_WS - CPL_gap + 0.5, ZW], rotate([-90, 0, 0], part("Jaw coupling spider",
                                                                           cylinder(d=CPL_D - 6, h=CPL_gap - 1)))))   # spider (+ the jaws)


# ---------------- coupling guard + stub cap (printed PETG): a box (top, two sides, two end walls) open at the bottom,
# standing on the deck on two feet (2 x M5 x 20 wood screws each).  The end walls have U-notches round the shafts (open
# UPWARD); the motor face and the housing face close the notches from outside (CG_END_GAP).  The stub cap is the same box
# over the +y stub, its far end wall closed.
def cg_foot_pts(y0, y1, feet=(-1, 1), iw=CG_IW):
    return [[XG + sx * (iw + CG_W + CG_FOOT_REACH / 2), (y0 + y1) / 2 + dy] for sx in feet for dy in (-10, 10)]


def cg_box(y0, y1, notch0, notch1, feet=(-1, 1), iw=CG_IW):
    """notch = radius of the U-notch in that end wall (0: closed wall); iw = inner half-width = inner height over the axis."""
    return difference(
        union(translate([XG - iw - CG_W, y0, DECK_TOP], cube([2 * (iw + CG_W), y1 - y0, ZW + iw + CG_W - DECK_TOP])),
              [translate([XG + iw + CG_W - 0.01 if sx > 0 else XG - iw - CG_W - CG_FOOT_REACH + 0.01, (y0 + y1) / 2 - CG_FOOT_W / 2, DECK_TOP],
                         cube([CG_FOOT_REACH, CG_FOOT_W, CG_FOOT_T])) for sx in feet]),                                   # the feet
        translate([XG - iw, y0 + CG_W, DECK_TOP - 1], cube([2 * iw, y1 - y0 - 2 * CG_W, ZW + iw - DECK_TOP + 1])),       # inside (open at the bottom)
        [translate([XG, e[0] - 1, ZW], rotate([-90, 0, 0], cylinder(r=e[1], h=CG_W + 2),
                                              translate([-e[1], -(iw + CG_W) - 1, 0], cube([2 * e[1], iw + CG_W + 1, CG_W + 2]))))
         for e in ((y0, notch0), (y1 - CG_W, notch1)) if e[1] > 0],                                                       # U-notch round the shaft, open upward
        [translate([q[0], q[1], DECK_TOP - 1], cylinder(d=5.5, h=CG_FOOT_T + 2)) for q in cg_foot_pts(y0, y1, feet, iw)])   # M5 clearance in the feet


CG2_IW = 19 / 2 + GUARD_CLEAR                       # the stub cap is only as big as the bare Ø19 stub needs
CG2_FEET = (-1,)                                    # the stub cap's foot only on the -x side


def cpl_guard():
    return cg_box(CG_Y0, CG_Y1, MOTOR_SHAFT_D / 2 + GUARD_CLEAR, 19 / 2 + GUARD_CLEAR)


def stub_cap():
    return cg_box(CG2_Y0, CG2_Y1, 19 / 2 + GUARD_CLEAR - 0.001, 0, CG2_FEET, CG2_IW)                 # the far end wall is closed


def drive_guards_low():
    return union(part("Coupling guard", cpl_guard()), part("Stub cap", stub_cap()))


def cg_all_foot_pts():
    return cg_foot_pts(CG_Y0, CG_Y1) + cg_foot_pts(CG2_Y0, CG2_Y1, CG2_FEET, CG2_IW)


def cg_foot_shanks():
    """M5 wood screw core: foot Ø5.5 + deck pilot Ø4.2."""
    return union(translate([p[0], p[1], DECK_Z0 + 2], cylinder(d=4, h=DECK_T + CG_FOOT_T + 4)) for p in cg_all_foot_pts())


def cg_screws_ph():
    return union(translate([p[0], p[1], DECK_TOP + CG_FOOT_T + 0.01], part("M5 x 20 wood screw (coupling guard)",
                     cylinder(d=9.5, h=3.5), translate([0, 0, -20], cylinder(d=3.6, h=20)))) for p in cg_all_foot_pts())


# ---------------- drive deck: REAL 18 mm plywood under the motor and the rails, on 4 timber legs (45 x 45)
# Outline = motor foot / rails / guards + margins.
# Holes: 6 x Ø4.2 pilots (coupling guard + stub cap feet), 8 x Ø5.5 (leg screws), 4 x Ø9 (rail bolts), 8 x Ø9
# (top-angle bolts).  The motor's own slots are not drilled.
assert DECK_LEG_LEN >= DRIVE_LEG_MIN, f"drive deck legs too short ({DECK_LEG_LEN} < {DRIVE_LEG_MIN})"
assert DECK_X1 < -30


def deck_leg_screw_xy():
    """Leg screws, 17 mm in from the leg centre toward the deck middle."""
    return [[c[0] + dx, c[1] + (17 if c[1] < 0 else -17)] for c in DECK_LEG_C for dx in (-10, 10)]


def drive_deck_2d():
    return difference(
        translate([DECK_X0, DECK_Y0], square([DECK_X1 - DECK_X0, DECK_Y1 - DECK_Y0])),
        [translate(p, circle(d=4.2)) for p in cg_all_foot_pts()],             # M5 wood screw pilots (coupling guard + stub cap feet)
        [translate(p, circle(d=5.5)) for p in deck_leg_screw_xy()],            # M5 leg screws (pilots Ø3.5 in the timber, deck_legs())
        [translate(p, circle(d=9)) for p in RAIL_BOLT_PTS],                    # rail bolts
        [translate(p, circle(d=9)) for p in TOPANG_DECK_PTS])                  # top-angle bolts


def drive_deck():
    return part("Drive deck", translate([0, 0, DECK_Z0], linear_extrude(DECK_T, drive_deck_2d())))


def legpts(c, pts):
    return [q for q in pts if abs(q[0] - c[0]) <= LEG_SECTION / 2 + 0.01 and abs(q[1] - c[1]) <= LEG_SECTION / 2 + 0.01]


def leg_name(c):
    """Which corner of the deck: -x / +x end, front (-y, the motor side) / back."""
    return f"{'-x' if leg_sx(c) > 0 else '+x'} end, {'front' if leg_sy(c) < 0 else 'back'}"


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
# ---------------- swept envelopes of the moving parts (full cylinders: any angle), every dimension grown by g (radially, and along x at both ends)
def cylx(r, x0, x1, y=0, z=0):
    return translate([x0, y, z], rotate([0, 90, 0], cylinder(r=r, h=x1 - x0)))


def drive_end_env(g=0, sprocket=True, shafts=("A", "B"), sleeves=True):
    """sleeves = False: without the two Ø30 sleeves that pass through the outboard plate."""
    def one(s):
        y = shaft_y(s)
        xe = end_x_drive(s)
        return union(
            cylx(GEAR_module * (GEAR_z + 2) / 2 + g, x_gear_out - g, x_gear_in + g, y),                 # gear teeth
            cylx(GEAR_HUB_D / 2 + g, x_gear_hub_out - g, x_gear_out + g, y),                            # gear hub
            [cylx(GEAR_SPACER_D / 2 + g, x_ob_ring_in - g, x_gear_hub_out + g, y),                      # sleeve: gear hub -> outboard bearing
             cylx(GEAR_SPACER_D / 2 + g, (x_spA_in if s == "A" else x_sprocket_in) - g, x_ob_ring_out + g, y)] if sleeves else None,
            cylx(COLLAR_OD / 2 + g, x_collar_out_drive - g, x_collar_in_drive + g, y),                  # collar
            cylx(THRUST_D / 2 + g, x_collar_in_drive - g, x_cap_out_drive + g, y),                      # thrust bearing
            cylx(15 + g, xe - END_WASHER_T - g, xe + g, y),                                             # end cap
            cylx(8 + g, xe - END_WASHER_T - 10 - g, xe - END_WASHER_T + g, y),                          # M10 head
            [cylx(TL_D / 2 + g, x_sprocket_out - g, x_spA_in + g, y),                                   # the TL350 body
             cylx(SPA_OD_ / 2 + g, X_CM - SPROCKET_T / 2 - g, X_CM + SPROCKET_T / 2 + g, y)]            # its 30T tooth plate
            if s == "A" and sprocket else None)

    return union(one(s) for s in shafts)


def sprocket_a_env(grow=0):
    """The TL350 on A: body + tooth plate as plain cylinders (swept over any angle)."""
    return translate([0, YA, 0],
                     axial(x_sprocket_out - grow, cylinder(d=TL_D + 2 * grow, h=TL_L + 2 * grow)),
                     axial(X_CM - SPROCKET_T / 2 - grow, cylinder(d=SPA_OD_ + 2 * grow, h=SPROCKET_T + 2 * grow)))


def pf_env(g=0):
    """The pin flange (disc + hub), its pins, the spacer, all swept, grown by g."""
    return union(cylx(PF_D / 2 + g, PF_X1 - g, PF_X0 + g, YA, ZO),
                 cylx(PF_HUB_D / 2 + g, PF_HUB_X - g, PF_X1 + g, YA, ZO),
                 cylx(OUT_SPACER_D / 2 + g, GB_X1 - g, PF_HUB_X + g, YA, ZO),
                 cylx(PIN_R + PIN_D / 2 + g, PF_X0 - g, PIN_X1 + g, YA, ZO))                    # the pins' ring, from the disc face to their tips


def coupling_env(g=0):
    """The whole coupling as a cylinder."""
    return translate([XG, CPL_Y_M0 - g, ZW], rotate([-90, 0, 0], cylinder(d=CPL_D + 2 * g, h=CPL_Y_W1 - CPL_Y_M0 + 2 * g)))


def stub_env(g=0):
    """The unused +y worm stub."""
    return translate([XG, Y_HF2 - 0.01, ZW], rotate([-90, 0, 0], cylinder(d=19 + 2 * g, h=GB_WORM_STUB + 0.01 + g)))


def motor_shaft_env(g=0):
    """The bare motor shaft between the face and the hub."""
    return translate([XG, Y_MF - 0.01, ZW], rotate([-90, 0, 0], cylinder(d=MOTOR_SHAFT_D + 2 * g, h=CPL_Y_M0 - Y_MF + 0.01)))


def drive_gearbox_ph():
    return union(gearbox_ph(), worm_ph(), output_shaft_ph(), shaft_hw_ph(), gb_mount())


# ---------------- accessors for checks / guards
def deck_geom():
    return [DECK_X0, DECK_X1, DECK_Y0, DECK_Y1, DECK_Z0, DECK_Z1]


def worm_axis():
    return [XG, ZW]


def motor_axis_z():
    return ZM


def gb_mount_box():
    return [[RAIL_X0, RAIL_Y_LO, DECK_TOP], [RAIL_X1 - RAIL_X0, RAIL_Y_HI - RAIL_Y_LO, SUBPLATE_T]]


def motor_axis_x():
    return XM


def cg_box_pts():
    return [[XG - CG_IW - CG_W - CG_FOOT_REACH, CG_Y0, DECK_TOP], [2 * (CG_IW + CG_W + CG_FOOT_REACH), CG_Y1 - CG_Y0, CG_ZT - DECK_TOP]]


# ---------------- joint alignment shanks (checks C16): a bolt shank through the hole of part 1 AND the hole of part 2; it must touch neither part's material
def deck_leg_shanks():
    """M5 wood screw core: deck Ø5.5 + leg pilot Ø3.5."""
    return union(translate([p[0], p[1], DECK_Z0 - 29], cylinder(d=3.3, h=DECK_T + 31)) for p in deck_leg_screw_xy())


def gbfoot_shanks():
    """M8: flange Ø9 + rail slot 9."""
    return union(translate([p[0], p[1], RAIL_Z0 - 3], cylinder(d=8, h=GB_RAIL_T + GB_FLANGE[2] + 6)) for p in gb_foot_pts())


def subbolt_shanks():
    """M8: rail Ø9 + spacer Ø9 + deck Ø9."""
    return union(translate([p[0], p[1], DECK_Z0 - 3], cylinder(d=8, h=DECK_T + SUBPLATE_T + 6)) for p in RAIL_BOLT_PTS)


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
    if sel == "output_shaft":
        return translate([-OUT_X0, 0, 0], output_shaft_local())
    if sel == "output_shaft_2d":
        return output_shaft_2d()
    if sel == "pin_flange":
        return pin_flange_local()                                                            # disc face down
    if sel == "pin_flange_2d":
        return pin_flange_2d()
    if sel == "sprocket_drill_2d":
        return sprocket_drill_2d()
    if sel == "cpl_guard":
        return translate([-(XG - CG_IW - CG_W - CG_FOOT_REACH), -CG_Y0, -DECK_TOP], cpl_guard())     # standing on its feet
    if sel == "stub_cap":
        return translate([-(XG - CG2_IW - CG_W - CG_FOOT_REACH), -CG2_Y0, -DECK_TOP], stub_cap())
    if sel == "drive_deck":
        return translate([-DECK_X0, -DECK_Y0, -DECK_Z0], drive_deck())
    if sel == "drive_deck_2d":
        return translate([-DECK_X0, -DECK_Y0], drive_deck_2d())
    if sel == "world":
        return union(drive_gearbox_ph(), pin_coupling_ph(), gb_foot_bolts_ph(), rail_bolts_ph(), motor_ph(), motor_shaft_ph(), coupling_ph(),
                     deck_ph(), deck_legs(), top_angles(), foot_angles(), holddown_hw_ph(), cpl_guard(), stub_cap(), cg_screws_ph())
    return None


# ---------------- the bodies of the assembly
BODIES = {
    "Frame": [
        Body("Worm gearbox NRV063", lambda: gearbox_ph(), GRAY, 0.6),
        Body("Gearbox + rail bolts", lambda: union(gb_foot_bolts_ph(), rail_bolts_ph()), DARK),
        Body("Gearbox rails", lambda: gb_mount(), METAL),
        Body("Motor", lambda: motor_ph(), DARK),
        Body("Coupling guard + stub cap", lambda: drive_guards_low(), PRINT, 0.55),
        Body("Coupling guard screws", lambda: cg_screws_ph(), DARK),
        Body("Drive deck + legs", lambda: union(drive_deck(), deck_legs()), "#c8a46e", 0.85),
        Body("Leg angles", lambda: union(top_angles(), foot_angles()), METAL),
        Body("Deck + leg bolts", lambda: union(topang_deck_bolts_ph(), topang_leg_bolts_ph(), footang_leg_bolts_ph()), DARK),
        Body("Floor anchors", lambda: anchors_ph(), RED),
    ],
    "Output shaft + pin flange": [
        Body("Output shaft 4140", lambda: output_shaft_ph(), "#2b6cb0"),
        Body("Pin flange + 4 pins", lambda: pin_coupling_ph(), "#9aa5b1"),
        Body("Circlip and spacer", lambda: shaft_hw_ph(), YELLOW),
    ],
    "Worm + jaw coupling": [
        Body("Worm", lambda: worm_ph(), DARK),
        Body("Jaw coupling", lambda: coupling_ph(), "#c45a1a"),
    ],
    "Motor shaft": [
        Body("Motor shaft", lambda: motor_shaft_ph(), DARK),
    ],
}


# the made parts of this file in their part frames / print poses (parts.py)
PARTS = {name: (lambda name=name: drive_part(name)) for name in (
    "output_shaft", "pin_flange", "cpl_guard", "stub_cap", "drive_deck", "gb_rail", "gb_spacer", "leg_angle")}

PARTS_2D = {name: (lambda name=name: drive_part(name + "_2d")) for name in (
    "drive_deck", "gb_rail", "output_shaft", "pin_flange", "sprocket_drill")}
