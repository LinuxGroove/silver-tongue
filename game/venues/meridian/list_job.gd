class_name MeridianListJob
extends JobDef
## Job 2 at the Hotel Meridian: a wedding night, a week after the gala. Get
## the Halvorsens' private guest list for the Marlin auction (or a copy of
## it) out of the building. Dana prints a copy for the auction house once Mr
## Okafor says so; Okafor shows a bidder into his office and is called away;
## or Gus hands the air conditioning engineer the office key while Okafor's
## at the speeches (docs/m1.md has the whole job).
##
## Okafor's night is the job's events, not a routine, so a Circuit night that
## moves routines round never moves him: he goes to his office, gives the
## first toast at the speeches, sees the cake in, and locks the list away.

const KITCHEN_CODE := MeridianGalaJob.KITCHEN_CODE
const OFFICE := 21 * 60 + 36
const SPEECHES := 21 * 60 + 45
const CAKE := 22 * 60
const LOCK_UP := 22 * 60 + 8
## Game minutes Okafor stays at the bar when he's called down to it.
const AWAY := 4.0
## What each story is about, as the people checking it would hear it.
const AUCTION_HOUSE := ["lindqvist", "auction house", "catalogue"]
const BIDDER := ["bidder", "bidding", "foundation", "collector"]
const AIRCON := ["air conditioning", "air con", "aircon", "engineer", "building services", "cooling"]

var _look_t := 0.0


