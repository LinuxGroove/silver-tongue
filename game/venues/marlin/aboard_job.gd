class_name MarlinAboardJob
extends JobDef
## Job 1 aboard the Marlin: the night she takes on crew and stores at the
## marina. Get aboard as crew before she sails at midnight: as Bianca's temp
## stew (once the purser has heard from Harbor Crew), as Rocco's galley hand,
## as a deckhand on Jun's crew list past Kofi at the gangway, or carrying
## Sal's stores down to a galley that never lets you leave.

const SAIL := 24 * 60
## When Rocco storms up to the quay about the stores, and goes back down.
const ROCCO_UP := 23 * 60 + 25
const ROCCO_DOWN := 23 * 60 + 41
const LAST_CALL := 23 * 60 + 50
## The caller ID the agency rings from.
const AGENCY := "Harbor Crew"


func _init() -> void:
	id = "marlin_aboard"
	venue_id = "marlin"
	number = 1
	memory_from = ["meridian"]
	title = "Aboard"
	venue_name = "The Marlin"
	briefing = "The Marlin, love: sixty meters of Halvorsen money in the marina, and the Rose goes under the hammer aboard her. Tonight she takes on crew and stores, and at midnight she sails for the preview. I want one of us on her crew list. Bianca, the chief stew, is a stew short. The chef will hire anyone with two hands. Kofi on the gangway goes by the purser's list, and the purser goes by Harbor Crew, which, between us, is whoever rings her. And the chandler's driver has more crates than back. Get aboard before she sails."
	goal = "Get aboard the Marlin as crew before she sails at midnight"
	situation = MarlinCast.SITUATIONS.aboard
	prize = "a berth aboard the Marlin"
	take = 3000
	start = 23 * 60 + 15
	end = SAIL
	end_text = "she sails"
	covers = {
		"stew": {
			"title": "Agency stew",
			"names": ["Toby Lane", "Tess Lane"],
			"job": "a temp stew from Harbor Crew, the crewing agency",
			"story": "Bianca, the chief stew, asked Harbor Crew for a temp on Monday and nobody came. You're the temp: in your whites, and late.",
			"outfit": "stew_whites",
			"for": "Bianca, the chief stew, on the quay",
			"lines": [
				"Evening. Harbor Crew sent me. I'm your temp stew.",
				"%s. Sorry I'm late, the agency only rang me this afternoon.",
				"Three seasons on charter yachts. Silver service, the lot.",
				"Your purser will have heard from Harbor Crew. Can you check?",
			],
		},
		"galley": {
			"title": "Galley hand",
			"names": ["Nico Ferri", "Gina Ferri"],
			"job": "a galley hand looking for a season's work",
			"story": "The chef's been shouting for hands all evening. You can peel, you can scrub and you keep up. He comes up to the quay for his stores; or ring the galley.",
			"outfit": "galley_whites",
			"for": "Rocco, the chef",
			"lines": [
				"Chef! I hear you need hands.",
				"I can peel, I can scrub, and I keep up.",
				"%s. Three seasons in hotel kitchens.",
				"Give me an apron and point me at the onions.",
			],
		},
		"deck": {
			"title": "Deckhand",
			"names": ["Ray Dorsey", "Rae Dorsey"],
			"job": "a deckhand joining the Marlin for the season through Harbor Crew",
			"story": "Kofi checks every name at the gangway against the purser's list. You have a discharge book and a Harbor Crew contract: good copies. Get on Jun's list, or have Harbor Crew ring her.",
			"outfit": "deck_polo",
			"for": "Jun, the purser, and Kofi, the bosun, at the gangway",
			"lines": [
				"Evening. %s, the new deckhand. Harbor Crew sent me.",
				"I'm joining for the season. I should be on the purser's list.",
				"Here's my discharge book and the contract.",
				"That's beautiful teak. Who looks after it?",
			],
		},
		"driver": {
			"title": "Chandler's mate",
			"names": ["Gus Pike", "Gail Pike"],
			"job": "a driver's mate from Caldera Chandlers, sent to help with the stores",
			"story": "Sal's mate is off sick and he has twelve crates for the Marlin's galley. Carry the stores aboard on his docket, and when the chef sees you, you might never leave.",
			"outfit": "chandler",
			"for": "Sal, the chandler's driver, then Kofi with the docket",
			"lines": [
				"Sal? The depot sent me. Gino's off sick.",
				"Give me the docket and I'll carry.",
				"Stores for the galley. Here's the docket.",
				"%s, Caldera Chandlers. Where do the crates go?",
			],
		},
	}
	cover_order = ["stew", "galley", "deck", "driver"]
	outfits = {
		"stew_whites": {"job": "yacht_stew", "male": "the Marlin's white steward's uniform", "female": "the Marlin's white stewardess's uniform"},
		"galley_whites": {"job": "kitchen", "male": "chef's whites and an apron", "female": "chef's whites and an apron"},
		"deck_polo": {"job": "yacht_deck", "male": "a navy deck crew polo and shorts", "female": "a navy deck crew polo and shorts"},
		"chandler": {"job": "chandler", "male": "a green Caldera Chandlers work jacket", "female": "a green Caldera Chandlers work jacket"},
	}
	staff_looking = ["stew_whites", "galley_whites", "deck_polo"]
	staff_rooms = MarlinCast.CREW_ROOMS.duplicate()
	for z in ["aft_deck", "saloon", "dining", "lobby", "sun_deck", "sky_lounge"]:
		staff_rooms[z] = "the Marlin, where only crew are aboard tonight"
	looks = MarlinCast.LOOKS
	extras = {"outside": "yacht_deck", "galley": "kitchen", "mess": "yacht_deck"}
	routine = [
		[ROCCO_UP, "rocco", "rocco_quay"],
		[ROCCO_DOWN, "rocco", "rocco"],
		[LAST_CALL, "freya", "freya"],
		[23 * 60 + 52, "bianca", "bianca_bar"],
	]
	chatter = [
		[23 * 60 + 17, "bianca", "Jun, any word from Harbor Crew about my temp?", "radio"],
		[23 * 60 + 17, "jun", "Nothing, Bianca. They never ring.", "radio"],
		[23 * 60 + 21, "sal", "Twelve crates. My back.", "near"],
		[ROCCO_UP + 1, "rocco", "Sal! Twelve crates! Twelve! Where are my stores?", "near"],
		[ROCCO_UP + 2, "sal", "Gino's sick, chef. I've got one pair of hands.", "near"],
		[ROCCO_UP + 6, "rocco", "Two hands short, and the stores still on the quay. Madonna.", "near"],
		[23 * 60 + 35, "teo", "Kofi, Teo. Anyone on the gangway I should know about?", "radio"],
		[23 * 60 + 35, "kofi", "Only crew and stores, Teo.", "radio"],
		[LAST_CALL, "kofi", "Last call! All crew aboard. Gangway comes up at midnight.", "near"],
		[23 * 60 + 55, "freya", "Bridge, stern. Five minutes, Captain.", "radio"],
	]
	events = [[LAST_CALL, "last_call"]]
	locked = ["gangway", "captain", "safe"]
	unlocked = ["crew", "saloon", "galley", "cabin_a", "cabin_b", "sun", "bridge"]
	lockdown_doors = ["gangway", "crew"]
	lockdown_text = "Lockdown. The gangway's shut and Halberd has the decks."
	door_texts = {"gangway": "The gate's shut. Kofi checks every name.", "captain": "The captain's cabin. Locked.", "safe": "The captain's strongroom. Locked."}
	office = {"door": "cabin_b", "held": "held", "guard": "held_guard", "name": "a locked crew cabin below decks"}
	items = {
		"crate": {"name": "a crate of stores", "at": "stores", "carry": "carrying a crate of stores"},
		"docket": {
			"name": "the delivery docket", "at": "", "carry": "",
			"papers": "Caldera Chandlers' delivery docket for the Marlin's galley, twelve crates, with %s down as the driver's mate",
			"belief": "delivering the galley's stores for Caldera Chandlers", "to": ["kofi", "teo", "jun"],
		},
		"discharge_book": {
			"name": "the discharge book and contract", "at": "", "carry": "",
			"papers": "a seaman's discharge book and a Harbor Crew contract in the name of %s", "forged": true,
			"copy": "the agency's stamp is printed, not inked, and the book has never been near salt water. It's a copy.",
			"belief": "has a Harbor Crew contract as a deckhand", "to": ["jun", "kofi"],
		},
	}
	actions = {
		"ask_purser": {"text": "radio Jun, the purser, to check them against the crew list (takes a moment)", "kind": "check"},
		"take_on": {"text": "take them on as your temp stew and walk them up the gangway", "kind": "opening", "lockdown": true},
		"hire": {"text": "hire them as a galley hand and tell Kofi to let them up", "kind": "opening", "lockdown": true},
		"hand_docket": {"text": "give them the delivery docket, so they can carry the crates aboard for you", "kind": "opening"},
	}
	effects = {
		"take_on": {"flag": "crew", "open": "gangway", "for": Job.OPEN_FOR, "walk": "bianca_bar", "toast": "%s has taken you on. Up the gangway with her."},
		"hire": {"flag": "crew", "open": "gangway", "for": Job.OPEN_FOR, "toast": "%s has hired you for the galley. Up the gangway, and below."},
		"hand_docket": {"flag": "delivering", "item": "docket", "toast": "%s gives you the delivery docket. Take a crate and show the bosun."},
		"add_to_list": {"flag": "listed", "toast": "%s has put you on the crew list. Kofi will find you on it."},
	}
	hot_words = ["stowaway", "sneak aboard", "not really crew"]
	phone = [
		{"id": "purser", "name": "Jun, the Marlin's purser", "who": "jun"},
		{"id": "chief_stew", "name": "Bianca, chief stew", "who": "bianca"},
		{"id": "galley", "name": "The Marlin's galley", "who": "rocco"},
		{"id": "bridge", "name": "The Marlin's bridge", "who": "anders"},
	]
	caller_ids = ["Withheld", AGENCY, "Caldera Chandlers", "Halvorsen Shipping"]
	mae_calls = [
		{"id": "temp", "label": "Ring the purser about the temp", "who": "jun", "as": AGENCY,
			"line": "Evening, Harbor Crew. Our temp stew for Bianca is on the quay now. So sorry it's late, it's been one of those nights.",
			"answer": "Finally. Fine, I'll tell Bianca when she asks.",
			"mae": "I'll ring the purser as Harbor Crew, love. When Bianca checks, the temp will be expected."},
		{"id": "crewing", "label": "Ring the purser about the deckhand", "who": "jun", "as": AGENCY,
			"line": "Harbor Crew again. We've a new deckhand joining the Marlin tonight. Short notice, I know. Their papers are with them.",
			"answer": "Of course you have. Fine. I'll put them down.",
			"mae": "Harbor Crew has a new deckhand for you, love. Jun will have them on her list when Kofi asks."},
		{"id": "depot", "label": "Ring Sal as his depot", "who": "sal", "as": "Caldera Chandlers",
			"line": "Sal, it's the depot. We've sent someone down to help you carry. Be nice to them.",
			"answer": "About time. My back thanks you.",
			"mae": "I'll ring Sal as his depot. He'll be glad of a helping hand."},
	]
	outcomes = {
		"aboard": ["ABOARD", "Signed on and aboard the Marlin at %s."],
		"ashore": ["LEFT ON THE QUAY", "The Marlin sailed at midnight without the crew."],
	}
	wins = ["aboard"]


