// assembly.scad -- the whole machine. Use -D flags to pick what is shown (see build.sh for the preview set).
//   angle           shaft A turns -angle about its axis, shaft B +angle (deg)
//   show_*          visibility switches
//   section_x       if set (number), keep only a 1 mm slab around that x (cross-section view)
//   section_pair    true: two 1 mm slabs through the axis planes y = -30 (shaft A: seal, bearing, thrust, collar, gear, sprocket) and y = +30 (shaft B: ... gear, end cap), the B slab 120 mm lower
//   ghost_guards    draw the drive-end guard / chain guard / free cover / belt guard as faint ghosts
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
show_drive_side = true;    // drive plates + bearings, gears, sprocket, drive end screws
show_gears = true;
show_gearbox = true;       // gearbox, TL350, chain, tensioner, motor, belt, deck (the whole drive)
show_hopper = true;       // collar + funnel + lid (+ interlock switch)
show_extras = true;       // skirts, guards, free-end cover, base plate, cabinet, belt guard, motor
lid_open = 0;             // hopper lid opening angle (deg)
show_motor = true;        // motor, pulleys, belt, belt guard, deck
show_combs_walls = true;
ghost_guards = false;
section_x = undef;
section_pair = false;
clip = undef;             // [x0, y0, z0, x1, y1, z1]: keep only this box (close-up views)
show_grid = true;          // the fixed mesh grid + its cleats in the bin cabinet (with show_extras)
grid_dims = false;         // dimension the blade-tip-to-grid distance (grid_section view)
show_holddown = true;
hide_guards = false;      // close-ups: leave the guards out
deck_alpha = 0.85;        // plywood deck opacity (low: the legs, angles and anchors under it show)     // leg angles, foot angles, floor anchors, ghost floor
drive_only = false;       // clip everything at x > -32: only the drive (gears, sprocket, guards, gearbox, TL, chain, tensioner, motor, belt, deck)

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
        if (show_gears) color(C_YELLOW) cut() rot_frame(sh, angle) gear_spacer_ph();
        if (sh == "A") color(C_ORANGE, 0.9) cut() rot_frame(sh, angle) sprocket_ph();
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
    }
}

module everything() {
    for (sh = ["A", "B"]) rotor_visual(sh, angle);
    bearings_seals();
    // plates
    color("#b4b7b4") cut() plates([0, 1, 2], ["free"]);
    if (show_drive_side) color("#c5c8c6") cut() plates([0, 1, 2], ["drive"]);
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
        color("#e69138", 0.55) cut() { skirt(1); skirt(-1); }
        color("#e69138", GA) cut() { free_end_cover(); if (show_drive_side && !hide_guards) drive_end_guard(); }
        color("#d9b98a") cut() { base_plate(); }
        color("#c8a46e", 0.55) cut() cabinet_shell_panels();
        color("#8c5a2b", 0.8) cut() upper_front();                                              // the FIXED upper front panel (screwed on): base plate down to just under the lower grid cleats
        color("#bf9000") cut() drawer_panels();
        color("#e69138") cut() { handle_world(); drawer_pad(); drawer_act_pad(); }              // printed: pull handle, switch pad, actuator pad (no tongue)
        color(C_DARK) cut() { drawer_switch_ph(); handle_screws_ph(); drawer_switch_screws_ph(); drawer_actuator_screws_ph(); upper_front_screws_ph(); }
        color("#b0b4b8") cut() drawer_actuator();                                              // the coded metal actuator (placeholder)
        if (show_grid) {
            color("#6b7076") cut() grid_mesh();                                                 // 1" galvanized welded mesh, 14 ga
            color("#a67c52") cut() { grid_cleats(0); grid_cleats(1); }                          // 20 x 20 timber cleats (lower set under the mesh, upper set on top)
            color(C_DARK) cut() grid_screws_ph();
        }
    }
    if (show_drive_side && show_gearbox) {
        color(C_GRAY, 0.6) cut() { gearbox_ph(); }
        color(C_DARK) cut() { worm_ph(); gb_foot_bolts_ph(); rail_bolts_ph(); tens_bolts_ph(); tens_bolt_ph(); }
        color("#2b6cb0") cut() output_shaft_ph();                                               // output shaft (made from the bought 4140 bar)
        color("#8e6fb0") cut() tl_ph();                                                          // TL350-2: flange, linings + sprocket plate, pressure plate, springs, nut
        color(C_YELLOW) cut() shaft_hw_ph();                                                     // circlip, 3 mm spacer, stop collar
        color("#b0b4b8") cut() gb_mount();                                                       // the two slotted rails + spacer blocks
        color(C_ORANGE, 0.9) cut() tens_idler_ph();
        color(C_RED) cut() { tens_upright(); tens_base(); }                                      // tensioner (welded flats)
        color("#444444", 0.9) cut() chain_band(0);                                               // chain
        if (show_motor) {
            color(C_DARK) cut() { motor_ph(); pulleys_ph(); motor_shaft_ph(); }
            color("#222222", 0.8) cut() belt_ph();
            if (!hide_guards) color("#e69138", GA) cut() { belt_guard(0); belt_guard(1); }
            color(C_DARK) cut() belt_guard_hw_ph();
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

// dimension of the safety distance (view along +x, +y on the viewer's left): blade-tip envelope bottom (z = -R_TIP) to the mesh top
module lbl(y, z, t, sz = 9) translate([section_x - 0.6, y, z]) rotate([90, 0, -90]) linear_extrude(1) text(t, size = sz, halign = "center", valign = "center");
module grid_dimensions() {
    y = -124;                                                                        // in front of the drawer front in this view
    color(C_RED) {
        translate([section_x, y, (GRID_Z - R_TIP) / 2]) cube([1.2, 1.2, -R_TIP - GRID_Z], center = true);                 // the dimension line
        for (z = [-R_TIP, GRID_Z]) translate([section_x, (y + 150) / 2, z]) cube([1.2, abs(y - 150), 0.8], center = true);   // the two levels: blade-tip envelope bottom, mesh top
        lbl(y - 40, (GRID_Z - R_TIP) / 2, str(-R_TIP - GRID_Z, " mm"), 11);
        lbl(y - 40, (GRID_Z - R_TIP) / 2 - 14, str("(>= ", GRID_MIN_DIST, ")"), 8);
        lbl(205, -R_TIP + 7, "blade tips z = -34", 8);
        lbl(205, GRID_Z + 7, str("mesh top z = ", GRID_Z), 8);
        // the fixed upper front panel and the short drawer front: the opening left by the drawer is entirely under the mesh
        translate([section_x, -180, uf_zb()]) cube([1.2, 140, 0.8], center = true);                                         // level line: the fixed panel's bottom edge
        lbl(-185, uf_zb() - 9, str("panel bottom z = ", uf_zb(), " (<= ", grid_zl(), ")"), 7);
        lbl(-205, -150, "FIXED front panel", 8);
        lbl(-205, -162, "(screwed on, 18 mm)", 7);
        lbl(-205, -295, "DRAWER front", 8);
        lbl(-205, -307, str("z ", GROUND_Z, " .. ", drf_zt()), 7);
        lbl(-205, -335, "opening: under the mesh", 7);
    }
}
if (grid_dims && !is_undef(section_x)) grid_dimensions();
if (section_pair) for (i = [0, 1]) translate([0, 0, -120 * i]) let($sec_y = shaft_y(i == 0 ? "A" : "B")) everything();
else everything();
