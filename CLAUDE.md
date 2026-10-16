# Silver Tongue

A co-op con game where the characters hear what the players say out loud, in Godot 4.7 with GDScript on top of the COGITO immersive sim template, built from Quaternius' Downtown City MegaKit and Universal Base Characters. The concept is idea 23 in [game-ideas](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/23-silver-tongue.md). It shares the LinuxGroove add-on with the other games; **read game-ideas' [online-addon.md](https://github.com/LinuxGroove/game-ideas/blob/main/online-addon.md) before touching online features or the shared add-on.** This is M0, the service door: one room, one guard, one door (see `docs/m0.md`).

## Commands

```sh
godot --headless --path . --import && godot --headless --path . --import   # twice: Cogito's fonts fail the first time
godot --headless --path . tools/check_scripts.tscn                  # every script compiles
godot --headless --path . tests/run_tests.tscn                      # unit tests, the menus, and the whole door against a fake Lemonade
godot --headless --path . tests/run_tests.tscn -- --only=_test_rules   # one test
godot --path . -- --door                                            # straight to the service door
godot --path . -- --door --text                                     # typing your lines instead of talking
godot --path . -- --door --set=ai/mode=external --set=ai/external_url=http://localhost:8000/api/v1   # a Lemonade you run yourself
godot --path . tools/m0_bench.tscn -- --model=LFM2.5-1.2B-Instruct-GGUF --runs=2 --out=/tmp/m0.json   # M0's numbers against a real Lemonade
python3 tools/fake_lemonade.py --port 13399                         # the stand-in Lemonade the tests use
python3 tools/make_icon.py && godot --headless --path . -s tools/svg_to_png.gd -- icon.svg icon.png 512   # the icon
python3 tools/vendor_megakit.py                                     # the MegaKit pieces from LinuxGroove/quaternius-assets
```

Run the script check and the tests before every commit. The tests start `tools/fake_lemonade.py` themselves (python3, standard library only) on a free port, so they need no model and no network. A new `class_name` needs an `--import` before the script check finds it. Headless runs reimport assets and rewrite `*.import` files and `icon.png.import`; revert those (`git checkout -- '*.import'`, `rm icon.png.import`) unless you meant to change them.

## Layout

| Path | What |
|---|---|
| `game/game_config.gd` | `GAME_ID`, setting defaults (play, voice), the play test survey, input map (Cogito's action names plus talk, whisper, shout, text) |
| `game/brain/` | `CharacterSheet` (Marcus: who he is, his voice, his actions, his scripted lines), `GuardPrompt` (the system prompt and the history's lines), `ReplySchema` (the reply's JSON schema and the probe), `GuardRules` (what a reply may do), `Earshot` (distance and voice to clarity), `BrainQueue` (one request at a time, with a timeout and the token counts), `Guard` (hears, thinks, speaks, acts), `ModelSetup` (starts the AI server and downloads and warms the three models before the door, with progress per model) |
| `game/world/` | `Kit` (MegaKit pieces by name, layers), `ServiceDoorRoom` (the corridor, in code), `GuardDoor` |
| `game/people/` | `Person` (Universal Base Characters in job colours, clips), `Face` (the mouth), `person.gdshader` |
| `game/player/` | `CrewMember` (extends `CogitoPlayer`: the talk controls, the pause menu, comfort) |
| `game/proof/` | `ProofScene`: the door, from the services starting to the result card and the `user://m0/` record |
| `game/ui/` | Title and About, the setup screen (`SetupScreen`: a progress bar per model before the door), how to play, settings, the HUD and its readout, the typed line, the result card, the pause menu, `HotelTheme`, the menu backdrop |
| `game/main.gd` | Startup: defaults, the launch ping, play tests, `--door` and `--text` (`--set=` is the shared add-on's) |
| `game/net/online_server.gd` | Default game server; `SERVER_KEY` stays `defaultkey` in git |
| `addons/linuxgroove/voice/` | `LGVoice` autoload (hearing over Lemonade's realtime socket or one request a turn, speaking through Kokoro sentence by sentence, `LGVoiceLine`, downloading its models with progress): new in this game, to port to the shared add-on |
| `addons/linuxgroove/llm/` | `LGBrain` and `LlmClient`, with `chat_full` (usage, timings), `json_schema` response formats, and `pull_async` with `download_progress` (Lemonade's `/pull` and `/downloads`) added here |
| `addons/cogito/` | Vendored COGITO 1.1.5 with local changes (see its `VENDORED.md`) |
| `addons/quaternius/downtowncity/` | The MegaKit pieces the game uses (CC0), from LinuxGroove/quaternius-assets by `tools/vendor_megakit.py` |
| `addons/com.heroiclabs.nakama/` | Vendored Nakama client with a local patch (see its `VENDORED.md`) |
| `assets/people/` | The base characters, their hair and the animation libraries |
| `tests/run_tests.gd` | Headless test runner; add checks with `check(ok, "what")` |
| `tools/` | Script checker, `fake_lemonade.py`, `m0_bench`, `probe_models.gd` (model sizes and bones), the icon, `version.sh`, `release.sh` |
| `docs/m0.md` | What M0 is, what to measure on real hardware, and the tables to fill in |

## How the game is built

- **Hearing, brains and speaking all go through Lemonade** on the player's machine, started by `LGBrain` (embedded in the snap, or an external one from the settings) and never a cloud. `LGVoice` streams the microphone to the realtime transcription socket while the talk button is held, shows partials, and commits the turn on release; replies go to Kokoro one sentence at a time so the first sound comes quickly, and the sound's envelope drives the mouth. No model at all still plays: the guard falls back to scripted lines.
- **Models download before the door, not during it.** Play and `--door` go through `SetupScreen.play_door()`: when anything is missing, `ModelSetup` starts the server, pulls and warms the brain, the hearing model and Kokoro in turn, and the screen shows a bar for each; when everything is ready it goes straight to the door. The run lives on the tree root, so going in early or backing out leaves the downloads going.
- **The model only talks.** A turn is one chat request with the stable system prompt first (so the server's cache reuses it) and the history after, forced into `ReplySchema` by a `json_schema` response format. `GuardRules` applies the rules before anything happens: suspicion moves at most two steps a turn, `let_through` needs trust and at least two turns, `radio_security` needs suspicion 4, and 5 ends it. Facts behind a trust lock (the kitchen code) are never in the prompt.
- **Earshot is the game's.** `Earshot` decides what reached the guard from where and in what voice, and tells the model how well it heard. Typed lines go through the same path.
- **Every turn is measured.** `Guard.turns` keeps what was said and heard, the hearing timings, the round trip, the prompt and cached token counts, whether the reply was strict, whether it timed out, and the time to the first sound; the HUD shows the last one and `ProofScene` writes them all to `user://m0/`. Keep that record complete: M0 is the measurements.
- **Levels are code**, as in Tiptoe: the room places MegaKit pieces on a grid with collision from their bounds (`Kit`), and the door is a `StaticBody3D` on the Doors layer.
- **Layers**: 1 world, 2 interactables, 4 people, 8 player, 16 doors. `Kit.LAYER_SOLID` is what blocks the way.
- **Cogito** provides the player controller, interaction raycast and footsteps; `CrewMember` frees what it doesn't use. Head bob and view roll default off, physics interpolation on; never add camera shake.
- **Play tests.** The shared add-on's `LGPlaytest` records a play test when the Play test recording setting is on (or with `-- --playtest`): a picture every few seconds, game events, frame times and controls, the player's notes (F8, or Note this moment in the pause menu) and a survey when they quit, all in one zip in `user://playtest/`. Game events go through `LGPlaytest.event()` and `moment()`; the door's own survey questions are `GameConfig.PLAYTEST`. Quit through `LGScenes.quit()` so the survey comes first.
- **Everything works offline.** No server or network is needed; the models download once.
- **Launch ping.** `game/main.gd` calls `LGLaunchPing.send(GameConfig.GAME_ID)` at startup: one anonymous request to the game server's `/launch` (game, random install id, version, OS, CPU) so the server counts every player. It's skipped headless, from source and with `DO_NOT_TRACK` set, and never blocks or retries. The game is not registered on game-server yet; it needs to be before the first release.

## The shared add-on

`addons/linuxgroove/` and `addons/com.heroiclabs.nakama/` are copies shared with [Foam Frenzy](https://github.com/LinuxGroove/foam-frenzy), [Graveyard Hollow](https://github.com/LinuxGroove/LampLighters), [Tiptoe](https://github.com/LinuxGroove/tiptoe), [Joyride Junction](https://github.com/LinuxGroove/joyride-junction), [Block Party: Skyway](https://github.com/LinuxGroove/block-party-skyway), [Race Day](https://github.com/LinuxGroove/race-day), [Verdigris Protocol](https://github.com/LinuxGroove/hull-bloom) and [Burn Rate](https://github.com/LinuxGroove/burn-rate). Fix shared behaviour in the add-on, not with a workaround here, keep it game-agnostic, and port the change to the other games in the same piece of work. When the change affects how games should use the add-on, update online-addon.md in game-ideas too. Keep the `_disconnect_peer` and `_close` patch in `NakamaMultiplayerPeer.gd` when updating nakama-godot. This game's `llm/` changes and its new `voice/` service are ahead of the other copies until they are ported.

## Style

- Match the surrounding code: `##` doc comments on classes and non-obvious functions, short comments only where the reason isn't obvious.
- Connect signals with methods (or `bind`), not lambdas.
- Build pieces so tests can drive them without a scene change or a model: `Guard`, `GuardRules`, `Earshot` and `GuardPrompt` need no scene, the room builds without a player, and the whole door runs against `tools/fake_lemonade.py`.
- Controller first: everything works with a pad, and the mouse and keyboard always work too.
- Player-facing text is plain and short, in the game's words (the crew, the job, the door, Marcus, reception, Halberd).

## Releases

Pushing to `main` builds the snap and publishes it to the `edge` channel; a GitHub release publishes to `candidate`. The **Windows and macOS** workflow (`desktop.yml`) exports both from Linux. CI injects the server key from the `GAME_SERVER_KEY` secret, so never commit the real key; `SERVER_KEY` stays `defaultkey` in git.

Versions are `vYYYY.WW.MINOR`, derived from git by `tools/version.sh`; make releases with the **Release** workflow. Commit subjects become the release notes, so write them for players.
