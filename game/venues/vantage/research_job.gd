class_name VantageResearchJob
extends JobDef
## Job 3 at Vantage Tower: the night before the cutting, take the Rose from
## the gem room on level 9 and get her out of the tower. Bram's checkpoint
## lets through orders Noor confirms, and Dr Lind signs the stone over to
## them; Joost the cutter, who hates the job, will bring her out to someone
## from the museum who means to keep her whole; or Odile the night cleaner
## takes on Marisol's cover, gets them past Bram, and knows the gem room's
## code. Past the checkpoint a scanner hears earpieces, and at 11:05 Dr Lind
## checks the stone: gone without her say-so, and Halberd shuts the tower.

## Renata's round of nine, Dr Lind's check of the stone, and Renata going back down.
const ROUND := 22 * 60 + 55
const CHECK := 23 * 60 + 5
const ROUND_END := 23 * 60 + 12
## Real seconds before the scanner can pick up the same crew member again.
const SCAN_EVERY := 8.0
## How hot a transmission past the checkpoint makes the tower.
const SCAN_HEAT := 3.0
## This close to Joost or Dr Lind, they hand you the Rose.
const HAND := 2.6
const TOLD := [
	["noor", ["ashby", "insur", "vault", "transfer", "orders"], "told:orders"],
	["joost", ["museum", "vance", "curator", "record"], "told:museum"],
	["odile", ["brightway", "marisol", "cover", "off sick"], "told:shift"],
]


