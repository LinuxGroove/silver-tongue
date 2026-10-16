class_name Job
extends Node
## One job on the host: the clock and the night's routine, who hears what
## the crew says (and who it's said to), what the characters see, checks
## over the radio, the phone, the doors and keypads, things to take, heat,
## the security office, and the end. The characters think; the job carries
## out what the rules let them do. What's particular to a job (its cast,
## doors, routine, prize and rules) comes from its [JobDef]. It knows nothing
## of the network: the scene hands it the crew's lines and uses, and passes
## on what it emits.
##
## The venue is a [Venue] (or anything with the same `spots`, `points`,
## `links`, `doors`, `uses` and `zone_at()`, as the tests' stub has).

## A character said something: every device plays it from them. `channel`
## is "" (out loud), "radio" (also from the nearest radio to each player) or
## "phone:<crew id>" (also in that crew member's ear).
signal line_out(char_id: String, text: String, tone: String, channel: String)
## A crew member said something: crewmates in earshot (or anywhere, on the
## earpiece) see it.
signal crew_line_out(crew_id: int, text: String, voice: String, earpiece: bool)
## Something to tell one crew member (0: all of them).
signal toast_for(crew_id: int, text: String)
signal heat_changed(level: int)
## A crew member's outfit, items, held or inside changed.
signal crew_changed(crew_id: int)
signal door_changed(door_name: String, is_open: bool, locked: bool)
## What a character makes of a crew member now.
signal faced(crew_id: int, char_id: String, suspicion: int)
## A game minute went by.
signal clock_changed(minute: int)
## An item moved: who holds it (0 for nobody) and where it lies ("" when
## it's held or gone).
signal item_changed(item: String, holder: int, at: String)
## A node of the venue is shown or hidden, by name, on every device.
signal shown(node_name: String, is_visible: bool)
## What a crew member (0: everyone) should do now.
signal goal_changed(crew_id: int, text: String)
## Auntie Mae on a crew member's earpiece.
signal mae_said(crew_id: int, text: String)
## A crew member's phone call started (with whom, as the phone lists them)
## or ended (both "").
signal call_changed(crew_id: int, char_id: String, number_name: String)
signal ended(report: Dictionary)

## Seconds a door stays open for someone a character let through.
const OPEN_FOR := 25.0
## Game minutes from the whole crew being held to the police taking them.
const POLICE := 3.0
const LOOK_EVERY := 0.5
## A murmur into the earpiece is noticed from this close.
const EARPIECE_NOTICE := 1.5
## A wall or a shut door between: distance counts this much more.
const THROUGH_WALL := 2.2
## Seconds from asking Mae to her call going through.
const MAE_WAIT := 3.0

var def: JobDef
var venue: Node3D
var crew: Array[CrewInfo] = []
## id -> Character.
var cast := {}
var heat := Heat.new()
var queue: BrainQueue
## Think with the model when it's ready (off: scripted replies only).
var brains := true
## Minutes after midnight.
var minutes := 0.0
var elapsed := 0.0
var done := false
## The night waits (for the crew's other devices to arrive).
var hold := false
## The job's own state, for its [JobDef]: anything it likes.
var flags := {}
## Where each item is: id -> {"holder" (crew id, 0 for nobody), "at" (the
## use id it lies at, "" when held or gone)}.
var items := {}
## What wasn't talk: keypads and the like (Silver needs none).
var tools_used := 0
## Crew on the phone: crew id -> {"who" (character id), "as" (caller ID)}.
var calls := {}
## What characters remember from earlier jobs here: id -> lines for their
## sheet's "knows" (set before [method setup]).
var memories := {}
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
var _minute := 0
var _shown := {}
var _goals := {}


