"""manifest.py -- the components of the SolidCraft assembly and the coloured bodies of each.

Colours are those of cad/assembly.scad (Tomorrow palette); alpha as there (GA = 0.55, deck_alpha = 0.85).
Each body is (display name, key `sel` of parts.scad, colour, alpha[, shaft]).  The key of a rotor body is exported once per shaft (-D sel=... -D sh="A"|"B").
"""
RED, ORANGE, YELLOW, GREEN = "#c82829", "#f5871f", "#eab700", "#718c00"
AQUA, BLUE, PURPLE, GRAY, DARK = "#3e999f", "#4271ae", "#8959a8", "#8e908c", "#4d4d4c"
PRINT, METAL = "#e69138", "#b0b4b8"

FRAME = ("Frame", [
    ("Bearings NA4905 (6)",        "f_bearings",   AQUA, 1),
    ("Bearing rollers",            "f_rollers",    "#9fd4d8", 1),
    ("Seals",                      "f_seals",      "#222222", 1),
    ("Thrust bearings",            "f_thrust",     "#c8c8c8", 1),
    ("Crinkle washers",            "f_crinkle",    "#d8b0ff", 1),
    ("End plates (free end)",      "f_plates_free",  "#b4b7b4", 1),
    ("End plates (drive end)",     "f_plates_drive", "#c5c8c6", 1),
    ("Outboard bearing plate + pillars", "f_plates_ob", "#a9b0b8", 1),
    ("Combs",                      "f_combs",      GREEN, 1),
    ("Chamber walls",              "f_walls",      PURPLE, 1),
    ("Hopper collar + funnel",     "f_hopper",     "#6fa8dc", 0.30),
    ("Lid guard-lock switch + screws", "f_lidswitch", DARK, 1),
    ("Fixed screen (aluminium)",   "f_screen",     "#9aa5b1", 1),
    ("Screen + wall screws",       "f_screenscrews", DARK, 1),
    ("Gear band, drive-end hood + free-end cover", "f_guards", PRINT, 0.55),
    ("Base plate",                 "f_baseplate",  "#d9b98a", 1),
    ("Cabinet (sides, back, floor)", "f_cabinet",  "#c8a46e", 0.55),
    ("Worm gearbox NRV063",        "f_gearbox",    GRAY, 0.6),
    ("Gearbox + rail bolts",       "f_gbbolts",    DARK, 1),
    ("Gearbox rails",              "f_rails",      METAL, 1),
    ("Motor",                      "f_motor",      DARK, 1),
    ("Coupling guard + stub cap",  "f_cplguard",   PRINT, 0.55),
    ("Coupling guard screws",      "f_cplguardhw", DARK, 1),
    ("Drive deck + legs",          "f_deck",       "#c8a46e", 0.85),
    ("Leg angles",                 "f_angles",     METAL, 1),
    ("Deck + leg bolts",           "f_deckbolts",  DARK, 1),
    ("Floor anchors",              "f_anchors",    RED, 1),
])

def rotor(sh):
    bc = ORANGE if sh == "A" else BLUE
    bodies = [      # body names carry the shaft letter: body names must be unique in the whole design
        ("Shaft " + sh,   "r_shaft",   DARK, 1, sh),
        ("Blades " + sh,  "r_blades",  bc, 1, sh),
        ("Spacers " + sh, "r_spacers", GRAY, 1, sh),
        ("Clamp + collared sleeves " + sh, "r_sleeves", YELLOW, 1, sh),
        ("Gear m4 z15 " + sh, "r_gear", RED, 0.75, sh),
    ]
    if sh == "A":
        bodies.append(("Torque limiter TL350 (30T)", "r_sprocket", "#8e6fb0", 1, sh))
    bodies.append(("End screws " + sh, "r_screws", DARK, 1, sh))
    return ("Rotor " + sh, bodies)

LID = ("Lid", [
    ("Lid + actuator pad",        "l_lid", PRINT, 0.45),
    ("Lid screws (pad, actuator)", "l_hw",  DARK, 1),
    ("Lid actuator key",          "l_key", METAL, 1),
])
DRAWER = ("Drawer", [
    ("Drawer front + bin",        "d_panels",  "#bf9000", 1),
    ("Handle",                    "d_printed", PRINT, 1),
    ("Handle screws",             "d_screws",  DARK, 1),
])
TL = ("Output shaft + pin flange", [
    ("Output shaft 4140",         "t_shaft", "#2b6cb0", 1),
    ("Pin flange + 4 pins",       "t_tl",    "#9aa5b1", 1),
    ("Circlip, spacer, stop collar", "t_hw", YELLOW, 1),
])
WORM = ("Worm + jaw coupling", [
    ("Worm",           "w_worm",     DARK, 1),
    ("Jaw coupling",   "w_coupling", "#c45a1a", 1),
])
MOTOR = ("Motor shaft", [
    ("Motor shaft",  "m_shaft",  DARK, 1),
])

COMPONENTS = [FRAME, rotor("A"), rotor("B"), LID, DRAWER, TL, WORM, MOTOR]
