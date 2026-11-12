# The CAD model is a SolidCraft project (cad/shredder_assembly.sc, built by cad/solidcraft from design/params.py).
#
# make params       : regenerate cad/params.scad + cad/blade_profile.scad from design/params.py
# make calc         : strength / drive / machining checks -> docs/CALCULATIONS.md (fails if a check fails)
# make solidcraft   : the SolidCraft assembly cad/shredder_assembly.sc (native bodies, joints, links, motion studies) from design/params.py (cad/solidcraft/README.md)
# make parts        : every made part from SolidCraft: cad/step, cad/stl (for AXIS CAM and printing), cad/dxf (outlines)
# make interference : SolidCraft's exact interference check, at rest and through the three motion studies -> cad/solidcraft/build/interference.md
# make pictures     : cad/png/solidcraft_*.png
# make verify       : assembly and parts against the measurements of the old OpenSCAD model (reference.json, parts_reference.json); fails on a difference.
#                     After a deliberate change of the design: `python3 build.py --freeze` and `python3 parts.py --freeze` in cad/solidcraft
# make checks       : the design checks C1 .. C32 of cad/checks.scad (alignment, clearances, envelopes).  They still run on the OpenSCAD sources: needs OpenSCAD
# make variants     : try the unknown bought parts (SPROCKET_A hub_L = 20 / 25, GEAR_LAYER_T = 9.5 / 10.0, CHAIN_CD = 152 / 157, GB_HUB_L = 80) in a TEMPORARY copy and run the
#                     alignment / collision checks there (cad/variants.sh); fails if any check fails; the real tree is not touched.  Needs OpenSCAD
# make cad          : the OLD OpenSCAD pipeline (cd cad && ./build.sh): PNG previews, the checks, and STL / DXF as OpenSCAD meshes, which OVERWRITE the SolidCraft exports in
#                     cad/stl and cad/dxf (run `make parts` after it).  Needs OpenSCAD
# make all          : params, calc, solidcraft, parts, checks
.PHONY: all params calc solidcraft parts interference pictures verify checks variants cad

all: params calc solidcraft parts checks

params:
	python3 design/build.py

calc: params
	python3 calc/calc.py > /dev/null

solidcraft: params
	cd cad/solidcraft && python3 -B build.py

parts: params
	cd cad/solidcraft && python3 -B parts.py --export

interference:
	cd cad/solidcraft && python3 -B interference.py

pictures:
	cd cad/solidcraft && python3 -B snapshots.py

verify: params
	cd cad/solidcraft && python3 -B build.py --check && python3 -B parts.py --check --compare --dxf

checks: params
	cd cad && ./build.sh checks

variants:
	cad/variants.sh

cad: params
	cd cad && ./build.sh
