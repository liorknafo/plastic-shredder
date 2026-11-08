#!/usr/bin/env python3
"""export_parts.py -- step 1 of the SolidCraft build: OpenSCAD -> one STL per body -> one coloured 3MF per component, and axes.json.

usage: export_parts.py [--force] [--jobs N]
  build/stl/<key>[_A|_B].stl   one per body (parts.scad, -D sel=<key> [-D sh=A|B])
  build/<component>.3mf        the bodies of one component, coloured, one object per body
  build/axes.json              joint geometry echoed by axes.scad
Needs openscad (>= 2025, manifold backend) on PATH.  Skips STLs newer than every cad/*.scad and parts.scad (--force: rebuild all).
"""
import argparse, json, os, re, struct, subprocess, sys, zipfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
CAD = os.path.dirname(HERE)
BUILD = os.path.join(HERE, "build")
STL = os.path.join(BUILD, "stl")
sys.path.insert(0, HERE)
import manifest

ENV = dict(os.environ, OPENSCADPATH=CAD)


def newest_source():
    t = 0
    for d in (CAD, HERE):
        for f in os.listdir(d):
            if f.endswith(".scad"):
                t = max(t, os.path.getmtime(os.path.join(d, f)))
    return t


def jobs():
    out = []
    for comp, bodies in manifest.COMPONENTS:
        for b in bodies:
            name, key, col, alpha = b[:4]
            sh = b[4] if len(b) > 4 else None
            out.append((comp, name, key, col, alpha, sh))
    return out


def stl_path(key, sh):
    return os.path.join(STL, key + (("_" + sh) if sh else "") + ".stl")


def run_openscad(job, newest, force):
    comp, name, key, col, alpha, sh = job
    p = stl_path(key, sh)
    if not force and os.path.exists(p) and os.path.getmtime(p) > newest:
        return p, "cached"
    cmd = ["openscad", "--backend=manifold", "--export-format", "binstl", "-D", f'sel="{key}"']
    if sh:
        cmd += ["-D", f'sh="{sh}"']
    cmd += ["-o", p, os.path.join(HERE, "parts.scad")]
    r = subprocess.run(cmd, env=ENV, capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(p):
        raise SystemExit(f"openscad failed for {key} {sh}:\n{r.stderr}")
    return p, "built"


def read_stl(path):
    d = open(path, "rb").read()
    n = struct.unpack_from("<I", d, 80)[0]
    verts, tris, off = {}, [], 84
    for _ in range(n):
        v = struct.unpack_from("<12f", d, off)
        off += 50
        t = []
        for j in range(3):
            k = (round(v[3 + 3 * j], 4), round(v[4 + 3 * j], 4), round(v[5 + 3 * j], 4))
            if k not in verts:
                verts[k] = len(verts)
            t.append(verts[k])
        if len(set(t)) == 3:
            tris.append(t)
    return list(verts), tris


def write_3mf(path, title, objs):
    """objs: [(name, '#rrggbb', alpha, stl_path)]"""
    mats, xml = [], []
    for i, (name, col, alpha, p) in enumerate(objs):
        verts, tris = read_stl(p)
        if not tris:
            print(f"  (empty body skipped: {name})")
            continue
        j = len(mats)
        mats.append(f'<base name="{name}" displaycolor="{col.upper()}{int(round(alpha * 255)):02X}"/>')
        vs = "".join(f'<vertex x="{x}" y="{y}" z="{z}"/>' for x, y, z in verts)
        ts = "".join(f'<triangle v1="{a}" v2="{b}" v3="{c}"/>' for a, b, c in tris)
        xml.append(f'<object id="{j + 2}" name="{name}" type="model" pid="1" pindex="{j}"><mesh><vertices>{vs}</vertices><triangles>{ts}</triangles></mesh></object>')
    items = "".join(f'<item objectid="{i + 2}"/>' for i in range(len(xml)))
    model = ('<?xml version="1.0" encoding="UTF-8"?><model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">'
             f'<metadata name="Title">{title}</metadata><resources><basematerials id="1">{"".join(mats)}</basematerials>{"".join(xml)}</resources><build>{items}</build></model>')
    ct = ('<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/></Types>')
    rels = ('<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", ct)
        z.writestr("_rels/.rels", rels)
        z.writestr("3D/3dmodel.model", model)
    return len(xml)


def comp_file(comp):
    return os.path.join(BUILD, re.sub(r"[^A-Za-z0-9]+", "_", comp).strip("_") + ".3mf")


def read_axes():
    r = subprocess.run(["openscad", "--backend=manifold", "-D", 'part="none"', "-o", os.path.join(BUILD, "axes.stl"), os.path.join(HERE, "axes.scad")],
                       env=ENV, capture_output=True, text=True)
    m = re.search(r"ECHO: AX = (\[.*\])", r.stderr + r.stdout)
    if not m:
        raise SystemExit("axes.scad printed no AX:\n" + r.stderr)
    ax = {k: v for k, v in json.loads(m.group(1))}
    json.dump(ax, open(os.path.join(BUILD, "axes.json"), "w"), indent=1)
    return ax


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 4) - 1))
    a = ap.parse_args()
    os.makedirs(STL, exist_ok=True)
    newest = newest_source()
    js = jobs()
    with ThreadPoolExecutor(a.jobs) as ex:
        res = list(ex.map(lambda j: run_openscad(j, newest, a.force), js))
    print(f"{sum(1 for _, s in res if s == 'built')} bodies built, {sum(1 for _, s in res if s == 'cached')} cached")
    ax = read_axes()
    print("axes:", ax)
    for comp, bodies in manifest.COMPONENTS:
        objs = []
        for b in bodies:
            name, key, col, alpha = b[:4]
            sh = b[4] if len(b) > 4 else None
            objs.append((name, col, alpha, stl_path(key, sh)))
        n = write_3mf(comp_file(comp), comp, objs)
        print(f"{comp}: {n} bodies -> {os.path.relpath(comp_file(comp), CAD)}")


if __name__ == "__main__":
    main()