func _init() -> void:
	id = "meridian_list"
	venue_id = "meridian"
	number = 2
	title = "The guest list"
	venue_name = "The Hotel Meridian"
	briefing = "A week on, love, and the Rose is going aboard the Marlin for the Halvorsens' charity auction. I want to know who's going aboard with it: the guest list, bidders and all. Mr Okafor keeps it in a green folder on his desk, in that new office of his across from the service door, and he locks it in his safe when he goes home at ten past ten. There's a wedding on tonight, so he'll be up and down to the ballroom all evening. Dana prints things for people Okafor vouches for, Gus the porter keeps the keys, and Okafor will do anything for anyone with money. Bring me the list, or a copy of it. Out the door, love, before he locks up."
	goal = "Get the auction's guest list, or a copy, out of the Meridian"
	situation = MeridianCast.WEDDING
	prize = "the auction's guest list"
	take = 4000
	start = 21 * 60 + 30
	end = 22 * 60 + 15
	end_text = "Okafor goes home"
	covers = {
		"auction": {
			"title": "Auction house",
			"names": ["Paul Ashby", "Pauline Ashby"],
			"job": "an associate at Lindqvist & Rowe, the auction house running the Marlin sale",
			"story": "Mr Okafor promised the auction house a copy of the guest list for the catalogue. You're here to collect it from reception.",
			"outfit": "business",
			"for": "Dana, on reception",
			"lines": [
				"Good evening. %s, from Lindqvist & Rowe, the auction house.",
				"Mr Okafor promised us a copy of the guest list for the catalogue.",
				"Could you ring him? He'll tell you.",
				"Just the one copy, and I'm out of your way.",
			],
		},
		"collector": {
			"title": "Collector",
			"names": ["Anton Sorel", "Annick Sorel"],
			"job": "a collector bidding at the Halvorsens' charity auction",
			"story": "You're bidding on the Rose aboard the Marlin, and you'd like a word with Mr Okafor about the night's arrangements. He'll want to impress you.",
			"outfit": "guest",
			"for": "Mr Okafor, the night manager",
			"lines": [
				"Good evening. %s. I'm bidding at the Halvorsens' auction on the Marlin.",
				"I was hoping for a word with you about the arrangements.",
				"Somewhere a little more private, perhaps?",
				"Mr Halvorsen is asking for you at the bar.",
			],
		},
		"facilities": {
			"title": "Facilities",
			"names": ["Ray Costa", "Rae Costa"],
			"job": "an air conditioning engineer from Caldera Building Services",
			"story": "Mr Okafor's office has been an oven all week. Gus, the night porter, keeps the keys.",
			"outfit": "facilities",
			"for": "Gus, the night porter",
			"lines": [
				"Evening. Caldera Building Services, about the air conditioning in Mr Okafor's office.",
				"He's been on at us all week. I'll need the key.",
				"Ring him if you like. He booked it.",
				"Twenty minutes and it'll be cold as a fridge in there.",
			],
		},
	}
	cover_order = ["auction", "collector", "facilities"]
	outfits = {"business": {"job": "meridian_business", "male": "a grey business suit", "female": "a grey business suit"}}
	looks = MeridianCast.LOOKS
	staff_looking = Covers.STAFF_LOOKING.duplicate()
	staff_rooms = Covers.STAFF_ROOMS.duplicate()
	staff_rooms["manager_office"] = "Mr Okafor's office"
	extras = {"ballroom": "guest", "lobby": "guest", "kitchen": "kitchen"}
	routine = [
		[21 * 60 + 50, "marcus", "smoke"],
		[22 * 60, "marcus", "marcus"],
	]
	chatter = [
		[21 * 60 + 32, "celeste", "Anneke looks radiant. Tomas looks like he's been arrested.", "near"],
		[21 * 60 + 32, "hugo", "So would you, marrying into the Achterbergs.", "near"],
		[21 * 60 + 35, "pippa", "Ten minutes to the speeches, people. Ten minutes!", "near"],
		[21 * 60 + 39, "hugo", "Okafor showed me the auction list last week. Half of Caldera's bidding on that diamond.", "near"],
		[21 * 60 + 40, "celeste", "Of course he did. He shows it to anyone with a yacht.", "near"],
		[21 * 60 + 49, "marcus", "Teo, it's Marcus. Going out for a smoke. Service door's locked.", "radio"],
		[21 * 60 + 49, "teo", "Copy that.", "radio"],
		[21 * 60 + 53, "benny", "Another wedding, another forty gin and tonics.", "near"],
		[22 * 60 + 1, "marcus", "Marcus, back on the service door.", "radio"],
	]
	events = [[OFFICE, "office"], [SPEECHES, "speeches"], [CAKE, "cake"], [LOCK_UP, "lock_up"]]
	locked = ["ballroom", "service", "pass", "loading", "manager"]
	unlocked = ["office", "staff"]
	open = ["front"]
	lockdown_doors = ["service", "pass", "manager", "ballroom"]
	lockdown_text = "Lockdown. The back of the house is shut."
	door_texts = {
		"service": "It's locked. There's a keypad by it.", "loading": "It's bolted from outside.",
		"manager": "Mr Okafor's office. It's locked.", "ballroom": "Teo's on the doors, checking invitations.",
	}
	keypads = {"keypad": {"door": "service", "code": KITCHEN_CODE, "label": "Kitchen door"}}
	items = {
		"guest_list": {"name": "the auction's guest list", "at": "okafor_desk", "carry": "carrying a green leather folder", "hot": true},
		"list_copy": {"name": "a copy of the guest list", "at": "", "carry": ""},
		"office_key": {"name": "the key to Mr Okafor's office", "at": "", "carry": ""},
	}
	actions = {
		"print_copy": {"text": "print them a copy of the Marlin auction's guest list from your computer", "kind": "opening", "lockdown": true},
		"invite_in": {"text": "take them to your office yourself, to talk about the auction in private", "kind": "opening", "lockdown": true},
		"go_to_halvorsen": {"text": "hurry down to the lobby bar, where you're told Mr Halvorsen is asking for you", "kind": "opening"},
		"give_key": {"text": "give them the key to Mr Okafor's office from the key cabinet", "kind": "opening", "lockdown": true},
		"send_for_okafor": {"text": "ring Mr Okafor and tell him there's trouble at the bar, so he comes down", "kind": "opening"},
	}
	effects = {
		"print_copy": {"item": "list_copy", "toast": "%s prints you a copy of the guest list. It folds into a pocket."},
		"give_key": {"item": "office_key", "flag": "booked", "toast": "%s gives you the key to Mr Okafor's office, across the back corridor from the service door."},
		"ask_for_invitation": {"toast": "Teo wants a wedding invitation. You haven't got one."},
		"let_through": {"open": "@door", "toast": "%s lets you through."},
	}
	phone = [
		{"id": "reception", "name": "Meridian reception", "who": "dana"},
		{"id": "manager", "name": "Mr Okafor, night manager", "who": "okafor"},
		{"id": "porter", "name": "The porter's desk", "who": "gus"},
		{"id": "bar", "name": "The lobby bar", "who": "benny"},
		{"id": "kitchen", "name": "The Meridian's kitchen", "who": "laurent"},
	]
	caller_ids = ["Withheld", "Lindqvist & Rowe", "Halvorsen Foundation", "Caldera Building Services", "Halvorsen Hotels"]
	mae_calls = [
		{"id": "auction", "label": "Ring Okafor as the auction house", "who": "okafor", "as": "Lindqvist & Rowe",
			"line": "Good evening, Lindqvist and Rowe. Our associate is calling at your reception tonight for the copy of the guest list you promised us, for the catalogue. Could you let your desk know?",
			"answer": "Ah. Yes, of course. Reception can print it. Good evening.",
			"mae": "I'll ring Okafor as the auction house, love. When Dana asks him, he'll say yes."},
		{"id": "vip", "label": "Tell Dana a bidder's coming", "who": "dana", "as": "Halvorsen Foundation",
			"line": "Good evening, the Halvorsen Foundation. One of the auction's bidders is calling on Mr Okafor tonight, about the arrangements on the Marlin. Please look after them.",
			"answer": "Of course. I'll tell Mr Okafor.",
			"mae": "I'll ring Dana from the Foundation. When Okafor checks on you, she'll say you're expected."},
		{"id": "ac", "label": "Book the air conditioning", "who": "okafor", "as": "Caldera Building Services",
			"line": "Evening, Caldera Building Services. We can get an engineer to your office air conditioning tonight after all. They'll pick up the key from your porter.",
			"answer": "Tonight? Thank heaven. Gus has the key. I'll be at the speeches.",
			"mae": "I'll ring Okafor as Building Services. When Gus rings him about you, he'll say yes."},
		{"id": "away", "label": "Call Okafor down to the bar", "who": "okafor", "as": "Halvorsen Hotels",
			"line": "Mr Okafor? Mr Halvorsen's office. Mr Halvorsen is in the lobby bar and would like a word with you. Now, please.",
			"answer": "Now? Of course. I'm on my way.",
			"mae": "Say no more. I'll ring Okafor from Halvorsen's office and he'll be at the bar in a minute."},
	]
	outcomes = {
		"out": ["THE LIST", "Out of the Meridian with the auction's guest list at %s."],
		"late": ["TOO LATE", "Mr Okafor locked the list in his safe and went home."],
		"inside": ["STILL INSIDE", "You had the list, but the night ended with you still in the hotel."],
	}
	wins = ["out"]


