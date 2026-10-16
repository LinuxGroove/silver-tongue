extends RefCounted
## Mae's house (game/venues/mae/): the building through the checks every
## venue passes ([VenueChecks]), and the house party played every way
## through, alone and with two, by [JobHarness].
##   godot --headless --path . tests/run_tests.tscn -- --only=mae

const DOORS: Array[String] = ["front", "back_room", "yard", "gate", "study", "safe", "terrace"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"crew_0": "street", "crew_1": "street", "gray_car": "street", "rocco_car": "street", "mae_street": "street",
	"gone": "street", "walt": "laundrette", "front_guard": "laundrette", "held": "back_room", "held_guard": "back_hall",
	"dot": "kitchen", "benny": "kitchen", "okafor": "kitchen", "mae": "living", "julian": "living", "rocco": "living",
	"dana": "living", "celeste": "living", "hugo": "living", "jojo": "living", "mae_dance": "living",
	"mae_desk": "study", "julian_study": "study", "rocco_study": "study", "safe_in": "study",
	"silas": "terrace", "nadia": "terrace", "mae_toast": "terrace", "julian_toast": "terrace", "rocco_toast": "terrace",
	"dot_toast": "terrace", "celeste_toast": "terrace", "hugo_toast": "terrace", "mae_fw": "terrace", "julian_fw": "terrace",
}


func _house(t: Node, open_doors := false) -> MaeHouse:
	return await VenueChecks.built(t, MaeHouse.new(), open_doors)


func test_builds(t) -> void:
	var h: MaeHouse = await _house(t)
	for d in DOORS:
		t.check(h.doors.get(d) is HotelDoor, "mae: the %s door" % d)
	t.check(h.doors.size() == DOORS.size(), "mae: no doors but the seven (%d)" % h.doors.size())
	VenueChecks.structure(t, h, "mae", SPOT_ZONES)
	for id in ["dial", "drawer", "safe_shelf", "case", "desk"]:
		t.check(h.uses.has(id), "mae: %s can be used" % id)
	var dial: Vector3 = h.uses.dial.global_position
	t.check(h.zone_at(dial) == "study" and dial.distance_to(h.doors.safe.centre()) < 2.0, "mae: the dial is beside the strongroom door, in the study")
	t.check(h.zone_at(h.uses.case.global_position + Vector3(0, 0.1, 0)) == "terrace", "mae: the buyer's case goes on the terrace")
	t.check(h.zone_at(h.uses.drawer.global_position + Vector3(0, 0.1, 0)) == "back_room", "mae: the drawer is in the back room")
	t.check(h.find_child("GrayCase", true, false) != null and h.find_child("Fireworks", true, false) != null, "mae: the case and the fireworks are there to show")
	t.check(h.extras.get("living", []).size() >= 5, "mae: a party in the living room")
	h.queue_free()


func test_spots(t) -> void:
	var h: MaeHouse = await _house(t)
	VenueChecks.standing_room(t, h, "mae")
	h.queue_free()


func test_links_clear(t) -> void:
	var h: MaeHouse = await _house(t, true)
	VenueChecks.walkable(t, h, "mae")
	h.queue_free()


func test_doors_block(t) -> void:
	var h: MaeHouse = await _house(t)
	await VenueChecks.doors_block(t, h, "mae")
	h.queue_free()


# --- The house party ---------------------------------------------------------------------------


