#!/usr/bin/env python3
"""Paints the Meridian's surfaces that the Downtown City kit doesn't have, as
tiling PNGs in assets/textures/hotel/ (python3 with numpy and Pillow):

    python3 tools/make_textures.py [name ...]

  carpet_ballroom   the ballroom's carpet: claret, with gold medallions and
                    scrolling leaves (one tile is 2 m)
  rug_lobby         the lobby's rug, a Persian-style field, medallion and
                    border (4 x 3 m, one picture; tools/blender/props.py
                    puts it on the rug)
  parquet           herringbone oak for the dance floor and the bar (0.85 m),
                    and its normal map
  tile_quarry       the kitchen's red quarry tiles (1.2 m), and normal map
  tile_white        white wall tiles for the kitchen (1.2 m), and normal map
  carpet_office     the security office's grey-blue carpet tiles (2 m)
  silk_stripe       the champagne silk stripe in the ballroom's wall panels
  marble_lobby      the lobby's floor: cream and black marble squares, 0.6 m,
                    laid as a chequerboard (2.4 m), and its normal map
  painting_coast    the lobby's paintings, after the old masters: a coast at
  painting_valley   dusk, a river valley in the evening and, for the
  painting_caldera  museum's gala, a volcano at night (one picture each)

Everything comes from fixed seeds, so the pictures only change when this
script does.
"""
import math
import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "textures", "hotel")


def srgb(hexstr):
    h = hexstr.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def grid(w, h, ss=1):
    """Pixel centres in 0..1 (u right, v down), supersampled `ss` times."""
    u = (np.arange(w * ss) + 0.5) / (w * ss)
    v = (np.arange(h * ss) + 0.5) / (h * ss)
    return np.meshgrid(u, v)


def down(a, ss):
    if ss == 1:
        return a
    h, w = a.shape[0] // ss, a.shape[1] // ss
    return a.reshape(h, ss, w, ss, *a.shape[2:]).mean(axis=(1, 3))


def smooth_noise(w, h, cells, rng, octaves=3):
    """Tiling value noise in 0..1."""
    out = np.zeros((h, w))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        c = cells * (2 ** o)
        g = rng.random((c, c))
        g = np.pad(g, ((0, 1), (0, 1)), mode="wrap")
        y = np.linspace(0, c, h, endpoint=False)
        x = np.linspace(0, c, w, endpoint=False)
        X, Y = np.meshgrid(x, y)
        x0, y0 = X.astype(int), Y.astype(int)
        fx, fy = X - x0, Y - y0
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        a = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
        b = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
        out += amp * (a * (1 - fy) + b * fy)
        total += amp
        amp *= 0.5
    return out / total


def save(name, rgb):
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


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# --- The ballroom's carpet -------------------------------------------------------------------

