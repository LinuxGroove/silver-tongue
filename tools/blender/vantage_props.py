"""Builds Vantage Tower's furniture and fittings and writes each one as a GLB.

Run from the repository root with a Python that has the `bpy` module (the same venv as
tools/blender/props.py):

    python tools/blender/vantage_props.py [prop ...]

Naming props rebuilds only those; `--list` prints them. They go to assets/models/vantage/,
where `Kit` finds them by name, so every name starts with `vantage_`.

The conventions are props.py's: Godot's axes, metres, floor props on y = 0 centred on their
footprint facing +Z, wall props with their back on z = 0, hanging props hanging down from
y = their height, door leaves hinged at the origin and spanning -x. The Rose is its own prop
(`vantage_rose`), so the game can hide it when it's taken.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import props  # noqa: E402
from props import Prop, box, cyl, lathe, tube, prism, sphere, ico, octa, move, rot_x, rot_y, rot_z, cushion  # noqa: E402

OUT = os.path.join(props.ROOT, "assets", "models", "vantage")

props.MATERIALS.update({
    "oak_pale": ("#b48d60", 0.0, 0.45, {}),
    "oak_slat": ("#9a7349", 0.0, 0.5, {}),
    "stone_pale": ("#d9d6cf", 0.0, 0.32, {}),
    "stone_dark": ("#28292b", 0.0, 0.22, {}),
    "steel_brushed": ("#a9adb1", 1.0, 0.36, {}),
    "steel_black": ("#2b2d30", 0.8, 0.4, {}),
    "leather_tan": ("#8a5a36", 0.0, 0.5, {}),
    "leather_charcoal": ("#2b2b2e", 0.0, 0.48, {}),
    "fabric_grey": ("#5b5f66", 0.0, 0.92, {}),
    "fabric_teal": ("#2c5561", 0.0, 0.92, {}),
    "epoxy_black": ("#1b1d1f", 0.0, 0.3, {}),
    "lab_white": ("#eceeee", 0.0, 0.42, {}),
    "glass_clear": ("#d6e2e6", 0.0, 0.03, {"alpha": 0.16}),
    "glass_frost": ("#e6eef0", 0.0, 0.25, {"alpha": 0.6}),
    "glass_dome": ("#eaf2f6", 0.0, 0.02, {"alpha": 0.12}),
    "rose_gem": ("#ff6f9f", 0.0, 0.04, {"emit": "#ff4f8a", "strength": 1.6}),
    "velvet_black": ("#141416", 0.0, 0.85, {}),
    "light_panel": ("#f4f6f8", 0.0, 0.3, {"emit": "#eef4ff", "strength": 3.0}),
    "light_warm": ("#fff2dc", 0.0, 0.3, {"emit": "#ffe0b0", "strength": 3.0}),
    "screen_blue": ("#16222e", 0.0, 0.2, {"emit": "#5d86b8", "strength": 1.3}),
    "led_blue": ("#4aa0ff", 0.0, 0.4, {"emit": "#3a90ff", "strength": 3.0}),
    "led_amber": ("#ffb040", 0.0, 0.4, {"emit": "#ffa020", "strength": 3.0}),
    "coffee": ("#2b1a10", 0.0, 0.3, {}),
    "cake": ("#c8935a", 0.0, 0.7, {}),
    "rubber_mat": ("#1e2022", 0.0, 0.9, {}),
})

PROPS = {}


def prop(fn):
    PROPS[fn.__name__] = fn
    return fn


def monitor(p, x, y, z, w=0.55, h=0.33, yaw=0.0, mat="screen"):
    """A slim monitor on a stand, its foot at (x, y, z), screen toward +Z turned by `yaw`."""
    m = move(x, y, z) @ rot_y(yaw)
    p.add(box((-0.09, 0.0, -0.07), (0.09, 0.012, 0.07), "plastic_black", 0.004, m=m))
    p.add(box((-0.02, 0.0, -0.04), (0.02, 0.16, -0.02), "plastic_black", 0.003, m=m))
    p.add(box((-w / 2, 0.12, -0.04), (w / 2, 0.12 + h, -0.015), "plastic_black", 0.004, m=m))
    p.add(box((-w / 2 + 0.012, 0.132, -0.015), (w / 2 - 0.012, 0.12 + h - 0.012, -0.013), mat, 0.0, m=m))


# --- The lobby ----------------------------------------------------------------------------------

@prop
def vantage_front_desk():
    """The front desk: 4.2 m of oak slats under a pale stone top, a work surface behind with two
    screens, a pass printer and a phone. 4.2 x 1.1 x 1.0; the visitors' side faces +Z."""
    p = Prop("vantage_front_desk")
    w, d, h = 4.2, 1.0, 1.1
    p.add(box((-w / 2, 0.0, -d / 2 + 0.12), (w / 2, 0.08, d / 2 - 0.06), "stone_dark", 0.004))
    n = 42
    for i in range(n):
        x = -w / 2 + (i + 0.5) * w / n
        p.add(box((x - 0.035, 0.08, d / 2 - 0.12), (x + 0.035, h - 0.06, d / 2 - 0.05), "oak_slat", 0.006))
    p.add(box((-w / 2, 0.08, -d / 2 + 0.12), (w / 2, h - 0.06, d / 2 - 0.12), "oak_pale", 0.004))
    for s in (-1, 1):
        p.add(box((s * w / 2 - 0.05, 0.08, -d / 2 + 0.12), (s * w / 2 + 0.05, h - 0.06, d / 2 - 0.05), "oak_pale", 0.006))
    p.add(box((-w / 2 - 0.04, h - 0.06, -0.05), (w / 2 + 0.04, h, d / 2), "stone_pale", 0.008))
    p.add(box((-w / 2, 0.72, -d / 2), (w / 2, 0.76, 0.0), "stone_pale", 0.006))
    for x in (-1.1, 0.9):
        monitor(p, x, 0.76, -0.28, 0.5, 0.3)
        p.add(box((x - 0.2, 0.76, -0.12), (x + 0.2, 0.775, 0.0), "plastic_black", 0.003))
    p.add(box((1.6, 0.76, -0.4), (1.95, 0.98, -0.12), "paint_white", 0.01))
    p.add(box((1.64, 0.98, -0.36), (1.91, 1.0, -0.16), "plastic_black", 0.004))
    p.add(box((-1.85, 0.76, -0.3), (-1.6, 0.82, -0.1), "plastic_black", 0.01))
    return p


@prop
def vantage_gate_desk():
    """Halberd's podium beside the speed gates: a dark stone lectern with a steel top and a
    screen set into it, 1.2 x 1.15 x 0.6; the visitors' side faces +Z."""
    p = Prop("vantage_gate_desk")
    p.add(box((-0.6, 0.0, -0.3), (0.6, 1.08, 0.3), "stone_dark", 0.01))
    p.add(box((-0.64, 1.08, -0.34), (0.64, 1.14, 0.34), "steel_brushed", 0.006))
    p.add(box((-0.5, 1.14, -0.3), (0.5, 1.16, 0.0), "plastic_black", 0.003))
    monitor(p, -0.2, 1.14, -0.18, 0.4, 0.24)
    p.add(box((0.2, 1.14, -0.25), (0.45, 1.17, -0.05), "plastic_black", 0.005))
    p.add(box((-0.2, 0.6, 0.3), (0.2, 0.7, 0.305), "steel_brushed", 0.002))
    return p