func test_job_data(t) -> void:
	VenueChecks.job_data(t, MaeHousePartyJob.new())
	await VenueChecks.routines(t, MaeHousePartyJob.new())
	var def := MaeHousePartyJob.new()
	t.check(def.mae_calls.is_empty(), "party: no calls from Mae tonight")
	t.check(def.briefer == "Benny" and def.briefer_voice == MeridianCast.benny().voice, "party: Benny gives the briefing, in his own voice")
	t.check(not def.briefing.contains("—") and not def.goal.contains("—"), "party: no dashes in the spoken briefing")
	var voices := {}
	for s in def.sheets():
		t.check(not voices.has(s.voice), "party: %s has a voice of their own (%s)" % [s.id, s.voice])
		voices[s.voice] = s.id
		for r in s.replies:
			t.check(not str(r.get("say", "")).contains("—"), "party: %s speaks without dashes" % s.id)
	t.check(def.sheet("mae").voice == GameConfig.MAE_VOICE, "party: Mae sounds like Mae")
	t.check(def.sheets().size() >= 10 and def.sheets().size() <= 15, "party: a cast of ten to fifteen")
	# Every way's moment is an event, so nobody's round can drift away from it.
	var names: Array = def.events.map(func(e): return str(e[1]))
	for e in ["viewing", "rose_out", "deal", "toast", "fireworks", "fireworks_end", "leaving", "drive_off"]:
		t.check(e in names, "party: %s is one of the night's events" % e)
	var v: MaeHouse = MaeHouse.new()
	v.build()
	for spot in MaeHousePartyJob.TOAST_SPOTS.values() + MaeHousePartyJob.FIREWORK_SPOTS.values() + MaeHousePartyJob.FETCH.values():
		t.check(v.spots.has(spot), "party: %s is a spot" % spot)
	for p in MaeHousePartyJob.PLACES:
		for it in ["rose", "copy"]:
			var at := str(MaeHousePartyJob.PLACES[p][it])
			t.check(v.uses.has(at) and str(v.uses[at].get_meta("use", "")) == "item:" + it, "party: the %s can lie at %s" % [it, at])
	v.free()


func test_scripted_replies(t) -> void:
	var def := MaeHousePartyJob.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var dot := def.sheet("dot")
	var f := JobRules.new_face(dot)
	t.check(_reply(dot, f, "That stew smells amazing.", rng).suspicion == 0, "Dot warms to praise for her stew")
	t.check(not _reply(dot, f, "Mae sold the Rose behind our backs.", rng).believes.is_empty(), "Dot hears that Mae sold the Rose")
	f.secrets = [0]
	t.check(str(_reply(dot, f, "What's the combination to the strongroom?", rng).say).contains(MaeCast.COMBINATION), "warm, Dot gives up the dial")
	var silas := def.sheet("silas")
	f = JobRules.new_face(silas)
	var r := _reply(silas, f, "Mae's cut you out of the sale, Silas.", rng)
	t.check(r.suspicion == 0 and not r.believes.is_empty(), "Silas is sore to hear he's been cut out")
	f.secrets = [0]
	t.check(str(_reply(silas, f, "Where's the second copy?", rng).say).contains("tea tin"), "warm, Silas says where the second copy is")
	var gray := def.sheet("julian")
	t.check(_reply(gray, JobRules.new_face(gray), "That stone is paste.", rng).do == "ask_silas", "told it's paste, Gray asks Silas")
	t.check(_reply(gray, JobRules.new_face(gray), "Remember Antwerp?", rng).suspicion == 1, "Antwerp gets Gray listening")
	var rocco := def.sheet("rocco")
	f = JobRules.new_face(rocco)
	t.check(_reply(rocco, f, "You're Halberd, aren't you?", rng).suspicion == 1, "Rocco goes quiet about Halberd")
	f.turns = 3
	t.check(_reply(rocco, f, "Let us go, it was a mistake.", rng, {"someone_held": true, "minding": true}).do == "release", "minding the back room, Rocco can let the crew go")
	t.check(_reply(rocco, JobRules.new_face(rocco), "Can I see the case?", rng).suspicion == 3, "Rocco doesn't like anyone near the case")
	var mae := def.sheet("mae")
	t.check(_reply(mae, JobRules.new_face(mae), "Martha Shaw, Caldera Assay Office.", rng).suspicion == 3, "Mae hears a cover story coming")
	f = JobRules.new_face(mae)
	f.turns = 3
	t.check(_reply(mae, f, "Give the Rose back, Mae.", rng).do == "give_back", "asked, Mae can give the Rose back")
	t.check(not _reply(mae, JobRules.new_face(mae), "We know you sold it, Mae.", rng).believes.is_empty(), "Mae hears that the crew knows")
	f.secrets = [0]
	t.check(str(_reply(mae, f, "Is it the laundrette?", rng).say).contains("Halvorsens"), "warm, Mae says why she sold it")
	t.check(_reply(def.sheet("jojo"), JobRules.new_face(def.sheet("jojo")), "Play Caldera Moon for Mae!", rng).do == "play_song", "Jojo plays Mae's song")
	for k in [["benny", "Who knows the combination?", "Dot"], ["benny", "Who made the copy?", "Silas"], ["benny", "Who's Gray?", "Antwerp"],
			["dana", "Who's the bodyguard?", "Halberd"], ["celeste", "Do you know Julian Gray?", "Antwerp"],
			["okafor", "What's wrong with the street?", "Halvorsens"], ["nadia", "What's up with Silas?", "furious"],
			["walt", "How do I get out through the yard?", "gate"], ["hugo", "When's Gray leaving?", "fireworks"]]:
		var s := def.sheet(k[0])
		t.check(str(_reply(s, JobRules.new_face(s), k[1], rng).say).contains(k[2]), "%s's reply to \"%s\" helps" % [k[0], k[1]])
	# Mae's name doesn't raise an eyebrow at her own party; it still does at the gala.
	t.check(not ScriptedBrain._hot(" mae's made her stew ", mae) and ScriptedBrain._hot(" mae's made her stew ", MeridianCast.sheet("teo")),
		"at Mae's own party, her name isn't a giveaway")