def carpet_ballroom():
    size, ss = 1024, 2
    U, V = grid(size, size, ss)
    rng = np.random.default_rng(11)
    base = srgb("#5c1119")
    dark = srgb("#3a0a10")
    gold = srgb("#b98b3e")
    olive = srgb("#6e5a2a")
    # Two medallions per tile, on a diamond lattice.
    img = np.zeros(U.shape + (3,)) + base
    pat = np.zeros(U.shape)
    trim = np.zeros(U.shape)
    for cx, cy in [(0.25, 0.25), (0.75, 0.75)]:
        dx = (U - cx + 0.5) % 1.0 - 0.5
        dy = (V - cy + 0.5) % 1.0 - 0.5
        r = np.hypot(dx, dy)
        a = np.arctan2(dy, dx)
        # Eight petals round a ring and a rosette.
        petal = r - (0.13 + 0.035 * np.cos(8 * a))
        pat = np.maximum(pat, smoothstep(0.006, -0.006, np.abs(petal) - 0.009))
        pat = np.maximum(pat, smoothstep(0.004, -0.004, r - 0.035 - 0.012 * np.cos(6 * a)))
        trim = np.maximum(trim, smoothstep(0.004, -0.004, np.abs(r - 0.075) - 0.006))
        # Leaves reaching out along the diagonals.
        for k in range(4):
            ang = math.pi / 4 + k * math.pi / 2
            ax, ay = math.cos(ang), math.sin(ang)
            along = dx * ax + dy * ay
            across = -dx * ay + dy * ax
            leaf = np.abs(across) - 0.028 * np.sin(np.clip((along - 0.16) / 0.17, 0, 1) * math.pi)
            mask = (along > 0.16) & (along < 0.33)
            pat = np.maximum(pat, np.where(mask, smoothstep(0.004, -0.004, leaf), 0))
            vein = np.abs(across - 0.01 * np.sin((along - 0.16) * 40)) - 0.0025
            trim = np.maximum(trim, np.where(mask, smoothstep(0.003, -0.003, vein), 0))
    # Small diamonds between the medallions.
    for cx, cy in [(0.75, 0.25), (0.25, 0.75)]:
        dx = (U - cx + 0.5) % 1.0 - 0.5
        dy = (V - cy + 0.5) % 1.0 - 0.5
        d = np.abs(dx) + np.abs(dy)
        pat = np.maximum(pat, smoothstep(0.004, -0.004, np.abs(d - 0.05) - 0.007))
        trim = np.maximum(trim, smoothstep(0.004, -0.004, d - 0.018))
    # A darker lattice of fine lines.
    lat = np.minimum(np.abs(((U + V) % 0.5) - 0.25), np.abs(((U - V) % 0.5) - 0.25))
    field = smoothstep(0.004, 0.0, lat - 0.0015)
    img = img * (1 - 0.35 * field[..., None]) + 0 * field[..., None]
    img = img * (1 - pat[..., None]) + gold * pat[..., None]
    img = img * (1 - trim[..., None]) + olive * trim[..., None]
    img = down(img, ss)
    # Pile: fine speckle and a soft mottle, the way wool takes the light.
    speck = rng.random((size, size, 1)) * 0.12 + 0.94
    mottle = smooth_noise(size, size, 8, rng)[..., None] * 0.12 + 0.94
    img = img * speck * mottle
    img = img * 0.94 + dark * 0.06
    save("carpet_ballroom", img)


# --- The lobby's rug ------------------------------------------------------------------------------

def rug_lobby():
    w, h, ss = 1024, 768, 2
    U, V = grid(w, h, ss)
    rng = np.random.default_rng(5)
    red = srgb("#6b1a1c")
    navy = srgb("#1c2541")
    gold = srgb("#b38a45")
    cream = srgb("#d9c9a3")
    rust = srgb("#9a4a2a")
    # Distances in metres on a 4 x 3 rug.
    X = (U - 0.5) * 4.0
    Y = (V - 0.5) * 3.0
    edge = np.minimum(2.0 - np.abs(X), 1.5 - np.abs(Y))
    img = np.zeros(U.shape + (3,)) + red
    # Borders: an outer navy band with a running vine, gold guard stripes.
    band = (edge < 0.32)
    img[band] = navy
    for d in (0.04, 0.30, 0.34):
        img[np.abs(edge - d) < 0.012] = gold
    t = np.where(np.abs(X) / 2.0 > np.abs(Y) / 1.5, Y, X)
    vine = np.abs((edge - 0.17) - 0.06 * np.sin(t * 2 * math.pi / 0.42)) < 0.016
    img[band & vine & (edge > 0.06) & (edge < 0.28)] = rust
    buds = (np.hypot((t * 2 / 0.42) % 1 - 0.5, (edge - 0.17) / 0.12) < 0.22) & band & (edge > 0.06) & (edge < 0.28)
    img[buds] = cream
    # Field: a lattice of small guls.
    field = edge >= 0.34
    gx = ((X / 0.5) % 1) - 0.5
    gy = ((Y / 0.5) % 1) - 0.5
    gul = (np.abs(gx) + np.abs(gy)) < 0.22
    img[field & gul] = rust
    img[field & ((np.abs(gx) + np.abs(gy)) < 0.09)] = cream
    # The medallion: a lobed ellipse in navy with a gold edge and a cream heart.
    R = np.hypot(X / 1.1, Y / 0.8)
    A = np.arctan2(Y, X)
    lobe = R - (1.0 + 0.08 * np.cos(12 * A))
    img[field & (lobe < 0)] = navy
    img[field & (np.abs(lobe) < 0.035)] = gold
    inner = np.hypot(X / 0.5, Y / 0.36) - (1.0 + 0.1 * np.cos(8 * A))
    img[field & (inner < 0)] = red
    img[field & (np.abs(inner) < 0.06)] = gold
    img[np.hypot(X, Y) < 0.1] = cream
    # Corner spandrels.
    for sx in (-1, 1):
        for sy in (-1, 1):
            c = np.hypot((X - sx * 1.66) / 0.7, (Y - sy * 1.16) / 0.5)
            img[field & (c < 1) & (np.abs(c - 0.85) < 0.06)] = gold
            img[field & (c < 0.75)] = navy
    img = down(img, ss)
    wear = smooth_noise(w, h, 6, rng)[..., None] * 0.14 + 0.92
    pile = rng.random((h, w, 1)) * 0.1 + 0.95
    save("rug_lobby", img * wear * pile)


