"""Single source of truth for the shredder's dimensions and design inputs.

All lengths are mm, forces N, stresses MPa, torques N*m unless a name says otherwise.
`design/build.py` turns these into `cad/params.scad` and `cad/blade_profile.scad`,
and `calc/calc.py` checks them. Change a number here, then run `make` (see README).

Axis convention (used by the CAD too):
  x  along the shafts. x = 0 is the inner face of the DRIVE-END plate (the end with
     the gears and the gearbox); +x runs into the cutting chamber toward the free end.
  y  across the machine. Shaft A (driven by the gearbox) is at y = -C/2, shaft B at +C/2.
  z  up. The shaft centres are at z = 0.
Rotation: shaft B turns POSITIVE about +x (right-hand rule: +y toward +z) and shaft A
turns NEGATIVE about +x, so both inner sides (toward y = 0) move DOWN and pull the
plastic down between the shafts. (Viewed from the drive end looking along +x, +y is on
the viewer's LEFT: B is on the left turning clockwise, A on the right counter-clockwise.)
The blade outline is drawn turning counter-clockwise in its own 2D frame (u, v); mapped
u->y, v->z it suits shaft B. Shaft A uses the SAME part turned over (v -> -z).
"""
import math

# --- Material (all steel stock is assumed to be mild steel; the user is not sure) ---
STEEL = dict(
    name="mild steel (assumed S235 / 1018, hot-rolled)",
    Sy=235.0,      # yield, MPa (lowest common value; bright-drawn 1018 is ~370)
    Su=360.0,      # ultimate, MPa
    E=210000.0,    # MPa
)
# Shaft material. Review 1 showed the user's mild steel cannot carry the operating torque
# when one shaft takes it all (fatigue SF < 1), so the two shafts are made from BOUGHT
# Ø30 42CrMo4 (4140) quenched-and-tempered bar (~28-32 HRC, machines fine with carbide).
# calc.py also reports the derated torque limits for C45 and for the user's mild steel.
SHAFT_MATERIALS = {
    "42CrMo4 QT (4140 pre-hard), bought": dict(Sy=650.0, Su=900.0),
    "C45 normalised, bought": dict(Sy=305.0, Su=580.0),
    "your mild-steel bar (S235)": dict(Sy=235.0, Su=360.0),
}
# Shaft steel. With the torque limiter, the limit is the hard-jam spike from the parts after it (calc
# s.3b, s.4c). Mild steel misses that check at the gear keyway of shaft A, so the shafts are made from
# BOUGHT 4140 (Amazon: 1.25 in x 3 ft, cold-worked annealed, ASIN B09Q3NW324), turned to Ø30 first.
SHAFT_MATERIALS["4140 annealed, 1.25 in bar (Amazon)"] = dict(Sy=415.0, Su=655.0)
SHAFT_MATERIAL = "4140 annealed, 1.25 in bar (Amazon)"
SHAFT_BAR_BUY = "4140 alloy steel round rod 1.25 in (31.75) x 3 ft, cold worked annealed (Amazon B09Q3NW324)"

# --- Stock the user has (2026-11-07) ---
STOCK = [
    ("Round bar", "Ø30 x 410"),
    ("Round bar", "Ø55 x 500"),
    ("Round bar", "Ø30 x 270"),
    ("Round bar", "Ø30 x 500 (x2)"),
    ("Flat bar", "70 x 10 x 1170"),
    ("Flat bar", "70 x 10 x 1300"),
    ("Flat bar", "50 x 10 x 1310"),
    ("Flat bar", "50 x 10 x 1100"),
    ("Block", "51 x 130 x 25.5"),
]

# --- Cutting geometry ---
C = 60.0               # shaft centre distance (= pitch diameter of the m3 z20 gears)
N_SLOTS = 16           # slots across the chamber: each shaft has N/2 blades + N/2 spacers
T_BLADE = 8.0          # blade thickness: the 10 mm flat faced 1 mm per side (flat, scale-free)
SIDE_CLEAR = 0.20      # side clearance blade-to-blade, each side (nominal)
T_SPACER = T_BLADE + 2 * SIDE_CLEAR   # 8.40 nominal; spacers are faced to a MEASURED stack schedule
STACK_TOL = 0.03       # every blade face within +-0.03 of its scheduled position (closed-loop stacking)
ALIGN_TOL = 0.03       # residual A-to-B stack offset after shimming with feeler gauges (DESIGN 7.3);
                       # the fixed bearings' axial play is taken up in one direction by the wave springs
END_CLEAR = 0.5        # gap between each stack end and the end-plate inner face

R_TIP = 34.0           # blade tip radius (Ø68 from the 70 mm flat, 1 mm to spare per side)
R_ROOT = 25.0          # blade root (gullet bottom) radius
TEETH = 3              # teeth per blade
HOOK_DEG = 10.0        # positive rake (hook) of the tooth face
GULLET_R = 4.0         # gullet fillet radius (>= 3.2 for the Ø6 cutter, with margin)
LAND_DEG = 4.0         # tip land, degrees (~2.4 mm at R34)
BACK_START_DEG = 32.0  # where the next tooth's back leaves the root circle, deg after a tip