## Sets the night up in a venue already in the tree: the cast at their
## spots, the doors as they start, the crew's items (whose `node`s the
## scene sets).
func setup(p_def: JobDef, p_venue: Node3D, p_crew: Array[CrewInfo], seed := 0) -> void:
	def = p_def
	venue = p_venue
	crew = p_crew
	Jobs.current = def
	Person.add_looks(def.looks)
	minutes = float(def.start)
	_minute = int(minutes)
	rng.seed = seed if seed != 0 else randi()
	queue = BrainQueue.new()
	queue.name = "Brains"
	add_child(queue)
	for sheet in def.sheets():
		for m in memories.get(sheet.id, []):
			sheet.knows.append(str(m))
		var ch := Character.make(sheet, self)
		venue.add_child(ch)
		ch.global_transform = spot(sheet.spot)
		ch.spoke.connect(_on_spoke)
		cast[sheet.id] = ch
	for n in venue.doors:
		var d = venue.doors[n]
		d.opened.connect(_on_door.bind(n))
		d.closed.connect(_on_door.bind(n))
	for n in def.locked:
		_lock(n, true)
	for n in def.unlocked:
		_lock(n, false)
	for n in def.open:
		var d = venue.doors.get(n)
		if d and d.get("auto") != true:
			_set_door(n, true)
	for id in def.items:
		items[id] = {"holder": 0, "at": str(def.items[id].get("at", ""))}
	if not crew.any(func(c): return not c.items.is_empty()):
		def.give_items(crew)
	for c in crew:
		for it in c.items:
			items[it] = {"holder": c.id, "at": ""}
	def.setup(self)


func crew_by_id(id: int) -> CrewInfo:
	for c in crew:
		if c.id == id:
			return c
	return null


func crew_node(id: int) -> Node3D:
	var c := crew_by_id(id)
	return c.node if c else null


## How the characters see a crew member: "a man in a black dinner suit",
## and anything they're carrying in plain sight.
func describe(id: int) -> String:
	var c := crew_by_id(id)
	if c == null:
		return "someone"
	var d := Covers.describe(c.outfit, c.female)
	for it in c.items:
		var seen := str(def.items.get(it, {}).get("carry", ""))
		if seen != "":
			d += ", " + seen
	return d


## How one character knows a crew member: by how they look, or on the phone
## by the number that shows.
func describe_to(id: int, ch: Character) -> String:
	var rang: Dictionary = calls.get(id, {})
	if ch and str(rang.get("who", "")) == ch.sheet.id:
		var as_who := str(rang.get("as", ""))
		return "the caller on the phone, whose number shows as %s" % as_who if not as_who in ["", "Withheld"] else "the caller on the phone, from a withheld number"
	return describe(id)


func clock_text() -> String:
	return JobDef.clock_text(minutes)


func spot(spot_name: String) -> Transform3D:
	return venue.spots.get(spot_name, Transform3D.IDENTITY)


## What the rules need to know about a character and a crew member.
func context_for(ch: Character, crew_id: int) -> Dictionary:
	var c := crew_by_id(crew_id)
	return {
		"heat": heat.level, "held": c.held if c else false, "someone_held": not _held_by.is_empty(),
		"minding": ch.minding, "shut": ch.sheet.door != "" and bool(flags.get("shut:" + ch.sheet.door, false)),
	}


## Says what a crew member (0: everyone) should do now, on the HUD.
func set_goal(crew_id: int, text: String) -> void:
	_goals[crew_id] = text
	goal_changed.emit(crew_id, text)


## The goal a crew member sees now.
func goal_for(crew_id: int) -> String:
	return str(_goals.get(crew_id, _goals.get(0, def.goal if def else "")))


#region The crew's lines

## A crew member said something (heard by their device, or typed). It
## reaches every character in earshot; the one they're facing and nearest
## to answers (or whoever's on the phone with them), and the rest only
## think on a hot word.
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
	var on_phone: Character = cast.get(str(calls.get(crew_id, {}).get("who", "")))
	var space := _space()
	var hearers: Array = []
	for ch in cast.values():
		if ch == on_phone:
			continue
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
	var to: Character = on_phone if on_phone else addressed(c, hearers)
	if to:
		entry["to"] = to.sheet.id
	var lower := " " + text.to_lower() + " "
	if on_phone:
		var key := "%s|%d" % [on_phone.sheet.id, crew_id]
		_told[key] = str(_told.get(key, "")) + " " + text
		on_phone.hear(crew_id, text, text, "clear", 0.5, "phone", true, ScriptedBrain._hot(lower, on_phone.sheet))
	for h in hearers:
		var ch: Character = h.ch
		var hearing: Dictionary = h.hearing
		var said_to := ch == to and on_phone == null
		if said_to and str(hearing.heard) != "":
			var key := "%s|%d" % [ch.sheet.id, crew_id]
			_told[key] = str(_told.get(key, "")) + " " + str(hearing.heard)
		ch.hear(crew_id, text, str(hearing.heard), str(hearing.how), float(h.d), voice, said_to, ScriptedBrain._hot(lower, ch.sheet), bool(h.wall))


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