func venue() -> Venue:
	return Marlin.new("aboard")


func cast() -> Array[CharacterSheet]:
	var out := MarlinCast.all("aboard")
	for s in out:
		if s.id == "jun":
			s.action_words = {"add_to_list": "add their name to the crew list"}
	return out


func give_items(crew: Array) -> void:
	for c in crew:
		if c.cover == "deck":
			c.items.append("discharge_book")


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"stores_drop":
			if not "crate" in c.items:
				return "The counter where the stores go."
			# Back to the stack on the quay: there are eleven more.
			job.place_item(c.id, "crate", "stores")
			job.show_node("GalleyCrate", true)
			c.flags["delivered"] = true
			if _rocco_below(job):
				_keep(job, c)
				return ""
			return "You leave the crate on the counter for the chef."
		"safe_keypad":
			return "The captain's strongroom. Nothing in it for you tonight."
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	if what == "stores_drop":
		return "Put the crate down" if "crate" in c.items else ""
	if what == "safe_keypad":
		return ""
	return null


func can_take(_job: Job, c: CrewInfo, item: String) -> String:
	if item == "crate" and not (c.flags.has("delivering") or c.flags.has("crew")):
		return "Those are Sal's crates. He'd want to know who you are."
	return ""


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	if act == "let_through" and ch.sheet.id == "kofi":
		job.open_for("gangway", Job.OPEN_FOR)
		if c.flags.has("delivering") and not (c.flags.has("listed") or c.flags.has("crew")):
			job.toast_for.emit(c.id, "Kofi waves you up with the stores. The galley's below: the crew stair, port side.")
		else:
			c.flags["crew"] = true
			job.toast_for.emit(c.id, "Kofi lets you up the gangway. Welcome aboard.")
		return true
	return false


