class_name JobScene
extends Node3D
## One job: its venue, its cast, the crew and you. On the host it runs the
## [Job]; on a guest's device the characters are puppets of the host's.
## Every device hears its own player ([LGVoice]) and plays the characters'
## lines itself, from them, from the nearest radio, or in your ear on the
## phone; [JobNet] carries the rest. Ends with the job report, which it also
## writes to user://jobs/.

const SCENE := "res://game/job/job_scene.tscn"
const TITLE := "res://game/ui/title.tscn"
const CREW := preload("res://game/player/crew_member.tscn")
const OUT_DIR := "user://jobs"
## How far off a character's line is shown (and spoken), and how close to
## someone's radio a radio call is.
const HEAR_LINE := 12.0
const HEAR_RADIO := 5.0
## How far off a crewmate's line is shown, by voice.
const CREW_HEAR := {"whisper": 3.2, "normal": 9.0, "shout": 30.0}
const POSE_EVERY := 0.1
## How often people moving between rooms get the new room's lights.
const LIGHT_EVERY := 0.25
const SNAP_EVERY := 0.1
## How far you can reach to use something.
const REACH := 2.4

static var current: JobScene
## Set before the scene starts (see [method play]): "job" (an id from
## [Jobs]), "circuit" (a Circuit night's number, or 0), "crew" (CrewInfo
## dicts), "me" (this device's crew id) and "seed".
static var setup := {}

var def: JobDef
var venue: Venue
var job: Job
var net: JobNet
var crew: Array[CrewInfo] = []
var me: CrewInfo
var player: CrewMember
## id -> Character: the job's on the host, puppets on a guest.
var cast := {}
var avatars := {}
var hud: JobHud
var pause: HotelPause
var text_line: TextLinePanel
var keypad: KeypadPanel
var phone: PhonePanel
var report_card: JobReportCard
var ui: CanvasLayer
var over := false
var report := {}
var started_at := 0
var speaking := true
var _hearing := {}
var _pose_t := 0.0
var _snap_t := 0.0
var _light_t := 0.0
var _earpiece_player: AudioStreamPlayer
var _replay_player: AudioStreamPlayer
var _relaying := false
var _use_target := ""
## The keypad being used.
var _pad := ""
## Who you're on the phone with ("" for nobody).
var _call := ""
## Mae's calls this device has asked for (a guest doesn't know the host's).
var _mae_made := {}
## Host: guests whose scene isn't ready yet.
var _waiting := {}


## Starts a job (after the setup screen has the models ready). `crew` is
## CrewInfo dicts; solo, one is made from `cover`.
static func play(p_setup := {}) -> void:
	setup = p_setup
	LGScenes.change_scene(SCENE)


## One crew member on this device: solo setup.
static func solo(cover := "", female := false, player_name := "", job_id := "meridian_gala") -> Dictionary:
	Jobs.current = Jobs.make(job_id)
	var n := player_name if player_name != "" else GameConfig.player_name()
	var c := CrewInfo.make(1, 1, n, cover if cover != "" else Covers.first(), female)
	c.burned = Progress.burned
	Jobs.current.give_items([c])
	return {"job": job_id, "crew": [c.to_dict()], "me": 1, "seed": randi()}


## The job a setup plays: its job, remixed when it's a Circuit night.
static func def_for(config: Dictionary) -> JobDef:
	var job_id := str(config.get("job", "meridian_gala"))
	var out := Jobs.make(job_id if Jobs.exists(job_id) else "meridian_gala")
	if int(config.get("circuit", 0)) != 0:
		Circuit.remix(out, int(config.circuit))
	return out


