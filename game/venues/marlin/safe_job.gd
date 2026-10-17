class_name MarlinSafeJob
extends JobDef
## Job 2 aboard the Marlin: at sea for the auction's preview. The captain's
## strongroom holds the auction file (the reserve, the bidders, their
## banks). Get it out before she turns for home: help Ollie with the
## captain's turndown and get the code from him, admire the Kestrel until
## Captain Lund shows you his cabin and is called away, or hold Freya's
## watch while Mr Halvorsen's office has her read the file down the phone.

const TURNDOWN := 20 * 60 + 50
const TURNDOWN_DONE := 21 * 60
const TURN := 21 * 60 + 5
const HOME := 21 * 60 + 15
## Real seconds the captain shows off the Kestrel before the bridge calls him.
const SHOWING := 20.0
## The caller ID the owner's office rings from.
const OWNER := "Halvorsen Shipping"


func _init() -> void:
	id = "marlin_safe"
	venue_id = "marlin"
	number = 2
	memory_from = ["meridian"]
	title = "The captain's safe"
	venue_name = "The Marlin"
	briefing = "We're at sea, love, and so is the auction's file: the reserve, every bidder and every bank behind them, in the captain's strongroom. Anders Lund can't stop talking about his first boat, and men like that use the same number for everything. Ollie, the cabin steward, turns the cabin down at ten to nine and would hand his work to anyone. And Freya, the first officer, jumps when Mr Halvorsen's office rings, if someone will hold her watch. Get me that file before she turns for home."
	goal = "Get the auction file out of the captain's safe before 9:15"
	situation = MarlinCast.SITUATIONS.safe
	prize = "the auction file"
	take = 6000
	start = 20 * 60 + 30
	end = HOME
	end_text = "she turns for home"
	covers = {
		"steward": {
			"title": "Steward",
			"names": ["Toby Lane", "Tess Lane"],
			"job": "a temp steward, signed on last night through Harbor Crew",
			"story": "You're one of Bianca's stews now. Ollie turns down the captain's cabin at ten to nine, hates it, and talks too much.",
			"outfit": "steward_whites",
			"for": "Ollie, the cabin steward",
			"lines": [
				"Ollie! Bianca sent me up to help you with the turndown.",
				"I'll do the bed, you do the bathroom.",
				"What's the captain like? Does he lock everything?",
				"%s. I started last night. Is it always this busy?",
			],
		},
		"deck": {
			"title": "Deckhand",
			"names": ["Ray Dorsey", "Rae Dorsey"],
			"job": "the new deckhand, signed on last night through Harbor Crew",
			"story": "Freya Holm is alone on the bridge and can't leave it. Take her watch, and when Mr Halvorsen's office rings for the file, she'll go and fetch it.",
			"outfit": "deck_polo",
			"for": "Freya Holm, the first officer, on the bridge",
			"lines": [
				"Evening. Kofi sent me up to take the watch.",
				"%s, the new deckhand. I can hold her steady.",
				"Go on, I've got her. Same heading?",
				"You'll have your own command one day.",
			],
		},
		"guest": {
			"title": "Guest",
			"names": ["Henry Lisle", "Helena Lisle"],
			"job": "a guest of the auction house at the preview, mad about sailing ships",
			"story": "Captain Lund will tell anyone about the Kestrel, his first command. Listen to him, and he might show you the model in his cabin.",
			"outfit": "guest",
			"for": "Captain Lund, in the saloon",
			"lines": [
				"Captain, is it true your first command was a ketch?",
				"Tell me about the Kestrel.",
				"I'd love to see her. Is there a picture?",
				"%s. I sail a little myself. Nothing like this.",
			],
		},
	}
	cover_order = ["steward", "deck", "guest"]
	outfits = {
		"steward_whites": {"job": "yacht_stew", "male": "the Marlin's white steward's uniform", "female": "the Marlin's white stewardess's uniform"},
		"deck_polo": {"job": "yacht_deck", "male": "a navy deck crew polo and shorts", "female": "a navy deck crew polo and shorts"},
	}
	staff_looking = ["steward_whites", "deck_polo"]
	staff_rooms = MarlinCast.CREW_ROOMS.duplicate()
	looks = MarlinCast.LOOKS
	extras = {"aft_deck": "guest", "saloon": "guest", "sky_lounge": "guest", "galley": "kitchen"}
	routine = [
		[TURNDOWN, "ollie", "ollie_bed"],
		[TURNDOWN + 4, "ollie", "ollie_ensuite"],
		[TURNDOWN_DONE, "ollie", "ollie"],
		[TURN + 1, "anders", "anders"],
	]
	chatter = [
		[20 * 60 + 33, "anders", "The Kestrel. Forty meters, and every one of them trying to kill me. Best year of my life.", "near"],
		[20 * 60 + 37, "pieter", "Hugo, is it true you sold them this boat? Only you've told me four times.", "near"],
		[20 * 60 + 38, "hugo", "Five, Pieter. Finest thing I ever sold.", "near"],
		[20 * 60 + 41, "anders", "Ninety-eight. I was thirty-five. I still use her year for everything, God help me.", "near"],
		[20 * 60 + 45, "bianca", "Ollie, the captain's cabin at ten to nine. Properly, this time.", "near"],
		[20 * 60 + 52, "rupert", "Eleven carats, ladies and gentlemen, and not a flaw in her.", "near"],
		[TURN, "freya", "Captain, bridge. We turn for home at a quarter past.", "radio"],
	]
	events = [[TURNDOWN, "turndown"], [TURNDOWN_DONE, "turndown_done"], [TURN, "turn"]]
	locked = ["captain", "safe"]
	unlocked = ["crew", "saloon", "galley", "cabin_a", "cabin_b", "sun", "bridge"]
	lockdown_doors = ["captain", "safe", "bridge", "crew"]
	lockdown_text = "Lockdown. The captain's deck is shut and Halberd is on every stair."
	door_texts = {"captain": "The captain's cabin. Locked.", "safe": "The strongroom door. There's a keypad beside it."}
	keypads = {"safe_keypad": {"door": "safe", "code": MarlinCast.SAFE_CODE, "for": 40.0, "label": "Strongroom"}}
	office = {"door": "cabin_b", "held": "held", "guard": "held_guard", "name": "a locked crew cabin below decks"}
	items = {
		"auction_file": {"name": "the auction file", "at": "safe_shelf", "carry": "carrying a thick leather folder", "hot": true},
	}
	actions = {
		"ask_bosun": {"text": "radio Kofi, the bosun, to check they're crew (takes a moment)", "kind": "check"},
		"take_along": {"text": "let them help with the captain's turndown, and hold his door for them", "kind": "opening"},
		"show_model": {"text": "take them up to your cabin to see the Kestrel's model", "kind": "opening", "lockdown": true},
		"hand_watch": {"text": "hand them the watch on the bridge, so you can step away when you must", "kind": "opening"},
		"fetch_file": {"text": "go to the strongroom and read the auction file to Mr Halvorsen's office on the phone", "kind": "opening", "lockdown": true},
	}
	effects = {
		"take_along": {"flag": "turndown", "toast": "%s says you can help with the captain's cabin at ten to nine. Meet him at the cabin door."},
		"hand_watch": {"flag": "watch", "toast": "%s hands you the watch. Keep her on her heading."},
	}
	hot_words = ["strongroom", "captain's safe", "the safe", "auction file", "the code"]
	# The Rose is on show for the sale's preview: everyone aboard talks about her.
	cool_words = ["the rose", "diamond"]
	phone = [
		{"id": "bridge", "name": "The Marlin's bridge", "who": "freya"},
		{"id": "chief_stew", "name": "Bianca, chief stew", "who": "bianca"},
		{"id": "galley", "name": "The Marlin's galley", "who": "rocco"},
	]
	caller_ids = ["Withheld", OWNER, "Ashcombe & Vale", "Caldera Museum"]
	mae_calls = [
		{"id": "owner", "label": "Ring the bridge as the owner's office", "who": "freya", "as": OWNER,
			"line": "Good evening, Mr Halvorsen's office. He needs the reserve and the guarantees from the auction file read to him tonight. Fetch the file and read it to me on this line, please.",
			"answer": "Of course. As soon as someone takes the watch, I'll fetch it.",
			"mae": "I'll ring the bridge as Mr Halvorsen's office, love. Once someone's holding her watch, Freya will fetch that file and read it to me."},
		{"id": "museum", "label": "Ring the captain as the museum", "who": "anders", "as": "Caldera Museum",
			"line": "Captain Lund? The museum's director. One of our patrons is aboard tonight and mad about sailing ships. Do show them your Kestrel.",
			"answer": "With pleasure! I'll keep an eye out for them.",
			"mae": "I'll ring the captain as the museum. He'll be keen to show a patron his old boat."},
	]
	outcomes = {
		"done": ["THE FILE", "The auction file was out of the captain's safe at %s."],
		"read": ["READ DOWN THE LINE", "Freya read the auction file down the phone to Mae at %s."],
		"home": ["TURNED FOR HOME", "The Marlin turned for home with the file still in the safe."],
	}
	wins = ["done", "read"]


