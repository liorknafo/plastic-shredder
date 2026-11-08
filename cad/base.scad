// base.scad -- 18 mm plywood base plate, the bin cabinet below it, the drawer with its printed pull handle and interlock pads,
//   World frame.
//   -D 'part="base_plate"|"cabinet"|"base_2d"|"cabinet_2d"|"drawer_handle"|"drawer_pad"|"drawer_act_pad"|"world"'
//
// ONE SOURCE FOR 3D AND DXF.  Every plywood panel is a 2D module (p_*_2d, base_2d) in its own (u, v) frame.  The 3D part extrudes that
//   module and the DXF sheet (cabinet_2d, base_2d) uses the same module, so the drawing and the model cannot diverge.
//
// BASE   the shredder box sits on it at z = -35 on 8 M6 feet (y = +-65, in the bottom edges of the inner and outer layers; slots +-2 mm in x).
//   A plain rectangle: x -30 .. chamber_L + 70, y -115 .. 110 (it carries the machine and the cabinet's 6 hang screws).  There is no rear wing any more: the
//   drive is OUTSIDE the cabinet on the -x side (the cabinet starts at x = -30, the chain plane is at x = -105) on its own deck (drive.scad), and the gearbox is
//   foot-mounted on that deck, so nothing is anchored to the base.
// CABINET  under the base, x -30 .. chamber_L+30, y -110 .. 110; the drawer bin (150+ mm wide, 303 mm below the outlet plane z = -35) slides
//   in from the front (-y).  The side panels hang on 6 screws through the base plate (x = panel centre line, set from the top BEFORE
//   the machine goes on the base: the end plates cover the heads).
// FIXED UPPER FRONT PANEL  18 mm ply in the plane of the drawer front (y = CAB_Y0 .. DR_Y0, the full width of the cabinet), from the underside of the base plate (face contact)
//   DOWN to UFRONT_ZB, at or below the underside of the lower grid cleats (GRID_ZL).  It is SCREWED on (a tool is needed to remove it): 4 x M4 x 45 from the top of the base
//   plate down into its top edge (the base plate reaches y = BASE_Y0 = -115, so it covers the panel) and 2 x 2 M4 x 45 through its face into the front edges of the side
//   panels.  This is what keeps the space ABOVE the mesh closed when the drawer is pulled out or removed: the opening the drawer leaves is entirely UNDER the mesh.
// DRAWER FRONT  18 mm panel in the same plane, the full width of the cabinet, from the bottom of the cabinet up to UFRONT_GAP (1 mm) under the fixed panel (z = DRF_ZT);
//   closed, it leaves that 1 mm gap and no other gap.  It has NO opening: the pull handle is a printed part on its outside, held by 2 x M4 x 22 screws that come
//   from INSIDE the bin through two Ø4.5 holes (each filled by its screw and covered by the handle) into heat-set inserts in the handle.
// DRAWER INTERLOCK  the Omron D4NS-2AF plain safety switch (positive-opening NC contacts; interlock.scad, APPROXIMATE envelope DSW_*: 30 x 90 x 30, drill to the
//   Omron drawing) on a flat 10 mm PAD on the OUTSIDE of the free-end side panel at the front (2 x M4 at 22 mm, slot facing the front, away from the shred
//   stream), and its D4DS-K2 key (DACT_*, approx. 50 x 15 x 12) on a flat printed PAD on the end face of the drawer front (2 x M4 at DACT_HOLE_SPACING).  Both pads sit at
//   DRAWER_SW_Z, inside the height of the (short) drawer front, under the handle and well under the grid cleat screws.
//   The key enters the head slot INTERLOCK_IN = 12 mm with the drawer fully closed and is completely out after 12 mm of travel (spec: out within
//   INTERLOCK_OUT_TRAVEL).  There is NO printed tongue.
// SAFETY GRID  (the real protection from below): a sheet of 1" welded wire mesh (GRID_PITCH, GRID_WIRE) across the WHOLE inside of the cabinet at GRID_Z, resting on
//   20 x 20 cleats (lower set) and held down by a second set (upper set), screwed from outside through the side and back panels.  The "front wall" of the cabinet above
//   the grid is the FIXED upper front panel, but the front cleats are not on it: they span the cabinet and are end-screwed through the side panels (1 mm clear of
//   the fixed panel and of the drawer front).  The drawer bin is only GRID_Z-dependent in height: its top stays GRID_BIN_CLEAR under the lower cleats (DR_H below).
//
// OPENINGS (Ø16 finger test, checks.scad C9 / C30).  Everything that is open in the cabinet / drawer / base / skirts / guards, with its size:
//   base plate   outlet cut-out 132.2 x 110       -> into the cabinet only; the cabinet is closed (sides, back, floor, fixed upper front panel, drawer front)
//                8 foot slots 10.6 x 6.6          -> closed from above by the end plates standing on them, filled by M6 screws
//                6 x Ø5 cabinet hang holes        -> filled by the hang screws
//                4 x Ø5 holes for the fixed front panel's top screws -> filled by the screws
//   cabinet      34 x Ø4.5 holes for the grid cleat screws (14 per side panel, 6 in the back), each filled by its screw
//   fixed front  4 x Ø4.5 holes (2 per side panel), each filled by its M4 screw; the panel closes the whole front of the cabinet from the base plate down to UFRONT_ZB
//                (<= GRID_ZL), so with the drawer REMOVED the only opening left is x = -12 .. 144.2, z = floor .. UFRONT_ZB: entirely UNDER the mesh (C30)
//   grid         mesh clear openings 23.4 x 23.4 (<= 30: ISO 13857 Table 4 gives 120 mm safety distance; the mesh top is 136 mm under the blade tips), edge gap 1 mm
//   drawer       front: 2 x Ø4.5 (filled by the M4 screws, covered by the handle); bin: closed box;
//                the gap between the drawer front and the fixed panel is 1 mm; all other joints are face contacts (C9a: no gap >= 4 mm round the closed drawer front)
//   skirts       3 x Ø4.5 flange holes, filled by M4 screws
//   drive guard  closed shell on the cap face (wings: 4 x Ø5.5 holes filled by M5 screws); the tensioner upright passes the chain tube's bottom through a notch with 3 mm all round
//   free cover   4 x Ø5.5 holes filled by M5 screws
//   hopper       top opening 180 x 180 closed by the interlocked lid.  The drawer opening (below the fixed front panel, under the mesh) is closed by the interlocked drawer
//                front and, when that is pulled out, protected by the grid.  These two are the ONLY openings >= 6 mm.
include <common.scad>
include <joints.scad>
// the drawer switch = Omron D4NS-2AF + D4DS-K2 key (all approximate); interlock.scad is a template built from these values
IL_SW_BODY = DSW_BODY;  IL_SW_HOLE_SPACING = DSW_HOLE_SPACING;  IL_SW_SLOT = DSW_SLOT;  IL_SW_SCREW = DSW_SCREW;
IL_ACT_SIZE = DACT_SIZE;  IL_ACT_BLADE_T = DACT_BLADE_T;  IL_ACT_BLADE_L = DACT_BLADE_L;  IL_ACT_HOLE_SPACING = DACT_HOLE_SPACING;  IL_ACT_SCREW = DACT_SCREW;
include <interlock.scad>

