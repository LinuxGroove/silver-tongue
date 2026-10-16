"""Builds the Marlin's props (the hull, the gangway, doors, furniture, the bridge, the auction's
rostrum and the Rose's case, the quay's van and crates) and writes each as a GLB:

    /tmp/claude-0/bpy/venv/bin/python tools/blender/marlin_props.py [prop ...]

Naming props rebuilds only those; `--list` prints them. They go to assets/models/marlin/, where
`Kit` finds them by name, so every name starts with `marlin_`. The conventions are props.py's:
Godot's axes, metres, floor props on y = 0 centred on their footprint with their front facing +Z,
wall props with their back on z = 0, door leaves hinged at the origin spanning -x.

The Marlin's decks: the quay is y = 0, the lower deck -1.5, the main deck 1.2 and the upper deck
4.2; the stern (transom) is at z = -2 and the bow points north (-z), port is -x.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import props  # noqa: E402  (bpy first, then props' helpers)
from props import Prop, box, cyl, lathe, tube, prism, sphere, move, rot_x, rot_y, rot_z, scale  # noqa: E402

import bmesh  # noqa: E402
from mathutils import Vector  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models", "marlin")
props.TEX = os.path.join(ROOT, "assets", "textures", "marlin")

props.MATERIALS.update({
    "hull_white": ("#f1f2f0", 0.0, 0.12, {}),
    "hull_navy": ("#0f1b2d", 0.0, 0.2, {}),
    "hull_grey": ("#3a3f45", 0.2, 0.3, {}),
    "marlin_teak": ("#ffffff", 0.0, 0.6, {"tex": "teak.png"}),
    "teak_solid": ("#8a6440", 0.0, 0.55, {}),
    "lacquer_white": ("#ecebe6", 0.0, 0.2, {}),
    "lacquer_black": ("#121315", 0.0, 0.18, {}),
    "cushion_white": ("#efece4", 0.0, 0.85, {}),
    "cushion_navy": ("#1d2a44", 0.0, 0.85, {}),
    "cushion_sand": ("#cdbb9a", 0.0, 0.85, {}),
    "leather_cream": ("#d9cdb6", 0.0, 0.45, {}),
    "corian": ("#f3f1ec", 0.0, 0.25, {}),
    "spa_water": ("#3fc6d8", 0.0, 0.05, {"emit": "#2bb7d0", "strength": 1.5}),
    "gem_pink": ("#ff6fae", 0.0, 0.04, {"emit": "#ff3d8e", "strength": 0.8}),
    "screen_chart": ("#1d3a4a", 0.0, 0.2, {"emit": "#3f8fb0", "strength": 1.4}),
    "screen_radar": ("#12301e", 0.0, 0.2, {"emit": "#3fbf6a", "strength": 1.2}),
    "rope_navy": ("#24324f", 0.0, 0.8, {}),
    "anti_slip": ("#5d6266", 0.0, 0.9, {}),
    "van_white": ("#e6e8e9", 0.2, 0.3, {}),
    "van_green": ("#1f5a3a", 0.0, 0.45, {}),
    "crate_blue": ("#2c6e9e", 0.0, 0.5, {}),
    "crate_grey": ("#6b7176", 0.0, 0.5, {}),
    "produce_green": ("#4a7a2a", 0.0, 0.6, {}),
    "produce_red": ("#a8261c", 0.0, 0.5, {}),
    "produce_orange": ("#d97a1c", 0.0, 0.5, {}),
    "buoy_orange": ("#e8571c", 0.0, 0.5, {}),
    "window_lit": ("#ffd9a0", 0.0, 0.5, {"emit": "#ffcf8a", "strength": 2.0}),
    "lamp_led": ("#e8f0ff", 0.0, 0.3, {"emit": "#cfe0ff", "strength": 4.0}),
    "nav_red": ("#ff2a1a", 0.0, 0.4, {"emit": "#ff2010", "strength": 5.0}),
    "nav_green": ("#30ff60", 0.0, 0.4, {"emit": "#20ff50", "strength": 5.0}),
    "nav_white": ("#ffffff", 0.0, 0.4, {"emit": "#ffffff", "strength": 5.0}),
    "mattress": ("#f2f0ea", 0.0, 0.85, {}),
    "blanket_grey": ("#6c7178", 0.0, 0.9, {}),
    "bronze_sculpt": ("#6b4a2a", 1.0, 0.35, {}),
    "folder_blue": ("#1b2c55", 0.0, 0.45, {}),
    "paddle_white": ("#f4f2ec", 0.0, 0.4, {}),
    "cloth_navy": ("#1b2438", 0.0, 0.9, {}),
    "safe_grey": ("#4b5157", 0.6, 0.38, {}),
    "glass_window": ("#0c1416", 0.2, 0.05, {"alpha": 0.35}),
})


def export(p):
    props.export(p, os.path.join(OUT, p.name + ".glb"))


PROPS = {}


def prop(fn):
    PROPS[fn.__name__] = fn
    return fn


# --- Shared pieces ------------------------------------------------------------------------------

def poly_part(pts, mat, uv=None):
    """A flat polygon from points (Godot coordinates), one face."""
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]
    bm.faces.new(vs)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return props.Part(bm, mat, uv)


def strip(rows, mat, uv=None, closed=False):
    """A surface skinned between rows of points (each row a list of Godot points, same length)."""
    bm = bmesh.new()
    rings = [[bm.verts.new(p) for p in row] for row in rows]
    for a, b in zip(rings, rings[1:]):
        n = len(a)
        for i in range(n if closed else n - 1):
            j = (i + 1) % n
            try:
                bm.faces.new((a[i], a[j], b[j], b[i]))
            except ValueError:
                pass
    return props.Part(bm, mat, uv)


def cushion(lo, hi, mat):
    return box(lo, hi, mat, bevel=0.04, seg=3)


def chrome_leg(x, z, y0, y1, r=0.018):
    return cyl(r, y0, y1, "chrome", 10, m=move(x, 0, z), bevel=0.002)


def bottle(x, y, z, rng):
    mat = rng.choice(["bottle_green", "bottle_amber", "bottle_clear", "bottle_blue"])
    h = rng.uniform(0.24, 0.32)
    r = rng.uniform(0.032, 0.042)
    return [lathe([(r, y), (r, y + h * 0.62), (r * 0.4, y + h * 0.78), (r * 0.32, y + h), (0.0, y + h)], mat, 10, m=move(x, 0, z)),
            box((x - r * 0.8, y + h * 0.25, z + r - 0.004), (x + r * 0.8, y + h * 0.5, z + r + 0.002), "label_cream", 0.0)]


def stanchion_rail(x0, x1, y_top, z=0.0, every=1.0, glass=False):
    """A chrome rail along x at y_top on stanchions, with a glass panel or two wires."""
    parts = [tube([(x0, y_top, z), (x1, y_top, z)], 0.022, "chrome", 10)]
    n = max(1, round((x1 - x0) / every))
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        parts.append(cyl(0.016, 0.0, y_top, "chrome", 8, m=move(x, 0, z), bevel=0.0))
    if glass:
        parts.append(box((x0 + 0.03, 0.08, z - 0.006), (x1 - 0.03, y_top - 0.08, z + 0.006), "glass", 0.0))
    else:
        for y in (y_top * 0.36, y_top * 0.7):
            parts.append(tube([(x0, y, z), (x1, y, z)], 0.005, "steel", 4))
    return parts


# --- The hull -----------------------------------------------------------------------------------

# Stations from the transom to the stem: z, half-beam at the top, the top edge's height, how far
# down the hull is drawn (the water hides the rest).
STATIONS = [
    (-2.0, 4.55, 1.2), (-2.6, 4.68, 1.2), (-4.0, 4.78, 1.2), (-8.0, 4.8, 1.2), (-37.9, 4.8, 1.2),
    (-38.0, 4.8, 2.2), (-42.0, 4.72, 2.3), (-46.0, 4.45, 2.4), (-50.0, 3.95, 2.5), (-53.0, 3.3, 2.58),
    (-55.5, 2.55, 2.64), (-57.5, 1.8, 2.7), (-59.2, 1.0, 2.75), (-60.4, 0.35, 2.8), (-61.0, 0.05, 2.82),
]
# A section's shape: (fraction of the half-beam, height); the top point is the station's top edge.
SECTION = [(1.0, None), (1.0, 0.6), (1.0, -0.85), (0.995, -1.3), (0.98, -1.75)]


def _hull_rows(side, top_only=False):
    rows = []
    for z, b, ytop in STATIONS:
        # The stem rakes aft below the sheer: forward stations lose their lower part.
        bow = max(0.0, (-z - 50.0) / 11.0)
        row = []
        for f, y in SECTION:
            yy = ytop if y is None else y
            ff = f * (1.0 - 0.25 * bow * max(0.0, (0.6 - yy) / 2.4))
            if bow > 0 and y is not None:
                yy = max(yy, -1.75 + bow * 2.6)
                yy = min(yy, ytop - 0.05)
            row.append((side * b * ff, yy, z))
        rows.append(row)
    return rows


def _band(rows, i0, i1, side):
    out = []
    for r in rows:
        out.append([r[i0], r[i1]] if side > 0 else [r[i1], r[i0]])
    return out


@prop
def marlin_hull():
    """The Marlin's hull, 59 m from the transom (z = -2) to the stem (z = -61): white topsides up
    to the main deck (y = 1.2) along the house, bulwarks rising to 2.8 m round the foredeck, a
    navy boot stripe at the waterline (y = -1.2), a stainless rubbing strake, portholes along the
    lower deck, the teak foredeck with its winches and the transom. Drawn down to y = -1.75."""
    p = Prop("marlin_hull")
    for side in (-1, 1):
        rows = _hull_rows(side)
        # Topsides (white) above the cove line, the boot stripe under it, then the bottom.
        for i0, i1, mat in ((0, 1, "hull_white"), (1, 2, "hull_white"), (2, 3, "hull_navy"), (3, 4, "hull_navy")):
            p.add(strip(_band(rows, i0, i1, side), mat))
        # The rubbing strake along the deck edge, and a grey cove stripe.
        strake = [(side * (b + 0.03), min(ytop, 1.2) - 0.06, z) for z, b, ytop in STATIONS if z > -38.5] + \
                 [(side * (b + 0.03), 1.14, z) for z, b, ytop in STATIONS if z < -38.5]
        p.add(tube(strake, 0.04, "steel", 8))
        cove = [(side * (b + 0.004), 0.55, z) for z, b, ytop in STATIONS if b > 1.5]
        p.add(tube(cove, 0.025, "hull_grey", 6))
        # Portholes along the lower deck (crew cabins and the mess).
        for z in (-18.0, -20.6, -26.0, -28.8):
            p.add(cyl(0.17, -0.02, 0.03, "hull_grey", 16, m=move(side * 4.8, 0.05, z) @ rot_z(90 * side), bevel=0.005))
            p.add(cyl(0.13, 0.02, 0.035, "glass_dark", 16, m=move(side * 4.8, 0.05, z) @ rot_z(90 * side), bevel=0.0))
        # The bulwark's inside round the foredeck, and its cap.
        inner = []
        for z, b, ytop in STATIONS:
            if z > -37.95:
                continue
            bi = max(b - 0.14, 0.02)
            inner.append([(side * bi, 1.2, z), (side * bi, ytop - 0.04, z)] if side < 0 else [(side * bi, ytop - 0.04, z), (side * bi, 1.2, z)])
        p.add(strip(inner, "hull_white"))
        cap = []
        for z, b, ytop in STATIONS:
            if z > -37.95:
                continue
            bi = max(b - 0.16, 0.0)
            cap.append([(side * bi, ytop, z), (side * (b + 0.02), ytop, z)] if side > 0 else [(side * (b + 0.02), ytop, z), (side * bi, ytop, z)])
        p.add(strip(cap, "teak_solid"))
        # Navigation lights on the bulwark's shoulder.
        p.add(box((side * 4.7 - 0.06, 2.3, -39.0), (side * 4.7 + 0.06, 2.42, -38.7), "nav_green" if side > 0 else "nav_red", 0.005))
    # The transom: white, closed from the deck down, with a recess for the name.
    tr = [r for r in _hull_rows(1)][0]
    tl = [r for r in _hull_rows(-1)][0]
    pts = [tl[0], tr[0], tr[1], tr[2], tr[4], tl[4], tl[2], tl[1]]
    p.add(poly_part([(x, y, z + 0.001) for x, y, z in pts], "hull_white"))
    p.add(box((-4.5, -1.3, -2.02), (4.5, -0.85, -1.99), "hull_navy", 0.0))
    # A swim platform under the stern.
    p.add(box((-4.4, -0.75, -2.0), (4.4, -0.55, -0.9), "hull_white", 0.02))
    p.add(box((-4.35, -0.55, -1.98), (4.35, -0.54, -0.95), "marlin_teak", 0.0, uv=("x", "z", 0.5, 0.5, 0.0, 0.0)))
    # The foredeck: teak inside the bulwarks.
    deck = []
    for z, b, ytop in STATIONS:
        if z > -37.95:
            continue
        deck.append((max(b - 0.14, 0.0), z))
    outline = [(-b, z) for b, z in deck] + [(b, z) for b, z in reversed(deck)]
    p.add(poly_part([(x, 1.2, z) for x, z in outline], "marlin_teak", uv=("x", "z", 0.5, 0.5, 0.0, 0.0)))
    # Winches, a windlass and the anchor chain's pipes on the foredeck.
    for side in (-1, 1):
        p.add(cyl(0.22, 1.2, 1.55, "steel", 16, m=move(side * 1.4, 0, -52.5)))
        p.add(cyl(0.16, 1.55, 1.68, "chrome", 16, m=move(side * 1.4, 0, -52.5)))
        p.add(lathe([(0.12, 1.2), (0.09, 1.45), (0.16, 1.55), (0.0, 1.58)], "cast_iron", 12, m=move(side * 3.6, 0, -44.0)))
        p.add(lathe([(0.12, 1.2), (0.09, 1.45), (0.16, 1.55), (0.0, 1.58)], "cast_iron", 12, m=move(side * 3.6, 0, -40.5)))
    p.add(box((-0.5, 1.2, -50.2), (0.5, 1.6, -49.2), "steel_dark", 0.03))
    p.add(box((-0.3, 1.2, -46.0), (0.3, 1.32, -45.2), "lacquer_white", 0.02))
    # The anchor, stowed in the bow.
    for side in (-1, 1):
        p.add(box((side * 2.05 - 0.04, 1.4, -57.2), (side * 2.05 + 0.04, 2.2, -56.8), "steel", 0.01))
    # A forward mast light on a short pole.
    p.add(cyl(0.04, 2.6, 3.6, "chrome", 8, m=move(0, 0, -58.5)))
    p.add(sphere(0.07, "nav_white", 8, 5, m=move(0, 3.66, -58.5)))
    return p


@prop
def marlin_gangway():
    """The passerelle: 1.0 m wide, from its foot on the quay (the origin) up to the aft deck at
    (0, 1.2, -3.8). Anti-slip treads on stainless stringers, stanchions with a navy rope rail
    at 0.9 m, and a hinged top plate."""
    p = Prop("marlin_gangway")
    run, rise = 3.8, 1.2
    ang = math.degrees(math.atan2(rise, run))
    length = math.hypot(run, rise)
    tilt = move(0, 0, 0) @ rot_x(ang)
    # The deck of it, tilted up toward -z.
    p.add(box((-0.5, -0.06, -length), (0.5, 0.0, 0.0), "steel", 0.006, m=tilt))
    p.add(box((-0.46, 0.0, -length + 0.05), (0.46, 0.012, -0.05), "anti_slip", 0.0, m=tilt))
    for i in range(12):
        z = -0.2 - i * (length - 0.4) / 11
        p.add(box((-0.46, 0.012, z - 0.015), (0.46, 0.03, z + 0.015), "steel", 0.003, m=tilt))
    for side in (-1, 1):
        p.add(box((side * 0.5 - 0.02, -0.14, -length), (side * 0.5 + 0.02, 0.06, 0.0), "chrome", 0.004, m=tilt))
        posts = 5
        tops = []
        for i in range(posts):
            z = -0.12 - i * (length - 0.24) / (posts - 1)
            p.add(cyl(0.016, 0.0, 0.92, "chrome", 8, m=tilt @ move(side * 0.5, 0, z) @ rot_x(-ang), bevel=0.0))
            q = tilt @ Vector((side * 0.5, 0.0, z))
            tops.append((q.x, q.y + 0.92, q.z))
        p.add(tube(tops, 0.02, "rope_navy", 8))
        for t in tops:
            p.add(sphere(0.022, "chrome", 8, 5, m=move(*t)))
    # The top plate, resting on the deck.
    p.add(box((-0.5, rise - 0.03, -run - 0.35), (0.5, rise + 0.005, -run + 0.05), "steel", 0.006))
    # Little wheels at the foot.
    for side in (-1, 1):
        p.add(cyl(0.05, -0.03, 0.03, "rubber", 10, m=move(side * 0.42, 0.05, -0.08) @ rot_z(90), bevel=0.0))
    return p


@prop
def marlin_gate():
    """The gangway's boarding gate: a 1.0 x 2.0 m leaf of glass in a polished stainless frame
    with a push bar. Hinged at the origin, spanning x -1.0..0."""
    p = Prop("marlin_gate")
    w, h = 1.0, 2.0
    for x0, x1 in ((-w, -w + 0.05), (-0.05, 0.0)):
        p.add(box((x0, 0.0, -0.025), (x1, h, 0.025), "chrome", 0.006))
    for y0, y1 in ((0.0, 0.1), (h - 0.06, h), (1.0, 1.05)):
        p.add(box((-w + 0.05, y0, -0.025), (-0.05, y1, 0.025), "chrome", 0.006))
    p.add(box((-w + 0.05, 0.1, -0.008), (-0.05, h - 0.06, 0.008), "glass", 0.0))
    for z in (-0.06, 0.06):
        p.add(tube([(-w + 0.12, 1.05, z), (-0.12, 1.05, z)], 0.016, "steel", 8))
    return p


@prop
def marlin_gate_frame():
    """The gangway gate's frame on the quay: two posts 2.3 m tall, a lintel with a navy sign
    board (the name goes on in the game), and glass screens 1.1 m wide either side. The opening
    is 1.0 m wide, centred on x; back on z = 0."""
    p = Prop("marlin_gate_frame")
    for side in (-1, 1):
        for x in (side * 0.53, side * 1.66):
            p.add(box((x - 0.04, 0.0, -0.04), (x + 0.04, 2.3, 0.04), "chrome", 0.006))
        p.add(box((side * 0.57, 0.08, -0.008), (side * 1.62, 1.9, 0.008), "glass", 0.0))
        p.add(box((min(side * 0.57, side * 1.62), 1.9, -0.025), (max(side * 0.57, side * 1.62), 1.94, 0.025), "chrome", 0.004))
        p.add(box((side * 1.66 - 0.18, 0.0, -0.18), (side * 1.66 + 0.18, 0.06, 0.18), "steel_dark", 0.01))
    p.add(box((-1.7, 2.3, -0.05), (1.7, 2.62, 0.05), "chrome", 0.008))
    p.add(box((-1.6, 2.33, 0.05), (1.6, 2.59, 0.06), "hull_navy", 0.0))
    return p


@prop
def marlin_door():
    """A guest door: a 0.9 x 2.1 m leaf of white lacquer with a walnut panel and a chrome lever.
    Hinged at the origin, spanning x -0.9..0."""
    p = Prop("marlin_door")
    w, h = 0.9, 2.1
    p.add(box((-w + 0.003, 0.0, -0.022), (-0.003, h, 0.022), "lacquer_white", 0.004))
    for zs in (-1, 1):
        p.add(box((-w + 0.14, 0.25, zs * 0.022 - 0.002), (-0.14, h - 0.25, zs * 0.022 + 0.002), "walnut", 0.002))
        p.add(box((-w + 0.13, 0.24, zs * 0.023 - 0.002), (-0.13, 0.25, zs * 0.023 + 0.002), "chrome", 0.0))
        p.add(box((-w + 0.13, h - 0.25, zs * 0.023 - 0.002), (-0.13, h - 0.24, zs * 0.023 + 0.002), "chrome", 0.0))
        p.add(tube([(-w + 0.07, 1.02, zs * 0.06), (-w + 0.07, 1.02, zs * 0.03), (-w + 0.2, 1.02, zs * 0.06)], 0.01, "chrome", 6))
    return p


@prop
def marlin_door_glass():
    """A saloon door leaf: 1.0 x 2.2 m of glass with polished stainless rails top and bottom
    and a long pull. Hinged at the origin, spanning x -1.0..0."""
    p = Prop("marlin_door_glass")
    w, h = 1.0, 2.2
    p.add(box((-w + 0.005, 0.1, -0.008), (-0.005, h - 0.05, 0.008), "glass", 0.0))
    p.add(box((-w, 0.0, -0.022), (0.0, 0.1, 0.022), "chrome", 0.004))
    p.add(box((-w, h - 0.05, -0.022), (0.0, h, 0.022), "chrome", 0.004))
    for zs in (-1, 1):
        p.add(cyl(0.014, 0.75, 1.45, "chrome", 8, m=move(-w + 0.1, 0, zs * 0.06), bevel=0.0))
        for y in (0.8, 1.4):
            p.add(tube([(-w + 0.1, y, zs * 0.06), (-w + 0.1, y, zs * 0.008)], 0.008, "chrome", 6))
    return p


@prop
def marlin_door_crew():
    """A crew door: a 0.9 x 2.0 m leaf of white laminate with a round porthole, a stainless kick
    plate and a lever. Hinged at the origin, spanning x -0.9..0."""
    p = Prop("marlin_door_crew")
    w, h = 0.9, 2.0
    p.add(box((-w + 0.003, 0.0, -0.025), (-0.003, h, 0.025), "paint_white", 0.004))
    for zs in (-1, 1):
        p.add(box((-w + 0.03, 0.02, zs * 0.025 - 0.002), (-0.03, 0.26, zs * 0.025 + 0.002), "steel", 0.0))
        p.add(cyl(0.15, -0.01, 0.01, "chrome", 20, m=move(-w * 0.5, 1.5, zs * 0.025) @ rot_x(90), bevel=0.0))
        p.add(tube([(-w + 0.07, 1.0, zs * 0.06), (-w + 0.07, 1.0, zs * 0.03), (-w + 0.2, 1.0, zs * 0.06)], 0.01, "chrome", 6))
    p.add(cyl(0.13, -0.03, 0.03, "glass", 20, m=move(-w * 0.5, 1.5, 0.0) @ rot_x(90), bevel=0.0))
    return p


@prop
def marlin_door_safe():
    """The captain's strongroom door: a 0.9 x 2.0 m leaf of brushed steel 8 cm thick, with a
    locking wheel and bolt heads on the outside (+Z). Hinged at the origin, spanning x -0.9..0."""
    p = Prop("marlin_door_safe")
    w, h = 0.9, 2.0
    p.add(box((-w + 0.004, 0.0, -0.04), (-0.004, h, 0.04), "safe_grey", 0.01))
    p.add(box((-w + 0.06, 0.06, 0.04), (-0.06, h - 0.06, 0.05), "steel", 0.006))
    c = (-w * 0.5, 1.15, 0.05)
    p.add(cyl(0.07, 0.0, 0.06, "chrome", 16, m=move(*c) @ rot_x(90), bevel=0.004))
    ring = [(c[0] + 0.2 * math.cos(a), c[1] + 0.2 * math.sin(a), 0.12) for a in [i * math.pi / 8 for i in range(17)]]
    p.add(tube(ring, 0.014, "chrome", 6))
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        p.add(tube([(c[0], c[1], 0.11), (c[0] + 0.2 * math.cos(a), c[1] + 0.2 * math.sin(a), 0.12)], 0.01, "chrome", 6))
    for y in (0.2, 0.7, 1.3, 1.8):
        for x in (-w + 0.1, -0.1):
            p.add(cyl(0.018, 0.0, 0.02, "chrome", 8, m=move(x, y, 0.05) @ rot_x(90), bevel=0.0))
    p.add(box((-0.12, 1.55, 0.05), (-0.04, 1.75, 0.07), "steel_dark", 0.004))
    return p


# --- The aft deck, the saloon, the dining room, the lobby -----------------------------------------

@prop
def marlin_bar():
    """The aft deck's bar: 2.6 m of teak front under a white top, a stainless foot rail, the
    bartender's well behind (-Z). Front faces +Z."""
    p = Prop("marlin_bar")
    w, d = 2.6, 0.7
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.08, d / 2 - 0.05), "lacquer_black", 0.004))
    for i in range(26):
        x = -w / 2 + 0.05 + i * (w - 0.1) / 25
        p.add(box((x - 0.045, 0.08, d / 2 - 0.08), (x + 0.045, 1.0, d / 2 - 0.05), "teak_solid", 0.004))
    for x in (-w / 2, w / 2 - 0.05):
        p.add(box((x, 0.08, -d / 2), (x + 0.05, 1.0, d / 2 - 0.05), "teak_solid", 0.004))
    p.add(box((-w / 2 - 0.04, 1.0, -d / 2 - 0.02), (w / 2 + 0.04, 1.06, d / 2 + 0.05), "corian", 0.012, 3))
    p.add(tube([(-w / 2 + 0.1, 0.22, d / 2 + 0.12), (w / 2 - 0.1, 0.22, d / 2 + 0.12)], 0.022, "chrome", 10))
    for x in (-w / 2 + 0.3, 0.0, w / 2 - 0.3):
        p.add(tube([(x, 0.22, d / 2 + 0.12), (x, 0.22, d / 2 - 0.06)], 0.01, "chrome", 6))
    p.add(box((-w / 2 + 0.06, 0.78, -d / 2), (w / 2 - 0.06, 0.82, d / 2 - 0.1), "steel", 0.004))
    rng = random.Random(5)
    for i in range(8):
        p.add(bottle(-w / 2 + 0.3 + i * 0.3, 0.82, -0.12, rng))
    # Glasses and a champagne bucket on top.
    for i in range(5):
        x = -0.9 + i * 0.18
        p.add(lathe([(0.03, 1.06), (0.03, 1.07), (0.004, 1.08), (0.004, 1.17), (0.035, 1.19), (0.04, 1.27)], "glass", 10, cap=(True, False), m=move(x, 0, 0.12)))
    p.add(lathe([(0.09, 1.06), (0.11, 1.28), (0.12, 1.29)], "chrome", 16, cap=(True, False), m=move(0.8, 0, 0.0)))
    p.add(bottle(0.82, 1.1, 0.0, rng))
    return p


