"""frame.py -- the fixed bodies round the cutting chamber: bearings (6: drive end, free end, outboard plate), seals,
thrust / crinkle washers, end plates, the outboard bearing plate + pillars, combs, chamber walls, the drive-end guard
(gear band + hood) and the free-end cover (the Frame groups of cad/assembly.scad).
"""
from common import *
import placeholders as ph
from plate import end_plates, standoffs
from comb import comb
from wall import wall
from guards import free_end_cover, drive_end_guard

SHAFTS = ("A", "B")
ENDS = ("drive", "free")
BEARING_ENDS = ("drive", "free", "ob")             # the third bearing of each shaft is in the outboard plate (no seal there: it is inside the guard)


def at_shafts(name, fn, ends=ENDS):
    """`fn(e)` on both shafts at each end, one part per position: translate([0, shaft_y(s), 0]) ..."""
    return union(translate([0, shaft_y(s), 0], part(f"{name} {s} ({'outboard plate' if e == 'ob' else e + ' end'})", fn(e)))
                 for s in SHAFTS for e in ends)


BODIES = {
    "Frame": [
        Body("Bearings NA4905 (6)", lambda: at_shafts("Bearing NA4905 rings", lambda e: [ph.bearing_inner_ph(e), ph.bearing_outer_ph(e)], BEARING_ENDS), AQUA),
        Body("Bearing rollers", lambda: at_shafts("Bearing NA4905 rollers", ph.bearing_rollers_ph, BEARING_ENDS), "#9fd4d8"),
        Body("Seals", lambda: at_shafts("Oil seal 30x42x7", ph.seal_ph), "#222222"),
        Body("Thrust bearings", lambda: at_shafts("Thrust bearing AXK3047", ph.thrust_ph), "#c8c8c8"),
        Body("Crinkle washers", lambda: at_shafts("Crinkle washer stack", lambda e: ph.crinkle_ph(), ["free"]), "#d8b0ff"),
        # plates(layers, ends) of cad/stack.scad = end_plates(layers, ends): layers 0 inner, 1 outer, 2 cap, 3 ob1, 4 ob2
        Body("End plates (free end)", lambda: end_plates([0, 1, 2], ["free"]), "#b4b7b4"),
        Body("End plates (drive end)", lambda: end_plates([0, 1, 2], ["drive"]), "#c5c8c6"),
        Body("Outboard bearing plate + pillars", lambda: union(end_plates([3, 4], ["drive"]), standoffs()), "#a9b0b8"),
        Body("Combs", lambda: union(part("Comb A", comb("A")), part("Comb B", comb("B"))), GREEN),
        Body("Chamber walls", lambda: union(part("Chamber wall B", wall(1)), part("Chamber wall A", wall(-1))), PURPLE),
        Body("Gear band, drive-end hood + free-end cover", lambda: union(part("Free-end cover", free_end_cover()), drive_end_guard()), PRINT, 0.55),
    ],
}
