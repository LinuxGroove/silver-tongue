extends RefCounted
## The Marlin (game/venues/marlin/) and its three jobs: the yacht on each of
## its nights through the checks every venue passes ([VenueChecks]), and
## every way through Aboard, The captain's safe and The auction, alone and
## with two, by [JobHarness].
##   godot --headless --path . tests/run_tests.tscn -- --only=marlin

const NIGHTS: Array[String] = ["aboard", "safe", "auction"]
## Spots on every night, and the zone each is in.
const SPOT_ZONES := {
	"teo_gang": "aft_deck", "kofi_aft": "aft_deck", "freya_stern": "aft_deck", "bianca_bar": "aft_deck",
	"celeste_aft": "aft_deck", "hugo_aft": "aft_deck", "aft_port": "aft_deck", "aft_sb": "aft_deck",
	"rocco": "galley", "galley_c": "galley", "ollie": "mess", "laundry": "laundry", "held": "cabin_b",
	"held_guard": "crew_hall", "saloon_in": "saloon", "saloon_c": "saloon", "dining_e": "dining", "lobby_c": "lobby",
	"sun_c": "sun_deck", "sky_c": "sky_lounge", "captain_c": "captain", "ollie_bed": "captain",
	"anders_cabin": "captain", "safe_out": "captain", "safe_in": "safe", "ollie_ensuite": "captain",
	"freya": "bridge", "anders": "bridge",
}
## And each night's own.
const NIGHT_SPOTS := {
	"aboard": {"crew_0": "outside", "crew_1": "outside", "kofi": "outside", "jun": "outside", "bianca_quay": "outside", "sal": "outside"},
	"safe": {"crew_0": "aft_deck", "crew_1": "aft_deck", "anders_saloon": "saloon", "teo_rose": "saloon", "rupert_rose": "saloon"},
	"auction": {"crew_0": "aft_deck", "crew_1": "aft_deck", "nina_desk": "aft_deck", "rupert": "saloon", "nina_phone": "saloon",
		"margit": "saloon", "pieter": "saloon", "celeste_side": "saloon", "hugo_side": "saloon"},
}
const DOORS: Array[String] = ["crew", "saloon", "galley", "cabin_a", "cabin_b", "sun", "captain", "safe", "bridge"]
## Places in each room.
const ROOM_SAMPLES := {
	"aft_deck": [Vector3(0, 2, -5), Vector3(-3, 2, -8)], "saloon": [Vector3(1, 2, -14), Vector3(-3, 2, -19)],
	"dining": [Vector3(0, 2, -22)], "lobby": [Vector3(0, 2, -28)], "crew_stair": [Vector3(-3.7, 0, -14)],
	"galley": [Vector3(2.5, -0.5, -20)], "mess": [Vector3(-3, -0.5, -21)], "crew_hall": [Vector3(0, -0.5, -25)],
	"cabin_a": [Vector3(-3, -0.5, -28)], "laundry": [Vector3(2.5, -0.5, -24.4)], "cabin_b": [Vector3(3, -0.5, -29)],
	"sun_deck": [Vector3(0, 5, -8)], "sky_lounge": [Vector3(0, 5, -17)], "captain": [Vector3(-2, 5, -25)],
	"safe": [Vector3(-3.3, 5, -32)], "upper_hall": [Vector3(2.5, 5, -27)], "bridge": [Vector3(0, 5, -36)],
	"outside": [Vector3(0, 1, 6), Vector3(10, 1, 20)],
}


func _spots(night: String) -> Dictionary:
	var s := SPOT_ZONES.duplicate()
	s.merge(NIGHT_SPOTS[night])
	return s


