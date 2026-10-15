extends Node
## Headless tests: run with
##   godot --headless --path . tests/run_tests.tscn
## Add `-- --only=_test_rules` for one test. The whole door is played
## through twice against `tools/fake_lemonade.py` (started here, so python3
## must be on the path). Exits non-zero on failure.

const FAKE := "res://tools/fake_lemonade.py"
const ACTIONS: Array[String] = ["none", "ask_for_badge", "ask_reception", "let_through", "radio_security"]

var failures := 0
var checks := 0
var _fake_pid := -1
var _fake_url := ""
var _heard: Array = []


func _ready() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	HotelTheme.apply(get_tree().root, 22)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	await get_tree().process_frame
	if only != "":
		printerr("- " + only)
		await call(only)
	else:
		for t in ["_test_schema", "_test_rules", "_test_earshot", "_test_prompt", "_test_voice_helpers",
				"_test_launch_ping", "_test_person", "_test_room", "_test_menus", "_test_pause",
				"_test_text_entry_pad_enter", "_test_playtest", "_test_scripted_door",
				"_test_fake_door", "_test_fake_hearing", "_test_fake_caught_and_timeout"]:
			printerr("- " + t)
			await call(t)
	_stop_fake()
	print("\n%d checks, %d failed" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", what)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Waits until `cond` is true, up to `seconds`; returns whether it was.
func until(cond: Callable, seconds := 10.0) -> bool:
	var t := 0.0
	while t < seconds:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()


#region The brain's pieces

func _test_schema() -> void:
	var s := ReplySchema.schema(ACTIONS)
	check(s.required.size() == 6 and s.properties.do.enum == ACTIONS, "the schema has every field and the allowed actions")
	check(s.additionalProperties == false and s.properties.suspicion.maximum == 5, "the schema is closed and suspicion tops out at 5")
	var good := '{"think":"hm","say":"Evening.","tone":"calm","do":"none","believes":["new"],"suspicion":1}'
	check(ReplySchema.is_strict(good, ACTIONS), "a reply with every field, in range, is strict")
	check(not ReplySchema.is_strict('{"say":"Evening."}', ACTIONS), "a reply missing fields isn't strict")
	check(not ReplySchema.is_strict(good.replace('"none"', '"escort_out"'), ACTIONS), "an action off the list isn't strict")
	var p := ReplySchema.parse("Sure! ```json\n" + good.replace('"calm"', '"GRUMPY"').replace('"suspicion":1', '"suspicion":9') + "\n```", ACTIONS)
	check(p.say == "Evening." and p.tone == "calm" and p.suspicion == 5, "a loose reply is found in the chatter and brought into range")
	check(ReplySchema.parse("no json here", ACTIONS).is_empty(), "no JSON means no reply")
	var long := ReplySchema.parse('{"say":"%s","believes":"one thing","do":"let_through"}' % "a".repeat(400), ACTIONS)
	check(long.say.length() == ReplySchema.SAY_MAX and long.believes == ["one thing"] and long.do == "let_through", "long lines are cut and a lone belief becomes a list")
	var probe := ReplySchema.probe_schema()
	check(probe.properties.word.enum == ["pineapple"], "the probe schema allows one word")


func _test_rules() -> void:
	var sheet := CharacterSheet.marcus()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var st := GuardRules.new_state(sheet)
	check(st.suspicion == 1 and st.turns == 0, "Marcus starts at his usual suspicion")
	var r := GuardRules.resolve({"say": "Go on through.", "tone": "friendly", "do": "let_through", "believes": ["facilities"], "suspicion": 0}, st, sheet, rng)
	check(r.do == "none" and r.vetoed == "let_through" and r.say in sheet.hesitations, "nobody is let through on the first line; he hesitates instead")
	r = GuardRules.resolve({"say": "x", "tone": "calm", "do": "none", "believes": [], "suspicion": 5}, st, sheet, rng)
	check(r.suspicion == 3, "suspicion climbs at most two steps at a time")
	st.suspicion = 3
	r = GuardRules.resolve({"say": "x", "tone": "calm", "do": "none", "believes": [], "suspicion": 0}, st, sheet, rng)
	check(r.suspicion == 2, "suspicion falls one step at a time")
	r = GuardRules.resolve({"say": "That's it.", "tone": "annoyed", "do": "radio_security", "believes": [], "suspicion": 3}, st, sheet, rng)
	check(r.do == "none" and r.vetoed == "radio_security" and r.ended == "", "backup needs suspicion 4")
	st.suspicion = 4
	r = GuardRules.resolve({"say": "That's it.", "tone": "annoyed", "do": "radio_security", "believes": [], "suspicion": 4}, st, sheet, rng)
	check(r.do == "radio_security" and r.ended == "caught", "at 4 he can call it in")
	st.suspicion = 3
	r = GuardRules.resolve({"say": "x", "tone": "alarmed", "do": "none", "believes": [], "suspicion": 5}, st, sheet, rng)
	check(r.do == "radio_security" and r.ended == "caught", "suspicion 5 calls it in whatever he meant to do")
	st = GuardRules.new_state(sheet)
	st.turns = 2
	st.suspicion = 1
	r = GuardRules.resolve({"say": "Go on.", "tone": "friendly", "do": "let_through", "believes": [], "suspicion": 1}, st, sheet, rng)
	check(r.vetoed == "let_through", "he doesn't let through someone he believes nothing about")
	r = GuardRules.resolve({"say": "Go on.", "tone": "friendly", "do": "let_through", "believes": ["Priya sent them"], "suspicion": 1}, st, sheet, rng)
	check(r.do == "let_through" and r.ended == "through" and r.say == "Go on.", "after two lines, believed and relaxed, he lets you through")
	r = GuardRules.resolve({"say": "I'll check.", "tone": "wary", "do": "ask_reception", "believes": [], "suspicion": 2}, st, sheet, rng)
	GuardRules.apply(r, st)
	check(r.do == "ask_reception" and st.reception == "asked" and st.suspicion == 2, "asking reception is allowed once and moves the state on")
	r = GuardRules.resolve({"say": "I'll check again.", "tone": "wary", "do": "ask_reception", "believes": [], "suspicion": 2}, st, sheet, rng)
	check(r.vetoed == "ask_reception", "he doesn't ask reception twice")
	r = GuardRules.resolve({"say": "x", "tone": "calm", "do": "escort_out", "believes": [], "suspicion": 2}, st, sheet, rng)
	check(r.do == "none" and r.vetoed == "", "an action not on his list is just nothing")


func _test_earshot() -> void:
	check(Earshot.clarity(1.0) == 1.0 and Earshot.clarity(20.0) == 0.0, "a normal voice is clear up close and gone far away")
	check(Earshot.clarity(2.5, "whisper") < 1.0 and Earshot.clarity(2.5, "whisper") > 0.0, "a whisper fades after a metre or two")
	check(Earshot.clarity(12.0, "shout") == 1.0, "a shout carries the corridor")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var line := "Evening. Facilities sent me about the freezer in the kitchen."
	var h := Earshot.hear(line, 1.5, "normal", rng)
	check(h.heard == line and h.how == "clear", "up close every word arrives")
	h = Earshot.hear(line, 6.5, "normal", rng)
	check(h.heard != line and h.heard.contains("...") and h.how in ["muffled", "faint"], "from down the corridor words drop out")
	h = Earshot.hear(line, 12.0, "normal", rng)
	check(h.heard == "" and h.how == "faint", "from the far end nothing arrives")
	h = Earshot.hear(line, 5.0, "whisper", rng)
	check(h.heard == "", "a whisper from five metres is nothing")
	h = Earshot.hear(line, 6.5, "shout", rng)
	check(h.heard == line, "a shout from the same spot is clear")
	var a := Earshot.hear(line, 6.5, "normal")
	var b := Earshot.hear(line, 6.5, "normal")
	check(a.heard == b.heard, "the same line at the same distance drops the same words")


func _test_prompt() -> void:
	var sheet := CharacterSheet.marcus()
	var sys := GuardPrompt.system(sheet)
	check(sys.contains("You are Marcus") and sys.contains("Halberd"), "the system prompt is Marcus's sheet")
	check(not sys.contains("4471"), "the kitchen code never goes in the prompt")
	check(sys.contains("let_through") and sys.contains("radio_security") and not sys.contains("escort_out"), "the prompt lists his five actions and no others")
	check(sys.contains('"suspicion"') and sys.contains('"believes"'), "the prompt shows the reply's shape")
	check(GuardPrompt.system(sheet, true).contains("no swearing") and not sys.contains("no swearing"), "Mind your language adds a line")
	var history := [
		{"who": "player", "text": GuardPrompt.player_line("Evening ... freezer", 3.0, "normal", "muffled")},
		{"who": "character", "text": GuardPrompt.reply_text({"think": "hm", "say": "Sorry?", "tone": "wary", "do": "none", "believes": [], "suspicion": 1})},
		{"who": "event", "text": GuardPrompt.event_line("Dana, on the radio: nothing booked")},
	]
	var msgs := GuardPrompt.messages(sheet, history)
	check(msgs.size() == 4 and msgs[0].role == "system" and msgs[1].role == "user" and msgs[2].role == "assistant" and msgs[3].role == "user", "the history follows the system prompt in order")
	check(msgs[1].content.contains("a few steps away") and msgs[1].content.contains("some words lost"), "a player line says where from and how well it was heard")
	check(msgs[3].content.begins_with("[") and msgs[3].content.ends_with("]"), "an event is in square brackets")
	var again := GuardPrompt.messages(sheet, history)
	check(again[0].content == msgs[0].content, "the system prompt is the same every turn, for the cache")
	check(GuardPrompt.player_line("x", 1.0, "whisper", "clear").contains("whispering") and GuardPrompt.player_line("x", 1.0, "shout", "clear").contains("shouting"), "whispers and shouts are marked")


## LGVoice's helpers: sentence splitting, the loudness envelope, the WAV.
func _test_voice_helpers() -> void:
	var parts := LGVoice.split_sentences("Facilities? Nobody told me about that. Hang on, I'll check with reception. Wait there.")
	check(parts.size() >= 2 and parts[0].ends_with("about that.") and parts[parts.size() - 1].ends_with("Wait there."), "a line splits at sentence ends, short tails kept with the one before: %s" % str(parts))
	check(LGVoice.split_sentences("Hm.") == ["Hm."], "a short line is one piece")
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 16000
	var data := PackedByteArray()
	data.resize(16000 * 2)
	for i in 16000:
		var v := 0.0 if i < 8000 else sin(i * 0.1) * 0.8
		data.encode_s16(i * 2, int(v * 32767.0))
	wav.data = data
	var env := LGVoice.envelope(wav)
	check(env.size() == 50 and env[5] == 0.0 and env[40] > 0.5, "the envelope is 20 ms steps, quiet then loud")
	var bytes := LGVoice._wav(data)
	check(bytes.size() == data.size() + 44 and bytes.slice(0, 4).get_string_from_ascii() == "RIFF" and bytes.decode_u32(24) == 16000, "the utterance WAV has a 16 kHz header")
	var loaded := AudioStreamWAV.load_from_buffer(bytes)
	check(loaded != null and loaded.mix_rate == 16000 and absf(loaded.get_length() - 1.0) < 0.01, "Godot reads it back as one second at 16 kHz")


func _test_launch_ping() -> void:
	var main := load("res://game/main.gd") as GDScript
	check(main.source_code.contains("LGLaunchPing.send(GameConfig.GAME_ID)"), "main sends the launch ping")
	check(GameConfig.GAME_ID == "silver-tongue", "the game id is silver-tongue")
	check(OnlineServer.SERVER_KEY == "defaultkey", "the server key in git is the default")

#endregion

#region The room and the people

func _test_person() -> void:
	var sheet := CharacterSheet.marcus()
	var p := Person.make(sheet.person_job, sheet.female, sheet.seed, sheet.person_look())
	add_child(p)
	await frames(2)
	check(p.meshes.size() >= 3 and p.skeleton != null, "Marcus has a body")
	for clip in ["Idle_FoldArms", "Idle", "Idle_Talking", "Idle_TalkingPhone", "Interact", "Idle_No", "Yes"]:
		check(p.clip_path(clip) != "", "the libraries have " + clip)
	p.play("Idle_Talking")
	check(p.current() == "Idle_Talking" and p.anim.is_playing(), "he can be told to talk")
	var f := Face.make(p)
	await frames(1)
	check(f.is_inside_tree() and f.global_position.y > 1.4 and f.global_position.y < 1.75, "the mouth sits on the face (y %.2f)" % f.global_position.y)
	f.level = 1.0
	await frames(3)
	check(f._box.size.y > Face.REST, "the mouth opens with the voice")
	p.queue_free()


func _test_room() -> void:
	var room := ServiceDoorRoom.new()
	add_child(room)
	await frames(2)
	check(room.door != null and not room.door.is_open and room.through != null, "the corridor has a shut door and somewhere past it")
	check(room.find_children("", "MeshInstance3D", true, false).size() > 40, "the corridor is built")
	var start := room.start.origin
	check(absf(start.x) < ServiceDoorRoom.W * 0.5 and start.z > ServiceDoorRoom.Z0 and start.z < ServiceDoorRoom.Z0 + ServiceDoorRoom.L, "you start inside it")
	check(room.guard_spot.origin.z < start.z and absf(room.guard_spot.origin.z - ServiceDoorRoom.Z0) < 2.0, "Marcus stands by the door")
	await frames(2)
	var space := get_viewport().world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, ServiceDoorRoom.Z0 + 2.0), Vector3(0, 1.0, ServiceDoorRoom.Z0 - 2.0), Kit.LAYER_SOLID)
	var hit := space.intersect_ray(q)
	check(not hit.is_empty() and hit.collider == room.door.body, "the shut door blocks the way through")
	room.door.open()
	check(room.door.is_open, "the door opens")
	await get_tree().create_timer(1.6).timeout
	hit = space.intersect_ray(q)
	check(hit.is_empty(), "an open door doesn't")
	room.queue_free()