@prop
def marlin_sofa():
    """A deep sofa, 2.4 m: a white lacquer base, sand cushions and navy scatter cushions; for the
    saloon and the aft deck. Front faces +Z."""
    p = Prop("marlin_sofa")
    w, d = 2.4, 0.95
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.3, d / 2), "lacquer_white", 0.02))
    p.add(box((-w / 2, 0.3, -d / 2), (w / 2, 0.78, -d / 2 + 0.18), "lacquer_white", 0.03))
    for side in (-1, 1):
        p.add(box((side * w / 2 - (0.16 if side > 0 else 0.0), 0.3, -d / 2), (side * w / 2 + (0.0 if side > 0 else 0.16), 0.62, d / 2), "lacquer_white", 0.03))
    for i in range(3):
        x0 = -w / 2 + 0.16 + i * (w - 0.32) / 3
        x1 = x0 + (w - 0.32) / 3
        p.add(cushion((x0 + 0.01, 0.3, -d / 2 + 0.18), (x1 - 0.01, 0.46, d / 2 - 0.02), "cushion_sand"))
        p.add(cushion((x0 + 0.01, 0.46, -d / 2 + 0.17), (x1 - 0.01, 0.82, -d / 2 + 0.36), "cushion_sand").xf(move(0, 0, 0)))
    for x, mat in ((-0.85, "cushion_navy"), (0.85, "cushion_navy"), (-0.55, "cushion_white")):
        p.add(cushion((x - 0.2, 0.46, -0.24), (x + 0.2, 0.86, -0.1), mat).xf(move(0, 0, 0)))
    return p


