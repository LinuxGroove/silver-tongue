"""Builds Mae's house: the laundrette's machines and counter, the back room where every job
was briefed, the flat upstairs (the big old sofa, the records, the kitchen, Mae's study and
its strongroom), the roof terrace, the yard, and the street's cars. Each prop is written as a
GLB to assets/models/mae/, named mae_*, where `Kit` finds it by name.

Run from the repository root with a Python that has the `bpy` module:

    python tools/blender/mae_props.py [prop ...]

It uses tools/blender/props.py's shapes and conventions: Godot's axes, metres, floor props on
y = 0 centred on their footprint and facing +Z, wall props with their back on z = 0, hanging
props from y = their height down to y = 0, door leaves hinged at the origin spanning -x.
Warm, cluttered and lived in: the opposite of the hotel.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import props  # noqa: E402
from props import (Prop, box, cyl, lathe, tube, prism, sphere, grid_sheet, move, rot_x, rot_y, rot_z,  # noqa: E402
                   scale, cushion, turned_leg, face_box, leaf_base, panel_moulding, export)

OUT = os.path.join(props.ROOT, "assets", "models", "mae")

props.MATERIALS.update({
    "enamel_white": ("#ebe8e0", 0.05, 0.28, {}),
    "enamel_cream": ("#e6dcc2", 0.05, 0.3, {}),
    "enamel_mint": ("#a9d2c2", 0.05, 0.3, {}),
    "steel_brushed": ("#a9adb0", 1.0, 0.38, {}),
    "laminate_teal": ("#3b7a74", 0.0, 0.35, {}),
    "laminate_cream": ("#e2d6b8", 0.0, 0.4, {}),
    "formica_red": ("#a8352c", 0.0, 0.3, {}),
    "plastic_blue": ("#2f6fb0", 0.0, 0.45, {}),
    "plastic_orange": ("#d0702a", 0.0, 0.45, {}),
    "plastic_cream": ("#ddd3bc", 0.0, 0.45, {}),
    "velvet_rust": ("#8a3c1f", 0.0, 0.85, {}),
    "velvet_teal": ("#1f5552", 0.0, 0.85, {}),
    "velvet_mustard": ("#a37a24", 0.0, 0.85, {}),
    "leather_brown": ("#5a3420", 0.0, 0.5, {}),
    "leather_green": ("#1f3a2a", 0.0, 0.45, {}),
    "knit_red": ("#9a2f2a", 0.0, 0.95, {}),
    "knit_cream": ("#d8ccb0", 0.0, 0.95, {}),
    "knit_mustard": ("#b5862f", 0.0, 0.95, {}),
    "tile_green": ("#2c5a4c", 0.0, 0.2, {}),
    "tile_cream": ("#d9cdb0", 0.0, 0.22, {}),
    "vinyl_black": ("#0c0c0d", 0.0, 0.28, {}),
    "sleeve_red": ("#a0302a", 0.0, 0.6, {}),
    "sleeve_blue": ("#2c4c7a", 0.0, 0.6, {}),
    "sleeve_yellow": ("#d6a832", 0.0, 0.6, {}),
    "sleeve_white": ("#e6e1d4", 0.0, 0.6, {}),
    "sleeve_green": ("#3c6a3e", 0.0, 0.6, {}),
    "sleeve_black": ("#1c1a1a", 0.0, 0.6, {}),
    "speaker_cloth": ("#242120", 0.0, 0.95, {}),
    "pink_gem": ("#ff6aa8", 0.0, 0.04, {"emit": "#ff3f8c", "strength": 0.9}),
    "velvet_black": ("#141214", 0.0, 0.9, {}),
    "paint_door_green": ("#29463a", 0.15, 0.42, {}),
    "paint_door_cream": ("#e2d8c2", 0.05, 0.45, {}),
    "paint_door_red": ("#7a2b22", 0.15, 0.42, {}),
    "paint_iron": ("#1c2123", 0.5, 0.5, {}),
    "car_paint": ("#d8cfb6", 0.4, 0.3, {}),
    "glass_car": ("#1a2226", 0.2, 0.05, {"alpha": 0.7}),
    "tail_red": ("#6a0c0c", 0.0, 0.3, {}),
    "headlamp": ("#e8e6dc", 0.6, 0.1, {}),
    "string_bulb": ("#ffe2a8", 0.0, 0.3, {"emit": "#ffc674", "strength": 5.0}),
    "fluoro": ("#f2f6ff", 0.0, 0.3, {"emit": "#e4eeff", "strength": 5.0}),
    "lamp_green": ("#2a6a46", 0.0, 0.15, {"emit": "#5fbf7a", "strength": 0.6}),
    "lampshade_warm": ("#e9c98e", 0.0, 0.85, {"emit": "#ffbe6a", "strength": 0.9}),
    "brick_red": ("#7c3f2c", 0.0, 0.9, {}),
    "terracotta": ("#a95a32", 0.0, 0.85, {}),
    "blueprint": ("#2e5684", 0.0, 0.8, {}),
    "photo": ("#bfae93", 0.0, 0.5, {}),
    "cloth_blue": ("#3d5a80", 0.0, 0.95, {}),
    "cloth_red": ("#a23b3b", 0.0, 0.95, {}),
    "cloth_yellow": ("#d9b44a", 0.0, 0.95, {}),
    "cloth_white": ("#e8e6e0", 0.0, 0.95, {}),
    "cloth_check": ("#c8b48a", 0.0, 0.95, {}),
    "grating": ("#2b3032", 0.6, 0.55, {}),
    "food_bread": ("#c89a5a", 0.0, 0.8, {}),
    "food_cake": ("#efe0c8", 0.0, 0.7, {}),
    "food_jam": ("#8a1a2a", 0.0, 0.4, {}),
    "food_green": ("#5a8a3a", 0.0, 0.7, {}),
    "stew": ("#6a3a1e", 0.0, 0.4, {}),
    "copper": ("#b06a3e", 1.0, 0.32, {}),
    "card_cream": ("#efe6d0", 0.0, 0.7, {}),
    "card_black": ("#18171a", 0.0, 0.5, {}),
    "screen_dim": ("#1e2a30", 0.0, 0.2, {"emit": "#6a8ca0", "strength": 0.8}),
    "led_blue": ("#3a7aff", 0.0, 0.4, {"emit": "#3a6aff", "strength": 3.0}),
})

PROPS = {}


def prop(fn):
    PROPS[fn.__name__] = fn
    return fn


# --- Shared pieces -------------------------------------------------------------------------------

def rng_for(name):
    return random.Random(sum(ord(c) for c in name))


def leg(x, z, h, s, mat):
    """A square leg standing at (x, z), `s` across."""
    return box((x - s / 2, 0.0, z - s / 2), (x + s / 2, h, z + s / 2), mat, 0.004)


def book_row(p, x0, x1, y, z0, z1, rng, mats=None, lean=True):
    """Books standing on a shelf from x0 to x1, spines facing +z at z1."""
    mats = mats or ["sleeve_red", "sleeve_blue", "sleeve_green", "sleeve_yellow", "card_cream", "leather_brown", "sleeve_black"]
    x = x0
    while x < x1 - 0.03:
        w = rng.uniform(0.022, 0.05)
        h = rng.uniform(0.17, 0.28)
        d = rng.uniform(0.15, min(0.24, z1 - z0))
        if x + w > x1:
            break
        p.add(box((x, y, z1 - d), (x + w, y + h, z1), rng.choice(mats), 0.003))
        x += w + 0.002
    return p


def records_row(p, x0, x1, y, z0, z1, rng):
    """LP sleeves standing on a shelf, their spines facing +z."""
    mats = ["sleeve_red", "sleeve_blue", "sleeve_yellow", "sleeve_white", "sleeve_green", "sleeve_black"]
    x = x0
    while x < x1 - 0.01:
        w = rng.uniform(0.004, 0.009)
        p.add(box((x, y, z0), (x + w, y + 0.31, z1), rng.choice(mats), 0.0))
        x += w + 0.0015
    return p


def glass_at(x, y, z, kind="wine"):
    """A glass standing at (x, y, z)."""
    if kind == "wine":
        return [lathe([(0.03, 0.0), (0.03, 0.004), (0.004, 0.01), (0.004, 0.09), (0.03, 0.12), (0.035, 0.16), (0.034, 0.2)], "glass", 10, m=move(x, y, z), cap=(True, False))]
    if kind == "tumbler":
        return [lathe([(0.03, 0.0), (0.035, 0.09)], "glass", 10, m=move(x, y, z), cap=(True, False))]
    return [lathe([(0.022, 0.0), (0.022, 0.004), (0.003, 0.01), (0.003, 0.1), (0.022, 0.13), (0.024, 0.22)], "glass", 8, m=move(x, y, z), cap=(True, False))]


def bottle_at(x, y, z, mat, h=0.3, r=0.037):
    return [lathe([(r, 0.0), (r, h * 0.62), (r * 0.4, h * 0.78), (r * 0.32, h), (r * 0.35, h + 0.01)], mat, 10, m=move(x, y, z)),
            lathe([(r * 1.01, h * 0.25), (r * 1.01, h * 0.5)], "label_cream", 10, m=move(x, y, z), cap=(False, False))]


def mug_at(x, y, z, mat):
    return [lathe([(0.038, 0.0), (0.042, 0.095)], mat, 12, m=move(x, y, z), cap=(True, False)),
            tube([(x + 0.04, y + 0.075, z), (x + 0.065, y + 0.07, z), (x + 0.065, y + 0.025, z), (x + 0.04, y + 0.02, z)], 0.007, mat, 5)]


def panel_leaf(p, w, h, t, mat, panels, knob_mat="brass", glass=None):
    """A door leaf hinged at the origin spanning -x: stiles and rails round `panels` (x0, y0,
    x1, y1) that are raised (mat) or glazed (glass), and a knob on each face."""
    leaf_base(p, w, h, t, mat)
    for (x0, y0, x1, y1) in panels:
        for zs in (-1, 1):
            z = zs * t / 2
            if glass:
                continue
            p.add(face_box(-w + x0 + 0.03, y0 + 0.03, -w + x1 - 0.03, y1 - 0.03, z, 0.008, zs, mat, 0.006))
            p.add(panel_moulding(-w + x0, y0, -w + x1, y1, z if zs > 0 else z - 0.01, 0.018, 0.01, mat))
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(cyl(0.028, 0, 0.012, knob_mat, 8, m=move(-w + 0.08, 1.0, z) @ rot_x(90 * zs)))
        p.add(sphere(0.03, knob_mat, 10, 6, m=move(-w + 0.08, 1.0, z + zs * 0.06)))
        p.add(cyl(0.008, 0, 0.05, knob_mat, 6, m=move(-w + 0.08, 1.0, z) @ rot_x(90 * zs)))
    return p


# --- The laundrette ----------------------------------------------------------------------------

@prop
def mae_washer():
    """A front-loading coin washer in white enamel: a chrome porthole, a control strip and a coin
    slot. 0.68 x 0.9 x 0.64 m."""
    p = Prop("mae_washer")
    w, h, d = 0.68, 0.9, 0.64
    p.add(box((-w / 2, 0.04, -d / 2), (w / 2, h - 0.12, d / 2), "enamel_white", 0.02, 3))
    p.add(box((-w / 2 + 0.01, 0.0, -d / 2 + 0.02), (w / 2 - 0.01, 0.06, d / 2 - 0.04), "rubber", 0.004))
    p.add(box((-w / 2, h - 0.12, -d / 2), (w / 2, h, d / 2 - 0.08), "enamel_white", 0.015, 3))
    # The control strip, sloping toward you.
    p.add(prism([(d / 2 - 0.08, h - 0.12), (d / 2, h - 0.12), (d / 2 - 0.08, h)], w - 0.01, "steel_brushed", plane="zy", bevel=0.004))
    for i, x in enumerate((-0.22, -0.08, 0.12)):
        p.add(cyl(0.022, 0, 0.025, "plastic_black", 10, m=move(x, h - 0.07, d / 2 - 0.035) @ rot_x(56)))
    p.add(box((0.2, h - 0.1, d / 2 - 0.06), (0.3, h - 0.035, d / 2 - 0.02), "steel", 0.003).xf(move(0, 0, 0)))
    # The porthole.
    zf = d / 2
    p.add(lathe([(0.2, 0.0), (0.205, 0.02), (0.17, 0.04), (0.15, 0.035)], "chrome", 24, m=move(0, 0.42, zf) @ rot_x(90), cap=(False, False)))
    p.add(cyl(0.15, -0.005, 0.02, "glass_dark", 20, m=move(0, 0.42, zf + 0.01) @ rot_x(90), bevel=0.0))
    p.add(box((0.16, 0.38, zf), (0.2, 0.46, zf + 0.04), "plastic_black", 0.008))
    # Clothes going round behind the glass.
    p.add(sphere(0.11, "cloth_blue", 8, 5, m=move(-0.03, 0.36, zf - 0.08), squash=0.6))
    p.add(sphere(0.08, "cloth_red", 8, 5, m=move(0.06, 0.34, zf - 0.1), squash=0.6))
    # The coin box.
    p.add(box((-w / 2 + 0.06, 0.1, zf), (-w / 2 + 0.2, 0.2, zf + 0.012), "steel", 0.003))
    return p


@prop
def mae_dryer():
    """A big stainless double tumble dryer, two drums one over the other, with round glass doors
    and a coin box. 0.8 x 1.95 x 0.82 m."""
    p = Prop("mae_dryer")
    w, h, d = 0.8, 1.95, 0.82
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "steel_brushed", 0.012, 2))
    p.add(box((-w / 2 + 0.02, 0.0, d / 2), (w / 2 - 0.02, 0.06, d / 2 + 0.005), "rubber", 0.002))
    zf = d / 2
    for y in (0.6, 1.38):
        p.add(lathe([(0.29, 0.0), (0.3, 0.02), (0.27, 0.05), (0.24, 0.045)], "chrome", 24, m=move(0, y, zf) @ rot_x(90), cap=(False, False)))
        p.add(cyl(0.245, -0.005, 0.03, "glass_dark", 24, m=move(0, y, zf + 0.01) @ rot_x(90), bevel=0.0))
        p.add(box((0.25, y - 0.05, zf), (0.31, y + 0.05, zf + 0.05), "plastic_black", 0.01))
    p.add(sphere(0.18, "cloth_white", 8, 5, m=move(0.02, 0.5, zf - 0.15), squash=0.5))
    p.add(sphere(0.14, "cloth_yellow", 8, 5, m=move(-0.06, 1.26, zf - 0.15), squash=0.5))
    # The control panel along the top: a lit display, the coin slot.
    p.add(box((-w / 2 + 0.04, 1.72, zf), (w / 2 - 0.04, 1.9, zf + 0.012), "plastic_black", 0.004))
    p.add(box((-0.3, 1.77, zf + 0.012), (-0.1, 1.85, zf + 0.016), "screen_dim", 0.0))
    p.add(box((0.15, 1.76, zf + 0.012), (0.25, 1.86, zf + 0.03), "steel", 0.003))
    p.add(box((-w / 2 + 0.08, 0.08, zf), (-w / 2 + 0.22, 0.2, zf + 0.012), "steel", 0.003))
    return p


@prop
def mae_folding_table():
    """The laundrette's folding table: teal laminate on chrome legs, a shelf under it with a
    basket of someone's washing. 2.0 x 0.9 x 0.8 m."""
    p = Prop("mae_folding_table")
    w, h, d = 2.0, 0.9, 0.8
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2), "laminate_teal", 0.01, 3))
    p.add(box((-w / 2 - 0.005, h - 0.045, -d / 2 - 0.005), (w / 2 + 0.005, h - 0.03, d / 2 + 0.005), "chrome", 0.003))
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        for z in (-d / 2 + 0.06, d / 2 - 0.06):
            p.add(cyl(0.02, 0.0, h - 0.04, "chrome", 8, m=move(x, 0, z)))
    p.add(box((-w / 2 + 0.06, 0.2, -d / 2 + 0.06), (w / 2 - 0.06, 0.22, d / 2 - 0.06), "steel_brushed", 0.003))
    # Folded washing on top, and a basket on the shelf.
    rng = rng_for("fold")
    for i, mat in enumerate(("cloth_white", "cloth_blue", "cloth_check", "cloth_white")):
        x = -0.7 + i * 0.32
        hh = rng.uniform(0.04, 0.09)
        p.add(box((x - 0.14, h, -0.15), (x + 0.14, h + hh, 0.15), mat, 0.02, 2))
    p.add(_basket(0.4, 0.22, 0.0, "plastic_blue"))
    return p


