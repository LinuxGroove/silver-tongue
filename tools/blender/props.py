"""Builds the Meridian's furniture and fittings and writes each one as a GLB.

Run from the repository root with a Python that has the `bpy` module (a Python 3.13 venv with
the bpy wheel):

    python tools/blender/props.py [prop ...]

Naming props (`sofa bar_stool`) rebuilds only those; `--list` prints them with their sizes.
They go to assets/models/hotel/, where `Kit` finds them by name.

Conventions:
  - Godot's axes throughout (x right, y up, z toward the viewer); converted to Blender's
    Z-up only when a mesh is made, and the glTF exporter turns that back into Y-up.
  - In metres. Floor props stand on y = 0, centred on their footprint, front facing +Z.
    Wall props (sconce, clock, notice board, drapes, keypad, bulkhead light) have their back
    on z = 0. Hanging props (chandelier, pendant) hang down from y = their height to y = 0,
    so they are placed at the ceiling minus their height. Door leaves hinge at the origin and
    span -x, their thickness centred on z = 0, like the kit's Door_1.
  - PBR colours with no textures except the rug and the ballroom's silk; edges are bevelled a
    few millimetres so they catch the light, and curved parts are smooth shaded. Triangle
    counts stay modest: the whole hotel has to hold 60 fps on a Steam Deck.
  - Material names carry through to Godot, which can dress them further by name: `velvet_*`
    get a sheen, `glass*` and `crystal` are see-through, `screen` is the CCTV's picture, and
    `bulb`, `flame` and `heat_lamp` glow.
  - Parts the game moves are their own nodes: the jacket rack's jackets (Jacket_1..5) and the
    clock's hands (HourHand, MinuteHand, pivoting at the clock's centre).
"""

import math
import os
import random
import sys

import bpy  # first: the bpy wheel provides bmesh and mathutils
import bmesh
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models", "hotel")
TEX = os.path.join(ROOT, "assets", "textures", "hotel")


# --- Materials ---------------------------------------------------------------------------------
# name: (sRGB colour, metallic, roughness, extras). Extras: alpha, emit (sRGB) and strength,
# tex (a file in TEX, mapped by the part's UVs).

MATERIALS = {
    "walnut": ("#3a2416", 0.0, 0.32, {}),
    "walnut_dark": ("#24160e", 0.0, 0.35, {}),
    "walnut_matte": ("#3a2416", 0.0, 0.6, {}),
    "oak": ("#7a5434", 0.0, 0.45, {}),
    "mahogany": ("#4a1d12", 0.0, 0.3, {}),
    "ebony": ("#141110", 0.0, 0.28, {}),
    "stage_floor": ("#2b1c12", 0.0, 0.42, {}),
    "brass": ("#d6ae58", 1.0, 0.28, {}),
    "brass_aged": ("#9a7638", 1.0, 0.42, {}),
    "gilt": ("#c9a050", 1.0, 0.36, {}),
    "chrome": ("#e4e4e4", 1.0, 0.12, {}),
    "steel": ("#bfc3c6", 1.0, 0.32, {}),
    "steel_dark": ("#55595c", 0.9, 0.45, {}),
    "iron": ("#1b1b1d", 0.4, 0.55, {}),
    "paint_white": ("#e9e6de", 0.0, 0.55, {}),
    "paint_cream": ("#e3d8c0", 0.0, 0.5, {}),
    "paint_locker": ("#5f6e6a", 0.35, 0.45, {}),
    "paint_grey": ("#7d8184", 0.3, 0.5, {}),
    "paint_green": ("#2f4a36", 0.25, 0.55, {}),
    "paint_bin": ("#2a2c2e", 0.0, 0.6, {}),
    "paint_door": ("#5a6266", 0.4, 0.45, {}),
    "marble_white": ("#e6e1d6", 0.0, 0.14, {}),
    "marble_black": ("#18181a", 0.0, 0.12, {}),
    "marble_green": ("#1e3a32", 0.0, 0.14, {}),
    "velvet_green": ("#1d3a2c", 0.0, 0.85, {}),
    "velvet_burgundy": ("#5e1420", 0.0, 0.85, {}),
    "velvet_navy": ("#1a2238", 0.0, 0.85, {}),
    "velvet_gold": ("#9a7a3a", 0.0, 0.8, {}),
    "leather_oxblood": ("#4e1a14", 0.0, 0.48, {}),
    "leather_black": ("#161312", 0.0, 0.45, {}),
    "linen": ("#eeebe3", 0.0, 0.85, {}),
    "cushion_cream": ("#e4d9c2", 0.0, 0.85, {}),
    "jacket_white": ("#f2f0ea", 0.0, 0.78, {}),
    "fabric_black": ("#161618", 0.0, 0.8, {}),
    "lampshade": ("#efe2c6", 0.0, 0.85, {"emit": "#ffd9a0", "strength": 0.6}),
    "glass": ("#c9d6d8", 0.0, 0.04, {"alpha": 0.22}),
    "glass_dark": ("#1c2224", 0.0, 0.06, {"alpha": 0.5}),
    "crystal": ("#eef0f8", 0.0, 0.04, {"emit": "#fff1d8", "strength": 0.7}),
    "mirror": ("#c8cccc", 1.0, 0.04, {}),
    "bottle_green": ("#1f3d26", 0.0, 0.08, {}),
    "bottle_amber": ("#6a3610", 0.0, 0.08, {}),
    "bottle_clear": ("#a8b4b0", 0.0, 0.06, {}),
    "bottle_blue": ("#1d3050", 0.0, 0.08, {}),
    "label_cream": ("#e8dcc0", 0.0, 0.7, {}),
    "bulb": ("#fff0d0", 0.0, 0.3, {"emit": "#ffd6a0", "strength": 6.0}),
    "flame": ("#ffc070", 0.0, 0.5, {"emit": "#ffb050", "strength": 8.0}),
    "heat_lamp": ("#ff8040", 0.0, 0.4, {"emit": "#ff6a2a", "strength": 5.0}),
    "led_red": ("#ff2a1a", 0.0, 0.4, {"emit": "#ff2010", "strength": 4.0}),
    "led_green": ("#40ff60", 0.0, 0.4, {"emit": "#30ff50", "strength": 3.0}),
    "screen": ("#2a3438", 0.0, 0.2, {"emit": "#7d97a3", "strength": 1.2}),
    "lantern_glass": ("#ffe2b0", 0.0, 0.1, {"emit": "#ffc880", "strength": 3.0}),
    "rubber": ("#121212", 0.0, 0.7, {}),
    "plastic_black": ("#18191b", 0.0, 0.4, {}),
    "paper": ("#f2eee4", 0.0, 0.85, {}),
    "cork": ("#a57a4c", 0.0, 0.9, {}),
    "leaf": ("#2c4a24", 0.0, 0.55, {}),
    "leaf_dark": ("#1d3318", 0.0, 0.6, {}),
    "soil": ("#2a1d14", 0.0, 0.95, {}),
    "rose_white": ("#f1ece2", 0.0, 0.7, {}),
    "rose_blush": ("#e2aca4", 0.0, 0.7, {}),
    "rose_red": ("#7c1420", 0.0, 0.7, {}),
    "wax": ("#f1e8d4", 0.0, 0.6, {}),
    "porcelain": ("#f4f2ec", 0.0, 0.18, {}),
    "cast_iron": ("#202022", 0.6, 0.5, {}),
    "pot_copper": ("#b06a3e", 1.0, 0.32, {}),
    "carpet_red": ("#6e1418", 0.0, 0.95, {}),
    "rope_velvet": ("#6a0f1c", 0.0, 0.75, {}),
    "wood_pallet": ("#9a7a52", 0.0, 0.85, {}),
    "cardboard": ("#a0784a", 0.0, 0.9, {}),
    "rug": ("#ffffff", 0.0, 0.95, {"tex": "rug_lobby.png"}),
    "silk": ("#ffffff", 0.0, 0.55, {"tex": "silk_stripe.png"}),
}


