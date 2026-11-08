// common.scad -- shared include for every part file: parameters, blade profile, layout helpers.
// World frame: x along the shafts (x = 0 inner face of the drive-end plate), y across (A at -C/2, B at +C/2), z up.
include <params.scad>
include <blade_profile.scad>

FN = 96;                       // facets for round features (each module sets $fn = FN itself)
N_BLADES = N_SLOTS / 2;        // blades per shaft (= spacers per shaft)

// ---- local frame (u, v, w) -> world:  x = x0 + w,  y = u,  z = v   (a proper rotation)
// Used for everything that is "an axial part": w runs along the shaft, (u, v) = (y, z) across it.
module axial(x0 = 0)
    multmatrix([[0, 0, 1, x0], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) children();

// ---- layout of the cutting stacks
function shaft_y(sh)     = sh == "A" ? -C / 2 : C / 2;
function shaft_sign(sh)  = sh == "A" ? -1 : 1;                       // rotation direction about +x
function stack_x0(sh)    = END_CLEAR + (sh == "A" ? 0 : end_spacer_B); // x of the first blade
function blade_pitch()   = T_BLADE + T_SPACER;
function blade_x0(sh, k) = stack_x0(sh) + k * blade_pitch();         // blade k: x in [x0, x0 + T_BLADE]
function blade_xc(sh, k) = blade_x0(sh, k) + T_BLADE / 2;
function blade_variant(k) = k % BLADE_VARIANTS;
// rotation of blade k in its own 2D frame: j*60 - v*STAGGER, j = -floor(k/4)   (deg)
function blade_rot(k)    = -floor(k / BLADE_VARIANTS) * 60 - blade_variant(k) * STAGGER_DEG;
function sleeve_free_x0(sh) = END_CLEAR + (sh == "A" ? stack_A : stack_B);
function sleeve_free_L(sh)  = sh == "A" ? sleeve_L_free_A : sleeve_L_free_B;
function shaft_x_start(sh)  = sh == "A" ? shaft_end_A_drive : shaft_end_B_drive;
// y span of a comb bar: [lo, hi] (B on +y, A mirrored)
function comb_y_lo(sh) = sh == "B" ? comb_edge_y : -(comb_edge_y + COMB_W);
function comb_y_hi(sh) = sh == "B" ? comb_edge_y + COMB_W : -comb_edge_y;
