#!/usr/bin/env python3
"""Paints Vantage Tower's surfaces, as tiling PNGs in assets/textures/vantage/
(python3 with numpy and Pillow, and tools/make_textures.py's helpers):

    python3 tools/vantage_textures.py [name ...]

  city_windows    the city's towers at night: a grid of office windows, some
                  lit warm, some cool, most dark (one tile is 24 m square;
                  the venue uses it as the far towers' glow)
  tower_facade    Vantage's own curtain wall at night: blue-black glass on
                  1.5 m mullions, a spandrel at every 4 m storey, a few
                  offices still lit (one tile is 12 m square)
  terrazzo        the lobby's floor: pale grey terrazzo with stone chips
                  (one tile is 2 m), and its normal map
  carpet_board    the board floor's warm gray carpet tiles (2 m)
  limestone       the lobby's walls: pale limestone panels 1 m tall and 2 m
                  long with fine joints (one tile is 2 m), and its normal map
  oak_slats       an oak slat wall: 60 mm slats on a dark backing (one tile
                  is 1 m), and its normal map

Everything comes from fixed seeds, so the pictures only change when this
script does.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_textures as mt  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures", "vantage")


def save(name, rgb):
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8))
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print(name, img.size)


def city_windows():
    """12 windows across and 8 storeys up a 24 m tile: lit, dim or dark."""
    rng = np.random.default_rng(1401)
    size = 512
    cols, rows = 12, 8
    u, v = mt.grid(size, size)
    cu = np.floor(u * cols).astype(int)
    cv = np.floor(v * rows).astype(int)
    fu = u * cols - cu
    fv = v * rows - cv
    # Each window: dark, a cool screen glow, or a warm lit office.
    kind = rng.random((rows, cols))
    warm = mt.srgb("#ffc77a")
    cool = mt.srgb("#bcd6ff")
    dim = mt.srgb("#2c3644")
    colour = np.zeros((rows, cols, 3))
    level = np.zeros((rows, cols))
    for j in range(rows):
        # Whole floors tend to be lit or dark together.
        floor_lit = rng.random() < 0.35
        for i in range(cols):
            k = kind[j, i]
            if floor_lit and k < 0.75 or (not floor_lit and k < 0.12):
                colour[j, i] = warm if rng.random() < 0.7 else cool
                level[j, i] = 0.55 + 0.45 * rng.random()
            else:
                colour[j, i] = dim
                level[j, i] = 0.25 + 0.25 * rng.random()
    glass = colour[cv, cu] * level[cv, cu][..., None]
    # A soft falloff inside each pane: brighter in the middle, as a lit room is.
    inside = mt.smoothstep(0.0, 0.18, fu) * mt.smoothstep(0.0, 0.18, 1 - fu) * mt.smoothstep(0.0, 0.25, fv) * mt.smoothstep(0.0, 0.12, 1 - fv)
    glass *= 0.6 + 0.4 * inside[..., None]
    # Mullions and the spandrels between storeys are dark.
    pane = (fu > 0.08) & (fu < 0.92) & (fv > 0.18) & (fv < 0.94)
    frame = mt.srgb("#07090c")
    rgb = np.where(pane[..., None], glass, frame)
    save("city_windows", rgb)


def tower_facade():
    """Three 4 m storeys of 1.5 m bays on a 12 m tile: glass, spandrels, a few lit offices."""
    rng = np.random.default_rng(2207)
    size = 1024
    cols, rows = 8, 3
    u, v = mt.grid(size, size)
    cu = np.floor(u * cols).astype(int)
    cv = np.floor(v * rows).astype(int)
    fu = u * cols - cu
    fv = v * rows - cv
    noise = mt.smooth_noise(size, size, 6, rng, 3)
    # The glass: blue-black with a faint sky in it, darker low in each pane.
    glass = mt.srgb("#0b1320") * (0.75 + 0.5 * noise[..., None])
    glass = glass + mt.srgb("#1a2a40") * (0.35 * (1 - fv))[..., None]
    lit = np.zeros((rows, cols))
    tint = np.zeros((rows, cols, 3))
    for j in range(rows):
        for i in range(cols):
            if rng.random() < 0.3:
                lit[j, i] = 0.5 + 0.5 * rng.random()
                tint[j, i] = mt.srgb("#d8e6ff") if rng.random() < 0.6 else mt.srgb("#ffd9a8")
    # A lit office: the ceiling's strip lights and the glow beneath them.
    strip = mt.smoothstep(0.03, 0.0, np.abs(fv - 0.12)) * 0.7 + 0.32 + mt.smoothstep(0.78, 0.3, fv) * 0.2
    glow = tint[cv, cu] * (lit[cv, cu] * strip)[..., None]
    rgb = glass + glow
    # Spandrels hide each floor slab; mullions run up every bay.
    spandrel = fv > 0.8
    rgb = np.where(spandrel[..., None], mt.srgb("#11161d") * (0.9 + 0.2 * noise[..., None]), rgb)
    mullion = (fu < 0.025) | (fu > 0.975)
    rgb = np.where(mullion[..., None], mt.srgb("#2b3138"), rgb)
    transom = np.abs(fv - 0.8) < 0.006
    rgb = np.where(transom[..., None], mt.srgb("#3a424b"), rgb)
    save("tower_facade", rgb)


def terrazzo():
    """Pale grey terrazzo: a fine matrix with chips of grey, white, black and a warm stone."""
    rng = np.random.default_rng(311)
    size = 1024
    noise = mt.smooth_noise(size, size, 8, rng, 4)
    base = mt.srgb("#c9c8c3") * (0.94 + 0.08 * noise[..., None])
    rgb = base.copy()
    height = np.zeros((size, size))
    colours = [mt.srgb(c) for c in ("#f2f1ec", "#8d8c88", "#3a3a3c", "#b49a7c", "#e4e2dc", "#6f6d69")]
    yy, xx = np.mgrid[0:size, 0:size]
    for k in range(2600):
        cx, cy = rng.random() * size, rng.random() * size
        r = rng.choice([1.5, 2.0, 2.5, 3.5, 5.0, 7.0], p=[0.3, 0.25, 0.2, 0.13, 0.08, 0.04])
        col = colours[rng.integers(len(colours))] * (0.92 + 0.12 * rng.random())
        x0, x1 = int(cx - r - 2), int(cx + r + 3)
        y0, y1 = int(cy - r - 2), int(cy + r + 3)
        sx = np.arange(x0, x1) % size
        sy = np.arange(y0, y1) % size
        gx, gy = np.meshgrid(np.arange(x0, x1) - cx, np.arange(y0, y1) - cy)
        a = rng.random() * np.pi
        sq = 0.6 + 0.6 * rng.random()
        d = np.sqrt((gx * np.cos(a) + gy * np.sin(a)) ** 2 + ((-gx * np.sin(a) + gy * np.cos(a)) / sq) ** 2)
        m = np.clip(r - d + 0.5, 0, 1)
        sub = rgb[np.ix_(sy, sx)]
        rgb[np.ix_(sy, sx)] = sub * (1 - m[..., None]) + col * m[..., None]
        height[np.ix_(sy, sx)] = np.maximum(height[np.ix_(sy, sx)], m * 0.4)
    save("terrazzo", rgb)
    save("terrazzo_n", mt.normal_map(height + noise * 0.3, 1.2))


def carpet_board():
    """Warm gray carpet tiles, 0.5 m, laid quarter-turned, with a fine loop pile."""
    rng = np.random.default_rng(97)
    size = 1024
    tiles = 4
    u, v = mt.grid(size, size)
    cu = np.floor(u * tiles).astype(int)
    cv = np.floor(v * tiles).astype(int)
    fu = u * tiles - cu
    fv = v * tiles - cv
    turn = (cu + cv) % 2 == 0
    stripe = np.where(turn, np.sin(fu * np.pi * 48), np.sin(fv * np.pi * 48))
    pile = mt.smooth_noise(size, size, 64, rng, 2)
    shade = 0.85 + 0.08 * stripe + 0.12 * pile + 0.04 * np.where(turn, 1.0, -1.0)
    rgb = mt.srgb("#6b6862") * shade[..., None]
    seam = (fu < 0.004) | (fv < 0.004)
    rgb = np.where(seam[..., None], rgb * 0.7, rgb)
    save("carpet_board", rgb)


def limestone():
    """Pale limestone panels, 2 m by 1 m, each with its own shade and a fine fossil grain."""
    rng = np.random.default_rng(812)
    size = 1024
    u, v = mt.grid(size, size)
    rows = 2
    cv = np.floor(v * rows).astype(int)
    fv = v * rows - cv
    noise = mt.smooth_noise(size, size, 10, rng, 4)
    grain = mt.smooth_noise(size, size, 90, rng, 2)
    shade = np.array([0.96 + 0.06 * rng.random() for _ in range(rows)])[cv]
    rgb = mt.srgb("#d8d2c4") * (shade * (0.95 + 0.06 * noise + 0.03 * grain))[..., None]
    # Little dark flecks, as limestone has.
    flecks = (mt.smooth_noise(size, size, 200, rng, 1) > 0.82).astype(float) * 0.06
    rgb = rgb * (1 - flecks[..., None])
    joint = (fv < 0.004) | (fv > 0.996) | (u < 0.002) | (u > 0.998)
    rgb = np.where(joint[..., None], rgb * 0.62, rgb)
    height = 1.0 - joint.astype(float) + noise * 0.08
    save("limestone", rgb)
    save("limestone_n", mt.normal_map(height, 2.0))


def oak_slats():
    """Vertical oak slats, 60 mm wide with 20 mm gaps showing a dark felt backing."""
    rng = np.random.default_rng(433)
    size = 1024
    u, v = mt.grid(size, size)
    n = 12
    cu = np.floor(u * n).astype(int)
    fu = u * n - cu
    tone = np.array([0.88 + 0.2 * rng.random() for _ in range(n)])[cu]
    grain = mt.smooth_noise(size, size, 4, rng, 3)
    streak = 0.5 + 0.5 * np.sin((u * 340 + grain * 6.0 + v * 2.0) * np.pi)
    wood = mt.srgb("#a57a4c") * (tone * (0.86 + 0.12 * streak))[..., None]
    gap = fu > 0.75
    edge = mt.smoothstep(0.0, 0.06, fu) * mt.smoothstep(0.75, 0.69, fu)
    rgb = np.where(gap[..., None], mt.srgb("#1a1714"), wood * (0.8 + 0.2 * edge)[..., None])
    height = np.where(gap, 0.0, 0.6 + 0.4 * edge)
    save("oak_slats", rgb)
    save("oak_slats_n", mt.normal_map(height, 3.0))


ALL = {
    "city_windows": city_windows,
    "tower_facade": tower_facade,
    "terrazzo": terrazzo,
    "carpet_board": carpet_board,
    "limestone": limestone,
    "oak_slats": oak_slats,
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    want = sys.argv[1:] or list(ALL)
    for n in want:
        ALL[n]()