def lin(c):
    c = c / 255.0 if c > 1 else c
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rgb(hexstr):
    h = hexstr.lstrip("#")
    return tuple(lin(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def material(name):
    mat = bpy.data.materials.get(name)
    if mat:
        return mat
    colour, metal, rough, extra = MATERIALS[name]
    mat = bpy.data.materials.new(name)
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb(colour), 1.0)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    mat.diffuse_color = (*rgb(colour), 1.0)
    if "alpha" in extra:
        bsdf.inputs["Alpha"].default_value = extra["alpha"]
        mat.surface_render_method = "BLENDED"
    if "emit" in extra:
        bsdf.inputs["Emission Color"].default_value = (*rgb(extra["emit"]), 1.0)
        bsdf.inputs["Emission Strength"].default_value = extra.get("strength", 1.0)
    if "tex" in extra:
        img = bpy.data.images.load(os.path.join(TEX, extra["tex"]))
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


# --- Geometry, in Godot's axes ----------------------------------------------------------------

def rot_x(deg):
    return Matrix.Rotation(math.radians(deg), 4, "X")


def rot_y(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Y")


def rot_z(deg):
    return Matrix.Rotation(math.radians(deg), 4, "Z")


def move(x, y, z):
    return Matrix.Translation((x, y, z))


def scale(x, y, z):
    m = Matrix.Identity(4)
    m[0][0], m[1][1], m[2][2] = x, y, z
    return m


class Part:
    """A piece of a prop under construction: a bmesh in Godot's axes, one material."""

    def __init__(self, bm, mat, uv=None):
        self.bm = bm
        self.mat = mat
        self.uv = uv  # (axis_u, axis_v, scale_u, scale_v, offset_u, offset_v) planar mapping

    def xf(self, m):
        bmesh.ops.transform(self.bm, matrix=m, verts=self.bm.verts)
        if m.determinant() < 0:
            bmesh.ops.reverse_faces(self.bm, faces=self.bm.faces)
        return self

    def bevel(self, width, segments=2, angle=30.0):
        """Rounds every edge sharper than `angle` degrees."""
        if width <= 0:
            return self
        edges = [e for e in self.bm.edges if e.is_manifold and math.degrees(e.calc_face_angle(0.0)) > angle]
        if edges:
            bmesh.ops.bevel(self.bm, geom=edges, offset=width, offset_type="OFFSET", segments=segments,
                            profile=0.5, affect="EDGES", clamp_overlap=True)
        return self


def _bm_box(lo, hi):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    cx, cy, cz = [(a + b) / 2 for a, b in zip(lo, hi)]
    sx, sy, sz = [max(b - a, 1e-4) for a, b in zip(lo, hi)]
    bmesh.ops.transform(bm, matrix=move(cx, cy, cz) @ scale(sx, sy, sz), verts=bm.verts)
    return bm


def box(lo, hi, mat, bevel=0.004, seg=2, m=None, uv=None):
    p = Part(_bm_box(lo, hi), mat, uv)
    p.bevel(min(bevel, *(0.45 * (b - a) for a, b in zip(lo, hi))), seg)
    if m is not None:
        p.xf(m)
    return p


def _ring(bm, pts):
    return [bm.verts.new(p) for p in pts]


def _skin(bm, rings, closed=True):
    for a, b in zip(rings, rings[1:]):
        n = len(a)
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            try:
                bm.faces.new((a[i], a[j], b[j], b[i]))
            except ValueError:
                pass


def lathe(profile, mat, n=16, m=None, cap=(True, True), wobble=None, start=0.0, bevel=0.0):
    """A turned shape round the y axis: `profile` is [(radius, y), ...] from the bottom up.
    `wobble(angle, y)` may scale the radius (folds in cloth)."""
    bm = bmesh.new()
    rings = []
    for r, y in profile:
        pts = []
        for i in range(n):
            a = start + 2 * math.pi * i / n
            rr = r * (wobble(a, y) if wobble else 1.0)
            pts.append((rr * math.cos(a), y, -rr * math.sin(a)))
        rings.append(_ring(bm, pts))
    _skin(bm, rings)
    if cap[0] and profile[0][0] > 1e-5:
        bm.faces.new(list(reversed(rings[0])))
    if cap[1] and profile[-1][0] > 1e-5:
        bm.faces.new(rings[-1])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    p = Part(bm, mat)
    if bevel:
        p.bevel(bevel, 1, 50.0)
    if m is not None:
        p.xf(m)
    return p


def cyl(r, y0, y1, mat, n=16, m=None, bevel=0.003, r1=None):
    """A cylinder (or a cone frustum to radius `r1`) along y from y0 to y1."""
    p = lathe([(r, y0), (r if r1 is None else r1, y1)], mat, n)
    p.bevel(bevel, 1, 50.0)
    if m is not None:
        p.xf(m)
    return p


def _frames(pts):
    """Parallel-transported frames along a polyline."""
    tans = []
    for i in range(len(pts)):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        tans.append((b - a).normalized())
    up = Vector((0, 1, 0)) if abs(tans[0].y) < 0.9 else Vector((1, 0, 0))
    n = tans[0].cross(up).normalized()
    frames = []
    for t in tans:
        n = (n - t * n.dot(t))
        if n.length < 1e-6:
            n = t.orthogonal()
        n.normalize()
        frames.append((t, n, t.cross(n).normalized()))
    return frames


def tube(points, r, mat, n=8, m=None, caps=True, closed=False, radii=None):
    """A round tube along a polyline of points (Godot coordinates)."""
    pts = [Vector(p) for p in points]
    if closed:
        pts = pts + [pts[0]]
    bm = bmesh.new()
    rings = []
    for i, (p, (t, a, b)) in enumerate(zip(pts, _frames(pts))):
        rr = radii[i] if radii else r
        rings.append(_ring(bm, [p + (a * math.cos(2 * math.pi * k / n) + b * math.sin(2 * math.pi * k / n)) * rr for k in range(n)]))
    _skin(bm, rings)
    if caps and not closed:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    if closed:
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    p = Part(bm, mat)
    if m is not None:
        p.xf(m)
    return p


def prism(outline, depth, mat, plane="xy", m=None, bevel=0.003, seg=2):
    """A flat outline [(a, b), ...] (counter-clockwise) extruded `depth` across its plane,
    centred: plane "xy" extrudes along z, "zy" along x (a = z), "xz" along y (b = z)."""
    bm = bmesh.new()
    lo, hi = [], []
    for a, b in outline:
        if plane == "xy":
            lo.append((a, b, -depth / 2)); hi.append((a, b, depth / 2))
        elif plane == "zy":
            lo.append((-depth / 2, b, a)); hi.append((depth / 2, b, a))
        else:
            lo.append((a, -depth / 2, b)); hi.append((a, depth / 2, b))
    r0, r1 = _ring(bm, lo), _ring(bm, hi)
    _skin(bm, [r0, r1])
    bm.faces.new(r0)
    bm.faces.new(list(reversed(r1)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    p = Part(bm, mat)
    p.bevel(bevel, seg)
    if m is not None:
        p.xf(m)
    return p


def sphere(r, mat, seg=10, rings=6, m=None, squash=1.0):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    if squash != 1.0:
        bmesh.ops.transform(bm, matrix=scale(1, 1, squash), verts=bm.verts)
    # create_uvsphere's poles are on z; turn them onto y.
    bmesh.ops.transform(bm, matrix=rot_x(-90), verts=bm.verts)
    p = Part(bm, mat)
    if m is not None:
        p.xf(m)
    return p


def ico(r, mat, subdiv=1, m=None):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    p = Part(bm, mat)
    if m is not None:
        p.xf(m)
    return p


def octa(r, h, mat, m=None):
    """A cut crystal drop: an elongated octahedron."""
    bm = bmesh.new()
    top = bm.verts.new((0, h * 0.35, 0))
    bot = bm.verts.new((0, -h * 0.65, 0))
    mid = [bm.verts.new((r * math.cos(a), 0, r * math.sin(a))) for a in [i * math.pi / 2 for i in range(4)]]
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new((top, mid[j], mid[i]))
        bm.faces.new((bot, mid[i], mid[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    p = Part(bm, mat)
    if m is not None:
        p.xf(m)
    return p


def grid_sheet(w, h, nu, nv, mat, f, m=None, thickness=0.0):
    """A sheet over x in [-w/2, w/2], y in [0, h], displaced along z by f(x, y): curtains,
    cloth. With `thickness` it gets a back."""
    bm = bmesh.new()
    rows = []
    for j in range(nv + 1):
        y = h * j / nv
        rows.append([bm.verts.new((-w / 2 + w * i / nu, y, f(-w / 2 + w * i / nu, y))) for i in range(nu + 1)])
    for j in range(nv):
        for i in range(nu):
            bm.faces.new((rows[j][i], rows[j][i + 1], rows[j + 1][i + 1], rows[j + 1][i]))
    if thickness:
        back = []
        for j in range(nv + 1):
            back.append([bm.verts.new((v.co.x, v.co.y, v.co.z - thickness)) for v in rows[j]])
        for j in range(nv):
            for i in range(nu):
                bm.faces.new((back[j][i + 1], back[j][i], back[j + 1][i], back[j + 1][i + 1]))
    p = Part(bm, mat)
    if m is not None:
        p.xf(m)
    return p


# --- Props ---------------------------------------------------------------------------------------

class Prop:
    """A prop: named nodes, each a list of parts; node origins are pivots (clock hands)."""

    def __init__(self, name):
        self.name = name
        self.nodes = {name: []}
        self.origins = {}

    def add(self, *parts, node=None):
        for p in parts:
            if isinstance(p, (list, tuple)):
                self.add(*p, node=node)
            else:
                self.nodes.setdefault(node or self.name, []).append(p)
        return self

    def pivot(self, node, origin):
        self.origins[node] = Vector(origin)

    def build(self):
        objs = []
        for node, parts in self.nodes.items():
            if not parts:
                continue
            origin = self.origins.get(node, Vector((0, 0, 0)))
            verts, faces, mats, uvs = [], [], [], []
            mat_names = []
            for p in parts:
                if p.mat not in mat_names:
                    mat_names.append(p.mat)
                mi = mat_names.index(p.mat)
                p.bm.verts.index_update()
                base = len(verts)
                for v in p.bm.verts:
                    c = v.co - origin
                    verts.append((c.x, -c.z, c.y))
                for f in p.bm.faces:
                    faces.append([base + v.index for v in f.verts])
                    mats.append(mi)
                    if p.uv:
                        au, av, su, sv, ou, ov = p.uv
                        uvs.append([(getattr(v.co, au) * su + ou, getattr(v.co, av) * sv + ov) for v in f.verts])
                    else:
                        uvs.append([(0.0, 0.0)] * len(f.verts))
            me = bpy.data.meshes.new(node)
            me.from_pydata(verts, [], faces)
            for mn in mat_names:
                me.materials.append(material(mn))
            for poly, mi in zip(me.polygons, mats):
                poly.material_index = mi
            if any(p.uv for p in parts):
                layer = me.uv_layers.new(name="UVMap")
                k = 0
                for poly, face_uv in zip(me.polygons, uvs):
                    for li, uv in zip(poly.loop_indices, face_uv):
                        layer.data[li].uv = uv
            me.validate()
            me.shade_smooth()
            me.set_sharp_from_angle(angle=math.radians(32))
            ob = bpy.data.objects.new(node, me)
            ob.location = (origin.x, -origin.z, origin.y)
            bpy.context.scene.collection.objects.link(ob)
            objs.append(ob)
        return objs


def export(prop, path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    objs = prop.build()
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_texcoords=True, export_normals=True,
                              export_materials="EXPORT", export_cameras=False, export_lights=False,
                              export_animations=False)
    tris = sum(len(o.data.polygons) and sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs)
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for o in objs:
        for v in o.data.vertices:
            w = o.matrix_world @ v.co
            g = Vector((w.x, w.z, -w.y))
            lo = Vector(map(min, lo, g))
            hi = Vector(map(max, hi, g))
    size = hi - lo
    print("%-20s %6d tris  size %.2f x %.2f x %.2f  (x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f)" % (
        prop.name, tris, size.x, size.y, size.z, lo.x, hi.x, lo.y, hi.y, lo.z, hi.z))


PROPS = {}


def prop(fn):
    PROPS[fn.__name__] = fn
    return fn


# --- Shared pieces ------------------------------------------------------------------------------

def turned_leg(x, z, h, r, mat, n=10, foot=None):
    """A tapered, turned furniture leg standing on the floor at (x, z), top at h."""
    prof = [(r * 0.6, 0.0), (r * 0.7, 0.03), (r * 0.75, h * 0.35), (r * 0.95, h * 0.8), (r, h)]
    parts = [lathe(prof, mat, n, m=move(x, 0, z))]
    if foot:
        parts.append(cyl(r * 0.7, 0.0, 0.025, foot, n, m=move(x, 0, z)))
    return parts


def cushion(lo, hi, mat, round_=0.04):
    return box(lo, hi, mat, bevel=round_, seg=3)


def panel_moulding(x0, y0, x1, y1, z, w, d, mat):
    """A rectangular picture-frame moulding on a wall face at depth z."""
    return [
        box((x0, y0, z), (x1, y0 + w, z + d), mat, 0.004),
        box((x0, y1 - w, z), (x1, y1, z + d), mat, 0.004),
        box((x0, y0 + w, z), (x0 + w, y1 - w, z + d), mat, 0.004),
        box((x1 - w, y0 + w, z), (x1, y1 - w, z + d), mat, 0.004),
    ]


def bottle(x, y, z, kind, rng):
    """A spirits bottle standing at (x, y, z)."""
    mats = ["bottle_green", "bottle_amber", "bottle_clear", "bottle_blue", "bottle_amber", "bottle_clear"]
    mat = mats[kind % len(mats)]
    h = 0.27 + rng.random() * 0.06
    r = 0.036 + rng.random() * 0.01
    square = kind % 5 == 3
    n = 4 if square else 8
    prof = [(r * 0.95, 0), (r, 0.01), (r, h * 0.62), (r * 0.55, h * 0.74), (r * 0.3, h * 0.8), (r * 0.3, h * 0.95)]
    parts = [lathe(prof, mat, n, m=move(x, y, z) @ rot_y(45 if square else 0))]
    parts.append(cyl(r * 0.32, h * 0.95, h, "cast_iron" if kind % 2 else "brass_aged", 6, m=move(x, y, z), bevel=0))
    parts.append(box((x - r * 0.75, y + h * 0.22, z + r * 0.62), (x + r * 0.75, y + h * 0.48, z + r * 0.98), "label_cream", 0.0))
    return parts


def flowers(cx, cy, cz, radius, height, rng, colours=("rose_white", "rose_white", "rose_blush"), count=24, leaves=14):
    """A rounded floral arrangement: blooms on a dome, leaves tucked between."""
    parts = []
    for i in range(count):
        a = rng.random() * 2 * math.pi
        t = math.sqrt(rng.random())
        rr = radius * t
        y = cy + height * (1 - t * t) * 0.9 + rng.random() * 0.03
        s = 0.045 + rng.random() * 0.025
        parts.append(ico(s, colours[i % len(colours)], 1, m=move(cx + rr * math.cos(a), y, cz + rr * math.sin(a)) @ scale(1, 0.75, 1)))
    for i in range(leaves):
        a = rng.random() * 2 * math.pi
        rr = radius * (0.8 + rng.random() * 0.35)
        y = cy + height * 0.25 + rng.random() * height * 0.3
        ln = 0.12 + rng.random() * 0.08
        parts.append(prism([(0, -0.025), (ln * 0.5, -0.03), (ln, 0), (ln * 0.5, 0.03), (0, 0.025)], 0.006, "leaf" if i % 2 else "leaf_dark",
                           plane="xz", m=move(cx + rr * 0.8 * math.cos(a), y, cz + rr * 0.8 * math.sin(a)) @ rot_y(-math.degrees(a)) @ rot_z(-20 - rng.random() * 25), bevel=0))
    return parts


def candle(x, y, z, h=0.08, r=0.022):
    return [cyl(r, y, y + h, "wax", 8, m=move(x, 0, z), bevel=0.002),
            lathe([(0.0, y + h + 0.005), (0.006, y + h + 0.012), (0.0, y + h + 0.035)], "flame", 6, m=move(x, 0, z))]


# --- The lobby -----------------------------------------------------------------------------------

@prop
def reception_desk():
    """4 m of walnut and brass with a black marble top for the guests' side and a lower work
    counter behind; the front faces +Z."""
    p = Prop("reception_desk")
    w, d = 4.0, 0.9
    x0, x1 = -w / 2, w / 2
    zb, zf = -d / 2, d / 2
    # Plinth, recessed in black.
    p.add(box((x0 + 0.05, 0, zb + 0.05), (x1 - 0.05, 0.1, zf - 0.06), "ebony", 0.004))
    # Front: fluted walnut between brass bands.
    p.add(box((x0, 0.1, zf - 0.12), (x1, 1.02, zf - 0.06), "walnut", 0.006))
    for i in range(40):
        x = x0 + 0.1 + i * (w - 0.2) / 39
        p.add(cyl(0.022, 0.18, 0.94, "walnut", 8, m=move(x, 0, zf - 0.06), bevel=0.0))
    p.add(box((x0, 0.12, zf - 0.07), (x1, 0.16, zf - 0.03), "brass", 0.004))
    p.add(box((x0, 0.95, zf - 0.07), (x1, 0.99, zf - 0.03), "brass", 0.004))
    # Ends.
    for x in (x0, x1 - 0.06):
        p.add(box((x, 0.1, zb), (x + 0.06, 1.02, zf - 0.06), "walnut", 0.006))
    # Guests' counter: black marble with a bullnose, standing proud of the front.
    p.add(box((x0 - 0.04, 1.02, zf - 0.3), (x1 + 0.04, 1.1, zf + 0.04), "marble_black", 0.02, 3))
    # Work counter behind, lower, and its shelf.
    p.add(box((x0 + 0.06, 0.72, zb), (x1 - 0.06, 0.76, zf - 0.12), "walnut_matte", 0.004))
    p.add(box((x0 + 0.06, 0.1, zb + 0.04), (x1 - 0.06, 0.14, zf - 0.14), "walnut_matte", 0.003))
    p.add(box((x0 + 0.06, 0.1, zb), (x1 - 0.06, 0.72, zb + 0.04), "walnut_dark", 0.003))
    # A brass bell, a guest book, a vase of white roses.
    rng = random.Random(4)
    p.add(lathe([(0.05, 1.1), (0.05, 1.11), (0.045, 1.13), (0.03, 1.17), (0.0, 1.18)], "brass", 12, m=move(0.9, 0, 0.25)))
    p.add(box((-0.55, 1.1, 0.12), (-0.15, 1.13, 0.4), "leather_oxblood", 0.006))
    p.add(box((-0.53, 1.13, 0.14), (-0.17, 1.135, 0.38), "paper", 0.0))
    p.add(lathe([(0.05, 1.1), (0.07, 1.16), (0.06, 1.28), (0.045, 1.32)], "glass", 10, cap=(True, False), m=move(-1.6, 0, 0.18)))
    p.add(flowers(-1.6, 1.3, 0.18, 0.16, 0.18, rng, count=14, leaves=8))
    # A brass nameplate and a computer screen for the receptionist, turned away from guests.
    p.add(box((-0.35, 0.76, -0.25), (0.15, 0.79, -0.05), "plastic_black", 0.004))
    p.add(box((-0.35, 0.79, -0.18), (0.15, 1.08, -0.15), "plastic_black", 0.006))
    p.add(box((-0.33, 0.81, -0.152), (0.13, 1.06, -0.149), "screen", 0.0))
    return p


@prop
def key_cabinet():
    """Pigeonholes and key hooks behind reception: walnut, 3 m wide, 2.6 m tall, 0.35 deep."""
    p = Prop("key_cabinet")
    w, h, d = 3.0, 2.6, 0.35
    z0, z1 = -d / 2, d / 2
    p.add(box((-w / 2, 0, z0), (w / 2, 0.9, z1), "walnut", 0.006))
    p.add(box((-w / 2 - 0.02, 0.9, z0), (w / 2 + 0.02, 0.94, z1 + 0.03), "marble_black", 0.012))
    for i in range(6):
        x = -w / 2 + 0.25 + i * 0.5
        p.add(box((x - 0.22, 0.08, z1 - 0.01), (x + 0.22, 0.82, z1 + 0.005), "walnut_dark", 0.004))
        p.add(lathe([(0.012, 0), (0.014, 0.02), (0.0, 0.03)], "brass", 8, m=move(x, 0.72, z1 + 0.005) @ rot_x(90)))
    # Upper: a back and a grid of pigeonholes with brass hooks and tags.
    p.add(box((-w / 2, 0.94, z0), (w / 2, h - 0.15, z0 + 0.03), "walnut_dark", 0.003))
    cols, rows = 10, 6
    for i in range(cols + 1):
        x = -w / 2 + i * w / cols
        p.add(box((x - 0.012, 0.94, z0), (x + 0.012, h - 0.15, z1 - 0.08), "walnut", 0.0))
    for j in range(rows + 1):
        y = 0.94 + j * (h - 1.09) / rows
        p.add(box((-w / 2, y - 0.012, z0), (w / 2, y + 0.012, z1 - 0.08), "walnut", 0.004, 1))
    rng = random.Random(9)
    for i in range(cols):
        for j in range(rows):
            x = -w / 2 + (i + 0.5) * w / cols
            y = 0.94 + (j + 0.75) * (h - 1.09) / rows
            p.add(cyl(0.004, 0, 0.05, "brass", 4, m=move(x, y, z0 + 0.03) @ rot_x(90), bevel=0))
            if rng.random() < 0.7:
                p.add(box((x - 0.012, y - 0.075, z0 + 0.06), (x + 0.012, y - 0.01, z0 + 0.07), "brass_aged", 0.0))
                p.add(box((x - 0.02, y - 0.12, z0 + 0.065), (x + 0.02, y - 0.075, z0 + 0.075), "leather_oxblood", 0.0))
            if rng.random() < 0.35:
                p.add(box((x - 0.1, 0.96 + j * (h - 1.09) / rows, z0 + 0.04), (x + 0.1, 0.96 + j * (h - 1.09) / rows + 0.05, z0 + 0.2), "paper", 0.0))
    # Cornice.
    p.add(box((-w / 2 - 0.06, h - 0.15, z0), (w / 2 + 0.06, h - 0.05, z1 + 0.06), "walnut", 0.01))
    p.add(box((-w / 2 - 0.08, h - 0.05, z0), (w / 2 + 0.08, h, z1 + 0.08), "walnut", 0.01))
    p.add(box((-w / 2 - 0.06, h - 0.17, z1 + 0.04), (w / 2 + 0.06, h - 0.15, z1 + 0.065), "brass", 0.004))
    return p


@prop
def bar_counter():
    """The lobby bar: 6 m of panelled walnut, a black marble top with a bullnose, a brass foot
    rail, and the bartender's well behind. Front faces +Z."""
    p = Prop("bar_counter")
    w, d = 6.0, 0.75
    x0, x1 = -w / 2, w / 2
    zb, zf = -d / 2, d / 2
    p.add(box((x0 + 0.04, 0, zb + 0.1), (x1 - 0.04, 0.1, zf - 0.08), "ebony", 0.004))
    p.add(box((x0, 0.1, zf - 0.14), (x1, 1.04, zf - 0.07), "walnut", 0.006))
    # Raised panels with gilt beads.
    n = 10
    pw = w / n
    for i in range(n):
        cx = x0 + (i + 0.5) * pw
        p.add(box((cx - pw / 2 + 0.07, 0.22, zf - 0.07), (cx + pw / 2 - 0.07, 0.92, zf - 0.035), "walnut", 0.012, 2))
        p.add(panel_moulding(cx - pw / 2 + 0.1, 0.25, cx + pw / 2 - 0.1, 0.89, zf - 0.035, 0.012, 0.008, "gilt"))
    for x in (x0, x1 - 0.06):
        p.add(box((x, 0.1, zb), (x + 0.06, 1.04, zf - 0.07), "walnut", 0.006))
    # Top.
    p.add(box((x0 - 0.05, 1.04, zb - 0.02), (x1 + 0.05, 1.12, zf + 0.06), "marble_black", 0.025, 3))
    # Foot rail on brass brackets.
    rail = [(x0 + 0.1, 0.22, zf + 0.12), (x1 - 0.1, 0.22, zf + 0.12)]
    p.add(tube(rail, 0.025, "brass", 10))
    for i in range(7):
        x = x0 + 0.3 + i * (w - 0.6) / 6
        p.add(tube([(x, 0.22, zf + 0.12), (x, 0.22, zf - 0.07)], 0.012, "brass", 6))
    # The well: a steel work shelf, glasses and bottles under the counter.
    p.add(box((x0 + 0.06, 0.78, zb), (x1 - 0.06, 0.82, zf - 0.16), "steel", 0.004))
    p.add(box((x0 + 0.06, 0.1, zb + 0.02), (x1 - 0.06, 0.78, zb + 0.05), "walnut_dark", 0.003))
    rng = random.Random(2)
    for i in range(18):
        x = x0 + 0.3 + i * 0.3
        p.add(bottle(x, 0.82, -0.1, i, rng))
    return p


@prop
def back_bar():
    """The wall behind the bar: walnut cupboards, a mirror, three glass shelves of bottles lit
    from below, and a cornice. 5 m wide, 2.8 m tall, 0.5 deep; stands against a wall."""
    p = Prop("back_bar")
    w, h, d = 5.0, 2.8, 0.5
    z0, z1 = -d / 2, d / 2
    x0, x1 = -w / 2, w / 2
    p.add(box((x0, 0, z0), (x1, 0.08, z1 - 0.05), "ebony", 0.003))
    p.add(box((x0, 0.08, z0), (x1, 0.9, z1), "walnut", 0.006))
    for i in range(8):
        cx = x0 + (i + 0.5) * w / 8
        p.add(box((cx - w / 16 + 0.03, 0.14, z1), (cx + w / 16 - 0.03, 0.84, z1 + 0.02), "walnut", 0.01))
        p.add(cyl(0.008, 0, 0.12, "brass", 6, m=move(cx + (w / 16 - 0.08) * (1 if i % 2 else -1), 0.62, z1 + 0.02) @ rot_x(90) @ move(0, -0.06, 0), bevel=0))
    p.add(box((x0 - 0.02, 0.9, z0), (x1 + 0.02, 0.95, z1 + 0.03), "marble_black", 0.012))
    # Mirror back between walnut pilasters.
    p.add(box((x0, 0.95, z0), (x1, h - 0.2, z0 + 0.03), "mirror", 0.0))
    for x in [x0 + i * w / 4 for i in range(5)]:
        p.add(box((x - 0.06, 0.95, z0), (x + 0.06, h - 0.2, z0 + 0.12), "walnut", 0.006))
    # Shelves, each with a warm strip of light under it and bottles on it.
    rng = random.Random(7)
    k = 0
    for y in (1.3, 1.72, 2.14):
        p.add(box((x0 + 0.06, y - 0.02, z0 + 0.03), (x1 - 0.06, y, z0 + 0.3), "glass_dark", 0.0))
        p.add(box((x0 + 0.06, y - 0.03, z0 + 0.03), (x1 - 0.06, y - 0.02, z0 + 0.06), "bulb", 0.0))
        x = x0 + 0.16
        while x < x1 - 0.12:
            if abs(((x - x0) % (w / 4)) - 0) < 0.12 or abs(((x - x0) % (w / 4)) - w / 4) < 0.12:
                x += 0.12
                continue
            p.add(bottle(x, y, z0 + 0.16, k, rng))
            k += 1
            x += 0.105 + rng.random() * 0.03
    # Glasses on the counter.
    for i in range(10):
        x = x0 + 0.4 + i * 0.12
        p.add(lathe([(0.03, 0.95), (0.032, 0.955), (0.036, 1.06), (0.034, 1.06)], "glass", 8, cap=(True, False), m=move(x, 0, 0.1)))
    # Cornice with a brass edge.
    p.add(box((x0 - 0.05, h - 0.2, z0), (x1 + 0.05, h - 0.08, z1), "walnut", 0.01))
    p.add(box((x0 - 0.08, h - 0.08, z0), (x1 + 0.08, h, z1 + 0.04), "walnut", 0.012))
    p.add(box((x0 - 0.05, h - 0.22, z1 - 0.02), (x1 + 0.05, h - 0.2, z1 + 0.01), "brass", 0.003))
    return p


@prop
def bar_stool():
    """A bar stool: a buttoned oxblood leather seat 0.78 m up on walnut legs with a brass ring."""
    p = Prop("bar_stool")
    h = 0.78
    for a in (45, 135, 225, 315):
        x, z = 0.17 * math.cos(math.radians(a)), 0.17 * math.sin(math.radians(a))
        top = Vector((x * 0.62, h - 0.06, z * 0.62))
        p.add(tube([(x, 0.0, z), top], 0.018, "walnut", 8, radii=[0.014, 0.02]))
    p.add(tube([(0.14 * math.cos(a * math.pi / 8), 0.3, 0.14 * math.sin(a * math.pi / 8)) for a in range(16)], 0.011, "brass", 6, closed=True))
    p.add(cyl(0.16, h - 0.07, h - 0.03, "walnut", 20, bevel=0.008))
    p.add(lathe([(0.19, h - 0.04), (0.2, h - 0.02), (0.195, h + 0.03), (0.16, h + 0.06), (0.0, h + 0.07)], "leather_oxblood", 20))
    return p


@prop
def sofa():
    """A deep velvet sofa with rolled arms and a buttoned back, on short turned legs. 2.2 m."""
    p = Prop("sofa")
    w, d = 2.2, 0.92
    x0, x1 = -w / 2, w / 2
    zb, zf = -d / 2, d / 2
    mat = "velvet_green"
    for x in (x0 + 0.1, x1 - 0.1):
        for z in (zb + 0.1, zf - 0.1):
            p.add(turned_leg(x, z, 0.12, 0.03, "walnut", foot="brass"))
    p.add(cushion((x0 + 0.02, 0.12, zb + 0.02), (x1 - 0.02, 0.38, zf - 0.02), mat, 0.04))
    # Seat cushions.
    for i in range(3):
        cx0 = x0 + 0.2 + i * (w - 0.4) / 3
        p.add(cushion((cx0 + 0.01, 0.38, zb + 0.22), (cx0 + (w - 0.4) / 3 - 0.01, 0.5, zf - 0.01), mat, 0.05))
    # Back with buttoned tufts.
    p.add(cushion((x0 + 0.08, 0.38, zb), (x1 - 0.08, 0.86, zb + 0.24), mat, 0.07))
    for i in range(9):
        for j in range(2):
            x = x0 + 0.3 + i * (w - 0.6) / 8 + (0.06 if j else 0)
            p.add(sphere(0.012, "velvet_gold", 6, 4, m=move(x, 0.58 + j * 0.14, zb + 0.24)))
    # Rolled arms.
    for side in (-1, 1):
        x = side * (w / 2 - 0.12)
        p.add(cushion((x - 0.12, 0.38, zb + 0.02), (x + 0.12, 0.6, zf - 0.01), mat, 0.04))
        p.add(cyl(0.12, zb + 0.02, zf + 0.01, mat, 16, m=move(x + side * 0.01, 0.62, 0) @ rot_x(90) @ scale(1, 1, 1), bevel=0.02))
    return p


@prop
def armchair():
    """A club armchair in burgundy velvet with rolled arms and a curved back."""
    p = Prop("armchair")
    w, d = 0.95, 0.9
    zb, zf = -d / 2, d / 2
    mat = "velvet_burgundy"
    for x in (-w / 2 + 0.09, w / 2 - 0.09):
        for z in (zb + 0.09, zf - 0.09):
            p.add(turned_leg(x, z, 0.12, 0.028, "walnut", foot="brass"))
    p.add(cushion((-w / 2 + 0.02, 0.12, zb + 0.02), (w / 2 - 0.02, 0.38, zf - 0.02), mat, 0.04))
    p.add(cushion((-w / 2 + 0.17, 0.38, zb + 0.22), (w / 2 - 0.17, 0.5, zf - 0.01), mat, 0.05))
    # Curved back: a ring of cushioned segments.
    segs = 7
    for i in range(segs):
        a0 = math.radians(200 + i * 140 / segs)
        a = a0 + math.radians(70 / segs)
        r = 0.36
        x, z = r * math.cos(a), r * math.sin(a) + 0.02
        p.add(cushion((-0.08, 0.38, -0.11), (0.08, 0.9, 0.11), mat, 0.05).xf(move(x, 0, z) @ rot_y(-math.degrees(a) - 90)))
    for side in (-1, 1):
        x = side * (w / 2 - 0.1)
        p.add(cushion((x - 0.1, 0.38, zb + 0.1), (x + 0.1, 0.62, zf - 0.01), mat, 0.04))
        p.add(cyl(0.1, zb + 0.1, zf + 0.01, mat, 14, m=move(x + side * 0.01, 0.63, 0) @ rot_x(90), bevel=0.02))
    return p


@prop
def low_table():
    """A low table: white marble top on a brass frame. 1.3 x 0.7 m, 0.42 m high, with a tray
    and two books."""
    p = Prop("low_table")
    w, d, h = 1.3, 0.7, 0.42
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2), "marble_white", 0.012, 3))
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        for z in (-d / 2 + 0.06, d / 2 - 0.06):
            p.add(box((x - 0.015, 0, z - 0.015), (x + 0.015, h - 0.04, z + 0.015), "brass", 0.004))
    for z in (-d / 2 + 0.06, d / 2 - 0.06):
        p.add(box((-w / 2 + 0.06, 0.06, z - 0.01), (w / 2 - 0.06, 0.08, z + 0.01), "brass", 0.003))
    p.add(box((-w / 2 + 0.06, 0.06, -0.01), (w / 2 - 0.06, 0.08, 0.01), "brass", 0.003).xf(rot_y(0)))
    p.add(box((0.15, h, -0.14), (0.5, h + 0.02, 0.14), "brass", 0.006))
    p.add(box((-0.45, h, -0.12), (-0.15, h + 0.035, 0.1), "leather_black", 0.004))
    p.add(box((-0.43, h + 0.035, -0.1), (-0.17, h + 0.06, 0.08), "velvet_burgundy", 0.004))
    p.add(lathe([(0.04, h + 0.02), (0.07, h + 0.05), (0.075, h + 0.07), (0.07, h + 0.075)], "porcelain", 12, m=move(0.33, 0, 0)))
    return p


@prop
def rug():
    """The lobby's rug, 4 x 3 m and a centimetre thick."""
    p = Prop("rug")
    p.add(box((-2.0, 0.0, -1.5), (2.0, 0.012, 1.5), "rug", 0.004, uv=("x", "z", 0.25, 1 / 3.0, 0.5, 0.5)))
    return p


@prop
def side_table():
    """A round walnut side table with a brass lamp and a pleated cream shade. 0.55 wide."""
    p = Prop("side_table")
    h = 0.6
    p.add(cyl(0.275, h - 0.03, h, "walnut", 24, bevel=0.008))
    p.add(lathe([(0.03, 0.0), (0.18, 0.0), (0.18, 0.02), (0.04, 0.05), (0.03, h - 0.03)], "walnut", 16))
    p.add(lathe([(0.07, h), (0.07, h + 0.02), (0.05, h + 0.05), (0.06, h + 0.18), (0.045, h + 0.3), (0.012, h + 0.32), (0.012, h + 0.42)], "brass", 14))
    p.add(lathe([(0.17, h + 0.36), (0.11, h + 0.58)], "lampshade", 16, cap=(False, False)))
    p.add(sphere(0.035, "bulb", 8, 6, m=move(0, h + 0.44, 0)))
    return p


@prop
def floor_lamp():
    """A brass floor lamp with a drum shade, 1.65 m."""
    p = Prop("floor_lamp")
    p.add(lathe([(0.0, 0.0), (0.17, 0.0), (0.17, 0.02), (0.06, 0.05), (0.014, 0.07)], "brass", 18))
    p.add(cyl(0.012, 0.07, 1.42, "brass", 8, bevel=0))
    p.add(lathe([(0.028, 0.5), (0.02, 0.56), (0.028, 0.62)], "brass", 10))
    p.add(lathe([(0.23, 1.32), (0.21, 1.65)], "lampshade", 20, cap=(False, False)))
    p.add(sphere(0.04, "bulb", 8, 6, m=move(0, 1.44, 0)))
    return p


@prop
def desk_lamp():
    """A banker's lamp: green glass shade on a brass stem, for reception and the office."""
    p = Prop("desk_lamp")
    p.add(lathe([(0.0, 0), (0.08, 0), (0.08, 0.015), (0.03, 0.03), (0.012, 0.04)], "brass", 14))
    p.add(cyl(0.008, 0.04, 0.3, "brass", 6, bevel=0))
    p.add(tube([(0, 0.3, 0), (0, 0.33, 0.05)], 0.007, "brass", 6))
    arc = [(0.075 * math.cos(math.pi * k / 10), 0.075 * math.sin(math.pi * k / 10)) for k in range(11)]
    inner = [(0.068 * math.cos(math.pi * k / 10), 0.068 * math.sin(math.pi * k / 10)) for k in reversed(range(11))]
    p.add(prism([(-z, y) for z, y in arc + inner], 0.3, "bottle_green", plane="zy", m=move(0, 0.3, 0.06), bevel=0.0))
    p.add(box((-0.14, 0.302, 0.0), (0.14, 0.306, 0.12), "bulb", 0.0))
    p.add(box((-0.15, 0.36, 0.055), (0.15, 0.38, 0.065), "brass", 0.003))
    return p


@prop
def wall_sconce():
    """A two-arm brass wall sconce with pleated shades; back on z = 0. Bulbs at y 0.42."""
    p = Prop("wall_sconce")
    p.add(box((-0.07, 0.0, 0.0), (0.07, 0.24, 0.025), "brass", 0.006))
    p.add(lathe([(0.0, 0), (0.03, 0.01), (0.02, 0.03)], "brass", 10, m=move(0, 0.12, 0.025) @ rot_x(90)))
    for side in (-1, 1):
        pts = [(0, 0.12, 0.05)] + [(side * 0.16 * math.sin(t * math.pi / 2), 0.12 + 0.12 * (1 - math.cos(t * math.pi / 2)) - 0.04 * math.sin(t * math.pi), 0.05 + 0.12 * t) for t in [i / 6 for i in range(1, 7)]]
        p.add(tube(pts, 0.009, "brass", 6))
        x, z = side * 0.16, 0.17
        p.add(lathe([(0.025, 0.24), (0.03, 0.27)], "brass", 10, m=move(x, 0, z)))
        p.add(cyl(0.012, 0.27, 0.34, "wax", 8, m=move(x, 0, z), bevel=0))
        p.add(lathe([(0.075, 0.3), (0.045, 0.42)], "lampshade", 12, cap=(False, False), m=move(x, 0, z)))
        p.add(sphere(0.018, "bulb", 6, 4, m=move(x, 0.36, z)))
    return p


@prop
def chandelier():
    """A crystal chandelier: two tiers of brass arms with candle bulbs, swags and drops of
    cut crystal, a crystal bowl, a ceiling rose and a short chain. 1.5 m across, 1.9 m from
    rose to finial; it hangs from y = 1.9 down to y = 0."""
    p = Prop("chandelier")
    rng = random.Random(1)
    H = 1.9
    # Rose, corona and chain.
    p.add(lathe([(0.0, H - 0.08), (0.2, H - 0.06), (0.22, H - 0.02), (0.22, H)], "brass", 20))
    for i in range(6):
        y = H - 0.12 - i * 0.07
        p.add(tube([(0.03, y, 0), (0.0, y - 0.03, 0), (-0.03, y, 0), (0.0, y + 0.03, 0)], 0.007, "brass_aged", 5, closed=True, m=rot_y(90 * (i % 2))))
    p.add(tube([(0.3 * math.cos(a * math.pi / 12), 1.32, 0.3 * math.sin(a * math.pi / 12)) for a in range(24)], 0.012, "brass", 6, closed=True))
    for i in range(12):
        a = 2 * math.pi * i / 12
        p.add(tube([(0.0, 1.42, 0.0), (0.3 * math.cos(a), 1.32, 0.3 * math.sin(a))], 0.005, "brass", 4))
        for k in range(3):
            p.add(octa(0.011, 0.035, "crystal", m=move(0.3 * math.cos(a), 1.3 - k * 0.04, 0.3 * math.sin(a))))
    # The column: turned brass with crystal balusters.
    col = [(0.0, 0.18), (0.03, 0.2), (0.05, 0.26), (0.03, 0.3), (0.045, 0.34), (0.06, 0.4), (0.04, 0.44),
           (0.09, 0.48), (0.1, 0.52), (0.04, 0.56), (0.035, 0.75), (0.07, 0.82), (0.07, 0.86), (0.03, 0.9),
           (0.025, 1.1), (0.05, 1.16), (0.02, 1.22), (0.015, H - 0.5)]
    p.add(lathe(col, "brass", 14))
    p.add(lathe([(0.0, 0.58), (0.06, 0.62), (0.075, 0.68), (0.06, 0.74), (0.0, 0.78)], "crystal", 10))
    p.add(lathe([(0.0, 1.16), (0.05, 1.19), (0.06, 1.24), (0.05, 1.29), (0.0, 1.31)], "crystal", 10))
    # The bowl under it all, hung with drops.
    p.add(lathe([(0.0, 0.12), (0.12, 0.16), (0.2, 0.24), (0.22, 0.27), (0.21, 0.28)], "crystal", 16, cap=(True, False)))
    for i in range(16):
        a = 2 * math.pi * i / 16
        p.add(octa(0.016, 0.1, "crystal", m=move(0.21 * math.cos(a), 0.25, 0.21 * math.sin(a))))
    p.add(octa(0.03, 0.14, "crystal", m=move(0, 0.12, 0)))
    # Lower tier: ten arms; upper tier: six.
    for tier, (n, r, y, drop) in enumerate([(10, 0.68, 0.5, 0.16), (6, 0.4, 1.0, 0.12)]):
        tips = []
        for i in range(n):
            a = 2 * math.pi * (i + 0.5 * tier) / n
            c, s = math.cos(a), math.sin(a)
            pts = []
            for k in range(9):
                t = k / 8
                rr = 0.06 + (r - 0.06) * t
                yy = y - 0.14 * math.sin(t * math.pi) + 0.1 * t * t
                pts.append((rr * c, yy, rr * s))
            p.add(tube(pts, 0.012, "brass", 6))
            tip = Vector(pts[-1])
            tips.append(tip)
            p.add(lathe([(0.04, 0.0), (0.05, 0.02), (0.04, 0.035), (0.025, 0.04)], "brass", 10, m=move(tip.x, tip.y, tip.z)))
            p.add(lathe([(0.06, 0.035), (0.07, 0.05)], "crystal", 10, cap=(False, False), m=move(tip.x, tip.y, tip.z)))
            p.add(cyl(0.014, tip.y + 0.04, tip.y + 0.13, "wax", 8, m=move(tip.x, 0, tip.z), bevel=0))
            p.add(lathe([(0.0, tip.y + 0.13), (0.018, tip.y + 0.15), (0.02, tip.y + 0.18), (0.0, tip.y + 0.22)], "bulb", 8, m=move(tip.x, 0, tip.z)))
            for k in range(3):
                p.add(octa(0.02 - k * 0.003, drop * (1 - 0.2 * k), "crystal", m=move(tip.x, tip.y - 0.02 - k * drop * 0.9, tip.z)))
        # Two swags of beads between neighbouring tips.
        for i in range(n):
            a, b = tips[i], tips[(i + 1) % n]
            for sag in (0.1, 0.2):
                for k in range(1, 9):
                    t = k / 9
                    q = a.lerp(b, t)
                    q.y -= sag * math.sin(t * math.pi)
                    q *= Vector((1.0 + sag * 0.15, 1.0, 1.0 + sag * 0.15))
                    p.add(octa(0.012, 0.032, "crystal", m=move(q.x, q.y, q.z) @ rot_y(rng.random() * 90)))
    return p


@prop
def pendant():
    """A bar pendant: an opal glass globe on a brass rod, 1.2 m long; hangs from y = 1.2."""
    p = Prop("pendant")
    p.add(lathe([(0.0, 1.18), (0.07, 1.18), (0.07, 1.2)], "brass", 12))
    p.add(cyl(0.008, 0.28, 1.18, "brass", 6, bevel=0))
    p.add(lathe([(0.04, 0.26), (0.05, 0.3), (0.0, 0.31)], "brass", 12))
    p.add(sphere(0.14, "lantern_glass", 14, 10, m=move(0, 0.14, 0)))
    return p


@prop
def flower_table():
    """The lobby's centrepiece: a round walnut pedestal table under a tall arrangement of white
    roses and greenery. 1.2 m across, 2 m tall."""
    p = Prop("flower_table")
    rng = random.Random(12)
    p.add(cyl(0.6, 0.72, 0.76, "walnut", 32, bevel=0.012))
    p.add(lathe([(0.0, 0.0), (0.42, 0.0), (0.42, 0.04), (0.3, 0.07), (0.1, 0.12), (0.08, 0.3), (0.12, 0.5), (0.07, 0.62), (0.2, 0.7), (0.2, 0.72)], "walnut", 20))
    p.add(lathe([(0.12, 0.76), (0.16, 0.8), (0.14, 0.86), (0.1, 0.9), (0.12, 0.96), (0.26, 1.12), (0.3, 1.2), (0.28, 1.24), (0.26, 1.24)], "brass", 20, cap=(True, False)))
    for i in range(18):
        a = 2 * math.pi * i / 18
        top = Vector((0.55 * math.cos(a), 1.75 + rng.random() * 0.25, 0.55 * math.sin(a)))
        p.add(tube([(0.12 * math.cos(a), 1.2, 0.12 * math.sin(a)), (0.35 * math.cos(a), 1.5, 0.35 * math.sin(a)), top], 0.006, "leaf_dark", 4))
    p.add(flowers(0, 1.3, 0, 0.62, 0.75, rng, count=120, leaves=60))
    for i in range(8):
        a = 2 * math.pi * i / 8 + 0.2
        base = Vector((0.2 * math.cos(a), 1.6, 0.2 * math.sin(a)))
        for k in range(6):
            p.add(ico(0.035, "rose_white", 1, m=move(base.x * (1 + k * 0.15), base.y + 0.15 + k * 0.08, base.z * (1 + k * 0.15))))
    return p


@prop
def potted_palm():
    """A kentia palm in a brass urn, 2.2 m."""
    p = Prop("potted_palm")
    rng = random.Random(3)
    p.add(lathe([(0.0, 0.0), (0.18, 0.0), (0.2, 0.05), (0.16, 0.1), (0.2, 0.14), (0.3, 0.3), (0.32, 0.55), (0.3, 0.62), (0.32, 0.66), (0.0, 0.62)], "brass_aged", 20, cap=(True, False)))
    p.add(cyl(0.29, 0.58, 0.6, "soil", 16, bevel=0))
    for i in range(11):
        a = 2 * math.pi * i / 11 + rng.random() * 0.3
        lean = 0.35 + rng.random() * 0.45
        length = 1.2 + rng.random() * 0.5
        pts = []
        for k in range(8):
            t = k / 7
            r = math.sin(lean) * length * t
            y = 0.6 + math.cos(lean) * length * t - 0.55 * t * t * lean
            pts.append(Vector((r * math.cos(a), y, r * math.sin(a))))
        p.add(tube(pts, 0.008, "leaf_dark", 4, radii=[0.012 - 0.008 * k / 7 for k in range(8)]))
        # Leaflets either side, drooping.
        for k in range(2, 8):
            q = pts[k - 1].lerp(pts[k], 0.5)
            d = (pts[k] - pts[k - 1]).normalized()
            side = d.cross(Vector((0, 1, 0))).normalized()
            ln = 0.28 * (1 - abs(k - 4.5) / 6)
            for s in (-1, 1):
                tip = q + side * s * ln + Vector((0, -0.1 - 0.05 * k / 7, 0)) + d * 0.08
                bm = bmesh.new()
                vs = [bm.verts.new(v) for v in (q - d * 0.03, q + d * 0.03, tip)]
                bm.faces.new(vs)
                p.add(Part(bm, "leaf"))
    return p


@prop
def luggage_cart():
    """A bellman's luggage cart: a red-carpeted deck on four wheels and a brass arch with a
    hanging rail. 1.2 x 1.9 x 0.65 m."""
    p = Prop("luggage_cart")
    w, d = 1.2, 0.65
    p.add(box((-w / 2, 0.16, -d / 2), (w / 2, 0.22, d / 2), "brass", 0.01))
    p.add(box((-w / 2 + 0.02, 0.22, -d / 2 + 0.02), (w / 2 - 0.02, 0.24, d / 2 - 0.02), "carpet_red", 0.004))
    for x in (-w / 2 + 0.1, w / 2 - 0.1):
        for z in (-d / 2 + 0.08, d / 2 - 0.08):
            p.add(cyl(0.075, -0.012, 0.012, "rubber", 14, m=move(x, 0.075, z) @ rot_x(90), bevel=0.005))
            p.add(box((x - 0.012, 0.075, z - 0.03), (x + 0.012, 0.16, z + 0.03), "brass", 0.003))
    arch = []
    for k in range(17):
        t = k / 16
        a = math.pi * t
        arch.append((-(w / 2 - 0.05) * math.cos(a), 0.24 + 1.45 * math.sin(a) ** 0.35 if 0 < t < 1 else 0.24, 0))
    for z in (-0.05, 0.05):
        p.add(tube([(x, y, z) for x, y, _ in arch], 0.016, "brass", 8))
    p.add(tube([(-0.45, 1.45, 0.0), (0.45, 1.45, 0.0)], 0.014, "brass", 8))
    # A suitcase and a hatbox, as if a guest just arrived.
    p.add(box((-0.5, 0.24, -0.25), (0.1, 0.44, 0.2), "leather_oxblood", 0.02, 2))
    p.add(box((-0.25, 0.44, -0.24), (-0.15, 0.48, -0.2), "brass", 0.004))
    p.add(cyl(0.17, 0.24, 0.46, "velvet_navy", 16, m=move(0.32, 0, 0.02), bevel=0.01))
    return p


@prop
def easel():
    """A walnut easel holding a framed board (0.9 x 1.2 m) for the gala's notice; the board's
    face is at z 0.07, its centre at y 1.25."""
    p = Prop("easel")
    for side in (-1, 1):
        p.add(tube([(side * 0.42, 0.0, 0.02), (side * 0.12, 1.95, -0.06)], 0.02, "walnut", 6))
    p.add(tube([(0, 0.0, -0.6), (0, 1.8, -0.08)], 0.018, "walnut", 6))
    p.add(box((-0.5, 0.6, -0.02), (0.5, 0.65, 0.14), "walnut", 0.006))
    p.add(box((-0.47, 0.65, 0.0), (0.47, 1.85, 0.05), "gilt", 0.012))
    p.add(box((-0.43, 0.69, 0.05), (0.43, 1.81, 0.07), "paint_cream", 0.004))
    return p


@prop
def rope_post():
    """A brass stanchion for a velvet rope, 1 m; the rope hooks are at y 0.92."""
    p = Prop("rope_post")
    p.add(lathe([(0.0, 0), (0.16, 0), (0.16, 0.02), (0.12, 0.05), (0.03, 0.08), (0.025, 0.1)], "brass", 18))
    p.add(cyl(0.025, 0.1, 0.9, "brass", 12, bevel=0))
    p.add(lathe([(0.03, 0.9), (0.04, 0.92), (0.03, 0.94)], "brass", 12))
    p.add(sphere(0.045, "brass", 12, 8, m=move(0, 0.98, 0)))
    return p


@prop
def rope():
    """A velvet rope between two posts 1.6 m apart (x -0.8..0.8), hanging from y 0.92."""
    p = Prop("rope")
    pts = []
    for k in range(13):
        t = k / 12
        x = -0.77 + 1.54 * t
        pts.append((x, 0.92 - 0.26 * (1 - (2 * t - 1) ** 2), 0))
    p.add(tube(pts, 0.022, "rope_velvet", 8))
    for x in (-0.77, 0.77):
        p.add(lathe([(0.026, -0.04), (0.03, 0.0), (0.02, 0.04)], "brass", 8, m=move(x, 0.92, 0) @ rot_z(90)))
    return p


@prop
def wall_clock():
    """A brass-rimmed wall clock, 0.9 m across; back on z = 0, centre at y 0.45. The hands are
    their own nodes pivoting at the centre (HourHand, MinuteHand), pointing up (12) at rest;
    turn them about z."""
    p = Prop("wall_clock")
    c = (0, 0.45, 0)
    p.add(lathe([(0.0, 0.0), (0.45, 0.0), (0.45, 0.04), (0.43, 0.07), (0.41, 0.07), (0.405, 0.05)], "brass", 40, cap=(True, False), m=move(0, 0.45, 0) @ rot_x(90)))
    p.add(cyl(0.41, 0.0, 0.055, "paint_cream", 40, m=move(0, 0.45, 0) @ rot_x(90), bevel=0))
    for i in range(12):
        a = math.radians(i * 30)
        x, y = 0.34 * math.sin(a), 0.45 + 0.34 * math.cos(a)
        ln = 0.07 if i % 3 == 0 else 0.04
        p.add(box((-0.008, -ln / 2, 0), (0.008, ln / 2, 0.006), "ebony", 0.0, m=move(x, y, 0.055) @ rot_z(-i * 30)))
    p.add(cyl(0.025, 0.055, 0.075, "brass", 12, m=move(0, 0.45, 0) @ rot_x(90), bevel=0))
    p.add(box((-0.012, -0.03, 0.075), (0.012, 0.22, 0.082), "ebony", 0.0, m=move(0, 0.45, 0)), node="HourHand")
    p.add(box((-0.008, -0.04, 0.082), (0.008, 0.32, 0.088), "ebony", 0.0, m=move(0, 0.45, 0)), node="MinuteHand")
    p.pivot("HourHand", c)
    p.pivot("MinuteHand", c)
    return p


@prop
def drapes():
    """A pair of velvet drapes gathered back under a pelmet, for a window 2.4 m wide; 4.6 m tall,
    back on z = 0."""
    p = Prop("drapes")
    h, w = 4.6, 3.0
    for side in (-1, 1):
        def f(x, y, side=side):
            return 0.06 + 0.035 * math.sin((x - side * 1.1) * 38.0) * (0.6 + 0.4 * y / h)
        sheet = grid_sheet(0.7, h - 0.35, 18, 6, "velvet_burgundy", f, thickness=0.01)
        # Gather toward the tieback at y 1.3: pinch the sheet's width there.
        for v in sheet.bm.verts:
            pinch = 1.0 - 0.45 * math.exp(-((v.co.y - 1.3) / 0.5) ** 2)
            v.co.x *= pinch
            v.co.x += side * (w / 2 - 0.35)
        p.add(sheet)
        p.add(tube([(side * (w / 2 - 0.35) - 0.25, 1.3, 0.1), (side * (w / 2 - 0.35), 1.25, 0.14), (side * (w / 2 - 0.35) + 0.25, 1.3, 0.1)], 0.018, "velvet_gold", 6))
    p.add(box((-w / 2 - 0.1, h - 0.4, 0.0), (w / 2 + 0.1, h, 0.18), "velvet_burgundy", 0.03, 2))
    p.add(box((-w / 2 - 0.1, h - 0.42, 0.17), (w / 2 + 0.1, h - 0.38, 0.2), "velvet_gold", 0.01))
    return p


@prop
def canopy():
    """The entrance canopy: a black and brass canopy 4 m wide reaching 3.5 m out over the
    pavement on two brass posts, its fascia at y 3.3 to 3.7. Back on z = 0."""
    p = Prop("canopy")
    w, d = 4.0, 3.5
    p.add(box((-w / 2, 3.3, 0.0), (w / 2, 3.72, d), "iron", 0.02))
    p.add(box((-w / 2 - 0.02, 3.3, d - 0.02), (w / 2 + 0.02, 3.34, d + 0.02), "brass", 0.006))
    p.add(box((-w / 2 - 0.02, 3.68, d - 0.02), (w / 2 + 0.02, 3.72, d + 0.02), "brass", 0.006))
    for x in (-w / 2, w / 2):
        p.add(box((x - 0.02, 3.3, 0), (x + 0.02, 3.72, d), "brass", 0.006))
    p.add(box((-w / 2 + 0.05, 3.29, 0.05), (w / 2 - 0.05, 3.3, d - 0.05), "paint_cream", 0.0))
    for x in (-w / 2 + 0.15, w / 2 - 0.15):
        p.add(lathe([(0.0, 0), (0.09, 0), (0.09, 0.03), (0.05, 0.08), (0.04, 0.1)], "brass", 14, m=move(x, 0, d - 0.15)))
        p.add(cyl(0.04, 0.1, 3.3, "brass", 12, m=move(x, 0, d - 0.15), bevel=0))
    for i in range(4):
        x = -w / 2 + 0.5 + i * (w - 1.0) / 3
        p.add(cyl(0.06, 3.27, 3.29, "bulb", 10, m=move(x, 0, d * 0.5), bevel=0))
    return p


@prop
def street_lamp():
    """A cast-iron street lamp with a lantern, 4.6 m; the lantern's glow is at y 4.1."""
    p = Prop("street_lamp")
    p.add(lathe([(0.0, 0), (0.2, 0), (0.2, 0.08), (0.16, 0.12), (0.14, 0.5), (0.1, 0.56), (0.08, 0.7), (0.06, 1.0), (0.055, 3.6), (0.08, 3.7), (0.06, 3.76)], "cast_iron", 12))
    p.add(lathe([(0.03, 3.76), (0.18, 3.82), (0.18, 3.86), (0.12, 3.88)], "cast_iron", 8))
    p.add(lathe([(0.12, 3.88), (0.16, 4.35)], "lantern_glass", 8, cap=(False, False)))
    for i in range(8):
        a = 2 * math.pi * (i + 0.5) / 8
        p.add(tube([(0.12 * math.cos(a), 3.88, 0.12 * math.sin(a)), (0.16 * math.cos(a), 4.35, 0.16 * math.sin(a))], 0.008, "cast_iron", 4))
    p.add(lathe([(0.2, 4.35), (0.22, 4.38), (0.1, 4.5), (0.03, 4.56), (0.0, 4.62)], "cast_iron", 8))
    p.add(sphere(0.05, "bulb", 8, 6, m=move(0, 4.1, 0)))
    return p


# --- The ballroom ---------------------------------------------------------------------------------

@prop
def banquet_table():
    """A round banquet table, 1.8 m across, its white cloth to the floor, laid for eight with a
    low centrepiece of roses and candles. Chairs go at radius 1.15."""
    p = Prop("banquet_table")
    rng = random.Random(21)
    r, h = 0.9, 0.76

    def folds(a, y):
        return 1.0 + 0.025 * max(0.0, (h - 0.05 - y) / h) * math.sin(a * 22)
    prof = [(0.0, h + 0.012), (r - 0.02, h + 0.012), (r + 0.005, h), (r + 0.02, h - 0.04), (r + 0.03, h - 0.2), (r + 0.06, 0.02), (r + 0.06, 0.0)]
    p.add(lathe(prof, "linen", 48, cap=(True, True), wobble=folds))
    for i in range(8):
        a = 2 * math.pi * i / 8
        x, z = 0.66 * math.cos(a), 0.66 * math.sin(a)
        p.add(lathe([(0.0, h + 0.012), (0.12, h + 0.014), (0.135, h + 0.03), (0.13, h + 0.032)], "porcelain", 16, m=move(x, 0, z)))
        p.add(lathe([(0.0, h + 0.03), (0.055, h + 0.035), (0.05, h + 0.05)], "porcelain", 12, m=move(x, 0, z)))
        gx, gz = 0.66 * math.cos(a + 0.28), 0.66 * math.sin(a + 0.28)
        gx, gz = gx * 1.12, gz * 1.12
        p.add(lathe([(0.03, h + 0.012), (0.004, h + 0.02), (0.004, h + 0.1), (0.03, h + 0.13), (0.035, h + 0.2)], "glass", 8, cap=(True, False), m=move(gx, 0, gz)))
        # Napkin folded into a fan on the plate.
        p.add(prism([(-0.04, 0), (0.04, 0), (0.0, 0.11)], 0.03, "linen", plane="xy", m=move(x, h + 0.05, z) @ rot_y(-math.degrees(a) + 90), bevel=0.004))
        # Cutlery either side.
        for s in (-1, 1):
            q = Vector((x, 0, z)) + Vector((-math.sin(a), 0, math.cos(a))) * 0.17 * s
            p.add(box((-0.008, h + 0.012, -0.09), (0.008, h + 0.017, 0.09), "chrome", 0.0, m=move(q.x, 0, q.z) @ rot_y(-math.degrees(a))))
    # Centrepiece: a low silver bowl of roses, candles in glass round it.
    p.add(lathe([(0.0, h + 0.012), (0.08, h + 0.012), (0.06, h + 0.04), (0.04, h + 0.06), (0.16, h + 0.12), (0.17, h + 0.14)], "chrome", 16, cap=(True, False)))
    p.add(flowers(0, h + 0.1, 0, 0.2, 0.14, rng, colours=("rose_white", "rose_blush", "rose_white", "rose_red"), count=22, leaves=12))
    for i in range(5):
        a = 2 * math.pi * i / 5 + 0.3
        x, z = 0.3 * math.cos(a), 0.3 * math.sin(a)
        p.add(lathe([(0.03, h + 0.012), (0.032, h + 0.09)], "glass", 8, cap=(True, False), m=move(x, 0, z)))
        p.add(candle(x, h + 0.015, z, 0.05, 0.022))
    return p


@prop
def banquet_chair():
    """A gilt Chiavari chair with a cream cushion; the seat is at 0.46 m and its front faces +Z."""
    p = Prop("banquet_chair")
    mat = "gilt"
    sw, sd, sh = 0.42, 0.42, 0.45
    legs = [(-sw / 2 + 0.03, -sd / 2 + 0.03, 0.92), (sw / 2 - 0.03, -sd / 2 + 0.03, 0.92), (-sw / 2 + 0.035, sd / 2 - 0.03, sh), (sw / 2 - 0.035, sd / 2 - 0.03, sh)]
    for x, z, top in legs:
        back = z < 0
        pts = [(x * 0.95, 0.0, z - (0.03 if back else -0.02)), (x, sh, z), (x * 0.98, top, z - (0.05 if back else 0))]
        if not back:
            pts = pts[:2]
        p.add(tube(pts, 0.013, mat, 6, radii=[0.011, 0.014, 0.012][:len(pts)]))
    for y in (0.15, 0.3):
        for z in (-sd / 2 + 0.03, sd / 2 - 0.03):
            p.add(tube([(-sw / 2 + 0.035, y, z), (sw / 2 - 0.035, y, z)], 0.007, mat, 5))
        for x in (-sw / 2 + 0.035, sw / 2 - 0.035):
            p.add(tube([(x, y, -sd / 2 + 0.03), (x, y, sd / 2 - 0.03)], 0.007, mat, 5))
    p.add(box((-sw / 2 + 0.02, sh - 0.02, -sd / 2 + 0.02), (sw / 2 - 0.02, sh, sd / 2 - 0.02), mat, 0.006))
    # Back: rails and spindles.
    for y in (0.62, 0.78, 0.91):
        p.add(tube([(-sw / 2 + 0.035, y, -sd / 2 - 0.0), (sw / 2 - 0.035, y, -sd / 2 - 0.0)], 0.009, mat, 5))
    for i in range(4):
        x = -0.09 + i * 0.06
        p.add(tube([(x, 0.62, -sd / 2), (x, 0.78, -sd / 2)], 0.006, mat, 5))
    p.add(cushion((-sw / 2 + 0.02, sh, -sd / 2 + 0.03), (sw / 2 - 0.02, sh + 0.04, sd / 2 - 0.01), "cushion_cream", 0.015))
    return p


@prop
def stage():
    """The ballroom's stage: 8 x 4 m and 0.6 m high, a dark oak deck, a pleated velvet skirt
    with a gilt edge, and three steps (0.2 m each) at each front corner, 1.2 m wide, reaching
    0.75 m out in front. The deck is centred on x and z; the steps go past z = 2."""
    p = Prop("stage")
    w, d, h = 8.0, 4.0, 0.6
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "stage_floor", 0.01))
    p.add(box((-w / 2 + 0.05, 0, -d / 2 + 0.05), (w / 2 - 0.05, h - 0.05, d / 2 - 0.05), "walnut_dark", 0.004))

    def pleats(x, y):
        return 0.025 * math.sin(x * 30.0)
    skirt = grid_sheet(w - 2.6, h - 0.06, 80, 1, "velvet_burgundy", pleats)
    p.add(skirt.xf(move(0, 0.0, d / 2 + 0.03)))
    for side in (-1, 1):
        side_skirt = grid_sheet(d, h - 0.06, 40, 1, "velvet_burgundy", pleats)
        p.add(side_skirt.xf(move(side * (w / 2 + 0.03), 0, 0) @ rot_y(90 * side)))
    p.add(box((-w / 2 - 0.04, h - 0.09, d / 2), (w / 2 + 0.04, h - 0.05, d / 2 + 0.06), "gilt", 0.006))
    # Steps.
    for side in (-1, 1):
        x0 = side * (w / 2 - 0.6)
        for k in range(3):
            y = 0.2 * (k + 1)
            z1 = d / 2 + 0.75 - 0.25 * k
            p.add(box((x0 - 0.6, 0, d / 2 - 0.05), (x0 + 0.6, y, z1), "stage_floor", 0.01))
            p.add(box((x0 - 0.6, y - 0.02, z1 - 0.02), (x0 + 0.6, y, z1 + 0.005), "brass", 0.004))
    return p


@prop
def lectern():
    """A walnut lectern with a brass crest, a reading light and a microphone; 0.65 x 1.2 x 0.5.
    The speaker stands behind it (at -z), facing +z."""
    p = Prop("lectern")
    prof = [(-0.25, 0.0), (0.25, 0.0), (0.25, 0.05), (0.2, 0.08), (0.2, 1.0), (0.26, 1.14), (-0.24, 1.08), (-0.2, 1.0), (-0.2, 0.08), (-0.25, 0.05)]
    p.add(prism(prof, 0.62, "walnut", plane="zy", bevel=0.008))
    p.add(box((-0.25, 0.25, 0.2), (0.25, 0.85, 0.21), "walnut_dark", 0.004))
    p.add(panel_moulding(-0.22, 0.28, 0.22, 0.82, 0.21, 0.015, 0.008, "gilt"))
    p.add(cyl(0.07, 0.0, 0.015, "brass", 16, m=move(0, 0.55, 0.21) @ rot_x(90), bevel=0.003))
    p.add(tube([(0.2, 1.11, 0.1), (0.2, 1.2, 0.05), (0.18, 1.3, -0.05)], 0.008, "chrome", 6))
    p.add(sphere(0.022, "plastic_black", 8, 6, m=move(0.18, 1.32, -0.07)))
    p.add(tube([(-0.2, 1.1, 0.12), (-0.2, 1.22, 0.08), (-0.12, 1.24, 0.0)], 0.006, "brass", 6))
    p.add(box((-0.14, 1.22, -0.03), (-0.06, 1.25, 0.04), "brass", 0.004))
    return p


@prop
def curtain_stage():
    """The stage's backdrop: pleated burgundy velvet 10 m wide and 6.8 m tall under a swagged
    valance with gilt fringe; back on z = 0."""
    p = Prop("curtain_stage")
    w, h = 10.0, 6.8

    def pleats(x, y):
        return 0.1 + 0.06 * math.sin(x * 9.0) + 0.012 * math.sin(x * 23.0 + 1.0)
    p.add(grid_sheet(w, h - 0.7, 220, 2, "velvet_burgundy", pleats))
    for i in range(5):
        x0 = -w / 2 + i * w / 5

        def swag(x, y, x0=x0):
            return 0.3 + 0.04 * math.sin((x - x0) * 20.0)
        s = grid_sheet(w / 5 + 0.1, 0.8, 30, 4, "velvet_burgundy", swag)
        for v in s.bm.verts:
            t = (v.co.x + w / 10) / (w / 5)
            v.co.y = h - 0.9 + v.co.y * 0.8 - 0.35 * math.sin(t * math.pi) * (1 - v.co.y / 0.8)
        p.add(s.xf(move(x0 + w / 10, 0, 0)))
    p.add(box((-w / 2, h - 0.12, 0), (w / 2, h, 0.42), "gilt", 0.02))
    for i in range(6):
        x = -w / 2 + i * w / 5
        p.add(tube([(x, h - 0.2, 0.32), (x, h - 1.1, 0.34)], 0.025, "velvet_gold", 6))
        p.add(lathe([(0.0, h - 1.2), (0.06, h - 1.12), (0.04, h - 1.06)], "velvet_gold", 8, m=move(x, 0, 0.34)))
    return p


@prop
def display_plinth():
    """The museum's piece, under a cloth until the speech: a white plinth with a dark velvet
    cover draped over the shape on it. 0.8 x 1.75 x 0.8."""
    p = Prop("display_plinth")
    p.add(box((-0.4, 0.0, -0.4), (0.4, 0.06, 0.4), "marble_black", 0.008))
    p.add(box((-0.36, 0.06, -0.36), (0.36, 1.0, 0.36), "paint_white", 0.006))
    p.add(box((-0.4, 1.0, -0.4), (0.4, 1.06, 0.4), "marble_black", 0.008))

    def drape(a, y):
        return 1.0 + 0.06 * math.sin(a * 7 + y * 4) * max(0.0, (1.5 - y) / 0.5)
    prof = [(0.0, 1.75), (0.12, 1.74), (0.2, 1.68), (0.26, 1.55), (0.28, 1.4), (0.36, 1.2), (0.42, 1.07), (0.44, 1.02)]
    p.add(lathe(prof, "velvet_navy", 28, cap=(True, False), wobble=drape))
    p.add(tube([(0.33 * math.cos(a * math.pi / 8), 1.25, 0.33 * math.sin(a * math.pi / 8)) for a in range(16)], 0.012, "velvet_gold", 5, closed=True))
    return p


@prop
def wall_ballroom():
    """The ballroom's wall panelling, one 2 m bay, 4.4 m tall: skirting, a dado of raised
    panels, a chair rail, then a tall panel of champagne silk in a gilt frame; back on z = 0."""
    p = Prop("wall_ballroom")
    w, h = 2.0, 4.4
    x0, x1 = -w / 2, w / 2
    p.add(box((x0, 0.0, 0.0), (x1, h, 0.04), "paint_cream", 0.0))
    p.add(box((x0, 0.0, 0.04), (x1, 0.18, 0.07), "walnut_dark", 0.006))
    p.add(box((x0, 0.17, 0.04), (x1, 0.19, 0.075), "gilt", 0.003))
    p.add(box((x0 + 0.12, 0.3, 0.04), (x1 - 0.12, 0.84, 0.06), "paint_cream", 0.01))
    p.add(panel_moulding(x0 + 0.1, 0.28, x1 - 0.1, 0.86, 0.04, 0.025, 0.02, "paint_cream"))
    p.add(box((x0, 0.95, 0.04), (x1, 1.03, 0.085), "paint_cream", 0.012))
    p.add(box((x0, 0.97, 0.08), (x1, 1.0, 0.095), "gilt", 0.004))
    # The silk panel, set back in a gilt frame.
    p.add(box((x0 + 0.2, 1.25, 0.035), (x1 - 0.2, 4.0, 0.045), "silk", 0.0, uv=("x", "y", 2.0, 2.0, 0.0, 0.0)))
    p.add(panel_moulding(x0 + 0.16, 1.21, x1 - 0.16, 4.04, 0.04, 0.045, 0.035, "gilt"))
    p.add(panel_moulding(x0 + 0.24, 1.29, x1 - 0.24, 3.96, 0.045, 0.012, 0.012, "gilt"))
    # A pilaster strip at the bay's left edge, so bays join with one between them.
    p.add(box((x0, 1.03, 0.04), (x0 + 0.08, h, 0.07), "paint_cream", 0.006))
    p.add(box((x1 - 0.08, 1.03, 0.04), (x1, h, 0.07), "paint_cream", 0.006))
    p.add(box((x0, h - 0.12, 0.04), (x1, h, 0.09), "paint_cream", 0.01))
    p.add(box((x0, h - 0.13, 0.08), (x1, h - 0.11, 0.1), "gilt", 0.003))
    return p


@prop
def frieze_ballroom():
    """The ballroom's upper wall, over wall_ballroom: one 2 m bay, 2.6 m tall (4.4 to 7.0 when
    stacked), a small framed panel and a deep coved cornice with a gilt egg-and-dart band;
    back on z = 0."""
    p = Prop("frieze_ballroom")
    w, h = 2.0, 2.6
    x0, x1 = -w / 2, w / 2
    p.add(box((x0, 0.0, 0.0), (x1, h, 0.04), "paint_cream", 0.0))
    p.add(panel_moulding(x0 + 0.25, 0.25, x1 - 0.25, 1.45, 0.04, 0.03, 0.02, "gilt"))
    # Cornice: stepped and coved toward the ceiling.
    steps = [(1.75, 0.06), (1.85, 0.1), (1.95, 0.14), (2.1, 0.2), (2.25, 0.28), (2.4, 0.36), (2.5, 0.42), (2.6, 0.46)]
    prev = 1.65
    for y, depth in steps:
        p.add(box((x0, prev, 0.0), (x1, y, depth), "paint_cream", 0.006))
        prev = y
    p.add(box((x0, 1.84, 0.1), (x1, 1.88, 0.13), "gilt", 0.004))
    for i in range(10):
        x = x0 + 0.1 + i * 0.2
        p.add(sphere(0.03, "gilt", 8, 6, m=move(x, 2.03, 0.15) @ scale(1, 1.4, 0.6)))
    return p


@prop
def door_surround():
    """A grand doorway surround in walnut and gilt for a 2.4 x 3.0 m opening: architrave,
    a frieze and a broken pediment; 3.6 m wide, 4.4 m tall, back on z = 0, the opening
    centred on x from y 0 to 3. The wall behind it needs to show round the pediment."""
    p = Prop("door_surround")
    ow, oh = 2.4, 3.0
    x0, x1 = -ow / 2, ow / 2
    # Architrave: stepped jambs and head.
    for k, (wd, dp) in enumerate([(0.3, 0.06), (0.22, 0.1), (0.12, 0.13)]):
        for side in (-1, 1):
            xa = side * (ow / 2) if side > 0 else -ow / 2 - wd
            xb = xa + wd
            p.add(box((xa, 0.0, 0.0), (xb, oh + wd, dp), "walnut", 0.006))
        p.add(box((x0 - wd, oh, 0.0), (x1 + wd, oh + wd, dp), "walnut", 0.006))
    p.add(panel_moulding(x0 - 0.06, -0.02, x1 + 0.06, oh + 0.06, 0.13, 0.02, 0.012, "gilt"))
    # Plinth blocks.
    for side in (-1, 1):
        x = side * (ow / 2 + 0.16)
        p.add(box((x - 0.18, 0.0, 0.0), (x + 0.18, 0.3, 0.16), "walnut_dark", 0.008))
    # Frieze and pediment.
    p.add(box((x0 - 0.36, oh + 0.3, 0.0), (x1 + 0.36, oh + 0.62, 0.12), "walnut", 0.008))
    p.add(box((x0 - 0.2, oh + 0.38, 0.12), (x1 + 0.2, oh + 0.54, 0.135), "walnut_dark", 0.004))
    p.add(box((x0 - 0.46, oh + 0.62, 0.0), (x1 + 0.46, oh + 0.72, 0.24), "walnut", 0.01))
    p.add(box((x0 - 0.46, oh + 0.6, 0.22), (x1 + 0.46, oh + 0.63, 0.25), "gilt", 0.004))
    for side in (-1, 1):
        pts = [(side * 0.45, 0.0), (side * 1.62, 0.0), (side * 0.45, 0.62)]
        if side < 0:
            pts = [(-1.62, 0.0), (-0.45, 0.0), (-0.45, 0.62)]
        else:
            pts = [(0.45, 0.0), (1.62, 0.0), (0.45, 0.62)]
        p.add(prism(pts, 0.2, "walnut", plane="xy", m=move(0, oh + 0.72, 0.1), bevel=0.01))
    # A gilt cartouche in the broken pediment.
    p.add(lathe([(0.0, 0.0), (0.16, 0.0), (0.18, 0.04), (0.12, 0.08), (0.0, 0.1)], "gilt", 16, m=move(0, oh + 1.0, 0.1) @ rot_x(90) @ scale(1, 1, 1.3)))
    return p


# --- Doors -----------------------------------------------------------------------------------------

def leaf_base(p, w, h, t, mat):
    p.add(box((-w + 0.004, 0.0, -t / 2), (-0.004, h, t / 2), mat, 0.006))


def face_box(x0, y0, x1, y1, z, depth, zs, mat, bevel=0.004):
    """A box standing proud of a door face at z, `depth` toward side zs (+1 or -1)."""
    return box((x0, y0, min(z, z + zs * depth)), (x1, y1, max(z, z + zs * depth)), mat, bevel)


@prop
def door_grand():
    """A ballroom door leaf: 1.2 x 3.0 m walnut with raised panels, gilt beads, a brass push
    plate both sides and a kick plate. Hinged at the origin, spanning x -1.2..0."""
    p = Prop("door_grand")
    w, h, t = 1.2, 3.0, 0.07
    leaf_base(p, w, h, t, "walnut")
    for zs in (-1, 1):
        z = zs * t / 2
        for (y0, y1) in ((0.35, 1.25), (1.45, 2.8)):
            p.add(face_box(-w + 0.16, y0, -0.16, y1, z, 0.012, zs, "walnut", 0.01))
            p.add(panel_moulding(-w + 0.13, y0 - 0.03, -0.13, y1 + 0.03, z if zs > 0 else z - 0.012, 0.014, 0.012, "gilt"))
        p.add(face_box(-w + 0.02, 0.02, -0.02, 0.27, z, 0.004, zs, "brass", 0.002))
        p.add(face_box(-w + 0.08, 1.3, -w + 0.22, 1.7, z, 0.006, zs, "brass", 0.002))
    return p


@prop
def door_glass():
    """A front door leaf: 1.0 x 2.2 m of glass in a slim brass frame with a long brass pull.
    Hinged at the origin, spanning x -1.0..0."""
    p = Prop("door_glass")
    w, h, t = 1.0, 2.2, 0.05
    f = 0.07
    p.add(box((-w, 0, -t / 2), (-w + f, h, t / 2), "brass", 0.006))
    p.add(box((-f, 0, -t / 2), (0, h, t / 2), "brass", 0.006))
    p.add(box((-w + f, 0, -t / 2), (-f, 0.22, t / 2), "brass", 0.006))
    p.add(box((-w + f, h - f, -t / 2), (-f, h, t / 2), "brass", 0.006))
    p.add(box((-w + f, 0.22, -0.008), (-f, h - f, 0.008), "glass", 0.0))
    for zs in (-1, 1):
        p.add(tube([(-w + 0.16, 0.8, zs * 0.03), (-w + 0.16, 0.8, zs * 0.08), (-w + 0.16, 1.5, zs * 0.08), (-w + 0.16, 1.5, zs * 0.03)], 0.014, "brass", 8))
    return p


@prop
def door_kitchen():
    """The pass door between the kitchen and the ballroom: a 1.1 x 2.2 m painted leaf with a
    round porthole, stainless kick and push plates. Hinged at the origin, spanning x -1.1..0."""
    p = Prop("door_kitchen")
    w, h, t = 1.1, 2.2, 0.05
    cx, cy, r = -w / 2, 1.5, 0.18
    # The leaf, built round the porthole.
    p.add(box((-w, 0, -t / 2), (0, cy - r - 0.02, t / 2), "paint_cream", 0.006))
    p.add(box((-w, cy + r + 0.02, -t / 2), (0, h, t / 2), "paint_cream", 0.006))
    p.add(box((-w, cy - r - 0.02, -t / 2), (cx - r - 0.02, cy + r + 0.02, t / 2), "paint_cream", 0.006))
    p.add(box((cx + r + 0.02, cy - r - 0.02, -t / 2), (0, cy + r + 0.02, t / 2), "paint_cream", 0.006))
    ring = lathe([(r, -t / 2 - 0.01), (r + 0.04, -t / 2 - 0.01), (r + 0.04, t / 2 + 0.01), (r, t / 2 + 0.01)], "steel", 24, cap=(False, False), m=move(cx, cy, 0) @ rot_x(90))
    p.add(ring)
    p.add(cyl(r, -0.006, 0.006, "glass", 24, m=move(cx, cy, 0) @ rot_x(90), bevel=0))
    # Fill the corners round the ring.
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(face_box(-w + 0.01, 0.01, -0.01, 0.35, z, 0.004, zs, "steel", 0.002))
        p.add(face_box(-w + 0.06, 1.0, -w + 0.2, 1.3, z, 0.004, zs, "steel", 0.002))
    return p


@prop
def door_wood():
    """A staff door: a 1.1 x 2.2 m walnut-veneer leaf with a brass kick plate and a lever.
    Hinged at the origin, spanning x -1.1..0."""
    p = Prop("door_wood")
    w, h, t = 1.1, 2.2, 0.05
    leaf_base(p, w, h, t, "walnut_matte")
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(face_box(-w + 0.02, 0.02, -0.02, 0.25, z, 0.003, zs, "brass_aged", 0.001))
        p.add(face_box(-w + 0.05, 0.98, -w + 0.09, 1.12, z, 0.01, zs, "brass", 0.003))
        p.add(tube([(-w + 0.07, 1.05, z + 0.01 * zs), (-w + 0.07, 1.05, z + 0.06 * zs), (-w + 0.2, 1.05, z + 0.06 * zs)], 0.01, "brass", 6))
    return p


@prop
def door_steel():
    """A back-of-house steel door: 1.1 x 2.2 m painted grey, a wired glass vision panel, a push
    bar on one side and a pull handle on the other. Hinged at the origin, spanning x -1.1..0."""
    p = Prop("door_steel")
    w, h, t = 1.1, 2.2, 0.05
    vx0, vx1, vy0, vy1 = -w + 0.25, -w + 0.45, 1.3, 1.9
    p.add(box((-w, 0, -t / 2), (0, vy0, t / 2), "paint_door", 0.004))
    p.add(box((-w, vy1, -t / 2), (0, h, t / 2), "paint_door", 0.004))
    p.add(box((-w, vy0, -t / 2), (vx0, vy1, t / 2), "paint_door", 0.004))
    p.add(box((vx1, vy0, -t / 2), (0, vy1, t / 2), "paint_door", 0.004))
    p.add(box((vx0, vy0, -0.005), (vx1, vy1, 0.005), "glass_dark", 0.0))
    p.add(box((-w + 0.08, 0.95, t / 2), (-0.12, 1.05, t / 2 + 0.07), "steel", 0.01))
    p.add(tube([(-w + 0.08, 0.9, -t / 2), (-w + 0.08, 0.9, -t / 2 - 0.06), (-w + 0.08, 1.2, -t / 2 - 0.06), (-w + 0.08, 1.2, -t / 2)], 0.014, "steel", 8))
    return p


@prop
def doorframe_plain():
    """A plain architrave for the 1.1 x 2.2 m single doors, 1.4 x 2.36 m, painted; one face, back
    on z = 0, the opening centred on x."""
    p = Prop("doorframe_plain")
    ow, oh = 1.1, 2.2
    for side in (-1, 1):
        x = side * ow / 2
        p.add(box((min(x, x + side * 0.15), 0.0, 0.0), (max(x, x + side * 0.15), oh + 0.15, 0.03), "paint_white", 0.008))
    p.add(box((-ow / 2 - 0.15, oh, 0.0), (ow / 2 + 0.15, oh + 0.16, 0.03), "paint_white", 0.008))
    return p


@prop
def doorframe_walnut():
    """The staff door's architrave on the lobby side: walnut, 1.5 x 2.4 m, back on z = 0."""
    p = Prop("doorframe_walnut")
    ow, oh = 1.1, 2.2
    for side in (-1, 1):
        x = side * ow / 2
        p.add(box((min(x, x + side * 0.2), 0.0, 0.0), (max(x, x + side * 0.2), oh + 0.2, 0.05), "walnut", 0.008))
        p.add(box((min(x, x + side * 0.24) if side < 0 else x + 0.16, 0.0, 0.0), (x - 0.16 if side < 0 else x + 0.24, 0.24, 0.07), "walnut_dark", 0.006))
    p.add(box((-ow / 2 - 0.2, oh, 0.0), (ow / 2 + 0.2, oh + 0.2, 0.05), "walnut", 0.008))
    p.add(box((-ow / 2 - 0.24, oh + 0.2, 0.0), (ow / 2 + 0.24, oh + 0.26, 0.08), "walnut", 0.008))
    return p


# --- The kitchen ----------------------------------------------------------------------------------

def steel_table(p, w, d, h, upstand=False):
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2), "steel", 0.006))
    p.add(box((-w / 2, h - 0.08, d / 2 - 0.01), (w / 2, h - 0.04, d / 2 + 0.005), "steel", 0.004))
    if upstand:
        p.add(box((-w / 2, h, -d / 2), (w / 2, h + 0.1, -d / 2 + 0.02), "steel", 0.004))
    p.add(box((-w / 2 + 0.05, 0.18, -d / 2 + 0.05), (w / 2 - 0.05, 0.2, d / 2 - 0.05), "steel", 0.003))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        for z in (-d / 2 + 0.05, d / 2 - 0.05):
            p.add(cyl(0.02, 0.03, h - 0.04, "steel", 8, m=move(x, 0, z), bevel=0))
            p.add(cyl(0.025, 0.0, 0.03, "plastic_black", 8, m=move(x, 0, z), bevel=0))