func _reply(s: CharacterSheet, f: Dictionary, line: String, rng: RandomNumberGenerator, ctx := {}) -> Dictionary:
	var r := ScriptedBrain.reply(s, f, {"kind": "line", "heard": line}, rng)
	var out := JobRules.resolve(r, f, s, ctx, rng)
	JobRules.apply(out, f)
	return out


## A party with scripted brains, and what it ends with.
func _party(t, covers: Array) -> Array:
	var job := JobHarness.start(t, MaeHousePartyJob.new(), covers)
	var ended := []
	job.ended.connect(func(r): ended.append(r))
	await t.frames(2)
	return [job, ended]


## Says lines to a character, waiting for each answer (a scripted brain
## may answer before the line's even done).
func _talk(t, job: Job, id: int, char_id: String, lines: Array) -> bool:
	var ok := true
	var ch: Character = job.cast[char_id]
	for l in lines:
		var want := ch.turns.size() + 1
		JobHarness.say(job, id, l)
		ok = await t.until(func() -> bool: return ch.turns.size() >= want and not ch.busy, 6.0) and ok
	return ok


func _last_said(job: Job, char_id: String) -> String:
	var ch: Character = job.cast[char_id]
	return str(ch.turns.back().get("reply", {}).get("say", "")) if not ch.turns.is_empty() else ""


## Stands a crew member at one of the venue's points, looking at another.
func _at(job: Job, id: int, point: String, look_at: String) -> void:
	JobHarness.stand(job, id, job.venue.points[point], job.venue.points[look_at])


## Everyone who's walking gets there.
func _settle(job: Job) -> void:
	for ch in job.cast.values():
		if ch.walking:
			JobHarness.walk(job, ch, str(ch.post))


func _clock(t, job: Job, minute: int) -> void:
	await JobHarness.clock_to(t, job, minute)
	_settle(job)
	await t.frames(2)


func _ended_as(t, ended: Array, outcome: String) -> bool:
	await t.until(func(): return not ended.is_empty(), 3.0)
	return not ended.is_empty() and str(ended[0].outcome) == outcome


