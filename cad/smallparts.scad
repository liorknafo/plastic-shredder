// smallparts.scad -- exported small printed/turned parts: hub spacer and end cap.  -D 'part="hub_spacer"|"end_cap"'
include <common.scad>
use <placeholders.scad>
part = "hub_spacer";
if (part == "hub_spacer") hub_spacer(); else end_cap();