@prop
def kitchen_counter():
    """A stainless prep table, 2 x 0.8 m, 0.9 m high, with an undershelf of trays and bowls."""
    p = Prop("kitchen_counter")
    steel_table(p, 2.0, 0.8, 0.9)
    rng = random.Random(30)
    for i in range(3):
        x = -0.6 + i * 0.6
        p.add(lathe([(0.0, 0.2), (0.12, 0.2), (0.17, 0.3), (0.165, 0.3)], "steel", 16, cap=(True, False), m=move(x, 0, 0.05)))
    p.add(box((-0.8, 0.9, -0.3), (-0.3, 0.93, 0.05), "oak", 0.006))
    p.add(box((0.2, 0.9, -0.25), (0.7, 0.92, 0.1), "steel", 0.004))
    for i in range(4):
        p.add(lathe([(0.0, 0.92 + i * 0.012), (0.1, 0.922 + i * 0.012), (0.11, 0.93 + i * 0.012)], "porcelain", 14, m=move(0.45, 0, -0.07)))
    return p


@prop
def kitchen_counter_wall():
    """A stainless wall bench with an upstand at the back, 2 x 0.7 m, 0.9 m high."""
    p = Prop("kitchen_counter_wall")
    steel_table(p, 2.0, 0.7, 0.9, upstand=True)
    p.add(box((-0.5, 0.9, -0.3), (-0.05, 0.92, 0.05), "steel", 0.003))
    p.add(lathe([(0.0, 0.9), (0.15, 0.9), (0.16, 1.15), (0.15, 1.15)], "steel", 16, cap=(True, False), m=move(0.5, 0, -0.08)))
    return p