BASE_NX = -30;  BASE_X0 = BASE_NX;  BASE_X1 = chamber_L + 30 + 40;
BASE_Y0 = -115;  BASE_Y1 = 110;                                      // y1 = the cabinet's back (CAB_Y1): the hang screws at y = 80 need plywood under them
BASE_Z1 = -PLATE_H / 2;  BASE_Z0 = BASE_Z1 - BASE_T;
FOOT_SLOT = 2;                                                       // +-2 mm in x   (the 8 foot screws: foot_screw_xy() in joints.scad, shared with plate.scad)

// ---------------- cabinet constants
CAB_X0 = -30;  CAB_X1 = chamber_L + 30;  CAB_T = 18;  CAB_Y0 = -110;  CAB_Y1 = 110;
CAB_ZT = BASE_Z0;                                                    // underside of the base
CAB_FLOOR_TOP = -350;  CAB_ZB = CAB_FLOOR_TOP - CAB_T;               // -368
DR_T = 10;  DR_W = 154;  DR_Y0 = CAB_Y0 + CAB_T;  DR_L = 160;  DR_Z0 = CAB_FLOOR_TOP + 2;
// ---------------- fixed safety grid: constants (modules further down).  The bin must slide in UNDER the lower cleats, so its height follows GRID_Z.
GRID_LAYER = GRID_WIRE - 0.1;                                        // the two crossed wire layers overlap 0.1 mm (the weld): no tangent-only contact in the model
GRID_T = GRID_WIRE + GRID_LAYER;                                     // 3.9 thick
GRID_ZB = GRID_Z - GRID_T;                                           // underside of the mesh = top of the lower cleats  (-173.9)
GRID_ZL = GRID_ZB - GRID_CLEAT;                                      // underside of the lower cleats (-193.9)
DR_H = floor(GRID_ZL - GRID_BIN_CLEAR - DR_Z0);                      // bin height 150: its top (-198) stays GRID_BIN_CLEAR under the lower cleats; it was 250 (top at -98) before the grid
BIN_FLOOR = DR_Z0 + DR_T;                                            // -338: 303 below the outlet plane (z = -35)
CAB_XC = (CAB_X0 + CAB_X1) / 2;
CAB_W = CAB_X1 - CAB_X0;  CAB_H = CAB_ZT - CAB_ZB;  CAB_SIDE_W = CAB_Y1 - DR_Y0;       // 192.2, 315, 202
HANG_X = [CAB_X0 + CAB_T / 2, CAB_X1 - CAB_T / 2];  HANG_Y = [-80, 0, 80];              // cabinet side panels hang on 6 screws
function hang_screw_xy() = [for (x = HANG_X, y = HANG_Y) [x, y]];                       // the ONE definition: base-plate Ø5 holes AND the pilots in the panel tops
HANG_PILOT_D = 3.3;  HANG_PILOT_DEPTH = 25;                                             // M4 x 45 screws: 18 plywood + 25 into the panel edge
assert(BASE_Z1 - BIN_FLOOR >= 300);
assert(CAB_ZB == GROUND_Z);
// ---------------- the fixed upper front panel and the (short) sliding drawer front: both derived from the grid, nothing typed in
UFRONT_ZB = floor(GRID_ZL - UFRONT_BELOW);                           // bottom edge of the fixed panel: -195, UFRONT_BELOW under the lower cleats (GRID_ZL = -193.9)
UFRONT_H = CAB_ZT - UFRONT_ZB;                                       // 142: from the underside of the base (face contact) down to UFRONT_ZB
DRF_ZT = UFRONT_ZB - UFRONT_GAP;                                     // top of the drawer front: -196
DRF_H = DRF_ZT - CAB_ZB;                                             // 172
UF_SCREW_Y = (CAB_Y0 + DR_Y0) / 2;                                   // the top screws go down the middle of the panel's thickness (y = -101); the base plate reaches BASE_Y0 = -115
UF_TOP_X = [for (i = [0 : 3]) CAB_X0 + 30 + i * (CAB_W - 60) / 3];  // 4 screws, 30 mm in from the ends, evenly spaced
function uf_top_xy() = [for (x = UF_TOP_X) [x, UF_SCREW_Y]];                                       // the ONE definition: base-plate Ø5 holes AND the pilots in the panel's top edge
UF_FACE_X = [CAB_X0 + CAB_T / 2, CAB_X1 - CAB_T / 2];  UF_FACE_Z = [CAB_ZT - 47, CAB_ZT - 77];     // through the face into the side panels' front edges (clear of the hang pilots z > -78 and of the grid screws z < -150)
function uf_face_xz() = [for (x = UF_FACE_X, z = UF_FACE_Z) [x, z]];                                // the ONE definition: Ø4.5 holes in the panel AND the pilots in the side panels
assert(UFRONT_ZB <= GRID_ZL, "the fixed upper front panel must reach down to or below the underside of the lower grid cleats");
assert(UFRONT_GAP > 0 && UFRONT_GAP < 4, "gap between the fixed panel and the drawer front: > 0 and < 4 mm (C9a)");
assert(CAB_ZB + DRF_H >= DR_Z0 + DR_H, "the drawer front must cover the bin");
assert(BASE_Y0 <= CAB_Y0 && BASE_Y1 >= CAB_Y0 + CAB_T, "the base plate must cover the top edge of the fixed panel (top screws)");

// ---------------- fixed safety grid: geometry.  ONE definition for the 3D mesh, the DXF, the checks and the screw holes in the plywood.
GRID_IX0 = CAB_X0 + CAB_T;  GRID_IX1 = CAB_X1 - CAB_T;  GRID_IY0 = DR_Y0;  GRID_IY1 = CAB_Y1 - CAB_T;     // the inside of the cabinet: x -12 .. 144.2, y -92 .. 92
GRID_WX = GRID_IX1 - GRID_IX0;  GRID_WY = GRID_IY1 - GRID_IY0;                                          // 156.2 x 184
GRID_NX = floor((GRID_WX - GRID_WIRE - 2 * GRID_EDGE_GAP) / GRID_PITCH) + 1;                            // wires running along y (their x positions): 7
GRID_NY = floor((GRID_WY - GRID_WIRE - 2 * GRID_EDGE_GAP) / GRID_PITCH) + 1;                            // wires running along x (their y positions): 8
GRID_LX = (GRID_NX - 1) * GRID_PITCH + GRID_WIRE;  GRID_LY = (GRID_NY - 1) * GRID_PITCH + GRID_WIRE;    // CUT SIZE of the sheet: 154.4 x 179.8
GRID_GX = (GRID_WX - GRID_LX) / 2;  GRID_GY = (GRID_WY - GRID_LY) / 2;                                  // gap sheet to wall: 0.9 (x), 2.1 (y)
GRID_X0 = CAB_XC - GRID_LX / 2;  GRID_Y0 = (GRID_IY0 + GRID_IY1) / 2 - GRID_LY / 2;
GRID_FCLR = 1;  GRID_FY = GRID_IY0 + GRID_FCLR;                                                           // the front rail stands 1 mm clear of the fixed upper front panel and of the sliding drawer front (their inner face y = -92)
GRID_PD = 17;                                                                                           // pilot depth in the cleat for the M4 x 35 (18 plywood + 17)
assert(GRID_PITCH - GRID_WIRE <= GRID_MAX_OPEN, "grid: the clear opening must be <= 30 mm (ISO 13857 Table 4: 120 mm distance for square openings 20 < e <= 30)");
assert(GRID_Z <= -R_TIP - GRID_MIN_DIST, "grid: its top must be >= 120 mm below the lowest point of the blade-tip envelope (z = -R_TIP)");
assert(GRID_GX >= GRID_EDGE_GAP - 1e-9 && GRID_GY >= GRID_EDGE_GAP - 1e-9 && GRID_GX < GRID_MAX_EDGE_GAP && GRID_GY < GRID_MAX_EDGE_GAP,
       "grid: the sheet must clear the walls by >= GRID_EDGE_GAP and leave an edge gap < 10 mm");
