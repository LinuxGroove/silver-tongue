class_name Job
extends Node
## The gala on the host: the clock and the night's routine, who hears what
## the crew says (and who it's said to), what the characters see, checks
## over the radio, the doors, heat, the security office, and the end. The
## characters think; the job carries out what the rules let them do. It
## knows nothing of the network: the scene hands it the crew's lines and
## uses, and passes on what it emits.
##
## The hotel is a [Meridian] (or anything with the same `spots`, `points`,
## `links`, `doors` and `zone_at()`, as the tests' stub has).

## A character said something: every device plays it from them (and, on the
## radio, from the nearest radio to its player).
signal line_out(char_id: String, text: String, tone: String, radio: bool)
## A crew member said something: crewmates in earshot (or anywhere, on the
## earpiece) see it.
signal crew_line_out(crew_id: int, text: String, voice: String, earpiece: bool)
## Something to tell one crew member (0: all of them).
signal toast_for(crew_id: int, text: String)
signal heat_changed(level: int)
## A crew member's outfit, held or inside changed.
signal crew_changed(crew_id: int)
signal door_changed(door_name: String, is_open: bool, locked: bool)
## What a character makes of a crew member now.
signal faced(crew_id: int, char_id: String, suspicion: int)
## A game minute went by.
signal clock_changed(minute: int)
signal ended(report: Dictionary)

## The clock, in minutes past eight: the start, the doors shut, the speech.
const START := 45.0
const SHUT := 80.0
const SPEECH := 90.0
const SECONDS_PER_MINUTE := 16.0
## Seconds a door stays open for someone a character let through.
const OPEN_FOR := 25.0
## Game minutes from the whole crew being held to the police taking them.
const POLICE := 3.0
const LOOK_EVERY := 0.5
## A murmur into the earpiece is noticed from this close.
const EARPIECE_NOTICE := 1.5
## A wall or a shut door between: distance counts this much more.
const THROUGH_WALL := 2.2
const KITCHEN_CODE := "4471"
## Who goes where, and when (minutes past eight).
const ROUTINE := [
	[50.0, "okafor", "okafor_stage"],
	[56.0, "okafor", "okafor"],
	[60.0, "marcus", "smoke"],
	[65.0, "celeste", "celeste_in"],
	[65.0, "hugo", "hugo_in"],
	[70.0, "marcus", "marcus"],
	[78.0, "okafor", "okafor_stage"],
]
## What each character's way in does, said to the crew member it's for.
const OPENED := {
	"let_through": "%s lets you through.",
	"escort_in": "%s is taking you into the ballroom himself. Stay with him.",
	"add_to_list": "%s has put your name on the guest list.",
	"book_visit": "%s has booked your visit. The service door will know.",
	"put_to_work": "%s has put you to work. The pass is open to you.",
	"plus_one": "%s will take you in as a plus-one at 9:05. Stay close.",
	"release": "%s lets you go.",
}

var hotel: Node3D
var crew: Array[CrewInfo] = []
## id -> Character.
var cast := {}
var heat := Heat.new()
var queue: BrainQueue
## Think with the model when it's ready (off: scripted replies only).
var brains := true
var minutes := START
var elapsed := 0.0
var done := false
## The night waits (for the crew's other devices to arrive).
var hold := false
var listed: Array[int] = []
var booked: Array[int] = []
var hired: Array[int] = []
var escorted: Array[int] = []
## crew id -> the guest taking them in.
var plus_ones := {}
var keypad_used := false
## Every crew line, in order: {"t", "crew", "text", "voice", "to", "earpiece"}.
var lines: Array = []
var rng := RandomNumberGenerator.new()
var _held_by := {}
var _ever_held := {}
var _police_at := -1.0
var _open := {}
var _look_t := 0.0
var _fired := {}
## "char|crew" -> what that crew member told them.
var _told := {}
var _minute := int(START)
var _shut := false


## Sets the night up in a hotel already in the tree: the cast at their
## spots, the doors as they start, and the crew (whose `node`s the scene
## sets).
func setup(p_hotel: Node3D, p_crew: Array[CrewInfo], seed := 0) -> void:
	hotel = p_hotel
	crew = p_crew
	rng.seed = seed if seed != 0 else randi()
	queue = BrainQueue.new()
	queue.name = "Brains"
	add_child(queue)
	for sheet in Cast.all():
		var ch := Character.make(sheet, self)
		hotel.add_child(ch)
		ch.global_transform = spot(sheet.spot)
		ch.spoke.connect(_on_spoke)
		cast[sheet.id] = ch
	for n in hotel.doors:
		var d = hotel.doors[n]
		d.opened.connect(_on_door.bind(n))
		d.closed.connect(_on_door.bind(n))
	for n in ["ballroom", "service", "pass", "loading"]:
		_lock(n, true)
	for n in ["office", "staff"]:
		_lock(n, false)
	if hotel.doors.has("front") and hotel.doors.front.get("auto") != true:
		_set_door("front", true)