func _ready() -> void:
	current = self
	started_at = Time.get_ticks_msec()
	if setup.is_empty():
		setup = solo()
	def = def_for(setup)
	Jobs.current = def
	Person.add_looks(def.looks)
	venue = def.venue()
	venue.name = "Venue"
	var env := WorldEnvironment.new()
	env.environment = venue.environment()
	add_child(env)
	add_child(venue)
	if venue.spots.is_empty():
		venue.build()
	net = JobNet.new()
	net.name = "Net"
	add_child(net)
	for d in setup.get("crew", []):
		crew.append(CrewInfo.from_dict(d))
	if not crew.is_empty() and not crew.any(func(c): return not c.items.is_empty()):
		def.give_items(crew)
	var my_id := int(setup.get("me", net.my_id()))
	for c in crew:
		if c.id == my_id:
			me = c
	if me == null:
		me = crew[0]
	_build_ui()
	_add_extras()
	_add_people()
	_connect_net()
	if net.is_host():
		job = Job.new()
		job.name = "Job"
		add_child(job)
		job.memories = Progress.memories_of([def.venue_id] + def.memory_from)
		job.setup(def, venue, crew, int(setup.get("seed", 0)))
		cast = job.cast
		_connect_job()
		for p in net.expected():
			_waiting[p] = true
		for p in net.guests():
			_on_guest_ready(p)
		job.hold = not _waiting.is_empty()
	else:
		_add_puppets()
		net.ready_for_state()
	hud.set_clock(job.clock_text() if job else JobDef.clock_text(def.start))
	hud.set_cover(me)
	hud.set_goal(def.goal if def.circuit.is_empty() else "%s\nTonight: %s" % [def.goal, Circuit.rules_text(def)])
	hud.set_hint(_hint())
	for it in def.items:
		_on_item(it, int(job.items[it].holder) if job else 0, str(job.items[it].at) if job else str(def.items[it].get("at", "")))
	if job and job.hold:
		hud.toast("Waiting for your crew")
	LGFocusPause.watch(self, player.open_pause)
	LGPlaytest.follow(self)
	LGPlaytest.event("job_start", {"crew": crew.size(), "cover": me.cover, "host": net.is_host()})
	LGVoice.heard.connect(_on_heard)
	LGVoice.state_changed.connect(_on_voice_state)
	LGVoice.mic_audio.connect(_on_mic_audio)
	LGBrain.state_changed.connect(_on_brain_state)
	_start_services()


func _exit_tree() -> void:
	if current == self:
		current = null
	for pair in [[LGVoice.heard, _on_heard], [LGVoice.state_changed, _on_voice_state], [LGVoice.mic_audio, _on_mic_audio], [LGBrain.state_changed, _on_brain_state]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	LGVoice.relay = false
	LGVoice.set_open_mic(false)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	hud = JobHud.new()
	ui.add_child(hud)
	text_line = TextLinePanel.new()
	text_line.submitted.connect(_on_text_submitted)
	text_line.cancelled.connect(_on_panel_closed)
	ui.add_child(text_line)
	keypad = KeypadPanel.new()
	keypad.entered.connect(_on_keypad_entered)
	keypad.cancelled.connect(_on_panel_closed)
	ui.add_child(keypad)
	phone = PhonePanel.new()
	phone.dialed.connect(_on_dialed)
	phone.mae_asked.connect(_on_mae_asked)
	phone.hung_up.connect(_on_hung_up)
	phone.closed.connect(_on_panel_closed)
	ui.add_child(phone)
	pause = HotelPause.new()
	pause.leave.connect(_on_quit)
	pause.quit_to_title.connect(_on_quit)
	pause.quit_game.connect(_on_quit_game)
	ui.add_child(pause)
	report_card = JobReportCard.new()
	report_card.again.connect(_again)
	report_card.to_title.connect(_on_quit)
	report_card.replay.connect(_on_replay)
	ui.add_child(report_card)
	_earpiece_player = AudioStreamPlayer.new()
	_earpiece_player.name = "Earpiece"
	add_child(_earpiece_player)
	VoiceRelay.prepare(_earpiece_player)
	_replay_player = AudioStreamPlayer.new()
	_replay_player.name = "Replay"
	_replay_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_replay_player)


## The crew: you, and a body for each crewmate on another device.
func _add_people() -> void:
	var i := 0
	for c in crew:
		var at: Transform3D = venue.spots.get("crew_%d" % i, venue.spots.get("crew_0", Transform3D.IDENTITY))
		i += 1
		if c == me:
			player = CREW.instantiate()
			player.hotel_pause = pause
			add_child(player)
			player.global_transform = _player_at(at)
			player.reset_physics_interpolation()
			player.talk_started.connect(_on_talk_started)
			player.talk_ended.connect(_on_talk_ended)
			player.text_requested.connect(_on_text_requested)
			player.use_pressed.connect(_on_use_pressed)
			player.phone_pressed.connect(_on_phone_pressed)
			c.node = player
			_dress_me()
		else:
			var a := CrewAvatar.make(c)
			venue.add_child(a)
			a.global_transform = at
			VoiceRelay.prepare(a.voice_player)
			avatars[c.id] = a
			c.node = a


