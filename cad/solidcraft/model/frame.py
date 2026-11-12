"""frame.py -- the fixed bodies round the cutting chamber: bearings, seals, thrust / crinkle washers, end plates, combs,
chamber walls, side skirts, drive-end guard and free-end cover (the Frame groups of cad/solidcraft/parts.scad).
"""
from common import *
import placeholders as ph
from plate import end_plates
from comb import comb
from wall import wall
from guards import skirt, free_end_cover, drive_end_guard

SHAFTS = ("A", "B")
ENDS = ("drive", "free")


def at_shafts(name, fn, ends=ENDS):
    """`fn(e)` on both shafts at each end, one part per position: translate([0, shaft_y(s), 0]) ..."""
    return union(translate([0, shaft_y(s), 0], part(f"{name} {s} ({e} end)", fn(e))) for s in SHAFTS for e in ends)


BODIES = {
    "Frame": [
        Body("Bearings NA4905", lambda: at_shafts("Bearing NA4905 rings", lambda e: [ph.bearing_inner_ph(e), ph.bearing_outer_ph(e)]), AQUA),
        Body("Bearing rollers", lambda: at_shafts("Bearing NA4905 rollers", ph.bearing_rollers_ph), "#9fd4d8"),
        Body("Seals", lambda: at_shafts("Oil seal 30x42x7", ph.seal_ph), "#222222"),
        Body("Thrust bearings", lambda: at_shafts("Thrust bearing AXK3047", ph.thrust_ph), "#c8c8c8"),
        Body("Crinkle washers", lambda: at_shafts("Crinkle washer stack", lambda e: ph.crinkle_ph(), ["free"]), "#d8b0ff"),
        # plates(layers, ends) of cad/stack.scad = end_plates(layers, ends): layers 0 inner, 1 outer, 2 cap
        Body("End plates (free end)", lambda: end_plates([0, 1, 2], ["free"]), "#b4b7b4"),
        Body("End plates (drive end)", lambda: end_plates([0, 1, 2], ["drive"]), "#c5c8c6"),
        Body("Combs", lambda: union(part("Comb A", comb("A")), part("Comb B", comb("B"))), GREEN),
        Body("Chamber walls", lambda: union(part("Chamber wall B", wall(1)), part("Chamber wall A", wall(-1))), PURPLE),
        Body("Side skirts", lambda: union(part("Side skirt B", skirt(1)), part("Side skirt A", skirt(-1))), PRINT, 0.55),
        Body("Drive-end guard + free-end cover", lambda: union(part("Free-end cover", free_end_cover()), drive_end_guard()), PRINT, 0.55),
    ],
}