func _test_menus() -> void:
	var title: Node = load("res://game/ui/title.tscn").instantiate()
	add_child(title)
	await frames(3)
	var texts: Array = title.button_texts()
	for b in ["The service door", "How to play", "Settings", "About", "Quit"]:
		check(b in texts, "the title has " + b)
	title.show_how(0)
	await frames(1)
	check("Next" in title.button_texts(), "how to play has pages")
	title.show_settings()
	await frames(1)
	var cyclers := title.find_children("", "LGCycler", true, false)
	var labels := []
	for c in cyclers:
		labels.append(c.label_text)
	for l in ["How you talk", "Hearing model", "He speaks out loud", "Head bob", "AI players"]:
		check(l in labels, "settings have " + l)
	title.show_about()
	await frames(1)
	var about := false
	for l in title.find_children("", "Label", true, false):
		about = about or (l as Label).text.contains("Ken VanDine")
	check(about, "about credits the VanDines")
	title.queue_free()
	await frames(1)


func _test_pause() -> void:
	var pause := HotelPause.new()
	add_child(pause)
	await frames(1)
	pause.open_pause_menu()
	check(pause.visible and get_tree().paused, "the pause menu pauses")
	pause.close_pause_menu()
	check(not pause.visible and not get_tree().paused, "and carries on")
	pause.show_how(1)
	check(pause._how.visible, "how to play opens in the pause menu")
	pause.queue_free()
	await frames(1)