func venue() -> Venue:
	var m := Meridian.new()
	m.setting = "wedding"
	return m


func cast() -> Array[CharacterSheet]:
	return MeridianCast.wedding()


func setup(job: Job) -> void:
	job.flags["okafor_post"] = "okafor"


#region The crew's doings

func use(job: Job, c: CrewInfo, what: String) -> Variant:
	var d = job.venue.doors.get(what.trim_prefix("door:")) if what.begins_with("door:") else null
	if d == null or d.is_open:
		return null
	match what:
		"door:manager":
			# From inside it opens; from outside, with the key or with Okafor's invitation.
			var inside: bool = job.venue.zone_at(c.position()) == "manager_office"
			if not inside and job.heat.level >= Heat.LOCKDOWN:
				return "Mr Okafor's office is locked. The building's locked down."
			if inside or "office_key" in c.items or c.flags.has("invited"):
				job.open_for("manager", 8.0)
				return ""
	return null


func can_take(job: Job, _c: CrewInfo, item: String) -> String:
	if item == "guest_list":
		var ok: Character = job.cast.get("okafor")
		if ok and job.venue.zone_at(ok.global_position) == "manager_office":
			return "Not with Mr Okafor right there."
	return ""


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"invite_in":
			c.flags["invited"] = true
			_send(job, "okafor_office")
			job.open_for("manager", Job.OPEN_FOR * 1.6)
			job.toast_for.emit(c.id, "Mr Okafor is taking you to his office, across the back corridor. Follow him.")
			return true
		"go_to_halvorsen":
			_call_away(job)
			job.toast_for.emit(c.id, "%s hurries off to find Mr Halvorsen at the bar." % ch.sheet.name)
			return true
		"send_for_okafor":
			_call_away(job)
			job.toast_for.emit(c.id, "%s rings Mr Okafor: trouble at the bar. He's on his way down." % ch.sheet.name)
			return true
	return false


