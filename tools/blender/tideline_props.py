"""Builds the Tideline's furniture and fittings and writes each one as a GLB.

Run from the repository root with a Python that has the `bpy` module (the venv that builds the
Meridian's props):

    python tools/blender/tideline_props.py [prop ...]

Naming props rebuilds only those; `--list` prints them. They go to assets/models/tideline/,
where `Kit` finds them by name, so every name starts with `tideline_`. The felts, the slot
machines' glass and the surveillance feeds are pictures from tools/tideline_textures.py.

The conventions are the Meridian's (tools/blender/props.py): Godot's axes, metres, floor props
on y = 0 centred on their footprint with their front (the players' side) toward +Z, wall props
with their back on z = 0, hanging props from y = their height down to y = 0, and door leaves
hinged at the origin spanning -x. Materials named `slot_art` and `feed` glow with their
picture in the game (Tideline._dress).
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
import props  # noqa: E402
from props import Prop, box, cyl, lathe, tube, prism, sphere, octa, move, rot_x, rot_y, rot_z, scale, cushion, steel_table  # noqa: E402

OUT = os.path.join(props.ROOT, "assets", "models", "tideline")
TEX = os.path.join(props.ROOT, "assets", "textures", "tideline")


def tex(name):
    return os.path.join(TEX, name + ".png")


props.MATERIALS.update({
    "felt_bj": ("#ffffff", 0.0, 0.92, {"tex": tex("felt_blackjack")}),
    "felt_roulette": ("#ffffff", 0.0, 0.92, {"tex": tex("felt_roulette")}),
    "felt_craps": ("#ffffff", 0.0, 0.92, {"tex": tex("felt_craps")}),
    "felt_baccarat": ("#ffffff", 0.0, 0.92, {"tex": tex("felt_baccarat")}),
    "felt_plain": ("#155a3a", 0.0, 0.92, {}),
    "wheel": ("#ffffff", 0.2, 0.25, {"tex": tex("wheel_roulette")}),
    "slot_art": ("#ffffff", 0.0, 0.2, {"tex": tex("slot_art")}),
    "feed": ("#ffffff", 0.0, 0.2, {"tex": tex("cctv_feed")}),
    "leather_rail": ("#2b1a12", 0.0, 0.42, {}),
    "lacquer_black": ("#0c0c0e", 0.2, 0.18, {}),
    "slot_glow_pink": ("#ff5aa8", 0.0, 0.3, {"emit": "#ff3c96", "strength": 3.0}),
    "slot_glow_cyan": ("#5af0ff", 0.0, 0.3, {"emit": "#2ee6ff", "strength": 3.0}),
    "slot_glow_gold": ("#ffd77a", 0.0, 0.3, {"emit": "#ffc24a", "strength": 3.0}),
    "button_red": ("#ff3030", 0.0, 0.3, {"emit": "#ff2020", "strength": 2.0}),
    "button_amber": ("#ffb030", 0.0, 0.3, {"emit": "#ffa020", "strength": 2.0}),
    "neon_cyan": ("#7ff6ff", 0.0, 0.3, {"emit": "#3ef0ff", "strength": 9.0}),
    "neon_pink": ("#ff7ac0", 0.0, 0.3, {"emit": "#ff3ca0", "strength": 9.0}),
    "neon_gold": ("#ffe09a", 0.0, 0.3, {"emit": "#ffc860", "strength": 8.0}),
    "vault_steel": ("#6d7276", 1.0, 0.38, {}),
    "vault_dark": ("#2e3134", 0.9, 0.45, {}),
    "cash_green": ("#7f9a6c", 0.0, 0.8, {}),
    "cash_band": ("#d9c58a", 0.0, 0.7, {}),
    "chip_red": ("#b0202a", 0.0, 0.45, {}),
    "chip_blue": ("#1f4aa0", 0.0, 0.45, {}),
    "chip_black": ("#16161a", 0.0, 0.45, {}),
    "chip_green": ("#1d7a3a", 0.0, 0.45, {}),
    "chip_white": ("#e8e6e0", 0.0, 0.45, {}),
    "chip_purple": ("#5a2a8a", 0.0, 0.45, {}),
    "card_white": ("#f4f2ec", 0.0, 0.5, {}),
    "card_back": ("#7a1420", 0.0, 0.5, {}),
    "pink_diamond": ("#ff9cc8", 0.0, 0.02, {"emit": "#ff6aa8", "strength": 1.6}),
    "velvet_black": ("#0e0d10", 0.0, 0.85, {}),
    "satin_white": ("#ece6dc", 0.0, 0.35, {}),
    "hull_white": ("#e9eaea", 0.1, 0.3, {}),
    "hull_navy": ("#14203a", 0.2, 0.3, {}),
    "teak": ("#8a6038", 0.0, 0.5, {}),
    "window_lit": ("#ffd9a0", 0.0, 0.4, {"emit": "#ffc880", "strength": 2.5}),
    "glass_black": ("#05070a", 0.6, 0.05, {}),
    "plastic_yellow": ("#e2b320", 0.0, 0.45, {}),
    "plastic_blue": ("#2a5da8", 0.0, 0.45, {}),
    "plastic_grey": ("#8a8e92", 0.0, 0.5, {}),
    "mop": ("#c9c2b0", 0.0, 0.95, {}),
    "paint_rail": ("#1d2a2a", 0.4, 0.5, {}),
    "paint_box": ("#7b8186", 0.5, 0.5, {}),
    "conduit": ("#9aa0a4", 0.8, 0.4, {}),
    "stage_floor": ("#2b1c12", 0.0, 0.42, {}),
})


# --- Tables ------------------------------------------------------------------------------------------

def half_ellipse(rx, rz, z0, n=24):
    """The outline of a half-moon table: the straight edge at z0, the arc toward +z."""
    return [(rx * math.cos(math.pi * i / n), z0 + rz * math.sin(math.pi * i / n)) for i in range(n + 1)]


def arc_pts(rx, rz, z0, y, n=24, inset=0.0):
    return [((rx - inset) * math.cos(math.pi * i / n), y, z0 + (rz - inset) * math.sin(math.pi * i / n)) for i in range(n + 1)]


def chip_stack(x, y, z, n, mat, r=0.02):
    return cyl(r, y, y + 0.0035 * n, mat, 10, m=move(x, 0, z), bevel=0.002)


def chip_rack(p, x, z, y, w=0.7, rows=8):
    """A dealer's chip rack sunk in the table's edge: rows of chips in their colours."""
    p.add(box((x - w / 2, y - 0.03, z - 0.09), (x + w / 2, y + 0.012, z + 0.09), "lacquer_black", 0.004))
    mats = ["chip_white", "chip_red", "chip_red", "chip_green", "chip_green", "chip_black", "chip_purple", "chip_blue"]
    for i in range(rows):
        cx = x - w / 2 + (i + 0.5) * w / rows
        p.add(box((cx - w / rows / 2 + 0.006, y - 0.005, z - 0.08), (cx + w / rows / 2 - 0.006, y + 0.025, z + 0.08), mats[i % len(mats)], 0.008))


def table_base(p, outline, y_top, inset=0.12):
    """The cabinet under a table: walnut on a black plinth, smaller than the top."""
    xs = [a for a, _ in outline]
    zs = [b for _, b in outline]
    cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    def shrink(k):
        return [(cx + (a - cx) * k, cz + (b - cz) * k) for a, b in outline]
    p.add(prism(shrink(0.82), y_top - 0.14, "walnut_dark", plane="xz", m=move(0, 0.12 + (y_top - 0.14) / 2, 0), bevel=0.01))
    p.add(prism(shrink(0.76), 0.12, "lacquer_black", plane="xz", m=move(0, 0.06, 0), bevel=0.006))


@props.prop
def tideline_blackjack():
    """A blackjack table: a half moon 2.2 x 1.25 m, 0.84 m high, the dealer's straight side at
    -Z with the chip rack, the shoe and the discards, seven places round the padded rail at +Z,
    and chips and cards out on two of them."""
    p = Prop("tideline_blackjack")
    rx, rz, z0, y = 1.1, 1.25, -0.5, 0.8
    out = half_ellipse(rx, rz, z0)
    table_base(p, out, y)
    p.add(prism(out, 0.04, "walnut", plane="xz", m=move(0, y - 0.02, 0), bevel=0.01))
    felt = half_ellipse(rx - 0.07, rz - 0.07, z0 + 0.0)
    top = prism(felt, 0.012, "felt_bj", plane="xz", m=move(0, y + 0.006, 0), bevel=0.0)
    top.uv = ("x", "z", 1 / (2 * rx), -1 / rz, 0.5, (rz + z0) / rz)
    p.add(top)
    p.add(tube(arc_pts(rx, rz, z0, y + 0.035, 28, 0.02), 0.045, "leather_rail", 10))
    p.add(box((-rx, y, z0 - 0.04), (rx, y + 0.04, z0 + 0.04), "walnut", 0.012))
    chip_rack(p, 0.0, z0 + 0.12, y + 0.02)
    # The shoe and the discard holder.
    p.add(prism([(0, 0), (0.19, 0), (0.19, 0.09), (0.04, 0.12), (0, 0.12)], 0.12, "lacquer_black", plane="zy", m=move(0.62, y + 0.012, z0 + 0.18) @ rot_y(-90), bevel=0.006))
    p.add(box((0.58, y + 0.09, z0 + 0.25), (0.66, y + 0.095, z0 + 0.34), "card_back", 0.0))
    p.add(box((-0.72, y + 0.012, z0 + 0.12), (-0.56, y + 0.08, z0 + 0.24), "glass_dark", 0.004))
    p.add(box((-0.71, y + 0.014, z0 + 0.13), (-0.57, y + 0.05, z0 + 0.23), "card_white", 0.0))
    # A brass limit sign at the dealer's right.
    p.add(box((0.9, y, z0 + 0.06), (1.02, y + 0.11, z0 + 0.08), "brass", 0.003))
    # Play on two places: chips on the spot, cards in front.
    rng = random.Random(4)
    for k in (1, 4, 5):
        a = math.radians(-54 + k * 18)
        sx, sz = 0.94 * math.sin(a), z0 + 1.07 * math.cos(a)
        p.add(chip_stack(sx, y + 0.012, sz, 3 + rng.randrange(6), ["chip_red", "chip_green", "chip_black"][k % 3]))
        cx, cz = 0.75 * math.sin(a), z0 + 0.84 * math.cos(a)
        for j in range(2):
            p.add(box((-0.03, 0, -0.045), (0.03, 0.002, 0.045), "card_white", 0.0, m=move(cx + j * 0.025, y + 0.013 + j * 0.002, cz) @ rot_y(-math.degrees(a) + rng.uniform(-8, 8))))
    for j in range(2):
        p.add(box((-0.03, 0, -0.045), (0.03, 0.002, 0.045), "card_white" if j else "card_back", 0.0, m=move(-0.04 + j * 0.07, y + 0.013, z0 + 0.36)))
    return p


@props.prop
def tideline_baccarat():
    """The high-limit room's baccarat table: a burgundy half moon 2.8 x 1.5 m, 0.84 m high, the
    dealer's side at -Z with a deep chip float, the shoe, and plaques out on the layout."""
    p = Prop("tideline_baccarat")
    rx, rz, z0, y = 1.4, 1.5, -0.6, 0.8
    out = half_ellipse(rx, rz, z0, 28)
    table_base(p, out, y)
    p.add(prism(out, 0.04, "walnut", plane="xz", m=move(0, y - 0.02, 0), bevel=0.01))
    felt = half_ellipse(rx - 0.07, rz - 0.07, z0, 28)
    top = prism(felt, 0.012, "felt_baccarat", plane="xz", m=move(0, y + 0.006, 0), bevel=0.0)
    top.uv = ("x", "z", 1 / (2 * rx), -1 / rz, 0.5, (rz + z0) / rz)
    p.add(top)
    p.add(tube(arc_pts(rx, rz, z0, y + 0.035, 32, 0.02), 0.05, "leather_rail", 10))
    p.add(box((-rx, y, z0 - 0.04), (rx, y + 0.04, z0 + 0.04), "walnut", 0.012))
    chip_rack(p, 0.0, z0 + 0.13, y + 0.02, 1.0, 10)
    p.add(prism([(0, 0), (0.2, 0), (0.2, 0.09), (0.04, 0.12), (0, 0.12)], 0.13, "lacquer_black", plane="zy", m=move(0.8, y + 0.012, z0 + 0.2) @ rot_y(-90), bevel=0.006))
    rng = random.Random(9)
    for k in range(5):
        a = math.radians(-40 + k * 20)
        sx, sz = 1.05 * math.sin(a), z0 + 1.1 * math.cos(a)
        p.add(box((-0.05, 0, -0.03), (0.05, 0.008, 0.03), "chip_purple" if k % 2 else "chip_black", 0.003, m=move(sx, y + 0.013, sz) @ rot_y(-math.degrees(a))))
        p.add(chip_stack(sx + 0.08, y + 0.012, sz - 0.04, 4 + rng.randrange(6), "chip_black"))
    return p


