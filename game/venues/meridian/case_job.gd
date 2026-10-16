class_name MeridianCaseJob
extends JobDef
## Job 3 at the Hotel Meridian: the morning the Rose leaves for the Marlin.
## Swap its display case on the ballroom stage for Mae's copy before
## Halberd's couriers take it, then get the real one out of the hotel or
## hide it on the breakfast cart. As the Courier's photographer who gets
## the stage cleared for the light, the insurer's assessor whom Wren lets
## handle the case, or a temp waiter at the press breakfast while Wren signs
## the handover in the lobby. tests/meridian_tests.gd plays every way through.
##
## Who's on the stage when is the job's events, not a routine, so a Circuit
## morning never moves the signing or the couriers.

const KITCHEN_CODE := MeridianGalaJob.KITCHEN_CODE
## Wren and Priya sign the handover in the lobby, come back with Ingrid, and
## Halberd's couriers take the case.
const SIGNING := 10 * 60 + 5
const BACK := 10 * 60 + 15
const COURIERS := 10 * 60 + 26
## Game minutes the stage stays clear for the photographer's light.
const CLEAR := 4.0
## What each story is about, as the people checking it would hear it.
const PRESS_WORDS := ["photographer", "caldera courier", "picture desk", "newspaper"]
const STAFFING := ["agency", "staffing", "temp", "catering", "breakfast", "extra hands", "pair of hands"]
const INSURER := ["brightwater", "insur", "assessor"]