## Each room's lights light only what's in it: people take the render
## layers of wherever they're standing.
func _light_people() -> void:
	for ch in cast.values():
		ch.person.set_light_layers(venue.light_layers_at(ch.global_position))
	for a in avatars.values():
		a.person.set_light_layers(venue.light_layers_at(a.global_position))
	if player and player.person:
		player.person.set_light_layers(venue.light_layers_at(player.feet_position()))


## Your own body in your cover's clothes, seen over your shoulder.
func _dress_me() -> void:
	if player.person and player.person.get_meta("outfit", "") == me.outfit:
		return
	var o: Dictionary = Covers.outfit(me.outfit)
	var p := Person.make(str(o.job), me.female, 1000 + me.id, me.look)
	p.set_meta("outfit", me.outfit)
	player.set_person(p)


## A spot faces its +z, as people do; the player looks down their -z, and
## stands with their origin above the floor.
static func _player_at(spot: Transform3D) -> Transform3D:
	return Transform3D(spot.basis.rotated(Vector3.UP, PI), spot.origin + Vector3(0, CrewMember.FEET, 0))


## On a guest: the cast, standing where the host says.
func _add_puppets() -> void:
	for sheet in def.sheets():
		var ch := Character.make(sheet)
		ch.puppet = true
		venue.add_child(ch)
		ch.global_transform = venue.spots.get(sheet.spot, Transform3D.IDENTITY)
		cast[sheet.id] = ch


## The crowd: guests, cooks, crew, dressed as the job says for each zone
## ([member JobDef.extras]). Posed, not animated, so they cost little.
func _add_extras() -> void:
	var n := 0
	for zone in venue.extras:
		var dress: Variant = def.extras.get(zone, "guest")
		var as_job := str(dress.get("job", "guest")) if dress is Dictionary else str(dress)
		var clips: Array = dress.get("clips", []) if dress is Dictionary else []
		if clips.is_empty():
			clips = ["Idle", "Interact"] if as_job == "kitchen" else ["Idle", "Idle_Talking", "Idle_FoldArms"]
		for t in venue.extras[zone]:
			n += 1
			var p := Person.make(as_job, n % 2 == 0, 500 + n)
			p.name = "Extra%d" % n
			venue.add_child(p)
			p.global_transform = t
			p.pose(clips[n % clips.size()], fmod(n * 0.37, 1.0))
			p.set_light_layers(venue.light_layers_at(t.origin))


func _connect_job() -> void:
	job.line_out.connect(_on_line)
	job.crew_line_out.connect(_on_crew_line_host)
	job.toast_for.connect(_on_toast_for)
	job.heat_changed.connect(_on_heat)
	job.crew_changed.connect(_on_crew_changed)
	job.door_changed.connect(_on_door_host)
	job.faced.connect(_on_faced_host)
	job.clock_changed.connect(_on_clock_host)
	job.item_changed.connect(_on_item_host)
	job.shown.connect(_on_shown_host)
	job.goal_changed.connect(_on_goal_host)
	job.mae_said.connect(_on_mae_host)
	job.call_changed.connect(_on_call_host)
	job.moved.connect(_on_moved_host)
	job.ended.connect(_on_job_ended)
	for ch in cast.values():
		ch.thought.connect(_on_thought)


func _connect_net() -> void:
	net.guest_ready.connect(_on_guest_ready)
	net.line_requested.connect(_on_line_requested)
	net.use_requested.connect(_on_use_requested)
	net.keypad_requested.connect(_on_keypad_requested)
	net.phone_requested.connect(_on_phone_requested)
	net.hang_up_requested.connect(_on_hang_up_requested)
	net.mae_requested.connect(_on_mae_requested)
	net.item_received.connect(_on_item)
	net.shown_received.connect(_on_shown)
	net.goal_received.connect(_on_goal)
	net.mae_received.connect(_on_mae)
	net.call_received.connect(_on_call)
	net.moved_received.connect(_on_moved)
	net.pose_received.connect(_on_pose)
	net.voice_received.connect(_on_voice)
	net.line_received.connect(_on_line)
	net.crew_line_received.connect(_on_crew_line)
	net.toast_received.connect(_on_toast)
	net.heat_received.connect(_on_heat)
	net.crew_received.connect(_on_crew_received)
	net.door_received.connect(_on_door_received)
	net.faced_received.connect(_on_faced)
	net.clock_received.connect(_on_clock)
	net.snapshot_received.connect(_on_snapshot)
	net.report_received.connect(_on_report)
	net.peer_gone.connect(_on_peer_gone)


