class_name JobScene
extends Node3D
## The gala: the Meridian, its cast, the crew and you. On the host it runs
## the [Job]; on a guest's device the characters are puppets of the host's.
## Every device hears its own player ([LGVoice]) and plays the characters'
## lines itself, from them or from the nearest radio; [JobNet] carries the
## rest. Ends with the job report, which it also writes to user://jobs/.

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
const PROMPTS := {
	"jackets": ["Put on a waiter's jacket", "Hang the jacket up"],
	"keypad": ["Use the keypad", ""],
}

static var current: JobScene
## Set before the scene starts (see [method play]): "crew" (CrewInfo dicts),
## "me" (this device's crew id) and "seed".
static var setup := {}

var hotel: Meridian
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
## Host: guests whose scene isn't ready yet.
var _waiting := {}


## Starts the gala (after the setup screen has the models ready). `crew`
## is CrewInfo dicts; solo, one is made from `cover`.
static func play(p_setup := {}) -> void:
	setup = p_setup
	LGScenes.change_scene(SCENE)


## One crew member on this device: solo setup.
static func solo(cover := "guest", female := false, player_name := "") -> Dictionary:
	var n := player_name if player_name != "" else GameConfig.player_name()
	var c := CrewInfo.make(1, 1, n, cover, female)
	c.has_invitation = true
	return {"crew": [c.to_dict()], "me": 1, "seed": randi()}


func _ready() -> void:
	current = self
	started_at = Time.get_ticks_msec()
	if setup.is_empty():
		setup = solo()
	var env := WorldEnvironment.new()
	env.environment = Meridian.environment()
	add_child(env)
	hotel = Meridian.new()
	hotel.name = "Hotel"
	add_child(hotel)
	if hotel.has_method("build") and hotel.spots.is_empty():
		hotel.build()
	net = JobNet.new()
	net.name = "Net"
	add_child(net)
	for d in setup.get("crew", []):
		crew.append(CrewInfo.from_dict(d))
	if not crew.any(func(c): return c.has_invitation) and not crew.is_empty():
		crew[0].has_invitation = true
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
		job.setup(hotel, crew, int(setup.get("seed", 0)))
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
	hud.set_clock(job.clock_text() if job else "8:45 pm")
	hud.set_cover(me)
	hud.set_hint(_hint())
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
		var at: Transform3D = hotel.spots.get("crew_%d" % i, hotel.spots.get("crew_0", Transform3D.IDENTITY))
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
			c.node = player
		else:
			var a := CrewAvatar.make(c)
			hotel.add_child(a)
			a.global_transform = at
			VoiceRelay.prepare(a.voice_player)
			avatars[c.id] = a
			c.node = a


## Each room's lights light only what's in it: people take the render
## layers of wherever they're standing.
func _light_people() -> void:
	if not hotel.has_method("light_layers_at"):
		return
	for ch in cast.values():
		ch.person.set_light_layers(hotel.light_layers_at(ch.global_position))
	for a in avatars.values():
		a.person.set_light_layers(hotel.light_layers_at(a.global_position))


## Hides a jacket on the staff room's rack for each crew member wearing one.
func _update_rack() -> void:
	var worn := crew.filter(func(c): return c.outfit == "waiter_jacket").size()
	var jackets := hotel.find_children("Jacket_?", "Node3D", true, false)
	jackets.sort_custom(func(a, b): return String(a.name) > String(b.name))
	for i in jackets.size():
		jackets[i].visible = i >= worn


## A spot faces its +z, as people do; the player looks down their -z, and
## stands with their origin above the floor.
static func _player_at(spot: Transform3D) -> Transform3D:
	return Transform3D(spot.basis.rotated(Vector3.UP, PI), spot.origin + Vector3(0, CrewMember.FEET, 0))


## On a guest: the cast, standing where the host says.
func _add_puppets() -> void:
	for sheet in Cast.all():
		var ch := Character.make(sheet)
		ch.puppet = true
		hotel.add_child(ch)
		ch.global_transform = hotel.spots.get(sheet.spot, Transform3D.IDENTITY)
		cast[sheet.id] = ch


## The rest of the gala: guests in the ballroom and lobby, cooks in the
## kitchen. Posed, not animated, so they cost little.
func _add_extras() -> void:
	var n := 0
	for zone in hotel.extras:
		for t in hotel.extras[zone]:
			n += 1
			var p := Person.make("kitchen" if zone == "kitchen" else "guest", n % 2 == 0, 500 + n)
			p.name = "Extra%d" % n
			hotel.add_child(p)
			p.global_transform = t
			var clips := ["Idle", "Idle_Talking", "Idle_FoldArms"] if zone != "kitchen" else ["Idle", "Interact"]
			p.pose(clips[n % clips.size()], fmod(n * 0.37, 1.0))
			if hotel.has_method("light_layers_at"):
				p.set_light_layers(hotel.light_layers_at(t.origin))


func _connect_job() -> void:
	job.line_out.connect(_on_line)
	job.crew_line_out.connect(_on_crew_line_host)
	job.toast_for.connect(_on_toast_for)
	job.heat_changed.connect(_on_heat)
	job.crew_changed.connect(_on_crew_changed)
	job.door_changed.connect(_on_door_host)
	job.faced.connect(_on_faced_host)
	job.clock_changed.connect(_on_clock_host)
	job.ended.connect(_on_job_ended)
	for ch in cast.values():
		ch.thought.connect(_on_thought)