# --- Herringbone parquet -------------------------------------------------------------------------

def parquet():
    """Herringbone oak: blocks W x 4W laid at 45 degrees, so the zigzags run
    along the tile's v. Unrotated, block pair m of staircase j is a lying block
    [mk + j, mk + j + k] x [mk - j, mk - j + 1] and a standing one
    [mk + j + k - 1, mk + j + k] x [mk - j + 1, mk - j + k + 1] (in W); the
    pattern repeats every A staircases and B pairs, which is one square tile."""
    size, ss = 1024, 2
    k, A, B = 4, 8, 2
    period = A * math.sqrt(2)  # in W, equal to B * k * sqrt(2)
    U, V = grid(size, size, ss)
    u, v = U * period, V * period
    x = (u + v) / math.sqrt(2)
    y = (v - u) / math.sqrt(2)
    ident = np.full(U.shape, -1, dtype=np.int64)
    lx = np.zeros(U.shape)  # along the block, 0..1
    ly = np.zeros(U.shape)  # across it, 0..1
    span = int(period * 2) + 2
    for j in range(-span, span):
        for m in range(-span // k - 2, span // k + 2):
            x0, y0 = m * k + j, m * k - j
            for kind, (bx0, by0, bx1, by1) in enumerate([(x0, y0, x0 + k, y0 + 1), (x0 + k - 1, y0 + 1, x0 + k, y0 + k + 1)]):
                inside = (x >= bx0) & (x < bx1) & (y >= by0) & (y < by1)
                if not inside.any():
                    continue
                ident[inside] = ((j % A) * B + (m % B)) * 2 + kind
                if kind == 0:
                    lx[inside] = (x[inside] - bx0) / k
                    ly[inside] = y[inside] - by0
                else:
                    lx[inside] = (y[inside] - by0) / k
                    ly[inside] = x[inside] - bx0
    rng = np.random.default_rng(3)
    tone = rng.random(A * B * 2) * 0.22 + 0.86
    warm = rng.random(A * B * 2) * 0.08 - 0.04
    oak = srgb("#8f5d33")
    grain = 0.5 + 0.5 * np.sin(ly * 9.0 + np.sin(lx * 7.0 + ident) * 1.6 + ident * 1.3)
    fine = 0.5 + 0.5 * np.sin(ly * 40.0 + lx * 3.0 + ident)
    t = tone[ident][..., None]
    img = oak * t * (0.88 + 0.08 * grain[..., None] + 0.04 * fine[..., None])
    img[..., 0] *= 1 + warm[ident]
    seam = np.minimum(np.minimum(lx * k, (1 - lx) * k), np.minimum(ly, 1 - ly))
    edge = smoothstep(0.0, 0.06, seam)
    img = img * (0.35 + 0.65 * edge[..., None])
    img = down(img, ss)
    save("parquet", img)
    save("parquet_n", normal_map(down(edge, ss), 2.0))


# --- Kitchen tiles ---------------------------------------------------------------------------------

def tiles(name, size, count_x, count_y, colour, grout, var, rng, bond=False, mottle_amount=0.05, grout_w=0.0035):
    """Tiles `count_x` by `count_y` to the picture (offset every other row when
    `bond`), with grout `grout_w` of the picture wide, and a normal map with
    rounded tile edges."""
    U, V = grid(size, size)
    tx = U * count_x
    ty = V * count_y
    row = np.floor(ty)
    if bond:
        tx = tx + (row % 2) * 0.5
    fx, fy = tx % 1.0, ty % 1.0
    ix = np.floor(tx) % count_x
    # Distance to the tile's edge, in picture widths.
    edge = np.minimum(np.minimum(fx, 1 - fx) / count_x, np.minimum(fy, 1 - fy) / count_y)
    tile_id = (ix * 13 + row * 7) % 23
    tone = 1.0 + var * np.sin(tile_id * 2.3)
    img = colour * tone[..., None]
    mottle = smooth_noise(size, size, 16, rng)[..., None]
    img = img * (1.0 - mottle_amount + 2 * mottle_amount * mottle)
    img[edge < grout_w] = grout
    height = smoothstep(grout_w * 0.6, grout_w * 2.5, edge)
    save(name, img)
    save(name + "_n", normal_map(height, 3.0))


def tile_quarry():
    rng = np.random.default_rng(8)
    tiles("tile_quarry", 1024, 8, 8, srgb("#8c3b25"), srgb("#3a3430"), 0.07, rng)


def tile_white():
    rng = np.random.default_rng(9)
    tiles("tile_white", 1024, 8, 16, srgb("#e9e7e0"), srgb("#b3aea2"), 0.012, rng, bond=True, mottle_amount=0.012, grout_w=0.0022)


# --- Office carpet and the silk damask -------------------------------------------------------------

def carpet_office():
    size = 512
    rng = np.random.default_rng(4)
    U, V = grid(size, size)
    base = srgb("#38404a")
    n = smooth_noise(size, size, 32, rng, octaves=3)
    img = base * (0.85 + 0.3 * n[..., None])
    # Carpet tiles 0.5 m, laid quarter-turned, so the pile catches the light differently.
    q = ((np.floor(U * 4) + np.floor(V * 4)) % 2)[..., None]
    img = img * (0.95 + 0.07 * q)
    stripes = 0.5 + 0.5 * np.sin(np.where(q[..., 0] > 0, U, V) * 2 * math.pi * 64)
    img = img * (0.96 + 0.06 * stripes[..., None])
    img = img * (rng.random((size, size, 1)) * 0.12 + 0.94)
    save("carpet_office", img)


def silk_stripe():
    """Champagne silk in Regency stripes: satin bands between matte ones, with
    a fine pinstripe, 0.5 m a tile."""
    size = 512
    U, V = grid(size, size)
    rng = np.random.default_rng(2)
    base = srgb("#bfa676")
    satin = srgb("#d9c497")
    pin = srgb("#9c8250")
    s = (U * 4) % 1.0
    band = smoothstep(0.0, 0.01, s - 0.08) * smoothstep(0.0, 0.01, 0.48 - s)
    img = base * (1 - band[..., None]) + satin * band[..., None]
    pins = (np.abs(s - 0.04) < 0.006) | (np.abs(s - 0.52) < 0.004) | (np.abs(s - 0.56) < 0.004)
    img[pins] = pin
    weave = 0.5 + 0.5 * np.sin(V * 2 * math.pi * 180)
    img = img * (0.97 + 0.04 * weave[..., None]) * (rng.random((size, size, 1)) * 0.03 + 0.985)
    save("silk_stripe", img)


# --- The lobby's marble ------------------------------------------------------------------------------

def marble_lobby():
    """Cream and black marble in 0.6 m squares, four by four to the picture
    (2.4 m), veined, with hairline joints."""
    size = 1024
    rng = np.random.default_rng(11)
    U, V = grid(size, size)
    n4 = 4
    tx, ty = U * n4, V * n4
    ix, iy = np.floor(tx), np.floor(ty)
    fx, fy = tx % 1.0, ty % 1.0
    dark = ((ix + iy) % 2) == 1
    # Veins: a warped stripe field, turned and shifted per square so no two match.
    warp = smooth_noise(size, size, 6, rng, octaves=4)
    warp2 = smooth_noise(size, size, 12, rng, octaves=3)
    tid = ix * 5 + iy * 3
    ang = tid * 1.7
    along = U * np.cos(ang) + V * np.sin(ang)
    phase = (along * 4.0 + warp * 2.4 + warp2 * 0.6 + tid * 0.37) * math.pi
    sp = np.sin(phase)
    vein = np.exp(-(sp / 0.025) ** 2) * 0.8 + np.exp(-(sp / 0.18) ** 2) * 0.25
    fine = np.exp(-(np.sin((along * 11.0 + warp2 * 3.0 + warp * 1.5) * math.pi) / 0.02) ** 2) * 0.35
    cloud = smooth_noise(size, size, 10, rng, octaves=4)
    cream = srgb("#d9cdb8") * (0.93 + 0.1 * cloud[..., None])
    cream = cream * (1 - 0.32 * vein[..., None] - 0.12 * fine[..., None]) + srgb("#b9ab95") * 0.0
    black = srgb("#2a2624") * (0.85 + 0.35 * cloud[..., None])
    black = black + (srgb("#9a948c") - black) * (0.55 * vein + 0.25 * fine)[..., None]
    img = np.where(dark[..., None], black, cream)
    edge = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy)) / n4
    joint = edge < 0.0012
    img[joint] = srgb("#5a5550")
    save("marble_lobby", img)
    save("marble_lobby_n", normal_map(smoothstep(0.0006, 0.0025, edge), 2.0))