@props.prop
def tideline_roulette():
    """A roulette table, 3.0 x 1.4 m, 0.84 m high: the wheel in its walnut bowl at the -X end,
    the layout toward +X, the croupier's side at -Z, a padded rail round the players' side, the
    dolly, and colour chips out on the numbers."""
    p = Prop("tideline_roulette")
    w, d, y = 3.0, 1.4, 0.8
    r_c = 0.3
    out = []
    for cx, cz, a0 in ((w / 2 - r_c, d / 2 - r_c, 0), (-w / 2 + r_c, d / 2 - r_c, 90), (-w / 2 + r_c, -d / 2 + r_c, 180), (w / 2 - r_c, -d / 2 + r_c, 270)):
        for i in range(5):
            a = math.radians(a0 + i * 22.5)
            out.append((cx + r_c * math.cos(a), cz + r_c * math.sin(a)))
    table_base(p, out, y)
    p.add(prism(out, 0.04, "walnut", plane="xz", m=move(0, y - 0.02, 0), bevel=0.01))
    inner = [(a * 0.97, b * 0.94) for a, b in out]
    top = prism(inner, 0.012, "felt_roulette", plane="xz", m=move(0, y + 0.006, 0), bevel=0.0)
    top.uv = ("x", "z", 1 / w, -1 / d, 0.5, 0.5)
    p.add(top)
    # The padded rail round the players' side and the far end.
    rail = [(x, y + 0.035, d / 2 - 0.03) for x in (-0.4, w / 2 - r_c)]
    rail += [(w / 2 - r_c + (r_c - 0.03) * math.cos(math.radians(a)), y + 0.035, d / 2 - r_c + (r_c - 0.03) * math.sin(math.radians(a))) for a in (30, 0, -30, -60)]
    rail += [(w / 2 - 0.03, y + 0.035, -d / 2 + r_c)]
    p.add(tube([rail[0]] + rail[1:2] + rail[2:], 0.045, "leather_rail", 10))
    # The wheel: a walnut bowl, the pockets under glassy lacquer, the brass turret.
    wx = -w / 2 + 0.5
    bowl = lathe([(0.0, y), (0.46, y), (0.47, y + 0.1), (0.44, y + 0.13), (0.41, y + 0.11), (0.39, y + 0.1)], "walnut", 40, cap=(True, False))
    p.add(bowl.xf(move(wx, 0, 0)))
    wheel = cyl(0.39, y + 0.07, y + 0.1, "wheel", 40, bevel=0)
    wheel.uv = ("x", "z", 1 / 0.8, -1 / 0.8, 0.5 - wx / 0.8, 0.5)
    p.add(wheel.xf(move(wx, 0, 0)))
    p.add(lathe([(0.06, y + 0.1), (0.04, y + 0.16), (0.012, y + 0.2), (0.0, y + 0.21)], "brass", 12, m=move(wx, 0, 0)))
    for k in range(4):
        a = math.radians(45 + 90 * k)
        p.add(tube([(wx + 0.03 * math.cos(a), y + 0.17, 0.03 * math.sin(a)), (wx + 0.1 * math.cos(a), y + 0.18, 0.1 * math.sin(a))], 0.008, "brass", 6))
    p.add(sphere(0.011, "chip_white", 8, 6, m=move(wx + 0.3, y + 0.105, 0.12)))
    # The dolly, and chips on the layout.
    p.add(lathe([(0.025, y + 0.012), (0.02, y + 0.06), (0.03, y + 0.08), (0.0, y + 0.085)], "chrome", 10, m=move(0.42, 0, -0.08)))
    rng = random.Random(12)
    mats = ["chip_red", "chip_blue", "chip_green", "chip_purple", "chip_white"]
    for k in range(14):
        x = -0.3 + rng.random() * 1.6
        z = -0.4 + rng.random() * 0.75
        p.add(chip_stack(x, y + 0.012, z, 1 + rng.randrange(5), mats[k % len(mats)], 0.017))
    return p