@prop
def range_stove():
    """A six-burner range with an oven under, 1.2 m wide, 0.9 high, 0.85 deep; front faces +Z."""
    p = Prop("range_stove")
    w, h, d = 1.2, 0.9, 0.85
    p.add(box((-w / 2, 0.1, -d / 2), (w / 2, h - 0.05, d / 2), "steel", 0.006))
    p.add(box((-w / 2 + 0.03, 0.0, -d / 2 + 0.05), (w / 2 - 0.03, 0.1, d / 2 - 0.05), "steel_dark", 0.003))
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "cast_iron", 0.004))
    p.add(box((-w / 2, h, -d / 2), (w / 2, h + 0.12, -d / 2 + 0.06), "steel", 0.004))
    # Oven doors and the knob rail.
    for side in (-1, 1):
        x0 = side * 0.02
        x1 = side * (w / 2 - 0.03)
        p.add(box((min(x0, x1), 0.18, d / 2), (max(x0, x1), 0.68, d / 2 + 0.02), "steel", 0.006))
        hx = (x0 + x1) / 2
        p.add(tube([(hx - 0.2, 0.62, d / 2 + 0.02), (hx - 0.2, 0.62, d / 2 + 0.06), (hx + 0.2, 0.62, d / 2 + 0.06), (hx + 0.2, 0.62, d / 2 + 0.02)], 0.01, "chrome", 6))
    for i in range(6):
        x = -w / 2 + 0.12 + i * (w - 0.24) / 5
        p.add(cyl(0.022, 0.0, 0.03, "plastic_black", 10, m=move(x, 0.78, d / 2) @ rot_x(90), bevel=0.004))
    # Burners and grates.
    for i in range(3):
        for j in range(2):
            x = -0.4 + i * 0.4
            z = -0.2 + j * 0.38
            p.add(cyl(0.07, h, h + 0.02, "iron", 12, m=move(x, 0, z), bevel=0.003))
            for a in (0, 90):
                p.add(box((-0.17, h + 0.02, -0.008), (0.17, h + 0.04, 0.008), "cast_iron", 0.003, m=move(x, 0, z) @ rot_y(a)))
    # A stockpot and a sauté pan.
    p.add(lathe([(0.0, h + 0.04), (0.16, h + 0.04), (0.16, h + 0.34), (0.155, h + 0.34)], "steel", 18, cap=(True, False), m=move(-0.4, 0, -0.2)))
    p.add(lathe([(0.0, h + 0.04), (0.13, h + 0.04), (0.14, h + 0.1), (0.135, h + 0.1)], "steel", 16, cap=(True, False), m=move(0.4, 0, 0.18)))
    p.add(tube([(0.52, h + 0.09, 0.18), (0.8, h + 0.11, 0.18)], 0.012, "steel", 6))
    return p