@prop
def marlin_armchair():
    """A low armchair to match the sofa, 0.9 x 0.85; front faces +Z."""
    p = Prop("marlin_armchair")
    w, d = 0.9, 0.85
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.3, d / 2), "lacquer_white", 0.02))
    p.add(box((-w / 2, 0.3, -d / 2), (w / 2, 0.75, -d / 2 + 0.16), "lacquer_white", 0.03))
    for side in (-1, 1):
        x0 = side * w / 2
        p.add(box((min(x0, x0 - side * 0.14), 0.3, -d / 2), (max(x0, x0 - side * 0.14), 0.6, d / 2), "lacquer_white", 0.03))
    p.add(cushion((-w / 2 + 0.15, 0.3, -d / 2 + 0.16), (w / 2 - 0.15, 0.46, d / 2 - 0.02), "cushion_sand"))
    p.add(cushion((-w / 2 + 0.15, 0.46, -d / 2 + 0.15), (w / 2 - 0.15, 0.8, -d / 2 + 0.33), "cushion_sand"))
    return p


@prop
def marlin_table():
    """A low table, 1.4 x 0.8 x 0.4: a teak top on polished stainless legs, with a tray of
    glasses and a bowl of limes."""
    p = Prop("marlin_table")
    w, d = 1.4, 0.8
    p.add(box((-w / 2, 0.36, -d / 2), (w / 2, 0.4, d / 2), "teak_solid", 0.008))
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        for z in (-d / 2 + 0.08, d / 2 - 0.08):
            p.add(chrome_leg(x, z, 0.0, 0.36))
    p.add(box((-0.25, 0.4, -0.15), (0.15, 0.42, 0.12), "lacquer_black", 0.005))
    for i in range(3):
        p.add(lathe([(0.03, 0.42), (0.035, 0.52)], "glass", 10, cap=(True, False), m=move(-0.18 + i * 0.1, 0, -0.04)))
    p.add(lathe([(0.05, 0.4), (0.12, 0.45), (0.13, 0.47)], "porcelain", 16, cap=(True, False), m=move(0.42, 0, 0.1)))
    for k in range(5):
        p.add(sphere(0.03, "produce_green", 8, 5, m=move(0.42 + 0.05 * math.cos(k * 1.3), 0.47, 0.1 + 0.05 * math.sin(k * 1.3))))
    return p


