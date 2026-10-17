class_name Guard
extends Node3D
## A character at a door: a [Person] with a [Face], a sheet, a brain through
## [BrainQueue], a voice through [LGVoice] and the rules round it all. Hears
## what the player says (as [Earshot] lets it through), thinks, speaks, acts
## and keeps the conversation and every turn's timings.

## Something was said out loud (for subtitles): who, and what.
signal said(name: String, text: String)
## A turn is done thinking: the record (see [method record_turn]).
signal thought(turn: Dictionary)
signal suspicion_changed(value: int)
signal acted(action: String)
## "through" (the door is open) or "caught" (backup's on its way).
signal ended(how: String)

## The radio's voice (Dana on reception).
const RADIO_VOICE := "af_sky"
const RADIO_WAIT := 2.4
## Seconds of standing close by in silence before the character remarks on it.
const SILENCE := 25.0

var sheet: CharacterSheet
var person: Person
var face: Face
var door: GuardDoor
var voice_player: AudioStreamPlayer3D
var radio_player: AudioStreamPlayer3D
var queue: BrainQueue
var state := {}
## The conversation as the model sees it (see [GuardPrompt]).
var history: Array = []
## One record per turn: what was said and heard, the reply, and the timings.
var turns: Array = []
## Use the model (false: scripted lines only, when there's no brain).
var brains := true
## Speak out loud through LGVoice (subtitles either way).
var speak := true
var busy := false
var peak_suspicion := 0
## Who to face (the player).
var look_at: Node3D
var rng := RandomNumberGenerator.new()
var _line: LGVoiceLine
var _idle := "Idle_FoldArms"
var _ended := ""
var _silent_for := 0.0
var _remarked := false
var _mood_t := 0.0


static func make(p_sheet: CharacterSheet, p_door: GuardDoor) -> Guard:
	var g := Guard.new()
	g.name = p_sheet.name
	g.sheet = p_sheet
	g.door = p_door
	g.rng.seed = p_sheet.seed
	return g


func _ready() -> void:
	state = GuardRules.new_state(sheet)
	peak_suspicion = int(state.suspicion)
	person = Person.make(sheet.person_job, sheet.female, sheet.seed, sheet.person_look())
	add_child(person)
	face = Face.make(person)
	_idle = "Idle_FoldArms" if sheet.arms_folded else "Idle"
	person.play(_idle)
	voice_player = AudioStreamPlayer3D.new()
	voice_player.name = "Voice"
	voice_player.position = person.eyes_at + Vector3(0, -0.08, 0.05)
	voice_player.unit_size = 4.0
	voice_player.max_distance = 30.0
	voice_player.bus = "Master"
	add_child(voice_player)
	radio_player = AudioStreamPlayer3D.new()
	radio_player.name = "Radio"
	radio_player.position = Vector3(0.18, 1.4, 0.05)
	radio_player.unit_size = 2.0
	radio_player.max_distance = 12.0
	radio_player.volume_db = -6.0
	add_child(radio_player)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = Kit.LAYER_PEOPLE
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	add_child(body)
	queue = BrainQueue.new()
	queue.name = "Brain"
	add_child(queue)


func _process(delta: float) -> void:
	face.level = _line.level if _line and _line.is_playing() else 0.0
	if look_at and _ended == "":
		var to := look_at.global_position - global_position
		to.y = 0.0
		if to.length() > 0.5 and to.length() < 7.0:
			var yaw := atan2(to.x, to.z)
			rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-delta * 3.0))
	if _mood_t > 0.0:
		_mood_t -= delta
		if _mood_t <= 0.0 and not is_speaking():
			person.play(_idle)
	# Someone standing close by saying nothing gets a word, once.
	if look_at and _ended == "" and not busy and brains:
		var near := look_at.global_position.distance_to(global_position) < 3.0
		_silent_for = _silent_for + delta if near else 0.0
		if _silent_for > SILENCE and not _remarked:
			_remarked = true
			event("They've been standing in front of you for a while without saying anything.")


func is_speaking() -> bool:
	return _line != null and _line.state in ["asked", "playing"]


func suspicion() -> int:
	return int(state.get("suspicion", 1))


## The player said something, from somewhere, in some voice.
func hear(text: String, from: Vector3, voice := "normal") -> void:
	if _ended != "" or text.strip_edges() == "":
		return
	_silent_for = 0.0
	var ear := global_position + Vector3(0, 1.6, 0)
	var d := ear.distance_to(from)
	var h := Earshot.hear(text, d, voice, rng)
	var turn := {"kind": "line", "said": text, "heard": str(h.heard), "clarity": float(h.clarity), "how": str(h.how), "distance": d, "voice": voice}
	if str(h.heard) == "":
		turn["reply"] = {}
		if float(h.clarity) > 0.0:
			_say(_pick(sheet.not_heard))
		turns.append(turn)
		thought.emit(turn)
		return
	state["turns"] = int(state.get("turns", 0)) + 1
	history.append({"who": "player", "text": GuardPrompt.player_line(str(h.heard), d, voice, str(h.how))})
	_think(turn)


## Something happened that the character notices.
func event(text: String) -> void:
	if _ended != "":
		return
	history.append({"who": "event", "text": GuardPrompt.event_line(text)})
	_think({"kind": "event", "said": "", "heard": text, "clarity": 1.0, "how": "clear", "distance": 0.0, "voice": ""})