@prop
def range_hood():
    """A stainless canopy hood over the range line: 4 m wide, 1.1 m deep, 0.7 m tall, with
    filters and lights under; hangs with its top at y = 0.7 (place it at the ceiling)."""
    p = Prop("range_hood")
    w, d, h = 4.0, 1.1, 0.7
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.06, d / 2), "steel", 0.006))
    p.add(box((-w / 2, 0.06, -d / 2), (w / 2, h, -d / 2 + 0.5), "steel", 0.006))
    p.add(prism([(d / 2, 0.06), (-d / 2 + 0.5, h), (-d / 2 + 0.5, 0.06)], w, "steel", plane="zy", bevel=0.004))
    for i in range(8):
        x = -w / 2 + 0.25 + i * (w - 0.5) / 7
        p.add(box((x - 0.2, 0.06, -0.2), (x + 0.2, 0.28, -0.18), "steel_dark", 0.002, m=move(0, 0, 0) @ Matrix.Identity(4)))
    for i in range(3):
        x = -1.2 + i * 1.2
        p.add(box((x - 0.15, -0.005, 0.25), (x + 0.15, 0.0, 0.4), "bulb", 0.0))
    return p


@prop
def pot_shelf():
    """Wire shelving, 1.5 x 1.8 x 0.5 m, of stockpots, pans, sheet trays and plates."""
    p = Prop("pot_shelf")
    w, h, d = 1.5, 1.8, 0.5
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        for z in (-d / 2 + 0.02, d / 2 - 0.02):
            p.add(cyl(0.013, 0.0, h, "chrome", 8, m=move(x, 0, z), bevel=0))
    rng = random.Random(14)
    levels = [0.15, 0.6, 1.1, 1.62]
    for y in levels:
        p.add(box((-w / 2, y - 0.015, -d / 2), (w / 2, y, d / 2), "chrome", 0.002))
        for i in range(14):
            x = -w / 2 + 0.05 + i * (w - 0.1) / 13
            p.add(box((x - 0.002, y, -d / 2), (x + 0.002, y + 0.005, d / 2), "chrome", 0.0))
    # Load each level.
    p.add(lathe([(0.0, 0.15), (0.2, 0.15), (0.2, 0.5), (0.19, 0.5)], "steel", 18, cap=(True, False), m=move(-0.4, 0, 0)))
    p.add(lathe([(0.0, 0.15), (0.18, 0.15), (0.18, 0.42), (0.17, 0.42)], "pot_copper", 18, cap=(True, False), m=move(0.25, 0, 0)))
    for k in range(6):
        p.add(box((-0.7, 0.6 + k * 0.025, -0.22), (-0.05, 0.615 + k * 0.025, 0.22), "steel", 0.004))
    for k in range(12):
        p.add(lathe([(0.0, 0.6 + k * 0.015), (0.12, 0.602 + k * 0.015), (0.13, 0.612 + k * 0.015)], "porcelain", 14, m=move(0.4, 0, 0)))
    for i in range(3):
        x = -0.5 + i * 0.45
        p.add(lathe([(0.0, 1.1), (0.14, 1.1), (0.16, 1.18), (0.155, 1.18)], "steel" if i != 1 else "pot_copper", 16, cap=(True, False), m=move(x, 0, 0)))
        p.add(tube([(x + 0.16, 1.16, 0), (x + 0.16, 1.16, 0.3)], 0.01, "steel", 6))
    for i in range(4):
        x = -0.55 + i * 0.36
        p.add(lathe([(0.0, 1.62), (0.13, 1.62), (0.14, 1.78), (0.135, 1.78)], "steel", 16, cap=(True, False), m=move(x, 0, 0.02)))
    return p