func test_builds(t) -> void:
	for night in NIGHTS:
		var label := "marlin (%s)" % night
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night))
		for d in DOORS:
			t.check(v.doors.get(d) is HotelDoor, "%s: the %s door" % [label, d])
		t.check(v.doors.has("gangway") == (night != "safe"), "%s: a gangway only when she's moored" % label)
		t.check(v.uses.has("stores") == (night == "aboard"), "%s: the stores on the quay only tonight" % label)
		t.check(v.uses.has("safe_shelf") == (night == "safe"), "%s: the file in the safe only tonight" % label)
		t.check(v.uses.has("paddle") == (night == "auction") and v.uses.has("rostrum") == (night == "auction"), "%s: the desk and rostrum only at the sale" % label)
		t.check(v.uses.has("safe_keypad"), "%s: the strongroom's keypad" % label)
		var pad: Vector3 = v.uses.safe_keypad.global_position
		t.check(v.zone_at(pad) == "captain" and pad.distance_to(v.doors.safe.centre()) < 1.5, "%s: the keypad is by the strongroom door, cabin side" % label)
		VenueChecks.structure(t, v, label, _spots(night))
		VenueChecks.standing_room(t, v, label)
		v.queue_free()


func test_walkable(t) -> void:
	for night in NIGHTS:
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night), true)
		VenueChecks.walkable(t, v, "marlin (%s)" % night)
		v.queue_free()


func test_doors_block(t) -> void:
	for night in ["aboard", "safe"]:
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night))
		await VenueChecks.doors_block(t, v, "marlin (%s)" % night)
		v.queue_free()


func test_zones(t) -> void:
	var v := Marlin.new()
	for room in ROOM_SAMPLES:
		for p in ROOM_SAMPLES[room]:
			t.check(v.zone_at(p) == room, "marlin: %s is in the %s (%s)" % [p, room, v.zone_at(p)])
	v.free()


#region The jobs

func test_job_data(t) -> void:
	for def in [MarlinAboardJob.new(), MarlinSafeJob.new(), MarlinAuctionJob.new()]:
		VenueChecks.job_data(t, def)
		await VenueChecks.routines(t, def)
	t.check(Jobs.at_venue("marlin") == ["marlin_aboard", "marlin_safe", "marlin_auction"], "the Marlin's three jobs, in order")
	for id in Jobs.at_venue("marlin"):
		t.check(Jobs.make(id).memory_from == ["meridian"], "%s: Teo and the Marlowes remember the crew from the Meridian" % id)
	var teo := MarlinCast.sheet("teo", "safe")
	t.check(teo.voice == MeridianCast.teo().voice and teo.name == MeridianCast.teo().name, "Teo is the same man who kept the Meridian's ballroom doors")
	var voices := {}
	for id in ["teo", "kofi", "jun", "bianca", "rocco", "ollie", "sal", "anders", "freya", "rupert", "nina", "margit", "pieter", "hugo", "celeste"]:
		var s := MarlinCast.sheet(id, "auction" if id in ["rupert", "nina"] else "aboard")
		t.check(s != null and not voices.has(s.voice), "%s has a voice of their own (%s)" % [id, s.voice if s else "?"])
		if s:
			voices[s.voice] = id


## Starts a job with this crew, keeping the report when it ends.
func _start(t, def: JobDef, covers: Array) -> Job:
	var job := JobHarness.start(t, def, covers)
	job.ended.connect(_on_ended.bind(job))
	return job


func _on_ended(r: Dictionary, job: Job) -> void:
	job.set_meta("report", r)


func _outcome(job: Job) -> String:
	return str(job.get_meta("report", {}).get("outcome", ""))


## Faces someone, says a line and waits for the answer: what they did.
func _talk(t, job: Job, id: int, char_id: String, text: String, distance := 1.4) -> String:
	JobHarness.face(job, id, char_id, distance)
	return await _said(t, job, id, char_id, text)


## Says a line (to whoever's faced, or down the phone) and waits until the
## character has answered it: what they did about it.
func _said(t, job: Job, id: int, char_id: String, text: String) -> String:
	var ch: Character = job.cast[char_id]
	var before := ch.turns.size()
	JobHarness.say(job, id, text)
	t.check(await t.until(func(): return ch.turns.size() > before and not ch.busy, 6.0), "%s answers \"%s\"" % [char_id, text])
	for i in range(before, ch.turns.size()):
		if str(ch.turns[i].kind) == "line" and ch.turns[i].has("reply"):
			return str(ch.turns[i].reply.get("do", "none"))
	return "none"


## Says a line down the phone and waits for the answer.
func _on_phone(t, job: Job, id: int, char_id: String, text: String) -> String:
	return await _said(t, job, id, char_id, text)


