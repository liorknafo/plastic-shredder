# The SolidCraft model

`cad/shredder_assembly.sc` is the machine as a native SolidCraft design: 8 components, 315 bodies (one per part),
7 joints, 4 motion links and 3 motion studies. Nothing in it is an imported mesh. It is built from
`design/params.py` by the scripts in this folder, with SolidCraft 0.40 (`solidcraft-cli` on `PATH`, or set
`SOLIDCRAFT_CLI`). Python 3, standard library only.

```sh
make solidcraft     # cad/shredder_assembly.sc
make parts          # cad/step, cad/stl, cad/dxf
make interference   # build/interference.md
make pictures       # cad/png/solidcraft_*.png
make verify         # assembly and parts against the OpenSCAD model
solidcraft cad/shredder_assembly.sc
```

The file is saved without SolidCraft's model cache: 0.3 MB, and it rebuilds for about 1.5 min when it opens.
`python3 build.py --cache` keeps the cache (it opens in seconds); saving from the app adds it too.

## Files

| file | job |
|---|---|
| `model/*.py` | the parts, one module per part family (see below) |
| `scq.py` | the modelling layer the modules are written in: `cube`, `cylinder`, `linear_extrude`, `hull`, `translate`, `difference` ..., compiled to SolidCraft features (boxes, cylinders, sketch extrudes with true circles and arcs, lofts, cut / join) |
| `build.py` | the assembly: components, bodies, colours, ground, joints, links, limits, motion studies -> `cad/shredder_assembly.sc` |
| `parts.py` | every made part in its own part frame -> `cad/step`, `cad/stl`, `cad/dxf` |
| `check.py` | builds chosen groups of bodies (`check.py Blades`, `check.py -m hopper`) and compares them with `reference.json` |
| `reference.py` | measures the OpenSCAD model: writes `reference.json` and `parts_reference.json` (see below) |
| `interference.py` | SolidCraft's interference check of the saved assembly |
| `snapshots.py` | `cad/png/solidcraft_*.png` (iso at rest, rotors 60 deg, drawer 180 mm, lid 100 deg, the drive end, sections) |
| `reference.json`, `parts_reference.json` | each group of the OpenSCAD mesh assembly and each OpenSCAD STL part, measured (volume, bounding box, centre of mass) |

`build/` is generated (git-ignored): the command scripts SolidCraft runs, measurements, `interference.md`.

### The model modules

Each module is the translation of the OpenSCAD file of the same name, function for function, in the same frames
(`cad/blade.scad` -> `model/blade.py`, and so on). A function returns a tree; `part("name", ...)` marks one
physical part, which becomes one body. A module lists

- `BODIES`: its groups of bodies in the assembly (`frame.py`, `hopper.py`, `base.py`, `drive.py`; the rotors are in `assembly.py`),
- `PARTS`: its made parts in their part frame (the names are the file names in `cad/step` and `cad/stl`),
- `PARTS_2D`: the outlines of its flat parts (`cad/dxf`).

`p.py` gives every module the values of `design/params.py` (the same ones `design/build.py` writes to
`cad/params.scad`). Change a dimension in `design/params.py`, then `make solidcraft parts`. A change of shape goes
into the `.scad` file and its `model/*.py` module alike (the design checks still run on the `.scad` files).

Two things in `scq.py` change how a tree is built, not what it builds:

- **Holes in one go.** Round cylinders cut from one body that start in the same plane, run the same length and
  keep apart become ONE sketch of circles and one extrude cut (the 216 holes of the screen: one boolean instead of
  216). The cuts are made smallest group first, the biggest last.
- **`split_faces`.** SolidCraft 0.40 cannot mesh a curved face with more than about 60 holes in it: the STL export
  and `inspect.compare` then cover every hole with a skin (the solid and the STEP are right). The screen's two R36
  top faces have 108 holes each, so `base.screen()` splits each of them between hole rows into bands of at most
  46 holes (`solid.split_face`, planes y = const). The solid is the same; the faces have extra edges.

## What is in the assembly