@prop
def marlin_dining_table():
    """The dining table, 4.2 x 1.2 m of walnut on two pedestals, laid for ten with white plates,
    glasses and silver, two candelabra and a low arrangement of white roses."""
    p = Prop("marlin_dining_table")
    w, d = 4.2, 1.2
    p.add(box((-w / 2, 0.72, -d / 2), (w / 2, 0.76, d / 2), "walnut", 0.01, 3))
    for x in (-1.3, 1.3):
        p.add(box((x - 0.12, 0.0, -0.3), (x + 0.12, 0.72, 0.3), "walnut_dark", 0.01))
        p.add(box((x - 0.3, 0.0, -0.45), (x + 0.3, 0.04, 0.45), "chrome", 0.005))
    places = [(x, z) for x in (-1.6, -0.8, 0.0, 0.8, 1.6) for z in (-0.42, 0.42)]
    for x, z in places:
        p.add(cyl(0.13, 0.76, 0.775, "porcelain", 20, m=move(x, 0, z), bevel=0.003))
        p.add(cyl(0.09, 0.775, 0.785, "porcelain", 16, m=move(x, 0, z), bevel=0.0))
        s = 1 if z > 0 else -1
        p.add(box((x + 0.17, 0.762, z - 0.08), (x + 0.19, 0.766, z + 0.08), "chrome", 0.0))
        p.add(box((x - 0.19, 0.762, z - 0.08), (x - 0.17, 0.766, z + 0.08), "chrome", 0.0))
        p.add(lathe([(0.03, 0.76), (0.03, 0.765), (0.004, 0.775), (0.004, 0.86), (0.035, 0.88), (0.04, 0.95)], "glass", 10, cap=(True, False), m=move(x + 0.14, 0, z - s * 0.16)))
    rng = random.Random(3)
    for x in (-0.95, 0.95):
        p.add(cyl(0.05, 0.76, 0.78, "chrome", 12, m=move(x, 0, 0), bevel=0.0))
        p.add(cyl(0.012, 0.78, 1.05, "chrome", 8, m=move(x, 0, 0), bevel=0.0))
        for dx in (-0.12, 0.0, 0.12):
            p.add(tube([(x, 1.0, 0), (x + dx, 1.02, 0)], 0.006, "chrome", 4))
            p.add(props.candle(x + dx, 1.02, 0.0))
    p.add(props.flowers(0.0, 0.76, 0.0, 0.3, 0.14, rng, count=16, leaves=10))
    return p


@prop
def marlin_chair():
    """A dining chair of walnut and cream leather; the seat is at 0.47 m and its front faces +Z.
    The auction's rows are the same chairs."""
    p = Prop("marlin_chair")
    w, d = 0.5, 0.52
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (-d / 2 + 0.04, d / 2 - 0.04):
            p.add(box((x - 0.022, 0.0, z - 0.022), (x + 0.022, 0.44, z + 0.022), "walnut", 0.006))
    p.add(cushion((-w / 2, 0.42, -d / 2), (w / 2, 0.5, d / 2), "leather_cream"))
    back = cushion((-w / 2 + 0.02, 0.5, -d / 2), (w / 2 - 0.02, 1.0, -d / 2 + 0.06), "leather_cream")
    p.add(back.xf(move(0, 0.5, -d / 2) @ rot_x(-8) @ move(0, -0.5, d / 2)))
    return p


@prop
def marlin_sideboard():
    """A low walnut sideboard, 2.0 x 0.8 x 0.45, with a lamp and a bowl; back on z = -0.225
    (stands against a wall); front faces +Z."""
    p = Prop("marlin_sideboard")
    w, h, d = 2.0, 0.8, 0.45
    p.add(box((-w / 2, 0.08, -d / 2), (w / 2, h, d / 2), "walnut", 0.008))
    p.add(box((-w / 2 + 0.05, 0.0, -d / 2 + 0.05), (w / 2 - 0.05, 0.08, d / 2 - 0.05), "lacquer_black", 0.004))
    for i in range(4):
        x = -w / 2 + (i + 0.5) * w / 4
        p.add(box((x - w / 8 + 0.01, 0.12, d / 2), (x + w / 8 - 0.01, h - 0.04, d / 2 + 0.005), "walnut_dark", 0.002))
        p.add(box((x - 0.06, h - 0.12, d / 2 + 0.005), (x + 0.06, h - 0.1, d / 2 + 0.015), "chrome", 0.002))
    p.add(lathe([(0.07, h), (0.1, h + 0.1), (0.05, h + 0.3), (0.03, h + 0.35)], "porcelain", 14, m=move(-0.6, 0, 0)))
    p.add(lathe([(0.0, h + 0.33), (0.18, h + 0.36), (0.12, h + 0.58), (0.0, h + 0.6)], "lampshade", 16, m=move(-0.6, 0, 0)))
    p.add(lathe([(0.06, h), (0.2, h + 0.08), (0.22, h + 0.1)], "bronze_sculpt", 16, cap=(True, False), m=move(0.5, 0, 0)))
    return p


@prop
def marlin_rostrum():
    """The auctioneer's rostrum from Ashcombe & Vale: a walnut lectern 0.9 m wide and 1.15 m
    tall with a brass rail, a gavel and its block, a reading lamp and a microphone. Front (the
    room's side) faces +Z; the auctioneer stands behind it at -Z."""
    p = Prop("marlin_rostrum")
    w, d = 0.9, 0.6
    p.add(box((-w / 2, 0.0, -d / 2 + 0.05), (w / 2, 1.05, d / 2), "walnut", 0.01))
    p.add(box((-w / 2 + 0.06, 0.12, d / 2), (w / 2 - 0.06, 0.95, d / 2 + 0.01), "walnut_dark", 0.004))
    p.add(box((-0.25, 0.55, d / 2 + 0.01), (0.25, 0.75, d / 2 + 0.02), "hull_navy", 0.002))
    p.add(box((-w / 2 - 0.03, 1.05, -d / 2), (w / 2 + 0.03, 1.1, d / 2 + 0.05), "walnut", 0.01))
    p.add(tube([(-w / 2, 1.13, d / 2 + 0.03), (w / 2, 1.13, d / 2 + 0.03)], 0.012, "brass", 8))
    # The sloped reading top, a catalogue, the gavel.
    p.add(box((-0.3, 1.1, -0.2), (0.3, 1.13, 0.15), "walnut_dark", 0.004).xf(move(0, 1.1, 0) @ rot_x(10) @ move(0, -1.1, 0)))
    p.add(box((-0.15, 1.13, -0.12), (0.15, 1.145, 0.1), "paper", 0.002).xf(move(0, 1.1, 0) @ rot_x(10) @ move(0, -1.1, 0)))
    p.add(cyl(0.05, 1.1, 1.13, "walnut_dark", 14, m=move(0.34, 0, 0.0)))
    p.add(cyl(0.018, -0.07, 0.07, "walnut_dark", 10, m=move(0.34, 1.16, 0.0) @ rot_z(90)))
    p.add(cyl(0.035, -0.04, 0.04, "walnut_dark", 12, m=move(0.42, 1.16, 0.0) @ rot_x(90) @ rot_z(90)))
    p.add(tube([(-0.32, 1.1, -0.1), (-0.32, 1.32, -0.02), (-0.24, 1.36, 0.05)], 0.008, "brass", 6))
    p.add(lathe([(0.0, 1.3), (0.06, 1.33), (0.07, 1.36)], "brass", 12, cap=(False, False), m=move(-0.22, 0, 0.06)))
    p.add(tube([(0.25, 1.1, -0.15), (0.2, 1.35, 0.0)], 0.006, "plastic_black", 6))
    p.add(sphere(0.022, "plastic_black", 8, 5, m=move(0.2, 1.37, 0.0)))
    return p


