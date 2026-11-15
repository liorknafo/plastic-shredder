// plate.scad -- end-plate layers (inner / outer / cap), the OUTBOARD bearing plate's two layers (ob1 gear side, ob2 outboard) and its 2 pillars, with the full hole table.
//
// Layer frame (u, v, w):  u = world y (plate centre = 0), v = world z (plate centre = 0),
// w = 0..LAYER_T measured OUTWARD from the face that touches the chamber side (cap: w = 0 touches the outer layer).
// Exported STLs are in this frame: the layer lies flat on XY, w up (inner: seal counterbore down; cap: bearing counterbore down, M6 counterbores up).
// plate_world() places a layer at the drive end (x <= 0) or the free end (x >= chamber_L).
include <common.scad>
include <joints.scad>

T = LAYER_T;

// ---------------------------------------------------------------- hole table
JOIN_PTS   = [[50, 26], [-50, 26], [76, -25], [-76, -25], [0, 27], [0, -27]];   // M6 joining screws
DOWEL_PTS  = [[55, -27], [-55, -27]];
COMB_PTS   = [[COMB_SCREW_Y, 0], [-COMB_SCREW_Y, 0]];                                              // M6 comb screws
WALL_PTS   = [[71, 14], [-71, 14], [71, 27], [-71, 27]];                        // M5 wall screws
GUARD_PTS  = guard_hole_yz();                                                    // 4 x M5, caps only (joints.scad: shared with the guards)
TOP_Y      = [TOP_HOLE_Y, -TOP_HOLE_Y];                                         // M5 hopper-collar holes, down from z = +35
FOOT_Y     = [FOOT_SCREW_Y, -FOOT_SCREW_Y];                                     // M6 feet, up from z = -PLATE_H/2 (joints.scad: the base plate's slots use the same foot_screw_xy())
FOOT_DEPTH = 12;
FOOT_D     = 5;

// Axial hole records (cylinders along w):  [name, y, z, diameter, w_from, w_to]   (all within [0, T])
// Shaft bores (both ends identical, w measured outward from the chamber side of the layer):
//   inner: seal counterbore Ø42 (SEAL_D) x SEAL_BORE_DEPTH from the chamber face, then Ø36 (INNER_HOLE_D) for the last 3 mm = shoulder for the bearing's outer ring
//   outer: Ø42 (BEARING_D, H7) through
//   cap:   Ø42 counterbore CAP_BORE_DEPTH from the inner face (the 17 mm bearing = 10 + 7), then Ø32 (CAP_HOLE_D) through the last 3 mm
// OUTBOARD PLATE layers (OB_L x OB_H x OB_T, w = 0 at the gear-side face): the NA4905 sits in a 17 mm pocket bored from the joint face of each layer
// (OB_STEP Ø32 steps at both outer faces hold the outer ring); 4 x Ø9 for the long M8 tie screws at the guard-hole positions, 2 x Ø6 dowels ob1 <-> ob2.
OB_DOWEL_PTS = [[55, -40], [-55, -40]];
function ob_holes(kind) = let (one = kind == "ob1") concat(
    [for (s = [-1, 1]) each [[str("obstep", s > 0 ? "B" : "A"), s * C / 2, 0, CAP_HOLE_D, one ? 0 : T - OB_STEP, one ? OB_STEP : T],
                             [str("obpocket", s > 0 ? "B" : "A"), s * C / 2, 0, BEARING_D, one ? OB_STEP : 0, one ? T : T - OB_STEP]]],
    [for (p = GUARD_PTS) ["tie", p[0], p[1], TIE_D + 1, 0, T]],
    one ? [] : [for (p = HOOD_SCREW_PTS) ["hood", p[0], p[1], 4.2, 0, T]],          // ob2: 4 x M5 tapped through for the hood's wings
    [for (p = OB_DOWEL_PTS) ["dowel", p[0], p[1], 6, 0, T]]);