assert(DR_Z0 + DR_H + GRID_BIN_CLEAR <= GRID_ZL + 1e-9 && DR_H >= 100, "the bin must stay under the lower cleats and at least 100 high");
function grid_xs() = [for (i = [0 : GRID_NX - 1]) CAB_XC + (i - (GRID_NX - 1) / 2) * GRID_PITCH];                               // x of the wires that run along y
function grid_ys() = [for (j = [0 : GRID_NY - 1]) (GRID_IY0 + GRID_IY1) / 2 + (j - (GRID_NY - 1) / 2) * GRID_PITCH];            // y of the wires that run along x
// cleats: 20 x 20 timber on the four walls, lower set under the mesh, upper set on top; plan boxes [x0, y0, x1, y1].  The FRONT "wall" is the drawer front, which slides
// out: the front cleat is a rail that spans the cabinet and is end-screwed through the side panels, GRID_FCLR clear of the drawer front.
function grid_cleat_boxes() = let (c = GRID_CLEAT) [
    [GRID_IX0, GRID_FY, GRID_IX1, GRID_FY + c],                      // front rail
    [GRID_IX0, GRID_IY1 - c, GRID_IX1, GRID_IY1],                    // back
    [GRID_IX0, GRID_FY + c, GRID_IX0 + c, GRID_IY1 - c],             // drive-end side
    [GRID_IX1 - c, GRID_FY + c, GRID_IX1, GRID_IY1 - c]];            // free-end side
function grid_level_z(level) = level == 0 ? GRID_ZB - GRID_CLEAT / 2 : GRID_Z + GRID_CLEAT / 2;       // mid-height of the lower (0) / upper (1) cleats
// the screws: [[point on the cleat's wall face], [direction into the cabinet]]; M4 x 35 from OUTSIDE through a Ø4.5 hole in the plywood into a Ø3 pilot in the cleat
function grid_screws(level) = let (z = grid_level_z(level), c = GRID_CLEAT) concat(
    [for (w = [0, 1], y = [GRID_FY + c / 2, GRID_IY1 - c / 2], dz = [-5, 5]) [[w == 0 ? GRID_IX0 : GRID_IX1, y, z + dz], [w == 0 ? 1 : -1, 0, 0]]],   // end grain of the front rail / back cleat, 2 per end
    [for (w = [0, 1], y = [-48, 0, 48]) [[w == 0 ? GRID_IX0 : GRID_IX1, y, z], [w == 0 ? 1 : -1, 0, 0]]],                                              // the side cleats
    [for (x = [CAB_XC - 50, CAB_XC, CAB_XC + 50]) [[x, GRID_IY1, z], [0, -1, 0]]]);                                                                   // the back cleat, through the back panel
function grid_side_holes() = [for (lv = [0, 1], s = grid_screws(lv)) if (s[1][0] == 1) [s[0][1] - DR_Y0, s[0][2] - CAB_ZB]];                          // (u, v) in p_side_2d
function grid_back_holes() = [for (lv = [0, 1], s = grid_screws(lv)) if (s[1][1] == -1) [s[0][0] - (CAB_X0 + CAB_T), s[0][2] - CAB_ZB]];              // (u, v) in p_back_2d

// ---------------- 2D outlines: the ONLY definition of each panel (3D parts and DXF both use these)
module base_2d() {
    difference() {
        translate([BASE_X0, BASE_Y0]) square([BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0]);
        translate([0, -55]) square([chamber_L, 110]);                                           // outlet cut-out
        for (p = foot_screw_xy()) hull() for (dx = [-FOOT_SLOT, FOOT_SLOT]) translate([p[0] + dx, p[1]]) circle(d = 6.6, $fn = 32);   // M6 feet (end plates)
        for (p = hang_screw_xy()) translate(p) circle(d = 5, $fn = 24);                         // cabinet hang screws, centred on the panel edges
        for (p = uf_top_xy()) translate(p) circle(d = 5, $fn = 24);                             // the fixed upper front panel's top screws, down the middle of its thickness
    }
}
module p_side_2d() difference() {                                         // u = y - DR_Y0 (front edge at u = 0), v = z - CAB_ZB;  14 x Ø4.5 for the grid cleat screws
    square([CAB_SIDE_W, CAB_H]);
    for (p = grid_side_holes()) translate(p) circle(d = GRID_SCREW[1], $fn = 24);
}
module p_back_2d() difference() {                                         // u = x - (CAB_X0 + CAB_T);  6 x Ø4.5 for the back cleats
    square([CAB_W - 2 * CAB_T, CAB_H]);
    for (p = grid_back_holes()) translate(p) circle(d = GRID_SCREW[1], $fn = 24);
}
module p_floor_2d() square([CAB_W, CAB_SIDE_W]);                         // u = x - CAB_X0, v = y - DR_Y0
function handle_screw_xz() = [for (s = [-1, 1]) [CAB_XC + s * HANDLE_SCREW_DX, HANDLE_Z]];       // the ONE definition (world x, z): drawer-front holes AND handle inserts
HANDLE_PTS = [for (p = handle_screw_xz()) [p[0] - CAB_X0, p[1] - CAB_ZB]];                      // in the drawer-front frame
module p_front_2d(test_hole_d = 0)                                       // drawer front: u = x - CAB_X0, v = z - CAB_ZB.  test_hole_d only for the C9 control
    difference() {
        square([CAB_W, DRF_H]);
        for (p = HANDLE_PTS) translate(p) circle(d = HANDLE_HOLE_D, $fn = 32);
        if (test_hole_d > 0) translate([CAB_W / 2, DRF_H / 2]) circle(d = test_hole_d, $fn = 32);
    }
module p_ufront_2d(raise = 0)                                            // fixed upper front panel: u = x - CAB_X0, v = z - UFRONT_ZB.  raise only for the C30 control (bottom edge raised)
    difference() {
        translate([0, raise]) square([CAB_W, UFRONT_H - raise]);
        for (p = uf_face_xz()) translate([p[0] - CAB_X0, p[1] - UFRONT_ZB]) circle(d = HANDLE_HOLE_D, $fn = 24);   // 4 x Ø4.5 for the M4 screws into the side panels
    }
module p_dbottom_2d() square([DR_W, DR_L]);
module p_dside_2d()   square([DR_L, DR_H - DR_T]);
module p_dback_2d()   square([DR_W - 2 * DR_T, DR_H - DR_T]);

