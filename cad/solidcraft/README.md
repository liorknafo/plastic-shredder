# The SolidCraft model

`cad/shredder_assembly.sc` is the machine as a native SolidCraft design: 8 components, 382 bodies (one per part),
7 joints, 4 motion links and 3 motion studies. Nothing in it is an imported mesh. It is built from
`design/params.py` by the scripts in this folder, with SolidCraft 0.40 (`solidcraft-cli` on `PATH`, or set
`SOLIDCRAFT_CLI`). Python 3, standard library only.

```sh
make solidcraft     # cad/shredder_assembly.sc
make parts          # cad/step, cad/stl, cad/dxf
make interference   # build/interference.md
make pictures       # cad/png/solidcraft_*.png
make verify         # assembly and parts against the old OpenSCAD model
solidcraft cad/shredder_assembly.sc
```

The file is saved without SolidCraft's model cache: 0.4 MB, and it rebuilds for about 40 s when it opens.
`python3 build.py --cache` keeps the cache (26 MB, opens in 2 s); saving from the app adds it too.

## Files

| file | job |
|---|---|
| `model/*.py` | the parts, one module per part family (see below) |
| `scq.py` | the modelling layer the modules are written in: `cube`, `cylinder`, `linear_extrude`, `hull`, `translate`, `difference` ..., compiled to SolidCraft features (boxes, cylinders, sketch extrudes with true circles and arcs, lofts, cut / join) |
| `build.py` | the assembly: components, bodies, colours, ground, joints, links, limits, motion studies -> `cad/shredder_assembly.sc` |
| `parts.py` | every made part in its own part frame -> `cad/step`, `cad/stl`, `cad/dxf` |
| `check.py` | builds chosen groups of bodies (`check.py Blades`, `check.py -m hopper`) and compares them with `reference.json` |
| `interference.py` | SolidCraft's interference check of the saved assembly |
| `snapshots.py` | `cad/png/solidcraft_*.png` (iso at rest, rotors 60 deg, drawer 180 mm, lid 100 deg, sections) |
| `reference.json`, `parts_reference.json` | each group of the old OpenSCAD mesh assembly and each old STL part, measured (volume, bounding box, centre of mass) |

`build/` is generated (git-ignored): the command scripts SolidCraft runs, measurements, `interference.md`.

### The model modules

Each module is the translation of the OpenSCAD file of the same name, function for function, in the same frames
(`cad/blade.scad` -> `model/blade.py`, and so on). A function returns a tree; `part("name", ...)` marks one
physical part, which becomes one body. A module lists

- `BODIES`: its groups of bodies in the assembly (`frame.py`, `hopper.py`, `base.py`, `drive.py`; the rotors are in `assembly.py`),
- `PARTS`: its made parts in their part frame (the names are the file names in `cad/step` and `cad/stl`),
- `PARTS_2D`: the outlines of its flat parts (`cad/dxf`).

`p.py` gives every module the values of `design/params.py` (the same ones `design/build.py` writes to
`cad/params.scad`). Change a dimension in `design/params.py`, then `make solidcraft parts`.

## What is in the assembly

Components: **Frame** (grounded), **Rotor A**, **Rotor B**, **Lid**, **Drawer**, **Torque limiter + output shaft**,
**Worm + gearbox pulley**, **Motor shaft + pulley**. Every body has a timeline folder of its own with its sketches
and features.

| joint | type | axis | positive value | limits |
|---|---|---|---|---|
| Shaft A | revolute | x through (y = -30, z = 0), joint axis -x | = the assembly's `angle` (A turns -angle about +x) | none |
| Shaft B | revolute | x through (y = +30, z = 0), joint axis +x | B turns +angle about +x | none |
| Output shaft | revolute | x through (y = -30, z = -150) (gearbox output axis), joint axis -x | same direction as A | none |
| Worm | revolute | y through (x = -155.8, z = -213), joint axis -y | | none |
| Motor | revolute | y through (x = -405.8, z = -213), joint axis -y | | none |
| Lid hinge | revolute | x through (y = 103, z = 298) (the M5 hinge pin), joint axis -x | opens the lid (front edge up) | 0 .. 100 deg |
| Drawer slide | slider | -y | pulled out toward the user | 0 .. 180 mm |

Links (a -> b; a link makes b follow a, so the **one joint to drive is Shaft A**; Shaft B, Output shaft, Worm and
Motor follow):