## A crew member used something: "door:<name>", "item:<id>",
## "character:<id>" (showing them papers), or whatever the venue's uses are
## and the job makes of them. Returns what to tell them ("" for nothing).
func use(crew_id: int, what: String) -> String:
	var c := crew_by_id(crew_id)
	if c == null or done:
		return ""
	if c.held:
		return "The door's locked. Someone's outside it." if what == "door:" + str(def.office.door) else ""
	var said: Variant = def.use(self, c, what)
	if said != null:
		return str(said)
	if what.begins_with("item:"):
		return take(crew_id, what.trim_prefix("item:"))
	if what.begins_with("character:"):
		var ch: Character = cast.get(what.trim_prefix("character:"))
		var paper := papers_for(c, ch)
		if ch and paper != "":
			show_papers(crew_id, ch, paper)
		return ""
	if not what.begins_with("door:"):
		return ""
	var door_name := what.trim_prefix("door:")
	var d = venue.doors.get(door_name)
	if d == null or d.get("auto") == true:
		return ""
	if d.locked:
		return "" if d.is_open else str(def.door_texts.get(door_name, "It's locked."))
	_set_door(door_name, not d.is_open)
	return ""


## A keypad by its use id. Returns what to tell them.
func keypad(crew_id: int, code: String, pad := "keypad") -> String:
	var c := crew_by_id(crew_id)
	var k: Dictionary = def.keypads.get(pad, {})
	if c == null or c.held or done or k.is_empty():
		return ""
	if heat.level >= Heat.LOCKDOWN:
		return "The keypad's dead. The building's locked down."
	if code != str(k.code):
		return "Wrong code."
	tools_used += 1
	flags["keypad:" + pad] = true
	_open_for(str(k.door), float(k.get("for", OPEN_FOR * 0.5)))
	witness(c, "You saw %s punch a code into the keypad by the %s door." % [describe(crew_id), str(k.door)], 2, Heat.KEYPAD_SEEN)
	return "The lock clicks."


## Takes an item lying in the venue. Returns what to tell them.
func take(crew_id: int, item: String) -> String:
	var c := crew_by_id(crew_id)
	var info: Dictionary = def.items.get(item, {})
	var st: Dictionary = items.get(item, {})
	if c == null or info.is_empty() or int(st.get("holder", 0)) != 0 or str(st.get("at", "")) == "":
		return ""
	var why := def.can_take(self, c, item)
	if why != "":
		return why
	give_item(crew_id, item)
	if bool(info.get("hot", false)):
		witness(c, "You saw %s take %s." % [describe(crew_id), str(info.get("name", item))], 2, Heat.KEYPAD_SEEN)
	return "You take %s." % str(info.get("name", item))


## Puts an item in a crew member's hands, from wherever it was.
func give_item(crew_id: int, item: String) -> void:
	var c := crew_by_id(crew_id)
	if c == null:
		return
	var was := int(items.get(item, {}).get("holder", 0))
	if was != 0 and was != crew_id:
		var other := crew_by_id(was)
		if other:
			other.items.erase(item)
			crew_changed.emit(was)
	items[item] = {"holder": crew_id, "at": ""}
	if not item in c.items:
		c.items.append(item)
	item_changed.emit(item, crew_id, "")
	crew_changed.emit(crew_id)


## Takes an item off a crew member and leaves it at a use id ("" for gone:
## handed over, swapped, or out of the building).
func place_item(crew_id: int, item: String, at := "") -> void:
	var c := crew_by_id(crew_id)
	if c:
		c.items.erase(item)
		crew_changed.emit(crew_id)
	items[item] = {"holder": 0, "at": at}
	item_changed.emit(item, 0, at)


## Who has an item (null for nobody).
func holder(item: String) -> CrewInfo:
	return crew_by_id(int(items.get(item, {}).get("holder", 0)))


## Shows or hides a node of the venue, by name, on every device.
func show_node(node_name: String, is_visible: bool) -> void:
	_shown[node_name] = is_visible
	var n := venue.find_child(node_name, true, false) as Node3D
	if n:
		n.visible = is_visible
	shown.emit(node_name, is_visible)


## Everything [method show_node] has changed, for a device joining late.
func shown_nodes() -> Dictionary:
	return _shown