func _init() -> void:
	id = "vantage_research"
	venue_id = "vantage"
	number = 3
	title = "The research floor"
	venue_name = "Vantage Tower"
	memory_from = ["meridian"]
	briefing = "This is it, love. The Rose is in the gem room on nine, and at eight tomorrow morning Joost cuts her into pieces. Tonight she's behind Halberd's checkpoint, a glass door and a keypad. Bram's on the checkpoint, Dr Lind's working late, and Joost hates every minute of this job. There's a scanner up there that hears earpieces, so not a word to each other past the checkpoint. Dr Lind checks the stone at five past eleven before she goes home. Bring me the Rose."
	goal = "Take the Rose from the gem room and get her out of the tower"
	situation = VantageCast.SITUATIONS.research
	prize = "the Rose"
	take = 20000
	start = 22 * 60 + 40
	end = 23 * 60 + 20
	end_text = "the shift change"
	covers = {
		"insurer": {
			"title": "Insurer", "names": ["Hal Mercer", "Hannah Mercer"], "job": "a loss adjuster from Ashby Mutual, the Rose's insurers",
			"story": "Ashby won't cover the Rose in a lab overnight. You have Mr Holt's signed orders moving her to the vault tonight. They're forged: Noor, his assistant, has to say otherwise.",
			"outfit": "vantage_insurer", "for": "Bram, on the checkpoint, and Dr Lind",
			"lines": [
				"Evening. %s, Ashby Mutual. I'm here for the stone.",
				"Mr Holt's signed orders. The Rose goes down to the vault tonight.",
				"Ring his office if you like. Noor knows all about it.",
				"Ashby won't cover her sitting in a lab overnight.",
			],
		},
		"curator": {
			"title": "Curator", "names": ["Dr Simon Arden", "Dr Sonia Arden"], "job": "a curator from the Caldera Museum",
			"story": "The museum showed the Rose at the gala and wants a record of her whole, before she's cut. Joost, the cutter, hates the job. He might bring her out to you.",
			"outfit": "vantage_tweed", "for": "Joost, the gemcutter, in the break room",
			"lines": [
				"Joost? %s, from the Caldera Museum.",
				"Cutting her is a crime. You know it is.",
				"The museum wants a record of her whole, before tomorrow.",
				"Photographs and measurements. Dr Vance sends his regards.",
			],
		},
		"cleaner": {
			"title": "Cleaner", "names": ["Luis Ortega", "Lucia Ortega"], "job": "a night cleaner from Brightway Cleaning",
			"story": "Odile cleans nine with Marisol, who's off sick tonight. You're the cover. Odile has watched Joost punch the gem room's code a hundred times.",
			"outfit": "vantage_cleaner", "for": "Odile, the night cleaner, in the break room",
			"lines": [
				"Hi. Brightway sent me. I'm covering for Marisol tonight.",
				"Where do you want me?",
				"I'm with Odile. Ask her.",
				"Long night? How do you get into the gem room, anyway?",
			],
		},
	}
	cover_order = ["insurer", "curator", "cleaner"]
	outfits = {
		"vantage_insurer": {"job": "vantage_insurer", "male": "a dark suit, carrying an attache case", "female": "a dark suit, carrying an attache case"},
		"vantage_tweed": {"job": "vantage_tweed", "male": "a tweed jacket with a museum lanyard", "female": "a tweed jacket with a museum lanyard"},
		"vantage_cleaner": {"job": "vantage_cleaner", "male": "a teal Brightway cleaning tabard", "female": "a teal Brightway cleaning tabard"},
	}
	staff_looking = ["vantage_cleaner"]
	staff_rooms = {"lab": "the lab", "lab_office": "Dr Lind's office", "cutting": "the gem room"}
	looks = VantageCast.LOOKS
	extras = {"lobby": "vantage_cleaner", "outside": "vantage_office"}
	routine = [
		[22 * 60 + 50, "odile", "odile_check"],
		[22 * 60 + 58, "joost", "joost_cut"],
		[23 * 60 + 1, "odile", "odile_lab"],
		[23 * 60 + 10, "wes", "wes_break"],
	]
	chatter = [
		[22 * 60 + 42, "joost", "Ten hours. Then I take her apart for a rich man's wife.", "near"],
		[22 * 60 + 44, "odile", "Marisol off again. All of nine on my own.", "near"],
		[22 * 60 + 48, "bram", "Renata, it's Bram. Nine's quiet. Dr Lind's still in, and the cutter.", "radio"],
		[22 * 60 + 48, "renata", "Copy. I'm up at five to.", "radio"],
		[23 * 60 + 2, "margot", "Wes, I'll check the stone at five past and then I'm going home.", "near"],
		[23 * 60 + 2, "wes", "Night, Dr Lind.", "near"],
	]
	events = [[ROUND, "round"], [CHECK, "check"], [ROUND_END, "round_end"]]
	locked = ["secure", "cutting", "gates", "lift_g", "lift_r", "lift_b", "founder", "boardroom", "service"]
	unlocked = ["break", "lab_office", "office", "plant", "pantry"]
	open = ["front"]
	lockdown_doors = ["secure", "cutting", "gates"]
	lockdown_text = "Lockdown. Halberd has shut the tower: the lifts are stopped and the doors are locked."
	door_texts = {"cutting": "Locked. There's a keypad by the door.", "founder": "Mr Holt's office. Locked."}
	keypads = {"cutting_pad": {"door": "cutting", "code": VantageCast.CUTTING_CODE, "label": "Gem room"}}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's security office"}
	items = {
		"orders": {
			"name": "the transfer orders", "at": "", "carry": "",
			"papers": "a transfer order on Vantage paper, signed E. Holt, moving the Rose to the basement vault tonight at the request of Ashby Mutual, for %s to carry out", "forged": true,
			"copy": "the signature's traced, and Vantage's vault is in the car park, not the basement. It's forged.",
			"belief": "has Mr Holt's signed orders to move the Rose to the vault tonight", "to": ["bram", "margot", "renata"],
		},
		"rose": {"name": "the Rose", "at": "cradle", "carry": "", "hot": true},
	}
	actions = VantageCast.ACTIONS.duplicate(true)
	effects = {
		"let_through": {"open": "@door", "for": 8.0, "flag": "cleared", "toast": "%s opens the secure door for you. Not a word on the earpiece in there."},
		"take_on": {"flag": "cleaner", "toast": "%s takes you on as Marisol's cover. Tell Bram on the checkpoint you're with her."},
	}
	hot_words = ["the gem room", "scanner"]
	phone = [
		{"id": "reception", "name": "Vantage front desk", "who": "dana"},
		{"id": "holt_office", "name": "Mr Holt's office", "who": "noor"},
		{"id": "joost", "name": "Joost Verbeke, mobile", "who": "joost"},
		{"id": "cleaning", "name": "Brightway Cleaning, night line", "who": "odile"},
		{"id": "checkpoint", "name": "Halberd checkpoint, level 9", "who": "bram"},
	]
	caller_ids = ["Withheld", "Ashby Mutual", "Caldera Museum", "Brightway Cleaning"]
	mae_calls = [
		{"id": "orders", "label": "Tell Noor the insurers are coming", "who": "noor", "as": "Ashby Mutual",
			"line": "Ashby Mutual for Mr Holt's office. Mr Holt signed the transfer this afternoon: our man moves the stone to your vault tonight.",
			"answer": "He signed it? Fine. I'll put it in the diary.",
			"mae": "I'll ring Noor as the insurers, love. When the checkpoint asks her, the orders will check out."},
		{"id": "museum", "label": "Have the museum ring Joost", "who": "joost", "as": "Caldera Museum",
			"line": "Dr Vance's office at the Caldera Museum. Our curator is coming tonight to record the Rose whole, before she's cut. Dr Vance hopes you'll help.",
			"answer": "Vance? Tonight? Ja. Ja, of course I'll help.",
			"mae": "I'll ring Joost from the museum, love. He only wants an excuse."},
		{"id": "shift", "label": "Tell Odile her cover's coming", "who": "odile", "as": "Brightway Cleaning",
			"line": "Brightway office. Marisol's off sick tonight, so we're sending you cover for nine.",
			"answer": "Cover? Good. I'll show them round.",
			"mae": "I'll ring Odile as Brightway, love. You're her cover tonight."},
	]
	outcomes = {
		"taken": ["THE ROSE", "Out of Vantage Tower with the Rose at %s."],
		"late": ["TOO LATE", "Twenty past eleven: Halberd's night shift came on with the Rose still on nine."],
		"found": ["FOUND OUT", "Dr Lind found the Rose gone, and Halberd shut the tower with the crew inside."],
	}
	wins = ["taken"]


