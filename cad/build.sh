#!/usr/bin/env bash
# build.sh -- STL (stl/), DXF (dxf/), PNG previews (png/), interference checks (logs/checks.txt).
# Usage: ./build.sh              everything
#        ./build.sh checks       only the checks      ./build.sh C1   only checks whose id contains "C1"
#        ./build.sh <word>       only outputs whose name contains <word> (e.g. "plate", "assembly", "dxf")
#        ./build.sh variants     only the alignment / collision checks (VARIANT_PATTERNS) + the design asserts; used by `make variants` in a TEMPORARY copy
#                                of the tree (it writes logs/checks_variants.txt, never logs/checks.txt)
# Exit status is non-zero on any OpenSCAD WARNING/ERROR, non-manifold result, failed check or failed ligament test.
set +u
cd "$(dirname "$0")"
OPENSCAD="${OPENSCAD:-$(command -v openscad || echo /opt/homebrew/bin/openscad)}"
BACKEND=(--backend=manifold)
# patterns that count as a problem in a log
BAD='^(WARNING|ERROR)|Status: +[^N ]|Status: +N[^o]|CGAL.*(error|warning|fail)|non-manifold|not manifold|empty'
mkdir -p stl dxf png logs logs/chk
ONLY="${1:-}"
VARIANT_PATTERNS="C2 C5 C8 C10 C16 C17 C20 C21 C22 C23 C24 C26 C27 C28 C29 C30 C31 C32"      # make variants: C2 envelopes (incl. the guards), C5 pairs, C8 belt guard, C10/C17 interlocks, C16 joint alignment, C20 bearings, C21 sprocket, C22 chain, C23 drive vs deck, C24 guard, C26 chain plane / belt, C27 hold-down, C28 output shaft, C29 safety grid
fail=0
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

want() { [ "$ONLY" = variants ] && return 1; [ -z "$ONLY" ] || [[ "$1" == *"$ONLY"* ]]; }
scan() { # LOGFILE
  if grep -qE "$BAD" "$1"; then echo "   ---- warnings/errors in $1:"; grep -E "$BAD" "$1" | sort -u | head -5; fail=1; fi
}

# part NAME FILE.scad "DEF1" "DEF2" ... -> stl/NAME.stl
part() {
  name="$1"; file="$2"; shift 2
  want "$name" || return
  args=(); for d in "$@"; do args+=(-D "$d"); done
  log="logs/$name.log"
  echo "== stl/$name.stl"
  "$OPENSCAD" "${BACKEND[@]}" ${args[@]+"${args[@]}"} -o "stl/$name.stl" "$file" >"$log" 2>&1 || { echo "   STL FAILED"; fail=1; }
  scan "$log"
}
# dxf NAME FILE.scad "DEFS"... -> dxf/NAME.dxf
dxf() {
  name="$1"; file="$2"; shift 2
  want "$name" || want dxf || return
  args=(); for d in "$@"; do args+=(-D "$d"); done
  log="logs/dxf_$name.log"
  echo "== dxf/$name.dxf"
  "$OPENSCAD" "${BACKEND[@]}" ${args[@]+"${args[@]}"} -o "dxf/$name.dxf" "$file" >"$log" 2>&1 || { echo "   DXF FAILED"; fail=1; }
  scan "$log"
}
# shot NAME FILE.scad CAMERA "DEFS"... -> png/NAME.png (1200x900, Tomorrow colours, orthographic, fitted to the model)
shot() {
  name="$1"; file="$2"; cam="$3"; shift 3
  want "$name" || return
  args=(); for d in "$@"; do args+=(-D "$d"); done
  log="logs/png_$name.log"
  echo "== png/$name.png"
  "$OPENSCAD" "${BACKEND[@]}" ${args[@]+"${args[@]}"} -o "png/$name.png" --imgsize=1200,900 --autocenter --viewall \
      --projection=ortho --colorscheme=Tomorrow --render 1 --camera="$cam" "$file" >"$log" 2>&1 || { echo "   PNG FAILED"; fail=1; }
  scan "$log"
}

# shotfix NAME FILE.scad CAMERA "DEFS"... -> like shot but the exact camera (no autocenter / viewall): tight views along an axis
shotfix() {
  name="$1"; file="$2"; cam="$3"; shift 3
  want "$name" || return
  args=(); for d in "$@"; do args+=(-D "$d"); done
  log="logs/png_$name.log"
  echo "== png/$name.png (fixed camera)"
  "$OPENSCAD" "${BACKEND[@]}" ${args[@]+"${args[@]}"} -o "png/$name.png" --imgsize=1200,900 \
      --projection=ortho --colorscheme=Tomorrow --render 1 --camera="$cam" "$file" >"$log" 2>&1 || { echo "   PNG FAILED"; fail=1; }
  scan "$log"
}

# ------------------------------------------------------------------ parts: STL
for v in 0 1 2 3; do part "blade_v$v" blade.scad "variant=$v"; done
part spacer          spacer.scad
part end_spacer_B    spacer.scad 'kind="end_B"'
part shaft_A         shaft.scad  'which="A"'
part shaft_B         shaft.scad  'which="B"'
part plate_inner     plate.scad  'kind="inner"'
part plate_outer     plate.scad  'kind="outer"'
part plate_cap       plate.scad  'kind="cap"'
part sleeve_drive    sleeve.scad 'kind="drive"'
part sleeve_free_A   sleeve.scad 'kind="free_A"'
part sleeve_free_B   sleeve.scad 'kind="free_B"'
part collar_sleeve_drive sleeve.scad 'kind="collar_drive"'
part collar_sleeve_free  sleeve.scad 'kind="collar_free"'
part gear_spacer     sleeve.scad 'kind="gear_spacer"'
part comb_A          comb.scad   'sh="A"'
part comb_B          comb.scad   'sh="B"'
part wall            wall.scad
part end_cap         smallparts.scad 'part="end_cap"'
part gear_A          gear.scad   'part="gear"'
part gear_B          gear.scad   'part="gear_B"'
part gear_layer      gear.scad   'part="layer"'
part gear_mandrel    gear.scad   'part="mandrel"'
part stop_collar     drive.scad  'part="stop_collar"'
part output_shaft    drive.scad  'part="output_shaft"'
# printed guards / hopper (PETG, MK3S 250 x 210 x 210): print pose, flat face down
part hopper_collar   hopper.scad 'part="collar"'
part hopper_funnel   hopper.scad 'part="funnel"'
part hopper_lid      hopper.scad 'part="lid"'
part hopper_lid_pad  hopper.scad 'part="lid_act_pad"'
part skirt_A         guards.scad 'part="skirt_A"'
part skirt_B         guards.scad 'part="skirt_B"'
part dg_upper        guards.scad 'part="dg_upper"'
part dg_lower        guards.scad 'part="dg_lower"'
part free_end_cover  guards.scad 'part="free_end_cover"'
part belt_guard_a    drive.scad  'part="belt_guard_a"'
part belt_guard_b    drive.scad  'part="belt_guard_b"'
# steel / plywood parts (3D reference models)
part base_plate      base.scad   'part="base_plate"'
part cabinet         base.scad   'part="cabinet"'
part upper_front     base.scad   'part="upper_front"'
part grid_mesh       base.scad   'part="grid_mesh"'
part grid_cleats     base.scad   'part="grid_cleats"'
part drive_deck      drive.scad  'part="drive_deck"'
part gb_rail         drive.scad  'part="gb_rail"'
part gb_spacer       drive.scad  'part="gb_spacer"'
part leg_angle       drive.scad  'part="leg_angle"'
part tens_upright    drive.scad  'part="tens_upright"'
part tens_base       drive.scad  'part="tens_base"'
# torque-limiter setting fixture (made parts)
part tl_stub         tlfix.scad  'part="stub"'
part tl_lever        tlfix.scad  'part="lever"'
part tl_lug          tlfix.scad  'part="lug"'
part test_lever      testlever.scad 'part="lever"'
# printed drawer parts (PETG)
part drawer_handle   base.scad   'part="drawer_handle"'
part drawer_pad      base.scad   'part="drawer_pad"'
part drawer_act_pad  base.scad   'part="drawer_act_pad"'