Components: **Frame** (grounded), **Rotor A**, **Rotor B**, **Lid**, **Drawer**, **Output shaft + pin flange**,
**Worm + jaw coupling**, **Motor shaft**. Every body has a timeline folder of its own with its sketches and features.

The drive has no belt and no chain: the motor turns the worm through a jaw coupling (coaxial), the worm gearbox's
hollow output is coaxial with shaft A, and the pin flange on the output shaft drives the TL350 torque limiter on
shaft A through 4 dowel pins in 4 holes drilled in the limiter's sprocket plate. The TL350 is a body of Rotor A;
the pin flange and its pins are bodies of the output shaft's component.

| joint | type | axis | positive value | limits |
|---|---|---|---|---|
| Shaft A | revolute | x through (y = -30, z = 0), joint axis -x | = the assembly's `angle` (A turns -angle about +x) | none |
| Shaft B | revolute | x through (y = +30, z = 0), joint axis +x | B turns +angle about +x | none |
| Output shaft | revolute | x through (y = -30, z = 0) (the gearbox output = shaft A's axis), joint axis -x | same direction as A | none |
| Worm | revolute | y through (x = -283, z = -63), joint axis -y | | none |
| Motor | revolute | y through (x = -283, z = -63) (coaxial with the worm), joint axis -y | | none |
| Lid hinge | revolute | x through (y = 103, z = 298) (the M5 hinge pin), joint axis -x | opens the lid (front edge up) | 0 .. 100 deg |
| Drawer slide | slider | -y | pulled out toward the user | 0 .. 180 mm |

Links (a -> b; a link makes b follow a, so the **one joint to drive is Shaft A**; Shaft B, Output shaft, Worm and
Motor follow):

* **Gear A-B**: Shaft A -> Shaft B, 1:1, B counter-rotating (bought gears m4 z15 / z15, involute teeth with backlash)
* pin coupling 1:1 (motion link): Shaft A -> Output shaft, on the same axis, same direction
* worm 50:1 (motion link): Output shaft -> Worm, the worm turns 50x the output shaft
* jaw coupling 1:1 (motion link): Worm -> Motor

The worm / motor turning direction is a free choice (the worm and the motor shaft are plain cylinders, with no
thread hand): only the speed ratios are meaningful.

Motion studies: **Shafts one turn** (Shaft A 0 -> 360 deg, 120 steps; B, the output shaft, worm, motor follow),
**Drawer out** (0 -> 180 mm, 90 steps), **Lid open** (0 -> 100 deg, 100 steps).

## How it is checked against the OpenSCAD model

The model is a translation of the OpenSCAD sources (`cad/*.scad`). `reference.py` measures the OpenSCAD model the
way the first conversion did: it checks the OpenSCAD commit out into a temporary git worktree, runs that commit's
mesh exporter (`cad/solidcraft/export_parts.py` + `build.py`: OpenSCAD -> one STL per group -> a mesh `.sc`) and
the STL section of its `cad/build.sh`, and measures every group of the mesh assembly and every part STL with
`solidcraft-cli eval`. The current numbers are from commit 727b848 (shredder-design: bought gears, outboard plate,
fixed screen, pin-flange drive); the first conversion's were from 27662be. `make verify` repeats the checks:

- **Assembly:** each of the 52 groups of bodies against the mesh body of the same name in the OpenSCAD assembly:
  total volume, bounding box, centre of mass. All 52 match: boxes to 0.0004 mm, centres to 0.06 mm, volumes to the
  amount the meshes lose by drawing circles as polygons (under 0.3 %; up to 1.8 % for screws drawn with 16 to 24 sides,
  `FACET_TOL` in `check.py`). The hopper collar's mesh is open, so only its box is compared.
- **Parts:** each of the 52 made parts against its OpenSCAD STL (volume, box, centre of mass), and with
  `inspect.compare` surface to surface: all 52 are identical within 0.05 mm (largest deviation 0.038 mm, the meshes'
  facets). The screen is compared with a fresh render instead of its old STL (below).
- **Outlines:** 16 of the 17 DXF files have the same number of closed loops and the same extent as the OpenSCAD one
  (the sprocket drilling template: 27 loops). The old screen drawing was broken (its plan overlapped the cross-section
  and erased 11 holes), so `screen.dxf` is checked on its own (`check_screen_dxf` in `parts.py`): exactly one
  cross-section loop and one plan outline with the right extents, 216 circles Ø5 (±0.01 mm) whose centres are the
  hole centres worked out from `design/params.py` in `parts.py` itself (not from `model/base.py`; within 0.001 mm),
  the 4 screws' Ø4.5 at x = L/3, 2L/3, |y| = 74, and nothing else. The DXFs hold true arcs and circles instead of
  polylines, the outside on layer `OUTLINE`, the holes on `CUT`. Each face of an outline is exported on its own and
  the files are merged: SolidCraft 0.40's DXF export drops islands that lie inside a hole (the template's rings).

