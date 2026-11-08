#!/usr/bin/env python3
"""interference.py -- body-by-body overlap check of the three motion studies, with OpenSCAD booleans (manifold) on the exported meshes.

Why: SolidCraft's own motion.interference refuses mesh bodies ("contact sweep does not support mesh bodies"), and every body of this
assembly is an imported mesh.  This script does the same job on the same meshes at the same poses as the studies saved in the design:
  Shafts one turn : Shaft A 0 -> 360 deg in 3 deg steps (B, output shaft, worm, motor follow through the links)
  Drawer out      : 0 -> 180 mm in 2 mm steps
  Lid open        : 0 -> 100 deg in 1 deg steps
For every pose it intersects each moving body with every body of another component whose bounding box touches it, and reports for each
pair the largest overlap volume and the smallest side of the overlap's bounding box (an upper bound of the penetration depth) over the study,
next to the same pair's value at the rest pose (a pair that overlaps at rest is a designed face contact / seat / mesh faceting).

usage: interference.py [--study a|b|c|all] [--step-scale K] [--jobs N]     -> build/interference.json, build/interference.md
"""
import argparse, json, math, os, struct, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
sys.path.insert(0, HERE)
import manifest
from export_parts import stl_path

AX = json.load(open(os.path.join(BUILD, "axes.json")))
ENV = dict(os.environ, OPENSCADPATH=CAD)
EPS_VOL = 1e-3           # mm3: below this an overlap is not reported


# ---------------------------------------------------------------- meshes
def load_stl(p):
    d = open(p, "rb").read()
    n = struct.unpack_from("<I", d, 80)[0]
    pts = set()
    for i in range(n):
        v = struct.unpack_from("<9f", d, 84 + 50 * i + 12)
        pts.add(v[0:3]); pts.add(v[3:6]); pts.add(v[6:9])
    return list(pts)


def stl_volume_bbox(p):
    d = open(p, "rb").read()
    n = struct.unpack_from("<I", d, 80)[0]
    vol, area, lo, hi = 0.0, 0.0, [1e9] * 3, [-1e9] * 3
    for i in range(n):
        f = struct.unpack_from("<12f", d, 84 + 50 * i)
        a, b, c = f[3:6], f[6:9], f[9:12]
        u = (b[0] - a[0], b[1] - a[1], b[2] - a[2]); w = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
        area += 0.5 * math.sqrt((u[1] * w[2] - u[2] * w[1]) ** 2 + (u[2] * w[0] - u[0] * w[2]) ** 2 + (u[0] * w[1] - u[1] * w[0]) ** 2)
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
        for q in (a, b, c):
            for k in range(3):
                lo[k] = min(lo[k], q[k]); hi[k] = max(hi[k], q[k])
    return vol, lo, hi, n, area


# ---------------------------------------------------------------- poses (column-vector 4x4, world)
def rot_about(point, axis, deg):
    """rotation by deg (right-hand) about the line through `point` along unit `axis`"""
    t = math.radians(deg); c, s = math.cos(t), math.sin(t)
    x, y, z = axis
    R = [[c + x * x * (1 - c), x * y * (1 - c) - z * s, x * z * (1 - c) + y * s],
         [y * x * (1 - c) + z * s, c + y * y * (1 - c), y * z * (1 - c) - x * s],
         [z * x * (1 - c) - y * s, z * y * (1 - c) + x * s, c + z * z * (1 - c)]]
    p = point
    tr = [p[i] - sum(R[i][j] * p[j] for j in range(3)) for i in range(3)]
    return [R[0] + [tr[0]], R[1] + [tr[1]], R[2] + [tr[2]], [0, 0, 0, 1]]


IDENT = rot_about((0, 0, 0), (1, 0, 0), 0)


def translate(v):
    return [[1, 0, 0, v[0]], [0, 1, 0, v[1]], [0, 0, 1, v[2]], [0, 0, 0, 1]]


def study_a(a):      # Shaft A joint value a (axis -x): A -a about +x, B +a, TL -a/2 (chain 2:1), worm 50x the TL, motor 2x the worm; worm / motor axes -y
    tl = a / 2
    return {
        "Rotor A": rot_about((0, AX["shaft_y_A"], 0), (1, 0, 0), -a),
        "Rotor B": rot_about((0, AX["shaft_y_B"], 0), (1, 0, 0), +a),
        "Torque limiter + output shaft": rot_about((0, AX["out_y"], AX["out_z"]), (1, 0, 0), -tl),
        "Worm + gearbox pulley": rot_about((AX["worm_x"], 0, AX["worm_z"]), (0, 1, 0), -50 * tl),
        "Motor shaft + pulley": rot_about((AX["motor_x"], 0, AX["motor_z"]), (0, 1, 0), -100 * tl),
    }


