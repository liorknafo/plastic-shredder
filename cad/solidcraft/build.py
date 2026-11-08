#!/usr/bin/env python3
"""build.py -- step 2: write the SolidCraft script (build/shredder_solidcraft.json, copied next to this file) and run it -> cad/shredder_assembly.sc.

Run export_parts.py first (the Makefile target `solidcraft` does both).  Everything is derived from the current design:
  build/*.3mf (one per component), build/axes.json (shaft axes, lid hinge, gearbox output axis, worm / motor axes).

Joint sign conventions = cad/assembly.scad: Shaft A turns -angle about +x, Shaft B +angle (so a positive "Shaft A" value is the assembly's `angle`);
lid: positive = opens (hinge_rot(a) rotates by -a about +x); drawer: positive = pulled out (travel along -y).
"""
import json, os, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
sys.path.insert(0, HERE)
import manifest
from export_parts import comp_file

CLI = os.environ.get("SOLIDCRAFT_CLI", "/Applications/SolidCraft.app/Contents/MacOS/solidcraft-cli")
OUT_SC = os.path.join(CAD, "shredder_assembly.sc")

ax = json.load(open(os.path.join(BUILD, "axes.json")))
XM_, XL = -1, 1                                   # direction helpers

# ---- design numbers (mm, deg) read from the design via axes.json, plus the ones the task fixes
LID_MAX = 100.0                                   # deg, see README: the free range checked with motion.interference
DRAWER_MAX = 180.0                                # mm
CHAIN = 30 / 15                                   # TL sprocket 30T drives sprocket A 15T
WORM = 50.0                                       # worm turns per output turn
BELT = 2.0                                        # motor pulley turns per gearbox-pulley turn (68 / 34)
A_T, TL_T = 15, 30                                # tooth counts (the chain link's "radii": a chain's ratio is the teeth, not the pitch circles)
PUL_G, PUL_M = ax["gearbox_pulley_d"], ax["motor_pulley_d"]
assert abs(ax["chain_ratio"] - CHAIN) < 1e-9 and abs(PUL_G / PUL_M - BELT) < 1e-9

cmds = []
def add(command, **params):
    cmds.append({"command": command, "params": params})

# ---- components
for comp, _ in manifest.COMPONENTS:
    add("file.insert_mesh", path=os.path.relpath(comp_file(comp), BUILD), name=comp)
occ = lambda comp: comp + ":1"
add("occurrence.ground", occurrence=occ("Frame"), grounded=True)

# ---- opacity of the see-through bodies (the 3MF colour keeps the colour, not the alpha)
for comp, bodies in manifest.COMPONENTS:
    for b in bodies:
        if b[3] < 1:
            add("appearance.assign", bodies=[b[0]], color=b[2], opacity=b[3])

def origin(point, z, x):
    return {"point": point, "z": z, "x": x}

def joint(jtype, name, a, b, at, limits=None):
    p = dict(type=jtype, name=name, a=occ(a), b=occ(b), at=at)
    if limits:
        p["limits"] = limits
    add("joint.as_built", **p)

yA, yB = ax["shaft_y_A"], ax["shaft_y_B"]
# Shaft A turns -angle about +x  =>  joint axis -x, so that +value = the assembly's angle; B turns +angle about +x.
joint("revolute", "Shaft A", "Frame", "Rotor A", origin([0, yA, 0], [-1, 0, 0], [0, 1, 0]))
joint("revolute", "Shaft B", "Frame", "Rotor B", origin([0, yB, 0], [1, 0, 0], [0, 1, 0]))
joint("revolute", "Output shaft", "Frame", "Torque limiter + output shaft", origin([0, ax["out_y"], ax["out_z"]], [-1, 0, 0], [0, 1, 0]))
joint("revolute", "Worm", "Frame", "Worm + gearbox pulley", origin([ax["worm_x"], ax["worm_y0"], ax["worm_z"]], [0, -1, 0], [1, 0, 0]))
joint("revolute", "Motor", "Frame", "Motor shaft + pulley", origin([ax["motor_x"], ax["worm_y0"], ax["motor_z"]], [0, -1, 0], [1, 0, 0]))
joint("revolute", "Lid hinge", "Frame", "Lid", origin([ax["lid_x_mid"], ax["lid_pin_y"], ax["lid_pin_z"]], [-1, 0, 0], [0, 1, 0]), [[0, LID_MAX]])
joint("slider", "Drawer slide", "Frame", "Drawer", origin([ax["lid_x_mid"], -92, -250], [0, -1, 0], [1, 0, 0]), [[0, DRAWER_MAX]])

# ---- links.  A link is one-way (driver a -> driven b: the driven joint can no longer be driven by hand), so they all start at Shaft A, the one joint to drag:
#      Shaft A -> Shaft B (gear), Shaft A -> Output shaft (chain), Output shaft -> Worm (worm gear), Worm -> Motor (belt).
#      internal: true = both turn the same way in joint-value terms (A's axis is -x, B's +x, so equal values = counter-rotation in the world).
add("joint.gear", a="Shaft A", b="Shaft B", ra=ax["gear_z"], rb=ax["gear_z"], internal=True, name="Gear A-B")           # m1.5 z40 / z40 (made gears, cad/gear.scad), 1:1
add("joint.gear", a="Shaft A", b="Output shaft", ra=A_T, rb=TL_T, internal=True, name="Chain 2:1")           # sprocket A 15T <- TL 30T: A turns 2x the TL, same direction
add("joint.motion_link", a="Output shaft", b="Worm", ratio=WORM)                                                       # worm 50:1: the worm turns 50x the output shaft
add("joint.gear", a="Worm", b="Motor", ra=PUL_G / 2, rb=PUL_M / 2, internal=True, name="Belt 2:1")                     # belt: motor pulley (34) turns 2x the gearbox pulley (68), same direction

# ---- motion studies
add("motion.study", name="Shafts one turn", steps=120, keys=[{"joint": "Shaft A", "points": [[0, 0], [120, 360]]}])
add("motion.study", name="Drawer out", steps=90, keys=[{"joint": "Drawer slide", "points": [[0, 0], [90, DRAWER_MAX]]}])
add("motion.study", name="Lid open", steps=100, keys=[{"joint": "Lid hinge", "points": [[0, 0], [100, LID_MAX]]}])

script = os.path.join(BUILD, "shredder_solidcraft.json")
json.dump(cmds, open(script, "w"), indent=1)
shutil.copy(script, os.path.join(HERE, "shredder_solidcraft.json"))

if "--no-run" not in sys.argv:
    r = subprocess.run([CLI, "run", script, "--results", "--save", OUT_SC], cwd=BUILD, capture_output=True, text=True)
    open(os.path.join(BUILD, "run.log"), "w").write(r.stdout + r.stderr)
    if r.returncode != 0:
        sys.exit(f"solidcraft-cli failed ({r.returncode}); see build/run.log\n{r.stderr[-2000:]}")
    print("wrote", os.path.relpath(OUT_SC, CAD))
