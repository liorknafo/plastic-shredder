// previews.scad -- part-level preview scenes for png/ (assembly views come from assembly.scad).
// Select with -D 'scene="blade_variants" | "shaft_A" | "shaft_B" | "plate_layers" | "comb_B" | "interlock_hopper" | "gears_mesh"'
include <common.scad>
use <blade.scad>
use <shaft.scad>
use <plate.scad>
use <comb.scad>
use <hopper.scad>
use <gear.scad>
use <placeholders.scad>

scene = "blade_variants";

if (scene == "blade_variants")
    for (v = [0 : 3]) translate([v * 78, 0, 0]) color(v % 2 == 0 ? "#4271ae" : "#f5871f") blade(v);
else if (scene == "shaft_A") color("#8e908c") shaft_part("A");
else if (scene == "shaft_B") color("#8e908c") shaft_part("B");
else if (scene == "plate_layers") {
    color("#718c00") translate([0, 0, 0]) plate_layer("inner");
    color("#3e999f") translate([PLATE_L + 15, 0, 0]) plate_layer("outer");
    color("#8959a8") translate([2 * (PLATE_L + 15), 0, 0]) plate_layer("cap");
}
else if (scene == "comb_B") color("#c82829") comb_part("B");
else if (scene == "interlock_hopper") {            // lid down (solid) and 9 deg up (ghost)
    intersection() {
        union() {
            color("#6fa8dc", 0.5) funnel();
            color("#e69138", 0.7) { lid_posed(0); lid_pad_posed(0); }
            color("#4d4d4c") { switch_ph(); switch_screws_ph(); lid_hw_posed(0); }
            color("#c82829") lid_actuator_posed(0);
            color("#3e999f", 0.35) { lid_posed(9); lid_pad_posed(9); lid_actuator_posed(9); }
        }
        translate([150, -45, 180]) cube([70, 90, 190]);
    }
}
else if (scene == "gears_mesh") {                  // the two bought m4 z15 gears in mesh (angle 0), looking along +x from the drive end; +y is on the viewer's left
    color("#c82829") translate([0, -30, 0]) axial(0) gear_solid(GEAR_cut_extra, 0, 0, gear_face);
    color("#4271ae") translate([0, 30, 0]) axial(0) gear_solid(GEAR_cut_extra, GEAR_z % 2 == 0 ? 180 / GEAR_z : 0, 0, gear_face);   // the same phase as gear_phase("B") in placeholders.scad
}
else assert(false, "unknown scene");