func crew_by_id(id: int) -> CrewInfo:
	for c in crew:
		if c.id == id:
			return c
	return null


func crew_node(id: int) -> Node3D:
	var c := crew_by_id(id)
	return c.node if c else null


## How the characters see a crew member: "a man in a black dinner suit".
func describe(id: int) -> String:
	var c := crew_by_id(id)
	return Covers.describe(c.outfit, c.female) if c else "someone"


func clock_text() -> String:
	var m := int(minutes)
	return "%d:%02d pm" % [8 + m / 60, m % 60]


func spot(spot_name: String) -> Transform3D:
	return hotel.spots.get(spot_name, Transform3D.IDENTITY)


## What the rules need to know about a character and a crew member.
func context_for(ch: Character, crew_id: int) -> Dictionary:
	var c := crew_by_id(crew_id)
	return {
		"heat": heat.level, "held": c.held if c else false, "someone_held": not _held_by.is_empty(),
		"minding": ch.minding, "shut": _shut and ch.sheet.id == "teo",
	}


#region The crew's lines

## A crew member said something (heard by their device, or typed). It
## reaches every character in earshot; the one they're facing and nearest
## to answers, and the rest only think on a hot word.
func crew_said(crew_id: int, text: String, voice := "normal", earpiece := false) -> void:
	var c := crew_by_id(crew_id)
	text = text.strip_edges()
	if c == null or c.node == null or done or text == "":
		return
	crew_line_out.emit(crew_id, text, voice, earpiece)
	var entry := {"t": elapsed, "clock": clock_text(), "crew": crew_id, "text": text, "voice": voice, "to": "", "earpiece": earpiece}
	lines.append(entry)
	var mouth := c.mouth()
	if earpiece:
		for ch in cast.values():
			var f: Dictionary = ch.face_of(crew_id)
			if ch.ear().distance_to(mouth) <= EARPIECE_NOTICE and not bool(f.earpiece):
				f["earpiece"] = true
				JobRules.nudge(f, 1)
				heat.bump(Heat.EARPIECE)
				ch.event("%s mutters something to nobody, a hand to their ear." % describe(crew_id).capitalize(), crew_id)
		return
	if voice == "shout":
		heat.bump(Heat.SHOUT)
	var space := _space()
	var hearers: Array = []
	for ch in cast.values():
		var d: float = ch.ear().distance_to(mouth)
		var wall := false
		if space and d > 0.5:
			var q := PhysicsRayQueryParameters3D.create(mouth, ch.ear(), Kit.LAYER_SOLID)
			wall = not space.intersect_ray(q).is_empty()
		if wall:
			d *= THROUGH_WALL
		var h := Earshot.hear(text, d, voice, rng)
		if float(h.clarity) < Earshot.NOTHING:
			continue
		hearers.append({"ch": ch, "d": d, "wall": wall, "hearing": h})
	var to := addressed(c, hearers)
	if to:
		entry["to"] = to.sheet.id
	var hot := ScriptedBrain._hot(" " + text.to_lower() + " ")
	for h in hearers:
		var ch: Character = h.ch
		var hearing: Dictionary = h.hearing
		if ch == to and str(hearing.heard) != "":
			var key := "%s|%d" % [ch.sheet.id, crew_id]
			_told[key] = str(_told.get(key, "")) + " " + str(hearing.heard)
		ch.hear(crew_id, text, str(hearing.heard), str(hearing.how), float(h.d), voice, ch == to, hot, bool(h.wall))


## Who a line is said to, of those who heard it clearly enough: the one
## the speaker faces, nearest first; with nobody faced, whoever is right
## next to them; nobody when a crewmate is in front and nearer.
func addressed(c: CrewInfo, hearers: Array) -> Character:
	var mouth := c.mouth()
	var fwd := c.facing()
	var best: Character = null
	var best_score := -INF
	var best_d := INF
	for h in hearers:
		if float(h.hearing.clarity) < 0.5:
			continue
		var ch: Character = h.ch
		var to := ch.ear() - mouth
		to.y = 0.0
		var d := to.length()
		var dot := fwd.dot(to.normalized()) if d > 0.05 else 1.0
		if dot > 0.45 and d < 6.0:
			var score := dot * 2.0 - d * 0.35
			if score > best_score:
				best = ch
				best_score = score
				best_d = d
	if best == null:
		for h in hearers:
			var ch: Character = h.ch
			var d := Vector2(ch.ear().x - mouth.x, ch.ear().z - mouth.z).length()
			if d < 2.5 and d < best_d and float(h.hearing.clarity) >= 0.5:
				best = ch
				best_d = d
	if best == null:
		return null
	for other in crew:
		if other == c or other.held or other.node == null:
			continue
		var to := other.position() - mouth
		to.y = 0.0
		if to.length() < best_d and to.length() < 4.0 and fwd.dot(to.normalized()) > 0.7:
			return null
	return best