## Brings the brain and the voice up, as at the door. Guests think nothing
## (the host does), but hear and speak with their own.
func _start_services() -> void:
	hud.set_brain(LGBrain.state, "Starting" if LGBrain.state == "off" else LGBrain.detail)
	hud.set_voice("off", "Waiting for the brain")
	if net.lan:
		LGVoice.start_mic()
	var ok: bool = await LGBrain.ensure_ready_async()
	if not is_inside_tree():
		return
	hud.set_brain(LGBrain.state, LGBrain.detail)
	if job:
		job.brains = ok
		if not ok:
			hud.toast("No brain: the staff are on scripted lines")
	var talk := str(LGSettings.get_value("voice", "talk", "push"))
	var want_voice: bool = ok and (bool(LGSettings.get_value("voice", "speaking", true)) or talk != "text")
	if not want_voice:
		speaking = false
		hud.set_voice("off", "Off")
		return
	LGVoice.hearing_model = str(LGSettings.get_value("voice", "hearing_model", "Whisper-Small"))
	var v: bool = await LGVoice.setup_async()
	if not is_inside_tree():
		return
	hud.set_voice(LGVoice.state, LGVoice.detail)
	speaking = v and bool(LGSettings.get_value("voice", "speaking", true))
	if v and talk == "open":
		LGVoice.set_open_mic(true)
	if not v:
		hud.toast("No voice: type your lines with %s" % LGInput.label_for_action("text"))


func _hint() -> String:
	var talk := str(LGSettings.get_value("voice", "talk", "push"))
	var ear := "  ·  %s: earpiece" % LGInput.label_for_action("earpiece") if crew.size() > 1 else ""
	match talk:
		"text":
			return "%s: type a line%s" % [LGInput.label_for_action("text"), ear]
		"open":
			return "Just talk  ·  %s: type a line%s" % [LGInput.label_for_action("text"), ear]
		_:
			return "Hold %s to talk  ·  %s whisper, %s shout  ·  %s: type%s" % [LGInput.label_for_action("talk"), LGInput.label_for_action("whisper"), LGInput.label_for_action("shout"), LGInput.label_for_action("text"), ear]


func _process(delta: float) -> void:
	if player == null:
		return
	_update_prompt()
	_light_t -= delta
	if _light_t <= 0.0:
		_light_t = LIGHT_EVERY
		_light_people()
	if not net.lan or over:
		return
	_pose_t -= delta
	if _pose_t <= 0.0:
		_pose_t = POSE_EVERY
		net.send_pose(me.id, player.feet_position(), player.look_dir(), player.is_crouching)
	if job:
		_snap_t -= delta
		if _snap_t <= 0.0:
			_snap_t = SNAP_EVERY
			var snaps := {}
			for id in cast:
				snaps[id] = cast[id].snapshot()
			net.snapshot(snaps)

#region Talking

func _on_talk_started() -> void:
	if over:
		return
	if player.on_earpiece and crew.size() < 2:
		player.end_talk()
		return
	if net.lan:
		_relaying = true
		LGVoice.relay = true
	if str(LGSettings.get_value("voice", "talk", "push")) == "text" or not LGVoice.is_ready():
		if not net.lan:
			_on_text_requested()
		return
	LGVoice.begin_hearing()
	hud.listening(true, player.on_earpiece)


func _on_talk_ended() -> void:
	if _relaying:
		_relaying = false
		LGVoice.relay = false
	LGVoice.end_hearing()


func _on_text_requested() -> void:
	if over or text_line.is_open() or keypad.is_open() or phone.is_open() or get_tree().paused:
		return
	player.is_movement_paused = true
	text_line.ask(_suggestions())


## Lines for text mode: what your cover might say.
func _suggestions() -> PackedStringArray:
	var out := PackedStringArray()
	for l in Covers.of(me.cover).get("lines", []):
		out.append(str(l) % me.cover_name if "%s" in str(l) else str(l))
	return out


func _on_text_submitted(text: String) -> void:
	player.is_movement_paused = false
	LGVoice.text_line(text)


func _on_panel_closed() -> void:
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
	var voice := player.voice()
	var ear := player.on_earpiece
	LGPlaytest.event("you_said", {"text": text, "voice": voice, "earpiece": ear, "hearing": _hearing})
	if job:
		job.crew_said(me.id, text, voice, ear)
	else:
		net.send_line(text, voice, ear, player.feet_position(), player.look_dir())


func _on_mic_audio(pcm: PackedByteArray) -> void:
	if not _relaying or not net.lan:
		return
	net.send_voice(me.id, VoiceRelay.encode(pcm), player.on_earpiece)


