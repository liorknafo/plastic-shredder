#!/usr/bin/env python3
"""reference.py -- measure the OpenSCAD model: reference.json and parts_reference.json.

    python3 reference.py [COMMIT]      default: OPENSCAD_COMMIT below

The native SolidCraft model (model/*.py) is a translation of the OpenSCAD sources (cad/*.scad).  The proof that the
translation is the same machine is a comparison with the OpenSCAD model itself, measured here:

  reference.json        each group of bodies of the OpenSCAD MESH assembly: that commit's old mesh exporter
                        (cad/solidcraft/export_parts.py + build.py: OpenSCAD -> one STL per group -> 3MF -> a mesh .sc),
                        measured with `solidcraft-cli eval` (volume, area, bounding box, centre of mass)
  parts_reference.json  each made part as that commit's OpenSCAD pipeline exports it (the STL section of its
                        cad/build.sh, run afresh: cad/stl/<name>.stl), measured the same way

COMMIT must be a commit whose cad/stl came from OpenSCAD (cad/build.sh) and which still has the mesh exporter
(cad/solidcraft/export_parts.py, manifest.py, parts.scad, axes.scad).  It is checked out into a temporary git worktree
(build/reference/); the working tree is not touched.  Needs openscad (manifold backend) and solidcraft-cli 0.40.
The first conversion measured commit 27662be this way; the current design was measured at OPENSCAD_COMMIT.
"""
import json
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RENAMED = {"Circlip, spacer, stop collar": "Circlip and spacer"}     # old mesh-exporter group names -> the native model's
CLI = os.environ.get("SOLIDCRAFT_CLI", "solidcraft-cli")
OPENSCAD_COMMIT = "727b848"          # shredder-design: bought gears, outboard plate, fixed screen, pin-flange drive


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        sys.exit(f"{' '.join(cmd)} failed ({r.returncode}):\n{(r.stderr or r.stdout)[-2000:]}")
    return r


def measure(path, out):
    run([CLI, "eval", path, "--json-out", out])
    return json.load(open(out))["bodies"]


def main():
    commit = sys.argv[1] if len(sys.argv) > 1 else OPENSCAD_COMMIT
    root = run(["git", "rev-parse", "--show-toplevel"], cwd=HERE).stdout.strip()
    sha = run(["git", "rev-parse", "--short", commit], cwd=root).stdout.strip()
    wt = os.path.join(HERE, "build", "reference")
    if os.path.exists(wt):
        run(["git", "worktree", "remove", "--force", wt], cwd=root)
    run(["git", "worktree", "add", "--detach", wt, sha], cwd=root)
    try:
        run([sys.executable, "-B", "design/build.py"], cwd=wt)
        sc_dir = os.path.join(wt, "cad", "solidcraft")
        env = dict(os.environ, SOLIDCRAFT_CLI=CLI)
        print(f"{sha}: OpenSCAD -> one STL per group (export_parts.py) ...", flush=True)
        run([sys.executable, "-B", "export_parts.py", "--force"], cwd=sc_dir, env=env)
        print(f"{sha}: the mesh assembly (build.py) ...", flush=True)
        run([sys.executable, "-B", "build.py"], cwd=sc_dir, env=env)
        tmp = os.path.join(HERE, "build")
        bodies = measure(os.path.join(wt, "cad", "shredder_assembly.sc"), os.path.join(tmp, "reference_eval.json"))
        ref = {}
        for b in bodies:
            ref[RENAMED.get(b["name"], b["name"])] = dict(volume_mm3=round(b["volume_mm3"], 1) if b["closed"] else None,
                                  area_mm2=round(b["area_mm2"], 1),
                                  bbox_min=[round(v, 3) for v in b["bbox"]["min"]],
                                  bbox_max=[round(v, 3) for v in b["bbox"]["max"]],
                                  com=[round(v, 3) for v in b["center_of_mass"]] if b["closed"] else None,
                                  closed=b["closed"], mesh_faces=b["faces"])
        json.dump({"_about": f"Each body of the OpenSCAD mesh assembly (commit {sha}: cad/*.scad through that commit's mesh exporter, "
                             "cad/solidcraft/export_parts.py + build.py, made by reference.py), measured with solidcraft-cli 0.40.0 eval. "
                             "The native bodies are checked against these numbers (check.py, build.py). Meshes are faceted, so round bodies "
                             "are up to about 1 % smaller here than the native ones.", "bodies": ref},
                  open(os.path.join(HERE, "reference.json"), "w"), indent=1)
        print(f"reference.json: {len(ref)} groups")

        print(f"{sha}: OpenSCAD -> cad/stl (the STL section of cad/build.sh) ...", flush=True)
        bsh = os.path.join(wt, "cad", "build.sh")
        text = open(bsh).read()
        cut = text.index("# printer-fit check")
        open(bsh, "w").write(text[:cut] + "exit $fail\n")
        stl_dir = os.path.join(wt, "cad", "stl")
        shutil.rmtree(stl_dir)
        run(["bash", bsh], cwd=os.path.join(wt, "cad"))
        parts = {}
        for f in sorted(os.listdir(stl_dir)):
            if not f.endswith(".stl"):
                continue
            bs = measure(os.path.join(stl_dir, f), os.path.join(tmp, "reference_part.json"))
            closed = all(b["closed"] for b in bs)
            v = sum(b["volume_mm3"] for b in bs) if closed else None
            parts[f[:-4]] = dict(
                volume_mm3=None if v is None else round(v, 1),
                bbox_min=[round(min(b["bbox"]["min"][i] for b in bs), 3) for i in range(3)],
                bbox_max=[round(max(b["bbox"]["max"][i] for b in bs), 3) for i in range(3)],
                com=None if v is None else [round(sum(b["volume_mm3"] * b["center_of_mass"][i] for b in bs) / v, 3) for i in range(3)],
                closed=closed, mesh_bodies=len(bs))
        json.dump({"_about": f"Each made part as the OpenSCAD pipeline exported it (cad/stl/<name>.stl at commit {sha}, measured by "
                             "reference.py with solidcraft-cli 0.40.0 eval). parts.py checks the native parts against these numbers. "
                             "Meshes are faceted, so round parts are up to about 1 % smaller here than the native ones.", "parts": parts},
                  open(os.path.join(HERE, "parts_reference.json"), "w"), indent=1)
        print(f"parts_reference.json: {len(parts)} parts")
    finally:
        run(["git", "worktree", "remove", "--force", wt], cwd=root)
        shutil.rmtree(wt, ignore_errors=True)


if __name__ == "__main__":
    main()
