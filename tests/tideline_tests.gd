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
	"gloria": "count_room", "count_look": "count_room", "dmitri": "eye", "eye_in": "eye", "held": "office",
	"office_in": "office", "lockers": "staff_room", "staff_room_in": "staff_room", "bea": "cage", "imani": "cage",
	"horace_window": "cage", "horace_listen": "cage", "imani_vault": "cage", "horace_vault": "cage", "vault_out": "cage",
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


## Halberd's relief for the drop: Dmitri has them on his log (Mae rang as
## Dispatch, or a crewmate did), so Marcus takes them on and walks the
## drop into the count room with them at eleven.
func _count_relief(t, two: bool) -> void:
	var label := "count, the relief%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineCountJob.new(), ["halberd_temp", "player"] if two else ["halberd_temp"])
	var c := job.crew_by_id(1)
	if two:
		t.check(await _ring(t, job, 2, "eye", "Halberd Dispatch", "Halberd Dispatch. We're sending a relief guard for tonight's drop. Put them on your log.") == "log_relief", "%s: Dmitri takes Dispatch's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "dispatch"), "%s: Mae rings Dmitri as Dispatch" % label)
	t.check(job.flags.has("relief_logged"), "%s: the relief's on Dmitri's log" % label)
	t.check(await _say(t, job, 1, "marcus", "Evening. Dispatch sent me as relief for the drop.") == "ask_surveillance", "%s: Marcus asks Dmitri" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("drop_temp"), 10.0), "%s: Dmitri has them on the log, and Marcus takes them on for the drop" % label)
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
## loop at the junction box, or a crewmate keeping Dmitri on the phone).
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
		t.check(await _ring(t, job, 2, "eye", "Withheld", "Hi Dmitri. Seen any good westerns lately?") == "none" and job.cast.dmitri.on_call == 2, "%s: a crewmate keeps Dmitri talking films" % label)
	else:
		JobHarness.stand_at(job, 1, "panel")
		t.check(job.use(1, "cam_panel").contains("loop") and job.tools_used == 1, "%s: a loop at the junction box blinds the eye" % label)
	t.check(not TidelineRules.watching(job), "%s: Dmitri isn't watching" % label)
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
	t.check(await _say(t, job, 2, "marcus", "Evening. Dispatch sent me as relief for the drop.") == "ask_surveillance", "count, wrong: Marcus asks Dmitri about the relief")
	t.check(await t.until(func() -> bool: return marcus.face_of(2).checks.get("ask_surveillance", "") == "bad" and not marcus.busy, 10.0), "count, wrong: nobody's on Dmitri's log")
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
	t.check(marcus.post == "corridor_check" and job.heat.events > heat and job.cast.dmitri.face_of(1).suspicion >= 3, "count, cameras: Dmitri sends Marcus to look, and the place heats up")
	t.check(not c.held, "count, cameras: but nobody's held for the corridor")
	await JobHarness.clock_to(t, job, TidelineCountJob.RUN + 0.5)
	_walk(job, "gloria", "cage_in")
	_walk(job, "marcus", "cage_c")
	job.keypad(1, TidelineCast.COUNT_CODE, "count_pad")
	JobHarness.stand_at(job, 1, "count_look")
	t.check(await t.until(func() -> bool: return c.held, 4.0), "count, cameras: in the count room on camera, Dmitri calls it in and they're held")
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
## under Gloria's eye, Bea on shift, and Mae keeping Dmitri busy.
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
	t.check(await _mae(t, job, 2, "footage") and not TidelineRules.watching(job), "count, rules: Mae has Dmitri pulling old footage")
	job.minutes = float(job.flags.dmitri_busy_until) + 0.5
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