// ---------------- placement: extrusions of the 2D modules above
module yz_panel(x0, y0, z0, t) axial(x0) translate([y0, z0]) linear_extrude(t) children();                // panel in the y-z plane, x0 .. x0+t
module xz_panel(x0, y1, z0, t) multmatrix([[1, 0, 0, x0], [0, 0, -1, y1], [0, 1, 0, z0], [0, 0, 0, 1]])  // panel in the x-z plane, y1-t .. y1
    linear_extrude(t) children();
module xy_panel(x0, y0, z0, t) translate([x0, y0, z0]) linear_extrude(t) children();                     // panel in the x-y plane, z0 .. z0+t

module base_plate() translate([0, 0, BASE_Z0]) linear_extrude(BASE_T) base_2d();
UF_PILOT_D = 3.3;  UF_PILOT_DEPTH = 25;                                                       // M4 x 45: 18 plywood + 25 into the edge (like the hang screws)
module cab_side(free_end) difference() {
    yz_panel(free_end ? CAB_X1 - CAB_T : CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_side_2d();
    for (p = hang_screw_xy()) if (abs(p[0] - HANGX(free_end)) < 0.01)                                  // pilots for the hang screws, in the top edge
        translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH]) cylinder(d = HANG_PILOT_D, h = HANG_PILOT_DEPTH + 1, $fn = 20);
    for (p = uf_face_xz()) if (abs(p[0] - HANGX(free_end)) < 0.01)                                     // pilots for the fixed front panel's face screws, in the front edge
        translate([p[0], DR_Y0 - 1, p[1]]) rotate([-90, 0, 0]) cylinder(d = UF_PILOT_D, h = UF_PILOT_DEPTH + 1, $fn = 20);
    if (free_end) for (q = sw_pad_screw_yz()) translate([CAB_X1 + 1, q[0], q[1]]) rotate([0, -90, 0]) cylinder(d = 4, h = 15, $fn = 20);   // pilots for the switch pad screws, from the outer face
}
function HANGX(free_end) = free_end ? HANG_X[1] : HANG_X[0];
module cabinet_shell_panels() {
    cab_side(false);                                                                                    // side (drive end)
    cab_side(true);                                                                                     // side (free end)
    xz_panel(CAB_X0 + CAB_T, CAB_Y1, CAB_ZB, CAB_T) p_back_2d();                                       // back
    xy_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_floor_2d();                                               // floor
}
module cabinet_panels() { cabinet_shell_panels(); upper_front(); }                                      // + the FIXED upper front panel (the drawer front is a separate, sliding part)
module drawer_front(test_hole_d = 0) difference() {                                                        // closes the opening below the fixed upper panel, no slot
    xz_panel(CAB_X0, DR_Y0, CAB_ZB, CAB_T) p_front_2d(test_hole_d);
    for (q = act_pad_screw_yz()) translate([CAB_X1 + 1, q[0], q[1]]) rotate([0, -90, 0]) cylinder(d = 3, h = 15, $fn = 20);   // pilots for the actuator-pad screws, in the end face
}
module upper_front(raise = 0) difference() {                                                               // FIXED panel: base plate (face contact) down to UFRONT_ZB; raise only for the C30 control
    xz_panel(CAB_X0, DR_Y0, UFRONT_ZB, CAB_T) p_ufront_2d(raise);
    for (p = uf_top_xy()) translate([p[0], p[1], CAB_ZT - UF_PILOT_DEPTH]) cylinder(d = UF_PILOT_D, h = UF_PILOT_DEPTH + 1, $fn = 20);   // pilots for the top screws, in the top edge
}
module upper_front_screws_ph() {                                                                           // 8 x M4 x 45 pan head (placeholder, visual only)
    for (p = uf_top_xy()) translate([p[0], p[1], BASE_Z1]) {                                               // head on top of the base plate, shank down through it into the pilot
        cylinder(d = 7, h = 3, $fn = 24);
        translate([0, 0, -(BASE_T + UF_PILOT_DEPTH - 1)]) cylinder(d = 4, h = BASE_T + UF_PILOT_DEPTH - 1, $fn = 20);
    }
    for (p = uf_face_xz()) translate([p[0], CAB_Y0 - 3, p[1]]) rotate([-90, 0, 0]) { cylinder(d = 7, h = 3, $fn = 24); translate([0, 0, 3]) cylinder(d = 4, h = CAB_T + UF_PILOT_DEPTH - 1, $fn = 20); }
}
DR_X0 = CAB_XC - DR_W / 2;  DR_X1 = CAB_XC + DR_W / 2;
module drawer_bin() {
    xy_panel(DR_X0, DR_Y0, DR_Z0, DR_T) p_dbottom_2d();                                                // bottom
    yz_panel(DR_X0, DR_Y0, DR_Z0 + DR_T, DR_T) p_dside_2d();                                           // sides
    yz_panel(DR_X1 - DR_T, DR_Y0, DR_Z0 + DR_T, DR_T) p_dside_2d();
    xz_panel(DR_X0 + DR_T, DR_Y0 + DR_L, DR_Z0 + DR_T, DR_T) p_dback_2d();                             // back
}
module drawer_panels() { drawer_front(); drawer_bin(); }

// ---------------- drawer pull handle (printed, PETG): an edge pull, back plate + shelf + lip; fingers go in from below.
// Local frame (u = distance in front of the drawer front, v = z - HANDLE_Z, w = along the width, 0 .. HANDLE_W)
HANDLE_SHELF_T = 8;  HANDLE_LIP_T = 6;  HANDLE_LIP_H = 18;
module handle_local() {
    ht = HANDLE_H / 2;  d1 = HANDLE_BACK_T + HANDLE_LIP_D;
    difference() {
        linear_extrude(HANDLE_W) {
            translate([0, -ht]) square([HANDLE_BACK_T, HANDLE_H]);                                     // back plate
            translate([0, ht - HANDLE_SHELF_T]) square([d1, HANDLE_SHELF_T]);                           // shelf
            translate([d1 - HANDLE_LIP_T, ht - HANDLE_LIP_H]) square([HANDLE_LIP_T, HANDLE_LIP_H]);     // lip
        }
        for (p = handle_screw_xz()) translate([-0.01, 0, CAB_XC + HANDLE_W / 2 - p[0]]) rotate([0, 90, 0])   // M4 heat-set inserts from the back face
            cylinder(d = INSERT_D, h = INSERT_DEPTH + 0.01, $fn = 32);
    }
}
// u -> -y (away from the cabinet), v -> z, w -> -x (a proper rotation)
module handle_world() multmatrix([[0, 0, -1, CAB_XC + HANDLE_W / 2], [-1, 0, 0, CAB_Y0], [0, 1, 0, HANDLE_Z], [0, 0, 0, 1]]) handle_local();
module handle_screws_ph() for (p = handle_screw_xz())  // 2 x M4 x 22 from inside the bin (head against the back of the drawer front)
    translate([p[0], DR_Y0 + 3, p[1]]) rotate([90, 0, 0]) {
        cylinder(d = 7, h = 3, $fn = 24);
        translate([0, 0, 3]) cylinder(d = 4, h = 22, $fn = 20);                // 22 under the head: 18 panel + 4 of the 6 mm insert
    }