func allowed_back(job: Job, c: CrewInfo) -> bool:
	return c.flags.has("invited") or c.flags.has("booked") or "office_key" in c.items or "let_through" in job.cast["marcus"].face_of(c.id).opened

#endregion

#region Lies and the people who check them

func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"okafor":
			if c and c.flags.has("invited"):
				return Job.fact("good", "You invited them into your office yourself tonight.", "Yes, they're with me. Look after them.")
			if Job.any(said, AUCTION_HOUSE):
				if _backed(job, "auction", "okafor", "Lindqvist & Rowe", AUCTION_HOUSE + ["copy", "list", "collect"]):
					return Job.fact("good", "Lindqvist & Rowe rang you tonight: their associate is collecting a copy of the guest list from reception, for the catalogue. You said yes.", "Yes, the auction house. Print them a copy, Dana. Just the one.")
				return Job.fact("bad", "Nobody from the auction house has said a word to you about a copy of the list.", "The auction house? Nobody's asked me for anything. Don't give them a thing.")
			if Job.any(said, AIRCON):
				if _backed(job, "ac", "okafor", "Caldera Building Services", AIRCON):
					return Job.fact("good", "Caldera Building Services rang you tonight: their engineer is coming for your office's air conditioning, and will get the key from Gus.", "Yes, yes, the air conditioning. Give them the key, Gus. At last.")
				return Job.fact("bad", "You've begged for an engineer all week, and nobody's booked for tonight.", "Nobody's booked for my office tonight. Not that I know of.")
			if Job.any(said, BIDDER):
				if _backed(job, "vip", "dana", "Halvorsen Foundation", BIDDER):
					return Job.fact("good", "Dana told you the Halvorsen Foundation rang about a bidder calling on you tonight.", "A bidder? Yes, the Foundation rang about them. Be nice to them, please.")
				return Job.fact("bad", "You know every bidder on that list, and nobody told you one was coming tonight.", "A bidder? Nobody told me. I've never heard of them.")
			if Job.any(said, ["wedding", "bride", "groom"]):
				return Job.fact("bad", "You don't know them, and Teo has the wedding's list.", "I don't know them. Teo has the wedding list.")
			return Job.fact("bad", "You've never met them.", "I don't know who that is.")
		"dana":
			if Job.any(said, BIDDER):
				if _backed(job, "vip", "dana", "Halvorsen Foundation", BIDDER):
					return Job.fact("good", "The Halvorsen Foundation rang you tonight: one of the auction's bidders is calling on Mr Okafor.", "Yes, the Foundation rang. A bidder, coming to see you, Mr Okafor.")
				return Job.fact("bad", "Nobody from the Foundation has rung you tonight.", "The Foundation? Nobody's rung me about anyone.")
			if Job.any(said, AUCTION_HOUSE):
				if _backed(job, "auction", "okafor", "Lindqvist & Rowe", AUCTION_HOUSE + ["copy", "list", "collect"]):
					return Job.fact("good", "Mr Okafor told you the auction house is collecting a copy of the list tonight.", "The auction house, yes. Mr Okafor said they'd come.")
				return Job.fact("bad", "The auction house hasn't been in touch with you tonight.", "The auction house hasn't rung me.")
			if Job.any(said, AIRCON):
				if _backed(job, "ac", "okafor", "Caldera Building Services", AIRCON):
					return Job.fact("good", "Mr Okafor booked the air conditioning engineer himself tonight.", "The air conditioning? Mr Okafor booked it himself.")
				return Job.fact("bad", "Nobody's booked any facilities tonight, not through you.", "Nobody's booked for tonight. Not through me.")
			if Job.any(said, ["wedding", "bride", "groom"]):
				return Job.fact("bad", "The wedding's list is Teo's, at the ballroom doors, not yours.", "If they're with the wedding, Teo has the list.")
			return Job.fact("bad", "They're not a guest of the hotel and nobody's told you about them.", "Nobody like that in my book.")
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
		"auction":
			ch.note("Lindqvist & Rowe, the auction house, rang: their associate is collecting a copy of the guest list from reception tonight, for the catalogue. You'd promised them one.")
		"vip":
			ch.note("The Halvorsen Foundation rang: one of the auction's bidders is calling on Mr Okafor tonight, about the arrangements on the Marlin. They're expected.")
			var ok: Character = job.cast.get("okafor")
			if ok:
				ok.note("On the radio, Dana: \"Mr Okafor, the Halvorsen Foundation rang. One of the auction's bidders is calling on you tonight.\"")
		"ac":
			ch.note("Caldera Building Services rang: their engineer is coming tonight for your office's air conditioning, and will get the key from Gus. At last.")
		"away":
			_call_away(job)

