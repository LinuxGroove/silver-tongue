class_name VantageLiftJob
extends JobDef
## Job 1 at Vantage Tower: get past the lobby and up the lift to level 12,
## Holt's floor, before the gates and the lifts lock at 6:40. A visitor's
## pass from Dana for a meeting Noor confirms; the lift engineer's key from
## Stan, if the front desk has Northline booked for car one; or a ride up
## with Ms Grant, who has a pass and hates a scene, for a parcel Noor is
## expecting.

## When the gates and the lifts lock for the night.
const LOCK := 18 * 60 + 40
## Real seconds Ms Grant waits by the lift for anyone she's taking up.
const WAIT := 25.0
## This close to her when she goes, you go with her.
const NEAR := 4.0
## Who a crewmate on the phone can tell what: [who, words, flag].
const TOLD := [
	["noor", ["halden", "meeting", "analyst", "appointment"], "told:meeting"],
	["dana", ["northline", "car one", "lift", "engineer"], "told:lift"],
	["noor", ["parcel", "courier", "delivery", "swift", "package"], "told:parcel"],
]


func _init() -> void:
	id = "vantage_lift"
	venue_id = "vantage"
	number = 1
	title = "The lobby and the lift"
	venue_name = "Vantage Tower"
	memory_from = ["meridian"]
	briefing = "Vantage Tower. Ezra Holt bought our Rose on the Marlin, and he's taking her up his own tower to be cut into earrings. Before we can do a thing about it, I need you able to get up that building. Halberd has the gates, a new woman runs their security, and the lifts lock at twenty to seven. Dana from the Meridian is on their front desk now, so mind your face. Get yourselves up to twelve, Holt's floor. A visitor's pass, the lift engineer's key, or a ride up with someone who has one: your choice, love."
	goal = "Get up the lift to level 12 before 6:40"
	situation = VantageCast.SITUATIONS.lift
	prize = "the way up to Holt's floor"
	take = 4000
	start = 18 * 60
	end = LOCK
	end_text = "the night lock"
	covers = {
		"investor": {
			"title": "Investor", "names": ["Adrian Pell", "Adriana Pell"], "job": "an analyst with Halden Capital, Vantage's biggest investor",
			"story": "Halden is meeting Mr Holt next Thursday. You're sure it was tonight. Get Noor, his assistant, to say so and Dana will print you a pass.",
			"outfit": "vantage_investor", "for": "Dana, at the front desk",
			"lines": [
				"Good evening. %s, Halden Capital. I'm here for Mr Holt.",
				"I have a meeting with Mr Holt at half past six.",
				"Could you ring up to Noor? She set it up.",
				"Halden doesn't miss meetings. Please check.",
			],
		},
		"engineer": {
			"title": "Lift engineer", "names": ["Ray Dolan", "Rae Dolan"], "job": "an engineer from Northline Lifts",
			"story": "Car one has been out of service for a month. Northline sent you tonight, at last. Stan, the night engineer, keeps the lift key.",
			"outfit": "vantage_engineer", "for": "Stan, the night engineer, in the plant room",
			"lines": [
				"Evening. %s, Northline Lifts. I'm here about car one.",
				"Your front desk should have me booked in.",
				"Here's the work order.",
				"I'll need the lift key to run car two while I work.",
			],
		},
		"courier": {
			"title": "Courier", "names": ["Kit Moreno", "Kit Moreno"], "job": "a rider for Swift Couriers",
			"story": "You have a parcel for Mr Holt that has to be signed for upstairs. Ms Grant, the company's lawyer, goes up at twenty past and hates a fuss.",
			"outfit": "vantage_courier", "for": "Ms Grant, the company's lawyer, at the cafe",
			"lines": [
				"Sorry to bother you. Parcel for Mr Holt, it has to be signed for upstairs.",
				"Swift Couriers. %s.",
				"Are you going up? Could I ride with you?",
				"His office knows it's coming. Ring Noor.",
			],
		},
	}
	cover_order = ["investor", "engineer", "courier"]
	outfits = {
		"vantage_investor": {"job": "vantage_investor", "male": "a navy suit and a red tie, carrying a slim portfolio", "female": "a navy suit, carrying a slim portfolio"},
		"vantage_engineer": {"job": "vantage_engineer", "male": "navy Northline Lifts overalls, carrying a tool case", "female": "navy Northline Lifts overalls, carrying a tool case"},
		"vantage_courier": {"job": "vantage_courier", "male": "an orange courier's jacket", "female": "an orange courier's jacket"},
	}
	staff_looking = ["vantage_engineer"]
	staff_rooms = {"plant": "the plant room", "office": "Halberd's security office"}
	looks = VantageCast.LOOKS
	extras = {
		"lobby": {"job": "vantage_office", "clips": ["Idle", "Idle_Talking", "Idle_TalkingPhone", "Idle_FoldArms"]},
		"lift_lobby": "vantage_office", "outside": "vantage_office", "assist": "vantage_office", "lab": "vantage_lab",
	}
	routine = [
		[18 * 60 + 12, "renata", "office_guard"],
		[18 * 60 + 20, "philippa", "lift_wait_g"],
		[18 * 60 + 26, "renata", "renata"],
	]
	chatter = [
		[18 * 60 + 2, "lupe", "Ms Grant! Flat white, extra hot. Going up at twenty past as usual?", "near"],
		[18 * 60 + 2, "philippa", "As usual, Lupe. Somebody has to read the contracts.", "near"],
		[18 * 60 + 6, "stan", "Teo, it's Stan. Car one's still dead. If Northline ever turns up, send them to the plant room.", "radio"],
		[18 * 60 + 6, "teo", "Copy that, Stan.", "radio"],
		[18 * 60 + 10, "dana", "Noor tells me nothing and Halberd tells me less.", "near"],
		[18 * 60 + 16, "renata", "Teo, Renata. Passes only after half past. No exceptions.", "radio"],
		[18 * 60 + 16, "teo", "Understood.", "radio"],
		[18 * 60 + 28, "lupe", "Closing in half an hour, people.", "near"],
	]
	events = [[18 * 60 + 35, "last_call"]]
	locked = ["gates", "lift_g", "lift_r", "lift_b", "secure", "cutting", "boardroom", "service", "founder"]
	unlocked = ["office", "plant", "break", "lab_office", "pantry"]
	open = ["front"]
	lockdown_doors = ["gates"]
	lockdown_text = "Lockdown. The gates are shut and the lifts are stopped."
	door_texts = {"founder": "Mr Holt's office. Locked.", "boardroom": "Locked.", "secure": "Halberd's secure door. It's shut."}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's security office"}
	items = {
		"visitor_pass": {"name": "a visitor's pass", "at": "", "carry": "a visitor's pass on a lanyard"},
		"lift_key": {"name": "the lift engineer's key", "at": "", "carry": ""},
		"parcel": {
			"name": "the parcel", "at": "", "carry": "carrying a parcel",
			"papers": "a signed-for parcel addressed to Mr E. Holt, Vantage, level 12",
			"belief": "has a parcel for Mr Holt that has to be signed for upstairs", "to": ["philippa", "dana", "noor", "teo"],
		},
		"work_order": {
			"name": "the work order", "at": "", "carry": "",
			"papers": "a Northline Lifts work order for car one at Vantage Tower, in the name of %s", "forged": true,
			"copy": "the job number's from last year and nobody's signed it. It's made up.",
			"belief": "has a Northline work order for car one", "to": ["stan", "dana", "teo"],
		},
	}
	actions = VantageCast.ACTIONS.duplicate(true)
	effects = {
		"issue_pass": {"item": "visitor_pass", "flag": "pass", "toast": "%s prints you a visitor's pass for level 12. Tap it at the gates, then call the lift."},
		"give_key": {"item": "lift_key", "flag": "lift_key", "toast": "%s lends you the lift engineer's key. It opens the gates and runs car two."},
		"let_through": {"open": "@door", "for": 8.0, "flag": "through", "toast": "%s opens the gates for you. The lift will still want a pass."},
		"ride_up": {"flag": "escort", "toast": "%s is going up now. Stay with her: through the gates to the lift."},
	}
	phone = [
		{"id": "reception", "name": "Vantage front desk", "who": "dana"},
		{"id": "holt_office", "name": "Mr Holt's office", "who": "noor"},
		{"id": "security", "name": "Halberd, Vantage Tower", "who": "renata"},
	]
	caller_ids = ["Withheld", "Halden Capital", "Northline Lifts", "Swift Couriers"]
	mae_calls = [
		{"id": "meeting", "label": "Put a meeting in Holt's diary", "who": "noor", "as": "Halden Capital",
			"line": "Good evening, Halden Capital for Mr Holt. Our analyst is on the way over for the half past six with Mr Holt. Could you let the front desk know?",
			"answer": "Half past six? It's not in the... yes, of course. I'll tell the desk.",
			"mae": "I'll ring Holt's assistant as Halden Capital, love. When the desk checks, there'll be a meeting."},
		{"id": "lift", "label": "Book the lift engineer", "who": "dana", "as": "Northline Lifts",
			"line": "Northline Lifts here. We've an engineer on the way tonight for your car one. Can you let your night engineer know?",
			"answer": "Car one? Finally. I'll tell Stan.",
			"mae": "Northline Lifts it is. Dana will know an engineer's coming for car one."},
		{"id": "parcel", "label": "Tell Holt's office a parcel's coming", "who": "noor", "as": "Swift Couriers",
			"line": "Swift Couriers, for Mr Holt. We've a signed-for parcel on the way, our rider's nearly with you.",
			"answer": "For Mr Holt? Fine, send it up. I'll sign.",
			"mae": "I'll tell Holt's office a parcel's on its way, love. Then find someone with a pass who's going up."},
	]
	outcomes = {
		"up": ["YOU'RE UP", "On level 12, Holt's floor, at %s."],
		"late": ["LOCKED OUT", "Twenty to seven: the gates and the lifts locked with the crew still downstairs."],
	}
	wins = ["up"]