function axial_holes(kind) = kind == "ob1" || kind == "ob2" ? ob_holes(kind) :
    let (
        inner = kind == "inner", outer = kind == "outer", cap = kind == "cap",
        join_d = inner ? 5 : 6.6
    )
    concat(
        // shaft holes (stepped: the two records of one bore are concentric, the ligament check skips them)
        inner ? [for (s = [-1, 1]) each [[str("seal", s > 0 ? "B" : "A"), s * C / 2, 0, BEARING_D, 0, SEAL_BORE_DEPTH],
                                        [str("shoulder", s > 0 ? "B" : "A"), s * C / 2, 0, INNER_HOLE_D, SEAL_BORE_DEPTH, T]]] : [],
        outer ? [for (s = [-1, 1]) [str("bearing", s > 0 ? "B" : "A"), s * C / 2, 0, BEARING_D, 0, T]] : [],
        cap ? [for (s = [-1, 1]) each [[str("cbore", s > 0 ? "B" : "A"), s * C / 2, 0, BEARING_D, 0, CAP_BORE_DEPTH],
                                      [str("step", s > 0 ? "B" : "A"), s * C / 2, 0, CAP_HOLE_D, CAP_BORE_DEPTH, T]]] : [],
        // M6 joining screws (cap: + counterbore on the outside face)
        [for (p = JOIN_PTS) ["join", p[0], p[1], join_d, 0, T]],
        cap ? [for (p = JOIN_PTS) ["join_cbore", p[0], p[1], 11, T - 6.5, T]] : [],
        // dowels
        [for (p = DOWEL_PTS) ["dowel", p[0], p[1], 6, 0, T]],
        // comb screws
        [for (p = COMB_PTS) ["comb", p[0], p[1], 6.6, 0, T]],
        cap ? [for (p = COMB_PTS) ["comb_cbore", p[0], p[1], 11, T - 6.5, T]] : [],
        // M5 wall screws
        [for (p = WALL_PTS) ["wall", p[0], p[1], 5.5, 0, T]],
        cap ? [for (p = WALL_PTS) ["wall_cbore", p[0], p[1], 9.5, T - 5.5, T]] : [],
        // the 4 M8 holes: tapped (Ø6.8) through the CAP layer and 9.5 deep into the OUTER layer from its cap-side face (both ends identical).
        // Drive end: the long M8 tie screws of the pillars + outboard plate; free end: the free-end cover (M8 x 16)
        cap ? [for (p = GUARD_PTS) ["guard", p[0], p[1], TIE_D - 1.2, 0, T]] : [],
        outer ? [for (p = GUARD_PTS) ["guard_tap", p[0], p[1], TIE_D - 1.2, 0.5, T]] : []
    );

// Foot holes (cylinders along z, from the bottom edge up):  [name, y, w, diameter, z_from, z_to]
function foot_holes(kind) =
    kind == "inner" || kind == "outer"
        ? [for (y = FOOT_Y) ["foot", y, T / 2, FOOT_D, -PLATE_H / 2, -PLATE_H / 2 + FOOT_DEPTH]]
        : [];

// Top-edge holes (cylinders along z, from the top edge down), INNER layers only:  [name, y, w, diameter, z_from, z_to]
function top_holes(kind) =
    kind == "inner"
        ? [for (y = TOP_Y) ["top", y, T / 2, 4.2, PLATE_H / 2 - TOP_HOLE_DEPTH, PLATE_H / 2]]
        : [];

// ---------------------------------------------------------------- geometry
function layer_dims(kind) = kind == "ob1" || kind == "ob2" ? [OB_L, OB_H, OB_ZC] : [PLATE_L, PLATE_H, 0];   // [y size, z size, z of the centre]
module plate_layer(kind = "inner") {
    $fn = 96;           // same facet count / phase as the bearing and seal placeholders: concentric polygons, no false overlaps
    ld = layer_dims(kind);
    difference() {
        translate([-ld[0] / 2, ld[2] - ld[1] / 2, 0]) cube([ld[0], ld[1], T]);
        for (h = axial_holes(kind)) {
            // extend the cutter past any face it opens onto
            w0 = h[4] <= 0 ? h[4] - 1 : h[4];
            w1 = h[5] >= T ? h[5] + 1 : h[5];
            translate([h[1], h[2], w0]) cylinder(d = h[3], h = w1 - w0);
        }
        for (f = foot_holes(kind))
            translate([f[1], f[4] - 1, f[2]]) rotate([-90, 0, 0]) cylinder(d = f[3], h = f[5] - f[4] + 1);
        for (f = top_holes(kind))
            translate([f[1], f[4], f[2]]) rotate([-90, 0, 0]) cylinder(d = f[3], h = f[5] - f[4] + 1);
    }
}

