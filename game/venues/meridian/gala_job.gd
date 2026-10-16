class_name MeridianGalaJob
extends JobDef
## Job 1 at the Hotel Meridian: the Caldera Museum's gala. Get the crew into
## the ballroom before the speech at half past nine, past Teo on the doors,
## Marcus on the service door, Laurent in the kitchen, or on the arm of a
## guest (docs/m1.md has the whole job).

const KITCHEN_CODE := "4471"
## When the ballroom doors shut, and the speech.
const SHUT := 21 * 60 + 20
const SPEECH := 21 * 60 + 30


func _init() -> void:
	id = "meridian_gala"
	venue_id = "meridian"
	number = 1
	title = "The gala"
	venue_name = "The Hotel Meridian"
	briefing = "The Caldera Museum's gala, at the Meridian. The Rose is on show in the ballroom, and before we can take it I need you in that room with your eyes open. Halberd has the doors. Teo's on the ballroom, Marcus has the service door, and the kitchen's run by a Frenchman who's short of waiters. Get inside before Halvorsen's speech at half past nine. Talk, love. That's all it ever takes."
	goal = "Get into the ballroom before the speech at 9:30"
	situation = MeridianCast.SITUATION
	prize = "a look at the Rose"
	take = 2000
	start = 20 * 60 + 45
	end = SPEECH
	end_text = "the speech"
	covers = Covers.ALL.duplicate(true)
	cover_order = Covers.ORDER.duplicate()
	covers.facilities["lines"] = [
		"Evening. Caldera Building Services, here about the walk-in freezer.",
		"Reception's been on at us all week about it.",
		"Can you check with Dana on the desk? She'll have me down.",
		"Twenty minutes and I'm out of your hair.",
	]
	covers.guest["lines"] = [
		"Good evening. %s, I'm on the list.",
		"Here's my invitation.",
		"I'm a friend of the Halvorsens. Is Mr Okafor about?",
		"Lovely night for it. Has the speech started?",
	]
	covers.press["lines"] = [
		"%s, Caldera Courier. I'm covering the gala.",
		"The Courier covers the museum gala every year.",
		"Could I have a word with the night manager?",
		"Two lines on the Rose and a photo, then I'm gone.",
	]
	covers.agency["lines"] = [
		"Caldera Staffing sent me. I'm so sorry I'm late.",
		"Where do you want me, chef?",
		"Traffic on the bridge was murder.",
		"I've done a hundred of these. Just point me at a tray.",
	]
	staff_looking = Covers.STAFF_LOOKING.duplicate()
	staff_rooms = Covers.STAFF_ROOMS.duplicate()
	extras = {"ballroom": "guest", "lobby": "guest", "kitchen": "kitchen"}
	routine = [
		[20 * 60 + 50, "okafor", "okafor_stage"],
		[20 * 60 + 56, "okafor", "okafor"],
		[21 * 60, "marcus", "smoke"],
		[21 * 60 + 5, "celeste", "celeste_in"],
		[21 * 60 + 5, "hugo", "hugo_in"],
		[21 * 60 + 10, "marcus", "marcus"],
		[21 * 60 + 18, "okafor", "okafor_stage"],
	]
	for l in MeridianCast.CHATTER:
		chatter.append([20 * 60 + int(l[0]), l[1], l[2], l[3]])
	events = [[SHUT, "shut"]]
	locked = ["ballroom", "service", "pass", "loading"]
	unlocked = ["office", "staff"]
	open = ["front"]
	lockdown_doors = ["ballroom", "service", "pass"]
	lockdown_text = "Lockdown. The ballroom and the kitchen are shut."
	door_texts = {"service": "It's locked. There's a keypad by it.", "loading": "It's bolted from outside."}
	keypads = {"keypad": {"door": "service", "code": KITCHEN_CODE, "label": "Kitchen door"}}
	items = {
		"invitation": {
			"name": "the invitation", "at": "", "carry": "",
			"papers": "an invitation to the gala in the name of %s", "forged": true,
			"copy": "the card's too thin and the crest is printed, not embossed. It's a copy.",
			"belief": "has an invitation",
		},
	}
	effects = {
		"escort_in": {"flag": "escorted", "open": "ballroom", "for": Job.OPEN_FOR * 1.5, "walk": "okafor_stage", "toast": "%s is taking you into the ballroom himself. Stay with him."},
		"add_to_list": {"flag": "listed", "toast": "%s has put your name on the guest list."},
		"book_visit": {"flag": "booked", "toast": "%s has booked your visit. The service door will know."},
		"put_to_work": {"flag": "hired", "outfit": "waiter_jacket", "toast": "%s has put you to work. The pass is open to you."},
		"plus_one": {"flag": "plus_one", "value": "@char", "toast": "%s will take you in as a plus-one at 9:05. Stay close."},
		"let_through": {"open": "@door", "toast": "%s lets you through."},
		"ask_for_invitation": {"if_item": "invitation", "toast": "Show the invitation: Interact, facing him."},
	}
	phone = [
		{"id": "reception", "name": "Meridian reception", "who": "dana"},
		{"id": "manager", "name": "Mr Okafor, night manager", "who": "okafor"},
		{"id": "kitchen", "name": "The Meridian's kitchen", "who": "laurent"},
	]
	caller_ids = ["Withheld", "Caldera Museum", "Caldera Building Services", "Caldera Staffing", "Halvorsen Hotels"]
	mae_calls = [
		{"id": "freezer", "label": "Book the freezer repair", "who": "dana", "as": "Caldera Building Services",
			"line": "Evening, this is Caldera Building Services. We've an engineer on the way for your walk-in freezer tonight. Can you let your door know?",
			"answer": "Oh, finally. Yes, I'll put it through. Thank you.",
			"mae": "Leave it with me, love. Dana will have a booking for the freezer in a minute."},
		{"id": "temp", "label": "Tell the kitchen a temp's coming", "who": "laurent", "as": "Caldera Staffing",
			"line": "Caldera Staffing here. Our temp for tonight's running late, but they're on their way. So sorry, chef.",
			"answer": "Late! Of course late. Fine, send them through the back.",
			"mae": "I'll ring the kitchen as the agency. Laurent will be expecting a late temp."},
		{"id": "nephew", "label": "Warn Okafor the nephew's coming", "who": "okafor", "as": "Halvorsen Hotels",
			"line": "Mr Halvorsen's office. Felix, his nephew, is on his way to the gala. Mr Halvorsen would like him looked after.",
			"answer": "Of course. Of course! We'll take care of him, please tell Mr Halvorsen.",
			"mae": "I'll ring Okafor from Halvorsen's office. If you're Felix tonight, he'll be ready for you."},
	]
	outcomes = {
		"in": ["YOU'RE IN", "Inside the ballroom at %s."],
		"late": ["TOO LATE", "The speech started with nobody inside."],
		"held": ["ALL HELD", "The whole crew ended up in the security office."],
	}
	wins = ["in"]
	inside_zone = "ballroom"
	inside_text = "You're in the ballroom."


