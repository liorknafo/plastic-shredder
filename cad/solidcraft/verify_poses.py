#!/usr/bin/env python3
"""verify_poses.py -- checks that the pose formulas of interference.py are SolidCraft's own: drives the saved design to a few values
and compares where SolidCraft puts each moving occurrence with interference.py's matrices (max point error, mm)."""
import json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import interference as I

CLI = os.environ.get("SOLIDCRAFT_CLI", "/Applications/SolidCraft.app/Contents/MacOS/solidcraft-cli")
SC = os.path.join(os.path.dirname(HERE), "shredder_assembly.sc")
PTS = [(10, 20, 30), (-150, -60, -140), (60, 80, 300), (-400, -90, -200)]
OCC = {"Rotor A": "Rotor A:1", "Rotor B": "Rotor B:1", "Torque limiter + output shaft": "Torque limiter + output shaft:1",
       "Worm + gearbox pulley": "Worm + gearbox pulley:1", "Motor shaft + pulley": "Motor shaft + pulley:1", "Lid": "Lid:1", "Drawer": "Drawer:1"}


def sc_poses(joint, value):
    cmds = [{"command": "joint.drive", "params": {"joint": joint, "value": value}}, {"command": "component.list", "params": {}}]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(cmds, f)
    r = subprocess.run([CLI, "run", f.name, "--in", SC, "--results"], capture_output=True, text=True)
    os.unlink(f.name)
    out = {}
    for c in json.loads(r.stdout)[-1]["components"]:
        for o in c.get("occurrences", []):
            out[o["name"]] = o["transform"]
    return out


def sc_apply(T, p):      # SolidCraft's transform is row-major with the translation in the last row (row vector * T)
    return tuple(sum(T[i][j] * p[i] for i in range(3)) + T[3][j] for j in range(3))


worst = 0.0
for joint, value, posef, arg in [("Shaft A", 77.0, I.study_a, 77.0), ("Lid hinge", 63.0, I.study_c, 63.0), ("Drawer slide", 123.0, I.study_b, 123.0)]:
    sc = sc_poses(joint, value)
    mine = posef(arg)
    for comp, M in mine.items():
        T = sc[OCC[comp]]
        err = max(max(abs(a - b) for a, b in zip(sc_apply(T, p), I.apply(M, p))) for p in PTS)
        # Worm / Motor turn many times: compare modulo the full turn, which the point test does implicitly
        worst = max(worst, err)
        print(f"{joint} {value}: {comp:34s} max point error {err:.4f} mm")
print("worst", round(worst, 4), "mm")
sys.exit(0 if worst < 0.05 else 1)
