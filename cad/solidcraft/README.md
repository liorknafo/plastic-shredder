# SolidCraft assembly with joints

`make solidcraft` (not part of `make all`) rebuilds `cad/shredder_assembly.sc` from the current OpenSCAD design, then
`open -a SolidCraft cad/shredder_assembly.sc`.  Needs `openscad` (manifold backend) and SolidCraft 0.30 (`/Applications/SolidCraft.app`, or set `SOLIDCRAFT_CLI`).

| file | job |
|---|---|
| `parts.scad` | wrapper: calls the modules `cad/assembly.scad` calls, one body at a time (`-D sel=...`), at angle 0, lid closed, drawer closed |
| `manifest.py` | components, their coloured bodies (colours / opacities of assembly.scad) |
| `axes.scad` | echoes the joint geometry (shaft axes, lid pin, gearbox output axis, worm / motor axes, tooth counts, pulley sizes) |
| `export_parts.py` | OpenSCAD -> `build/stl/*.stl` -> one coloured 3MF per component (`build/*.3mf`) + `build/axes.json` |
| `build.py` | writes `shredder_solidcraft.json` (SolidCraft script: components, ground, joints, links, limits, studies) and runs it with `solidcraft-cli` |
| `interference.py` | body-by-body overlap check of the three studies (see below) |

`build/` is generated (git-ignored).  Nothing in `design/` or the existing `cad/*.scad` is touched.

## What is in the file

Components: **Frame** (grounded, 35 coloured bodies), **Rotor A**, **Rotor B**, **Lid**, **Drawer**, **Torque limiter + output shaft**,
**Worm + gearbox pulley**, **Motor shaft + pulley**.

| joint | type | axis | positive value | limits |
|---|---|---|---|---|
| Shaft A | revolute | x through (y = -30, z = 0), joint axis -x | = `angle` of assembly.scad (A turns -angle about +x) | none |
| Shaft B | revolute | x through (y = +30, z = 0), joint axis +x | B turns +angle about +x | none |
| Output shaft | revolute | x through (y = -30, z = -150) (gearbox output axis), joint axis -x | same direction as A | none |
| Worm | revolute | y through (x = -155.8, z = -213), joint axis -y | | none |
| Motor | revolute | y through (x = -405.8, z = -213), joint axis -y | | none |
| Lid hinge | revolute | x through (y = 103, z = 298) (the M5 hinge pin), joint axis -x | opens the lid (front edge up) | 0 .. 100 deg |
| Drawer slide | slider | -y | pulled out toward the user | 0 .. 180 mm |

Links (a -> b; a link makes b follow a, so the **one joint to drive is Shaft A**; Shaft B, Output shaft, Worm and Motor follow):

* **Gear A-B**: Shaft A -> Shaft B, 1:1, B counter-rotating (made gears m1.5 z40 / z40, real involute teeth with backlash)
* **Chain 2:1**: Shaft A -> Output shaft, A turns 2x the TL (15T sprocket on A, 30T on the TL350), same direction
* worm 50:1 (motion link): Output shaft -> Worm, the worm turns 50x the output shaft
* **Belt 2:1**: Worm -> Motor, the motor pulley (34) turns 2x the gearbox pulley (68), same direction

(SolidCraft does not name links; they show in the joint list by their two joints.)  The worm / motor turning direction is a free choice (the design models the worm and
both pulleys as plain cylinders, with no thread hand): only the speed ratios are meaningful.

Motion studies saved in the design: **Shafts one turn** (Shaft A 0 -> 360 deg, 120 steps; B, TL, worm, motor follow), **Drawer out** (0 -> 180 mm, 90 steps),
**Lid open** (0 -> 100 deg, 100 steps).

## Interference

SolidCraft's `motion.interference` / `joint.sweep` refuse mesh bodies ("contact sweep does not support mesh bodies") and every body here is an imported mesh
(OpenSCAD cannot write STEP).  `interference.py` therefore repeats the check with OpenSCAD booleans on the same meshes at the same poses (3 deg / 2 mm / 1 deg steps; poses
computed from the joint axes and cross-checked against SolidCraft's own occurrence transforms): for every pose, every moving body against every body of another component whose
bounding box touches it.  It prints the largest overlap volume per pair, and the same pair at rest: an overlap that is already there at rest and
does not grow is a designed contact (placeholder discs touching, a shaft placeholder through a housing placeholder, mesh faceting).  Results: `build/interference.md`.