func venue() -> Venue:
	return Meridian.new()


func cast() -> Array[CharacterSheet]:
	return MeridianCast.all()


func give_items(crew: Array) -> void:
	if crew.is_empty():
		return
	for c in crew:
		if c.cover == "guest":
			c.items.append("invitation")
			return
	crew[0].items.append("invitation")


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	if what == "jackets":
		if c.outfit == "waiter_jacket":
			c.outfit = str(Covers.of(c.cover).outfit)
			job.crew_changed.emit(c.id)
			_rack(job)
			return "You hang the jacket back up."
		c.outfit = "waiter_jacket"
		job.crew_changed.emit(c.id)
		_rack(job)
		return "You put on a waiter's jacket."
	var d = job.venue.doors.get(what.trim_prefix("door:")) if what.begins_with("door:") else null
	if d == null or d.is_open:
		return null
	match what:
		"door:ballroom":
			return "The doors are shut for the speech." if job.flags.has("shut:ballroom") else "Teo's on the doors."
		"door:pass":
			if c.outfit == "waiter_jacket" or c.flags.has("hired"):
				job.open_for("pass", Job.OPEN_FOR * 0.5)
				return ""
			return "The waiters' door. You don't look like a waiter."
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	if what == "jackets":
		return "Hang the jacket up" if c.outfit == "waiter_jacket" else "Put on a waiter's jacket"
	if what == "keypad":
		return "Use the keypad"
	return null