func venue() -> Venue:
	return VantageTower.new("research")


func cast() -> Array[CharacterSheet]:
	return VantageCast.all("research")


func give_items(crew: Array) -> void:
	if crew.is_empty():
		return
	for c in crew:
		if c.cover == "insurer":
			c.items.append("orders")
			return


func setup(job: Job) -> void:
	job.flags["night"] = "research"


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	if what.begins_with("lift_call_"):
		return VantageTower.ride_lift(job, c, what.trim_prefix("lift_call_"), true)
	var d = job.venue.doors.get(what.trim_prefix("door:")) if what.begins_with("door:") else null
	match what:
		"door:gates":
			return VantageTower.gates(job, c, true)
		"door:lift_g", "door:lift_r", "door:lift_b":
			return "Call the lift with the button beside the doors."
		"door:secure":
			if d == null or d.is_open:
				return null
			if job.heat.level >= Heat.LOCKDOWN or job.flags.has("shut"):
				return "The secure door's locked down."
			# Out is a push button; in is Bram's say.
			if job.venue.zone_at(c.position() + Vector3.UP) in ["lab", "lab_office", "cutting"]:
				job.open_for("secure", 5.0)
				return ""
			if c.flags.has("cleared") or c.flags.has("handed"):
				job.open_for("secure", 6.0)
				return ""
			return "The secure door. Bram opens it for people he's cleared."
		"item:rose":
			if c.flags.has("handed") and str(job.items.get("rose", {}).get("at", "")) == "cradle":
				_hand_rose(job, c, "Dr Lind signs the Rose over to you. She's yours to take down.")
				return ""
	return null


func prompt_for(_c: CrewInfo, what: String) -> Variant:
	if what.begins_with("lift_call_"):
		return "Call the lift"
	return null


func on_crew_said(job: Job, c: CrewInfo, text: String, _voice: String, earpiece: bool) -> void:
	if earpiece:
		if not c.held and c.node != null and job.venue.zone_at(c.position() + Vector3.UP) in VantageTower.SECURE:
			_scanned(job, c)
		return
	var flag := VantageTower.heard_on_phone(job, c, text, TOLD)
	if flag != "":
		_vouched(job, flag.trim_prefix("told:"))