## The papers a crew member would show a character: the first they carry
## that the character looks at ("" for none).
func papers_for(c: CrewInfo, ch: Character) -> String:
	if c == null or ch == null:
		return ""
	return def.papers_for(c.items, ch.sheet.id)


## Shows a character papers: a glance passes a forgery, a close look
## (anyone already suspicious) doesn't; real papers always pass.
func show_papers(crew_id: int, ch: Character, item := "") -> void:
	var c := crew_by_id(crew_id)
	if c == null:
		return
	if item == "":
		item = papers_for(c, ch)
	var info: Dictionary = def.items.get(item, {})
	if not item in c.items or not info.has("papers"):
		return
	var f := ch.face_of(crew_id)
	f["met"] = true
	f["turns"] = int(f.turns) + 1
	ch.attend(c.node)
	var named := str(info.papers) % c.cover_name if "%s" in str(info.papers) else str(info.papers)
	var belief := str(info.get("belief", "has papers"))
	if not bool(info.get("forged", false)) or int(f.suspicion) <= JobRules.TRUST:
		f["papers"] = "passed"
		ch.event("%s shows you %s. It looks right." % [describe(crew_id).capitalize(), named], crew_id, "papers", {"belief": belief})
	else:
		f["papers"] = "copy"
		JobRules.nudge(f, 2)
		ch.event("%s shows you %s. You look closely: %s" % [describe(crew_id).capitalize(), named, str(info.get("copy", "it's not real."))], crew_id, "papers", {"belief": belief})
	faced.emit(crew_id, ch.sheet.id, int(f.suspicion))


## Staff and Halberd who can see a crew member take note of what they did:
## suspicion up by `by`, and heat.
func witness(c: CrewInfo, text: String, by := 2, heat_points := 0.0) -> void:
	var space := _space()
	if space == null:
		return
	for ch in cast.values():
		if not (ch.sheet.staff or ch.sheet.halberd):
			continue
		if ch.look([c], space).has(c.id):
			JobRules.nudge(ch.face_of(c.id), by)
			if heat_points > 0.0:
				heat.bump(heat_points)
			ch.event(text, c.id, "seen")

#endregion

#region The phone and Mae

## A crew member rings a number on the job's list, showing `as_who` as the
## caller. Returns what to tell them ("" when it rings through).
func ring(crew_id: int, number_id: String, as_who := "Withheld") -> String:
	var c := crew_by_id(crew_id)
	var num := _number(number_id)
	if c == null or c.held or done or num.is_empty():
		return ""
	hang_up(crew_id)
	var ch: Character = cast.get(str(num.get("who", "")))
	if ch == null:
		return "Nobody answers."
	if ch.on_call != 0 or ch.minding:
		return "It's engaged."
	ch.on_call = crew_id
	calls[crew_id] = {"who": ch.sheet.id, "as": as_who}
	call_changed.emit(crew_id, ch.sheet.id, str(num.get("name", "")))
	ch.hold_clip("Idle_TalkingPhone")
	var shows := ": the caller ID says %s" % as_who if not as_who in ["", "Withheld"] else ", from a withheld number"
	ch.event("Your phone rings%s. You answer it." % shows, crew_id, "phone")
	return ""


func hang_up(crew_id: int) -> void:
	var rang: Dictionary = calls.get(crew_id, {})
	if rang.is_empty():
		return
	calls.erase(crew_id)
	var ch: Character = cast.get(str(rang.who))
	if ch:
		ch.on_call = 0
		ch.hold_clip("")
		ch.note("The caller hung up.")
	call_changed.emit(crew_id, "", "")


func _number(number_id: String) -> Dictionary:
	for n in def.phone:
		if str(n.get("id", "")) == number_id:
			return n
	return {}


## Mae's calls still to make.
func mae_left() -> Array:
	return def.mae_calls.filter(func(m): return not flags.has("mae:" + str(m.id)))


## Asks Auntie Mae to make one of her calls. Returns false when she can't.
func mae_call(crew_id: int, call_id: String) -> bool:
	var mae: Dictionary = {}
	for m in def.mae_calls:
		if str(m.get("id", "")) == call_id:
			mae = m
	var ch: Character = cast.get(str(mae.get("who", "")))
	if mae.is_empty() or ch == null or done or flags.has("mae:" + call_id):
		return false
	flags["mae:" + call_id] = true
	mae_said.emit(crew_id, str(mae.get("mae", "Leave it with me, love.")))
	_mae_rings.call_deferred(ch, mae)
	return true