#endregion

#region What the crew does

## A crew member used something: "door:<name>", "jackets", or
## "character:<id>" (showing them the invitation). Returns what to tell
## them ("" for nothing).
func use(crew_id: int, what: String) -> String:
	var c := crew_by_id(crew_id)
	if c == null or done:
		return ""
	if c.held:
		return "The door's locked. Someone's outside it." if what == "door:office" else ""
	if what == "jackets":
		if c.outfit == "waiter_jacket":
			c.outfit = str(Covers.ALL[c.cover].outfit)
			crew_changed.emit(crew_id)
			return "You hang the jacket back up."
		c.outfit = "waiter_jacket"
		crew_changed.emit(crew_id)
		return "You put on a waiter's jacket."
	if what.begins_with("character:"):
		var ch: Character = cast.get(what.trim_prefix("character:"))
		if ch and c.has_invitation:
			show_papers(crew_id, ch)
			return ""
		return ""
	if not what.begins_with("door:"):
		return ""
	var door_name := what.trim_prefix("door:")
	var d = hotel.doors.get(door_name)
	if d == null:
		return ""
	match door_name:
		"front":
			return ""
		"ballroom":
			if d.is_open:
				return ""
			return "The doors are shut for the speech." if _shut else "Teo's on the doors."
		"service":
			if d.is_open:
				return ""
			return "It's locked. There's a keypad by it."
		"pass":
			if d.is_open:
				return ""
			if c.outfit == "waiter_jacket" or crew_id in hired:
				_open_for("pass", OPEN_FOR * 0.5)
				return ""
			return "The waiters' door. You don't look like a waiter."
		"loading":
			return "It's bolted from outside."
	if d.locked:
		return "It's locked."
	_set_door(door_name, not d.is_open)
	return ""


## The kitchen keypad. Returns what to tell them.
func keypad(crew_id: int, code: String) -> String:
	var c := crew_by_id(crew_id)
	if c == null or c.held or done:
		return ""
	if heat.level >= Heat.LOCKDOWN:
		return "The keypad's dead. The building's locked down."
	if code != KITCHEN_CODE:
		return "Wrong code."
	keypad_used = true
	_open_for("service", OPEN_FOR * 0.5)
	var space := _space()
	for ch in cast.values():
		if not (ch.sheet.staff or ch.sheet.halberd) or space == null:
			continue
		if ch.look([c], space).has(crew_id):
			JobRules.nudge(ch.face_of(crew_id), 2)
			heat.bump(Heat.KEYPAD_SEEN)
			ch.event("You saw %s punch a code into the service door's keypad." % describe(crew_id), crew_id, "seen")
	return "The lock clicks."


## Shows a character the forged invitation: a glance passes it, a close
## look (anyone already suspicious) doesn't.
func show_papers(crew_id: int, ch: Character) -> void:
	var c := crew_by_id(crew_id)
	if c == null or not c.has_invitation:
		return
	var f := ch.face_of(crew_id)
	f["met"] = true
	f["turns"] = int(f.turns) + 1
	ch.attend(c.node)
	var named := "an invitation to the gala in the name of %s" % c.cover_name
	if int(f.suspicion) <= JobRules.TRUST:
		f["papers"] = "passed"
		ch.event("%s shows you %s. It looks right." % [describe(crew_id).capitalize(), named], crew_id, "papers")
	else:
		f["papers"] = "copy"
		JobRules.nudge(f, 2)
		ch.event("%s shows you %s. You look closely: the card's too thin and the crest is printed, not embossed. It's a copy." % [describe(crew_id).capitalize(), named], crew_id, "papers")
	faced.emit(crew_id, ch.sheet.id, int(f.suspicion))

#endregion

#region What the characters do

