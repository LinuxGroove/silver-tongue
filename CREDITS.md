# Credits

Made by Drew, Kaden and Ken VanDine, the LinuxGroove team.

## Art

- The Hotel Meridian's corridors are built from
  [Quaternius](https://quaternius.com)' Downtown City MegaKit, CC0 (public
  domain), in `addons/quaternius/downtowncity/` with its licence file
  (vendored from LinuxGroove/quaternius-assets by `tools/vendor_megakit.py`).
- Marcus and the rest of the cast are Quaternius' Universal Base Characters
  with their hair, animated with the Universal Animation Library 1 and 2
  (CC0), in `assets/people/` with their licence files. Their clothes are
  drawn by `game/people/person.gdshader`.
- The icon is drawn by `tools/make_icon.py`.

## Fonts

- Montserrat by Julieta Ulanovsky and others, SIL Open Font License 1.1,
  from Cogito's `addons/cogito/Assets/Fonts/`.

## Audio

- The menu sounds in `addons/linuxgroove/ui/sounds/` are by
  [Kenney](https://kenney.nl), CC0.
- Footsteps are Cogito's (CC0).
- Marcus's voice is made as he speaks, by Kokoro through Lemonade Server
  (below). Nothing he says is recorded in this repository.

## Code

- [Godot Engine](https://godotengine.org), MIT.
- [COGITO](https://codeberg.org/Phazorknight/Cogito) by Phazorknight and
  contributors, MIT, vendored in `addons/cogito` (see `VENDORED.md` there),
  with Nathan Hoad's [InputHelper](https://github.com/nathanhoad/godot_input_helper)
  (MIT) and Bryce Dixon's [QuickAudio](https://github.com/BtheDestroyer/Godot_QuickAudio)
  (MIT). Cogito's assets are by Kenney, Quaternius (CC0) and Philip Drobar
  (MIT); the freesound.org sounds kept are CC0.
- [Nakama Godot client](https://github.com/heroiclabs/nakama-godot),
  Apache-2.0, vendored in `addons/com.heroiclabs.nakama` (see `VENDORED.md`).
- The shared LinuxGroove add-on in `addons/linuxgroove`, MIT.
- [Lemonade Server](https://lemonade-server.ai) by AMD and contributors,
  Apache-2.0: the snap bundles its embeddable release, and the game starts
  it privately on localhost. It serves the guard's hearing
  ([whisper.cpp](https://github.com/ggml-org/whisper.cpp), MIT, with
  OpenAI's Whisper models, MIT), his brains
  ([llama.cpp](https://github.com/ggml-org/llama.cpp), MIT) and his voice
  ([Kokoro](https://github.com/hexgrad/kokoro), Apache-2.0).
- The language models download on first use and are never committed:
  Qwen3-4B-Instruct-2507 (Apache-2.0) by default, and LFM2.5-1.2B (the
  LFM Open License, which allows commercial use under $10M a year) for
  handhelds.