// ---------------- drawer interlock: real switch (interlock.scad, approximate envelope) on the PAD on the free-end side panel, coded actuator on the
// PAD on the end face of the drawer front.  Switch frame S (a, b, c) -> world: a -> +x, b -> +y (head end face at the front), c -> +z.
SW_X0 = CAB_X1 + SW_PAD_T;                                     // switch mounting face = pad outer face
SW_Y0 = CAB_Y0 + 2 + ACT_L - INTERLOCK_IN;                     // head end face of the switch = slot mouth (-70): the actuator's tail then lies 2 mm behind the drawer front's outer face
SW_YC = SW_Y0 + SW_L / 2;
module sw_world() translate([SW_X0, SW_Y0, DRAWER_SW_Z]) children();
DPAD_B = [for (s = [-1, 1]) SW_L / 2 + s * 35];                // the 2 x M5 wood screws that hold the switch pad on the side panel (b positions)
function sw_pad_screw_yz() = [for (b = DPAD_B) [SW_Y0 + b, DRAWER_SW_Z]];                         // world (y, z)
APAD_B = [INTERLOCK_IN - ACT_L - 2, INTERLOCK_IN - ACT_BL + 3];                               // actuator pad extent along b: -40 .. -5 (world y -110 .. -75)
APAD_BR = DR_Y0 - SW_Y0;                                       // b of the side panels' front edge (-22): beyond it the pad overhangs the panel face, 1 mm clear
APAD_SCREW_B = CAB_Y0 + CAB_T / 2 - SW_Y0;                     // the 2 x M4 wood screws into the drawer-front end face: middle of its 18 mm thickness (b = -17)
function act_pad_screw_yz() = [for (c = [-8, 8]) [SW_Y0 + APAD_SCREW_B, DRAWER_SW_Z + c]];        // world (y, z)
assert(INTERLOCK_IN >= 10 && INTERLOCK_IN < IL_SW_SLOT[2] && INTERLOCK_IN <= INTERLOCK_OUT_TRAVEL);
assert(SW_Y0 + APAD_B[1] < SW_Y0 - 1);                         // the actuator pad ends >= 1 mm in front of the switch head end face
assert(abs(SW_Y0 + APAD_B[0] - CAB_Y0) < 1e-9);                // ... and starts flush with the drawer front's outer face
// the interlock pads must lie on the SHORT drawer front (z = CAB_ZB .. DRF_ZT) / on the side panel next to it, above the floor, under the handle, clear of the grid cleat screw heads
SW_LOW_GRID_Z = CAB_ZB + min([for (h = grid_side_holes()) h[1]]);                                  // lowest grid screw on the side panel's outer face
assert(DRAWER_SW_Z + SW_PAD_W / 2 <= DRF_ZT - 2 && DRAWER_SW_Z - SW_PAD_W / 2 >= CAB_FLOOR_TOP, "interlock pads must lie within the drawer front's height, above the floor");
assert(DRAWER_SW_Z + SW_PAD_W / 2 <= SW_LOW_GRID_Z - GRID_SCREW[2] / 2 - 2, "the switch pad must clear the grid cleat screw heads on the side panel");
assert(DRAWER_SW_Z + SW_PAD_W / 2 <= HANDLE_Z - HANDLE_H / 2 - 2 || DRAWER_SW_Z - SW_PAD_W / 2 >= HANDLE_Z + HANDLE_H / 2 + 2, "interlock pads clear (in z) of the handle");
assert(HANDLE_Z + HANDLE_H / 2 <= DRF_ZT - 5 && HANDLE_Z - HANDLE_H / 2 >= CAB_ZB + 5, "the pull handle must lie fully on the drawer front");
// the fixed panel's face-screw pilots (u 0 .. UF_PILOT_DEPTH in the side panels) clear of the grid screw holes, the hang pilots and the switch pad's pilots
assert(min([for (h = grid_side_holes(), z = UF_FACE_Z) abs(h[1] - (z - CAB_ZB))]) >= 10, "fixed-panel face screws clear of the grid cleat screw holes");
assert(UF_FACE_Z[0] <= CAB_ZT - HANG_PILOT_DEPTH - 10, "fixed-panel face screws clear of the hang pilots");
assert(min([for (q = sw_pad_screw_yz()) q[0] - DR_Y0]) >= UF_PILOT_DEPTH + 5, "fixed-panel face screws clear of the switch pad pilots");

module drawer_pad() sw_world() difference() {                  // printed switch pad on the free-end side panel: 10 x 92 x 32 (a, b, c)
    translate([-SW_PAD_T, (SW_L - SW_PAD_L) / 2, -SW_PAD_W / 2]) cube([SW_PAD_T, SW_PAD_L, SW_PAD_W]);
    sw_pad_pilots();                                                                              // 2 x Ø3.3 pilots for the switch's M4 screws, 22 apart
    for (b = DPAD_B) translate([0.01, b, 0]) rotate([0, -90, 0]) {                                // 2 x M5 wood screws into the panel (blind)
        cylinder(d = 5.5, h = SW_PAD_T + 0.02, $fn = 24);
        cylinder(d = 10, h = 4, $fn = 24);
    }
}
module drawer_act_pad() sw_world() difference() {              // printed actuator pad on the end face of the drawer front: 19 thick, flat face, no tongue
    union() {
        translate([-SW_PAD_T, APAD_B[0], -SW_PAD_W / 2]) cube([SW_PAD_T + A_OFF, APAD_BR - APAD_B[0] + 0.01, SW_PAD_W]);                  // on the drawer front's end face
        translate([-SW_PAD_T + 1, APAD_BR, -SW_PAD_W / 2]) cube([SW_PAD_T - 1 + A_OFF, APAD_B[1] - APAD_BR, SW_PAD_W]);                   // overhang past the front edge of the side panel (1 mm clear)
    }
    act_in_sw() act_pad_pilots();                                                                 // 2 x Ø3.3 pilots, ACT_HOLE_SPACING apart
    for (c = [-8, 8]) translate([A_OFF + 0.01, APAD_SCREW_B, c]) rotate([0, -90, 0]) {            // 2 x M4 wood screws into the drawer-front end face
        cylinder(d = 4.5, h = SW_PAD_T + A_OFF + 0.02, $fn = 20);
        cylinder(d = 8.5, h = 4, $fn = 24);
    }
}
module drawer_switch_ph() sw_world() sw_ph();                                                     // the safety switch (placeholder), slot cut
module drawer_switch_env() sw_world() sw_body_env();                                              // body without the slot
module drawer_switch_slot() sw_world() sw_slot();
module drawer_switch_screws_ph() sw_world() sw_screws_ph();
// the moving side: travel > 0 = drawer pulled out by that much (-y)
module drawer_act_pad_moved(travel = 0) translate([0, -travel, 0]) drawer_act_pad();
module drawer_actuator(travel = 0) translate([0, -travel, 0]) sw_world() act_in_sw() act_ph();   // the coded actuator (placeholder)
module drawer_actuator_screws_ph(travel = 0) translate([0, -travel, 0]) sw_world() act_in_sw() act_screws_ph();
module drawer_blade(travel = 0) translate([0, -travel, 0]) sw_world() blade_env();               // the blade only: the part that enters the head
module drawer_interlock_ph(travel = 0) { drawer_pad(); drawer_switch_ph(); drawer_act_pad_moved(travel); drawer_actuator(travel); }