def study_b(t):
    return {"Drawer": translate((0, -t, 0))}


def study_c(a):      # hinge_rot(a): rotate([-a, 0, 0]) about the pin axis
    return {"Lid": rot_about((0, AX["lid_pin_y"], AX["lid_pin_z"]), (1, 0, 0), -a)}


STUDIES = {
    "a": ("Shafts one turn", study_a, [3.0 * i for i in range(121)], "deg"),
    "b": ("Drawer out", study_b, [2.0 * i for i in range(91)], "mm"),
    "c": ("Lid open", study_c, [1.0 * i for i in range(101)], "deg"),
}


def apply(M, p):
    return (M[0][0] * p[0] + M[0][1] * p[1] + M[0][2] * p[2] + M[0][3],
            M[1][0] * p[0] + M[1][1] * p[1] + M[1][2] * p[2] + M[1][3],
            M[2][0] * p[0] + M[2][1] * p[1] + M[2][2] * p[2] + M[2][3])


def bbox(pts, M=None):
    lo, hi = [1e9] * 3, [-1e9] * 3
    for p in pts:
        q = apply(M, p) if M else p
        for k in range(3):
            lo[k] = min(lo[k], q[k]); hi[k] = max(hi[k], q[k])
    return lo, hi


def overlap_box(b1, b2, margin=0.3):
    return all(b1[0][k] - margin <= b2[1][k] and b2[0][k] - margin <= b1[1][k] for k in range(3))


# ---------------------------------------------------------------- one pair at one pose
SCAD = """
ma = []; mb = [];
module a() multmatrix(ma) import(fa, convexity = 10);
module b() multmatrix(mb) import(fb, convexity = 10);
fa = ""; fb = "";
intersection() { a(); b(); }
"""
_scad_path = None


def scad_file():
    global _scad_path
    if _scad_path is None:
        fd, _scad_path = tempfile.mkstemp(suffix=".scad", prefix="sc_interf_")
        os.write(fd, SCAD.encode()); os.close(fd)
    return _scad_path


def mm(M):
    return "[" + ",".join("[" + ",".join(repr(float(x)) for x in row) + "]" for row in M) + "]"


def overlap(fa, Ma, fb, Mb):
    """-> None (no overlap) | (volume mm3, min side of the overlap bbox, bbox lo, bbox hi)"""
    fd, out = tempfile.mkstemp(suffix=".stl", prefix="sc_interf_"); os.close(fd)
    os.unlink(out)
    cmd = ["openscad", "--backend=manifold", "--export-format", "binstl", "-D", f"ma={mm(Ma)}", "-D", f"mb={mm(Mb)}",
           "-D", f'fa="{fa}"', "-D", f'fb="{fb}"', "-o", out, scad_file()]
    r = subprocess.run(cmd, env=ENV, capture_output=True, text=True)
    if not os.path.exists(out):
        if "empty" in (r.stderr + r.stdout).lower():
            return None
        raise RuntimeError(r.stderr[-800:])
    try:
        vol, lo, hi, n, area = stl_volume_bbox(out)
    finally:
        os.unlink(out)
    if n == 0 or abs(vol) < EPS_VOL:
        return None
    return (vol, min(hi[k] - lo[k] for k in range(3)), lo, hi, 2 * abs(vol) / area if area else 0.0)


# ---------------------------------------------------------------- the check
def all_bodies():
    out = []
    for comp, bodies in manifest.COMPONENTS:
        for b in bodies:
            sh = b[4] if len(b) > 4 else None
            out.append((comp, b[0], stl_path(b[1], sh)))
    return out


