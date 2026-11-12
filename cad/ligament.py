#!/usr/bin/env python3
"""Hole-ligament check for the end-plate layers.

Reads the hole table that plate.scad itself echoes (so there is ONE table), e.g.
    openscad -D dump_holes=true -o logs/holes.echo plate.scad
then, per layer kind, computes
  * hole-to-hole ligament  = centre distance - r1 - r2   (only holes whose depth ranges overlap; concentric
    stepped features of the same screw/bearing seat, e.g. through hole + counterbore, are skipped),
  * foot hole (cylinder along z from the bottom edge) to every axial hole, exactly (rectangle-to-circle in the
    plate plane),
  * hole-to-plate-edge ligament.
Negative or zero ligament = intersecting holes -> exit 1.
"""
import math
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "logs/holes.echo"
min_ok = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0   # mm: anything below this is reported as a failure

axial, foot = {}, {}
plate = None
num = r"(-?[0-9.]+(?:e-?[0-9]+)?)"
for line in open(path):
    m = re.match(r'ECHO: "HOLE", "(\w+)", "axial", "(\w+)", ' + ", ".join([num] * 5), line)
    if m:
        k = m.group(1)
        y, z, d, w0, w1 = map(float, m.groups()[2:])
        axial.setdefault(k, []).append((m.group(2), y, z, d / 2, w0, w1))
        continue
    m = re.match(r'ECHO: "HOLE", "(\w+)", "(?:foot|top)", "(\w+)", ' + ", ".join([num] * 5), line)
    if m:
        k = m.group(1)
        y, w, d, z0, z1 = map(float, m.groups()[2:])
        foot.setdefault(k, []).append((m.group(2), y, w, d / 2, z0, z1))
        continue
    m = re.match(r"ECHO: \"PLATE\", " + ", ".join([num] * 3), line)
    if m:
        plate = tuple(map(float, m.groups()))
if not axial or plate is None:
    sys.exit(f"ligament.py: no hole table found in {path}")
PL, PH, T = plate

results = []   # (ligament, kind, text)
for kind, holes in axial.items():
    for i, h in enumerate(holes):
        for j in range(i + 1, len(holes)):
            g = holes[j]
            if abs(h[1] - g[1]) < 1e-9 and abs(h[2] - g[2]) < 1e-9:
                continue                                   # concentric: same screw / bearing seat
            if min(h[5], g[5]) - max(h[4], g[4]) <= 1e-9:
                continue                                   # different depth ranges, cannot touch
            lig = math.hypot(h[1] - g[1], h[2] - g[2]) - h[3] - g[3]
            results.append((lig, kind, f"{h[0]}({h[1]:g},{h[2]:g}) - {g[0]}({g[1]:g},{g[2]:g})"))
    for f in foot.get(kind, []):
        for h in holes:
            # foot hole footprint in the (y, z) plane: [y - r, y + r] x [z0, z1]
            dy = max(abs(h[1] - f[1]) - f[3], 0.0)
            dz = max(h[2] - f[5], f[4] - h[2], 0.0)
            lig = math.hypot(dy, dz) - h[3]
            results.append((lig, kind, f"{f[0]}({f[1]:g}) - {h[0]}({h[1]:g},{h[2]:g})"))
edge = []
for kind, holes in axial.items():
    for h in holes:
        e = min(PL / 2 - abs(h[1]) - h[3], PH / 2 - abs(h[2]) - h[3])
        edge.append((e, kind, f"{h[0]}({h[1]:g},{h[2]:g}) to plate edge"))
    for f in foot.get(kind, []):
        edge.append((PL / 2 - abs(f[1]) - f[3], kind, f"{f[0]}({f[1]:g}) to side edge"))

results.sort()
edge.sort()
print("hole-to-hole ligaments (smallest 8):")
for lig, kind, txt in results[:8]:
    print(f"  {lig:6.2f} mm  [{kind}] {txt}")
print("hole-to-edge ligaments (smallest 5):")
for lig, kind, txt in edge[:5]:
    print(f"  {lig:6.2f} mm  [{kind}] {txt}")
for kind in axial:
    kh = min(r for r in results if r[1] == kind)
    ke = min(r for r in edge if r[1] == kind)
    print(f"  per layer {kind:10s}: hole-hole {kh[0]:5.2f} mm, hole-edge {ke[0]:5.2f} mm")
mh, me = results[0], edge[0]
print(f"MIN hole-to-hole ligament: {mh[0]:.2f} mm  [{mh[1]}] {mh[2]}")
print(f"MIN hole-to-edge ligament: {me[0]:.2f} mm  [{me[1]}] {me[2]}")
ok = mh[0] >= min_ok and me[0] >= min_ok
print("LIGAMENT", "PASS" if ok else "FAIL", f"(threshold {min_ok} mm: no intersecting holes, no hole breaking out)")
sys.exit(0 if ok else 1)
