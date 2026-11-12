#!/usr/bin/env python3
"""Printer-fit check: bounding box of ASCII STL files against the MK3S build volume (x 250, y 210, z 210)."""
import re, sys
lim = tuple(map(float, sys.argv[1:4])); bad = 0
for f in sys.argv[4:]:
    mn = [1e18]*3; mx = [-1e18]*3
    for line in open(f):
        m = re.match(r"\s*vertex\s+(\S+)\s+(\S+)\s+(\S+)", line)
        if m:
            for i in range(3):
                v = float(m.group(i+1)); mn[i] = min(mn[i], v); mx[i] = max(mx[i], v)
    size = [mx[i]-mn[i] for i in range(3)]
    ok = all(size[i] <= lim[i] for i in range(3)) and mn[2] > -1e-3 and mn[2] < 1e-3
    print(f"{'ok  ' if ok else 'FAIL'} {f}: {size[0]:.1f} x {size[1]:.1f} x {size[2]:.1f}  (z0 {mn[2]:.2f})")
    bad |= not ok
sys.exit(1 if bad else 0)