## Rings a number and waits for the hello.
func _ring(t, job: Job, id: int, number: String, as_who: String, char_id: String) -> void:
	var ch: Character = job.cast[char_id]
	var before := ch.turns.size()
	t.check(job.ring(id, number, as_who) == "", "%s's phone rings" % char_id)
	t.check(await t.until(func(): return ch.turns.size() > before and not ch.busy, 6.0), "%s picks up" % char_id)


func _mae(t, job: Job, call_id: String, flag: String) -> void:
	t.check(job.mae_call(1, call_id), "Mae makes her %s call" % call_id)
	t.check(await t.until(func(): return job.flags.has(flag), 10.0), "and it does what it should (%s)" % flag)


func _ended(t, job: Job, outcome: String, label: String) -> void:
	t.check(await t.until(func(): return job.done, 8.0) and _outcome(job) == outcome, "%s: it ends %s (%s)" % [label, outcome, _outcome(job)])

#endregion

#region Aboard

## Bianca's temp: the purser has heard from Harbor Crew (Mae, ringing as
## the agency), so Bianca's check comes back good and she takes them on.
func test_aboard_stew(t) -> void:
	var job := _start(t, MarlinAboardJob.new(), ["stew"])
	await t.frames(2)
	await _mae(t, job, "temp", "agency:temp")
	t.check(await _talk(t, job, 1, "bianca", "Evening. Harbor Crew sent me. I'm your temp stew.") == "ask_purser", "Bianca checks the temp with Jun")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("crew"), 12.0), "Jun says Harbor Crew rang, and Bianca takes them on")
	t.check(job.venue.doors.gangway.is_open, "the gangway's open for them")
	JobHarness.stand_at(job, 1, "kofi_aft")
	await _ended(t, job, "aboard", "the temp stew")
	JobHarness.done(job)
	await t.frames(2)


## Rocco on the quay hires anyone; and over the phone, a crewmate too.
func test_aboard_galley(t) -> void:
	var job := _start(t, MarlinAboardJob.new(), ["galley", "galley"])
	await t.frames(2)
	await JobHarness.clock_to(t, job, MarlinAboardJob.ROCCO_UP)
	t.check(JobHarness.walk(job, job.cast.rocco, "rocco_quay"), "Rocco storms up to the quay")
	t.check(await _talk(t, job, 1, "rocco", "Chef! I hear you need hands.") == "none", "he wants to know they can work first")
	t.check(await _talk(t, job, 1, "rocco", "I can peel, I can scrub, and I keep up.") == "hire", "and hires them")
	t.check(job.crew_by_id(1).flags.has("crew") and job.venue.doors.gangway.is_open, "they're crew, and up the gangway")
	t.check(JobHarness.walk(job, job.cast.rocco, "rocco"), "Rocco goes back down")
	await _ring(t, job, 2, "galley", "Withheld", "rocco")
	await _on_phone(t, job, 2, "rocco", "Chef? I hear you need hands in the galley.")
	t.check(await _on_phone(t, job, 2, "rocco", "I can peel and scrub, and I keep up.") == "hire", "a crewmate rings the galley and he hires them too")
	job.hang_up(2)
	JobHarness.stand_at(job, 1, "kofi_aft")
	JobHarness.stand_at(job, 2, "bianca_bar")
	await _ended(t, job, "aboard", "the galley hands")
	JobHarness.done(job)
	await t.frames(2)


