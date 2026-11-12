#!/usr/bin/env python3
"""build.py -- builds the native SolidCraft assembly cad/shredder_assembly.sc from design/params.py.

Every body is native SolidCraft geometry made by the model modules (model/*.py: the parts, one module per part
family); nothing is imported as a mesh.

    python3 build.py            write build/shredder_assembly.json (the command script), run it with solidcraft-cli,
                                save cad/shredder_assembly.sc and compare every group of bodies with reference.json
    python3 build.py --no-run   only write the script
    python3 build.py --out F    save the design as F instead (a trial build)
    python3 build.py --cache    keep the evaluated model in the file: it then opens in 2 s instead of 40 s, and is
                                26 MB instead of 0.4 MB (SolidCraft adds the cache by itself when you save from the app)
    python3 build.py --check    exit with an error when a group does not match reference.json
    python3 build.py --freeze   make what was built the new reference.json (after a deliberate change of the design)

reference.json holds each group of the old OpenSCAD mesh assembly, measured: the comparison is the proof that the
native model is the same machine.  It stays valid until a parameter changes; then freeze the new numbers.

Needs SolidCraft 0.40 (`solidcraft-cli` on PATH, or SOLIDCRAFT_CLI).  Standard library only.

Joint sign conventions: Shaft A turns -angle about +x, Shaft B +angle (so a positive "Shaft A" value is the assembly's
`angle`); lid: positive = opens; drawer: positive = pulled out (travel along -y).
"""
import json
import os
import subprocess
import sys
import time

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
sys.path[:0] = [HERE, os.path.join(HERE, "model")]
from scq import Script                       # noqa: E402
from check import CLI, compare, freeze, reference    # noqa: E402
import assembly                              # noqa: E402
import common as c                           # noqa: E402
import drive_geom as g                       # noqa: E402

OUT_SC = os.path.join(CAD, "shredder_assembly.sc")
LID_MAX = 100.0                              # deg: the free range of the lid
DRAWER_MAX = 180.0                           # mm
WORM_RATIO = 50.0                            # worm turns per output turn
A_T, TL_T = 15, 30                           # tooth counts: a chain's ratio is the teeth, not the pitch circles
assert abs(c.CHAIN_RATIO - TL_T / A_T) < 1e-9 and abs(c.GEARBOX_PULLEY_D / c.MOTOR_PULLEY_D - 2.0) < 1e-9


