extends RefCounted
## The Tideline (game/venues/tideline/) and its three jobs: the building
## through the checks every venue passes ([VenueChecks]), each job's data and
## routines, every way through each job played with scripted brains, the
## ways it goes wrong, the cameras, and the cast's scripted replies.
##   godot --headless --path . tests/run_tests.tscn -- --only=tideline

const DOORS: Array[String] = ["front", "high_limit", "staff", "cage", "vault", "count_room", "eye", "office", "staff_room", "back"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"crew_0": "outside", "crew_1": "outside", "teo": "outside", "kerb": "outside", "tess_smoke": "outside",
	"panel": "outside", "back_out": "outside", "desi": "floor", "bea_bar": "floor", "pilar": "floor",
	"marcus": "floor", "lyle": "floor", "window_2": "floor", "staff_out": "floor", "front_in": "floor",
	"augie": "pit", "tess": "pit", "horace": "lounge", "marisol": "lounge", "anton": "high_limit",
	"hugo": "high_limit", "hl_in": "high_limit", "corridor_check": "corridor", "office_guard": "corridor",
	"count_out": "corridor", "staff_in": "corridor", "count_in": "count_room", "marcus_count": "count_room",
	"gloria": "count_room", "count_look": "count_room", "wes": "eye", "eye_in": "eye", "held": "office",
	"office_in": "office", "lockers": "staff_room", "staff_room_in": "staff_room", "bea": "cage", "noor": "cage",
	"horace_window": "cage", "horace_listen": "cage", "noor_vault": "cage", "horace_vault": "cage",
	"cage_in": "cage", "vault_in": "vault", "rose_table": "vault",
}
## Places in each room, for the zones.
const ROOM_SAMPLES := {
	"floor": [Vector3(-4, 1, -9), Vector3(-15, 1, -3), Vector3(7, 1, -23), Vector3(-16, 1, -24)],
	"pit": [Vector3(-3, 1, -15)],
	"lounge": [Vector3(15, 1, -3), Vector3(24, 1, -1)],
	"high_limit": [Vector3(-11, 1, -30), Vector3(-6, 1, -36)],
	"cage": [Vector3(13, 1, -10), Vector3(11, 1, -7)],
	"vault": [Vector3(18.5, 1, -10)],
	"corridor": [Vector3(18, 1, -16)],
	"count_room": [Vector3(13, 1, -22)],
	"eye": [Vector3(19.5, 1, -22)],
	"office": [Vector3(24, 1, -22)],
	"staff_room": [Vector3(23.5, 1, -10)],
	"outside": [Vector3(-4, 1, 5), Vector3(30, 1, -10), Vector3(0, 1, 16)],
}


func _venue(t: Node, open_doors := false) -> Tideline:
	return await VenueChecks.built(t, Tideline.new(), open_doors)


#region The building

func test_builds(t) -> void:
	var v: Tideline = await _venue(t)
	for d in DOORS:
		t.check(v.doors.get(d) is HotelDoor, "tideline: the %s door" % d)
	t.check(v.doors.size() == DOORS.size(), "tideline: no doors but the ten (%d)" % v.doors.size())
	for z in ROOM_SAMPLES:
		for p in ROOM_SAMPLES[z]:
			t.check(v.zone_at(p) == z, "tideline: %s is in the %s (%s)" % [p, z, v.zone_at(p)])
	for id in ["count_pad", "back_pad", "cam_panel", "count_desk", "vault_table", "request"]:
		t.check(v.uses.has(id), "tideline: %s can be used" % id)
	t.check(str(v.uses.count_desk.get_meta("use", "")) == "item:count_sheet", "tideline: the count sheet lies on the count table")
	t.check(str(v.uses.vault_table.get_meta("use", "")) == "item:rose", "tideline: the Rose lies on the vault's table")
	t.check(v.zone_at(v.uses.count_pad.global_position) == "corridor" and v.uses.count_pad.global_position.distance_to(v.doors.count_room.centre()) < 2.0, "tideline: the count room's keypad is beside its door")
	t.check(v.zone_at(v.uses.back_pad.global_position) == "outside" and v.uses.back_pad.global_position.distance_to(v.doors.back.centre()) < 2.0, "tideline: the back door's keypad is outside it")
	t.check(v.zone_at(v.uses.vault_table.global_position) == "vault", "tideline: the Rose is in the vault")
	t.check(v.extras.get("floor", []).size() >= 12, "tideline: a crowd on the floor")
	t.check(v.extras.get("pit", []).size() >= 4, "tideline: dealers in the pit")
	t.check(v.extras.get("lounge", []).size() >= 4, "tideline: people in the lounge")
	VenueChecks.structure(t, v, "tideline", SPOT_ZONES)
	v.queue_free()


func test_spots(t) -> void:
	var v: Tideline = await _venue(t)
	VenueChecks.standing_room(t, v, "tideline")
	v.queue_free()


func test_links_clear(t) -> void:
	var v: Tideline = await _venue(t, true)
	VenueChecks.walkable(t, v, "tideline")
	v.queue_free()


func test_doors_block(t) -> void:
	var v: Tideline = await _venue(t)
	await VenueChecks.doors_block(t, v, "tideline")
	v.queue_free()