@prop
def vantage_gate():
    """A speed gate's cabinet: 0.24 wide, 1.0 tall and 1.6 long (along z), brushed steel with a
    black glass top, a card reader at the +Z end and green lane lights."""
    p = Prop("vantage_gate")
    w, h, l = 0.24, 1.0, 1.6
    p.add(box((-w / 2, 0.0, -l / 2), (w / 2, 0.05, l / 2), "rubber_mat", 0.004))
    p.add(box((-w / 2, 0.05, -l / 2), (w / 2, h - 0.04, l / 2), "steel_brushed", 0.02))
    p.add(box((-w / 2 - 0.005, h - 0.04, -l / 2), (w / 2 + 0.005, h, l / 2), "epoxy_black", 0.01))
    p.add(box((-0.07, h, l / 2 - 0.3), (0.07, h + 0.01, l / 2 - 0.12), "plastic_black", 0.003))
    p.add(box((-0.04, h + 0.01, l / 2 - 0.27), (0.04, h + 0.012, l / 2 - 0.15), "led_green", 0.0))
    for s in (-1, 1):
        p.add(box((s * w / 2 - 0.004, 0.7, -l / 2 + 0.1), (s * w / 2 + 0.004, 0.72, l / 2 - 0.1), "led_blue", 0.0))
    return p


@prop
def vantage_gate_flap():
    """A speed gate's glass flap: 1.0 x 1.0 nominal (scaled to fit), clear glass with a steel
    edge. Hinged at the origin, spanning x -1.0..0, like a door leaf."""
    p = Prop("vantage_gate_flap")
    w, h = 1.0, 1.0
    p.add(box((-w, 0.08, -0.008), (-0.02, h, 0.008), "glass_clear", 0.0))
    p.add(box((-0.03, 0.08, -0.012), (0.0, h, 0.012), "steel_brushed", 0.004))
    p.add(box((-w, h - 0.02, -0.01), (-0.02, h, 0.01), "steel_brushed", 0.004))
    return p


@prop
def vantage_glass_leaf():
    """A frameless glass door leaf, 1.0 x 2.4 nominal, with steel patch fittings top and bottom
    and a long steel pull. Hinged at the origin, spanning x -1.0..0."""
    p = Prop("vantage_glass_leaf")
    w, h = 1.0, 2.4
    p.add(box((-w + 0.004, 0.0, -0.01), (-0.004, h, 0.01), "glass_clear", 0.0))
    for y0, y1 in ((0.0, 0.12), (h - 0.12, h)):
        p.add(box((-w + 0.004, y0, -0.016), (-0.004, y1, 0.016), "steel_brushed", 0.004))
    for zs in (-1, 1):
        p.add(tube([(-w + 0.12, 0.85, zs * 0.016), (-w + 0.12, 0.85, zs * 0.06), (-w + 0.12, 1.75, zs * 0.06), (-w + 0.12, 1.75, zs * 0.016)], 0.014, "steel_brushed", 8))
    return p


@prop
def vantage_lift_leaf():
    """A lift door leaf, 0.6 x 2.3 nominal: brushed steel with a dark edge. Hinged at the origin,
    spanning x -0.6..0."""
    p = Prop("vantage_lift_leaf")
    w, h = 0.6, 2.3
    p.add(box((-w + 0.003, 0.0, -0.025), (-0.003, h, 0.025), "steel_brushed", 0.004))
    p.add(box((-0.012, 0.0, -0.026), (-0.003, h, 0.026), "steel_black", 0.002))
    return p


@prop
def vantage_door_oak():
    """An office door leaf: 1.0 x 2.3 nominal pale oak, flush, with a steel lever and kick plate.
    Hinged at the origin, spanning x -1.0..0."""
    p = Prop("vantage_door_oak")
    w, h, t = 1.0, 2.3, 0.05
    p.add(box((-w + 0.004, 0.0, -t / 2), (-0.004, h, t / 2), "oak_pale", 0.006))
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(box((-w + 0.03, 0.02, min(z, z + zs * 0.003)), (-0.03, 0.22, max(z, z + zs * 0.003)), "steel_brushed", 0.001))
        p.add(tube([(-w + 0.08, 1.05, z), (-w + 0.08, 1.05, z + zs * 0.06), (-w + 0.24, 1.05, z + zs * 0.06)], 0.011, "steel_brushed", 6))
    return p


@prop
def vantage_lift_frame():
    """The steel portal round a lift's doors: 1.8 wide, 2.7 tall, with a floor display over it.
    Back on z = 0; the doorway (1.2 x 2.3) is centred on x = 0."""
    p = Prop("vantage_lift_frame")
    for s in (-1, 1):
        p.add(box((s * 0.6, 0.0, 0.0), (s * 0.9, 2.45, 0.05), "steel_brushed", 0.006))
    p.add(box((-0.9, 2.3, 0.0), (0.9, 2.7, 0.05), "steel_brushed", 0.006))
    p.add(box((-0.25, 2.42, 0.05), (0.25, 2.6, 0.06), "epoxy_black", 0.003))
    p.add(box((-0.2, 2.47, 0.06), (0.2, 2.55, 0.062), "led_amber", 0.0))
    return p


@prop
def vantage_call_panel():
    """A lift call panel: a steel plate with an up and a down button and a card reader; 0.12 x
    0.32, back on z = 0, from y 0."""
    p = Prop("vantage_call_panel")
    p.add(box((-0.06, 0.0, 0.0), (0.06, 0.32, 0.015), "steel_brushed", 0.004))
    for y in (0.2, 0.26):
        p.add(cyl(0.018, 0.015, 0.024, "led_blue", 12, m=move(0, y, 0) @ rot_x(90), bevel=0))
    p.add(box((-0.04, 0.04, 0.015), (0.04, 0.12, 0.022), "plastic_black", 0.003))
    p.add(box((-0.015, 0.105, 0.022), (0.015, 0.11, 0.024), "led_green", 0.0))
    return p


@prop
def vantage_lift_car():
    """A lift car's inside, 2.6 wide, 2.6 deep and 2.6 tall: steel side walls, a mirror at the
    back over a handrail, a stone floor and a lit ceiling. The open front is on z = 0 and the
    car runs back to z = -2.6."""
    p = Prop("vantage_lift_car")
    w, d, h = 2.6, 2.6, 2.6
    p.add(box((-w / 2, -0.02, -d), (w / 2, 0.0, 0.0), "stone_dark", 0.0))
    for s in (-1, 1):
        p.add(box((s * w / 2 - (0.03 if s > 0 else 0.0), 0.0, -d), (s * w / 2 + (0.0 if s > 0 else 0.03), h, 0.0), "steel_brushed", 0.0))
    p.add(box((-w / 2, 0.0, -d), (w / 2, h, -d + 0.03), "steel_brushed", 0.0))
    p.add(box((-w / 2 + 0.2, 0.95, -d + 0.03), (w / 2 - 0.2, 2.3, -d + 0.035), "mirror", 0.0))
    p.add(tube([(-w / 2 + 0.25, 0.9, -d + 0.05), (-w / 2 + 0.25, 0.9, -d + 0.1), (w / 2 - 0.25, 0.9, -d + 0.1), (w / 2 - 0.25, 0.9, -d + 0.05)], 0.02, "steel_brushed", 8))
    p.add(box((-w / 2, h - 0.03, -d), (w / 2, h, 0.0), "steel_black", 0.0))
    p.add(box((-w / 2 + 0.3, h - 0.035, -d + 0.3), (w / 2 - 0.3, h - 0.03, -0.3), "light_panel", 0.0))
    p.add(box((w / 2 - 0.03, 1.0, -0.5), (w / 2 - 0.02, 1.5, -0.3), "steel_black", 0.002))
    return p