@prop
def marlin_case():
    """The Rose's case: a black lacquer plinth 0.6 m square and 1.0 m tall, a glass vitrine on
    it, and inside, on a navy velvet cushion, the Rose: a pink diamond the size of a walnut
    (node Rose, so the game can show or hide it)."""
    p = Prop("marlin_case")
    s = 0.3
    p.add(box((-s, 0.0, -s), (s, 0.08, s), "chrome", 0.006))
    p.add(box((-s + 0.02, 0.08, -s + 0.02), (s - 0.02, 0.98, s - 0.02), "lacquer_black", 0.008))
    p.add(box((-s, 0.98, -s), (s, 1.0, s), "chrome", 0.004))
    p.add(box((-s + 0.01, 1.0, -s + 0.01), (s - 0.01, 1.5, s - 0.01), "glass", 0.0))
    p.add(box((-s, 1.5, -s), (s, 1.52, s), "chrome", 0.004))
    p.add(box((-0.1, 1.0, -0.1), (0.1, 1.06, 0.1), "velvet_navy", 0.02))
    # A small brass plate.
    p.add(box((-0.12, 0.82, s - 0.02), (0.12, 0.88, s - 0.015), "brass", 0.0))
    stone = props.octa(0.035, 0.07, "gem_pink")
    stone.xf(move(0, 1.105, 0) @ rot_x(180) @ rot_y(20))
    p.add(stone, node="Rose")
    p.add(lathe([(0.0, 1.06), (0.045, 1.066), (0.04, 1.07), (0.0, 1.072)], "gem_pink", 8), node="Rose")
    return p


@prop
def marlin_sculpture():
    """The lobby's bronze: a tall twisting form, like a fish leaping, on a white plinth; 0.5 m
    square, 2.0 m tall."""
    p = Prop("marlin_sculpture")
    p.add(box((-0.25, 0.0, -0.25), (0.25, 1.0, 0.25), "lacquer_white", 0.01))
    pts = []
    rad = []
    for i in range(14):
        t = i / 13
        pts.append((0.12 * math.sin(t * 5.0), 1.0 + t * 1.0, 0.1 * math.cos(t * 4.0)))
        rad.append(0.09 * math.sin(math.pi * min(1.0, t * 1.1 + 0.05)) + 0.01)
    p.add(tube(pts, 0.05, "bronze_sculpt", 10, radii=rad))
    p.add(prism([(-0.02, 0.0), (0.2, 0.08), (0.02, 0.16)], 0.03, "bronze_sculpt", m=move(pts[-1][0] - 0.02, pts[-1][1] - 0.08, pts[-1][2])))
    return p


@prop
def marlin_reg_desk():
    """The auction's registration desk: a table 1.6 x 0.7 under a navy cloth to the floor, with
    a laptop, a fan of white bidding paddles, a card stand and a pen pot. Front faces +Z."""
    p = Prop("marlin_reg_desk")
    w, d = 1.6, 0.7
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.76, d / 2), "cloth_navy", 0.01))
    p.add(box((-w / 2 - 0.01, 0.74, -d / 2 - 0.01), (w / 2 + 0.01, 0.765, d / 2 + 0.01), "cloth_navy", 0.01))
    # Laptop, open toward -Z (the registrar).
    p.add(box((-0.2, 0.765, -0.15), (0.15, 0.78, 0.08), "steel_dark", 0.004))
    p.add(box((-0.2, 0.78, 0.07), (0.15, 1.0, 0.085), "steel_dark", 0.004).xf(move(0, 0.78, 0.075) @ rot_x(-12) @ move(0, -0.78, -0.075)))
    p.add(box((-0.19, 0.79, 0.068), (0.14, 0.99, 0.07), "screen", 0.0).xf(move(0, 0.78, 0.075) @ rot_x(-12) @ move(0, -0.78, -0.075)))
    for i in range(6):
        a = -25 + i * 10
        paddle = [cyl(0.1, -0.003, 0.003, "paddle_white", 16, m=move(0, 0.25, 0) @ rot_x(90), bevel=0.0),
                  box((-0.015, 0.0, -0.006), (0.015, 0.16, 0.006), "walnut", 0.002)]
        for part in paddle:
            p.add(part.xf(move(0.5, 0.766, 0.05) @ rot_x(-90) @ rot_z(a)))
    p.add(prism([(-0.12, 0.0), (0.12, 0.0), (0.0, 0.18)], 0.004, "paper", m=move(-0.55, 0.765, 0.15) @ rot_y(0)))
    p.add(cyl(0.035, 0.765, 0.86, "chrome", 10, m=move(-0.6, 0, -0.15), bevel=0.0))
    return p


# --- The upper deck -------------------------------------------------------------------------------

@prop
def marlin_lounger():
    """A sun lounger: 2.0 x 0.75, teak frame, a white cushion with the back raised; front (the
    foot) faces +Z."""
    p = Prop("marlin_lounger")
    w, l = 0.75, 2.0
    p.add(box((-w / 2, 0.1, -l / 2), (w / 2, 0.3, l / 2), "teak_solid", 0.01))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        for z in (-l / 2 + 0.08, l / 2 - 0.08):
            p.add(box((x - 0.03, 0.0, z - 0.03), (x + 0.03, 0.1, z + 0.03), "teak_solid", 0.004))
    p.add(cushion((-w / 2 + 0.03, 0.3, -l / 2 + 0.62), (w / 2 - 0.03, 0.4, l / 2 - 0.03), "cushion_white"))
    back = cushion((-w / 2 + 0.03, 0.0, 0.0), (w / 2 - 0.03, 0.1, 0.62), "cushion_white")
    p.add(back.xf(move(0, 0.3, -l / 2 + 0.62) @ rot_x(40) @ move(0, 0, -0.62)))
    p.add(box((-0.2, 0.42, -0.6), (0.2, 0.44, -0.3), "cushion_navy", 0.01).xf(move(0, 0.0, 0.0)))
    return p


@prop
def marlin_spa():
    """The sun deck's spa pool: 3.0 x 2.2 m and 0.75 m tall, white sides, a teak surround and
    lit turquoise water."""
    p = Prop("marlin_spa")
    w, d, h = 3.0, 2.2, 0.75
    t = 0.18
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h - 0.05, -d / 2 + t), "hull_white", 0.02))
    p.add(box((-w / 2, 0.0, d / 2 - t), (w / 2, h - 0.05, d / 2), "hull_white", 0.02))
    p.add(box((-w / 2, 0.0, -d / 2 + t), (-w / 2 + t, h - 0.05, d / 2 - t), "hull_white", 0.02))
    p.add(box((w / 2 - t, 0.0, -d / 2 + t), (w / 2, h - 0.05, d / 2 - t), "hull_white", 0.02))
    for lo, hi in (((-w / 2 - 0.03, h - 0.05, -d / 2 - 0.03), (w / 2 + 0.03, h, -d / 2 + t + 0.02)),
                   ((-w / 2 - 0.03, h - 0.05, d / 2 - t - 0.02), (w / 2 + 0.03, h, d / 2 + 0.03)),
                   ((-w / 2 - 0.03, h - 0.05, -d / 2 + t), (-w / 2 + t + 0.02, h, d / 2 - t)),
                   ((w / 2 - t - 0.02, h - 0.05, -d / 2 + t), (w / 2 + 0.03, h, d / 2 - t))):
        p.add(box(lo, hi, "teak_solid", 0.008))
    p.add(box((-w / 2 + t, 0.0, -d / 2 + t), (w / 2 - t, h - 0.15, d / 2 - t), "spa_water", 0.0))
    p.add(box((-w / 2 + t, 0.0, -d / 2 + t), (w / 2 - t, h - 0.16, d / 2 - t), "lacquer_white", 0.0))
    return p