## Whether Harbor Crew has told Jun about a temp ("temp") or a new
## deckhand ("deck"): Mae's call, or anyone ringing her from the agency's
## number and saying so.
func _agency(job: Job, kind: String) -> bool:
	if job.flags.has("agency:" + kind):
		return true
	var jun: Character = job.cast.get("jun")
	if jun == null:
		return false
	var words: Array = ["temp", "stew", "steward"] if kind == "temp" else ["deckhand", "deck", "new crew", "joining"]
	for other in job.crew:
		if job.flags.has("rang_jun:%d" % other.id) and Job.any(job.told(jun, other.id), words):
			return true
	return false


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	if who != "jun" or c == null:
		return {}
	if c.flags.has("listed"):
		return Job.fact("good", "You put them on the crew list yourself tonight.", "Yes, they're on my list. I put them there myself.")
	if c.flags.has("crew"):
		return Job.fact("good", "They've been taken on tonight.", "Yes, they're crew. Signed on tonight.")
	if Job.any(said, ["stores", "docket", "chandler", "delivering", "crate", "delivery"]):
		if c.flags.has("delivering"):
			return Job.fact("good", "Sal's van has the galley's stores tonight, and his docket says who's carrying.", "The chandler's stores? Yes. Send them down to the galley.")
		return Job.fact("bad", "Sal hasn't said anything about a second driver.", "The chandler's? Sal's on his own tonight, as far as I know.")
	if Job.any(said, ["temp", "stew", "steward"]):
		if _agency(job, "temp"):
			return Job.fact("good", "Harbor Crew rang tonight: Bianca's temp stew is on the quay.", "Yes, Harbor Crew rang. The temp's expected. Take them.")
		return Job.fact("bad", "Bianca asked Harbor Crew for a temp on Monday and they've said nothing since.", "Harbor Crew hasn't rung me about any temp.")
	if Job.any(said, ["deckhand", "deck", "new crew", "joining", "harbor crew", "agency", "contract"]) or (c.cover_name != "" and said.contains(c.cover_name.to_lower())):
		if _agency(job, "deck"):
			return Job.fact("good", "Harbor Crew rang tonight about a new deckhand joining.", "Yes, Harbor Crew rang about a new deckhand. They're on my list.")
		return Job.fact("bad", "Harbor Crew hasn't sent you any new deckhand.", "No new deckhand on my list. Harbor Crew hasn't sent anyone.")
	if Job.any(said, ["galley", "rocco", "chef", "kitchen"]):
		return Job.fact("bad", "Rocco hasn't told you he's taken anyone on.", "Rocco hasn't told me about anyone.")
	return Job.fact("bad", "They're not on your crew list.", "Not on my list.")


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"temp":
			job.flags["agency:temp"] = true
			ch.note("Harbor Crew rang: Bianca's temp stew is on the quay now. If anyone asks, the temp is expected.")
		"crewing":
			job.flags["agency:deck"] = true
			ch.note("Harbor Crew rang: a new deckhand joins tonight, with their papers. If Kofi asks, they're on your list.")
		"depot":
			ch.note("Your depot rang: they've sent someone down to help you carry tonight.")
			for c in job.crew:
				JobRules.nudge(ch.face_of(c.id), -1)


