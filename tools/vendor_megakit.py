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
    # The Meridian (M1): the lobby's columns, corners and cornice ends, the
    # front with its steps and arch, the facade's windows.
    "Marble_Column_Large_Bottom", "Marble_Column_Large_Center", "Marble_Column_Large_Top",
    "Marble_Corner_Plain", "Cornice_Marble_L", "Cornice_Marble_R",
    "Cornice_Marble_90Angle_L", "Cornice_Marble_90Angle_R",
    "Prop_Ornament_2", "Prop_Ornament_3", "Floor_Inset",
    "Entrance_Marble_2x2", "Entrance_Marble_2x1", "Stairs_Entrance_Marble", "Stairs_Rails_Marble",
    "Prop_EntranceArch", "Marble_ShopWindow", "Marble_Window_Single",
    # Back of house: painted block, brick and concrete, metal doors.
    "Concrete_Plain_4", "Concrete_Plain_1", "WhiteBrick_Plain_4", "WhiteBrick_Plain_1",
    "Brick_Plain_4", "Brick_Plain_1", "WornBrick_Plain_4", "WornBrick_Bottom",
    "DoorFrame_Metal_Single", "DoorFrame_MetalBrick", "Door_3", "Door_4",
    "Prop_ACUnit", "Prop_Drain",
    # The street and the buildings across it.
    "Street_2Lane", "Street_4Lane", "Street_Asphalt_6x6", "Sidewalk_Straight_3m", "Sidewalk_Straight_2m",
    "Sidewalk_NoCurb_3m", "Sidewalk_Planter", "Prop_Bollard", "Prop_ManholeCover",
    "Brick_BottomTrim", "Brick_TopTrim", "Brick_Window_Trim", "Brick_Inset_Window",
    "Brick_RedWhite_DoubleWindow", "Cornice_Brick_Center", "Brick_HalfColumn_Bottom",
    "Brick_HalfColumn_Center", "WhiteBrick_Window", "Cornice_WhiteBrick_Center",
    "Trim_FirstFloor_Window", "Trim_FirstFloor_Wall", "Metal_FirstFloor_Window",
    "Metal_FirstFloor_Wall", "DoorFrame_Trim", "Prop_Awning_Long", "Prop_Awning_Pub_Long",
    "Prop_Sign_Hannigan",
]
## Textures no model names but the game uses: the rooms seen through other
## buildings' windows at night.
TEXTURES = ["T_lit_interior_1.png", "T_lit_interior_2.png", "T_dark_interior.png"]


def main(src: str) -> None:
    os.makedirs(DEST, exist_ok=True)
    textures = set(TEXTURES)
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
