class_name VantageBoardJob
extends JobDef
## Job 2 at Vantage Tower: sit in on the board meeting on level 12 and get
## its decision (when and where the Rose is cut, and who goes near her) down
## to the lobby. Noor needs a minute-taker the agency hasn't sent; Mirela
## from Bellweather is a pair of hands short for the coffee, which goes in
## through the pantry's service door just before the vote; Halden Capital
## has an observer's seat, with a letter Ms Grant checks with Noor. The
## pantry's service door hears the vote too, while it's open.

## The night's moments: the board sits, the coffee goes in, the vote, the
## coffee comes out, the meeting closes.
const START := 19 * 60 + 40
const COFFEE := 19 * 60 + 52
const DECISION := 19 * 60 + 58
const SERVED := 20 * 60 + 1
const CLOSE := 20 * 60 + 6
## At the pantry's service door, this close to its ear, you hear the vote.
const EAR := 2.5
const TOLD := [
	["dana", ["kestrel", "temp", "minute", "agency", "staffing"], "told:temp"],
	["noor", ["halden", "observer", "letter", "the vote"], "told:halden"],
	["mirela", ["bellweather", "hands", "help", "server", "short"], "told:hands"],
]


func _init() -> void:
	id = "vantage_board"
	venue_id = "vantage"
	number = 2
	title = "The board meeting"
	venue_name = "Vantage Tower"
	memory_from = ["meridian"]
	briefing = "Holt's board meets tonight on twelve to sign off the cutting: when, where, and who gets near her. I want to know what they decide, love, word for word. You know the way up now. Noor, his assistant, is short a minute-taker. Bellweather does the coffee and they're always a pair of hands short. And Halden Capital have an observer's chair they never use, and I've a letter that says they do. Sit in, listen, and bring it down to the lobby. Renata's on the boardroom doors, and she's sharp, so don't get clever with her."
	goal = "Hear the board's decision and get it down to the lobby"
	situation = VantageCast.SITUATIONS.board
	prize = "the board's decision"
	take = 8000
	start = 19 * 60 + 30
	end = 20 * 60 + 20
	end_text = "the floor's cleared"
	covers = {
		"temp": {
			"title": "Minute-taker", "names": ["Owen Marsh", "Olivia Marsh"], "job": "a temp from Kestrel Staffing",
			"story": "The board's secretary is off sick and Noor asked Kestrel Staffing for a minute-taker. They never sent one. You're it, if the front desk says Kestrel signed you in.",
			"outfit": "vantage_temp", "for": "Noor, Mr Holt's assistant",
			"lines": [
				"Hi. %s, from Kestrel Staffing. I'm here to take the minutes.",
				"Noor? The agency said to ask for you.",
				"I signed in at the desk downstairs.",
				"Shorthand, a hundred and twenty words a minute.",
			],
		},
		"server": {
			"title": "Server", "names": ["Marco Pinto", "Mara Pinto"], "job": "a server from Bellweather Catering",
			"story": "Bellweather does the board's coffee. Mirela runs it from the pantry, and tonight she's on her own. The coffee goes in just before the vote.",
			"outfit": "vantage_server", "for": "Mirela, in the pantry",
			"lines": [
				"Bellweather sent me. Extra hands for the coffee.",
				"Busy night? Where do you want me?",
				"I've done boards before. In, pour, out, nobody notices.",
				"%s. Ring the office if you like.",
			],
		},
		"observer": {
			"title": "Observer", "names": ["Julian Ashe", "Juliet Ashe"], "job": "Halden Capital's observer",
			"story": "Halden Capital has an observer's seat at Vantage's board. You have a letter of authority from Halden's chair: a good copy. Ms Grant will check it with Noor.",
			"outfit": "vantage_investor", "for": "Ms Grant, the general counsel",
			"lines": [
				"Good evening. %s, Halden Capital. I'm here to observe the vote.",
				"Here's my letter of authority from our chair.",
				"Mr Holt agreed it with our office. Noor will know.",
				"I'll sit by the wall and say nothing.",
			],
		},
	}
	cover_order = ["temp", "server", "observer"]
	outfits = {
		"vantage_temp": {"job": "vantage_temp", "male": "a grey suit, with a notepad", "female": "a grey suit, with a notepad"},
		"vantage_server": {"job": "vantage_server", "male": "a black server's suit", "female": "a black server's suit"},
		"vantage_investor": {"job": "vantage_investor", "male": "a navy suit and a red tie, carrying a slim portfolio", "female": "a navy suit, carrying a slim portfolio"},
	}
	staff_looking = ["vantage_server"]
	staff_rooms = {"pantry": "the pantry", "boardroom": "the boardroom, during the meeting", "founder": "Mr Holt's office"}
	looks = VantageCast.LOOKS
	extras = {
		"boardroom": {"job": "vantage_board", "clips": ["Sitting_Idle", "Sitting_Talking"]},
		"assist": "vantage_office", "lobby": "vantage_office", "outside": "vantage_office",
	}
	routine = [
		[19 * 60 + 36, "ezra", "ezra"],
	]
	chatter = [
		[19 * 60 + 31, "mirela", "One server for twelve people's coffee. Bellweather, I swear.", "near"],
		[19 * 60 + 32, "noor", "Kestrel promised me a minute-taker an hour ago. An hour!", "near"],
		[19 * 60 + 34, "renata", "Teo, Renata. Twelve's closed from now. Nobody up without Noor.", "radio"],
		[19 * 60 + 34, "teo", "Copy.", "radio"],
		[19 * 60 + 44, "margot", "Slide four is the schedule, Joost. Don't argue with them.", "near"],
		[19 * 60 + 44, "joost", "I don't argue. I weep.", "near"],
		[19 * 60 + 50, "mirela", "Coffee in two minutes. Where's my trolley?", "near"],
	]
	events = [[START, "start"], [COFFEE, "coffee"], [DECISION, "decision"], [SERVED, "served"], [CLOSE, "close"]]
	locked = ["gates", "lift_g", "lift_r", "lift_b", "boardroom", "service", "founder", "secure", "cutting"]
	unlocked = ["pantry", "office", "plant", "break", "lab_office"]
	open = ["front"]
	lockdown_doors = ["boardroom", "service", "gates"]
	lockdown_text = "Lockdown. The boardroom's shut and the lifts are stopped."
	door_texts = {"founder": "Mr Holt's office. Locked.", "secure": "Halberd's secure door. It's shut."}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's security office"}
	items = {
		"letter": {
			"name": "the letter of authority", "at": "", "carry": "",
			"papers": "a letter on Halden Capital's paper, signed by its chair, naming %s as Halden's observer at tonight's board", "forged": true,
			"copy": "the signature's printed and the letterhead is last year's. It's a copy.",
			"belief": "has a letter of authority from Halden Capital's chair", "to": ["philippa", "renata", "noor"],
		},
	}
	actions = VantageCast.ACTIONS.duplicate(true)
	effects = {
		"seat_minutes": {"flag": "minutes", "open": "boardroom", "for": 30.0, "toast": "%s takes you on as the minute-taker. The boardroom's through the doors on the left: sit at the end and write."},
		"seat_observer": {"flag": "observer", "open": "boardroom", "for": 30.0, "toast": "%s takes you in as Halden's observer. Sit by the wall and say nothing."},
		"put_to_work": {"flag": "serving", "outfit": "vantage_server", "toast": "%s puts you to work. The coffee goes into the boardroom through the service door at 7:52."},
		"let_through": {"open": "@door", "for": 10.0, "flag": "through", "toast": "%s opens the boardroom door for you."},
	}
	hot_words = ["the vote", "the decision"]
	phone = [
		{"id": "reception", "name": "Vantage front desk", "who": "dana"},
		{"id": "holt_office", "name": "Mr Holt's office", "who": "noor"},
		{"id": "catering", "name": "Bellweather Catering, level 12", "who": "mirela"},
	]
	caller_ids = ["Withheld", "Kestrel Staffing", "Halden Capital", "Bellweather Catering"]
	mae_calls = [
		{"id": "temp", "label": "Sign the temp in at the desk", "who": "dana", "as": "Kestrel Staffing",
			"line": "Kestrel Staffing here. Our minute-taker for Vantage's board tonight is on the way up. Could you sign them in for us?",
			"answer": "Kestrel? Fine, I'll put them in the book.",
			"mae": "I'll ring the front desk as the agency. When Noor checks, Dana will have you signed in."},
		{"id": "halden", "label": "Tell Noor Halden's sending someone", "who": "noor", "as": "Halden Capital",
			"line": "Halden Capital, the chair's office. We're sending an observer to sit in on tonight's vote, as agreed with Mr Holt.",
			"answer": "An observer? I'll let Ms Grant know.",
			"mae": "I'll ring Noor from Halden's office, love. Then show Ms Grant the letter."},
		{"id": "hands", "label": "Tell Mirela help is coming", "who": "mirela", "as": "Bellweather Catering",
			"line": "Bellweather office. We're sending you another pair of hands for the board's coffee.",
			"answer": "Thank God. Send them in.",
			"mae": "I'll tell Mirela her office is sending help, love. She'll be glad of you."},
	]
	outcomes = {
		"out": ["DECIDED", "Down in the lobby with the board's decision at %s."],
		"missed": ["MISSED IT", "The board voted without anyone from the crew there to hear it."],
		"stuck": ["STILL UPSTAIRS", "The crew heard the vote, but Halberd cleared twelve with them still on it."],
	}
	wins = ["out"]