func _test_text_entry_pad_enter() -> void:
	var edit := LineEdit.new()
	LGUi.gamepad_text_entry(edit)
	add_child(edit)
	var submitted := []
	edit.text_submitted.connect(func(t): submitted.append(t))
	for order in [["enter", "a"], ["a", "enter"]]:
		edit.grab_focus()
		await get_tree().process_frame
		check(edit.is_editing(), "a field focused by its page is being typed in")
		for pressed in [true, false]:
			for what in order:
				_send_input(what, pressed)
				await get_tree().process_frame
			await get_tree().create_timer(0.2).timeout
		check(submitted.is_empty(), "A that comes with Enter (%s first) doesn't submit the field" % order[0])
		var boards := get_tree().root.find_children("*", "OnScreenKeyboard", true, false)
		check(boards.size() == 1, "A that comes with Enter (%s first) opens the keyboard" % order[0])
		for b in boards:
			b.get_parent().free()
	edit.grab_focus()
	await get_tree().process_frame
	for pressed in [true, false]:
		_send_input("enter", pressed)
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	check(submitted.size() == 1, "Enter on its own submits the field")
	edit.free()


func _send_input(what: String, pressed: bool) -> void:
	var ev: InputEvent
	if what == "a":
		ev = InputEventJoypadButton.new()
		ev.button_index = JOY_BUTTON_A
	else:
		ev = InputEventKey.new()
		ev.keycode = KEY_ENTER
		ev.physical_keycode = KEY_ENTER
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _test_playtest() -> void:
	var main := load("res://game/main.gd") as GDScript
	check(main.source_code.contains("LGPlaytest.setup(GameConfig.GAME_ID, GameConfig.PLAYTEST)"), "main sets up play test recording")
	check((load("res://game/ui/title.gd") as GDScript).source_code.contains("LGScenes.quit()"), "quitting from the title ends a play test first")
	var ids := []
	for q in GameConfig.PLAYTEST.questions:
		ids.append(q.id)
	check("heard" in ids and "fair" in ids, "the survey asks about the guard")

