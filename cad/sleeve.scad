// sleeve.scad -- clamp sleeves (OD 30 = SLEEVE_OD, also the oil-seal running surface) and the COLLARED sleeves (turned from the Ø55 bar).
// Part frame: axis along +Z from 0.  Collared sleeve: collar (OD COLLAR_OD x COLLAR_T) at z = 0, then the Ø30 body.
include <params.scad>

module tube(od, id, L) {
    $fn = 96;
    difference() {
        cylinder(d = od, h = L);
        translate([0, 0, -1]) cylinder(d = id, h = L + 2);
    }
}

module sleeve(L) tube(SLEEVE_OD, SLEEVE_ID, L);
// collar first (z 0 .. COLLAR_T), body after it
module collared(Lb) { tube(COLLAR_OD, SLEEVE_ID, COLLAR_T); translate([0, 0, COLLAR_T - 0.01]) tube(SLEEVE_OD, SLEEVE_ID, Lb + 0.01); }

// standalone render:  -D 'kind="drive"|"free_A"|"free_B"|"collar_drive"|"collar_free"|"gear_spacer"'
kind = "drive";
if (kind == "drive") sleeve(sleeve_L_drive);
else if (kind == "free_A") sleeve(sleeve_L_free_A);
else if (kind == "free_B") sleeve(sleeve_L_free_B);
else if (kind == "collar_drive") collared(collar_body_L_drive);
else if (kind == "gear_spacer") tube(GEAR_SPACER_D, SLEEVE_ID, gear_spacer_L);
else collared(collar_body_L_free);