## Dmitri's camera on wheel two: the Gaming Board asks him to watch it (Mae,
## or a crewmate on the phone as the Board), the next spin with Tess
## dealing catches Pruitt, and the crew tells Augie it was them.
func _favor_camera(t, two: bool) -> void:
	var label := "favor, the camera%s" % (" with two" if two else "")
	var job: Job = await _start(t, TidelineFavorJob.new(), ["player", "inspector"] if two else ["player"])
	if two:
		t.check(await _ring(t, job, 2, "eye", "Caldera Gaming Board", "Caldera Gaming Board. We've had a complaint about wheel two. Watch it tonight, please.") == "watch_wheel", "%s: Dmitri takes the Board's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "board"), "%s: Mae rings Dmitri as the Board" % label)
	t.check(job.flags.has("watch_wheel") and TidelineRules.watching(job), "%s: Dmitri has a camera on wheel two" % label)
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


#region The vault

## A vault job, with the crew owed Augie's favor or not.
func _vault(t, covers: Array, owed := true) -> Job:
	var def := TidelineVaultJob.new()
	def.owed = owed
	return await _start(t, def, covers)


## Horace has said yes to a release: both keys, the Rose from its table and
## through the cage's middle window to crew member `id`, who walks it out
## the front. Checks each step under `label`.
func _released(t, job: Job, id: int, label: String) -> void:
	t.check(str(job.flags.get("release", "")) == "keys" and job.cast.horace.post == "horace_vault", "%s: Horace goes to open the vault" % label)
	JobHarness.stand_at(job, id, "window_2")
	_walk(job, "horace", "horace_vault")
	_walk(job, "imani", "imani_vault")
	t.check(await t.until(func() -> bool: return str(job.flags.get("release", "")) == "fetch", 2.0), "%s: both keys turn" % label)
	_walk(job, "horace", "rose_table")
	t.check(await t.until(func() -> bool: return str(job.flags.get("release", "")) == "window", 2.0), "%s: Horace takes the Rose from its table" % label)
	_walk(job, "horace", "horace_window")
	_walk(job, "imani", "imani")
	t.check(await t.until(func() -> bool: return job.holder("rose") == job.crew_by_id(id), 2.0), "%s: and passes it through the window" % label)
	t.check(not job.flags.has("vault_open") and job.cast.horace.post == "horace", "%s: Horace goes back to his table" % label)
	JobHarness.stand_at(job, id, "crew_0")
	t.check(await _ends(t, job) == "out", "%s: out the front with the Rose (%s)" % [label, _outcome(job)])


## Larkspur's courier: Anton's told the buyer's collecting (Mae, or a
## crewmate on the phone as Larkspur), so Horace's call checks out.
func _vault_courier(t, two: bool) -> void:
	var label := "vault, the courier%s" % (" with two" if two else "")
	var job: Job = await _vault(t, ["courier", "player"] if two else ["courier"])
	var horace: Character = job.cast.horace
	if two:
		t.check(await _ring(t, job, 2, "manager", "Larkspur Holdings", "Larkspur Holdings, for Mr Varga. Our courier will collect the Rose tonight.") == "expect_courier", "%s: Anton takes Larkspur's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "buyer"), "%s: Mae rings Anton as Larkspur" % label)
	t.check(job.flags.has("courier_expected"), "%s: Anton expects the courier" % label)
	if two:
		JobHarness.face(job, 1, "horace")
		job.show_papers(1, horace)
		t.check(await t.until(func() -> bool: return horace.face_of(1).checks.has("call_manager"), 2.0), "%s: the release order sends Horace to Anton" % label)
	else:
		t.check(await _say(t, job, 1, "horace", "Mr Bell? Peter Wren, from Larkspur Holdings. I'm here to collect the Rose.") == "call_manager", "%s: Horace calls Anton" % label)
	t.check(await t.until(func() -> bool: return job.flags.has("release"), 10.0), "%s: it checks out" % label)
	await _released(t, job, 1, label)
	JobHarness.done(job)
	await t.frames(2)


func test_vault_courier(t) -> void:
	await _vault_courier(t, false)


func test_vault_courier_two(t) -> void:
	await _vault_courier(t, true)


## Halberd's transfer team: Marcus has heard from Dispatch (Mae, or a
## crewmate on the phone as Dispatch), and Horace asks Marcus.
func _vault_transfer(t, two: bool) -> void:
	var label := "vault, the transfer%s" % (" with two" if two else "")
	var job: Job = await _vault(t, ["halberd_escort", "player"] if two else ["halberd_escort"])
	if two:
		t.check(await _ring(t, job, 2, "halberd", "Halberd Dispatch", "Halberd Dispatch. Transfer team coming for one item from the vault tonight.") == "expect_transfer", "%s: Marcus takes Dispatch's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "dispatch"), "%s: Mae rings Marcus as Dispatch" % label)
	t.check(job.flags.has("transfer_expected"), "%s: Marcus expects a transfer" % label)
	t.check(await _say(t, job, 1, "horace", "Mr Bell. Halberd transfer team. We're moving the Rose tonight.") == "ask_security", "%s: Horace asks Marcus" % label)
	t.check(await t.until(func() -> bool: return job.flags.has("release"), 10.0), "%s: it checks out" % label)
	await _released(t, job, 1, label)
	JobHarness.done(job)
	await t.frames(2)


func test_vault_transfer(t) -> void:
	await _vault_transfer(t, false)


func test_vault_transfer_two(t) -> void:
	await _vault_transfer(t, true)


## Augie's favor: he owes the crew for Pruitt, vouches for them to Horace,
## and Horace takes his oldest friend's word.
func _vault_favor(t, two: bool) -> void:
	var label := "vault, Augie's favor%s" % (" with two" if two else "")
	var job: Job = await _vault(t, ["player", "courier"] if two else ["player"])
	var who := 2 if two else 1
	t.check(await _say(t, job, who, "augie", "Evening, Augie. Remember us?") == "none", "%s: Augie remembers the crew" % label)
	t.check(await _say(t, job, who, "augie", "You said you owed us one. Put in a word with Horace?") == "vouch", "%s: and vouches for them" % label)
	t.check(job.flags.has("vouched"), "%s: Augie's told Horace they're friends" % label)
	JobHarness.stand(job, who, Vector3(0, 0, -6), Vector3(0, 0, -10))
	t.check(await _say(t, job, 1, "horace", "Augie sent me. He said you'd help us.") == "ask_pit", "%s: Horace asks Augie" % label)
	t.check(await t.until(func() -> bool: return job.flags.has("release"), 10.0), "%s: and that's good enough for him" % label)
	await _released(t, job, 1, label)
	JobHarness.done(job)
	await t.frames(2)


func test_vault_favor(t) -> void:
	await _vault_favor(t, false)


func test_vault_favor_two(t) -> void:
	await _vault_favor(t, true)


## The float: hired as Imani's cage temp, in the cage when the vault opens at
## half past eleven, with Horace's song sending him to the lounge and the
## eye blind (Mae has Dmitri pulling footage, or a crewmate loops the cameras).
func _vault_float(t, two: bool) -> void:
	var label := "vault, the float%s" % (" with two" if two else "")
	var job: Job = await _vault(t, ["cage_temp", "player"] if two else ["cage_temp"])
	var c := job.crew_by_id(1)
	var helper := 2 if two else 1
	if two:
		t.check(await _ring(t, job, 2, "manager", "Caldera Staffing", "Caldera Staffing. Your cage temp for tonight is on the way.") == "expect_temp", "%s: Anton takes the agency's call" % label)
		job.hang_up(2)
	else:
		t.check(await _mae(t, job, 1, "staffing"), "%s: Mae rings Anton as Caldera Staffing" % label)
	t.check(job.flags.has("temp_expected"), "%s: a cage temp is booked" % label)
	t.check(await _say(t, job, helper, "marisol", "Could you sing Moon over the Harbor? It's for Horace.") == "take_request" and job.flags.has("song"), "%s: Marisol will sing Horace's song" % label)
	t.check(await _say(t, job, 1, "imani", "Hi, Caldera Staffing sent me. You're short tonight?") == "call_manager", "%s: Imani calls Anton" % label)
	t.check(await t.until(func() -> bool: return c.flags.has("cage_temp"), 10.0), "%s: Imani takes them on" % label)
	t.check(job.venue.doors.staff.is_open and job.venue.doors.cage.is_open, "%s: through the staff door and into the cage" % label)
	JobHarness.stand_at(job, 1, "cage_in")
	await t.frames(3)
	t.check(not c.held and not job.flags.has("cam:1:cage"), "%s: a temp in the cage is nothing to anyone" % label)
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT - 3)
	if two:
		JobHarness.stand_at(job, 2, "panel")
		t.check(job.use(2, "cam_panel").contains("loop"), "%s: a crewmate loops the cameras" % label)
	else:
		t.check(await _mae(t, job, 1, "footage"), "%s: Mae has Dmitri pulling old footage" % label)
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT - 2 + 0.1)
	_walk(job, "horace", "horace_vault")
	_walk(job, "imani", "imani_vault")
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT + 0.1)
	t.check(await t.until(func() -> bool: return job.flags.has("vault_open"), 2.0) and job.venue.doors.vault.is_open, "%s: both keys, and the vault's open for the float" % label)
	await JobHarness.clock_to(t, job, TidelineVaultJob.TRAYS + 0.1)
	_walk(job, "imani", "imani")
	await JobHarness.clock_to(t, job, TidelineVaultJob.SET + 0.1)
	t.check(job.flags.has("horace_away") and job.cast.horace.post == "horace", "%s: Marisol sings Eleanor's song and Horace goes to listen" % label)
	_walk(job, "horace", "horace")
	JobHarness.stand_at(job, 1, "vault_in")
	await t.frames(2)
	t.check(job.use(1, "item:rose") == "You take the Rose." and job.holder("rose") == c, "%s: the Rose" % label)
	t.check(not c.held and job.cast.dmitri.face_of(1).suspicion < JobRules.ALARM, "%s: and nobody saw a thing" % label)
	JobHarness.stand_at(job, 1, "cage_in")
	t.check(job.use(1, "door:cage") in ["You push the bar.", ""] and job.venue.doors.cage.is_open, "%s: out through the cage door" % label)
	JobHarness.stand_at(job, 1, "staff_in")
	t.check(job.use(1, "door:staff") in ["You push the bar.", ""] and job.venue.doors.staff.is_open, "%s: and the staff door" % label)
	JobHarness.stand_at(job, 1, "crew_0")
	t.check(await _ends(t, job) == "out", "%s: out the front with the Rose (%s)" % [label, _outcome(job)])
	JobHarness.done(job)
	await t.frames(2)


