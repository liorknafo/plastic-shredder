// assembly.scad -- the whole machine. Use -D flags to pick what is shown (see build.sh for the preview set).
//   angle           shaft A turns -angle about its axis, shaft B +angle (deg)
//   show_*          visibility switches
//   section_x       if set (number), keep only a 1 mm slab around that x (cross-section view)
//   section_pair    true: two 1 mm slabs through the axis planes y = -30 (shaft A: seal, bearing, thrust, collar, gear, TL350) and y = +30 (shaft B: ... gear, end cap), the B slab 120 mm lower
//   ghost_guards    draw the drive-end guard / free cover / coupling guard as faint ghosts
include <common.scad>
use <stack.scad>
use <placeholders.scad>
use <plate.scad>
use <comb.scad>
use <wall.scad>
use <shaft.scad>
use <hopper.scad>
use <guards.scad>
use <drive.scad>
use <base.scad>

angle = 0;
show_drive_side = true;    // drive plates + bearings, gears, the TL350, drive end screws
show_gears = true;
show_gearbox = true;       // gearbox, pin flange, motor, coupling, deck (the whole drive)
show_hopper = true;       // collar + funnel + lid (+ interlock switch)
show_extras = true;       // guards, free-end cover, base plate, cabinet, screen
lid_open = 0;             // hopper lid opening angle (deg)
show_motor = true;        // motor, coupling, coupling guard, deck
show_combs_walls = true;
ghost_guards = false;
section_x = undef;
section_pair = false;
clip = undef;             // [x0, y0, z0, x1, y1, z1]: keep only this box (close-up views)
show_cabinet = true;       // base plate, cabinet, drawer, handle (false: see the screen from below)
show_screen = true;        // the fixed screen under the blades (with show_extras)
screen_dims = false;       // dimension the blade-tip-to-screen gap and the hole band (screen_section view)
show_holddown = true;
hide_guards = false;      // close-ups: leave the guards out
deck_alpha = 0.85;        // plywood deck opacity (low: the legs, angles and anchors under it show)     // leg angles, foot angles, floor anchors, ghost floor
drive_only = false;       // clip everything at x > -32: only the drive (gears, TL350, guards, gearbox, pin flange, motor, coupling, deck)

// Tomorrow palette
C_RED = "#c82829"; C_ORANGE = "#f5871f"; C_YELLOW = "#eab700"; C_GREEN = "#718c00";
C_AQUA = "#3e999f"; C_BLUE = "#4271ae"; C_PURPLE = "#8959a8"; C_GRAY = "#8e908c"; C_DARK = "#4d4d4c";

// section view: each coloured group is cut on its own so that it keeps its colour
module cut() {
    if (!is_undef(section_x)) intersection() { children(); translate([section_x - 0.5, -900, -900]) cube([1, 1800, 1800]); }
    else if (!is_undef(clip)) intersection() { children(); translate([clip[0], clip[1], clip[2]]) cube([clip[3] - clip[0], clip[4] - clip[1], clip[5] - clip[2]]); }
    else if (drive_only) intersection() { children(); translate([-800, -800, -800]) cube([768, 1600, 1600]); }
    else if (!is_undef($sec_y)) intersection() { children(); translate([-150, $sec_y - 0.5, -62]) cube([192, 1, 124]); }
    else children();
}
GA = ghost_guards ? 0.18 : 0.55;

module rotor_visual(sh, angle) {
    bc = sh == "A" ? C_ORANGE : C_BLUE;
    // cut() is applied OUTSIDE rot_frame, in world coordinates (a y section must not be shifted by the shaft's own translation)
    color(C_DARK)   cut() rot_frame(sh, angle) shaft_local(sh);
    color(bc)       cut() rot_frame(sh, angle) blades_of(sh);
    color(C_GRAY)   cut() rot_frame(sh, angle) spacers_of(sh);
    color(C_YELLOW) cut() rot_frame(sh, angle) { clamp_sleeves_of(sh); collared_sleeves_of(sh); }
    if (show_drive_side) {
        if (show_gears) color(C_RED, 0.75) cut() rot_frame(sh, angle) gear_ph(sh);
        if (show_gears) color(C_YELLOW) cut() rot_frame(sh, angle) { gear_spacer_ph(); ob_sleeve_ph(sh); }
        if (sh == "A") color("#8e6fb0") cut() rot_frame(sh, angle) sprocket_ph();               // TL350-2 on shaft A: flange, linings + its 30T sprocket, pressure plate, springs, nut
        color(C_DARK) cut() rot_frame(sh, angle) end_screw_drive(sh);
    }
    color(C_DARK) cut() rot_frame(sh, angle) end_screw_free();
}