def _basket(x, y, z, mat, w=0.55, d=0.38, h=0.3):
    parts = [box((x - w / 2, y, z - d / 2), (x + w / 2, y + 0.02, z + d / 2), mat, 0.01)]
    for sx in (-1, 1):
        parts.append(box((x + sx * w / 2 - 0.012, y, z - d / 2), (x + sx * w / 2 + 0.012 * (sx < 0) - 0.0 * (sx > 0), y + h, z + d / 2), mat, 0.005).xf(move(0 if sx < 0 else 0, 0, 0)))
    for sz in (-1, 1):
        parts.append(box((x - w / 2, y, z + sz * d / 2 - 0.012), (x + w / 2, y + h, z + sz * d / 2), mat, 0.005))
    parts.append(sphere(0.2, "cloth_red", 8, 5, m=move(x - 0.08, y + h * 0.7, z), squash=0.5))
    parts.append(sphere(0.17, "cloth_white", 8, 5, m=move(x + 0.1, y + h * 0.75, z + 0.04), squash=0.5))
    return parts


@prop
def mae_basket():
    """A plastic laundry basket heaped with washing. 0.55 x 0.42 x 0.38 m."""
    p = Prop("mae_basket")
    p.add(_basket(0.0, 0.0, 0.0, "plastic_orange"))
    return p


@prop
def mae_counter():
    """The laundrette's counter: cream laminate, an old till, a bell to ring, a jar of change and
    the ticket book; the customer's side faces +Z. 1.8 x 1.05 x 0.65 m."""
    p = Prop("mae_counter")
    w, h, d = 1.8, 1.0, 0.65
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h - 0.04, d / 2 - 0.04), "paint_door_green", 0.008))
    p.add(box((-w / 2 - 0.03, h - 0.04, -d / 2), (w / 2 + 0.03, h, d / 2 + 0.02), "laminate_cream", 0.008))
    for x in (-0.6, 0.0, 0.6):
        p.add(face_box(x - 0.26, 0.12, x + 0.26, 0.82, d / 2 - 0.04, 0.012, 1, "paint_door_green", 0.006))
    p.add(box((-w / 2, 0.0, d / 2 - 0.06), (w / 2, 0.08, d / 2 - 0.02), "rubber", 0.003))
    # The till.
    p.add(box((0.3, h, -0.22), (0.66, h + 0.12, 0.1), "cast_iron", 0.01))
    p.add(prism([(-0.22, h + 0.12), (0.1, h + 0.12), (-0.22, h + 0.26)], 0.36, "cast_iron", plane="zy", m=move(0.48, 0, 0), bevel=0.008))
    for i in range(3):
        for j in range(4):
            p.add(cyl(0.012, 0, 0.012, "plastic_cream", 6, m=move(0.36 + j * 0.08, h + 0.17 + i * 0.022, -0.02 - i * 0.05) @ rot_x(60)))
    # The bell, the jar, the ticket book.
    p.add(lathe([(0.05, 0.0), (0.05, 0.01), (0.012, 0.015), (0.04, 0.02), (0.045, 0.05), (0.02, 0.065), (0.0, 0.07)], "brass", 12, m=move(-0.1, h, 0.15)))
    p.add(cyl(0.006, 0.07, 0.085, "brass", 6, m=move(-0.1, h, 0.15)))
    p.add(lathe([(0.06, 0.0), (0.065, 0.14), (0.05, 0.16)], "glass", 12, m=move(-0.4, h, -0.05), cap=(True, False)))
    p.add(cyl(0.055, 0.0, 0.06, "brass_aged", 10, m=move(-0.4, h, -0.05)))
    p.add(box((-0.75, h, -0.1), (-0.55, h + 0.02, 0.06), "paper", 0.003))
    p.add(box((-0.75, h + 0.02, -0.1), (-0.55, h + 0.025, 0.06), "sleeve_red", 0.001))
    return p


@prop
def mae_bench():
    """A slatted wooden bench on iron legs, for waiting on a wash. 1.6 x 0.46 x 0.42 m."""
    p = Prop("mae_bench")
    w, h, d = 1.6, 0.46, 0.42
    for i in range(4):
        z = -d / 2 + 0.03 + i * (d - 0.06) / 3.4
        p.add(box((-w / 2, h - 0.035, z), (w / 2, h, z + 0.08), "oak", 0.006))
    for x in (-w / 2 + 0.12, w / 2 - 0.12):
        p.add(box((x - 0.025, 0.0, -d / 2 + 0.02), (x + 0.025, h - 0.035, -d / 2 + 0.06), "cast_iron", 0.004))
        p.add(box((x - 0.025, 0.0, d / 2 - 0.06), (x + 0.025, h - 0.035, d / 2 - 0.02), "cast_iron", 0.004))
        p.add(box((x - 0.025, h - 0.07, -d / 2 + 0.02), (x + 0.025, h - 0.035, d / 2 - 0.02), "cast_iron", 0.004))
    p.add(box((-0.6, h, -0.05), (-0.25, h + 0.02, 0.18), "paper", 0.003).xf(rot_y(0)))
    return p


@prop
def mae_waiting_chairs():
    """Three moulded plastic chairs joined on a steel beam, the laundrette's waiting seats.
    1.6 x 0.8 x 0.55 m."""
    p = Prop("mae_waiting_chairs")
    p.add(box((-0.78, 0.36, -0.03), (0.78, 0.4, 0.03), "steel", 0.006))
    for x in (-0.65, 0.65):
        p.add(box((x - 0.02, 0.0, -0.2), (x + 0.02, 0.38, -0.16), "steel", 0.004))
        p.add(box((x - 0.02, 0.0, 0.16), (x + 0.02, 0.38, 0.2), "steel", 0.004))
        p.add(box((x - 0.02, 0.0, -0.22), (x + 0.02, 0.02, 0.22), "steel", 0.004))
    for i, mat in enumerate(("plastic_orange", "plastic_orange", "plastic_orange")):
        x = -0.52 + i * 0.52
        p.add(box((x - 0.22, 0.4, -0.2), (x + 0.22, 0.44, 0.24), mat, 0.02, 3))
        p.add(box((x - 0.21, 0.44, -0.24), (x + 0.21, 0.82, -0.2), mat, 0.02, 3).xf(move(0, 0, 0)))
    return p


@prop
def mae_vending():
    """A soap powder machine: boxes behind glass, a coin slot, a tray. 0.7 x 1.75 x 0.5 m."""
    p = Prop("mae_vending")
    w, h, d = 0.7, 1.75, 0.5
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "paint_door_red", 0.01))
    zf = d / 2
    p.add(box((-w / 2 + 0.05, 0.75, zf - 0.04), (w / 2 - 0.18, h - 0.1, zf - 0.03), "steel", 0.0))
    for i in range(4):
        y = 0.8 + i * 0.2
        for j in range(3):
            x = -w / 2 + 0.1 + j * 0.13
            p.add(box((x - 0.05, y, zf - 0.2), (x + 0.05, y + 0.14, zf - 0.08), ["sleeve_yellow", "sleeve_blue", "cloth_red"][(i + j) % 3], 0.003))
    p.add(box((-w / 2 + 0.05, 0.75, zf - 0.005), (w / 2 - 0.18, h - 0.1, zf), "glass", 0.0))
    p.add(box((w / 2 - 0.16, 0.9, zf), (w / 2 - 0.04, 1.4, zf + 0.012), "steel", 0.003))
    p.add(box((-w / 2 + 0.1, 0.25, zf - 0.02), (w / 2 - 0.1, 0.45, zf + 0.02), "cast_iron", 0.006))
    return p


@prop
def mae_shop_door():
    """The laundrette's front door: an aluminium-framed glass leaf with a push bar and an OPEN
    card. 1.0 x 2.3 m, hinged at the origin, spanning x -1.0..0."""
    p = Prop("mae_shop_door")
    w, h, t = 1.0, 2.3, 0.05
    s = 0.07
    p.add(box((-w, 0.0, -t / 2), (-w + s, h, t / 2), "steel_brushed", 0.004))
    p.add(box((-s, 0.0, -t / 2), (0.0, h, t / 2), "steel_brushed", 0.004))
    p.add(box((-w + s, h - s, -t / 2), (-s, h, t / 2), "steel_brushed", 0.004))
    p.add(box((-w + s, 0.0, -t / 2), (-s, 0.22, t / 2), "steel_brushed", 0.004))
    p.add(box((-w + s, 0.22, -0.006), (-s, h - s, 0.006), "glass", 0.0))
    for zs in (-1, 1):
        p.add(tube([(-w + 0.1, 1.0, zs * t / 2), (-w + 0.1, 1.0, zs * 0.07), (-0.12, 1.0, zs * 0.07), (-0.12, 1.0, zs * t / 2)], 0.014, "chrome", 6))
    # The OPEN card, hanging on a string.
    p.add(box((-w * 0.5 - 0.15, 1.55, -0.012), (-w * 0.5 + 0.15, 1.7, -0.008), "card_cream", 0.0))
    p.add(box((-w * 0.5 - 0.12, 1.59, -0.0125), (-w * 0.5 + 0.12, 1.66, -0.012), "sleeve_red", 0.0))
    p.add(tube([(-w * 0.5 - 0.13, 1.7, -0.01), (-w * 0.5, 1.82, -0.01), (-w * 0.5 + 0.13, 1.7, -0.01)], 0.002, "paper", 3))
    return p


@prop
def mae_door_bell():
    """A brass shop bell on a curled spring, over the door. Back on z = 0, 0.12 x 0.2 m."""
    p = Prop("mae_door_bell")
    p.add(box((-0.03, 0.12, 0.0), (0.03, 0.2, 0.01), "brass_aged", 0.002))
    p.add(tube([(0.0, 0.16, 0.01), (0.0, 0.17, 0.06), (0.02, 0.15, 0.09), (0.0, 0.13, 0.1), (-0.01, 0.1, 0.09)], 0.004, "cast_iron", 5))
    p.add(lathe([(0.0, 0.0), (0.035, 0.0), (0.03, 0.02), (0.02, 0.05), (0.008, 0.065), (0.0, 0.07)], "brass", 12, m=move(-0.01, 0.025, 0.09)))
    return p