func _init() -> void:
	id = "meridian_case"
	venue_id = "meridian"
	number = 3
	title = "The display case"
	venue_name = "The Hotel Meridian"
	briefing = "This is the one, love. This morning the Rose sits on the Meridian's stage in its case for the press, and at twenty-six past ten Halberd's couriers carry that case to the Marlin. I've had a copy made, down to the scratches, with a lock I can open. Swap them, and the Rose travels in my case. Then get the real one out of the building, or hide it on the breakfast cart; my people collect that at eleven. Wren from the museum never leaves it, Priya's running the show, and Ingrid from Halberd is on the front door. One of you carries my copy in. Don't let anyone see you swap them."
	goal = "Swap the Rose's case for Mae's copy, then get the real one out or hide it"
	situation = MeridianCast.PRESS
	prize = "the Rose"
	take = 8000
	start = 9 * 60 + 40
	end = 10 * 60 + 30
	end_text = "the van leaves"
	covers = {
		"press": {
			"title": "Photographer",
			"names": ["Jonah Pike", "Jo Pike"],
			"job": "a photographer for the Caldera Courier",
			"story": "The Courier wants the Rose on its front page. You'll need the stage to yourself for the light. Your camera case is Mae's copy.",
			"outfit": "press",
			"for": "Teo on the doors, and Priya, who runs the press call",
			"lines": [
				"Morning. %s, Caldera Courier. I'm the photographer.",
				"Check with Dana, she'll have me on the press list.",
				"I need the stage clear for two minutes. The light's perfect.",
				"Front page, if I get the shot.",
			],
		},
		"catering": {
			"title": "Catering",
			"names": ["Sid Moran", "Sadie Moran"],
			"job": "an extra pair of hands from Caldera Staffing, for the press breakfast",
			"story": "Laurent's short-handed for the press breakfast, as always. You come in through the loading bay with a crate of pastries.",
			"outfit": "agency",
			"for": "Marcus on the service door, and Laurent in the kitchen",
			"lines": [
				"Morning. Caldera Staffing sent me for the press breakfast.",
				"Ring reception if you like. They'll have me down.",
				"Where do you want me, chef?",
				"I've done a hundred of these. Point me at a tray.",
			],
		},
		"assessor": {
			"title": "Assessor",
			"names": ["Graham Voss", "Greta Voss"],
			"job": "an assessor from Brightwater Mutual, the Rose's insurer",
			"story": "Brightwater wants one last look at the case before it travels. Halberd will want to check with the insurer.",
			"outfit": "business",
			"for": "Wren, the museum's registrar",
			"lines": [
				"Good morning. %s, Brightwater Mutual. I'm here for the condition check.",
				"It's a condition of the policy, I'm afraid. Halberd knows.",
				"I'll need to look the case over before it travels.",
				"Two minutes, and you can have it back.",
			],
		},
	}
	cover_order = ["press", "catering", "assessor"]
	outfits = {"business": {"job": "meridian_business", "male": "a gray business suit", "female": "a gray business suit"}}
	looks = MeridianCast.LOOKS
	staff_looking = Covers.STAFF_LOOKING.duplicate()
	staff_rooms = Covers.STAFF_ROOMS.duplicate()
	staff_rooms["manager_office"] = "Mr Okafor's office"
	extras = {"ballroom": "meridian_press_crowd", "lobby": "guest", "kitchen": "kitchen"}
	routine = [
		[9 * 60 + 50, "hugo", "pippa_in"],
		[9 * 60 + 52, "rafe", "okafor_stage"],
		[9 * 60 + 58, "hugo", "hugo_in"],
		[10 * 60, "rafe", "rafe"],
	]
	chatter = [
		[9 * 60 + 41, "priya", "Five minutes, everyone. Coffee's on the buffets.", "near"],
		[9 * 60 + 44, "rafe", "Diamond sits in a box. Hold the front page.", "near"],
		[9 * 60 + 47, "hugo", "She's going aboard my Marlin, you know. I sold them that boat.", "near"],
		[9 * 60 + 47, "celeste", "Everyone knows, Hugo. You've told them all.", "near"],
		[9 * 60 + 55, "laurent", "More croissants! The press eat like wolves!", "near"],
		[9 * 60 + 58, "marcus", "Teo, it's Marcus. Twenty hours on this door. Tell Ingrid.", "radio"],
		[9 * 60 + 58, "teo", "She knows, Marcus.", "radio"],
	]
	events = [[SIGNING, "signing"], [BACK, "back"], [COURIERS, "couriers"]]
	locked = ["ballroom", "service", "pass", "manager"]
	unlocked = ["office", "staff", "loading"]
	open = ["front"]
	lockdown_doors = ["ballroom", "service", "pass", "loading"]
	lockdown_text = "Lockdown. The ballroom and the back of the house are shut."
	door_texts = {
		"service": "It's locked. There's a keypad by it.", "ballroom": "Teo's on the doors, checking passes.",
		"manager": "Mr Okafor's office. It's locked.",
	}
	keypads = {"keypad": {"door": "service", "code": KITCHEN_CODE, "label": "Kitchen door"}}
	items = {
		"rose_case": {"name": "the Rose's case", "at": "plinth", "carry": "carrying a black hard case", "hot": true},
		"mae_case": {"name": "Mae's copy", "at": "", "carry": "carrying a black hard case"},
		"press_pass": {
			"name": "the press pass", "at": "", "carry": "",
			"papers": "a Caldera Courier press pass in the name of %s", "forged": true,
			"copy": "the laminate's peeling and the photo's printed on paper. It's a copy.",
			"belief": "has a Courier press pass", "to": ["teo", "priya"],
		},
		"insurer_letter": {
			"name": "the policy letter", "at": "", "carry": "",
			"papers": "a letter from Brightwater Mutual sending %s to look over the Rose's case", "forged": true,
			"copy": "the letterhead's a scan and the signature's printed. It's a copy.",
			"belief": "has a letter from Brightwater Mutual", "to": ["teo", "wren", "ingrid"],
		},
	}
	cool_words = ["the rose", "diamond"]
	actions = {
		"clear_stage": {"text": "clear the stage for their picture: you and Wren step out to the lobby for a few minutes", "kind": "opening", "lockdown": true},
		"condition_check": {"text": "let them look the case over for the insurer, handling it as they need to", "kind": "opening", "lockdown": true},
		"ask_halberd": {"text": "radio Ingrid at Halberd to check who they are (takes a moment)", "kind": "check"},
	}
	effects = {
		"put_to_work": {"flag": "hired", "outfit": "waiter_jacket", "toast": "%s has put you to work. The pass into the ballroom is open to you."},
		"let_through": {"open": "@door", "toast": "%s lets you through."},
	}
	phone = [
		{"id": "reception", "name": "Meridian reception", "who": "dana"},
		{"id": "manager", "name": "Priya Nair, day manager", "who": "priya"},
		{"id": "kitchen", "name": "The Meridian's kitchen", "who": "laurent"},
		{"id": "halberd", "name": "Halberd transport desk", "who": "ingrid"},
	]
	caller_ids = ["Withheld", "Caldera Staffing", "Caldera Courier", "Brightwater Mutual", "Caldera Museum"]
	mae_calls = [
		{"id": "temp", "label": "Tell reception a temp's coming", "who": "dana", "as": "Caldera Staffing",
			"line": "Morning, Caldera Staffing. We're sending one more pair of hands for your press breakfast; they'll come in through the loading bay. Could you let your door know?",
			"answer": "Oh, good, Laurent will be pleased. I'll tell Marcus.",
			"mae": "I'll ring the desk as the agency, love. When Marcus checks, Dana will say you're expected."},
		{"id": "press", "label": "Put you on the press list", "who": "dana", "as": "Caldera Courier",
			"line": "Morning, picture desk at the Caldera Courier. We're sending a photographer to the Rose's press call. Could you put them on your press list?",
			"answer": "Of course. I'll add them now.",
			"mae": "I'll ring Dana from the Courier's picture desk. Your name will be on her press list."},
		{"id": "assessor", "label": "Ring Halberd as the insurer", "who": "ingrid", "as": "Brightwater Mutual",
			"line": "Good morning, Brightwater Mutual. Our assessor is coming to look over the Rose's case before it travels. A condition of the policy, I'm afraid.",
			"answer": "Understood. I'll tell the registrar.",
			"mae": "I'll ring Ingrid as Brightwater. When Wren asks Halberd about you, Ingrid will say you're expected."},
	]
	outcomes = {
		"swapped": ["THE SWITCH", "The Rose is yours, and Mae's case goes to the Marlin in its place. Done at %s."],
		"gone": ["TOO LATE", "Halberd's couriers took the Rose to the Marlin in its own case."],
		"inside": ["STILL INSIDE", "The couriers left with Mae's case, but the Rose was still on you inside the hotel."],
	}
	wins = ["swapped"]


