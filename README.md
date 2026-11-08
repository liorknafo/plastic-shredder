<img src="assets/icon.svg" width="64" height="64" alt="">

# plastic-shredder

A small twin-shaft shredder for 3D-print waste.

- **Made from shop stock** (blades, plates, sleeves and the laminated, case-hardened timing gears cut with your module 1.5 cutter set) on a manual lathe (Roher TBL-20/520), a manual mill (SIEG X3.5D) and a small CNC router (Jingyan CNC4030).
- **Bought parts:** all from Amazon, among them needle bearings, a worm gearbox, a TL350 torque limiter, the chain drive and the shaft steel. The gears are made in the shop (module 1.5, z 40, 4 layers of the 70x10 flat, case-hardened; one extra 600 mm piece of flat is needed).
- **Drive:** a salvaged 375 W single-phase motor.

![Assembly](cad/png/assembly_iso.png)

- **Start here:** [docs/DESIGN.md](docs/DESIGN.md). It covers the parts lists with Amazon links, how to make each part, the drive and torque limiter, assembly and safety.
- **Strength, drive and machining checks:** [docs/CALCULATIONS.md](docs/CALCULATIONS.md). This file is generated.
- **Every dimension:** [design/params.py](design/params.py).

`make all` regenerates the parameters, the calculations, and the STL, DXF and PNG files, and runs all the checks. `make variants` re-checks the fit for other sizes of the bought parts and for other gear layer thicknesses. Both need Python 3 and OpenSCAD; no extra packages are required.
