"""plate.py -- end-plate layers (inner / outer / cap), the OUTBOARD bearing plate's two layers (ob1 gear side, ob2
outboard) and its 2 pillars, with the full hole table (cad/plate.scad).

Layer frame (u, v, w):  u = world y (plate centre = 0), v = world z (plate centre = 0),
w = 0..LAYER_T measured OUTWARD from the face that touches the chamber side (cap: w = 0 touches the outer layer).
The layer lies flat on XY, w up (inner: seal counterbore down; cap: bearing counterbore down, M6 counterbores up).
plate_world() places a layer at the drive end (x <= 0) or the free end (x >= chamber_L).
"""
from common import *
from joints import *

T = LAYER_T

# ---------------------------------------------------------------- hole table
JOIN_PTS = [[50, 26], [-50, 26], [76, -25], [-76, -25], [0, 27], [0, -27]]     # M6 joining screws
DOWEL_PTS = [[55, -27], [-55, -27]]
COMB_PTS = [[COMB_SCREW_Y, 0], [-COMB_SCREW_Y, 0]]                             # M6 comb screws
WALL_PTS = [[71, 14], [-71, 14], [71, 27], [-71, 27]]                          # M5 wall screws
GUARD_PTS = guard_hole_yz()                                                    # the 4 M8 holes (joints: shared with the cover / tie screws)
TOP_Y = [TOP_HOLE_Y, -TOP_HOLE_Y]                                              # M5 hopper-collar holes, down from z = +35
FOOT_Y = [FOOT_SCREW_Y, -FOOT_SCREW_Y]                                         # M6 feet, up from z = -PLATE_H/2 (joints: the base plate's slots use foot_screw_xy())
FOOT_DEPTH = 12
FOOT_D = 5
# OUTBOARD PLATE layers (OB_L x OB_H x OB_T, w = 0 at the gear-side face): the NA4905 sits in a 17 mm pocket bored from
# the joint face of each layer (OB_STEP Ø32 steps at both outer faces hold the outer ring); 4 x Ø9 for the long M8 tie
# screws at the guard-hole positions, 2 x Ø6 dowels ob1 <-> ob2.
OB_DOWEL_PTS = [[55, -40], [-55, -40]]


def ob_holes(kind):
    one = kind == "ob1"
    return ([r for s in (-1, 1) for r in (
                ["obstep" + ("B" if s > 0 else "A"), s * C / 2, 0, CAP_HOLE_D, 0 if one else T - OB_STEP, OB_STEP if one else T],
                ["obpocket" + ("B" if s > 0 else "A"), s * C / 2, 0, BEARING_D, OB_STEP if one else 0, T if one else T - OB_STEP])]
            + [["tie", p[0], p[1], TIE_D + 1, 0, T] for p in GUARD_PTS]
            + ([] if one else [["hood", p[0], p[1], 4.2, 0, T] for p in HOOD_SCREW_PTS])     # ob2: 4 x M5 tapped through for the hood's wings
            + [["dowel", p[0], p[1], 6, 0, T] for p in OB_DOWEL_PTS])


def axial_holes(kind):
    """Axial hole records (cylinders along w):  [name, y, z, diameter, w_from, w_to]   (all within [0, T]).
    Shaft bores (both ends identical, w measured outward from the chamber side of the layer):
      inner: seal counterbore Ø42 x SEAL_BORE_DEPTH from the chamber face, then Ø36 (INNER_HOLE_D) for the last 3 mm
             = shoulder for the bearing's outer ring
      outer: Ø42 (BEARING_D, H7) through
      cap:   Ø42 counterbore CAP_BORE_DEPTH from the inner face (the 17 mm bearing = 10 + 7), then Ø32 (CAP_HOLE_D)
             through the last 3 mm"""
    if kind in ("ob1", "ob2"):
        return ob_holes(kind)
    inner, outer, cap = kind == "inner", kind == "outer", kind == "cap"
    join_d = 5 if inner else 6.6

    def ab(s):
        return "B" if s > 0 else "A"

    return (
        # shaft holes (stepped: the two records of one bore are concentric)
        ([r for s in (-1, 1) for r in (["seal" + ab(s), s * C / 2, 0, BEARING_D, 0, SEAL_BORE_DEPTH],
                                       ["shoulder" + ab(s), s * C / 2, 0, INNER_HOLE_D, SEAL_BORE_DEPTH, T])] if inner else [])
        + ([["bearing" + ab(s), s * C / 2, 0, BEARING_D, 0, T] for s in (-1, 1)] if outer else [])
        + ([r for s in (-1, 1) for r in (["cbore" + ab(s), s * C / 2, 0, BEARING_D, 0, CAP_BORE_DEPTH],
                                         ["step" + ab(s), s * C / 2, 0, CAP_HOLE_D, CAP_BORE_DEPTH, T])] if cap else [])
        # M6 joining screws (cap: + counterbore on the outside face)
        + [["join", p[0], p[1], join_d, 0, T] for p in JOIN_PTS]
        + ([["join_cbore", p[0], p[1], 11, T - 6.5, T] for p in JOIN_PTS] if cap else [])
        # dowels
        + [["dowel", p[0], p[1], 6, 0, T] for p in DOWEL_PTS]
        # comb screws
        + [["comb", p[0], p[1], 6.6, 0, T] for p in COMB_PTS]
        + ([["comb_cbore", p[0], p[1], 11, T - 6.5, T] for p in COMB_PTS] if cap else [])
        # M5 wall screws
        + [["wall", p[0], p[1], 5.5, 0, T] for p in WALL_PTS]
        + ([["wall_cbore", p[0], p[1], 9.5, T - 5.5, T] for p in WALL_PTS] if cap else [])
        # the 4 M8 holes: tapped (Ø6.8) through the CAP layer and 9.5 deep into the OUTER layer from its cap-side face
        # (both ends identical).  Drive end: the long M8 tie screws of the pillars + outboard plate; free end: the free-end cover
        + ([["guard", p[0], p[1], TIE_D - 1.2, 0, T] for p in GUARD_PTS] if cap else [])
        + ([["guard_tap", p[0], p[1], TIE_D - 1.2, 0.5, T] for p in GUARD_PTS] if outer else []))


