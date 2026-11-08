// spacer.scad -- round spacer tube. Part frame: axis along +Z, one end on Z = 0.
include <params.scad>

module spacer(t = T_SPACER) {
    $fn = 96;
    difference() {
        cylinder(d = SPACER_OD, h = t);
        translate([0, 0, -1]) cylinder(d = SPACER_BORE, h = t + 2);
    }
}

// standalone render:  -D 'kind="end_B"'  for the 8.15 end spacer of shaft B
kind = "normal";
spacer(kind == "end_B" ? end_spacer_B : T_SPACER);