@prop
def mae_strip_light():
    """A fluorescent fitting on two short chains: a white batten and its tube. 1.25 m long,
    hanging from y 0.2 to 0."""
    p = Prop("mae_strip_light")
    p.add(box((-0.62, 0.02, -0.05), (0.62, 0.07, 0.05), "paint_white", 0.008))
    p.add(cyl(0.016, -0.6, 0.6, "fluoro", 8, m=rot_z(90) @ move(0, 0, 0)).xf(move(0, 0.02, 0)))
    for x in (-0.45, 0.45):
        p.add(cyl(0.004, 0.07, 0.2, "steel", 4, m=move(x, 0, 0)))
    return p


# --- The back room -------------------------------------------------------------------------------

@prop
def mae_briefing_table():
    """The table every job was planned on: old oak with a drawer on its +Z side (its own node,
    Drawer), floor plans weighed down with mugs, an ashtray and a pencil. 2.2 x 0.78 x 1.1 m."""
    p = Prop("mae_briefing_table")
    w, h, d = 2.2, 0.78, 1.1
    p.add(box((-w / 2, h - 0.05, -d / 2), (w / 2, h, d / 2), "oak", 0.012, 3))
    p.add(box((-w / 2 + 0.06, h - 0.17, -d / 2 + 0.06), (w / 2 - 0.06, h - 0.05, d / 2 - 0.06), "walnut_matte", 0.006))
    for x in (-w / 2 + 0.1, w / 2 - 0.1):
        for z in (-d / 2 + 0.1, d / 2 - 0.1):
            p.add(turned_leg(x, z, h - 0.05, 0.04, "oak"))
    # The drawer's front.
    p.add(box((-0.3, h - 0.16, d / 2 - 0.07), (0.3, h - 0.06, d / 2 - 0.045), "oak", 0.006), node="Drawer")
    p.add(sphere(0.016, "brass", 8, 6, m=move(0.0, h - 0.11, d / 2 - 0.04)), node="Drawer")
    # Plans and photos spread out, held down.
    rng = rng_for("brief")
    for i in range(5):
        x, z = rng.uniform(-0.75, 0.75), rng.uniform(-0.3, 0.3)
        a = rng.uniform(-25, 25)
        p.add(box((-0.21, h, -0.15), (0.21, h + 0.002 + i * 0.001, 0.15), "blueprint" if i % 2 == 0 else "paper", 0.0).xf(move(x, 0, z) @ rot_y(a)))
    for x, z in ((-0.6, 0.25), (0.55, -0.2)):
        p.add(mug_at(x, h + 0.005, z, "porcelain" if x < 0 else "enamel_mint"))
    p.add(lathe([(0.07, 0.0), (0.07, 0.015), (0.06, 0.03)], "glass_dark", 12, m=move(0.2, h + 0.004, 0.32), cap=(True, False)))
    p.add(cyl(0.004, -0.08, 0.08, "sleeve_yellow", 6, m=move(-0.1, h + 0.01, -0.1) @ rot_z(90) @ rot_x(0)))
    p.add(box((0.7, h + 0.004, 0.1), (0.85, h + 0.01, 0.22), "photo", 0.0).xf(rot_y(12)))
    return p


@prop
def mae_chair():
    """A bentwood kitchen chair, its seat 0.46 m up, facing +Z. 0.44 x 0.9 x 0.48 m."""
    p = Prop("mae_chair")
    sh = 0.46
    p.add(cyl(0.21, sh - 0.03, sh, "walnut_matte", 16, bevel=0.01, m=move(0, 0, 0.02)))
    p.add(lathe([(0.2, sh - 0.12), (0.205, sh - 0.1)], "walnut_matte", 14, m=move(0, 0, 0.02), cap=(False, False)))
    for a in (45, 135, 225, 315):
        x, z = 0.17 * math.cos(math.radians(a)), 0.17 * math.sin(math.radians(a)) + 0.02
        p.add(tube([(x * 1.18, 0.0, z * 1.1), (x, sh - 0.03, z)], 0.014, "walnut_matte", 6))
    # The bent back: a hoop and two spindles.
    pts = []
    for i in range(13):
        a = math.radians(180 + i * 15)
        pts.append((0.18 * math.cos(a), sh + 0.02 + 0.4 * math.sin(math.radians(i * 15)), -0.17 - 0.03 * math.sin(math.radians(i * 15))))
    p.add(tube(pts, 0.012, "walnut_matte", 6))
    for x in (-0.05, 0.05):
        p.add(tube([(x, sh, -0.18), (x, sh + 0.33, -0.2)], 0.008, "walnut_matte", 5))
    return p


@prop
def mae_plans_board():
    """A cork board of the season's floor plans, photos and string, back on z = 0. 2.4 x 1.3 m,
    from y 0 to 1.3."""
    p = Prop("mae_plans_board")
    w, h = 2.4, 1.3
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, 0.025), "cork", 0.004))
    for e in ((-w / 2 - 0.03, -0.03, w / 2 + 0.03, 0.0), (-w / 2 - 0.03, h, w / 2 + 0.03, h + 0.03)):
        p.add(box((e[0], e[1], 0.0), (e[2], e[3], 0.035), "oak", 0.004))
    for x in (-w / 2 - 0.03, w / 2):
        p.add(box((x, 0.0, 0.0), (x + 0.03, h, 0.035), "oak", 0.004))
    rng = rng_for("plans")
    pins = []
    for i, (x, y, ww, hh) in enumerate(((-0.85, 0.65, 0.5, 0.42), (-0.25, 0.75, 0.46, 0.38), (0.35, 0.7, 0.5, 0.42),
                                        (0.9, 0.72, 0.4, 0.34), (-0.6, 0.2, 0.42, 0.32), (0.55, 0.2, 0.44, 0.34))):
        p.add(box((x - ww / 2, y - hh / 2, 0.025), (x + ww / 2, y + hh / 2, 0.028), "blueprint", 0.0).xf(move(0, 0, 0)))
        for k in range(4):
            yy = y - hh / 2 + 0.06 + k * (hh - 0.1) / 3
            p.add(box((x - ww / 2 + 0.04, yy, 0.028), (x + ww / 2 - 0.04, yy + 0.006, 0.029), "paper", 0.0))
        pins.append((x, y + hh / 2 - 0.03))
    for (x, y) in ((-0.05, 0.25), (0.15, 0.3), (1.0, 0.28), (-1.0, 1.1), (0.05, 1.12)):
        p.add(box((x - 0.06, y - 0.08, 0.025), (x + 0.06, y + 0.08, 0.03), "photo", 0.0))
        pins.append((x, y + 0.05))
    for (x, y) in pins:
        p.add(sphere(0.012, "cloth_red", 6, 4, m=move(x, y, 0.035)))
    for a, b in ((0, 6), (6, 1), (2, 8), (3, 7), (4, 5)):
        if a < len(pins) and b < len(pins):
            p.add(tube([(pins[a][0], pins[a][1], 0.036), (pins[b][0], pins[b][1], 0.036)], 0.002, "cloth_red", 3))
    return p


@prop
def mae_sideboard():
    """An old sideboard with the kettle, the tea caddy, mugs on hooks, a biscuit tin and a radio;
    its front faces +Z. 1.5 x 0.9 x 0.48 m (the kettle to 1.15)."""
    p = Prop("mae_sideboard")
    w, h, d = 1.5, 0.88, 0.48
    p.add(box((-w / 2, 0.08, -d / 2), (w / 2, h - 0.03, d / 2 - 0.02), "walnut_matte", 0.006))
    p.add(box((-w / 2 - 0.02, h - 0.03, -d / 2), (w / 2 + 0.02, h, d / 2), "walnut", 0.008))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        for z in (-d / 2 + 0.05, d / 2 - 0.07):
            p.add(leg(x, z, 0.09, 0.04, "walnut"))
    for x in (-0.5, 0.0, 0.5):
        p.add(face_box(x - 0.22, 0.14, x + 0.22, 0.6, d / 2 - 0.02, 0.012, 1, "walnut_matte", 0.006))
        p.add(face_box(x - 0.22, 0.64, x + 0.22, 0.8, d / 2 - 0.02, 0.012, 1, "walnut_matte", 0.006))
        p.add(sphere(0.014, "brass", 6, 4, m=move(x, 0.72, d / 2 + 0.005)))
    # The kettle (chrome, on its base), the caddy, the tin, the radio.
    y = h
    p.add(cyl(0.09, 0, 0.02, "plastic_black", 14, m=move(-0.45, y, 0.0)))
    p.add(lathe([(0.085, 0.02), (0.1, 0.06), (0.1, 0.17), (0.07, 0.24), (0.025, 0.26), (0.0, 0.27)], "chrome", 16, m=move(-0.45, y, 0.0)))
    p.add(tube([(-0.36, y + 0.1, 0.0), (-0.3, y + 0.16, 0.0), (-0.29, y + 0.2, 0.0)], 0.012, "chrome", 6))
    p.add(tube([(-0.53, y + 0.22, 0.0), (-0.45, y + 0.3, 0.0), (-0.37, y + 0.22, 0.0)], 0.012, "plastic_black", 6))
    p.add(cyl(0.06, 0, 0.16, "paint_door_red", 12, m=move(-0.18, y, -0.05)))
    p.add(cyl(0.062, 0.16, 0.18, "brass_aged", 12, m=move(-0.18, y, -0.05)))
    p.add(cyl(0.12, 0, 0.09, "sleeve_blue", 16, m=move(0.15, y, 0.02)))
    p.add(box((0.38, y, -0.15), (0.68, y + 0.17, -0.02), "walnut", 0.012))
    p.add(box((0.4, y + 0.03, -0.019), (0.56, y + 0.14, -0.015), "speaker_cloth", 0.0))
    p.add(cyl(0.02, 0, 0.02, "brass", 8, m=move(0.62, y + 0.09, -0.02) @ rot_x(90)))
    for x in (-0.05, 0.08):
        p.add(mug_at(x, y, 0.15, "enamel_white" if x < 0 else "sleeve_yellow"))
    return p


@prop
def mae_sofa_small():
    """The back room's worn leather two-seater, its cushions sagging. 1.6 x 0.85 x 0.85 m."""
    p = Prop("mae_sofa_small")
    w, d = 1.6, 0.85
    mat = "leather_brown"
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        for z in (-d / 2 + 0.08, d / 2 - 0.08):
            p.add(cyl(0.025, 0.0, 0.1, "walnut", 8, m=move(x, 0, z)))
    p.add(cushion((-w / 2, 0.1, -d / 2), (w / 2, 0.36, d / 2), mat, 0.04))
    for i in range(2):
        x0 = -w / 2 + 0.17 + i * (w - 0.34) / 2
        p.add(cushion((x0 + 0.01, 0.36, -d / 2 + 0.2), (x0 + (w - 0.34) / 2 - 0.01, 0.46 - i * 0.02, d / 2 - 0.01), mat, 0.05))
    p.add(cushion((-w / 2 + 0.06, 0.36, -d / 2), (w / 2 - 0.06, 0.8, -d / 2 + 0.2), mat, 0.06))
    for s in (-1, 1):
        x = s * (w / 2 - 0.09)
        p.add(cushion((x - 0.09, 0.36, -d / 2 + 0.01), (x + 0.09, 0.62, d / 2), mat, 0.04))
    p.add(cushion((-0.5, 0.42, -0.3), (-0.1, 0.62, -0.18), "knit_red", 0.05).xf(rot_z(8)))
    return p


@prop
def mae_pendant_green():
    """A green enamel shade on a flex, over the briefing table: 0.42 m across, hanging from
    y 0.95 to 0; the bulb's at y 0.06."""
    p = Prop("mae_pendant_green")
    p.add(lathe([(0.21, 0.0), (0.2, 0.012), (0.13, 0.08), (0.05, 0.14), (0.03, 0.17)], "paint_door_green", 20, cap=(False, True), bevel=0.0))
    p.add(lathe([(0.205, 0.004), (0.13, 0.075), (0.045, 0.13)], "enamel_white", 20, cap=(False, False)).xf(scale(0.98, 1.0, 0.98)))
    p.add(cyl(0.025, 0.17, 0.22, "brass_aged", 10))
    p.add(cyl(0.004, 0.22, 0.95, "plastic_black", 5))
    p.add(sphere(0.045, "bulb", 10, 6, m=move(0, 0.07, 0)))
    return p


# --- The flat: the living room -------------------------------------------------------------------

