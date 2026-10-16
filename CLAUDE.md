# Silver Tongue

A co-op con game where the characters hear what the players say out loud, in Godot 4.7 with GDScript on top of the COGITO immersive sim template, built from Quaternius' Downtown City MegaKit and Universal Base Characters. The concept is idea 23 in [game-ideas](https://github.com/LinuxGroove/game-ideas/blob/main/ideas/23-silver-tongue.md). It shares the LinuxGroove add-on with the other games; **read game-ideas' [online-addon.md](https://github.com/LinuxGroove/game-ideas/blob/main/online-addon.md) before touching online features or the shared add-on.** This is M2, the campaign: thirteen jobs at four venues and Mae's house party, picked from Mae's back room, then the Circuit's remixed nights, for a crew of one or two on LAN (see `docs/m2.md`, which is also the contract for building a venue). M1's gala is the first job (`docs/m1.md`), and M0's service door stays on the title for measuring (`docs/m0.md`).

## Commands

```sh
godot --headless --path . --import && godot --headless --path . --import   # twice: Cogito's fonts fail the first time
godot --headless --path . tools/check_scripts.tscn                  # every script compiles
godot --headless --path . tests/run_tests.tscn                      # unit tests, the menus, the door, every venue and job against a fake Lemonade
godot --headless --path . tests/run_tests.tscn -- --only=_test_rules   # one test
godot --headless --path . tests/run_tests.tscn -- --only=marlin     # one set of tests/*_tests.gd (several with commas, or --only=test_job_check, one of its tests)
godot --headless --path . tests/run_tests.tscn -- --core           # everything but the venues' own sets (CI runs each venue's side by side)
godot --path . -- --job=marlin_safe [--cover=steward] [--female]    # straight into any job alone (ids in Jobs.CAMPAIGN; --gala is the first)
godot --path . -- --circuit=482913                                  # straight into a Circuit night
godot --path . -- --door                                            # straight to the service door
godot --path . -- --door --text                                     # typing your lines instead of talking (or --gala --text)
XDG_DATA_HOME=/tmp/a godot --headless --path . tools/net_check.tscn -- host /tmp/code &   # two copies play the gala on LAN (-- host /tmp/code marlin_safe [482913] for another job, or a Circuit night)
XDG_DATA_HOME=/tmp/b godot --headless --path . tools/net_check.tscn -- join /tmp/code
godot --path . -- --door --set=ai/mode=external --set=ai/external_url=http://localhost:8000/api/v1   # a Lemonade you run yourself
godot --path . tools/m0_bench.tscn -- --model=LFM2.5-1.2B-Instruct-GGUF --runs=2 --out=/tmp/m0.json   # M0's numbers against a real Lemonade
python3 tools/fake_lemonade.py --port 13399                         # the stand-in Lemonade the tests use
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --resolution 1280x800 tools/screenshot.tscn -- --all=docs/screenshots [group=hotel|marlin|tideline|vantage|mae|gala|jobs] [--only=a,b]   # every venue's views, the gala in play, and each job's start
python3 tools/make_textures.py                                      # the hotel's carpets, floors, silk and paintings (numpy, Pillow)
python tools/blender/props.py [prop ...]                            # the hotel's props into assets/models/hotel/ (the wardrobe's bpy venv; each venue's <venue>_props.py builds on it)
python3 tools/make_icon.py && godot --headless --path . -s tools/svg_to_png.gd -- icon.svg icon.png 512   # the icon
python3 tools/vendor_megakit.py                                     # the MegaKit pieces from LinuxGroove/quaternius-assets (the Meridian's, plus each venue's list in tools/megakit/)
python tools/blender/wardrobe.py assets/people assets/people/outfits halberd_suit evening_dress female   # the outfits, for one body (Python 3.13 venv with bpy, scipy, scikit-image)
```

Run the script check and the tests before every commit. The tests start `tools/fake_lemonade.py` themselves (python3, standard library only) on a free port, so they need no model and no network. A new `class_name` needs an `--import` before the script check finds it. Headless runs reimport assets and rewrite `*.import` files and `icon.png.import`; revert those (`git checkout -- '*.import'`, `rm icon.png.import`) unless you meant to change them.

## Layout

| Path | What |
|---|---|
| `game/game_config.gd` | `GAME_ID`, `PROTOCOL`, `MAX_CREW`, `MAE_VOICE`, setting defaults (play, voice, comfort), the play test survey, input map (Cogito's action names plus talk, whisper, shout, earpiece, text, phone) |
| `game/brain/` | `CharacterSheet` (who someone is, their voice, actions, secrets and scripted replies), `CharacterPrompt` (a cast member's system prompt and lines), `JobRules` (what a cast member's reply may do), `Heat` (Calm to Lockdown), `ScriptedBrain` (replies with no model), `ReplySchema` (the reply's JSON schema and the probe), `Earshot` (distance, voice and walls to clarity), `BrainQueue` (one request at a time, with a timeout and the token counts), M0's `Guard`, `GuardPrompt` and `GuardRules`, `ModelSetup` (starts the AI server and downloads and warms the three models before play, with progress per model), `Language` (Mind your language) |
| `game/job/` | Any job: `JobDef` (a job's data and hooks), `Jobs` (the campaign in order, and the job being played), `Job` (the host's night: who hears what, checks over the radio and phone, doors, keypads, items, heat, the office, Mae's calls, the clock, the report), `JobScene` (one device's view of it: the player, the HUD, talking, the phone, using things), `JobNet` (the job's RPCs), `CrewInfo` and `Covers` (the crew and their covers), `CrewAvatar` (a crewmate on another device), `Circuit` (remixed nights and the weekly contract) |
| `game/venues/<venue>/` | One folder per venue (`meridian`, `marlin`, `tideline`, `vantage`, `mae`): the building in code (extends `Venue`), its people (`<Venue>Cast`) and its three jobs (`<job>_job.gd`, extending `JobDef`) |
| `game/world/` | `Venue` (a building in code: rooms, lights per room, spots, the walking graph, doors, uses, extras, views and clocks), `Kit` (MegaKit pieces by name, layers), `HotelDoor` (single and double doors that swing away from whoever opens them; `auto` for automatic ones), M0's `ServiceDoorRoom` and `GuardDoor` |
| `game/people/` | `Person` (Universal Base Characters, clips; a job's real clothes from `WARDROBE`, or job colors painted by `person.gdshader`), `Character` (a cast member: hears, thinks, speaks, walks, per crew member suspicion and beliefs), `wardrobe.gdshader` (cloth and the textured skin), `Face` (the mouth) |
| `game/player/` | `CrewMember` (extends `CogitoPlayer`: the talk controls, the pause menu, comfort, the over-the-shoulder view) |
| `game/proof/` | `ProofScene`: the door, from the services starting to the result card and the `user://m0/` record |
| `game/ui/` | Title (Mae's back room, the Circuit, a job's briefing and covers, the LAN crew) and About, the setup screen (`SetupScreen`: a progress bar per model before play), how to play, settings, the job's `JobHud`, `KeypadPanel`, `PhonePanel` and `JobReportCard` (saved as a picture or copied as text), M0's HUD and result card, the typed line with suggested lines, the pause menu, `HotelTheme`, the menu backdrop |
| `game/progress.gd` | `Progress` autoload: the season (jobs done and how, the take, Halberd's file and new faces), what each venue's people remember of the crew, and the Circuit's bests (user://progress.cfg) |
| `game/main.gd` | Startup: defaults, the launch ping, play tests, `--gala`, `--job=`, `--circuit=`, `--door` and `--text` (`--set=` is the shared add-on's) |
| `game/net/session.gd` | `Session` autoload: the crew's lobby and transport, alone or on LAN (host, browse, join by code), and starting everyone together |
| `game/net/voice_relay.gd` | `VoiceRelay`: crew voices as 8-bit mu-law at 16 kHz, and playing them |
| `game/net/online_server.gd` | Default game server; `SERVER_KEY` stays `defaultkey` in git |
| `addons/linuxgroove/voice/` | `LGVoice` autoload (hearing over Lemonade's realtime socket or one request a turn, speaking through Kokoro sentence by sentence, `LGVoiceLine`, downloading its models with progress): new in this game, to port to the shared add-on |
| `addons/linuxgroove/llm/` | `LGBrain` and `LlmClient`, with `chat_full` (usage, timings), `json_schema` response formats, and `pull_async` with `download_progress` (Lemonade's `/pull` and `/downloads`) added here |
| `addons/cogito/` | Vendored COGITO 1.1.5 with local changes (see its `VENDORED.md`) |
| `addons/quaternius/downtowncity/` | The MegaKit pieces the game uses (CC0), from LinuxGroove/quaternius-assets by `tools/vendor_megakit.py` |
| `addons/com.heroiclabs.nakama/` | Vendored Nakama client with a local patch (see its `VENDORED.md`) |
| `assets/models/<venue>/`, `assets/textures/<venue>/` | Each venue's props (from `tools/blender/props.py` and the venue's `<venue>_props.py`; each stands on y = 0 facing +z) and textures (the hotel's from `tools/make_textures.py`) |
| `assets/people/` | The base characters, their hair, skin and eye textures (`textures/`), the outfits fitted to them (`outfits/`, made by `tools/blender/wardrobe.py`) and the animation libraries |
| `tests/run_tests.gd` | Headless test runner; add checks with `check(ok, "what")`. It also runs every `tests/*_tests.gd`: each `test_*(t)` method gets the runner as `t` |
| `tests/gala_tests.gd` | The gala's rules, heat, prompts, covers and the whole job in `StubHotel` (`tests/stub_hotel.gd`, the Meridian's rooms, spots and doors with no models), and the scene against the fake |
| `tests/<venue>_tests.gd`, `tests/hotel_tests.gd` | Each venue built (`VenueChecks`: structure, standing room, walking, doors) and each of its jobs played every way through, alone and with two, by `JobHarness` (a job with no scene, no player and no model) |
| `tests/campaign_tests.gd` | The season (`Progress`), Mae's board, the report card's picture and text, minding your language, the phone, suggested lines, the over-the-shoulder view and the Circuit |
| `tools/` | Script checker, `fake_lemonade.py`, `m0_bench`, `net_check` (two copies play a job), `screenshot` (every venue's views, the gala in play, each job's start), `probe_models.gd` (model sizes and bones), `blender/wardrobe.py` (the outfits), `blender/props.py` and `make_textures.py` (the hotel's props and textures), the icon, `version.sh`, `release.sh` |
| `docs/m0.md`, `docs/m1.md`, `docs/m2.md` | What each milestone is; M0's measurements to take on real hardware, M1's job, cast, rules and hotel, and M2's campaign and the contract for a venue and its jobs |
| `docs/screenshots/<group>/` | Every view of each venue (`hotel/`, `marlin/`, `tideline/`, `vantage/`, `mae/`), the gala in play and the title's pages (`gala/`), and each job's start (`jobs/`), with a README each, made by `tools/screenshot.tscn -- --all=docs/screenshots` |

## How the game is built

- **Hearing, brains and speaking all go through Lemonade** on the player's machine, started by `LGBrain` (embedded in the snap, or an external one from the settings) and never a cloud. `LGVoice` streams the microphone to the realtime transcription socket while the talk button is held, shows partials, and commits the turn on release; replies go to Kokoro one sentence at a time so the first sound comes quickly, and the sound's envelope drives the mouth. No model at all still plays: everyone falls back to scripted lines (`ScriptedBrain`).
- **Models download before the door, not during it.** Play and `--door` go through `SetupScreen.play_door()`: when anything is missing, `ModelSetup` starts the server, pulls and warms the brain, the hearing model and Kokoro in turn, and the screen shows a bar for each; when everything is ready it goes straight to the door. The run lives on the tree root, so going in early or backing out leaves the downloads going.
- **The model only talks.** A turn is one chat request with the stable system prompt first (so the server's cache reuses it) and the history after, forced into `ReplySchema` by a `json_schema` response format. `GuardRules` applies the rules before anything happens: suspicion moves at most two steps a turn, `let_through` needs trust and at least two turns, `radio_security` needs suspicion 4, and 5 ends it. Facts behind a trust lock (the kitchen code) are never in the prompt.
- **Jobs are data plus hooks.** A job's `JobDef` sets its venue, cast, covers, clock, routine, doors, items, phone numbers and Mae's calls in `_init()`, and its hooks do what data can't; `Job` runs any of them. docs/m2.md is the contract, and the Meridian's gala is the worked example. Character ids are people across the whole campaign (`memory_from` brings what another venue's people remember), and every job has at least three ways through, each tested alone and with two.
- **The season.** `Progress` opens each job when the one before it comes off, keeps the take, and burns a face held at any job into Halberd's file until a new one is bought. The Circuit (`Circuit`) remixes a job from a night's number (rules, people's rounds, the take); the host sends the number with the job, and each week's contract is the week's number.
- **A job is host-authoritative.** On LAN, peer 1 runs `Job`: the cast's brains, earshot, checks, doors, heat and the clock; a guest runs puppets of the cast from the host's snapshots. Requests are `_c_*` and state `_h_*` in `JobNet`, always with `rpc_id`; a guest says its scene is up through `Session` and the host holds the clock until every guest is. Each device hears its own player and sends the words, and decides itself which characters' lines it's near enough to show and speak. Bump `PROTOCOL` whenever an RPC's arguments or meaning change.
- **The cast compare notes.** A check (`ask_reception`, `call_manager`, a guard's radio) is a radio question to a colleague, who answers from game facts (`Job.lookup`) and what crew told them; the asker then decides with the answer as an event. `JobRules` decides what a reply may do, per crew member: opening needs trust, two lines (or a check that came back good) and a belief; alarms need suspicion 4; Lockdown keeps the doors shut. Heat (`Heat`) is everyone's suspicion plus loud events.
- **Earshot is the game's.** `Earshot` decides what reached the guard from where and in what voice, and tells the model how well it heard. Typed lines go through the same path.
- **Every turn is measured.** `Guard.turns` keeps what was said and heard, the hearing timings, the round trip, the prompt and cached token counts, whether the reply was strict, whether it timed out, and the time to the first sound; the HUD shows the last one and `ProofScene` writes them all to `user://m0/`. Keep that record complete: M0 is the measurements.
- **People wear real clothes** where a job has them: `tools/blender/wardrobe.py` fits an outfit over a base body (a distance field of the body, closed so cloth bridges hollows, with collars and the shirt's front following lines round the neck) and writes one glTF with the body's own skeleton, the skin the clothes cover cut away, and each piece as its own skinned mesh (Suit, Skirt, Shirt, Tie, Trousers, Shoes, Dress, Necklace, ...). `Person` loads it for the job's `wardrobe` and colors each piece by name from `WARDROBE`; the skin is the body's texture tinted to the person's skin. The Halberd suit has a men's and a women's cut (`halberd_suit_male`, `halberd_suit_female`), and women guests wear `evening_dress`; a job can name one outfit, or one per body (`{"male": ..., "female": ...}`), and jobs with none get the painted uniform. After changing the script, rebuild the glTF and check the collar with the head turned (Idle, Idle_FoldArms), where it's easiest to break.
- **Levels are code**, as in Tiptoe: rooms place MegaKit pieces on a grid with collision from their bounds (`Kit`), and doors are `StaticBody3D`s on the Doors layer. A venue also names the cast's spots, the walking graph (`points` and `links`, through doorways and up stairs and lifts), zones and the extras; `StubHotel` mirrors the Meridian's names for tests, so keep them in step.
- **Layers**: 1 world, 2 interactables, 4 people, 8 player, 16 doors. `Kit.LAYER_SOLID` is what blocks the way.
- **Each room lights only itself.** A venue's rooms render on their own layers (2 to 20), each light culls to its room and layer 1, and people take the layers of where they stand (`Venue.light_layers_at`, `Person.set_light_layers`). A spot faces its +z, as people do; the player looks down -z and stands with its origin `CrewMember.FEET` above the floor (`JobScene._player_at`).
- **Cogito** provides the player controller, interaction raycast and footsteps; `CrewMember` frees what it doesn't use. Head bob and view roll default off, physics interpolation on; the over-the-shoulder view follows calmly and never shakes. Never add camera shake.
- **Play tests.** The shared add-on's `LGPlaytest` records a play test when the Play test recording setting is on (or with `-- --playtest`): a picture every few seconds, game events, frame times and controls, the player's notes (F8, or Note this moment in the pause menu) and a survey when they quit, all in one zip in `user://playtest/`. Game events go through `LGPlaytest.event()` and `moment()`; the game's own survey questions are `GameConfig.PLAYTEST`. Quit through `LGScenes.quit()` so the survey comes first.
- **Everything works offline.** No server or network is needed (LAN co-op needs only the local network); the models download once.
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