## Kofi checks a deckhand with Jun: good once Harbor Crew has rung her
## (Mae), or once she's put them on the list herself (the discharge book).
func test_aboard_deck(t) -> void:
	var job := _start(t, MarlinAboardJob.new(), ["deck"])
	await t.frames(2)
	await _mae(t, job, "crewing", "agency:deck")
	t.check(await _talk(t, job, 1, "kofi", "Evening. I'm the new deckhand. Harbor Crew sent me.") == "ask_purser", "Kofi checks the name with Jun")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("crew"), 12.0), "Jun has them, and Kofi lets them up")
	JobHarness.stand_at(job, 1, "kofi_aft")
	await _ended(t, job, "aboard", "the deckhand, on Mae's call")
	JobHarness.done(job)
	await t.frames(2)
	# On Jun's list by the discharge book, with a crewmate ringing as the agency.
	job = _start(t, MarlinAboardJob.new(), ["deck", "stew"])
	await t.frames(2)
	t.check("discharge_book" in job.crew_by_id(1).items, "the deckhand carries a discharge book")
	await _talk(t, job, 1, "jun", "Evening. I'm joining for the season. Harbor Crew sent me.")
	job.show_papers(1, job.cast.jun)
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("listed"), 8.0), "Jun looks at the book and puts them on the list")
	await _ring(t, job, 2, "purser", MarlinAboardJob.AGENCY, "jun")
	await _on_phone(t, job, 2, "jun", "Harbor Crew here. Your temp stew is on the quay now.")
	await t.frames(2)
	job.hang_up(2)
	t.check(job.flags.has("rang_jun:2") and job.def._agency(job, "temp"), "a crewmate ringing as Harbor Crew counts as the agency")
	t.check(await _talk(t, job, 1, "kofi", "Evening. I'm the new deckhand, on the list.") == "ask_purser", "Kofi checks")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("crew"), 12.0), "and up the deckhand goes")
	JobHarness.done(job)
	await t.frames(2)


## Sal hands over his docket; Kofi waves the stores up; the crate goes
## down to the galley, and Rocco keeps whoever carried it.
func test_aboard_driver(t) -> void:
	var job := _start(t, MarlinAboardJob.new(), ["driver"])
	await t.frames(2)
	t.check(job.take(1, "crate").contains("Sal's"), "Sal's crates aren't anyone's to take")
	t.check(await _talk(t, job, 1, "sal", "Sal? The depot sent me. I'll carry.") == "none", "Sal wants to know who sent them")
	t.check(await _talk(t, job, 1, "sal", "Gino's off sick. I'll help you unload.") == "hand_docket", "and hands them the docket")
	t.check("docket" in job.crew_by_id(1).items and job.take(1, "crate").begins_with("You take"), "with the docket, a crate")
	job.show_papers(1, job.cast.kofi)
	t.check(await t.until(func(): return job.venue.doors.gangway.is_open, 14.0), "Kofi checks the docket with Jun and waves the stores up")
	t.check(not job.crew_by_id(1).flags.has("crew"), "carrying stores isn't joining the crew")
	JobHarness.stand_at(job, 1, "galley_c")
	job.use(1, "stores_drop")
	t.check(job.crew_by_id(1).flags.has("crew") and job.shown_nodes().get("GalleyCrate", false), "the crate's on the counter, and Rocco keeps them")
	await _ended(t, job, "aboard", "the chandler's mate")
	JobHarness.done(job)
	await t.frames(2)


func test_aboard_goes_wrong(t) -> void:
	var job := _start(t, MarlinAboardJob.new(), ["stew", "galley"])
	await t.frames(2)
	t.check(await _talk(t, job, 1, "bianca", "Evening. Harbor Crew sent me. I'm your temp stew.") == "ask_purser", "Bianca checks the temp")
	t.check(await t.until(func(): return job.cast.bianca.turns.size() >= 2 and not job.cast.bianca.busy, 12.0), "and hears back")
	t.check(not job.crew_by_id(1).flags.has("crew") and job.cast.bianca.suspicion_of(1) >= 2, "Harbor Crew never rang Jun: no temp, and Bianca's wary")
	t.check(job.use(1, "door:gangway") != "" and not job.venue.doors.gangway.is_open, "the gangway gate stays shut")
	job.heat.bump(30.0)
	await t.frames(2)
	t.check(job.heat.level == Heat.LOCKDOWN, "trouble on the quay is Lockdown")
	await _talk(t, job, 2, "rocco", "Chef! I hear you need hands.")
	t.check(await _talk(t, job, 2, "rocco", "I can peel, I can scrub, and I keep up.") != "hire", "at Lockdown, even Rocco hires nobody")
	job._hold(1, job.cast.teo)
	t.check(job.crew_by_id(1).held and job.venue.doors.cabin_b.locked, "Teo holds them in a crew cabin below")
	job.minutes = MarlinAboardJob.SAIL + 0.1
	await _ended(t, job, "ashore", "midnight")
	JobHarness.done(job)
	await t.frames(2)

#endregion

#region The captain's safe

