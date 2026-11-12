// plate.scad -- end-plate layers (inner / outer / cap) with the full hole table.
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
function axial_holes(kind) =
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
        // gear-guard / free-end-cover holes: M5 tapped (Ø4.2) through the CAP layer only
        cap ? [for (p = GUARD_PTS) ["guard", p[0], p[1], 4.2, 0, T]] : []
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
module plate_layer(kind = "inner") {
    $fn = 96;           // same facet count / phase as the bearing and seal placeholders: concentric polygons, no false overlaps
    difference() {
        translate([-PLATE_L / 2, -PLATE_H / 2, 0]) cube([PLATE_L, PLATE_H, T]);
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

// World placement. end = "drive" | "free"; i = 0 inner, 1 outer, 2 cap.
module plate_world(end, i, kind) {
    if (end == "drive")
        // 180 deg about z: x = -w - T*i, y = -u, z = v  (a proper rotation; the hole pattern is y-symmetric anyway)
        multmatrix([[0, 0, -1, -LAYER_T * i], [-1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) plate_layer(kind);
    else
        multmatrix([[0, 0, 1, chamber_L + LAYER_T * i], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) plate_layer(kind);
}
module end_plates(layers = [0, 1, 2], ends = ["drive", "free"]) {
    for (e = ends, i = layers)
        plate_world(e, i, i == 0 ? "inner" : i == 1 ? "outer" : "cap");
}

// ---------------------------------------------------------------- standalone render / hole dump
kind = "inner";          // inner | outer | cap  (drive and free ends are identical)
dump_holes = false;      // -D dump_holes=true: echo the hole table for cad/ligament.py (no geometry)

if (dump_holes) {
    for (k = ["inner", "outer", "cap"]) {
        for (h = axial_holes(k)) echo("HOLE", k, "axial", h[0], h[1], h[2], h[3], h[4], h[5]);
        for (f = foot_holes(k))  echo("HOLE", k, "foot",  f[0], f[1], f[2], f[3], f[4], f[5]);
        for (f = top_holes(k))   echo("HOLE", k, "top",   f[0], f[1], f[2], f[3], f[4], f[5]);
    }
    echo("PLATE", PLATE_L, PLATE_H, T);
} else plate_layer(kind);