@props.prop
def tideline_craps():
    """A craps table, 3.6 x 1.6 m with its rail at 1.0 m: a walnut tub round a sunken felt bed,
    a chip groove in the rail, a mirrored bumper wall, the boxman's chip float at -Z, and dice
    and the stick on the bed."""
    p = Prop("tideline_craps")
    w, d = 3.6, 1.6
    rr = d / 2
    out = []
    for side, a0 in ((1, -90), (-1, 90)):
        cx = side * (w / 2 - rr)
        for i in range(13):
            a = math.radians(a0 + i * 15)
            out.append((cx + rr * math.cos(a), rr * math.sin(a)))
    # Pedestal and the tub's outside.
    p.add(prism([(a * 0.6, b * 0.5) for a, b in out], 0.3, "lacquer_black", plane="xz", m=move(0, 0.15, 0), bevel=0.01))
    p.add(prism([(a * 0.96, b * 0.94) for a, b in out], 0.62, "walnut_dark", plane="xz", m=move(0, 0.3 + 0.31, 0), bevel=0.02))
    # The bed, sunk 0.2 below the rail.
    bed = prism([(a * 0.86, b * 0.76) for a, b in out], 0.02, "felt_craps", plane="xz", m=move(0, 0.79, 0), bevel=0.0)
    bed.uv = ("x", "z", 1 / (w * 0.86), -1 / (d * 0.76), 0.5, 0.5)
    p.add(bed)
    # The walls up to the rail: mirror inside, walnut cap, the padded rail, the groove.
    ring = [(a * 0.93, 0.0, b * 0.88) for a, b in out]
    p.add(tube([(x, 0.9, z) for x, _, z in ring], 0.1, "mirror", 6, closed=True))
    p.add(tube([(a * 0.97, 0.985, b * 0.95) for a, b in out], 0.035, "walnut", 8, closed=True))
    p.add(tube([(a * 1.0, 1.0, b * 1.0) for a, b in out], 0.05, "leather_rail", 10, closed=True))
    p.add(tube([(a * 0.955, 0.965, b * 0.925) for a, b in out], 0.018, "lacquer_black", 6, closed=True))
    chip_rack(p, 0.0, -d / 2 + 0.2, 0.83, 0.9, 10)
    # The stick, and two dice.
    p.add(tube([(-0.6, 0.81, 0.3), (0.5, 0.81, 0.12)], 0.008, "oak", 6))
    p.add(box((0.47, 0.805, 0.08), (0.56, 0.815, 0.16), "oak", 0.004))
    for k, (x, z, a) in enumerate([(0.9, 0.05, 20), (0.98, 0.1, 55)]):
        p.add(box((-0.009, 0, -0.009), (0.009, 0.018, 0.009), "chip_red", 0.003, m=move(x, 0.8, z) @ rot_y(a)))
    rng = random.Random(3)
    for k in range(10):
        x = (rng.random() - 0.5) * 2.6
        z = 0.25 + rng.random() * 0.3
        p.add(chip_stack(x, 0.8, z, 1 + rng.randrange(4), ["chip_red", "chip_green", "chip_black"][k % 3], 0.017))
    return p


# --- Slots ---------------------------------------------------------------------------------------------

def slot_machine(p, x, glow):
    """One machine 0.7 m wide in a bank: a lacquered cabinet, the reels and the top glass from
    slot_art, a sloped button deck, light strips down its sides in `glow`."""
    w, d, h = 0.7, 0.72, 1.92
    x0, x1 = x - w / 2 + 0.01, x + w / 2 - 0.01
    z0, z1 = -d / 2, d / 2
    p.add(box((x0, 0.0, z0), (x1, 0.1, z1 - 0.04), "lacquer_black", 0.004))
    p.add(box((x0, 0.1, z0), (x1, 0.86, z1), "lacquer_black", 0.008))
    p.add(box((x0 + 0.06, 0.18, z1), (x1 - 0.06, 0.78, z1 + 0.01), "chrome", 0.004))
    # The button deck, sloped toward the player.
    deck = box((x0, 0.0, -0.18), (x1, 0.06, 0.18), "lacquer_black", 0.01, m=move(0, 0.92, z1 - 0.12) @ rot_x(14))
    p.add(deck)
    for k in range(5):
        bx = x0 + 0.12 + k * 0.1
        p.add(box((-0.03, 0.0, -0.02), (0.03, 0.02, 0.02), "button_red" if k == 4 else "button_amber", 0.006, m=move(bx, 0.98, z1 - 0.05) @ rot_x(14)))
    # The body above the deck, the reels and the top glass.
    p.add(box((x0, 0.95, z0), (x1, h, z1 - 0.22), "lacquer_black", 0.01))
    sw = w - 0.14
    reels = box((x - sw / 2, 1.02, z1 - 0.23), (x + sw / 2, 1.4, z1 - 0.21), "slot_art", 0.0)
    reels.uv = ("x", "y", 1 / sw, 0.5 / 0.38, 0.5 - x / sw, -1.02 * 0.5 / 0.38)
    p.add(reels)
    top = box((x - sw / 2, 1.46, z1 - 0.23), (x + sw / 2, 1.84, z1 - 0.21), "slot_art", 0.0)
    top.uv = ("x", "y", 1 / sw, 0.5 / 0.38, 0.5 - x / sw, 0.5 - 1.46 * 0.5 / 0.38)
    p.add(top)
    p.add(box((x - sw / 2 - 0.02, 1.405, z1 - 0.235), (x + sw / 2 + 0.02, 1.455, z1 - 0.2), "chrome", 0.006))
    for s in (-1, 1):
        sx = x + s * (w / 2 - 0.035)
        p.add(box((sx - 0.012, 0.95, z1 - 0.24), (sx + 0.012, h - 0.04, z1 - 0.2), glow, 0.004))
    # A bill slot and a card reader.
    p.add(box((x1 - 0.16, 0.86, z1 - 0.21), (x1 - 0.04, 0.9, z1 - 0.18), "chrome", 0.004))


@props.prop
def tideline_slots():
    """A bank of four slot machines, 2.8 m wide, 0.72 deep, with a lit sign on top to 2.25 m;
    each machine glows down its sides (pink, cyan, gold, pink). Back flat at -Z, so two banks
    stand back to back."""
    p = Prop("tideline_slots")
    glows = ["slot_glow_pink", "slot_glow_cyan", "slot_glow_gold", "slot_glow_pink"]
    for i in range(4):
        slot_machine(p, -1.05 + i * 0.7, glows[i])
    p.add(box((-1.4, 1.92, -0.36), (1.4, 2.0, 0.16), "chrome", 0.01))
    p.add(box((-1.36, 2.0, -0.12), (1.36, 2.24, 0.08), "lacquer_black", 0.01))
    p.add(box((-1.3, 2.04, 0.08), (1.3, 2.2, 0.095), "slot_glow_gold", 0.0))
    p.add(box((-1.36, 2.24, -0.12), (1.36, 2.26, 0.08), "slot_glow_pink", 0.0))
    return p