func _on_voice(crew_id: int, data: PackedByteArray, earpiece: bool) -> void:
	if crew_id == me.id:
		return
	if earpiece:
		VoiceRelay.play(_earpiece_player, data)
	elif avatars.has(crew_id):
		VoiceRelay.play(avatars[crew_id].voice_player, data)


## A character speaks: shown and spoken here if you're near them, near a
## radio when it's on the radio, or in your ear when they're on the phone
## with you.
func _on_line(char_id: String, text: String, tone: String, channel: String) -> void:
	if job:
		net.line(char_id, text, tone, channel)
	var ch: Character = cast.get(char_id)
	if ch == null or player == null:
		return
	if channel == "phone:%d" % me.id:
		hud.say(ch.sheet.name + " (phone)", text)
		if speaking:
			LGVoice.say(Language.clean(text), ch.sheet.voice, _earpiece_player, ch.sheet.voice_speed)
		return
	var at := player.global_position
	var near := ch.global_position.distance_to(at)
	var through: Character = null
	if channel == "radio":
		var best := minf(near, HEAR_RADIO)
		for other in cast.values():
			if other != ch and other.sheet.radio:
				var d: float = other.global_position.distance_to(at)
				if d < best:
					best = d
					through = other
	if near > HEAR_LINE and through == null:
		return
	hud.say(ch.sheet.name + (" (radio)" if through else ""), text, _where(through if through else ch))
	if not speaking:
		return
	if through:
		LGVoice.say(Language.clean(text), ch.sheet.voice, through.radio_player, ch.sheet.voice_speed)
	else:
		ch.speak_local(text, false, true)


func _on_crew_line_host(crew_id: int, text: String, voice: String, earpiece: bool) -> void:
	net.crew_line(crew_id, text, voice, earpiece)
	_on_crew_line(crew_id, text, voice, earpiece)


## A crewmate's words, as you'd hear them.
func _on_crew_line(crew_id: int, text: String, voice: String, earpiece: bool) -> void:
	if crew_id == me.id:
		return
	var c: CrewInfo = _crew(crew_id)
	if c == null or c.node == null:
		return
	if earpiece or c.position().distance_to(player.global_position) <= float(CREW_HEAR.get(voice, 9.0)):
		hud.crew(c.name, text, earpiece)


## Which way someone is from you, for subtitles: "" ahead, else "left",
## "right" or "behind".
func _where(n: Node3D) -> String:
	if n == null or player == null:
		return ""
	var to := n.global_position - player.global_position
	to.y = 0.0
	if to.length() < 0.5:
		return ""
	var look := player.look_dir()
	look.y = 0.0
	var a := rad_to_deg(look.normalized().signed_angle_to(to.normalized(), Vector3.UP))
	if absf(a) < 40.0:
		return ""
	if absf(a) > 130.0:
		return "behind"
	return "left" if a > 0.0 else "right"

#endregion

#region Using things

## What's in front of you, and what Interact would do with it.
func _update_prompt() -> void:
	_use_target = ""
	if over or player.is_movement_paused or get_tree().paused:
		hud.set_prompt("")
		return
	var from := player.mouth_position()
	var q := PhysicsRayQueryParameters3D.create(from, from + player.look_dir() * REACH, Kit.LAYER_INTERACT | Kit.LAYER_DOORS | Kit.LAYER_PEOPLE | Kit.LAYER_WORLD)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var what := ""
	if not hit.is_empty() and hit.collider != null:
		var node: Node = hit.collider
		if node.has_meta("use"):
			what = str(node.get_meta("use"))
		elif node.has_meta("character"):
			what = "character:" + str(node.get_meta("character"))
	if what == "":
		what = _facing_character()
	_use_target = what
	hud.set_prompt(_prompt_for(what))


## Someone close and nearly straight ahead, for when the aim passes over
## their shoulder or head.
func _facing_character() -> String:
	var look := player.look_dir()
	look.y = 0.0
	look = look.normalized()
	for id in cast:
		var d: Vector3 = cast[id].global_position - player.global_position
		d.y = 0.0
		if d.length() < REACH and d.length() > 0.01 and look.dot(d.normalized()) > 0.9:
			return "character:" + str(id)
	return ""


