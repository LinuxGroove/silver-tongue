class_name Character
extends Node3D
## One of the gala's cast: a [Person] with a [Face], a [CharacterSheet], a
## voice and a radio, and, on the host, a mind: what they've heard and seen
## tonight (the history the model reads), and per crew member a face (see
## [method JobRules.new_face]) with suspicion, beliefs, checks and papers.
## The [Job] tells them what they heard and saw; they think through the
## job's one [BrainQueue] (or [ScriptedBrain] with no model), the rules
## decide what happens, and the job carries it out.
##
## On a guest's device a character is a puppet: it stands, walks and plays
## clips as the host's snapshots say, and speaks the lines the host sends.

## A line said out loud (on the host). `radio_to` is the character on the
## other end of the radio, or null.
signal spoke(character: Character, text: String, tone: String, radio_to: Character)
## A turn is done: its record (see [member turns]).
signal thought(character: Character, turn: Dictionary)

const WALK_SPEED := 1.3
## Seconds they keep turned to someone after that person's last line.
const ATTEND := 9.0
const SEE_RANGE := 12.0
## How far round they see: the cosine of the angle off straight ahead.
const SEE_COS := -0.2
## Radio calls wait this long for an answer.
const RADIO_WAIT := 1.6

var sheet: CharacterSheet
var job: Job
var person: Person
var face: Face
var voice_player: AudioStreamPlayer3D
var radio_player: AudioStreamPlayer3D
var body: StaticBody3D
## crew id -> face (see [method JobRules.new_face]).
var faces := {}
## The night as the model sees it (see [CharacterPrompt]).
var history: Array = []
## One record per turn: kind, subject, what was said and heard, the reply
## as the rules left it, suspicion before and after, and the timings.
var turns: Array = []
var busy := false
var puppet := false
## Minds the security office (a Halberd guard standing in for a post).
var minding := false
## The crew member on the phone with them (0 for nobody).
var on_call := 0
## The spot they belong at now ("" when walking somewhere for a reason).
var post := ""
var walking := false
var rng := RandomNumberGenerator.new()
var _path: Array = []
var _path_doors: Array = []
var _opened: Array = []
var _arrive := Transform3D.IDENTITY
var _attend: Node3D
var _attend_t := 0.0
var _idle := "Idle"
var _mood_t := 0.0
var _clip_hold := ""
var _lines: Array[LGVoiceLine] = []
var _ticket := 0
var _serving := 0


static func make(p_sheet: CharacterSheet, p_job: Job = null) -> Character:
	var c := Character.new()
	c.name = p_sheet.id.capitalize()
	c.sheet = p_sheet
	c.job = p_job
	c.post = p_sheet.spot
	c.rng.seed = p_sheet.seed
	return c


func _ready() -> void:
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
	add_child(voice_player)
	radio_player = AudioStreamPlayer3D.new()
	radio_player.name = "Radio"
	radio_player.position = Vector3(0.18, 1.4, 0.05)
	radio_player.unit_size = 2.0
	radio_player.max_distance = 12.0
	radio_player.volume_db = -6.0
	add_child(radio_player)
	body = StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = Kit.LAYER_PEOPLE
	body.collision_mask = 0
	body.set_meta("character", sheet.id)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	add_child(body)


## Where their ears are, and their eyes.
func ear() -> Vector3:
	return global_position + Vector3(0, 1.6, 0)


func forward() -> Vector3:
	return global_transform.basis.z.normalized()


func face_of(crew_id: int) -> Dictionary:
	if not faces.has(crew_id):
		faces[crew_id] = JobRules.new_face(sheet, job.heat.level if job else Heat.CALM)
		if job:
			job.new_face(self, crew_id, faces[crew_id])
	return faces[crew_id]


func suspicion_of(crew_id: int) -> int:
	return int(faces[crew_id].suspicion) if faces.has(crew_id) else sheet.start_suspicion


func is_speaking() -> bool:
	for l in _lines:
		if l.state in ["asked", "playing"]:
			return true
	return false


#region Hearing, seeing, thinking (host)

## A crew member said something this character heard. `addressed`: it was
## said to them; otherwise it's overheard, and they think only when `hot`.
func hear(crew_id: int, said: String, heard: String, how: String, distance: float, voice: String, addressed: bool, hot := false, through_wall := false) -> void:
	var who: String = job.describe_to(crew_id, self) if job else "someone"
	var f := face_of(crew_id)
	f["met"] = true
	if heard == "":
		if addressed and how != "none":
			_say(_pick(sheet.not_heard), "calm")
		return
	history.append({"who": "crew", "text": CharacterPrompt.crew_line(_clock(), who, heard, distance, voice, how, addressed, through_wall)})
	if addressed:
		f["turns"] = int(f.turns) + 1
		attend(job.crew_node(crew_id) if job else null)
		_think(crew_id, {"kind": "line", "said": said, "heard": heard, "how": how, "distance": distance, "voice": voice})
	elif hot:
		_think(crew_id, {"kind": "overheard", "said": said, "heard": heard, "how": how, "distance": distance, "voice": voice})