func venue() -> Venue:
	return VantageTower.new("lift")


func cast() -> Array[CharacterSheet]:
	return VantageCast.all("lift")


func give_items(crew: Array) -> void:
	for c in crew:
		match c.cover:
			"courier":
				c.items.append("parcel")
			"engineer":
				c.items.append("work_order")


func setup(job: Job) -> void:
	job.flags["night"] = "lift"


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	if what.begins_with("lift_call_"):
		var fl := what.trim_prefix("lift_call_")
		if fl == "g" and c.flags.has("escort") and _waiting(job) and _near_philippa(job, c):
			_ride_with_philippa(job)
			return ""
		return VantageTower.ride_lift(job, c, fl, c.flags.has("pass") or c.flags.has("lift_key"))
	match what:
		"door:gates":
			return VantageTower.gates(job, c, c.flags.has("pass") or c.flags.has("lift_key") or c.flags.has("escort") or c.flags.has("through"))
		"door:lift_g", "door:lift_r", "door:lift_b":
			return "Call the lift with the button beside the doors."
	return null


func prompt_for(_c: CrewInfo, what: String) -> Variant:
	if what.begins_with("lift_call_"):
		return "Call the lift"
	return null


func on_crew_said(job: Job, c: CrewInfo, text: String, _voice: String, earpiece: bool) -> void:
	if earpiece:
		return
	var flag := VantageTower.heard_on_phone(job, c, text, TOLD)
	if flag != "":
		_vouched(job, flag.trim_prefix("told:"))


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"noor":
			if Job.any(said, ["halden", "meeting", "analyst", "investor", "appointment"]):
				if _has(job, "meeting"):
					return Job.fact("good", "Halden Capital rang tonight: their analyst is coming to see Mr Holt.", "Yes, Halden's analyst. Mr Holt's expecting them on twelve.")
				return Job.fact("bad", "Halden Capital is in the diary for next Thursday, not tonight, and nobody's rung.", "Halden? They're in the diary for next Thursday, not tonight.")
			if Job.any(said, ["parcel", "courier", "delivery", "package", "signed for", "sign for"]):
				if _has(job, "parcel"):
					return Job.fact("good", "Swift Couriers rang tonight: a signed-for parcel for Mr Holt is on its way up, and you'll sign for it.", "Yes, I'm expecting a parcel for Mr Holt. Bring it up.")
				return Job.fact("bad", "You're not expecting anything for Mr Holt tonight.", "I'm not expecting anything tonight.")
			return Job.fact("bad", "You don't have anyone like that for Mr Holt tonight.", "I don't have anyone like that for Mr Holt.")
		"dana":
			if c and c.flags.has("pass"):
				return Job.fact("good", "You printed their visitor's pass yourself tonight.", "Yes, I printed their pass myself.")
			if Job.any(said, ["northline", "car one", "lift", "engineer"]):
				if _has(job, "lift"):
					return Job.fact("good", "Northline Lifts rang tonight: their engineer is coming for car one.", "Yes, Northline rang. Their engineer's here for car one.")
				return Job.fact("bad", "Nobody's booked for the lifts tonight. Stan has been chasing Northline for a month.", "Nobody's booked for the lifts tonight.")
			if Job.any(said, ["halden", "meeting", "mr holt"]):
				if _has(job, "meeting"):
					return Job.fact("good", "Noor rang down: a Halden Capital analyst is coming to see Mr Holt tonight.", "Noor says Halden's expected. Go ahead.")
				return Job.fact("bad", "Nobody's signed in for twelve tonight, and Noor hasn't rung down.", "Nobody's signed in for twelve tonight.")
			return Job.fact("bad", "They're not in your book.", "They're not in my book.")
	return {}