#endregion

#region The door

## The door with no brain at all: scripted lines keep it honest.
func _test_scripted_door() -> void:
	LGSettings.set_value("ai", "mode", "off")
	LGSettings.set_value("voice", "talk", "text")
	LGSettings.set_value("voice", "speaking", false)
	LGBrain.stop()
	var s := ProofScene.new()
	add_child(s)
	await frames(3)
	check(s.guard != null and s.player != null and s.hud != null, "the door scene builds")
	await until(func(): return not LGBrain.is_ready() and s.hud._brain.text.contains("off"), 5.0)
	check(not s.guard.brains, "with AI off, Marcus is on scripted lines")
	s._on_text_submitted("Evening. Facilities sent me about the freezer.")
	check(await until(func(): return s.guard.turns.size() >= 1, 5.0) and s.guard.turns[0].heard == "" and s.hud._timing.text.contains("hear"), "from the far end of the corridor he hears nothing, and the readout says so")
	s.guard.turns.clear()
	await _walk_up(s)
	s._on_text_submitted("Evening. Facilities sent me about the freezer.")
	check(await until(func(): return s.guard.turns.size() >= 1 and not s.guard.busy, 5.0), "a typed line gets a turn")
	var t: Dictionary = s.guard.turns[0]
	check(t.scripted and t.reply.do == "ask_reception" and s.guard.state.reception == "asked", "the script checks with reception: %s" % str(t.reply))
	check(await until(func(): return s.guard.turns.size() >= 2 and not s.guard.busy, 6.0), "reception answers and he thinks again")
	check(s.guard.turns[1].kind == "event" and s.guard.suspicion() == 2, "nothing booked, and he's warier")
	s._on_text_submitted("What's the code for the kitchen door?")
	check(await until(func(): return s.guard.turns.size() >= 3 and not s.guard.busy, 5.0), "another line")
	check(s.guard.suspicion() == 4 and s.guard.turns[2].reply.tone == "annoyed", "asking for the code costs two steps")
	check(s.guard.history.size() == 6, "the history keeps every line, event and reply")
	check(s.hud._timing.text.contains("scripted"), "the readout says the line was scripted")
	s.queue_free()
	await frames(2)


