#!/usr/bin/env python3
"""Paints the Marlin's surfaces that neither the Downtown City kit nor the Meridian has, as tiling
PNGs in assets/textures/marlin/ (python3 with numpy and Pillow):

    python3 tools/marlin_textures.py [name ...]

  teak      the decks: teak planks laid fore and aft (along the picture's v) with black caulking
            and staggered butt joints (one tile is 2 m), and its normal map

Everything comes from fixed seeds, so the pictures only change when this script does.
"""
import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures", "marlin")


def srgb(hexstr):
    h = hexstr.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def grid(w, h, ss=1):
    u = (np.arange(w * ss) + 0.5) / (w * ss)
    v = (np.arange(h * ss) + 0.5) / (h * ss)
    return np.meshgrid(u, v)


def down(a, ss):
    if ss == 1:
        return a
    h, w = a.shape[0] // ss, a.shape[1] // ss
    return a.reshape(h, ss, w, ss, *a.shape[2:]).mean(axis=(1, 3))


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def save(name, rgb):
    os.makedirs(OUT, exist_ok=True)
    img = Image.fromarray((np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8))
    img.save(os.path.join(OUT, name + ".png"), optimize=True)
    print(name, img.size)


def normal_map(height, strength):
    """A tangent-space normal map (OpenGL, +Y up) from a tiling height field."""
    dx = (np.roll(height, -1, 1) - np.roll(height, 1, 1)) * 0.5 * strength
    dy = (np.roll(height, -1, 0) - np.roll(height, 1, 0)) * 0.5 * strength
    n = np.dstack([-dx, dy, np.ones_like(height)])
    n /= np.linalg.norm(n, axis=2, keepdims=True)
    return n * 0.5 + 0.5


def teak():
    """Planks 1/32 of the tile wide (6 cm on a 2 m tile), each in two or three lengths with butt
    joints at random places, a warm honey colour that varies plank to plank, long grain along v,
    and black caulking between."""
    size, ss = 1024, 2
    planks = 32
    U, V = grid(size, size, ss)
    rng = np.random.default_rng(23)
    col = np.floor(U * planks).astype(int)
    across = U * planks - col
    # Butt joints: each plank is cut at two places down its length.
    first = rng.random(planks) * 0.4 + 0.05
    cuts = np.stack([first, first + 0.4 + rng.random(planks) * 0.15], axis=1)
    c0 = cuts[col, 0]
    c1 = cuts[col, 1]
    piece = np.where(V < c0, 0, np.where(V < c1, 1, 2))
    # The first and last pieces are one board across the tile's edge.
    piece = np.where(piece == 2, 0, piece)
    ident = col * 2 + piece
    tone = rng.random(planks * 2) * 0.24 + 0.84
    warm = rng.random(planks * 2) * 0.1 - 0.05
    honey = srgb("#a27a4e")
    phase = rng.random(planks * 2) * 40.0
    grain = 0.5 + 0.5 * np.sin(across * 7.0 + np.sin(V * 9.0 + phase[ident]) * 1.8 + phase[ident])
    fine = 0.5 + 0.5 * np.sin(across * 46.0 + V * 5.0 + phase[ident] * 3.0)
    streak = 0.5 + 0.5 * np.sin(V * 60.0 * (1.0 + 0.3 * tone[ident]) + phase[ident])
    img = honey * tone[ident][..., None] * (0.84 + 0.1 * grain[..., None] + 0.04 * fine[..., None] + 0.02 * streak[..., None])
    img[..., 0] *= 1 + warm[ident]
    img[..., 2] *= 1 - warm[ident] * 0.5
    # Caulking along the planks' sides and across the butt joints.
    side = np.minimum(across, 1 - across) / planks
    butt = np.minimum(np.abs(V - c0), np.abs(V - c1))
    gap = np.minimum(side, butt)
    caulk = smoothstep(0.0011, 0.0006, gap)
    black = srgb("#141210")
    img = img * (1 - caulk[..., None]) + black * caulk[..., None]
    img = down(img, ss)
    save("teak", img)
    save("teak_n", normal_map(down(1 - caulk, ss), 3.0))


TEXTURES = {"teak": teak}


def main():
    want = sys.argv[1:] or list(TEXTURES)
    for n in want:
        TEXTURES[n]()


if __name__ == "__main__":
    main()