func _prompt_for(what: String) -> String:
	if what == "":
		return ""
	var key := LGInput.label_for_action("interact")
	var said: Variant = def.prompt_for(me, what)
	if said != null:
		return "%s: %s" % [key, said] if str(said) != "" else ""
	if def.keypads.has(what):
		return "%s: Use the keypad" % key
	if what.begins_with("item:"):
		var info: Dictionary = def.items.get(what.trim_prefix("item:"), {})
		return "%s: Take %s" % [key, info.get("name", "it")] if not info.is_empty() and not me.held else ""
	if what.begins_with("character:"):
		var paper := def.papers_for(me.items, what.trim_prefix("character:"))
		return "%s: Show %s" % [key, def.items[paper].get("name", "your papers")] if paper != "" and not me.held else ""
	if what.begins_with("door:"):
		var d = venue.doors.get(what.trim_prefix("door:"))
		if d == null or d.get("auto") == true:
			return ""
		return "%s: %s" % [key, "Close" if d.is_open else "Open"]
	return ""


func _on_use_pressed() -> void:
	if over or _use_target == "":
		return
	if def.keypads.has(_use_target):
		if me.held:
			return
		_pad = _use_target
		player.is_movement_paused = true
		keypad.ask(str(def.keypads[_pad].get("label", "Keypad")))
		return
	if job:
		_toast_back(job.use(me.id, _use_target))
	else:
		net.send_use(_use_target)


func _on_keypad_entered(code: String) -> void:
	player.is_movement_paused = false
	if job:
		_toast_back(job.keypad(me.id, code, _pad))
	else:
		net.send_keypad(code, _pad)


## The phone: the job's numbers, the caller ID to show, and (alone) Auntie
## Mae's calls.
func _on_phone_pressed() -> void:
	if over or me.held or text_line.is_open() or keypad.is_open() or phone.is_open() or get_tree().paused:
		return
	if def.phone.is_empty() and def.mae_calls.is_empty():
		hud.toast("No numbers for this job")
		return
	player.is_movement_paused = true
	phone.ask(def, _call, _mae_open(), crew.size() == 1)


## Mae's calls not made yet (asked of the host's job, or as far as this
## device knows).
func _mae_open() -> Array:
	if job:
		return job.mae_left()
	return def.mae_calls.filter(func(m): return not _mae_made.has(str(m.id)))



func _on_dialed(number_id: String, as_who: String) -> void:
	player.is_movement_paused = false
	if job:
		_toast_back(job.ring(me.id, number_id, as_who))
	else:
		net.send_phone(number_id, as_who)


func _on_hung_up() -> void:
	player.is_movement_paused = false
	if job:
		job.hang_up(me.id)
	else:
		net.send_hang_up()


func _on_mae_asked(call_id: String) -> void:
	player.is_movement_paused = false
	_mae_made[call_id] = true
	if job:
		if not job.mae_call(me.id, call_id):
			hud.toast("Mae can't make that call now")
	else:
		net.send_mae(call_id)


func _toast_back(text: String) -> void:
	if text != "":
		hud.toast(text)

#endregion

#region The host's side

func _on_guest_ready(peer: int) -> void:
	_waiting.erase(peer)
	job.hold = not _waiting.is_empty()
	for c in crew:
		net.crew(c.to_dict(), peer)
	for n in venue.doors:
		if venue.doors[n].get("auto") != true:
			net.door(n, venue.doors[n].is_open, venue.doors[n].locked, peer)
	net.heat(job.heat.level, peer)
	for it in job.items:
		net.item(it, int(job.items[it].holder), str(job.items[it].at), peer)
	var shown_now := job.shown_nodes()
	for n in shown_now:
		net.shown(n, bool(shown_now[n]), peer)
	net.goal(peer, job.goal_for(peer))


func _on_line_requested(peer: int, text: String, voice: String, earpiece: bool, at: Vector3, look: Vector3) -> void:
	if avatars.has(peer):
		avatars[peer].snap(at, look)
	job.crew_said(peer, text, voice, earpiece)


func _on_use_requested(peer: int, what: String) -> void:
	var said := job.use(peer, what)
	if said != "":
		net.toast(peer, said)


func _on_keypad_requested(peer: int, code: String, pad: String) -> void:
	var said := job.keypad(peer, code, pad)
	if said != "":
		net.toast(peer, said)


func _on_phone_requested(peer: int, number_id: String, as_who: String) -> void:
	var said := job.ring(peer, number_id, as_who)
	if said != "":
		net.toast(peer, said)


func _on_hang_up_requested(peer: int) -> void:
	job.hang_up(peer)


func _on_mae_requested(peer: int, call_id: String) -> void:
	if not job.mae_call(peer, call_id):
		net.toast(peer, "Mae can't make that call now")