@prop
def pass_counter():
    """The pass: a heated stainless counter 3 m long and 0.9 high, plates waiting under a
    gantry of glowing heat lamps (at 1.7 m), a ticket rail along it. The waiters' side is +Z."""
    p = Prop("pass_counter")
    w, d, h = 3.0, 0.8, 0.9
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h - 0.04, d / 2), "steel", 0.006))
    p.add(box((-w / 2 - 0.02, h - 0.04, -d / 2 - 0.02), (w / 2 + 0.02, h, d / 2 + 0.02), "steel", 0.006))
    for i in range(4):
        x = -w / 2 + 0.4 + i * (w - 0.8) / 3
        p.add(box((x - 0.3, 0.12, d / 2), (x + 0.3, 0.78, d / 2 + 0.015), "steel", 0.004))
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        p.add(box((x - 0.03, h, -0.03), (x + 0.03, 1.72, 0.03), "steel", 0.004))
    p.add(box((-w / 2, 1.7, -0.15), (w / 2, 1.8, 0.15), "steel", 0.006))
    for i in range(6):
        x = -w / 2 + 0.3 + i * (w - 0.6) / 5
        p.add(lathe([(0.0, 1.62), (0.08, 1.66), (0.09, 1.7)], "steel_dark", 12, m=move(x, 0, 0)))
        p.add(cyl(0.07, 1.61, 1.63, "heat_lamp", 12, m=move(x, 0, 0), bevel=0))
    p.add(box((-w / 2, 1.5, 0.15), (w / 2, 1.53, 0.18), "steel", 0.003))
    for i in range(7):
        x = -w / 2 + 0.3 + i * 0.4
        p.add(box((x - 0.04, 1.36, 0.17), (x + 0.04, 1.51, 0.172), "paper", 0.0))
    rng = random.Random(8)
    for i in range(6):
        x = -w / 2 + 0.3 + i * 0.48
        z = -0.1 + (i % 2) * 0.2
        p.add(lathe([(0.0, h), (0.08, h), (0.13, h + 0.015), (0.14, h + 0.025)], "porcelain", 16, m=move(x, 0, z)))
        if i % 2 == 0:
            p.add(lathe([(0.12, h + 0.02), (0.11, h + 0.08), (0.06, h + 0.12), (0.0, h + 0.13)], "chrome", 14, m=move(x, 0, z)))
            p.add(sphere(0.015, "chrome", 6, 4, m=move(x, h + 0.14, z)))
        else:
            p.add(ico(0.05, "rose_blush", 1, m=move(x, h + 0.04, z) @ scale(1.2, 0.5, 1.0)))
    return p