## A character finished a turn: carry out what the rules let them do.
func on_reply(ch: Character, crew_id: int, turn: Dictionary, out: Dictionary) -> void:
	if done:
		return
	var c := crew_by_id(crew_id)
	if c:
		faced.emit(crew_id, ch.sheet.id, ch.suspicion_of(crew_id))
	if str(turn.get("kind", "")) == "question":
		_answer(ch, crew_id, turn, out)
		return
	if c == null:
		return
	var act := str(out.get("do", "none"))
	var who := ch.sheet.name
	match act:
		"let_through":
			if ch.sheet.id == "teo":
				_open_for("ballroom", OPEN_FOR)
			else:
				_open_for("service", OPEN_FOR)
			toast_for.emit(crew_id, OPENED[act] % who)
		"escort_in":
			if not crew_id in escorted:
				escorted.append(crew_id)
			_open_for("ballroom", OPEN_FOR * 1.5)
			ch.walk_to("okafor_stage")
			toast_for.emit(crew_id, OPENED[act] % who)
		"add_to_list":
			if not crew_id in listed:
				listed.append(crew_id)
			toast_for.emit(crew_id, OPENED[act] % who)
		"book_visit":
			if not crew_id in booked:
				booked.append(crew_id)
			toast_for.emit(crew_id, OPENED[act] % who)
		"put_to_work":
			if not crew_id in hired:
				hired.append(crew_id)
			if c.outfit != "waiter_jacket":
				c.outfit = "waiter_jacket"
				crew_changed.emit(crew_id)
			toast_for.emit(crew_id, OPENED[act] % who)
		"plus_one":
			plus_ones[crew_id] = ch.sheet.id
			toast_for.emit(crew_id, OPENED[act] % who)
		"release":
			if c.held:
				_release(crew_id, ch)
			else:
				for id in _held_by.keys():
					if _held_by[id] == ch.sheet.id:
						_release(id, ch)
		"radio_security":
			_hold(crew_id, ch)
		"ask_reception", "call_manager":
			_check(ch, crew_id, act)
		"ask_for_invitation":
			if c.has_invitation:
				toast_for.emit(crew_id, "Show the invitation: Interact, facing him.")


## A check: the character radios a colleague, who answers from what they
## know (the game's facts, and anything the crew told them), and then the
## character makes up their mind.
func _check(asker: Character, crew_id: int, act: String) -> void:
	var target: Character = cast.get(str(asker.sheet.checks_with.get(act, "")))
	if target == null:
		return
	var claim := _claim(asker, crew_id)
	var fact := lookup(target.sheet.id, crew_id, asker)
	asker.hold_clip("Idle_TalkingPhone")
	asker.say_scripted("%s, it's %s. I've got %s here: %s. Does that check out?" % [_first(target), _first(asker), describe(crew_id), claim], target)
	await get_tree().create_timer(Character.RADIO_WAIT).timeout
	if done or not is_inside_tree():
		asker.hold_clip("")
		return
	target.event("On the radio, %s asks about %s: %s. What you know: %s" % [asker.sheet.name, describe(crew_id), claim, fact.text], crew_id, "question", {
		"answer": fact.answer, "radio_to": asker, "asker": asker.sheet.id, "verdict": fact.verdict, "check": act,
	})


func _answer(target: Character, crew_id: int, turn: Dictionary, out: Dictionary) -> void:
	var asker: Character = cast.get(str(turn.get("asker", "")))
	if asker == null:
		return
	var said := str(out.get("say", ""))
	if said == "":
		said = str(turn.get("answer", ""))
		target.say_scripted(said, asker)
	await get_tree().create_timer(0.8 + said.split(" ").size() * 0.32).timeout
	asker.hold_clip("")
	if done or not is_inside_tree():
		return
	var verdict := str(turn.get("verdict", "bad"))
	asker.face_of(crew_id)["checks"][str(turn.get("check", ""))] = verdict
	asker.event("On the radio, %s answers: \"%s\" %s" % [target.sheet.name, said, "So it checks out." if verdict == "good" else "So it doesn't check out."], crew_id, "answer", {"verdict": verdict})