func on_action(job: Job, ch: Character, _c: CrewInfo, act: String) -> bool:
	if act == "ride_up" and ch.sheet.id == "philippa" and not job.flags.has("philippa_going"):
		job.flags["philippa_going"] = true
		ch.walk_to("lift_wait_g")
	return false


func on_routine(job: Job, ch: Character, spot_name: String) -> bool:
	if ch.sheet.id == "philippa" and spot_name == "lift_wait_g":
		if job.flags.has("philippa_going"):
			return false
		job.flags["philippa_going"] = true
		for c in job.crew:
			if c.flags.has("escort"):
				job.toast_for.emit(c.id, "Ms Grant's going up. Stay with her: through the gates to the lift.")
	return true


func on_event(job: Job, event_name: String) -> void:
	if event_name == "last_call":
		job.toast_for.emit(0, "The gates and the lifts lock at 6:40.")
		var r: Character = job.cast.get("renata")
		if r:
			r.say_scripted("All units, the lifts lock in five minutes. Anyone without a pass comes down.", job.cast.get("teo"))


func tick(job: Job, _delta: float) -> void:
	for c in job.crew:
		var up: bool = not c.held and c.node != null and VantageTower.floor_of(c.position()) == "b"
		if up != c.inside:
			c.inside = up
			job.crew_changed.emit(c.id)
			if up:
				job.toast_for.emit(c.id, "You're on level 12.")
	# Ms Grant at the lift: up she goes, with anyone she's taking.
	if _waiting(job):
		if not job.flags.has("philippa_at"):
			job.flags["philippa_at"] = job.elapsed
		var near := job.free_crew().filter(func(x): return x.flags.has("escort") and _near_philippa(job, x))
		if not near.is_empty() or job.elapsed - float(job.flags.philippa_at) > WAIT:
			_ride_with_philippa(job)