@prop
def mae_sofa_big():
    """Mae's big old sofa: deep rust velvet, sagging cushions, a knitted throw over one arm.
    2.4 x 0.95 x 1.0 m, facing +Z."""
    p = Prop("mae_sofa_big")
    w, d = 2.4, 1.0
    mat = "velvet_rust"
    for x in (-w / 2 + 0.1, w / 2 - 0.1):
        for z in (-d / 2 + 0.1, d / 2 - 0.1):
            p.add(turned_leg(x, z, 0.12, 0.032, "walnut"))
    p.add(cushion((-w / 2 + 0.02, 0.12, -d / 2 + 0.02), (w / 2 - 0.02, 0.4, d / 2 - 0.02), mat, 0.05))
    for i in range(3):
        cx0 = -w / 2 + 0.24 + i * (w - 0.48) / 3
        p.add(cushion((cx0 + 0.01, 0.4, -d / 2 + 0.25), (cx0 + (w - 0.48) / 3 - 0.01, 0.53 - (i == 1) * 0.03, d / 2 - 0.01), mat, 0.06))
    p.add(cushion((-w / 2 + 0.1, 0.4, -d / 2), (w / 2 - 0.1, 0.92, -d / 2 + 0.26), mat, 0.08))
    for s in (-1, 1):
        x = s * (w / 2 - 0.13)
        p.add(cushion((x - 0.13, 0.4, -d / 2 + 0.02), (x + 0.13, 0.66, d / 2 - 0.01), mat, 0.05))
        p.add(cyl(0.13, -d / 2 + 0.02, d / 2 - 0.01, mat, 14, m=move(x + s * 0.01, 0.66, 0) @ rot_x(90), bevel=0.02))
    # Scatter cushions and the throw.
    p.add(cushion((-0.95, 0.5, -d / 2 + 0.24), (-0.55, 0.88, -d / 2 + 0.38), "velvet_teal", 0.07).xf(move(0, 0, 0) @ rot_z(-6)))
    p.add(cushion((0.5, 0.5, -d / 2 + 0.24), (0.88, 0.86, -d / 2 + 0.38), "velvet_mustard", 0.07).xf(rot_z(5)))
    p.add(cushion((w / 2 - 0.27, 0.62, -d / 2 + 0.12), (w / 2 + 0.03, 0.81, d / 2 - 0.04), "knit_mustard", 0.03))
    p.add(grid_sheet(0.66, 0.46, 10, 5, "knit_mustard", lambda x, y: 0.012 * math.sin(x * 22.0) * (0.4 + y),
                     m=move(w / 2 + 0.035, 0.34, 0.06) @ rot_y(90), thickness=0.012))
    return p


@prop
def mae_armchair():
    """An old wingback armchair in teal velvet, a little threadbare. 0.88 x 1.1 x 0.9 m."""
    p = Prop("mae_armchair")
    w, d = 0.88, 0.9
    mat = "velvet_teal"
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        for z in (-d / 2 + 0.08, d / 2 - 0.08):
            p.add(turned_leg(x, z, 0.14, 0.028, "walnut"))
    p.add(cushion((-w / 2 + 0.02, 0.14, -d / 2 + 0.02), (w / 2 - 0.02, 0.4, d / 2 - 0.02), mat, 0.04))
    p.add(cushion((-w / 2 + 0.14, 0.4, -d / 2 + 0.2), (w / 2 - 0.14, 0.52, d / 2 - 0.01), mat, 0.05))
    p.add(cushion((-w / 2 + 0.06, 0.4, -d / 2), (w / 2 - 0.06, 1.1, -d / 2 + 0.2), mat, 0.07))
    for s in (-1, 1):
        x = s * (w / 2 - 0.08)
        p.add(cushion((x - 0.08, 0.4, -d / 2 + 0.02), (x + 0.08, 0.66, d / 2 - 0.02), mat, 0.04))
        p.add(cushion((x - 0.06, 0.66, -d / 2 + 0.02), (x + 0.06, 1.04, -d / 2 + 0.36), mat, 0.05))
    p.add(box((-0.2, 0.66, -d / 2 + 0.18), (0.2, 0.9, -d / 2 + 0.2), "linen", 0.004).xf(move(0, 0.12, 0)))
    return p


@prop
def mae_coffee_table():
    """A low teak table with magazines, a bowl of crisps, an ashtray and glasses left about.
    1.2 x 0.42 x 0.62 m."""
    p = Prop("mae_coffee_table")
    w, h, d = 1.2, 0.42, 0.62
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2), "oak", 0.012, 3))
    for x in (-w / 2 + 0.07, w / 2 - 0.07):
        for z in (-d / 2 + 0.07, d / 2 - 0.07):
            p.add(tube([(x * 1.05, 0.0, z * 1.08), (x, h - 0.04, z)], 0.02, "oak", 8))
    p.add(box((-w / 2 + 0.08, 0.12, -d / 2 + 0.08), (w / 2 - 0.08, 0.14, d / 2 - 0.08), "oak", 0.004))
    p.add(box((-0.5, 0.14, -0.15), (-0.2, 0.18, 0.12), "sleeve_red", 0.003))
    p.add(box((-0.48, h, -0.2), (-0.2, h + 0.008, 0.02), "sleeve_white", 0.002).xf(move(0, 0, 0)))
    p.add(lathe([(0.04, 0.0), (0.1, 0.03), (0.12, 0.07)], "porcelain", 16, m=move(0.12, h, 0.0), cap=(True, False)))
    p.add(sphere(0.09, "food_bread", 8, 4, m=move(0.12, h + 0.04, 0.0), squash=0.3))
    p.add(lathe([(0.06, 0.0), (0.065, 0.015), (0.055, 0.025)], "glass_dark", 12, m=move(0.42, h, -0.15), cap=(True, False)))
    p.add(glass_at(0.4, h, 0.15, "wine"))
    p.add(glass_at(-0.05, h, 0.2, "tumbler"))
    return p


@prop
def mae_record_shelf():
    """A long low cabinet of records in cubbies, the record player and its two speakers on top.
    1.8 x 1.05 x 0.45 m, facing +Z."""
    p = Prop("mae_record_shelf")
    w, h, d = 1.8, 0.75, 0.45
    rng = rng_for("records")
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.06, d / 2), "walnut", 0.004))
    p.add(box((-w / 2, h - 0.03, -d / 2), (w / 2, h, d / 2), "walnut", 0.006))
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, -d / 2 + 0.02), "walnut_matte", 0.0))
    for i in range(5):
        x = -w / 2 + i * (w - 0.03) / 4
        p.add(box((x, 0.06, -d / 2), (x + 0.03, h - 0.03, d / 2), "walnut", 0.004))
    p.add(box((-w / 2, 0.36, -d / 2), (w / 2, 0.39, d / 2), "walnut", 0.004))
    for i in range(4):
        x0 = -w / 2 + 0.035 + i * (w - 0.03) / 4
        x1 = x0 + (w - 0.03) / 4 - 0.04
        records_row(p, x0, x1 - rng.uniform(0.0, 0.08), 0.06, -d / 2 + 0.04, d / 2 - 0.03, rng)
        records_row(p, x0, x1 - rng.uniform(0.0, 0.15), 0.39, -d / 2 + 0.04, d / 2 - 0.03, rng)
    # The record player: a plinth, a platter with a record, the arm; the lid propped up.
    y = h
    p.add(box((-0.25, y, -0.18), (0.25, y + 0.08, 0.18), "walnut", 0.008))
    p.add(cyl(0.15, y + 0.08, y + 0.095, "steel", 20, m=move(-0.04, 0, 0)))
    p.add(cyl(0.148, y + 0.095, y + 0.1, "vinyl_black", 20, m=move(-0.04, 0, 0)))
    p.add(cyl(0.05, y + 0.1, y + 0.102, "sleeve_red", 12, m=move(-0.04, 0, 0)))
    p.add(tube([(0.19, y + 0.12, -0.12), (0.2, y + 0.12, 0.02), (0.1, y + 0.12, 0.09)], 0.005, "chrome", 5))
    p.add(box((-0.25, y + 0.08, -0.185), (0.25, y + 0.42, -0.175), "glass", 0.0).xf(move(0, 0, 0)))
    for x in (-0.68, 0.68):
        p.add(box((x - 0.16, y, -0.16), (x + 0.16, y + 0.3, 0.16), "walnut", 0.008))
        p.add(box((x - 0.14, y + 0.02, 0.16), (x + 0.14, y + 0.28, 0.165), "speaker_cloth", 0.0))
    # A few sleeves leaning against the front.
    for i, mat in enumerate(("sleeve_yellow", "sleeve_blue")):
        p.add(box((-0.15, 0.0, 0.0), (0.16, 0.31, 0.006), mat, 0.0).xf(move(0.3 + i * 0.05, 0.0, d / 2 + 0.06 - i * 0.02) @ rot_x(-12)))
    return p


@prop
def mae_dj_table():
    """Jojo's decks on a trestle table: two turntables, a mixer, a laptop and a tangle of cable,
    a crate of records underneath. 1.6 x 1.05 x 0.65 m, facing +Z."""
    p = Prop("mae_dj_table")
    w, h, d = 1.6, 0.86, 0.65
    p.add(box((-w / 2, h - 0.035, -d / 2), (w / 2, h, d / 2), "plastic_black", 0.006))
    for s in (-1, 1):
        x = s * (w / 2 - 0.15)
        p.add(tube([(x - 0.15, 0.0, -d / 2 + 0.05), (x, h - 0.04, 0.0), (x + 0.15, 0.0, -d / 2 + 0.05)], 0.015, "steel", 6))
        p.add(tube([(x - 0.15, 0.0, d / 2 - 0.05), (x, h - 0.04, 0.0), (x + 0.15, 0.0, d / 2 - 0.05)], 0.015, "steel", 6))
    for x in (-0.48, 0.48):
        p.add(box((x - 0.24, h, -0.2), (x + 0.24, h + 0.07, 0.17), "cast_iron", 0.008))
        p.add(cyl(0.16, h + 0.07, h + 0.08, "vinyl_black", 20, m=move(x - 0.03, 0, -0.02)))
        p.add(cyl(0.05, h + 0.08, h + 0.082, "sleeve_yellow", 12, m=move(x - 0.03, 0, -0.02)))
        p.add(tube([(x + 0.19, h + 0.09, -0.15), (x + 0.2, h + 0.09, 0.0), (x + 0.1, h + 0.09, 0.06)], 0.005, "chrome", 5))
    p.add(box((-0.14, h, -0.18), (0.14, h + 0.09, 0.15), "plastic_black", 0.008))
    for i in range(3):
        p.add(box((-0.1 + i * 0.08, h + 0.09, -0.06), (-0.08 + i * 0.08, h + 0.1, 0.1), "steel", 0.0))
    p.add(box((-0.04, h + 0.09, -0.15), (0.04, h + 0.095, -0.12), "led_blue", 0.0))
    # The laptop, open, on the table's back edge.
    p.add(box((-0.16, h, -d / 2 + 0.02), (0.16, h + 0.015, -d / 2 + 0.23), "steel_brushed", 0.004).xf(move(0, 0, 0)))
    p.add(box((-0.16, 0.0, 0.0), (0.16, 0.22, 0.01), "steel_brushed", 0.003).xf(move(0, h + 0.015, -d / 2 + 0.02) @ rot_x(15)))
    p.add(box((-0.15, 0.01, 0.011), (0.15, 0.21, 0.013), "screen_dim", 0.0).xf(move(0, h + 0.015, -d / 2 + 0.02) @ rot_x(15)))
    p.add(tube([(-0.6, h, 0.1), (-0.3, h - 0.3, 0.2), (0.0, h - 0.5, 0.25), (0.4, h - 0.3, 0.2), (0.6, h, 0.1)], 0.006, "plastic_black", 4))
    # A crate of records under it.
    p.add(box((-0.2, 0.0, -0.18), (0.2, 0.3, 0.18), "plastic_blue", 0.01))
    records_row(p, -0.17, 0.17, 0.02, -0.16, 0.16, rng_for("crate"))
    return p


@prop
def mae_speaker():
    """A party speaker on a tripod stand, its grille facing +Z. 0.45 x 1.75 x 0.45 m."""
    p = Prop("mae_speaker")
    for a in (90, 210, 330):
        x, z = 0.22 * math.cos(math.radians(a)), 0.22 * math.sin(math.radians(a))
        p.add(tube([(x, 0.0, z), (0.0, 0.55, 0.0)], 0.012, "cast_iron", 5))
    p.add(cyl(0.02, 0.4, 1.2, "cast_iron", 8))
    p.add(box((-0.2, 1.15, -0.17), (0.2, 1.75, 0.17), "plastic_black", 0.02, 3))
    p.add(box((-0.18, 1.18, 0.17), (0.18, 1.72, 0.175), "speaker_cloth", 0.0))
    p.add(box((-0.04, 1.2, 0.175), (0.04, 1.22, 0.18), "led_blue", 0.0))
    return p


