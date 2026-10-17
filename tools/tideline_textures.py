#!/usr/bin/env python3
"""Paints the Tideline's surfaces as PNGs in assets/textures/tideline/ (python3 with numpy and
Pillow), using the Meridian's helpers in tools/make_textures.py:

    python3 tools/tideline_textures.py [name ...]

  carpet_casino     the casino floor's carpet: navy, with waves in teal and gold and red
                    compass stars (one tile is 2 m)
  damask_wine       wall fabric for the casino floor, gold on wine (one tile is 1 m)
  damask_green      wall fabric for the high-limit room, gold on bottle green (1 m)
  felt_blackjack    a blackjack table's top: the arc, the betting spots, the rules
  felt_roulette     a roulette table's layout: the numbers, the dozens and the even money
  wheel_roulette    the roulette wheel's pockets and numbers, seen from above
  felt_craps        a craps table's bed: the pass line, the field, the come, the numbers
  felt_baccarat     the high-limit room's baccarat layout: player, banker and tie
  slot_art          the slot machines' glass: the top's art over three reels
  cctv_feed         nine camera pictures for the surveillance room's monitor wall
  planks            the boardwalk's weathered planks (one tile is 2 m)

Tables put their felt on with the props' planar UVs (tools/blender/tideline_props.py): the
dealer's side is the top of the picture and the players read it from the bottom. Everything
comes from fixed seeds, so the pictures only change when this script does.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_textures as mt  # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "textures", "tideline")
FONTS = os.path.join(ROOT, "addons", "cogito", "Assets", "Fonts", "Montserrat")


def font(weight, size):
    return ImageFont.truetype(os.path.join(FONTS, "Montserrat-%s.ttf" % weight), size)


def save(name, img):
    if isinstance(img, np.ndarray):
        img = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8))
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print(name, img.size)


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def felt(w, h, colour, seed, nap=0.07):
    """Baize: a colour with a soft mottle and a fine nap, as an RGB array 0..1."""
    rng = np.random.default_rng(seed)
    base = mt.srgb(colour)
    n = mt.smooth_noise(w, h, 6, rng, octaves=4)
    img = base * (0.9 + 0.18 * n[..., None])
    img = img * (rng.random((h, w, 1)) * nap + (1 - nap / 2))
    return img


def to_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8))


def text_on_arc(img, text, cx, cy, r, mid_deg, fnt, fill, spacing=1.0, outward=False):
    """Prints `text` along a circle round (cx, cy), centred at `mid_deg` (0 is down the picture,
    toward the players), reading left to right for someone below."""
    d = ImageDraw.Draw(img)
    widths = [d.textlength(ch, font=fnt) * spacing for ch in text]
    total = sum(widths)
    # Left to right as the players see it is from the left of the arc to the right, and each
    # letter's top leans in toward the centre.
    ang = math.radians(mid_deg) - (total / 2) / r
    for ch, wd in zip(text, widths):
        ang += wd / 2 / r
        x = cx + r * math.sin(ang)
        y = cy + r * math.cos(ang)
        size = int(fnt.size * 1.6)
        tile = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        ImageDraw.Draw(tile).text((size / 2, size / 2), ch, font=fnt, fill=fill, anchor="mm")
        rot = tile.rotate(math.degrees(ang) + (180 if outward else 0), resample=Image.BICUBIC)
        img.alpha_composite(rot, (int(x - size / 2), int(y - size / 2)))
        ang += wd / 2 / r


# --- The floor's carpet ---------------------------------------------------------------------------

def carpet_casino():
    """Navy wool with waves: rows of scallops (seigaiha) in teal and gold, and between them
    red compass stars, busy the way casino carpets are so nobody looks down."""
    size, ss = 1024, 2
    U, V = mt.grid(size, size, ss)
    rng = np.random.default_rng(21)
    navy = mt.srgb("#0f1a33")
    teal = mt.srgb("#1f5b63")
    teal_dark = mt.srgb("#163f48")
    gold = mt.srgb("#c39a45")
    red = mt.srgb("#8c1d24")
    img = np.zeros(U.shape + (3,)) + navy
    # Scallops (seigaiha): circles of radius R, rows R/2 apart and staggered, each row drawn
    # over the one above so they stack like waves. Four scallops across the tile; it wraps.
    n = 4
    R = 0.5 / n
    ring = np.ones(U.shape)
    rows = int(round(1.0 / (R / 2)))
    for row in range(rows + 2):
        cy = row * R / 2
        off = (row % 2) * R
        for col in range(n):
            cx = col * 2 * R + off
            dx = (U - cx + 0.5) % 1.0 - 0.5
            dy = (V - cy + 0.5) % 1.0 - 0.5
            r = np.hypot(dx, dy)
            ring = np.where(r < R, r / R, ring)
    bands = np.floor(ring * 5)
    edge = np.abs((ring * 5) % 1.0 - 0.5)
    line = mt.smoothstep(0.38, 0.47, edge)
    col = np.where((bands % 2 == 0)[..., None], teal, teal_dark)
    col = np.where((bands == 4)[..., None], navy * 1.25, col)
    col = np.where((bands == 0)[..., None], navy * 0.9, col)
    img = col * (1 - line[..., None]) + gold * line[..., None]
    # Compass stars where the scallops leave gaps.
    star = np.zeros(U.shape)
    core = np.zeros(U.shape)
    for cx, cy in [(0.125, 0.06), (0.625, 0.31), (0.375, 0.56), (0.875, 0.81)]:
        dx = (U - cx + 0.5) % 1.0 - 0.5
        dy = (V - cy + 0.5) % 1.0 - 0.5
        r = np.hypot(dx, dy)
        a = np.arctan2(dy, dx)
        spikes = 0.035 + 0.03 * np.abs(np.cos(4 * a)) ** 6 + 0.012 * np.abs(np.cos(4 * a + math.pi / 4)) ** 8
        star = np.maximum(star, mt.smoothstep(0.003, -0.003, r - spikes))
        core = np.maximum(core, mt.smoothstep(0.003, -0.003, r - 0.012))
    img = img * (1 - star[..., None]) + red * star[..., None]
    img = img * (1 - core[..., None]) + gold * core[..., None]
    img = mt.down(img, ss)
    speck = rng.random((size, size, 1)) * 0.14 + 0.93
    mottle = mt.smooth_noise(size, size, 8, rng)[..., None] * 0.12 + 0.94
    save("carpet_casino", img * speck * mottle)


# --- Wall fabric ------------------------------------------------------------------------------------

def damask(name, ground, figure, seed):
    """A damask: a mirrored flower-and-leaf figure, two to the tile on a half drop, in satin
    on a matte ground."""
    size, ss = 512, 2
    U, V = mt.grid(size, size, ss)
    rng = np.random.default_rng(seed)
    g = mt.srgb(ground)
    f = mt.srgb(figure)
    pat = np.zeros(U.shape)
    for cx, cy in [(0.5, 0.5), (0.0, 0.0)]:
        dx = np.abs((U - cx + 0.5) % 1.0 - 0.5)  # mirrored
        dy = (V - cy + 0.5) % 1.0 - 0.5
        # The flower: a teardrop of petals up the middle.
        r = np.hypot(dx * 1.35, dy + 0.02)
        a = np.arctan2(dx, -(dy + 0.02))
        petals = r - (0.11 + 0.035 * np.cos(5 * a) - 0.04 * np.clip(dy, 0, 1) * 4)
        pat = np.maximum(pat, mt.smoothstep(0.006, -0.006, np.abs(petals) - 0.012))
        pat = np.maximum(pat, mt.smoothstep(0.005, -0.005, np.hypot(dx, dy + 0.03) - 0.03))
        # A stem and two scrolling leaves either side.
        stem = np.abs(dx) - 0.006
        pat = np.maximum(pat, np.where((dy > 0.08) & (dy < 0.36), mt.smoothstep(0.004, -0.004, stem), 0))
        lx, ly = dx - 0.13, dy - 0.2
        la = np.arctan2(ly, lx)
        lr = np.hypot(lx, ly * 1.8)
        leaf = lr - (0.08 + 0.02 * np.sin(3 * la))
        pat = np.maximum(pat, mt.smoothstep(0.005, -0.005, np.abs(leaf) - 0.009))
        curl = np.abs(np.hypot(dx - 0.2, dy + 0.18) - 0.07) - 0.008
        pat = np.maximum(pat, np.where(dy > -0.25, mt.smoothstep(0.004, -0.004, curl), 0))
        dots = np.hypot(dx - 0.24, ((dy + 0.5) % 0.12) - 0.06) - 0.008
        pat = np.maximum(pat, mt.smoothstep(0.003, -0.003, dots) * (dy < 0.45))
    img = g * (1 - pat[..., None]) + f * pat[..., None]
    img = mt.down(img, ss)
    weave = 0.5 + 0.5 * np.sin(np.arange(size) * 2 * math.pi / 3.0)
    img = img * (0.97 + 0.04 * weave[None, :, None]) * (rng.random((size, size, 1)) * 0.04 + 0.98)
    save(name, img)


# --- Felts ------------------------------------------------------------------------------------------

GOLD = (214, 182, 112, 255)
CREAM = (236, 226, 200, 255)
RED = (150, 26, 30, 255)
BLACK = (18, 18, 20, 255)


def felt_blackjack():
    """The half-moon table seen from above, 2.2 x 1.3 m to 1024 x 512: the dealer's straight
    edge at the top, seven betting spots round the arc, the rules printed in gold."""
    w, h = 1024, 512
    img = to_img(felt(w, h, "#155a3a", 3)).convert("RGBA")
    d = ImageDraw.Draw(img)
    cx, cy = w / 2, -80
    # The arc's two printed bands.
    for r, wd in [(430, 3), (500, 2)]:
        d.arc((cx - r, cy - r, cx + r, cy + r), 15, 165, fill=GOLD, width=wd)
    text_on_arc(img, "BLACKJACK PAYS 3 TO 2", cx, cy, 395, 0, font("SemiBold", 34), GOLD)
    text_on_arc(img, "DEALER MUST DRAW TO 16 AND STAND ON ALL 17s", cx, cy, 350, 0, font("Medium", 19), CREAM)
    text_on_arc(img, "INSURANCE PAYS 2 TO 1", cx, cy, 465, 0, font("SemiBold", 22), GOLD)
    # Seven betting spots, just inside the outer edge.
    for k in range(7):
        a = math.radians(-54 + k * 18)
        x, y = cx + 545 * math.sin(a), cy + 545 * math.cos(a)
        d.ellipse((x - 34, y - 34, x + 34, y + 34), outline=GOLD, width=3)
        d.ellipse((x - 26, y - 26, x + 26, y + 26), outline=(214, 182, 112, 120), width=1)
    # The house's name under the chip rack.
    d.text((cx, 150), "THE TIDELINE", font=font("Bold", 30), fill=GOLD, anchor="mm")
    d.text((cx, 182), "CALDERA", font=font("Medium", 16), fill=CREAM, anchor="mm")
    save("felt_blackjack", img.convert("RGB"))


def felt_roulette():
    """The layout of a roulette table, 3.0 x 1.4 m to 1024 x 512: the wheel's end on the left
    (left plain for the wheel), zero, the numbers in three rows of twelve, the dozens and the
    even-money bets toward the players."""
    w, h = 1024, 512
    img = to_img(felt(w, h, "#17603f", 5)).convert("RGBA")
    d = ImageDraw.Draw(img)
    reds = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
    x0, y0 = 400, 70
    cw, ch = 46, 72
    # Zero.
    d.polygon([(x0, y0), (x0 - 40, y0 + ch * 1.5), (x0, y0 + ch * 3)], fill=(20, 120, 60, 255), outline=CREAM)
    d.text((x0 - 15, y0 + ch * 1.5), "0", font=font("Bold", 30), fill=CREAM, anchor="mm")
    num = font("Bold", 26)
    for col in range(12):
        for row in range(3):
            n = col * 3 + (3 - row)
            x, y = x0 + col * cw, y0 + row * ch
            d.rectangle((x, y, x + cw, y + ch), outline=CREAM, width=2)
            cx, cy = x + cw / 2, y + ch / 2
            d.ellipse((cx - 17, cy - 17, cx + 17, cy + 17), fill=RED if n in reds else BLACK)
            d.text((cx, cy), str(n), font=num, fill=CREAM, anchor="mm")
    # Column bets at the far end.
    for row in range(3):
        x, y = x0 + 12 * cw, y0 + row * ch
        d.rectangle((x, y, x + cw + 10, y + ch), outline=CREAM, width=2)
        d.text((x + (cw + 10) / 2, y + ch / 2), "2:1", font=font("SemiBold", 18), fill=CREAM, anchor="mm")
    # Dozens, and the even money.
    yd = y0 + 3 * ch
    for k, label in enumerate(["1st 12", "2nd 12", "3rd 12"]):
        x = x0 + k * 4 * cw
        d.rectangle((x, yd, x + 4 * cw, yd + 54), outline=CREAM, width=2)
        d.text((x + 2 * cw, yd + 27), label, font=font("SemiBold", 22), fill=CREAM, anchor="mm")
    ye = yd + 54
    for k, label in enumerate(["1-18", "EVEN", "RED", "BLACK", "ODD", "19-36"]):
        x = x0 + k * 2 * cw
        d.rectangle((x, ye, x + 2 * cw, ye + 60), outline=CREAM, width=2)
        if label in ("RED", "BLACK"):
            cx, cy = x + cw, ye + 30
            d.polygon([(cx, cy - 18), (cx + 26, cy), (cx, cy + 18), (cx - 26, cy)], fill=RED if label == "RED" else BLACK)
        else:
            d.text((x + cw, ye + 30), label, font=font("SemiBold", 18), fill=CREAM, anchor="mm")
    # The wheel's end: the house's name round where the wheel sits.
    d.text((175, 470), "THE TIDELINE", font=font("Bold", 24), fill=GOLD, anchor="mm")
    save("felt_roulette", img.convert("RGB"))


def wheel_roulette():
    """A European wheel from above, 512 x 512: the turret's brass hub in the middle, the
    pockets in red and black round a green zero, their numbers, and the wooden bowl."""
    size = 512
    img = Image.new("RGBA", (size, size), hexc("#3a1f12") + (255,))
    d = ImageDraw.Draw(img)
    c = size / 2
    order = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
    reds = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
    # The wood bowl's rings.
    for r, col in [(254, "#2a160c"), (244, "#5a3218"), (232, "#46260f"), (214, "#6b3d1d")]:
        d.ellipse((c - r, c - r, c + r, c + r), fill=hexc(col) + (255,))
    # Number ring, then the pockets.
    step = 360.0 / len(order)
    for k, n in enumerate(order):
        a0 = -90 + k * step - step / 2
        col = (20, 120, 60, 255) if n == 0 else (RED if n in reds else BLACK)
        d.pieslice((c - 196, c - 196, c + 196, c + 196), a0, a0 + step, fill=col)
    d.ellipse((c - 150, c - 150, c + 150, c + 150), fill=hexc("#c8a25a") + (255,))
    for k, n in enumerate(order):
        a0 = -90 + k * step - step / 2
        col = (20, 110, 55, 255) if n == 0 else ((120, 20, 24, 255) if n in reds else (12, 12, 14, 255))
        d.pieslice((c - 146, c - 146, c + 146, c + 146), a0, a0 + step, fill=col)
        d.pieslice((c - 146, c - 146, c + 146, c + 146), a0, a0 + 0.8, fill=hexc("#d8b56a") + (255,))
    num = font("Bold", 17)
    for k, n in enumerate(order):
        a = math.radians(-90 + k * step)
        r = 174
        tile = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        ImageDraw.Draw(tile).text((20, 20), str(n), font=num, fill=CREAM, anchor="mm")
        rot = tile.rotate(-math.degrees(a) - 90, resample=Image.BICUBIC)
        img.alpha_composite(rot, (int(c + r * math.cos(a) - 20), int(c + r * math.sin(a) - 20)))
    # The cone and the turret.
    for r, col in [(100, "#7a4a22"), (96, "#8c5a2c"), (40, "#c9a050"), (30, "#e0c070"), (10, "#9a7638")]:
        d.ellipse((c - r, c - r, c + r, c + r), fill=hexc(col) + (255,))
    for k in range(4):
        a = math.radians(45 + 90 * k)
        d.line((c, c, c + 92 * math.cos(a), c + 92 * math.sin(a)), fill=hexc("#d8b56a") + (255,), width=6)
    save("wheel_roulette", img.convert("RGB"))


def felt_craps():
    """A craps table's bed, 3.2 x 1.2 m to 1024 x 384: the same layout at both ends (pass line,
    don't pass, come, field, the place numbers) and the propositions in the middle."""
    w, h = 1024, 384
    img = to_img(felt(w, h, "#0f4f6b", 9)).convert("RGBA")
    d = ImageDraw.Draw(img)
    big = font("Bold", 30)
    mid = font("SemiBold", 20)
    small = font("Medium", 14)
    for side in (-1, 1):
        def X(x):
            return w / 2 + side * x
        # The place numbers along the top.
        for k, n in enumerate(["4", "5", "SIX", "8", "NINE", "10"]):
            xa, xb = X(140 + k * 56), X(196 + k * 56)
            d.rectangle((min(xa, xb), 24, max(xa, xb), 100), outline=CREAM, width=2)
            d.text(((xa + xb) / 2, 62), n, font=mid if len(n) > 2 else big, fill=CREAM, anchor="mm")
        # Come, field, don't pass, pass line.
        xa, xb = X(140), X(476)
        lo, hi = min(xa, xb), max(xa, xb)
        d.rectangle((lo, 106, hi, 170), outline=CREAM, width=2)
        d.text(((lo + hi) / 2, 138), "COME", font=big, fill=RED, anchor="mm")
        d.rectangle((lo, 176, hi, 244), outline=CREAM, width=2)
        d.text(((lo + hi) / 2, 196), "2 . 3 . 4 . 9 . 10 . 11 . 12", font=mid, fill=CREAM, anchor="mm")
        d.text(((lo + hi) / 2, 226), "FIELD", font=mid, fill=GOLD, anchor="mm")
        d.rectangle((lo, 250, hi, 290), outline=CREAM, width=2)
        d.text(((lo + hi) / 2, 270), "DON'T PASS BAR", font=small, fill=CREAM, anchor="mm")
        d.rounded_rectangle((lo - 24 if side < 0 else lo, 296, hi if side < 0 else hi + 24, 360), radius=20, outline=CREAM, width=3)
        d.text(((lo + hi) / 2, 328), "PASS LINE", font=big, fill=CREAM, anchor="mm")
    # The propositions in the middle.
    d.rectangle((w / 2 - 96, 30, w / 2 + 96, 330), outline=CREAM, width=2)
    d.text((w / 2, 56), "SEVEN  4 TO 1", font=small, fill=RED, anchor="mm")
    for k, (a, b) in enumerate([("HARD 6", "9 TO 1"), ("HARD 10", "7 TO 1"), ("HARD 8", "9 TO 1"), ("HARD 4", "7 TO 1")]):
        x = w / 2 - 48 + (k % 2) * 96
        y = 100 + (k // 2) * 70
        d.rectangle((x - 46, y - 30, x + 46, y + 30), outline=CREAM, width=1)
        d.text((x, y - 9), a, font=small, fill=CREAM, anchor="mm")
        d.text((x, y + 11), b, font=small, fill=GOLD, anchor="mm")
    d.text((w / 2, 260), "ANY CRAPS  7 TO 1", font=small, fill=CREAM, anchor="mm")
    d.text((w / 2, 300), "THE TIDELINE", font=mid, fill=GOLD, anchor="mm")
    save("felt_craps", img.convert("RGB"))


def felt_baccarat():
    """The high-limit room's baccarat table, 2.8 x 1.5 m to 1024 x 512, in burgundy: fourteen
    places round the curve, each with its player, banker and tie boxes."""
    w, h = 1024, 512
    img = to_img(felt(w, h, "#5a1420", 13)).convert("RGBA")
    d = ImageDraw.Draw(img)
    cx, cy = w / 2, -170
    for r, label, f in [(470, "TIE  8 TO 1", font("SemiBold", 20)), (560, "BANKER", font("Bold", 26)), (650, "PLAYER", font("Bold", 26))]:
        d.arc((cx - r - 40, cy - r - 40, cx + r + 40, cy + r + 40), 35, 145, fill=GOLD, width=2)
        text_on_arc(img, label, cx, cy, r, 0, f, GOLD if label != "TIE  8 TO 1" else CREAM)
    for k in range(7):
        a = math.radians(-45 + k * 15)
        x, y = cx + 610 * math.sin(a), cy + 610 * math.cos(a)
        d.text((x, y), str(k + 1), font=font("Medium", 18), fill=CREAM, anchor="mm")
    d.text((cx, 120), "BACCARAT", font=font("Bold", 34), fill=GOLD, anchor="mm")
    d.text((cx, 156), "THE TIDELINE  .  PRIVATE SALON", font=font("Medium", 15), fill=CREAM, anchor="mm")
    save("felt_baccarat", img.convert("RGB"))


# --- Slots, the eye, the boardwalk ------------------------------------------------------------------

def slot_art():
    """A slot machine's glass, 512 x 512: the top half is the top box's art (a wave under a
    sunburst and the machine's name), the bottom half the reels behind their window."""
    w, h = 512, 512
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    top = np.zeros((256, 512, 3))
    U, V = mt.grid(512, 256)
    sky = mt.srgb("#2a0a4a") * (1 - V[..., None]) + mt.srgb("#d0306a") * V[..., None]
    rays = 0.5 + 0.5 * np.cos(np.arctan2(V - 1.1, U - 0.5) * 24)
    top = sky * (0.8 + 0.3 * rays[..., None])
    wave = V - (0.72 + 0.06 * np.sin(U * 2 * math.pi * 3))
    top = np.where((wave > 0)[..., None], mt.srgb("#11a3b8") * (0.7 + 0.5 * (1 - V[..., None])), top)
    img.paste(to_img(top), (0, 0))
    d = ImageDraw.Draw(img)
    d.text((256, 82), "TIDE OF", font=font("Black", 40), fill=(255, 230, 140, 255), anchor="mm")
    d.text((256, 136), "FORTUNE", font=font("Black", 64), fill=(255, 214, 90, 255), anchor="mm")
    d.text((256, 214), "PROGRESSIVE  $48,212", font=font("Bold", 22), fill=(255, 255, 255, 255), anchor="mm")
    # The reels.
    d.rectangle((0, 256, 512, 512), fill=(24, 8, 30, 255))
    symbols = [["7", "BAR", "7"], ["BAR", "7", "~"], ["~", "BAR", "7"]]
    colours = {"7": (210, 30, 40, 255), "BAR": (20, 20, 22, 255), "~": (20, 140, 170, 255)}
    for k in range(3):
        x0 = 30 + k * 156
        d.rounded_rectangle((x0, 280, x0 + 140, 488), radius=12, fill=(246, 240, 228, 255))
        for j, s in enumerate(symbols[k]):
            y = 315 + j * 70
            f = font("Black", 46 if s == "7" else 30)
            d.text((x0 + 70, y), "≈" if s == "~" else s, font=f, fill=colours[s], anchor="mm")
        d.line((x0 + 4, 384, x0 + 136, 384), fill=(220, 40, 60, 255), width=3)
    save("slot_art", img.convert("RGB"))


def cctv_feed():
    """Nine grey-green camera pictures, 512 x 512 as three by three: tables from above with
    players round them, the cage counter, a corridor, the count table, each with its number
    and the time."""
    size = 512
    rng = np.random.default_rng(31)
    img = Image.new("RGB", (size, size), (10, 14, 12))
    d = ImageDraw.Draw(img)
    cell = size // 3
    labels = ["CAM 01  PIT A", "CAM 02  PIT B", "CAM 04  WHEEL 2", "CAM 07  CAGE", "CAM 08  COUNT", "CAM 11  CORRIDOR",
              "CAM 03  CRAPS", "CAM 12  STAFF DOOR", "CAM 15  HIGH LIMIT"]
    small = font("Medium", 11)
    for k in range(9):
        x0, y0 = (k % 3) * cell, (k // 3) * cell
        base = int(48 + rng.random() * 18)
        d.rectangle((x0 + 2, y0 + 2, x0 + cell - 2, y0 + cell - 2), fill=(base - 10, base + 6, base - 4))
        kind = k % 3
        if k in (0, 1, 2, 6, 8):
            # A table from above, with heads round it.
            tx, ty = x0 + cell / 2, y0 + cell / 2 + 8
            d.ellipse((tx - 52, ty - 30, tx + 52, ty + 30), fill=(base + 30, base + 46, base + 30))
            for j in range(6):
                a = math.pi * (0.15 + 0.7 * j / 5)
                hx, hy = tx + 62 * math.cos(a), ty + 40 * math.sin(a)
                d.ellipse((hx - 7, hy - 7, hx + 7, hy + 7), fill=(base - 26, base - 20, base - 26))
        elif k == 3 or k == 4:
            d.rectangle((x0 + 20, y0 + 60, x0 + cell - 20, y0 + 92), fill=(base + 34, base + 44, base + 36))
            for j in range(3):
                hx = x0 + 40 + j * 40
                d.ellipse((hx - 8, y0 + 100, hx + 8, y0 + 116), fill=(base - 26, base - 20, base - 26))
        else:
            # A corridor's perspective.
            cx, cy = x0 + cell / 2, y0 + cell / 2
            d.polygon([(x0 + 10, y0 + cell - 6), (cx - 18, cy - 10), (cx + 18, cy - 10), (x0 + cell - 10, y0 + cell - 6)], fill=(base + 18, base + 28, base + 18))
            d.rectangle((cx - 18, cy - 40, cx + 18, cy - 10), fill=(base - 14, base - 6, base - 14))
        d.text((x0 + 8, y0 + 8), labels[k], font=small, fill=(220, 230, 220))
        d.text((x0 + 8, y0 + cell - 20), "23:%02d:%02d" % (rng.integers(0, 59), rng.integers(0, 59)), font=small, fill=(220, 230, 220))
    a = np.asarray(img).astype(float) / 255.0
    lines = (np.arange(size) % 3 == 0)[:, None, None] * 0.12
    a = a * (1 - lines) * (rng.random((size, size, 1)) * 0.1 + 0.95)
    save("cctv_feed", a)


def planks():
    """Weathered boardwalk planks, 0.25 m wide, running across the picture, staggered joints,
    silvered wood with dark gaps (2 m a tile, 512 px)."""
    size = 512
    rng = np.random.default_rng(17)
    U, V = mt.grid(size, size)
    n = 8
    row = np.floor(V * n)
    fv = (V * n) % 1.0
    offs = (row * 0.37) % 1.0
    lengths = 0.5
    fu = ((U + offs) / lengths) % 1.0
    plank_id = row * 7 + np.floor((U + offs) / lengths)
    tone = (np.sin(plank_id * 12.9898) * 43758.5453) % 1.0
    grain = mt.smooth_noise(size, size, 4, rng, octaves=4)
    streak = 0.5 + 0.5 * np.sin((V * n * 18 + grain * 6) * math.pi)
    wood = mt.srgb("#7d7266") * (0.8 + 0.3 * tone[..., None]) * (0.9 + 0.12 * streak[..., None])
    wood = wood * (0.92 + 0.14 * mt.smooth_noise(size, size, 16, rng)[..., None])
    gap = (fv < 0.05) | (fv > 0.97) | (fu < 0.006)
    img = np.where(gap[..., None], mt.srgb("#14110e"), wood)
    nails = (np.abs(fu - 0.04) < 0.008) & ((np.abs(fv - 0.25) < 0.03) | (np.abs(fv - 0.75) < 0.03))
    img[nails] = mt.srgb("#2e2a26")
    save("planks", img)


ALL = {
    "carpet_casino": carpet_casino,
    "damask_wine": lambda: damask("damask_wine", "#3e0d16", "#a17a3c", 41),
    "damask_green": lambda: damask("damask_green", "#12281f", "#8f7637", 43),
    "felt_blackjack": felt_blackjack,
    "felt_roulette": felt_roulette,
    "wheel_roulette": wheel_roulette,
    "felt_craps": felt_craps,
    "felt_baccarat": felt_baccarat,
    "slot_art": slot_art,
    "cctv_feed": cctv_feed,
    "planks": planks,
}


def main():
    os.makedirs(OUT, exist_ok=True)
    want = sys.argv[1:] or list(ALL)
    for name in want:
        ALL[name]()


if __name__ == "__main__":
    main()