## Stories that don't check out, a favor nobody owes, Horace tired of
## waiting at the window, and the time lock.
func test_vault_wrong(t) -> void:
	var job: Job = await _vault(t, ["courier", "player"], false)
	var horace: Character = job.cast.horace
	t.check(await _say(t, job, 1, "horace", "Mr Bell? Peter Wren, from Larkspur Holdings. I'm here to collect the Rose.") == "call_manager", "vault, wrong: Horace calls Anton")
	t.check(await t.until(func() -> bool: return horace.face_of(1).checks.get("call_manager", "") == "bad" and not horace.busy, 10.0), "vault, wrong: Larkspur never rang Anton")
	t.check(not job.flags.has("release") and horace.face_of(1).suspicion >= 2, "vault, wrong: no release, and Horace is wary")
	t.check(await _say(t, job, 1, "horace", "Where do you keep your key?") == "none" and horace.face_of(1).suspicion >= 4, "vault, wrong: asking about his key makes it worse")
	await _say(t, job, 2, "augie", "Evening, Augie. Remember us?")
	await _say(t, job, 2, "augie", "You said you owed us one.")
	t.check(not job.flags.has("vouched"), "vault, wrong: Augie owes nobody anything if the crew never did him the favor")
	JobHarness.done(job)
	await t.frames(2)
	job = await _vault(t, ["courier"])
	job.flags["courier_expected"] = true
	await _say(t, job, 1, "horace", "Mr Bell? Peter Wren, from Larkspur Holdings. I'm here to collect the Rose.")
	await t.until(func() -> bool: return job.flags.has("release"), 10.0)
	_walk(job, "horace", "horace_vault")
	_walk(job, "imani", "imani_vault")
	await t.frames(2)
	_walk(job, "horace", "rose_table")
	await t.frames(2)
	_walk(job, "horace", "horace_window")
	await t.frames(2)
	t.check(str(job.flags.get("release", "")) == "window" and job.holder("rose") == null, "vault, wrong: Horace waits at the window with the Rose")
	job.flags["window_until"] = job.elapsed
	await t.frames(2)
	t.check(str(job.items.rose.at) == "vault_table" and str(job.flags.release) == "", "vault, wrong: with nobody there, he puts it back")
	await JobHarness.clock_to(t, job, job.def.end + 0.1)
	t.check(await _ends(t, job) == "late", "vault, wrong: the time lock shuts the vault with the Rose inside (%s)" % _outcome(job))
	JobHarness.done(job)
	await t.frames(2)