## Way 1: Dot gives up the dial, and the Rose walks out of the strongroom.
func test_way_combination(t) -> void:
	for covers in [["help"], ["help", "crew"]]:
		var p: Array = await _party(t, covers)
		var job: Job = p[0]
		JobHarness.face(job, 1, "dot")
		t.check(await _talk(t, job, 1, "dot", ["Dot, that stew smells amazing.", "Mae sold the Rose behind our backs, Dot.",
			"Do you know the combination to the strongroom?"]), "dial (%d): Dot answers" % covers.size())
		t.check(_last_said(job, "dot").contains(MaeCast.COMBINATION), "dial (%d): Dot gives up the combination" % covers.size())
		_at(job, 1, "safe_out", "safe_in")
		t.check(job.keypad(1, "1234", "dial") == "Wrong code.", "dial: a wrong number doesn't open it")
		t.check(job.keypad(1, MaeCast.COMBINATION, "dial") == "The lock clicks." and job.venue.doors.safe.is_open, "dial (%d): the strongroom opens" % covers.size())
		_at(job, 1, "safe_in", "safe_out")
		t.check(job.use(1, "item:rose") == "You take the Rose.", "dial (%d): the Rose comes off the shelf" % covers.size())
		t.check(not job.done, "dial: inside the house it isn't over")
		JobHarness.stand_at(job, 1, "crew_0")
		t.check(await _ended_as(t, p[1], "back"), "dial (%d): out of the house with the Rose, it's back" % covers.size())
		t.check(p[1][0].win and p[1][0].take == 25000 and p[1][0].ending.mae == "ruined", "dial: the take, and Mae left to face Gray")
		JobHarness.done(job)
		await t.frames(2)


## Way 2: Silas is sore, so when Gray asks him, he backs the story that Mae's stone is paste.
func test_way_paste(t) -> void:
	for covers in [["appraiser"], ["appraiser", "crew"]]:
		var p: Array = await _party(t, covers)
		var job: Job = p[0]
		var by: int = covers.size()
		# Alone, Silas is rung; with two, the second has a word with him on the terrace.
		if by == 1:
			t.check(job.ring(1, "silas", "Withheld") == "", "paste: Silas picks up")
			await t.until(func() -> bool: return not job.cast.silas.turns.is_empty() and not job.cast.silas.busy, 3.0)
			t.check(await _talk(t, job, 1, "silas", ["Mae's cut you out of the sale, Silas. Gray's paying her four hundred thousand."]), "paste: Silas hears it")
			job.hang_up(1)
		else:
			JobHarness.face(job, 2, "silas")
			t.check(await _talk(t, job, 2, "silas", ["Mae's cut you out of the sale, Silas."]), "paste (2): Silas hears it")
		t.check((job.def as MaeHousePartyJob).silas_sore(job), "paste (%d): Silas is sore" % by)
		JobHarness.face(job, 1, "julian")
		t.check(await _talk(t, job, 1, "julian", ["Martin Shaw, Caldera Assay Office. I look at stones for a living.",
			"The stone Mae's selling you is paste. Silas made it."]), "paste (%d): Gray listens" % by)
		t.check(JobHarness.last_do(job, "julian") == "ask_silas", "paste (%d): Gray rings Silas" % by)
		t.check(await t.until(func(): return job.flags.has("no_sale"), 12.0), "paste (%d): Silas backs it, and Gray calls off the sale" % by)
		JobHarness.walk(job, job.cast.mae, "mae_desk")
		await t.until(func(): return str(job.items.rose.at) == "desk", 2.0)
		t.check(str(job.items.rose.at) == "desk", "paste (%d): Mae takes the Rose out to look at it" % by)
		job.flags["look_t"] = MaeHousePartyJob.MAE_LOOKS
		await t.until(func(): return str(job.flags.get("mae_check", "")) == "street", 2.0)
		JobHarness.walk(job, job.cast.mae, "mae_street")
		JobHarness.walk(job, job.cast.julian, "gray_car")
		job.flags["gray_wait"] = MaeHousePartyJob.GRAY_WAITS
		await t.until(func(): return job.flags.has("gray_gone"), 2.0)
		t.check(job.flags.has("gray_gone"), "paste (%d): Gray drives off without it" % by)
		_at(job, 1, "julian_study", "mae_desk")
		t.check(job.use(1, "item:rose") == "You take the Rose.", "paste (%d): the Rose is there on the desk" % by)
		JobHarness.stand_at(job, 1, "crew_0")
		t.check(await _ended_as(t, p[1], "ruined"), "paste (%d): out with it, and Mae's name is mud" % by)
		JobHarness.done(job)
		await t.frames(2)