func _mae_rings(ch: Character, mae: Dictionary) -> void:
	await get_tree().create_timer(MAE_WAIT).timeout
	if done or not is_inside_tree():
		return
	ch.hold_clip("Idle_TalkingPhone")
	ch.event("Your phone rings. It's %s: \"%s\"" % [str(mae.get("as", "someone")), str(mae.get("line", ""))], 0, "mae", {
		"answer": str(mae.get("answer", "Right away.")), "call": str(mae.id),
	})

#endregion

#region What the characters do

## A character finished a turn: carry out what the rules let them do.
func on_reply(ch: Character, crew_id: int, turn: Dictionary, out: Dictionary) -> void:
	if done:
		return
	var c := crew_by_id(crew_id)
	if c:
		faced.emit(crew_id, ch.sheet.id, ch.suspicion_of(crew_id))
	match str(turn.get("kind", "")):
		"question":
			_answer(ch, crew_id, turn, out)
			return
		"mae":
			ch.hold_clip("")
			def.on_mae(self, str(turn.get("call", "")), ch)
			return
	if c == null:
		return
	var act := str(out.get("do", "none"))
	if act in ["", "none"]:
		return
	if act == "release":
		if c.held:
			_release(crew_id, ch)
		else:
			for id in _held_by.keys():
				if _held_by[id] == ch.sheet.id:
					_release(id, ch)
		return
	if act == "radio_security":
		_hold(crew_id, ch)
		return
	if ch.sheet.is_check(act):
		_check(ch, crew_id, act)
		return
	if def.on_action(self, ch, c, act):
		return
	effect(ch, c, act)


## Does what [member JobDef.effects] says an action does.
func effect(ch: Character, c: CrewInfo, act: String) -> void:
	var e: Dictionary = def.effects.get(act, {})
	if e.is_empty() and act == "let_through":
		e = {"open": "@door"}
	if e.is_empty():
		return
	if e.has("if_item") and not str(e.if_item) in c.items:
		return
	if e.has("flag"):
		var v: Variant = e.get("value", true)
		c.flags[str(e.flag)] = ch.sheet.id if str(v) == "@char" else v
	if e.has("outfit") and c.outfit != str(e.outfit):
		c.outfit = str(e.outfit)
		crew_changed.emit(c.id)
	if e.has("item"):
		give_item(c.id, str(e.item))
	if e.has("open"):
		var door := ch.sheet.door if str(e.open) == "@door" else str(e.open)
		if door != "":
			_open_for(door, float(e.get("for", OPEN_FOR)))
	if e.has("walk"):
		ch.walk_to(str(e.walk))
	if e.has("toast"):
		var t := str(e.toast)
		toast_for.emit(c.id, t % ch.sheet.name if "%s" in t else t)


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
	asker.say_scripted("%s, it's %s. I've got %s here: %s. Does that check out?" % [target.sheet.name, asker.sheet.name, describe(crew_id), claim], target)
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
	var f := def.lookup(self, who, crew_id, told(asker, crew_id), asker)
	return f if not f.is_empty() else fact("bad", "You don't know them.", "No idea.")


## Everything a crew member told a character, and what the character came
## to believe about them, in lower case: what a check is asked about.
func told(ch: Character, crew_id: int) -> String:
	return (str(_told.get("%s|%d" % [ch.sheet.id, crew_id], "")) + " " + " ".join(ch.face_of(crew_id).believes)).to_lower()


## Notes something a crew member told a character, as if said to them.
func tell(char_id: String, crew_id: int, text: String) -> void:
	var key := "%s|%d" % [char_id, crew_id]
	_told[key] = str(_told.get(key, "")) + " " + text


## A colleague's answer to a check.
static func fact(verdict: String, text: String, answer: String) -> Dictionary:
	return {"verdict": verdict, "text": text, "answer": answer}


static func any(text: String, words: Array) -> bool:
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


## A character's first look at a crew member: Halberd has a photo of a
## burned face.
func new_face(ch: Character, crew_id: int, f: Dictionary) -> void:
	var c := crew_by_id(crew_id)
	if c and c.burned and ch.sheet.halberd:
		f["suspicion"] = maxi(int(f.suspicion), 3)
		ch.note("Halberd's file has a photo of %s: held at another job this season. Watch them." % describe(crew_id))


