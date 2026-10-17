extends RefCounted
## Vantage Tower (game/venues/vantage/): the building through the checks
## every venue passes ([VenueChecks]) on each of its three nights, and its
## own (the lifts, the gates, the scanner), then each job's data, routines
## and every way through, alone with Mae's calls and with two crew.
##   godot --headless --path . tests/run_tests.tscn -- --only=vantage

const NIGHTS := ["lift", "board", "research"]
## Every spot the cast uses, and the zone it's in.
const SPOT_ZONES := {
	"dana": "lobby", "teo": "lobby", "lupe": "lobby", "philippa": "lobby", "stan": "plant", "renata": "office",
	"held": "office", "office_guard": "lobby", "plaza": "outside",
	"arrive_g": "lift_lobby", "lift_wait_g": "lift_lobby", "arrive_r": "r_lobby", "lift_wait_r": "r_lobby",
	"arrive_b": "b_lobby", "lift_wait_b": "b_lobby",
	"joost_break": "break_room", "wes_break": "break_room", "odile": "break_room",
	"bram": "checkpoint", "check_desk": "checkpoint", "odile_check": "checkpoint", "renata_r": "checkpoint",
	"wes": "lab", "margot_lab": "lab", "odile_lab": "lab", "margot": "lab_office", "lo_c": "lab_office",
	"joost_cut": "cutting", "rose": "cutting",
	"noor": "assist", "renata_b": "assist", "philippa_b": "assist", "mirela": "pantry", "service_ear": "pantry",
	"mirela_serve": "boardroom", "ezra": "boardroom", "ezra_office": "founder",
	"seat_n1": "boardroom", "seat_n2": "boardroom", "seat_n3": "boardroom", "seat_n4": "boardroom",
	"seat_s1": "boardroom", "seat_s2": "boardroom", "seat_s3": "boardroom", "seat_s4": "boardroom",
	"margot_board": "boardroom", "joost_board": "boardroom",
}
const CREW_ZONE := {"lift": "lobby", "board": "b_lobby", "research": "r_lobby"}
const DOORS := ["front", "gates", "plant", "office", "break", "lab_office", "pantry", "service", "boardroom", "founder",
	"lift_g", "lift_r", "lift_b", "secure", "cutting"]


func _zones(night: String) -> Dictionary:
	var z := SPOT_ZONES.duplicate()
	z["crew_0"] = CREW_ZONE[night]
	z["crew_1"] = CREW_ZONE[night]
	return z


#region The building

func test_builds(t) -> void:
	for night in NIGHTS:
		var v: VantageTower = await VenueChecks.built(t, VantageTower.new(night))
		var label := "vantage(%s)" % night
		VenueChecks.structure(t, v, label, _zones(night))
		for d in DOORS:
			t.check(v.doors.get(d) is HotelDoor, "%s: the %s door" % [label, d])
		t.check(v.doors.size() == DOORS.size(), "%s: no doors but the %d (%d)" % [label, DOORS.size(), v.doors.size()])
		for fl in ["g", "r", "b"]:
			var u: StaticBody3D = v.uses.get("lift_call_" + fl)
			t.check(u != null and u.get_meta("use", "") == "lift_call_" + fl, "%s: the lift's call button on floor %s" % [label, fl])
			if u:
				t.check(VantageTower.floor_of(u.global_position) == fl and u.global_position.distance_to(v.doors["lift_" + fl].centre()) < 2.5, "%s: the %s button is by its lift door" % [label, fl])
		var pad: StaticBody3D = v.uses.get("cutting_pad")
		t.check(pad != null and v.zone_at(pad.global_position) == "lab" and pad.global_position.distance_to(v.doors.cutting.centre()) < 2.0, "%s: the gem room's keypad is beside its door, lab side" % label)
		var cradle: StaticBody3D = v.uses.get("cradle")
		t.check(cradle != null and v.zone_at(cradle.global_position) == "cutting" and cradle.get_meta("use", "") == "item:rose", "%s: the Rose lies in her cradle in the gem room" % label)
		t.check(v.zone_at(v.doors.secure.centre() + Vector3(0, 1, 1.0)) == "lab" and v.zone_at(v.doors.secure.centre() + Vector3(0, 1, -1.0)) == "checkpoint", "%s: the secure door goes from the checkpoint into the lab" % label)
		t.check(v.zones.has("outside") and v.zone_at(Vector3(0, 1, 6)) == "outside", "%s: the plaza is outside" % label)
		t.check(VantageTower.floor_of(v.spots.noor.origin) == "b" and VantageTower.floor_of(v.spots.bram.origin) == "r" and VantageTower.floor_of(v.spots.dana.origin) == "g", "%s: floors tell apart" % label)
		v.queue_free()
		await t.frames(1)
	var lift: VantageTower = await VenueChecks.built(t, VantageTower.new("lift"))
	t.check(lift.extras.get("lobby", []).size() >= 6, "the lift night: people leaving work in the lobby")
	lift.queue_free()
	var board: VantageTower = await VenueChecks.built(t, VantageTower.new("board"))
	t.check(board.extras.get("boardroom", []).size() >= 5, "the board night: the board round the table")
	board.queue_free()
	await t.frames(1)


func test_spots(t) -> void:
	for night in NIGHTS:
		var v: VantageTower = await VenueChecks.built(t, VantageTower.new(night))
		VenueChecks.standing_room(t, v, "vantage(%s)" % night)
		v.queue_free()
		await t.frames(1)


func test_links_clear(t) -> void:
	for night in NIGHTS:
		var v: VantageTower = await VenueChecks.built(t, VantageTower.new(night), true)
		VenueChecks.walkable(t, v, "vantage(%s)" % night)
		v.queue_free()
		await t.frames(1)


func test_doors_block(t) -> void:
	var v: VantageTower = await VenueChecks.built(t, VantageTower.new("lift"))
	await VenueChecks.doors_block(t, v, "vantage")
	# The lift's doors slide apart rather than swing.
	var d: HotelDoor = v.doors.lift_g
	var before: Array = []
	for leaf in d.leaves:
		before.append([leaf.position, leaf.rotation.y])
	d.open(Vector3(3.5, 0, -24))
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	var slid := true
	for i in d.leaves.size():
		var p: Vector3 = d.leaves[i].position
		var was: Vector3 = before[i][0]
		slid = slid and absf(p.z - was.z) < 0.01 and absf(p.x - was.x) > 0.4 and absf(d.leaves[i].rotation.y - float(before[i][1])) < 0.01
	t.check(slid, "the lift's doors slide apart")
	v.queue_free()
	await t.frames(1)

