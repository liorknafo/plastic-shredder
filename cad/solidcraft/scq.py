"""scq.py -- a CSG tree in the shape of the old OpenSCAD sources that compiles to a SolidCraft command script.

The model modules (cad/solidcraft/model/*.py) build trees with the functions below (cube, cylinder, linear_extrude,
translate, rotate, difference, hull ...: same names, same argument meaning and same frames as OpenSCAD), and
`Script.build(node, name)` lowers a tree to native SolidCraft features: boxes, cylinders, cones, spheres and sketch
extrudes on the planes the transforms lead to, combined with cut / join / intersect.  Nothing is meshed: a circle is a
circle, the hull of circles is lines and arcs.

Differences from OpenSCAD, on purpose:
  * $fn is ignored (round is round).  Pass fn= only where the source used a small $fn to MAKE a polygon (fn=6: a hexagon).
  * transforms must be rigid (rotation, translation, mirror); `scale` does not exist.
  * hull() and offset() are 2D only, of circles, squares and polygons (the result is lines and arcs).
  * a 2D difference whose holes lie inside the outline is ONE sketch (outline + holes) and one extrude.

Standard library only.
"""
import math

CUT_GROW = 1.0          # a hole that comes from a 2D difference is cut this much past both faces of the extrusion
POLY_FN = 12            # fn up to this means "a polygon", above it "a circle"


__all__ = ["cube", "cylinder", "sphere", "linear_extrude", "prismoid", "circle", "square", "polygon", "hull", "offset",
           "translate", "rotate", "mirror", "multmatrix", "union", "difference", "intersection", "color", "part", "Script", "Node",
           "sin", "cos", "tan", "asin", "acos", "atan", "atan2", "sqrt", "floor", "ceil", "norm", "PI"]

# ------------------------------------------------------------------------------------------------ OpenSCAD's maths (degrees)
PI = math.pi
sqrt, floor, ceil = math.sqrt, math.floor, math.ceil


def sin(a):
    return math.sin(math.radians(a))


def cos(a):
    return math.cos(math.radians(a))


def tan(a):
    return math.tan(math.radians(a))


def asin(x):
    return math.degrees(math.asin(x))


def acos(x):
    return math.degrees(math.acos(x))


def atan(x):
    return math.degrees(math.atan(x))


def atan2(y, x):
    return math.degrees(math.atan2(y, x))


def norm(v):
    return math.sqrt(sum(c * c for c in v))


# ------------------------------------------------------------------------------------------------ matrices (4x4, rows)
I4 = [[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]]


def mmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def pt(m, p):
    x, y, z = p
    return [m[i][0] * x + m[i][1] * y + m[i][2] * z + m[i][3] for i in range(3)]


def vec(m, v):
    x, y, z = v
    return [m[i][0] * x + m[i][1] * y + m[i][2] * z for i in range(3)]


def _unit(v):
    n = math.sqrt(sum(c * c for c in v))
    return [c / n for c in v]


def _cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def _dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def _num(x):
    x = round(float(x), 9)
    return 0.0 if x == 0 else x


def _nums(v):
    return [_num(c) for c in v]


def m_translate(v):
    v = list(v) + [0.0] * (3 - len(v))
    return [[1.0, 0.0, 0.0, v[0]], [0.0, 1.0, 0.0, v[1]], [0.0, 0.0, 1.0, v[2]], [0.0, 0.0, 0.0, 1.0]]


def m_axis_angle(axis, deg):
    x, y, z = _unit(axis)
    a = math.radians(deg)
    c, s, t = math.cos(a), math.sin(a), 1 - math.cos(a)
    return [[t * x * x + c, t * x * y - s * z, t * x * z + s * y, 0.0],
            [t * x * y + s * z, t * y * y + c, t * y * z - s * x, 0.0],
            [t * x * z - s * y, t * y * z + s * x, t * z * z + c, 0.0],
            [0.0, 0.0, 0.0, 1.0]]


