// joints.scad -- ONE coordinate function per bolted joint that more than one part needs.  `include` it AFTER common.scad.
// Every hole that receives a fastener from another part (in the base plate, the drive deck, the cabinet, the end plates, the sub-plate ...) is
// placed from the function below, never from a number typed into the part: change the function and BOTH parts follow.  The alignment checks
// (checks.scad C16*) push a bolt shank through the hole of part 1 and the hole of part 2 and fail if it touches either part's material.
//
//   foot_screw_xy()    8 x M6: base-plate foot slots  <->  end-plate layers                       (base.scad, plate.scad)
//   guard_hole_yz()    4 x M5: drive-end guard wings / free-end cover  <->  cap layers (tapped)   (plate.scad, guards.scad)
//   gb_foot_pts()      4 x M8: gearbox foot flange  <->  sub-plate (tapped)                       (drive.scad, drive_geom.scad)
//   SUBBOLT_PTS        4 x M8: sub-plate  <->  drive deck                                         (drive.scad)
//   TENS_BOLT_PTS      4 x M8: tensioner base plate  <->  drive deck                              (drive.scad)
// The other joints (cabinet hang screws, belt-guard feet, deck legs, handle, interlock pads, guard seam ears ...) have both ends in ONE file and
// their functions live there (hang_screw_xy, bg_foot_screw_uw, dg_ear_pts, ...); checks.scad C16 covers all of them.
include <drive_geom.scad>

FOOT_SCREW_Y = 65;                                       // |y| of the M6 feet in the bottom edge of the inner / outer end-plate layers
function layer_centre_x(end, i) = end == "drive" ? -LAYER_T * (i + 0.5) : chamber_L + LAYER_T * (i + 0.5);   // i = 0 inner, 1 outer
function foot_screw_xy() = [for (e = ["drive", "free"], i = [0, 1], y = [-FOOT_SCREW_Y, FOOT_SCREW_Y]) [layer_centre_x(e, i), y]];
function guard_hole_yz() = [for (sy = [-1, 1], sz = [-1, 1]) [sy * GUARD_HOLE_Y, sz * GUARD_HOLE_Z]];
