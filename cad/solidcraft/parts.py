#!/usr/bin/env python3
"""parts.py -- the made parts one by one, each in its own part frame, as native SolidCraft bodies.

    python3 parts.py                  build every part and compare it with the old OpenSCAD STL (parts_reference.json)
    python3 parts.py blade shaft      only parts whose name contains a word
    python3 parts.py -m gear          only the parts model/gear.py defines (its PARTS)
    python3 parts.py --compare        also lay each old STL over its native part and compare the two surfaces
                                      (SolidCraft's inspect.compare, 0.05 mm): the old STLs are read from git
    python3 parts.py --dxf            also build the flat parts' outlines as DXF (into build/, not cad/dxf)
    python3 parts.py --check          exit with an error when a part does not match parts_reference.json
    python3 parts.py --freeze         make what was built the new parts_reference.json (after a deliberate change)
    python3 parts.py --export         also write cad/step/<name>.step, cad/stl/<name>.stl and cad/dxf/<name>.dxf

A module of model/ lists its parts as PARTS = {name: builder} (the names are the file names in cad/stl and cad/step)
and the outlines of its flat parts as PARTS_2D = {name: builder} (cad/dxf).
Needs SolidCraft 0.40 (`solidcraft-cli` on PATH, or SOLIDCRAFT_CLI).  Standard library only.
"""
import importlib
import json
import os
import subprocess
import sys
import time

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
sys.path[:0] = [HERE, os.path.join(HERE, "model")]
from scq import Script, linear_extrude # noqa: E402
from check import BUILD, CLI, compare, freeze  # noqa: E402

OLD_COMMIT = "27662be"               # the last commit whose cad/stl/*.stl came from OpenSCAD
COMPARE_TOL = 0.05                   # mm: the old meshes are polygons inside the true circles (0.013 mm at R25, $fn 96)
# The welded wire mesh is a bought part: nobody prints it, and round Ø2 wires make a 20 MB STL.  Its STEP is 0.6 MB.
NOT_EXPORTED = {("stl", "grid_mesh")}
# A difference the surface comparison finds that is known and is not a difference of shape.
KNOWN = {"grid_mesh": "SolidCraft 0.40 leaves 13 of the 56 wire crossings unfused when it joins the wires (they graze "
                      "0.1 mm deep), in any order of joining: both wires' surfaces stay inside the weld there, 0.031 mm3 "
                      "each.  Volume, box and centre of mass are right."}


def compare_surfaces(names, build):
    """Each native part against its old STL, surface to surface.  Returns the number that differ."""
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=HERE, capture_output=True, text=True).stdout.strip()
    old = os.path.join(build, "old_stl")
    os.makedirs(old, exist_ok=True)
    bad = 0
    print(f"{'part':24s} {'max dev mm':>10s} {'mean mm':>8s}  verdict")
    for name in names:
        stl = os.path.join(old, name + ".stl")
        r = subprocess.run(["git", "show", f"{OLD_COMMIT}:cad/stl/{name}.stl"], cwd=root, capture_output=True)
        if r.returncode != 0:
            print(f"{name:24s}  (no old STL)")
            continue
        open(stl, "wb").write(r.stdout)
        steps = one_part_steps(name, build)
        steps += [{"command": "file.insert_mesh", "params": {"path": stl, "name": "old"}},
                  {"command": "inspect.compare", "params": {"a": name, "b": name + " (2)", "tolerance": COMPARE_TOL}}]
        script, out = os.path.join(build, "compare.json"), os.path.join(build, "compare_out.json")
        json.dump(steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--results", "--quiet", "--json-out", out], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:24s}  FAILED: {r.stderr.strip()[-160:]}")
            bad += 1
            continue
        res = json.load(open(out))
        c = (res.get("results", res) if isinstance(res, dict) else res)[-1]
        dev = max(c["deviation"]["a_to_b"]["max_mm"], c["deviation"]["b_to_a"]["max_mm"])
        mean = max(c["deviation"]["a_to_b"]["mean_mm"], c["deviation"]["b_to_a"]["mean_mm"])
        bad += not c["identical"] and name not in KNOWN
        print(f"{name:24s} {dev:10.4f} {mean:8.4f}  {c['verdict']}")
        if not c["identical"] and name in KNOWN:
            print(f"{'':24s} known: {KNOWN[name]}")
    return bad