## The cage's windows: you can talk through them and see through them, but
## nobody climbs through.
func test_cage_windows(t) -> void:
	var v: Tideline = await _venue(t)
	for z in Tideline.WINDOWS:
		var a := Vector3(9.0, 1.6, z)
		var b := Vector3(11.0, 1.6, z)
		t.check(VenueChecks._ray(t, a, b, Kit.LAYER_SOLID).is_empty(), "tideline: you can see through the cage's window at %.1f" % z)
		t.check(not VenueChecks._ray(t, a, b, Kit.LAYER_PEOPLE).is_empty(), "tideline: nobody climbs through the cage's window at %.1f" % z)
	v.queue_free()

#endregion


#region The jobs' data

func test_job_data(t) -> void:
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		VenueChecks.job_data(t, def)
	var ids := {}
	for night in ["count", "favor", "vault"]:
		for s in TidelineCast.all(night):
			t.check(s.voice != GameConfig.MAE_VOICE, "tideline: %s doesn't speak in Mae's voice" % s.id)
			ids[s.id] = s.voice
	var voices := {}
	for id in ids:
		t.check(not voices.has(ids[id]), "tideline: %s has a voice of their own (%s)" % [id, ids[id]])
		voices[ids[id]] = id
	t.check(ids.size() == 15, "tideline: a cast of fifteen (%d)" % ids.size())
	for id in ["marcus", "teo", "hugo"]:
		t.check(MeridianCast.IDS.has(id), "tideline: %s is the Meridian's %s" % [id, id])
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		t.check(def.memory_from == ["meridian"], "%s: the cast remembers the Meridian" % def.id)


func test_routines(t) -> void:
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		await VenueChecks.routines(t, def)

#endregion


#region Playing a job

## Starts a job in the Tideline, keeping its report when it ends.
func _start(t, def: JobDef, covers: Array, female := []) -> Job:
	var job := JobHarness.start(t, def, covers, null, 7, female)
	var ended: Array = []
	job.set_meta("ended", ended)
	job.ended.connect(_on_ended.bind(ended))
	await t.frames(2)
	return job


func _on_ended(r: Dictionary, ended: Array) -> void:
	ended.append(r)


## How the job ended ("" while it's still on).
func _outcome(job: Job) -> String:
	var ended: Array = job.get_meta("ended", [])
	return str(ended[0].get("outcome", "")) if not ended.is_empty() else ""


## Waits for the job to end; returns how.
func _ends(t, job: Job, seconds := 3.0) -> String:
	await t.until(func() -> bool: return job.done, seconds)
	return _outcome(job)


## A crew member walks up to a character and says a line. Returns what the
## character did ("" when they never answered).
func _say(t, job: Job, id: int, char_id: String, text: String, distance := 1.4) -> String:
	var ch: Character = job.cast[char_id]
	var had := ch.turns.size()
	JobHarness.face(job, id, char_id, distance)
	JobHarness.say(job, id, text)
	if not await t.until(func() -> bool: return ch.turns.size() > had and not ch.busy, 6.0):
		return ""
	return JobHarness.last_do(job, char_id)


## A crew member rings one of the job's numbers, showing `as_who`, and says
## a line. Returns what the one who answered did; stays on the line.
func _ring(t, job: Job, id: int, number: String, as_who: String, text: String) -> String:
	var who := ""
	for n in job.def.phone:
		if str(n.id) == number:
			who = str(n.who)
	var ch: Character = job.cast[who]
	if job.ring(id, number, as_who) != "":
		return ""
	await t.until(func() -> bool: return not ch.busy, 3.0)
	var had := ch.turns.size()
	JobHarness.say(job, id, text)
	if not await t.until(func() -> bool: return ch.turns.size() > had and not ch.busy, 6.0):
		return ""
	return JobHarness.last_do(job, who)


## Asks Mae for a call and waits until whoever she rang has hung up on her.
func _mae(t, job: Job, id: int, call_id: String) -> bool:
	var who := ""
	for m in job.def.mae_calls:
		if str(m.id) == call_id:
			who = str(m.who)
	var ch: Character = job.cast[who]
	var had := ch.turns.size()
	if not job.mae_call(id, call_id):
		return false
	return await t.until(func() -> bool: return ch.turns.size() > had and str(ch.turns.back().get("kind", "")) == "mae" and not ch.busy, Job.MAE_WAIT + 3.0)


## Puts a character where their routine sends them at once.
func _walk(job: Job, char_id: String, spot_name: String) -> bool:
	return JobHarness.walk(job, job.cast[char_id], spot_name)

#endregion


#region The count room