def m_rotate(a):
    """OpenSCAD rotate(a): a number turns about z, [x, y, z] turns about x, then y, then z."""
    if isinstance(a, (int, float)):
        return m_axis_angle([0, 0, 1], a)
    a = list(a) + [0.0] * (3 - len(a))
    m = I4
    for axis, deg in (([1, 0, 0], a[0]), ([0, 1, 0], a[1]), ([0, 0, 1], a[2])):
        if deg:
            m = mmul(m_axis_angle(axis, deg), m)
    return m


def m_mirror(n):
    n = list(n) + [0.0] * (3 - len(n))
    if not any(n):                                            # OpenSCAD: mirror([0, 0, 0]) changes nothing
        return I4
    n = _unit(n)
    m = [[(1.0 if i == j else 0.0) - 2 * n[i] * n[j] for j in range(3)] + [0.0] for i in range(3)]
    return m + [[0.0, 0.0, 0.0, 1.0]]


def m_from(rows):
    """A 3x4 or 4x4 matrix as OpenSCAD's multmatrix takes it."""
    rows = [list(map(float, r)) for r in rows]
    if len(rows) == 3:
        rows.append([0.0, 0.0, 0.0, 1.0])
    return rows


# ------------------------------------------------------------------------------------------------ the tree
class Node:
    __slots__ = ("kind", "dim", "ch", "a")

    def __init__(self, kind, dim, ch=(), **a):
        self.kind, self.dim, self.ch, self.a = kind, dim, list(ch), a

    def __repr__(self):
        return f"<{self.kind}{self.dim}d {self.a if self.kind != 'T' else ''} {self.ch}>"


def _flat(args):
    out = []
    for x in args:
        if x is None:
            continue
        if isinstance(x, Node):
            out.append(x)
        else:
            out.extend(_flat(x))
    return out


def _dim(ch):
    dims = {c.dim for c in ch}
    assert len(dims) <= 1, "2D and 3D children mixed"
    return dims.pop() if dims else 3


def _xf(m, ch):
    ch = _flat(ch)
    return Node("T", _dim(ch), ch, m=m) if ch else None


def translate(v, *ch):
    return _xf(m_translate(v), ch)


def rotate(a, *ch, v=None):
    """rotate(a, ...) as OpenSCAD's rotate(a); with v=[x, y, z]: `a` degrees about that axis."""
    return _xf(m_axis_angle(v, a) if v is not None else m_rotate(a), ch)


def mirror(n, *ch):
    return _xf(m_mirror(n), ch)


def multmatrix(rows, *ch):
    return _xf(m_from(rows), ch)


def _bool(kind, ch):
    ch = _flat(ch)
    if not ch:
        return None
    return ch[0] if len(ch) == 1 and kind == "union" else Node(kind, _dim(ch), ch)


def union(*ch):
    return _bool("union", ch)


def intersection(*ch):
    return _bool("intersection", ch)


def difference(a, *ch):
    """a minus every other child.  `a` None (an empty first child) gives nothing, as in OpenSCAD."""
    if a is None or (not isinstance(a, Node) and not _flat([a])):
        return None
    a = union(a)
    ch = _flat(ch)
    return Node("difference", a.dim, [a] + ch) if ch else a


def color(_c, *ch, alpha=None):
    return union(*ch)


def part(name, *ch):
    """One made or bought part: at the top of a body's tree it becomes a body of its own with this name (a second
    part of the same name is `name (2)`, and so on).  Anywhere else (inside a difference ...) it is just its shape."""
    ch = _flat(ch)
    return Node("part", 3, ch, name=name) if ch else None


def _size(size, n):
    return [float(size)] * n if isinstance(size, (int, float)) else [float(s) for s in size]


def cube(size, center=False):
    return Node("cube", 3, size=_size(size, 3), center=center)