module cabinet() { cabinet_panels(); drawer_panels(); handle_world(); drawer_interlock_ph(); grid_mesh(); grid_cleats(0); grid_cleats(1); grid_screws_ph(); upper_front_screws_ph(); }

// ---------------- the fixed safety grid
module grid_wires_2d() {                                                   // plan of the mesh: the wires (2 mm) at GRID_PITCH; the holes of this shape are the cells
    for (x = grid_xs()) translate([x - GRID_WIRE / 2, GRID_Y0]) square([GRID_WIRE, GRID_LY]);
    for (y = grid_ys()) translate([GRID_X0, y - GRID_WIRE / 2]) square([GRID_LX, GRID_WIRE]);
}
module grid_sheet_2d() translate([GRID_X0, GRID_Y0]) square([GRID_LX, GRID_LY]);       // the cut sheet's outline
module grid_mesh() {                                                       // round wire Ø2: the wires along x on top (top surface = GRID_Z), those along y under them, welded at the crossings
    for (x = grid_xs()) translate([x, GRID_Y0, GRID_Z - GRID_WIRE / 2 - GRID_LAYER]) rotate([-90, 0, 0]) cylinder(d = GRID_WIRE, h = GRID_LY, $fn = 16);
    for (y = grid_ys()) translate([GRID_X0, y, GRID_Z - GRID_WIRE / 2]) rotate([0, 90, 0]) cylinder(d = GRID_WIRE, h = GRID_LX, $fn = 16);
}
module dir_z(d) {                                                          // local +z -> the axis direction d (one of +x, -x, -y)
    if (d[0] == 1) rotate([0, 90, 0]) children();
    else if (d[0] == -1) rotate([0, -90, 0]) children();
    else rotate([90, 0, 0]) children();
}
module grid_cleats(level = 0, g = 0)                                       // level 0: lower set (top face under the mesh), 1: upper set (bottom face on the mesh); g > 0: every box shrunk by g per face (touching-face checks)
    difference() {
        for (b = grid_cleat_boxes()) translate([b[0] + g, b[1] + g, (level == 0 ? GRID_ZL : GRID_Z) + g]) cube([b[2] - b[0] - 2 * g, b[3] - b[1] - 2 * g, GRID_CLEAT - 2 * g]);
        for (s = grid_screws(level)) translate(s[0] - 0.01 * s[1]) dir_z(s[1]) cylinder(d = GRID_SCREW[4], h = GRID_PD + 0.01, $fn = 16);       // Ø3 pilots
    }
module grid_screws_ph() for (lv = [0, 1], s = grid_screws(lv)) translate(s[0] - CAB_T * s[1]) dir_z(s[1]) {                                // M4 x 35 pan head, head on the outside
    translate([0, 0, -GRID_SCREW[3]]) cylinder(d = GRID_SCREW[2], h = GRID_SCREW[3], $fn = 16);
    cylinder(d = GRID_SCREW[0], h = CAB_T + GRID_PD - 1, $fn = 12);
}
module grid_screw_shanks() for (lv = [0, 1], s = grid_screws(lv)) translate(s[0] - (CAB_T + 1) * s[1]) dir_z(s[1]) cylinder(d = GRID_SCREW[4] - 0.2, h = CAB_T + GRID_PD - 1, $fn = 12);   // C16: thread core through the plywood hole and the cleat pilot
module cleat_strip_2d(len, holes) difference() {
    square([len, GRID_CLEAT]);
    for (h = holes) translate([h, GRID_CLEAT / 2]) circle(d = GRID_SCREW[4], $fn = 24);
}
GRID_SIDE_LEN = GRID_IY1 - GRID_FY - 2 * GRID_CLEAT;                                          // the side cleats run between the front rail and the back cleat: 143
module grid_cleats_2d() for (lv = [0, 1]) translate([0, lv * 4 * (GRID_CLEAT + 10)]) {      // the 8 strips (4 lower, 4 upper), elevation seen from the wall side, with the Ø3 face pilots; the rails also have 2 end-grain pilots per end
    cleat_strip_2d(GRID_WX, []);                                                             // front rail
    translate([0, GRID_CLEAT + 10]) cleat_strip_2d(GRID_WX, [for (x = [CAB_XC - 50, CAB_XC, CAB_XC + 50]) x - GRID_IX0]);                   // back cleat
    for (i = [0, 1]) translate([0, (2 + i) * (GRID_CLEAT + 10)]) cleat_strip_2d(GRID_SIDE_LEN, [for (y = [-48, 0, 48]) y - (GRID_FY + GRID_CLEAT)]);   // side cleats
}
// check helpers (checks.scad sees modules only)
function grid_box() = [[GRID_X0, GRID_Y0, GRID_ZB], [GRID_LX, GRID_LY, GRID_T]];
function grid_cleat_box(level) = [[GRID_IX0, GRID_FY, level == 0 ? GRID_ZL : GRID_Z], [GRID_WX, GRID_IY1 - GRID_FY, GRID_CLEAT]];
module grid_set(g = 0.01) { grid_mesh(); grid_cleats(0, g); grid_cleats(1, g); }            // mesh + both cleat sets (cleats shrunk by g: they touch the walls)
module grid_reach(h) translate([GRID_IX0, GRID_IY0, GRID_Z]) cube([GRID_WX, GRID_WY, h]);      // the volume over the cabinet from the mesh top up to h above it
module grid_probes(d, reach)                                                                // finger probes of Ø d, one in the middle of every cell, pushed up from far below to `reach` above the mesh top
    for (i = [0 : GRID_NX - 2], j = [0 : GRID_NY - 2])
        translate([(grid_xs()[i] + grid_xs()[i + 1]) / 2, (grid_ys()[j] + grid_ys()[j + 1]) / 2, GRID_ZL - 100]) cylinder(d = d, h = GRID_Z + reach - (GRID_ZL - 100), $fn = 32);
module grid_edge_free(sh = 0) difference() {                                                // the free space between the cut sheet and the walls (a 40 mm window round the mesh); sh: control, sheet smaller by sh per side
    translate([GRID_IX0, GRID_IY0, GRID_Z - 20]) cube([GRID_WX, GRID_WY, 40]);
    translate([GRID_X0 + sh, GRID_Y0 + sh, GRID_Z - 21]) cube([GRID_LX - 2 * sh, GRID_LY - 2 * sh, 42]);
}
module grid_free_2d() difference() { grid_inside_2d(); grid_wires_2d(); }                  // the plan of the cabinet minus the wires: the openings (cells + the thin edge gaps)
module grid_inside_2d() translate([GRID_IX0, GRID_IY0]) square([GRID_WX, GRID_WY]);       // the inside of the cabinet in plan
module grid_cleat_plan_2d() for (b = grid_cleat_boxes()) translate([b[0], b[1]]) square([b[2] - b[0], b[3] - b[1]]);
module drawer_moved_ph(t) translate([0, -t, 0]) { drawer_panels(); handle_world(); handle_screws_ph(); }     // the drawer (front, bin, handle) pulled out by t