## The Gaming Board's auditor: Anton's told to expect one (by Mae, or a
## crewmate on the phone as the Board), so Marcus's call checks out; at the
## count room's buzzer Gloria asks Marcus, and lets them in for the count.
func _count_auditor(t, two: bool) -> void:
	var label := "count, the auditor%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineCountJob.new(), ["auditor", "player"] if two else ["auditor"])
	var c := job.crew_by_id(1)
	if two:
		t.check(await _ring(t, job, 2, "manager", "Caldera Gaming Board", "Caldera Gaming Board, compliance. One of our auditors will observe tonight's count. Please give them every help.") == "expect_inspector", "%s: Anton takes the Board's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "board"), "%s: Mae rings Anton as the Board" % label)
	t.check(job.flags.has("board_expected"), "%s: Anton expects an auditor" % label)
	t.check(await _say(t, job, 1, "marcus", "Evening. Martin Kessler, Caldera Gaming Board. I'm here to observe tonight's count.") == "call_manager", "%s: Marcus calls Anton" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("cleared"), 10.0), "%s: it checks out and Marcus lets them through" % label)
	t.check(str(c.flags.get("cleared", "")) == "board" and job.venue.doors.staff.is_open, "%s: as the Board's auditor, through the staff door" % label)
	JobHarness.stand_at(job, 1, "count_out")
	await t.frames(2)
	t.check(job.use(1, "door:count_room").contains("buzzer") and job.venue.doors.count_room.is_open, "%s: the buzzer brings Gloria to the door" % label)
	t.check(_walk(job, "gloria", "count_door"), "%s: Gloria comes to the door" % label)
	t.check(await _say(t, job, 1, "gloria", "Martin Kessler, Gaming Board. I'm here to observe the count.") == "ask_security", "%s: Gloria asks Marcus about them" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("in_count"), 10.0), "%s: Marcus vouches, and Gloria lets them in" % label)
	t.check(not job.flags.has("cam:1:corridor") and not c.held, "%s: the eye doesn't mind a cleared auditor" % label)
	JobHarness.stand_at(job, 1, "count_look")
	await JobHarness.clock_to(t, job, TidelineCountJob.DROP + 1)
	t.check(job.flags.has("count_on"), "%s: the drop comes in and the count starts" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("looked"), TidelineCountJob.LOOK_SECONDS + 3.0), "%s: they watch the count" % label)
	t.check(not c.held and not job.done, "%s: and nobody minds" % label)
	JobHarness.stand_at(job, 1, "staff_out")
	t.check(await _ends(t, job) == "look", "%s: back on the floor, it's a look inside (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_count_auditor(t) -> void:
	await _count_auditor(t, false)


func test_count_auditor_two(t) -> void:
	await _count_auditor(t, true)


## Pilar's new cleaner: she's short and glad of anyone (talked round, or
## told by Harbor Cleaning on the phone), and at a quarter past Gloria
## opens the count room for the cleaner.
func _count_cleaner(t, two: bool) -> void:
	var label := "count, the cleaner%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineCountJob.new(), ["cleaner", "player"] if two else ["cleaner"])
	var c := job.crew_by_id(1)
	if two:
		t.check(await _ring(t, job, 2, "housekeeping", "Harbor Cleaning", "Harbor Cleaning here. We found you a cleaner for the count room tonight after all.") == "expect_cleaner", "%s: Pilar takes Harbor's call" % label)
		job.hang_up(2)
		t.check(job.flags.has("cleaner_expected") and not job.crew_by_id(2).flags.has("cleaner"), "%s: she expects a cleaner, and hasn't hired the caller" % label)
		t.check(await _say(t, job, 1, "pilar", "Hi, Harbor Cleaning sent me.") == "none", "%s: Pilar can hardly believe it" % label)
	else:
		t.check(await _say(t, job, 1, "pilar", "Rough night? You look run off your feet.") == "none", "%s: Pilar's had a long week" % label)
	t.check(await _say(t, job, 1, "pilar", "I'm the cleaner Harbor Cleaning sent. Where do you want me?") == "hire_cleaner", "%s: Pilar hires them" % label)
	t.check(c.flags.has("cleaner") and job.venue.doors.staff.is_open, "%s: and buzzes the staff door open" % label)
	JobHarness.stand_at(job, 1, "count_out")
	await t.frames(3)
	t.check(not job.flags.has("cam:1:corridor"), "%s: a cleaner in the corridor is nothing to the eye" % label)
	await JobHarness.clock_to(t, job, TidelineCountJob.DROP + 1)
	await JobHarness.clock_to(t, job, TidelineCountJob.CLEAN + 0.5)
	t.check(job.flags.has("clean_window") and job.venue.doors.count_room.is_open, "%s: at a quarter past Gloria opens up for the cleaner" % label)
	JobHarness.stand_at(job, 1, "count_look")
	t.check(await t.until(func() -> bool: return c.flags.has("looked"), TidelineCountJob.LOOK_SECONDS + 3.0), "%s: they mop round the count" % label)
	t.check(not c.held, "%s: and nobody minds" % label)
	JobHarness.stand_at(job, 1, "staff_out")
	t.check(await _ends(t, job) == "look", "%s: out on the floor, it's a look inside (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_count_cleaner(t) -> void:
	await _count_cleaner(t, false)


func test_count_cleaner_two(t) -> void:
	await _count_cleaner(t, true)


## Halberd's relief for the drop: Wes has them on his log (Mae rang as
## Dispatch, or a crewmate did), so Marcus takes them on and walks the
## drop into the count room with them at eleven.
func _count_relief(t, two: bool) -> void:
	var label := "count, the relief%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineCountJob.new(), ["halberd_temp", "player"] if two else ["halberd_temp"])
	var c := job.crew_by_id(1)
	if two:
		t.check(await _ring(t, job, 2, "eye", "Halberd Dispatch", "Halberd Dispatch. We're sending a relief guard for tonight's drop. Put them on your log.") == "log_relief", "%s: Wes takes Dispatch's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "dispatch"), "%s: Mae rings Wes as Dispatch" % label)
	t.check(job.flags.has("relief_logged"), "%s: the relief's on Wes's log" % label)
	t.check(await _say(t, job, 1, "marcus", "Evening. Dispatch sent me as relief for the drop.") == "ask_surveillance", "%s: Marcus asks Wes" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("drop_temp"), 10.0), "%s: Wes has them on the log, and Marcus takes them on for the drop" % label)
	t.check(job.venue.doors.staff.is_open, "%s: through the staff door" % label)
	JobHarness.stand_at(job, 1, "count_out")
	await JobHarness.clock_to(t, job, TidelineCountJob.DROP + 0.5)
	t.check(job.venue.doors.count_room.is_open and job.flags.has("count_on"), "%s: at eleven the drop goes in" % label)
	JobHarness.stand_at(job, 1, "count_look")
	t.check(await t.until(func() -> bool: return c.flags.has("looked"), TidelineCountJob.LOOK_SECONDS + 3.0), "%s: they stand by the boxes for the count" % label)
	t.check(not c.held, "%s: and nobody minds" % label)
	JobHarness.stand_at(job, 1, "staff_out")
	t.check(await _ends(t, job) == "look", "%s: out on the floor, it's a look inside (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_count_relief(t) -> void:
	await _count_relief(t, false)


func test_count_relief_two(t) -> void:
	await _count_relief(t, true)


## Bea's codes: off shift at the bar she talks, and at twenty past the
## count room sits empty. In by the back door, with the cameras blind (the
## loop at the junction box, or a crewmate keeping Wes on the phone).
func _count_bea(t, two: bool) -> void:
	var label := "count, Bea's codes%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineCountJob.new(), ["player", "player"] if two else ["player"])
	var c := job.crew_by_id(1)
	var bea: Character = job.cast.bea
	await JobHarness.clock_to(t, job, TidelineCountJob.DROP + 1)
	t.check(_walk(job, "bea", "bea_bar"), "%s: Bea's at the bar after her shift" % label)
	t.check(await _say(t, job, 1, "bea", "Can I buy you a drink?") == "none" and bea.face_of(1).suspicion == 0, "%s: she'll have a margarita" % label)
	await _say(t, job, 1, "bea", "I love your earrings.")
	await _say(t, job, 1, "bea", "Cheers! What are you having next?")
	await _say(t, job, 1, "bea", "So what's the code on that count room door?")
	t.check(str(bea.turns.back().reply.say).contains(TidelineCast.COUNT_CODE), "%s: she gives up the count room's code (%s)" % [label, bea.turns.back().reply.say])
	await _say(t, job, 1, "bea", "And how do the staff get in from the alley?")
	t.check(str(bea.turns.back().reply.say).contains(TidelineCast.BACK_CODE), "%s: and the back door's (%s)" % [label, bea.turns.back().reply.say])
	await _say(t, job, 1, "bea", "When does the count room sit empty?")
	t.check(str(bea.turns.back().reply.say).contains("twenty past"), "%s: and when the count room's empty (%s)" % [label, bea.turns.back().reply.say])
	await JobHarness.clock_to(t, job, TidelineCountJob.RUN - 1)
	if two:
		t.check(await _ring(t, job, 2, "eye", "Withheld", "Hi Wes. Seen any good westerns lately?") == "none" and job.cast.wes.on_call == 2, "%s: a crewmate keeps Wes talking films" % label)
	else:
		JobHarness.stand_at(job, 1, "panel")
		t.check(job.use(1, "cam_panel").contains("loop") and job.tools_used == 1, "%s: a loop at the junction box blinds the eye" % label)
	t.check(not TidelineRules.watching(job), "%s: Wes isn't watching" % label)
	JobHarness.stand_at(job, 1, "back_out")
	t.check(job.keypad(1, TidelineCast.BACK_CODE, "back_pad") == "The lock clicks." and job.venue.doors.back.is_open, "%s: Bea's code opens the back door" % label)
	await JobHarness.clock_to(t, job, TidelineCountJob.RUN + 0.5)
	t.check(job.flags.has("room_empty"), "%s: at twenty past the count room empties" % label)
	t.check(_walk(job, "gloria", "cage_in") and _walk(job, "marcus", "cage_c"), "%s: Gloria and Marcus take the bags to the cage" % label)
	JobHarness.stand_at(job, 1, "count_out")
	t.check(job.keypad(1, TidelineCast.COUNT_CODE, "count_pad") == "The lock clicks." and job.venue.doors.count_room.is_open, "%s: Gloria's birthday opens the count room" % label)
	JobHarness.stand_at(job, 1, "count_look")
	await t.frames(3)
	t.check(job.use(1, "item:count_sheet") == "You take the count sheet." and job.holder("count_sheet") == c, "%s: the count sheet" % label)
	t.check(not c.held and not job.flags.has("cam:1:count_room") and not job.flags.has("cam:1:corridor"), "%s: and nobody saw a thing" % label)
	JobHarness.stand_at(job, 1, "count_out")
	t.check(job.use(1, "door:staff") == "You push the bar." and job.venue.doors.staff.is_open, "%s: out through the staff door's push bar" % label)
	JobHarness.stand_at(job, 1, "staff_out")
	t.check(await _ends(t, job) == "sheet", "%s: out on the floor with the sheet (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


## Stories that don't check out, the cameras, the office and the police.
func test_count_wrong(t) -> void:
	var job: Job = await _start(t, TidelineCountJob.new(), ["auditor", "halberd_temp"])
	var marcus: Character = job.cast.marcus
	t.check(await _say(t, job, 1, "marcus", "Evening. Caldera Gaming Board. I'm here to observe tonight's count.") == "call_manager", "count, wrong: Marcus calls Anton about the auditor")
	t.check(await t.until(func() -> bool: return marcus.face_of(1).checks.get("call_manager", "") == "bad" and not marcus.busy, 10.0), "count, wrong: nobody told Anton, so it doesn't check out")
	t.check(not job.crew_by_id(1).flags.has("cleared") and not job.venue.doors.staff.is_open and marcus.face_of(1).suspicion >= 2, "count, wrong: Marcus keeps the door shut, and he's wary")
	JobHarness.stand(job, 1, Vector3(5, 0, -6), Vector3(5, 0, -10))
	t.check(await _say(t, job, 2, "marcus", "Evening. Dispatch sent me as relief for the drop.") == "ask_surveillance", "count, wrong: Marcus asks Wes about the relief")
	t.check(await t.until(func() -> bool: return marcus.face_of(2).checks.get("ask_surveillance", "") == "bad" and not marcus.busy, 10.0), "count, wrong: nobody's on Wes's log")
	t.check(not job.crew_by_id(2).flags.has("drop_temp") and not job.venue.doors.staff.is_open, "count, wrong: no relief, no door")
	JobHarness.done(job)
	await t.frames(2)


func test_count_cameras(t) -> void:
	var job: Job = await _start(t, TidelineCountJob.new(), ["player"])
	var c := job.crew_by_id(1)
	var marcus: Character = job.cast.marcus
	var heat := job.heat.events
	JobHarness.stand_at(job, 1, "count_out")
	t.check(await t.until(func() -> bool: return job.flags.has("cam:1:corridor"), 2.0), "count, cameras: the eye sees a guest in the back corridor")
	t.check(marcus.post == "corridor_check" and job.heat.events > heat and job.cast.wes.face_of(1).suspicion >= 3, "count, cameras: Wes sends Marcus to look, and the place heats up")
	t.check(not c.held, "count, cameras: but nobody's held for the corridor")
	await JobHarness.clock_to(t, job, TidelineCountJob.RUN + 0.5)
	_walk(job, "gloria", "cage_in")
	_walk(job, "marcus", "cage_c")
	job.keypad(1, TidelineCast.COUNT_CODE, "count_pad")
	JobHarness.stand_at(job, 1, "count_look")
	t.check(await t.until(func() -> bool: return c.held, 4.0), "count, cameras: in the count room on camera, Wes calls it in and they're held")
	t.check(job.venue.doors.office.locked and job.cast.values().any(func(ch): return ch.minding), "count, cameras: in Halberd's office, minded")
	t.check(job.use(1, "door:office") != "" and job.keypad(1, TidelineCast.BACK_CODE, "back_pad") == "", "count, cameras: and going nowhere")
	await t.frames(2)
	job.minutes += Job.POLICE + 0.5
	t.check(await _ends(t, job) == "held", "count, cameras: the police come for the only one of the crew (%s)" % _outcome(job))
	JobHarness.done(job)
	await t.frames(2)


func test_count_lockdown(t) -> void:
	var job: Job = await _start(t, TidelineCountJob.new(), ["halberd_temp"])
	job.crew_by_id(1).flags["drop_temp"] = true
	await JobHarness.clock_to(t, job, TidelineCountJob.DROP + 0.5)
	t.check(job.flags.has("count_on") and job.venue.doors.count_room.is_open, "count, lockdown: the count's on")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	t.check(job.heat.level == Heat.LOCKDOWN, "count, lockdown: called in twice over is Lockdown")
	t.check(not job.flags.has("count_on") and not job.venue.doors.count_room.is_open and not job.venue.doors.staff.is_open, "count, lockdown: Gloria stops the count and the back's shut")
	t.check(job.keypad(1, TidelineCast.COUNT_CODE, "count_pad").contains("dead"), "count, lockdown: the keypads are dead")
	JobHarness.stand_at(job, 1, "count_look")
	await t.frames(30)
	t.check(not job.crew_by_id(1).flags.has("count_look"), "count, lockdown: nothing to see in a stopped count")
	JobHarness.done(job)
	await t.frames(2)


## The count room's own rules: the buzzer, push bars, the loop, the sheet
## under Gloria's eye, Bea on shift, and Mae keeping Wes busy.
func test_count_rules(t) -> void:
	var job: Job = await _start(t, TidelineCountJob.new(), ["player", "cleaner"])
	var c := job.crew_by_id(1)
	var def: TidelineCountJob = job.def
	JobHarness.stand_at(job, 1, "staff_out")
	t.check(job.use(1, "door:staff") == "It's locked. Marcus keeps this door.", "count, rules: the staff door's locked from the floor")
	JobHarness.stand_at(job, 1, "panel")
	t.check(def.prompt_for(c, "cam_panel") == "Loop the cameras" and job.use(1, "cam_panel").contains("loop"), "count, rules: the loop goes in")
	t.check(job.use(1, "cam_panel") == "The loop's already in." and not TidelineRules.watching(job), "count, rules: once")
	JobHarness.stand_at(job, 1, "count_out")
	t.check(def.prompt_for(c, "door:count_room") == "Press the buzzer", "count, rules: there's a buzzer by the count room")
	JobHarness.stand_at(job, 1, "count_look")
	await t.frames(1)
	t.check(def.prompt_for(c, "door:count_room") == "Push the bar" and job.use(1, "door:count_room") == "You push the bar." and job.venue.doors.count_room.is_open, "count, rules: the count room opens from inside")
	JobHarness.stand_at(job, 1, "staff_in")
	t.check(job.use(1, "door:staff") == "You push the bar." and job.venue.doors.staff.is_open, "count, rules: and so does the staff door")
	JobHarness.face(job, 1, "gloria")
	await t.frames(1)
	t.check(job.use(1, "item:count_sheet").begins_with("Not with Gloria"), "count, rules: nobody takes the sheet under Gloria's nose")
	_walk(job, "gloria", "cage_in")
	JobHarness.stand_at(job, 1, "count_out")
	await t.until(func() -> bool: return not job.venue.doors.count_room.is_open, 8.0)
	t.check(job.use(1, "door:count_room") == "You press the buzzer. Nobody comes.", "count, rules: nobody answers the buzzer with Gloria away from her table")
	t.check(not c.held and not job.flags.has("cam:1:corridor"), "count, rules: the eye saw none of it")
	JobHarness.stand_at(job, 1, "staff_out")
	job.minutes += TidelineRules.LOOP_MINUTES + 0.5
	await t.frames(2)
	t.check(TidelineRules.watching(job) and job.flags.has("loop_over") and job.use(1, "cam_panel").contains("won't take twice"), "count, rules: the loop runs out, and won't take twice")
	t.check(await _mae(t, job, 2, "footage") and not TidelineRules.watching(job), "count, rules: Mae has Wes pulling old footage")
	job.minutes = float(job.flags.wes_busy_until) + 0.5
	await t.frames(2)
	t.check(TidelineRules.watching(job), "count, rules: and he's back on his screens after")
	var bea: Character = job.cast.bea
	JobHarness.face(job, 2, "bea")
	for line in ["Can I buy you a drink?", "I love your earrings.", "Cheers!", "What's the code on the count room door?"]:
		await _say(t, job, 2, "bea", line)
	t.check(not str(bea.turns.back().reply.say).contains(TidelineCast.COUNT_CODE), "count, rules: Bea won't give a code on shift")
	JobHarness.done(job)
	await t.frames(2)


func test_count_bea(t) -> void:
	await _count_bea(t, false)


func test_count_bea_two(t) -> void:
	await _count_bea(t, true)

#endregion


#region The pit boss's favor

## Wes's camera on wheel two: the Gaming Board asks him to watch it (Mae,
## or a crewmate on the phone as the Board), the next spin with Tess
## dealing catches Pruitt, and the crew tells Augie it was them.
func _favor_camera(t, two: bool) -> void:
	var label := "favor, the camera%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineFavorJob.new(), ["player", "inspector"] if two else ["player"])
	if two:
		t.check(await _ring(t, job, 2, "eye", "Caldera Gaming Board", "Caldera Gaming Board. We've had a complaint about wheel two. Watch it tonight, please.") == "watch_wheel", "%s: Wes takes the Board's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "board"), "%s: Mae rings Wes as the Board" % label)
	t.check(job.flags.has("watch_wheel") and TidelineRules.watching(job), "%s: Wes has a camera on wheel two" % label)
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[0] + 0.2)
	t.check(str(job.flags.get("caught", "")) == "camera", "%s: the next spin, Pruitt's caught on tape" % label)
	t.check(job.cast.lyle.post == "kerb" and job.cast.tess.post == "staff_out", "%s: Pruitt's walked out, and Tess goes off the floor" % label)
	t.check(not job.flags.has("owed_at"), "%s: Augie doesn't know who to thank yet" % label)
	await _say(t, job, 1, "augie", "That camera on wheel two? That was us.")
	t.check(str(job.cast.augie.turns.back().reply.say).contains("owe you"), "%s: Augie owes them one (%s)" % [label, job.cast.augie.turns.back().reply.say])
	t.check(await _ends(t, job, TidelineFavorJob.OWED_PAUSE + 2.0) == "owed", "%s: Augie owes the crew (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_favor_camera(t) -> void:
	await _favor_camera(t, false)


func test_favor_camera_two(t) -> void:
	await _favor_camera(t, true)


## Tess on her break in the alley: frightened by the Board (Mae's call, or
## a crewmate playing the inspector) and talked round kindly, she goes and
## tells Augie everything.
func _favor_tess(t, two: bool) -> void:
	var label := "favor, Tess%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineFavorJob.new(), ["player", "inspector"] if two else ["player"])
	var tess: Character = job.cast.tess
	var who := 2 if two else 1
	if not two:
		t.check(await _mae(t, job, 1, "scare"), "%s: Mae rings Tess as the Board" % label)
		t.check(tess.face_of(1).suspicion <= 1, "%s: Tess is frightened, and ready to talk" % label)
	await JobHarness.clock_to(t, job, TidelineFavorJob.BREAK + 0.5)
	t.check(job.flags.get("tess_out", false) and _walk(job, "tess", "tess_smoke"), "%s: Tess goes out to the alley on her break" % label)
	if two:
		t.check(await _say(t, job, 2, "tess", "Caldera Gaming Board. They know about wheel two.") == "none", "%s: the inspector frightens Tess" % label)
		t.check(await _say(t, job, 2, "tess", "If there's something you want to tell your pit boss, tonight's the night. Tell Augie.") == "confess", "%s: and she'll tell Augie" % label)
	else:
		t.check(await _say(t, job, 1, "tess", "Are you all right? You look frightened.") == "none", "%s: a kind word" % label)
		t.check(await _say(t, job, 1, "tess", "Tell Augie. Come clean, before the Board does it for you.") == "confess", "%s: and she'll tell Augie" % label)
	t.check(job.flags.get("tess_confessing", 0) == who and tess.post == "pit_c", "%s: Tess walks to Augie" % label)
	t.check(_walk(job, "tess", "pit_c"), "%s: she gets to the pit" % label)
	t.check(await t.until(func() -> bool: return str(job.flags.get("caught", "")) == "tess", 2.0), "%s: she tells him everything, and Pruitt's out" % label)
	t.check(await _ends(t, job, TidelineFavorJob.OWED_PAUSE + 2.0) == "owed", "%s: Augie owes the crew (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_favor_tess(t) -> void:
	await _favor_tess(t, false)


func test_favor_tess_two(t) -> void:
	await _favor_tess(t, true)


## Hugo Marlowe saw Pruitt cheat on the Marlin: warmed up, he says so, and
## Augie checks with him and throws Pruitt out.
func _favor_hugo(t, two: bool) -> void:
	var label := "favor, Hugo%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineFavorJob.new(), ["player", "player"] if two else ["player"])
	var hugo: Character = job.cast.hugo
	var who := 2 if two else 1
	t.check(await _say(t, job, who, "hugo", "Is it true you sold the Marlin? Lovely yacht.") == "none", "%s: Hugo loves to talk boats" % label)
	await _say(t, job, who, "hugo", "What do you make of Lyle Pruitt?")
	await _say(t, job, who, "hugo", "Tell me about Pruitt and the Marlin's card game.")
	t.check(str(hugo.turns.back().reply.say).contains("sliding chips"), "%s: Hugo saw Pruitt cheat (%s)" % [label, hugo.turns.back().reply.say])
	JobHarness.stand(job, who, Vector3(-10, 0, -26), Vector3(-10, 0, -31))
	t.check(await _say(t, job, 1, "augie", "Hugo Marlowe saw Pruitt cheat on the Marlin's card game. Ask him.") == "ask_regular", "%s: Augie goes to ask Hugo" % label)
	t.check(await t.until(func() -> bool: return job.flags.has("caught"), 10.0), "%s: Hugo backs it up" % label)
	t.check(str(job.flags.caught) == "hugo" and job.cast.augie.face_of(1).checks.get("ask_regular", "") == "good", "%s: and Augie throws Pruitt out on a witness" % label)
	t.check(await _ends(t, job, TidelineFavorJob.OWED_PAUSE + 2.0) == "owed", "%s: Augie owes the crew (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_favor_hugo(t) -> void:
	await _favor_hugo(t, false)


func test_favor_hugo_two(t) -> void:
	await _favor_hugo(t, true)


## The relief croupier: Anton's been told a relief is coming (Mae, or a
## crewmate as Caldera Staffing), so Augie puts them on wheel two for Tess's
## break, and Pruitt tries it on with them.
func _favor_relief(t, two: bool) -> void:
	var label := "favor, the relief%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineFavorJob.new(), ["croupier", "player"] if two else ["croupier"])
	var c := job.crew_by_id(1)
	if two:
		t.check(await _ring(t, job, 2, "manager", "Caldera Staffing", "Caldera Staffing. Your relief croupier for wheel two is on the way.") == "expect_temp", "%s: Anton takes the agency's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "staffing"), "%s: Mae rings Anton as Caldera Staffing" % label)
	t.check(job.flags.has("relief_booked"), "%s: a relief is booked" % label)
	t.check(await _say(t, job, 1, "augie", "Evening. Caldera Staffing sent me as relief for wheel two.") == "call_manager", "%s: Augie checks with Anton" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("relief"), 10.0), "%s: it checks out, and Augie puts them on wheel two for the break" % label)
	await JobHarness.clock_to(t, job, TidelineFavorJob.BREAK + 0.5)
	_walk(job, "tess", "tess_smoke")
	JobHarness.stand_at(job, 1, "tess")
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[3] + 0.2)
	t.check(str(job.flags.get("caught", "")) == "relief", "%s: Pruitt tries it on with the new croupier and Augie sees it" % label)
	t.check(await _ends(t, job, TidelineFavorJob.OWED_PAUSE + 2.0) == "owed", "%s: Augie owes the crew (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


func test_favor_relief(t) -> void:
	await _favor_relief(t, false)


func test_favor_relief_two(t) -> void:
	await _favor_relief(t, true)


## Stories that don't check out, Tess with Pruitt watching, a catch nobody
## owns up to, and Pruitt cashing out.
func test_favor_wrong(t) -> void:
	var job: Job = await _start(t, TidelineFavorJob.new(), ["croupier", "player"])
	var augie: Character = job.cast.augie
	t.check(await _say(t, job, 1, "augie", "Evening. Caldera Staffing sent me as relief for wheel two.") == "call_manager", "favor, wrong: Augie checks the relief with Anton")
	t.check(await t.until(func() -> bool: return augie.face_of(1).checks.get("call_manager", "") == "bad" and not augie.busy, 10.0), "favor, wrong: Anton booked nobody")
	t.check(not job.crew_by_id(1).flags.has("relief"), "favor, wrong: so no wheel for them")
	JobHarness.stand(job, 1, Vector3(0, 0, -6), Vector3(0, 0, -10))
	t.check(await _say(t, job, 2, "augie", "Pruitt's cheating at wheel two. He slides chips.") == "none" and not job.flags.has("caught"), "favor, wrong: Augie can't act on a guess")
	t.check(await _say(t, job, 2, "augie", "Hugo Marlowe saw him do it on the Marlin.") == "ask_regular", "favor, wrong: he asks Hugo")
	t.check(await t.until(func() -> bool: return augie.face_of(2).checks.get("ask_regular", "") == "bad" and not augie.busy, 10.0), "favor, wrong: Hugo's never met them and won't be dragged in")
	t.check(not job.flags.has("caught"), "favor, wrong: Pruitt plays on")
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[0] + 0.2)
	t.check(not job.flags.has("caught"), "favor, wrong: with Tess dealing and nobody watching, Pruitt wins again")
	await JobHarness.clock_to(t, job, TidelineFavorJob.CASH_OUT + 0.2)
	t.check(job.cast.lyle.post == "kerb", "favor, wrong: Pruitt cashes out")
	await JobHarness.clock_to(t, job, job.def.end + 0.1)
	t.check(await _ends(t, job) == "late", "favor, wrong: and walks off with it (%s)" % _outcome(job))
	JobHarness.done(job)
	await t.frames(2)
	job = await _start(t, TidelineFavorJob.new(), ["player"])
	job.flags["watch_wheel"] = 1
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[0] + 0.2)
	t.check(str(job.flags.get("caught", "")) == "camera", "favor, wrong: caught on tape")
	await JobHarness.clock_to(t, job, job.def.end + 0.1)
	t.check(await _ends(t, job) == "caught", "favor, wrong: but nobody told Augie it was them (%s)" % _outcome(job))
	JobHarness.done(job)
	await t.frames(2)


## Pruitt's lucky spins, the camera blinded by a loop, and Augie before
## anything's happened.
func test_favor_rules(t) -> void:
	var job: Job = await _start(t, TidelineFavorJob.new(), ["player", "player"])
	var tess: Character = job.cast.tess
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[0] - 2)
	JobHarness.stand_at(job, 1, "panel")
	job.use(1, "cam_panel")
	job.flags["watch_wheel"] = 1
	await JobHarness.clock_to(t, job, TidelineFavorJob.SPINS[0] + 0.2)
	t.check(not job.flags.has("caught"), "favor, rules: a looped camera sees nothing at wheel two")
	job.flags.erase("watch_wheel")
	t.check(await _say(t, job, 1, "augie", "I'd say you owe me a favor.") == "none" and str(job.cast.augie.turns.back().reply.say).contains("Nobody owes"), "favor, rules: nobody's owed anything yet")
	for line in ["Are you all right?", "You look frightened.", "Tell Augie the truth."]:
		await _say(t, job, 2, "tess", line)
	t.check(not job.flags.has("tess_confessing") and job.flags.get("tess_later", 0) == 2 and tess.post == "tess", "favor, rules: Tess won't go to Augie with Pruitt watching")
	JobHarness.stand_at(job, 2, "bea_bar")
	JobHarness.stand_at(job, 1, "count_out")
	await t.frames(3)
	t.check(not job.flags.has("cam:1:corridor"), "favor, rules: the loop hides a guest in the back corridor")
	job.minutes += TidelineRules.LOOP_MINUTES
	t.check(await t.until(func() -> bool: return job.flags.has("cam:1:corridor"), 2.0), "favor, rules: till it runs out")
	JobHarness.stand_at(job, 1, "bea_bar")
	await JobHarness.clock_to(t, job, TidelineFavorJob.BREAK + 0.5)
	t.check(job.flags.get("tess_confessing", 0) == 2 and tess.post == "pit_c", "favor, rules: on her break she goes to Augie instead")
	_walk(job, "tess", "pit_c")
	t.check(await _ends(t, job, TidelineFavorJob.OWED_PAUSE + 2.0) == "owed" and str(job.flags.get("caught", "")) == "tess", "favor, rules: and tells him everything (%s)" % _outcome(job))
	JobHarness.done(job)
	await t.frames(2)

#endregion