## Ollie's turndown: he holds the captain's door at ten to nine for whoever
## offered to help, and once he's warmed to them, he knows the code.
func test_safe_steward(t) -> void:
	var job := _start(t, MarlinSafeJob.new(), ["steward"])
	await t.frames(2)
	var ollie: Character = job.cast.ollie
	JobHarness.walk(job, ollie, "ollie")
	t.check(await _talk(t, job, 1, "ollie", "Ollie! Bianca sent me up to help you with the turndown.") == "none", "Ollie can't believe anyone would help")
	t.check(await _talk(t, job, 1, "ollie", "I'll do the bed, you do the bathroom.") == "take_along", "and takes them along")
	await _talk(t, job, 1, "ollie", "Kofi's the best deckhand on the coast, isn't he?")
	await _talk(t, job, 1, "ollie", "What's the code for the captain's strongroom?")
	t.check(str(ollie.turns.back().reply.say).contains(MarlinCast.SAFE_CODE), "warmed up, Ollie lets the code slip")
	await JobHarness.clock_to(t, job, MarlinSafeJob.TURNDOWN)
	t.check(JobHarness.walk(job, ollie, "ollie_bed"), "at ten to nine he goes up to the cabin")
	await t.frames(2)
	t.check(job.venue.doors.captain.is_open, "and holds the door for them")
	JobHarness.stand_at(job, 1, "safe_out")
	t.check(job.keypad(1, "1234", "safe_keypad") == "Wrong code.", "a wrong code does nothing")
	t.check(job.keypad(1, MarlinCast.SAFE_CODE, "safe_keypad") == "The lock clicks." and job.venue.doors.safe.is_open, "the Kestrel's year opens the strongroom")
	t.check(job.take(1, "auction_file").begins_with("You take"), "the auction file")
	await _ended(t, job, "done", "the turndown")
	JobHarness.done(job)
	await t.frames(2)


## Captain Lund and his Kestrel: he gives away the year talking about her,
## takes a fan up to see the model, and is called to the bridge.
func test_safe_guest(t) -> void:
	var job := _start(t, MarlinSafeJob.new(), ["guest"])
	await t.frames(2)
	var anders: Character = job.cast.anders
	t.check(await _talk(t, job, 1, "anders", "Captain, is it true your first command was a ketch? Tell me about the Kestrel.") == "none", "the captain talks about the Kestrel")
	t.check(str(anders.turns.back().reply.say).contains(MarlinCast.SAFE_CODE), "and her year")
	t.check(await _talk(t, job, 1, "anders", "I'd love to see her. Is there a model?") == "show_model", "he takes them up to see her model")
	t.check(JobHarness.walk(job, anders, "anders_cabin"), "up to his cabin")
	await t.frames(2)
	t.check(job.venue.doors.captain.is_open and job.flags.has("shown_at"), "he opens the cabin and shows her off")
	job.flags.shown_at = job.elapsed - MarlinSafeJob.SHOWING - 1.0
	await t.frames(2)
	t.check(job.flags.has("called_away") and anders.post == "anders" and not job.venue.doors.captain.locked, "the bridge calls him, and he leaves his cabin open")
	JobHarness.stand_at(job, 1, "safe_out")
	t.check(job.keypad(1, MarlinCast.SAFE_CODE, "safe_keypad") == "The lock clicks.", "the Kestrel's year")
	job.take(1, "auction_file")
	await _ended(t, job, "done", "the Kestrel")
	JobHarness.done(job)
	await t.frames(2)
	# Mae, ringing as the museum, warms him up first.
	job = _start(t, MarlinSafeJob.new(), ["guest"])
	await t.frames(2)
	await _mae(t, job, "museum", "mae:museum")
	t.check(await t.until(func(): return job.cast.anders.suspicion_of(1) == 0, 6.0), "the museum's call warms the captain to its patron")
	JobHarness.done(job)
	await t.frames(2)