#endregion


#region The jobs' data

func test_job_data(t) -> void:
	for def in [VantageLiftJob.new(), VantageBoardJob.new(), VantageResearchJob.new()]:
		VenueChecks.job_data(t, def)
		t.check(def.memory_from.has("meridian"), "%s: Dana and Teo remember the Meridian" % def.id)
		t.check(def.covers.size() == 3 and def.mae_calls.size() == 3, "%s: three covers, and three calls for Mae" % def.id)


func test_routines(t) -> void:
	await VenueChecks.routines(t, VantageLiftJob.new())
	await VenueChecks.routines(t, VantageBoardJob.new())
	await VenueChecks.routines(t, VantageResearchJob.new())


func test_cast(t) -> void:
	var voices := {}
	for id in VantageCast.EVERYONE:
		var s := VantageCast.sheet(id, "research" if id in ["bram", "odile", "joost", "wes"] else "lift")
		t.check(s != null and s.id == id, "cast: %s has a sheet" % id)
		if s == null:
			continue
		t.check(not voices.has(s.voice), "cast: %s has a voice of their own (%s)" % [id, s.voice])
		voices[s.voice] = id
		t.check(s.voice != GameConfig.MAE_VOICE, "cast: %s isn't Mae" % id)
		for k in ["manner", "job", "post"]:
			t.check(str(s.get(k)) != "", "cast: %s has a %s" % [id, k])
		for k in ["routine", "knows", "never", "checks", "weaknesses"]:
			t.check(not (s.get(k) as Array).is_empty(), "cast: %s has %s" % [id, k])
		for night in VantageCast.IDS:
			var n := VantageCast.sheet(id, night)
			for line in n.replies:
				t.check(not str(line.get("say", "")).contains("—"), "cast: %s's lines have no dashes" % id)
	t.check(VantageCast.EVERYONE.size() >= 10 and VantageCast.EVERYONE.size() <= 15, "cast: ten to fifteen people")
	var dana := VantageCast.dana()
	t.check(dana.id == "dana" and dana.voice == MeridianCast.dana().voice and dana.post.contains("Vantage"), "Dana is the Meridian's Dana, on Vantage's desk")
	var teo := VantageCast.teo()
	t.check(teo.id == "teo" and teo.halberd and teo.door == "gates", "Teo is Halberd's, on the gates")
	var renata := VantageCast.renata()
	t.check(renata.halberd and renata.female and renata.start_suspicion >= 2, "Renata, Halberd's head of security, starts wary")
	for night in VantageCast.IDS:
		for id in VantageCast.IDS[night]:
			t.check(id in VantageCast.EVERYONE, "cast: %s on the %s night works in the tower" % [id, night])

#endregion


#region Scripted replies

## What a sheet's scripted brain does for a line, on a fresh face.
func _reply(sheet: CharacterSheet, line: String, turns := 2, suspicion := -1) -> Dictionary:
	var face := JobRules.new_face(sheet)
	face["turns"] = turns
	if suspicion >= 0:
		face["suspicion"] = suspicion
	sheet.more_actions = VantageCast.ACTIONS
	return ScriptedBrain.reply(sheet, face, {"kind": "line", "heard": line})


func test_scripted(t) -> void:
	t.check(_reply(VantageCast.dana("lift"), "I have a meeting with Mr Holt at half past six.").do == "call_assistant", "Dana rings Noor about a meeting")
	t.check(_reply(VantageCast.stan("lift"), "Northline Lifts, here about car one.").do == "call_reception", "Stan rings the desk about Northline")
	t.check(_reply(VantageCast.philippa("lift"), "Parcel for Mr Holt, it has to be signed for upstairs.").do == "call_assistant", "Ms Grant rings Noor about a parcel")
	t.check(_reply(VantageCast.philippa("lift"), "Long day?").suspicion == 1, "Ms Grant warms to a kind word")
	t.check(_reply(VantageCast.teo("lift"), "Did you see the Mariners last night?").suspicion == 0, "Teo still loves the Mariners")
	t.check(_reply(VantageCast.renata("board"), "I'm the minute-taker from Kestrel.").do == "call_assistant", "Renata checks a minute-taker with Noor")
	t.check(_reply(VantageCast.noor("board"), "Kestrel Staffing sent me to take the minutes.").do == "call_reception", "Noor rings the desk about Kestrel's temp")
	t.check(_reply(VantageCast.philippa("board"), "I'm Halden's observer for the vote.").do == "call_assistant", "Ms Grant checks Halden's observer with Noor")
	var m := _reply(VantageCast.mirela("board"), "Bellweather sent me, where do you want me?", 1)
	t.check(m.do == "none" and str(m.say).contains("Nobody tells me"), "Mirela, on a first line, wonders why nobody told her")
	t.check(_reply(VantageCast.mirela("board"), "Bellweather sent me, where do you want me?", 2, 1).do == "put_to_work", "then puts the server to work")
	t.check(_reply(VantageCast.bram("research"), "Brightway sent me, I'm covering for Marisol with Odile.").do == "ask_cleaner", "Bram asks Odile about a cleaner")
	t.check(_reply(VantageCast.bram("research"), "Ashby Mutual. Mr Holt's orders: the stone goes to the vault.").do == "call_assistant", "Bram rings Noor about orders")
	t.check(_reply(VantageCast.margot("research"), "Ashby Mutual, I have orders to move the Rose to the vault.").do == "call_assistant", "Dr Lind confirms orders with Noor")
	t.check(_reply(VantageCast.joost("research"), "The museum wants to record her whole before tomorrow.", 2, 1).do == "bring_stone", "Joost will fetch the Rose for the museum")
	t.check(_reply(VantageCast.joost("research"), "Cutting her is a crime.").suspicion == 1, "Joost warms to anyone who hates the cutting")
	t.check(_reply(VantageCast.odile("research"), "Brightway sent me. Where do you want me?").do == "take_on", "Odile takes on Brightway's cover")
	var o := VantageCast.odile("research")
	var face := JobRules.new_face(o)
	face["turns"] = 4
	face["secrets"] = [0]
	sheet_said(t, ScriptedBrain.reply(o, face, {"kind": "line", "heard": "How do you get into the gem room?"}), VantageCast.CUTTING_CODE, "Odile, warmed up, gives up the gem room's code")