#endregion

#region The night

func on_event(job: Job, event_name: String) -> void:
	var ok: Character = job.cast.get("okafor")
	match event_name:
		"office":
			_send(job, "okafor_office")
			if ok:
				ok.say_scripted("Dana, it's Mr Okafor. I'll be in my office until the speeches.", _radio_to(job, ok))
		"speeches":
			_leaves_guests(job, "Mr Okafor has to give his toast. He asks you to wait in his office.")
			_send(job, "okafor_stage")
			for w in [["pippa", "pippa_in"], ["celeste", "celeste_in"], ["hugo", "hugo_in"]]:
				_walk(job, w[0], w[1])
			job.toast_for.emit(0, "The speeches are starting in the ballroom. Mr Okafor gives the first toast.")
		"cake":
			_leaves_guests(job, "Mr Okafor has to see the cake in. He asks you to wait in his office.")
			_send(job, "okafor")
			_walk(job, "pippa", "pippa")
			job.toast_for.emit(0, "The cake's going in. Mr Okafor's back in the lobby.")
		"lock_up":
			job.flags["lock_up"] = true
			_send(job, "okafor_office")
			if ok:
				ok.say_scripted("Dana, it's Mr Okafor. I'm locking up the office and going home. Goodnight.", _radio_to(job, ok))
			job.toast_for.emit(0, "Mr Okafor's going to lock the list in his safe.")


func tick(job: Job, delta: float) -> void:
	# Who rang whom, showing what: the checks ask about it.
	for id in job.calls:
		var r: Dictionary = job.calls[id]
		job.flags["rang:%s:%s" % [r["who"], r["as"]]] = id
	var ok: Character = job.cast.get("okafor")
	if ok == null:
		return
	var here := ok.post != "" and not ok.walking and ok.global_position.distance_to(job.spot(ok.post).origin) < 0.3
	# Called down to the bar: a few minutes there, then back where he should be.
	if job.flags.has("away") and here and ok.post == "okafor_bar":
		if not job.flags.has("away_back"):
			job.flags["away_back"] = job.minutes + AWAY
		elif job.minutes >= float(job.flags.away_back):
			job.flags.erase("away")
			job.flags.erase("away_back")
			ok.walk_to(str(job.flags.get("okafor_post", "okafor")))
	# Into his office: is the list where he left it?
	var in_office := here and ok.post == "okafor_office"
	if in_office and not job.flags.has("okafor_in"):
		job.flags["okafor_in"] = true
		_in_office(job, ok)
	elif not in_office:
		job.flags.erase("okafor_in")
	_look_t -= delta
	if job.flags.has("alarm") and _look_t <= 0.0:
		_look_t = 0.5
		_spot_folder(job)
	_confiscate(job)