func venue() -> Venue:
	return Marlin.new("safe")


func cast() -> Array[CharacterSheet]:
	return MarlinCast.all("safe")


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"show_model":
			c.flags["showing"] = true
			job.flags["showing"] = c.id
			job.flags.erase("shown_at")
			ch.walk_to("anders_cabin")
			job.toast_for.emit(c.id, "%s is taking you up to his cabin to see the Kestrel. Follow him." % ch.sheet.name)
			return true
		"take_along":
			# Already at it: he holds the door now.
			if _at(job, "ollie", ["ollie_bed", "ollie_ensuite"]):
				job.open_for("captain", Job.OPEN_FOR)
		"fetch_file":
			var rang: Dictionary = job.calls.get(c.id, {})
			if str(rang.get("who", "")) == "freya" and str(rang.get("as", "")) != OWNER:
				ch.say_scripted("I'll call the office back on its own line, thank you.")
				return true
			job.flags["owner_call"] = true
			_fetch(job)
			return true
	return false


## Freya goes for the file once the owner's office has asked and someone
## she trusts holds the watch; until then she says so.
func _fetch(job: Job) -> void:
	var freya: Character = job.cast.get("freya")
	if freya == null or job.flags.has("fetching") or not job.flags.has("owner_call") or freya.minding:
		return
	if not job.crew.any(func(c): return c.flags.has("watch") and not c.held):
		if not job.flags.has("waiting"):
			job.flags["waiting"] = true
			freya.say_scripted("I'm alone on the bridge. As soon as someone takes the watch, I'll fetch it.")
		return
	if job.heat.level >= Heat.LOCKDOWN:
		return
	job.flags["fetching"] = true
	freya.say_scripted("You have the watch. Two minutes.")
	freya.walk_to("safe_in")


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"owner":
			job.flags["owner_call"] = true
			ch.note("Mr Halvorsen's office rang: he needs the reserve and the guarantees from the auction file read to him on that line. You'll fetch it as soon as someone you trust holds the watch.")
			_fetch(job)
		"museum":
			ch.note("The museum's director rang: a patron aboard tonight is mad about sailing ships, and you're to show them the Kestrel.")
			for c in job.crew:
				JobRules.nudge(ch.face_of(c.id), -1)


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	if who != "kofi" or c == null:
		return {}
	if c.cover == "deck" and (Job.any(said, ["deckhand", "deck", "kofi", "watch", "harbor crew"]) or (c.cover_name != "" and said.contains(c.cover_name.to_lower()))):
		return Job.fact("good", "You signed on a new deckhand from Harbor Crew last night, %s, and you'd trust them with a watch." % c.cover_name, "That's my new deckhand. Signed on last night. Good with a wheel.")
	if c.cover == "steward" and Job.any(said, ["stew", "steward", "bianca"]):
		return Job.fact("bad", "That's Bianca's temp stew, not one of your deck crew. You didn't send anyone up.", "That's one of Bianca's stews. I didn't send anyone up.")
	return Job.fact("bad", "You didn't send anyone up to the bridge.", "I didn't send anyone up.")