def cylinder(h, r=None, d=None, r1=None, r2=None, d1=None, d2=None, center=False, fn=None):
    if r is None and d is not None:
        r = d / 2
    if r1 is None:
        r1 = d1 / 2 if d1 is not None else r
    if r2 is None:
        r2 = d2 / 2 if d2 is not None else r
    return Node("cylinder", 3, h=float(h), r1=float(r1), r2=float(r2), center=center, fn=fn)


def sphere(r=None, d=None):
    return Node("sphere", 3, r=float(r if r is not None else d / 2))


def linear_extrude(height, *ch, center=False):
    ch = _flat(ch)
    return Node("extrude", 3, ch, h=float(height), center=center) if ch else None


def prismoid(bottom, top, height):
    """A loft with straight sides between two polygons with the same number of corners: `bottom` in the plane z = 0,
    `top` in z = height (what OpenSCAD's hull() of two thin slabs made: a funnel wall, a tapered block)."""
    assert len(bottom) == len(top) >= 3
    return Node("prismoid", 3, bottom=[(float(p[0]), float(p[1])) for p in bottom],
                top=[(float(p[0]), float(p[1])) for p in top], h=float(height))


def circle(r=None, d=None, fn=None):
    return Node("circle", 2, r=float(r if r is not None else d / 2), fn=fn)


def square(size, center=False):
    return Node("square", 2, size=_size(size, 2), center=center)


def polygon(points):
    return Node("polygon", 2, pts=[(float(p[0]), float(p[1])) for p in points])


def hull(*ch):
    ch = _flat(ch)
    assert ch and _dim(ch) == 2, "hull() is 2D only here: model a 3D hull with the features it stands for"
    return Node("hull", 2, ch)


def offset(*ch, r=None, delta=None):
    """offset(r=) rounds, as in OpenSCAD.  offset(delta=) is only taken of round shapes (circles and their hulls)."""
    ch = _flat(ch)
    return Node("offset", 2, ch, r=r, delta=delta)


# ------------------------------------------------------------------------------------------------ 2D loops
class Loop:
    """A closed outline: a full circle, or segments ("L", p0, p1) and ("A", centre, radius, p0, p1, ccw)."""

    def __init__(self, segs=None, circle=None):
        self.segs, self.circle = segs, circle

    def sample(self, step_deg=6.0):
        if self.circle:
            (cx, cy), r = self.circle
            n = max(12, int(360 / step_deg))
            return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]
        out = []
        for s in self.segs:
            if s[0] == "L":
                out.append(s[1])
            else:
                _, c, r, p0, p1, ccw = s
                a0 = math.atan2(p0[1] - c[1], p0[0] - c[0])
                a1 = math.atan2(p1[1] - c[1], p1[0] - c[0])
                sweep = (a1 - a0) % (2 * math.pi) if ccw else -((a0 - a1) % (2 * math.pi))
                n = max(2, int(abs(math.degrees(sweep)) / step_deg) + 1)
                out.extend((c[0] + r * math.cos(a0 + sweep * i / n), c[1] + r * math.sin(a0 + sweep * i / n)) for i in range(n))
        return out

    def bbox(self):
        if self.circle:
            (cx, cy), r = self.circle
            return (cx - r, cy - r, cx + r, cy + r)
        p = self.sample(2.0)
        return (min(q[0] for q in p), min(q[1] for q in p), max(q[0] for q in p), max(q[1] for q in p))


def _poly_loop(pts):
    out = []
    for p in pts:                                             # drop repeated points
        if not out or math.dist(p, out[-1]) > 1e-9:
            out.append(p)
    if len(out) > 1 and math.dist(out[0], out[-1]) <= 1e-9:
        out.pop()
    assert len(out) >= 3, "a polygon needs three points"
    return Loop(segs=[("L", out[i], out[(i + 1) % len(out)]) for i in range(len(out))])