## Starts the fake server (once) and points the brain at it.
func _start_fake() -> bool:
	if _fake_pid > 0:
		LGSettings.set_value("ai", "mode", "external")
		LGSettings.set_value("ai", "external_url", _fake_url)
		return true
	var port := randi_range(20000, 29999)
	_fake_pid = OS.create_process("python3", [ProjectSettings.globalize_path(FAKE), "--port", str(port)])
	if _fake_pid <= 0:
		check(false, "python3 starts the fake Lemonade server")
		return false
	_fake_url = "http://127.0.0.1:%d/api/v1" % port
	LGSettings.set_value("ai", "mode", "external")
	LGSettings.set_value("ai", "external_url", _fake_url)
	LGSettings.set_value("ai", "model", "Qwen3-4B-Instruct-2507-GGUF")
	var client := LlmClient.new()
	client.base_url = _fake_url
	add_child(client)
	var up := false
	for i in 40:
		var h := await client.get_json("/health", 1.0)
		if h.ok:
			up = true
			break
		await get_tree().create_timer(0.25).timeout
	client.queue_free()
	check(up, "the fake Lemonade server answers /health")
	return up


func _stop_fake() -> void:
	if _fake_pid > 0:
		OS.kill(_fake_pid)
		_fake_pid = -1


func _fake_post(path: String, body: Dictionary) -> Dictionary:
	var client := LlmClient.new()
	client.base_url = _fake_url
	add_child(client)
	var res := await client.post_json(path, body, 5.0)
	client.queue_free()
	return res


