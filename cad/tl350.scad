// tl350.scad -- the Tsubaki TL350-2 friction torque limiter to the MANUFACTURER'S layout, in its own frame, shared by drive.scad and tlfix.scad.  `include` after common.scad.
// Frame: axis on the x axis, x = 0 at the hub FLANGE-END face, the hub runs to +x for TL_L = 62 (the adjusting-nut end).  All dimensions from params.py:
//   hub L = 62, hub OD DH = 42, outer D = 89 (flange, plates, springs, nut), centre member (the #40 30T sprocket, plate 7.2, S <= 16) on a bushing BETWEEN the hub
//   flange and the pressure plate: its mid-plane is TL_CM_OFFSET = 12 from the flange-end face.  Stack (x from the flange-end face):
//     0 .. 8 flange | 8 .. 16 friction pack (linings 8 .. 8.4 and 15.6 .. 16, sprocket plate 8.4 .. 15.6 between them) | 16 .. 24 pressure plate | 24 .. 50 disc springs | 50 .. 62 adjusting nut
// Every part is modelled seated with 0.01 mm on every face and Ø25.02 over the Ø25 shaft (like the other bought parts), so touching neighbours do not show as overlaps.
TL_FIT = 0.01;
TL_LIN_L = TL_CM_OFFSET - SPROCKET_T / 2 - TL_FLANGE_T;                  // friction lining each side of the sprocket plate (0.4)
TL_PRESS_X0 = TL_CM_OFFSET + SPROCKET_T / 2 + TL_LIN_L;                  // 16
TL_SPRING_X0 = TL_PRESS_X0 + TL_PRESS_T;
TL_NUT_X0 = TL_SPRING_X0 + TL_SPRING_L;
module tlt(od, x0, len, id = TL_HUB_D) translate([x0 + TL_FIT, 0, 0]) rotate([0, 90, 0]) difference() {
    cylinder(d = od - 2 * TL_FIT, h = len - 2 * TL_FIT, $fn = 96);
    translate([0, 0, -1]) cylinder(d = id + 2 * TL_FIT, h = len + 2, $fn = 96);
}
module tl_flange_l()  tlt(TL_D, 0, TL_FLANGE_T);
module tl_pack_l()    { tlt(TL_PACK_D, TL_FLANGE_T, TL_LIN_L); tlt(TL_PACK_D, TL_CM_OFFSET + SPROCKET_T / 2, TL_LIN_L); }     // friction linings
module tl_plate_l()   tlt(tl_sprocket_pd + SPROCKET_OD_EXTRA, TL_CM_OFFSET - SPROCKET_T / 2, SPROCKET_T);      // the sprocket's tooth plate
module tl_press_l()   tlt(TL_D, TL_PRESS_X0, TL_PRESS_T);
module tl_spring_l()  tlt(TL_D, TL_SPRING_X0, TL_SPRING_L);
module tl_nut_l()     tlt(TL_D, TL_NUT_X0, TL_L - TL_NUT_X0);
module tl_hub_l()     tlt(TL_HUB_D, 0, TL_L, JOURNAL_D);
module tl350_l() { tl_flange_l(); tl_pack_l(); tl_plate_l(); tl_press_l(); tl_spring_l(); tl_nut_l(); tl_hub_l(); }
module tl350_body_l() { tl_flange_l(); tl_pack_l(); tl_press_l(); tl_spring_l(); tl_nut_l(); tl_hub_l(); }      // everything except the sprocket's tooth plate