func _on_item_host(item: String, holder: int, at: String) -> void:
	net.item(item, holder, at)
	_on_item(item, holder, at)


func _on_shown_host(node_name: String, is_visible: bool) -> void:
	net.shown(node_name, is_visible)


func _on_goal_host(crew_id: int, text: String) -> void:
	net.goal(crew_id, text)
	if crew_id == 0 or crew_id == me.id:
		_on_goal(text)


func _on_moved_host(crew_id: int, at: Transform3D) -> void:
	if crew_id == me.id:
		_on_moved(at)
	else:
		net.move(crew_id, at)


func _on_mae_host(crew_id: int, text: String) -> void:
	if crew_id == me.id:
		_on_mae(text)
	else:
		net.mae(crew_id, text)


func _on_call_host(crew_id: int, char_id: String, number_name: String) -> void:
	if crew_id == me.id:
		_on_call(char_id, number_name)
	else:
		net.call_state(crew_id, char_id, number_name)


func _on_toast_for(crew_id: int, text: String) -> void:
	if crew_id == 0 or crew_id == me.id:
		hud.toast(text)
	if crew_id != me.id:
		net.toast(crew_id, text)


func _on_door_host(door_name: String, is_open: bool, locked: bool) -> void:
	net.door(door_name, is_open, locked)


func _on_faced_host(crew_id: int, char_id: String, suspicion: int) -> void:
	if crew_id == me.id:
		_on_faced(char_id, suspicion)
	else:
		net.faced(crew_id, char_id, suspicion)


func _on_clock_host(minute: int) -> void:
	net.clock(minute)
	_on_clock(minute)


func _on_thought(_ch: Character, turn: Dictionary) -> void:
	if int(turn.get("subject", 0)) == me.id and str(turn.get("kind", "")) == "line":
		turn["hearing"] = _hearing
		hud.set_timing(turn)


func _on_job_ended(r: Dictionary) -> void:
	net.report(r)
	_on_report(r)

#endregion

#region Everyone's side

func _on_crew_changed(crew_id: int) -> void:
	var c := _crew(crew_id)
	if c == null:
		return
	if job:
		net.crew(c.to_dict())
	_apply_crew(c)


func _on_crew_received(info: Dictionary) -> void:
	var c := _crew(int(info.get("id", 0)))
	if c == null:
		return
	var fresh := CrewInfo.from_dict(info)
	c.outfit = fresh.outfit
	c.items = fresh.items
	c.flags = fresh.flags
	var was_held := c.held
	c.held = fresh.held
	c.inside = fresh.inside
	_apply_crew(c, was_held)


## Shows a crew member's change: clothes, held, inside.
func _apply_crew(c: CrewInfo, was_held := false) -> void:
	if avatars.has(c.id):
		avatars[c.id].dress()
	if c != me:
		return
	hud.set_cover(me)
	_dress_me()
	if c.held and not hud.is_held():
		hud.set_held(true, str(def.office.get("name", "the security office")))
		var i := crew.find(c)
		var at: Transform3D = venue.spots.get(str(def.office.get("held", "held")), player.global_transform)
		at.origin += at.basis.x * (0.8 * i)
		hud.fade()
		await get_tree().create_timer(0.35).timeout
		if is_inside_tree():
			player.global_transform = _player_at(at)
			player.reset_physics_interpolation()
	elif not c.held and (was_held or hud.is_held()):
		hud.set_held(false)


func _on_toast(text: String) -> void:
	hud.toast(text)


func _on_heat(level: int) -> void:
	hud.set_heat(level)


func _on_door_received(door_name: String, is_open: bool, locked: bool) -> void:
	var d = venue.doors.get(door_name)
	if d == null:
		return
	if is_open and not d.is_open:
		d.locked = false
		d.open()
	elif not is_open and d.is_open:
		d.close()
	d.locked = locked


func _on_faced(char_id: String, suspicion: int) -> void:
	var ch: Character = cast.get(char_id)
	hud.set_face(ch.sheet.name if ch else char_id.capitalize(), suspicion)


func _on_clock(minute: int) -> void:
	hud.set_clock(JobDef.clock_text(minute))
	venue.set_clock(minute)


## An item moved: it shows at the use it lies at (any of the venue's uses
## for it), and nowhere else.
func _on_item(item: String, _holder: int, at: String) -> void:
	for u in venue.uses:
		var n: Node3D = venue.uses[u]
		if n == null or str(n.get_meta("use", "")) != "item:" + item:
			continue
		var here := str(u) == at
		n.visible = here
		if n is CollisionObject3D:
			(n as CollisionObject3D).collision_layer = Kit.LAYER_INTERACT if here else 0