def _hull_loop(gens):
    """Convex hull of circles (centre, radius; radius 0 is a point): lines and arcs, counter-clockwise."""
    g = []
    for c, r in gens:                                         # drop a generator inside another
        if any(math.dist(c, oc) + r <= orr + 1e-12 for oc, orr in g):
            continue
        g = [(oc, orr) for oc, orr in g if math.dist(c, oc) + orr > r + 1e-12] + [(c, r)]
    if len(g) == 1:
        assert g[0][1] > 0, "hull of a single point"
        return Loop(circle=(g[0][0], g[0][1]))
    cand = []
    for i in range(len(g)):
        for j in range(i + 1, len(g)):
            dx, dy = g[i][0][0] - g[j][0][0], g[i][0][1] - g[j][0][1]
            dist = math.hypot(dx, dy)
            q = (g[j][1] - g[i][1]) / dist
            if abs(q) <= 1:
                phi = math.atan2(dy, dx)
                cand += [(phi + math.acos(q)) % (2 * math.pi), (phi - math.acos(q)) % (2 * math.pi)]
    cand.sort()
    angles = []
    for a in cand:
        if not angles or a - angles[-1] > 1e-10:
            angles.append(a)
    if len(angles) > 1 and angles[0] + 2 * math.pi - angles[-1] <= 1e-10:
        angles.pop()

    def active(th):
        return max(range(len(g)), key=lambda i: g[i][0][0] * math.cos(th) + g[i][0][1] * math.sin(th) + g[i][1])

    spans = []                                               # [start angle, end angle, generator]
    for k, a in enumerate(angles):
        b = angles[(k + 1) % len(angles)] + (2 * math.pi if k + 1 == len(angles) else 0)
        i = active((a + b) / 2)
        if spans and spans[-1][2] == i:
            spans[-1][1] = b
        else:
            spans.append([a, b, i])
    if len(spans) > 1 and spans[0][2] == spans[-1][2]:
        spans[0][0] = spans[-1][0] - 2 * math.pi
        spans.pop()

    def on(i, th):
        (cx, cy), r = g[i]
        return (cx + r * math.cos(th), cy + r * math.sin(th))

    segs = []
    for k, (a, b, i) in enumerate(spans):
        p0, p1 = on(i, a), on(i, b)
        if g[i][1] > 1e-12 and b - a > 1e-12:
            segs.append(("A", g[i][0], g[i][1], p0, p1, True))
        q = on(spans[(k + 1) % len(spans)][2], b)
        if math.dist(p1, q) > 1e-9:
            segs.append(("L", p1, q))
    return Loop(segs=segs)


def _p2(m, p):
    return (m[0][0] * p[0] + m[0][1] * p[1] + m[0][3], m[1][0] * p[0] + m[1][1] * p[1] + m[1][3])


def _check2d(m):
    assert abs(m[2][0]) + abs(m[2][1]) + abs(m[0][2]) + abs(m[1][2]) + abs(m[2][3]) < 1e-9, "a 2D shape left its plane"


def _gens(n, A, grow):
    k = n.kind
    if k == "T":
        m = mmul(A, n.a["m"])
        _check2d(m)
        return [x for c in n.ch for x in _gens(c, m, grow)]
    if k in ("hull", "union"):
        return [x for c in n.ch for x in _gens(c, A, grow)]
    if k == "offset":
        assert n.a["r"] is not None or all(_round(c) for c in n.ch), "offset(delta=) of a shape with corners"
        return [x for c in n.ch for x in _gens(c, A, grow + (n.a["r"] if n.a["r"] is not None else n.a["delta"]))]
    if k == "circle":
        if n.a["fn"] and n.a["fn"] <= POLY_FN:
            return [(p, grow) for p in _ngon(n.a["r"], n.a["fn"], A)]
        return [(_p2(A, (0, 0)), n.a["r"] + grow)]
    if k == "square":
        return [(p, grow) for p in _square_pts(n, A)]
    if k == "polygon":
        return [(_p2(A, p), grow) for p in n.a["pts"]]
    raise NotImplementedError(f"hull / offset of {k}")


