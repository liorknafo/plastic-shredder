// axes.scad -- prints the joint geometry of the SolidCraft assembly (read by build.py):
//   OPENSCADPATH=<repo>/cad openscad -D 'part="none"' -o /dev/null.stl axes.scad     (part="none": hopper.scad and drive.scad render nothing)
include <common.scad>
include <drive_geom.scad>
include <hopper.scad>
echo(AX = [
    ["shaft_y_A", shaft_y("A")], ["shaft_y_B", shaft_y("B")],
    ["lid_pin_y", PIN_Y], ["lid_pin_z", PIN_Z], ["lid_x_mid", XC],
    ["out_y", YA], ["out_z", ZO],
    ["worm_x", XG], ["worm_z", ZW], ["worm_y0", GB_Y0],
    ["motor_x", XM], ["motor_z", ZM],
    ["gear_z", GEAR_z]]);
cube(1);