@prop
def mae_fireplace():
    """A tiled fireplace with a gas fire glowing, a mantel crowded with cards, photos, a clock and
    candles. Back on z = 0; 1.6 x 1.25 x 0.36 m."""
    p = Prop("mae_fireplace")
    w, h, d = 1.6, 1.2, 0.36
    p.add(box((-w / 2, 0.0, 0.0), (-0.42, 1.08, 0.2), "tile_green", 0.004))
    p.add(box((0.42, 0.0, 0.0), (w / 2, 1.08, 0.2), "tile_green", 0.004))
    p.add(box((-0.42, 0.78, 0.0), (0.42, 1.08, 0.2), "tile_green", 0.004))
    p.add(box((-0.42, 0.0, 0.0), (0.42, 0.78, 0.04), "cast_iron", 0.0))
    p.add(box((-w / 2 - 0.05, 1.08, 0.0), (w / 2 + 0.05, 1.13, d), "walnut", 0.008))
    p.add(box((-w / 2 - 0.1, 0.0, 0.0), (w / 2 + 0.1, 0.04, 0.48), "tile_cream", 0.004))
    # The gas fire: a grate of glowing radiants.
    p.add(box((-0.32, 0.08, 0.04), (0.32, 0.6, 0.18), "cast_iron", 0.008))
    for i in range(5):
        x = -0.24 + i * 0.12
        p.add(box((x - 0.04, 0.14, 0.18), (x + 0.04, 0.48, 0.19), "heat_lamp", 0.0))
    # Along the mantel.
    rng = rng_for("mantel")
    y = 1.13
    p.add(box((-0.14, y, 0.08), (0.14, y + 0.22, 0.2), "walnut", 0.02))
    p.add(cyl(0.08, -0.002, 0.004, "paper", 16, m=move(0.0, y + 0.12, 0.2) @ rot_x(90)))
    for x in (-0.65, -0.45, 0.4, 0.62):
        hh = rng.uniform(0.14, 0.22)
        p.add(box((x - 0.06, y, 0.12), (x + 0.06, y + hh, 0.14), "photo", 0.003).xf(move(0, 0, 0)))
        p.add(box((x - 0.07, y, 0.14), (x + 0.07, y + hh + 0.01, 0.15), "brass_aged", 0.002))
    for x in (-0.3, 0.27):
        p.add(cyl(0.025, y, y + 0.18, "wax", 8, m=move(x, 0, 0.22)))
        p.add(sphere(0.012, "flame", 6, 4, m=move(x, y + 0.2, 0.22), squash=1.6))
    for i in range(4):
        x = -0.8 + i * 0.1
        p.add(prism([(0.0, 0.0), (0.06, 0.12), (0.12, 0.0)], 0.002, "card_cream", m=move(x, y, 0.28), bevel=0.0))
    return p


@prop
def mae_floor_lamp():
    """A standard lamp with a fringed silk shade, lit warm. 1.65 m; the bulb at y 1.4."""
    p = Prop("mae_floor_lamp")
    p.add(lathe([(0.0, 0.0), (0.16, 0.0), (0.16, 0.03), (0.06, 0.06), (0.03, 0.1)], "brass_aged", 14))
    p.add(cyl(0.014, 0.1, 1.38, "brass_aged", 8))
    p.add(lathe([(0.25, 1.26), (0.24, 1.29), (0.15, 1.6)], "lampshade_warm", 16, cap=(False, False)))
    for i in range(24):
        a = 2 * math.pi * i / 24
        p.add(box((-0.004, 0.0, -0.002), (0.004, 0.08, 0.002), "velvet_gold", 0.0).xf(move(0.25 * math.cos(a), 1.18, 0.25 * math.sin(a))))
    p.add(sphere(0.04, "bulb", 8, 6, m=move(0, 1.4, 0)))
    return p


@prop
def mae_drinks_table():
    """A folding table under a white cloth: bottles, glasses in rows, an ice bucket and a stack of
    paper plates. 1.4 x 1.1 x 0.62 m, facing +Z."""
    p = Prop("mae_drinks_table")
    w, h, d = 1.4, 0.76, 0.62
    p.add(box((-w / 2, h - 0.03, -d / 2), (w / 2, h, d / 2), "linen", 0.006))
    p.add(box((-w / 2 - 0.01, h - 0.3, d / 2), (w / 2 + 0.01, h, d / 2 + 0.01), "linen", 0.003))
    for x in (-w / 2 + 0.05, w / 2 - 0.05):
        p.add(tube([(x, 0.0, -d / 2 + 0.05), (x, h - 0.03, d / 2 - 0.1)], 0.012, "steel", 5))
        p.add(tube([(x, 0.0, d / 2 - 0.05), (x, h - 0.03, -d / 2 + 0.1)], 0.012, "steel", 5))
    rng = rng_for("drinks")
    for i, mat in enumerate(("bottle_green", "bottle_amber", "bottle_clear", "bottle_green", "bottle_amber", "bottle_blue")):
        p.add(bottle_at(-0.6 + i * 0.1, h, -0.2 + rng.uniform(-0.03, 0.03), mat, rng.uniform(0.26, 0.34)))
    for i in range(4):
        for j in range(3):
            p.add(glass_at(-0.05 + i * 0.09, h, -0.05 + j * 0.09, "flute" if j == 0 else "wine"))
    p.add(lathe([(0.1, 0.0), (0.12, 0.2), (0.125, 0.21)], "steel", 16, m=move(0.5, h, -0.1), cap=(True, False)))
    p.add(bottle_at(0.47, h + 0.04, -0.12, "bottle_green", 0.3, 0.035))
    p.add(cyl(0.11, h, h + 0.05, "paper", 16, m=move(0.5, 0, 0.17)))
    return p


# --- The kitchen ---------------------------------------------------------------------------------

@prop
def mae_kitchen_run():
    """A 3 m run of kitchen units: cupboards and drawers in cream, a wooden worktop with a sink,
    a draining rack, a bread bin, jars and the washing up. Against its back wall; 3.0 x 0.92 x
    0.62 m, facing +Z."""
    p = Prop("mae_kitchen_run")
    w, h, d = 3.0, 0.92, 0.62
    p.add(box((-w / 2, 0.1, -d / 2), (w / 2, h - 0.04, d / 2 - 0.02), "paint_door_cream", 0.004))
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.1, d / 2 - 0.08), "walnut_dark", 0.002))
    p.add(box((-w / 2 - 0.01, h - 0.04, -d / 2), (w / 2 + 0.01, h, d / 2 + 0.01), "oak", 0.006))
    for i in range(5):
        x0 = -w / 2 + 0.02 + i * (w - 0.04) / 5
        x1 = x0 + (w - 0.04) / 5 - 0.02
        if i == 1:
            for k in range(3):
                y0 = 0.14 + k * 0.24
                p.add(face_box(x0, y0, x1, y0 + 0.22, d / 2 - 0.02, 0.018, 1, "paint_door_cream", 0.004))
                p.add(box(((x0 + x1) / 2 - 0.06, y0 + 0.15, d / 2), ((x0 + x1) / 2 + 0.06, y0 + 0.17, d / 2 + 0.025), "chrome", 0.004))
        else:
            p.add(face_box(x0, 0.14, x1, h - 0.08, d / 2 - 0.02, 0.018, 1, "paint_door_cream", 0.004))
            p.add(box((x1 - 0.05, h - 0.26, d / 2), (x1 - 0.035, h - 0.13, d / 2 + 0.025), "chrome", 0.003))
    # The sink and its tap, the rack, the bread bin, jars.
    sx = 0.6
    p.add(box((sx - 0.3, h - 0.005, -0.2), (sx + 0.3, h + 0.005, 0.2), "steel", 0.004))
    p.add(box((sx - 0.24, h - 0.18, -0.16), (sx + 0.24, h, 0.16), "steel_dark", 0.0))
    p.add(tube([(sx, h, -0.25), (sx, h + 0.28, -0.25), (sx, h + 0.32, -0.15), (sx, h + 0.26, -0.08)], 0.014, "chrome", 8))
    p.add(box((sx + 0.32, h, -0.18), (sx + 0.7, h + 0.02, 0.18), "steel_dark", 0.004))
    for i in range(6):
        p.add(cyl(0.11, -0.006, 0.006, ["porcelain", "enamel_mint", "porcelain"][i % 3], 16, m=move(sx + 0.38 + i * 0.05, h + 0.12, 0.0) @ rot_z(90) @ rot_x(0)))
    p.add(box((-1.35, h, -0.27), (-0.95, h + 0.24, -0.02), "enamel_cream", 0.03))
    p.add(box((-1.33, h + 0.15, -0.02), (-0.97, h + 0.2, 0.0), "paint_door_red", 0.004))
    for i, (x, mat) in enumerate(((-0.8, "glass"), (-0.68, "glass"), (-0.56, "terracotta"))):
        p.add(cyl(0.045, h, h + 0.16 + i * 0.02, mat, 12, m=move(x, 0, -0.18)))
        p.add(cyl(0.048, h + 0.16 + i * 0.02, h + 0.19 + i * 0.02, "copper", 12, m=move(x, 0, -0.18)))
    p.add(box((-0.3, h, -0.25), (0.1, h + 0.03, 0.0), "oak", 0.006))
    p.add(sphere(0.07, "food_bread", 10, 6, m=move(-0.12, h + 0.06, -0.12), squash=0.7).xf(scale(1.6, 1, 1)).xf(move(0.07, 0, 0)))
    return p


@prop
def mae_wall_cupboards():
    """Cream wall cupboards over the run, with a plate rack at one end. Back on z = 0; 2.4 x 0.7
    x 0.34 m, from y 0 to 0.7 (hung at 1.45)."""
    p = Prop("mae_wall_cupboards")
    w, h, d = 2.4, 0.7, 0.34
    p.add(box((-w / 2, 0.0, 0.0), (w / 2 - 0.6, h, d), "paint_door_cream", 0.004))
    for i in range(3):
        x0 = -w / 2 + 0.02 + i * 0.6
        p.add(face_box(x0, 0.03, x0 + 0.56, h - 0.03, d, 0.016, 1, "paint_door_cream", 0.004))
        p.add(box((x0 + 0.49, 0.06, d + 0.016), (x0 + 0.51, 0.18, d + 0.035), "chrome", 0.003))
    # The plate rack: two rails and plates on edge.
    x0 = w / 2 - 0.6
    for y in (0.05, h - 0.05):
        p.add(box((x0, y - 0.02, 0.0), (w / 2, y + 0.02, d - 0.04), "oak", 0.004))
    for i in range(8):
        p.add(cyl(0.12, -0.006, 0.006, "porcelain" if i % 3 else "enamel_mint", 16, m=move(x0 + 0.06 + i * 0.065, 0.2, d / 2) @ rot_z(90)))
    return p


@prop
def mae_cooker():
    """An old enamel cooker with four rings, the eye-level grill, and a big pot of stew on the go.
    0.62 x 1.5 x 0.64 m, facing +Z."""
    p = Prop("mae_cooker")
    w, h, d = 0.62, 0.9, 0.64
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "enamel_cream", 0.02, 3))
    p.add(box((-w / 2 + 0.05, 0.12, d / 2), (w / 2 - 0.05, 0.62, d / 2 + 0.02), "enamel_cream", 0.01))
    p.add(box((-w / 2 + 0.12, 0.38, d / 2 + 0.02), (w / 2 - 0.12, 0.56, d / 2 + 0.025), "glass_dark", 0.0))
    p.add(cyl(0.012, -w / 2 + 0.08, w / 2 - 0.08, "chrome", 8, m=move(0, 0.66, d / 2 + 0.06) @ rot_z(90)).xf(move(0, 0, 0)))
    for i in range(5):
        p.add(cyl(0.02, 0, 0.03, "plastic_black", 8, m=move(-0.2 + i * 0.1, 0.78, d / 2) @ rot_x(90)))
    p.add(box((-w / 2, h, -d / 2), (w / 2, h + 0.01, d / 2), "cast_iron", 0.003))
    for x in (-0.14, 0.14):
        for z in (-0.14, 0.14):
            p.add(cyl(0.08, h + 0.01, h + 0.025, "cast_iron", 12, m=move(x, 0, z)))
    # The eye-level grill on its back panel.
    p.add(box((-w / 2, h, -d / 2), (w / 2, h + 0.62, -d / 2 + 0.04), "enamel_cream", 0.01))
    p.add(box((-w / 2, h + 0.45, -d / 2), (w / 2, h + 0.6, -d / 2 + 0.3), "enamel_cream", 0.012))
    p.add(box((-w / 2 + 0.04, h + 0.47, -d / 2 + 0.3), (w / 2 - 0.04, h + 0.58, -d / 2 + 0.305), "cast_iron", 0.0))
    # The stew, a kettle, a frying pan.
    p.add(lathe([(0.15, 0.0), (0.16, 0.2), (0.165, 0.21)], "copper", 18, m=move(-0.14, h + 0.025, 0.14), cap=(True, False)))
    p.add(cyl(0.155, 0.17, 0.175, "stew", 18, m=move(-0.14, h + 0.025, 0.14)))
    p.add(tube([(-0.32, h + 0.2, 0.14), (-0.36, h + 0.21, 0.14)], 0.012, "copper", 6))
    p.add(tube([(0.04, h + 0.2, 0.14), (0.08, h + 0.21, 0.14)], 0.012, "copper", 6))
    p.add(lathe([(0.08, 0.0), (0.1, 0.05), (0.1, 0.12), (0.06, 0.17), (0.0, 0.18)], "enamel_mint", 14, m=move(0.14, h + 0.025, -0.14)))
    p.add(lathe([(0.1, 0.0), (0.12, 0.04)], "cast_iron", 14, m=move(0.14, h + 0.025, 0.14), cap=(True, False)))
    p.add(tube([(0.26, h + 0.06, 0.14), (0.45, h + 0.07, 0.14)], 0.012, "cast_iron", 6))
    return p