// ---------------- panel outlines, laid out on a sheet (mm).  Every outline is the SAME module the 3D part extrudes.
module cabinet_2d() {
    sz = CAB_H;  sy = CAB_SIDE_W;
    p_side_2d();                                                                          // side x2
    translate([sy + 10, 0]) p_side_2d();
    translate([0, sz + 10]) p_back_2d();                                                  // back
    translate([2 * sy + 20, 0]) p_floor_2d();                                             // floor
    translate([2 * sy + 20, sy + 10]) p_front_2d();                                       // drawer front (short): only the 2 x Ø4.5 handle screw holes
    translate([2 * sy + 20, sy + 10 + DRF_H + 10]) p_ufront_2d();                         // FIXED upper front panel: 4 x Ø4.5 face-screw holes (the top-edge pilots are drilled from the base plate)
    translate([0, 2 * sz + 20]) p_dbottom_2d();                                           // drawer bottom
    for (i = [0, 1]) translate([DR_W + 10 + i * (DR_L + 10), 2 * sz + 20]) p_dside_2d();   // drawer sides
    translate([DR_W + 10 + 2 * (DR_L + 10), 2 * sz + 20]) p_dback_2d();                    // drawer back
}

// ---------------- check helpers (checks.scad only sees modules, not variables)
module cab_shell_free(test_hole_d = 0, utest_hole_d = 0) difference() {   // free space inside the 18 mm shell of the cabinet (sides, back, floor, fixed upper front, drawer front), drawer closed
    translate([CAB_X0, CAB_Y0, CAB_ZB]) cube([CAB_W, CAB_Y1 - CAB_Y0, CAB_H]);
    translate([CAB_X0 + CAB_T, DR_Y0, CAB_ZB + CAB_T]) cube([CAB_W - 2 * CAB_T, CAB_Y1 - CAB_T - DR_Y0, CAB_H - CAB_T + 1]);   // the inside (open to the base plate above)
    cabinet_shell_panels();
    upper_front_with_hole(utest_hole_d);
    drawer_front(test_hole_d);
}
module upper_front_with_hole(d) difference() {                    // upper_front(), plus (only for a C9 control) a Ø d hole through its middle
    upper_front();
    if (d > 0) translate([CAB_XC, CAB_Y0 - 1, (UFRONT_ZB + CAB_ZT) / 2]) rotate([-90, 0, 0]) cylinder(d = d, h = CAB_T + 2, $fn = 32);
}
module cab_shell_free_nodrawer(raise = 0) difference() {          // C30: the same shell with the drawer (front AND bin) REMOVED; raise: control, the fixed panel's bottom edge raised by that much (>= UFRONT_H: panel absent)
    translate([CAB_X0, CAB_Y0, CAB_ZB]) cube([CAB_W, CAB_Y1 - CAB_Y0, CAB_H]);
    translate([CAB_X0 + CAB_T, DR_Y0, CAB_ZB + CAB_T]) cube([CAB_W - 2 * CAB_T, CAB_Y1 - CAB_T - DR_Y0, CAB_H - CAB_T + 1]);
    cabinet_shell_panels();
    if (raise < UFRONT_H) upper_front(raise);
}
module above_mesh_slab() translate([CAB_X0 - 10, CAB_Y0 - 10, GRID_ZL]) cube([CAB_W + 20, CAB_Y1 - CAB_Y0 + 20, CAB_ZT - GRID_ZL + 10]);   // everything from the underside of the lower cleats (below the mesh) up to the base
module below_grid_slab() translate([CAB_X0 - 10, CAB_Y0 - 10, CAB_ZB - 10]) cube([CAB_W + 20, CAB_Y1 - CAB_Y0 + 20, GRID_ZL - CAB_ZB + 10]);       // everything under the lower cleats
function grid_zl() = GRID_ZL;  function uf_zb() = UFRONT_ZB;  function uf_zt() = CAB_ZT;  function drf_zt() = DRF_ZT;  function bin_top() = DR_Z0 + DR_H;  function uf_gap() = UFRONT_GAP;
module uf_top_shanks() for (p = uf_top_xy()) translate([p[0], p[1], CAB_ZT - UF_PILOT_DEPTH + 1]) cylinder(d = UF_PILOT_D - 0.2, h = UF_PILOT_DEPTH + BASE_T + 2, $fn = 16);       // C16: M4 core: base Ø5 + panel pilot Ø3.3
module uf_face_shanks() for (p = uf_face_xz()) translate([p[0], CAB_Y0 - 2, p[1]]) rotate([-90, 0, 0]) cylinder(d = UF_PILOT_D - 0.2, h = CAB_T + UF_PILOT_DEPTH + 1, $fn = 16);   // C16: panel Ø4.5 + side-panel pilot Ø3.3
module rail_slot_free(shift = 0) difference() {                    // C30b: the air between the fixed panel's back face and the front rail, over the height of the grid; shift: control, grid set moved back by that much
    translate([GRID_IX0, DR_Y0, GRID_ZL]) cube([GRID_WX, GRID_FY + GRID_CLEAT - DR_Y0, GRID_Z + GRID_CLEAT - GRID_ZL]);
    translate([0, shift, 0]) grid_set(0);
}
function ufront_box() = [[CAB_X0, CAB_Y0, UFRONT_ZB], [CAB_W, CAB_T, UFRONT_H]];
// joint alignment shanks (checks.scad C16): one shank per bolt, through the hole of part 1 and the hole of part 2
module foot_screw_shanks() for (p = foot_screw_xy()) translate([p[0], p[1], BASE_Z0 - 3]) cylinder(d = 4.9, h = BASE_T + 14, $fn = 20);   // M6 core: base slot 6.6 + plate hole Ø5 x 12 deep (ends 11 mm up the hole)
module hang_shanks() for (p = hang_screw_xy()) translate([p[0], p[1], CAB_ZT - HANG_PILOT_DEPTH + 1]) cylinder(d = HANG_PILOT_D - 0.2, h = HANG_PILOT_DEPTH + BASE_T + 2, $fn = 16);   // M4 core: base Ø5 + panel pilot Ø3.3
module handle_shanks() for (p = handle_screw_xz()) translate([p[0], DR_Y0 + 2, p[1]]) rotate([90, 0, 0]) cylinder(d = 4, h = CAB_T + 2 + 5, $fn = 20);   // M4: front Ø4.5 + handle insert Ø5.6 (6 deep)
function drawer_pad_box() = [[CAB_X1, SW_Y0 + (SW_L - SW_PAD_L) / 2, DRAWER_SW_Z - SW_PAD_W / 2], [SW_PAD_T, SW_PAD_L, SW_PAD_W]];
function drawer_act_pad_box() = [[CAB_X1, CAB_Y0, DRAWER_SW_Z - SW_PAD_W / 2], [SW_PAD_T + A_OFF, APAD_B[1] - APAD_B[0], SW_PAD_W]];
module drawer_sw_shanks() sw_world() sw_shanks();                                                // switch M4 screws: body Ø4.5 + pad pilots
module drawer_pad_shanks() for (q = sw_pad_screw_yz()) translate([SW_X0 + 1, q[0], q[1]]) rotate([0, -90, 0]) cylinder(d = 3.8, h = SW_PAD_T + 13, $fn = 20);   // M5 core: pad Ø5.5 + panel pilot Ø4 (14 deep, shank 1 short of the bottom)
module drawer_act_shanks(travel = 0) translate([0, -travel, 0]) sw_world() act_in_sw() act_shanks();    // actuator M4 screws: block Ø4.5 + pad pilots
module drawer_act_pad_shanks() for (q = act_pad_screw_yz()) translate([SW_X0 + A_OFF + 1, q[0], q[1]]) rotate([0, -90, 0]) cylinder(d = 2.8, h = SW_PAD_T + A_OFF + 13, $fn = 20);   // M4 core: pad Ø4.5 + end-face pilot Ø3 (14 deep)
module sw_slot_from(depth) intersection() {                      // the part of the switch slot deeper than `depth` from the mouth
    drawer_switch_slot();
    translate([SW_X0 - 1, SW_Y0 + depth, DRAWER_SW_Z - 50]) cube([40, 50, 100]);
}
function base_box() = [[BASE_X0, BASE_Y0, BASE_Z0], [BASE_X1 - BASE_X0, BASE_Y1 - BASE_Y0, BASE_T]];
module hole_probe_ph(d, len = 300) children();                   // (reserved)