func venue() -> Venue:
	return VantageTower.new("board")


func cast() -> Array[CharacterSheet]:
	return VantageCast.all("board")


func give_items(crew: Array) -> void:
	if crew.is_empty():
		return
	for c in crew:
		if c.cover == "observer":
			c.items.append("letter")
			return


func setup(job: Job) -> void:
	job.flags["night"] = "board"


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	if what.begins_with("lift_call_"):
		return VantageTower.ride_lift(job, c, what.trim_prefix("lift_call_"), true)
	var d = job.venue.doors.get(what.trim_prefix("door:")) if what.begins_with("door:") else null
	match what:
		"door:gates":
			return VantageTower.gates(job, c, true)
		"door:lift_g", "door:lift_r", "door:lift_b":
			return "Call the lift with the button beside the doors."
		"door:boardroom":
			if d == null or d.is_open:
				return null
			if job.flags.has("closed"):
				return "The meeting's over. The boardroom's locked."
			if job.heat.level < Heat.LOCKDOWN and (_seated(c) or (c.flags.has("serving") and job.flags.has("coffee"))):
				job.open_for("boardroom", 6.0)
				return ""
			return "Renata's on the door: the board meets in closed session." if job.flags.has("meeting") else "The board hasn't sat down yet. Renata's on the door."
		"door:service":
			if d == null or d.is_open:
				return null
			return "The service door into the boardroom. It stays shut until the coffee goes in."
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
			if c and c.flags.has("minutes"):
				return Job.fact("good", "You took them on as the minute-taker yourself.", "Yes, that's my minute-taker. Let them in.")
			if Job.any(said, ["halden", "observer", "letter", "authority"]):
				if _has(job, "halden"):
					return Job.fact("good", "Halden Capital's chair's office rang tonight: they're sending an observer to the vote, agreed with Mr Holt.", "Halden's observer? Yes, their office rang. Mr Holt agreed it.")
				return Job.fact("bad", "Halden didn't say they were sending anyone tonight, and Mr Holt hasn't mentioned it.", "Halden didn't tell me they were sending anyone.")
			if Job.any(said, ["kestrel", "temp", "minute", "agency", "staffing"]):
				if _has(job, "temp"):
					return Job.fact("good", "Kestrel Staffing's temp signed in at the front desk tonight.", "Kestrel's temp? Yes, Dana signed them in.")
				return Job.fact("bad", "You're still waiting for Kestrel's temp, and you haven't met this one.", "I'm waiting for Kestrel's temp, but I haven't met this one.")
			if Job.any(said, ["bellweather", "server", "coffee", "catering"]):
				if c and c.flags.has("serving"):
					return Job.fact("good", "Mirela has taken them on for the coffee.", "They're with Mirela. They're fine.")
				return Job.fact("bad", "Catering is Mirela's business, not yours.", "Ask Mirela, it's her coffee.")
			return Job.fact("bad", "You don't know them, and they're not in Mr Holt's diary.", "I don't know them.")
		"dana":
			if Job.any(said, ["kestrel", "temp", "minute", "agency", "staffing"]):
				if _has(job, "temp"):
					return Job.fact("good", "Kestrel Staffing rang tonight and you signed their temp into the book.", "Yes, Kestrel's temp. I signed them in.")
				return Job.fact("bad", "Nobody from an agency has signed in with you tonight.", "Nobody from an agency signed in with me tonight.")
			return Job.fact("bad", "They're not in your book.", "They're not in my book.")
		"mirela":
			if c and c.flags.has("serving"):
				return Job.fact("good", "You put them to work on the coffee yourself.", "They're mine. Bellweather.")
			return Job.fact("bad", "They don't work for you.", "Not one of mine.")
	return {}