@prop
def mae_fridge():
    """A round-shouldered old fridge in cream, covered in magnets, a postcard and a business card.
    0.7 x 1.62 x 0.7 m, facing +Z."""
    p = Prop("mae_fridge")
    w, h, d = 0.7, 1.62, 0.7
    p.add(box((-w / 2, 0.06, -d / 2), (w / 2, h, d / 2), "enamel_cream", 0.08, 4))
    p.add(box((-w / 2 + 0.03, 0.0, -d / 2 + 0.03), (w / 2 - 0.03, 0.06, d / 2 - 0.05), "cast_iron", 0.004))
    p.add(box((-w / 2 + 0.02, 1.0, d / 2 - 0.02), (w / 2 - 0.02, 1.02, d / 2 + 0.005), "chrome", 0.003))
    p.add(box((w / 2 - 0.08, 1.1, d / 2), (w / 2 - 0.05, 1.4, d / 2 + 0.05), "chrome", 0.01))
    rng = rng_for("fridge")
    for i in range(9):
        x, y = rng.uniform(-0.25, 0.2), rng.uniform(1.05, 1.5)
        mat = rng.choice(["photo", "card_cream", "sleeve_yellow", "paper", "card_black"])
        ww, hh = rng.uniform(0.06, 0.12), rng.uniform(0.05, 0.1)
        p.add(box((x, y, d / 2 + 0.002), (x + ww, y + hh, d / 2 + 0.004), mat, 0.0))
        p.add(sphere(0.012, rng.choice(["cloth_red", "plastic_blue", "sleeve_yellow"]), 6, 4, m=move(x + ww / 2, y + hh, d / 2 + 0.01)))
    return p


@prop
def mae_kitchen_table():
    """A formica kitchen table on chrome legs, laid for the party: sandwiches, a cake, a bowl of
    salad, bottles. 1.4 x 0.95 x 0.85 m."""
    p = Prop("mae_kitchen_table")
    w, h, d = 1.4, 0.76, 0.85
    p.add(box((-w / 2, h - 0.035, -d / 2), (w / 2, h, d / 2), "formica_red", 0.012, 3))
    p.add(box((-w / 2 - 0.005, h - 0.04, -d / 2 - 0.005), (w / 2 + 0.005, h - 0.025, d / 2 + 0.005), "chrome", 0.003))
    for x in (-w / 2 + 0.06, w / 2 - 0.06):
        for z in (-d / 2 + 0.06, d / 2 - 0.06):
            p.add(cyl(0.017, 0.0, h - 0.035, "chrome", 8, m=move(x, 0, z)))
    y = h
    # A cake on a stand.
    p.add(lathe([(0.04, 0.0), (0.03, 0.06), (0.15, 0.08), (0.16, 0.09)], "porcelain", 16, m=move(-0.35, y, -0.1)))
    p.add(cyl(0.13, 0.09, 0.2, "food_cake", 16, m=move(-0.35, y, -0.1)))
    p.add(cyl(0.132, 0.14, 0.15, "food_jam", 16, m=move(-0.35, y, -0.1)))
    # Sandwiches on a plate.
    p.add(cyl(0.15, 0.0, 0.012, "porcelain", 16, m=move(0.1, y, 0.15)))
    for i in range(6):
        a = i * 60
        p.add(prism([(0.0, 0.0), (0.08, 0.0), (0.0, 0.08)], 0.04, "food_bread", plane="xz", m=move(0.1, y + 0.03, 0.15) @ rot_y(a) @ move(0.01, 0, 0.01), bevel=0.004))
    p.add(lathe([(0.05, 0.0), (0.13, 0.05), (0.15, 0.09)], "glass", 16, m=move(0.42, y, -0.18), cap=(True, False)))
    p.add(sphere(0.12, "food_green", 10, 5, m=move(0.42, y + 0.06, -0.18), squash=0.4))
    for i, mat in enumerate(("bottle_green", "bottle_amber")):
        p.add(bottle_at(-0.05 + i * 0.12, y, -0.25, mat, 0.3))
    p.add(glass_at(0.5, y, 0.25, "wine"))
    p.add(glass_at(-0.55, y, 0.28, "tumbler"))
    return p


# --- The study and the strongroom ----------------------------------------------------------------

@prop
def mae_desk():
    """Mae's partner's desk: mahogany with a green leather top, a banker's lamp, the black phone,
    files, an ashtray and a framed photo of the crew. 1.6 x 0.78 x 0.85 m; her chair goes on
    its -Z side."""
    p = Prop("mae_desk")
    w, h, d = 1.6, 0.76, 0.85
    p.add(box((-w / 2, h - 0.04, -d / 2), (w / 2, h, d / 2), "mahogany", 0.01, 3))
    p.add(box((-w / 2 + 0.08, h - 0.002, -d / 2 + 0.08), (w / 2 - 0.08, h + 0.003, d / 2 - 0.08), "leather_green", 0.0))
    for s in (-1, 1):
        x0, x1 = (-w / 2, -w / 2 + 0.48) if s < 0 else (w / 2 - 0.48, w / 2)
        p.add(box((x0, 0.0, -d / 2 + 0.02), (x1, h - 0.04, d / 2 - 0.02), "mahogany", 0.008))
        for k in range(3):
            y0 = 0.06 + k * 0.22
            p.add(face_box(x0 + 0.03, y0, x1 - 0.03, y0 + 0.2, -d / 2 + 0.02, 0.012, -1, "mahogany", 0.004))
            p.add(box(((x0 + x1) / 2 - 0.05, y0 + 0.09, -d / 2 - 0.02), ((x0 + x1) / 2 + 0.05, y0 + 0.11, -d / 2 + 0.005), "brass", 0.003))
        p.add(face_box(x0 + 0.03, 0.06, x1 - 0.03, h - 0.08, d / 2 - 0.02, 0.012, 1, "mahogany", 0.004))
    p.add(box((-0.32, h - 0.18, d / 2 - 0.04), (0.32, h - 0.04, d / 2 - 0.02), "mahogany", 0.004))
    # The banker's lamp.
    y = h
    p.add(box((0.45, y, -0.25), (0.65, y + 0.02, -0.12), "brass", 0.004))
    p.add(cyl(0.01, y + 0.02, y + 0.3, "brass", 6, m=move(0.55, 0, -0.18)))
    p.add(cyl(0.035, -0.17, 0.17, "lamp_green", 12, m=move(0.55, y + 0.33, -0.12) @ rot_z(90)).xf(scale(1, 0.75, 1.0)))
    p.add(sphere(0.02, "bulb", 6, 4, m=move(0.55, y + 0.3, -0.12)))
    # The phone, an ashtray, a stack of files, the photo.
    p.add(box((-0.62, y, -0.3), (-0.4, y + 0.08, -0.12), "card_black", 0.02))
    p.add(tube([(-0.6, y + 0.1, -0.21), (-0.51, y + 0.13, -0.21), (-0.42, y + 0.1, -0.21)], 0.02, "card_black", 6))
    p.add(cyl(0.04, y + 0.08, y + 0.085, "steel", 10, m=move(-0.51, 0, -0.2)))
    p.add(lathe([(0.06, 0.0), (0.065, 0.015), (0.055, 0.025)], "glass_dark", 12, m=move(-0.2, y, 0.25), cap=(True, False)))
    for i in range(4):
        p.add(box((-0.1 - 0.01 * i, y + i * 0.025, -0.3), (0.22 + 0.01 * i, y + 0.024 + i * 0.025, -0.06), ["sleeve_yellow", "card_cream", "plastic_blue", "card_cream"][i], 0.003).xf(move(0, 0.004, 0)))
    p.add(box((0.15, y, 0.05), (0.33, y + 0.004, 0.27), "paper", 0.0).xf(rot_y(10)))
    p.add(box((0.0, 0.0, -0.01), (0.14, 0.18, 0.01), "brass_aged", 0.003).xf(move(0.3, y, -0.3) @ rot_y(-25) @ rot_x(-12)))
    p.add(box((0.012, 0.012, 0.0105), (0.128, 0.168, 0.012), "photo", 0.0).xf(move(0.3, y, -0.3) @ rot_y(-25) @ rot_x(-12)))
    return p


@prop
def mae_desk_chair():
    """A captain's chair in mahogany with a leather seat, facing +Z. 0.6 x 0.85 x 0.55 m."""
    p = Prop("mae_desk_chair")
    sh = 0.46
    p.add(cushion((-0.25, sh - 0.06, -0.22), (0.25, sh, 0.24), "leather_oxblood", 0.03))
    for x in (-0.21, 0.21):
        for z in (-0.18, 0.2):
            p.add(tube([(x * 1.08, 0.0, z * 1.08), (x, sh - 0.06, z)], 0.018, "mahogany", 6))
    pts = [(0.27 * math.cos(math.radians(a)), 0.74, 0.27 * math.sin(math.radians(a)) - 0.02) for a in range(200, 341, 14)]
    p.add(tube(pts, 0.025, "mahogany", 8))
    for a in range(210, 336, 25):
        x, z = 0.26 * math.cos(math.radians(a)), 0.26 * math.sin(math.radians(a)) - 0.02
        p.add(tube([(x * 0.9, sh, z * 0.9 - 0.02), (x, 0.74, z)], 0.01, "mahogany", 5))
    return p


@prop
def mae_bookcase():
    """A tall bookcase of books, box files and ledgers: Mae's files on everyone she's ever
    worked with. 1.0 x 2.1 x 0.36 m, facing +Z."""
    p = Prop("mae_bookcase")
    w, h, d = 1.0, 2.1, 0.36
    p.add(box((-w / 2, 0.0, -d / 2), (-w / 2 + 0.025, h, d / 2), "walnut", 0.004))
    p.add(box((w / 2 - 0.025, 0.0, -d / 2), (w / 2, h, d / 2), "walnut", 0.004))
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, -d / 2 + 0.015), "walnut_matte", 0.0))
    p.add(box((-w / 2 - 0.02, h - 0.04, -d / 2), (w / 2 + 0.02, h, d / 2 + 0.02), "walnut", 0.006))
    rng = rng_for("bookcase")
    ys = [0.0, 0.4, 0.78, 1.14, 1.5, 1.86]
    for i, y in enumerate(ys):
        p.add(box((-w / 2 + 0.025, y, -d / 2), (w / 2 - 0.025, y + 0.025, d / 2), "walnut", 0.003))
        if y < 1.86:
            if i in (1, 2):
                x = -w / 2 + 0.04
                while x < w / 2 - 0.1:
                    p.add(box((x, y + 0.025, -d / 2 + 0.03), (x + 0.075, y + 0.33, d / 2 - 0.02), rng.choice(["sleeve_yellow", "card_cream", "plastic_blue", "paint_door_red"]), 0.004))
                    p.add(cyl(0.012, 0, 0.004, "steel", 8, m=move(x + 0.0375, y + 0.26, d / 2 - 0.02) @ rot_x(90)))
                    x += 0.08
            else:
                book_row(p, -w / 2 + 0.03, w / 2 - 0.03 - rng.uniform(0.0, 0.2), y + 0.025, -d / 2, d / 2 - 0.03, rng)
    return p


@prop
def mae_strongroom_door():
    """The old pawnbroker's strongroom door: 0.9 x 2.0 m of painted steel with rivets, a spoked
    handle and a brass dial. Hinged at the origin, spanning x -0.9..0, 0.12 thick."""
    p = Prop("mae_strongroom_door")
    w, h, t = 0.9, 2.0, 0.12
    p.add(box((-w + 0.004, 0.0, -t / 2), (-0.004, h, t / 2), "paint_door_green", 0.012))
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(face_box(-w + 0.06, 0.06, -0.06, h - 0.06, z, 0.012, zs, "paint_door_green", 0.008))
        for i in range(8):
            for x in (-w + 0.04, -0.04):
                p.add(sphere(0.01, "cast_iron", 6, 4, m=move(x, 0.15 + i * 0.25, z)))
    zf = t / 2 + 0.012
    # The spoked handle, the dial, the maker's plate (on the outer face, +z).
    p.add(cyl(0.035, 0.0, 0.05, "brass_aged", 10, m=move(-w * 0.5, 1.0, zf) @ rot_x(90)))
    for a in range(0, 360, 90):
        x, y = 0.16 * math.cos(math.radians(a)), 0.16 * math.sin(math.radians(a))
        p.add(tube([(-w * 0.5, 1.0, zf + 0.04), (-w * 0.5 + x, 1.0 + y, zf + 0.04)], 0.012, "brass_aged", 6))
        p.add(sphere(0.022, "brass", 8, 6, m=move(-w * 0.5 + x, 1.0 + y, zf + 0.04)))
    p.add(cyl(0.07, 0.0, 0.03, "brass", 20, m=move(-w * 0.5, 1.4, zf) @ rot_x(90)))
    p.add(cyl(0.055, 0.03, 0.045, "cast_iron", 16, m=move(-w * 0.5, 1.4, zf) @ rot_x(90)))
    p.add(box((-w * 0.5 - 0.15, 1.65, zf - 0.01), (-w * 0.5 + 0.15, 1.75, zf + 0.002), "brass_aged", 0.003))
    return p


@prop
def mae_strongroom_frame():
    """The strongroom door's heavy steel frame, on the study's face of the wall: the 0.9 x 2.0 m
    opening centred on x, back on z = 0. 1.3 x 2.25 m."""
    p = Prop("mae_strongroom_frame")
    ow, oh = 0.9, 2.0
    for s in (-1, 1):
        x = s * ow / 2
        p.add(box((min(x, x + s * 0.2), 0.0, 0.0), (max(x, x + s * 0.2), oh + 0.2, 0.06), "steel_dark", 0.01))
        for i in range(6):
            p.add(sphere(0.012, "cast_iron", 6, 4, m=move(x + s * 0.1, 0.2 + i * 0.36, 0.06)))
    p.add(box((-ow / 2 - 0.2, oh, 0.0), (ow / 2 + 0.2, oh + 0.25, 0.06), "steel_dark", 0.01))
    p.add(box((-0.25, oh + 0.06, 0.06), (0.25, oh + 0.18, 0.07), "brass_aged", 0.003))
    return p