* **Gear A-B**: Shaft A -> Shaft B, 1:1, B counter-rotating (made gears m1.5 z40 / z40, involute teeth with backlash)
* **Chain 2:1**: Shaft A -> Output shaft, A turns 2x the TL (15T sprocket on A, 30T on the TL350), same direction
* worm 50:1 (motion link): Output shaft -> Worm, the worm turns 50x the output shaft
* **Belt 2:1**: Worm -> Motor, the motor pulley (34) turns 2x the gearbox pulley (68), same direction

The worm / motor turning direction is a free choice (the worm and both pulleys are plain cylinders, with no thread
hand): only the speed ratios are meaningful.

Motion studies: **Shafts one turn** (Shaft A 0 -> 360 deg, 120 steps; B, TL, worm, motor follow), **Drawer out**
(0 -> 180 mm, 90 steps), **Lid open** (0 -> 100 deg, 100 steps).

## How it was checked against the OpenSCAD model

The model was converted from OpenSCAD (`cad/*.scad`, last built at commit 27662be). `make verify` repeats the checks:

- **Assembly:** each of the 62 groups of bodies against the mesh body of the same name in the old assembly: total
  volume, bounding box, centre of mass. All 62 match: boxes to 0.006 mm, centres to 0.23 mm, volumes to the amount
  the old meshes lose by drawing circles as polygons (0.07 % at `$fn = 96`, up to 4 % for screws drawn with 12 to 16 sides).
- **Parts:** each of the 55 made parts against its old STL, and with `inspect.compare` surface to surface: 54 are
  identical within 0.05 mm (largest deviation 0.048 mm, the old meshes' facets). The 55th is the wire mesh (below).
- **Outlines:** each of the 19 DXF files has the same number of closed loops and the same extent as the old one.
  They now hold true arcs and circles instead of polylines, the outside on layer `OUTLINE`, the holes on `CUT`.

Differences that are known:

- `stop_collar` is not built as a part: its two Ø5 tap-drill holes are as wide as the collar is thick (5 mm), which
  is not a solid. The old STL was an open mesh for the same reason. `cad/stl/stop_collar.stl` is still the old file.
- `grid_mesh`: SolidCraft 0.40 leaves 13 of the 56 wire crossings unfused when it joins the wires (they graze 0.1 mm
  deep), in any order of joining. Volume, box and centre of mass are right; the surface comparison sees the two
  wires' surfaces inside those welds. It is exported as STEP only: round Ø2 wires make a 20 MB STL of a bought part,
  so `cad/stl/grid_mesh.stl` is still the old file.
- The cabinet's floor panel overlaps the bottom 18 mm of both side panels and of the back panel (181 505 mm³). The
  old mesh was the union of the panels, which hid it; here each panel is a body.
- OpenSCAD's 0.01 mm "weld" overlaps between pieces of one part are gone (the pieces are flush or one feature).

## Interference

`make interference` runs SolidCraft's `inspect.interference` (an exact boolean per pair of bodies whose boxes
meet) at rest on every pair, and at 6 poses of each motion study on pairs of bodies of different components
(`--steps N` for more poses). Results: `build/interference.md`. The old mesh assembly could not be checked this way.

Through all three studies nothing overlaps beyond what overlaps at rest. At rest 80 pairs overlap:

- the cabinet floor panel with the side and back panels (above);
- stand-ins that pass through each other by design: the worm through the gearbox housing, the motor shaft in the
  motor, the chain band over the sprocket tooth plates;
- the **idler sprocket and the TL350's sprocket**: 4918 mm³. Their centres are 78.8 mm apart and their pitch radii
  are 30.5 + 60.8 = 91.3 mm, in the same chain plane;
- the four M8 bolts of the tensioner base: 14 mm apart, with Ø16 washers, so neighbouring washers, nuts and heads overlap;
- screws in their pilot holes (wood screws, thread-forming screws in the printed pads).

16 pairs cannot be checked: SolidCraft's boolean fails on parts that touch face to face (a blade and the spacer
next to it, the chamber walls and the hopper collar).

## What still uses OpenSCAD

The design checks C1 .. C32 (`cad/checks.scad`, `make checks`), `make variants`, and the preview pictures
`cad/png/*.png` other than `solidcraft_*.png` (`cad/build.sh`) have not been converted: they run on the OpenSCAD
sources, which are still in `cad/` and unchanged. A change to a part therefore goes into its `model/*.py` module and,
for those checks to see it, into its `.scad` file.