func _connect_net() -> void:
	net.guest_ready.connect(_on_guest_ready)
	net.line_requested.connect(_on_line_requested)
	net.use_requested.connect(_on_use_requested)
	net.keypad_requested.connect(_on_keypad_requested)
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
	if over or text_line.is_open() or keypad.is_open() or get_tree().paused:
		return
	player.is_movement_paused = true
	text_line.ask()


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


## A character speaks: shown and spoken here if you're near them, or near
## a radio when it's on the radio.
func _on_line(char_id: String, text: String, tone: String, radio: bool) -> void:
	if job:
		net.line(char_id, text, tone, radio)
	var ch: Character = cast.get(char_id)
	if ch == null or player == null:
		return
	var at := player.global_position
	var near := ch.global_position.distance_to(at)
	var through: Character = null
	if radio:
		var best := minf(near, HEAR_RADIO)
		for other in cast.values():
			if other != ch and other.sheet.radio:
				var d: float = other.global_position.distance_to(at)
				if d < best:
					best = d
					through = other
	if near > HEAR_LINE and through == null:
		return
	hud.say(ch.sheet.name + (" (radio)" if through else ""), text)
	if not speaking:
		return
	if through:
		LGVoice.say(text, ch.sheet.voice, through.radio_player, ch.sheet.voice_speed)
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
	if what == "jackets":
		return "%s: %s" % [key, PROMPTS.jackets[1 if me.outfit == "waiter_jacket" else 0]]
	if what == "keypad":
		return "%s: %s" % [key, PROMPTS.keypad[0]]
	if what.begins_with("character:"):
		return "%s: Show the invitation" % key if me.has_invitation and not me.held else ""
	if what.begins_with("door:"):
		var d = hotel.doors.get(what.trim_prefix("door:"))
		if d == null or what == "door:front":
			return ""
		return "%s: %s" % [key, "Close" if d.is_open else "Open"]
	return ""


func _on_use_pressed() -> void:
	if over or _use_target == "":
		return
	if _use_target == "keypad":
		if me.held:
			return
		player.is_movement_paused = true
		keypad.ask()
		return
	if job:
		_toast_back(job.use(me.id, _use_target))
	else:
		net.send_use(_use_target)


func _on_keypad_entered(code: String) -> void:
	player.is_movement_paused = false
	if job:
		_toast_back(job.keypad(me.id, code))
	else:
		net.send_keypad(code)


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
	for n in hotel.doors:
		if hotel.doors[n].get("auto") != true:
			net.door(n, hotel.doors[n].is_open, hotel.doors[n].locked, peer)
	net.heat(job.heat.level, peer)


func _on_line_requested(peer: int, text: String, voice: String, earpiece: bool, at: Vector3, look: Vector3) -> void:
	if avatars.has(peer):
		avatars[peer].snap(at, look)
	job.crew_said(peer, text, voice, earpiece)


func _on_use_requested(peer: int, what: String) -> void:
	var said := job.use(peer, what)
	if said != "":
		net.toast(peer, said)


func _on_keypad_requested(peer: int, code: String) -> void:
	var said := job.keypad(peer, code)
	if said != "":
		net.toast(peer, said)


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
	c.has_invitation = fresh.has_invitation
	var was_held := c.held
	c.held = fresh.held
	c.inside = fresh.inside
	_apply_crew(c, was_held)


## Shows a crew member's change: clothes, held, inside.
func _apply_crew(c: CrewInfo, was_held := false) -> void:
	_update_rack()
	if avatars.has(c.id):
		avatars[c.id].dress()
	if c != me:
		return
	hud.set_cover(me)
	if c.held and not hud.is_held():
		hud.set_held(true)
		var i := crew.find(c)
		var at: Transform3D = hotel.spots.get("held", player.global_transform)
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
	var d = hotel.doors.get(door_name)
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
	hud.set_clock("%d:%02d pm" % [8 + minute / 60, minute % 60])
	if hotel.has_method("set_clock"):
		hotel.set_clock(20 * 60 + minute)


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
		_finish({"outcome": "lost", "crew": [], "best": {}, "worst": {}})
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
	LGPlaytest.moment("job_" + str(report.get("outcome", "")), {"clock": report.get("clock", ""), "heat_peak": report.get("heat_peak", 0)})
	report_card.show_report(report, me.id)


func _write(r: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var path := "%s/gala-%s.json" % [OUT_DIR, Time.get_datetime_string_from_system(true).replace(":", "-")]
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
	var sheet := Cast.sheet(char_id)
	if sheet == null or not LGVoice.is_ready():
		return
	LGVoice.hush(_replay_player)
	LGVoice.say(text, sheet.voice, _replay_player, sheet.voice_speed)


func _again() -> void:
	get_tree().paused = false
	if net.lan:
		_on_quit()
		return
	LGScenes.change_scene(SCENE)


func _on_quit() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if net.lan:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	LGScenes.change_scene(TITLE)


func _on_quit_game() -> void:
	LGScenes.quit()

#endregion


func _crew(id: int) -> CrewInfo:
	for c in crew:
		if c.id == id:
			return c
	return null