@prop
def mae_dial():
    """The strongroom's combination dial on a steel plate by the door. Back on z = 0, 0.2 x 0.3 m;
    the dial's at y 0.15."""
    p = Prop("mae_dial")
    p.add(box((-0.1, 0.0, 0.0), (0.1, 0.3, 0.02), "steel_dark", 0.006))
    p.add(cyl(0.075, 0.0, 0.025, "brass", 24, m=move(0, 0.15, 0.02) @ rot_x(90)))
    p.add(cyl(0.05, 0.025, 0.05, "cast_iron", 16, m=move(0, 0.15, 0.02) @ rot_x(90)))
    p.add(box((-0.004, 0.22, 0.045), (0.004, 0.25, 0.05), "flame", 0.0))
    for i in range(10):
        a = math.radians(i * 36)
        p.add(box((-0.002, -0.008, 0.0), (0.002, 0.008, 0.002), "cast_iron", 0.0).xf(move(0.063 * math.sin(a), 0.15 + 0.063 * math.cos(a), 0.045)))
    return p


@prop
def mae_strongroom_shelves():
    """Steel shelves in the strongroom: deed boxes, ledgers, cash tins and a shoebox of photos.
    1.4 x 2.0 x 0.42 m, facing +Z."""
    p = Prop("mae_strongroom_shelves")
    w, h, d = 1.4, 2.0, 0.42
    for x in (-w / 2, w / 2 - 0.03):
        for z in (-d / 2, d / 2 - 0.03):
            p.add(box((x, 0.0, z), (x + 0.03, h, z + 0.03), "steel_dark", 0.003))
    rng = rng_for("strongroom")
    for y in (0.08, 0.55, 1.02, 1.49, 1.94):
        p.add(box((-w / 2, y, -d / 2), (w / 2, y + 0.02, d / 2), "steel_dark", 0.003))
        if y > 1.9:
            continue
        x = -w / 2 + 0.05
        while x < w / 2 - 0.2:
            kind = rng.random()
            if kind < 0.4:
                ww = rng.uniform(0.25, 0.35)
                p.add(box((x, y + 0.02, -d / 2 + 0.03), (x + ww, y + 0.02 + rng.uniform(0.15, 0.24), d / 2 - 0.04), rng.choice(["paint_door_green", "cast_iron", "paint_door_red"]), 0.01))
                p.add(box((x + ww / 2 - 0.04, y + 0.12, d / 2 - 0.04), (x + ww / 2 + 0.04, y + 0.14, d / 2 - 0.02), "brass_aged", 0.003))
            elif kind < 0.75:
                ww = 0.22
                book_row(p, x, x + ww, y + 0.02, -d / 2 + 0.05, d / 2 - 0.04, rng, ["leather_brown", "leather_oxblood", "card_black"])
            else:
                ww = rng.uniform(0.2, 0.28)
                p.add(box((x, y + 0.02, -d / 2 + 0.06), (x + ww, y + 0.13, d / 2 - 0.06), "cardboard", 0.006))
            x += ww + 0.03
    return p


@prop
def mae_rose():
    """The Rose: a pink diamond in an open box of black velvet. 0.1 x 0.1 x 0.1 m; the stone sits
    0.06 m up."""
    p = Prop("mae_rose")
    p.add(box((-0.05, 0.0, -0.04), (0.05, 0.045, 0.04), "velvet_black", 0.006))
    p.add(box((-0.05, 0.0, -0.006), (0.05, 0.075, 0.0), "velvet_black", 0.004).xf(move(0, 0.045, -0.04) @ rot_x(-20)))
    p.add(box((-0.04, 0.04, -0.03), (0.04, 0.046, 0.03), "silk" if False else "linen", 0.002))
    # A cushion cut: a flat table on top, facets down to a point.
    p.add(lathe([(0.0, -0.02), (0.022, 0.0), (0.024, 0.006), (0.015, 0.014), (0.0, 0.014)], "pink_gem", 8, m=move(0, 0.06, 0.0), cap=(False, False)))
    return p


@prop
def mae_case():
    """Julian Gray's jewel case: black leather, brass corners, the lid open and grey velvet
    inside with a hollow for the stone. 0.34 x 0.3 x 0.26 m."""
    p = Prop("mae_case")
    w, d, h = 0.34, 0.26, 0.1
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "leather_black", 0.008))
    p.add(box((-w / 2 + 0.02, h - 0.004, -d / 2 + 0.02), (w / 2 - 0.02, h + 0.002, d / 2 - 0.02), "velvet_navy", 0.002))
    for x in (-w / 2, w / 2 - 0.03):
        for z in (-d / 2, d / 2 - 0.03):
            p.add(box((x, 0.0, z), (x + 0.03, 0.03, z + 0.03), "brass", 0.003))
    p.add(box((-0.03, h - 0.04, d / 2), (0.03, h - 0.01, d / 2 + 0.01), "brass", 0.003))
    p.add(box((-w / 2, 0.0, -0.06), (w / 2, d - 0.02, 0.0), "leather_black", 0.008).xf(move(0, h, -d / 2) @ rot_x(-100)))
    p.add(box((-w / 2 + 0.02, 0.02, -0.003), (w / 2 - 0.02, d - 0.04, 0.0), "velvet_navy", 0.0).xf(move(0, h, -d / 2) @ rot_x(-100)))
    return p


@prop
def mae_files():
    """A stack of Mae's folders on the crew, a photo clipped to the top one. 0.36 x 0.12 x
    0.28 m."""
    p = Prop("mae_files")
    rng = rng_for("files")
    for i in range(5):
        a = rng.uniform(-6, 6)
        p.add(box((-0.16, i * 0.022, -0.12), (0.16, i * 0.022 + 0.02, 0.12), ["card_cream", "sleeve_yellow", "card_cream", "plastic_blue", "card_cream"][i], 0.003).xf(rot_y(a)))
    p.add(box((-0.06, 0.112, -0.06), (0.06, 0.115, 0.08), "photo", 0.0).xf(rot_y(8)))
    p.add(box((-0.02, 0.11, 0.07), (0.02, 0.12, 0.09), "steel", 0.002))
    return p


# --- The terrace, the yard -----------------------------------------------------------------------

@prop
def mae_terrace_table():
    """A slatted garden table, weathered, with a jug of flowers and a candle in a jar.
    1.2 x 0.85 x 0.7 m."""
    p = Prop("mae_terrace_table")
    w, h, d = 1.2, 0.74, 0.7
    for i in range(6):
        z = -d / 2 + i * d / 6
        p.add(box((-w / 2, h - 0.03, z + 0.006), (w / 2, h, z + d / 6 - 0.006), "wood_pallet", 0.005))
    for x in (-w / 2 + 0.08, w / 2 - 0.08):
        p.add(box((x - 0.03, h - 0.08, -d / 2 + 0.03), (x + 0.03, h - 0.03, d / 2 - 0.03), "wood_pallet", 0.004))
        for z in (-d / 2 + 0.06, d / 2 - 0.06):
            p.add(leg(x, z, h - 0.03, 0.05, "wood_pallet"))
    p.add(lathe([(0.05, 0.0), (0.06, 0.1), (0.04, 0.16), (0.045, 0.18)], "enamel_white", 12, m=move(0.35, h, -0.15)))
    for k in range(6):
        a = k * 60
        p.add(sphere(0.03, ["rose_red", "sleeve_yellow", "rose_white"][k % 3], 6, 4, m=move(0.35 + 0.04 * math.cos(math.radians(a)), h + 0.22, -0.15 + 0.04 * math.sin(math.radians(a)))))
    p.add(lathe([(0.04, 0.0), (0.045, 0.1)], "glass", 10, m=move(-0.4, h, 0.15), cap=(True, False)))
    p.add(cyl(0.02, 0.0, 0.04, "wax", 8, m=move(-0.4, h, 0.15)))
    p.add(sphere(0.008, "flame", 6, 4, m=move(-0.4, h + 0.05, 0.15), squash=1.6))
    return p


@prop
def mae_terrace_chair():
    """A folding garden chair, slatted wood on a green frame, facing +Z. 0.46 x 0.85 x 0.55 m."""
    p = Prop("mae_terrace_chair")
    sh = 0.45
    for x in (-0.2, 0.2):
        p.add(tube([(x, 0.0, -0.22), (x, sh, 0.05), (x, 0.0, 0.25)], 0.014, "paint_door_green", 6))
        p.add(tube([(x, sh - 0.02, -0.18), (x, 0.85, -0.26)], 0.014, "paint_door_green", 6))
    for i in range(4):
        z = -0.17 + i * 0.1
        p.add(box((-0.22, sh, z), (0.22, sh + 0.02, z + 0.08), "wood_pallet", 0.004))
    for i in range(3):
        y = 0.55 + i * 0.1
        p.add(box((-0.22, y, -0.23 - (y - 0.45) * 0.1), (0.22, y + 0.07, -0.21 - (y - 0.45) * 0.1), "wood_pallet", 0.004))
    return p


@prop
def mae_planter():
    """A wooden trough of herbs and geraniums. 1.2 x 0.75 x 0.42 m."""
    p = Prop("mae_planter")
    w, h, d = 1.2, 0.4, 0.42
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "wood_pallet", 0.008))
    p.add(box((-w / 2 + 0.03, h - 0.06, -d / 2 + 0.03), (w / 2 - 0.03, h - 0.02, d / 2 - 0.03), "soil", 0.0))
    rng = rng_for("planter")
    for i in range(12):
        x, z = rng.uniform(-w / 2 + 0.1, w / 2 - 0.1), rng.uniform(-0.1, 0.1)
        hh = rng.uniform(0.12, 0.32)
        p.add(sphere(rng.uniform(0.07, 0.12), rng.choice(["leaf", "leaf_dark"]), 8, 5, m=move(x, h + hh * 0.6, z), squash=0.8))
        if i % 3 == 0:
            p.add(sphere(0.035, "rose_red", 6, 4, m=move(x + 0.03, h + hh, z + 0.03)))
    return p


@prop
def mae_pot_tree():
    """A terracotta pot with a little lemon tree. 0.5 x 1.4 x 0.5 m."""
    p = Prop("mae_pot_tree")
    p.add(lathe([(0.16, 0.0), (0.22, 0.4), (0.24, 0.42), (0.24, 0.45)], "terracotta", 14, cap=(True, False)))
    p.add(cyl(0.21, 0.36, 0.38, "soil", 14))
    p.add(tube([(0.0, 0.38, 0.0), (0.02, 0.8, 0.01), (-0.01, 1.0, 0.0)], 0.025, "walnut_dark", 6))
    rng = rng_for("lemon")
    for i in range(9):
        a, r = rng.uniform(0, 6.28), rng.uniform(0.05, 0.22)
        p.add(sphere(rng.uniform(0.1, 0.16), rng.choice(["leaf", "leaf_dark"]), 8, 5, m=move(r * math.cos(a), 1.0 + rng.uniform(-0.1, 0.3), r * math.sin(a))))
    for i in range(4):
        a = rng.uniform(0, 6.28)
        p.add(sphere(0.035, "sleeve_yellow", 8, 5, m=move(0.2 * math.cos(a), 0.95 + rng.uniform(0, 0.2), 0.2 * math.sin(a)), squash=1.3))
    return p


@prop
def mae_chimney():
    """The old wash house's chimney stack on the terrace: brick, a stone cap and two pots.
    1.2 x 2.6 x 0.9 m."""
    p = Prop("mae_chimney")
    w, h, d = 1.2, 1.9, 0.9
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, h, d / 2), "brick_red", 0.01))
    for y in (0.3, 0.9, 1.5):
        p.add(box((-w / 2 - 0.005, y, -d / 2 - 0.005), (w / 2 + 0.005, y + 0.015, d / 2 + 0.005), "plaster_mortar" if False else "paint_cream", 0.0))
    p.add(box((-w / 2 - 0.05, h, -d / 2 - 0.05), (w / 2 + 0.05, h + 0.1, d / 2 + 0.05), "paint_grey", 0.01))
    for x in (-0.26, 0.26):
        p.add(lathe([(0.13, 0.0), (0.12, 0.08), (0.1, 0.5), (0.12, 0.56), (0.11, 0.6)], "terracotta", 12, m=move(x, h + 0.1, 0), cap=(True, False)))
    return p