## Way 3: Silas's second copy, swapped into Gray's case while everyone watches the fireworks.
func test_way_swap(t) -> void:
	for covers in [["crew"], ["crew", "help"]]:
		var p: Array = await _party(t, covers)
		var job: Job = p[0]
		var by: int = covers.size()
		var hand := by
		JobHarness.face(job, 1, "silas")
		t.check(await _talk(t, job, 1, "silas", ["Silas, Mae's cutting you out of the sale.", "Did you make Mae a copy of the Rose?",
			"Where's the second copy?"]), "swap (%d): Silas talks" % by)
		t.check(_last_said(job, "silas").contains("tea tin"), "swap (%d): Silas says where the second copy is" % by)
		_at(job, hand, "back_room_in", "held")
		t.check(job.use(hand, "item:copy") == "You take Silas's copy of the Rose.", "swap (%d): the copy's in the back room drawer" % by)
		await _clock(t, job, MaeHousePartyJob.VIEWING)
		t.check(str(job.cast.mae.post) == "mae_desk" and str(job.cast.julian.post) == "julian_study", "swap: Mae shows Gray into her study")
		await _clock(t, job, MaeHousePartyJob.ROSE_OUT)
		t.check(str(job.items.rose.at) == "desk", "swap: the Rose comes out onto Mae's desk")
		await _clock(t, job, MaeHousePartyJob.DEAL)
		t.check(str(job.items.rose.at) == "case", "swap: it goes into Gray's case, on the terrace")
		await _clock(t, job, MaeHousePartyJob.TOAST)
		_at(job, hand, "terrace_e", "terrace_out")
		t.check(job.use(hand, "item:rose").begins_with("Not with"), "swap (%d): not under Rocco's nose" % by)
		await _clock(t, job, MaeHousePartyJob.FIREWORKS)
		t.check(job.flags.has("fireworks") and str(job.cast.rocco.post) == "rocco_fw", "swap: everyone turns to the fireworks")
		t.check(job.use(hand, "item:rose") == "You swap the Rose for Silas's copy. Nobody saw.", "swap (%d): the swap, while they look up" % by)
		t.check(str(job.items.copy.at) == "copy_case" and job.holder("rose") != null, "swap (%d): the copy's in the case, the Rose in a pocket" % by)
		await _clock(t, job, MaeHousePartyJob.FIREWORKS_END)
		await _clock(t, job, MaeHousePartyJob.LEAVING)
		t.check(str(job.flags.get("gray_has", "")) == "copy", "swap (%d): Gray leaves with the copy" % by)
		await _clock(t, job, MaeHousePartyJob.DRIVE_OFF)
		t.check(await _ended_as(t, p[1], "swapped"), "swap (%d): Gray drives off with paste" % by)
		JobHarness.done(job)
		await t.frames(2)


## Way 4: tell Mae you know, and offer to help her keep the laundrette.
func test_way_mae(t) -> void:
	for covers in [["crew"], ["crew", "crew"]]:
		var p: Array = await _party(t, covers)
		var job: Job = p[0]
		var by: int = covers.size()
		JobHarness.face(job, 1, "mae")
		t.check(await _talk(t, job, 1, "mae", ["Mae, we know you sold the Rose to Julian Gray. Benny told us."]), "Mae (%d): she hears it" % by)
		if by == 2:
			JobHarness.face(job, 2, "mae", 1.0)
			t.check(await _talk(t, job, 2, "mae", ["Is it the laundrette, Mae? We'll help you keep it."]), "Mae (2): she hears the offer")
			_at(job, 2, "living_e", "living_c")
			JobHarness.face(job, 1, "mae")
		else:
			t.check(await _talk(t, job, 1, "mae", ["Is it the laundrette, Mae? We'll help you keep it."]), "Mae: she hears the offer")
		t.check(await _talk(t, job, 1, "mae", ["Give the Rose back, Mae."]), "Mae (%d): asked" % by)
		t.check(job.flags.has("giving") and str(job.cast.mae.post) == "safe_in", "Mae (%d): she goes to fetch it" % by)
		JobHarness.walk(job, job.cast.mae, "safe_in")
		t.check(await _ended_as(t, p[1], "forgiven"), "Mae (%d): she puts it in your hand" % by)
		var r: Dictionary = p[1][0] if not p[1].is_empty() else {}
		t.check(r.get("win", false) and r.ending.rose == "crew" and r.ending.mae == "forgiven" and str(r.epilogue) != "" and str(r.mae_says) != "", "Mae: the report reads like an ending")
		JobHarness.done(job)
		await t.frames(2)