@prop
def freezer_door():
    """The walk-in freezer's door in its frame: 1.6 x 2.5 m of white insulated panel with a
    heavy steel door, chrome hinges, a latch and a temperature readout; back on z = 0."""
    p = Prop("freezer_door")
    w, h = 1.6, 2.5
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, 0.06), "paint_white", 0.006))
    p.add(box((-0.55, 0.02, 0.06), (0.55, 2.1, 0.16), "steel", 0.012))
    for y in (0.4, 1.7):
        p.add(box((0.5, y - 0.12, 0.06), (0.62, y + 0.12, 0.2), "chrome", 0.01))
    p.add(box((-0.52, 0.95, 0.16), (-0.36, 1.25, 0.2), "chrome", 0.008))
    p.add(tube([(-0.44, 1.1, 0.2), (-0.44, 1.1, 0.26), (-0.2, 1.1, 0.26)], 0.018, "chrome", 8))
    p.add(box((-0.12, 2.2, 0.06), (0.12, 2.34, 0.1), "plastic_black", 0.006))
    p.add(box((-0.09, 2.23, 0.1), (0.09, 2.31, 0.102), "led_red", 0.0))
    return p


@prop
def service_trolley():
    """A three-tier stainless service trolley, 0.9 x 0.95 x 0.5, with a tray of glasses."""
    p = Prop("service_trolley")
    w, d, h = 0.9, 0.5, 0.95
    for y in (0.15, 0.52, 0.89):
        p.add(box((-w / 2, y, -d / 2), (w / 2, y + 0.025, d / 2), "steel", 0.004))
        p.add(box((-w / 2, y + 0.025, -d / 2), (w / 2, y + 0.06, -d / 2 + 0.01), "steel", 0.002))
        p.add(box((-w / 2, y + 0.025, d / 2 - 0.01), (w / 2, y + 0.06, d / 2), "steel", 0.002))
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        for z in (-d / 2 + 0.02, d / 2 - 0.02):
            p.add(cyl(0.012, 0.09, h, "steel", 8, m=move(x, 0, z), bevel=0))
            p.add(cyl(0.045, -0.015, 0.015, "rubber", 10, m=move(x, 0.045, z) @ rot_x(90), bevel=0.003))
    p.add(tube([(-w / 2 - 0.02, 0.9, -0.15), (-w / 2 - 0.08, 0.9, -0.15), (-w / 2 - 0.08, 0.9, 0.15), (-w / 2 - 0.02, 0.9, 0.15)], 0.012, "steel", 6))
    p.add(cyl(0.2, 0.915, 0.93, "chrome", 20, bevel=0.003))
    for i in range(7):
        a = 2 * math.pi * i / 7
        x, z = 0.12 * math.cos(a), 0.12 * math.sin(a)
        p.add(lathe([(0.03, 0.93), (0.004, 0.94), (0.004, 1.02), (0.032, 1.05), (0.036, 1.12)], "glass", 8, cap=(True, False), m=move(x, 0, z)))
    return p


# --- The staff room --------------------------------------------------------------------------------

@prop
def lockers():
    """A bank of five staff lockers, 2 m wide, 1.9 high, 0.5 deep, with vents, number plates and
    handles; front faces +Z."""
    p = Prop("lockers")
    n, lw, h, d = 5, 0.4, 1.9, 0.5
    w = n * lw
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.1, d / 2 - 0.03), "plastic_black", 0.003))
    p.add(box((-w / 2, 0.1, -d / 2), (w / 2, h, d / 2 - 0.02), "paint_locker", 0.004))
    for i in range(n):
        x0 = -w / 2 + i * lw + 0.008
        x1 = x0 + lw - 0.016
        p.add(box((x0, 0.12, d / 2 - 0.02), (x1, h - 0.02, d / 2), "paint_locker", 0.006))
        for k in range(5):
            y = h - 0.25 + k * 0.03
            p.add(box((x0 + 0.08, y, d / 2), (x1 - 0.08, y + 0.012, d / 2 + 0.004), "plastic_black", 0.0))
        p.add(box((x1 - 0.06, 0.9, d / 2), (x1 - 0.035, 1.1, d / 2 + 0.03), "chrome", 0.004))
        p.add(box((x0 + 0.13, 1.45, d / 2), (x1 - 0.13, 1.5, d / 2 + 0.003), "brass_aged", 0.001))
    p.add(box((-w / 2, h, -d / 2), (w / 2, h + 0.02, d / 2), "paint_locker", 0.003))
    return p


@prop
def locker_bench():
    """A slatted oak bench on steel legs, 1.8 x 0.45 x 0.35."""
    p = Prop("locker_bench")
    for i in range(3):
        z = -0.13 + i * 0.13
        p.add(box((-0.9, 0.4, z - 0.055), (0.9, 0.44, z + 0.055), "oak", 0.006))
    for x in (-0.75, 0.75):
        p.add(box((x - 0.02, 0.0, -0.16), (x + 0.02, 0.4, -0.12), "steel_dark", 0.003))
        p.add(box((x - 0.02, 0.0, 0.12), (x + 0.02, 0.4, 0.16), "steel_dark", 0.003))
        p.add(box((x - 0.02, 0.36, -0.16), (x + 0.02, 0.4, 0.16), "steel_dark", 0.003))
    return p


@prop
def jacket_rack():
    """A chrome rolling rail with five waiter's white jackets on wooden hangers (nodes Jacket_1
    to Jacket_5, so the game can take one away), 1.5 x 1.75 x 0.55; the rail is at y 1.65."""
    p = Prop("jacket_rack")
    w, d = 1.5, 0.55
    for side in (-1, 1):
        x = side * (w / 2)
        p.add(tube([(x, 0.08, -d / 2), (x, 0.08, d / 2)], 0.015, "chrome", 8))
        p.add(tube([(x, 0.08, 0), (x, 1.68, 0)], 0.015, "chrome", 8))
        for z in (-d / 2, d / 2):
            p.add(cyl(0.035, -0.012, 0.012, "rubber", 10, m=move(x, 0.035, z) @ rot_z(90), bevel=0.003))
    p.add(tube([(-w / 2, 1.65, 0), (w / 2, 1.65, 0)], 0.014, "chrome", 8))
    for i in range(5):
        x = -0.54 + i * 0.27
        node = "Jacket_%d" % (i + 1)
        parts = [tube([(x, 1.65, -0.012), (x, 1.69, 0), (x, 1.65, 0.012)], 0.004, "chrome", 4)]
        # A white mess jacket on a wooden hanger, front toward +Z, then turned along the rail.
        j = []
        j.append(tube([(-0.2, 1.56, 0), (0.0, 1.6, 0), (0.2, 1.56, 0)], 0.012, "oak", 6))
        outline = [(-0.19, 0.0), (0.19, 0.0), (0.205, 0.4), (0.215, 0.56), (0.14, 0.62), (-0.14, 0.62), (-0.215, 0.56), (-0.205, 0.4)]
        j.append(prism(outline, 0.11, "jacket_white", plane="xy", m=move(0, 0.97, 0), bevel=0.03, seg=2))
        for s_ in (-1, 1):
            j.append(tube([(s_ * 0.215, 1.55, 0.0), (s_ * 0.235, 1.3, 0.01), (s_ * 0.235, 1.02, 0.02)], 0.05, "jacket_white", 8, radii=[0.055, 0.05, 0.045]))
            j.append(prism([(0.0, 0.0), (0.07, 0.0), (0.02, 0.24)], 0.012, "jacket_white", plane="xy", m=move(s_ * 0.005, 1.33, 0.06) @ scale(s_, 1, 1), bevel=0.004))
        j.append(box((-0.06, 1.57, -0.035), (0.06, 1.63, 0.035), "jacket_white", 0.015))
        for k in range(3):
            j.append(sphere(0.009, "brass", 6, 4, m=move(0.03, 1.27 - k * 0.1, 0.058)))
        turn = move(x, 0, 0) @ rot_y(60)
        for q in j:
            parts.append(q.xf(turn))
        p.add(parts, node=node)
    return p