@prop
def mae_iron_stairs():
    """The iron stairs from the terrace down into the yard: one straight flight, 1.2 m wide,
    rising 3.6 m over 6.3 m toward -Z from the foot at z = 0, with open grating treads and a
    rail each side."""
    p = Prop("mae_iron_stairs")
    w, rise, run = 1.2, 3.6, 6.3
    n = 18
    step_r, step_t = rise / n, run / n
    for s in (-1, 1):
        x = s * (w / 2 - 0.03)
        p.add(box((x - 0.02, -0.12, -0.08), (x + 0.02, 0.12, 0.08), "paint_iron", 0.003).xf(move(0, 0, 0)))
        L = math.hypot(rise, run)
        ang = math.degrees(math.atan2(rise, run))
        p.add(box((x - 0.012, -0.12, -L), (x + 0.012, 0.12, 0.0), "paint_iron", 0.003).xf(rot_x(ang)))
        # The rail, its posts every third step.
        p.add(tube([(x, 0.95, 0.0), (x, rise + 0.95, -run)], 0.022, "paint_iron", 6))
        for i in range(0, n + 1, 3):
            z = -i * step_t
            p.add(tube([(x, i * step_r, z), (x, i * step_r + 0.95, z)], 0.014, "paint_iron", 5))
        p.add(tube([(x, rise * 0.5 + 0.45, -run * 0.5 - 0.3), (x, rise * 0.5 + 0.45 + 0.02, -run * 0.5 + 0.3)], 0.008, "paint_iron", 4))
    for i in range(n):
        y = (i + 1) * step_r
        z = -i * step_t
        p.add(box((-w / 2 + 0.05, y - 0.03, z - step_t - 0.02), (w / 2 - 0.05, y, z), "grating", 0.003))
    return p


@prop
def mae_gate():
    """The yard gate: painted planks on ledges and a brace, a ring latch and a bolt. 1.2 x 1.95 m,
    hinged at the origin, spanning x -1.2..0."""
    p = Prop("mae_gate")
    w, h, t = 1.2, 1.95, 0.04
    n = 9
    for i in range(n):
        x0 = -w + i * w / n + 0.004
        p.add(box((x0, 0.0, -t / 2), (x0 + w / n - 0.008, h - (0.03 if i % 2 else 0.0), t / 2), "paint_door_green", 0.004))
    for y in (0.25, h - 0.3):
        p.add(box((-w + 0.05, y, -t / 2 - 0.03), (-0.05, y + 0.14, -t / 2), "paint_door_green", 0.004))
    L = math.hypot(w - 0.2, h - 0.85)
    ang = math.degrees(math.atan2(h - 0.85, w - 0.2))
    p.add(box((0.0, -0.06, -t / 2 - 0.028), (L, 0.06, -t / 2), "paint_door_green", 0.004).xf(move(-w + 0.1, 0.39, 0) @ rot_z(ang)))
    for zs in (-1, 1):
        p.add(lathe([(0.04, 0.0), (0.045, 0.01)], "cast_iron", 10, m=move(-w + 0.1, 1.0, zs * (t / 2 + 0.01)) @ rot_x(90), cap=(False, False)))
    p.add(box((-w + 0.05, 1.3, t / 2), (-w + 0.25, 1.33, t / 2 + 0.03), "cast_iron", 0.003))
    for y in (0.35, h - 0.25):
        p.add(box((-0.25, y - 0.025, t / 2), (0.0, y + 0.025, t / 2 + 0.008), "cast_iron", 0.002))
    return p


@prop
def mae_back_door():
    """The back door to the yard: painted wood, four panes of glass over two panels, a brass
    knob. 0.95 x 2.15 m, hinged at the origin, spanning x -0.95..0."""
    p = Prop("mae_back_door")
    w, h, t = 0.95, 2.15, 0.05
    leaf_base(p, w, 1.15, t, "paint_door_red")
    for zs in (-1, 1):
        z = zs * t / 2
        for x0, x1 in ((0.1, 0.45), (0.5, 0.85)):
            p.add(face_box(-w + x0 + 0.02, 0.15, -w + x1 - 0.02, 1.0, z, 0.008, zs, "paint_door_red", 0.006))
    s = 0.09
    p.add(box((-w, 1.15, -t / 2), (-w + s, h, t / 2), "paint_door_red", 0.004))
    p.add(box((-s, 1.15, -t / 2), (0.0, h, t / 2), "paint_door_red", 0.004))
    p.add(box((-w + s, h - s, -t / 2), (-s, h, t / 2), "paint_door_red", 0.004))
    p.add(box((-w + s, 1.6, -t / 2), (-s, 1.64, t / 2), "paint_door_red", 0.003))
    p.add(box((-w / 2 - 0.02, 1.15, -t / 2), (-w / 2 + 0.02, h - s, t / 2), "paint_door_red", 0.003))
    p.add(box((-w + s, 1.15, -0.004), (-s, h - s, 0.004), "glass", 0.0))
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(cyl(0.028, 0, 0.012, "brass", 8, m=move(-w + 0.08, 1.0, z) @ rot_x(90 * zs)))
        p.add(sphere(0.03, "brass", 10, 6, m=move(-w + 0.08, 1.0, z + zs * 0.06)))
        p.add(cyl(0.008, 0, 0.05, "brass", 6, m=move(-w + 0.08, 1.0, z) @ rot_x(90 * zs)))
    return p


@prop
def mae_panel_door():
    """An inside door: four raised panels painted cream, a brass knob. 0.95 x 2.1 m, hinged at
    the origin, spanning x -0.95..0."""
    p = Prop("mae_panel_door")
    w, h, t = 0.95, 2.1, 0.045
    panel_leaf(p, w, h, t, "paint_door_cream", [(0.1, 0.15, 0.45, 0.95), (0.5, 0.15, 0.85, 0.95), (0.1, 1.1, 0.45, 1.95), (0.5, 1.1, 0.85, 1.95)])
    return p


@prop
def mae_glazed_door():
    """The door onto the terrace: a wooden frame round six panes over a panel, a brass knob.
    0.95 x 2.15 m, hinged at the origin, spanning x -0.95..0."""
    p = Prop("mae_glazed_door")
    w, h, t = 0.95, 2.15, 0.05
    s = 0.08
    p.add(box((-w, 0.0, -t / 2), (-w + s, h, t / 2), "paint_door_cream", 0.004))
    p.add(box((-s, 0.0, -t / 2), (0.0, h, t / 2), "paint_door_cream", 0.004))
    p.add(box((-w + s, h - s, -t / 2), (-s, h, t / 2), "paint_door_cream", 0.004))
    p.add(box((-w + s, 0.0, -t / 2), (-s, 0.55, t / 2), "paint_door_cream", 0.004))
    for zs in (-1, 1):
        p.add(face_box(-w + s + 0.04, 0.1, -s - 0.04, 0.46, zs * t / 2, 0.008, zs, "paint_door_cream", 0.006))
    for y in (0.55 + (h - s - 0.55) / 3, 0.55 + 2 * (h - s - 0.55) / 3):
        p.add(box((-w + s, y - 0.015, -t / 2 + 0.008), (-s, y + 0.015, t / 2 - 0.008), "paint_door_cream", 0.002))
    p.add(box((-w / 2 - 0.015, 0.55, -t / 2 + 0.008), (-w / 2 + 0.015, h - s, t / 2 - 0.008), "paint_door_cream", 0.002))
    p.add(box((-w + s, 0.55, -0.004), (-s, h - s, 0.004), "glass", 0.0))
    for zs in (-1, 1):
        z = zs * t / 2
        p.add(sphere(0.03, "brass", 10, 6, m=move(-w + 0.06, 1.0, z + zs * 0.06)))
        p.add(cyl(0.008, 0, 0.05, "brass", 6, m=move(-w + 0.06, 1.0, z) @ rot_x(90 * zs)))
    return p


@prop
def mae_whirligig():
    """A rotary washing line in the yard with a sheet and some shirts pegged out. 2.4 x 2.0 m."""
    p = Prop("mae_whirligig")
    p.add(cyl(0.025, 0.0, 1.85, "steel", 8))
    for a in (0, 90, 180, 270):
        x, z = 1.1 * math.cos(math.radians(a)), 1.1 * math.sin(math.radians(a))
        p.add(tube([(0.0, 1.7, 0.0), (x, 1.82, z)], 0.01, "steel", 5))
    for r in (0.4, 0.75, 1.05):
        pts = [(r * math.cos(math.radians(a)), 1.72 + r * 0.1, r * math.sin(math.radians(a))) for a in range(0, 361, 30)]
        p.add(tube(pts, 0.003, "paper", 3))
    p.add(grid_sheet(1.0, 0.9, 12, 6, "cloth_white", lambda x, y: 0.05 * math.sin(x * 9.0 + y * 2.0) * (1.2 - y),
                     m=move(0.0, 0.88, 0.75) @ rot_y(0), thickness=0.004))
    p.add(grid_sheet(0.45, 0.6, 3, 3, "cloth_blue", lambda x, y: 0.02 * math.sin(y * 5.0), m=move(-0.75, 1.18, 0.05) @ rot_y(90)))
    p.add(grid_sheet(0.45, 0.55, 3, 3, "cloth_check", lambda x, y: 0.02 * math.sin(y * 5.0), m=move(0.05, 1.2, -0.75)))
    return p


@prop
def mae_crates():
    """Empty bottle crates stacked by the back door after the party's first run. 0.5 x 0.9 x
    0.35 m."""
    p = Prop("mae_crates")
    rng = rng_for("crates")
    for i in range(3):
        y = i * 0.3
        a = rng.uniform(-6, 6)
        p.add(box((-0.25, y, -0.17), (0.25, y + 0.29, 0.17), ["plastic_blue", "paint_door_red", "plastic_blue"][i], 0.01).xf(rot_y(a)))
        for k in range(4):
            p.add(cyl(0.03, y + 0.29, y + 0.36, "bottle_green" if k % 2 else "bottle_amber", 8, m=rot_y(a) @ move(-0.15 + k * 0.1, 0, 0.05)))
    return p


# --- The street ----------------------------------------------------------------------------------

@prop
def mae_car():
    """A boxy old saloon car, parked: one paint ("car_paint", tinted in the game), chrome bumpers,
    dark glass. 1.75 x 1.4 x 4.4 m, its front toward +Z."""
    p = Prop("mae_car")
    w, L = 1.72, 4.4
    # The body: a lower box, the cabin on top with sloped screens.
    p.add(box((-w / 2, 0.28, -L / 2), (w / 2, 0.82, L / 2), "car_paint", 0.05, 3))
    cab = [(-L / 2 + 0.55, 0.82), (-L / 2 + 0.95, 1.32), (L / 2 - 1.55, 1.32), (L / 2 - 1.05, 0.82)]
    p.add(prism([(z, y) for z, y in cab], w - 0.12, "car_paint", plane="zy", bevel=0.03))
    # Glass inset on the cabin's sides and screens.
    for s in (-1, 1):
        x = s * (w / 2 - 0.055)
        p.add(prism([(-L / 2 + 0.68, 0.86), (-L / 2 + 1.0, 1.27), (L / 2 - 1.6, 1.27), (L / 2 - 1.18, 0.86)], 0.01, "glass_car", plane="zy", m=move(x, 0, 0), bevel=0.0))
    ang = math.degrees(math.atan2(0.5, 0.5))
    p.add(box((-w / 2 + 0.12, 0.0, -0.005), (w / 2 - 0.12, 0.62, 0.005), "glass_car", 0.0).xf(move(0, 0.86, L / 2 - 1.08) @ rot_x(-ang)))
    p.add(box((-w / 2 + 0.12, 0.0, -0.005), (w / 2 - 0.12, 0.6, 0.005), "glass_car", 0.0).xf(move(0, 0.86, -L / 2 + 0.58) @ rot_x(ang)))
    # Bumpers, lamps, grille, plates.
    for zs in (-1, 1):
        z = zs * (L / 2 + 0.02)
        p.add(box((-w / 2 - 0.02, 0.3, z - 0.06), (w / 2 + 0.02, 0.42, z + 0.06), "chrome", 0.03))
        p.add(box((-0.25, 0.44, z - 0.01 * zs), (0.25, 0.56, z + 0.005 * zs if zs > 0 else z), "card_cream", 0.002).xf(move(0, 0, -0.02 * zs)))
        for s in (-1, 1):
            if zs > 0:
                p.add(cyl(0.09, -0.02, 0.03, "headlamp", 14, m=move(s * (w / 2 - 0.25), 0.66, L / 2) @ rot_x(90)))
            else:
                p.add(box((s * (w / 2 - 0.12) - 0.12, 0.58, -L / 2 - 0.02), (s * (w / 2 - 0.12) + 0.12, 0.72, -L / 2 + 0.01), "tail_red", 0.01))
    p.add(box((-0.42, 0.56, L / 2), (0.42, 0.76, L / 2 + 0.02), "chrome", 0.006))
    # Wheels.
    for s in (-1, 1):
        for zs in (-1, 1):
            m = move(s * (w / 2 - 0.12), 0.32, zs * (L / 2 - 0.78)) @ rot_z(90)
            p.add(cyl(0.32, -0.11, 0.11, "rubber", 16, m=m, bevel=0.03))
            p.add(cyl(0.17, -0.115, 0.115, "chrome", 12, m=m, bevel=0.0))
    # A shadow of the dashboard and seats through the glass.
    p.add(box((-w / 2 + 0.15, 0.82, L / 2 - 1.2), (w / 2 - 0.15, 0.95, L / 2 - 1.0), "plastic_black", 0.01))
    for z in (-0.25, -1.0):
        p.add(box((-w / 2 + 0.2, 0.6, z - 0.25), (w / 2 - 0.2, 1.1, z + 0.05), "leather_brown", 0.04))
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
        export(PROPS[name](), os.path.join(OUT, name + ".glb"))


if __name__ == "__main__":
    main()