## Takes a crew member to the security office, minded by a Halberd guard.
func _hold(crew_id: int, by: Character) -> void:
	var c := crew_by_id(crew_id)
	if c == null or c.held:
		return
	hang_up(crew_id)
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
	var office_door := str(def.office.door)
	var office_name := str(def.office.get("name", "the security office"))
	if not guard.minding:
		guard.minding = true
		guard.walk_to(str(def.office.guard))
	_set_door(office_door, false)
	_lock(office_door, true)
	guard.note("You're minding %s: %s is held inside until the police decide what to do. Let them go only if you're sure it was a mistake." % [office_name, describe(crew_id)])
	for ch in cast.values():
		if ch.sheet.radio and ch != guard:
			ch.note("On the radio: security has %s in %s." % [describe(crew_id), office_name])
	toast_for.emit(crew_id, "%s called security. You're held in %s." % [by.sheet.name, office_name])
	for other in crew:
		if other.id != crew_id:
			toast_for.emit(other.id, "%s is held in %s." % [c.name, office_name])
	crew_changed.emit(crew_id)
	_check_end()


func _release(crew_id: int, by: Character) -> void:
	var c := crew_by_id(crew_id)
	if c == null or not c.held:
		return
	c.held = false
	_held_by.erase(crew_id)
	if _held_by.is_empty():
		var office_door := str(def.office.door)
		_lock(office_door, false)
		_open_for(office_door, OPEN_FOR)
		by.minding = false
		by.walk_to(post_now(by))
	for ch in cast.values():
		if ch.sheet.radio:
			ch.note("On the radio: %s let %s go." % [by.sheet.name, describe(crew_id)])
	toast_for.emit(crew_id, "%s lets you go." % by.sheet.name)
	crew_changed.emit(crew_id)


## Where a character should be now: the last spot their routine sent them
## to, or their own.
func post_now(ch: Character) -> String:
	var at := ch.sheet.spot
	var when := -INF
	for r in def.routine:
		if str(r[1]) == ch.sheet.id and float(r[0]) <= minutes and float(r[0]) > when:
			when = float(r[0])
			at = str(r[2])
	return at


## A character said a line: out to every device, and to the other radios.
func _on_spoke(ch: Character, text: String, tone: String, radio_to: Character) -> void:
	var channel := "radio" if radio_to else ("phone:%d" % ch.on_call if ch.on_call != 0 else "")
	line_out.emit(ch.sheet.id, text, tone, channel)
	if radio_to == null:
		return
	for other in cast.values():
		if other != ch and other.sheet.radio:
			other.note("On the radio, %s: \"%s\"" % [ch.sheet.name, text])

#endregion

#region The night

func _process(delta: float) -> void:
	if done or venue == null or hold:
		return
	elapsed += delta
	minutes += delta / def.seconds_per_minute
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
	if def.inside_zone != "":
		for c in crew:
			var inside: bool = not c.held and c.node != null and venue.zone_at(c.position()) == def.inside_zone
			if inside != c.inside:
				c.inside = inside
				crew_changed.emit(c.id)
				if inside and def.inside_text != "":
					toast_for.emit(c.id, def.inside_text)
	def.tick(self, delta)
	_check_end()
	if not done and minutes >= def.end:
		_end(def.at_end(self))


func _routine() -> void:
	for i in def.routine.size():
		var r: Array = def.routine[i]
		if _fired.has("r%d" % i) or minutes < float(r[0]):
			continue
		_fired["r%d" % i] = true
		var ch: Character = cast.get(r[1])
		if ch == null or ch.minding or not def.on_routine(self, ch, str(r[2])):
			continue
		ch.walk_to(str(r[2]))
	for i in def.chatter.size():
		var l: Array = def.chatter[i]
		if _fired.has("c%d" % i) or minutes < float(l[0]):
			continue
		_fired["c%d" % i] = true
		var ch: Character = cast.get(l[1])
		if ch == null or ch.busy or ch.is_speaking() or ch.minding or ch.on_call != 0:
			continue
		var radio_to: Character = null
		if str(l[3]) == "radio":
			for other in cast.values():
				if other != ch and other.sheet.radio and other.sheet.halberd:
					radio_to = other
					break
		ch.say_scripted(str(l[2]), radio_to)
	for i in def.events.size():
		var e: Array = def.events[i]
		if _fired.has("e%d" % i) or minutes < float(e[0]):
			continue
		_fired["e%d" % i] = true
		def.on_event(self, str(e[1]))