func on_event(job: Job, event_name: String) -> void:
	if event_name == "last_call":
		for ch in job.cast.values():
			ch.note("Last call. The gangway comes up at midnight.")
		job.toast_for.emit(0, "Last call: the gangway comes up at midnight.")


func tick(job: Job, _delta: float) -> void:
	# The agency's number ringing the purser.
	for id in job.calls:
		var rang: Dictionary = job.calls[id]
		if str(rang.get("who", "")) == "jun" and str(rang.get("as", "")) == AGENCY:
			job.flags["rang_jun:%d" % id] = true
	# Stores left in the galley: the chef keeps whoever carried them.
	if _rocco_below(job):
		for c in job.crew:
			if c.flags.has("delivered") and not c.flags.has("crew") and not c.held and job.venue.zone_at(c.position()) == "galley":
				_keep(job, c)
	for c in job.crew:
		var aboard: bool = not c.held and c.node != null and c.flags.has("crew") and job.venue.zone_at(c.position()) != "outside"
		if aboard != c.inside:
			c.inside = aboard
			job.crew_changed.emit(c.id)
			if aboard:
				job.toast_for.emit(c.id, "You're aboard, and on the crew.")


## Rocco is in his galley, not on his way anywhere.
func _rocco_below(job: Job) -> bool:
	var r: Character = job.cast.get("rocco")
	return r != null and not r.walking and not r.minding and job.venue.zone_at(r.global_position + Vector3.UP * 0.5) == "galley"


## The chef keeps the one who carried his stores down.
func _keep(job: Job, c: CrewInfo) -> void:
	c.flags["crew"] = true
	var r: Character = job.cast.get("rocco")
	if r:
		r.say_scripted("You carried my stores down? Then you stay. I'm two hands short. Apron's on the hook.")
		r.note("The chandler's mate, %s, brought your stores down. You've kept them on as a galley hand." % job.describe(c.id))
	job.toast_for.emit(c.id, "Rocco keeps you on in the galley. You're crew.")


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return c.flags.has("crew") or c.flags.has("delivering") or c.flags.has("listed")


func check_end(job: Job) -> String:
	var free := job.free_crew()
	if not free.is_empty() and free.all(func(c): return c.inside):
		return "aboard"
	return ""


func at_end(job: Job) -> String:
	return "aboard" if job.crew.any(func(c): return c.inside) else "ashore"