module bearings_seals() {
    for (sh = ["A", "B"]) {
        for (e = ["drive", "free"]) if (e == "free" || show_drive_side) {
            color(C_AQUA) cut() translate([0, shaft_y(sh), 0]) { bearing_inner_ph(e); bearing_outer_ph(e); }
            color("#9fd4d8") cut() translate([0, shaft_y(sh), 0]) bearing_rollers_ph(e);
            color("#222222") cut() translate([0, shaft_y(sh), 0]) seal_ph(e);
            color("#c8c8c8") cut() translate([0, shaft_y(sh), 0]) thrust_ph(e);
        }
        color("#d8b0ff") cut() translate([0, shaft_y(sh), 0]) crinkle_ph();
        if (show_drive_side) {                                                                   // the outboard bearing (no seal: it is inside the guard)
            color(C_AQUA) cut() translate([0, shaft_y(sh), 0]) { bearing_inner_ph("ob"); bearing_outer_ph("ob"); }
            color("#9fd4d8") cut() translate([0, shaft_y(sh), 0]) bearing_rollers_ph("ob");
        }
    }
}

module everything() {
    for (sh = ["A", "B"]) rotor_visual(sh, angle);
    bearings_seals();
    // plates
    color("#b4b7b4") cut() plates([0, 1, 2], ["free"]);
    if (show_drive_side) { color("#c5c8c6") cut() plates([0, 1, 2], ["drive"]); color("#a9b0b8") cut() plates([3, 4], ["drive"]); color(C_DARK) cut() standoffs(); }   // + the outboard bearing plate on its 4 standoffs
    // combs and walls
    if (show_combs_walls) {
        color(C_GREEN) cut() { comb("A"); comb("B"); }
        color(C_PURPLE) cut() { wall(1); wall(-1); }
    }
    if (show_hopper) {
        color("#6fa8dc", 0.30) cut() { collar(); funnel(); }
        color("#e69138", 0.45) cut() { lid_posed(lid_open); lid_pad_posed(lid_open); }          // printed: lid + its actuator pad
        color(C_DARK) cut() { switch_ph(); switch_screws_ph(); lid_hw_posed(lid_open); }          // safety switch (placeholder) + screws
        color("#b0b4b8") cut() lid_actuator_posed(lid_open);                                      // its coded metal actuator (placeholder)
    }
    if (show_extras) {
        color("#e69138", GA) cut() { free_end_cover(); if (show_drive_side && !hide_guards) drive_end_guard(); }
        if (show_cabinet) {
            color("#d9b98a") cut() { base_plate(); }
            color("#c8a46e", 0.55) cut() cabinet_shell_panels();
            color("#bf9000") cut() drawer_panels();
            color("#e69138") cut() handle_world();                                               // printed pull handle
            color(C_DARK) cut() handle_screws_ph();
        }
        if (show_screen) {                                                                      // the fixed screen (aluminium) under the blades + its screws
            color("#9aa5b1") cut() screen();
            color(C_DARK) cut() { screen_screws_ph(); wall_screws_ph(); }
        }
    }
    if (show_drive_side && show_gearbox) {
        color(C_GRAY, 0.6) cut() { gearbox_ph(); }
        color(C_DARK) cut() { worm_ph(); gb_foot_bolts_ph(); rail_bolts_ph(); }
        color("#2b6cb0") cut() output_shaft_ph();                                               // output shaft (made from the bought 4140 bar)
        color("#9aa5b1") cut() pin_flange();                                                     // the pin flange (6061), coaxial with shaft A
        color(C_DARK) cut() pins_ph();                                                           // its 4 dowel pins (through the TL350's drilled sprocket plate)
        color(C_YELLOW) cut() shaft_hw_ph();                                                     // circlip, 3 mm spacer
        color("#b0b4b8") cut() gb_mount();                                                       // the two slotted rails + spacer blocks
        if (show_motor) {
            color(C_DARK) cut() { motor_ph(); motor_shaft_ph(); }
            color("#c45a1a") cut() coupling_ph();                                                 // jaw coupling
            if (!hide_guards) color("#e69138", GA) cut() { cpl_guard(); stub_cap(); }
            color(C_DARK) cut() cg_screws_ph();
            color("#c8a46e", deck_alpha) cut() { drive_deck(); deck_legs(); }
            if (show_holddown) {
                color("#b0b4b8") cut() { top_angles(); foot_angles(); }                          // 40x40x4 leg angles
                color(C_DARK) cut() { topang_deck_bolts_ph(); topang_leg_bolts_ph(); footang_leg_bolts_ph(); }   // M8 bolts
                color(C_RED) cut() anchors_ph();                                                 // the 8 floor anchors
                color("#d8d8d8", 0.25) cut() floor_ph();
            }
        }
    }
}

// screen section (view along +x, +y on the viewer's left): the blade-tip circles, the 2 mm gap, the hole band
module lbl(y, z, t, sz = 9) translate([section_x - 0.6, y, z]) rotate([90, 0, -90]) linear_extrude(1) text(t, size = sz, halign = "center", valign = "center");
module screen_dimensions() color(C_RED) {
    lbl(0, -60, str("screen: ", SCREEN_GAP, " mm under the blade tips, holes Ø", SCREEN_HOLE_D), 6);
    lbl(0, -70, str("wall ", SCREEN_T, ", holes where the top is <= ", SCREEN_HOLE_SLOPE, " deg"), 6);
}
if (screen_dims && !is_undef(section_x)) screen_dimensions();
if (section_pair) for (i = [0, 1]) translate([0, 0, -120 * i]) let($sec_y = shaft_y(i == 0 ? "A" : "B")) everything();
else everything();