func sheet_said(t, r: Dictionary, words: String, what: String) -> void:
	t.check(str(r.get("say", "")).contains(words), "%s (%s)" % [what, r.get("say", "")])

#endregion


#region Playing the jobs

func _start(t, def: JobDef, covers: Array, female: Array = []) -> Job:
	var job := JobHarness.start(t, def, covers, null, 7, female)
	job.ended.connect(_note_end.bind(job))
	await t.frames(2)
	return job


func _note_end(r: Dictionary, job: Job) -> void:
	job.set_meta("outcome", r.outcome)


## Asks Mae to make a call, and waits until it's gone through.
func _mae(t, job: Job, call_id: String) -> bool:
	var who := ""
	for m in job.def.mae_calls:
		if m.id == call_id:
			who = str(m.who)
	var ch: Character = job.cast[who]
	if not job.mae_call(1, call_id):
		return false
	return await t.until(func() -> bool: return ch.turns.any(func(x): return str(x.get("kind", "")) == "mae") and not ch.busy, 8.0)


## A crew member rings a number as someone, says a line, and hangs up.
func _ring(t, job: Job, id: int, number: String, as_who: String, line: String) -> void:
	t.check(job.ring(id, number, as_who) == "", "%s rings through as %s" % [number, as_who])
	await t.frames(2)
	job.crew_said(id, line)
	await t.until(func() -> bool: return JobHarness.quiet(job), 4.0)
	job.hang_up(id)


## Says a line to a character and waits for them, and any check they make,
## to settle.
func _say_to(t, job: Job, id: int, char_id: String, line: String) -> void:
	JobHarness.face(job, id, char_id)
	JobHarness.say(job, id, line)
	await JobHarness.answered(t, job, char_id)
	await _settle(t, job, char_id)


## Waits for a character's check, if they started one, to come back.
func _settle(t, job: Job, char_id: String, seconds := 10.0) -> void:
	var ch: Character = job.cast[char_id]
	await t.until(func() -> bool:
		for f in ch.faces.values():
			for v in (f.checks as Dictionary).values():
				if v == "asked":
					return false
		return not ch.busy and JobHarness.quiet(job), seconds)
	await t.frames(2)


## Puts a crew member on one of the walking points, looking north.
func _stand_point(job: Job, id: int, point: String) -> void:
	var at: Vector3 = job.venue.points[point]
	JobHarness.stand(job, id, at, at + Vector3.FORWARD)


func _ride(job: Job, id: int, floor_id: String) -> String:
	JobHarness.stand_at(job, id, "lift_wait_" + floor_id)
	return job.use(id, "lift_call_" + floor_id)


func _done_as(t, job: Job, outcome: String, what: String) -> void:
	await t.until(func() -> bool: return job.done, 3.0)
	var got := str(job.get_meta("outcome", "not over"))
	t.check(got == outcome, "%s (%s)" % [what, got])


func _end(t, job: Job) -> void:
	JobHarness.done(job)
	await t.frames(2)

#endregion


#region The lobby and the lift

func test_lift_basics(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["investor"])
	t.check(job.clock_text() == "6:00 pm" and job.cast.size() == 10, "the lift night starts at six with ten in the tower")
	t.check(job.venue.doors.gates.locked and job.venue.doors.lift_g.locked and not job.venue.doors.plant.locked, "the gates and lifts are locked to the crew, the plant room isn't")
	JobHarness.stand(job, 1, Vector3(3.15, 0, -15.5), Vector3(3.15, 0, -20))
	t.check(job.use(1, "door:gates").contains("pass") and not job.venue.doors.gates.is_open, "the gates want a pass")
	JobHarness.stand_at(job, 1, "lift_wait_g")
	t.check(job.use(1, "lift_call_g").contains("pass"), "and so does the lift")
	t.check(job.use(1, "door:lift_g").contains("button"), "the lift's doors open from the button")
	t.check(job.use(1, "door:gates") == "" and job.venue.doors.gates.is_open, "but the gates let you out")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	t.check(job.heat.level == Heat.LOCKDOWN and job.use(1, "lift_call_g").contains("stopped"), "at Lockdown the lifts stop")
	await _end(t, job)


func test_lift_pass(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["investor"])
	await _say_to(t, job, 1, "dana", "Good evening. I'm here for a meeting with Mr Holt.")
	var c := job.crew_by_id(1)
	t.check(not c.flags.has("pass") and job.cast.dana.face_of(1).checks.get("call_assistant", "") == "bad", "with nobody vouching, Noor has no meeting tonight")
	await _end(t, job)
	job = await _start(t, VantageLiftJob.new(), ["investor"])
	c = job.crew_by_id(1)
	t.check(await _mae(t, job, "meeting"), "Mae rings Noor as Halden Capital")
	await _say_to(t, job, 1, "dana", "Good evening. I'm here for a meeting with Mr Holt.")
	t.check(c.flags.has("pass") and "visitor_pass" in c.items, "Noor confirms the meeting and Dana prints a pass (%s)" % str(job.cast.dana.turns.back().get("reply", {})))
	JobHarness.stand(job, 1, Vector3(3.15, 0, -15.5), Vector3(3.15, 0, -20))
	t.check(job.use(1, "door:gates") != "" and job.venue.doors.gates.is_open, "the pass opens the gates")
	t.check(_ride(job, 1, "g").contains("level 12"), "and calls the lift")
	t.check(VantageTower.floor_of(job.crew_node(1).global_position) == "b", "which takes you up to twelve")
	await _done_as(t, job, "up", "on twelve, the job's done")
	await _end(t, job)


