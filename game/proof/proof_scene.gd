class_name ProofScene
extends Node3D
## M0's proof: the Meridian's back corridor, Marcus at the service door, and
## you. Talk your way through the door, or get called in. Wires the talk
## controls to [LGVoice], what's heard to the [Guard], and everything to
## the HUD; keeps every turn's timings and writes them to user://m0/ at
## the end.

const TITLE := "res://game/ui/title.tscn"
const SCENE := "res://game/proof/proof_scene.tscn"
const CREW := preload("res://game/player/crew_member.tscn")
const OUT_DIR := "user://m0"

static var current: ProofScene

var room: ServiceDoorRoom
var guard: Guard
var player: CrewMember
var hud: ProofHud
var pause: HotelPause
var text_line: TextLinePanel
var result: ResultCard
var ui: CanvasLayer
var over := false
var outcome := ""
var started_at := 0
## The hearing timings of the line the guard is about to hear.
var _hearing := {}


static func play() -> void:
	LGScenes.change_scene(SCENE)


func _ready() -> void:
	current = self
	started_at = Time.get_ticks_msec()
	var env := WorldEnvironment.new()
	env.environment = ServiceDoorRoom.environment()
	add_child(env)
	room = ServiceDoorRoom.new()
	room.name = "Room"
	add_child(room)
	room.through.body_entered.connect(_on_through)
	guard = Guard.make(CharacterSheet.marcus(), room.door)
	guard.transform = room.guard_spot
	add_child(guard)
	guard.said.connect(_on_said)
	guard.thought.connect(_on_thought)
	guard.suspicion_changed.connect(_on_suspicion)
	guard.ended.connect(_on_guard_ended)
	_build_ui()
	player = CREW.instantiate()
	player.hotel_pause = pause
	add_child(player)
	player.global_transform = room.start
	player.reset_physics_interpolation()
	player.talk_started.connect(_on_talk_started)
	player.talk_ended.connect(_on_talk_ended)
	player.text_requested.connect(_on_text_requested)
	guard.look_at = player
	hud.set_guard_name(guard.sheet.name)
	hud.set_suspicion(guard.suspicion())
	hud.set_hint(_hint())
	LGFocusPause.watch(self, player.open_pause)
	LGPlaytest.follow(self)
	LGPlaytest.event("door_start", {"guard": guard.sheet.id})
	LGVoice.heard.connect(_on_heard)
	LGVoice.state_changed.connect(_on_voice_state)
	LGBrain.state_changed.connect(_on_brain_state)
	_start_services()


func _exit_tree() -> void:
	if current == self:
		current = null
	if LGVoice.heard.is_connected(_on_heard):
		LGVoice.heard.disconnect(_on_heard)
	if LGVoice.state_changed.is_connected(_on_voice_state):
		LGVoice.state_changed.disconnect(_on_voice_state)
	if LGBrain.state_changed.is_connected(_on_brain_state):
		LGBrain.state_changed.disconnect(_on_brain_state)
	LGVoice.set_open_mic(false)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	hud = ProofHud.new()
	ui.add_child(hud)
	text_line = TextLinePanel.new()
	text_line.submitted.connect(_on_text_submitted)
	text_line.cancelled.connect(_on_text_cancelled)
	ui.add_child(text_line)
	pause = HotelPause.new()
	pause.leave.connect(_on_quit)
	pause.quit_to_title.connect(_on_quit)
	pause.quit_game.connect(_on_quit_game)
	ui.add_child(pause)
	result = ResultCard.new()
	result.again.connect(_again)
	result.to_title.connect(_on_quit)
	ui.add_child(result)


## Brings the brain and the voice up, in that order, and says how it went.
func _start_services() -> void:
	hud.set_brain(LGBrain.state, "Starting" if LGBrain.state == "off" else LGBrain.detail)
	hud.set_voice("off", "Waiting for the brain")
	var ok: bool = await LGBrain.ensure_ready_async()
	if not is_inside_tree():
		return
	guard.brains = ok
	hud.set_brain(LGBrain.state, LGBrain.detail)
	if ok:
		var probe: String = await guard.queue.probe_schema()
		if not is_inside_tree():
			return
		hud.set_schema(probe)
		LGPlaytest.event("schema_probe", {"result": probe})
	else:
		hud.set_schema("")
		hud.toast("No brain: Marcus is on scripted lines")
	var talk := str(LGSettings.get_value("voice", "talk", "push"))
	var want_voice: bool = ok and (bool(LGSettings.get_value("voice", "speaking", true)) or talk != "text")
	if not want_voice:
		guard.speak = false
		hud.set_voice("off", "Off")
		return
	LGVoice.hearing_model = str(LGSettings.get_value("voice", "hearing_model", "Whisper-Small"))
	var v: bool = await LGVoice.setup_async()
	if not is_inside_tree():
		return
	guard.speak = v and bool(LGSettings.get_value("voice", "speaking", true))
	if v and talk == "open":
		LGVoice.set_open_mic(true)
	if not v:
		hud.toast("No voice: type your lines with %s" % LGInput.label_for_action("text"))