// World placement. end = "drive" | "free"; i = 0 inner, 1 outer, 2 cap, 3 ob1, 4 ob2 (drive end only).
module plate_world(end, i, kind) {
    if (i >= 3)
        multmatrix([[0, 0, -1, x_ob_in - OB_T * (i - 3)], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) plate_layer(kind);
    else if (end == "drive")
        // 180 deg about z: x = -w - T*i, y = -u, z = v  (a proper rotation; the hole pattern is y-symmetric anyway)
        multmatrix([[0, 0, -1, -LAYER_T * i], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) plate_layer(kind);
    else
        multmatrix([[0, 0, 1, chamber_L + LAYER_T * i], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) plate_layer(kind);
}
module end_plates(layers = [0, 1, 2, 3, 4], ends = ["drive", "free"]) {
    for (e = ends, i = layers) if (i < 3 || e == "drive")
        plate_world(e, i, ["inner", "outer", "cap", "ob1", "ob2"][i]);
}
// the 2 PILLARS (from the 51 x 130 x 25.5 block): PILLAR[0] (y) x PILLAR[1] (z) x standoff_L (x), between the drive cap's outer face and ob1's gear-side face, ends faced
// square and to equal length (±0.01), two Ø9 holes for that side's M8 tie screws.  Clamped by the screws (a friction joint, calc s.7b), the outboard plate lined up by
// the shafts at assembly (DESIGN 7.2).  g > 0: shrunk by g on every face (touching-face checks); g < 0: grown.
module pillar(sy, g = 0) difference() {
    translate([x_ob_in + g, sy > 0 ? PILLAR_Y0 + g : -PILLAR_Y0 - PILLAR[0] + g, -PILLAR[1] / 2 + g]) cube([standoff_L - 2 * g, PILLAR[0] - 2 * g, PILLAR[1] - 2 * g]);
    for (p = guard_hole_yz()) if (p[0] * sy > 0) translate([x_ob_in - 1, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = TIE_D + 1, h = standoff_L + 2, $fn = 32);
}
module standoffs(g = 0) for (sy = [-1, 1]) pillar(sy, g);
module standoff_local() translate([-x_ob_in, -PILLAR_Y0, PILLAR[1] / 2]) pillar(1);   // export pose: one pillar, at the origin
// the long M8 tie screws (12.9, 35 N·m): head on 3 hardened washers on ob2's outer face, through ob2, ob1, the pillar, into the cap + outer layer (M8 x 100)
TIE_SCREW_L = 100;
function tie_screw_x0() = x_ob_out - 4;                        // under the head (the guard wing is 4 thick)

// ---------------------------------------------------------------- standalone render / hole dump
kind = "inner";          // inner | outer | cap  (drive and free ends are identical)
dump_holes = false;      // -D dump_holes=true: echo the hole table for cad/ligament.py (no geometry)

if (dump_holes) {
    for (k = ["inner", "outer", "cap", "ob1", "ob2"]) {
        for (h = axial_holes(k)) echo("HOLE", k, "axial", h[0], h[1], h[2], h[3], h[4], h[5]);
        for (f = foot_holes(k))  echo("HOLE", k, "foot",  f[0], f[1], f[2], f[3], f[4], f[5]);
        for (f = top_holes(k))   echo("HOLE", k, "top",   f[0], f[1], f[2], f[3], f[4], f[5]);
    }
    echo("PLATE", PLATE_L, PLATE_H, T);
    for (k = ["ob1", "ob2"]) echo("PLATEK", k, OB_L, OB_H - 2 * OB_ZC, OB_T);   // symmetric about the axes for the edge check: the shorter half (conservative)
} else if (kind == "standoff") standoff_local();
else plate_layer(kind);