def dxf_entities(text):
    """The entity types of a DXF and the extent [x0, y0, x1, y1] of its LWPOLYLINEs (bulge arcs included) and CIRCLEs."""
    import math
    lines = text.splitlines()
    pairs = [(lines[i].strip(), lines[i + 1].strip()) for i in range(0, len(lines) - 1, 2)]      # group code, value
    start = next((i for i, p in enumerate(pairs) if p == ("2", "ENTITIES")), 0)
    end = next((i for i in range(start, len(pairs)) if pairs[i] == ("0", "ENDSEC")), len(pairs))
    pairs = pairs[start + 1:end]
    ents, pts, cur = [], [], None

    def close():
        if not cur:
            return
        if cur["type"] == "CIRCLE" and "r" in cur:
            pts.extend([(cur["x"][0] - cur["r"], cur["y"][0] - cur["r"]), (cur["x"][0] + cur["r"], cur["y"][0] + cur["r"])])
        elif cur["type"] == "LWPOLYLINE":
            v = list(zip(cur["x"], cur["y"], cur["b"] + [0.0] * len(cur["x"])))
            for i, (x0, y0, b) in enumerate(v):
                pts.append((x0, y0))
                x1, y1 = v[(i + 1) % len(v)][:2]
                if b and (i + 1 < len(v) or cur["closed"]):          # a bulge: tan(sweep / 4) of the arc to the next vertex
                    ang, chord = 4 * math.atan(b), math.hypot(x1 - x0, y1 - y0)
                    r = chord / (2 * math.sin(ang / 2))
                    a0 = math.atan2(y1 - y0, x1 - x0) + math.pi / 2 - ang / 2
                    cx, cy = x0 - r * math.cos(a0 - math.pi), y0 - r * math.sin(a0 - math.pi)
                    a = math.atan2(y0 - cy, x0 - cx)
                    pts.extend((cx + abs(r) * math.cos(a + ang * k / 24), cy + abs(r) * math.sin(a + ang * k / 24)) for k in range(25))

    for code, val in pairs:
        if code == "0":
            close()
            cur = {"type": val, "x": [], "y": [], "b": [], "closed": False} if val in ("LWPOLYLINE", "CIRCLE", "LINE", "ARC") else None
            if cur:
                ents.append(val)
        elif cur:
            if code == "10":
                cur["x"].append(float(val))
                cur["b"] += [0.0] * (len(cur["x"]) - 1 - len(cur["b"]))
            elif code == "20":
                cur["y"].append(float(val))
            elif code == "42":
                cur["b"].append(float(val))
            elif code == "40":
                cur["r"] = float(val)
            elif code == "70":
                cur["closed"] = bool(int(val) & 1)
    close()
    return ents, ([min(p[0] for p in pts), min(p[1] for p in pts), max(p[0] for p in pts), max(p[1] for p in pts)] if pts else [0, 0, 0, 0])


def export_dxf(outlines, build, write):
    """The outline of each flat part as DXF: its body's faces in the plane z = 0, projected into a sketch (true arcs,
    closed loops; the outside on layer OUTLINE, the holes on CUT).  `outlines`: name -> builder of a 2D tree (the part is
    that shape) or of a solid lying on z = 0 (its underside).  Checked against the extent of the old DXF."""
    import re
    root = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=HERE, capture_output=True, text=True).stdout.strip()
    out_dir = os.path.join(CAD, "dxf") if write else os.path.join(build, "dxf")
    os.makedirs(out_dir, exist_ok=True)
    bad = 0
    print(f"{'outline':20s} {'loops':>5s} {'old':>5s}  {'extent':40s} against the old DXF")
    for name, builder in outlines.items():
        tree = builder()
        s = Script()
        body = "outline " + name
        s.build(linear_extrude(1, tree) if tree.dim == 2 else tree, body, split=False)
        n_model = len(s.steps)
        s.step("model.faces", body=body)
        script, res = os.path.join(build, "dxf.json"), os.path.join(build, "dxf_out.json")
        json.dump(s.steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--results", "--quiet", "--json-out", res], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:20s}  FAILED: {r.stderr.strip()[-200:]}")
            bad += 1
            continue
        faces = json.load(open(res))
        faces = (faces.get("results", faces) if isinstance(faces, dict) else faces)[-1]["faces"]
        flat = [f["point"] for f in faces if f.get("plane_normal") and abs(f["plane_normal"][2]) > 0.999999]
        z = 0.0 if tree.dim == 2 else max(p[2] for p in flat)       # a solid: seen from above (blind holes underneath stay out)
        under = [p for p in flat if abs(p[2] - z) < 1e-6]
        path = os.path.join(out_dir, name + ".dxf")
        steps = s.steps[:n_model] + [
            {"command": "sketch.create", "params": {"plane": "XY", "offset": z, "name": name + " outline"}},
            {"command": "sketch.project", "params": {"refs": [{"face": p, "body": body} for p in under], "construction": False}},
            {"command": "sketch.export_dxf", "params": {"path": path, "join": True, "layers": "roles"}},
            {"command": "sketch.finish", "params": {}}]
        json.dump(steps, open(script, "w"))
        r = subprocess.run([CLI, "run", script, "--quiet"], capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:20s}  FAILED: {r.stderr.strip()[-200:]}")
            bad += 1
            continue
        ents, ext = dxf_entities(open(path).read())
        loops = ents.count("LWPOLYLINE") + ents.count("CIRCLE")
        r = subprocess.run(["git", "show", f"{OLD_COMMIT}:cad/dxf/{name}.dxf"], cwd=root, capture_output=True, text=True)
        m = re.search(r"\$EXTMIN\s+10\s+(\S+)\s+20\s+(\S+)\s+9\s+\$EXTMAX\s+10\s+(\S+)\s+20\s+(\S+)", r.stdout) if r.returncode == 0 else None
        old_loops = len(re.findall(r"\n\s*0\nLWPOLYLINE", r.stdout)) if r.returncode == 0 else 0
        loose = len(ents) - loops
        if m:
            d = max(abs(a - float(b)) for a, b in zip(ext, m.groups()))
            ok = d < 0.05 and not loose and loops == old_loops
            verdict = f"extent within {d:.3f} mm" + ("" if not loose else f", {loose} loose curves") + ("" if ok else "  CHECK")
        else:
            ok, verdict = not loose, "(no old DXF)"
        bad += not ok
        print(f"{name:20s} {loops:5d} {old_loops:5d}  {str([round(v, 3) for v in ext]):40s} {verdict}")
    return bad