func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"turndown":
			job.flags["turndown_on"] = true
		"turndown_done":
			job.flags.erase("turndown_on")
			job.flags["relock"] = true
		"turn":
			job.toast_for.emit(0, "Ten minutes, and the Marlin turns for home.")
			for ch in job.cast.values():
				ch.note("The Marlin turns for home at a quarter past nine.")


func tick(job: Job, _delta: float) -> void:
	var anders: Character = job.cast.get("anders")
	# The captain shows off his Kestrel, until the bridge calls him away.
	if job.flags.has("showing") and anders and not anders.walking and anders.post == "anders_cabin" and not job.flags.has("called_away"):
		if not job.flags.has("shown_at"):
			job.flags["shown_at"] = job.elapsed
			job.open_for("captain", Job.OPEN_FOR)
			anders.say_scripted("There she is. The Kestrel. Come in, come in.")
		elif job.elapsed - float(job.flags.shown_at) > SHOWING:
			job.flags["called_away"] = true
			var freya: Character = job.cast.get("freya")
			if freya:
				freya.say_scripted("Captain, bridge. Could you come up a moment?", anders)
			anders.say_scripted("Duty calls. Make yourself at home, I'll be five minutes.")
			anders.walk_to("anders")
			job.lock("captain", false)
			var guest := job.crew_by_id(int(job.flags.showing))
			if guest:
				job.toast_for.emit(guest.id, "The captain's called to the bridge. He's left you in his cabin.")
	# Ollie holds the door for whoever offered to help.
	if job.flags.has("turndown_on") and not job.flags.has("held_door") and _at(job, "ollie", ["ollie_bed"]):
		job.flags["held_door"] = true
		for c in job.crew:
			if c.flags.has("turndown") and not c.held:
				job.open_for("captain", Job.OPEN_FOR * 1.5)
				job.toast_for.emit(c.id, "Ollie's holding the captain's door for you.")
	# Locked again once nobody's inside.
	if job.flags.has("relock") and not job.crew.any(func(c): return not c.held and job.venue.zone_at(c.position()) in ["captain", "safe"]):
		job.flags.erase("relock")
		job.lock("captain", true)
	# The owner's office, the watch, and the file read down the phone.
	if job.flags.has("owner_call") and not job.flags.has("fetching"):
		_fetch(job)
	var freya: Character = job.cast.get("freya")
	if job.flags.has("fetching") and freya and not freya.walking and freya.post == "safe_in" and not job.done:
		freya.say_scripted("Reserve, one million eight hundred thousand. Mrs Lindqvist, guaranteed by Nordbank to two and a half. Mr Achterberg, to two. Shall I go on?")
		job.finish("read")


## Whether a character stands at one of these spots, done walking.
func _at(job: Job, char_id: String, spots: Array) -> bool:
	var ch: Character = job.cast.get(char_id)
	return ch != null and not ch.walking and ch.post in spots and ch.global_position.distance_to(job.spot(ch.post).origin) < 0.3


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return c.flags.has("showing") or c.flags.has("turndown") or c.flags.has("watch")


func check_end(job: Job) -> String:
	var h := job.holder("auction_file")
	return "done" if h != null and not h.held else ""


func at_end(_job: Job) -> String:
	return "home"
