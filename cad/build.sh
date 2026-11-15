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
VARIANT_PATTERNS="C2 C5 C16 C17 C20 C21 C23 C24 C26 C27 C28 C31 C32 C35 C40 C41 C42"      # make variants: C2 envelopes (incl. the guards), C5 pairs, C16 joint alignment, C17 lid interlock, C20 bearings, C21 sprocket, C22 chain, C23 drive vs deck, C24 guard, C26 chain plane / coaxial motor, C27 hold-down, C28 output shaft, C40 screen, C41 coupling guard
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
part ob_sleeve       sleeve.scad 'kind="ob_sleeve"'
part ob_sleeve_A     sleeve.scad 'kind="ob_sleeve_A"'
part plate_ob1       plate.scad  'kind="ob1"'
part plate_ob2       plate.scad  'kind="ob2"'
part standoff        plate.scad  'kind="standoff"'
part comb_A          comb.scad   'sh="A"'
part comb_B          comb.scad   'sh="B"'
part wall            wall.scad
part end_cap         smallparts.scad 'part="end_cap"'
part gear_A          gear.scad   'part="gear"'
part gear_B          gear.scad   'part="gear_B"'
part output_shaft    drive.scad  'part="output_shaft"'
part pin_flange      drive.scad  'part="pin_flange"'               # 6061, lathe
# printed guards / hopper (PETG, MK3S 250 x 210 x 210): print pose, flat face down
part hopper_collar   hopper.scad 'part="collar"'
part hopper_funnel   hopper.scad 'part="funnel"'
part hopper_lid      hopper.scad 'part="lid"'
part hopper_lid_pad  hopper.scad 'part="lid_act_pad"'
part dg_upper        guards.scad 'part="dg_upper"'
part dg_lower        guards.scad 'part="dg_lower"'
part free_end_cover  guards.scad 'part="free_end_cover"'
part gear_band       guards.scad 'part="gear_band"'
part cpl_guard       drive.scad  'part="cpl_guard"'
part stub_cap        drive.scad  'part="stub_cap"'
# steel / plywood parts (3D reference models)
part base_plate      base.scad   'part="base_plate"'
part cabinet         base.scad   'part="cabinet"'
part screen          base.scad   'part="screen"'                # aluminium, CNC4030
part drive_deck      drive.scad  'part="drive_deck"'
part gb_rail         drive.scad  'part="gb_rail"'
part gb_spacer       drive.scad  'part="gb_spacer"'
part leg_angle       drive.scad  'part="leg_angle"'
# torque-limiter setting fixture (made parts)
part tl_stub         tlfix.scad  'part="stub"'
part tl_lever        tlfix.scad  'part="lever"'
part tl_lug          tlfix.scad  'part="lug"'
part test_lever      testlever.scad 'part="lever"'
# printed drawer parts (PETG)
part drawer_handle   base.scad   'part="drawer_handle"'

# printer-fit check: every printed part must fit 250 x 210 x 210 (and sit on z = 0)
if want fit || want hopper || want guard || want drawer || want dg_ || want cap || [ -z "$ONLY" ]; then
  echo "== printer fit (MK3S 250 x 210 x 210)"
  PRINTED=(); for n in hopper_collar hopper_funnel hopper_lid hopper_lid_pad dg_upper dg_lower gear_band free_end_cover cpl_guard stub_cap drawer_handle; do [ -f "stl/$n.stl" ] && PRINTED+=("stl/$n.stl"); done
  python3 fit.py 250 210 210 "${PRINTED[@]}" | tee logs/fit.txt || fail=1
fi

