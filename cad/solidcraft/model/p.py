"""p.py -- every name of cad/params.scad (design/params.py through design/build.py) and the blade outline, as globals.

    from p import *

The values are the ones design/build.py writes to cad/params.scad (rounded to 4 decimals there), so the SolidCraft
model and the OpenSCAD sources read the same numbers.
"""
import importlib.util
import os
import sys

sys.dont_write_bytecode = True
_DESIGN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "design")


def _load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


_build = _load("design_build", os.path.join(_DESIGN, "build.py"))
globals().update(_build.params_values())

blade_outline_pts = [(round(x, 4), round(y, 4)) for x, y in _build.blade_outline()[0]]


def blade_hex(v):
    return [(round(x, 4), round(y, 4)) for x, y in _build.hex_bore(int(v))[0]]