func _think(turn: Dictionary) -> void:
	while busy:
		await get_tree().process_frame
	if _ended != "":
		return
	busy = true
	var reply := {}
	var res := {}
	var actions := sheet.actions
	turn["scripted"] = true
	turn["strict"] = false
	turn["thought"] = 0.0
	if brains and LGBrain.is_ready():
		var mind := bool(LGSettings.get_value("voice", "mind_language", false))
		res = await queue.ask(GuardPrompt.messages(sheet, history, mind), ReplySchema.schema(actions))
		turn["thought"] = float(res.seconds)
		turn["prompt_tokens"] = int(res.prompt_tokens)
		turn["completion_tokens"] = int(res.completion_tokens)
		turn["cached_tokens"] = int(res.cached_tokens)
		turn["timed_out"] = bool(res.timed_out)
		turn["raw"] = str(res.text)
		if res.ok:
			reply = ReplySchema.parse(str(res.text), actions)
			turn["strict"] = ReplySchema.is_strict(str(res.text), actions)
			turn["scripted"] = reply.is_empty()
	if reply.is_empty():
		reply = _scripted_reply(turn)
	var out := GuardRules.resolve(reply, state, sheet, rng)
	GuardRules.apply(out, state)
	peak_suspicion = maxi(peak_suspicion, suspicion())
	history.append({"who": "character", "text": GuardPrompt.reply_text(out)})
	turn["reply"] = out
	turn["suspicion"] = suspicion()
	turn["vetoed"] = str(out.vetoed)
	turns.append(turn)
	suspicion_changed.emit(suspicion())
	_mood(str(out.tone))
	LGPlaytest.event("guard_turn", {"heard": turn.heard, "say": out.say, "do": out.do, "suspicion": suspicion(), "thought": turn.thought, "scripted": turn.scripted})
	var spoke := await _say(str(out.say))
	turn["spoke"] = spoke
	thought.emit(turn)
	_act(str(out.do))
	busy = false
	if str(out.ended) != "":
		_end(str(out.ended))


## Without a model: a few lines that keep the door honest.
func _scripted_reply(turn: Dictionary) -> Dictionary:
	var heard := str(turn.get("heard", "")).to_lower()
	var r := {"think": "", "say": _pick(sheet.fallbacks), "tone": "calm", "do": "none", "believes": [], "suspicion": suspicion()}
	if turn.get("kind", "") == "event":
		r.say = "Reception says nothing's booked. So who sent you?" if heard.contains("reception") else ""
		r.suspicion = suspicion() + 1
	elif heard.contains("badge") or heard.contains("work order"):
		r.say = "Let's see it, then."
		r.do = "ask_for_badge"
	elif heard.contains("code"):
		r.say = "Not a chance."
		r.tone = "annoyed"
		r.suspicion = suspicion() + 2
	elif heard.contains("reception") or heard.contains("booked") or heard.contains("facilities"):
		r.say = "Hang on, I'll check with reception." if str(state.get("reception", "")) == "" else "Reception already said no."
		r.do = "ask_reception" if str(state.get("reception", "")) == "" else "none"
		r.tone = "wary"
	else:
		r.say = _pick(["Staff only back here.", "Service entrance. You want the front.", "Can I help you?"])
	return r


## Says a line out loud (and emits it for subtitles). Returns seconds from
## the ask to the first sound, or -1 when nothing was said out loud.
func _say(text: String) -> float:
	if text.strip_edges() == "":
		return -1.0
	said.emit(sheet.name, text)
	if not speak or not LGVoice.is_ready():
		return -1.0
	_line = LGVoice.say(Language.clean(text), sheet.voice, voice_player, sheet.voice_speed)
	person.play("Idle_Talking")
	var waited := 0.0
	while _line.state == "asked" and waited < 20.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _line.state != "playing":
		person.play(_idle)
		return -1.0
	_line.finished.connect(_on_line_finished, CONNECT_ONE_SHOT)
	return _line.first_sound


func _on_line_finished() -> void:
	if _mood_t <= 0.0:
		person.play(_idle)


func _mood(tone: String) -> void:
	match tone:
		"friendly":
			_idle = "Idle"
		"calm":
			_idle = "Idle_FoldArms" if sheet.arms_folded else "Idle"
		"wary":
			_idle = "Idle_FoldArms"
		"annoyed":
			_idle = "Idle_FoldArms"
			person.play("Idle_No")
			_mood_t = 2.5
		"alarmed":
			_idle = "Idle"


func _act(action: String) -> void:
	acted.emit(action)
	match action:
		"ask_for_badge":
			person.play("Interact")
			_mood_t = 1.5
		"ask_reception":
			_radio_reception()
		"let_through":
			person.play("Interact")
			_mood_t = 1.5
			if door:
				door.open()
		"radio_security":
			person.play("Idle_TalkingPhone")
			_mood_t = 6.0


## Calls reception; Dana answers after a moment, and the character thinks
## again with her answer.
func _radio_reception() -> void:
	person.play("Idle_TalkingPhone")
	_mood_t = RADIO_WAIT + 2.0
	await get_tree().create_timer(RADIO_WAIT).timeout
	if _ended != "":
		return
	state["reception"] = "answered"
	said.emit("Dana, on the radio", sheet.reception_line)
	if speak and LGVoice.is_ready():
		LGVoice.say(sheet.reception_line, RADIO_VOICE, radio_player, 1.05)
	event("Dana, on the radio: \"%s\"" % sheet.reception_line)


func _end(how: String) -> void:
	_ended = how
	ended.emit(how)


func _pick(lines: Array[String]) -> String:
	if lines.is_empty():
		return ""
	return lines[rng.randi() % lines.size()]