## Shuts a door for the night: closed, kept closed, and the character who
## keeps it lets nobody through (see [method context_for]).
func shut_for_night(door_name: String) -> void:
	flags["shut:" + door_name] = true
	_open.erase(door_name)
	_set_door(door_name, false)


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
				ch.event("%s you saw earlier is now wearing %s." % [Covers.describe(was, c.female).capitalize(), Covers.wearing(c.outfit, c.female)], id, "event")
				faced.emit(id, ch.sheet.id, int(f.suspicion))
				continue
			var zone: String = venue.zone_at(c.position())
			if zone in f.zones:
				continue
			f["zones"].append(zone)
			if def.on_seen(self, ch, c, zone):
				continue
			if not def.staff_rooms.has(zone) or not (ch.sheet.staff or ch.sheet.halberd):
				continue
			if not Covers.looks_staff(c.outfit) and not def.allowed_back(self, c):
				ch.event("%s is in %s, where only staff should be." % [describe(id).capitalize(), def.staff_rooms[zone]], id, "seen")


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
				toast_for.emit(0, "The staff are on alert.")
			Heat.LOCKDOWN:
				for ch in cast.values():
					ch.note("Lockdown: nobody goes anywhere they shouldn't until it's lifted.")
					if ch.sheet.halberd:
						for id in ch.faces:
							ch.faces[id]["suspicion"] = maxi(int(ch.faces[id].suspicion), 3)
				for n in def.lockdown_doors:
					_open.erase(n)
					_set_door(n, false)
				toast_for.emit(0, def.lockdown_text)
	elif was == Heat.LOCKDOWN:
		for ch in cast.values():
			ch.note("The lockdown's lifted, but security's still on alert.")
		toast_for.emit(0, "The lockdown's lifted.")
	def.on_heat(self, was, now)


## The crew members not held.
func free_crew() -> Array:
	return crew.filter(func(c): return not c.held)


func _check_end() -> void:
	if done or crew.is_empty():
		return
	if free_crew().is_empty():
		if _police_at < 0.0:
			_police_at = minutes + POLICE
			toast_for.emit(0, "Security has called the police. Talk your way out before they come.")
		elif minutes >= _police_at:
			_end("held")
		return
	_police_at = -1.0
	var o := def.check_end(self)
	if o != "":
		_end(o)


## Ends the night (a [JobDef] can call it with its own outcome).
func finish(outcome: String) -> void:
	_end(outcome)


func _end(outcome: String) -> void:
	if done:
		return
	done = true
	for id in calls.keys():
		hang_up(id)
	ended.emit(report(outcome))


## The job report: how it went, the scores, the take, and the night's best
## and worst lines (the one that bought the most trust, the one that cost
## the most).
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
				"said": str(t.get("said", "")) if str(t.kind) == "line" else "(showed their papers)",
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
		people.append({"name": c.name, "cover": c.cover, "cover_name": c.cover_name, "held": c.held, "was_held": _ever_held.has(c.id), "inside": c.inside, "id": c.id, "items": c.items.duplicate()})
	var won := outcome in def.wins
	var usual := {
		"held": ["ALL HELD", "The whole crew ended up in %s." % str(def.office.get("name", "the security office"))],
		"lost": ["THE HOST LEFT", "The night ended when the host's game did."],
	}
	var heading: Array = def.outcomes.get(outcome, usual.get(outcome, [outcome.to_upper(), ""]))
	var text := str(heading[1])
	var r := {
		"job": def.id, "job_title": def.title, "venue": def.venue_id, "venue_name": def.venue_name,
		"outcome": outcome, "win": won, "title": str(heading[0]), "text": text % clock_text() if "%s" in text else text,
		"clock": clock_text(), "seconds": elapsed, "crew": people,
		"heat_peak": heat.peak, "heat_peak_name": Heat.name_of(heat.peak),
		"clean": _ever_held.is_empty() and heat.peak < Heat.LOCKDOWN,
		"quiet": heat.peak <= Heat.CURIOUS,
		"silver": tools_used == 0,
		"prize": def.prize, "take": def.take if won else 0,
		"best": best, "worst": worst,
		"turns": all_turns, "scripted": scripted, "timed_out": timed_out,
		"mean_thought": thought / maxf(1.0, float(all_turns - scripted)),
		"lines": lines.duplicate(true),
		"memories": _memories(),
	}
	def.report(self, outcome, r)
	return r