func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"start":
			job.flags["meeting"] = true
			_walk(job, "philippa", "seat_n2")
			for ch in job.cast.values():
				if ch.sheet.staff or ch.sheet.halberd:
					ch.note("The board meeting has started. The boardroom is closed to anyone but the board, Ms Grant, Dr Lind, the cutter, a minute-taker and Halden's observer.")
			job.toast_for.emit(0, "The board's sitting down.")
		"coffee":
			job.flags["coffee"] = true
			job.set_door("service", true)
			_walk(job, "mirela", "mirela_serve")
			for c in job.crew:
				if c.flags.has("serving"):
					job.toast_for.emit(c.id, "Coffee. Follow Mirela through the service door.")
		"decision":
			_decide(job)
		"served":
			_walk(job, "mirela", "mirela")
		"close":
			job.flags["closed"] = true
			job.set_door("service", false)
			_walk(job, "ezra", "ezra_office")
			_walk(job, "philippa", "philippa_b")
			_walk(job, "margot", "lift_wait_b")
			_walk(job, "joost", "arrive_b")
			job.toast_for.emit(0, "The meeting's over.")


## The vote: everyone from the crew in the room hears it, and so does
## anyone at the open service door in the pantry.
func _decide(job: Job) -> void:
	job.flags["decided"] = true
	var ez: Character = job.cast.get("ezra")
	if ez:
		ez.say_scripted("Then it's agreed. Joost cuts the Rose next Tuesday at eight in the morning, in the gem room on nine. Until then she stays behind the checkpoint, and nobody goes near her but Dr Lind and Joost.")
	var door: HotelDoor = job.venue.doors.service
	var ear: Vector3 = job.spot("service_ear").origin
	for c in job.free_crew():
		if c.node == null:
			continue
		var p: Vector3 = c.position()
		var heard: bool = job.venue.zone_at(p + Vector3.UP) == "boardroom"
		if not heard and door.is_open and job.venue.zone_at(p + Vector3.UP) == "pantry" and Vector2(p.x - ear.x, p.z - ear.z).length() < EAR:
			heard = true
		if heard:
			c.flags["decision"] = true
			job.toast_for.emit(c.id, "You heard it: the Rose is cut next Tuesday at 8 am, in the gem room on level 9, and only Dr Lind and the cutter go near her. Get it down to the lobby.")
			job.set_goal(c.id, "Get the decision down to the lobby")
	for id in ["margot", "joost", "philippa", "noor"]:
		var ch: Character = job.cast.get(id)
		if ch:
			ch.note("The board voted: " + VantageCast.DECISION)