@prop
def marlin_helm():
    """The bridge's helm console: 4.4 m wide and 1.05 m tall, dark grey, with six chart and
    radar screens on a sloped face, a small wheel and the throttles in the middle. The
    officer's side faces +Z; the windscreen is beyond it at -Z."""
    p = Prop("marlin_helm")
    w, d = 4.4, 0.8
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.8, d / 2), "lacquer_black", 0.01))
    slope = move(0, 0.8, d / 2) @ rot_x(-28)
    p.add(box((-w / 2, 0.0, -0.5), (w / 2, 0.06, 0.0), "steel_dark", 0.01, m=slope))
    for i, x in enumerate((-1.75, -1.15, -0.55, 0.55, 1.15, 1.75)):
        mat = "screen_radar" if i in (1, 4) else "screen_chart"
        p.add(box((x - 0.27, 0.06, -0.45), (x + 0.27, 0.07, -0.12), mat, 0.0, m=slope))
    p.add(box((-w / 2, 0.8, -d / 2), (w / 2, 1.05, -d / 2 + 0.25), "lacquer_black", 0.01))
    # The wheel and the throttles.
    wheel = move(0.0, 0.95, 0.12) @ rot_x(-60)
    ring = [(0.2 * math.cos(a), 0.0, 0.2 * math.sin(a)) for a in [i * math.pi / 10 for i in range(21)]]
    p.add(tube(ring, 0.015, "steel", 8, m=wheel))
    for k in range(3):
        a = k * 2 * math.pi / 3
        p.add(tube([(0, 0, 0), (0.19 * math.cos(a), 0, 0.19 * math.sin(a))], 0.01, "steel", 6, m=wheel))
    p.add(cyl(0.03, -0.05, 0.05, "steel_dark", 10, m=wheel))
    for x in (0.38, 0.48):
        p.add(tube([(x, 0.82, 0.25), (x, 0.95, 0.22)], 0.012, "chrome", 6))
        p.add(sphere(0.03, "plastic_black", 8, 5, m=move(x, 0.96, 0.22)))
    return p


@prop
def marlin_helm_chair():
    """A helm chair: black leather on a stainless pedestal, 0.65 x 1.3; front faces +Z."""
    p = Prop("marlin_helm_chair")
    p.add(cyl(0.28, 0.0, 0.03, "chrome", 20))
    p.add(cyl(0.05, 0.03, 0.6, "chrome", 12))
    p.add(cushion((-0.3, 0.6, -0.28), (0.3, 0.72, 0.28), "leather_black"))
    p.add(cushion((-0.29, 0.72, -0.3), (0.29, 1.3, -0.18), "leather_black").xf(move(0, 0.72, -0.24) @ rot_x(-10) @ move(0, -0.72, 0.24)))
    for side in (-1, 1):
        p.add(cushion((side * 0.3 - 0.04, 0.82, -0.22), (side * 0.3 + 0.04, 0.88, 0.2), "leather_black"))
    p.add(tube([(-0.2, 0.3, 0.2), (0.2, 0.3, 0.2)], 0.012, "chrome", 6))
    return p


@prop
def marlin_chart_table():
    """A chart table, 1.2 x 0.8 x 0.95, walnut with a chart, dividers and a lamp."""
    p = Prop("marlin_chart_table")
    w, d = 1.2, 0.8
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.9, d / 2), "walnut", 0.01))
    p.add(box((-w / 2 - 0.02, 0.9, -d / 2 - 0.02), (w / 2 + 0.02, 0.94, d / 2 + 0.02), "walnut_dark", 0.008))
    p.add(box((-0.5, 0.94, -0.33), (0.45, 0.942, 0.3), "paper", 0.0))
    p.add(box((-0.3, 0.942, -0.1), (0.1, 0.943, 0.05), "rope_navy", 0.0))
    p.add(tube([(0.0, 0.95, 0.0), (0.12, 0.96, 0.1)], 0.004, "brass", 4))
    p.add(tube([(0.0, 0.95, 0.0), (0.16, 0.96, -0.02)], 0.004, "brass", 4))
    p.add(tube([(-0.55, 0.94, -0.35), (-0.55, 1.25, -0.3), (-0.42, 1.3, -0.2)], 0.008, "brass", 6))
    p.add(lathe([(0.0, 1.24), (0.06, 1.27), (0.07, 1.3)], "brass", 12, cap=(False, False), m=move(-0.4, 0, -0.18)))
    return p


@prop
def marlin_bed():
    """The captain's bed: 1.8 x 2.1 m, a navy padded headboard 1.2 m tall at -Z, white linen, a
    grey throw and four pillows; the foot faces +Z."""
    p = Prop("marlin_bed")
    w, l = 1.8, 2.1
    p.add(box((-w / 2, 0.0, -l / 2), (w / 2, 0.32, l / 2), "walnut", 0.01))
    p.add(cushion((-w / 2 + 0.02, 0.32, -l / 2 + 0.08), (w / 2 - 0.02, 0.56, l / 2 - 0.02), "mattress"))
    p.add(cushion((-w / 2 - 0.1, 0.0, -l / 2 - 0.08), (w / 2 + 0.1, 1.2, -l / 2 + 0.06), "cushion_navy"))
    p.add(box((-w / 2 + 0.01, 0.5, 0.25), (w / 2 - 0.01, 0.6, 0.85), "blanket_grey", 0.03))
    for x in (-0.55, -0.2, 0.2, 0.55):
        p.add(cushion((x - 0.2, 0.56, -l / 2 + 0.12), (x + 0.2, 0.74, -l / 2 + 0.4), "linen" if abs(x) > 0.3 else "cushion_white").xf(move(0, 0.0, 0.0)))
    return p


@prop
def marlin_safe_cabinet():
    """The strongroom's safe: a steel cabinet 0.8 x 1.4 x 0.55 with its door standing open and
    shelves of document boxes; front faces +Z."""
    p = Prop("marlin_safe_cabinet")
    w, h, d = 0.8, 1.4, 0.55
    t = 0.05
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, -d / 2 + t), "safe_grey", 0.006))
    for side in (-1, 1):
        x0 = side * w / 2
        p.add(box((min(x0, x0 - side * t), 0.0, -d / 2), (max(x0, x0 - side * t), h, d / 2), "safe_grey", 0.006))
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, t, d / 2), "safe_grey", 0.006))
    p.add(box((-w / 2, h - t, -d / 2), (w / 2, h, d / 2), "safe_grey", 0.006))
    for y in (0.45, 0.9):
        p.add(box((-w / 2 + t, y, -d / 2 + t), (w / 2 - t, y + 0.02, d / 2 - 0.03), "steel", 0.002))
    rng = random.Random(8)
    for i in range(5):
        x = -0.3 + i * 0.12
        p.add(box((x - 0.045, t, -0.18), (x + 0.045, t + 0.32 + rng.random() * 0.04, 0.14), "cardboard" if i % 2 else "folder_blue", 0.004))
    # The door, open toward +X.
    door = box((0.0, 0.0, -0.04), (w - 0.02, h - 0.02, 0.04), "safe_grey", 0.008)
    p.add(door.xf(move(w / 2, 0.01, d / 2) @ rot_y(-100)))
    dial = cyl(0.06, 0.0, 0.03, "chrome", 16, m=rot_x(90))
    p.add(dial.xf(move(w / 2, 0.01, d / 2) @ rot_y(-100) @ move(0.4, 0.8, 0.05)))
    return p


@prop
def marlin_file():
    """The auction file: a navy leather folder 0.33 x 0.05 x 0.25 with papers inside and a
    ribbon."""
    p = Prop("marlin_file")
    p.add(box((-0.165, 0.0, -0.125), (0.165, 0.05, 0.125), "folder_blue", 0.006))
    p.add(box((-0.16, 0.008, -0.12), (0.155, 0.042, 0.12), "paper", 0.001))
    p.add(box((0.02, 0.05, -0.126), (0.04, 0.052, 0.126), "velvet_burgundy", 0.0))
    return p


# --- The lower deck -----------------------------------------------------------------------------

@prop
def marlin_bunks():
    """Crew bunks: two berths 2.0 x 0.8, one over the other, in white laminate with curtains half
    drawn, reading lights and a short ladder; open side faces +Z."""
    p = Prop("marlin_bunks")
    w, d, h = 2.0, 0.85, 1.9
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.35, d / 2), "paint_white", 0.006))
    p.add(box((-w / 2, 0.95, -d / 2), (w / 2, 1.08, d / 2), "paint_white", 0.006))
    p.add(box((-w / 2, h - 0.06, -d / 2), (w / 2, h, d / 2), "paint_white", 0.006))
    for x in (-w / 2, w / 2 - 0.03):
        p.add(box((x, 0.0, -d / 2), (x + 0.03, h, d / 2), "paint_white", 0.004))
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, -d / 2 + 0.02), "paint_white", 0.0))
    for y in (0.35, 1.08):
        p.add(cushion((-w / 2 + 0.04, y, -d / 2 + 0.03), (w / 2 - 0.04, y + 0.14, d / 2 - 0.04), "mattress"))
        p.add(box((-w / 2 + 0.05, y + 0.13, 0.0), (w / 2 - 0.6, y + 0.18, d / 2 - 0.05), "blanket_grey", 0.02))
        p.add(cushion((w / 2 - 0.55, y + 0.14, -d / 2 + 0.06), (w / 2 - 0.1, y + 0.26, d / 2 - 0.08), "linen"))
        p.add(box((-w / 2 + 0.04, y + 0.2, d / 2 - 0.02), (-0.3, y + 0.58, d / 2), "cushion_navy", 0.006))
        p.add(box((w / 2 - 0.2, y + 0.45, -d / 2 + 0.02), (w / 2 - 0.1, y + 0.5, -d / 2 + 0.06), "bulb", 0.004))
    for x in (0.4, 0.7):
        p.add(box((x - 0.015, 0.0, d / 2 - 0.03), (x + 0.015, 1.25, d / 2), "chrome", 0.004))
    for y in (0.3, 0.6, 0.9):
        p.add(box((0.4, y - 0.012, d / 2 - 0.025), (0.7, y + 0.012, d / 2 - 0.005), "chrome", 0.004))
    return p


