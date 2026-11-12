// previews.scad -- part-level preview scenes for png/ (assembly views come from assembly.scad).
// Select with -D 'scene="blade_variants" | "shaft_A" | "shaft_B" | "plate_layers" | "comb_B" | "interlock_drawer" | "interlock_hopper"'
include <common.scad>
use <blade.scad>
use <shaft.scad>
use <plate.scad>
use <comb.scad>
use <base.scad>
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
else if (scene == "interlock_drawer") {            // drawer closed (solid) and pulled out 12 mm (ghost): switch on its pad, actuator on its pad on the drawer front
    intersection() {
        union() {
            color("#c8a46e", 0.5) { cabinet_shell_panels(); }
            color("#8c5a2b", 0.5) upper_front();                                    // the fixed upper front panel above the (short) drawer front
            color("#bf9000", 0.6) drawer_front();
            color("#e69138") { drawer_pad(); drawer_act_pad(); }
            color("#4d4d4c") { drawer_switch_ph(); drawer_switch_screws_ph(); drawer_actuator_screws_ph(); }
            color("#c82829") drawer_actuator();
            color("#3e999f", 0.35) translate([0, 0, 0]) { drawer_actuator(12); drawer_act_pad_moved(12); }
        }
        translate([120, -150, DRAWER_SW_Z - 55]) cube([120, 190, 110]);
    }
}
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
else if (scene == "gears_mesh") {                  // the two made gears in mesh (angle 0), looking along +x from the drive end; +y is on the viewer's left
    color("#c82829") translate([0, -30, 0]) axial(0) gear_solid(GEAR_cut_extra, 0, 0, gear_face);
    color("#4271ae") translate([0, 30, 0]) axial(0) gear_solid(GEAR_cut_extra, 180 / GEAR_z, 0, gear_face);
}
else if (scene == "gear_layer") {                  // ONE CNC layer (Ø64 rough, bore, keyway) in grey; the finished tooth profile as a red outline, the pitch circle dashed
    color("#8e908c") linear_extrude(GEAR_LAYER_T) gear_layer_2d();
    color("#c82829") translate([0, 0, GEAR_LAYER_T]) linear_extrude(0.4) difference() { offset(delta = 0.25) gear_outline(); offset(delta = -0.25) gear_outline(); }
    color("#3e999f") translate([0, 0, GEAR_LAYER_T]) linear_extrude(0.4) difference() { circle(d = GEAR_module * GEAR_z + 0.3, $fn = 180); circle(d = GEAR_module * GEAR_z - 0.3, $fn = 180); }
}
else assert(false, "unknown scene");