@prop
def vantage_cafe_counter():
    """The lobby cafe's counter: 3.2 m of oak slats under white stone, a glass cake case, an
    espresso machine and a till. 3.2 x 1.05 x 0.8; customers' side faces +Z."""
    p = Prop("vantage_cafe_counter")
    w, d, h = 3.2, 0.8, 1.05
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.08, d / 2 - 0.04), "stone_dark", 0.004))
    n = 32
    for i in range(n):
        x = -w / 2 + (i + 0.5) * w / n
        p.add(box((x - 0.04, 0.08, d / 2 - 0.08), (x + 0.04, h - 0.04, d / 2 - 0.02), "oak_slat", 0.006))
    p.add(box((-w / 2, 0.08, -d / 2), (w / 2, h - 0.04, d / 2 - 0.08), "oak_pale", 0.004))
    p.add(box((-w / 2 - 0.03, h - 0.04, -d / 2 - 0.03), (w / 2 + 0.03, h, d / 2 + 0.02), "marble_white", 0.006))
    # The cake case.
    p.add(box((-1.4, h, -0.2), (-0.5, h + 0.02, 0.3), "steel_brushed", 0.003))
    p.add(box((-1.4, h + 0.02, -0.2), (-0.5, h + 0.42, 0.3), "glass_clear", 0.004))
    p.add(box((-1.38, h + 0.22, -0.18), (-0.52, h + 0.23, 0.28), "glass_clear", 0.0))
    for i in range(4):
        p.add(cyl(0.075, h + 0.02, h + 0.11, "cake", 12, m=move(-1.28 + i * 0.22, 0, 0.05), bevel=0.006))
        p.add(cyl(0.06, h + 0.23, h + 0.3, "cake", 12, m=move(-1.28 + i * 0.22, 0, 0.05), bevel=0.006))
    # The espresso machine and grinder.
    p.add(box((0.2, h, -0.32), (0.95, h + 0.42, 0.05), "steel_brushed", 0.02))
    p.add(box((0.2, h + 0.42, -0.32), (0.95, h + 0.46, 0.05), "chrome", 0.01))
    for x in (0.38, 0.75):
        p.add(cyl(0.03, h + 0.16, h + 0.24, "chrome", 10, m=move(x, 0, 0.08), bevel=0))
        p.add(lathe([(0.0, h + 0.02), (0.035, h + 0.02), (0.04, h + 0.1), (0.0, h + 0.1)], "porcelain", 10, m=move(x, 0, 0.12)))
    p.add(cyl(0.07, h, h + 0.28, "steel_black", 12, m=move(1.15, 0, -0.15)))
    p.add(lathe([(0.0, h + 0.28), (0.08, h + 0.3), (0.06, h + 0.45), (0.0, h + 0.46)], "glass_dark", 12, m=move(1.15, 0, -0.15)))
    p.add(box((1.35, h, -0.3), (1.55, h + 0.06, -0.05), "plastic_black", 0.006))
    p.add(box((1.38, h + 0.06, -0.28), (1.52, h + 0.2, -0.24), "screen", 0.003))
    return p


@prop
def vantage_cafe_back():
    """The cafe's back counter: a low oak cupboard under open shelves of cups and coffee bags,
    and a lit menu board. 3.2 x 2.6 x 0.6; front faces +Z."""
    p = Prop("vantage_cafe_back")
    rng = random.Random(4)
    w, d = 3.2, 0.6
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.9, d / 2), "oak_pale", 0.006))
    p.add(box((-w / 2, 0.9, -d / 2), (w / 2, 0.94, d / 2 + 0.02), "marble_white", 0.004))
    for i in range(4):
        x = -w / 2 + 0.4 + i * 0.8
        p.add(box((x - 0.36, 0.06, d / 2), (x + 0.36, 0.84, d / 2 + 0.01), "oak_slat", 0.004))
    for y in (1.45, 1.8):
        p.add(box((-w / 2, y, -d / 2), (w / 2, y + 0.03, -d / 2 + 0.28), "oak_pale", 0.004))
        x = -w / 2 + 0.12
        while x < w / 2 - 0.1:
            if rng.random() < 0.55:
                p.add(lathe([(0.0, y + 0.03), (0.04, y + 0.03), (0.045, y + 0.12), (0.0, y + 0.12)], "porcelain", 8, m=move(x, 0, -d / 2 + 0.14)))
                x += 0.1
            else:
                p.add(box((x, y + 0.03, -d / 2 + 0.06), (x + 0.12, y + 0.24, -d / 2 + 0.2), "paper" if rng.random() < 0.5 else "cardboard", 0.01))
                x += 0.16
    p.add(box((-1.0, 2.0, -d / 2), (1.0, 2.6, -d / 2 + 0.04), "epoxy_black", 0.006))
    p.add(box((-0.95, 2.05, -d / 2 + 0.04), (0.95, 2.55, -d / 2 + 0.045), "screen", 0.0))
    return p


@prop
def vantage_cafe_table():
    """A round cafe table, 0.7 across and 0.74 tall, white stone on a black pedestal."""
    p = Prop("vantage_cafe_table")
    p.add(lathe([(0.0, 0.0), (0.26, 0.0), (0.26, 0.02), (0.05, 0.05), (0.035, 0.08), (0.035, 0.7), (0.0, 0.7)], "steel_black", 16))
    p.add(cyl(0.35, 0.7, 0.74, "marble_white", 24, bevel=0.008))
    return p


@prop
def vantage_cafe_chair():
    """A cafe chair: an oak seat and back on black steel legs, 0.45 x 0.8 x 0.5; faces +Z."""
    p = Prop("vantage_cafe_chair")
    for x in (-0.19, 0.19):
        for z in (-0.19, 0.17):
            p.add(tube([(x, 0.0, z), (x * 0.95, 0.44, z * 0.95)], 0.012, "steel_black", 6))
    p.add(box((-0.22, 0.44, -0.22), (0.22, 0.47, 0.2), "oak_pale", 0.01))
    for x in (-0.18, 0.18):
        p.add(tube([(x, 0.46, -0.2), (x, 0.8, -0.24)], 0.011, "steel_black", 6))
    p.add(box((-0.21, 0.62, -0.26), (0.21, 0.8, -0.23), "oak_pale", 0.01).xf(move(0, 0.7, -0.24) @ rot_x(-8) @ move(0, -0.7, 0.24)))
    return p


@prop
def vantage_bench():
    """A lobby bench: oak slats on two black steel frames, 2.0 x 0.45 x 0.5."""
    p = Prop("vantage_bench")
    w, d, h = 2.0, 0.5, 0.45
    for x in (-0.75, 0.75):
        p.add(box((x - 0.03, 0.0, -d / 2 + 0.02), (x + 0.03, h - 0.04, -d / 2 + 0.07), "steel_black", 0.004))
        p.add(box((x - 0.03, 0.0, d / 2 - 0.07), (x + 0.03, h - 0.04, d / 2 - 0.02), "steel_black", 0.004))
        p.add(box((x - 0.03, h - 0.07, -d / 2 + 0.02), (x + 0.03, h - 0.04, d / 2 - 0.02), "steel_black", 0.004))
    for i in range(6):
        z = -d / 2 + 0.04 + i * (d - 0.08) / 5
        p.add(box((-w / 2, h - 0.04, z - 0.03), (w / 2, h, z + 0.03), "oak_slat", 0.006))
    return p


def _crown(p, x, y, z, r, rng, mats=("leaf", "leaf_dark")):
    for i in range(7):
        a = rng.random() * 2 * math.pi
        rr = r * (0.3 + 0.5 * rng.random())
        c = (x + rr * math.cos(a), y + (rng.random() - 0.3) * r * 0.7, z + rr * math.sin(a))
        p.add(ico(r * (0.45 + 0.25 * rng.random()), mats[i % len(mats)], 1, m=move(*c)))


