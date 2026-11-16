"""gear.py -- the BOUGHT spur gear (module 4, z = 15, 20 deg, hardened teeth) as modelled: involute teeth, the bore
re-bored Ø25 with the broached 8 mm keyway, and its hub (cad/gear.scad).  All 2D profiles are in the gear's own (u, v)
plane, tooth 0 centred on +u.

BACKLASH.  A bought gear's teeth are made a little thin (tooth-thickness tolerance); the model represents that as a cut
`extra` (GEAR_cut_extra = 0.10 mm) deeper than standard on BOTH gears: a rack-shaped cutter moved radially in by
`extra` is a profile shift x = -extra / m, so each tooth is thinner at the pitch circle by 2 * extra * tan(alpha) =
0.0728 mm; two such gears in mesh have 0.1456 mm of circumferential backlash.  Below the base circle the flank is a
radial line down to the root circle.
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
    """Bore Ø25 (+ clearance `bd_extra`) with the broached 8 mm keyway on +v, 3.3 above the bore surface
    (corner R = GEAR_KEY_TOOL_D / 2, nearly sharp)."""
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
    """The teeth, gear_face thick, axis = +w (local frame, w = 0 at the face toward the hub)."""
    return linear_extrude(gear_face if L is None else L, gear_2d(extra, phase, bd_extra))


def gear_hub_solid(bd_extra=0, L=None):
    """The hub (bought; APPROXIMATE size until the listing is chosen): GEAR_HUB_D x GEAR_HUB_L, the same bore + keyway."""
    return linear_extrude(GEAR_HUB_L if L is None else L, difference(circle(d=GEAR_HUB_D), bore_keyway_2d(bd_extra)))


def gear_part(phase=0):
    """The whole bought gear in its own frame: hub w = 0 .. GEAR_HUB_L, teeth w = GEAR_HUB_L .. GEAR_HUB_L + gear_face
    (on the machine the hub is OUTBOARD)."""
    return union(gear_hub_solid(), translate([0, 0, GEAR_HUB_L], gear_solid(GEAR_cut_extra, phase)))


PARTS = {"gear_A": lambda: gear_part(),                                                       # a tooth centred on the keyway
         "gear_B": lambda: gear_part(180 / GEAR_z if int(GEAR_z) % 2 == 0 else 0)}           # the same part for an odd tooth count

PARTS_2D = {"gear_profile": gear_2d}           # the bought gear as modelled (teeth + the re-bored Ø25 + broached keyway), for reference