@props.prop
def tideline_slot_stool():
    """A slot player's stool: a round padded seat 0.66 m up with a low back, on a chrome post
    and a weighted base; faces +Z (the machine is at -Z)."""
    p = Prop("tideline_slot_stool")
    h = 0.66
    p.add(lathe([(0.2, 0.0), (0.21, 0.01), (0.19, 0.03), (0.04, 0.05), (0.0, 0.05)], "chrome", 18))
    p.add(cyl(0.028, 0.05, h - 0.05, "chrome", 10, bevel=0))
    p.add(tube([(0.15 * math.cos(a * math.pi / 8), 0.3, 0.15 * math.sin(a * math.pi / 8)) for a in range(16)], 0.01, "chrome", 6, closed=True))
    p.add(lathe([(0.19, h - 0.05), (0.2, h - 0.02), (0.19, h + 0.04), (0.14, h + 0.06), (0.0, h + 0.065)], "velvet_burgundy", 18))
    p.add(cushion((-0.17, h + 0.04, 0.12), (0.17, h + 0.3, 0.18), "velvet_burgundy", 0.03).xf(move(0, h, 0.15) @ rot_x(8) @ move(0, -h, -0.15)))
    return p


# --- The pit, the bar, the lounge -------------------------------------------------------------------

@props.prop
def tideline_podium():
    """The pit boss's podium: a walnut desk 0.9 x 1.15 x 0.6 with a brass rail, a screen with
    the tables' ratings, a phone and the fill slips. The boss stands at -Z; +Z faces the pit."""
    p = Prop("tideline_podium")
    w, h, d = 0.9, 1.15, 0.6
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.08, d / 2), "lacquer_black", 0.004))
    p.add(box((-w / 2, 0.08, -d / 2 + 0.05), (w / 2, h - 0.05, d / 2), "walnut", 0.01))
    p.add(props.panel_moulding(-w / 2 + 0.08, 0.2, w / 2 - 0.08, h - 0.2, d / 2, 0.015, 0.01, "brass"))
    top = box((-w / 2 - 0.03, 0, -d / 2 - 0.02), (w / 2 + 0.03, 0.04, d / 2 + 0.03), "marble_black", 0.012, m=move(0, h - 0.05, 0) @ rot_x(-8))
    p.add(top)
    p.add(box((-0.3, h + 0.02, -0.1), (0.15, h + 0.3, -0.08), "plastic_black", 0.008))
    p.add(box((-0.28, h + 0.04, -0.08), (0.13, h + 0.28, -0.075), "screen", 0.0))
    p.add(box((0.2, h - 0.01, -0.15), (0.38, h + 0.05, 0.0), "plastic_black", 0.01))
    p.add(box((0.21, h + 0.05, -0.14), (0.37, h + 0.08, -0.1), "plastic_black", 0.012))
    for k in range(3):
        p.add(box((-0.35 + k * 0.012, h + 0.0, 0.02 + k * 0.01), (-0.12 + k * 0.012, h + 0.004 + k * 0.002, 0.2 + k * 0.01), "paper", 0.0))
    return p


