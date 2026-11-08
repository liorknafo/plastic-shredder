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
if (sel == "f_bearings")  for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) { bearing_inner_ph(e); bearing_outer_ph(e); }
if (sel == "f_rollers")   for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) bearing_rollers_ph(e);
if (sel == "f_seals")     for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) seal_ph(e);
if (sel == "f_thrust")    for (s = ["A", "B"], e = ["drive", "free"]) translate([0, shaft_y(s), 0]) thrust_ph(e);
if (sel == "f_crinkle")   for (s = ["A", "B"]) translate([0, shaft_y(s), 0]) crinkle_ph();
if (sel == "f_plates_free")  plates([0, 1, 2], ["free"]);
if (sel == "f_plates_drive") plates([0, 1, 2], ["drive"]);
if (sel == "f_combs")     { comb("A"); comb("B"); }
if (sel == "f_walls")     { wall(1); wall(-1); }
if (sel == "f_hopper")    { collar(); funnel(); }
if (sel == "f_lidswitch") { switch_ph(); switch_screws_ph(); }
if (sel == "f_skirts")    { skirt(1); skirt(-1); }
if (sel == "f_guards")    { free_end_cover(); drive_end_guard(); }
if (sel == "f_baseplate") base_plate();
if (sel == "f_cabinet")   cabinet_shell_panels();
if (sel == "f_upperfront") upper_front();
if (sel == "f_drawerpad") drawer_pad();
if (sel == "f_drawersw")  { drawer_switch_ph(); drawer_switch_screws_ph(); upper_front_screws_ph(); }
if (sel == "f_mesh")      grid_mesh();
if (sel == "f_cleats")    { grid_cleats(0); grid_cleats(1); }
if (sel == "f_gridscrews") grid_screws_ph();
if (sel == "f_gearbox")   gearbox_ph();
if (sel == "f_gbbolts")   { gb_foot_bolts_ph(); rail_bolts_ph(); tens_bolts_ph(); tens_bolt_ph(); }
if (sel == "f_rails")     gb_mount();
if (sel == "f_idler")     tens_idler_ph();
if (sel == "f_tensioner") { tens_upright(); tens_base(); }
if (sel == "f_chain")     chain_band(0);
if (sel == "f_motor")     motor_ph();
if (sel == "f_belt")      belt_ph();
if (sel == "f_beltguard") { belt_guard(0); belt_guard(1); }
if (sel == "f_beltguardhw") belt_guard_hw_ph();
if (sel == "f_deck")      { drive_deck(); deck_legs(); }
if (sel == "f_angles")    { top_angles(); foot_angles(); }
if (sel == "f_deckbolts") { topang_deck_bolts_ph(); topang_leg_bolts_ph(); footang_leg_bolts_ph(); }
if (sel == "f_anchors")   anchors_ph();

// ---- Rotors (sh = "A" | "B")
if (sel == "r_shaft")    rot0() shaft_local(sh);
if (sel == "r_blades")   rot0() blades_of(sh);
if (sel == "r_spacers")  rot0() spacers_of(sh);
if (sel == "r_sleeves")  rot0() { clamp_sleeves_of(sh); collared_sleeves_of(sh); gear_spacer_ph(); }
if (sel == "r_gear")     rot0() gear_ph(sh);
if (sel == "r_sprocket") rot0() sprocket_ph();
if (sel == "r_screws")   rot0() { end_screw_drive(sh); end_screw_free(); }

// ---- Lid (closed)
if (sel == "l_lid")  { lid_posed(0); lid_pad_posed(0); }
if (sel == "l_hw")   lid_hw_posed(0);
if (sel == "l_key")  lid_actuator_posed(0);

// ---- Drawer (closed)
if (sel == "d_panels")  drawer_panels();
if (sel == "d_printed") { handle_world(); drawer_act_pad(); }
if (sel == "d_screws")  { handle_screws_ph(); drawer_actuator_screws_ph(); }
if (sel == "d_key")     drawer_actuator();

// ---- Torque limiter + output shaft
if (sel == "t_shaft") output_shaft_ph();
if (sel == "t_tl")    tl_ph();
if (sel == "t_hw")    shaft_hw_ph();

// ---- Worm + gearbox pulley (axis along y), motor shaft + motor pulley (axis along y)
if (sel == "w_worm")   worm_ph();
if (sel == "w_pulley") pulley_ph(XG, GEARBOX_PULLEY_D, 19);
if (sel == "m_shaft")  motor_shaft_ph();
if (sel == "m_pulley") pulley_ph(XM, MOTOR_PULLEY_D, 12);