## Freya hands the new deckhand the watch once Kofi vouches, and when the
## owner's office rings, she reads the file down the line.
func test_safe_deck(t) -> void:
	var job := _start(t, MarlinSafeJob.new(), ["deck"])
	await t.frames(2)
	var freya: Character = job.cast.freya
	t.check(await _talk(t, job, 1, "freya", "Evening. Kofi sent me up to take the watch.") == "ask_bosun", "Freya checks with Kofi")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("watch"), 12.0), "Kofi vouches, and she hands them the watch")
	await _mae(t, job, "owner", "fetching")
	t.check(freya.walking and freya.post == "safe_in", "with the watch held, Freya goes for the file")
	t.check(JobHarness.walk(job, freya, "safe_in"), "into the strongroom")
	await _ended(t, job, "read", "the owner's office, on Mae's call")
	JobHarness.done(job)
	await t.frames(2)
	# A crewmate rings the bridge as Halvorsen Shipping.
	job = _start(t, MarlinSafeJob.new(), ["deck", "steward"])
	await t.frames(2)
	freya = job.cast.freya
	await _talk(t, job, 1, "freya", "Evening. Kofi sent me up to take the watch.")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("watch"), 12.0), "the watch")
	JobHarness.stand(job, 1, Vector3(0, 0, 10), Vector3(0, 0, 0))
	await _ring(t, job, 2, "bridge", MarlinSafeJob.OWNER, "freya")
	await _on_phone(t, job, 2, "freya", "Mr Halvorsen's office. He needs the auction file read out tonight.")
	t.check(await _on_phone(t, job, 2, "freya", "The reserve and the guarantees, please. Read them to me on this line.") == "fetch_file", "Freya will fetch the file for the owner's office")
	t.check(job.flags.has("fetching"), "and goes for it")
	JobHarness.walk(job, freya, "safe_in")
	await _ended(t, job, "read", "the owner's office, on a crewmate's call")
	JobHarness.done(job)
	await t.frames(2)


func test_safe_goes_wrong(t) -> void:
	var job := _start(t, MarlinSafeJob.new(), ["steward", "guest"])
	await t.frames(2)
	t.check(await _talk(t, job, 1, "freya", "Evening. Kofi sent me up to take the watch.") == "ask_bosun", "Freya checks the steward with Kofi")
	t.check(await t.until(func(): return job.cast.freya.turns.size() >= 2 and not job.cast.freya.busy, 12.0), "and hears back")
	t.check(not job.crew_by_id(1).flags.has("watch"), "Kofi didn't send a stew: no watch")
	await _ring(t, job, 2, "bridge", "Withheld", "freya")
	await _on_phone(t, job, 2, "freya", "Mr Halvorsen's office. He needs the auction file read out tonight.")
	await _on_phone(t, job, 2, "freya", "The reserve and the guarantees, please. Read them to me on this line.")
	t.check(not job.flags.has("owner_call"), "from a withheld number, Freya won't fetch the file for 'the owner's office'")
	job.hang_up(2)
	t.check(job.use(1, "door:captain") == "The captain's cabin. Locked.", "the captain's cabin is locked")
	t.check(job.keypad(1, "1234", "safe_keypad") == "Wrong code.", "and a guess won't open the strongroom")
	await JobHarness.clock_to(t, job, MarlinSafeJob.HOME + 0.1)
	await _ended(t, job, "home", "the turn for home")
	JobHarness.done(job)
	await t.frames(2)

#endregion

#region The auction

## Runs the sale round by round, the crew's first member raising their
## paddle whenever someone else has the bid (when `bid`), until the hammer.
func _sale(t, job: Job, bid: bool) -> void:
	var m := float(MarlinAuctionJob.SALE)
	await JobHarness.clock_to(t, job, m)
	t.check(job.flags.has("sale") and job.cast.nina.post == "nina_phone", "at eight the sale opens, and Ms Castell takes the telephones")
	while not job.flags.has("sold") and m < MarlinAuctionJob.LAST - 2:
		if bid and str(job.flags.get("high", "")) != "crew:1":
			job.use(1, "rostrum")
		m += MarlinAuctionJob.ROUND
		await JobHarness.clock_to(t, job, m)
	t.check(job.flags.has("sold"), "the hammer falls by %s" % JobDef.clock_text(m))


## Registers the crew's first member at the desk.
func _register(t, job: Job) -> void:
	await _talk(t, job, 1, "nina", "Good evening. I'd like to register to bid.")
	job.show_papers(1, job.cast.nina)
	t.check(await t.until(func(): return "paddle_1" in job.crew_by_id(1).items, 8.0), "Ms Castell takes the letter and gives them paddle 41")