# printer-fit check: every printed part must fit 250 x 210 x 210 (and sit on z = 0)
if want fit || want hopper || want guard || want skirt || want belt || want drawer || want dg_ || [ -z "$ONLY" ]; then
  echo "== printer fit (MK3S 250 x 210 x 210)"
  PRINTED=(); for n in hopper_collar hopper_funnel hopper_lid hopper_lid_pad skirt_A skirt_B dg_upper dg_lower free_end_cover belt_guard_a belt_guard_b drawer_handle drawer_pad drawer_act_pad; do [ -f "stl/$n.stl" ] && PRINTED+=("stl/$n.stl"); done
  python3 fit.py 250 210 210 "${PRINTED[@]}" | tee logs/fit.txt || fail=1
fi

# ------------------------------------------------------------------ DXF
for v in 0 1 2 3; do dxf "blade_v$v" blade.scad "variant=$v" flat=true; done
dxf gear_layer gear.scad 'part="layer_2d"'              # ONE layer for the CNC4030: rough Ø64 outline + bore Ø25 + keyway 8 (R1.5 corners); 8 of them
dxf gear_profile gear.scad 'part="profile_2d"'          # the finished gear (teeth + bore + keyway), for reference / checking the cut gear
dxf comb_A comb.scad 'sh="A"' flat=true
dxf base_plate base.scad 'part="base_2d"'
dxf cabinet_panels base.scad 'part="cabinet_2d"'
dxf grid_mesh base.scad 'part="grid_mesh_2d"'          # the welded mesh (wires at 25.4 pitch); its extent is the CUT SIZE of the sheet
dxf grid_cleats base.scad 'part="grid_cleats_2d"'      # the 8 timber cleat strips (4 lower, 4 upper) with the Ø3 pilots
dxf drive_deck drive.scad 'part="drive_deck_2d"'
dxf gb_rail drive.scad 'part="gb_rail_2d"'
dxf output_shaft drive.scad 'part="output_shaft_2d"'
dxf tens_upright drive.scad 'part="tens_upright_2d"'
dxf tens_base drive.scad 'part="tens_base_2d"'
dxf tl_stub tlfix.scad 'part="stub_2d"'
dxf tl_lever tlfix.scad 'part="lever_2d"'
dxf test_lever testlever.scad 'part="lever_2d"'

# ------------------------------------------------------------------ PNG previews
# camera "x,y,z,rx,ry,rz,dist" (rotation form) or "ex,ey,ez,cx,cy,cz" (eye / centre form); fitted by --viewall
FRONT="65,0,15,90,0,270,330"     # looks along +x from the drive side (+y on the viewer's left, z up), x of the centre is irrelevant
shot assembly_iso     assembly.scad "0,0,0,62,0,320,900" show_motor=false ghost_guards=true
shot assembly_guards  assembly.scad "0,0,0,65,0,215,900" show_hopper=false
shotfix assembly_front assembly.scad "$FRONT" show_drive_side=false show_hopper=false show_extras=false show_gearbox=false
shot assembly_top     assembly.scad "0,0,0,0,0,0,900" show_hopper=false show_extras=false show_gearbox=false
shotfix grid_section  assembly.scad "66,0,-160,90,0,270,1100" section_x=66.1 grid_dims=true show_hopper=false show_drive_side=false show_gearbox=false
shotfix section_x60   assembly.scad "$FRONT" section_x=60 show_hopper=false show_extras=false show_gearbox=false
shotfix hopper_section assembly.scad "66,0,140,90,0,270,1100" section_x=66.1 show_motor=false show_gearbox=false
shot drive_end_section assembly.scad "0,0,0,90,0,0,500" section_pair=true show_hopper=false show_gearbox=false show_combs_walls=false
shot drive_iso        assembly.scad "0,0,0,62,0,300,900" show_hopper=false drive_only=true ghost_guards=true deck_alpha=0.3
shot drive_tl         assembly.scad "0,0,0,62,0,130,900" show_hopper=false show_motor=false hide_guards=true deck_alpha=0.3 show_holddown=false 'clip=[-275,-115,-300,-36,75,-40]'
shot drive_tl_section assembly.scad "0,0,0,60,0,200,900" show_hopper=false show_motor=false hide_guards=true deck_alpha=0.3 show_holddown=false 'clip=[-275,-115,-300,-36,-29.9,-40]'
shot tl_setting       tlfix.scad    "0,0,0,62,0,195,900" labels=true 'cam=[62,0,195]'
shot blade_variants   previews.scad "0,0,0,0,0,0,600" 'scene="blade_variants"'
shot shaft_A          previews.scad "0,0,0,55,0,340,900" 'scene="shaft_A"'
shot shaft_B          previews.scad "0,0,0,55,0,340,900" 'scene="shaft_B"'
shot plate_layers     previews.scad "0,0,0,0,0,0,900" 'scene="plate_layers"'
shot comb_B           previews.scad "0,0,0,0,0,0,400" 'scene="comb_B"'
shot interlock_drawer previews.scad "0,0,0,62,0,40,500" 'scene="interlock_drawer"'
# the made gears: close-up of the mesh (view along the shafts, +y on the viewer's left) and one CNC layer with the finished tooth profile over it
shotfix gears_mesh    previews.scad "0,0,0,90,0,270,130" 'scene="gears_mesh"'
shotfix gear_layer    previews.scad "0,0,5,0,0,0,215" 'scene="gear_layer"'
shot interlock_hopper previews.scad "0,0,0,80,0,115,350" 'scene="interlock_hopper"'
# blade torque test: fixed camera (the billboarded labels would otherwise shrink the --viewall fit); cam= must match the camera rotation
shotfix blade_torque_test testlever.scad "0,260,-60,78,0,70,2100" labels=true 'cam=[78,0,70]'