func test_lift_pass_crewmate(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["investor", "courier"])
	await _ring(t, job, 2, "holt_office", "Halden Capital", "Halden Capital here. Our analyst is on the way for a meeting with Mr Holt tonight.")
	t.check(job.flags.has("told:meeting"), "a crewmate on the phone puts the meeting in Noor's head")
	await _say_to(t, job, 1, "dana", "Hello. I have a meeting with Mr Holt, from Halden.")
	t.check(job.crew_by_id(1).flags.has("pass"), "and Dana prints the pass")
	_ride(job, 1, "g")
	t.check(not job.done, "one crew member up isn't the whole crew")
	await _end(t, job)
	job = await _start(t, VantageLiftJob.new(), ["investor", "courier"])
	await _ring(t, job, 2, "holt_office", "Halden Capital", "Halden Capital. Our analyst has a meeting with Mr Holt tonight.")
	await _say_to(t, job, 1, "dana", "Good evening, I have a meeting with Mr Holt.")
	JobHarness.stand_at(job, 1, "lift_wait_g")
	JobHarness.stand(job, 2, job.spot("lift_wait_g").origin + Vector3(-1.5, 0, 0.5), job.spot("lift_wait_g").origin)
	t.check(job.use(1, "lift_call_g").contains("level 12"), "the pass calls the lift")
	t.check(VantageTower.floor_of(job.crew_node(2).global_position) == "b", "and the crewmate beside them rides up too")
	await _done_as(t, job, "up", "the whole crew on twelve")
	await _end(t, job)


func test_lift_key(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["engineer"])
	var c := job.crew_by_id(1)
	await _say_to(t, job, 1, "stan", "Evening. Northline Lifts, I'm here about car one.")
	t.check(not c.flags.has("lift_key") and job.cast.stan.face_of(1).checks.get("call_reception", "") == "bad", "nobody's booked Northline: no key")
	await _end(t, job)
	job = await _start(t, VantageLiftJob.new(), ["engineer"])
	c = job.crew_by_id(1)
	t.check(await _mae(t, job, "lift"), "Mae rings the desk as Northline Lifts")
	t.check(job.cast.stan.history.any(func(h): return str(h.text).contains("Northline")), "and Dana radios Stan")
	await _say_to(t, job, 1, "stan", "Evening. Northline Lifts, I'm here about car one.")
	t.check(c.flags.has("lift_key") and "lift_key" in c.items, "the desk has Northline booked, and Stan lends the key (%s)" % str(job.cast.stan.turns.back().get("reply", {})))
	JobHarness.stand(job, 1, Vector3(3.15, 0, -15.5), Vector3(3.15, 0, -20))
	t.check(job.use(1, "door:gates") != "" and job.venue.doors.gates.is_open, "the key opens the gates")
	t.check(_ride(job, 1, "g").contains("level 12"), "and runs car two")
	await _done_as(t, job, "up", "the engineer is on twelve")
	await _end(t, job)
	# With a crewmate ringing the desk instead.
	job = await _start(t, VantageLiftJob.new(), ["engineer", "investor"])
	await _ring(t, job, 2, "reception", "Northline Lifts", "Northline Lifts here. Our engineer is on the way for your car one tonight.")
	t.check(job.flags.has("told:lift"), "a crewmate books the engineer by phone")
	await _say_to(t, job, 1, "stan", "Northline Lifts. Here about car one.")
	t.check(job.crew_by_id(1).flags.has("lift_key"), "and Stan lends the key")
	JobHarness.stand_at(job, 1, "lift_wait_g")
	JobHarness.stand(job, 2, job.spot("lift_wait_g").origin + Vector3(-1.5, 0, 0.5), job.spot("lift_wait_g").origin)
	t.check(job.use(1, "lift_call_g").contains("level 12"), "the key runs car two")
	await _done_as(t, job, "up", "the engineer and the crewmate beside them on twelve")
	await _end(t, job)


func test_lift_ride(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["courier"])
	var p: Character = job.cast.philippa
	var c := job.crew_by_id(1)
	t.check(await _mae(t, job, "parcel"), "Mae tells Noor a parcel's coming")
	await _say_to(t, job, 1, "philippa", "Sorry to bother you. Parcel for Mr Holt, it has to be signed for upstairs.")
	t.check(c.flags.has("escort") and p.post == "lift_wait_g", "Noor's expecting it, and Ms Grant takes the courier up with her (%s)" % str(p.turns.back().get("reply", {})))
	JobHarness.stand(job, 1, Vector3(3.15, 0, -15.5), Vector3(3.15, 0, -20))
	t.check(job.use(1, "door:gates") != "" and job.venue.doors.gates.is_open, "with her, the gates open")
	t.check(JobHarness.walk(job, p, "lift_wait_g"), "she walks to the lift")
	JobHarness.stand(job, 1, p.global_position + Vector3(-1.5, 0, 0.5), p.global_position)
	await t.until(func() -> bool: return job.done, 3.0)
	t.check(VantageTower.floor_of(job.crew_node(1).global_position) == "b" and p.post == "philippa_b", "and up you go together")
	await _done_as(t, job, "up", "riding up with Ms Grant")
	await _end(t, job)
	# Talked to alone: she won't ride with a stranger nobody's expecting.
	job = await _start(t, VantageLiftJob.new(), ["courier"])
	job.show_papers(1, job.cast.philippa)
	await _settle(t, job, "philippa")
	t.check(not job.crew_by_id(1).flags.has("escort"), "the parcel alone, unexpected, doesn't get you a ride")
	await _end(t, job)
	# A crewmate rings Noor as the couriers.
	job = await _start(t, VantageLiftJob.new(), ["courier", "engineer"])
	await _ring(t, job, 2, "holt_office", "Swift Couriers", "Swift Couriers. We've a signed-for parcel for Mr Holt on the way up.")
	await _say_to(t, job, 1, "philippa", "Parcel for Mr Holt. It has to be signed for upstairs.")
	t.check(job.crew_by_id(1).flags.has("escort"), "with a crewmate's call, she takes the courier up")
	p = job.cast.philippa
	t.check(JobHarness.walk(job, p, "lift_wait_g"), "she walks to the lift")
	JobHarness.stand(job, 1, p.global_position + Vector3(-1.5, 0, 0.5), p.global_position)
	JobHarness.stand(job, 2, p.global_position + Vector3(-1.5, 0, -0.7), p.global_position)
	await _done_as(t, job, "up", "Ms Grant takes the courier and the crewmate beside them up")
	await _end(t, job)