## Okafor's back at his desk: at ten past ten he locks the list away; if it's
## gone, he raises the alarm.
func _in_office(job: Job, ok: Character) -> void:
	if str(job.items.get("guest_list", {}).get("at", "")) == "okafor_desk":
		if job.flags.has("lock_up"):
			job.place_item(0, "guest_list", "")
			job.flags["locked_away"] = true
			ok.note("You've locked the auction's guest list in your safe for the night.")
			job.toast_for.emit(0, "Mr Okafor locks the guest list in his safe.")
		return
	if job.flags.has("locked_away") or job.flags.has("alarm"):
		return
	job.flags["alarm"] = true
	job.heat.bump(Heat.CAUGHT)
	ok.say_scripted("Security, it's Okafor. The auction's guest list is gone from my desk. Nobody leaves with a green folder!", _radio_to(job, ok))
	for ch in job.cast.values():
		if ch != ok:
			ch.note("Mr Okafor's green folder, the auction's guest list, has gone from his office. Watch for anyone carrying it.")
	_walk(job, "teo", "front_watch")
	job.toast_for.emit(0, "Mr Okafor has found the guest list gone. Teo's watching the front doors.")


## After the alarm, staff who see the green folder on someone know what it is.
func _spot_folder(job: Job) -> void:
	if not job.venue.is_inside_tree():
		return
	var space := job.venue.get_world_3d().direct_space_state
	for c in job.crew:
		if c.held or c.node == null or not "guest_list" in c.items:
			continue
		for ch in job.cast.values():
			var key: String = "spotted:" + ch.sheet.id
			if c.flags.has(key) or not (ch.sheet.staff or ch.sheet.halberd) or not ch.look([c], space).has(c.id):
				continue
			c.flags[key] = true
			JobRules.nudge(ch.face_of(c.id), JobRules.CAUGHT)
			job.heat.bump(Heat.KEYPAD_SEEN)
			ch.event("You saw %s carrying Mr Okafor's green folder: the missing guest list." % job.describe(c.id), c.id, "seen")


## Whoever's held gives up what they took.
func _confiscate(job: Job) -> void:
	for c in job.crew:
		if not c.held:
			continue
		if "guest_list" in c.items:
			job.place_item(c.id, "guest_list", "okafor_desk")
			job.toast_for.emit(0, "Halberd takes the green folder back to Mr Okafor's desk.")
		if "list_copy" in c.items:
			job.place_item(c.id, "list_copy", "")
		if "office_key" in c.items:
			job.place_item(c.id, "office_key", "")


## Okafor goes somewhere the night needs him, and that's where he belongs
## until the next thing.
func _send(job: Job, spot_name: String) -> void:
	job.flags["okafor_post"] = spot_name
	job.flags.erase("away")
	job.flags.erase("away_back")
	var ok: Character = job.cast.get("okafor")
	if ok == null or ok.minding:
		return
	if not ok.walking and ok.global_position.distance_to(job.spot(spot_name).origin) < 0.3:
		ok.post = spot_name
		# Already there: look at the desk again.
		job.flags.erase("okafor_in")
		return
	ok.walk_to(spot_name)


## Okafor's called down to the bar for a few minutes.
func _call_away(job: Job) -> void:
	var ok: Character = job.cast.get("okafor")
	if ok == null or ok.minding:
		return
	_leaves_guests(job, "Mr Okafor hurries out of his office.")
	job.flags["away"] = true
	job.flags.erase("away_back")
	ok.walk_to("okafor_bar")


## Tells anyone of the crew in Okafor's office that he's leaving them there.
func _leaves_guests(job: Job, text: String) -> void:
	var ok: Character = job.cast.get("okafor")
	if ok == null or job.venue.zone_at(ok.global_position) != "manager_office":
		return
	for c in job.free_crew():
		if c.node and job.venue.zone_at(c.position()) == "manager_office":
			job.toast_for.emit(c.id, text)


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
	for c in job.free_crew():
		if c.node and ("guest_list" in c.items or "list_copy" in c.items) and job.venue.zone_at(c.position()) == "outside":
			return "out"
	return ""


func at_end(job: Job) -> String:
	for c in job.free_crew():
		if "guest_list" in c.items or "list_copy" in c.items:
			return "inside"
	return "late"

#endregion