# bill of materials of the timber / hardware placeholders (echoed by the scad files)
if want bom || [ -z "$ONLY" ]; then
  { for f in base drive hopper tlfix testlever; do "$OPENSCAD" "${BACKEND[@]}" -D 'part="bom"' -o "$TMP/bom_$f.stl" $f.scad 2>&1 | grep '^ECHO' ; done; } | sed 's/^ECHO: "//; s/"$//' > logs/bom.txt
  echo "== logs/bom.txt"; cat logs/bom.txt
fi

# ------------------------------------------------------------------ hole ligament (hole table comes from plate.scad itself)
if want ligament || want plate || want checks || [ -z "$ONLY" ]; then
  echo "== hole ligament"
  "$OPENSCAD" "${BACKEND[@]}" -D dump_holes=true -o logs/holes.echo plate.scad >logs/holes.log 2>&1 || { echo "   FAILED"; fail=1; }
  scan logs/holes.log
  python3 ligament.py logs/holes.echo | tee logs/ligament.txt || fail=1
fi

# ------------------------------------------------------------------ interference checks
# run_check ID "description" EXPECT(empty|nonempty) "DEF"...   -> a line in logs/checks.txt, sets cfail on mismatch.
CHK="logs/checks.txt"
cfail=0
RESULTS=()
run_check() {
  id="$1"; desc="$2"; expect="$3"; shift 3
  args=(); for d in "$@"; do args+=(-D "$d"); done
  log="logs/chk/$id.log"
  "$OPENSCAD" "${BACKEND[@]}" ${args[@]+"${args[@]}"} -o "$TMP/chk_$id.stl" checks.scad >"$log" 2>&1
  rc=$?
  if grep -qE '^(WARNING|ERROR)' "$log"; then got="error"
  elif grep -q 'Current top level object is empty' "$log"; then got="empty"
  elif [ "$rc" = 0 ]; then got="nonempty"
  else got="error"; fi
  if [ "$got" = "$expect" ]; then st=PASS; else st=FAIL; cfail=1; fi
  RESULTS+=("$st $id | $desc | expected $expect, got $got")
  [ "$st" = FAIL ] && echo "   $st $id ($desc): expected $expect, got $got (see $log)"
}
cwant() {
  if [ -z "$ONLY" ] || [ "$ONLY" = checks ]; then return 0; fi
  if [ "$ONLY" = variants ]; then for p in $VARIANT_PATTERNS; do [[ "$1" == *"$p"* ]] && return 0; done; return 1; fi
  [[ "$1" == *"$ONLY"* ]]
}
[ "$ONLY" = variants ] && CHK="logs/checks_variants.txt"

if [ "$ONLY" = variants ]; then      # the top-level asserts of the part files (hole distances, wing layout ...) only run when the file itself is rendered
  echo "== design asserts (base, drive, hopper, tlfix)"
  for f in base drive hopper tlfix; do
    "$OPENSCAD" "${BACKEND[@]}" -D 'part="bom"' -o "$TMP/as_$f.stl" $f.scad >"logs/asserts_$f.log" 2>&1
    if grep -qE '^(WARNING|ERROR)' "logs/asserts_$f.log"; then echo "   FAIL asserts $f:"; grep -E '^(WARNING|ERROR)' "logs/asserts_$f.log" | sort -u | head -3; fail=1; fi
  done
fi