# ------------------------------------------------------------------ DXF
for v in 0 1 2 3; do dxf "blade_v$v" blade.scad "variant=$v" flat=true; done
dxf gear_profile gear.scad 'part="profile_2d"'          # the bought gear as modelled (teeth + the re-bored Ø25 + broached keyway), for reference
dxf comb_A comb.scad 'sh="A"' flat=true
dxf base_plate base.scad 'part="base_2d"'
dxf cabinet_panels base.scad 'part="cabinet_2d"'
dxf screen base.scad 'part="screen_2d"'                 # the screen: cross-section (top) and plan with the holes, the screws and the pockets (below)
dxf drive_deck drive.scad 'part="drive_deck_2d"'
dxf gb_rail drive.scad 'part="gb_rail_2d"'
dxf output_shaft drive.scad 'part="output_shaft_2d"'
dxf pin_flange drive.scad 'part="pin_flange_2d"'
dxf sprocket_drill drive.scad 'part="sprocket_drill_2d"'      # 1:1 drilling template for the TL350's sprocket plate (4 x Ø8.5 on PCD 101)
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
shotfix screen_section assembly.scad "66,0,-30,90,0,270,330" section_x=66.1 screen_dims=true show_hopper=false show_drive_side=false show_gearbox=false
shotfix section_x60   assembly.scad "$FRONT" section_x=60 show_hopper=false show_extras=false show_gearbox=false
shotfix hopper_section assembly.scad "66,0,140,90,0,270,1100" section_x=66.1 show_motor=false show_gearbox=false
shot drive_end_section assembly.scad "0,0,0,90,0,0,500" section_pair=true show_hopper=false show_gearbox=false show_combs_walls=false
shot drive_iso        assembly.scad "0,0,0,62,0,300,900" show_hopper=false drive_only=true ghost_guards=true deck_alpha=0.3
shot drive_tl         assembly.scad "0,0,0,62,0,130,900" show_hopper=false show_motor=false hide_guards=true deck_alpha=0.3 show_holddown=false 'clip=[-330,-115,-140,-36,75,80]'
shot drive_tl_section assembly.scad "0,0,0,60,0,200,900" show_hopper=false show_motor=false hide_guards=true deck_alpha=0.3 show_holddown=false 'clip=[-330,-115,-140,-36,-29.9,80]'
shot tl_setting       tlfix.scad    "0,0,0,62,0,195,900" labels=true 'cam=[62,0,195]'
shot blade_variants   previews.scad "0,0,0,0,0,0,600" 'scene="blade_variants"'
shot shaft_A          previews.scad "0,0,0,55,0,340,900" 'scene="shaft_A"'
shot shaft_B          previews.scad "0,0,0,55,0,340,900" 'scene="shaft_B"'
shot plate_layers     previews.scad "0,0,0,0,0,0,900" 'scene="plate_layers"'
shot comb_B           previews.scad "0,0,0,0,0,0,400" 'scene="comb_B"'
# the made gears: close-up of the mesh (view along the shafts, +y on the viewer's left) and one CNC layer with the finished tooth profile over it
shotfix gears_mesh    previews.scad "0,0,0,90,0,270,130" 'scene="gears_mesh"'
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
    cwant "C2_$s" && run_check "C2_$s" "C2 swept envelope of shaft $s blades+spacers ^ combs+walls+inner layers+collar+funnel+screen+drive-end guard+free-end cover" empty 'check="C2"' "sh=\"$s\""
    cwant "C2ctl_$s" && run_check "C2ctl_$s" "C2 control: shaft $s envelope with R_TIP+3 (must hit)" nonempty 'check="C2ctl"' "sh=\"$s\""
    for kk in 0 1 2 3 4 5 6 7; do
      cwant "C3_${s}_k$kk" && run_check "C3_${s}_k$kk" "C3 blade $kk of shaft $s ^ shaft $s (hex bore clears hex)" empty 'check="C3"' "sh=\"$s\"" "k=$kk"
    done
    cwant "C3x_$s" && run_check "C3x_$s" "C3x spacers+clamp sleeves+collared sleeves of shaft $s ^ shaft $s" empty 'check="C3x"' "sh=\"$s\""
    cwant "C3ctl_$s" && run_check "C3ctl_$s" "C3 control: blade 0 vs shaft $s turned 30 deg (must hit)" nonempty 'check="C3ctl"' "sh=\"$s\"" k=0
  done
  # C2g/C2c: rotating drive-end parts vs the drive-end guard; free-end collars / thrust / caps / heads vs the free-end cover (>= 3 mm)
  cwant C2g && run_check C2g "C2g gears, hubs, sleeves, collars, thrust bearings, the TL350 on A, end caps + M10 heads (A, B) grown 2.9 mm ^ gear band + hood (>= 3 mm clear)" empty 'check="C2g"'
  cwant C2gctl && run_check C2gctl "C2g control: gear band + hood 0.5 mm sideways (must hit)" nonempty 'check="C2gctl"'
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
  cwant C20a && run_check C20a "C20a 6 bearings (incl. the 2 outboard) + 4 seals + 4 thrust + 2 crinkle stacks ^ all plate layers" empty 'check="C20a"'
  cwant C20actl && run_check C20actl "C20a control: bearings shifted 3 mm in y (must hit the plates)" nonempty 'check="C20actl"'
  DN=(seal bearing_outer rollers inner_ring thrust clamp_sleeve collared_sleeve gear gear_spacer end_cap_screw sprocket_A ob_bearing_outer ob_rollers ob_inner_ring ob_sleeve)
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
  cwant C20s5 && run_check C20s5 "C20s outboard: bearing outer ring 0.05 mm toward the chamber overlaps ob1's step (held by it)" nonempty 'check="C20s5"'
  cwant C20s6 && run_check C20s6 "C20s outboard: bearing outer ring 0.05 mm outward overlaps ob2's step" nonempty 'check="C20s6"'
  cwant C20sctl && run_check C20sctl "C20s control: outer ring 0.45 mm off its shoulder: no overlap" empty 'check="C20sctl"'
  CDESC=("C20c1|drive inner ring touches the clamp sleeve" "C20c2|drive inner ring touches the collared sleeve" "C20c3|thrust bearing touches the collar" "C20c3b|thrust bearing touches the drive cap face"
         "C20c4|free inner ring touches the clamp sleeve" "C20c5|free inner ring touches the collared sleeve" "C20c6|crinkle stack touches the free cap face" "C20c7|free thrust bearing touches the crinkle stack"
         "C20c7b|free thrust bearing touches the free collar" "C20c8|gear touches the drive collar" "C20c9|inner sleeve touches the gear hub's outer face" "C20c10|the TL350 hub (nut end) touches shaft A's outer sleeve" "C20c14|outboard inner ring touches the inner sleeve" "C20c15|outboard inner ring touches the outer sleeve"
         "C20c11|end cap A sits on the TL350 hub (flange end)" "C20c12|end cap B sits on the outer sleeve" "C20c13|free end cap sits on the collar")
  for cd in "${CDESC[@]}"; do cwant "${cd%%|*}" && run_check "${cd%%|*}" "C20c contact: ${cd#*|} (0.04 mm further in = overlap, so the stack has no gap > 0.04 mm)" nonempty "check=\"${cd%%|*}\""; done
  cwant C20cctl && run_check C20cctl "C20c control: drive inner ring 0.46 mm away from the clamp sleeve: no contact" empty 'check="C20cctl"'
  cwant C20c3ctl && run_check C20c3ctl "C20c control: thrust bearing 0.46 mm off the collar: no contact" empty 'check="C20c3ctl"'
  # C21: the TL350 on A vs shaft B's parts
  cwant C21 && run_check C21 "C21 the TL350 on A (body Ø89 + its 30T tooth plate OD 127.7, swept, grown 4.9 mm) ^ shaft B's gear, hub, collar, thrust, end cap, M10 head: >= 5 mm clear" empty 'check="C21"'
  cwant C21ctl && run_check C21ctl "C21 control: the TL350 grown 11.5 mm hits B's parts" nonempty 'check="C21ctl"'
  # C31: the two bought gears in mesh through more than one tooth pitch (24 deg), 1 deg steps; controls: centre distance 0.3 short, no backlash + 0.5 deg offset, wrong tooth phase
  for ang in $(seq 0 1 25); do
    id=$(printf "C31_angle%02d" "$ang")
    cwant "$id" && run_check "$id" "C31 gear A ^ gear B (m4 z15 involute teeth, backlash), A turns -$ang deg, B +$ang deg" empty 'check="C31"' "angle=$ang"
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
    cwant "C32_angle$ang" && run_check "C32_angle$ang" "C32 both gears (angle $ang) ^ all plates (incl. the outboard plate), gear band + hood" empty 'check="C32"' "angle=$ang"
  done
  cwant C32s && run_check C32s "C32s gear B ^ the TL350 on A (body + tooth plate)" empty 'check="C32s"' 'angle=0'
  cwant C32ctl && run_check C32ctl "C32 control: gears 10 mm toward the plates (must hit)" nonempty 'check="C32ctl"'
  # C23: gearbox, TL, motor, coupling vs deck, cabinet, base ...
  cwant C23a && run_check C23a "C23a gearbox + worm + output shaft + spacer + pin flange + pins ^ plates, combs, screen, cabinet, base plate, drawer, deck, legs, motor" empty 'check="C23a"'
  cwant C23actl && run_check C23actl "C23a control: gearbox moved 300 mm toward the machine (must hit the cabinet)" nonempty 'check="C23actl"'
  cwant C23b && run_check C23b "C23b motor + its shaft + coupling ^ plates, cabinet, base plate, legs, gearbox, rails, pin flange, drive-end guard" empty 'check="C23b"'
  cwant C23c && run_check C23c "C23c deck (nudged 0.01: contact only) ^ motor foot, rails, coupling guard, stub cap, gearbox, coupling" empty 'check="C23c"'
  cwant C23cctl && run_check C23cctl "C23c control: deck raised 3 mm (must hit the motor foot and the rails)" nonempty 'check="C23cctl"'
  cwant C23d && run_check C23d "C23d deck + legs ^ building, gearbox, rails, pin flange, drive-end guard" empty 'check="C23d"'
  cwant C23e && run_check C23e "C23e gearbox foot bolts, rail bolts + nuts ^ flange, housing, rails, deck (seated 0.01)" empty 'check="C23e"'
  cwant C23ectl && run_check C23ectl "C23e control: bolts moved 3 mm in x (must hit the plates)" nonempty 'check="C23ectl"'
  # C24: drive-end guard
  cwant C24a && run_check C24a "C24a drive-end guard ^ every moving part grown 2.9 mm (gears, hubs, collars, thrust, caps, heads, the TL350 + its plate, pins, pin flange, spacer, free-end parts): >= 3 mm clear" empty 'check="C24a"'
  cwant C24actl && run_check C24actl "C24a control: parts grown 3.5 mm hit the guard" nonempty 'check="C24actl"'
  cwant C24b && run_check C24b "C24b guard ^ gearbox, worm shaft, rails, deck, legs, coupling guard, stub cap, motor, coupling, cabinet, base plate, tie-screw hardware" empty 'check="C24b"'
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
  # C27: hold-down (top angles, foot angles, bolts, floor anchors); C28: gearbox output shaft, circlip, spacer - pin flange retention, keyways
  cwant C27a && run_check C27a "C27a top + foot angles (sit 0.01 off every face) ^ deck, legs, rails, motor, floor, coupling guard, stub cap" empty 'check="C27a"'
  cwant C27actl && run_check C27actl "C27a control: top angles 0.5 mm up hit the deck" nonempty 'check="C27actl"'
  cwant C27b && run_check C27b "C27b hold-down bolts / washers / nuts / anchors ^ deck, legs, angles, floor, rails (shanks Ø8 in Ø9 holes)" empty 'check="C27b"'
  cwant C27bctl && run_check C27bctl "C27b control: all hold-down hardware 2 mm sideways must hit" nonempty 'check="C27bctl"'
  cwant C27c && run_check C27c "C27c angles + hold-down hardware ^ gearbox, shaft, pin flange, motor, coupling, guards, building, drive guard" empty 'check="C27c"'
  cwant C27d && run_check C27d "C27d hold-down counts: 8 anchors, 8 + 8 + 8 angle bolts, 4 rail bolts (echoes the anchor positions)" empty 'check="C27d"'
  cwant C28a && run_check C28a "C28a output shaft Ø25 ^ hollow hub, the pin flange's bore, spacer, circlip (all seated)" empty 'check="C28a"'
  cwant C28b && run_check C28b "C28b circlip lies on the housing's far face (0.05 further = in the housing)" nonempty 'check="C28b"'
  cwant C28bctl && run_check C28bctl "C28b control: circlip 0.4 mm off the face: no contact" empty 'check="C28bctl"'
  cwant C28c1 && run_check C28c1 "C28c spacer on the housing face (0.04 further in = overlap)" nonempty 'check="C28c1"'
  cwant C28c2 && run_check C28c2 "C28c the pin flange's hub on the spacer" nonempty 'check="C28c2"'
  cwant C28cctl && run_check C28cctl "C28c control: flange 0.5 mm off the spacer: no contact" empty 'check="C28cctl"'
  cwant C28d && run_check C28d "C28d gearbox keyway 8 x 4 is cut in the shaft inside the hollow hub" empty 'check="C28d"'
  cwant C28dctl && run_check C28dctl "C28d control: 3 mm before the hub's end the shaft is solid" nonempty 'check="C28dctl"'
  cwant C28e && run_check C28e "C28e pin-flange keyway 8 x 4 is cut in the shaft under the flange's bore" empty 'check="C28e"'
  cwant C28ectl && run_check C28ectl "C28e control: beyond the flange keyway the shaft is solid" nonempty 'check="C28ectl"'
  cwant C28f && run_check C28f "C28f shaft length = far circlip + hub + spacer + the flange's bore - 1" empty 'check="C28f"'
  cwant C28fctl && run_check C28fctl "C28f control: a shaft 1 mm short fails the assert" error 'check="C28fctl"'
  # C26: design asserts (coaxial motor, deck position)
  cwant C26b && run_check C26b "C26b the motor is coaxial with the worm (x and z of the axes equal)" empty 'check="C26b"'
  cwant C26bctl && run_check C26bctl "C26b control: a motor 5 mm lower fails the assert" error 'check="C26bctl"'
  cwant C26e && run_check C26e "C26e the drive deck is outside the cabinet (x < -30) and below it" empty 'check="C26e"'
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
  for jn in foot hang dleg cgfoot gbfoot subbolt topdeck topleg footleg anchor gseam gcapd gcapf handle hsw hact hlid screen hood; do
    cwant "C16_$jn" && run_check "C16_$jn" "C16 joint $jn: shank through the holes of all its parts touches none" empty 'check="C16"' "joint=\"$jn\""
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
  # C40: the FIXED SCREEN; C41: the coupling guard and the stub cap
  cwant C40a && run_check C40a "C40a the screen is 2 mm under the blade-tip circles: both swept blade envelopes grown 1.9 mm miss it" empty 'check="C40a"'
  cwant C40actl && run_check C40actl "C40a control: grown 2.3 mm they hit it" nonempty 'check="C40actl"'
  cwant C40b && run_check C40b "C40b screen (0.01 off the combs) ^ combs, walls, all plate layers, base plate, cabinet, wall-screw heads, drawer closed and pulled out 0 .. 180" empty 'check="C40b"'
  cwant C40bctl && run_check C40bctl "C40b control: screen 0.5 mm up is in the combs" nonempty 'check="C40bctl"'
  cwant C40c && run_check C40c "C40c the wings bear on the combs' underside (0.04 further up = overlap)" nonempty 'check="C40c"'
  cwant C40cctl && run_check C40cctl "C40c control: 0.46 mm lower: no contact" empty 'check="C40cctl"'
  cwant C40d && run_check C40d "C40d plan under the chamber (inside the walls): no opening of 5.2 mm or more except the Ø5 holes (end gaps 0.5)" empty 'check="C40d"'
  cwant C40dctl && run_check C40dctl "C40d control: Ø5.6 holes are seen by the same test" nonempty 'check="C40dctl"'
  cwant C40e && run_check C40e "C40e every screen hole lies over the drawer bin, 2 mm inside its walls" empty 'check="C40e"'
  cwant C40ectl && run_check C40ectl "C40e control: a bin 28 mm smaller each side misses holes" nonempty 'check="C40ectl"'
  cwant C40f && run_check C40f "C40f a socket key reaches the 4 counterbores from below: nothing of the base plate or the cabinet under them" empty 'check="C40f"'
  cwant C40fctl && run_check C40fctl "C40f control: screws 12 mm further out are under the base plate" nonempty 'check="C40fctl"'
  cwant C40g && run_check C40g "C40g asserts: shortest hole + gap >= 5 mm (ISO 13857, round openings 4 < e <= 6); the screen comes out through the drawer opening" empty 'check="C40g"'
  cwant C40gctl && run_check C40gctl "C40g control: a 25 mm requirement fails the assert" error 'check="C40gctl"'
  cwant C41a && run_check C41a "C41a coupling, bare motor shaft, unused worm stub grown 2.9 mm ^ coupling guard + stub cap (>= 3 mm clear)" empty 'check="C41a"'
  cwant C41actl && run_check C41actl "C41a control: grown 3.5 mm they hit" nonempty 'check="C41actl"'
  cwant C41b && run_check C41b "C41b coupling guard + stub cap (0.01 up) ^ motor, gearbox, rails, deck, legs, drive-end guard, bolts" empty 'check="C41b"'
  cwant C41bctl && run_check C41bctl "C41b control: guard 3 mm toward the motor hits it" nonempty 'check="C41bctl"'
  cwant C41c && run_check C41c "C41c the guards' feet stand on the deck (0.01 lower = overlap)" nonempty 'check="C41c"'
  # C42: the pin coupling (pin flange on the coaxial gearbox output, 4 pins through the TL350's drilled sprocket plate)
  cwant C42a && run_check C42a "C42a pins grown 1.5 mm radially ^ the TL350's body (flange, pack, pressure plate, springs, nut, hub): >= 1.5 mm clear" empty 'check="C42a"'
  cwant C42actl && run_check C42actl "C42a control: pins grown 2.5 mm hit the TL350's body" nonempty 'check="C42actl"'
  cwant C42b && run_check C42b "C42b pins in the 4 holes drilled in the sprocket plate (0.25 play)" empty 'check="C42b"'
  cwant C42bctl && run_check C42bctl "C42b control: pins 0.3 mm sideways hit the hole walls" nonempty 'check="C42bctl"'
  cwant C42c && run_check C42c "C42c asserts: pins >= 1.5 outside the TL body, holes >= 1.5 inside the plate band (body .. tooth root), pin tips >= 1 past the plate (echoes the margins)" empty 'check="C42c"'
  cwant C42cctl && run_check C42cctl "C42c control: a 3 mm band margin fails the assert" error 'check="C42cctl"'
  cwant C42d && run_check C42d "C42d pin flange ^ the TL350 (drilled plate), A's end cap + M10 head, shaft A" empty 'check="C42d"'
  cwant C42dctl && run_check C42dctl "C42d control: flange 2.1 mm toward A is in the TL's flange end" nonempty 'check="C42dctl"'
  cwant C42e && run_check C42e "C42e pin flange + output shaft ^ A's end cap + M10 head grown 1.9 mm (pocket 3 mm round the cap, the shaft end 3 mm past the head)" empty 'check="C42e"'
  cwant C42ectl && run_check C42ectl "C42e control: cap + head grown 3.1 mm reach the pocket wall and the shaft end" nonempty 'check="C42ectl"'
  cwant C42g && run_check C42g "C42g the gearbox output is coaxial with shaft A (y, z)" empty 'check="C42g"'
  cwant C42gctl && run_check C42gctl "C42g control: an output 1 mm off fails the assert" error 'check="C42gctl"'
  # C35: the outboard bearing plate, standoffs, gear band
  cwant C35a && run_check C35a "C35a standoffs (0.01 short each end) clear of everything but the faces they are clamped to" empty 'check="C35a"'
  cwant C35actl && run_check C35actl "C35a control: standoffs 0.02 longer overlap the cap and ob1 (they bear on both faces)" nonempty 'check="C35actl"'
  cwant C35b && run_check C35b "C35b the hood butts on ob2's outer face (0.01 off: no overlap)" empty 'check="C35b"'
  cwant C35bctl && run_check C35bctl "C35b control: hood 0.5 mm toward the machine is in the plate" nonempty 'check="C35bctl"'
  cwant C35c && run_check C35c "C35c the gear band (0.3 from the cap and ob1, round the standoffs) clear of plates, standoffs, hood, hopper, base, screen, combs" empty 'check="C35c"'
  cwant C35cctl && run_check C35cctl "C35c control: band 0.5 mm toward the cap hits it" nonempty 'check="C35cctl"'
  cwant C35d && run_check C35d "C35d gear hubs, sprocket hub, B's end cap grown 1.9 mm clear of the outboard plate (gap 2)" empty 'check="C35d"'
  cwant C35dctl && run_check C35dctl "C35d control: grown 2.2 they reach it" nonempty 'check="C35dctl"'
  cwant C35f && run_check C35f "C35f the M8 tie screws' hardened washers + heads clear the printed hood (the preload is through steel only)" empty 'check="C35f"'
  cwant C35fctl && run_check C35fctl "C35f control: washers 2 mm bigger reach the hood wing" nonempty 'check="C35fctl"'
  cwant C35e && run_check C35e "C35e outboard plate, standoffs, gear band clear of the deck, gearbox, pin flange, motor, coupling, guards" empty 'check="C35e"'
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
  NEW=(collar funnel lid screen dg_upper dg_lower free_cover base_plate lid_pad drive_deck gb_mount cpl_guard stub_cap)
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