@prop
def vantage_planter():
    """A square planter of dark stone, 1.2 x 0.6 x 1.2, with a small tree 3.4 m tall in it."""
    p = Prop("vantage_planter")
    rng = random.Random(8)
    p.add(box((-0.6, 0.0, -0.6), (0.6, 0.6, 0.6), "stone_dark", 0.012))
    p.add(box((-0.54, 0.6, -0.54), (0.54, 0.62, 0.54), "soil", 0.0))
    p.add(tube([(0, 0.6, 0), (0.05, 1.6, 0.02), (0.0, 2.4, -0.03)], 0.06, "oak_slat", 7, radii=[0.07, 0.05, 0.035]))
    for a in (0.3, 2.4, 4.4):
        p.add(tube([(0.03, 1.8, 0), (0.45 * math.cos(a), 2.5, 0.45 * math.sin(a))], 0.025, "oak_slat", 5))
    _crown(p, 0.0, 2.75, 0.0, 0.6, rng)
    return p


@prop
def vantage_plant():
    """An office plant: a tall white pot 0.45 across with a leafy plant, 1.5 m tall."""
    p = Prop("vantage_plant")
    rng = random.Random(15)
    p.add(lathe([(0.0, 0.0), (0.17, 0.0), (0.22, 0.6), (0.0, 0.6)], "paint_white", 14))
    p.add(cyl(0.2, 0.58, 0.6, "soil", 12, bevel=0))
    for i in range(9):
        a = i * 2.39
        h = 0.95 + rng.random() * 0.5
        tip = (0.35 * math.cos(a), h, 0.35 * math.sin(a))
        p.add(tube([(0, 0.6, 0), (tip[0] * 0.4, h * 0.85, tip[2] * 0.4), tip], 0.008, "leaf_dark", 4))
        p.add(ico(0.12, "leaf", 1, m=move(*tip) @ props.scale(1.4, 0.5, 1.0)))
    return p


@prop
def vantage_sculpture():
    """The lobby's sculpture: a faceted steel ring standing on its edge, 2.6 m tall, on a dark
    stone plinth 1.6 m square."""
    p = Prop("vantage_sculpture")
    p.add(box((-0.8, 0.0, -0.8), (0.8, 0.45, 0.8), "stone_dark", 0.012))
    pts = []
    n = 12
    for i in range(n):
        a = 2 * math.pi * i / n
        pts.append((0.95 * math.sin(a), 1.55 + 0.95 * math.cos(a), 0.0))
    p.add(tube(pts, 0.12, "chrome", 6, closed=True))
    p.add(box((-0.08, 0.45, -0.12), (0.08, 0.62, 0.12), "steel_black", 0.006))
    return p


@prop
def vantage_ring_light():
    """The lobby's hanging ring light: 6 m across, lit underneath, on three cables; hangs from
    y = 3.0 down to the ring at y = 0."""
    p = Prop("vantage_ring_light")
    pts = [(3.0 * math.cos(2 * math.pi * i / 36), 0.0, 3.0 * math.sin(2 * math.pi * i / 36)) for i in range(36)]
    p.add(tube(pts, 0.09, "steel_black", 8, closed=True))
    for i in range(36):
        a0 = 2 * math.pi * i / 36
        a1 = 2 * math.pi * (i + 1) / 36
        x0, z0 = 3.0 * math.cos(a0), 3.0 * math.sin(a0)
        x1, z1 = 3.0 * math.cos(a1), 3.0 * math.sin(a1)
        p.add(prism([(x0 * 0.985, z0 * 0.985), (x1 * 0.985, z1 * 0.985), (x1 * 1.015, z1 * 1.015), (x0 * 1.015, z0 * 1.015)], 0.01, "light_warm", plane="xz", m=move(0, -0.09, 0), bevel=0.0))
    for i in range(3):
        a = 2 * math.pi * i / 3 + 0.5
        p.add(tube([(3.0 * math.cos(a), 0.05, 3.0 * math.sin(a)), (3.0 * math.cos(a), 3.0, 3.0 * math.sin(a))], 0.006, "steel", 4))
    return p


@prop
def vantage_canopy():
    """The entrance canopy: a steel-edged glass canopy 8 m wide, reaching 3.5 m out, with a lit
    soffit. Back on z = 0, top at y 0.35."""
    p = Prop("vantage_canopy")
    w, d = 8.0, 3.5
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, 0.08, d), "steel_black", 0.01))
    p.add(box((-w / 2, 0.08, d - 0.1), (w / 2, 0.35, d), "steel_black", 0.01))
    for s in (-1, 1):
        p.add(box((s * w / 2 - 0.1, 0.08, 0.0), (s * w / 2 + 0.1, 0.35, d), "steel_black", 0.01))
    p.add(box((-w / 2 + 0.1, 0.3, 0.0), (w / 2 - 0.1, 0.32, d - 0.1), "glass_frost", 0.0))
    for i in range(5):
        x = -3.2 + i * 1.6
        p.add(cyl(0.08, -0.01, 0.0, "light_warm", 12, m=move(x, 0, d * 0.55), bevel=0))
    return p


# --- The board floor --------------------------------------------------------------------------

@prop
def vantage_board_table():
    """The boardroom table: 9 m of walnut, 1.8 m wide, on two dark steel slab legs, with a
    leather blotter, water glasses and a closed laptop at each of fourteen places. 0.75 tall;
    long along x."""
    p = Prop("vantage_board_table")
    w, d, h = 9.0, 1.8, 0.75
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "walnut", 0.01, 3))
    p.add(box((-w / 2 + 0.3, h - 0.06, -0.06), (w / 2 - 0.3, h - 0.045, 0.06), "steel_black", 0.002))
    for x in (-w / 2 + 1.2, w / 2 - 1.2):
        p.add(box((x - 0.06, 0.0, -d / 2 + 0.3), (x + 0.06, h - 0.05, d / 2 - 0.3), "steel_black", 0.006))
    for i in range(6):
        x = -w / 2 + 1.0 + i * (w - 2.0) / 5
        for s in (-1, 1):
            z = s * (d / 2 - 0.32)
            p.add(box((x - 0.24, h, z - 0.17), (x + 0.24, h + 0.005, z + 0.17), "leather_charcoal", 0.002))
            p.add(lathe([(0.0, h), (0.03, h), (0.035, h + 0.12), (0.0, h + 0.12)], "glass_clear", 8, m=move(x + 0.32, 0, z - s * 0.12), cap=(True, False)))
            if (i + (s > 0)) % 2 == 0:
                p.add(box((x - 0.16, h + 0.005, z - 0.11), (x + 0.16, h + 0.02, z + 0.11), "steel_brushed", 0.004))
            else:
                p.add(box((x - 0.1, h + 0.005, z - 0.15), (x + 0.1, h + 0.008, z + 0.13), "paper", 0.0))
    for x in (-w / 2 + 0.35, w / 2 - 0.35):
        p.add(box((x - 0.24, h, -0.17), (x + 0.24, h + 0.005, 0.17), "leather_charcoal", 0.002))
    for x in (-1.5, 1.5):
        p.add(lathe([(0.0, h), (0.07, h), (0.08, h + 0.24), (0.04, h + 0.28), (0.0, h + 0.28)], "glass_clear", 10, m=move(x, 0, 0)))
    return p


@prop
def vantage_board_chair():
    """A boardroom chair: high-backed black leather on a chrome swivel, 0.62 x 1.15 x 0.62; faces +Z."""
    p = Prop("vantage_board_chair")
    for i in range(5):
        a = 2 * math.pi * i / 5 + math.pi / 2
        x, z = 0.3 * math.cos(a), 0.3 * math.sin(a)
        p.add(tube([(0, 0.1, 0), (x, 0.06, z)], 0.02, "chrome", 6))
        p.add(sphere(0.028, "rubber", 8, 6, m=move(x, 0.03, z)))
    p.add(cyl(0.025, 0.1, 0.42, "chrome", 10, bevel=0))
    p.add(cushion((-0.26, 0.42, -0.24), (0.26, 0.52, 0.26), "leather_charcoal", 0.04))
    p.add(cushion((-0.25, 0.55, -0.33), (0.25, 1.15, -0.23), "leather_charcoal", 0.05).xf(move(0, 0.55, -0.28) @ rot_x(-10) @ move(0, -0.55, 0.28)))
    for s in (-1, 1):
        p.add(tube([(s * 0.27, 0.5, -0.18), (s * 0.28, 0.68, -0.12), (s * 0.28, 0.68, 0.14)], 0.016, "chrome", 6))
    return p