def run_study(key, jobs, scale):
    title, posef, values, unit = STUDIES[key]
    values = values[::scale] if scale > 1 else values
    if values[-1] != STUDIES[key][2][-1]:
        values = values + [STUDIES[key][2][-1]]
    bodies = all_bodies()
    pts = {p: load_stl(p) for _, _, p in bodies}
    rest_box = {p: bbox(pts[p]) for _, _, p in bodies}
    movers_names = list(posef(values[0]).keys())
    print(f"== {title}: {len(values)} poses, moving: {movers_names}", flush=True)

    tasks = []                                   # (value index, mover body, other body, matrices)
    for vi, v in enumerate(values):
        poses = posef(v)
        boxes = {}
        for comp, name, p in bodies:
            M = poses.get(comp)
            boxes[(comp, name)] = bbox(pts[p], M) if M else rest_box[p]
        for comp, name, p in bodies:
            if comp not in poses:
                continue
            for comp2, name2, p2 in bodies:
                if comp2 == comp or (comp2 in poses and comp2 < comp):          # each moving-moving pair once
                    continue
                if overlap_box(boxes[(comp, name)], boxes[(comp2, name2)]):
                    tasks.append((vi, v, (comp, name, p), (comp2, name2, p2), poses.get(comp, IDENT), poses.get(comp2, IDENT)))
    print(f"   {len(tasks)} pair checks", flush=True)

    def work(t):
        vi, v, A, B, Ma, Mb = t
        return t, overlap(A[2], Ma, B[2], Mb)

    pairs = {}
    with ThreadPoolExecutor(jobs) as ex:
        for k, (t, res) in enumerate(ex.map(work, tasks)):
            vi, v, A, B, _, _ = t
            if k % 500 == 0:
                print(f"   {k}/{len(tasks)}", flush=True)
            e = pairs.setdefault((A[0], A[1], B[0], B[1]), {"max_vol": 0.0, "min_side_at_max": None, "worst_value": None, "values": [], "rest": None, "bbox": None})
            if res:
                e["values"].append(v)
                if res[0] > e["max_vol"]:
                    e["max_vol"], e["min_side_at_max"], e["worst_value"], e["sliver"] = res[0], res[1], v, res[4]
                    e["bbox"] = [[round(x, 2) for x in res[2]], [round(x, 2) for x in res[3]]]
                e["max_side"] = max(e.get("max_side", 0.0), res[1])
                if vi == 0:
                    e["rest"] = res[0]
    rows = []
    for (c1, b1, c2, b2), e in pairs.items():
        if e["max_vol"] > 0:
            rows.append(dict(a=f"{c1} / {b1}", b=f"{c2} / {b2}", unit=unit, rest_volume_mm3=e["rest"], max_volume_mm3=round(e["max_vol"], 4),
                             min_side_mm_at_max=round(e["min_side_at_max"], 4), sliver_thickness_mm=round(e["sliver"], 4), max_of_min_side_mm=round(e.get("max_side", 0), 4),
                             worst_value=e["worst_value"], n_poses=len(e["values"]), of=len(values), bbox=e["bbox"]))
    rows.sort(key=lambda r: -r["max_volume_mm3"])
    return dict(study=title, unit=unit, poses=len(values), checks=len(tasks), overlaps=rows)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--study", default="all")
    ap.add_argument("--step-scale", type=int, default=1, help="use every K-th pose (quick look)")
    ap.add_argument("--fine", action="store_true", help="study a only: 1 deg steps, rotors only (blade / spacer clearance between the shafts)")
    ap.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 4) - 1))
    a = ap.parse_args()
    keys = ["a", "b", "c"] if a.study == "all" else [a.study]
    if a.fine:
        keys = ["a"]
        STUDIES["a"] = ("Shafts one turn, rotors only, 1 deg", lambda v: {k: m for k, m in study_a(v).items() if k.startswith("Rotor")}, [float(i) for i in range(361)], "deg")
    res = [run_study(k, a.jobs, a.step_scale) for k in keys]
    tag = "_fine" if a.fine else ""
    json.dump(res, open(os.path.join(BUILD, f"interference{tag}.json"), "w"), indent=1)
    with open(os.path.join(BUILD, f"interference{tag}.md"), "w") as f:
        for r in res:
            f.write(f"## {r['study']}  ({r['poses']} poses, {r['checks']} pair checks)\n\n")
            if not r["overlaps"]:
                f.write("no overlaps\n\n"); continue
            f.write("| moving body | other body | at rest mm3 | max mm3 | overlap box min side (mm) | 2V/area thickness (mm) | at | poses |\n|---|---|---|---|---|---|---|---|\n")
            for o in r["overlaps"]:
                f.write(f"| {o['a']} | {o['b']} | {o['rest_volume_mm3'] if o['rest_volume_mm3'] is not None else '-'} | {o['max_volume_mm3']} | {o['min_side_mm_at_max']} | {o['sliver_thickness_mm']} | {o['worst_value']} {o['unit']} | {o['n_poses']}/{o['of']} |\n")
            f.write("\n")
    print(open(os.path.join(BUILD, f"interference{tag}.md")).read())


if __name__ == "__main__":
    main()