## Registered on Mae's letter, with Mae ringing Ms Castell as the bank: the
## crew outbids Mrs Lindqvist past two million.
func test_auction_bank(t) -> void:
	var job := _start(t, MarlinAuctionJob.new(), ["bidder"])
	await t.frames(2)
	await _register(t, job)
	await _mae(t, job, "bank", "bank_ok")
	await JobHarness.clock_to(t, job, MarlinAuctionJob.SALE)
	t.check(await _talk(t, job, 1, "rupert", "One million two hundred thousand!", 3.0) == "take_bid" and job.flags.get("high", "") == "crew:1", "a bid called out to Mr Ashcombe stands")
	await _sale(t, job, true)
	t.check(int(job.flags.price) > MarlinCast.CHECK_ABOVE and job.flags.has("bank_said"), "past two million, Ms Castell has the bank's word")
	await _ended(t, job, "won", "the bank's guarantee")
	var r: Dictionary = job.get_meta("report", {})
	t.check(bool(r.get("win", false)) and str(r.get("text", "")).contains("$"), "the report says the hammer price: %s" % r.get("text", ""))
	JobHarness.done(job)
	await t.frames(2)
	# A crewmate rings Ms Castell from the bank's number.
	job = _start(t, MarlinAuctionJob.new(), ["bidder", "stew"])
	await t.frames(2)
	await _ring(t, job, 2, "registrar", MarlinAuctionJob.BANK, "nina")
	await _on_phone(t, job, 2, "nina", "Good evening, Caldera Mutual. I'm calling to confirm our client's letter of guarantee.")
	t.check(await _on_phone(t, job, 2, "nina", "Our client is bidding tonight, to three million.") == "note_guarantee" and job.flags.has("bank_ok"), "Ms Castell notes the bank's guarantee")
	JobHarness.done(job)
	await t.frames(2)


## A whisper about the certificate takes Mrs Lindqvist out, and the crew
## beats Mr Achterberg without ever passing two million.
func test_auction_rumor(t) -> void:
	var job := _start(t, MarlinAuctionJob.new(), ["bidder"])
	await t.frames(2)
	await _register(t, job)
	t.check(await _talk(t, job, 1, "pieter", "Between us, I heard something about the certificate.") == "none", "Mr Achterberg wants more")
	t.check(await _talk(t, job, 1, "pieter", "They say it's a copy. The real one's in Antwerp.") == "spread_word", "and he's off to tell Margit")
	t.check(JobHarness.walk(job, job.cast.pieter, "pieter_margit"), "across the saloon")
	await t.frames(2)
	t.check(job.flags.has("margit_out") and job.cast.margit.post == "aft_port", "Mrs Lindqvist won't bid on her, and walks out")
	await _sale(t, job, true)
	t.check(int(job.flags.price) <= MarlinCast.CHECK_ABOVE and not job.flags.has("bank_ok"), "the bidding never needs the bank")
	await _ended(t, job, "won", "the rumor")
	JobHarness.done(job)
	await t.frames(2)
	# A crewmate tells Mrs Lindqvist herself, once she's warmed to them.
	job = _start(t, MarlinAuctionJob.new(), ["bidder", "stew"])
	await t.frames(2)
	await _talk(t, job, 2, "margit", "Is it true what they're saying about the certificate?")
	t.check(await _talk(t, job, 2, "margit", "They say the certificate's a copy.") != "withdraw" and not job.flags.has("margit_out"), "a stranger's whisper isn't enough for Mrs Lindqvist")
	JobHarness.done(job)
	await t.frames(2)
	job = _start(t, MarlinAuctionJob.new(), ["bidder", "stew"])
	await t.frames(2)
	await _talk(t, job, 2, "margit", "Eleven carats, and the clarity! A fancy pink like that is rare.")
	t.check(await _talk(t, job, 2, "margit", "Is it true what they're saying about the certificate?") == "withdraw" and job.flags.has("margit_out"), "but from someone who knows stones, it is")
	JobHarness.done(job)
	await t.frames(2)