def main():
    out_sc = os.path.abspath(sys.argv[sys.argv.index("--out") + 1]) if "--out" in sys.argv else OUT_SC
    s = Script(folders=True)                 # one timeline folder per body
    names = {}                               # group -> its bodies
    comps = [comp for comp, _ in assembly.COMPONENTS]

    # ---- components and their bodies
    for comp, bodies in assembly.COMPONENTS:
        s.step("component.create", name=comp, parent="root", activate=True)
        for b in bodies:
            names[b.name] = s.build(b.node(), b.name, color=b.color, opacity=b.opacity)
        s.step("component.activate", component="root")
    n_model = len(s.steps)

    def occ(comp):
        return comp + ":1"

    def joint(jtype, name, b, point, z, x, limits=None):
        if "Frame" not in comps or b not in comps:
            print(f"  (joint {name!r} left out: component missing)")
            return False
        p = dict(type=jtype, name=name, a=occ("Frame"), b=occ(b), at={"point": point, "z": z, "x": x})
        if limits:
            p["limits"] = limits
        s.step("joint.as_built", **p)
        return True

    if "Frame" in comps:
        s.step("occurrence.ground", occurrence=occ("Frame"), grounded=True)

    # ---- joints.  Shaft A turns -angle about +x  =>  joint axis -x, so that +value = the assembly's angle.
    xc = c.chamber_L / 2
    ja = joint("revolute", "Shaft A", "Rotor A", [0, c.shaft_y("A"), 0], [-1, 0, 0], [0, 1, 0])
    jb = joint("revolute", "Shaft B", "Rotor B", [0, c.shaft_y("B"), 0], [1, 0, 0], [0, 1, 0])
    jo = joint("revolute", "Output shaft", "Torque limiter + output shaft", [0, g.YA, g.ZO], [-1, 0, 0], [0, 1, 0])
    jw = joint("revolute", "Worm", "Worm + gearbox pulley", [g.XG, g.GB_Y0, g.ZW], [0, -1, 0], [1, 0, 0])
    jm = joint("revolute", "Motor", "Motor shaft + pulley", [g.XM, g.GB_Y0, g.ZM], [0, -1, 0], [1, 0, 0])
    if "Lid" in comps:
        import hopper
        joint("revolute", "Lid hinge", "Lid", [xc, hopper.PIN_Y, hopper.PIN_Z], [-1, 0, 0], [0, 1, 0], [[0, LID_MAX]])
    joint("slider", "Drawer slide", "Drawer", [xc, -92, -250], [0, -1, 0], [1, 0, 0], [[0, DRAWER_MAX]])

    # ---- links.  A link is one-way (driver a -> driven b), so they all start at Shaft A, the one joint to drag:
    #      Shaft A -> Shaft B (gear), Shaft A -> Output shaft (chain), Output shaft -> Worm (worm gear), Worm -> Motor (belt).
    #      internal: true = both turn the same way in joint-value terms (A's axis is -x, B's +x, so equal values =
    #      counter-rotation in the world).
    if ja and jb:
        s.step("joint.gear", a="Shaft A", b="Shaft B", ra=c.GEAR_z, rb=c.GEAR_z, internal=True, name="Gear A-B")
    if ja and jo:
        s.step("joint.gear", a="Shaft A", b="Output shaft", ra=A_T, rb=TL_T, internal=True, name="Chain 2:1")
    if jo and jw:
        s.step("joint.motion_link", a="Output shaft", b="Worm", ratio=WORM_RATIO)
    if jw and jm:
        s.step("joint.gear", a="Worm", b="Motor", ra=c.GEARBOX_PULLEY_D / 2, rb=c.MOTOR_PULLEY_D / 2, internal=True, name="Belt 2:1")

    # ---- motion studies
    if ja:
        s.step("motion.study", name="Shafts one turn", steps=120, keys=[{"joint": "Shaft A", "points": [[0, 0], [120, 360]]}])
    if "Drawer" in comps:
        s.step("motion.study", name="Drawer out", steps=90, keys=[{"joint": "Drawer slide", "points": [[0, 0], [90, DRAWER_MAX]]}])
    if "Lid" in comps:
        s.step("motion.study", name="Lid open", steps=100, keys=[{"joint": "Lid hinge", "points": [[0, 0], [100, LID_MAX]]}])
    s.step("document.metadata.set", values={
        "project": "plastic-shredder",
        "description": "Twin-shaft shredder for 3D-print waste: native SolidCraft assembly built from design/params.py"})

    s.step("file.save_as", path=out_sc, cache="--cache" in sys.argv)
    os.makedirs(BUILD, exist_ok=True)
    script = os.path.join(BUILD, "shredder_assembly.json")
    json.dump(s.steps, open(script, "w"))
    json.dump(names, open(os.path.join(BUILD, "groups.json"), "w"), indent=1)
    n_bodies = sum(len(v) for v in names.values())
    print(f"{len(comps)} components, {len(names)} groups, {n_bodies} bodies; {n_model} modelling steps, "
          f"{len(s.steps) - n_model - 1} assembly steps -> {os.path.relpath(script, HERE)}")
    if "--no-run" in sys.argv:
        return

    t0 = time.time()
    r = subprocess.run([CLI, "run", script, "--quiet"], cwd=BUILD, capture_output=True, text=True)
    open(os.path.join(BUILD, "run.log"), "w").write(r.stdout + r.stderr)
    if r.returncode != 0:
        sys.exit(f"solidcraft-cli failed ({r.returncode}); see build/run.log\n{r.stderr[-2000:]}")
    print(f"wrote {os.path.relpath(out_sc, CAD)} in {time.time() - t0:.0f} s")

    # ---- the saved design against the old mesh assembly, group by group
    out = os.path.join(BUILD, "eval.json")
    r = subprocess.run([CLI, "eval", out_sc, "--json-out", out], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"solidcraft-cli eval failed ({r.returncode})\n{r.stderr[-2000:]}")
    got = {b["name"]: b for b in json.load(open(out))["bodies"]}
    if "--freeze" in sys.argv:
        freeze(os.path.join(HERE, "reference.json"), "bodies", list(names), names, got,
               "Each group of bodies of cad/shredder_assembly.sc as build.py --freeze measured it (solidcraft-cli eval): "
               "total volume, bounding box, centre of mass.  build.py and check.py compare what they build with these numbers.")
        return
    bad = compare(list(names), names, got, reference())
    print(f"{len(names)} groups, {len(got)} bodies; {bad} differ from reference.json")
    sys.exit(1 if bad and "--check" in sys.argv else 0)


if __name__ == "__main__":
    main()
