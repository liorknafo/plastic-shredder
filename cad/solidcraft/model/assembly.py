"""assembly.py -- the components of the SolidCraft assembly and the groups of bodies of each, at angle 0, lid closed,
drawer closed.  A group is one line of the old parts list (one colour); its bodies are the parts in it.
Body names are unique in the whole design.
"""
import importlib
import os

from common import *
import stack
import placeholders as ph
from shaft import shaft_local


def rot0(sh, *ch):
    return translate([0, shaft_y(sh), 0], *ch)                 # = rot_frame(sh, 0)


def rotor(sh):
    bc = ORANGE if sh == "A" else BLUE
    bodies = [
        Body("Shaft " + sh, lambda: rot0(sh, shaft_local(sh)), DARK),
        Body("Blades " + sh, lambda: rot0(sh, stack.blades_of(sh)), bc),
        Body("Spacers " + sh, lambda: rot0(sh, stack.spacers_of(sh)), GRAY),
        Body("Clamp + collared sleeves " + sh,
             lambda: rot0(sh, stack.clamp_sleeves_of(sh), stack.collared_sleeves_of(sh),
                          part(f"Gear spacer sleeve {sh}", ph.gear_spacer_ph()),
                          part(f"Outboard sleeve {sh}", ph.ob_sleeve_ph(sh))), YELLOW),
        Body("Gear m4 z15 " + sh, lambda: rot0(sh, part(f"Gear m4 z15 {sh}", ph.gear_ph(sh))), RED, 0.75),
    ]
    if sh == "A":
        bodies.append(Body("Torque limiter TL350 (30T)", lambda: rot0(sh, part("Torque limiter TL350-2", ph.sprocket_ph())), "#8e6fb0"))
    bodies.append(Body("End screws " + sh, lambda: rot0(sh, part(f"End cap + M10 screw {sh} (drive end)", ph.end_screw_drive(sh)),
                                                         part(f"End cap + M10 screw {sh} (free end)", ph.end_screw_free())), DARK))
    return bodies


# the components in the order they are made (the first one, the Frame, is the grounded one), and the modules whose
# BODIES hold their groups
ORDER = ["Frame", "Rotor A", "Rotor B", "Lid", "Drawer", "Output shaft + pin flange", "Worm + jaw coupling", "Motor shaft"]
SOURCES = ["frame", "hopper", "base", "drive"]
if os.environ.get("SHREDDER_SOURCES"):                         # a partial build: SHREDDER_SOURCES=frame,hopper
    SOURCES = os.environ["SHREDDER_SOURCES"].split(",")
# the Frame's groups in the order of the old parts list
FRAME_ORDER = [
    "Bearings NA4905 (6)", "Bearing rollers", "Seals", "Thrust bearings", "Crinkle washers", "End plates (free end)",
    "End plates (drive end)", "Outboard bearing plate + pillars", "Combs", "Chamber walls", "Hopper collar + funnel",
    "Lid guard-lock switch + screws", "Fixed screen (aluminium)", "Screen + wall screws",
    "Gear band, drive-end hood + free-end cover", "Base plate", "Cabinet (sides, back, floor)", "Worm gearbox NRV063",
    "Gearbox + rail bolts", "Gearbox rails", "Motor", "Coupling guard + stub cap", "Coupling guard screws",
    "Drive deck + legs", "Leg angles", "Deck + leg bolts", "Floor anchors"]


def _components():
    groups = {"Rotor A": rotor("A"), "Rotor B": rotor("B")}
    for name in SOURCES:
        try:
            mod = importlib.import_module(name)
        except ModuleNotFoundError as e:
            if e.name != name:
                raise
            continue                                            # a module that is not written yet
        for comp, bodies in mod.BODIES.items():
            groups.setdefault(comp, []).extend(bodies)
    if "Frame" in groups:
        groups["Frame"].sort(key=lambda b: FRAME_ORDER.index(b.name))
    return [(comp, groups[comp]) for comp in ORDER if comp in groups]


COMPONENTS = _components()
