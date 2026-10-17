#!/usr/bin/env python3
"""Draws the game's icon: a brass speech bubble on dark lacquer, with a
silver tongue inside it. Writes icon.svg and the snap's copy:

    python3 tools/make_icon.py [--out=file.svg]

Plain shapes and gradients only, no filters, so Godot's SVG importer draws
it as a browser does.
"""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUTS = [ROOT / "icon.svg", ROOT / "snap/gui/silver-tongue.svg"]

SVG = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="lacquer" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#2a1a1c"/>
      <stop offset="1" stop-color="#120b0c"/>
    </linearGradient>
    <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f3d58a"/>
      <stop offset="0.5" stop-color="#d4a24a"/>
      <stop offset="1" stop-color="#8e6420"/>
    </linearGradient>
    <linearGradient id="silver" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#f4f4f6"/>
      <stop offset="0.55" stop-color="#c3c6cf"/>
      <stop offset="1" stop-color="#7d818c"/>
    </linearGradient>
    <linearGradient id="mouth" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#4a1418"/>
      <stop offset="1" stop-color="#2a0a0d"/>
    </linearGradient>
  </defs>
  <rect x="16" y="16" width="480" height="480" rx="96" fill="url(#lacquer)"/>
  <rect x="30" y="30" width="452" height="452" rx="84" fill="none" stroke="#d4a24a" stroke-opacity="0.35" stroke-width="4"/>
  <!-- The speech bubble, in brass. -->
  <path d="M 118 118 H 394 A 44 44 0 0 1 438 162 V 318 A 44 44 0 0 1 394 362 H 236 L 160 426 L 176 362 H 118 A 44 44 0 0 1 74 318 V 162 A 44 44 0 0 1 118 118 Z" fill="url(#brass)"/>
  <path d="M 126 130 H 386 A 32 32 0 0 1 418 162 V 318 A 32 32 0 0 1 386 350 H 228 L 180 392 L 190 350 H 126 A 32 32 0 0 1 94 318 V 162 A 32 32 0 0 1 126 130 Z" fill="url(#mouth)"/>
  <!-- The tongue, in silver. -->
  <path d="M 172 206 C 200 176 312 176 340 206 C 350 262 318 326 256 334 C 194 326 162 262 172 206 Z" fill="url(#silver)"/>
  <path d="M 256 212 C 252 250 250 290 256 322" fill="none" stroke="#8a8e99" stroke-opacity="0.75" stroke-width="7" stroke-linecap="round"/>
  <path d="M 196 214 C 220 200 292 200 316 214" fill="none" stroke="#ffffff" stroke-opacity="0.6" stroke-width="6" stroke-linecap="round"/>
</svg>
"""


def main():
    outs = OUTPUTS
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            outs = [Path(a[6:])]
    for p in outs:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(SVG)
        print("wrote", p)


if __name__ == "__main__":
    main()