func check_end(job: Job) -> String:
	var free := job.free_crew()
	if not free.is_empty() and free.all(func(c): return c.inside):
		return "up"
	return ""


func at_end(job: Job) -> String:
	return "up" if job.free_crew().any(func(c): return c.inside) else "late"


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return c.flags.has("lift_key")


func on_mae(job: Job, call_id: String, _ch: Character) -> void:
	_vouched(job, call_id)


## A story's been backed up, by Mae or a crewmate on the phone: the people
## it was told to know it, and pass it on as they would.
func _vouched(job: Job, what: String) -> void:
	match what:
		"meeting":
			_note(job, "noor", "Halden Capital rang: their analyst is coming to see Mr Holt tonight at half past six. It wasn't in the diary, but Halden is Halden. You rang the front desk to say so.")
			_note(job, "dana", "Noor rang down from twelve: a Halden Capital analyst is coming to see Mr Holt tonight. You'll print them a pass once Noor confirms.")
		"lift":
			_note(job, "dana", "Northline Lifts rang: their engineer is coming tonight for car one, at last. You radioed Stan.")
			_note(job, "stan", "Dana radioed: Northline's engineer is on the way for car one, at last.")
		"parcel":
			_note(job, "noor", "Swift Couriers rang: a signed-for parcel for Mr Holt is on its way. You'll sign for it on twelve.")


func _note(job: Job, char_id: String, text: String) -> void:
	var ch: Character = job.cast.get(char_id)
	if ch:
		ch.note(text)


func _has(job: Job, what: String) -> bool:
	return job.flags.has("mae:" + what) or job.flags.has("told:" + what)


## Ms Grant is standing at the lift, waiting to go up.
func _waiting(job: Job) -> bool:
	var p: Character = job.cast.get("philippa")
	return p != null and not job.flags.has("philippa_up") and p.post == "lift_wait_g" and not p.walking and not p.minding


func _near_philippa(job: Job, c: CrewInfo) -> bool:
	var p: Character = job.cast.get("philippa")
	return p != null and c.node != null and c.position().distance_to(p.global_position) < NEAR


## Ms Grant goes up to twelve, taking whoever she said she would (and
## whoever's beside them).
func _ride_with_philippa(job: Job) -> void:
	var p: Character = job.cast.get("philippa")
	job.flags["philippa_up"] = true
	var riders: Array = []
	for c in job.free_crew():
		if c.flags.has("escort") and _near_philippa(job, c):
			for r in VantageTower.riders_with(job, c):
				if not r in riders:
					riders.append(r)
	job.open_for("lift_g", 3.0)
	for r in riders:
		job.move_crew(r.id, "arrive_b")
		job.toast_for.emit(r.id, "You ride up to level 12 with Ms Grant.")
	p.walk_to("philippa_b")