func _hint() -> String:
	var talk := str(LGSettings.get_value("voice", "talk", "push"))
	match talk:
		"text":
			return "%s: type a line" % LGInput.label_for_action("text")
		"open":
			return "Just talk  ·  %s: type a line" % LGInput.label_for_action("text")
		_:
			return "Hold %s to talk  ·  %s whisper, %s shout  ·  %s: type a line" % [LGInput.label_for_action("talk"), LGInput.label_for_action("whisper"), LGInput.label_for_action("shout"), LGInput.label_for_action("text")]


func _on_talk_started() -> void:
	if over:
		return
	if str(LGSettings.get_value("voice", "talk", "push")) == "text" or not LGVoice.is_ready():
		_on_text_requested()
		return
	LGVoice.begin_hearing()
	hud.listening(true)


func _on_talk_ended() -> void:
	LGVoice.end_hearing()


func _on_text_requested() -> void:
	if over or text_line.is_open() or get_tree().paused:
		return
	player.is_movement_paused = true
	text_line.ask()


func _on_text_submitted(text: String) -> void:
	player.is_movement_paused = false
	LGVoice.text_line(text)


func _on_text_cancelled() -> void:
	player.is_movement_paused = false


func _on_heard(text: String, final: bool) -> void:
	if over:
		return
	hud.you(text, final)
	if not final:
		return
	_hearing = LGVoice.last_hearing.duplicate()
	if text == "":
		hud.toast("Didn't catch that")
		LGPlaytest.event("misheard", {})
		return
	LGPlaytest.event("you_said", {"text": text, "voice": player.voice(), "hearing": _hearing})
	guard.hear(text, player.mouth_position(), player.voice())


func _on_said(who: String, text: String) -> void:
	hud.say(who, text)


func _on_thought(turn: Dictionary) -> void:
	if str(turn.get("kind", "")) == "line":
		turn["hearing"] = _hearing
	hud.set_timing(turn)


func _on_suspicion(value: int) -> void:
	hud.set_suspicion(value)


func _on_guard_ended(how: String) -> void:
	if how == "caught":
		_finish("caught")
	else:
		hud.toast("The door's open")
		LGPlaytest.moment("let_through", {"turns": guard.turns.size()})


func _on_through(body: Node3D) -> void:
	if body == player and not over:
		_finish("through")


func _on_voice_state(state: String, detail: String) -> void:
	if is_instance_valid(hud):
		hud.set_voice(state, detail)


func _on_brain_state(state: String, detail: String) -> void:
	if is_instance_valid(hud):
		hud.set_brain(state, detail)


func _finish(how: String) -> void:
	over = true
	outcome = how
	player.is_movement_paused = true
	if player.talking:
		player.end_talk()
	var summary := summarize()
	summary["file"] = _write(summary)
	LGPlaytest.moment("door_" + how, summary)
	result.show_result(summary)


## The night in numbers: lines, time, suspicion, and the average timings.
func summarize() -> Dictionary:
	var heard := []
	var thought := []
	var spoke := []
	var scripted := 0
	var lines := 0
	for t in guard.turns:
		if str(t.get("kind", "")) == "line":
			lines += 1
			var h: Dictionary = t.get("hearing", {})
			if h.has("final") and float(h.final) >= 0.0 and float(h.get("spoken", 0.0)) > 0.0:
				heard.append(float(h.final))
		if float(t.get("thought", 0.0)) > 0.0 and not bool(t.get("scripted", false)):
			thought.append(float(t.thought))
		if float(t.get("spoke", -1.0)) >= 0.0:
			spoke.append(float(t.spoke))
		if bool(t.get("scripted", false)) and t.has("reply") and not (t.reply as Dictionary).is_empty():
			scripted += 1
	return {
		"outcome": outcome,
		"turns": lines,
		"seconds": (Time.get_ticks_msec() - started_at) / 1000.0,
		"peak": guard.peak_suspicion,
		"heard": _mean(heard),
		"thought": _mean(thought),
		"spoke": _mean(spoke),
		"scripted": scripted,
		"brain": LGBrain.detail,
		"voice": LGVoice.detail,
		"transport": LGVoice.transport,
		"hearing_model": LGVoice.hearing_model,
		"turn_log": guard.turns,
	}


static func _mean(values: Array) -> float:
	if values.is_empty():
		return -1.0
	var s := 0.0
	for v in values:
		s += float(v)
	return s / values.size()


func _write(summary: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var path := "%s/door-%s.json" % [OUT_DIR, Time.get_datetime_string_from_system(true).replace(":", "-")]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	return ProjectSettings.globalize_path(path)


func _again() -> void:
	get_tree().paused = false
	LGScenes.change_scene(SCENE)


func _on_quit() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	LGScenes.change_scene(TITLE)


func _on_quit_game() -> void:
	LGScenes.quit()