@props.prop
def tideline_table_light():
    """The light over a table: a long brass frame with smoked glass sides and a glowing
    diffuser underneath, 1.5 x 0.5, on four rods; hangs from y 0.9 to y 0."""
    p = Prop("tideline_table_light")
    w, d, hh = 1.5, 0.5, 0.26
    p.add(box((-w / 2, 0.0, -d / 2), (w / 2, 0.02, d / 2), "lampshade", 0.0))
    for s in (-1, 1):
        p.add(box((-w / 2, 0.0, s * d / 2 - 0.01), (w / 2, hh, s * d / 2 + 0.01), "glass_dark", 0.0))
        p.add(box((s * w / 2 - 0.01, 0.0, -d / 2), (s * w / 2 + 0.01, hh, d / 2), "glass_dark", 0.0))
    for y in (0.0, hh):
        for s in (-1, 1):
            p.add(box((-w / 2 - 0.015, y - 0.012, s * d / 2 - 0.015), (w / 2 + 0.015, y + 0.012, s * d / 2 + 0.015), "brass", 0.003))
            p.add(box((s * w / 2 - 0.015, y - 0.012, -d / 2 - 0.015), (s * w / 2 + 0.015, y + 0.012, d / 2 + 0.015), "brass", 0.003))
    p.add(box((-w / 2 + 0.02, hh - 0.01, -d / 2 + 0.02), (w / 2 - 0.02, hh, d / 2 - 0.02), "lacquer_black", 0.0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            p.add(cyl(0.006, hh, 0.9, "brass", 6, m=move(sx * (w / 2 - 0.1), 0, sz * (d / 2 - 0.08)), bevel=0))
    return p


@props.prop
def tideline_stage():
    """The lounge's stage: a round platform 3.4 m across and 0.22 high, stained boards with a
    brass nosing and a step at the front (+Z)."""
    p = Prop("tideline_stage")
    r, h = 1.7, 0.22
    p.add(cyl(r, 0.0, h - 0.03, "lacquer_black", 40, bevel=0.01))
    p.add(cyl(r - 0.01, h - 0.03, h, "stage_floor", 40, bevel=0.006))
    p.add(lathe([(r + 0.005, h - 0.035), (r + 0.015, h - 0.02), (r + 0.005, h + 0.004), (r - 0.02, h + 0.004)], "brass", 40, cap=(False, False)))
    p.add(box((-0.6, 0.0, r - 0.12), (0.6, h * 0.5, r + 0.18), "stage_floor", 0.008))
    return p


@props.prop
def tideline_mic():
    """A singer's microphone on a chrome stand, 1.55 m, with a round base."""
    p = Prop("tideline_mic")
    p.add(cyl(0.14, 0.0, 0.02, "chrome", 16, bevel=0.004))
    p.add(cyl(0.012, 0.02, 1.42, "chrome", 8, bevel=0))
    p.add(tube([(0, 1.42, 0), (0, 1.47, 0.06)], 0.009, "chrome", 6))
    p.add(cyl(0.02, 0.0, 0.1, "plastic_black", 10, m=move(0, 1.46, 0.08) @ rot_x(60), bevel=0.003))
    p.add(sphere(0.026, "steel_dark", 10, 6, m=move(0, 1.5, 0.13)))
    return p


@props.prop
def tideline_cocktail_table():
    """A lounge table: a round black marble top 0.6 m across, 0.72 high, on a brass pedestal,
    with a little glass lamp and two drinks."""
    p = Prop("tideline_cocktail_table")
    p.add(lathe([(0.22, 0.0), (0.22, 0.02), (0.05, 0.05), (0.035, 0.68), (0.08, 0.7), (0.0, 0.7)], "brass", 16))
    p.add(cyl(0.3, 0.7, 0.73, "marble_black", 24, bevel=0.008))
    p.add(lathe([(0.04, 0.73), (0.045, 0.78), (0.03, 0.84), (0.0, 0.85)], "lantern_glass", 10))
    for k, (x, z) in enumerate([(0.14, 0.08), (-0.1, 0.14)]):
        p.add(lathe([(0.03, 0.73), (0.008, 0.745), (0.006, 0.82), (0.045, 0.86), (0.04, 0.86)], "glass", 10, cap=(True, False), m=move(x, 0, z)))
    return p


@props.prop
def tideline_banquette():
    """A curved lounge booth in burgundy velvet, 2.4 m across, its back to -Z, seat 0.45 high,
    the back to 1.0 m."""
    p = Prop("tideline_banquette")
    n = 10
    r0, r1 = 1.2, 0.62
    seat, back = [], []
    for i in range(n + 1):
        a = math.pi + math.pi * i / n
        seat.append((r0 * math.cos(a), -0.2 + 0.75 * math.sin(a) * -1.0))
    for i in range(n):
        a0 = math.pi + math.pi * i / n
        a1 = math.pi + math.pi * (i + 1) / n
        pts = [(r0 * math.cos(a0), 0.55 * math.sin(a0)), (r0 * math.cos(a1), 0.55 * math.sin(a1)),
               (r1 * math.cos(a1), 0.2 * math.sin(a1)), (r1 * math.cos(a0), 0.2 * math.sin(a0))]
        p.add(prism(pts, 0.32, "velvet_burgundy", plane="xz", m=move(0, 0.29, 0.1), bevel=0.03))
        bpts = [(1.25 * math.cos(a0), 0.6 * math.sin(a0)), (1.25 * math.cos(a1), 0.6 * math.sin(a1)),
                (1.08 * math.cos(a1), 0.5 * math.sin(a1)), (1.08 * math.cos(a0), 0.5 * math.sin(a0))]
        p.add(prism(bpts, 0.6, "velvet_burgundy", plane="xz", m=move(0, 0.4 + 0.3, 0.1), bevel=0.04))
    p.add(prism([(1.24 * math.cos(math.pi + math.pi * i / 16), 0.1 + 0.58 * math.sin(math.pi + math.pi * i / 16)) for i in range(17)], 0.12, "lacquer_black", plane="xz", m=move(0, 0.06, 0), bevel=0.004))
    return p


# --- The cage and the vault -------------------------------------------------------------------------

@props.prop
def tideline_cage_window():
    """A cashier's window filling a hole 1.8 x 2.6 m in the cage's wall (0.4 thick, centred on
    z = 0): a walnut counter front and a black marble ledge toward the floor (+Z), brass bars
    with a speaking gap over the counter, glass above, a lit header, and the cashier's work
    counter on the cage side (-Z)."""
    p = Prop("tideline_cage_window")
    w, h, t = 1.8, 2.6, 0.4
    p.add(box((-w / 2, 0.0, -t / 2), (w / 2, 1.04, t / 2), "walnut", 0.006))
    p.add(box((-w / 2 + 0.08, 0.12, t / 2), (w / 2 - 0.08, 0.95, t / 2 + 0.02), "walnut", 0.01))
    p.add(props.panel_moulding(-w / 2 + 0.12, 0.16, w / 2 - 0.12, 0.91, t / 2 + 0.02, 0.012, 0.01, "brass"))
    p.add(box((-w / 2 - 0.02, 1.04, -t / 2 - 0.3), (w / 2 + 0.02, 1.1, t / 2 + 0.22), "marble_black", 0.02, 3))
    p.add(box((-w / 2, 0.0, -t / 2 - 0.3), (w / 2, 1.04, -t / 2 - 0.26), "walnut_dark", 0.004))
    # The bars and the glass.
    p.add(box((-w / 2, 1.1, -0.04), (w / 2, 1.14, 0.04), "brass", 0.006))
    for k in range(15):
        x = -w / 2 + 0.06 + k * (w - 0.12) / 14
        p.add(cyl(0.008, 1.14, 2.18, "brass", 6, m=move(x, 0, 0.06), bevel=0))
    p.add(box((-w / 2, 1.36, -0.01), (w / 2, 2.18, 0.01), "glass", 0.0))
    p.add(box((-w / 2, 1.34, -0.03), (w / 2, 1.38, 0.03), "brass", 0.004))
    p.add(box((-w / 2, 2.18, -t / 2), (w / 2, h, t / 2), "walnut", 0.006))
    p.add(box((-w / 2 + 0.1, 2.26, t / 2), (w / 2 - 0.1, 2.5, t / 2 + 0.02), "brass_aged", 0.004))
    for s in (-1, 1):
        p.add(box((s * w / 2 - 0.05, 1.1, -t / 2), (s * w / 2 + (0.0 if s > 0 else 0.05), 2.18, t / 2), "walnut", 0.004))
    # The cashier's side: a cash drawer, a till, papers.
    p.add(box((-0.3, 0.86, -t / 2 - 0.28), (0.3, 1.0, -t / 2 - 0.02), "steel_dark", 0.006))
    p.add(box((-0.25, 1.1, -t / 2 - 0.2), (0.05, 1.32, -t / 2 - 0.18), "plastic_black", 0.01))
    p.add(box((-0.23, 1.12, -t / 2 - 0.181), (0.03, 1.3, -t / 2 - 0.178), "screen", 0.0))
    p.add(box((0.25, 1.1, -t / 2 - 0.25), (0.6, 1.106, -t / 2 - 0.05), "paper", 0.0))
    return p


@props.prop
def tideline_cage_door():
    """The cage's door leaf, 1.0 x 2.2: a steel frame, brass bars over a solid lower panel, a
    lock box. Hinged at the origin, spanning x -1.0..0."""
    p = Prop("tideline_cage_door")
    w, h, t = 1.0, 2.2, 0.06
    p.add(box((-w, 0.0, -t / 2), (0.0, 1.0, t / 2), "paint_door", 0.004))
    for x0, x1 in ((-w, -w + 0.07), (-0.07, 0.0)):
        p.add(box((x0, 1.0, -t / 2), (x1, h, t / 2), "paint_door", 0.004))
    p.add(box((-w, h - 0.08, -t / 2), (0.0, h, t / 2), "paint_door", 0.004))
    p.add(box((-w, 1.0, -t / 2), (0.0, 1.06, t / 2), "paint_door", 0.004))
    for k in range(9):
        x = -w + 0.12 + k * (w - 0.24) / 8
        p.add(cyl(0.011, 1.06, h - 0.08, "brass_aged", 6, m=move(x, 0, 0), bevel=0))
    for s in (-1, 1):
        p.add(box((-w + 0.05, 0.95, s * t / 2), (-w + 0.2, 1.15, s * (t / 2 + 0.05)), "steel", 0.006))
        p.add(box((-w + 0.08, 0.06, s * t / 2), (-0.08, 0.3, s * (t / 2 + 0.003)), "steel", 0.002))
    return p


@props.prop
def tideline_vault_door():
    """The vault's round door: 2.2 m across and 0.35 thick, a rim of bolts, a spoked wheel and
    the time lock on its front (+Z), the bolt work on its back. Hinged at the origin (two
    heavy arms), spanning x -2.2..0, y 0..2.2."""
    p = Prop("tideline_vault_door")
    r, t = 1.1, 0.34
    c = (-r, r)
    face = rot_x(90)
    p.add(lathe([(0.0, -t / 2), (r - 0.04, -t / 2), (r, -t / 2 + 0.04), (r, t / 2 - 0.06), (r - 0.08, t / 2), (0.0, t / 2)], "vault_steel", 48, m=move(c[0], c[1], 0) @ face))
    for rr, z in ((0.95, t / 2), (0.72, t / 2 + 0.01), (0.5, t / 2 + 0.02)):
        p.add(lathe([(rr, z), (rr + 0.03, z + 0.015), (rr + 0.06, z)], "chrome" if rr == 0.5 else "vault_dark", 40, cap=(False, False), m=move(c[0], c[1], 0) @ face))
    # Bolts round the rim, standing proud of the edge.
    for k in range(16):
        a = 2 * math.pi * k / 16
        bx, by = c[0] + (r - 0.06) * math.cos(a), c[1] + (r - 0.06) * math.sin(a)
        p.add(cyl(0.035, -0.08, 0.08, "chrome", 10, m=move(bx, by, 0) @ face, bevel=0.004))
    # The wheel: a hub and five spokes with knobs.
    hub = (c[0], c[1], t / 2 + 0.05)
    p.add(cyl(0.11, 0.0, 0.08, "chrome", 20, m=move(*hub) @ face, bevel=0.01))
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.3
        end = (hub[0] + 0.42 * math.cos(a), hub[1] + 0.42 * math.sin(a), hub[2] + 0.06)
        p.add(tube([(hub[0], hub[1], hub[2] + 0.06), end], 0.022, "chrome", 8))
        p.add(sphere(0.04, "chrome", 10, 6, m=move(*end)))
    # The time lock: a dial in a brass box above the wheel.
    p.add(box((c[0] - 0.2, c[1] + 0.55, t / 2), (c[0] + 0.2, c[1] + 0.8, t / 2 + 0.05), "brass_aged", 0.008))
    for k in range(3):
        p.add(cyl(0.04, 0.0, 0.012, "porcelain", 14, m=move(c[0] - 0.12 + k * 0.12, c[1] + 0.67, t / 2 + 0.05) @ face, bevel=0.002))
    # The back: the bolt work under a plate.
    p.add(box((c[0] - 0.7, c[1] - 0.45, -t / 2 - 0.03), (c[0] + 0.7, c[1] + 0.45, -t / 2), "vault_dark", 0.01))
    for y in (c[1] - 0.25, c[1] + 0.25):
        p.add(box((c[0] - 0.95, y - 0.04, -t / 2 - 0.06), (c[0] + 0.95, y + 0.04, -t / 2 - 0.03), "chrome", 0.01))
    # The hinge arms.
    for y in (0.45, 1.75):
        p.add(box((-0.32, y - 0.1, -0.12), (0.0, y + 0.1, 0.12), "vault_dark", 0.02))
        p.add(cyl(0.07, y - 0.14, y + 0.14, "vault_steel", 14, m=move(-0.04, 0, 0), bevel=0.01))
    return p


@props.prop
def tideline_vault_frame():
    """The vault door's frame on a wall face: a steel plate 3.0 x 2.6 with a round opening 2.3
    across (its bottom on the floor), a chrome ring round it and a nameplate. Back on z = 0."""
    p = Prop("tideline_vault_frame")
    W, H, R = 3.0, 2.6, 1.15
    cy = R
    # The plate is quads from the round opening out to the plate's edge, split at its corners
    # so each quad's outer side lies on one edge.
    corners = [math.atan2(y - cy, x) for x, y in ((W / 2, H), (-W / 2, H), (-W / 2, 0.0), (W / 2, 0.0))]
    angles = sorted({round(2 * math.pi * k / 48, 6) for k in range(48)} | {round(a % (2 * math.pi), 6) for a in corners})
    angles.append(angles[0] + 2 * math.pi)

    def outer(a):
        c, s = math.cos(a), math.sin(a)
        t = 1e9
        if abs(c) > 1e-6:
            t = min(t, (W / 2) / abs(c))
        if s > 1e-6:
            t = min(t, (H - cy) / s)
        elif s < -1e-6:
            t = min(t, cy / -s)
        return (t * c, cy + t * s)

    for a0, a1 in zip(angles, angles[1:]):
        quad = [(R * math.cos(a0), cy + R * math.sin(a0)), outer(a0), outer(a1), (R * math.cos(a1), cy + R * math.sin(a1))]
        if math.dist(quad[0], quad[1]) < 0.01 and math.dist(quad[2], quad[3]) < 0.01:
            continue
        p.add(prism(quad, 0.06, "vault_steel", plane="xy", m=move(0, 0, 0.03), bevel=0.0))
    p.add(tube([(R * math.cos(2 * math.pi * k / 40), cy + R * math.sin(2 * math.pi * k / 40), 0.07) for k in range(40)], 0.05, "chrome", 8, closed=True))
    for k in range(20):
        a = 2 * math.pi * k / 20
        if cy + (R + 0.16) * math.sin(a) > 0.08:
            p.add(sphere(0.02, "chrome", 6, 4, m=move((R + 0.16) * math.cos(a), cy + (R + 0.16) * math.sin(a), 0.07)))
    p.add(box((-0.45, 2.35, 0.06), (0.45, 2.52, 0.075), "brass", 0.004))
    return p


@props.prop
def tideline_vault_shelves():
    """Steel shelving in the vault, 1.8 x 2.2 x 0.5: cash bricks in plastic, coin bags and racks
    of chips; front faces +Z."""
    p = Prop("tideline_vault_shelves")
    w, h, d = 1.8, 2.2, 0.5
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        for z in (-d / 2 + 0.02, d / 2 - 0.02):
            p.add(box((x - 0.02, 0, z - 0.02), (x + 0.02, h, z + 0.02), "steel_dark", 0.003))
    rng = random.Random(5)
    for k, y in enumerate((0.12, 0.62, 1.12, 1.62, 2.12)):
        p.add(box((-w / 2, y - 0.02, -d / 2), (w / 2, y, d / 2), "steel", 0.003))
        if y > 2.0:
            continue
        x = -w / 2 + 0.08
        while x < w / 2 - 0.2:
            kind = rng.randrange(3)
            if kind == 0:
                for j in range(rng.randrange(2, 5)):
                    p.add(box((x, y + j * 0.07, -0.12), (x + 0.17, y + 0.07 + j * 0.07, 0.12), "cash_green", 0.006))
                    p.add(box((x + 0.07, y + j * 0.07, -0.122), (x + 0.1, y + 0.07 + j * 0.07, 0.122), "cash_band", 0.0))
                x += 0.2
            elif kind == 1:
                p.add(lathe([(0.0, y), (0.1, y), (0.12, y + 0.12), (0.06, y + 0.24), (0.02, y + 0.27), (0.0, y + 0.27)], "linen", 10, m=move(x + 0.11, 0, 0)))
                x += 0.25
            else:
                p.add(box((x, y, -0.13), (x + 0.3, y + 0.08, 0.13), "lacquer_black", 0.004))
                for j in range(5):
                    p.add(box((x + 0.01 + j * 0.058, y + 0.02, -0.12), (x + 0.058 + j * 0.058, y + 0.09, 0.12), ["chip_red", "chip_green", "chip_black", "chip_purple", "chip_blue"][j], 0.006))
                x += 0.34
    return p


@props.prop
def tideline_deposit_boxes():
    """A wall of safe deposit boxes, 2.4 x 2.2, back on z = 0: eight across, eleven high, each
    with a brass number plate and two keyholes."""
    p = Prop("tideline_deposit_boxes")
    w, h, d = 2.4, 2.2, 0.06
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, d), "vault_dark", 0.004))
    cols, rows = 8, 11
    cw, rh = w / cols, (h - 0.1) / rows
    for i in range(cols):
        for j in range(rows):
            x0, y0 = -w / 2 + i * cw + 0.008, 0.05 + j * rh + 0.008
            x1, y1 = x0 + cw - 0.016, y0 + rh - 0.016
            p.add(box((x0, y0, d), (x1, y1, d + 0.012), "vault_steel", 0.004))
            p.add(box((x0 + 0.03, y1 - 0.05, d + 0.012), (x0 + 0.1, y1 - 0.03, d + 0.015), "brass", 0.0))
            for kx in (x1 - 0.08, x1 - 0.05):
                p.add(box((kx - 0.008, y0 + rh * 0.4, d + 0.012), (kx + 0.008, y0 + rh * 0.4 + 0.02, d + 0.016), "brass_aged", 0.0))
    return p