## The checkpoint's scanner picks up an earpiece past it: Bram (and Renata,
## if she's on nine) know who, and the tower heats up.
func _scanned(job: Job, c: CrewInfo) -> void:
	var key := "scan:%d" % c.id
	if job.flags.has(key) and job.elapsed - float(job.flags[key]) < SCAN_EVERY:
		return
	var first := not job.flags.has(key)
	job.flags[key] = job.elapsed
	job.heat.bump(SCAN_HEAT)
	job.toast_for.emit(c.id, "The checkpoint's scanner picked up your earpiece.")
	for id in ["bram", "renata"]:
		var ch: Character = job.cast.get(id)
		if ch == null or ch.minding or VantageTower.floor_of(ch.global_position) != "r":
			continue
		var f := ch.face_of(c.id)
		JobRules.nudge(f, 2 if first else 1)
		job.faced.emit(c.id, id, int(f.suspicion))
		if id == "bram" and first:
			ch.say_scripted("Whoever's on an earpiece in there, the scanner's lit up. Turn it off.")
		ch.event("The scanner by the checkpoint lights up: someone is transmitting on an earpiece past it. It's %s." % job.describe(c.id), c.id)


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"noor":
			if Job.any(said, ["ashby", "insur", "vault", "transfer", "orders"]):
				if _has(job, "orders"):
					return Job.fact("good", "Ashby Mutual rang tonight: Mr Holt signed a transfer this afternoon, and their man moves the Rose to the vault tonight.", "Yes, Mr Holt signed a transfer for the insurers. The stone goes to the vault tonight.")
				return Job.fact("bad", "Mr Holt is at home and hasn't signed anything about the stone. You'd know.", "Mr Holt's at home. He hasn't signed anything about the stone tonight.")
			return Job.fact("bad", "You don't know anything about them.", "I don't know anything about that.")
		"odile":
			if c and c.flags.has("cleaner"):
				return Job.fact("good", "You took them on yourself tonight as Marisol's cover.", "Yes, they're with me. Marisol's cover.")
			if Job.any(said, ["brightway", "marisol", "cover", "clean"]) and _has(job, "shift"):
				return Job.fact("good", "Brightway rang: they're sending cover for Marisol tonight.", "Brightway said they'd send cover. That'll be them.")
			return Job.fact("bad", "You're on your own tonight. Nobody's told you about any cover.", "I'm on my own tonight. Marisol's off.")
		"margot":
			if c and c.flags.has("handed"):
				return Job.fact("good", "You're signing the stone over to them yourself.", "They're with me.")
			return Job.fact("bad", "You're not expecting anyone.", "I'm not expecting anyone.")
	return {}


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"hand_over":
			if job.flags.has("handed") or str(job.items.get("rose", {}).get("at", "")) != "cradle":
				return true
			job.flags["handed"] = c.id
			c.flags["handed"] = true
			ch.walk_to("rose")
			job.open_for("cutting", 45.0)
			job.toast_for.emit(c.id, "Dr Lind is taking you into the gem room to sign the Rose over. Go with her.")
			return true
		"bring_stone":
			if job.flags.has("fetch") or str(job.items.get("rose", {}).get("at", "")) != "cradle":
				return true
			job.flags["fetch"] = c.id
			job.flags["joost"] = "going"
			ch.walk_to("rose")
			job.toast_for.emit(c.id, "Joost's going to fetch the Rose for you. Wait for him in the break room.")
			return true
	return false


func on_routine(job: Job, ch: Character, _spot: String) -> bool:
	if ch.sheet.id == "joost" and job.flags.has("joost"):
		return false
	if ch.sheet.id == "margot" and job.flags.has("handed"):
		return false
	return true


func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"round":
			_walk(job, "renata", "renata_r")
		"round_end":
			_walk(job, "renata", "renata")
		"check":
			_check_stone(job)


## Dr Lind checks the gem room before she goes home. The Rose gone without
## her say-so or Joost's, and Halberd shuts the tower.
func _check_stone(job: Job) -> void:
	var m: Character = job.cast.get("margot")
	if m == null or job.flags.has("handed"):
		return
	_walk(job, "margot", "rose")
	if str(job.items.get("rose", {}).get("at", "")) == "cradle":
		return
	if job.flags.has("joost"):
		var j: Character = job.cast.get("joost")
		m.say_scripted("Joost, have you got her?")
		if j:
			j.say_scripted("Ja, ja. She's with me, under the good lamp.")
		return
	job.flags["shut"] = true
	job.heat.bump(Heat.LEVELS[Heat.LOCKDOWN] + 4.0)
	job.lock("front", true)
	job.set_door("front", false)
	m.say_scripted("Bram! The Rose is gone. Shut the building!", job.cast.get("bram"))
	for ch in job.cast.values():
		ch.note("Dr Lind found the Rose gone from the gem room. Halberd has shut the tower: nobody leaves.")
	job.toast_for.emit(0, "Dr Lind has found the Rose gone. Halberd is shutting the tower.")