# --- Paintings ---------------------------------------------------------------------------------

def ridge(w, rng, base, amp, points, rough=0.0):
    """A skyline across the picture: y (0 top, 1 bottom) for each column."""
    xs = np.linspace(0, 1, points)
    ys = rng.random(points)
    x = (np.arange(w) + 0.5) / w
    y = np.interp(x, xs, ys)
    # Smooth it, then add a little crag.
    k = max(3, w // points)
    kern = np.ones(k) / k
    y = np.convolve(np.pad(y, k, mode="edge"), kern, mode="same")[k:-k]
    if rough > 0:
        y = y + (rng.random(w) - 0.5) * rough
        y = np.convolve(np.pad(y, 3, mode="edge"), np.ones(5) / 5, mode="same")[3:-3]
    return base - amp * y


def mix(a, b, t):
    t = np.asarray(t)
    if t.ndim == 2:
        t = t[..., None]
    return a + (b - a) * t


def finish_painting(img, rng, warm=0.0):
    """Brushwork, old varnish and a darkened edge."""
    h, w = img.shape[:2]
    # Horizontal strokes: noise stretched along x.
    n1 = smooth_noise(w, h, 64, rng, octaves=2)
    n2 = smooth_noise(w // 8 if w > 256 else w, h, 96, rng, octaves=1)
    n2 = np.array(Image.fromarray((n2 * 255).astype(np.uint8)).resize((w, h), Image.BILINEAR)) / 255.0
    stroke = (n1 - 0.5) * 0.08 + (n2 - 0.5) * 0.1
    img = img * (1.0 + stroke[..., None])
    # Canvas weave.
    U, V = grid(w, h)
    weave = (np.sin(U * w * 1.4) * np.sin(V * h * 1.4)) * 0.015
    img = img * (1.0 + weave[..., None])
    # Varnish: warmer and a little darker.
    img = img * np.array([1.0, 0.93, 0.78 - warm])
    # Vignette.
    d = ((U - 0.5) / 0.62) ** 2 + ((V - 0.5) / 0.62) ** 2
    img = img * (1.0 - 0.45 * smoothstep(0.35, 1.3, d))[..., None]
    return np.clip(img, 0, 1)


def painting_coast():
    """A rocky coast at dusk: the sun just over the sea, a headland on the left."""
    w, h = 900, 600
    rng = np.random.default_rng(31)
    U, V = grid(w, h)
    horizon = 0.6
    sky_top, sky_low = srgb("#1f2a3c"), srgb("#e3a15a")
    t = smoothstep(0.0, horizon, V) ** 1.6
    img = mix(sky_top, sky_low, t)
    sun = np.exp(-(((U - 0.66) / 0.05) ** 2 + ((V - (horizon - 0.06)) / 0.05) ** 2))
    glow = np.exp(-(((U - 0.66) / 0.3) ** 2 + ((V - horizon) / 0.2) ** 2))
    img = img + srgb("#ffd79a") * (sun * 0.9)[..., None] + srgb("#f09a50") * (glow * 0.35)[..., None]
    # Clouds: long bands, dark above, lit underneath.
    cl = smooth_noise(w, h, 5, rng, octaves=4)
    band = np.sin(V * 22.0 + cl * 6.0) * 0.5 + 0.5
    cloud = smoothstep(0.55, 0.85, band * cl * 1.6) * smoothstep(horizon - 0.02, 0.1, V)
    img = mix(img, mix(srgb("#2b2730"), srgb("#c9784a"), smoothstep(0.1, horizon, V) * (0.4 + glow)), cloud * 0.75)
    # The sea: dark, with the sun's road on it.
    sea = V > horizon
    s = (V - horizon) / (1 - horizon)
    sea_col = mix(srgb("#3a3f48"), srgb("#10161c"), np.clip(s, 0, 1) ** 0.6)
    ripple = smooth_noise(w, h, 48, rng, octaves=2)
    streak = smooth_noise(w, h, 90, rng, octaves=2)
    streak = np.array(Image.fromarray((streak * 255).astype(np.uint8)).resize((w // 6, h), Image.BILINEAR).resize((w, h), Image.BILINEAR)) / 255.0
    road = np.exp(-((U - 0.66) / (0.04 + 0.2 * s)) ** 2) * smoothstep(0.45, 0.7, streak + ripple * 0.2)
    sea_col = sea_col + srgb("#f2b46a") * (road * (0.8 - 0.5 * s))[..., None]
    img = np.where(sea[..., None], sea_col, img)
    # The headland, and rocks in front.
    far = ridge(w, rng, horizon - 0.005, 0.12, 9) + smoothstep(0.3, 0.6, (np.arange(w) + 0.5) / w) * 0.6
    near = ridge(w, rng, 1.02, 0.5, 7, rough=0.01) + smoothstep(0.2, 0.42, (np.arange(w) + 0.5) / w) * 0.6
    land_far = V > far[None, :]
    img = np.where(land_far[..., None], mix(srgb("#3a2e2a"), srgb("#241e1d"), cl) + srgb("#a0603a") * (glow * 0.25)[..., None], img)
    land = V > near[None, :]
    rock = mix(srgb("#231c17"), srgb("#0e0c0a"), smoothstep(0.6, 1.0, V)) * (0.7 + 0.6 * cl[..., None])
    rim = np.exp(-((V - near[None, :]) / 0.012) ** 2) * 0.3
    img = np.where(land[..., None], rock + srgb("#d08a4a") * rim[..., None], img)
    save("painting_coast", finish_painting(img, rng))


def painting_valley():
    """A river valley in the evening: hills fading into haze, trees, the river."""
    w, h = 900, 600
    rng = np.random.default_rng(37)
    U, V = grid(w, h)
    sky_top, sky_low = srgb("#5d6f86"), srgb("#f0d29a")
    img = mix(sky_top, sky_low, smoothstep(0.0, 0.55, V))
    cl = smooth_noise(w, h, 6, rng, octaves=5)
    puff = smoothstep(0.5, 0.75, cl) * smoothstep(0.55, 0.05, V)
    img = mix(img, mix(srgb("#f4e2c0"), srgb("#8a8c98"), smoothstep(0.3, 0.8, cl)), puff * 0.8)
    haze = srgb("#c9c2aa")
    layers = [
        (0.52, 0.12, 6, srgb("#7c8a8c"), 0.7),
        (0.6, 0.12, 8, srgb("#5f6f5a"), 0.45),
        (0.7, 0.15, 7, srgb("#3f4f33"), 0.2),
        (0.86, 0.2, 6, srgb("#283420"), 0.0),
    ]
    for base, amp, pts, col, hz in layers:
        y = ridge(w, rng, base, amp, pts, rough=0.004)
        mask = V > y[None, :]
        shade = mix(col, col * 0.7, smoothstep(0.0, 0.2, V - y[None, :]))
        shade = mix(shade, haze, hz) * (0.9 + 0.25 * cl[..., None])
        img = np.where(mask[..., None], shade, img)
    # The river: a winding light band in the valley floor, reflecting the sky.
    rv = 0.5 + 0.18 * np.sin(V * 9.0 + 1.0) * smoothstep(0.62, 1.0, V)
    width = 0.004 + 0.09 * smoothstep(0.66, 1.0, V) ** 1.5
    river = (np.abs(U - rv) < width) & (V > 0.66)
    img = np.where(river[..., None], mix(srgb("#e8d6a8"), srgb("#8a9aa4"), smoothstep(0.66, 1.0, V)), img)
    # Trees: dark clumps on the near slopes.
    trees = smooth_noise(w, h, 24, rng, octaves=3)
    clump = (trees > 0.66) & (V > 0.62) & ~river
    img = np.where(clump[..., None], srgb("#1a2214") * (0.8 + 0.4 * trees[..., None]), img)
    save("painting_valley", finish_painting(img, rng))


def painting_caldera():
    """A volcano at night, the crater glowing, smoke lit from beneath, a lake."""
    w, h = 600, 800
    rng = np.random.default_rng(41)
    U, V = grid(w, h)
    img = mix(srgb("#0b0d16"), srgb("#3a1a14"), smoothstep(0.0, 0.62, V))
    # The cone: a trapezoid with a notch for the crater.
    peak = 0.33
    slope = np.abs(U - 0.5)
    edge = ridge(w, rng, 0.0, 0.035, 14, rough=0.01)[None, :]
    cone_top = peak + (np.maximum(0.0, slope - 0.09) ** 1.25) * 1.9 - edge
    crater = (slope < 0.09) & (V > peak + 0.015)
    cone = (V > cone_top) | crater
    cone = cone & (V < 0.72)
    cl = smooth_noise(w, h, 8, rng, octaves=5)
    # Smoke: a column rising from the crater, spreading.
    sx = (U - 0.5 - (peak - V) * 0.35 * cl) / (0.06 + (peak - V) * 0.6)
    smoke = np.exp(-sx ** 2) * smoothstep(peak + 0.02, 0.02, V) * (0.4 + 0.8 * cl)
    lit = smoothstep(0.0, peak, V) ** 2
    img = mix(img, mix(srgb("#1d1716"), srgb("#c0502a"), lit), np.clip(smoke, 0, 1) * 0.85)
    glow = np.exp(-(((U - 0.5) / 0.12) ** 2 + ((V - peak) / 0.05) ** 2))
    img = img + srgb("#ff8a3a") * (glow * 0.8)[..., None]
    rock = mix(srgb("#1a1412"), srgb("#0c0a0a"), smoothstep(peak, 0.72, V)) * (0.7 + 0.6 * cl[..., None])
    # Lava runs down the slopes.
    runs = np.exp(-((np.sin(U * 40.0 + cl * 8.0) * 0.5 + 0.5 - 0.98) / 0.012) ** 2)
    runs = runs * smoothstep(0.72, peak, V) * (slope < 0.3)
    rock = rock + srgb("#ff6a20") * (runs * 0.9 + glow * 0.4)[..., None]
    img = np.where(cone[..., None], rock, img)
    # The lake below, reflecting it all.
    lake = V > 0.72
    rv = np.clip(2 * 0.72 - V, 0, 1)
    ref = np.zeros_like(img)
    rows = np.clip((rv * h).astype(int), 0, h - 1)
    ref = img[rows[:, 0], :, :]
    ripple = smooth_noise(w, h, 40, rng, octaves=2)
    ref = ref * (0.45 + 0.2 * np.sin(V * 600 + ripple * 10)[..., None])
    img = np.where(lake[..., None], ref + srgb("#05070a"), img)
    # The shore.
    shore = ridge(w, rng, 0.75, 0.04, 8, rough=0.006)
    img = np.where((np.abs(V - shore[None, :]) < 0.008)[..., None] & lake[..., None], srgb("#0a0808"), img)
    save("painting_caldera", finish_painting(img, rng, warm=0.04))


ALL = {
    "carpet_ballroom": carpet_ballroom,
    "rug_lobby": rug_lobby,
    "parquet": parquet,
    "tile_quarry": tile_quarry,
    "tile_white": tile_white,
    "carpet_office": carpet_office,
    "silk_stripe": silk_stripe,
    "marble_lobby": marble_lobby,
    "painting_coast": painting_coast,
    "painting_valley": painting_valley,
    "painting_caldera": painting_caldera,
}


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    want = sys.argv[1:] or list(ALL)
    for n in want:
        ALL[n]()
