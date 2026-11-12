#!/usr/bin/env python3
"""interference.py -- SolidCraft's own interference check of cad/shredder_assembly.sc, on the native bodies.

    python3 interference.py            at rest: every pair of bodies; then the three motion studies, a few poses each
    python3 interference.py --rest     only at rest
    python3 interference.py --steps N  N poses per study instead of 6 (the shafts' study covers one turn)

At rest every pair is checked exactly (a boolean per pair whose boxes meet).  In a study only pairs of bodies of
DIFFERENT components are checked, and only the overlaps that are not already there at rest are listed: an overlap at
rest that does not change is a property of the model (a stand-in pushed through a stand-in, a screw in its pilot
hole), not a collision of the motion.  Writes build/interference.md.

Needs cad/shredder_assembly.sc (python3 build.py) and SolidCraft 0.40.  Standard library only.
"""
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
CLI = os.environ.get("SOLIDCRAFT_CLI", "solidcraft-cli")
SC = os.path.join(CAD, "shredder_assembly.sc")
COMPONENTS = ["Frame", "Rotor A", "Rotor B", "Lid", "Drawer", "Torque limiter + output shaft", "Worm + gearbox pulley",
              "Motor shaft + pulley"]
STUDIES = [("Shafts one turn", "Shaft A", 0.0, 360.0, "deg"), ("Drawer out", "Drawer slide", 0.0, 180.0, "mm"),
           ("Lid open", "Lid hinge", 0.0, 100.0, "deg")]
MIN_VOLUME = 0.01            # mm3: less is contact


def run(steps, tag):
    script, out = os.path.join(BUILD, f"interference_{tag}.json"), os.path.join(BUILD, f"interference_{tag}_out.json")
    json.dump(steps, open(script, "w"))
    r = subprocess.run([CLI, "run", script, "--in", SC, "--results", "--quiet", "--json-out", out], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"solidcraft-cli failed ({r.returncode})\n{r.stderr[-2000:]}")
    res = json.load(open(out))
    return res.get("results", res) if isinstance(res, dict) else res


def pairs(result):
    out = {}
    for i in result["interferences"]:
        if (i.get("volume_mm3") or 0) >= MIN_VOLUME:
            key = tuple(sorted((i["a"], i["b"])))
            out[key] = (i["volume_mm3"], (i.get("a_part") or {}).get("component"), (i.get("b_part") or {}).get("component"))
    return out


def main():
    os.makedirs(BUILD, exist_ok=True)
    steps = int(sys.argv[sys.argv.index("--steps") + 1]) if "--steps" in sys.argv else 6
    lines = ["# Interference of cad/shredder_assembly.sc (SolidCraft, exact, body by body)", ""]
    t0 = time.time()
    rest = run([{"command": "inspect.interference", "params": {"budget_s": 1800}}], "rest")[0]
    at_rest = pairs(rest)
    lines += [f"## At rest: {rest['checked']} bodies, {rest['pairs_candidate']} pairs whose boxes meet, "
              f"{len(at_rest)} overlap, {len(rest['unchecked'])} could not be checked", "",
              "| body | body | overlap mm3 | components |", "|---|---|---:|---|"]
    for (a, b), (v, ca, cb) in sorted(at_rest.items(), key=lambda kv: -kv[1][0]):
        lines.append(f"| {a} | {b} | {v:.2f} | {ca if ca == cb else f'{ca} / {cb}'} |")
    if rest["unchecked"]:
        lines += ["", "Not checked (SolidCraft's boolean failed on the pair; these are parts that touch face to face):", ""]
        lines += [f"- {u['a']} / {u['b']}" for u in rest["unchecked"]]
    print(f"at rest: {len(at_rest)} overlapping pairs of {rest['pairs_candidate']} candidates, "
          f"{len(rest['unchecked'])} not checked ({time.time() - t0:.0f} s)")

    if "--rest" not in sys.argv:
        same = [[c + ":1", c + ":1"] for c in COMPONENTS]             # pairs inside one component do not move
        for study, joint, lo, hi, unit in STUDIES:
            t0 = time.time()
            values = [lo + (hi - lo) * k / steps for k in range(1, steps + 1)]
            cmds = []
            for v in values:
                cmds += [{"command": "joint.drive", "params": {"joint": joint, "value": v}},
                         {"command": "inspect.interference", "params": {"budget_s": 1800, "exclude_pairs": same}}]
            res = run(cmds, study.replace(" ", "_").lower())
            new, unchecked = {}, set()
            for k, v in enumerate(values):
                r = res[2 * k + 1]
                unchecked |= {tuple(sorted((u["a"], u["b"]))) for u in r["unchecked"]}
                for key, (vol, ca, cb) in pairs(r).items():
                    grew = vol - at_rest.get(key, (0.0,))[0]
                    if grew > max(MIN_VOLUME, 1e-3 * vol) and vol > new.get(key, (0.0,))[0]:
                        new[key] = (vol, v, ca, cb)
            lines += ["", f"## {study}: {joint} {lo:g} .. {hi:g} {unit}, {steps} poses, bodies of different components", ""]
            if new:
                lines += [f"| body | body | largest overlap mm3 | at {unit} | at rest mm3 |", "|---|---|---:|---:|---:|"]
                lines += [f"| {a} | {b} | {vol:.2f} | {v:g} | {at_rest.get((a, b), (0.0,))[0]:.2f} |"
                          for (a, b), (vol, v, ca, cb) in sorted(new.items(), key=lambda kv: -kv[1][0])]
            else:
                lines.append("No overlap beyond those at rest.")
            if unchecked:
                lines += ["", f"Not checked at some pose: {', '.join(f'{a} / {b}' for a, b in sorted(unchecked))}"]
            print(f"{study}: {len(new)} pairs overlap more than at rest, {len(unchecked)} not checked ({time.time() - t0:.0f} s)")
    out = os.path.join(BUILD, "interference.md")
    open(out, "w").write("\n".join(lines) + "\n")
    print("wrote", os.path.relpath(out, HERE))


if __name__ == "__main__":
    main()