@prop
def vantage_sideboard():
    """A low walnut sideboard with a coffee service on it: two flasks, cups and a plate of
    biscuits, 2.4 x 0.8 x 0.5; front faces +Z."""
    p = Prop("vantage_sideboard")
    w, h, d = 2.4, 0.8, 0.5
    p.add(box((-w / 2, 0.06, -d / 2), (w / 2, h, d / 2), "walnut", 0.006))
    p.add(box((-w / 2 + 0.05, 0.0, -d / 2 + 0.05), (w / 2 - 0.05, 0.06, d / 2 - 0.05), "steel_black", 0.004))
    for i in range(4):
        x = -w / 2 + 0.3 + i * 0.6
        p.add(box((x - 0.28, 0.1, d / 2), (x + 0.28, h - 0.04, d / 2 + 0.008), "walnut", 0.004))
    for x in (-0.8, -0.55):
        p.add(lathe([(0.0, h), (0.08, h), (0.09, h + 0.24), (0.04, h + 0.3), (0.0, h + 0.31)], "steel_black", 12, m=move(x, 0, 0)))
    for i in range(6):
        x = -0.2 + (i % 3) * 0.16
        z = -0.08 + (i // 3) * 0.16
        p.add(cyl(0.07, h, h + 0.008, "porcelain", 12, m=move(x, 0, z), bevel=0))
        p.add(lathe([(0.0, h + 0.008), (0.035, h + 0.008), (0.042, h + 0.07), (0.0, h + 0.07)], "porcelain", 10, m=move(x, 0, z), cap=(True, False)))
    p.add(cyl(0.16, h, h + 0.015, "porcelain", 16, m=move(0.7, 0, 0), bevel=0))
    for i in range(7):
        a = i * 0.9
        p.add(cyl(0.03, h + 0.015, h + 0.028, "cake", 8, m=move(0.7 + 0.09 * math.cos(a), 0, 0.09 * math.sin(a)), bevel=0))
    return p


@prop
def vantage_exec_desk():
    """The founder's desk: a slab of walnut 2.4 x 1.0 on a black steel frame with a wide screen,
    a lamp and a folder; 0.76 tall, the visitor's side faces +Z."""
    p = Prop("vantage_exec_desk")
    w, d, h = 2.4, 1.0, 0.76
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "walnut", 0.008, 3))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        p.add(box((x - 0.03, 0.0, -d / 2 + 0.05), (x + 0.03, h - 0.05, d / 2 - 0.05), "steel_black", 0.004))
    p.add(box((-w / 2 + 0.1, h - 0.4, d / 2 - 0.12), (w / 2 - 0.1, h - 0.05, d / 2 - 0.1), "walnut", 0.004))
    monitor(p, 0.0, h, -0.3, 0.8, 0.36)
    p.add(box((-0.25, h, -0.05), (0.2, h + 0.015, 0.1), "steel_brushed", 0.003))
    p.add(box((0.55, h, -0.15), (0.85, h + 0.02, 0.2), "leather_tan", 0.004))
    p.add(tube([(-0.9, h, -0.3), (-0.9, h + 0.35, -0.3), (-0.75, h + 0.45, -0.15)], 0.01, "steel_black", 6))
    p.add(cyl(0.07, h, h + 0.015, "steel_black", 12, m=move(-0.9, 0, -0.3), bevel=0))
    p.add(lathe([(0.0, 0.0), (0.07, 0.0), (0.04, 0.08), (0.0, 0.08)], "steel_black", 12, m=move(-0.75, h + 0.37, -0.15)))
    return p


@prop
def vantage_office_desk():
    """An assistant's desk: white top 1.6 x 0.8 on steel legs with a screen, a keyboard, a phone,
    trays of paper and a modesty panel; 0.75 tall, the visitor's side faces +Z."""
    p = Prop("vantage_office_desk")
    w, d, h = 1.6, 0.8, 0.75
    p.add(box((-w / 2, h - 0.03, -d / 2), (w / 2, h, d / 2), "paint_white", 0.006))
    for x in (-w / 2 + 0.04, w / 2 - 0.04):
        for z in (-d / 2 + 0.04, d / 2 - 0.04):
            p.add(box((x - 0.02, 0.0, z - 0.02), (x + 0.02, h - 0.03, z + 0.02), "steel_brushed", 0.004))
    p.add(box((-w / 2 + 0.06, 0.3, d / 2 - 0.06), (w / 2 - 0.06, h - 0.03, d / 2 - 0.04), "paint_grey", 0.004))
    monitor(p, -0.1, h, -0.22, 0.55, 0.32)
    p.add(box((-0.33, h, 0.02), (0.13, h + 0.015, 0.16), "plastic_black", 0.003))
    p.add(box((0.4, h, -0.15), (0.62, h + 0.06, 0.05), "plastic_black", 0.01))
    for k in range(3):
        p.add(box((-0.75, h + k * 0.05, -0.32), (-0.45, h + 0.012 + k * 0.05, -0.1), "plastic_black", 0.002))
        p.add(box((-0.73, h + 0.012 + k * 0.05, -0.3), (-0.47, h + 0.02 + k * 0.05, -0.12), "paper", 0.0))
    return p


@prop
def vantage_sofa():
    """A low modern sofa in charcoal leather on a steel plinth, 2.2 x 0.75 x 0.9; faces +Z."""
    p = Prop("vantage_sofa")
    w, d = 2.2, 0.9
    p.add(box((-w / 2 + 0.05, 0.0, -d / 2 + 0.05), (w / 2 - 0.05, 0.12, d / 2 - 0.05), "steel_black", 0.004))
    p.add(cushion((-w / 2, 0.12, -d / 2), (w / 2, 0.3, d / 2), "leather_charcoal", 0.03))
    for s in (-1, 0, 1):
        if s != 0:
            p.add(cushion((s * w / 2 - (0.18 if s > 0 else 0.0), 0.3, -d / 2), (s * w / 2 + (0.0 if s > 0 else 0.18), 0.6, d / 2), "leather_charcoal", 0.05))
    for x in (-0.47, 0.47):
        p.add(cushion((x - 0.45, 0.3, -d / 2 + 0.22), (x + 0.45, 0.44, d / 2 - 0.02), "leather_charcoal", 0.05))
        p.add(cushion((x - 0.45, 0.3, -d / 2), (x + 0.45, 0.75, -d / 2 + 0.22), "leather_charcoal", 0.06))
    return p


@prop
def vantage_coffee_table():
    """A low table of dark stone, 1.2 x 0.38 x 0.6, with a few books on it."""
    p = Prop("vantage_coffee_table")
    p.add(box((-0.6, 0.32, -0.3), (0.6, 0.38, 0.3), "stone_dark", 0.01))
    p.add(box((-0.5, 0.0, -0.2), (0.5, 0.32, 0.2), "steel_black", 0.006))
    for i, mat in enumerate(("fabric_teal", "paper", "leather_tan")):
        p.add(box((-0.35, 0.38 + i * 0.03, -0.12), (0.0, 0.405 + i * 0.03, 0.14), mat, 0.004))
    return p


@prop
def vantage_screen_wall():
    """A big wall screen, 2.6 x 1.5, black-framed, showing the company's slides. Back on z = 0,
    from y 0."""
    p = Prop("vantage_screen_wall")
    p.add(box((-1.3, 0.0, 0.0), (1.3, 1.5, 0.05), "plastic_black", 0.01))
    p.add(box((-1.26, 0.04, 0.05), (1.26, 1.46, 0.052), "screen_blue", 0.0))
    return p