## What each character will remember of the crew next time at this venue:
## who they helped, and who gave them a bad feeling.
func _memories() -> Dictionary:
	var out := {}
	for ch in cast.values():
		var said: Array = []
		for id in ch.faces:
			var c := crew_by_id(id)
			var f: Dictionary = ch.faces[id]
			if c == null or not bool(f.get("met", false)):
				continue
			var who := describe(id)
			if c.cover_name != "" and told(ch, id).contains(c.cover_name.to_lower()):
				who += ", who called themselves %s" % c.cover_name
			if not (f.get("opened", []) as Array).is_empty():
				said.append("At %s, you helped %s. You've wondered about it since." % [def.title.to_lower(), who])
			elif int(f.suspicion) >= 3:
				said.append("At %s, %s gave you a bad feeling. You'd know them again." % [def.title.to_lower(), who])
		if not said.is_empty():
			out[ch.sheet.id] = said
	return out

#endregion

#region Doors and paths

func door_can_close(d) -> bool:
	if d.get("auto") == true:
		return false
	for n in _open:
		if venue.doors.get(n) == d:
			return false
	return true


func _set_door(door_name: String, open: bool) -> void:
	var d = venue.doors.get(door_name)
	if d == null:
		return
	if open and not d.is_open:
		open_door(door_name)
	elif not open and d.is_open:
		d.close()


## Opens or shuts a door for the job (a [JobDef] uses this).
func set_door(door_name: String, open: bool) -> void:
	if not open:
		_open.erase(door_name)
	_set_door(door_name, open)


## Opens a door for the staff, who have keys: a door locked to the crew
## opens all the same, and stays locked to them.
func open_door(door_name: String, from := Vector3.INF) -> void:
	var d = venue.doors.get(door_name)
	if d == null or d.is_open:
		return
	var was: bool = d.locked
	d.locked = false
	d.open(from)
	d.locked = was


## Opens a door for a while, then shuts it.
func open_for(door_name: String, seconds: float) -> void:
	_open_for(door_name, seconds)


func _open_for(door_name: String, seconds: float) -> void:
	_set_door(door_name, true)
	_open[door_name] = maxf(float(_open.get(door_name, 0.0)), seconds)


## Locks or unlocks a door to the crew.
func lock(door_name: String, locked: bool) -> void:
	_lock(door_name, locked)


func _lock(door_name: String, locked: bool) -> void:
	var d = venue.doors.get(door_name)
	if d == null:
		return
	d.locked = locked
	door_changed.emit(door_name, d.is_open, d.locked)


func _on_door(door_name: String) -> void:
	var d = venue.doors[door_name]
	# Doors that open by themselves do so on every device.
	if d.get("auto") == true:
		return
	door_changed.emit(door_name, d.is_open, d.locked)


## A way from somewhere to a spot through the venue's points: {"points",
## "doors"} with the door crossed on the way to each point ("" for none).
func route(from: Vector3, spot_name: String) -> Dictionary:
	var to := spot(spot_name).origin
	var pts: Dictionary = venue.points
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


## The nearest point in the same room, or the nearest of all (a storey
## counts four times its height, so people stay on their own deck).
func _nearest_point(p: Vector3) -> String:
	var zone: String = venue.zone_at(p)
	var best := ""
	var best_any := ""
	var d_best := INF
	var d_any := INF
	for n in venue.points:
		var q: Vector3 = venue.points[n]
		var d := Vector2(q.x - p.x, q.z - p.z).length() + absf(q.y - p.y) * 4.0
		if d < d_any:
			d_any = d
			best_any = n
		if d < d_best and venue.zone_at(q) == zone:
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
		for l in venue.links:
			var other := ""
			if l[0] == cur:
				other = l[1]
			elif l[1] == cur:
				other = l[0]
			if other == "":
				continue
			var nd := float(dist[cur]) + (venue.points[cur] as Vector3).distance_to(venue.points[other])
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
	for l in venue.links:
		if (l[0] == a and l[1] == b) or (l[0] == b and l[1] == a):
			return str(l[2]) if l.size() > 2 else ""
	return ""


func _space() -> PhysicsDirectSpaceState3D:
	if venue == null or not venue.is_inside_tree():
		return null
	return venue.get_world_3d().direct_space_state

#endregion