## What a colleague knows about a crew member, from the game's facts and
## what that member told the one asking: {"verdict" ("good"/"bad"), "text"
## (for the colleague's brain), "answer" (a line, with no model)}.
func lookup(who: String, crew_id: int, asker: Character) -> Dictionary:
	var said := (str(_told.get("%s|%d" % [asker.sheet.id, crew_id], "")) + " " + " ".join(asker.face_of(crew_id).believes)).to_lower()
	match who:
		"dana":
			if crew_id in listed:
				return _fact("good", "You put them on the guest list yourself tonight.", "Yes, they're on the list. I added them myself.")
			if crew_id in booked:
				return _fact("good", "You booked their visit yourself tonight.", "Yes, I booked them in tonight.")
			for surname in Cast.GUEST_LIST:
				if said.contains(surname):
					if surname == "halvorsen":
						return _fact("good", Cast.GUEST_LIST[surname] + ".", "Felix Halvorsen? He's on the list. Not checked in yet.")
					return _fact("bad", Cast.GUEST_LIST[surname] + ", so this isn't them.", "The %ss? They checked in an hour ago." % surname.capitalize())
			if _any(said, ["agency", "staffing", "temp"]):
				return _fact("good", "Caldera Staffing is sending temps to the kitchen tonight.", "Caldera Staffing? Yes, the kitchen's expecting temps.")
			if _any(said, ["freezer", "facilit", "engineer", "repair", "maintenance"]):
				return _fact("bad", "You've asked twice this week for the freezer to be fixed, but nobody's booked for tonight.", "Nobody's booked for the freezer tonight. Not through me.")
			if _any(said, ["press", "courier", "writer", "journalist"]):
				return _fact("bad", "There's no press on tonight's list.", "There's no press on my list.")
			return _fact("bad", "They're not on the guest list and you haven't booked anyone like them.", "Nobody like that on my list.")
		"okafor":
			var of: Dictionary = cast["okafor"].faces.get(crew_id, {})
			if "escort_in" in of.get("opened", []):
				return _fact("good", "You're taking them in yourself.", "Yes, they're with me.")
			if _any(said, ["halvorsen", "nephew"]):
				return _fact("good", "You've never met Felix Halvorsen, the owner's nephew, and you dread offending the family.", "If he's Mr Halvorsen's nephew, let him in! Please!")
			if bool(of.get("met", false)) and int(of.get("suspicion", 2)) <= JobRules.TRUST:
				return _fact("good", "You've met them tonight; they seemed fine.", "I've met them. They're fine.")
			return _fact("bad", "You've never met them.", "I don't know who that is.")
	return _fact("bad", "You don't know them.", "No idea.")


static func _fact(verdict: String, text: String, answer: String) -> Dictionary:
	return {"verdict": verdict, "text": text, "answer": answer}


static func _any(text: String, words: Array) -> bool:
	for w in words:
		if text.contains(w):
			return true
	return false


## What a character would say a crew member claims, on the radio.
func _claim(ch: Character, crew_id: int) -> String:
	var b: Array = ch.face_of(crew_id).believes
	if b.is_empty():
		return "won't say much"
	return "; ".join(b.slice(0, 3))


static func _first(ch: Character) -> String:
	return ch.sheet.name


## Takes a crew member to the security office, minded by a Halberd guard.
func _hold(crew_id: int, by: Character) -> void:
	var c := crew_by_id(crew_id)
	if c == null or c.held:
		return
	c.held = true
	c.inside = false
	_ever_held[crew_id] = true
	heat.bump(Heat.CAUGHT)
	var guard: Character = null
	for id in _held_by.values():
		guard = cast[id]
	if guard == null:
		var best := INF
		for ch in cast.values():
			if ch.sheet.halberd:
				var d: float = ch.global_position.distance_to(by.global_position)
				if d < best:
					best = d
					guard = ch
	if guard == null:
		guard = by
	_held_by[crew_id] = guard.sheet.id
	if not guard.minding:
		guard.minding = true
		guard.walk_to("office_guard")
	_set_door("office", false)
	_lock("office", true)
	guard.note("You're minding the security office: %s is held inside until the police decide what to do. Let them go only if you're sure it was a mistake." % describe(crew_id))
	for ch in cast.values():
		if ch.sheet.radio and ch != guard:
			ch.note("On the radio: security has %s in the office." % describe(crew_id))
	toast_for.emit(crew_id, "%s called security. You're held in the security office." % by.sheet.name)
	for other in crew:
		if other.id != crew_id:
			toast_for.emit(other.id, "%s is held in the security office." % c.name)
	crew_changed.emit(crew_id)
	_check_end()


func _release(crew_id: int, by: Character) -> void:
	var c := crew_by_id(crew_id)
	if c == null or not c.held:
		return
	c.held = false
	_held_by.erase(crew_id)
	if _held_by.is_empty():
		_lock("office", false)
		_open_for("office", OPEN_FOR)
		by.minding = false
		by.walk_to(by.sheet.spot if not (by.sheet.id == "marcus" and minutes >= 60.0 and minutes < 70.0) else "smoke")
	for ch in cast.values():
		if ch.sheet.radio:
			ch.note("On the radio: %s let %s go." % [by.sheet.name, describe(crew_id)])
	toast_for.emit(crew_id, OPENED["release"] % by.sheet.name)
	crew_changed.emit(crew_id)