Differences that are known:

- `screen`: against its old STL the surface comparison would find 6 places, 0.145 mm deep: the 6 wall-screw pockets
  (Ø11, `$fn = 32`) cut the steep end of the R36 top arcs (`$fn = 192`) at a grazing angle near |y| = 65.6, which
  magnifies the mesh's facets there. So `parts.py --compare` renders the screen of `cad/base.scad` afresh with
  OpenSCAD (`FINE`: a patched copy in `build/` with `$fn` 1536 on the arcs, 512 on the pockets and 128 on the holes,
  deleted afterwards) and compares the native screen with that, with no exception: surface within the normal 0.05 mm
  (0.012 mm), and volume within 0.03 % (-0.008 %; Ø5.05 holes would be -0.26 %, which the surface comparison alone
  does not see) and centre of mass within 0.05 mm. Against the old STL's numbers (`parts_reference.json`) the native
  screen is 0.23 % smaller (its 216 holes are round).
- The cabinet's floor panel overlaps the bottom 18 mm of both side panels and of the back panel (181 505 mm³). The
  mesh was the union of the panels, which hid it; here each panel is a body.
- OpenSCAD's 0.01 mm "weld" overlaps between pieces of one part are gone (the pieces are flush or one feature).
- Parts that no longer exist (belt guard, tensioner, wire-mesh grid and its cleats, upper front panel, drawer switch
  pads, side skirts, stop collar, the made gear's layer and mandrel) have no STEP, STL or DXF any more.

## Interference

`make interference` runs SolidCraft's `inspect.interference` (an exact boolean per pair of bodies whose boxes
meet) at rest on every pair, and at 6 poses of each motion study on pairs of bodies of different components
(`--steps N` for more poses). Results: `build/interference.md`.

Through all three studies nothing overlaps beyond what overlaps at rest. At rest 10 pairs overlap (315 bodies,
859 pairs whose boxes meet):

- the cabinet floor panel with the two side panels and the back panel (65 448, 65 448, 50 609 mm³; above);
- the worm through the gearbox housing (28 353 mm³): both are stand-ins, the housing is a plain box;
- screws in their pilot holes: the lid actuator pad's M5 and M4 screws (52 and 9 mm³ each), the lid switch's two
  M4 screws in the hopper funnel (28 mm³ each).

The overlaps of the old drive are gone with its parts: the idler sprocket against the TL350's sprocket, the
tensioner's M8 washers, the chain band over the sprockets, the motor shaft in the motor.

20 pairs cannot be checked: SolidCraft's boolean fails on parts that touch face to face (a blade and the spacer
next to it, the chamber walls and the hopper collar).

## What still uses OpenSCAD

The design checks (`cad/checks.scad`, `make checks`), `make variants`, and the preview pictures `cad/png/*.png` other
than `solidcraft_*.png` (`cad/build.sh`) have not been converted: they run on the OpenSCAD sources in `cad/`.
`make verify` needs OpenSCAD too: it renders the screen of `cad/base.scad` to compare it with the native one. A change
to a part therefore goes into its `model/*.py` module and, for those checks to see it, into its `.scad` file.