@prop
def vantage_pantry_counter():
    """The catering pantry's counter run: white cupboards under a steel top with a sink, a
    plumbed coffee machine and stacked cups, 2.8 x 0.92 x 0.65, and wall cupboards above
    (to 2.3 m); front faces +Z."""
    p = Prop("vantage_pantry_counter")
    w, d, h = 2.8, 0.65, 0.92
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.1, d / 2 - 0.05), "plastic_black", 0.004))
    p.add(box((-w / 2, 0.1, -d / 2), (w / 2, h - 0.04, d / 2), "paint_white", 0.004))
    for i in range(4):
        x = -w / 2 + 0.35 + i * 0.7
        p.add(box((x - 0.33, 0.12, d / 2), (x + 0.33, h - 0.06, d / 2 + 0.01), "paint_white", 0.006))
        p.add(box((x - 0.1, h - 0.14, d / 2 + 0.01), (x + 0.1, h - 0.12, d / 2 + 0.03), "steel_brushed", 0.004))
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2 + 0.02), "steel_brushed", 0.004))
    p.add(box((-1.1, h - 0.2, -0.2), (-0.6, h - 0.002, 0.18), "steel", 0.01))
    p.add(tube([(-0.85, h, -0.27), (-0.85, h + 0.3, -0.27), (-0.85, h + 0.32, -0.1)], 0.014, "chrome", 6))
    p.add(box((0.2, h, -0.3), (0.75, h + 0.6, 0.15), "steel_black", 0.02))
    p.add(box((0.25, h + 0.3, 0.15), (0.7, h + 0.5, 0.152), "screen", 0.0))
    for k in range(5):
        p.add(cyl(0.045, h + k * 0.07, h + 0.065 + k * 0.07, "porcelain", 10, m=move(1.0, 0, 0.0), bevel=0.003))
    p.add(box((-w / 2, 1.5, -d / 2), (w / 2, 2.3, -d / 2 + 0.35), "paint_white", 0.006))
    for i in range(4):
        x = -w / 2 + 0.35 + i * 0.7
        p.add(box((x - 0.33, 1.52, -d / 2 + 0.35), (x + 0.33, 2.28, -d / 2 + 0.36), "paint_white", 0.006))
    p.add(box((-w / 2 + 0.05, 1.49, -d / 2 + 0.05), (w / 2 - 0.05, 1.5, -d / 2 + 0.3), "light_warm", 0.0))
    return p


@prop
def vantage_fridge():
    """A tall steel catering fridge, 0.7 x 2.0 x 0.7; front faces +Z."""
    p = Prop("vantage_fridge")
    p.add(box((-0.35, 0.0, -0.35), (0.35, 2.0, 0.33), "steel_brushed", 0.01))
    p.add(box((-0.33, 0.05, 0.33), (0.33, 1.98, 0.35), "steel_brushed", 0.006))
    p.add(box((0.24, 0.9, 0.35), (0.27, 1.5, 0.39), "steel_black", 0.006))
    return p


@prop
def vantage_trolley():
    """A catering trolley: two steel shelves with coffee flasks, cups and saucers, 1.0 x 0.95 x
    0.55, a handle at the -x end."""
    p = Prop("vantage_trolley")
    w, d = 1.0, 0.55
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (-d / 2 + 0.03, d / 2 - 0.03):
            p.add(cyl(0.012, 0.08, 0.9, "steel_brushed", 6, m=move(x, 0, z), bevel=0))
            p.add(sphere(0.04, "rubber", 8, 6, m=move(x, 0.04, z)))
    for y in (0.3, 0.88):
        p.add(box((-w / 2, y, -d / 2), (w / 2, y + 0.02, d / 2), "steel_brushed", 0.004))
    p.add(tube([(-w / 2, 0.88, -d / 2 + 0.05), (-w / 2 - 0.1, 0.95, -d / 2 + 0.05), (-w / 2 - 0.1, 0.95, d / 2 - 0.05), (-w / 2, 0.88, d / 2 - 0.05)], 0.012, "steel_brushed", 6))
    for x in (-0.3, -0.1):
        p.add(lathe([(0.0, 0.9), (0.07, 0.9), (0.08, 1.14), (0.04, 1.2), (0.0, 1.21)], "steel_black", 12, m=move(x, 0, 0)))
    for i in range(6):
        x = 0.1 + (i % 3) * 0.13
        z = -0.1 + (i // 3) * 0.18
        p.add(lathe([(0.0, 0.9), (0.034, 0.9), (0.04, 0.96), (0.0, 0.96)], "porcelain", 10, m=move(x, 0, z), cap=(True, False)))
    for i in range(8):
        p.add(cyl(0.07, 0.32 + i * 0.012, 0.328 + i * 0.012, "porcelain", 12, m=move(0.2, 0, 0), bevel=0))
    return p


@prop
def vantage_printer():
    """An office copier, 0.6 x 1.1 x 0.62, with a paper tray and a screen; front faces +Z."""
    p = Prop("vantage_printer")
    p.add(box((-0.3, 0.0, -0.31), (0.3, 0.95, 0.31), "paint_white", 0.012))
    p.add(box((-0.3, 0.95, -0.31), (0.3, 1.08, 0.2), "paint_grey", 0.01))
    p.add(box((0.05, 0.95, 0.2), (0.28, 1.0, 0.31), "plastic_black", 0.006))
    p.add(box((0.08, 1.0, 0.24), (0.25, 1.003, 0.3), "screen", 0.0))
    for k in range(3):
        p.add(box((-0.28, 0.12 + k * 0.24, 0.31), (0.28, 0.32 + k * 0.24, 0.315), "paint_grey", 0.003))
    p.add(box((-0.25, 0.85, 0.2), (0.0, 0.86, 0.38), "paper", 0.0))
    return p


@prop
def vantage_shelves():
    """Open office shelving with binders and boxes, 1.2 x 2.0 x 0.4; front faces +Z."""
    p = Prop("vantage_shelves")
    rng = random.Random(21)
    w, h, d = 1.2, 2.0, 0.4
    for x in (-w / 2, w / 2):
        p.add(box((x - 0.02, 0.0, -d / 2), (x + 0.02, h, d / 2), "oak_pale", 0.004))
    for y in (0.05, 0.5, 0.95, 1.4, 1.85):
        p.add(box((-w / 2, y, -d / 2), (w / 2, y + 0.025, d / 2), "oak_pale", 0.004))
        if y > 1.8:
            continue
        x = -w / 2 + 0.05
        while x < w / 2 - 0.12:
            if rng.random() < 0.7:
                bw = 0.06 + rng.random() * 0.03
                mat = rng.choice(["epoxy_black", "fabric_teal", "paint_white", "fabric_grey"])
                p.add(box((x, y + 0.025, -d / 2 + 0.06), (x + bw, y + 0.35, d / 2 - 0.04), mat, 0.004))
                x += bw + 0.005
            else:
                p.add(box((x, y + 0.025, -d / 2 + 0.05), (x + 0.3, y + 0.25, d / 2 - 0.05), "cardboard", 0.006))
                x += 0.34
    return p


@prop
def vantage_ceiling_light():
    """A linear pendant light, 2.4 m long, lit below, on two wires; hangs from y = 0.6."""
    p = Prop("vantage_ceiling_light")
    p.add(box((-1.2, 0.0, -0.06), (1.2, 0.06, 0.06), "steel_black", 0.006))
    p.add(box((-1.18, -0.002, -0.045), (1.18, 0.0, 0.045), "light_panel", 0.0))
    for x in (-0.9, 0.9):
        p.add(cyl(0.003, 0.06, 0.6, "steel", 4, m=move(x, 0, 0), bevel=0))
    return p


# --- The research floor -----------------------------------------------------------------------

@prop
def vantage_lab_bench():
    """A lab bench: black epoxy top on white cabinets, a reagent shelf above on steel uprights,
    a microscope and racks of glassware. 3.0 x 1.6 x 0.8; front faces +Z."""
    p = Prop("vantage_lab_bench")
    rng = random.Random(33)
    w, d, h = 3.0, 0.8, 0.92
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.1, d / 2 - 0.05), "plastic_black", 0.004))
    p.add(box((-w / 2, 0.1, -d / 2), (w / 2, h - 0.03, d / 2 - 0.02), "lab_white", 0.006))
    for i in range(4):
        x = -w / 2 + 0.375 + i * 0.75
        p.add(box((x - 0.36, 0.12, d / 2 - 0.02), (x + 0.36, h - 0.06, d / 2), "lab_white", 0.006))
        p.add(box((x - 0.12, h - 0.13, d / 2), (x + 0.12, h - 0.11, d / 2 + 0.02), "steel_brushed", 0.004))
    p.add(box((-w / 2 - 0.02, h - 0.03, -d / 2), (w / 2 + 0.02, h, d / 2 + 0.03), "epoxy_black", 0.006))
    for x in (-w / 2 + 0.05, 0.0, w / 2 - 0.05):
        p.add(box((x - 0.02, h, -d / 2 + 0.02), (x + 0.02, 1.6, -d / 2 + 0.06), "steel_brushed", 0.004))
    p.add(box((-w / 2, 1.35, -d / 2), (w / 2, 1.38, -d / 2 + 0.3), "lab_white", 0.004))
    for i in range(14):
        x = -w / 2 + 0.15 + i * 0.2
        r = 0.03 + rng.random() * 0.025
        p.add(lathe([(0.0, 1.38), (r, 1.38), (r, 1.38 + 0.08 + rng.random() * 0.06), (r * 0.4, 1.52), (0.0, 1.52)], "glass_clear" if i % 3 else "bottle_amber", 8, m=move(x, 0, -d / 2 + 0.15)))
    # The microscope.
    mx = -0.8
    p.add(box((mx - 0.12, h, -0.15), (mx + 0.12, h + 0.03, 0.12), "lab_white", 0.008))
    p.add(box((mx - 0.04, h + 0.03, -0.15), (mx + 0.04, h + 0.35, -0.08), "lab_white", 0.008))
    p.add(cyl(0.03, 0.0, 0.18, "steel_black", 10, m=move(mx, h + 0.22, -0.02) @ rot_x(-30), bevel=0))
    p.add(box((mx - 0.08, h + 0.12, -0.08), (mx + 0.08, h + 0.14, 0.06), "steel_black", 0.004))
    for k in range(2):
        p.add(cyl(0.012, 0.0, 0.08, "steel_black", 8, m=move(mx - 0.02 + k * 0.04, h + 0.35, 0.0) @ rot_x(-40), bevel=0))
    # A tray of stones under loupes, and a lamp.
    p.add(box((0.4, h, -0.1), (0.8, h + 0.02, 0.15), "velvet_black", 0.003))
    for k in range(5):
        p.add(octa(0.012, 0.02, "glass_clear", m=move(0.48 + k * 0.07, h + 0.03, 0.02)))
    p.add(tube([(1.2, h, -0.3), (1.2, h + 0.4, -0.3), (1.0, h + 0.5, -0.05)], 0.01, "steel_black", 6))
    p.add(lathe([(0.0, 0.0), (0.06, 0.0), (0.035, 0.07), (0.0, 0.07)], "steel_black", 12, m=move(1.0, h + 0.42, -0.05)))
    return p