func _fake_log() -> Dictionary:
	var client := LlmClient.new()
	client.base_url = _fake_url
	add_child(client)
	var res := await client.get_json("/fake/log", 5.0)
	client.queue_free()
	return res.data if res.ok else {}


## The whole loop against the fake: the brain comes up, the schema probe
## says enforced, the voice comes up over the socket, three typed lines
## talk Marcus round, the door opens, you walk through, the card shows.
func _test_fake_door() -> void:
	if not await _start_fake():
		return
	await _fake_post("/fake/reset", {})
	LGSettings.set_value("voice", "talk", "text")
	LGSettings.set_value("voice", "speaking", true)
	LGBrain.stop()
	var s := ProofScene.new()
	add_child(s)
	await frames(3)
	check(await until(func(): return LGBrain.is_ready(), 15.0), "the brain is ready against the fake")
	check(s.guard.brains, "Marcus has a brain")
	check(await until(func(): return s.hud._schema.text.contains("enforced"), 10.0), "the schema probe runs: %s" % s.hud._schema.text)
	check(s.hud._schema.text == "Schema: enforced", "the fake enforces the schema, and the HUD says so")
	check(await until(func(): return LGVoice.is_ready(), 20.0), "the voice is ready: %s" % LGVoice.detail)
	check(LGVoice.transport == "realtime", "hearing goes over the realtime socket (%s)" % LGVoice.transport)
	check(s.guard.speak, "Marcus speaks out loud")
	await _walk_up(s)
	s._on_text_submitted("Evening. Facilities sent me about the walk-in freezer.")
	check(await until(func(): return s.guard.turns.size() >= 1 and not s.guard.busy, 10.0), "the first line gets a turn")
	var t0: Dictionary = s.guard.turns[0]
	check(not t0.scripted and t0.strict and t0.reply.do == "ask_reception", "the model's reply follows the schema and he checks with reception: %s" % str(t0.get("reply")))
	check(t0.cached_tokens == 60 and t0.prompt_tokens == 80 and t0.thought > 0.0, "the turn keeps the tokens the cache reused and the round trip (%s/%s, %.2f s)" % [t0.cached_tokens, t0.prompt_tokens, t0.thought])
	check(await until(func(): return s.guard.turns.size() >= 2 and not s.guard.busy, 10.0), "Dana answers and he thinks again")
	check(s.guard.turns[1].kind == "event" and s.guard.suspicion() == 2, "nothing booked: suspicion 2")
	check(s.hud._subtitle.text != "" and s.hud._speaker.text != "", "subtitles show who said what")
	s._on_text_submitted("Priya booked it before she left. Ask her in the morning if you like.")
	check(await until(func(): return s.guard.turns.size() >= 3 and not s.guard.busy, 10.0), "the third line")
	var t2: Dictionary = s.guard.turns[2]
	check(t2.reply.do == "let_through" and t2.vetoed == "" and s.room.door.is_open, "believed, relaxed and on the third line, he opens the door: %s" % str(t2.get("reply")))
	check(await until(func(): return float(t2.get("spoke", -1.0)) >= 0.0 or s.guard._line == null or s.guard._line.state != "asked", 10.0) and float(t2.get("spoke", -1.0)) >= 0.0, "his line was spoken (first sound after %.2f s)" % float(t2.get("spoke", -1.0)))
	check(s.hud._timing.text.contains("thought") and s.hud._timing.text.contains("cached") and s.hud._timing.text.contains("spoke"), "the readout has thought, cache and spoke: %s" % s.hud._timing.text)
	s.player.global_position = Vector3(0, 0.5, ServiceDoorRoom.Z0 - 1.2)
	check(await until(func(): return s.over, 5.0) and s.outcome == "through", "walking through ends it")
	check(s.result.visible and s.summarize().turns == 2 and s.summarize().peak == 2, "the card says you're through after two lines, peak 2")
	check(FileAccess.file_exists(s.summarize().get("file", "")) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(ProofScene.OUT_DIR)), "the turns are written to user://m0")
	var log := await _fake_log()
	var chats: Array = log.get("chat", [])
	check(chats.size() >= 4, "the fake saw the probe and three turns (%d)" % chats.size())
	var passed := chats.size() >= 2 and typeof(chats[1].get("response_format")) == TYPE_DICTIONARY and str(chats[1].response_format.get("type", "")) == "json_schema"
	check(passed, "every turn sends the schema as response_format")
	var speech: Array = log.get("speech", [])
	check(speech.size() >= 2 and str(speech[0].model) == "kokoro-v1" and str(speech[0].format) == "wav", "lines go to Kokoro as WAV (%d asked)" % speech.size())
	check(int(log.get("ws", {}).get("connections", 0)) >= 1, "the realtime socket was opened")
	s.queue_free()
	await frames(2)


