#!/usr/bin/env python3
"""snapshots.py -- renders cad/png/solidcraft_*.png from cad/shredder_assembly.sc with solidcraft-cli (iso at rest, rotors 60 deg, drawer 180 mm, lid 100 deg, sections)."""
import json, os, subprocess, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
CLI = os.environ.get("SOLIDCRAFT_CLI", "/Applications/SolidCraft.app/Contents/MacOS/solidcraft-cli")
SC = os.path.join(CAD, "shredder_assembly.sc")
PNG = os.path.join(CAD, "png")
os.makedirs(PNG, exist_ok=True)

def cam(target, yaw, pitch, dist):
    return json.dumps({"target": target, "yaw": yaw, "pitch": pitch, "distance": dist})

SHOTS = [   # name, joint drives, camera, extra args
    ("iso_rest",         [], cam([0, 0, -60], -0.8, 0.45, 1000), []),
    ("rotors_60deg",     [("Shaft A", 60)], cam([60, 0, 0], -0.8, 0.6, 450), []),
    ("drawer_180mm",     [("Drawer slide", 180)], cam([60, -100, -150], -0.8, 0.35, 1100), []),
    ("lid_open_100deg",  [("Lid hinge", 100)], cam([60, 0, 200], -0.8, 0.3, 900), []),
    ("section_x66",      [], cam([66, 0, -60], -1.9, 0.25, 1000), ["--section", "x=66.1"]),
    ("section_blades",   [("Shaft A", 60)], cam([66, 0, 0], -1.9, 0.2, 330), ["--section", "x=66.1"]),
]

for name, drives, camera, extra in SHOTS:
    cmds = [{"command": "joint.drive", "params": {"joint": j, "value": v}} for j, v in drives]
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(cmds, f)
    out = os.path.join(PNG, f"solidcraft_{name}.png")
    r = subprocess.run([CLI, "snapshot", f.name, "--in", SC, "--out", out, "--width", "1600", "--height", "1000", "--camera", camera, "--no-grid", "--no-axes"] + extra,
                       capture_output=True, text=True)
    os.unlink(f.name)
    print(name, "ok" if r.returncode == 0 else r.stderr[-300:])