## The float gone wrong: no song, the vault's camera, and the Rose missed
## when the float's done.
func test_vault_float_wrong(t) -> void:
	var job: Job = await _vault(t, ["cage_temp"])
	var c := job.crew_by_id(1)
	c.flags["cage_temp"] = true
	JobHarness.stand_at(job, 1, "cage_in")
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT - 2 + 0.1)
	_walk(job, "horace", "horace_vault")
	_walk(job, "imani", "imani_vault")
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT + 0.1)
	await t.until(func() -> bool: return job.flags.has("vault_open"), 2.0)
	# The vault's door takes a moment to swing clear of the doorway.
	await t.get_tree().create_timer(HotelDoor.SECONDS + 0.2).timeout
	await JobHarness.clock_to(t, job, TidelineVaultJob.TRAYS + 0.1)
	_walk(job, "imani", "imani")
	await JobHarness.clock_to(t, job, TidelineVaultJob.SET + 0.1)
	t.check(job.flags.has("vault_open") and not job.flags.has("horace_away") and job.cast.horace.post == "vault_out", "vault, float: with no request, Horace minds the vault's doorway")
	_walk(job, "horace", "vault_out")
	JobHarness.stand_at(job, 1, "vault_in")
	await t.frames(1)
	var said := job.use(1, "item:rose")
	t.check(said.begins_with("Not with"), "vault, float: nobody takes the Rose under Horace's nose (%s, held %s, at %s)" % [said, c.held, job.venue.zone_at(c.position())])
	JobHarness.stand_at(job, 1, "panel")
	job.use(1, "cam_panel")
	JobHarness.stand_at(job, 1, "vault_in")
	job.cast.horace.global_position = job.spot("horace").origin
	await t.frames(1)
	t.check(job.use(1, "item:rose") == "You take the Rose.", "vault, float: with Horace away and the loop in, the Rose")
	await JobHarness.clock_to(t, job, TidelineVaultJob.FLOAT_DONE + 0.1)
	t.check(job.flags.has("missing") and job.heat.level == Heat.LOCKDOWN, "vault, float: still inside when the float's done, Imani finds it gone: Lockdown")
	t.check(job.venue.doors.front.locked and not job.venue.doors.cage.is_open, "vault, float: the front's locked and the cage shut")
	t.check(await t.until(func() -> bool: return c.held, 4.0), "vault, float: the only stranger in the cage is held")
	t.check(str(job.items.rose.at) == "vault_table", "vault, float: and the Rose goes back")
	JobHarness.done(job)
	await t.frames(2)
	job = await _vault(t, ["cage_temp"])
	c = job.crew_by_id(1)
	c.flags["cage_temp"] = true
	job.flags["vault_open"] = true
	job.set_door("vault", true)
	JobHarness.stand_at(job, 1, "vault_in")
	await t.frames(1)
	t.check(job.use(1, "item:rose").contains("camera saw"), "vault, float: the vault's camera sees the Rose taken")
	t.check(await t.until(func() -> bool: return c.held, 4.0), "vault, float: Dmitri calls it in")
	t.check(await t.until(func() -> bool: return str(job.items.rose.at) == "vault_table", 2.0), "vault, float: and the Rose goes back")
	JobHarness.done(job)
	await t.frames(2)