// ---------------- print poses (flat face down)
module drawer_handle_print() multmatrix([[0, 0, -1, HANDLE_W], [0, 1, 0, HANDLE_H / 2], [1, 0, 0, 0], [0, 0, 0, 1]]) handle_local();   // back face down, shelf up
module drawer_pad_print()      // panel face down, holes open upward
    multmatrix([[0, 1, 0, -(SW_YC - SW_PAD_L / 2)], [0, 0, 1, -(DRAWER_SW_Z - SW_PAD_W / 2)], [1, 0, 0, -CAB_X1], [0, 0, 0, 1]]) drawer_pad();
module drawer_act_pad_print()  // face against the drawer front down, the actuator face (pilots) up
    multmatrix([[0, 1, 0, -CAB_Y0], [0, 0, 1, -(DRAWER_SW_Z - SW_PAD_W / 2)], [1, 0, 0, -CAB_X1], [0, 0, 0, 1]]) drawer_act_pad();

part = "world";
if (part == "base_plate") base_plate();
else if (part == "base_2d") base_2d();
else if (part == "cabinet_2d") cabinet_2d();
else if (part == "grid_mesh") grid_mesh();
else if (part == "grid_cleats") { grid_cleats(0); grid_cleats(1); }
else if (part == "grid_mesh_2d") grid_wires_2d();
else if (part == "grid_cleats_2d") grid_cleats_2d();
else if (part == "cabinet") { cabinet_panels(); drawer_panels(); }
else if (part == "upper_front") upper_front();
else if (part == "drawer_handle") drawer_handle_print();
else if (part == "drawer_pad") drawer_pad_print();
else if (part == "drawer_act_pad") drawer_act_pad_print();
else if (part == "bom") {
    echo(str("BOM base plate: 18 mm plywood ", BASE_X1 - BASE_X0, " x ", BASE_Y1 - BASE_Y0, " (x ", BASE_X0, " .. ", BASE_X1, ", y ", BASE_Y0, " .. ", BASE_Y1, "); 6 x M4 x 45 hang screws (Ø5 holes, Ø", HANG_PILOT_D, " x ", HANG_PILOT_DEPTH, " pilots in the cabinet side panels)"));
    echo(str("BOM fixed upper front panel: 18 mm plywood ", CAB_W, " x ", UFRONT_H, " (z ", UFRONT_ZB, " .. ", CAB_ZT, ", y ", CAB_Y0, " .. ", DR_Y0, "), screwed on: ", len(uf_top_xy()), " x M4 x 45 from the top of the base plate (Ø5 holes in the base, Ø", UF_PILOT_D, " x ", UF_PILOT_DEPTH, " pilots in the panel's top edge) + ", len(uf_face_xz()), " x M4 x 45 through its face (Ø", HANDLE_HOLE_D, " holes) into the side panels' front edges (Ø", UF_PILOT_D, " x ", UF_PILOT_DEPTH, " pilots); the drawer front is ", DRF_H, " high (z ", CAB_ZB, " .. ", DRF_ZT, ", ", UFRONT_GAP, " mm under it)"));
    echo(str("BOM drawer: pull handle (printed), M4 x 22 screws 2 + heat-set inserts M4 2 (handle); switch pad 10 x 92 x 32 printed (2 x M5 x 25 wood screws into the side panel, 2 x Ø", PILOT_D, " pilots for the switch's M4 screws); actuator pad 19 x 35 x 32 printed (2 x M4 x 35 wood screws into the drawer-front end face, 2 x Ø", PILOT_D, " pilots for the actuator's M4 screws)"));
    echo(str("BOM drawer interlock: 1 x Omron D4NS-2AF plain safety switch (positive-opening NC contacts) + 1 x Omron D4DS-K2 key (both Amazon). *** APPROXIMATE envelopes - verify with Omron's drawing before drilling: *** switch body about ", SW_W, " x ", SW_L, " (about 75 body + head, slot in the head end face) x ", SW_D, " deep, 2 x M4 holes about ", DSW_HOLE_SPACING, " apart; key about ", ACT_L, " x ", ACT_W, " x ", ACT_H, ", 2 x M4 holes about ", DACT_HOLE_SPACING, " apart; key ", INTERLOCK_IN, " mm in the head when the drawer is closed, out after ", INTERLOCK_IN, " mm of travel (spec <= ", INTERLOCK_OUT_TRAVEL, ")"));
    echo(str("BOM drawer bin: plywood sides ", DR_L, " x ", DR_H - DR_T, ", back ", DR_W - 2 * DR_T, " x ", DR_H - DR_T, ", bottom ", DR_W, " x ", DR_L, " (10 mm): the bin is ", DR_H, " high (it was 250) so that its top (z = ", DR_Z0 + DR_H, ") slides in under the lower grid cleats (z = ", GRID_ZL, ")"));
    echo(str("BOM safety grid: 1 sheet of 1\" x 1\" welded wire mesh, 14 ga (", GRID_WIRE, " mm wire), galvanized (pitch ", GRID_PITCH, ", clear opening ", GRID_PITCH - GRID_WIRE, "), CUT to ", GRID_LX, " x ", GRID_LY, " = ", GRID_NX, " wires along y + ", GRID_NY, " wires along x (gap to the walls ", GRID_GX, " in x, ", GRID_GY, " in y); top surface z = ", GRID_Z, " = ", -R_TIP - GRID_Z, " mm below the lowest blade tip (z = ", -R_TIP, "), >= ", GRID_MIN_DIST, " required (ISO 13857 Table 4, openings 20 < e <= 30).  Timber cleats ", GRID_CLEAT, " x ", GRID_CLEAT, ": lower set under the mesh (top z = ", GRID_ZB, ") and upper set on top (bottom z = ", GRID_Z, "): 2 x ", GRID_WX, " front rails (the front 'wall' is the sliding drawer front: the rail spans the cabinet, ", GRID_FCLR, " mm clear of it), 2 x ", GRID_WX, " back, 4 x ", GRID_SIDE_LEN, " sides; ", len(grid_screws(0)) + len(grid_screws(1)), " x M4 x 35 wood screws from OUTSIDE through Ø", GRID_SCREW[1], " holes in the plywood (", len(grid_side_holes()) / 2, " per side panel, ", len(grid_back_holes()), " in the back) into Ø", GRID_SCREW[4], " x ", GRID_PD, " pilots"));
}
else if (part == "world") { base_plate(); cabinet(); }