func test_lift_clock(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["investor"])
	var p: Character = job.cast.philippa
	job.minutes = 18 * 60 + 20.5
	await t.frames(2)
	t.check(p.walking and p.post == "lift_wait_g", "at twenty past Ms Grant goes up")
	JobHarness.walk(job, p, "lift_wait_g")
	await t.frames(2)
	job.elapsed += VantageLiftJob.WAIT + 1.0
	await t.frames(2)
	t.check(p.post == "philippa_b", "and with nobody to take, she goes on her own")
	job.minutes = VantageLiftJob.LOCK + 0.1
	await _done_as(t, job, "late", "the night lock with the crew downstairs")
	await _end(t, job)


func test_lift_office(t) -> void:
	var job := await _start(t, VantageLiftJob.new(), ["investor", "engineer"])
	job._hold(1, job.cast.teo)
	t.check(job.crew_by_id(1).held and job.venue.doors.office.locked, "held in Halberd's security office")
	var minder: Character = null
	for ch in job.cast.values():
		if ch.minding:
			minder = ch
	t.check(minder != null and minder.sheet.halberd and minder.post == "office_guard", "a Halberd guard minds the office")
	t.check(job.venue.zone_at(job.spot("held").origin + Vector3.UP) == "office", "the held spot is in the office")
	await _end(t, job)

#endregion


#region The board meeting

func _decided(job: Job, id: int) -> bool:
	return job.crew_by_id(id).flags.has("decision")


func test_board_temp(t) -> void:
	var job := await _start(t, VantageBoardJob.new(), ["temp"])
	t.check(job.clock_text() == "7:30 pm" and job.venue.doors.boardroom.locked, "the board night starts at 7:30 with the boardroom locked")
	_stand_point(job, 1, "assist_bw")
	t.check(job.use(1, "door:boardroom").contains("Renata"), "Renata's on the boardroom door")
	await _say_to(t, job, 1, "noor", "Hi. Kestrel Staffing sent me to take the minutes.")
	t.check(not job.crew_by_id(1).flags.has("minutes"), "with nobody signed in downstairs, Noor won't seat the temp")
	await _end(t, job)
	job = await _start(t, VantageBoardJob.new(), ["temp"])
	t.check(await _mae(t, job, "temp"), "Mae signs the temp in at the desk as Kestrel")
	await _say_to(t, job, 1, "noor", "Hi. Kestrel Staffing sent me to take the minutes.")
	var c := job.crew_by_id(1)
	t.check(c.flags.has("minutes") and job.venue.doors.boardroom.is_open, "Dana has them signed in, and Noor opens the boardroom (%s)" % str(job.cast.noor.turns.back().get("reply", {})))
	JobHarness.stand_at(job, 1, "seat_s1")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1), "in the room for the vote, you hear the decision")
	t.check(job.goal_for(1).contains("lobby"), "and the goal is to get it downstairs")
	t.check(_ride(job, 1, "b").contains("lobby"), "the lift goes down")
	await _done_as(t, job, "out", "down with the decision")
	await _end(t, job)
	# A crewmate signs the temp in by phone.
	job = await _start(t, VantageBoardJob.new(), ["temp", "server"])
	await _ring(t, job, 2, "reception", "Kestrel Staffing", "Kestrel Staffing. Our temp minute-taker for the board is on the way up.")
	await _say_to(t, job, 1, "noor", "Kestrel Staffing sent me to take the minutes.")
	t.check(job.crew_by_id(1).flags.has("minutes"), "a crewmate's call signs the temp in")
	JobHarness.stand_at(job, 1, "seat_s1")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1) and not _decided(job, 2), "the temp hears the vote, the crewmate downstairs doesn't")
	_ride(job, 1, "b")
	await _done_as(t, job, "out", "the temp gets it down to the crewmate")
	await _end(t, job)


func test_board_server(t) -> void:
	var job := await _start(t, VantageBoardJob.new(), ["server"])
	var c := job.crew_by_id(1)
	await _say_to(t, job, 1, "mirela", "Bellweather sent me. Extra hands for the coffee.")
	await _say_to(t, job, 1, "mirela", "Busy night? You're on your own?")
	await _say_to(t, job, 1, "mirela", "Where do you want me?")
	t.check(c.flags.has("serving"), "Mirela puts the server to work (%s)" % str(job.cast.mirela.turns.back().get("reply", {})))
	t.check(job.use(1, "door:service").contains("coffee"), "the service door stays shut until the coffee")
	job.minutes = VantageBoardJob.COFFEE + 0.2
	await t.frames(3)
	t.check(job.venue.doors.service.is_open and job.cast.mirela.post == "mirela_serve", "at the coffee the service door opens and Mirela goes in")
	JobHarness.stand_at(job, 1, "mirela_serve")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1), "pouring the coffee, you hear the vote")
	_ride(job, 1, "b")
	await _done_as(t, job, "out", "the server gets it downstairs")
	await _end(t, job)
	# Mae's call: Mirela was expecting help.
	job = await _start(t, VantageBoardJob.new(), ["server"])
	t.check(await _mae(t, job, "hands"), "Mae tells Mirela help is coming")
	await _say_to(t, job, 1, "mirela", "Bellweather sent me.")
	await _say_to(t, job, 1, "mirela", "Where do you want me?")
	t.check(job.crew_by_id(1).flags.has("serving"), "and she puts you straight to work")
	# Listening at the service door instead.
	job.minutes = VantageBoardJob.COFFEE + 0.2
	await t.frames(3)
	JobHarness.stand_at(job, 1, "service_ear")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1), "at the open service door, the pantry hears the vote")
	await _end(t, job)
	# A crewmate rings the pantry as Bellweather.
	job = await _start(t, VantageBoardJob.new(), ["server", "temp"])
	await _ring(t, job, 2, "catering", "Bellweather Catering", "Bellweather office. We're short tonight, so we've sent you an extra pair of hands.")
	t.check(job.flags.has("told:hands"), "a crewmate tells Mirela help is coming")
	await _say_to(t, job, 1, "mirela", "Bellweather sent me.")
	await _say_to(t, job, 1, "mirela", "Where do you want me?")
	t.check(job.crew_by_id(1).flags.has("serving"), "and she puts the server to work")
	job.minutes = VantageBoardJob.COFFEE + 0.2
	await t.frames(3)
	JobHarness.stand_at(job, 1, "mirela_serve")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1), "pouring the coffee, the server hears the vote")
	_ride(job, 1, "b")
	await _done_as(t, job, "out", "the server gets it downstairs")
	await _end(t, job)