## Hearing over the socket: fed audio, a commit, a partial, then the line.
func _test_fake_hearing() -> void:
	if not await _start_fake():
		return
	if not LGVoice.is_ready():
		LGBrain.stop()
		check(await LGVoice.setup_async(), "the voice comes up")
	_heard.clear()
	LGVoice.heard.connect(_on_heard)
	await _fake_post("/fake/transcript", {"text": "Testing the socket from the corridor."})
	LGVoice.begin_hearing()
	check(LGVoice.state == "listening", "holding the button listens")
	var pcm := PackedByteArray()
	pcm.resize(16000 * 2)
	for i in 16000:
		pcm.encode_s16(i * 2, int(sin(i * 0.05) * 12000.0))
	for i in 4:
		LGVoice.feed_audio(pcm.slice(i * 8000, (i + 1) * 8000))
		await frames(1)
	LGVoice.end_hearing()
	check(LGVoice.state == "thinking", "letting go waits for the words")
	check(await until(func(): return _heard.size() >= 1 and _heard[_heard.size() - 1][1], 10.0), "the line comes back")
	var partials := 0
	for h in _heard:
		if not h[1]:
			partials += 1
	check(partials >= 1 and _heard[0][0].begins_with("Testing the socket"), "a partial came first: %s" % str(_heard))
	check(_heard[_heard.size() - 1][0] == "Testing the socket from the corridor.", "then the whole line")
	check(LGVoice.last_hearing.final >= 0.0 and LGVoice.last_hearing.first_word >= 0.0 and LGVoice.last_hearing.spoken > 0.0, "the timings are kept: %s" % str(LGVoice.last_hearing))
	check(LGVoice.state == "ready", "and it's ready again")
	var log := await _fake_log()
	check(int(log.ws.commits) >= 1 and int(log.ws.bytes) >= 30000, "the audio went over the socket in chunks (%s)" % str(log.ws))
	_heard.clear()
	LGVoice.begin_hearing()
	LGVoice.end_hearing()
	check(await until(func(): return _heard.size() >= 1 and _heard[_heard.size() - 1][1], 10.0) and _heard[_heard.size() - 1][0] == "", "nothing said is heard as nothing")
	check(LGVoice.misheard >= 1, "and counted as misheard")
	LGVoice.heard.disconnect(_on_heard)