STAGGER_DEG = 120.0 / (N_SLOTS // 2)   # 15 deg: tooth phase step from blade to blade (helix)
BLADE_VARIANTS = 4     # phase offsets 0/15/30/45 deg between teeth and hex (60 deg symmetry)

SPACER_OD = 50.0       # from the Ø55 bar; tip-to-spacer radial gap = C - R_TIP - SPACER_OD/2
SPACER_BORE = 29.2     # round bore, slides over the hex corners (AC 28.93)

# --- Shafts ---
HEX_AF = 25.05         # hex across flats, milled on the SIEG (flats just clear the Ø25 journals)
HEX_BORE_AF = 25.10    # blade hex bore across flats (CNC), finished to the real shaft: a hand slide
                       # fit with no rocking, 25.08-25.13 (0.03-0.08 clearance)
HEX_RELIEF_D = 3.2     # corner relief circles in the blade bore, cut with a Ø3 end mill
                       # (small reliefs keep 11.35 of each 14.55 flank for torque contact)
JOURNAL_D = 25.0       # all bearing / gear / gearbox journals, h6 slide fit
END_SCREW = "M10"      # tapped in both shaft ends; clamps the whole stack axially
END_SCREW_LEN = 30.0   # M10 x 30, 8.8: end cap 10 + recess 1.5 + 18.5 engagement (25 deep thread)
END_TAP_DEPTH = 25.0   # full thread depth (drill Ø8.5 x 30)
END_WASHER_T = 10.0    # END CAP Ø30 x 10 (annular plate, calc s.8; a 3 mm washer would yield)
SHAFT_END_RECESS = 1.5 # each shaft end stops 1.5 short of the face its washer clamps, so the
                       # washers always clamp the parts, never the shaft end (tolerance +-1.5)
CLAMP_N = 4000.0       # axial clamp from each M10 (about 8 N*m tightening torque); limited by the
                       # Ø30 clamp sleeve on the Ø29.2 spacer bore (calc s.8)

# --- Bearings (2026-11-07, user's choice, all on Amazon): NA4905 needle roller bearings with inner
# ring at all four positions. The inner ring (25 bore, 30 OD, 17 wide) is part of the clamp chain like
# the old ball-bearing inner rings; the outer ring is held in the plates. Needle bearings let the inner
# ring slide axially, so the free end floats by itself. C0 = the LOWEST Amazon rating found (Bettomshin
# 20.475 kN); branded NTN / JNS / SKF parts are rated 30.7-34.5 kN.
BEARING = dict(name="NA4905 needle roller bearing with inner ring", d=25.0, D=42.0, B=17.0, F=30.0,
               C=23700.0, C0=20500.0)
# Lengthwise location: one thrust needle bearing per shaft end, round a collared sleeve (so the clamp
# chain stays continuous). Drive end: the collar presses it on the cap face. Free end: crinkle washers
# between the cap face and the bearing push every shaft toward +x, so the drive-end thrust bearing
# always carries the (tiny) axial load and the stacks cannot wander.
THRUST = dict(name="AXK3047 + 2 x AS3047 thrust needle bearing", d=30.0, D=47.0, T=4.0)
SEAL = dict(name="TC 30x42x7 nitrile oil seal", d=30.0, D=42.0, B=7.0)      # in the inner layer, on the sleeve
CRINKLE = dict(name="crinkle (wave) washer 30x39x0.5", d=30.0, D=39.0, n=3, stack_h=2.0)

# --- End plates (3 layers of the 70x10 flat per end, bolted + doweled) ---
PLATE_H = 70.0         # z extent, centred on the shafts
PLATE_L = 170.0        # y extent
LAYER_T = 10.0         # inner layer, outer (bearing) layer, cap layer
# Bores (both ends identical): INNER layer: seal counterbore Ø42 x 7 from the chamber face, then Ø36
# for the last 3 mm (shoulder for the bearing's outer ring). OUTER layer: Ø42 H7 through. CAP layer:
# Ø42 H7 counterbore 7 deep from its inner face (the bearing is 17 = 10 + 7 wide), then Ø32 through
# the last 3 mm (the outer ring is clamped between the inner-layer shoulder and this step).
SEAL_BORE_DEPTH = 7.0
INNER_HOLE_D = 36.0
CAP_BORE_DEPTH = 7.0   # = BEARING B - LAYER_T
CAP_HOLE_D = 32.0

# --- Clamp sleeves (turned from the Ø55 bar) ---
SLEEVE_OD = 30.0       # also the oil-seal running surface: turn it smooth (Ra <= 0.8)
SLEEVE_ID = 25.05
COLLAR_OD = 46.0       # collared sleeves at both ends: body Ø30 through the cap hole and the thrust bearing
COLLAR_T = 4.0

# --- Gears: BOUGHT (2026-11-13, user's choice after review 7), keep the shafts in step (1:1, opposite directions) ---
# Review 7 showed that a gear OVERHUNG 42 mm outside the drive bearing on the Ø25 shaft tilts under load, so its teeth carry the load on only ~7-11 mm of their width
# (ISO 6336-1 face load factor 4-6): the home-made m1.5 gears failed, and so did any overhung gear.  Now each gear sits BETWEEN two bearings: the drive bearing
# and an OUTBOARD BEARING PLATE (below), and the gears are bought m4 z15 steel spur gears with HARDENED teeth (the contact stress at d = 60 needs them).
# m4 z15 rather than m3 z20 (same pitch Ø60): with the ISO face load factor for an assumed cheap gear (grade 9) and +-0.02 bearing seats, m3 misses the hard-jam bending check (calc s.6).
# Bought from Amazon, re-bored Ø25 H7 and broached for the 8 mm key on the lathe like the sprocket.  *** APPROXIMATE: hub size until the listing is chosen. ***
GEAR_MODULE = 4.0
GEAR_Z = 15            # odd: gear B needs no half-pitch turn to mesh with A (a gap of B faces a tooth of A)
GEAR_ALPHA = 20.0      # pressure angle, deg
GEAR_FACE = 30.0       # tooth face width (the hub is extra).  (40 would help pitting, but moves the drive out 10 more and the standoffs get too soft: review 7)
GEAR_HUB_L = 18.0      # APPROX: hub length (on the outboard side of the teeth); make variants tries 12 and 22
GEAR_HUB_D = 45.0      # APPROX: hub OD
GEAR_CUT_EXTRA = 0.10  # MODEL ONLY: the bought gears' tooth-thickness tolerance as an equivalent extra cutting depth on both gears (backlash ~0.15, calc s.6; C31)
GEAR_KEY_W = 8.0       # 8 x 7 key, shaft keyway 4 deep, gear keyway GEAR_KEYWAY_H above the bore surface
GEAR_KEYWAY_H = 3.3    # broached keyway depth in the gear above the Ø25 bore surface (the key stands 7 - 4 = 3 above the shaft: 0.3 clearance)
GEAR_KEY_TOOL_D = 0.4  # corner radius x 2 of the broached keyway (sharp)
GEAR_ISO_GRADE = 9     # ASSUMED accuracy of a cheap bought gear (ISO 1328): sets the helix slope deviation fHbeta in the face load factor (calc s.6)
GEAR = dict(module=GEAR_MODULE, z=GEAR_Z, alpha=GEAR_ALPHA, bore=25.0, hub_L=GEAR_HUB_L, cut_extra=GEAR_CUT_EXTRA,
            material="C45 (45#) steel, teeth induction-hardened (HRC 45-55), bought",
            Sy=305.0, Su=580.0,   # CORE of C45 normalised, EN 10083-2, 16 < d <= 100 (the hardened tooth surface is ignored for bending: conservative)
            lewis_Y=0.290,        # Y(z = 15, 20 deg full depth, load at the tip): Shigley's MED, Table 14-2
            HV_min=513.0,         # BUY REQUIREMENT: teeth >= HRC 50 (= 513 HV, ASTM E140)
            sigma_H_lim=0.740 * 513.0 + 602.0)   # ISO 6336-5, flame / induction hardened, quality ML: 0.740 HV + 602 = 982 MPa at the minimum hardness
GEAR_HERTZ_SF = 1.0    # required SF on the pitting limit (with the ISO life factor), the ISO 6336-2 minimum for pitting: pitting is slow and visible, the gears are cheap (DESIGN 8.3)
# Pitting is rated as a LIFE (review 7): the gears are a replaceable wear part (2 spares on the list).  Inputs of ISO 6336-2's lubrication / speed / roughness factors:
GEAR_RZ = 10.0         # flank roughness Rz of the pair, µm: ASSUMED for hobbed (not ground) and then induction-hardened teeth
GREASE_NU40 = 220.0    # base-oil viscosity of the gear grease at 40 °C, mm²/s (BUY: EP2 or open-gear grease, base oil ISO VG 220 or thicker)
GEAR_CASE_MIN = 0.5    # hardened case depth on the flanks, mm (BUY REQUIREMENT, as stated by the seller; induction hardening of m4 teeth is normally 1-3 mm)
GEAR_LIFE_MIN_H = 200.0   # required pitting life, hours of cutting with ALL of the motor's operating torque through the gears (the conservative rating)
GEAR_SPACER_D = SLEEVE_OD   # the two sleeves either side of the outboard bearing's inner ring are plain Ø30 sleeves (the Ø55 bar)
# --- OUTBOARD BEARING PLATE (2026-11-13): a 2-layer steel plate outside the gears, on 4 standoffs from the drive cap layer, carries a 5th and 6th NA4905 ---
OB_T = 10.0            # each of its 2 layers (from 100 x 10 flat, bought locally like the gear flat before)
OB_H = 100.0           # z extent (taller than the 70 end plates: the drive-end guard's hood and the gear band butt fully against it)
OB_ZC = 3.0            # its centre is this far ABOVE the shaft axes: bottom edge at z = -47, so the chain tube's top wall under it clears the tensioner's head plate (C24c)
OB_L = 180.0           # y extent (10 more than the end plates: edge margin round the M8 tie holes at |y| = 80)
OB_GAP = 2.0           # rotating part to the plate face (gear hub inboard; sprocket hub / B end cap outboard)
OB_STEP = 1.5          # Ø32 step at each outer face holds the bearing's outer ring: pocket 17 = 8.5 + 8.5 bored from the joint face of each layer
# Two PILLARS (one per side) carry the outboard plate: rectangular bars 15 (y) x 60 (z) x standoff_L, from 60 x 15 flat (bought locally), each with the two Ø9 holes for
# that side's tie screws.  Review 7: four Ø18 tubes (the most that fit at z = ±9) were overstressed and their end faces opened under the plate's twist; the twist is
# carried as up/down forces at y = ±80, where the pillar is 50 deep.
PILLAR = [15.0, 60.0]  # [y width, z height]: from 60 x 15 flat, bought locally (60 tall: the end faces must stay closed at the hard-jam peak, calc s.7b)
PILLAR_Y0 = 73.0       # |y| of the pillar's inner face (3 mm outside the gear band's lobes at y = ±70); its outer face at ±88, 3 past the cap's edge (±85)
TIE_D = 8.0            # M8 tie screws: tapped Ø6.8 through the cap and 9.5 into the outer layer (both ends identical), Ø9 through ob1, ob2 and the standoffs
# The tie screws clamp STEEL ONLY (review 7): head -> 3 hardened washers -> ob2 -> ob1 -> standoff -> cap.  The printed hood does NOT sit under them (its wings have Ø17 clearance
# holes round the washer stacks) and is held by its own 4 x M5 screws into ob2 (HOOD_SCREW_PTS).
TIE_GRADE = "12.9"
TIE_TORQUE = 35.0      # N·m, torque wrench, oiled thread
TIE_PRELOAD_N = TIE_TORQUE / (0.2 * TIE_D / 1000)   # 21.9 kN nominal (k = 0.2)
TIE_SCATTER = 0.25     # torque-wrench scatter of the preload, +-
TIE_EMBED = 0.10       # preload lost to settling of the 6 steel interfaces (VDI 2230 order of magnitude)
TIE_MU = 0.20          # slip factor of clean, dry, UNTREATED machined steel (EN 1993-1-8 Table 3.7 class D): no surface preparation is needed
TIE_WASHERS = 3        # ISO 7089 M8 300HV hardened washers (Ø16 x 1.6) under each head: 4.8 = the hood wing (4) + 0.8, so the head never touches it
HOOD_SCREW_PTS = [[76.0, 28.0], [76.0, -28.0], [-76.0, 28.0], [-76.0, -28.0]]   # 4 x M5 x 12: hood wings -> ob2 (tapped through)
BORE_POS_TOL = 0.02    # each bearing seat within +-0.02 of its DRO position (calc s.4: forced bending of the 3-bearing shaft; s.6: gear misalignment)

# --- Combs (stripper fingers) and walls ---
COMB_W = 25.0          # comb bar width (y); 10 thick (z), from the 50x10 flat
COMB_GAP = 0.5         # comb edge to spacer surface
COMB_SLOT_CLEAR = 0.5  # blade-to-comb-slot side clearance
COMB_SLOT_PAST_TIP = 3.0  # slots run 3 mm past the blade tip radius: the Ø6 cutter leaves R3
                       # corners at the slot bottom, which must stay clear of the blade tip
COMB_SCREW_Y = 74.0    # |y| of the M6 screws into the comb end faces (clear of the slot bottoms)
WALL_H = 50.0          # front/back walls, 50x10 flat on edge
WALL_GAP = 2.0         # blade tip to wall

# --- Motor: the user's salvaged motor (nameplate photo 2026-11-07) ---
MOTOR = dict(
    nameplate_W=375.0, volt=220.0, amp=1.7, hz=50, poles=4, phase=1, rpm=1420.0,
    duty="S2 30 min", insulation="B",
    kind="single-phase capacitor induction motor (capacitor box on top), foot mount, slotted base",
    # 1.7 A x 220 V = 374 VA INPUT. With a typical PF ~0.8 and efficiency ~0.65-0.75 that is
    # ~200-250 W of real shaft output, not 375 W. Use 250 W as the working figure and 375 W
    # as the upper bound (if the label's watts are output and the amps are wrong).
    P_likely_W=250.0,
    breakdown_ratio=2.2,   # typical max/rated torque for a small capacitor motor
    shaft_d_est=12.0,      # ESTIMATE from the photo - measure
)

# --- Drive (2026-11-15).  No belt (user: "I don't think we really need a belt") and no chain (user: "why do we need the other belt?"):
# motor -> flexible JAW COUPLING -> foot-mounted worm gearbox i = 50 (NRV063-VS: solid Ø19 input shaft, Ø25 hollow output with a shop-made output shaft),
# its output COAXIAL with shaft A -> PIN FLANGE (made, 6061) on the output shaft -> 4 hardened dowel pins through 4 holes drilled in the TL350's own 30T
# sprocket plate -> TL350-2 friction torque limiter ON SHAFT A.  The motor turns the worm directly (1420 rpm in, 28.4 rpm out = the shaft speed).
# The limiter stays on shaft A: only the shafts, blades, gears and the limiter's own hub are downstream of it (calc s.3b).
# (The user's bronze is under Ø50: too small for a home-made friction disc, so the bought TL350 stays and the bronze is not used.)
WORM = dict(name="NRV063-VS worm gearbox, i = 50, Ø19 input shaft, Ø25 hollow output",
            ratio=50.0, eff=0.60, rated_out_Nm=150.0)  # eff: catalogue ~0.63 at i = 50, 1400 rpm in (0.60 used); torque: catalogue order of magnitude at i = 50
CHAIN = dict(name="#40 (ANSI 40, 1/2 in) roller chain", pitch=12.7, eff=0.97, kg_per_m=0.41)   # only the TL350's 30T sprocket (geometry) and the setting fixture's chain whip
TL = dict(name="TL350-2 friction torque limiter with #40 30T sprocket (Amazon), bore 25",
          z=30, T_min=34.0, T_max=149.0, L=62.0, D=89.0)
TL_B_CLEAR = 5.0           # the TL350 on shaft A starts this far outside B's M10 head (its Ø89 body passes outside B's end, R > C = 60)
# pin coupling (2026-11-15): the TL350 is FLIPPED (flange end outward), so its sprocket plate is 12 mm from A's outer end; a pin flange on the coaxial gearbox output
# drives it through 4 pins in 4 holes drilled in the plate, between the TL's Ø89 body and the tooth root (the teeth carry nothing any more)
PIN_N = 4                  # dowel pins
PIN_D = 8.0                # Ø8 x 32 hardened dowel (ISO 8734 / DIN 6325), pressed through the flange disc
PIN_L = 32.0
PIN_R = 50.5               # pitch radius of the pins (PCD 101): drill the sprocket at (±35.71, ±35.71) from its bore centre
PIN_HOLE_D = 8.5           # drilled in the sprocket plate: 0.25 radial play + free axial slide = the coupling's misalignment allowance
PF_D = 120.0               # pin flange disc (6061-T6 from a Ø125 x 50 round, or S235)
PF_T = 12.0                # disc thickness = the pins' press length
PF_GAP = 2.0               # disc face to the TL350's outer (flange-end) face
PF_HUB_D = 50.0            # hub behind the disc
PF_POCKET_D = 36.0         # pocket in the face over A's end cap (Ø30) and M10 head (Ø16)
PF_POCKET_CLEAR = 2.0      # pocket bottom beyond the M10 head
PF_KEY_L = 25.0            # keyed Ø25 H7 bore behind the pocket (8 mm keyway, 1 x M6 grub screw over the key)
PF_SHAFT_RECESS = 1.0      # the output shaft ends this far short of the pocket bottom
# jaw coupling between the motor and the worm's input shaft (L090 class: hubs Ø54, the spider between them); APPROXIMATE envelope until bought
CPL = dict(name="jaw (spider) coupling, L090 size, bores 19 (worm) and your motor's shaft", D=54.0, hub_L=20.6, gap=12.7)
MOTOR_SHAFT_L = 40.0       # PLACEHOLDER: motor shaft length out of the motor's front face (measure)
TL_SCATTER = 0.15      # friction slip torque scatter (+15 %) between setting and the most it can transmit

T_OPERATING = 45.0     # design operating input torque at shaft A, N*m (both shafts together)
T_SET = 55.0           # torque limiter setting (the TL is on shaft A)
T_LIMIT = T_SET * (1 + TL_SCATTER)   # 63.3: the most the TL can pass to shaft A (quasi-static)
TL_SET_AT_TL = T_SET                  # 55 N*m: the TL is on shaft A

FATIGUE_SF = 1.5       # Goodman, on the Marin-corrected endurance limit. 1e6 rotations at full
                       # load = ~1400 h of continuous cutting at 11.8 rpm.
STATIC_SF = 1.5        # on yield, at the jam limit

# --- Plastics: shear strength used for printed parts (conservative, MPa) ---
PLASTICS = {
    "PLA": 45.0,
    "PETG": 40.0,
    "ABS / ASA": 35.0,
    "PC": 55.0,
    "Nylon (PA, dry)": 50.0,
}
K_DULL = 1.3           # extra force for dulled edges, friction, crushing
R_BITE = (R_TIP + (C - R_TIP)) / 2   # 30: mean radius where a tooth bites (overlap zone)

# --- CNC4030 blade cutting (estimate; regenerate real paths in AXIS CAM) ---
CNC = dict(
    tool_d=6.0, flutes=3, rpm=7500.0, feed=400.0, ae=0.3, ap=T_BLADE / 2, levels=2,
    spindle_w=800.0, spindle_rpm_max=24000.0, kc11=1700.0, mc=0.25,
    air_factor=1.5,   # trochoidal loops / lead-ins
    relief_tool_d=3.0,
)


# --- Guards, hopper, base, cabinet, drive extras (ADDED; nothing above this block was changed) ---
PRINTER_X, PRINTER_Y, PRINTER_Z = 250.0, 210.0, 210.0   # Prusa MK3S build volume
PRINT_WALL = 3.0           # minimum printed wall (PETG)
PRINT_FLANGE = 4.0         # minimum printed flange thickness
HOPPER_TOP_Z = 305.0       # top of the funnel: 250 mm above the wall tops (z = 55)
HOPPER_TOP_IN = 180.0      # funnel inner opening, square
HOPPER_SPLIT_Z = 105.0     # collar / funnel joint (funnel 200 tall fits the 210 mm printer height)
TOP_HOLE_Y = 10.0          # |y| of the M5 holes in the TOP edge of each inner end-plate layer (≥5 mm from the Ø48 bore and the M6 joining holes)
TOP_HOLE_DEPTH = 10.0      # M5 tapped depth, down from z = +35
WALL_TOP_HOLE_X = 30.0     # wall top-edge M5 holes at x = 30 and chamber_L - 30, |y| = 71
WALL_TOP_HOLE_Y = 71.0

GUARD_HOLE_Y = 80.0        # 4 x M5 tapped through each cap only, at (+-GUARD_HOLE_Y, +-GUARD_HOLE_Z)
GUARD_HOLE_Z = 9.0
GUARD_CLEAR = 3.0          # gear guard inner clearance round the gears / washer / screw head
BASE_T = 18.0              # plywood
WORM_AXIS_DROP = 63.0      # worm input axis below the gearbox output axis (NMRV063 centre distance)


# --- Review round 2 (ADDED; nothing above this block was changed) ---
GROUND_Z = -368.0          # bench / floor level = underside of the cabinet; every timber leg stands here
# drawer, pull handle and tongue interlock (the drawer front has NO opening; the handle is screwed on from inside)
HANDLE_W = 110.0           # printed drawer pull (x)
HANDLE_H = 40.0            # (z)
HANDLE_BACK_T = 8.0        # back plate against the drawer front (2 heat-set inserts, 6 deep)
HANDLE_LIP_D = 26.0        # shelf depth in front of the drawer front (finger space under it)
HANDLE_Z = -200.0          # world z of the handle centre (about the middle of the full-height drawer front)
HANDLE_SCREW_DX = 35.0     # the 2 x M4 sit at x = cabinet centre +- this
HANDLE_HOLE_D = 4.5        # the ONLY holes in the drawer front: M4 clearance, filled by the screw, covered by the handle
INSERT_D = 5.6             # M4 heat-set insert hole
INSERT_DEPTH = 6.0
DRF_GAP = 1.0              # gap between the drawer front's top edge and the underside of the base plate
SW_PAD_L = 92.0            # hopper switch pad: 32 x 92, 2 x M4 at 22 mm
SW_PAD_W = 32.0
SW_PAD_T = 10.0
SW_SCREW_SPACING = 22.0
INTERLOCK_IN = 12.0        # lid switch: tongue insertion with the lid closed (>= 10)
INTERLOCK_OUT_TRAVEL = 15.0   # (kept for the hopper's interlock template)
# coupling guard (printed): a tunnel over the jaw coupling from the motor's face to the gearbox housing, on two feet screwed to the deck
CG_END_GAP = 1.0           # the tunnel's ends to the motor face and to the housing face
CG_FOOT_W = 36.0           # foot flange length (along y)
CG_FOOT_T = 4.0            # foot flange thickness
CG_FOOT_REACH = 16.0       # the flange sticks out this far beside the tunnel (2 x M5 x 20 wood screws each)
# drive deck (plywood) and timber legs
DECK_PLY_T = 18.0
DECK_MARGIN = 30.0         # deck margin round the motor foot, gearbox, coupling guard
LEG_SECTION = 45.0         # timber legs 45 x 45
FOOT_PLATE_L = 130.0       # steel foot plate under each base-wing leg: flat 50 x 10 x 130, 2 x M8 floor bolts, M8 hold-down stud tapped in
FOOT_PLATE_W = 50.0
FOOT_PLATE_T = 10.0
# torque-limiter test stub (from the user's Ø30 bar)
STUB_D = 25.0              # h6 end that the gearbox hollow shaft slides on
STUB_L = 80.0
STUB_END_D = 30.0          # vise end
STUB_END_L = 60.0
STUB_FLAT_AF = 22.0        # two flats for the vise: 20.4 wide each, corner lever arm 10.2 mm
STUB_FLAT_L = 40.0
STUB_KEY_L = 70.0          # 8 mm keyway, open at the Ø25 end

# --- Blade torque TEST LEVER (ADDED; nothing above this block was changed) ---
# Proves that a mild-steel blade's hex bore takes T_LIMIT: the shaft is held in a vise by two hex flats, ONE blade
# sits on the hex next to the drive-side Ø25 journal, a lever turns on that journal, a pin fixed in the lever
# bears on the straight HOOK face of one tooth, and TEST_WEIGHT_KG hangs at TEST_WEIGHT_ARM from the pivot.
# The lever turns OPPOSITE to the blade's cutting rotation (the direction plastic loads the hook face).
TEST_PIN_D = 12.0          # Ø12 hardened dowel pin (or the plain shank of an M12 12.9 bolt), pressed / screwed into the lever
TEST_PIN_R = 32.0          # pivot-to-pin-centre radius: smallest radius at which a Ø12 pin clears the blade root and
                           # gullet fillet and touches the STRAIGHT hook face is 30.9995 (build.py recomputes it from the
                           # real outline and fails if this is not "that + 1.0, rounded up to 0.5")
TEST_PIN_PROJ = 9.0        # pin projects this far from the lever face: across the blade (8) + the 1 mm gap
TEST_BLADE_GAP = 1.0       # lever face to blade face
TEST_LEVER_L = 540.0       # lever: flat 50 x 10 (mild steel), 540 long
TEST_LEVER_W = 50.0
TEST_LEVER_T = 10.0
TEST_LEVER_PIVOT_END = 25.0   # pivot centre this far from the end of the lever
TEST_LEVER_PIVOT_D = 25.2  # pivot hole on the Ø25 journal
TEST_WEIGHT_ARM = 500.0    # pivot to weight hole; TEST_WEIGHT_KG x 9.81 x 0.5 m + lever ~5 N*m = T_LIMIT
TEST_WEIGHT_HOLE_D = 10.5  # M10 shackle bolt
TEST_WEIGHT_KG = round((T_LIMIT - 5.0) / 0.5 / 9.81, 1)   # + the lever's own ~5 N*m = T_LIMIT
TEST_BLADE_ROT = -30.0     # tooth tip direction in the test frame (deg, + = from +y toward +z): the vise holds the hex on two
                           # flats facing +-y (hex vertices at 30, 90, 150 ...), blade variant 0 puts a vertex under every tip.
                           # The lever is horizontal at contact (points +y), so the weight acts on the full TEST_WEIGHT_ARM;
                           # the pin hole is offset sideways from the lever centreline
TEST_LEVER_DEG = 0.0       # lever direction at contact (deg, from +y toward +z): 0 = horizontal, pointing +y

# --- Review round 3 (ADDED; nothing above this block was changed) ---
# Safety interlock: a REAL tongue-actuated switch with positive-opening NC contacts (IEC 60947-5-1 Annex K) and its MATCHING coded
# metal actuator (e.g. Schneider XCSPA + its straight actuator, or Omron D4NS + D4DS-K1).  Every dimension below is an APPROXIMATE
# envelope of that class of device: drill to the datasheet of the switch you buy.  The printed parts only carry flat pads with
# PILOT_D holes for M4 thread-forming screws at the two hole spacings; re-drill the pads if your datasheet differs.
SW_BODY = [31.0, 30.0, 90.0]   # switch body, approx: [width across the mounting face, depth out of the mounting face, length (head at one end)]
SW_HOLE_SPACING = SW_SCREW_SPACING   # 22: the two M4 mounting holes of the switch, along its length, centred (keep)
SW_SLOT = [5.0, 23.0, 20.0]    # actuator entry slot in the head end face, approx: [thickness, width, depth]; the blade must pass through it
ACT_SIZE = [12.0, 20.0, 50.0]  # actuator envelope, approx: [height above its mounting face, width, length tip to tail]
ACT_BLADE_T = 3.0              # blade thickness (approx), centred in the actuator height
ACT_BLADE_L = 20.0             # blade length from the tip to the mounting block (approx); the block is ACT_SIZE[2] - ACT_BLADE_L = 30 long, holes 5 from its ends
ACT_HOLE_SPACING = 20.0        # the two M4 mounting holes of the actuator (approx), along its length, centred on the block
PILOT_D = 3.3                  # pilot hole in the printed pads for an M4 thread-forming screw (the pads are 10 mm or more thick)
PILOT_DEPTH = 8.0
# Torque-arm anchor bracket foot (hand-made from the 50 x 10 flat): 4 x M8 through the foot AND the 18 mm plywood wing, hex head + Ø16 washer on
# top, Ø24 penny washer + nyloc nut underneath.  The bolt rows sit BRK_BOLT_DY - 25 = 11 mm clear of the ears' end faces (ear faces at |dy| = 25),
# so a Ø16 washer, a 13 mm socket (Ø20) or a 6 mm key fits above every head; the columns are 11 mm from the arm's faces (tool radius 10).
BRK_TAB_DY0 = 26.5             # the tabs start at this |dy|; between them the foot is only as wide as the ears (34)


# --- Drive CAD dimensions (ADDED 2026-11-07 with the foot-mounted gearbox; all PLACEHOLDER envelopes unless said) ---
# The gearbox output is COAXIAL with shaft A (2026-11-15: no chain); its feet sit on two slotted rails on the deck, shimmed so the output lines up with A.
SUBPLATE_T = 20.0          # gearbox sub-plate: 20 mm steel plate (or 2 x 10), tapped M8 for the gearbox feet, 4 x M8 down into the deck
GB_BOX = [100.0, 100.0, 145.0]   # NRV063-VS housing envelope (placeholder, measure yours). Brief: "100 (x) x 145 x 100": read as x 100 along the output axis, y 100 along the worm
                           # axis, z 145 (z must be the 145: it holds the output axis AND the worm axis 63 below it)
GB_BELOW_OUT = 113.0       # foot flange underside this far below the output axis (worm axis is 50 above the foot). With the 20 mm sub-plate on the deck the worm axis is then 70 above
                           # the deck = the axis height of a motor (Ø120, foot 10) standing on the deck -> coaxial with the worm (jaw coupling). cad/drive_geom.scad asserts this
GB_BOSS = 9.0              # output hub boss between the housing face and the TL350 body
GB_FOOT = [124.0, 76.0]    # gearbox foot bolts, spacing (x, y): 4 x Ø9 -> M8 into the sub-plate (drill to the gearbox you buy)
GB_FLANGE = [140.0, 100.0, 8.0]  # foot flange x, y, thickness
GB_WORM_STUB = 40.0        # worm input shaft (Ø19) sticks out this far on each side of the housing
SPROCKET_T = 7.2           # sprocket tooth plate thickness (#40: 7.2)
SPROCKET_OD_EXTRA = 6.2    # tooth-tip OD = pitch dia + this  (#40 30T: 127.7)
SPROCKET_ROOT = 7.92       # root Ø = pitch Ø - this (#40 roller Ø 7.92): 113.6 for the 30T
CHAIN_ENV_W = 18.0         # #40 roller chain envelope: width over the pin ends (the setting fixture's chain whip)
CHAIN_ENV_H = 12.1         # ... and link plate height (centred on the pitch line)
DRIVE_LEG_MIN = 60.0       # shortest drive-deck leg
DG_SEAM_Z = 0.0            # the drive-end guard is split in two halves at this horizontal seam (through the shaft axes), so it closes round the pin flange
DG_FLANGE_W = 12.0         # seam ears
DG_FLANGE_T = 4.0
TLFIX_ARM = 500.0          # torque-limiter setting fixture: weight hole this far from the TL axis
TLFIX_LEVER_L = 600.0      # chain-whip lever: flat 50 x 10 x 600, pivots on the stub tip, the chain ends bolt to it
TLFIX_LEVER_W = 50.0
TLFIX_LEVER_T = 10.0

# --- Review round 5: TL350 to the manufacturer's layout, gearbox output shaft, rails, deck hold-down, TL fixture (ADDED; nothing above changed) ---
# Tsubaki TL350: hub length L = 62 (TL["L"]), hub OD DH = 42, outer D = 89 (flange, plates, spring, nut), centre member (the sprocket) S <= 16
# sits on a bushing between the hub flange and the pressure plate, near the FLANGE end.  The spring and the adjusting nut are on the far end.
TL_HUB_D = 42.0            # hub OD DH
TL_FLANGE_T = 8.0          # hub flange thickness
TL_CM_OFFSET = 12.0        # hub flange-end face to the mid-plane of the sprocket (centre member)
TL_GB_GAP = 3.0            # Ø36 spacer on the output shaft between the housing face and the pin flange's hub
TL_PACK_D = 70.0           # friction pack (linings + bushing) between the flange and the pressure plate, envelope
TL_PRESS_T = 8.0           # pressure plate (after the 8 mm friction pack: 16 from the flange-end face)
TL_SPRING_L = 26.0         # disc spring stack after the pressure plate (24 .. 50); the adjusting nut takes the last 12 of the hub (50 .. 62)
GB_HUB_L = 72.0            # PLACEHOLDER, measure: width of the gearbox housing along the output axis = length of the hollow output hub (supersedes GB_BOX[0]);
                           # the output shaft passes through all of it. make variants also tries 80
OUT_SPACER_D = 36.0        # shaft spacer (TL_GB_GAP long) between the housing face and the pin flange's hub
SHAFT_KEY_W, SHAFT_KEY_D = 8.0, 4.0     # keyways 8 x 4 in the output shaft: gearbox key (along the hollow hub) and pin-flange key
GB_KEY_END = 6.0           # gearbox keyway stops this far inside each end of the hub
TL_KEY_END = 3.0           # TL keyway stops this far inside each end of the TL hub
# DIN 471 circlip for a Ø25 shaft against the housing's far face (the other side: spacer + pin flange on its key + grub screw)
CIRCLIP_GROOVE_D, CIRCLIP_GROOVE_W = 23.9, 1.3
CIRCLIP_T, CIRCLIP_OD = 1.2, 31.4       # ring 25 x 1.2; installed OD about 31.4
CIRCLIP_EDGE = 3.0         # shaft end beyond the groove
# gearbox rails: 2 x flat 50 x 10 under the foot rows, slots along x for the axial alignment (pin flange gap), on 10 mm spacer blocks (SUBPLATE_T = rail + spacer)
GB_RAIL_W, GB_RAIL_T = 50.0, 10.0
GB_RAIL_SLOT = 6.0         # slots run +-6 mm along x
GB_RAIL_BOLT_DX = 86.0     # M8 deck bolts at +-this from the housing centre, outside the foot flange (x +-70)
GB_RAIL_END = 10.0         # rail ends this far beyond the deck bolts
GB_SPACER_L = 18.0         # spacer block under each rail end (x), 50 x 10 flat cut off
DECK_RAIL_MARGIN = 20.0    # deck margin beyond the rails' +x end (the 30 mm DECK_MARGIN would run into the cabinet)
# hold-down: the gearbox's reaction torque (= the shaft torque, at most T_LIMIT) lifts one foot row; load path = gearbox feet -> rails (M8) -> deck -> leg angles -> legs -> foot angles -> floor anchors
DECK_ANCHOR = "M8"         # floor / bench anchor (wedge or drop-in anchor, or an M8 coach screw into the bench)
DECK_ANCHOR_D = 8.0
DECK_ANGLE = [40.0, 40.0, 4.0]  # steel angle 40 x 40 x 4 (a stock section)
DECK_ANGLE_L = 44.0        # length of each angle piece (a hair under the 45 leg: the two angles on one leg never touch)
DECK_ANGLE_DECK_BOLTS = 2  # M8 through-bolts: deck <-> top angle (per leg)
DECK_ANGLE_LEG_BOLTS = 2   # M8 through-bolts: top angle <-> leg (per leg)
FOOT_ANGLE_LEG_BOLTS = 2   # M8 through-bolts: foot angle <-> leg (per leg)
FOOT_ANGLE_ANCHORS = 2     # M8 anchors: foot angle <-> floor (per leg)
BIG_WASHER_D, BIG_WASHER_T = 24.0, 2.0   # penny washers on the plywood and the timber
DECK_LEG_INSET_Y = 45.0    # legs stand this far in from the deck's y edges (room for the top angles' flanges under the deck)
# TL setting fixture: the lever PIVOTS on a Ø25 pin that continues the stub beyond the TL (outboard of the adjusting nut)
TLFIX_PIN_L = 25.0         # Ø25 pin beyond the TL nut face
TLFIX_LEVER_GAP = 5.0      # TL nut face to the lever
TLFIX_PIVOT_D = 25.2       # lever pivot bore
TLFIX_LUG = [20.0, 20.0]   # the two chain-end lugs between the lever and the chain (section)
TLFIX_LUG_GAP = 2.4        # lug end to the chain edge

# --- Review round 4 (ADDED; nothing above this block was changed) ---
# SAFETY ARRANGEMENT.  The generic SW_BODY / SW_SLOT / ACT_* envelope of round 3 (above) is SUPERSEDED: the CAD no longer reads it (it is left here so nothing else breaks).
# Each switch now has its own envelope.  A "screw" is [thread Ø, clearance hole Ø, head Ø, head height, pilot Ø in the printed pad].
#
# (1) HOPPER LID: Pizzato FS 3096D024-F7 guard-locking switch ("standard DIN size" FS body) + its jointed adjustable actuator VF KEYF7 (comes with the switch).
#     *** EVERY NUMBER IN THIS BLOCK IS APPROXIMATE (from the brief, not from a datasheet): VERIFY WITH PIZZATO'S 2D DRAWING BEFORE DRILLING. ***
HSW_BODY = [42.0, 38.0, 112.0]   # APPROX [width across the mounting face, depth out of the mounting face, length incl. the head]; the actuator entry is in the TOP (head) face
HSW_HOLE_SPACING = 22.0          # APPROX: 2 x M4 along the length, ~22 apart (centred on the length in the CAD)
HSW_SLOT = [6.0, 24.0, 25.0]     # APPROX entry slot in the head face [thickness, width, depth] (guess: the jointed actuator needs side play)
HACT_BLOCK_L = 46.0              # APPROX VF KEYF7 body/mounting block 46 x 20 x 15 (from the brief); I read the 46 as the BLOCK, because 2 x M5 holes 30 apart need
                                 # a block of at least ~38 and the tongue must then stick out of it by HACT_BLADE_L (an overall 46 would leave no tongue).  CHECK THIS.
HACT_BLADE_L = 22.0              # APPROX tongue length beyond the block (>= INTERLOCK_IN)
HACT_SIZE = [15.0, 20.0, HACT_BLOCK_L + HACT_BLADE_L]   # APPROX [height above its mounting face, width, length tip to tail] (46 block + 22 tongue = 68)
HACT_BLADE_T = 3.0               # APPROX tongue thickness
HACT_HOLE_SPACING = 30.0         # APPROX: 2 x M5 holes ~30 apart, centred on the block
HSW_SCREW = [4.0, 4.5, 7.0, 3.0, 3.3]   # M4 pan head into the Ø3.3 pilots of the funnel pad
HACT_SCREW = [5.0, 5.5, 8.5, 3.5, 4.2]  # M5 pan head, Ø4.2 pilots (thread-forming, PETG) in the lid actuator pad
HSW_PAD_W = 48.0                 # width (across) of the printed switch pad on the funnel: the 42 wide body + 3 each side
# --- FIXED SCREEN (2026-11-15, user: "machine ... the shape of the bottom of the blades with holes so only small enough pieces will pass and the
# others will have to keep shredding").  It REPLACES the vibrating screen, the wire-mesh safety grid, the fixed upper front panel, the drawer switch and the
# printed side skirts.  One aluminium block (6061 / 6082, CNC4030), its top a "W": two arcs SCREEN_GAP under the blade-tip circles of A and B, meeting in a
# ridge between the shafts and rising on the outer sides to the combs' underside, then flat WINGS that are screwed up against the combs (6 x M4 into the comb's
# tapped holes at |y| = SKIRT_HOLE_Y).  Ø5 holes drilled straight down (z) where the top is no steeper than SCREEN_HOLE_SLOPE.  Oversize stays on the
# screen and the teeth drag it round to the combs and back into the bite until it passes.  The screen is also the guard from below: ISO 13857 Table 4,
# round openings 4 < e <= 6 need >= 5 mm to the hazard; here hole length + gap >= 8.
SCREEN_GAP = 2.0           # blade-tip circle (R_TIP) to the screen's top surface, radial
SCREEN_T = 10.0            # Ø5 land under the top (the bottom is FLAT at R_TIP + SCREEN_GAP + SCREEN_T under the axes; deeper down each hole is relieved); calc s.13
SCREEN_RELIEF_D = 6.5      # relief drilled up from the flat bottom so every Ø5 hole is only SCREEN_T long (long thin holes clog); 1.5 mm webs on the 8 mm pitch
SCREEN_HOLE_D = 5.0        # the largest piece that passes
SCREEN_HOLE_PITCH = 8.0    # hexagonal pattern (3 mm ligaments: calc s.13)
SCREEN_HOLE_SLOPE = 50.0   # deg: holes only where the top surface is at most this steep (they are drilled vertically)
SCREEN_END_GAP = 0.5       # each end face of the screen to the end plate's inner face
SCREEN_SCREW = [4.0, 4.5, 7.0, 4.0, 8.5]   # M4 x 16 socket head up into the comb: [thread, clearance hole, head Ø, head h, counterbore Ø]
SCREEN_SCREW_Y = 74.0      # |y| of the 4 screws (2 per comb, at x = L/3 and 2L/3: between the wall screws at x = 20, L/2, L-20)
SCREEN_TAP_DEPTH = 9.0     # M4 tapped up into the comb's underside (the comb is 10 thick; the wall sits on top of it there)
SCREEN_SCREW_LAND = 8.0    # wing material under the comb at each screw (the counterbore comes up from the underside to here)
SCREEN_POCKET = [11.0, 6.0]   # pockets in the wing top round the M5 heads of the wall screws (under the comb at |y| = 71): Ø, depth
WALL_SCREW_HEAD = [8.5, 5.0]  # M5 socket head of the wall screws (from below, through the comb into the wall)
BASE_CUT_Y = 83.0          # |y| of the base plate cut-out's long edges (was 55): the screen's screws are reached from below and the screen drops out
PSU_24V_W = 30.0           # 24 V supply (only the lid lock's solenoid now)
LID_SOLENOID_W = 10.0      # Pizzato FS 3096D024 solenoid, approx (datasheet: verify)


def derived():
    """Dimensions that follow from the inputs above."""
    d = {}
    half = N_SLOTS // 2
    d["blades_per_shaft"] = half
    d["stack_A"] = half * T_BLADE + half * T_SPACER                 # B S B S ... B S
    d["end_spacer_B"] = T_SPACER - SIDE_CLEAR                       # 8.20: centres B's blades
    d["stack_B"] = d["end_spacer_B"] + (half - 1) * T_SPACER + half * T_BLADE
    d["chamber_L"] = d["stack_A"] + 2 * END_CLEAR                   # inner face to inner face
    d["overlap"] = 2 * R_TIP - C
    d["tip_to_spacer"] = C - R_TIP - SPACER_OD / 2
    d["hex_AC"] = HEX_AF / 0.8660254
    d["bore_AC"] = HEX_BORE_AF / 0.8660254
    # bearing centres: half a bearing width outboard of the inner/outer layer joint
    d["bearing_x_drive"] = -LAYER_T - BEARING["B"] / 2               # -18.5
    d["bearing_x_free"] = d["chamber_L"] + LAYER_T + BEARING["B"] / 2
    d["bearing_span"] = d["bearing_x_free"] - d["bearing_x_drive"]
    # clamp sleeves: inner ring face to stack end
    d["sleeve_L_drive"] = LAYER_T + END_CLEAR                        # 10.5
    d["sleeve_L_free_A"] = LAYER_T + END_CLEAR                       # 10.5
    d["sleeve_L_free_B"] = LAYER_T + END_CLEAR + (d["stack_A"] - d["stack_B"])  # 10.70
    # drive end, outward: inner ring (-27..-10) | collared sleeve body (-34..-27: 3 mm cap step + 4 mm
    # thrust bearing on the cap face at -30) + collar (-38..-34) | gear (teeth, hub) | sleeve | OUTBOARD bearing | sleeve | (A only) sprocket | end cap.
    # The gear sits between the drive bearing and the OUTBOARD bearing plate (2026-11-13); the sprocket on A is outboard of that plate and
    # its teeth (R 33.7) clear B's end cap (R 15) by 11 mm.
    d["x_inner_ring_out_drive"] = -LAYER_T - BEARING["B"]            # -27
    d["x_cap_out_drive"] = -3 * LAYER_T                              # -30
    d["collar_body_L_drive"] = (d["x_inner_ring_out_drive"] - d["x_cap_out_drive"]) + THRUST["T"]   # 7
    d["x_collar_in_drive"] = d["x_cap_out_drive"] - THRUST["T"]      # -34
    d["x_collar_out_drive"] = d["x_collar_in_drive"] - COLLAR_T      # -38
    d["gear_face"] = GEAR_FACE
    d["x_gear_in"] = d["x_collar_out_drive"]                        # -38: teeth next to the collar
    d["x_gear_out"] = d["x_gear_in"] - GEAR_FACE                     # -68
    d["x_gear_hub_out"] = d["x_gear_out"] - GEAR_HUB_L               # -86: outer face of the gear's hub
    # OUTBOARD BEARING PLATE: 2 layers, OB_GAP outside the hub; the NA4905 sits in a 17 mm pocket between OB_STEP steps
    d["x_ob_in"] = d["x_gear_hub_out"] - OB_GAP                      # -88: inner face (gear side)
    d["x_ob_out"] = d["x_ob_in"] - 2 * OB_T                          # -108: outer face
    d["x_ob_ring_in"] = d["x_ob_in"] - OB_STEP                       # bearing (outer + inner ring) inner face
    d["x_ob_ring_out"] = d["x_ob_ring_in"] - BEARING["B"]            # ... outer face
    d["bearing_x_ob"] = (d["x_ob_ring_in"] + d["x_ob_ring_out"]) / 2   # -98
    d["gear_spacer_L"] = d["x_gear_hub_out"] - d["x_ob_ring_in"]      # 3.5: Ø30 sleeve, gear hub -> outboard inner ring
    d["x_sprocket_in"] = d["x_ob_out"] - OB_GAP                      # -110: B's outer sleeve end = B's end cap
    d["ob_sleeve_L"] = d["x_ob_ring_out"] - d["x_sprocket_in"]       # 3.5: Ø30 sleeve, outboard inner ring -> end cap (B)
    # shaft A's drive end, outward: outer sleeve (long) | TL350 FLIPPED (nut end inward, flange end outward, its 30T sprocket TL_CM_OFFSET in from the outer end) | end cap + M10
    d["x_spA_in"] = d["x_sprocket_in"] - END_WASHER_T - 10.0 - TL_B_CLEAR   # -135: the TL's nut-end face = A's outer sleeve end
    d["x_sprocket_out"] = d["x_spA_in"] - TL["L"]                    # -197: the TL hub's outer (flange-end) face = A's clamp point (end cap)
    d["x_cm"] = d["x_sprocket_out"] + TL_CM_OFFSET                   # -185: the TL's sprocket plate (centre member) = where the pins drive it
    d["a_end_hub_L"] = TL["L"]
    d["ob_sleeve_A_L"] = d["x_ob_ring_out"] - d["x_spA_in"]          # 28.5: A's outer sleeve (longer than B's)
    d["standoff_L"] = d["x_cap_out_drive"] - d["x_ob_in"]            # 58 between the faces (+ 2 spigots)
    d["x_sprocket_c"] = (d["x_spA_in"] + d["x_sprocket_out"]) / 2
    # free end, outward: inner ring | collared sleeve body (3 cap step + crinkle stack + thrust) + collar | end cap
    d["x_inner_ring_out_free"] = d["chamber_L"] + LAYER_T + BEARING["B"]
    d["x_cap_out_free"] = d["chamber_L"] + 3 * LAYER_T
    d["collar_body_L_free"] = (d["x_cap_out_free"] - d["x_inner_ring_out_free"]) + CRINKLE["stack_h"] + THRUST["T"]   # 9
    d["x_collar_in_free"] = d["x_inner_ring_out_free"] + d["collar_body_L_free"]
    d["x_collar_out_free"] = d["x_collar_in_free"] + COLLAR_T
    d["shaft_end_free"] = d["x_collar_out_free"] - SHAFT_END_RECESS
    d["shaft_end_A_drive"] = d["x_sprocket_out"] + SHAFT_END_RECESS
    d["shaft_end_B_drive"] = d["x_sprocket_in"] + SHAFT_END_RECESS
    d["shaft_A_len"] = d["shaft_end_free"] - d["shaft_end_A_drive"]
    d["shaft_B_len"] = d["shaft_end_free"] - d["shaft_end_B_drive"]
    d["tl_sprocket_pd"] = CHAIN["pitch"] / math.sin(math.pi / TL["z"])
    d["sprocket_A_pd"] = d["tl_sprocket_pd"]                         # the TL's own 30T sprocket on A
    d["tl_sprocket_root_d"] = d["tl_sprocket_pd"] - SPROCKET_ROOT    # 113.6: the pin holes stay inside it
    # hex section: from 1.0 mm inside the first stack element to 1.0 mm inside the last
    d["hex_x0"] = END_CLEAR + 1.0
    d["hex_x1"] = END_CLEAR + d["stack_A"] - 1.0
    d["gear_pitch_d"] = GEAR["module"] * GEAR["z"]
    assert abs(d["gear_pitch_d"] - C) < 1e-9, "1:1 gears: the pitch diameter must equal the shaft centre distance C"
    d["gear_od"] = GEAR["module"] * (GEAR["z"] + 2)                   # 63.0
    d["gear_root_d_std"] = GEAR["module"] * (GEAR["z"] - 2.5)         # 56.25 (dedendum 1.25 m)
    d["gear_root_d"] = d["gear_root_d_std"] - 2 * GEAR_CUT_EXTRA      # 56.05 as cut (0.10 deeper)
    d["gear_cut_depth"] = (d["gear_od"] - d["gear_root_d"]) / 2       # 3.475
    d["comb_edge_y"] = C / 2 + SPACER_OD / 2 + COMB_GAP              # from machine centre
    d["comb_slot_w"] = T_BLADE + 2 * COMB_SLOT_CLEAR
    d["comb_slot_bottom_y"] = C / 2 + R_TIP + COMB_SLOT_PAST_TIP          # 67
    d["wall_inner_y"] = C / 2 + R_TIP + WALL_GAP
    return d


if __name__ == "__main__":
    for k, v in derived().items():
        print(f"{k:24s} {v:9.3f}")