func test_board_observer(t) -> void:
	var job := await _start(t, VantageBoardJob.new(), ["observer"])
	var c := job.crew_by_id(1)
	t.check("letter" in c.items, "the observer carries Halden's letter")
	JobHarness.face(job, 1, "philippa")
	job.show_papers(1, job.cast.philippa)
	await t.until(func() -> bool: return job.cast.philippa.turns.size() >= 1, 4.0)
	await _settle(t, job, "philippa")
	t.check(not c.flags.has("observer") and job.cast.philippa.face_of(1).checks.get("call_assistant", "") == "bad", "the letter alone: Noor's heard nothing from Halden")
	await _end(t, job)
	job = await _start(t, VantageBoardJob.new(), ["observer"])
	c = job.crew_by_id(1)
	t.check(await _mae(t, job, "halden"), "Mae rings Noor from Halden's office")
	JobHarness.face(job, 1, "philippa")
	job.show_papers(1, job.cast.philippa)
	await t.until(func() -> bool: return job.cast.philippa.turns.size() >= 1, 4.0)
	await _settle(t, job, "philippa")
	t.check(c.flags.has("observer") and job.venue.doors.boardroom.is_open, "the letter passes a glance, Noor confirms, and Ms Grant takes you in (%s)" % str(job.cast.philippa.turns.back().get("reply", {})))
	_stand_point(job, 1, "board_nw")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(_decided(job, 1), "the observer hears the vote")
	_ride(job, 1, "b")
	await _done_as(t, job, "out", "the observer gets it downstairs")
	await _end(t, job)
	# Renata gives the letter a close look.
	job = await _start(t, VantageBoardJob.new(), ["observer"])
	JobHarness.face(job, 1, "renata")
	job.show_papers(1, job.cast.renata)
	t.check(job.cast.renata.face_of(1).papers == "copy" and job.cast.renata.suspicion_of(1) >= 3, "Renata looks closely and sees a copy")
	await _end(t, job)
	# A crewmate rings Noor as Halden.
	job = await _start(t, VantageBoardJob.new(), ["observer", "temp"])
	await _ring(t, job, 2, "holt_office", "Halden Capital", "Halden Capital, the chair's office. We're sending an observer to the vote tonight.")
	JobHarness.face(job, 1, "philippa")
	job.show_papers(1, job.cast.philippa)
	await t.until(func() -> bool: return job.cast.philippa.turns.size() >= 1, 4.0)
	await _settle(t, job, "philippa")
	t.check(job.crew_by_id(1).flags.has("observer"), "a crewmate's call makes the observer good")
	_stand_point(job, 1, "board_nw")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	_ride(job, 1, "b")
	await _done_as(t, job, "out", "the observer gets the vote downstairs")
	await _end(t, job)


func test_board_clock(t) -> void:
	var job := await _start(t, VantageBoardJob.new(), ["temp"])
	job.minutes = VantageBoardJob.START + 0.2
	await t.frames(3)
	t.check(job.flags.has("meeting") and job.cast.philippa.post == "seat_n2", "at twenty to eight the board sits and Ms Grant goes in")
	job.minutes = VantageBoardJob.DECISION + 0.2
	await t.frames(3)
	t.check(not _decided(job, 1), "outside the room, you don't hear the vote")
	job.minutes = VantageBoardJob.CLOSE + 0.2
	await _done_as(t, job, "missed", "the meeting closes with nobody from the crew having heard it")
	await _end(t, job)
	job = await _start(t, VantageBoardJob.new(), ["temp"])
	job.crew_by_id(1).flags["decision"] = true
	job.minutes = job.def.end + 0.1
	await _done_as(t, job, "stuck", "heard but never got it downstairs")
	await _end(t, job)

#endregion


#region The research floor

func _rose_with(job: Job) -> int:
	var h := job.holder("rose")
	return h.id if h else 0


## Out of the tower with the Rose: down the lift and out the front.
func _out(t, job: Job, id: int) -> void:
	JobHarness.stand_at(job, id, "lift_wait_r")
	job.use(id, "lift_call_r")
	JobHarness.stand_at(job, id, "plaza")
	await t.frames(3)


func test_research_basics(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["insurer"])
	t.check(job.clock_text() == "10:40 pm" and job.cast.size() == 10, "the research night starts at 10:40 with ten in the tower")
	t.check(job.venue.doors.secure.locked and job.venue.doors.cutting.locked and str(job.items.rose.at) == "cradle", "the secure door and the gem room are locked, and the Rose is in her cradle")
	_stand_point(job, 1, "check_c")
	t.check(job.use(1, "door:secure").contains("Bram"), "the secure door is Bram's")
	_stand_point(job, 1, "lab_in")
	t.check(job.use(1, "door:secure") == "" and job.venue.doors.secure.is_open, "from the lab it opens to let you out")
	t.check(job.keypad(1, "1111", "cutting_pad") == "Wrong code." and not job.venue.doors.cutting.is_open, "a wrong code doesn't open the gem room")
	await _end(t, job)


