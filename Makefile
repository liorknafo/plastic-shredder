# make params : regenerate cad/params.scad + cad/blade_profile.scad from design/params.py
# make calc   : strength / drive / machining checks -> docs/CALCULATIONS.md (fails if a check fails)
# make cad    : STL / DXF / PNG / interference checks (cd cad && ./build.sh)
# make variants : try the unknown bought parts (GEAR_HUB_L = 12 / 22, the TL350's sprocket 1 mm deeper, GB_HUB_L = 80 + motor shaft 50) and the pin flange set off (PF_GAP 1 / 3, spacer 6) in a TEMPORARY copy and run the
#                 alignment / collision checks there (cad/variants.sh); fails if any check fails; the real tree is not touched
# make solidcraft : interactive SolidCraft assembly with joints (cad/shredder_assembly.sc) from the current cad/*.scad; NOT part of `all` (cad/solidcraft/README.md)
# make all    : everything
.PHONY: all params calc cad variants solidcraft

all: params calc cad

params:
	python3 design/build.py

calc: params
	python3 calc/calc.py > /dev/null

cad: params
	cd cad && ./build.sh

variants:
	cad/variants.sh

solidcraft:
	cd cad/solidcraft && python3 export_parts.py && python3 build.py