## Mae won't give it back to someone who only asks, and a sore Mae needs
## an apology first; Jojo's record softens her.
func test_mae_moods(t) -> void:
	var def := MaeHousePartyJob.new()
	t.check(def.season_mood() == "fond", "a fresh season: Mae's fond of the crew")
	Progress.burned = true
	t.check(def.season_mood() == "sore", "a face burned this season: Mae's sore")
	Progress.burned = false
	for j in ["meridian_gala", "meridian_list", "meridian_case", "marlin_aboard", "marlin_safe", "marlin_auction"]:
		Progress.done[j] = {"outcome": "in", "clean": true}
	t.check(def.season_mood() == "proud", "a clean season: Mae's proud")
	Progress.reset()
	var p: Array = await _party(t, ["crew"])
	var job: Job = p[0]
	JobHarness.face(job, 1, "mae")
	await _talk(t, job, 1, "mae", ["Hello Mae, lovely party.", "Give the Rose back, Mae."])
	t.check(not job.flags.has("giving") and _last_said(job, "mae") == "You want it back.", "only asked, Mae won't")
	await t.until(func(): return JobHarness.quiet(job), 2.0)
	t.check(not job.flags.has("giving"), "it's sold, as far as she's concerned")
	JobHarness.face(job, 1, "jojo")
	await _talk(t, job, 1, "jojo", ["Play Caldera Moon for Mae!"])
	t.check(job.flags.has("song") and str(job.cast.mae.post) == "mae_dance", "Jojo plays her song, and Mae dances")
	t.check(job.cast.mae.suspicion_of(1) == 0, "Mae's song softens her")
	JobHarness.done(job)
	await t.frames(2)
	Progress.burned = true
	p = await _party(t, ["crew"])
	job = p[0]
	t.check(job.cast.mae.sheet.start_suspicion == 2 and str(job.flags.mood) == "sore", "a sore Mae starts warier")
	JobHarness.face(job, 1, "mae")
	await _talk(t, job, 1, "mae", ["We know you sold the Rose, Mae.", "We'll help you keep the laundrette.", "Give the Rose back, Mae."])
	t.check(not job.flags.has("giving"), "sore, she won't hear it yet")
	await _talk(t, job, 1, "mae", ["We're sorry, Mae.", "Give the Rose back, Mae."])
	t.check(job.flags.has("giving"), "after sorry, she will")
	Progress.reset()
	JobHarness.done(job)
	await t.frames(2)