## A character said a line: out to every device, and to the other radios.
func _on_spoke(ch: Character, text: String, tone: String, radio_to: Character) -> void:
	line_out.emit(ch.sheet.id, text, tone, radio_to != null)
	if radio_to == null:
		return
	for other in cast.values():
		if other != ch and other.sheet.radio:
			other.note("On the radio, %s: \"%s\"" % [ch.sheet.name, text])

#endregion

#region The night

func _process(delta: float) -> void:
	if done or hotel == null or hold:
		return
	elapsed += delta
	minutes += delta / SECONDS_PER_MINUTE
	if int(minutes) != _minute:
		_minute = int(minutes)
		clock_changed.emit(_minute)
	_routine()
	for n in _open.keys():
		_open[n] = float(_open[n]) - delta
		if float(_open[n]) <= 0.0:
			_open.erase(n)
			_set_door(n, false)
	_look_t -= delta
	if _look_t <= 0.0:
		_look_t = LOOK_EVERY
		_look()
	var sus: Array = []
	for ch in cast.values():
		var top := 0
		for id in ch.faces:
			var c := crew_by_id(id)
			if c == null or c.held:
				continue
			if JobRules.drift(ch.faces[id], ch.sheet, delta):
				faced.emit(id, ch.sheet.id, int(ch.faces[id].suspicion))
			top = maxi(top, int(ch.faces[id].suspicion))
		sus.append(top)
	var was := heat.level
	if heat.update(delta, Heat.points(sus)):
		_on_heat(was, heat.level)
	for c in crew:
		var inside: bool = not c.held and c.node != null and hotel.zone_at(c.position()) == "ballroom"
		if inside != c.inside:
			c.inside = inside
			crew_changed.emit(c.id)
			if inside:
				toast_for.emit(c.id, "You're in the ballroom.")
	_check_end()
	if not done and minutes >= SPEECH:
		_end("in" if crew.any(func(c): return c.inside) else "late")


func _routine() -> void:
	for i in ROUTINE.size():
		var r: Array = ROUTINE[i]
		if _fired.has("r%d" % i) or minutes < float(r[0]):
			continue
		_fired["r%d" % i] = true
		var ch: Character = cast.get(r[1])
		if ch == null or ch.minding or (ch.sheet.id == "okafor" and minutes < 60.0 and not escorted.is_empty()):
			continue
		if str(r[1]) in ["celeste", "hugo"]:
			_go_in(ch)
		ch.walk_to(str(r[2]))
	for i in Cast.CHATTER.size():
		var l: Array = Cast.CHATTER[i]
		if _fired.has("c%d" % i) or minutes < float(l[0]):
			continue
		_fired["c%d" % i] = true
		var ch: Character = cast.get(l[1])
		if ch == null or ch.busy or ch.is_speaking() or (ch.minding and str(l[1]) == "marcus"):
			continue
		var radio_to: Character = null
		if str(l[3]) == "radio":
			for other in cast.values():
				if other != ch and other.sheet.radio and other.sheet.halberd:
					radio_to = other
					break
		ch.say_scripted(str(l[2]), radio_to)
	if not _shut and minutes >= SHUT:
		_shut = true
		_set_door("ballroom", false)
		_open.erase("ballroom")
		for ch in cast.values():
			ch.note("The ballroom doors are shut for the speech. Nobody else goes in.")
		toast_for.emit(0, "The ballroom doors are shut for the speech.")


## A guest goes in for the speech, with their plus-one if they took one.
func _go_in(ch: Character) -> void:
	var theirs := []
	for id in plus_ones:
		if plus_ones[id] == ch.sheet.id:
			theirs.append(id)
	if heat.level >= Heat.LOCKDOWN:
		for id in theirs:
			toast_for.emit(id, "%s goes in alone: the building's locked down." % ch.sheet.name)
		return
	_open_for("ballroom", OPEN_FOR)
	for id in theirs:
		toast_for.emit(id, "%s is going in. Stay with her, through the doors." % ch.sheet.name if ch.sheet.female else "%s is going in. Stay with him, through the doors." % ch.sheet.name)