@props.prop
def tideline_rose_case():
    """The Rose in its case: a black velvet box 0.26 x 0.2, its lid open, a pink diamond on white
    satin. Sits on a table top at y = 0."""
    p = Prop("tideline_rose_case")
    p.add(box((-0.13, 0.0, -0.1), (0.13, 0.07, 0.1), "velvet_black", 0.012))
    p.add(box((-0.115, 0.05, -0.085), (0.115, 0.072, 0.085), "satin_white", 0.008))
    lid = box((-0.13, 0.0, -0.01), (0.13, 0.2, 0.02), "velvet_black", 0.012, m=move(0, 0.07, -0.1) @ rot_x(-12) @ move(0, 0, -0.01))
    p.add(lid)
    p.add(octa(0.034, 0.05, "pink_diamond", m=move(0, 0.098, 0.0) @ rot_y(20)))
    p.add(lathe([(0.0, 0.0), (0.034, 0.0), (0.0, -0.025)], "pink_diamond", 8, m=move(0, 0.098, 0) @ rot_x(180)))
    return p


@props.prop
def tideline_vault_table():
    """A steel table for the vault's middle, 1.2 x 0.7 x 0.9."""
    p = Prop("tideline_vault_table")
    steel_table(p, 1.2, 0.7, 0.9)
    return p