@prop
def vantage_fume_hood():
    """A fume hood against the wall: a white cabinet 1.5 x 2.4 x 0.85 with a glass sash, a lit
    working space and a black epoxy top inside; front faces +Z."""
    p = Prop("vantage_fume_hood")
    w, h, d = 1.5, 2.4, 0.85
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.9, d / 2), "lab_white", 0.006))
    p.add(box((-w / 2, 0.88, -d / 2), (w / 2, 0.92, d / 2), "epoxy_black", 0.004))
    for x in (-w / 2, w / 2 - 0.08):
        p.add(box((x, 0.92, -d / 2), (x + 0.08, h, d / 2), "lab_white", 0.006))
    p.add(box((-w / 2, 0.92, -d / 2), (w / 2, h, -d / 2 + 0.05), "lab_white", 0.004))
    p.add(box((-w / 2, 1.85, -d / 2), (w / 2, h, d / 2), "lab_white", 0.006))
    p.add(box((-w / 2 + 0.1, 1.83, -d / 2 + 0.1), (w / 2 - 0.1, 1.85, d / 2 - 0.1), "light_panel", 0.0))
    p.add(box((-w / 2 + 0.08, 1.15, d / 2 - 0.04), (w / 2 - 0.08, 1.83, d / 2 - 0.03), "glass_clear", 0.0))
    p.add(box((-w / 2 + 0.08, 1.12, d / 2 - 0.05), (w / 2 - 0.08, 1.16, d / 2 - 0.02), "steel_brushed", 0.004))
    p.add(box((w / 2 - 0.3, 2.0, d / 2), (w / 2 - 0.12, 2.1, d / 2 + 0.01), "led_green", 0.0))
    return p


@prop
def vantage_scaife():
    """The gemcutter's scaife: a cast iron bench 1.6 x 0.85 x 0.8 with its horizontal wheel, a
    dop arm, a lamp on a long arm and a loupe; front faces +Z."""
    p = Prop("vantage_scaife")
    w, d, h = 1.6, 0.8, 0.85
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        p.add(box((x - 0.05, 0.0, -d / 2 + 0.05), (x + 0.05, h - 0.05, d / 2 - 0.05), "cast_iron", 0.01))
    p.add(box((-w / 2 + 0.05, 0.15, -0.05), (w / 2 - 0.05, 0.22, 0.05), "cast_iron", 0.008))
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "cast_iron", 0.01))
    p.add(cyl(0.3, h, h + 0.04, "steel", 32, m=move(-0.1, 0, 0.0), bevel=0.004))
    p.add(cyl(0.05, h + 0.04, h + 0.06, "chrome", 12, m=move(-0.1, 0, 0.0), bevel=0))
    p.add(box((-0.1 - 0.35, h, -0.38), (-0.1 + 0.35, h + 0.06, -0.33), "cast_iron", 0.006))
    p.add(box((0.35, h, 0.0), (0.45, h + 0.18, 0.1), "steel_black", 0.006))
    p.add(tube([(0.4, h + 0.15, 0.05), (0.1, h + 0.12, 0.05), (-0.1, h + 0.06, 0.02)], 0.012, "chrome", 6))
    p.add(tube([(0.65, h, -0.3), (0.65, h + 0.55, -0.3), (0.2, h + 0.7, 0.0)], 0.012, "steel_black", 6))
    p.add(lathe([(0.0, 0.0), (0.08, 0.0), (0.04, 0.09), (0.0, 0.09)], "steel_black", 12, m=move(0.2, h + 0.62, 0.0)))
    p.add(cyl(0.06, -0.002, 0.0, "light_warm", 12, m=move(0.2, h + 0.62, 0.0), bevel=0))
    p.add(cyl(0.025, h, h + 0.03, "steel_black", 10, m=move(0.6, 0, 0.25), bevel=0))
    return p