func check_end(job: Job) -> String:
	for c in job.free_crew():
		if c.flags.has("decision") and c.node != null and VantageTower.floor_of(c.position()) == "g":
			c.inside = true
			return "out"
	if job.flags.has("closed") and not job.crew.any(func(c): return c.flags.has("decision")):
		return "missed"
	return ""


func at_end(job: Job) -> String:
	return "stuck" if job.crew.any(func(c): return c.flags.has("decision")) else "missed"


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return _seated(c) or c.flags.has("serving")


func on_mae(job: Job, call_id: String, _ch: Character) -> void:
	_vouched(job, call_id)


func _vouched(job: Job, what: String) -> void:
	match what:
		"temp":
			_note(job, "dana", "Kestrel Staffing rang: their temp minute-taker for the board is on the way up. You've signed them into the book.")
		"halden":
			_note(job, "noor", "Halden Capital's chair's office rang: they're sending an observer to sit in on tonight's vote, as agreed with Mr Holt.")
			_note(job, "philippa", "Noor told you Halden Capital's office rang: they're sending an observer to the vote tonight.")
		"hands":
			var m: Character = job.cast.get("mirela")
			if m:
				m.note("Bellweather's office rang: they're sending you another pair of hands for the coffee tonight. Thank God.")
				_warm(m)


## Someone who was told to expect you starts off easier on you.
static func _warm(ch: Character) -> void:
	ch.sheet.start_suspicion = mini(ch.sheet.start_suspicion, JobRules.TRUST)
	for id in ch.faces:
		var f: Dictionary = ch.faces[id]
		f["suspicion"] = mini(int(f.suspicion), JobRules.TRUST)


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


## Someone let them into the meeting.
static func _seated(c: CrewInfo) -> bool:
	return c.flags.has("minutes") or c.flags.has("observer") or c.flags.has("through")