# --- The count room ------------------------------------------------------------------------------------

@props.prop
def tideline_count_table():
    """The count room's table: 3.0 x 1.0, 0.92 high, steel, with two note counters, banded
    bricks of cash, coin trays, a calculator and the strap box. Front faces +Z."""
    p = Prop("tideline_count_table")
    steel_table(p, 3.0, 1.0, 0.92)
    y = 0.92
    for x in (-1.0, 0.7):
        p.add(box((x - 0.17, y, -0.25), (x + 0.17, y + 0.22, 0.05), "plastic_grey", 0.02))
        p.add(box((x - 0.12, y + 0.22, -0.2), (x + 0.12, y + 0.26, 0.0), "plastic_black", 0.01))
        p.add(box((x - 0.06, y + 0.12, 0.05), (x + 0.06, y + 0.15, 0.052), "led_green", 0.0))
    rng = random.Random(8)
    for k in range(9):
        x = -1.35 + k * 0.3 + rng.random() * 0.05
        if abs(x + 1.0) < 0.25 or abs(x - 0.7) < 0.25:
            continue
        for j in range(1 + rng.randrange(4)):
            p.add(box((x, y + j * 0.04, 0.08), (x + 0.16, y + 0.04 + j * 0.04, 0.15), "cash_green", 0.004))
            p.add(box((x + 0.06, y + j * 0.04, 0.078), (x + 0.09, y + 0.04 + j * 0.04, 0.152), "cash_band", 0.0))
    for x in (-0.4, -0.15):
        p.add(box((x, y, -0.4), (x + 0.22, y + 0.04, -0.15), "steel_dark", 0.004))
        for k in range(6):
            p.add(cyl(0.012, y + 0.02, y + 0.035, "brass_aged", 8, m=move(x + 0.03 + k * 0.03, 0, -0.27), bevel=0))
    p.add(box((1.1, y, 0.1), (1.26, y + 0.02, 0.3), "plastic_black", 0.006))
    return p


@props.prop
def tideline_count_sheet():
    """The count sheet on its clipboard, 0.24 x 0.33, lying flat (y 0..0.015)."""
    p = Prop("tideline_count_sheet")
    p.add(box((-0.12, 0.0, -0.165), (0.12, 0.008, 0.165), "oak", 0.003))
    p.add(box((-0.105, 0.008, -0.14), (0.105, 0.01, 0.15), "paper", 0.0))
    for k in range(12):
        p.add(box((-0.09, 0.0101, -0.1 + k * 0.02), (0.06 + (k % 3) * 0.01, 0.0103, -0.096 + k * 0.02), "plastic_black", 0.0))
    p.add(box((-0.05, 0.008, -0.17), (0.05, 0.022, -0.13), "chrome", 0.003))
    return p


@props.prop
def tideline_drop_cart():
    """The drop team's cart: a steel trolley 1.2 x 0.6, 1.0 high, two shelves of locked drop
    boxes, a push bar at -X."""
    p = Prop("tideline_drop_cart")
    w, d = 1.2, 0.6
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for z in (-d / 2 + 0.03, d / 2 - 0.03):
            p.add(cyl(0.015, 0.1, 0.95, "steel", 8, m=move(x, 0, z), bevel=0))
            p.add(cyl(0.045, -0.02, 0.02, "rubber", 10, m=move(x, 0.05, z) @ rot_x(90), bevel=0.004))
    for y in (0.2, 0.6):
        p.add(box((-w / 2, y - 0.02, -d / 2), (w / 2, y, d / 2), "steel", 0.004))
        for k in range(3):
            x = -0.4 + k * 0.4
            p.add(box((x - 0.17, y, -0.2), (x + 0.17, y + 0.3, 0.2), "steel_dark", 0.01))
            p.add(box((x - 0.04, y + 0.12, 0.2), (x + 0.04, y + 0.2, 0.215), "brass", 0.003))
    p.add(tube([(-w / 2 - 0.02, 0.95, -d / 2 + 0.05), (-w / 2 - 0.12, 0.98, -d / 2 + 0.05), (-w / 2 - 0.12, 0.98, d / 2 - 0.05), (-w / 2 - 0.02, 0.95, d / 2 - 0.05)], 0.016, "steel", 8))
    return p


@props.prop
def tideline_key_box():
    """The count room's key box: a steel cabinet 0.45 x 0.55 with a wired glass door and the
    keys on their hooks, back on z = 0, bottom at y = 0."""
    p = Prop("tideline_key_box")
    w, h, d = 0.45, 0.55, 0.1
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, d), "paint_box", 0.006))
    p.add(box((-w / 2 + 0.03, 0.03, d), (w / 2 - 0.03, h - 0.03, d + 0.005), "glass_dark", 0.0))
    for j in range(3):
        for i in range(4):
            x = -0.15 + i * 0.1
            y = 0.42 - j * 0.14
            p.add(cyl(0.004, 0.0, 0.04, "steel", 4, m=move(x, y, d - 0.02) @ rot_x(90), bevel=0))
            p.add(box((x - 0.01, y - 0.07, d - 0.03), (x + 0.01, y - 0.01, d - 0.025), "brass", 0.0))
            p.add(box((x - 0.018, y - 0.1, d - 0.03), (x + 0.018, y - 0.07, d - 0.027), "chip_red" if (i + j) % 3 == 0 else "chip_white", 0.0))
    p.add(box((w / 2 - 0.06, 0.22, d + 0.005), (w / 2 - 0.03, 0.3, d + 0.03), "chrome", 0.004))
    return p


# --- The eye, the staff room, the alley -----------------------------------------------------------

@props.prop
def tideline_monitor_wall():
    """The eye in the sky's video wall: four by three screens, 4.4 x 2.4, each showing the
    feeds, in a black frame with status lights. Back on z = 0, bottom at y = 0."""
    p = Prop("tideline_monitor_wall")
    w, h = 4.4, 2.4
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, 0.12), "plastic_black", 0.01))
    sw, sh = 1.04, 0.74
    for i in range(4):
        for j in range(3):
            cx = -w / 2 + 0.12 + sw / 2 + i * (sw + 0.04)
            cy = 0.12 + sh / 2 + j * (sh + 0.04)
            s = box((cx - sw / 2, cy - sh / 2, 0.12), (cx + sw / 2, cy + sh / 2, 0.125), "feed", 0.0)
            s.uv = ("x", "y", 1 / sw, 1 / sh, 0.5 - cx / sw, 0.5 - cy / sh)
            p.add(s)
            p.add(box((cx + sw / 2 - 0.05, cy - sh / 2 + 0.01, 0.125), (cx + sw / 2 - 0.03, cy - sh / 2 + 0.02, 0.128), "led_green", 0.0))
    return p


@props.prop
def tideline_dome_camera():
    """A ceiling camera: a smoked dome 0.26 across under a white ring, hanging from y 0.12 to 0."""
    p = Prop("tideline_dome_camera")
    p.add(cyl(0.16, 0.08, 0.12, "paint_white", 20, bevel=0.006))
    p.add(lathe([(0.13, 0.08), (0.12, 0.04), (0.08, 0.01), (0.0, 0.0)], "glass_black", 16, cap=(False, False)))
    return p


@props.prop
def tideline_cam_panel():
    """The cameras' junction box in the alley: a grey steel box 0.5 x 0.7 x 0.2 on the wall,
    conduit up and down, a stencilled plate and a padlock. Back on z = 0, bottom at y = 0."""
    p = Prop("tideline_cam_panel")
    w, h, d = 0.5, 0.7, 0.2
    p.add(box((-w / 2, 0.0, 0.0), (w / 2, h, d), "paint_box", 0.01))
    p.add(box((-w / 2 + 0.02, 0.02, d), (w / 2 - 0.02, h - 0.02, d + 0.01), "paint_box", 0.006))
    p.add(box((-0.12, h - 0.16, d + 0.01), (0.12, h - 0.08, d + 0.012), "plastic_yellow", 0.0))
    p.add(tube([(w / 2 - 0.06, h - 0.3, d + 0.012), (w / 2 - 0.02, h - 0.3, d + 0.03)], 0.006, "chrome", 6))
    p.add(box((w / 2 - 0.05, h - 0.4, d + 0.02), (w / 2 + 0.0, h - 0.33, d + 0.035), "brass", 0.004))
    for x in (-0.12, 0.0, 0.12):
        p.add(cyl(0.02, h, h + 1.6, "conduit", 8, m=move(x, 0, 0.06), bevel=0))
    p.add(cyl(0.025, -1.0, 0.0, "conduit", 8, m=move(0.0, 0, 0.06), bevel=0))
    return p