func test_research_orders(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["insurer"])
	var c := job.crew_by_id(1)
	t.check("orders" in c.items, "the insurer carries the forged orders")
	JobHarness.face(job, 1, "bram")
	job.show_papers(1, job.cast.bram)
	await t.until(func() -> bool: return job.cast.bram.turns.size() >= 1, 4.0)
	await _settle(t, job, "bram")
	t.check(not c.flags.has("cleared") and job.cast.bram.face_of(1).checks.get("call_assistant", "") == "bad", "Noor knows nothing of any orders: Bram won't open")
	await _end(t, job)
	job = await _start(t, VantageResearchJob.new(), ["insurer"])
	c = job.crew_by_id(1)
	t.check(await _mae(t, job, "orders"), "Mae rings Noor as Ashby Mutual")
	JobHarness.face(job, 1, "bram")
	job.show_papers(1, job.cast.bram)
	await t.until(func() -> bool: return job.cast.bram.turns.size() >= 1, 4.0)
	await _settle(t, job, "bram")
	t.check(c.flags.has("cleared") and job.venue.doors.secure.is_open, "Noor confirms the orders and Bram opens the secure door (%s)" % str(job.cast.bram.turns.back().get("reply", {})))
	await _say_to(t, job, 1, "margot", "Ashby Mutual. Mr Holt's orders: the Rose goes down to the vault tonight.")
	var m: Character = job.cast.margot
	t.check(c.flags.has("handed") and m.post == "rose", "Dr Lind confirms with Noor and takes you to the gem room (%s)" % str(m.turns.back().get("reply", {})))
	t.check(JobHarness.walk(job, m, "rose"), "she walks to the Rose")
	JobHarness.stand(job, 1, m.global_position + Vector3(-1.2, 0, 0.6), m.global_position)
	await t.frames(3)
	t.check(_rose_with(job) == 1, "and signs her over to you")
	job.minutes = VantageResearchJob.CHECK + 0.2
	await t.frames(3)
	t.check(not job.flags.has("shut"), "signed out, she's not missed at five past")
	await _out(t, job, 1)
	await _done_as(t, job, "taken", "out of the tower with the Rose")
	await _end(t, job)
	# A crewmate rings Noor as the insurers.
	job = await _start(t, VantageResearchJob.new(), ["insurer", "cleaner"])
	await _ring(t, job, 2, "holt_office", "Ashby Mutual", "Ashby Mutual for Mr Holt. Our man moves the stone to the vault tonight, he signed the transfer.")
	t.check(job.flags.has("told:orders"), "a crewmate puts the orders in Noor's diary")
	await _say_to(t, job, 1, "bram", "Evening. Ashby Mutual, I have Mr Holt's orders to move the stone to the vault.")
	t.check(job.crew_by_id(1).flags.has("cleared"), "and Bram lets the insurer through")
	await _say_to(t, job, 1, "margot", "Ashby Mutual. Mr Holt's orders: the Rose goes down to the vault tonight.")
	m = job.cast.margot
	t.check(job.crew_by_id(1).flags.has("handed") and JobHarness.walk(job, m, "rose"), "Dr Lind takes the insurer to the Rose")
	JobHarness.stand(job, 1, m.global_position + Vector3(-1.2, 0, 0.6), m.global_position)
	await t.frames(3)
	t.check(_rose_with(job) == 1, "and signs her over")
	await _out(t, job, 1)
	await _done_as(t, job, "taken", "the insurer walks out with the Rose")
	await _end(t, job)


func test_research_joost(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["curator"])
	var j: Character = job.cast.joost
	await _say_to(t, job, 1, "joost", "Joost? Dr Arden, from the Caldera Museum.")
	await _say_to(t, job, 1, "joost", "The museum wants a record of her whole, before tomorrow.")
	t.check(not job.flags.has("fetch"), "a stranger from the museum isn't enough on his own")
	await _say_to(t, job, 1, "joost", "Cutting her is a crime. You know it is.")
	await _say_to(t, job, 1, "joost", "Let the museum record her whole. Photographs, that's all.")
	t.check(job.flags.has("fetch") and j.post == "rose", "won over, Joost goes to fetch the Rose (%s)" % str(j.turns.back().get("reply", {})))
	t.check(JobHarness.walk(job, j, "rose"), "he walks to the gem room")
	await t.frames(3)
	t.check(str(job.items.rose.at) == "" and job.flags.get("joost", "") == "bringing", "takes her out of her cradle")
	t.check(JobHarness.walk(job, j, "joost_break"), "and brings her back")
	JobHarness.stand(job, 1, j.global_position + Vector3(-1.0, 0, 0.5), j.global_position)
	await t.frames(3)
	t.check(_rose_with(job) == 1, "and puts her in your hand")
	job.minutes = VantageResearchJob.CHECK + 0.2
	await t.frames(3)
	t.check(not job.flags.has("shut"), "when Dr Lind checks, Joost says he has her")
	await _out(t, job, 1)
	await _done_as(t, job, "taken", "the curator walks out with the Rose")
	await _end(t, job)
	# Mae rings him from the museum first.
	job = await _start(t, VantageResearchJob.new(), ["curator"])
	t.check(await _mae(t, job, "museum"), "Mae rings Joost from the museum")
	await _say_to(t, job, 1, "joost", "Joost? Dr Arden, from the Caldera Museum.")
	await _say_to(t, job, 1, "joost", "The museum wants to record her whole, before tomorrow.")
	t.check(job.flags.has("fetch"), "expecting the museum, he goes for the Rose")
	await _end(t, job)
	# A crewmate rings him as the museum.
	job = await _start(t, VantageResearchJob.new(), ["curator", "insurer"])
	await _ring(t, job, 2, "joost", "Caldera Museum", "Dr Vance's office, the Caldera Museum. Our curator is coming to record her whole tonight.")
	await _say_to(t, job, 1, "joost", "Joost? I'm the curator from the museum.")
	await _say_to(t, job, 1, "joost", "We want to record her whole, before tomorrow.")
	t.check(job.flags.has("fetch"), "a crewmate's call does it too")
	j = job.cast.joost
	t.check(JobHarness.walk(job, j, "rose"), "he goes for her")
	await t.frames(3)
	t.check(JobHarness.walk(job, j, "joost_break"), "and brings her back")
	_stand_point(job, 1, "lab_c")
	JobHarness.stand(job, 2, j.global_position + Vector3(-1.0, 0, 0.5), j.global_position)
	await t.frames(3)
	t.check(_rose_with(job) == 2, "and hands her to whichever of the crew is there")
	await _out(t, job, 2)
	await _done_as(t, job, "taken", "the crewmate walks out with the Rose")
	await _end(t, job)