## What the characters see: a familiar face in new clothes, strangers in
## the back of the house.
func _look() -> void:
	var space := _space()
	if space == null:
		return
	for ch in cast.values():
		if ch.walking:
			continue
		var seen: Dictionary = ch.look(crew, space)
		for id in seen:
			var c := crew_by_id(id)
			var f: Dictionary = ch.face_of(id)
			var was := str(f.seen)
			f["seen"] = c.outfit
			if was != "" and was != c.outfit and (ch.sheet.staff or ch.sheet.halberd):
				JobRules.nudge(f, 1)
				ch.event("%s you saw earlier is now wearing %s." % [Covers.describe(was, c.female).capitalize(), Covers.OUTFITS[c.outfit]["female" if c.female else "male"]], id, "event")
				faced.emit(id, ch.sheet.id, int(f.suspicion))
				continue
			var zone: String = hotel.zone_at(c.position())
			if not Covers.STAFF_ROOMS.has(zone) or zone in f.zones or not (ch.sheet.staff or ch.sheet.halberd):
				continue
			f["zones"].append(zone)
			if not Covers.looks_staff(c.outfit) and not _allowed_back(id):
				ch.event("%s is in %s, where only staff should be." % [describe(id).capitalize(), Covers.STAFF_ROOMS[zone]], id, "seen")
			elif ch.sheet.id == "laurent" and not id in hired and zone in ["kitchen", "staff_room"]:
				ch.event("A waiter you don't know, %s, is in your kitchen." % describe(id), id, "event")


## Someone let them into the back of the house.
func _allowed_back(id: int) -> bool:
	return id in booked or id in hired or "let_through" in cast["marcus"].face_of(id).opened


func _on_heat(was: int, now: int) -> void:
	heat_changed.emit(now)
	var staff: Array = cast.values().filter(func(ch): return ch.sheet.staff or ch.sheet.halberd)
	if now > was:
		match now:
			Heat.CURIOUS:
				for ch in staff:
					ch.note("Something about tonight feels off. You're keeping your eyes open.")
			Heat.ALERT:
				for ch in staff:
					ch.note("Security's on alert. Ask anyone you don't know for papers or a name you can check.")
				var ok: Character = cast.get("okafor")
				if ok and not ok.minding and escorted.is_empty():
					ok.walk_to("okafor")
				toast_for.emit(0, "The staff are on alert.")
			Heat.LOCKDOWN:
				for ch in cast.values():
					ch.note("Lockdown: nobody goes into the ballroom or the kitchen until it's lifted.")
					if ch.sheet.halberd:
						for id in ch.faces:
							ch.faces[id]["suspicion"] = maxi(int(ch.faces[id].suspicion), 3)
				for n in ["ballroom", "service", "pass"]:
					_open.erase(n)
					_set_door(n, false)
				toast_for.emit(0, "Lockdown. The ballroom and the kitchen are shut.")
	elif was == Heat.LOCKDOWN:
		for ch in cast.values():
			ch.note("The lockdown's lifted, but security's still on alert.")
		toast_for.emit(0, "The lockdown's lifted.")


func _check_end() -> void:
	if done or crew.is_empty():
		return
	var free := crew.filter(func(c): return not c.held)
	if free.is_empty():
		if _police_at < 0.0:
			_police_at = minutes + POLICE
			toast_for.emit(0, "Security has called the police. Talk your way out before they come.")
		elif minutes >= _police_at:
			_end("held")
		return
	_police_at = -1.0
	if free.all(func(c): return c.inside):
		_end("in")


func _end(outcome: String) -> void:
	if done:
		return
	done = true
	ended.emit(report(outcome))


## The job report: how it went, the scores, and the night's best and worst
## lines (the one that bought the most trust, the one that cost the most).
func report(outcome: String) -> Dictionary:
	var best := {}
	var worst := {}
	var best_score := 0.0
	var worst_score := 0.0
	var all_turns := 0
	var scripted := 0
	var timed_out := 0
	var thought := 0.0
	for ch in cast.values():
		for t in ch.turns:
			all_turns += 1
			if bool(t.get("scripted", true)):
				scripted += 1
			if bool(t.get("timed_out", false)):
				timed_out += 1
			thought += float(t.get("thought", 0.0))
			if not str(t.get("kind", "")) in ["line", "papers"] or not t.has("reply"):
				continue
			var reply: Dictionary = t.reply
			var moved := int(t.get("before", 0)) - int(t.get("after", 0))
			var good := moved + (3.0 if str(reply.get("ended", "")) == "open" else 0.0)
			var bad := -moved + (3.0 if str(reply.get("ended", "")) == "caught" else 0.0)
			var line := {
				"char": ch.sheet.id, "name": ch.sheet.name, "voice": ch.sheet.voice, "crew": int(t.get("subject", 0)),
				"said": str(t.get("said", "")) if str(t.kind) == "line" else "(showed the invitation)",
				"reply": str(reply.get("say", "")), "clock": str(t.get("clock", "")),
			}
			if good > best_score:
				best_score = good
				best = line
			if bad > worst_score:
				worst_score = bad
				worst = line
	var people: Array = []
	for c in crew:
		people.append({"name": c.name, "cover": c.cover, "cover_name": c.cover_name, "held": c.held, "was_held": _ever_held.has(c.id), "inside": c.inside})
	return {
		"outcome": outcome, "clock": clock_text(), "seconds": elapsed, "crew": people,
		"heat_peak": heat.peak, "heat_peak_name": Heat.name_of(heat.peak),
		"clean": _ever_held.is_empty() and heat.peak < Heat.LOCKDOWN,
		"quiet": heat.peak <= Heat.CURIOUS,
		"silver": not keypad_used,
		"best": best, "worst": worst,
		"turns": all_turns, "scripted": scripted, "timed_out": timed_out,
		"mean_thought": thought / maxf(1.0, float(all_turns - scripted)),
		"lines": lines.duplicate(true),
	}