@props.prop
def tideline_cleaning_cart():
    """A cleaner's cart: a yellow frame with a grey bin bag, a mop bucket with its wringer and
    mop, trays of sprays and cloths; 1.2 x 1.05 x 0.55, front +Z."""
    p = Prop("tideline_cleaning_cart")
    w, d = 1.2, 0.55
    p.add(box((-w / 2, 0.08, -d / 2), (w / 2, 0.12, d / 2), "plastic_yellow", 0.01))
    p.add(box((-w / 2, 0.55, -d / 2), (0.1, 0.6, d / 2), "plastic_yellow", 0.01))
    p.add(box((-w / 2, 0.92, -d / 2), (0.1, 0.97, d / 2), "plastic_yellow", 0.01))
    for x in (-w / 2 + 0.03, 0.07):
        for z in (-d / 2 + 0.03, d / 2 - 0.03):
            p.add(cyl(0.015, 0.12, 0.95, "plastic_yellow", 8, m=move(x, 0, z), bevel=0))
            p.add(cyl(0.04, -0.02, 0.02, "rubber", 10, m=move(x, 0.045, z) @ rot_x(90), bevel=0.003))
    p.add(box((-w / 2 + 0.06, 0.12, -d / 2 + 0.06), (0.04, 0.55, d / 2 - 0.06), "plastic_grey", 0.04))
    rng = random.Random(14)
    for k in range(5):
        x = -0.5 + k * 0.11
        p.add(cyl(0.03, 0.6, 0.78 + rng.random() * 0.05, ["plastic_blue", "chip_green", "chip_red"][k % 3], 8, m=move(x, 0, 0.1), bevel=0.004))
        p.add(box((x - 0.012, 0.8, 0.09), (x + 0.03, 0.83, 0.11), "plastic_black", 0.003))
    for k in range(3):
        p.add(box((-0.5 + k * 0.18, 0.97, -0.15), (-0.36 + k * 0.18, 1.0, 0.15), ["plastic_blue", "linen", "chip_red"][k], 0.01))
    # The bucket and the mop.
    p.add(lathe([(0.0, 0.12), (0.18, 0.12), (0.2, 0.45), (0.19, 0.45)], "plastic_yellow", 16, cap=(True, False), m=move(0.38, 0, 0)))
    p.add(box((0.3, 0.45, -0.1), (0.46, 0.62, 0.1), "plastic_grey", 0.01))
    p.add(cyl(0.012, 0.15, 1.45, "chrome", 6, m=move(0.42, 0, 0.05) @ rot_z(-8), bevel=0))
    p.add(lathe([(0.0, 0.14), (0.1, 0.18), (0.04, 0.3), (0.0, 0.32)], "mop", 10, m=move(0.42, 0, 0.05)))
    return p


@props.prop
def tideline_railing():
    """A harbour railing 2 m long: dark green posts and three rails, 1.05 high; centred on x."""
    p = Prop("tideline_railing")
    for x in (-1.0, 1.0):
        p.add(cyl(0.035, 0.0, 1.08, "paint_rail", 10, m=move(x, 0, 0), bevel=0.004))
        p.add(sphere(0.045, "paint_rail", 10, 6, m=move(x, 1.1, 0)))
    for y in (0.35, 0.7, 1.04):
        p.add(tube([(-1.0, y, 0), (1.0, y, 0)], 0.02 if y > 1 else 0.012, "paint_rail", 8))
    return p


@props.prop
def tideline_yacht():
    """A superyacht at anchor, 26 m long, as seen across the harbour at night: a white hull
    with a navy boot top, three decks of dark glass, lit portholes and windows, a mast with a
    light. The waterline is y = 0, the bow toward +X."""
    p = Prop("tideline_yacht")
    L, B = 26.0, 5.2
    hull = []
    for i in range(13):
        t = i / 12
        x = -L / 2 + L * t
        half = B / 2 * (1.0 if t < 0.6 else max(0.05, math.cos((t - 0.6) / 0.4 * math.pi / 2)))
        hull.append((x, half))
    outline = [(x, z) for x, z in hull] + [(x, -z) for x, z in reversed(hull)]
    p.add(prism(outline, 2.4, "hull_white", plane="xz", m=move(0, 1.2 + 0.4, 0), bevel=0.05))
    p.add(prism([(x * 0.99, z * 0.98) for x, z in outline], 0.5, "hull_navy", plane="xz", m=move(0, 0.25, 0), bevel=0.02))
    for k, (x0, x1, y, inset) in enumerate([(-11.5, 5.5, 2.8, 0.4), (-9.0, 2.5, 5.0, 0.7), (-6.5, -0.5, 7.2, 1.0)]):
        p.add(box((x0, y, -B / 2 + inset), (x1, y + 2.2, B / 2 - inset), "hull_white", 0.05))
        p.add(box((x0 + 0.3, y + 0.6, -B / 2 + inset - 0.02), (x1 - 0.4, y + 1.8, B / 2 - inset + 0.02), "glass_black", 0.02))
        rng = random.Random(30 + k)
        x = x0 + 0.8
        while x < x1 - 1.0:
            if rng.random() < 0.55:
                for s in (-1, 1):
                    p.add(box((x, y + 0.75, s * (B / 2 - inset) - 0.04), (x + 0.9, y + 1.6, s * (B / 2 - inset) + 0.04), "window_lit", 0.0))
            x += 1.3
    for k in range(10):
        x = -10.0 + k * 2.0
        for s in (-1, 1):
            p.add(cyl(0.14, -0.03, 0.03, "window_lit", 10, m=move(x, 1.6, s * B / 2) @ rot_x(90), bevel=0))
    p.add(cyl(0.12, 9.4, 13.5, "hull_white", 10, m=move(-3.5, 0, 0), bevel=0))
    p.add(sphere(0.18, "bulb", 8, 6, m=move(-3.5, 13.6, 0)))
    p.add(box((-13.0, 2.0, -B / 2 + 0.2), (-11.0, 2.15, B / 2 - 0.2), "teak", 0.02))
    return p


@props.prop
def tideline_neon_wave():
    """The neon wave under the Tideline's name: two tubes of light, cyan and pink, 6 m long and
    0.8 high, on a black back; back on z = 0."""
    p = Prop("tideline_neon_wave")
    for k, (mat, y0, ph) in enumerate([("neon_cyan", 0.45, 0.0), ("neon_pink", 0.25, 0.6)]):
        pts = [(-3.0 + 6.0 * i / 60, y0 + 0.16 * math.sin(i / 60 * 4 * math.pi + ph), 0.08) for i in range(61)]
        p.add(tube(pts, 0.025, mat, 8))
    for x in (-2.8, -1.0, 1.0, 2.8):
        p.add(cyl(0.012, 0.0, 0.08, "chrome", 6, m=move(x, 0.4, 0) @ rot_x(90), bevel=0))
    return p


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    mine = {k: v for k, v in props.PROPS.items() if k.startswith("tideline_")}
    if "--list" in args:
        for n, fn in mine.items():
            print("%-26s %s" % (n, (fn.__doc__ or "").strip().split("\n")[0]))
        return
    os.makedirs(OUT, exist_ok=True)
    want = args or list(mine)
    for name in want:
        if name not in mine:
            print("no prop called", name)
            continue
        props.export(mine[name](), os.path.join(OUT, name + ".glb"))


if __name__ == "__main__":
    main()