func _on_heard(text: String, final: bool) -> void:
	_heard.append([text, final])


## Puts the player a step or two from Marcus, where a normal voice carries.
func _walk_up(s: ProofScene) -> void:
	s.player.global_position = Vector3(0.0, 0.0, ServiceDoorRoom.Z0 + 2.5)
	await frames(1)


## Suspicion 5 ends it, and a slow brain falls back to a scripted line.
func _test_fake_caught_and_timeout() -> void:
	if not await _start_fake():
		return
	LGSettings.set_value("voice", "talk", "text")
	LGSettings.set_value("voice", "speaking", false)
	var s := ProofScene.new()
	add_child(s)
	await frames(3)
	check(await until(func(): return LGBrain.is_ready() and s.hud._schema.text != "", 15.0), "the brain is ready")
	await _walk_up(s)
	s._on_text_submitted("Open it or I'm calling the cops.")
	check(await until(func(): return s.guard.turns.size() >= 1 and not s.guard.busy, 10.0), "a threat gets a turn")
	var t0: Dictionary = s.guard.turns[0]
	check(not s.over and s.guard.suspicion() == 3 and t0.reply.do == "none" and t0.vetoed == "radio_security", "one line can only climb two steps, so the radio call is vetoed at 3: %s" % str(t0.reply))
	s._on_text_submitted("I said open it. Now.")
	check(await until(func(): return s.over, 10.0) and s.outcome == "caught", "a second threat gets you called in")
	check(s.guard.turns[1].reply.do == "radio_security" and s.guard.suspicion() == 5, "suspicion 5 ends it")
	s.queue_free()
	await frames(2)
	s = ProofScene.new()
	add_child(s)
	await frames(3)
	check(await until(func(): return LGBrain.is_ready() and s.hud._schema.text != "", 15.0), "the brain is ready again")
	await _fake_post("/fake/slow", {"seconds": BrainQueue.TIMEOUT + 3.0})
	await _walk_up(s)
	s._on_text_submitted("Evening.")
	check(await until(func(): return s.guard.turns.size() >= 1 and not s.guard.busy, BrainQueue.TIMEOUT + 6.0), "a slow brain still gets a turn")
	var t: Dictionary = s.guard.turns[0]
	check(t.scripted and t.timed_out and t.reply.say != "", "the line was scripted after the timeout (%.1f s)" % float(t.thought))
	s.queue_free()
	await frames(2)

#endregion