## The ways it goes wrong: a lie to Mae, a story Silas won't back, Rocco and
## the back room, Lockdown, the Rose found missing, and Gray driving off with it.
func test_failures(t) -> void:
	var p: Array = await _party(t, ["appraiser"])
	var job: Job = p[0]
	JobHarness.face(job, 1, "mae")
	await _talk(t, job, 1, "mae", ["Martin Shaw, Caldera Assay Office."])
	t.check(job.cast.mae.suspicion_of(1) == 3 and _last_said(job, "mae").contains("taught you"), "a cover story on Mae costs you")
	JobHarness.face(job, 1, "julian")
	await _talk(t, job, 1, "julian", ["The stone Mae's selling you is paste."])
	t.check(JobHarness.last_do(job, "julian") == "ask_silas", "Gray rings Silas")
	await t.until(func(): return job.cast.julian.face_of(1).checks.get("ask_silas", "") in ["good", "bad"], 10.0)
	await t.until(func(): return JobHarness.quiet(job), 3.0)
	t.check(job.cast.julian.face_of(1).checks.get("ask_silas", "") == "bad" and not job.flags.has("no_sale"), "Silas, not sore, says it's the real thing")
	JobHarness.done(job)
	await t.frames(2)
	# Rocco, the back room, and talking him round.
	p = await _party(t, ["crew"])
	job = p[0]
	JobHarness.face(job, 1, "rocco")
	await _talk(t, job, 1, "rocco", ["Let me see the case.", "Show me the Rose.", "Open the case."])
	var c := job.crew_by_id(1)
	await t.until(func(): return c.held, 2.0)
	t.check(c.held and job.cast.rocco.minding, "Rocco takes you down to Mae's back room")
	t.check(job.venue.doors.back_room.locked, "the back room's locked")
	t.check(job.use(1, "item:copy") == "", "held, you can't get at the drawer")
	JobHarness.walk(job, job.cast.rocco, "held_guard")
	JobHarness.stand_at(job, 1, "held")
	JobHarness.face(job, 1, "rocco")
	await _talk(t, job, 1, "rocco", ["You're Halberd, aren't you? Moonlighting on your night off.", "Dana at the Meridian knows you.",
		"Halberd would fire you for this, Rocco.", "Let us go. It was a mistake."])
	t.check(not c.held, "talked round, Rocco lets you go")
	JobHarness.done(job)
	await t.frames(2)
	# Held for good: Gray's people come.
	p = await _party(t, ["crew"])
	job = p[0]
	JobHarness.face(job, 1, "rocco")
	await _talk(t, job, 1, "rocco", ["Let me see the case.", "Show me the Rose.", "Open the case."])
	await t.until(func(): return job.crew_by_id(1).held, 2.0)
	await JobHarness.clock_to(t, job, job.minutes + Job.POLICE + 0.5)
	t.check(await _ended_as(t, p[1], "held") and not p[1][0].win and str(p[1][0].title) == "IN THE BACK ROOM", "the whole crew held: it's over")
	JobHarness.done(job)
	await t.frames(2)
	# Lockdown.
	p = await _party(t, ["crew"])
	job = p[0]
	job.heat.bump(30.0)
	await t.until(func(): return job.heat.level >= Heat.LOCKDOWN, 2.0)
	await t.frames(2)
	t.check(job.venue.doors.front.locked and job.venue.doors.gate.locked, "Lockdown: Rocco locks the doors out")
	t.check(job.use(1, "door:front") == "Locked. Rocco has the key.", "Lockdown: the front door won't open")
	JobHarness.done(job)
	await t.frames(2)
	# The Rose found missing, and Gray leaving with it.
	p = await _party(t, ["crew"])
	job = p[0]
	_at(job, 1, "safe_out", "safe_in")
	job.keypad(1, MaeCast.COMBINATION, "dial")
	_at(job, 1, "safe_in", "safe_out")
	job.use(1, "item:rose")
	_at(job, 1, "living_c", "living_e")
	await _clock(t, job, MaeHousePartyJob.VIEWING)
	await _clock(t, job, MaeHousePartyJob.ROSE_OUT)
	t.check(job.flags.has("alarm") and job.cast.mae.suspicion_of(1) >= 3 and str(job.cast.rocco.post) == "front_guard", "the strongroom's found empty: Mae knows, and Rocco watches the door")
	await JobHarness.clock_to(t, job, job.def.end)
	t.check(await _ended_as(t, p[1], "back"), "still holding it at the end of the party, it's back")
	JobHarness.done(job)
	await t.frames(2)
	p = await _party(t, ["crew"])
	job = p[0]
	for m in [MaeHousePartyJob.VIEWING, MaeHousePartyJob.ROSE_OUT, MaeHousePartyJob.DEAL, MaeHousePartyJob.TOAST, MaeHousePartyJob.FIREWORKS,
			MaeHousePartyJob.FIREWORKS_END, MaeHousePartyJob.LEAVING]:
		await _clock(t, job, m)
	t.check(str(job.flags.get("gray_has", "")) == "rose" and str(job.cast.julian.post) == "gray_car", "Gray goes out to his car with the Rose")
	await _clock(t, job, MaeHousePartyJob.DRIVE_OFF)
	t.check(await _ended_as(t, p[1], "gone") and not p[1][0].win and p[1][0].ending.rose == "buyer", "Gray drives off with it: gone")
	JobHarness.done(job)
	await t.frames(2)