## The request card, Lockdown and Mae's calls.
func test_vault_rules(t) -> void:
	var job: Job = await _vault(t, ["player"])
	t.check(job.def.prompt_for(job.crew_by_id(1), "request") == "Leave a request for Marisol" and job.use(1, "request").contains(TidelineCast.SONG) and job.flags.has("song"), "vault, rules: a request on Marisol's stand")
	t.check(job.use(1, "request") == "Your request's already on the stand.", "vault, rules: once")
	for call in ["buyer", "dispatch", "staffing"]:
		t.check(await _mae(t, job, 1, call), "vault, rules: Mae makes her %s call" % call)
	t.check(job.flags.has("courier_expected") and job.flags.has("transfer_expected") and job.flags.has("temp_expected"), "vault, rules: Anton expects a courier and a temp, and Marcus a transfer")
	t.check(not job.mae_call(1, "buyer"), "vault, rules: each of Mae's calls is made once")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	t.check(job.heat.level == Heat.LOCKDOWN and job.venue.doors.front.locked, "vault, rules: at Lockdown Halberd locks the front")
	JobHarness.done(job)
	await t.frames(2)


func test_vault_float(t) -> void:
	await _vault_float(t, false)


func test_vault_float_two(t) -> void:
	await _vault_float(t, true)