func tick(job: Job, _delta: float) -> void:
	_joost(job)
	_margot(job)
	var h := job.holder("rose")
	if h:
		h.inside = not h.held
		if not h.flags.has("has_rose"):
			h.flags["has_rose"] = true
			job.set_goal(h.id, "Get the Rose out of the tower")
			job.crew_changed.emit(h.id)


## Joost fetches the Rose from the gem room, brings her back to the break
## room, and hands her to whoever asked once they're beside him.
func _joost(job: Job) -> void:
	var j: Character = job.cast.get("joost")
	if j == null or not job.flags.has("joost"):
		return
	match str(job.flags.joost):
		"going":
			if j.walking or j.post != "rose":
				return
			if str(job.items.get("rose", {}).get("at", "")) != "cradle":
				job.flags["joost"] = "gone"
				return
			job.place_item(0, "rose", "")
			job.flags["fetched"] = true
			job.flags["joost"] = "bringing"
			j.walk_to("joost_break")
		"bringing":
			var c := job.crew_by_id(int(job.flags.fetch))
			if c and not c.held and c.node and c.position().distance_to(j.global_position) < HAND:
				job.flags["joost"] = "given"
				_hand_rose(job, c, "Joost puts the Rose in your hand. \"Keep her whole.\"")


## Dr Lind, at the gem room to sign the stone over, hands it to whoever
## she's signing it to once they're beside her.
func _margot(job: Job) -> void:
	var m: Character = job.cast.get("margot")
	if m == null or not job.flags.has("handed") or m.walking or m.post != "rose":
		return
	if str(job.items.get("rose", {}).get("at", "")) != "cradle":
		return
	var c := job.crew_by_id(int(job.flags.handed))
	if c and not c.held and c.node and c.position().distance_to(m.global_position) < HAND:
		_hand_rose(job, c, "Dr Lind lifts the Rose out of her cradle and signs her over to you.")


func _hand_rose(job: Job, c: CrewInfo, text: String) -> void:
	job.give_item(c.id, "rose")
	job.toast_for.emit(c.id, text)


func check_end(job: Job) -> String:
	var h := job.holder("rose")
	if h and not h.held and h.node != null and job.venue.zone_at(h.position() + Vector3.UP) == "outside":
		return "taken"
	return ""


func at_end(job: Job) -> String:
	return "found" if job.flags.has("shut") else "late"


func can_take(_job: Job, c: CrewInfo, item: String) -> String:
	if item == "rose" and c.held:
		return "Not now."
	return ""


func on_heat(job: Job, was: int, now: int) -> void:
	if now == Heat.LOCKDOWN and was < Heat.LOCKDOWN:
		job.lock("front", true)
		job.set_door("front", false)
	elif was == Heat.LOCKDOWN and now < Heat.LOCKDOWN and not job.flags.has("shut"):
		job.lock("front", false)


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	if zone == "cutting" and (ch.sheet.staff or ch.sheet.halberd) and not c.flags.has("handed"):
		ch.event("%s is in the gem room, where nobody goes without Dr Lind." % job.describe(c.id).capitalize(), c.id, "seen")
		return true
	return false


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return c.flags.has("cleared") or c.flags.has("handed") or c.flags.has("cleaner")


func on_mae(job: Job, call_id: String, _ch: Character) -> void:
	_vouched(job, call_id)


func _vouched(job: Job, what: String) -> void:
	match what:
		"orders":
			_note(job, "noor", "Ashby Mutual rang for Mr Holt: he signed a transfer this afternoon, and their man moves the Rose to the vault tonight. You've put it in the diary.")
		"museum":
			var j: Character = job.cast.get("joost")
			if j:
				j.note("Dr Vance's office at the Caldera Museum rang: their curator is coming tonight to record the Rose whole before she's cut, and Dr Vance hopes you'll help. You'd do anything to keep her whole.")
				VantageBoardJob._warm(j)
		"shift":
			_note(job, "odile", "Brightway rang: Marisol's off sick, so they're sending you cover for nine tonight.")


func _note(job: Job, char_id: String, text: String) -> void:
	var ch: Character = job.cast.get(char_id)
	if ch:
		ch.note(text)


func _walk(job: Job, char_id: String, spot_name: String) -> void:
	var ch: Character = job.cast.get(char_id)
	if ch and not ch.minding:
		ch.walk_to(spot_name)


func _has(job: Job, what: String) -> bool:
	return job.flags.has("mae:" + what) or job.flags.has("told:" + what)