@prop
def vantage_rose_plinth():
    """The Rose's plinth: a white column 0.6 square and 1.0 tall with a black velvet cradle under
    a glass dome; the Rose itself is `vantage_rose`, set on the cradle at y = 1.06."""
    p = Prop("vantage_rose_plinth")
    p.add(box((-0.3, 0.0, -0.3), (0.3, 0.05, 0.3), "stone_dark", 0.006))
    p.add(box((-0.27, 0.05, -0.27), (0.27, 0.98, 0.27), "lab_white", 0.008))
    p.add(box((-0.3, 0.98, -0.3), (0.3, 1.0, 0.3), "stone_dark", 0.004))
    p.add(lathe([(0.0, 1.0), (0.12, 1.0), (0.12, 1.02), (0.08, 1.06), (0.0, 1.06)], "velvet_black", 16))
    p.add(lathe([(0.17, 1.0), (0.17, 1.22), (0.14, 1.32), (0.08, 1.37), (0.0, 1.385)], "glass_dome", 20, cap=(False, True)))
    p.add(cyl(0.18, 1.0, 1.012, "steel_brushed", 20, bevel=0))
    p.add(box((-0.08, 0.6, 0.27), (0.08, 0.66, 0.272), "steel_brushed", 0.001))
    return p


@prop
def vantage_rose():
    """The Rose: a pink diamond the size of a walnut, sitting on y = 0 (the plinth's cradle is at
    1.06), so the game can hide it when it's taken."""
    p = Prop("vantage_rose")
    p.add(octa(0.028, 0.05, "rose_gem", m=move(0, 0.034, 0) @ rot_y(20)))
    p.add(octa(0.026, 0.045, "rose_gem", m=move(0, 0.034, 0) @ rot_y(65)))
    return p


@prop
def vantage_safe():
    """A floor safe: grey steel 0.8 x 1.2 x 0.7 with a dial, a wheel handle and a keypad; front
    faces +Z."""
    p = Prop("vantage_safe")
    p.add(box((-0.4, 0.0, -0.35), (0.4, 1.2, 0.33), "paint_grey", 0.02))
    p.add(box((-0.36, 0.05, 0.33), (0.36, 1.15, 0.36), "paint_grey", 0.01))
    p.add(cyl(0.07, 0.0, 0.03, "chrome", 20, m=move(-0.1, 0.75, 0.36) @ rot_x(90), bevel=0.004))
    for k in range(3):
        a = k * 2 * math.pi / 3
        p.add(tube([(0.15, 0.6, 0.38), (0.15 + 0.1 * math.cos(a), 0.6 + 0.1 * math.sin(a), 0.38)], 0.012, "chrome", 6))
    p.add(box((0.05, 0.85, 0.36), (0.25, 1.05, 0.37), "plastic_black", 0.003))
    p.add(box((0.12, 1.02, 0.37), (0.18, 1.03, 0.372), "led_red", 0.0))
    return p


@prop
def vantage_scanner():
    """A walk-through scanner arch: two grey columns and a head, 1.3 wide and 2.3 tall, the way
    through 0.9 wide along z, with a light bar."""
    p = Prop("vantage_scanner")
    for s in (-1, 1):
        p.add(box((s * 0.45, 0.0, -0.3), (s * 0.65, 2.1, 0.3), "paint_grey", 0.02))
        p.add(box((s * 0.45 - 0.004, 0.8, -0.2), (s * 0.45 + 0.004, 1.6, 0.2), "led_green", 0.0))
    p.add(box((-0.65, 2.1, -0.3), (0.65, 2.3, 0.3), "paint_grey", 0.02))
    p.add(box((-0.2, 2.15, 0.3), (0.2, 2.25, 0.31), "led_green", 0.0))
    return p


@prop
def vantage_check_desk():
    """Halberd's checkpoint desk: grey steel and black glass, 1.8 x 1.1 x 0.75, with two camera
    screens, the floor's scanner screen and a radio charger; the visitors' side faces +Z."""
    p = Prop("vantage_check_desk")
    w, h, d = 1.8, 1.1, 0.75
    p.add(box((-w / 2, 0.0, -d / 2 + 0.1), (w / 2, h - 0.04, d / 2), "paint_grey", 0.01))
    p.add(box((-w / 2 - 0.03, h - 0.04, 0.05), (w / 2 + 0.03, h, d / 2 + 0.03), "epoxy_black", 0.006))
    p.add(box((-w / 2, 0.72, -d / 2), (w / 2, 0.76, 0.05), "epoxy_black", 0.004))
    for x in (-0.5, 0.05):
        monitor(p, x, 0.76, -0.25, 0.48, 0.3)
    monitor(p, 0.6, 0.76, -0.22, 0.32, 0.22, -0.3, "led_green")
    p.add(box((-0.85, 0.76, -0.1), (-0.7, 0.82, 0.02), "plastic_black", 0.006))
    p.add(box((-0.8, 0.82, -0.08), (-0.76, 1.0, -0.04), "plastic_black", 0.004))
    p.add(box((-0.3, 0.76, -0.05), (0.15, 0.775, 0.06), "plastic_black", 0.003))
    return p


@prop
def vantage_cleaning_cart():
    """A cleaner's cart: a grey frame with a bin bag, buckets, sprays, a mop and folded cloths,
    1.1 x 1.1 x 0.5; long along x."""
    p = Prop("vantage_cleaning_cart")
    w, d = 1.1, 0.5
    p.add(box((-w / 2, 0.08, -d / 2), (w / 2, 0.12, d / 2), "paint_grey", 0.006))
    p.add(box((-w / 2, 0.9, -d / 2), (0.1, 0.94, d / 2), "paint_grey", 0.006))
    for x in (-w / 2 + 0.03, 0.07):
        for z in (-d / 2 + 0.03, d / 2 - 0.03):
            p.add(cyl(0.015, 0.12, 0.92, "paint_grey", 6, m=move(x, 0, z), bevel=0))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        for z in (-d / 2 + 0.05, d / 2 - 0.05):
            p.add(sphere(0.04, "rubber", 8, 6, m=move(x, 0.04, z)))
    p.add(box((0.12, 0.12, -d / 2 + 0.02), (w / 2, 0.85, d / 2 - 0.02), "plastic_black", 0.03))
    for x, mat in ((-0.35, "led_amber"), (-0.15, "fabric_teal")):
        p.add(lathe([(0.0, 0.12), (0.1, 0.12), (0.12, 0.35), (0.0, 0.35)], "paint_grey" if mat == "led_amber" else "plastic_black", 12, m=move(x, 0, 0)))
    for k in range(3):
        p.add(lathe([(0.0, 0.94), (0.035, 0.94), (0.035, 1.12), (0.015, 1.18), (0.0, 1.18)], ("fabric_teal", "paint_white", "led_amber")[k], 8, m=move(-0.42 + k * 0.1, 0, 0.1)))
    p.add(box((-0.2, 0.94, -0.18), (0.05, 1.0, 0.0), "fabric_teal", 0.01))
    p.add(tube([(0.05, 0.12, -0.15), (0.0, 1.6, -0.15)], 0.012, "steel_brushed", 6))
    return p


@prop
def vantage_lab_stool():
    """A lab stool: a round black seat on a chrome column and a five-star base, 0.45 tall-ish."""
    p = Prop("vantage_lab_stool")
    for i in range(5):
        a = 2 * math.pi * i / 5
        p.add(tube([(0, 0.08, 0), (0.25 * math.cos(a), 0.05, 0.25 * math.sin(a))], 0.018, "plastic_black", 6))
    p.add(cyl(0.022, 0.08, 0.6, "chrome", 10, bevel=0))
    p.add(cyl(0.2, 0.6, 0.66, "leather_charcoal", 18, bevel=0.02))
    p.add(lathe([(0.2, 0.3), (0.22, 0.3), (0.22, 0.31), (0.2, 0.31)], "chrome", 16, cap=(False, False)))
    return p


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if "--list" in args:
        for n, fn in PROPS.items():
            print("%-24s %s" % (n, (fn.__doc__ or "").strip().split("\n")[0]))
        return
    os.makedirs(OUT, exist_ok=True)
    want = args or list(PROPS)
    for name in want:
        if name not in PROPS:
            print("no prop called", name)
            continue
        props.export(PROPS[name](), os.path.join(OUT, name + ".glb"))


if __name__ == "__main__":
    main()