@prop
def marlin_washers():
    """The laundry's machines: two stacked washer-dryers side by side, 1.3 x 1.9 x 0.65, with
    round glass doors; front faces +Z."""
    p = Prop("marlin_washers")
    for x in (-0.33, 0.33):
        for y in (0.0, 0.92):
            p.add(box((x - 0.3, y, -0.32), (x + 0.3, y + 0.88, 0.32), "porcelain", 0.02))
            p.add(cyl(0.19, -0.01, 0.02, "chrome", 20, m=move(x, y + 0.42, 0.32) @ rot_x(90), bevel=0.003))
            p.add(cyl(0.15, 0.0, 0.03, "glass_dark", 20, m=move(x, y + 0.42, 0.32) @ rot_x(90), bevel=0.0))
            p.add(box((x - 0.26, y + 0.76, 0.32), (x + 0.26, y + 0.84, 0.33), "steel_dark", 0.002))
    return p


@prop
def marlin_dinette():
    """The crew mess's table: a white laminate table 1.6 x 0.8 with a U of navy bench round three
    sides, mugs and a fruit bowl; the open side faces +Z."""
    p = Prop("marlin_dinette")
    w, d = 1.6, 0.8
    p.add(box((-w / 2, 0.72, -d / 2), (w / 2, 0.76, d / 2), "corian", 0.01))
    p.add(cyl(0.05, 0.0, 0.72, "chrome", 12))
    p.add(cyl(0.3, 0.0, 0.02, "chrome", 16))
    bw = 0.45
    for lo, hi in (((-w / 2 - bw, 0.0, -d / 2 - bw), (w / 2 + bw, 0.45, -d / 2)),
                   ((-w / 2 - bw, 0.0, -d / 2), (-w / 2, 0.45, d / 2 + 0.2)),
                   ((w / 2, 0.0, -d / 2), (w / 2 + bw, 0.45, d / 2 + 0.2))):
        p.add(box(lo, hi, "paint_white", 0.01))
        p.add(cushion((lo[0] + 0.02, 0.45, lo[2] + 0.02), (hi[0] - 0.02, 0.55, hi[2] - 0.02), "cushion_navy"))
    p.add(cushion((-w / 2 - bw, 0.55, -d / 2 - bw), (w / 2 + bw, 1.0, -d / 2 - bw + 0.14), "cushion_navy"))
    for x, z in ((-0.5, 0.1), (0.3, -0.2), (0.55, 0.15)):
        p.add(lathe([(0.04, 0.76), (0.042, 0.86)], "porcelain", 12, cap=(True, False), m=move(x, 0, z)))
    p.add(lathe([(0.05, 0.76), (0.13, 0.81), (0.14, 0.83)], "porcelain", 16, cap=(True, False), m=move(-0.1, 0, -0.1)))
    for k in range(4):
        p.add(sphere(0.035, "produce_orange" if k % 2 else "produce_red", 8, 5, m=move(-0.1 + 0.05 * math.cos(k * 1.6), 0.83, -0.1 + 0.05 * math.sin(k * 1.6))))
    return p


@prop
def marlin_porthole():
    """A porthole seen from inside: a chrome ring 0.42 m across with dark glass; back on z = 0,
    centre at y = 0.21."""
    p = Prop("marlin_porthole")
    p.add(cyl(0.21, 0.0, 0.04, "chrome", 20, m=move(0, 0.21, 0) @ rot_x(90), bevel=0.006))
    p.add(cyl(0.16, 0.0, 0.045, "glass_dark", 20, m=move(0, 0.21, 0) @ rot_x(90), bevel=0.0))
    for k in range(6):
        a = k * math.pi / 3
        p.add(cyl(0.012, 0.0, 0.05, "steel", 6, m=move(0.185 * math.cos(a), 0.21 + 0.185 * math.sin(a), 0) @ rot_x(90), bevel=0.0))
    return p


@prop
def marlin_lifering():
    """A lifebuoy on a white bracket: an orange ring 0.75 m across with white bands; back on
    z = 0, centre at y = 0.4."""
    p = Prop("marlin_lifering")
    p.add(box((-0.08, 0.35, 0.0), (0.08, 0.5, 0.06), "lacquer_white", 0.01))
    for k in range(4):
        a0 = k * math.pi / 2
        pts = [(0.3 * math.cos(a0 + t * math.pi / 2), 0.4 + 0.3 * math.sin(a0 + t * math.pi / 2), 0.11) for t in [i / 6 for i in range(7)]]
        p.add(tube(pts, 0.07, "buoy_orange" if k % 2 == 0 else "paint_white", 8))
    return p


# --- The quay -----------------------------------------------------------------------------------

@prop
def marlin_bollard():
    """A cast-iron mooring bollard, 0.6 m tall, 0.5 m across its cap."""
    p = Prop("marlin_bollard")
    p.add(lathe([(0.3, 0.0), (0.3, 0.06), (0.2, 0.1), (0.17, 0.42), (0.25, 0.5), (0.25, 0.56), (0.0, 0.6)], "cast_iron", 16))
    return p


@prop
def marlin_van():
    """The chandler's van: a white panel van 5.2 x 2.5 x 2.1 with green Caldera Marine Supplies
    stripes, its sliding side door open on the +X side and stores inside. Nose toward -Z."""
    p = Prop("marlin_van")
    w, l = 2.0, 5.2
    z0, z1 = -l / 2, l / 2
    p.add(box((-w / 2, 0.35, z0 + 1.2), (w / 2, 2.45, z1), "van_white", 0.06, 3))
    nose = prism([(z0, 0.35), (z0 + 1.25, 0.35), (z0 + 1.25, 2.4), (z0 + 0.7, 2.0), (z0 + 0.15, 1.2), (z0, 1.0)], w, "van_white", plane="zy", bevel=0.05)
    p.add(nose)
    p.add(prism([(z0 + 0.72, 1.95), (z0 + 0.2, 1.24), (z0 + 0.2, 1.3), (z0 + 0.68, 1.98)], w - 0.1, "glass_dark", plane="zy", bevel=0.0).xf(move(0, 0.02, 0)))
    for side in (-1, 1):
        p.add(box((side * w / 2 - 0.01, 1.3, z0 + 0.75), (side * w / 2 + 0.01, 1.95, z0 + 1.2), "glass_dark", 0.0))
        p.add(box((side * w / 2 - 0.005, 1.0, z0 + 1.5), (side * w / 2 + 0.005, 1.25, z1 - 0.2), "van_green", 0.0))
        for z in (z0 + 0.85, z1 - 0.9):
            p.add(cyl(0.36, -0.13, 0.13, "rubber", 18, m=move(side * (w / 2 - 0.1), 0.36, z) @ rot_z(90), bevel=0.02))
            p.add(cyl(0.2, 0.12, 0.14, "steel", 12, m=move(side * (w / 2 - 0.1), 0.36, z) @ rot_z(90), bevel=0.0))
    p.add(box((-w / 2, 0.3, z0 - 0.05), (w / 2, 0.55, z0 + 0.1), "plastic_black", 0.03))
    p.add(box((-w / 2, 0.3, z1 - 0.1), (w / 2, 0.55, z1 + 0.05), "plastic_black", 0.03))
    for x in (-0.75, 0.75):
        p.add(box((x - 0.15, 0.85, z0 - 0.02), (x + 0.15, 1.0, z0 + 0.02), "lamp_led", 0.01))
        p.add(box((x - 0.12, 1.4, z1 + 0.0), (x + 0.12, 1.7, z1 + 0.02), "nav_red", 0.01))
    # The side door's opening (+X), dark inside, with crates.
    p.add(box((w / 2 - 0.02, 0.4, -0.3), (w / 2 + 0.005, 2.2, 1.2), "steel_dark", 0.0))
    p.add(box((w / 2 + 0.02, 0.4, 1.25), (w / 2 + 0.06, 2.2, 2.6), "van_white", 0.01))
    for i, (x, z) in enumerate(((0.5, 0.0), (0.5, 0.65), (0.0, 0.3))):
        p.add(box((x - 0.28, 0.4, z - 0.2), (x + 0.28, 0.75, z + 0.2), "crate_blue" if i % 2 == 0 else "crate_grey", 0.01))
    return p