@prop
def notice_board():
    """A cork notice board with the rota and a few notes pinned to it; 1.2 x 0.9, back on
    z = 0, bottom at y = 0."""
    p = Prop("notice_board")
    p.add(box((-0.6, 0.0, 0.0), (0.6, 0.9, 0.03), "oak", 0.006))
    p.add(box((-0.56, 0.04, 0.03), (0.56, 0.86, 0.035), "cork", 0.0))
    rng = random.Random(6)
    for i in range(7):
        x = -0.45 + (i % 4) * 0.28 + rng.random() * 0.04
        y = 0.5 - (i // 4) * 0.35 + rng.random() * 0.05
        p.add(box((x - 0.1, y - 0.14, 0.035), (x + 0.1, y + 0.14, 0.038), "paper", 0.0, m=move(x, y, 0) @ rot_z(rng.random() * 8 - 4) @ move(-x, -y, 0)))
        p.add(sphere(0.008, "led_red" if i % 3 else "rose_white", 6, 4, m=move(x, y + 0.12, 0.042)))
    return p


# --- The security office ---------------------------------------------------------------------------

@prop
def office_desk():
    """An office desk, 1.6 x 0.76 x 0.8, with a drawer pedestal, a phone, a logbook and a mug."""
    p = Prop("office_desk")
    w, d, h = 1.6, 0.8, 0.76
    p.add(box((-w / 2, h - 0.03, -d / 2), (w / 2, h, d / 2), "oak", 0.006))
    p.add(box((w / 2 - 0.45, 0.0, -d / 2 + 0.02), (w / 2 - 0.02, h - 0.03, d / 2 - 0.02), "paint_grey", 0.004))
    for k in range(3):
        y0 = 0.05 + k * 0.22
        p.add(box((w / 2 - 0.44, y0, d / 2 - 0.02), (w / 2 - 0.03, y0 + 0.2, d / 2), "paint_grey", 0.004))
        p.add(box((w / 2 - 0.3, y0 + 0.14, d / 2), (w / 2 - 0.17, y0 + 0.16, d / 2 + 0.02), "chrome", 0.003))
    p.add(box((-w / 2 + 0.02, 0.0, -d / 2 + 0.02), (-w / 2 + 0.05, h - 0.03, d / 2 - 0.02), "paint_grey", 0.003))
    p.add(box((-w / 2 + 0.05, 0.3, -d / 2 + 0.02), (w / 2 - 0.45, h - 0.05, -d / 2 + 0.04), "paint_grey", 0.003))
    p.add(box((-0.6, h, -0.2), (-0.3, h + 0.07, 0.0), "plastic_black", 0.01))
    p.add(box((-0.6, h + 0.07, -0.2), (-0.3, h + 0.1, -0.15), "plastic_black", 0.01))
    p.add(box((-0.1, h, 0.0), (0.3, h + 0.025, 0.3), "leather_black", 0.004))
    p.add(box((-0.08, h + 0.025, 0.02), (0.28, h + 0.03, 0.28), "paper", 0.0))
    p.add(lathe([(0.0, h), (0.04, h), (0.042, h + 0.1), (0.038, h + 0.1)], "porcelain", 12, cap=(True, False), m=move(0.55, 0, 0.1)))
    return p


@prop
def cctv_monitors():
    """The security office's camera wall: a console 2.4 m wide and 0.75 high with six screens
    above it in two rows on a steel frame, a keyboard and a camera joystick. The screens use
    the material `screen` (the game can give them a picture); front faces +Z."""
    p = Prop("cctv_monitors")
    w, d, h = 2.4, 0.7, 0.75
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h - 0.03, d / 2), "paint_grey", 0.006))
    p.add(box((-w / 2 - 0.02, h - 0.03, -d / 2), (w / 2 + 0.02, h, d / 2 + 0.03), "plastic_black", 0.006))
    for x in (-w / 2 + 0.1, w / 2 - 0.1):
        p.add(box((x - 0.03, h, -d / 2 + 0.02), (x + 0.03, 1.95, -d / 2 + 0.08), "steel_dark", 0.004))
    for y in (1.08, 1.6):
        p.add(box((-w / 2 + 0.07, y - 0.02, -d / 2 + 0.03), (w / 2 - 0.07, y + 0.02, -d / 2 + 0.07), "steel_dark", 0.003))
        for i in range(3):
            x = -0.78 + i * 0.78
            p.add(box((x - 0.37, y - 0.24, -d / 2 + 0.07), (x + 0.37, y + 0.22, -d / 2 + 0.14), "plastic_black", 0.01))
            p.add(box((x - 0.34, y - 0.21, -d / 2 + 0.14), (x + 0.34, y + 0.19, -d / 2 + 0.142), "screen", 0.0))
            p.add(box((x + 0.3, y - 0.235, -d / 2 + 0.14), (x + 0.32, y - 0.225, -d / 2 + 0.143), "led_green", 0.0))
    p.add(box((-0.3, h, 0.05), (0.2, h + 0.025, 0.22), "plastic_black", 0.006))
    p.add(box((0.45, h, 0.05), (0.65, h + 0.04, 0.22), "plastic_black", 0.01))
    p.add(cyl(0.012, h + 0.04, h + 0.15, "plastic_black", 8, m=move(0.55, 0, 0.13), bevel=0))
    p.add(sphere(0.02, "led_red", 8, 6, m=move(0.55, h + 0.16, 0.13)))
    p.add(box((-0.9, h, 0.0), (-0.6, h + 0.18, 0.12), "plastic_black", 0.01))
    for k in range(4):
        p.add(cyl(0.012, 0.0, 0.16, "plastic_black", 6, m=move(-0.85 + k * 0.06, h + 0.18, 0.06), bevel=0))
        p.add(sphere(0.008, "led_green", 4, 3, m=move(-0.85 + k * 0.06, h + 0.12, 0.122)))
    return p


@prop
def office_chair():
    """A black swivel office chair, 0.65 x 1.05 x 0.65; faces +Z."""
    p = Prop("office_chair")
    for i in range(5):
        a = 2 * math.pi * i / 5 + math.pi / 2
        x, z = 0.3 * math.cos(a), 0.3 * math.sin(a)
        p.add(tube([(0, 0.1, 0), (x, 0.07, z)], 0.022, "plastic_black", 6))
        p.add(sphere(0.03, "rubber", 8, 6, m=move(x, 0.03, z)))
    p.add(cyl(0.025, 0.1, 0.4, "chrome", 10, bevel=0))
    p.add(cushion((-0.25, 0.4, -0.22), (0.25, 0.5, 0.25), "leather_black", 0.04))
    p.add(box((-0.03, 0.42, -0.3), (0.03, 0.62, -0.24), "plastic_black", 0.01))
    p.add(cushion((-0.23, 0.55, -0.32), (0.23, 1.05, -0.24), "leather_black", 0.04).xf(move(0, 0.55, -0.28) @ rot_x(-8) @ move(0, -0.55, 0.28)))
    for s in (-1, 1):
        p.add(tube([(s * 0.25, 0.48, -0.05), (s * 0.27, 0.65, -0.05), (s * 0.27, 0.65, 0.15)], 0.015, "plastic_black", 6))
    return p


@prop
def filing_cabinet():
    """A four-drawer grey filing cabinet, 0.47 x 1.32 x 0.62; front faces +Z."""
    p = Prop("filing_cabinet")
    w, h, d = 0.47, 1.32, 0.62
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2 - 0.02), "paint_grey", 0.004))
    for k in range(4):
        y0 = 0.03 + k * 0.32
        p.add(box((-w / 2 + 0.01, y0, d / 2 - 0.02), (w / 2 - 0.01, y0 + 0.3, d / 2), "paint_grey", 0.005))
        p.add(box((-0.08, y0 + 0.22, d / 2), (0.08, y0 + 0.24, d / 2 + 0.03), "chrome", 0.004))
        p.add(box((-0.05, y0 + 0.25, d / 2), (0.05, y0 + 0.28, d / 2 + 0.003), "paper", 0.0))
    return p


@prop
def keypad():
    """The kitchen door's keypad: a steel plate with twelve keys and a status light; 0.1 x 0.16,
    back on z = 0, centre at y 0.08."""
    p = Prop("keypad")
    p.add(box((-0.05, 0.0, 0.0), (0.05, 0.16, 0.025), "steel", 0.004))
    for i in range(3):
        for j in range(4):
            x = -0.025 + i * 0.025
            y = 0.03 + j * 0.025
            p.add(box((x - 0.009, y - 0.009, 0.025), (x + 0.009, y + 0.009, 0.031), "steel_dark", 0.0015, 1))
    p.add(box((-0.03, 0.135, 0.025), (0.03, 0.145, 0.027), "led_red", 0.0))
    return p


@prop
def cctv_camera():
    """A dome-less corridor camera on a wall bracket; back on z = 0, at y 0."""
    p = Prop("cctv_camera")
    p.add(box((-0.04, -0.06, 0.0), (0.04, 0.06, 0.02), "paint_white", 0.004))
    p.add(tube([(0, 0, 0.02), (0, 0.0, 0.12), (0, -0.04, 0.16)], 0.012, "paint_white", 6))
    head = move(0, -0.06, 0.16) @ rot_x(20)
    p.add(box((-0.045, -0.04, -0.06), (0.045, 0.04, 0.16), "paint_white", 0.01, m=head))
    p.add(cyl(0.026, 0.0, 0.012, "glass_dark", 10, m=head @ move(0, 0, 0.16) @ rot_x(90), bevel=0))
    p.add(box((-0.05, 0.04, -0.07), (0.05, 0.045, 0.2), "paint_white", 0.0, m=head))
    p.add(sphere(0.006, "led_red", 4, 3, m=head @ move(0.03, 0.02, 0.15)))
    return p


@prop
def bulkhead_light():
    """A caged bulkhead light for the loading bay and back corridors; back on z = 0."""
    p = Prop("bulkhead_light")
    p.add(box((-0.16, -0.1, 0.0), (0.16, 0.1, 0.05), "cast_iron", 0.01))
    p.add(box((-0.13, -0.07, 0.05), (0.13, 0.07, 0.1), "lantern_glass", 0.03, 2))
    for i in range(3):
        x = -0.08 + i * 0.08
        p.add(tube([(x, -0.08, 0.05), (x, -0.08, 0.11), (x, 0.08, 0.11), (x, 0.08, 0.05)], 0.005, "cast_iron", 4))
    return p


# --- The loading bay --------------------------------------------------------------------------------

@prop
def dumpster():
    """A green steel dumpster with black lids on castors, 1.9 x 1.3 x 1.1; front faces +Z."""
    p = Prop("dumpster")
    w, d = 1.9, 1.1
    body = box((-w / 2, 0.15, -d / 2), (w / 2, 1.18, d / 2), "paint_green", 0.03)
    for v in body.bm.verts:
        if v.co.y < 0.5 and v.co.z > 0:
            v.co.z -= 0.15 * (0.5 - v.co.y) / 0.35
    p.add(body)
    p.add(box((-w / 2 - 0.03, 1.1, -d / 2 - 0.03), (w / 2 + 0.03, 1.16, d / 2 + 0.03), "paint_green", 0.01))
    for side in (-1, 1):
        lid = box((0.0, 0.0, -d / 2 - 0.02), (w / 2 - 0.01, 0.06, d / 2 + 0.04), "plastic_black", 0.02)
        p.add(lid.xf(move(0, 1.18, 0) @ rot_x(-4) @ (move(-w / 2, 0, 0) if side < 0 else move(0.01, 0, 0))))
    for x in (-w / 2 + 0.15, w / 2 - 0.15):
        for z in (-d / 2 + 0.15, d / 2 - 0.15):
            p.add(cyl(0.065, -0.02, 0.02, "rubber", 12, m=move(x, 0.065, z) @ rot_x(90), bevel=0.004))
            p.add(box((x - 0.03, 0.09, z - 0.04), (x + 0.03, 0.15, z + 0.04), "steel_dark", 0.004))
    p.add(tube([(-w / 2 - 0.08, 0.9, -0.3), (-w / 2 - 0.08, 0.9, 0.3)], 0.02, "steel_dark", 6))
    return p


@prop
def wheelie_bin():
    """A dark grey wheelie bin, 0.6 x 1.07 x 0.73, wheels at the back (-Z)."""
    p = Prop("wheelie_bin")
    body = box((-0.29, 0.04, -0.33), (0.29, 1.0, 0.33), "paint_bin", 0.03)
    for v in body.bm.verts:
        s = 0.88 + 0.12 * v.co.y
        v.co.x *= s
        v.co.z *= s
    p.add(body)
    p.add(box((-0.31, 1.0, -0.37), (0.31, 1.06, 0.37), "paint_bin", 0.02))
    p.add(tube([(-0.25, 0.98, -0.4), (0.25, 0.98, -0.4)], 0.018, "paint_bin", 6))
    for x in (-0.24, 0.24):
        p.add(cyl(0.1, -0.03, 0.03, "rubber", 12, m=move(x, 0.1, -0.3) @ rot_z(90), bevel=0.004))
    p.add(tube([(-0.3, 0.1, -0.3), (0.3, 0.1, -0.3)], 0.012, "steel_dark", 6))
    return p


@prop
def pallet():
    """A wooden pallet with two cardboard cartons on it, 1.2 x 0.9 x 1.0."""
    p = Prop("pallet")
    for z in (-0.45, 0.0, 0.45):
        p.add(box((-0.6, 0.0, z - 0.05), (0.6, 0.1, z + 0.05), "wood_pallet", 0.006))
    for i in range(7):
        x = -0.55 + i * (1.1 / 6)
        p.add(box((x - 0.05, 0.1, -0.5), (x + 0.05, 0.13, 0.5), "wood_pallet", 0.004))
    p.add(box((-0.55, 0.13, -0.45), (0.0, 0.58, 0.4), "cardboard", 0.006))
    p.add(box((0.02, 0.13, -0.42), (0.55, 0.5, 0.35), "cardboard", 0.006))
    p.add(box((-0.5, 0.58, -0.4), (-0.05, 0.9, 0.3), "cardboard", 0.006))
    return p


@prop
def bay_gate():
    """A steel palisade gate panel for the loading bay, 3.5 m wide and 2.6 m tall, with a post
    at its left end (x -1.75); panels join end to end."""
    p = Prop("bay_gate")
    w, h = 3.5, 2.6
    p.add(box((-w / 2 - 0.06, 0.0, -0.06), (-w / 2 + 0.06, h + 0.1, 0.06), "cast_iron", 0.006))
    for y in (0.3, h - 0.3):
        p.add(box((-w / 2, y - 0.03, -0.02), (w / 2, y + 0.03, 0.02), "cast_iron", 0.004))
    n = 22
    for i in range(n):
        x = -w / 2 + 0.12 + i * (w - 0.2) / (n - 1)
        p.add(box((x - 0.025, 0.04, 0.02), (x + 0.025, h - 0.12, 0.035), "cast_iron", 0.003))
        p.add(prism([(-0.035, 0.0), (0.035, 0.0), (0.0, 0.14)], 0.015, "cast_iron", m=move(x, h - 0.12, 0.028), bevel=0.0))
    return p


# --- Main ---------------------------------------------------------------------------------------

def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if "--list" in args:
        for n, fn in PROPS.items():
            print("%-20s %s" % (n, (fn.__doc__ or "").strip().split("\n")[0]))
        return
    os.makedirs(OUT, exist_ok=True)
    want = args or list(PROPS)
    for name in want:
        if name not in PROPS:
            print("no prop called", name)
            continue
        export(PROPS[name](), os.path.join(OUT, name + ".glb"))


if __name__ == "__main__":
    main()
