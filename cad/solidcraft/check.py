#!/usr/bin/env python3
"""check.py -- build bodies of the assembly natively and compare them with the old mesh assembly (reference.json).

    python3 check.py                 every body
    python3 check.py Blades "Shaft A"   groups whose name contains one of the words
    python3 check.py -m hopper       only the groups model/hopper.py defines (its BODIES), without the rest of the assembly

A body of the old assembly was one mesh per colour; here it is a group of bodies, one per part.  For each group:
total volume, bounding box and centre of mass against the mesh body of the same name.  The meshes are
faceted (circles were polygons), so a round body is up to about 1 % larger here; a prismatic one matches closely.
Needs solidcraft-cli 0.40 on PATH (or SOLIDCRAFT_CLI).
"""
import json
import math
import os
import subprocess
import sys
import time

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [HERE, os.path.join(HERE, "model")]
from scq import Script          # noqa: E402


def assembly_components(module=None):
    """[(component, [Body ...])]: the whole assembly, or with -m NAME only the groups that model/NAME.py defines (its BODIES)."""
    import importlib
    if module is None:
        return importlib.import_module("assembly").COMPONENTS
    return list(importlib.import_module(module).BODIES.items())

CLI = os.environ.get("SOLIDCRAFT_CLI", "solidcraft-cli")
BUILD = os.path.join(HERE, "build")
VOL_TOL, BOX_TOL, COM_TOL = 0.015, 0.5, 0.5          # relative volume, mm, mm
# Round hardware that the old meshes drew with $fn 12 to 24: a 12-gon has 95.5 % of the circle's area, a 16-gon 97.4 %.
FACET_TOL = {"Grid screws": 0.05, "Safety grid mesh": 0.03, "grid_mesh": 0.03,
             "Handle + actuator screws": 0.02, "Lid screws (pad, actuator)": 0.02, "Belt guard hardware": 0.03}
# Parts that overlap in the design itself.  The old mesh was their union, so its volume is short by the overlap.
# Cabinet: the floor panel (192.2 x 202 x 18) lies in the bottom 18 mm of both side panels (65448.0 mm3 each) and of
# the back panel (50608.8 mm3).  Here every panel is a body of its own; the design is left as it is.
OVERLAP = {"Cabinet (sides, back, floor)": 181504.8}


def compare(groups, names, got, ref, counts=None):
    """Print one line per group (a Body of the assembly: `names[group]` are its bodies, `got` the measured bodies by
    name) against the mesh reference.  Returns the number of groups that do not match."""
    bad = 0
    print(f"{'group (bodies)':46s} {'steps':>5s} {'volume':>12s} {'mesh':>12s} {'dV %':>7s} {'box mm':>7s} {'com mm':>7s}")
    for name in groups:
        gs, m = [got[n] for n in names[name] if n in got], ref.get(name)
        label = f"{name} ({len(gs)})"
        steps = f"{counts[name]:5d}" if counts else "     "
        if len(gs) != len(names[name]) or not gs:
            print(f"{label:46s} {steps}  NOT BUILT: {sorted(set(names[name]) - set(got))[:4]}")
            bad += 1
            continue
        closed = all(g["closed"] for g in gs)
        v = sum(g["volume_mm3"] for g in gs) if closed else None
        lo = [min(g["bbox"]["min"][i] for g in gs) for i in range(3)]
        hi = [max(g["bbox"]["max"][i] for g in gs) for i in range(3)]
        if m is None:
            print(f"{label:46s} {steps} {v if v is not None else float('nan'):12.1f}  (no reference body)")
            continue
        box = max(abs(a - c) for a, c in zip(lo + hi, m["bbox_min"] + m["bbox_max"]))
        note = ""
        if v is None or m["volume_mm3"] is None:
            dv, com = float("nan"), float("nan")
            ok = box <= BOX_TOL
        else:
            com = math.dist([sum(g["volume_mm3"] * g["center_of_mass"][i] for g in gs) / v for i in range(3)], m["com"])
            if name in OVERLAP:                           # compare the union, as the mesh was; its centre is not checked
                v -= OVERLAP[name]
                com = float("nan")
                note = f"  (its parts overlap by {OVERLAP[name]:.1f} mm3 in the design)"
            dv = (v - m["volume_mm3"]) / m["volume_mm3"]
            ok = abs(dv) <= FACET_TOL.get(name, VOL_TOL) and box <= BOX_TOL and not com > COM_TOL
        bad += not ok
        print(f"{label:46s} {steps} {v if v is not None else float('nan'):12.1f} "
              f"{m['volume_mm3'] if m['volume_mm3'] is not None else float('nan'):12.1f} {100 * dv:+7.3f} {box:7.3f} {com:7.3f}"
              f"  {'ok' if ok else 'CHECK'}{'' if closed else '  (open body)'}{note}")
    extra = sorted(set(got) - {n for ns in names.values() for n in ns})
    if extra:
        print("bodies left over (a piece that did not join):", extra[:12])
        bad += 1
    return bad


def reference():
    return json.load(open(os.path.join(HERE, "reference.json")))["bodies"]


def freeze(path, key, groups, names, got, about):
    """Write what was just built as the new reference numbers (after a deliberate change of the design)."""
    ref = {}
    for name in groups:
        gs = [got[n] for n in names[name] if n in got]
        closed = all(g["closed"] for g in gs)
        v = sum(g["volume_mm3"] for g in gs) if closed else None
        ref[name] = dict(
            volume_mm3=None if v is None else round(v, 1),
            bbox_min=[round(min(g["bbox"]["min"][i] for g in gs), 3) for i in range(3)],
            bbox_max=[round(max(g["bbox"]["max"][i] for g in gs), 3) for i in range(3)],
            com=None if v is None else [round(sum(g["volume_mm3"] * g["center_of_mass"][i] for g in gs) / v, 3) for i in range(3)],
            closed=closed)
    json.dump({"_about": about, key: ref}, open(path, "w"), indent=1)
    print(f"froze {len(ref)} references in {os.path.basename(path)}")


def main():
    args = sys.argv[1:]
    module = args.pop(args.index("-m") + 1) if "-m" in args else None
    comps = assembly_components(module)
    build = os.path.join(BUILD, module or "all")           # one folder per module: checks may run side by side
    words = [a.lower() for a in args if not a.startswith("-")]
    bodies = [b for _, bs in comps for b in bs
              if not words or any(w in b.name.lower() for w in words)]
    if not bodies:
        sys.exit("no body matches")
    s = Script()
    counts, names = {}, {}
    for b in bodies:
        n0 = len(s.steps)
        names[b.name] = s.build(b.node(), b.name)
        counts[b.name] = len(s.steps) - n0
    os.makedirs(build, exist_ok=True)
    script, out = os.path.join(build, "check.json"), os.path.join(build, "check_eval.json")
    json.dump(s.steps, open(script, "w"))
    t0 = time.time()
    r = subprocess.run([CLI, "eval", script, "--json-out", out], capture_output=True, text=True)
    dt = time.time() - t0
    if r.returncode != 0:
        print((r.stderr or r.stdout)[-3000:])
        sys.exit(f"solidcraft-cli failed ({r.returncode}) after {dt:.1f} s; script: {script}")
    got = {b["name"]: b for b in json.load(open(out))["bodies"]}
    bad = compare([b.name for b in bodies], names, got, reference(), counts)
    print(f"{len(bodies)} groups, {len(got)} bodies, {len(s.steps)} steps, {dt:.1f} s; {bad} to check")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
