// parts.scad -- per-body exporter for the SolidCraft assembly (cad/solidcraft/build.py).
// Not part of the design: it only CALLS the modules cad/assembly.scad calls (same arguments), one body at a time, at angle = 0, lid_open = 0, drawer closed.
//   openscad -D 'sel="f_cabinet"' -o f_cabinet.stl parts.scad        with OPENSCADPATH=<repo>/cad
// `sel` is the key used in manifest.py (component, body name, colour).
include <common.scad>
include <drive_geom.scad>
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

sel = "";
sh  = "A";          // shaft for the r_* bodies

module rot0() translate([0, shaft_y(sh), 0]) children();       // = rot_frame(sh, 0)

// ---- Frame
if (sel == "f_bearings")  for (s = ["A", "B"], e = ["drive", "free", "ob"]) translate([0, shaft_y(s), 0]) { bearing_inner_ph(e); bearing_outer_ph(e); }
if (sel == "f_rollers")   for (s = ["A", "B"], e = ["drive", "free", "ob"]) translate([0, shaft_y(s), 0]) bearing_rollers_ph(e);
if (sel == "f_seals")     for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) seal_ph(e);
if (sel == "f_thrust")    for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) thrust_ph(e);
if (sel == "f_crinkle")   for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) crinkle_ph();
if (sel == "f_plates_free")  plates([0, 1, 2], ["free"]);
if (sel == "f_plates_drive") plates([0, 1, 2], ["drive"]);
if (sel == "f_plates_ob")    { plates([3, 4], ["drive"]); standoffs(); }
if (sel == "f_combs")     { comb("A"); comb("B"); }
if (sel == "f_walls")     { wall(1); wall(-1); }
if (sel == "f_hopper")    { collar(); funnel(); }
if (sel == "f_lidswitch") { switch_ph(); switch_screws_ph(); }
if (sel == "f_screen")    screen();
if (sel == "f_screenscrews") { screen_screws_ph(); wall_screws_ph(); }
if (sel == "f_guards")    { free_end_cover(); drive_end_guard(); }
if (sel == "f_baseplate") base_plate();
if (sel == "f_cabinet")   cabinet_shell_panels();
if (sel == "f_gearbox")   gearbox_ph();
if (sel == "f_gbbolts")   { gb_foot_bolts_ph(); rail_bolts_ph(); }
if (sel == "f_rails")     gb_mount();
if (sel == "f_motor")     motor_ph();
if (sel == "f_cplguard")  { cpl_guard(); stub_cap(); }
if (sel == "f_cplguardhw") cg_screws_ph();
if (sel == "f_deck")      { drive_deck(); deck_legs(); }
if (sel == "f_angles")    { top_angles(); foot_angles(); }
if (sel == "f_deckbolts") { topang_deck_bolts_ph(); topang_leg_bolts_ph(); footang_leg_bolts_ph(); }
if (sel == "f_anchors")   anchors_ph();

// ---- Rotors (sh = "A" | "B")
if (sel == "r_shaft")    rot0() shaft_local(sh);
if (sel == "r_blades")   rot0() blades_of(sh);
if (sel == "r_spacers")  rot0() spacers_of(sh);
if (sel == "r_sleeves")  rot0() { clamp_sleeves_of(sh); collared_sleeves_of(sh); gear_spacer_ph(); ob_sleeve_ph(sh); }
if (sel == "r_gear")     rot0() gear_ph(sh);
if (sel == "r_sprocket") rot0() sprocket_ph();
if (sel == "r_screws")   rot0() { end_screw_drive(sh); end_screw_free(); }

// ---- Lid (closed)
if (sel == "l_lid")  { lid_posed(0); lid_pad_posed(0); }
if (sel == "l_hw")   lid_hw_posed(0);
if (sel == "l_key")  lid_actuator_posed(0);

// ---- Drawer (closed)
if (sel == "d_panels")  drawer_panels();
if (sel == "d_printed") handle_world();
if (sel == "d_screws")  handle_screws_ph();

// ---- Output shaft + the pin flange and its 4 pins (coaxial with shaft A; the TL350 is on shaft A: r_sprocket)
if (sel == "t_shaft") output_shaft_ph();
if (sel == "t_tl")    { pin_flange(); pins_ph(); }
if (sel == "t_hw")    shaft_hw_ph();

// ---- Worm, jaw coupling, motor shaft (all on one axis along y)
if (sel == "w_worm")   worm_ph();
if (sel == "w_coupling") coupling_ph();
if (sel == "m_shaft")  motor_shaft_ph();