func venue() -> Venue:
	var m := Meridian.new()
	m.setting = "press"
	return m


func cast() -> Array[CharacterSheet]:
	return MeridianCast.press_morning()


## Mae's copy comes in with whoever's cover carries a case best.
func give_items(crew: Array) -> void:
	for c in crew:
		match c.cover:
			"press":
				c.items.append("press_pass")
			"assessor":
				c.items.append("insurer_letter")
	for cover in ["press", "assessor", "catering"]:
		for c in crew:
			if c.cover == cover:
				c.items.append("mae_case")
				return
	if not crew.is_empty():
		crew[0].items.append("mae_case")


func setup(job: Job) -> void:
	job.flags["at:wren"] = "wren"
	job.flags["at:priya"] = "priya"


#region The crew's doings

func use(job: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"item:rose_case":
			return _swap(job, c)
		"item:mae_case":
			return "Mae's copy. It stays where it is."
		"trolley":
			if not "rose_case" in c.items:
				return "The breakfast cart. It goes back to the caterer's van at eleven."
			job.place_item(c.id, "rose_case", "")
			job.flags["hidden"] = true
			return "You tuck the Rose's case under the cloth on the breakfast cart. Mae's people collect it at eleven."
	var d = job.venue.doors.get(what.trim_prefix("door:")) if what.begins_with("door:") else null
	if d == null or d.is_open:
		return null
	var zone: String = job.venue.zone_at(c.position())
	match what:
		"door:ballroom":
			# Out is easy; in is Teo's business.
			if zone == "ballroom":
				if job.heat.level >= Heat.LOCKDOWN:
					return "The ballroom doors are shut. The building's locked down."
				job.open_for("ballroom", 6.0)
				return ""
		"door:service":
			if zone == "kitchen" and job.heat.level < Heat.LOCKDOWN:
				job.open_for("service", 6.0)
				return ""
		"door:pass":
			if c.outfit == "waiter_jacket" or c.flags.has("hired"):
				job.open_for("pass", Job.OPEN_FOR * 0.5)
				return ""
			return "The waiters' door. You don't look like a waiter."
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	match what:
		"item:rose_case":
			return "Swap it for Mae's copy" if "mae_case" in c.items else "Look at the Rose's case"
		"item:mae_case":
			return ""
		"trolley":
			return "Hide the Rose's case on the cart" if "rose_case" in c.items else "Look at the breakfast cart"
	return null


## Mae's copy on the stand, the Rose's case in hand. Staff who see it happen
## know exactly what they saw, unless Wren's letting you handle the case.
func _swap(job: Job, c: CrewInfo) -> String:
	if not "mae_case" in c.items:
		return "Take it and leave the stand empty? They'd notice in a second. You need Mae's copy."
	if not c.flags.has("inspecting"):
		job.witness(c, "You saw %s lift the Rose's case off its stand and put another one down in its place." % job.describe(c.id), 4, Heat.CAUGHT)
		if c.held:
			return "You lift the case, and every eye on the stage is on you."
	job.place_item(c.id, "mae_case", "plinth_copy")
	job.give_item(c.id, "rose_case")
	job.flags["swapped"] = c.id
	job.set_goal(0, "Get the Rose's case out of the hotel, or hide it on the breakfast cart")
	return "You swap the cases. Mae's copy sits on the stand."


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"clear_stage":
			job.flags["clear_until"] = job.minutes + CLEAR
			_walk(job, "wren", "wren_lobby")
			_walk(job, "priya", "priya_lobby")
			job.toast_for.emit(c.id, "%s clears the stage for your picture. She and Wren step out to the lobby for a few minutes." % ch.sheet.name)
			return true
		"condition_check":
			c.flags["inspecting"] = true
			job.toast_for.emit(c.id, "%s lets you look the case over. Handle it as you need to." % ch.sheet.name)
			return true
	return false


func allowed_back(job: Job, c: CrewInfo) -> bool:
	return c.flags.has("hired") or "let_through" in job.cast["marcus"].face_of(c.id).opened


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	if ch.sheet.id == "laurent" and zone in ["kitchen", "staff_room"] and Covers.looks_staff(c.outfit) and not c.flags.has("hired"):
		ch.event("A waiter you don't know, %s, is in your kitchen." % job.describe(c.id), c.id, "event")
		return true
	return false

#endregion

#region Lies and the people who check them

func lookup(job: Job, who: String, _crew_id: int, said: String, _asker: Character) -> Dictionary:
	match who:
		"dana":
			if Job.any(said, PRESS_WORDS):
				if _backed(job, "press", "dana", "Caldera Courier", PRESS_WORDS):
					return Job.fact("good", "The Caldera Courier's picture desk rang this morning: their photographer is on your press list.", "Yes, the Courier rang. Their photographer's on my list.")
				return Job.fact("bad", "The Courier sent Rafe Doyle this morning. There's no photographer on your press list.", "The Courier sent Rafe. There's no photographer on my list.")
			if Job.any(said, STAFFING):
				if _backed(job, "temp", "dana", "Caldera Staffing", STAFFING):
					return Job.fact("good", "Caldera Staffing rang this morning: one more pair of hands for the press breakfast, through the loading bay.", "Yes, the agency rang. One extra for the breakfast. Let them through.")
				return Job.fact("bad", "Nobody's rung you about extra staff for the breakfast.", "Nobody's rung me about extra staff.")
			if Job.any(said, INSURER):
				return Job.fact("bad", "The insurer is Halberd's business, not yours.", "The insurer? That's Ingrid's business, not mine.")
			return Job.fact("bad", "Nobody like that is on your list this morning.", "Nobody like that on my list.")
		"ingrid":
			if Job.any(said, INSURER):
				if _backed(job, "assessor", "ingrid", "Brightwater Mutual", INSURER + ["condition", "case"]):
					return Job.fact("good", "Brightwater Mutual rang you this morning: their assessor is coming to look the case over before it travels.", "Brightwater rang. Their assessor's expected. Let them look.")
				return Job.fact("bad", "Brightwater Mutual always rings you before they send anyone, and they haven't.", "Brightwater haven't rung me. Nobody touches that case.")
			if Job.any(said, PRESS_WORDS):
				return Job.fact("bad", "The press list is Dana's, not yours.", "Press is Dana's list. Not mine.")
			return Job.fact("bad", "You don't know them.", "Never heard of them.")
		"priya":
			if Job.any(said, STAFFING):
				if _backed(job, "temp", "dana", "Caldera Staffing", STAFFING):
					return Job.fact("good", "Dana told you Caldera Staffing is sending one more for the breakfast.", "The agency, yes. Dana said they'd send one.")
				return Job.fact("bad", "Nobody's told you about extra staff this morning.", "I don't know anything about extra staff.")
			return Job.fact("bad", "You don't know them.", "I don't know who that is.")
	return {}


## A story backed up by phone: Mae's call went through, or one of the crew
## rang `who` showing `as_who`, told them something with one of `words`, and
## didn't put them off.
static func _backed(job: Job, call_id: String, who: String, as_who: String, words: Array) -> bool:
	if job.flags.has("called:" + call_id):
		return true
	var by := int(job.flags.get("rang:%s:%s" % [who, as_who], 0))
	var ch: Character = job.cast.get(who)
	return by != 0 and ch != null and ch.suspicion_of(by) <= 2 and Job.any(job.told(ch, by), words)


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	job.flags["called:" + call_id] = true
	match call_id:
		"temp":
			ch.note("Caldera Staffing rang: they're sending one more pair of hands for Laurent's press breakfast, through the loading bay. Marcus should let them through.")
			for other in job.cast.values():
				if other.sheet.id in ["marcus", "laurent", "priya"]:
					other.note("On the radio, Dana: \"The agency's sending one more for the breakfast, through the loading bay.\"")
		"press":
			ch.note("The Caldera Courier's picture desk rang: they're sending a photographer to the press call. You've put them on your press list.")
		"assessor":
			ch.note("Brightwater Mutual rang: their assessor is coming to look over the Rose's case before it travels, as the policy says. They're expected.")

#endregion

#region The morning

func on_event(job: Job, event_name: String) -> void:
	var ingrid: Character = job.cast.get("ingrid")
	match event_name:
		"signing":
			job.flags["at:wren"] = "wren_lobby"
			job.flags["at:priya"] = "priya_lobby"
			job.flags.erase("clear_until")
			_walk(job, "wren", "wren_lobby")
			_walk(job, "priya", "priya_lobby")
			if ingrid:
				ingrid.say_scripted("Wren, Priya, the handover papers are ready. Front of the lobby, please.", _radio_to(job, ingrid))
			job.toast_for.emit(0, "Wren and Priya go out to the lobby to sign the handover papers.")
		"back":
			job.flags["at:wren"] = "wren"
			job.flags["at:priya"] = "priya"
			job.flags.erase("clear_until")
			_walk(job, "wren", "wren")
			_walk(job, "priya", "priya")
			_walk(job, "ingrid", "ingrid_stage")
			job.toast_for.emit(0, "Wren and Priya are back on the stage, and Ingrid's with them.")
		"couriers":
			if str(job.items.get("rose_case", {}).get("at", "")) == "plinth":
				job.finish("gone")
				return
			if str(job.items.get("mae_case", {}).get("at", "")) == "plinth_copy":
				job.place_item(0, "mae_case", "")
			if ingrid:
				ingrid.say_scripted("The van's here. Moving the case now.", _radio_to(job, ingrid))
			_walk(job, "ingrid", "front_watch")
			_walk(job, "wren", "wren_lobby")
			job.toast_for.emit(0, "Halberd's couriers carry Mae's case out to the van.")


func tick(job: Job, _delta: float) -> void:
	if not job.flags.has("started"):
		job.flags["started"] = true
		# Catering comes in the back way, with the deliveries.
		for c in job.crew:
			if c.cover == "catering":
				job.move_crew(c.id, "crew_bay")
		var h := job.holder("mae_case")
		if h:
			job.toast_for.emit(h.id, "You're carrying Mae's copy of the case.")
	for id in job.calls:
		var r: Dictionary = job.calls[id]
		job.flags["rang:%s:%s" % [r["who"], r["as"]]] = id
	# The stage cleared for the light: back after a few minutes.
	if job.flags.has("clear_until") and job.minutes >= float(job.flags.clear_until):
		job.flags.erase("clear_until")
		_walk(job, "wren", str(job.flags.get("at:wren", "wren")))
		_walk(job, "priya", str(job.flags.get("at:priya", "priya")))
	_rafe(job)
	_confiscate(job)


## Rafe knows every photographer the Courier has. Put him off, and he has a
## word with Priya.
func _rafe(job: Job) -> void:
	var rafe: Character = job.cast.get("rafe")
	var priya: Character = job.cast.get("priya")
	if rafe == null or priya == null:
		return
	for c in job.free_crew():
		if c.flags.has("rafe_told") or not rafe.faces.has(c.id) or rafe.suspicion_of(c.id) < 3:
			continue
		c.flags["rafe_told"] = true
		priya.note("Rafe Doyle from the Courier tells you %s is no photographer of the Courier's that he knows." % job.describe(c.id))
		JobRules.nudge(priya.face_of(c.id), 2)
		job.faced.emit(c.id, "priya", priya.suspicion_of(c.id))
		job.toast_for.emit(c.id, "Rafe has a quiet word with Priya, looking your way.")


## Whoever's held has the Rose's case taken back to its stand.
func _confiscate(job: Job) -> void:
	for c in job.crew:
		if not c.held or not "rose_case" in c.items:
			continue
		job.place_item(c.id, "rose_case", "plinth")
		if str(job.items.get("mae_case", {}).get("at", "")) == "plinth_copy":
			job.place_item(0, "mae_case", "")
		job.flags.erase("swapped")
		job.toast_for.emit(0, "Halberd puts the Rose's case back on its stand.")


func _walk(job: Job, char_id: String, spot_name: String) -> void:
	var ch: Character = job.cast.get(char_id)
	if ch and not ch.minding:
		ch.walk_to(spot_name)


## A Halberd radio to say something over.
static func _radio_to(job: Job, from: Character) -> Character:
	for ch in job.cast.values():
		if ch != from and ch.sheet.radio and ch.sheet.halberd:
			return ch
	return null


func check_end(job: Job) -> String:
	if not job.flags.has("swapped"):
		return ""
	if job.flags.has("hidden"):
		return "swapped"
	for c in job.free_crew():
		if c.node and "rose_case" in c.items and job.venue.zone_at(c.position()) == "outside":
			return "swapped"
	return ""


func at_end(job: Job) -> String:
	if not job.flags.has("swapped"):
		return "gone"
	return "inside"

#endregion
