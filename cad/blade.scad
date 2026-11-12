// blade.scad -- cutter blade: 3 hooked teeth, hex bore with corner reliefs, phase variant v = 0..3.
// Part frame: blade in XY, thickness along +Z from 0.
include <common.scad>

module blade_2d(v = 0) {
    $fn = FN;
    difference() {
        polygon(blade_outline_pts);
        polygon(blade_hex(v));
        for (p = blade_hex(v)) translate(p) circle(d = HEX_RELIEF_D);
    }
}

module blade(v = 0) linear_extrude(T_BLADE) blade_2d(v);

// standalone render:  -D variant=N   (3D part)  or  -D flat=true (2D, for DXF)
variant = 0;
flat = false;
if (flat) blade_2d(variant); else blade(variant);