def _crate(p, x, y, z, rng, mat="crate_blue", produce=None):
    w, d, h = 0.6, 0.4, 0.3
    p.add(box((x - w / 2, y, z - d / 2), (x + w / 2, y + 0.02, z + d / 2), mat, 0.004))
    for sx in (-1, 1):
        p.add(box((x + sx * w / 2 - (0.02 if sx > 0 else 0), y, z - d / 2), (x + sx * w / 2 + (0.0 if sx > 0 else 0.02), y + h, z + d / 2), mat, 0.004))
    for sz in (-1, 1):
        p.add(box((x - w / 2, y, z + sz * d / 2 - (0.02 if sz > 0 else 0)), (x + w / 2, y + h, z + sz * d / 2 + (0.0 if sz > 0 else 0.02)), mat, 0.004))
    if produce:
        for i in range(10):
            px = x - 0.22 + (i % 5) * 0.11
            pz = z - 0.08 + (i // 5) * 0.16
            p.add(sphere(0.055, produce, 8, 5, m=move(px + rng.uniform(-0.01, 0.01), y + h - 0.03, pz)))


@prop
def marlin_crate():
    """Ship's stores to carry aboard: two blue crates, one of lemons and one of greens, 0.6 x 0.6
    x 0.4; picked up from the van."""
    p = Prop("marlin_crate")
    rng = random.Random(11)
    _crate(p, 0.0, 0.0, 0.0, rng, "crate_blue", "produce_green")
    _crate(p, 0.0, 0.3, 0.0, rng, "crate_grey", "produce_orange")
    return p


@prop
def marlin_crates():
    """Stores waiting on the quay: a pallet of crates and cartons, 1.2 x 1.0 x 0.9."""
    p = Prop("marlin_crates")
    rng = random.Random(12)
    for z in (-0.45, 0.0, 0.45):
        p.add(box((-0.6, 0.0, z - 0.05), (0.6, 0.1, z + 0.05), "wood_pallet", 0.006))
    p.add(box((-0.6, 0.1, -0.5), (0.6, 0.13, 0.5), "wood_pallet", 0.004))
    _crate(p, -0.3, 0.13, -0.25, rng, "crate_blue", "produce_red")
    _crate(p, 0.3, 0.13, -0.25, rng, "crate_grey", "produce_green")
    _crate(p, -0.3, 0.13, 0.25, rng, "crate_blue", "produce_orange")
    p.add(box((0.02, 0.13, 0.06), (0.58, 0.55, 0.46), "cardboard", 0.006))
    p.add(box((-0.55, 0.43, -0.42), (-0.05, 0.8, 0.0), "cardboard", 0.006))
    return p


@prop
def marlin_trestle():
    """The purser's table on the quay: a folding table 1.6 x 0.7 with a clipboard of crew lists, a
    laptop, a cash box and a lamp. Front faces +Z (the purser sits or stands behind, at -Z)."""
    p = Prop("marlin_trestle")
    w, d = 1.6, 0.7
    p.add(box((-w / 2, 0.72, -d / 2), (w / 2, 0.75, d / 2), "paint_white", 0.006))
    for x in (-w / 2 + 0.15, w / 2 - 0.15):
        for s in (-1, 1):
            p.add(tube([(x, 0.72, s * (d / 2 - 0.05)), (x + s * 0.0, 0.0, -s * (d / 2 - 0.05))], 0.014, "steel", 6))
    p.add(box((-0.55, 0.75, -0.05), (-0.25, 0.765, 0.2), "steel_dark", 0.004))
    p.add(box((-0.53, 0.765, -0.03), (-0.27, 0.768, 0.18), "paper", 0.0))
    p.add(box((-0.1, 0.75, -0.25), (0.25, 0.765, -0.02), "steel_dark", 0.004))
    p.add(box((-0.1, 0.765, -0.27), (0.25, 0.97, -0.255), "steel_dark", 0.004).xf(move(0.0, 0.765, -0.26) @ rot_x(12) @ move(0, -0.765, 0.26)))
    p.add(box((0.4, 0.75, -0.15), (0.65, 0.85, 0.05), "paint_green", 0.006))
    p.add(tube([(0.7, 0.75, -0.25), (0.7, 1.05, -0.2), (0.6, 1.1, -0.1)], 0.008, "steel_dark", 6))
    p.add(lathe([(0.0, 1.05), (0.06, 1.08), (0.07, 1.11)], "steel_dark", 12, cap=(False, False), m=move(0.58, 0, -0.08)))
    return p


@prop
def marlin_neighbor():
    """A neighbour in the marina: a 36 m motor yacht moored stern-to, white with dark window bands
    and a few lit portholes; stern at z = 0, bow toward -Z, 7.4 m in the beam."""
    p = Prop("marlin_neighbor")
    b = 3.7
    st = [(0.0, b * 0.95, 1.0), (-2.0, b, 1.0), (-24.0, b, 1.0), (-24.1, b, 1.9), (-29.0, b * 0.8, 2.0),
          (-33.0, b * 0.45, 2.15), (-35.5, b * 0.12, 2.25), (-36.0, 0.03, 2.3)]
    for side in (-1, 1):
        rows = []
        for z, hb, yt in st:
            bow = max(0.0, (-z - 28.0) / 8.0)
            rows.append([(side * hb, yt, z), (side * hb * 0.98, -1.4 + bow * 1.6, z)] if side > 0 else [(side * hb * 0.98, -1.4 + bow * 1.6, z), (side * hb, yt, z)])
        p.add(strip(rows, "hull_white"))
        p.add(box((side * (b + 0.01) - 0.01, -1.25, -30.0), (side * (b + 0.01) + 0.01, -0.95, -1.0), "hull_navy", 0.0))
        p.add(box((side * (b - 0.25) - 0.01, 1.6, -22.0), (side * (b - 0.25) + 0.01, 2.6, -6.0), "glass_dark", 0.0))
        for i in range(6):
            z = -9.0 - i * 2.5
            p.add(cyl(0.12, -0.01, 0.01, "window_lit" if (i + (side > 0)) % 3 == 0 else "glass_dark", 12, m=move(side * (b + 0.01), 0.1, z) @ rot_z(90), bevel=0.0))
    p.add(box((-b, -1.4, 0.0), (b, 1.0, 0.02), "hull_white", 0.0))
    # Decks and the house.
    p.add(box((-b + 0.05, 0.95, -24.0), (b - 0.05, 1.0, 0.0), "teak_solid", 0.0))
    p.add(box((-b + 0.25, 1.0, -22.0), (b - 0.25, 3.1, -6.0), "hull_white", 0.04))
    p.add(box((-b + 0.25, 1.6, -5.99), (b - 0.25, 2.7, -5.97), "window_lit", 0.0))
    p.add(box((-b + 0.6, 3.1, -19.0), (b - 0.6, 5.0, -8.0), "hull_white", 0.04))
    for side in (-1, 1):
        p.add(box((side * (b - 0.6) - 0.01, 3.6, -18.0), (side * (b - 0.6) + 0.01, 4.6, -9.0), "glass_dark", 0.0))
    p.add(box((-b + 0.3, 3.05, -24.0), (b - 0.3, 3.15, -2.0), "hull_white", 0.02))
    p.add(box((-b + 0.8, 5.0, -18.5), (b - 0.8, 5.12, -6.5), "hull_white", 0.02))
    p.add(cyl(0.06, 5.1, 7.0, "chrome", 8, m=move(0, 0, -14.0)))
    p.add(sphere(0.08, "nav_white", 8, 5, m=move(0, 7.05, -14.0)))
    p.add(box((-b * 0.8, 1.0, -0.4), (b * 0.8, 1.9, -0.36), "glass", 0.0))
    return p


@prop
def marlin_mast():
    """The radar arch on the hardtop: two raked white legs 2.4 m tall joined by a crossbar with
    two radar scanners, a dome, the masthead lights and the flag staff; 6 m wide."""
    p = Prop("marlin_mast")
    for side in (-1, 1):
        leg = prism([(-0.6, 0.0), (0.6, 0.0), (0.2, 2.2), (-0.3, 2.2)], 0.25, "hull_white", plane="zy", bevel=0.03)
        p.add(leg.xf(move(side * 2.6, 0, 0)))
    p.add(box((-2.9, 2.1, -0.4), (2.9, 2.5, 0.25), "hull_white", 0.05))
    for x in (-1.6, 1.6):
        p.add(box((x - 0.06, 2.5, -0.06), (x + 0.06, 2.75, 0.06), "steel_dark", 0.01))
        p.add(box((x - 0.9, 2.75, -0.08), (x + 0.9, 2.9, 0.08), "steel_dark", 0.03))
    p.add(cyl(0.05, 2.5, 3.3, "chrome", 8, m=move(0, 0, 0)))
    p.add(sphere(0.35, "paint_white", 12, 8, m=move(0.6, 2.85, 0.0)))
    p.add(sphere(0.07, "nav_white", 8, 5, m=move(0, 3.35, 0)))
    p.add(box((-0.06, 3.0, -0.06), (0.06, 3.1, 0.06), "nav_red", 0.0))
    return p


@prop
def marlin_rail():
    """A 2 m section of the upper deck's balustrade: glass between polished stanchions under a
    stainless handrail at 1.1 m; stands on y = 0 along x, centred."""
    p = Prop("marlin_rail")
    p.add(stanchion_rail(-1.0, 1.0, 1.1, 0.0, 1.0, glass=True))
    return p


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if "--list" in args:
        for n, fn in PROPS.items():
            print("%-24s %s" % (n, (fn.__doc__ or "").strip().split("\n")[0]))
        return
    os.makedirs(OUT, exist_ok=True)
    for name in args or list(PROPS):
        if name not in PROPS:
            print("no prop called", name)
            continue
        export(PROPS[name]())


if __name__ == "__main__":
    main()