## Hugo Marlowe bids for the crew's client, and Mr Ashcombe takes his word.
func test_auction_proxy(t) -> void:
	var job := _start(t, MarlinAuctionJob.new(), ["agent"])
	await t.frames(2)
	t.check(await _talk(t, job, 1, "hugo", "You sold the Halvorsens this boat? She's beautiful.") == "none", "Hugo loves to hear about the Marlin")
	t.check(await _talk(t, job, 1, "hugo", "I act for a client who can't be seen bidding. Three percent.") == "bid_for", "and he'll bid for the client")
	await _sale(t, job, false)
	t.check(job.flags.high == "hugo" and int(job.flags.price) > MarlinCast.CHECK_ABOVE, "Hugo outbids Mrs Lindqvist, no bank asked")
	await _ended(t, job, "proxy", "the proxy")
	JobHarness.done(job)
	await t.frames(2)
	# Mae, ringing as the client, warms Hugo up first.
	job = _start(t, MarlinAuctionJob.new(), ["agent"])
	await t.frames(2)
	await _mae(t, job, "client", "client_rang")
	t.check(await t.until(func(): return job.cast.hugo.suspicion_of(1) <= 1, 6.0), "a client's call warms Hugo to their agent")
	JobHarness.done(job)
	await t.frames(2)


func test_auction_goes_wrong(t) -> void:
	var job := _start(t, MarlinAuctionJob.new(), ["bidder", "stew"])
	await t.frames(2)
	t.check(job.use(2, "rostrum").contains("registered"), "no paddle, no bid")
	await _ring(t, job, 2, "registrar", "Withheld", "nina")
	await _on_phone(t, job, 2, "nina", "Good evening, Caldera Mutual. I'm calling to confirm our client's letter of guarantee.")
	await _on_phone(t, job, 2, "nina", "Our client is bidding tonight, to three million.")
	t.check(not job.flags.has("bank_ok"), "a 'bank' on a withheld number doesn't count")
	job.hang_up(2)
	await _register(t, job)
	var m := float(MarlinAuctionJob.SALE)
	var refused := false
	while not job.flags.has("sold") and m < MarlinAuctionJob.LAST - 2:
		if str(job.flags.get("high", "")) != "crew:1" and not refused:
			refused = job.use(1, "rostrum").contains("bank")
		m += MarlinAuctionJob.ROUND
		await JobHarness.clock_to(t, job, m)
	t.check(refused and job.cast.rupert.suspicion_of(1) >= 2, "past two million with no bank, Mr Ashcombe won't take the bid")
	t.check(job.flags.high == "margit", "Mrs Lindqvist has her")
	await _ended(t, job, "sold", "no bank and no rumor")
	JobHarness.done(job)
	await t.frames(2)
	# Registration closes at eight, and Lockdown stops the sale.
	job = _start(t, MarlinAuctionJob.new(), ["bidder"])
	await t.frames(2)
	await JobHarness.clock_to(t, job, MarlinAuctionJob.SALE + 1.0)
	await _talk(t, job, 1, "nina", "Good evening. I'd like to register to bid.")
	job.show_papers(1, job.cast.nina)
	await t.until(func(): return not job.cast.nina.busy, 4.0)
	t.check(JobHarness.last_do(job, "nina") == "register" and job.holder("paddle_1") == null, "registration closed at eight")
	var price := int(job.flags.get("price", 0))
	job.heat.bump(30.0)
	await t.frames(2)
	await JobHarness.clock_to(t, job, MarlinAuctionJob.SALE + 4.0)
	t.check(job.heat.level == Heat.LOCKDOWN and int(job.flags.get("price", 0)) == price, "at Lockdown the bidding stops")
	await JobHarness.clock_to(t, job, MarlinAuctionJob.LAST + 0.1)
	await _ended(t, job, "unsold", "Lockdown")
	JobHarness.done(job)
	await t.frames(2)


func test_auction_money(t) -> void:
	t.check(MarlinAuctionJob.money(1200000) == "one million two hundred thousand", "one million two hundred thousand")
	t.check(MarlinAuctionJob.money(2000000) == "two million", "two million")
	t.check(MarlinAuctionJob.money(2450000) == "two million four hundred fifty thousand", "the odd sum")
	t.check(MarlinAuctionJob.dollars(2500000) == "$2,500,000" and MarlinAuctionJob.dollars(900) == "$900", "dollars, with commas")

#endregion
