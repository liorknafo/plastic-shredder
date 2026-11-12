// shaft.scad -- Ø25 shaft with a hex section (vertex at +y), gear / sprocket keyways (top, +z) and M10 end holes.
include <common.scad>

KEY_W = 8;
KEY_D = 4;
END_HOLE_D = 8.5;      // M10 tap drill
END_HOLE_L = 25;

module keyway(xa, xb) {
    // 8 wide x 4 deep from the Ø25 surface on the +z side; the cutter extends past the surface
    axial(xa) translate([-KEY_W / 2, JOURNAL_D / 2 - KEY_D, 0]) cube([KEY_W, KEY_D + 3, xb - xa]);
}

// Shaft with its axis on the x axis (y = z = 0), in world x positions. Rotates cleanly about its own axis.
// Keyways: the gear seat (the 4 layers, x_gear_out .. x_gear_in; the spacer sleeve after it is on the plain Ø25) on both shafts, the sprocket seat (x_sprocket_out .. x_sprocket_in) on A only.
module shaft_local(which) {
    $fn = FN;
    xs = shaft_x_start(which);
    difference() {
        union() {
            axial(xs) cylinder(d = JOURNAL_D, h = shaft_end_free - xs);
            // hex prism across flats HEX_AF; circle($fn=6) has a vertex on +u = +y
            axial(hex_x0) linear_extrude(hex_x1 - hex_x0) circle(d = HEX_AF / cos(30), $fn = 6);
        }
        keyway(x_gear_out, x_gear_in);
        if (which == "A") keyway(x_sprocket_out, x_sprocket_in);
        axial(xs - 1) cylinder(d = END_HOLE_D, h = END_HOLE_L + 1);
        axial(shaft_end_free - END_HOLE_L) cylinder(d = END_HOLE_D, h = END_HOLE_L + 1);
    }
}

// In its world position (axis at y = -C/2 for A, +C/2 for B).
module shaft(which) translate([0, shaft_y(which), 0]) shaft_local(which);

// Part frame for export: axis along +X, starting at x = 0, axis on the X axis.
module shaft_part(which) translate([-shaft_x_start(which), 0, 0]) shaft_local(which);

// standalone render:  -D 'which="A"'
which = "A";
shaft_part(which);