## A jacket gone from the staff room's rack for each crew member wearing one.
func _rack(job: Job) -> void:
	var worn := job.crew.filter(func(x): return x.outfit == "waiter_jacket").size()
	for i in 5:
		job.show_node("Jacket_%d" % (5 - i), i >= worn)


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"dana":
			if c and c.flags.has("listed"):
				return Job.fact("good", "You put them on the guest list yourself tonight.", "Yes, they're on the list. I added them myself.")
			if c and c.flags.has("booked"):
				return Job.fact("good", "You booked their visit yourself tonight.", "Yes, I booked them in tonight.")
			for surname in MeridianCast.GUEST_LIST:
				if said.contains(surname):
					if surname == "halvorsen":
						return Job.fact("good", MeridianCast.GUEST_LIST[surname] + ".", "Felix Halvorsen? He's on the list. Not checked in yet.")
					return Job.fact("bad", MeridianCast.GUEST_LIST[surname] + ", so this isn't them.", "The %ss? They checked in an hour ago." % surname.capitalize())
			if Job.any(said, ["agency", "staffing", "temp"]):
				return Job.fact("good", "Caldera Staffing is sending temps to the kitchen tonight.", "Caldera Staffing? Yes, the kitchen's expecting temps.")
			if Job.any(said, ["freezer", "facilit", "engineer", "repair", "maintenance"]):
				if job.flags.has("mae:freezer"):
					return Job.fact("good", "Caldera Building Services rang tonight: their engineer is coming for the freezer.", "Yes, the freezer engineer. They rang ahead. Let them through.")
				return Job.fact("bad", "You've asked twice this week for the freezer to be fixed, but nobody's booked for tonight.", "Nobody's booked for the freezer tonight. Not through me.")
			if Job.any(said, ["press", "courier", "writer", "journalist"]):
				return Job.fact("bad", "There's no press on tonight's list.", "There's no press on my list.")
			return Job.fact("bad", "They're not on the guest list and you haven't booked anyone like them.", "Nobody like that on my list.")
		"okafor":
			var of: Dictionary = job.cast["okafor"].faces.get(crew_id, {})
			if "escort_in" in of.get("opened", []):
				return Job.fact("good", "You're taking them in yourself.", "Yes, they're with me.")
			if Job.any(said, ["halvorsen", "nephew"]):
				return Job.fact("good", "You've never met Felix Halvorsen, the owner's nephew, and you dread offending the family.", "If he's Mr Halvorsen's nephew, let him in! Please!")
			if bool(of.get("met", false)) and int(of.get("suspicion", 2)) <= JobRules.TRUST:
				return Job.fact("good", "You've met them tonight; they seemed fine.", "I've met them. They're fine.")
			return Job.fact("bad", "You've never met them.", "I don't know who that is.")
	return {}


func on_routine(job: Job, ch: Character, _spot: String) -> bool:
	match ch.sheet.id:
		"okafor":
			# Taking someone in himself, he's busy until nine.
			if job.minutes < 21 * 60 and job.crew.any(func(c): return c.flags.has("escorted")):
				return false
		"celeste", "hugo":
			_go_in(job, ch)
	return true


## A guest goes in for the speech, with their plus-one if they took one.
func _go_in(job: Job, ch: Character) -> void:
	var theirs := job.crew.filter(func(c): return str(c.flags.get("plus_one", "")) == ch.sheet.id)
	if job.heat.level >= Heat.LOCKDOWN:
		for c in theirs:
			job.toast_for.emit(c.id, "%s goes in alone: the building's locked down." % ch.sheet.name)
		return
	job.open_for("ballroom", Job.OPEN_FOR)
	for c in theirs:
		job.toast_for.emit(c.id, "%s is going in. Stay with %s, through the doors." % [ch.sheet.name, "her" if ch.sheet.female else "him"])


func on_event(job: Job, event_name: String) -> void:
	if event_name != "shut":
		return
	job.shut_for_night("ballroom")
	for ch in job.cast.values():
		ch.note("The ballroom doors are shut for the speech. Nobody else goes in.")
	job.toast_for.emit(0, "The ballroom doors are shut for the speech.")


func on_heat(job: Job, was: int, now: int) -> void:
	if now == Heat.ALERT and now > was:
		var ok: Character = job.cast.get("okafor")
		if ok and not ok.minding and not job.crew.any(func(c): return c.flags.has("escorted")):
			ok.walk_to("okafor")


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	if ch.sheet.id == "laurent" and zone in ["kitchen", "staff_room"] and Covers.looks_staff(c.outfit) and c.outfit != "facilities" and not c.flags.has("hired"):
		ch.event("A waiter you don't know, %s, is in your kitchen." % job.describe(c.id), c.id, "event")
		return true
	return false


func allowed_back(job: Job, c: CrewInfo) -> bool:
	return c.flags.has("booked") or c.flags.has("hired") or "let_through" in job.cast["marcus"].face_of(c.id).opened


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"freezer":
			ch.note("You've booked the freezer engineer from Caldera Building Services in for tonight. If the door asks, they're expected.")
			for other in job.cast.values():
				if other.sheet.id == "marcus":
					other.note("On the radio, Dana: \"Marcus, a freezer engineer's booked in tonight. Caldera Building Services.\"")
		"temp":
			ch.note("Caldera Staffing rang: their temp for tonight is late but on the way. You're short-handed and you'd take them gladly.")
		"nephew":
			ch.note("Mr Halvorsen's office rang: Felix, the owner's nephew, is coming tonight, and you're to look after him personally.")


func check_end(job: Job) -> String:
	var free := job.free_crew()
	if not free.is_empty() and free.all(func(c): return c.inside):
		return "in"
	return ""


func at_end(job: Job) -> String:
	return "in" if job.crew.any(func(c): return c.inside) else "late"