func test_research_cleaner(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["cleaner"])
	var c := job.crew_by_id(1)
	await _say_to(t, job, 1, "bram", "Hi. Brightway sent me, I'm covering for Marisol with Odile.")
	t.check(not c.flags.has("cleared") and job.cast.bram.face_of(1).checks.get("ask_cleaner", "") == "bad", "Odile's never heard of you: Bram won't open")
	await _end(t, job)
	job = await _start(t, VantageResearchJob.new(), ["cleaner"])
	c = job.crew_by_id(1)
	await _say_to(t, job, 1, "odile", "Hi. Brightway sent me. I'm covering for Marisol tonight.")
	await _say_to(t, job, 1, "odile", "Where do you want me?")
	t.check(c.flags.has("cleaner"), "Odile takes you on (%s)" % str(job.cast.odile.turns.back().get("reply", {})))
	await _say_to(t, job, 1, "odile", "Long night? Your feet must be killing you.")
	await _say_to(t, job, 1, "odile", "How do you get into the gem room, anyway?")
	t.check(str(job.cast.odile.turns.back().get("reply", {}).get("say", "")).contains(VantageCast.CUTTING_CODE), "warmed up, she tells you the gem room's code (%s)" % str(job.cast.odile.turns.back().get("reply", {}).get("say", "")))
	await _say_to(t, job, 1, "bram", "Evening. Brightway, I'm with Odile, covering for Marisol.")
	t.check(c.flags.has("cleared") and job.venue.doors.secure.is_open, "Odile vouches and Bram lets you through (%s)" % str(job.cast.bram.turns.back().get("reply", {})))
	JobHarness.stand(job, 1, Vector3(7.0, VantageTower.R, -9.6), Vector3(9, VantageTower.R, -9.6))
	t.check(job.keypad(1, VantageCast.CUTTING_CODE, "cutting_pad") == "The lock clicks." and job.venue.doors.cutting.is_open, "the code opens the gem room")
	JobHarness.stand_at(job, 1, "rose")
	t.check(job.use(1, "item:rose").contains("Rose") and _rose_with(job) == 1, "you take the Rose from her cradle")
	await _out(t, job, 1)
	await _done_as(t, job, "taken", "the cleaner walks out with the Rose")
	await _end(t, job)
	# Mae rings Odile as Brightway: Bram's check comes back good straight away.
	job = await _start(t, VantageResearchJob.new(), ["cleaner"])
	t.check(await _mae(t, job, "shift"), "Mae tells Odile her cover's coming")
	await _say_to(t, job, 1, "bram", "Brightway, I'm Marisol's cover, with Odile.")
	t.check(job.crew_by_id(1).flags.has("cleared"), "Odile was told: Bram lets the cover through")
	await _end(t, job)
	# A crewmate rings Odile as Brightway.
	job = await _start(t, VantageResearchJob.new(), ["cleaner", "insurer"])
	await _ring(t, job, 2, "cleaning", "Brightway Cleaning", "Brightway office. Marisol's off sick, we're sending you cover tonight.")
	await _say_to(t, job, 1, "bram", "Brightway sent me, I'm Marisol's cover.")
	t.check(job.crew_by_id(1).flags.has("cleared"), "a crewmate's call does it too")
	JobHarness.stand(job, 1, Vector3(7.0, VantageTower.R, -9.6), Vector3(9, VantageTower.R, -9.6))
	t.check(job.keypad(1, VantageCast.CUTTING_CODE, "cutting_pad") == "The lock clicks.", "the code opens the gem room")
	JobHarness.stand_at(job, 1, "rose")
	job.use(1, "item:rose")
	t.check(_rose_with(job) == 1, "and the cleaner takes the Rose")
	await _out(t, job, 1)
	await _done_as(t, job, "taken", "the cleaner walks out with the Rose")
	await _end(t, job)


func test_research_scanner(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["cleaner", "insurer"])
	var bram: Character = job.cast.bram
	var toasts := []
	job.toast_for.connect(func(id, text): toasts.append([id, text]))
	_stand_point(job, 1, "r_south")
	job.crew_said(1, "Can you hear me?", "whisper", true)
	await t.frames(2)
	t.check(bram.suspicion_of(1) == bram.sheet.start_suspicion, "on the earpiece outside the checkpoint, nothing")
	_stand_point(job, 1, "lab_c")
	var heat := job.heat.events
	job.crew_said(1, "I'm in. Where's the gem room?", "whisper", true)
	await t.frames(2)
	t.check(bram.suspicion_of(1) >= bram.sheet.start_suspicion + 2 and job.heat.events > heat, "in the lab, the scanner picks it up: Bram knows, and the tower heats up")
	t.check(toasts.any(func(x): return x[0] == 1 and str(x[1]).contains("scanner")), "and you're told")
	job.crew_said(1, "Hello?", "whisper", true)
	await t.frames(2)
	t.check(bram.suspicion_of(1) == bram.sheet.start_suspicion + 2, "the scanner doesn't count the same person twice in a moment")
	job.elapsed += VantageResearchJob.SCAN_EVERY + 1.0
	job.crew_said(1, "Hello?", "whisper", true)
	await t.until(func() -> bool: return JobHarness.quiet(job), 3.0)
	job.elapsed += VantageResearchJob.SCAN_EVERY + 1.0
	job.crew_said(1, "Anyone?", "whisper", true)
	t.check(await t.until(func() -> bool: return job.crew_by_id(1).held, 6.0), "keep talking and Bram calls it in")
	await _end(t, job)


func test_research_check(t) -> void:
	var job := await _start(t, VantageResearchJob.new(), ["cleaner"])
	JobHarness.stand_at(job, 1, "rose")
	job.flags["keypad:cutting_pad"] = true
	t.check(job.take(1, "rose") != "" and _rose_with(job) == 1, "the Rose comes off her cradle")
	job.minutes = VantageResearchJob.ROUND + 0.2
	await t.frames(3)
	t.check(job.cast.renata.post == "renata_r", "at five to eleven Renata comes up on her round")
	job.minutes = VantageResearchJob.CHECK + 0.2
	await t.frames(3)
	t.check(job.flags.has("shut") and job.venue.doors.front.locked, "at five past Dr Lind finds her gone, and Halberd shuts the tower")
	JobHarness.stand_at(job, 1, "lift_wait_r")
	t.check(job.use(1, "lift_call_r").contains("stopped"), "the lifts stop")
	job.minutes = job.def.end + 0.1
	await _done_as(t, job, "found", "found out")
	await _end(t, job)
	job = await _start(t, VantageResearchJob.new(), ["cleaner"])
	job.minutes = job.def.end + 0.1
	await _done_as(t, job, "late", "the shift changes with the Rose still on nine")
	await _end(t, job)

#endregion