def foot_holes(kind):
    """Foot holes (cylinders along z, from the bottom edge up):  [name, y, w, diameter, z_from, z_to]"""
    return ([["foot", y, T / 2, FOOT_D, -PLATE_H / 2, -PLATE_H / 2 + FOOT_DEPTH] for y in FOOT_Y]
            if kind in ("inner", "outer") else [])


def top_holes(kind):
    """Top-edge holes (cylinders along z, from the top edge down), INNER layers only:  [name, y, w, diameter, z_from, z_to]"""
    return ([["top", y, T / 2, 4.2, PLATE_H / 2 - TOP_HOLE_DEPTH, PLATE_H / 2] for y in TOP_Y]
            if kind == "inner" else [])


# ---------------------------------------------------------------- geometry
def layer_dims(kind):
    """[y size, z size, z of the centre]"""
    return [OB_L, OB_H, OB_ZC] if kind in ("ob1", "ob2") else [PLATE_L, PLATE_H, 0]


def plate_layer(kind="inner"):
    ld = layer_dims(kind)

    def axial_cut(h):
        # extend the cutter past any face it opens onto
        w0 = h[4] - 1 if h[4] <= 0 else h[4]
        w1 = h[5] + 1 if h[5] >= T else h[5]
        return translate([h[1], h[2], w0], cylinder(d=h[3], h=w1 - w0))

    return difference(
        translate([-ld[0] / 2, ld[2] - ld[1] / 2, 0], cube([ld[0], ld[1], T])),
        [axial_cut(h) for h in axial_holes(kind)],
        [translate([f[1], f[4] - 1, f[2]], rotate([-90, 0, 0], cylinder(d=f[3], h=f[5] - f[4] + 1))) for f in foot_holes(kind)],
        [translate([f[1], f[4], f[2]], rotate([-90, 0, 0], cylinder(d=f[3], h=f[5] - f[4] + 1))) for f in top_holes(kind)])


def plate_world(end, i, kind):
    """World placement.  end = "drive" | "free"; i = 0 inner, 1 outer, 2 cap, 3 ob1, 4 ob2 (drive end only)."""
    if i >= 3:
        return multmatrix([[0, 0, -1, x_ob_in - OB_T * (i - 3)], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], plate_layer(kind))
    if end == "drive":
        # 180 deg about z: x = -w - T*i, y = -u, z = v  (a proper rotation; the hole pattern is y-symmetric anyway)
        return multmatrix([[0, 0, -1, -LAYER_T * i], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], plate_layer(kind))
    return multmatrix([[0, 0, 1, chamber_L + LAYER_T * i], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]], plate_layer(kind))


def layer_kind(i):
    return ["inner", "outer", "cap", "ob1", "ob2"][i]


def end_plates(layers=(0, 1, 2, 3, 4), ends=("drive", "free")):
    return union(part(f"Outboard plate, {layer_kind(i)} layer" if i >= 3 else f"End plate, {layer_kind(i)} layer ({e} end)",
                      plate_world(e, i, layer_kind(i)))
                 for e in ends for i in layers if i < 3 or e == "drive")


def pillar(sy, g=0):
    """One of the 2 PILLARS (from the 51 x 130 x 25.5 block): PILLAR[0] (y) x PILLAR[1] (z) x standoff_L (x), between the
    drive cap's outer face and ob1's gear-side face, two Ø9 holes for that side's M8 tie screws.  g > 0: shrunk by g on
    every face; g < 0: grown."""
    return difference(
        translate([x_ob_in + g, PILLAR_Y0 + g if sy > 0 else -PILLAR_Y0 - PILLAR[0] + g, -PILLAR[1] / 2 + g],
                  cube([standoff_L - 2 * g, PILLAR[0] - 2 * g, PILLAR[1] - 2 * g])),
        [translate([x_ob_in - 1, p[0], p[1]], rotate([0, 90, 0], cylinder(d=TIE_D + 1, h=standoff_L + 2)))
         for p in guard_hole_yz() if p[0] * sy > 0])


def standoffs(g=0):
    return union(part(f"Pillar {'B' if sy > 0 else 'A'} side", pillar(sy, g)) for sy in (-1, 1))


def standoff_local():
    """Export pose: one pillar, at the origin."""
    return translate([-x_ob_in, -PILLAR_Y0, PILLAR[1] / 2], pillar(1))


# the long M8 tie screws (12.9, 35 N·m): head on 3 hardened washers on ob2's outer face, through ob2, ob1, the pillar,
# into the cap + outer layer (M8 x 100)
TIE_SCREW_L = 100


def tie_screw_x0():
    return x_ob_out - 4                        # under the head (the guard wing is 4 thick)


# the made parts of this file, each in its part frame (parts.py); drive and free ends are identical
PARTS = {"plate_inner": lambda: plate_layer("inner"),
         "plate_outer": lambda: plate_layer("outer"),
         "plate_cap": lambda: plate_layer("cap"),
         "plate_ob1": lambda: plate_layer("ob1"),
         "plate_ob2": lambda: plate_layer("ob2"),
         "standoff": standoff_local}