if [ -z "$ONLY" ] || [ "$ONLY" = checks ] || [ "$ONLY" = variants ] || [[ "$ONLY" == C* ]]; then
  echo "== interference checks"
  for ang in $(seq 0 5 115); do
    id=$(printf "C1_angle%03d" "$ang")
    cwant "$id" && run_check "$id" "C1 A rotating set ^ B rotating set, angle=$ang" empty 'check="C1"' "angle=$ang"
  done
  cwant C1ctl && run_check C1ctl "C1 control: B shifted 4 mm toward A (must collide)" nonempty 'check="C1ctl"'
  for s in A B; do
    cwant "C2_$s" && run_check "C2_$s" "C2 swept envelope of shaft $s blades+spacers ^ combs+walls+inner layers+collar+funnel+skirts+drive-end guard+free-end cover" empty 'check="C2"' "sh=\"$s\""
    cwant "C2ctl_$s" && run_check "C2ctl_$s" "C2 control: shaft $s envelope with R_TIP+3 (must hit)" nonempty 'check="C2ctl"' "sh=\"$s\""
    for kk in 0 1 2 3 4 5 6 7; do
      cwant "C3_${s}_k$kk" && run_check "C3_${s}_k$kk" "C3 blade $kk of shaft $s ^ shaft $s (hex bore clears hex)" empty 'check="C3"' "sh=\"$s\"" "k=$kk"
    done
    cwant "C3x_$s" && run_check "C3x_$s" "C3x spacers+clamp sleeves+collared sleeves of shaft $s ^ shaft $s" empty 'check="C3x"' "sh=\"$s\""
    cwant "C3ctl_$s" && run_check "C3ctl_$s" "C3 control: blade 0 vs shaft $s turned 30 deg (must hit)" nonempty 'check="C3ctl"' "sh=\"$s\"" k=0
  done
  # C2g/C2c: rotating drive-end parts vs the drive-end guard; free-end collars / thrust / caps / heads vs the free-end cover (>= 3 mm)
  cwant C2g && run_check C2g "C2g gears, hubs, collars, thrust bearings, sprocket A, end caps + M10 heads (A, B) grown 2.9 mm ^ drive-end guard (>= 3 mm clear)" empty 'check="C2g"'
  cwant C2gctl && run_check C2gctl "C2g control: guard shifted 4 mm toward the gears (must hit)" nonempty 'check="C2gctl"'
  cwant C2c && run_check C2c "C2c free-end collars, thrust + crinkle washers, end caps, M10 heads grown 2.9 mm ^ free-end cover (>= 3 mm clear)" empty 'check="C2c"'
  cwant C2cctl && run_check C2cctl "C2c control: parts grown 3.5 mm hit the cover" nonempty 'check="C2cctl"'
  # C6: tolerance: shaft B blades+spacers shifted +-0.17 mm along x vs shaft A's rotating set
  for ang in $(seq 0 15 115); do
    for sgn in p m; do
      d=0.17; [ "$sgn" = m ] && d=-0.17
      id=$(printf "C6_%s_angle%03d" "$sgn" "$ang")
      cwant "$id" && run_check "$id" "C6 A rotating set ^ B blades+spacers shifted $d mm in x, angle=$ang" empty 'check="C6"' "dx=$d" "angle=$ang"
    done
  done
  for ang in 0 45 90; do
    cwant C6ctl && run_check "C6ctl_angle$ang" "C6 control: B shifted +0.25 mm in x, angle=$ang (must hit)" nonempty 'check="C6"' "dx=0.25" "angle=$ang"
  done
  # C20: bearings, seals, thrust, crinkle, collared sleeves, gears, sprocket, end caps -- vs the plates, vs each other, seated
  cwant C20a && run_check C20a "C20a 4 bearings + 4 seals + 4 thrust + 2 crinkle stacks ^ all plate layers (new bores)" empty 'check="C20a"'
  cwant C20actl && run_check C20actl "C20a control: bearings shifted 3 mm in y (must hit the plates)" nonempty 'check="C20actl"'
  DN=(seal bearing_outer rollers inner_ring thrust clamp_sleeve collared_sleeve gear gear_spacer end_cap_screw sprocket_A)
  FN=(seal bearing_outer rollers inner_ring crinkle thrust clamp_sleeve collared_sleeve end_cap_screw)
  for i in $(seq 0 $(( ${#DN[@]} - 1 ))); do
    cwant "C20b_drive_${DN[$i]}" && run_check "C20b_drive_${DN[$i]}" "C20b drive end: ${DN[$i]} ^ every other part of the stack, both shafts, the 3 plate layers" empty 'check="C20b"' 'en="drive"' "oi=$i"
  done
  for i in $(seq 0 $(( ${#FN[@]} - 1 ))); do
    cwant "C20b_free_${FN[$i]}" && run_check "C20b_free_${FN[$i]}" "C20b free end: ${FN[$i]} ^ every other part of the stack, both shafts, the 3 plate layers" empty 'check="C20b"' 'en="free"' "oi=$i"
  done
  cwant C20bctl && run_check C20bctl "C20b control: drive inner ring 3 mm toward the chamber (must hit)" nonempty 'check="C20bctl"'
  cwant C20s1 && run_check C20s1 "C20s drive: bearing outer ring 0.05 mm toward the chamber overlaps the inner-layer shoulder (seated on it)" nonempty 'check="C20s1"'
  cwant C20s2 && run_check C20s2 "C20s drive: bearing outer ring 0.05 mm outward overlaps the cap step (held by it)" nonempty 'check="C20s2"'
  cwant C20s3 && run_check C20s3 "C20s free: bearing outer ring 0.05 mm toward the chamber overlaps the inner-layer shoulder" nonempty 'check="C20s3"'
  cwant C20s4 && run_check C20s4 "C20s free: bearing outer ring 0.05 mm outward overlaps the cap step" nonempty 'check="C20s4"'
  cwant C20sctl && run_check C20sctl "C20s control: outer ring 0.45 mm off its shoulder: no overlap" empty 'check="C20sctl"'
  CDESC=("C20c1|drive inner ring touches the clamp sleeve" "C20c2|drive inner ring touches the collared sleeve" "C20c3|thrust bearing touches the collar" "C20c3b|thrust bearing touches the drive cap face"
         "C20c4|free inner ring touches the clamp sleeve" "C20c5|free inner ring touches the collared sleeve" "C20c6|crinkle stack touches the free cap face" "C20c7|free thrust bearing touches the crinkle stack"
         "C20c7b|free thrust bearing touches the free collar" "C20c8|gear touches the drive collar" "C20c9|gear spacer sleeve touches the gear's outer face" "C20c10|sprocket A hub touches shaft A's gear spacer sleeve"
         "C20c11|end cap A sits on the sprocket hub face" "C20c12|end cap B sits on the gear spacer sleeve" "C20c13|free end cap sits on the collar")
  for cd in "${CDESC[@]}"; do cwant "${cd%%|*}" && run_check "${cd%%|*}" "C20c contact: ${cd#*|} (0.04 mm further in = overlap, so the stack has no gap > 0.04 mm)" nonempty "check=\"${cd%%|*}\""; done
  cwant C20cctl && run_check C20cctl "C20c control: drive inner ring 0.46 mm away from the clamp sleeve: no contact" empty 'check="C20cctl"'
  cwant C20c3ctl && run_check C20c3ctl "C20c control: thrust bearing 0.46 mm off the collar: no contact" empty 'check="C20c3ctl"'
  # C21: sprocket A vs shaft B's parts
  cwant C21 && run_check C21 "C21 sprocket A (teeth OD 67.3 + hub, swept, grown 4.9 mm) ^ shaft B's gear, hub, collar, thrust, end cap, M10 head: >= 5 mm clear" empty 'check="C21"'
  cwant C21ctl && run_check C21ctl "C21 control: sprocket grown 11.5 mm hits B's parts" nonempty 'check="C21ctl"'
  # C31: the two made gears in mesh through more than one tooth pitch (9 deg), 1 deg steps; controls: centre distance 0.3 short, no backlash + 0.5 deg offset, wrong tooth phase
  for ang in $(seq 0 1 10); do
    id=$(printf "C31_angle%02d" "$ang")
    cwant "$id" && run_check "$id" "C31 made gear A ^ made gear B (involute teeth, backlash), A turns -$ang deg, B +$ang deg" empty 'check="C31"' "angle=$ang"
  done
  for ang in 0 3 6; do
    cwant "C31ctl_cd" && run_check "C31ctl_cd_angle$ang" "C31 control: centre distance 59.7 (0.3 short), angle=$ang (must hit)" nonempty 'check="C31ctl_cd"' "angle=$ang"
    cwant "C31ctl_nobl" && run_check "C31ctl_nobl_angle$ang" "C31 control: zero-backlash gears with B 0.5 deg off, angle=$ang (must hit)" nonempty 'check="C31ctl_nobl"' "angle=$ang"
  done
  cwant C31ctl_phase && run_check C31ctl_phase "C31 control: B's teeth not turned half a pitch (tooth meets tooth, must hit)" nonempty 'check="C31ctl_phase"'
  for off in 0.10 -0.10; do   # backlash is real: the gears can be turned +-0.10 deg against each other (half the backlash is 0.139 deg) ...
    cwant C31off && run_check "C31off_$off" "C31 backlash: gear B turned $off deg off the conjugate position, angle=0: still free (half backlash = 0.139 deg)" empty 'check="C31off"' "goff=$off"
  done
  for off in 0.18 -0.18; do   # ... but not +-0.18 deg
    cwant C31off && run_check "C31offctl_$off" "C31 backlash control: gear B turned $off deg: teeth touch (must hit)" nonempty 'check="C31off"' "goff=$off"
  done
  for ang in 0 4; do
    cwant "C32_angle$ang" && run_check "C32_angle$ang" "C32 both made gears (angle $ang) ^ drive plates, drive-end + chain guard, chain band" empty 'check="C32"' "angle=$ang"
  done
  cwant C32s && run_check C32s "C32s made gear B ^ sprocket A (hub + tooth plate)" empty 'check="C32s"' 'angle=0'
  cwant C32ctl && run_check C32ctl "C32 control: gears 10 mm toward the plates (must hit)" nonempty 'check="C32ctl"'
  # C22: the chain
  cwant C22a && run_check C22a "C22a chain (swept band round A, TL sprocket, idler at both slot ends, grown 2.9 mm) ^ plates, combs, walls, hopper, skirts, base plate, cabinet, drawer, deck + legs, gearbox, rails, motor, belt guard, tensioner, guards" empty 'check="C22a"'
  cwant C22actl && run_check C22actl "C22a control: chain moved 85 mm toward the machine (must hit the drive plates)" nonempty 'check="C22actl"'
  cwant C22b && run_check C22b "C22b chain (grown 2.9 mm) ^ both shafts' gears, hubs, collars, thrust, end caps, heads (sprocket A excluded: it carries the chain)" empty 'check="C22b"'
  cwant C22bctl && run_check C22bctl "C22b control: chain moved 40 mm toward shaft B (must hit B's end cap / head)" nonempty 'check="C22bctl"'
  cwant C22c && run_check C22c "C22c chain ^ TL body + stop collar, idler spacer + washers + nut (all three slot positions)" empty 'check="C22c"'
  cwant C22cctl && run_check C22cctl "C22c control: chain 15 mm sideways cuts the TL body (must hit)" nonempty 'check="C22cctl"'
  # C23: gearbox, TL, motor, belt vs deck, cabinet, base ...
  cwant C23a && run_check C23a "C23a gearbox + TL350 + worm + output shaft ^ plates, combs, cabinet, base plate, drawer, deck, legs, tensioner, motor, pulleys, belt" empty 'check="C23a"'
  cwant C23actl && run_check C23actl "C23a control: gearbox + TL moved 195 mm toward the machine (must hit the cabinet)" nonempty 'check="C23actl"'
  cwant C23b && run_check C23b "C23b motor + pulleys + belt ^ plates, cabinet, base plate, legs, tensioner, gearbox, rails, TL" empty 'check="C23b"'
  cwant C23c && run_check C23c "C23c deck (nudged 0.01: contact only) ^ motor foot, rails, tensioner base, belt guard, gearbox, pulleys, belt" empty 'check="C23c"'
  cwant C23cctl && run_check C23cctl "C23c control: deck raised 3 mm (must hit the motor foot and the rails)" nonempty 'check="C23cctl"'
  cwant C23d && run_check C23d "C23d deck + legs ^ building, gearbox, rails, tensioner, TL, drive guard" empty 'check="C23d"'
  cwant C23e && run_check C23e "C23e gearbox foot bolts, rails bolts + nuts, tensioner bolts, idler hardware ^ flange, housing, rails, deck, tensioner base + upright (seated 0.01)" empty 'check="C23e"'
  cwant C23ectl && run_check C23ectl "C23e control: bolts moved 3 mm in x (must hit the plates)" nonempty 'check="C23ectl"'
  cwant C23f && run_check C23f "C23f idler sprocket + spacer tube ^ tensioner upright" empty 'check="C23f"'
  cwant C23fctl && run_check C23fctl "C23f control: idler 1 mm toward the upright (must hit)" nonempty 'check="C23fctl"'
  # C24: drive-end guard / chain guard
  cwant C24a && run_check C24a "C24a drive-end + chain guard ^ every moving part grown 2.9 mm (gears, hubs, collars, thrust, caps, heads, sprocket A, chain at all idler positions, TL, boss, idler hardware, free-end parts): >= 3 mm clear" empty 'check="C24a"'
  cwant C24actl && run_check C24actl "C24a control: parts grown 3.5 mm hit the guard" nonempty 'check="C24actl"'
  cwant C24b && run_check C24b "C24b guard ^ gearbox, worm shaft, rails, deck, legs, tensioner bolts, belt guard, motor, pulleys, belt, cabinet, base plate" empty 'check="C24b"'
  cwant C24c && run_check C24c "C24c guard notch ^ tensioner upright grown 2.9 mm (the notch is 3 mm all round) and base plate" empty 'check="C24c"'
  cwant C24cctl && run_check C24cctl "C24c control: upright grown 3.4 mm hits the notch edge" nonempty 'check="C24cctl"'
  # C25: torque-limiter setting fixture
  cwant C25a && run_check C25a "C25a TL fixture: chain wrap grown 2.9 mm ^ stub, vise, stand, bench, TL body, key (>= 3 mm clear)" empty 'check="C25a"'
  cwant C25actl && run_check C25actl "C25a control: vise moved under the TL hits the chain wrap" nonempty 'check="C25actl"'
  cwant C25b && run_check C25b "C25b TL fixture: lever ^ chain, stub, vise, stand, bench, TL" empty 'check="C25b"'
  cwant C25bctl && run_check C25bctl "C25b control: lugs 3 mm toward the chain (gap 2.4) must hit" nonempty 'check="C25bctl"'
  cwant C25c && run_check C25c "C25c TL fixture: hanging weight clear of bench, vise, stand" empty 'check="C25c"'
  cwant C25d && run_check C25d "C25d TL fixture: TL bore over the stub, TL clear of the vise" empty 'check="C25d"'
  cwant C25dctl && run_check C25dctl "C25d control: stub 0.5 mm off-axis must hit the TL bore" nonempty 'check="C25dctl"'
  cwant C25e && run_check C25e "C25e TL fixture: chain-end bolts + lever clear of stub, vise, bench, TL body" empty 'check="C25e"'
  cwant C25ectl && run_check C25ectl "C25e control: chain-end bolts 2 mm off their lever / lug holes must hit" nonempty 'check="C25ectl"'
  cwant C25f && run_check C25f "C25f TL fixture, balanced position: lever, lugs, chain-end bolts, hanging weight ^ vise, stand, bench, stub (pivot bore on the pin), TL350, key" empty 'check="C25f"'
  cwant C25fctl && run_check C25fctl "C25f control: lever 0.5 mm off the pin axis must hit the pin" nonempty 'check="C25fctl"'
  cwant C25g && run_check C25g "C25g TL fixture: lever 1 mm nearer than its 5 mm gap is still clear of the adjusting nut" empty 'check="C25g"'
  cwant C25gctl && run_check C25gctl "C25g control: lever 6 mm nearer hits the nut" nonempty 'check="C25gctl"'
  # C27: hold-down against the chain uplift (top angles, foot angles, bolts, floor anchors); C28: gearbox output shaft, circlip, spacer - TL - collar retention, keyways, overhang
  cwant C27a && run_check C27a "C27a top + foot angles (sit 0.01 off every face) ^ deck, legs, rails, tensioner base, motor, floor, belt guard" empty 'check="C27a"'
  cwant C27actl && run_check C27actl "C27a control: top angles 0.5 mm up hit the deck" nonempty 'check="C27actl"'
  cwant C27b && run_check C27b "C27b hold-down bolts / washers / nuts / anchors ^ deck, legs, angles, floor, rails (shanks Ø8 in Ø9 holes)" empty 'check="C27b"'
  cwant C27bctl && run_check C27bctl "C27b control: all hold-down hardware 2 mm sideways must hit" nonempty 'check="C27bctl"'
  cwant C27c && run_check C27c "C27c angles + hold-down hardware ^ gearbox, shaft, TL, motor, belt, tensioner, building, drive guard" empty 'check="C27c"'
  cwant C27d && run_check C27d "C27d hold-down counts: 8 anchors, 8 + 8 + 8 angle bolts, 4 rail bolts (echoes the anchor positions)" empty 'check="C27d"'
  cwant C28a && run_check C28a "C28a output shaft Ø25 ^ hollow hub, TL bore, spacer, collar, circlip (all seated)" empty 'check="C28a"'
  cwant C28b && run_check C28b "C28b circlip lies on the housing's far face (0.05 further = in the housing)" nonempty 'check="C28b"'
  cwant C28bctl && run_check C28bctl "C28b control: circlip 0.4 mm off the face: no contact" empty 'check="C28bctl"'
  cwant C28c1 && run_check C28c1 "C28c spacer on the housing face (0.04 further in = overlap)" nonempty 'check="C28c1"'
  cwant C28c2 && run_check C28c2 "C28c TL hub on the spacer" nonempty 'check="C28c2"'
  cwant C28c3 && run_check C28c3 "C28c stop collar on the TL hub's outboard end" nonempty 'check="C28c3"'
  cwant C28cctl && run_check C28cctl "C28c control: TL 0.5 mm off the spacer: no contact" empty 'check="C28cctl"'
  cwant C28d && run_check C28d "C28d gearbox keyway 8 x 4 is cut in the shaft inside the hollow hub" empty 'check="C28d"'
  cwant C28dctl && run_check C28dctl "C28d control: 3 mm before the hub's end the shaft is solid" nonempty 'check="C28dctl"'
  cwant C28e && run_check C28e "C28e TL keyway 8 x 4 is cut in the shaft under the TL hub" empty 'check="C28e"'
  cwant C28ectl && run_check C28ectl "C28e control: beyond the TL keyway the shaft is solid" nonempty 'check="C28ectl"'
  cwant C28f && run_check C28f "C28f shaft length = far circlip + hub + gap + TL + collar + 3" empty 'check="C28f"'
  cwant C28fctl && run_check C28fctl "C28f control: a shaft 1 mm short fails the assert" error 'check="C28fctl"'
  cwant C28g && run_check C28g "C28g chain plane = housing face + TL_GB_GAP + TL_CM_OFFSET = shaft A's sprocket plane (GB_OHL_ARM)" empty 'check="C28g"'
  cwant C28gctl && run_check C28gctl "C28g control: a 1 mm wrong overhang fails the assert" error 'check="C28gctl"'
  cwant C28h && run_check C28h "C28h TL350, collar and shaft end stay outside the cabinet (x < -30) with the guard" empty 'check="C28h"'
  # C26: design asserts (chain plane, belt height, wraps)
  cwant C26a1 && run_check C26a1 "C26a sprocket A's tooth plate is cut by the chain-plane slab" nonempty 'check="C26a1"'
  cwant C26a2 && run_check C26a2 "C26a the TL350's tooth plate is cut by the chain-plane slab" nonempty 'check="C26a2"'
  cwant C26a3 && run_check C26a3 "C26a the idler's tooth plate is cut by the chain-plane slab" nonempty 'check="C26a3"'
  cwant C26a4 && run_check C26a4 "C26a the chain is cut by the chain-plane slab" nonempty 'check="C26a4"'
  cwant C26actl && run_check C26actl "C26a control: a slab 14 mm behind the chain plane cuts none of them" empty 'check="C26actl"'
  cwant C26b && run_check C26b "C26b motor axis height = worm axis height (belt horizontal)" empty 'check="C26b"'
  cwant C26bctl && run_check C26bctl "C26b control: a motor 5 mm lower fails the assert" error 'check="C26bctl"'
  cwant C26c && run_check C26c "C26c wrap angle on sprocket A is between 120 and 180 deg" empty 'check="C26c"'
  cwant C26d && run_check C26d "C26d the idler is inside the loop and pushes the slack run outward" empty 'check="C26d"'
  cwant C26dctl && run_check C26dctl "C26d control: an idler 30 mm too far in does not push the run out (assert fails)" error 'check="C26dctl"'
  cwant C26e && run_check C26e "C26e the drive deck is outside the cabinet (x < -30) and below it" empty 'check="C26e"'
  cwant C8b && run_check C8b "C8b belt guard ^ deck, base plate, tensioner (feet touch the deck)" empty 'check="C8b"'
  cwant C8c && run_check C8c "C8c belt guard ^ gearbox housing, flange, rails (face contact only)" empty 'check="C8c"'
  cwant C8d && run_check C8d "C8d belt guard ^ pulleys, belt, motor" empty 'check="C8d"'
  cwant C8ctl && run_check C8ctl "C8 control: gearbox housing moved 0.5 mm into the belt guard (must hit)" nonempty 'check="C8ctl"'
  cwant C8e && run_check C8e "C8e belt guard half A ^ half B (0.3 mm lap clearance; end faces touch)" empty 'check="C8e"'
  cwant C8ectl && run_check C8ectl "C8e control: half B moved 0.5 mm up into half A (must hit)" nonempty 'check="C8ectl"'
  cwant C9a && run_check C9a "C9a cabinet shell (sides, back, floor, closed drawer front) has no gap >= 4 mm" empty 'check="C9a"'
  cwant C9actl && run_check C9actl "C9a control: drawer front with a Ø16 hole (must show)" nonempty 'check="C9actl"'
  cwant C9actl2 && run_check C9actl2 "C9a control: fixed upper front panel with a Ø16 hole (must show)" nonempty 'check="C9actl2"'
  # C30: the fixed upper front panel: with the drawer (front + bin) removed the space above the grid stays closed to the outside
  cwant C30a && run_check C30a "C30a drawer REMOVED: the cabinet shell's free space eroded by a 4 mm cube is empty from the lower cleats' underside (z >= GRID_ZL) up: nothing >= 4 mm leads to the space above the mesh" empty 'check="C30a"'
  cwant C30actl && run_check C30actl "C30a control: the fixed panel's bottom edge raised 30 mm leaves an opening above the mesh underside (must show)" nonempty 'check="C30actl"'
  cwant C30actl2 && run_check C30actl2 "C30a control: no fixed panel at all (the old open front) must show" nonempty 'check="C30actl2"'
  cwant C30a2 && run_check C30a2 "C30a2 drawer REMOVED: the opening IS there, under the lower cleats (the test can see it): non-empty" nonempty 'check="C30a2"'
  cwant C30b && run_check C30b "C30b no 4 mm cube fits between the fixed panel's back face and the front rail (z GRID_ZL .. top of the upper cleats)" empty 'check="C30b"'
  cwant C30bctl && run_check C30bctl "C30b control: grid set 6 mm further back leaves a 7 mm slot (must show)" nonempty 'check="C30bctl"'
  cwant C30c && run_check C30c "C30c the fixed panel's top edge touches the base plate (0.04 further up = overlap: no gap)" nonempty 'check="C30c"'
  cwant C30cctl && run_check C30cctl "C30c control: panel 0.46 mm below the base plate: no contact" empty 'check="C30cctl"'
  cwant C30d && run_check C30d "C30d the fixed panel's back face touches the side panels' front edges (0.04 further back = overlap: no gap)" nonempty 'check="C30d"'
  cwant C30dctl && run_check C30dctl "C30d control: panel 0.46 mm forward of the side panels: no contact" empty 'check="C30dctl"'
  cwant C30e && run_check C30e "C30e drawer (front, bin, handle) closed and pulled out 0 .. 180 mm clears the fixed panel" empty 'check="C30e"'
  cwant C30ectl && run_check C30ectl "C30e control: drawer raised 1.5 mm (of its 1 mm gap) hits the fixed panel" nonempty 'check="C30ectl"'
  cwant C30f && run_check C30f "C30f fixed panel bottom <= underside of the lower grid cleats; drawer front 1 mm under it and above the bin top (asserts)" empty 'check="C30f"'
  cwant C30fctl && run_check C30fctl "C30f control: a fixed panel 30 mm higher fails the assert" error 'check="C30fctl"'
  cwant C10a && run_check C10a "C10a drawer closed: actuator blade >= 10 mm into the switch head slot" nonempty 'check="C10a"' travel=0
  cwant C10actl && run_check C10actl "C10a control: drawer 3 mm open: blade only 9 mm in (must NOT reach 10)" empty 'check="C10a"' travel=3
  cwant C10b && run_check C10b "C10b the whole actuator clears the switch (slot walls included) over the drawer travel 0 .. 15 mm" empty 'check="C10b"'
  cwant C10bctl && run_check C10bctl "C10b control: actuator 1.4 mm sideways (blade 3 in a 5 slot) must hit the slot wall" nonempty 'check="C10bctl"'
  cwant C10c && run_check C10c "C10c drawer 12 mm open (spec <= INTERLOCK_OUT_TRAVEL = 15): blade completely out of the switch head" empty 'check="C10c"' travel=12
  cwant C10cctl && run_check C10cctl "C10c control: drawer 5 mm open: blade still in the switch (must hit)" nonempty 'check="C10c"' travel=5
  cwant C10d && run_check C10d "C10d actuator, its pad and screws clear pad, switch, cabinet and base plate" empty 'check="C10d"'
  for h in 0 1; do
    cwant "C11feet_$h" && run_check "C11feet_$h" "C11 belt guard half $h: feet touch the deck top (0.01 nudge overlaps)" nonempty 'check="C11feet"' "half=$h"
  done
  cwant C11lap && run_check C11lap "C11 lap >= 15 mm: halves overlap at u = 125.5 (16 mm lap, 15.5 mm from A's end)" nonempty 'check="C11lap"' u0=125.4 u1=125.6
  cwant C11lapctl && run_check C11lapctl "C11 lap control: no overlap at u = 124.4, outside the lap" empty 'check="C11lap"' u0=124.2 u1=124.6
  # C14: blade torque test lever (pin on the straight hook face, lever clear of blade / vise / shaft)
  cwant C14a && run_check C14a "C14a test pin ^ blade (pin tangent to the hook face, no overlap)" empty 'check="C14a"'
  cwant C14actl && run_check C14actl "C14a control: pin 0.3 mm into the hook face (must hit)" nonempty 'check="C14actl"'
  cwant C14b && run_check C14b "C14b test pin within 0.2 mm of the straight hook face (0.2 mm closer = overlap on the face strip)" nonempty 'check="C14b"'
  cwant C14bctl && run_check C14bctl "C14b control: pin 0.3 mm off the face, same 0.2 mm test (must stay clear)" empty 'check="C14bctl"'
  cwant C14c && run_check C14c "C14c test pin swept 0..15 deg back off the face ^ blade (pin backs off freely)" empty 'check="C14c"'
  cwant C14cctl && run_check C14cctl "C14c control: blade turned 1 deg onto the pin (must hit)" nonempty 'check="C14cctl"'
  cwant C14d && run_check C14d "C14d test lever ^ blade (1.0 mm face gap)" empty 'check="C14d"'
  cwant C14dctl && run_check C14dctl "C14d control: lever 1.6 mm toward the blade (must hit)" nonempty 'check="C14dctl"'
  cwant C14e && run_check C14e "C14e test lever + pin ^ vise block" empty 'check="C14e"'
  cwant C14ectl && run_check C14ectl "C14e control: lever 30 mm toward the vise (must hit)" nonempty 'check="C14ectl"'
  cwant C14f && run_check C14f "C14f test blade ^ vise block" empty 'check="C14f"'
  cwant C14g && run_check C14g "C14g test blade hex bore ^ shaft hex (test orientation)" empty 'check="C14g"'
  cwant C14gctl && run_check C14gctl "C14g control: shaft turned 30 deg (must hit)" nonempty 'check="C14gctl"'
  cwant C14h && run_check C14h "C14h test lever + pin ^ shaft (Ø25.2 hole on the Ø25 journal)" empty 'check="C14h"'
  cwant C14hctl && run_check C14hctl "C14h control: lever 0.5 mm off-axis (must hit the journal)" nonempty 'check="C14hctl"'
  # C16: joint alignment: a shank through BOTH holes of a joint touches neither part; control = shanks 4 mm off in six directions must hit
  for jn in foot hang dleg bgfoot gbfoot subbolt topdeck topleg footleg anchor tbase taxle0 taxlep taxlem gseam gcapd gcapf handle dsw dpad dact dactpad hsw hact hlid gcl uftop ufface; do
    cwant "C16_$jn" && run_check "C16_$jn" "C16 joint $jn: shank through the holes of both parts touches neither" empty 'check="C16"' "joint=\"$jn\""
    cwant "C16ctl_$jn" && run_check "C16ctl_$jn" "C16 control, joint $jn: shanks moved 4 mm (6 directions, union) must hit" nonempty 'check="C16ctl"' "joint=\"$jn\""
  done
  # C17: hopper lid interlock
  cwant C17a && run_check C17a "C17a lid down: actuator blade >= 10 mm into the switch head slot" nonempty 'check="C17a"'
  cwant C17actl && run_check C17actl "C17a control: lid 3 deg up: blade less than 10 mm in (must be empty)" empty 'check="C17actl"'
  cwant C17b && run_check C17b "C17b the whole actuator clears the switch (slot walls, screws) for every lid angle 0 .. 12 deg" empty 'check="C17b"'
  cwant C17bctl && run_check C17bctl "C17b control: actuator sideways by the slot play + 0.4 mm (1.9 mm: 3 mm tongue in the 6 mm slot) must hit the slot wall" nonempty 'check="C17bctl"'
  cwant C17c && run_check C17c "C17c lid 9 deg up (tip travel 16 mm): blade completely out of the switch" empty 'check="C17c"'
  cwant C17cctl && run_check C17cctl "C17c control: lid 3 deg up: blade still in the switch (must hit)" nonempty 'check="C17cctl"'
  cwant C17d && run_check C17d "C17d lid pad, actuator, screws clear of funnel, collar, switch, hinge pin for lid angles 0 .. 12 deg" empty 'check="C17d"'
  # C29: the fixed safety grid (base.scad)
  cwant C29a && run_check C29a "C29a grid top z = -170: the blade-tip envelopes (both shafts) moved 120 mm down miss the mesh (mesh top >= 120 mm under the lowest blade tip); the assert is in the same run" empty 'check="C29a"'
  cwant C29actl && run_check C29actl "C29a control: envelopes moved 140 down (= a mesh 20 mm too high) hit the mesh" nonempty 'check="C29actl"'
  cwant C29actl2 && run_check C29actl2 "C29a control: a grid 40 mm higher fails the 120 mm assert" error 'check="C29actl2"'
  cwant C29b && run_check C29b "C29b Ø16 finger probes through EVERY cell, pushed up to 120 mm above the mesh, do not reach the blade-tip envelopes" empty 'check="C29b"'
  cwant C29bctl && run_check C29bctl "C29b control: probes 25 mm longer reach the blades" nonempty 'check="C29bctl"'
  cwant C29b2 && run_check C29b2 "C29b2 INFORMATION: a Ø16 finger in the middle of a cell touches no wire (passes the mesh): the protection is the 120 mm distance, not the mesh" empty 'check="C29b2"'
  cwant C29b2ctl && run_check C29b2ctl "C29b2 control: a probe 2 mm wider than the clear opening is stopped by the wires" nonempty 'check="C29b2ctl"'
  cwant C29h && run_check C29h "C29h no Ø30 disc fits in any opening of the mesh plan (largest clear opening < 30 mm)" empty 'check="C29h"'
  cwant C29hctl && run_check C29hctl "C29h control: a Ø16 disc does fit in the cells" nonempty 'check="C29hctl"'
  cwant C29g && run_check C29g "C29g no wire above GRID_Z" empty 'check="C29g"'
  cwant C29gctl && run_check C29gctl "C29g control: the wires do reach GRID_Z" nonempty 'check="C29gctl"'
  cwant C29c1 && run_check C29c1 "C29c grid mesh + both cleat sets (shrunk 0.01 where they touch) clear of the cabinet panels (sides, back, floor), drawer front, base plate, skirts" empty 'check="C29c1"'
  cwant C29c1ctl && run_check C29c1ctl "C29c control: grid 3 mm toward the drive-end wall hits it" nonempty 'check="C29c1ctl"'
  cwant C29c2 && run_check C29c2 "C29c bin + drawer front + handle closed and pulled out 0 .. 180 mm (raised by 3.9 mm of its 4.1 clearance) clear of the grid and cleats" empty 'check="C29c2"'
  cwant C29c2ctl && run_check C29c2ctl "C29c control: the drawer raised 4.5 mm hits the lower cleats" nonempty 'check="C29c2ctl"'
  cwant C29c3ctl && run_check C29c3ctl "C29c control: the old 250 high bin (top 100 higher) hits the grid" nonempty 'check="C29c3ctl"'
  cwant C29d && run_check C29d "C29d no 10 mm cube fits between the cut sheet and the cabinet walls (edge gap < 10 mm)" empty 'check="C29d"'
  cwant C29dctl && run_check C29dctl "C29d control: a sheet 12 mm smaller each side leaves room for the 10 mm cube" nonempty 'check="C29dctl"'
  cwant C29e && run_check C29e "C29e mesh clear opening (pitch - wire) <= 30 mm" empty 'check="C29e"'
  cwant C29ectl && run_check C29ectl "C29e control: a 40 mm pitch mesh fails the assert" error 'check="C29ectl"'
  cwant C4 && run_check C4 "C4 all sleeves (clamp + collared) ^ inner/outer/cap layers, both ends (the new bores)" empty 'check="C4"'
  cwant C4ctl && run_check C4ctl "C4 control: sleeves shifted 3 mm in y (must hit)" nonempty 'check="C4ctl"'
  NAMES=(comb_A comb_B wall_A wall_B drive_inner drive_outer drive_cap free_inner free_outer free_cap)
  for i in 0 1 2 3 4 5 6 7 8 9; do
    for j in 0 1 2 3 4 5 6 7 8 9; do
      [ "$j" -gt "$i" ] || continue
      id="C5_${NAMES[$i]}__${NAMES[$j]}"
      cwant "$id" && run_check "$id" "C5 ${NAMES[$i]} ^ ${NAMES[$j]}" empty 'check="C5"' "a=$i" "b=$j"
    done
  done
  # new static parts (a) against the combs / walls / plate layers (b, shrunk); touching faces allowed
  NEW=(collar funnel lid skirt_A skirt_B dg_upper dg_lower free_cover base_plate lid_pad drawer_pad drawer_act_pad drive_deck gb_mount tens_upright tens_base grid_mesh grid_cleats_low grid_cleats_up upper_front)
  NN=$(( ${#NEW[@]} - 1 ))
  for n in $(seq 0 $NN); do
    for j in 0 1 2 3 4 5 6 7 8 9; do
      id="C5_${NEW[$n]}__${NAMES[$j]}"
      cwant "$id" && run_check "$id" "C5 ${NEW[$n]} ^ ${NAMES[$j]}" empty 'check="C5"' "a=$((n+10))" "b=$j"
    done
  done
  for n in $(seq 0 $NN); do
    for m in $(seq 0 $NN); do
      [ "$m" -gt "$n" ] || continue
      id="C5_${NEW[$n]}__${NEW[$m]}"
      cwant "$id" && run_check "$id" "C5 ${NEW[$n]} ^ ${NEW[$m]}" empty 'check="C5"' "a=$((n+10))" "b=$((m+10))"
    done
  done
  cwant C5ctl && run_check C5ctl "C5 control: comb B moved 0.5 mm into the drive inner layer (must hit)" nonempty 'check="C5ctl"'
  cwant C5ctl2 && run_check C5ctl2 "C5 control: comb B moved only 0.05 mm into the drive inner layer (must hit)" nonempty 'check="C5ctl2"'

  {
    echo "Interference checks ($(date '+%Y-%m-%d %H:%M')), OpenSCAD $("$OPENSCAD" --version 2>&1)"
    echo "A check passes when the intersection is EMPTY (log has 'Current top level object is empty.')."
    echo "Controls (ctl) must be NON-empty: they prove each test can see an overlap."
    echo "C5: exactly touching faces make manifold return a zero-thickness sheet, so the 2nd operand of each pair is"
    echo "    shrunk by 0.01 mm per side (about its bounding-box centre); overlaps > 0.01 mm are still detected (C5ctl2)."
    echo
    printf '%s\n' "${RESULTS[@]}"
    echo
    echo "checks run: ${#RESULTS[@]}, failed: $(printf '%s\n' "${RESULTS[@]}" | grep -c '^FAIL')"
    [ -f logs/ligament.txt ] && { echo; echo "--- hole ligament ---"; cat logs/ligament.txt; }
  } > "$CHK"
  echo "   $(printf '%s\n' "${RESULTS[@]}" | grep -c '^PASS') passed, $(printf '%s\n' "${RESULTS[@]}" | grep -c '^FAIL') failed -> $CHK"
  [ "$cfail" = 0 ] || fail=1
fi

[ "$fail" = 0 ] && echo "ALL OK (no warnings, all checks passed)" || echo "DONE WITH WARNINGS/ERRORS/FAILED CHECKS (see logs/)"
exit "$fail"