def _round(n):
    if n.kind == "circle":
        return not (n.a["fn"] and n.a["fn"] <= POLY_FN)
    if n.kind in ("T", "hull", "union", "offset"):
        return all(_round(c) for c in n.ch)
    return False


def _ngon(r, fn, A):
    return [_p2(A, (r * math.cos(2 * math.pi * i / fn), r * math.sin(2 * math.pi * i / fn))) for i in range(int(fn))]


def _square_pts(n, A):
    sx, sy = n.a["size"]
    x0, y0 = (-sx / 2, -sy / 2) if n.a["center"] else (0.0, 0.0)
    return [_p2(A, p) for p in ((x0, y0), (x0 + sx, y0), (x0 + sx, y0 + sy), (x0, y0 + sy))]


def _is_prim2(n):
    if n.kind == "T":
        return len(n.ch) == 1 and _is_prim2(n.ch[0])
    return n.kind in ("circle", "square", "polygon", "hull", "offset")


def _loop(n, A):
    k = n.kind
    if k == "T":
        m = mmul(A, n.a["m"])
        _check2d(m)
        return _loop(n.ch[0], m)
    if k == "circle":
        if n.a["fn"] and n.a["fn"] <= POLY_FN:
            return _poly_loop(_ngon(n.a["r"], n.a["fn"], A))
        return Loop(circle=(_p2(A, (0, 0)), n.a["r"]))
    if k == "square":
        return _poly_loop(_square_pts(n, A))
    if k == "polygon":
        return _poly_loop([_p2(A, p) for p in n.a["pts"]])
    return _hull_loop(_gens(n, A, 0.0))


def _inside(inner, outer):
    """Every point of `inner` strictly inside `outer` (sampled; conservative)."""
    poly = outer.sample(3.0)
    if outer.circle:
        (cx, cy), r = outer.circle
        return all(math.hypot(p[0] - cx, p[1] - cy) < r - 1e-6 for p in inner.sample(3.0))
    for p in inner.sample(3.0):
        hit = False
        for i in range(len(poly)):
            (x1, y1), (x2, y2) = poly[i], poly[(i + 1) % len(poly)]
            if (y1 > p[1]) != (y2 > p[1]) and p[0] < (x2 - x1) * (p[1] - y1) / (y2 - y1) + x1:
                hit = not hit
            dx, dy = x2 - x1, y2 - y1
            t = max(0.0, min(1.0, ((p[0] - x1) * dx + (p[1] - y1) * dy) / (dx * dx + dy * dy or 1.0)))
            if math.hypot(p[0] - x1 - t * dx, p[1] - y1 - t * dy) < 1e-4:
                return False
        if not hit:
            return False
    return True


def _apart(a, b):
    (ax0, ay0, ax1, ay1), (bx0, by0, bx1, by1) = a.bbox(), b.bbox()
    g = 1e-6
    return ax1 + g < bx0 or bx1 + g < ax0 or ay1 + g < by0 or by1 + g < ay0


def _leaves2(nodes, A):
    """The shapes of a 2D union as (node, matrix), through transforms and unions."""
    out = []
    for n in nodes:
        if n.kind == "T" and not _is_prim2(n):
            out += _leaves2(n.ch, mmul(A, n.a["m"]))
        elif n.kind == "union":
            out += _leaves2(n.ch, A)
        else:
            out.append((n, A))
    return out