func _on_shown(node_name: String, is_visible: bool) -> void:
	var n := venue.find_child(node_name, true, false) as Node3D
	if n:
		n.visible = is_visible


func _on_goal(text: String) -> void:
	hud.set_goal(text)


## Taken somewhere at once: a fade, then there.
func _on_moved(at: Transform3D) -> void:
	hud.fade()
	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		player.global_transform = _player_at(at)
		player.reset_physics_interpolation()


## Auntie Mae, in your ear.
func _on_mae(text: String) -> void:
	hud.say("Auntie Mae (earpiece)", text)
	if speaking:
		LGVoice.say(Language.clean(text), GameConfig.MAE_VOICE, _earpiece_player, 0.95)


func _on_call(char_id: String, number_name: String) -> void:
	_call = char_id
	hud.set_call(number_name)


func _on_snapshot(chars: Dictionary) -> void:
	var dt := get_process_delta_time()
	for id in chars:
		var ch: Character = cast.get(id)
		if ch:
			ch.apply_snapshot(chars[id], dt)


func _on_pose(crew_id: int, at: Vector3, look: Vector3, crouch: bool) -> void:
	if avatars.has(crew_id):
		avatars[crew_id].apply_pose(at, look, crouch)


func _on_peer_gone(peer: int) -> void:
	if peer == 1 and not net.is_host() and not over:
		hud.toast("The host left")
		_finish({"outcome": "lost", "title": "THE HOST LEFT", "text": "The night ended when the host's game did.", "crew": [], "best": {}, "worst": {}})
		return
	_waiting.erase(peer)
	var c := _crew(peer)
	if c:
		hud.toast("%s left" % c.name)
		c.held = true
		if job:
			job.hold = not _waiting.is_empty()
			job._check_end()


func _on_report(r: Dictionary) -> void:
	_finish(r)


func _on_voice_state(state: String, detail: String) -> void:
	if is_instance_valid(hud):
		hud.set_voice(state, detail)


func _on_brain_state(state: String, detail: String) -> void:
	if is_instance_valid(hud):
		hud.set_brain(state, detail)

#endregion

#region The end

func _finish(r: Dictionary) -> void:
	if over:
		return
	over = true
	report = r.duplicate(true)
	report["me"] = me.id
	report["host"] = net.is_host()
	report["lan"] = net.lan
	report["brain"] = LGBrain.detail
	report["voice"] = LGVoice.detail
	report["hearing_model"] = LGVoice.hearing_model
	player.is_movement_paused = true
	if player.talking:
		player.end_talk()
	report["file"] = _write(report)
	Progress.record(report, me.id)
	_report_online()
	LGPlaytest.moment("job_" + str(report.get("outcome", "")), {"clock": report.get("clock", ""), "heat_peak": report.get("heat_peak", 0)})
	report_card.show_report(report, me.id)


## Online: the host reports the job to the game server, and the contract's
## take goes on its board from whoever played it.
func _report_online() -> void:
	if Session.mode == Session.Mode.ONLINE_HOST:
		Session.report_job(report)
	if CityOnline.is_contract(report):
		CityOnline.submit_contract(report)


func _write(r: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var path := "%s/%s-%s.json" % [OUT_DIR, def.id, Time.get_datetime_string_from_system(true).replace(":", "-")]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	var turns := {}
	if job:
		for id in cast:
			turns[id] = cast[id].turns
	var out := r.duplicate(true)
	out["turn_log"] = turns
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	return ProjectSettings.globalize_path(path)


## Plays a line from the report again, in the character's voice.
func _on_replay(char_id: String, text: String) -> void:
	var sheet := def.sheet(char_id)
	if sheet == null or not LGVoice.is_ready():
		return
	LGVoice.hush(_replay_player)
	LGVoice.say(Language.clean(text), sheet.voice, _replay_player, sheet.voice_speed)


func _again() -> void:
	get_tree().paused = false
	if net.lan:
		_on_quit()
		return
	setup = solo(me.cover, me.female, me.name, def.id) if not net.lan else setup
	LGScenes.change_scene(SCENE)


func _on_quit() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if over:
		Session.back_to = "board"
	if net.lan:
		Session.leave()
	LGScenes.change_scene(TITLE)


func _on_quit_game() -> void:
	LGScenes.quit()

#endregion


func _crew(id: int) -> CrewInfo:
	for c in crew:
		if c.id == id:
			return c
	return null
