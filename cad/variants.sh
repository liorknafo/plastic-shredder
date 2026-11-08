#!/usr/bin/env bash
# variants.sh -- `make variants`: does the CAD still fit together when the BOUGHT parts turn out different (sprocket hub, chain centre distance, gearbox hub width) or the MADE gear layers a different thickness (GEAR_LAYER_T)?
# For each variant it makes a TEMPORARY copy of design/ + cad/ (sources only), appends the overrides to the COPY of params.py, regenerates params.scad
# there and runs `build.sh variants` (the alignment / collision checks C2 C5 C8 C10 C16 C17 C20 C21 C22 C23 C24 C26 C27 C28 C31 C32 + the design asserts) in the copy.
# Nothing in the real tree is touched (the copy lives in a mktemp directory and is removed at the end).  Exit status 1 if any variant fails.
#   ./variants.sh                      the default variants below
#   ./variants.sh 'SPROCKET_A["hub_L"]=30'   your own variant(s), each one argument: "NAME=value NAME=value" (dict entries work: SPROCKET_A["hub_L"]=30)
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [ $# -gt 0 ]; then VARIANTS=("$@"); else
  VARIANTS=('SPROCKET_A["hub_L"]=20' 'SPROCKET_A["hub_L"]=25' 'GEAR_LAYER_T=9.5' 'GEAR_LAYER_T=10.0' "CHAIN_CD=152" "CHAIN_CD=157" "GB_HUB_L=80")
fi

run_variant() {   # INDEX "NAME=value ..."
  local idx="$1" spec="$2" d="$TMP/v$1" kv
  mkdir -p "$d/design" "$d/cad"
  cp "$ROOT"/design/*.py "$d/design/"
  cp "$ROOT"/cad/*.scad "$ROOT"/cad/*.py "$ROOT"/cad/build.sh "$d/cad/"
  for kv in $spec; do printf '%s = %s\n' "${kv%%=*}" "${kv#*=}"; done >> "$d/design/params.py"   # last assignment wins; derived() reads the globals when it is called
  { (cd "$d" && python3 design/build.py > "$d/params.out" 2>&1) \
    && (cd "$d/cad" && ./build.sh variants > "$d/out.txt" 2>&1); } ; echo $? > "$d/rc"
}

i=0
for spec in "${VARIANTS[@]}"; do i=$((i + 1)); run_variant "$i" "$spec" & done
wait

status=0; i=0
for spec in "${VARIANTS[@]}"; do
  i=$((i + 1)); d="$TMP/v$i"
  echo "=== variant $i: $spec"
  grep -E '^(CHAIN_CD|x_sprocket_out|x_gear_out|x_gear_hub_out|shaft_end_A_drive|shaft_end_B_drive) ' "$d/cad/params.scad" 2>/dev/null | tr '\n' ' '; echo
  if [ ! -f "$d/out.txt" ]; then echo "   FAILED to generate the parameters:"; tail -5 "$d/params.out"; status=1; continue; fi
  grep -E 'FAIL|FAILED|asserts' "$d/out.txt" | head -20
  grep -E 'passed,' "$d/out.txt"
  if [ "$(cat "$d/rc")" = 0 ]; then echo "   PASS"; else echo "   FAIL (rc $(cat "$d/rc"))"; status=1; fi
done
[ "$status" = 0 ] && echo "ALL VARIANTS OK" || echo "VARIANTS FAILED"
exit "$status"