# ------------------------------------------------------------------------------------------------ the script
class Script:
    """Collects SolidCraft commands.  `build` lowers one tree to one named body."""

    def __init__(self, folders=False):
        self.steps = []
        self.folders = folders                  # one timeline folder per body, holding its sketches and features
        self._feats = []
        self.label = "part"
        self._nb = 0
        self._nf = {}
        self._names = {}

    def step(self, command, **params):
        self.steps.append({"command": command, "params": params})

    def _name(self, kind=""):
        n = self._nf.get((self.label, kind), 0) + 1
        self._nf[(self.label, kind)] = n
        name = f"{self.label} {kind}{n}"
        self._feats.append(name)
        return name

    def _done(self, body):
        """The body just built gets its name, and its features go into one timeline folder of that name."""
        feats, self._feats = self._feats, []
        if body is None:
            return False
        self.step("body.rename", body=body, name=self.label)
        if self.folders and feats:
            self.step("timeline.group", name=self.label, features=feats)
        return True

    def build(self, node, name, color=None, opacity=1.0, material=None, split=True):
        """The bodies of one tree: every `part` at the top of the tree is a body of its own, whatever else is there
        is ONE body called `name` (its pieces need not touch).  split=False: one body, whatever the tree names.
        Returns the names of the bodies made."""
        items = []

        def walk(n, M):
            if n.kind == "T":
                for c in n.ch:
                    walk(c, mmul(M, n.a["m"]))
            elif n.kind == "union" or (n.kind == "part" and not split):
                for c in n.ch:
                    walk(c, M)
            else:
                items.append((n, M))

        node = union(node)
        if node is not None:
            walk(node, I4)
        made = []
        rest = [(n, M) for n, M in items if n.kind != "part"]
        if rest:
            self.label, body = self._unique(name), None
            for n, M in rest:
                body = self._emit(n, M, "new" if body is None else "join", body)
            if self._done(body):
                made.append(self.label)
        for n, M in items:
            if n.kind == "part":
                self.label = self._unique(n.a["name"])
                if self._done(self._many(n.ch, M, "new", None)):
                    made.append(self.label)
        if made and material:
            self.step("material.assign", bodies=made, material=material)
        if made and color:
            self.step("appearance.assign", bodies=made, color=color, opacity=opacity)
        return made

    def _unique(self, name):
        n = self._names.get(name, 0) + 1
        self._names[name] = n
        return name if n == 1 else f"{name} ({n})"

    # ---- 3D
    def _many(self, ch, M, op, tgt):
        if not ch:
            return tgt
        if op == "intersect" and len(ch) > 1:
            return self._combine(tgt, self._many(ch, M, "new", None), op)
        for c in ch:
            if op == "new":
                tgt = self._emit(c, M, "new", None)
                op = "join" if tgt is not None else "new"
            else:
                self._emit(c, M, op, tgt)
        return tgt

    def _emit(self, n, M, op, tgt):
        assert n.dim == 3, f"a 2D shape ({n.kind}) used as a solid: wrap it in linear_extrude"
        k = n.kind
        if k == "T":
            return self._many(n.ch, mmul(M, n.a["m"]), op, tgt)
        if k in ("union", "part"):
            return self._many(n.ch, M, op, tgt)
        if k in ("difference", "intersection"):
            if op != "new":
                return self._combine(tgt, self._emit(n, M, "new", None), op)
            body = self._emit(n.ch[0], M, "new", None)
            for c in n.ch[1:]:
                if body is not None:
                    self._emit(c, M, "cut" if k == "difference" else "intersect", body)
            return body
        if k == "cube":
            return self._cube(n, M, op, tgt)
        if k == "cylinder":
            return self._cylinder(n, M, op, tgt)
        if k == "sphere":
            return self._prim("solid.sphere", dict(radius=_num(n.a["r"]), center=_nums(pt(M, [0, 0, 0]))), op, tgt)
        if k == "extrude":
            h = n.a["h"]
            return self._ext_many(n.ch, I4, M, h, -h / 2 if n.a["center"] else 0.0, op, tgt)
        if k == "prismoid":
            names = [self._sketch([_poly_loop(pts)], M, z) for pts, z in ((n.a["bottom"], 0.0), (n.a["top"], n.a["h"]))]
            return self._prim("solid.loft", dict(sections=[{"sketch": s} for s in names]), op, tgt)
        raise NotImplementedError(k)

    def _prim(self, command, params, op, tgt):
        params["name"] = self._name()
        if op == "new":
            self._nb += 1
            body = f"_b{self._nb}"
            self.step(command, operation="new", body_name=body, **params)
            return body
        if tgt is None:
            return None
        if op == "join":
            params["touching"] = "one_body"
        self.step(command, operation=op, targets=[tgt], **params)
        return tgt

    def _combine(self, tgt, tool, op):
        if tool is None or tgt is None:
            return tgt
        extra = {"touching": "one_body"} if op == "join" else {}
        self.step("solid.combine", target=tgt, tools=[tool], operation=op, name=self._name(), **extra)
        return tgt

    def _cube(self, n, M, op, tgt):
        s = n.a["size"]
        if min(s) <= 0:
            return tgt
        lo = [-c / 2 for c in s] if n.a["center"] else [0.0, 0.0, 0.0]
        lin = [M[i][j] for i in range(3) for j in range(3)]
        if all(abs(v) < 1e-9 or abs(abs(v) - 1) < 1e-9 for v in lin):          # the axes stay on the axes
            p0, p1 = pt(M, lo), pt(M, [lo[i] + s[i] for i in range(3)])
            dims = [abs(p1[i] - p0[i]) for i in range(3)]
            return self._prim("solid.box", dict(length=_num(dims[0]), width=_num(dims[1]), height=_num(dims[2]),
                                                corner=_nums([min(p0[i], p1[i]) for i in range(3)])), op, tgt)
        rect = _poly_loop([(lo[0], lo[1]), (lo[0] + s[0], lo[1]), (lo[0] + s[0], lo[1] + s[1]), (lo[0], lo[1] + s[1])])
        return self._sketch_extrude([rect], M, s[2], lo[2], op, tgt)

    def _cylinder(self, n, M, op, tgt):
        h, r1, r2, fn = n.a["h"], n.a["r1"], n.a["r2"], n.a["fn"]
        if h <= 0 or max(r1, r2) <= 0:
            return tgt
        z0 = -h / 2 if n.a["center"] else 0.0
        if fn and fn <= POLY_FN:
            assert r1 == r2, "a tapered prism"
            return self._sketch_extrude([_poly_loop(_ngon(r1, fn, I4))], M, h, z0, op, tgt)
        axis = _unit(vec(M, [0, 0, 1]))
        if r1 == r2:
            return self._prim("solid.cylinder", dict(radius=_num(r1), height=_num(h), base=_nums(pt(M, [0, 0, z0])),
                                                     axis=_nums(axis)), op, tgt)
        if r1 == 0:                                                              # the apex goes on top
            return self._prim("solid.cone", dict(radius=_num(r2), top_radius=0, height=_num(h),
                                                 base=_nums(pt(M, [0, 0, z0 + h])), axis=_nums([-c for c in axis])), op, tgt)
        return self._prim("solid.cone", dict(radius=_num(r1), top_radius=_num(r2), height=_num(h),
                                             base=_nums(pt(M, [0, 0, z0])), axis=_nums(axis)), op, tgt)

    # ---- extrusions of 2D trees
    def _ext_many(self, ch, A, M, h, z0, op, tgt):
        if not ch:
            return tgt
        if op == "intersect" and len(ch) > 1:
            return self._combine(tgt, self._ext_many(ch, A, M, h, z0, "new", None), op)
        for c in ch:
            if op == "new":
                tgt = self._ext(c, A, M, h, z0, "new", None)
                op = "join" if tgt is not None else "new"
            else:
                self._ext(c, A, M, h, z0, op, tgt)
        return tgt

    def _ext(self, n, A, M, h, z0, op, tgt):
        assert n.dim == 2, f"a solid ({n.kind}) inside linear_extrude"
        if _is_prim2(n):
            return self._sketch_extrude([_loop(n, A)], M, h, z0, op, tgt)
        k = n.kind
        if k == "T":
            m = mmul(A, n.a["m"])
            _check2d(m)
            return self._ext_many(n.ch, m, M, h, z0, op, tgt)
        if k == "union":
            return self._ext_many(n.ch, A, M, h, z0, op, tgt)
        if op != "new":
            return self._combine(tgt, self._ext(n, A, M, h, z0, "new", None), op)
        if k == "intersection":
            body = self._ext(n.ch[0], A, M, h, z0, "new", None)
            for c in n.ch[1:]:
                self._ext(c, A, M, h, z0, "intersect", body)
            return body
        assert k == "difference", k
        tools = _leaves2(n.ch[1:], A)
        loops = [(_loop(t, At) if _is_prim2(t) else None, t, At) for t, At in tools]
        holes, cuts = [], []
        if _is_prim2(n.ch[0]):                                                  # outline + holes: one sketch, one extrude
            outer = _loop(n.ch[0], A)
            for lp, t, At in loops:
                if lp is not None and _inside(lp, outer) and all(_apart(lp, o) for o in holes):
                    holes.append(lp)
                else:
                    cuts.append((lp, t, At))
            body = self._sketch_extrude([outer] + holes, M, h, z0, "new", None)
        else:
            body = self._ext(n.ch[0], A, M, h, z0, "new", None)
            cuts = loops
        groups = []                                                              # loops that keep apart share a cut
        for lp, t, At in cuts:
            if lp is None:
                self._combine(body, self._ext(t, At, M, h + 2 * CUT_GROW, z0 - CUT_GROW, "new", None), "cut")
                continue
            for grp in groups:
                if all(_apart(lp, o) for o in grp):
                    grp.append(lp)
                    break
            else:
                groups.append([lp])
        for grp in groups:
            self._sketch_extrude(grp, M, h + 2 * CUT_GROW, z0 - CUT_GROW, "cut", body)
        return body

    def _sketch_extrude(self, loops, M, h, z0, op, tgt):
        if h <= 0 or (op != "new" and tgt is None):
            return tgt
        name = self._sketch(loops, M, z0)
        params = dict(distance=_num(h), sketch=name)
        if _dot(_cross(vec(M, [1, 0, 0]), vec(M, [0, 1, 0])), vec(M, [0, 0, 1])) < 0:
            params["direction"] = "negative"
        return self._prim("solid.extrude", params, op, tgt)

    def _sketch(self, loops, M, z0):
        """A finished sketch of the loops on the plane z = z0 of the frame M.  Returns its name."""
        xd, yd = _unit(vec(M, [1, 0, 0])), _unit(vec(M, [0, 1, 0]))
        assert abs(_dot(xd, yd)) < 1e-9, "a sheared sketch plane"
        name = self._name("sketch ")
        self.step("sketch.create", plane=dict(origin=_nums(pt(M, [0, 0, z0])), x_dir=_nums(xd), y_dir=_nums(yd)), name=name)
        for lp in loops:
            self._draw(lp)
        self.step("sketch.finish")
        return name

    def _draw(self, lp):
        if lp.circle:
            self.step("sketch.circle.center", center=_nums(lp.circle[0]), radius=_num(lp.circle[1]))
            return
        if all(s[0] == "L" for s in lp.segs):
            self.step("sketch.line", points=[_nums(s[1]) for s in lp.segs], closed=True)
            return
        run = []

        def flush():
            if len(run) > 1:
                self.step("sketch.line", points=[_nums(p) for p in run])
            run.clear()

        for s in lp.segs:
            if s[0] == "L":
                if not run:
                    run.append(s[1])
                run.append(s[2])
            else:
                flush()
                self.step("sketch.arc.center_point", center=_nums(s[1]), start=_nums(s[3]), end=_nums(s[4]),
                          clockwise=not s[5])
        flush()
