#!/usr/bin/env python3
"""Copies the pieces of Quaternius' Downtown City MegaKit that Silver Tongue
uses into addons/quaternius/downtowncity/, from the kit's Source tier glTF
export for Godot (`Downtown City MegaKit[Source]/Exports/glTF (Godot)` in
https://github.com/LinuxGroove/quaternius-assets):

    python3 tools/vendor_megakit.py "/path/to/quaternius-assets/Downtown City MegaKit[Source]/Exports/glTF (Godot)"

Each model's glTF and buffer are copied as they are, with the textures they
name scaled to MAX_TEX pixels (the kit's 2K sheets are more than a hotel room
needs on a handheld). The kit is CC0 (Downtown_City_MegaKit_License.txt).
"""
import json
import os
import shutil
import sys

from PIL import Image

MAX_TEX = 1024
DEST = os.path.join(os.path.dirname(__file__), "..", "addons", "quaternius", "downtowncity")
MODELS = [
    # The hotel's back corridor: marble walls, a cornice, columns, the floor.
    "Marble_Plain_1", "Marble_Plain_3", "Marble_Plain_4", "Cornice_Marble_Center",
    "Marble_BevelColumn_Bottom", "Marble_BevelColumn_Center", "Marble_BevelColumn_Top",
    "Floor_4x4", "Floor_2x2",
    # The door the guard keeps.
    "DoorFrame_Marble", "DoorFrame_Wooden", "Door_1", "Door_2",
    # Dressing.
    "Prop_Planter_Single", "Prop_Column_Trim", "Prop_Ornament_1",
]


def main(src: str) -> None:
    os.makedirs(DEST, exist_ok=True)
    textures = set()
    for name in MODELS:
        gltf = os.path.join(src, name + ".gltf")
        g = json.load(open(gltf))
        shutil.copy(gltf, os.path.join(DEST, name + ".gltf"))
        for b in g.get("buffers", []):
            shutil.copy(os.path.join(src, b["uri"]), os.path.join(DEST, b["uri"]))
        for im in g.get("images", []):
            textures.add(im["uri"])
    for t in sorted(textures):
        img = Image.open(os.path.join(src, t))
        if max(img.size) > MAX_TEX:
            img = img.resize((img.width * MAX_TEX // max(img.size), img.height * MAX_TEX // max(img.size)), Image.LANCZOS)
        img.save(os.path.join(DEST, t), optimize=True)
        print(t, img.size)
    lic = os.path.join(src, "..", "..", "Downtown_City_MegaKit_License.txt")
    for cand in [lic, os.path.join(src, "..", "Downtown_City_MegaKit_License.txt"), os.path.join(src, "Downtown_City_MegaKit_License.txt")]:
        if os.path.exists(cand):
            shutil.copy(cand, os.path.join(DEST, "Downtown_City_MegaKit_License.txt"))
            break
    print("%d models, %d textures" % (len(MODELS), len(textures)))


if __name__ == "__main__":
    main(sys.argv[1])