_STEPS = {}


def one_part_steps(name, build):
    return list(_STEPS[name])


MODULES = ["blade", "spacer", "shaft", "sleeve", "placeholders", "gear", "plate", "comb", "wall", "guards", "hopper",
           "base", "drive", "tlfix", "testlever"]


def main():
    args = sys.argv[1:]
    export = "--export" in args
    module = args.pop(args.index("-m") + 1) if "-m" in args else None
    words = [a.lower() for a in args if not a.startswith("-")]
    parts, outlines, not_built = {}, {}, {}
    for name in [module] if module else MODULES:
        try:
            mod = importlib.import_module(name)
        except ModuleNotFoundError as e:
            if e.name != name:
                raise
            continue
        parts.update(getattr(mod, "PARTS", {}))
        outlines.update(getattr(mod, "PARTS_2D", {}))
        not_built.update(getattr(mod, "NOT_BUILT", {}))
    parts = {n: b for n, b in parts.items() if not words or any(w in n.lower() for w in words)}
    outlines = {n: b for n, b in outlines.items() if not words or any(w in n.lower() for w in words)}
    if not parts and not outlines:
        sys.exit("no part matches")
    build = os.path.join(BUILD, "parts_" + (module or "all"))
    os.makedirs(build, exist_ok=True)
    s = Script()
    names = {}
    for name, builder in parts.items():
        n0 = len(s.steps)
        names[name] = s.build(builder(), name, split=False)
        _STEPS[name] = s.steps[n0:]
    if export:
        for sub in ("step", "stl"):
            os.makedirs(os.path.join(CAD, sub), exist_ok=True)
            for name in parts:
                if (sub, name) not in NOT_EXPORTED:
                    s.step("file.export", path=os.path.join(CAD, sub, f"{name}.{sub}"), bodies=[name])
    script, out = os.path.join(build, "parts.json"), os.path.join(build, "parts_eval.json")
    json.dump(s.steps, open(script, "w"))
    t0 = time.time()
    r = subprocess.run([CLI, "eval", script, "--json-out", out], capture_output=True, text=True)
    if r.returncode != 0:
        print((r.stderr or r.stdout)[-3000:])
        sys.exit(f"solidcraft-cli failed ({r.returncode}); script: {script}")
    got = {b["name"]: b for b in json.load(open(out))["bodies"]}
    if "--freeze" in args:
        assert not words and not module, "freeze every part at once"
        freeze(os.path.join(HERE, "parts_reference.json"), "parts", list(parts), names, got,
               "Each made part in its part frame as parts.py --freeze measured it (solidcraft-cli eval): volume, bounding "
               "box, centre of mass.  parts.py compares what it builds with these numbers.")
        return
    ref = json.load(open(os.path.join(HERE, "parts_reference.json")))["parts"]
    bad = compare(list(parts), names, got, ref)
    for name, why in not_built.items():
        if not words or any(w in name.lower() for w in words):
            print(f"{name}: NOT BUILT: {why}")
    if "--compare" in args:
        bad += compare_surfaces(list(parts), build)
    if "--dxf" in args or export:
        bad += export_dxf(outlines, build, export)
    print(f"{len(parts)} parts, {len(s.steps)} steps, {time.time() - t0:.1f} s; {bad} differ from the references"
          + ("; exported to cad/step, cad/stl and cad/dxf" if export else ""))
    sys.exit(1 if bad and "--check" in args else 0)


if __name__ == "__main__":
    main()
