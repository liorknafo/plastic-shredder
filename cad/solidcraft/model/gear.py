"""gear.py -- the MADE spur gear (module 1.5, z = 40, 20 deg): involute teeth, backlash, bore Ø25 and the 8 mm keyway (cad/gear.scad).

Also one rough LAYER (the CNC part) and the gear mandrel (lathe part).  All 2D profiles are in the gear's own (u, v)
plane, tooth 0 centred on +u.

BACKLASH.  The gear is cut with a form cutter `extra` (GEAR_cut_extra = 0.10 mm) deeper than standard on BOTH gears.
A rack-shaped cutter moved radially in by `extra` is a profile shift x = -extra / m, so each tooth gets thinner at
the pitch circle by 2 * extra * tan(alpha) = 0.0728 mm (transverse); the base circle, the involute flanks and the
tip circle (OD 63.0, turned on the lathe) stay as they are.  Below the base circle (r 28.19 > root r 28.025) the
flank is a radial line down to the root circle.
Each flank is NF points, base circle .. tip circle (inscribed in the convex tooth: never bigger than the real tooth).
"""
from common import *

NF = 10                                            # points per flank, base circle .. tip circle


def inv_deg(a):
    return tan(a) - a * PI / 180                   # involute function (radians), angle a in degrees


def g_rp(m, z):
    return m * z / 2


def g_rb(m, z, alpha):
    return g_rp(m, z) * cos(alpha)


def g_ra(m, z):
    return m * (z + 2) / 2


def g_rr(m, z, extra):
    return m * (z - 2.5) / 2 - extra


def g_s(m, alpha, extra):
    return PI * m / 2 - 2 * extra * tan(alpha)     # tooth thickness on the pitch circle (transverse)


def g_half(m, z, alpha, extra, r):
    """Half angle (deg) of the tooth at radius r."""
    return (g_s(m, alpha, extra) / (2 * g_rp(m, z)) + inv_deg(alpha) - inv_deg(acos(g_rb(m, z, alpha) / r))) * 180 / PI


def pol(r, a):
    return [r * cos(a), r * sin(a)]


def gear_pts(m=None, z=None, alpha=None, extra=None, phase=0):
    """Outline of the whole gear (tooth 0 centred on +u, rotated by `phase` deg)."""
    m = GEAR_module if m is None else m
    z = int(GEAR_z if z is None else z)
    alpha = GEAR_alpha if alpha is None else alpha
    extra = GEAR_cut_extra if extra is None else extra
    rb, ra, rr = g_rb(m, z, alpha), g_ra(m, z), g_rr(m, z, extra)
    r0, pitch = max(rb, rr), 360 / z
    hb = g_half(m, z, alpha, extra, r0 + 1e-9)
    rs = [r0 + (ra - r0) * i / NF for i in range(NF + 1)]

    def half(r):
        return g_half(m, z, alpha, extra, r0 + 1e-9 if r < r0 + 1e-6 else r)

    pts = []
    for k in range(z):
        c = phase + k * pitch
        pts.append(pol(rr, c - hb))
        pts += [pol(r, c - half(r)) for r in rs]
        pts.append(pol(ra, c))
        pts += [pol(rs[i], c + half(rs[i])) for i in range(NF, -1, -1)]
        pts += [pol(rr, c + hb), pol(rr, c + pitch / 2)]
    return pts


def gear_outline(extra=None, phase=0):
    return polygon(gear_pts(GEAR_module, GEAR_z, GEAR_alpha, extra, phase))


def bore_keyway_2d(bd_extra=0):
    """Bore Ø25 (+ clearance `bd_extra`) with the 8 mm keyway on +v, 3.3 above the bore surface.

    The keyway is cut by the Ø3 end mill: its far corners have R = GEAR_KEY_TOOL_D / 2.
    """
    rt = GEAR_KEY_TOOL_D / 2
    return union(
        circle(d=GEAR_bore + bd_extra),
        # slot: from inside the bore to GEAR_bore/2 + GEAR_KEYWAY_H; only its far corners are rounded
        hull(translate([-GEAR_KEY_W / 2, 0], square([GEAR_KEY_W, 1])),
             [translate([sx * (GEAR_KEY_W / 2 - rt), GEAR_bore / 2 + GEAR_KEYWAY_H - rt], circle(r=rt)) for sx in (-1, 1)]))


def gear_2d(extra=None, phase=0, bd_extra=0):
    """The finished gear (one flat 2D shape): teeth + bore + keyway."""
    return difference(gear_outline(extra, phase), bore_keyway_2d(bd_extra))


def gear_solid(extra=None, phase=0, bd_extra=0, L=None):
    """The finished gear, GEAR_LAYERS layers = gear_face thick, axis = +w (w = 0 at the face toward the shaft end)."""
    return linear_extrude(gear_face if L is None else L, gear_2d(extra, phase, bd_extra))


def gear_layer_2d():
    """ONE rough layer as the CNC cuts it: Ø64 outline, bore Ø25 H7, keyway 8 JS9."""
    return difference(circle(d=GEAR_ROUGH_D), bore_keyway_2d(0))


def gear_layer():
    return linear_extrude(GEAR_LAYER_T, gear_layer_2d())


# gear mandrel (lathe, from the Ø30 bar): grip Ø30 x grip_L, Ø25 g6 seat (4 layers + 2.8) with the 8 mm key keyway,
# M16 x 1.5 stud, centre drilled.  Axis +w; w = 0 at the grip end.
G_GRIP_L = 45
G_SEAT_L = gear_face + 2.8
G_THR_L = 24


def gear_mandrel():
    return difference(
        union(cylinder(d=30, h=G_GRIP_L),
              translate([0, 0, G_GRIP_L], cylinder(d=25, h=G_SEAT_L)),
              translate([0, 0, G_GRIP_L + G_SEAT_L], cylinder(d=16, h=G_THR_L))),
        # keyway 8 x 4 (on +v), closed at both ends, 40 long, starts 1 mm past the shoulder
        translate([-4, 25 / 2 - 4, G_GRIP_L + 1], cube([8, 5, 40])),
        translate([0, 0, G_GRIP_L + G_SEAT_L + G_THR_L - 4], cylinder(d1=0, d2=5, h=4.01)))   # centre hole


PARTS = {"gear_A": lambda: gear_solid(),                                # a tooth centred on the keyway
         "gear_B": lambda: gear_solid(GEAR_cut_extra, 180 / GEAR_z),    # a gap centred on the keyway (same blank, cut half a pitch later)
         "gear_layer": gear_layer,
         "gear_mandrel": gear_mandrel}

PARTS_2D = {"gear_layer": gear_layer_2d,      # ONE layer for the CNC: rough Ø64 outline + bore Ø25 + keyway 8 (R1.5 corners); 8 of them
            "gear_profile": gear_2d}           # the finished gear (teeth + bore + keyway), for reference / checking the cut gear