## Something happened that they notice and think about. `kind` is for the
## scripted brain ("event", "seen", "papers", "question", "answer").
func event(text: String, crew_id := 0, kind := "event", extra := {}) -> void:
	history.append({"who": "event", "text": CharacterPrompt.event_line(_clock(), text)})
	var turn := {"kind": kind, "said": "", "heard": text}
	turn.merge(extra)
	_think(crew_id, turn)


## Something they know now, without stopping to think about it.
func note(text: String) -> void:
	history.append({"who": "event", "text": CharacterPrompt.event_line(_clock(), text)})


func _think(crew_id: int, turn: Dictionary) -> void:
	var ticket := _ticket
	_ticket += 1
	while busy or ticket != _serving:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	busy = true
	# A newer line for this character is waiting: it answers both.
	if str(turn.kind) in ["line", "overheard"] and _ticket > ticket + 1:
		turn["merged"] = true
		_done(turn)
		return
	turn["subject"] = crew_id
	turn["clock"] = _clock()
	var f: Dictionary = face_of(crew_id) if crew_id != 0 else {"suspicion": sheet.start_suspicion, "turns": 0, "believes": [], "checks": {}, "papers": "", "opened": [], "secrets": []}
	turn["before"] = int(f.suspicion)
	var reply := {}
	turn["scripted"] = true
	turn["strict"] = false
	turn["thought"] = 0.0
	if job and job.brains and LGBrain.is_ready():
		var mind := bool(LGSettings.get_value("voice", "mind_language", false))
		CharacterPrompt.trim(history)
		var res: Dictionary = await job.queue.ask(CharacterPrompt.messages(sheet, history, mind), ReplySchema.schema(sheet.actions))
		if not is_inside_tree():
			return
		turn["thought"] = float(res.seconds)
		turn["prompt_tokens"] = int(res.prompt_tokens)
		turn["cached_tokens"] = int(res.cached_tokens)
		turn["timed_out"] = bool(res.timed_out)
		if res.ok:
			reply = ReplySchema.parse(str(res.text), sheet.actions)
			turn["strict"] = ReplySchema.is_strict(str(res.text), sheet.actions)
			turn["scripted"] = reply.is_empty()
	if reply.is_empty():
		reply = ScriptedBrain.reply(sheet, f, turn, rng)
	# A radio answer is words only: what happens is the asker's business.
	if str(turn.kind) == "question":
		reply["do"] = "none"
		reply["suspicion"] = int(f.suspicion)
	var ctx: Dictionary = job.context_for(self, crew_id) if job and crew_id != 0 else {}
	var out := JobRules.resolve(reply, f, sheet, ctx, rng)
	if crew_id != 0:
		JobRules.apply(out, f)
	history.append({"who": "character", "text": CharacterPrompt.reply_text(out)})
	turn["reply"] = out
	turn["after"] = int(f.suspicion)
	turn["vetoed"] = str(out.vetoed)
	_mood(str(out.tone))
	var radio_to: Character = turn.get("radio_to")
	_say(str(out.say), str(out.tone), radio_to)
	if crew_id != 0:
		for i in JobRules.newly_open(f, sheet):
			note("You've warmed to %s. If they ask, you'd tell them: %s" % [job.describe(crew_id) if job else "them", sheet.secrets[i].text])
	_done(turn)
	if job:
		job.on_reply(self, crew_id, turn, out)


func _done(turn: Dictionary) -> void:
	turn.erase("radio_to")
	turns.append(turn)
	busy = false
	_serving += 1
	thought.emit(self, turn)


## Says a line: emitted for the job to route to whoever's in earshot.
func _say(text: String, tone := "calm", radio_to: Character = null) -> void:
	if text.strip_edges() == "":
		return
	spoke.emit(self, text, tone, radio_to)


## Says a scripted line (chatter, a radio call) as if they'd thought it.
func say_scripted(text: String, radio_to: Character = null) -> void:
	note("You said: \"%s\"" % text)
	_say(text, "calm", radio_to)


## Looks for crew members in front of them with nothing in the way:
## {crew id: distance} of those seen.
func look(crew: Array, space: PhysicsDirectSpaceState3D) -> Dictionary:
	var seen := {}
	var eye := global_position + Vector3(0, 1.62, 0)
	var fwd := forward()
	for c in crew:
		var n: Node3D = c.node
		if n == null or c.held:
			continue
		var head: Vector3 = n.global_position + Vector3(0, 1.55, 0)
		var to := head - eye
		var d := to.length()
		if d > SEE_RANGE or d < 0.01:
			continue
		var flat := Vector3(to.x, 0, to.z).normalized()
		if d > 2.0 and flat.dot(fwd) < SEE_COS:
			continue
		var q := PhysicsRayQueryParameters3D.create(eye, head, Kit.LAYER_SOLID)
		if not space.intersect_ray(q).is_empty():
			continue
		seen[c.id] = d
	return seen