#endregion

#region Doors and paths

func door_can_close(d) -> bool:
	if d == hotel.doors.get("front"):
		return false
	for n in _open:
		if hotel.doors.get(n) == d:
			return false
	return true


func _set_door(door_name: String, open: bool) -> void:
	var d = hotel.doors.get(door_name)
	if d == null:
		return
	if open and not d.is_open:
		open_door(door_name)
	elif not open and d.is_open:
		d.close()


## Opens a door for the staff, who have keys: a door locked to the crew
## opens all the same, and stays locked to them.
func open_door(door_name: String, from := Vector3.INF) -> void:
	var d = hotel.doors.get(door_name)
	if d == null or d.is_open:
		return
	var was: bool = d.locked
	d.locked = false
	d.open(from)
	d.locked = was


func _open_for(door_name: String, seconds: float) -> void:
	_set_door(door_name, true)
	_open[door_name] = maxf(float(_open.get(door_name, 0.0)), seconds)


func _lock(door_name: String, locked: bool) -> void:
	var d = hotel.doors.get(door_name)
	if d == null:
		return
	d.locked = locked
	door_changed.emit(door_name, d.is_open, d.locked)


func _on_door(door_name: String) -> void:
	var d = hotel.doors[door_name]
	# Doors that open by themselves do so on every device.
	if d.get("auto") == true:
		return
	door_changed.emit(door_name, d.is_open, d.locked)


## A way from somewhere to a spot through the hotel's points: {"points",
## "doors"} with the door crossed on the way to each point ("" for none).
func route(from: Vector3, spot_name: String) -> Dictionary:
	var to := spot(spot_name).origin
	var pts: Dictionary = hotel.points
	if pts.is_empty():
		return {"points": [to], "doors": [""]}
	var a := _nearest_point(from)
	var b := _nearest_point(to)
	var path := _path(a, b)
	var points: Array = []
	var doors: Array = []
	var prev := ""
	for n in path:
		points.append(pts[n])
		doors.append(_link_door(prev, n) if prev != "" else "")
		prev = n
	points.append(to)
	doors.append("")
	return {"points": points, "doors": doors}


## The nearest point in the same room, or the nearest of all.
func _nearest_point(p: Vector3) -> String:
	var zone: String = hotel.zone_at(p)
	var best := ""
	var best_any := ""
	var d_best := INF
	var d_any := INF
	for n in hotel.points:
		var q: Vector3 = hotel.points[n]
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < d_any:
			d_any = d
			best_any = n
		if d < d_best and hotel.zone_at(q) == zone:
			d_best = d
			best = n
	return best if best != "" else best_any


func _path(a: String, b: String) -> Array:
	var dist := {a: 0.0}
	var prev := {}
	var open := [a]
	while not open.is_empty():
		var cur: String = open[0]
		for n in open:
			if float(dist[n]) < float(dist[cur]):
				cur = n
		open.erase(cur)
		if cur == b:
			break
		for l in hotel.links:
			var other := ""
			if l[0] == cur:
				other = l[1]
			elif l[1] == cur:
				other = l[0]
			if other == "":
				continue
			var nd := float(dist[cur]) + (hotel.points[cur] as Vector3).distance_to(hotel.points[other])
			if not dist.has(other) or nd < float(dist[other]):
				dist[other] = nd
				prev[other] = cur
				if not other in open:
					open.append(other)
	if not dist.has(b):
		return [b]
	var path := [b]
	while path[0] != a:
		path.push_front(prev[path[0]])
	return path


func _link_door(a: String, b: String) -> String:
	for l in hotel.links:
		if (l[0] == a and l[1] == b) or (l[0] == b and l[1] == a):
			return str(l[2]) if l.size() > 2 else ""
	return ""


func _space() -> PhysicsDirectSpaceState3D:
	if hotel == null or not hotel.is_inside_tree():
		return null
	return hotel.get_world_3d().direct_space_state

#endregion
