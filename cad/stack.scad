// stack.scad -- places the real (machined) parts: blade/spacer stacks, sleeves, rotating sets, plates, combs, walls.
// Shared by assembly.scad and checks.scad so that both see exactly the same geometry.
include <common.scad>
use <blade.scad>
use <spacer.scad>
use <shaft.scad>
use <sleeve.scad>
use <plate.scad>
use <comb.scad>
use <wall.scad>

// ---- shaft-local frame: axis on the x axis, y = z = 0. (Wrap in rot_frame() to put it in the machine.)

// Blade k of shaft sh. Rotated in its own 2D frame by blade_rot(k) BEFORE mapping to world:
//   B: (u, v, w) -> (y, z, x)     A (turned over): (u, v, w) -> (y, -z, -x)  [blade occupies the same x slab]
module blade_placed(sh, k) {
    x0 = blade_x0(sh, k);
    if (sh == "B")
        multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]])
            rotate([0, 0, blade_rot(k)]) blade(blade_variant(k));
    else
        multmatrix([[0, 0, -1, x0 + T_BLADE], [1, 0, 0, 0], [0, -1, 0, 0], [0, 0, 0, 1]])
            rotate([0, 0, blade_rot(k)]) blade(blade_variant(k));
}
module blades_of(sh) for (k = [0 : N_BLADES - 1]) blade_placed(sh, k);

module spacers_of(sh) {
    if (sh == "B") axial(END_CLEAR) spacer(end_spacer_B);
    for (k = [0 : N_BLADES - 1])
        if (sh == "A" || k < N_BLADES - 1) axial(blade_x0(sh, k) + T_BLADE) spacer(T_SPACER);
}

// the two clamp sleeves at the stack ends (drive end, free end)
module clamp_sleeves_of(sh) {
    axial(-LAYER_T) sleeve(sleeve_L_drive);
    axial(sleeve_free_x0(sh)) sleeve(sleeve_free_L(sh));
}
// the collared sleeves (part of the clamp chain, next to the bearing inner rings): collar outermost.  Drive: body x -34 .. -27, collar -38 .. -34.
// Free: body L+27 .. L+36, collar L+36 .. L+40 (mirrored: the collar is at the higher x).
module collared_sleeves_of(sh) {
    axial(x_collar_out_drive) collared(collar_body_L_drive);
    translate([x_collar_out_free, 0, 0]) rotate([0, -90, 0]) collar_free_local();
}
module collar_free_local() collared(collar_body_L_free);       // local +z -> world -x
module collar_sleeve(end) { if (end == "drive") axial(x_collar_out_drive) collared(collar_body_L_drive); else translate([x_collar_out_free, 0, 0]) rotate([0, -90, 0]) collar_free_local(); }
module clamp_sleeve(end, sh) { if (end == "drive") axial(-LAYER_T) sleeve(sleeve_L_drive); else axial(sleeve_free_x0(sh)) sleeve(sleeve_free_L(sh)); }
module all_sleeves_of(sh) { clamp_sleeves_of(sh); collared_sleeves_of(sh); }

// ---- machine frame
module rot_frame(sh, angle = 0)
    translate([0, shaft_y(sh), 0]) rotate([shaft_sign(sh) * angle, 0, 0]) children();

// everything that turns with one shaft and is a machined part of the cutting set (no gears, no placeholders)
module rotating_set(sh, angle = 0) {
    rot_frame(sh, angle) {
        shaft_local(sh);
        blades_of(sh);
        spacers_of(sh);
        clamp_sleeves_of(sh);
        collared_sleeves_of(sh);
    }
}

// ---- end plates: layers = [0 inner, 1 outer, 2 cap], ends = ["drive", "free"]
module plates(layers = [0, 1, 2], ends = ["drive", "free"]) end_plates(layers, ends);
module plate_one(end, i) end_plates([i], [end]);