#endregion

#region Body, voice and walking (every device)

## Turns to face someone for a while.
func attend(n: Node3D) -> void:
	if n:
		_attend = n
		_attend_t = ATTEND


## Plays a line here, from their mouth or their radio, with the mouth
## moving. Returns the line (or null with no voice).
func speak_local(text: String, on_radio := false, voice_on := true) -> LGVoiceLine:
	if not voice_on or not LGVoice.is_ready():
		return null
	var player := radio_player if on_radio else voice_player
	var voice := sheet.voice
	var line := LGVoice.say(Language.clean(text), voice, player, sheet.voice_speed)
	if not on_radio:
		_lines.append(line)
	return line


## The talking clip while their voice plays (on every device that hears it).
func _process(delta: float) -> void:
	var level := 0.0
	for l in _lines:
		if l.is_playing():
			level = maxf(level, l.level)
	_lines = _lines.filter(func(l): return l.state in ["asked", "playing"])
	face.level = level
	if puppet:
		return
	if walking:
		_walk(delta)
	elif _attend and _attend_t > 0.0:
		_attend_t -= delta
		var to := _attend.global_position - global_position
		to.y = 0.0
		if to.length() > 0.4 and to.length() < 8.0:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 3.0))
	elif post != "" and job:
		var spot: Transform3D = job.spot(post)
		var yaw := atan2(spot.basis.z.x, spot.basis.z.z)
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-delta * 1.5))
	if _mood_t > 0.0:
		_mood_t -= delta
	if not walking:
		if _clip_hold != "":
			person.play(_clip_hold)
		elif is_speaking():
			person.play("Idle_Talking")
		elif _mood_t <= 0.0:
			person.play(_idle)


## Holds a clip (the radio, a gesture) until it's cleared with "".
func hold_clip(clip: String) -> void:
	_clip_hold = clip


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


## Walks to a spot through the venue's points, opening doors on the way.
func walk_to(spot_name: String) -> void:
	if job == null:
		return
	var route: Dictionary = job.route(global_position, spot_name)
	_path = route.points
	_path_doors = route.doors
	_arrive = job.spot(spot_name)
	post = spot_name
	walking = not _path.is_empty()
	if walking:
		person.play("Walk")
	else:
		global_transform = Transform3D(_arrive.basis, _arrive.origin)


func _walk(delta: float) -> void:
	if _path.is_empty():
		walking = false
		for d in _opened:
			if job.door_can_close(d):
				d.close()
		_opened.clear()
		return
	var target: Vector3 = _path[0]
	var door: String = _path_doors[0]
	if door != "" and job.venue.doors.has(door):
		var hd = job.venue.doors[door]
		if not hd.is_open:
			job.open_door(door, global_position)
			_opened.append(hd)
	# Up and down (stairs, a gangway) follows the line between two points; a
	# link straight up (a lift) is ridden in a step.
	var rise := target.y - global_position.y
	var to := target - global_position
	to.y = 0.0
	var step := WALK_SPEED * delta
	if to.length() <= step:
		global_position = target
		_path.pop_front()
		_path_doors.pop_front()
		# Doors behind them shut once they're through.
		if door == "" and not _opened.is_empty():
			for d in _opened:
				if job.door_can_close(d):
					d.close()
			_opened.clear()
		if _path.is_empty():
			walking = false
			global_transform = Transform3D(_arrive.basis, _arrive.origin)
			for d in _opened:
				if job.door_can_close(d):
					d.close()
			_opened.clear()
			person.play(_idle)
		return
	global_position += to.normalized() * step + Vector3(0, rise * step / to.length(), 0)
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 8.0))
	person.play("Walk")


## Where they are and what they're doing, for guests' devices.
func snapshot() -> Array:
	return [global_position, rotation.y, person.current()]


func apply_snapshot(s: Array, delta: float) -> void:
	var at: Vector3 = s[0]
	if global_position.distance_to(at) > 3.0:
		global_position = at
	else:
		global_position = global_position.lerp(at, 1.0 - exp(-delta * 12.0))
	rotation.y = lerp_angle(rotation.y, float(s[1]), 1.0 - exp(-delta * 12.0))
	var clip := str(s[2])
	if clip != "" and not is_speaking():
		person.play(clip)
	elif is_speaking():
		person.play("Idle_Talking")

#endregion


func _clock() -> String:
	return job.clock_text() if job else "8:45 pm"


func _pick(lines: Array[String]) -> String:
	if lines.is_empty():
		return ""
	return lines[rng.randi() % lines.size()]
