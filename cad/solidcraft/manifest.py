"""manifest.py -- the components of the SolidCraft assembly and the coloured bodies of each.

Colours are those of cad/assembly.scad (Tomorrow palette); alpha as there (GA = 0.55, deck_alpha = 0.85).
Each body is (display name, key `sel` of parts.scad, colour, alpha[, shaft]).  The key of a rotor body is exported once per shaft (-D sel=... -D sh="A"|"B").
"""
RED, ORANGE, YELLOW, GREEN = "#c82829", "#f5871f", "#eab700", "#718c00"
AQUA, BLUE, PURPLE, GRAY, DARK = "#3e999f", "#4271ae", "#8959a8", "#8e908c", "#4d4d4c"
PRINT, METAL = "#e69138", "#b0b4b8"

FRAME = ("Frame", [
    ("Bearings NA4905",            "f_bearings",   AQUA, 1),
    ("Bearing rollers",            "f_rollers",    "#9fd4d8", 1),
    ("Seals",                      "f_seals",      "#222222", 1),
    ("Thrust bearings",            "f_thrust",     "#c8c8c8", 1),
    ("Crinkle washers",            "f_crinkle",    "#d8b0ff", 1),
    ("End plates (free end)",      "f_plates_free",  "#b4b7b4", 1),
    ("End plates (drive end)",     "f_plates_drive", "#c5c8c6", 1),
    ("Combs",                      "f_combs",      GREEN, 1),
    ("Chamber walls",              "f_walls",      PURPLE, 1),
    ("Hopper collar + funnel",     "f_hopper",     "#6fa8dc", 0.30),
    ("Lid guard-lock switch + screws", "f_lidswitch", DARK, 1),
    ("Side skirts",                "f_skirts",     PRINT, 0.55),
    ("Drive-end guard + free-end cover", "f_guards", PRINT, 0.55),
    ("Base plate",                 "f_baseplate",  "#d9b98a", 1),
    ("Cabinet (sides, back, floor)", "f_cabinet",  "#c8a46e", 0.55),
    ("Fixed upper front panel",    "f_upperfront", "#8c5a2b", 0.8),
    ("Drawer switch pad",          "f_drawerpad",  PRINT, 1),
    ("Drawer switch + screws, front panel screws", "f_drawersw", DARK, 1),
    ("Safety grid mesh",           "f_mesh",       "#6b7076", 1),
    ("Grid cleats",                "f_cleats",     "#a67c52", 1),
    ("Grid screws",                "f_gridscrews", DARK, 1),
    ("Worm gearbox NRV063",        "f_gearbox",    GRAY, 0.6),
    ("Gearbox + rail + tensioner bolts", "f_gbbolts", DARK, 1),
    ("Gearbox rails",              "f_rails",      METAL, 1),
    ("Chain idler sprocket",       "f_idler",      ORANGE, 0.9),
    ("Chain tensioner",            "f_tensioner",  RED, 1),
    ("Chain #40",                  "f_chain",      "#444444", 0.9),
    ("Motor",                      "f_motor",      DARK, 1),
    ("V-belt",                     "f_belt",       "#222222", 0.8),
    ("Belt guard",                 "f_beltguard",  PRINT, 0.55),
    ("Belt guard hardware",        "f_beltguardhw", DARK, 1),
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
        ("Gear m1.5 z40 " + sh, "r_gear", RED, 0.75, sh),
    ]
    if sh == "A":
        bodies.append(("Sprocket 15T A", "r_sprocket", ORANGE, 0.9, sh))
    bodies.append(("End screws " + sh, "r_screws", DARK, 1, sh))
    return ("Rotor " + sh, bodies)

LID = ("Lid", [
    ("Lid + actuator pad",        "l_lid", PRINT, 0.45),
    ("Lid screws (pad, actuator)", "l_hw",  DARK, 1),
    ("Lid actuator key",          "l_key", METAL, 1),
])
DRAWER = ("Drawer", [
    ("Drawer front + bin",        "d_panels",  "#bf9000", 1),
    ("Handle + actuator pad",     "d_printed", PRINT, 1),
    ("Handle + actuator screws",  "d_screws",  DARK, 1),
    ("Drawer actuator key",       "d_key",     METAL, 1),
])
TL = ("Torque limiter + output shaft", [
    ("Output shaft 4140",         "t_shaft", "#2b6cb0", 1),
    ("Torque limiter TL350",      "t_tl",    "#8e6fb0", 1),
    ("Circlip, spacer, stop collar", "t_hw", YELLOW, 1),
])
WORM = ("Worm + gearbox pulley", [
    ("Worm",           "w_worm",   DARK, 1),
    ("Gearbox pulley", "w_pulley", DARK, 1),
])
MOTOR = ("Motor shaft + pulley", [
    ("Motor shaft",  "m_shaft",  DARK, 1),
    ("Motor pulley", "m_pulley", DARK, 1),
])

COMPONENTS = [FRAME, rotor("A"), rotor("B"), LID, DRAWER, TL, WORM, MOTOR]