#endregion


#region The scripted replies

## Each night's key words, and what they get from whoever hears them.
const SCRIPTED := [
	["count", "marcus", "I'm from the Gaming Board, here to observe the count.", "call_manager"],
	["count", "marcus", "Halberd dispatch sent me as relief for the drop.", "ask_surveillance"],
	["count", "marcus", "I'm Pilar's new cleaner.", "ask_housekeeping"],
	["count", "gloria", "Gaming Board. I'm here to observe.", "ask_security"],
	["count", "gloria", "I'm the cleaner. Pilar sent me.", "ask_housekeeping"],
	["count", "pilar", "Harbor Cleaning sent me.", "hire_cleaner"],
	["count", "pilar", "Harbor Cleaning here. We found you someone.", "expect_cleaner"],
	["count", "dmitri", "Halberd Dispatch. Put a relief on your log.", "log_relief"],
	["count", "anton", "The Gaming Board is sending an auditor.", "expect_inspector"],
	["count", "marisol", "Could you sing Moon over the Harbor?", "take_request"],
	["favor", "augie", "Hugo Marlowe saw him cheat on the Marlin.", "ask_regular"],
	["favor", "augie", "Caldera Staffing sent me as the relief croupier.", "call_manager"],
	["favor", "dmitri", "Gaming Board. We've had a complaint about wheel two.", "watch_wheel"],
	["favor", "anton", "Caldera Staffing. Your relief croupier is coming.", "expect_temp"],
	["favor", "tess", "You should tell Augie. Come clean.", "confess"],
	["vault", "horace", "Larkspur's courier, here to collect.", "call_manager"],
	["vault", "horace", "Halberd transfer team, here to move the Rose.", "ask_security"],
	["vault", "horace", "Augie sent me. He owes us.", "ask_pit"],
	["vault", "augie", "You owe us a favor.", "vouch"],
	["vault", "imani", "Caldera Staffing sent me. I'm your temp.", "call_manager"],
	["vault", "marcus", "Halberd Dispatch. A transfer from the vault tonight.", "expect_transfer"],
	["vault", "anton", "Larkspur Holdings. Our courier will collect the Rose.", "expect_courier"],
	["vault", "anton", "Caldera Staffing. A cashier temp for Imani.", "expect_temp"],
	["vault", "marisol", "Could you sing Moon over the Harbor for Horace?", "take_request"],
]


func test_scripted(t) -> void:
	for row in SCRIPTED:
		var s := TidelineCast.sheet(row[1], row[0])
		var face := JobRules.new_face(s)
		face["turns"] = 2
		face["suspicion"] = 1
		var r := ScriptedBrain.reply(s, face, {"kind": "line", "heard": row[2]})
		t.check(str(r.do) == row[3], "tideline, scripted: %s on the %s night hears \"%s\" and does %s (%s)" % [row[1], row[0], row[2], row[3], r.do])
		t.check(row[3] in s.actions, "tideline, scripted: %s may %s on the %s night" % [row[1], row[3], row[0]])
	var bea := TidelineCast.sheet("bea", "count")
	var face := JobRules.new_face(bea)
	face["secrets"] = [0, 1, 2]
	for row in [["What's the code on the count room?", TidelineCast.COUNT_CODE], ["How do you get in from the alley?", TidelineCast.BACK_CODE], ["When's the count room empty?", "twenty past"]]:
		t.check(str(ScriptedBrain.reply(bea, face, {"kind": "line", "heard": row[0]}).say).contains(row[1]), "tideline, scripted: Bea, warmed up, says %s" % row[1])
	var hugo := TidelineCast.sheet("hugo", "favor")
	face = JobRules.new_face(hugo)
	face["secrets"] = [0]
	t.check(str(ScriptedBrain.reply(hugo, face, {"kind": "line", "heard": "Ever seen Pruitt at the Marlin's card game?"}).say).contains("sliding chips"), "tideline, scripted: Hugo, warmed up, saw Pruitt cheat")
	for night in ["count", "favor", "vault"]:
		for s in TidelineCast.all(night):
			var r := ScriptedBrain.reply(s, JobRules.new_face(s), {"kind": "line", "heard": "Good evening."})
			t.check(str(r.say) != "" and str(r.do) == "none", "tideline, scripted: %s says good evening back on the %s night" % [s.id, night])

#endregion
