extends RefCounted
## The Meridian's jobs 2 and 3: the guest list on the wedding night and the
## display case at the Rose's press call. Each job's data and routines, every
## way through played alone (Mae making the calls) and with two crew (a
## crewmate ringing ahead on the phone), the ways they go wrong, the jobs'
## own rules, and the scripted replies each way needs.


#region Helpers

## Says a line to a character, face to face, and waits for the answer.
func _say_to(t, job: Job, id: int, char_id: String, text: String) -> bool:
	JobHarness.face(job, id, char_id)
	var before: int = job.cast[char_id].turns.size()
	JobHarness.say(job, id, text)
	return await _turned(t, job, char_id, before)


## Waits until a character has taken a turn since they'd taken `before`, and
## is done thinking. A scripted turn is often over before the line that
## started it returns, so count from before it.
func _turned(t, job: Job, char_id: String, before: int, seconds := 6.0) -> bool:
	var ch: Character = job.cast[char_id]
	return await t.until(func() -> bool: return ch.turns.size() > before and not ch.busy, seconds)


## Asks Auntie Mae for one of her calls and waits for it to go through.
func _mae(t, job: Job, call_id: String) -> bool:
	if not job.mae_call(1, call_id):
		return false
	return await t.until(func(): return job.flags.has("called:" + call_id), 8.0)


## A crewmate rings a number showing `as_who`, says a line once they've
## picked up, and hangs up.
func _ring(t, job: Job, id: int, number: String, as_who: String, text: String) -> bool:
	var who := ""
	for n in job.def.phone:
		if str(n.id) == number:
			who = str(n.who)
	var before: int = job.cast[who].turns.size()
	if job.ring(id, number, as_who) != "":
		return false
	await _turned(t, job, who, before)
	before = job.cast[who].turns.size()
	JobHarness.say(job, id, text)
	var ok: bool = await _turned(t, job, who, before)
	await t.frames(2)
	job.hang_up(id)
	return ok


## Puts a crew member on one of the venue's walking points, looking at another.
func _at(job: Job, id: int, point: String, toward: String) -> void:
	JobHarness.stand(job, id, job.venue.points[point], job.venue.points[toward])


## Walks a crew member out of the front doors.
func _out_front(job: Job, id: int) -> void:
	_at(job, id, "front_out", "front_in")
	JobHarness.stand(job, id, job.venue.points.front_out + Vector3(0, 0, 1.5), job.venue.points.front_out + Vector3(0, 0, 4))


## Collects the job's report when it ends.
func _ends(job: Job) -> Array:
	var out: Array = []
	job.ended.connect(func(r): out.append(r))
	return out


func _won(t, ends: Array, outcome: String) -> bool:
	await t.until(func(): return not ends.is_empty(), 3.0)
	return not ends.is_empty() and str(ends[0].outcome) == outcome and bool(ends[0].win) == (outcome in ["out", "swapped"])

#endregion

#region Both jobs

func test_data(t) -> void:
	VenueChecks.job_data(t, MeridianListJob.new())
	await VenueChecks.routines(t, MeridianListJob.new())
	VenueChecks.job_data(t, MeridianCaseJob.new())
	await VenueChecks.routines(t, MeridianCaseJob.new())
	var ids := MeridianCast.all().map(func(s): return s.id)
	t.check(ids == MeridianCast.IDS and ids.size() == 8, "the gala's cast is still its eight")
	var voices := {}
	for id in MeridianCast.IDS + ["gus", "pippa", "priya", "wren", "ingrid", "rafe"]:
		var s := MeridianCast.sheet(id)
		t.check(s != null and s.id == id, "%s has a sheet of their own" % id)
		if s == null:
			continue
		t.check(not voices.has(s.voice), "%s's voice is theirs alone at the Meridian (%s)" % [id, s.voice])
		voices[s.voice] = id
		for a in s.actions:
			t.check(CharacterSheet.ACTIONS.has(a), "%s's usual sheet uses only the usual actions (%s), so other venues can borrow them" % [id, a])
		t.check(s.manner != "" and not s.knows.is_empty() and not s.never.is_empty() and not s.checks.is_empty() and not s.weaknesses.is_empty(), "%s has a manner, knows, nevers, checks and weaknesses" % id)
	t.check(voices.size() == 14, "fourteen people at the Meridian")
	for sheets in [MeridianCast.wedding(), MeridianCast.press_morning()]:
		for s in sheets:
			t.check(not s.routine.is_empty() and s.post != "" and s.situation != MeridianCast.SITUATION, "%s has that night's post, routine and situation" % s.id)
			for c in s.checks_with:
				t.check(str(s.checks_with[c]) in sheets.map(func(x): return x.id), "%s checks with someone who's there (%s)" % [s.id, s.checks_with[c]])


func test_scripted(t) -> void:
	var list := MeridianListJob.new()
	var case := MeridianCaseJob.new()
	var face := {"suspicion": 1, "turns": 1, "believes": [], "checks": {}, "papers": "", "opened": [], "secrets": []}
	var two := face.duplicate(true)
	two.turns = 2
	var cases := [
		[list, "dana", "Good evening. I'm from Lindqvist & Rowe, the auction house.", face, "call_manager"],
		[list, "okafor", "Good evening. I'm bidding at the Halvorsens' auction.", face, "ask_reception"],
		[list, "gus", "Caldera Building Services, about the air conditioning in Mr Okafor's office.", face, "call_manager"],
		[list, "okafor", "Mr Halvorsen is asking for you at the bar.", face, "none"],
		[list, "okafor", "Mr Halvorsen is asking for you at the bar.", two, "go_to_halvorsen"],
		[list, "benny", "Could you ring the manager? I want to complain.", face, "none"],
		[list, "benny", "Could you ring the manager? I want to complain.", two, "send_for_okafor"],
		[list, "pippa", "I'm with Lindqvist & Rowe, the auction house.", face, "call_manager"],
		[case, "teo", "Morning. Caldera Courier, I'm the photographer.", face, "ask_reception"],
		[case, "teo", "Brightwater Mutual, the insurer. I'm the assessor.", face, "call_manager"],
		[case, "priya", "I need the stage clear for the light.", face, "ask_reception"],
		[case, "wren", "Brightwater Mutual. I'm here for the condition check.", face, "ask_halberd"],
		[case, "marcus", "Caldera Staffing sent me for the press breakfast.", face, "ask_reception"],
		[case, "laurent", "Caldera Staffing sent me. Where do you want me?", face, "none"],
		[case, "laurent", "Caldera Staffing sent me. Where do you want me?", two, "put_to_work"],
	]
	for c in cases:
		var def: JobDef = c[0]
		var sheet := def.sheet(str(c[1]))
		var r := ScriptedBrain.reply(sheet, c[3], {"kind": "line", "heard": c[2]})
		t.check(r.do == c[4] and r.say != "", "%s, told \"%s\", does %s (%s: %s)" % [c[1], c[2], c[4], r.do, r.say])
	# A good check gets each one's opening.
	for c in [[list, "dana", "print_copy"], [list, "okafor", "invite_in"], [list, "gus", "give_key"],
			[case, "teo", "let_through"], [case, "priya", "clear_stage"], [case, "wren", "condition_check"], [case, "marcus", "let_through"]]:
		var def: JobDef = c[0]
		var r := ScriptedBrain.reply(def.sheet(str(c[1])), face, {"kind": "answer", "verdict": "good"})
		t.check(r.do == c[2], "a story that checks out gets %s from %s (%s)" % [c[2], c[1], r.do])
	# Rafe knows the Courier's people; a freelancer gets by.
	var rafe := case.sheet("rafe")
	t.check(ScriptedBrain.reply(rafe, face, {"kind": "line", "heard": "I'm the Courier's photographer."}).suspicion == 3, "Rafe doesn't know the Courier's new photographer")
	t.check(ScriptedBrain.reply(rafe, face, {"kind": "line", "heard": "Freelance photographer, for the Courier."}).suspicion == 0, "but a freelancer he can believe")
	# The Rose is what everyone talks about at its own press call.
	var wren := case.sheet("wren")
	t.check(not ScriptedBrain._hot(" so that's the rose. what a diamond. ", wren), "at the press call, nobody looks up at the Rose")
	t.check(ScriptedBrain._hot(" so that's the rose. ", list.sheet("dana")), "on the wedding night they do")
	t.check(ScriptedBrain._hot(" so that's the rose. ", MeridianCast.dana()), "and at the gala")
	t.check(ScriptedBrain._hot(" it's a fake case. ", wren), "and fake still is")
	t.check(ScriptedBrain.reply(wren, face, {"kind": "overheard", "heard": "The Rose is a beautiful diamond."}).suspicion == 1, "overhearing it, Wren doesn't stir")

#endregion

#region The guest list

func test_list_auction_alone(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["auction"])
	await t.frames(2)
	var ends := _ends(job)
	var dana: Character = job.cast.dana
	t.check(await _mae(t, job, "auction"), "Mae rings Okafor as the auction house")
	t.check(await _say_to(t, job, 1, "dana", "Good evening. Paul Ashby, from Lindqvist & Rowe, the auction house."), "Dana answers")
	t.check(await t.until(func(): return "list_copy" in job.crew_by_id(1).items, 10.0), "she rings Okafor, it checks out, and she prints a copy (%s)" % str(dana.face_of(1).checks))
	t.check(dana.face_of(1).checks.get("call_manager", "") == "good", "on Okafor's word")
	t.check(not job.done, "the job's not done inside the hotel")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "out of the front doors with the copy, the job comes off")
	JobHarness.done(job)
	await t.frames(2)


func test_list_auction_crew(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["auction", "collector"])
	await t.frames(2)
	var ends := _ends(job)
	t.check(await _ring(t, job, 2, "manager", "Lindqvist & Rowe", "Good evening, Lindqvist and Rowe. Our associate will collect a copy of the guest list from reception tonight."), "a crewmate rings Okafor as the auction house")
	t.check(await _say_to(t, job, 1, "dana", "Good evening. I'm from Lindqvist & Rowe, here for the copy of the list."), "Dana answers")
	t.check(await t.until(func(): return "list_copy" in job.crew_by_id(1).items, 10.0), "Okafor remembers the call, and Dana prints the copy")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "and out it goes")
	JobHarness.done(job)
	await t.frames(2)


func test_list_auction_unbacked(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["auction"])
	await t.frames(2)
	var dana: Character = job.cast.dana
	await _say_to(t, job, 1, "dana", "Good evening. I'm from Lindqvist & Rowe, the auction house.")
	t.check(await t.until(func(): return dana.face_of(1).checks.get("call_manager", "") == "bad", 10.0), "with nobody ringing ahead, Okafor's never heard of it")
	await t.until(func(): return not dana.busy and dana.turns.size() >= 3, 5.0)
	t.check(not "list_copy" in job.crew_by_id(1).items and dana.suspicion_of(1) >= 2, "no copy, and Dana's wary")
	await _say_to(t, job, 1, "dana", "Could you print it anyway? Just a copy.")
	t.check(not "list_copy" in job.crew_by_id(1).items, "asking again gets nowhere: she's already checked")
	JobHarness.done(job)
	await t.frames(2)


func test_list_collector_alone(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["collector"])
	await t.frames(2)
	var ends := _ends(job)
	var ok: Character = job.cast.okafor
	t.check(await _mae(t, job, "vip"), "Mae rings Dana as the Halvorsen Foundation")
	t.check(await _say_to(t, job, 1, "okafor", "Good evening, Mr Okafor. Anton Sorel. I'm bidding at the Halvorsens' auction on the Marlin."), "Okafor answers")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("invited"), 10.0), "Dana backs the story, and Okafor invites the bidder to his office")
	t.check(ok.post == "okafor_office" and job.venue.doors.manager.is_open, "he heads there, and his door's open for them")
	JobHarness.walk(job, ok, "okafor_office")
	_at(job, 1, "manager_c", "okafor_office")
	job.set_door("manager", false)
	await t.frames(2)
	t.check(job.use(1, "item:guest_list") == "Not with Mr Okafor right there.", "with Okafor at his desk, the list stays put")
	t.check(job.use(1, "door:manager") == "" and job.venue.doors.manager.is_open, "from inside, the office door opens")
	job.set_door("manager", false)
	t.check(await _mae(t, job, "away"), "Mae rings Okafor from Mr Halvorsen's office")
	t.check(await t.until(func(): return ok.post == "okafor_bar", 4.0), "and he hurries down to the bar")
	JobHarness.walk(job, ok, "okafor_bar")
	await t.frames(2)
	t.check(job.use(1, "item:guest_list").begins_with("You take"), "alone in the office, the guest list comes away")
	t.check(job.heat.events < Heat.KEYPAD_SEEN, "and nobody saw it go")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "out of the front doors with the folder, the job comes off")
	JobHarness.done(job)
	await t.frames(2)


func test_list_collector_crew(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["collector", "auction"])
	await t.frames(2)
	var ends := _ends(job)
	var ok: Character = job.cast.okafor
	t.check(await _ring(t, job, 2, "reception", "Halvorsen Foundation", "Good evening, the Halvorsen Foundation. One of our bidders is calling on Mr Okafor tonight."), "a crewmate rings Dana as the Foundation")
	await _say_to(t, job, 1, "okafor", "Good evening. I'm bidding at the auction on the Marlin, and I'd love a word.")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("invited"), 10.0), "Dana backs the story, and Okafor invites the bidder in")
	JobHarness.walk(job, ok, "okafor_office")
	_at(job, 1, "manager_c", "okafor_office")
	job.set_door("manager", false)
	# The crewmate has Benny call Okafor down to the bar.
	JobHarness.face(job, 2, "benny")
	await _say_to(t, job, 2, "benny", "Evening. Lovely bar. A gin, please, and keep the change.")
	await _say_to(t, job, 2, "benny", "Could you ring the manager? I want to complain about the wedding party.")
	t.check(JobHarness.last_do(job, "benny") == "send_for_okafor", "Benny rings Okafor about trouble at the bar")
	t.check(ok.post == "okafor_bar", "and Okafor goes down")
	JobHarness.walk(job, ok, "okafor_bar")
	await t.frames(2)
	t.check(job.use(1, "item:guest_list").begins_with("You take"), "the bidder takes the list from the empty office")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "and walks out with it")
	JobHarness.done(job)
	await t.frames(2)


func test_list_facilities_alone(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["facilities"])
	await t.frames(2)
	var ends := _ends(job)
	t.check(job.use(1, "door:manager") == "Mr Okafor's office. It's locked." and not job.venue.doors.manager.is_open, "Okafor's office is locked")
	t.check(await _mae(t, job, "ac"), "Mae rings Okafor as Building Services")
	t.check(await _say_to(t, job, 1, "gus", "Evening. Caldera Building Services, about the air conditioning in Mr Okafor's office."), "Gus answers")
	t.check(await t.until(func(): return "office_key" in job.crew_by_id(1).items, 10.0), "he rings Okafor, it checks out, and he hands over the key")
	t.check(job.def.allowed_back(job, job.crew_by_id(1)), "with the key, the engineer belongs in the back")
	_at(job, 1, "manager_out", "manager_in")
	t.check(job.use(1, "door:manager") == "" and job.venue.doors.manager.is_open, "the key opens Okafor's door")
	_at(job, 1, "manager_c", "okafor_office")
	job.set_door("manager", false)
	await t.frames(2)
	t.check(job.use(1, "item:guest_list").begins_with("You take"), "with Okafor in the lobby, the list is the engineer's")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "out the front with it, the job comes off")
	JobHarness.done(job)
	await t.frames(2)


func test_list_facilities_crew(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["facilities", "auction"])
	await t.frames(2)
	var ends := _ends(job)
	var ok: Character = job.cast.okafor
	t.check(await _ring(t, job, 2, "manager", "Caldera Building Services", "Evening, Caldera Building Services. Our engineer can come tonight for your air conditioning."), "a crewmate rings Okafor as Building Services")
	await _say_to(t, job, 1, "gus", "Evening. I'm the engineer for the air conditioning in Mr Okafor's office.")
	t.check(await t.until(func(): return "office_key" in job.crew_by_id(1).items, 10.0), "Okafor remembers the call, and Gus hands over the key")
	# Okafor's at his desk until the speeches.
	await JobHarness.clock_to(t, job, MeridianListJob.OFFICE)
	JobHarness.walk(job, ok, "okafor_office")
	_at(job, 1, "manager_c", "okafor_office")
	await t.frames(2)
	t.check(job.use(1, "item:guest_list") == "Not with Mr Okafor right there.", "while Okafor's in, the list stays put")
	await JobHarness.clock_to(t, job, MeridianListJob.SPEECHES)
	t.check(ok.post == "okafor_stage", "at a quarter to ten he goes to give his toast")
	JobHarness.walk(job, ok, "okafor_stage")
	job.set_door("manager", false)
	await t.frames(2)
	t.check(job.use(1, "item:guest_list").begins_with("You take"), "and the engineer takes the list")
	_out_front(job, 1)
	t.check(await _won(t, ends, "out"), "out the front with it")
	JobHarness.done(job)
	await t.frames(2)


func test_list_night(t) -> void:
	var job := JobHarness.start(t, MeridianListJob.new(), ["facilities"])
	await t.frames(2)
	var ends := _ends(job)
	var ok: Character = job.cast.okafor
	# The list goes while Okafor's out; he comes back and finds it gone.
	job.give_item(1, "office_key")
	_at(job, 1, "manager_c", "okafor_office")
	t.check(job.use(1, "item:guest_list").begins_with("You take"), "the list is taken")
	_at(job, 1, "lobby_c", "lobby_s")
	await JobHarness.clock_to(t, job, MeridianListJob.OFFICE)
	JobHarness.walk(job, ok, "okafor_office")
	t.check(await t.until(func(): return job.flags.has("alarm"), 2.0), "Okafor finds his desk bare and raises the alarm")
	await t.frames(2)
	t.check(job.heat.level >= Heat.ALERT, "and the hotel's on alert (%s)" % Heat.name_of(job.heat.level))
	t.check(job.cast.teo.post == "front_watch", "Teo goes to watch the front doors")
	JobHarness.face(job, 1, "dana", 1.6)
	t.check(await t.until(func(): return job.crew_by_id(1).held, 8.0), "staff who see the green folder now know what it is, and call it in")
	t.check(not "guest_list" in job.crew_by_id(1).items and str(job.items.guest_list.at) == "okafor_desk", "Halberd takes it back to Okafor's desk")
	JobHarness.done(job)
	await t.frames(2)
	# He locks it away at ten past ten, and the night ends with nothing.
	job = JobHarness.start(t, MeridianListJob.new(), ["auction"])
	await t.frames(2)
	ends = _ends(job)
	ok = job.cast.okafor
	await JobHarness.clock_to(t, job, MeridianListJob.LOCK_UP)
	JobHarness.walk(job, ok, "okafor_office")
	t.check(await t.until(func(): return job.flags.has("locked_away"), 2.0), "at ten past ten Okafor locks the list in his safe")
	t.check(str(job.items.guest_list.at) == "" and not job.flags.has("alarm"), "it's gone from the desk, and nobody's alarmed")
	await JobHarness.clock_to(t, job, job.def.end)
	t.check(await _won(t, ends, "late"), "the night ends with nothing")
	JobHarness.done(job)
	await t.frames(2)
	# Lockdown shuts Okafor's office.
	job = JobHarness.start(t, MeridianListJob.new(), ["facilities"])
	await t.frames(2)
	job.give_item(1, "office_key")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	_at(job, 1, "manager_out", "manager_in")
	t.check(job.heat.level == Heat.LOCKDOWN and job.use(1, "door:manager").contains("locked down") and not job.venue.doors.manager.is_open, "at Lockdown even the key won't open Okafor's office")
	_at(job, 1, "manager_c", "manager_in")
	t.check(job.use(1, "door:manager") == "", "but from inside it still opens")
	JobHarness.done(job)
	await t.frames(2)

#endregion

#region The display case

func test_case_press_alone(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["press"])
	await t.frames(2)
	var ends := _ends(job)
	var c := job.crew_by_id(1)
	t.check("mae_case" in c.items and "press_pass" in c.items, "the photographer carries Mae's copy in, and a press pass")
	t.check(job.use(1, "door:ballroom") != "" and not job.venue.doors.ballroom.is_open, "the ballroom's Teo's to open")
	t.check(await _mae(t, job, "press"), "Mae rings Dana as the Courier's picture desk")
	await _say_to(t, job, 1, "teo", "Morning. Jonah Pike, Caldera Courier. I'm the photographer.")
	t.check(await t.until(func(): return job.venue.doors.ballroom.is_open, 10.0), "Teo checks the press list and lets the photographer in")
	await _say_to(t, job, 1, "priya", "Morning! Could I have the stage clear for two minutes? The light's perfect.")
	t.check(await t.until(func(): return job.flags.has("clear_until"), 10.0), "Priya checks with Dana and clears the stage")
	t.check(job.cast.wren.post == "wren_lobby" and job.cast.priya.post == "priya_lobby", "she and Wren step out to the lobby")
	JobHarness.walk(job, job.cast.wren, "wren_lobby")
	JobHarness.walk(job, job.cast.priya, "priya_lobby")
	job.set_door("ballroom", false)
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap"), "the photographer swaps the cases")
	t.check("rose_case" in c.items and not "mae_case" in c.items and str(job.items.mae_case.at) == "plinth_copy", "Mae's copy on the stand, the Rose in hand")
	t.check(not c.held and job.heat.events < Heat.CAUGHT, "and nobody saw")
	t.check(job.use(1, "door:ballroom") == "" and job.venue.doors.ballroom.is_open, "from inside, the ballroom doors open")
	_out_front(job, 1)
	t.check(await _won(t, ends, "swapped"), "out of the front doors with the Rose, the job comes off")
	JobHarness.done(job)
	await t.frames(2)


func test_case_press_crew(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["press", "catering"])
	await t.frames(2)
	var ends := _ends(job)
	t.check(not "mae_case" in job.crew_by_id(2).items, "one copy, with the photographer")
	t.check(await _ring(t, job, 2, "reception", "Caldera Courier", "Morning, the Courier's picture desk. We're sending a photographer to the press call."), "a crewmate rings Dana as the Courier")
	await _say_to(t, job, 1, "teo", "Morning. Caldera Courier, I'm the photographer.")
	t.check(await t.until(func(): return job.venue.doors.ballroom.is_open, 10.0), "Teo checks the press list and lets them in")
	await _say_to(t, job, 1, "priya", "I'll need the stage clear for the light. Front page.")
	t.check(await t.until(func(): return job.flags.has("clear_until"), 10.0), "and Priya clears the stage")
	JobHarness.walk(job, job.cast.wren, "wren_lobby")
	JobHarness.walk(job, job.cast.priya, "priya_lobby")
	job.set_door("ballroom", false)
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap"), "the cases are swapped")
	_out_front(job, 1)
	t.check(await _won(t, ends, "swapped"), "and the Rose walks out of the front doors")
	JobHarness.done(job)
	await t.frames(2)


func test_case_catering_alone(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["catering"])
	await t.frames(3)
	var ends := _ends(job)
	var c := job.crew_by_id(1)
	t.check(job.venue.zone_at(c.position()) == "outside" and "mae_case" in c.items, "catering starts in the loading bay, with Mae's copy")
	t.check(await _mae(t, job, "temp"), "Mae rings reception as the agency")
	await _say_to(t, job, 1, "marcus", "Morning. Caldera Staffing sent me for the press breakfast.")
	t.check(await t.until(func(): return job.venue.doors.service.is_open, 10.0), "Marcus checks with Dana and opens the service door")
	await _say_to(t, job, 1, "laurent", "Caldera Staffing sent me. Where do you want me, chef?")
	await _say_to(t, job, 1, "laurent", "Caldera Staffing, the extra pair of hands. Point me at a tray.")
	t.check(c.flags.has("hired") and c.outfit == "waiter_jacket", "Laurent puts them in a white jacket")
	t.check(job.use(1, "door:pass") == "" and job.venue.doors.pass.is_open, "and the pass opens for a waiter")
	await JobHarness.clock_to(t, job, MeridianCaseJob.SIGNING)
	t.check(job.cast.wren.post == "wren_lobby" and job.cast.priya.post == "priya_lobby", "at five past ten Wren and Priya go out to sign the papers")
	JobHarness.walk(job, job.cast.wren, "wren_lobby")
	JobHarness.walk(job, job.cast.priya, "priya_lobby")
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap") and not c.held, "the waiter swaps the cases on the empty stage")
	t.check(job.use(1, "trolley").begins_with("You tuck"), "and hides the Rose on the breakfast cart")
	t.check(await _won(t, ends, "swapped"), "for Mae's people to collect: the job comes off")
	JobHarness.done(job)
	await t.frames(2)


func test_case_catering_crew(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["catering", "catering"])
	await t.frames(3)
	var ends := _ends(job)
	var c := job.crew_by_id(1)
	t.check(await _ring(t, job, 2, "reception", "Caldera Staffing", "Morning, Caldera Staffing. We're sending one more pair of hands for the press breakfast."), "a crewmate rings Dana as the agency")
	await _say_to(t, job, 1, "marcus", "Morning. The agency sent me, Caldera Staffing.")
	t.check(await t.until(func(): return job.venue.doors.service.is_open, 10.0), "Dana backs the story and Marcus lets them through")
	await _say_to(t, job, 1, "laurent", "Morning, chef. Caldera Staffing sent me.")
	await _say_to(t, job, 1, "laurent", "Yes, Caldera Staffing. Where do you want me?")
	t.check(c.flags.has("hired"), "Laurent takes them on")
	await JobHarness.clock_to(t, job, MeridianCaseJob.SIGNING)
	JobHarness.walk(job, job.cast.wren, "wren_lobby")
	JobHarness.walk(job, job.cast.priya, "priya_lobby")
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap"), "the swap, while the stage is empty")
	# Out the back this time, through the loading bay.
	_at(job, 1, "crew_bay", "smoke")
	t.check(await _won(t, ends, "swapped"), "and out through the loading bay with the Rose")
	JobHarness.done(job)
	await t.frames(2)


func test_case_assessor_alone(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["assessor"])
	await t.frames(2)
	var ends := _ends(job)
	var c := job.crew_by_id(1)
	t.check("mae_case" in c.items and "insurer_letter" in c.items, "the assessor carries Mae's copy, and a letter")
	t.check(await _mae(t, job, "assessor"), "Mae rings Ingrid as Brightwater Mutual")
	await _say_to(t, job, 1, "teo", "Good morning. Graham Voss, Brightwater Mutual, the insurer.")
	t.check(await t.until(func(): return job.venue.doors.ballroom.is_open, 10.0), "Teo radios Ingrid, and lets the assessor in")
	await _say_to(t, job, 1, "wren", "Good morning. Brightwater Mutual. I'm here for the condition check before it travels.")
	t.check(await t.until(func(): return c.flags.has("inspecting"), 10.0), "Wren checks with Ingrid and lets the assessor handle the case")
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap") and not c.held, "in front of everyone, the inspection is the swap")
	for id in ["wren", "priya"]:
		t.check(job.cast[id].suspicion_of(1) <= 2, "%s saw an inspection, nothing more" % id)
	_out_front(job, 1)
	t.check(await _won(t, ends, "swapped"), "the assessor walks out with the Rose")
	JobHarness.done(job)
	await t.frames(2)


func test_case_assessor_crew(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["assessor", "press"])
	await t.frames(2)
	var ends := _ends(job)
	var c := job.crew_by_id(1)
	t.check("mae_case" in job.crew_by_id(2).items, "with a photographer along, the camera case carries Mae's copy")
	# Hand the copy over for this test: the assessor does the swap.
	job.give_item(1, "mae_case")
	t.check(await _ring(t, job, 2, "halberd", "Brightwater Mutual", "Good morning, Brightwater Mutual. Our assessor's coming to look over the Rose's case before it travels."), "a crewmate rings Ingrid as the insurer")
	await _say_to(t, job, 1, "teo", "Good morning. Brightwater Mutual, I'm the assessor.")
	t.check(await t.until(func(): return job.venue.doors.ballroom.is_open, 10.0), "Ingrid backs the story and Teo lets them in")
	await _say_to(t, job, 1, "wren", "Brightwater Mutual. The condition check, as the policy says.")
	t.check(await t.until(func(): return c.flags.has("inspecting"), 10.0), "and Wren lets them handle the case")
	_at(job, 1, "stage_front", "ballroom_c")
	await t.frames(2)
	t.check(job.use(1, "item:rose_case").begins_with("You swap"), "the swap")
	_out_front(job, 1)
	t.check(await _won(t, ends, "swapped"), "and out")
	JobHarness.done(job)
	await t.frames(2)


func test_case_wrong(t) -> void:
	# Swapped in front of Wren: called in, and the Rose goes back on its stand.
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["press"])
	await t.frames(2)
	var c := job.crew_by_id(1)
	_at(job, 1, "stage_front", "ballroom_c")
	t.check(job.use(1, "item:rose_case") != "", "a swap in plain view")
	t.check(await t.until(func(): return c.held, 8.0), "Wren calls it in, and the photographer's held")
	await t.frames(2)
	t.check(str(job.items.rose_case.at) == "plinth" and not job.flags.has("swapped"), "and the Rose stays on its stand")
	t.check(job.heat.level >= Heat.ALERT, "the hotel's on alert")
	JobHarness.done(job)
	await t.frames(2)
	# Rafe knows the Courier: put him off and Priya hears about it.
	job = JobHarness.start(t, MeridianCaseJob.new(), ["press"])
	await t.frames(2)
	t.check(await _mae(t, job, "press"), "Mae rings ahead")
	await _say_to(t, job, 1, "rafe", "Morning. I'm the Courier's photographer.")
	t.check(await t.until(func(): return job.crew_by_id(1).flags.has("rafe_told"), 3.0), "Rafe's never heard of them, and tells Priya")
	await _say_to(t, job, 1, "priya", "Could I have the stage clear for the light?")
	await t.until(func(): return job.cast.priya.face_of(1).checks.get("ask_reception", "") == "good", 10.0)
	await t.until(func(): return not job.cast.priya.busy and job.cast.priya.turns.size() >= 2, 5.0)
	await t.frames(5)
	t.check(not job.flags.has("clear_until"), "so even with Dana's word, Priya won't clear the stage")
	JobHarness.done(job)
	await t.frames(2)
	# An assessor nobody rang ahead for.
	job = JobHarness.start(t, MeridianCaseJob.new(), ["assessor"])
	await t.frames(2)
	await _say_to(t, job, 1, "teo", "Good morning. Brightwater Mutual, the insurer.")
	t.check(await t.until(func(): return job.cast.teo.face_of(1).checks.get("call_manager", "") == "bad", 10.0), "Ingrid's had no call from Brightwater")
	await t.frames(10)
	t.check(not job.venue.doors.ballroom.is_open, "and Teo keeps the doors shut")
	JobHarness.done(job)
	await t.frames(2)
	# The couriers come for the real thing.
	job = JobHarness.start(t, MeridianCaseJob.new(), ["press"])
	await t.frames(2)
	var ends := _ends(job)
	await JobHarness.clock_to(t, job, MeridianCaseJob.COURIERS)
	t.check(await _won(t, ends, "gone"), "at twenty-six past ten Halberd takes the Rose in its own case")
	JobHarness.done(job)
	await t.frames(2)
	# Swapped, but still inside when the van's gone.
	job = JobHarness.start(t, MeridianCaseJob.new(), ["assessor"])
	await t.frames(2)
	ends = _ends(job)
	job.crew_by_id(1).flags["inspecting"] = true
	_at(job, 1, "stage_front", "ballroom_c")
	job.use(1, "item:rose_case")
	await JobHarness.clock_to(t, job, MeridianCaseJob.COURIERS)
	t.check(not job.done and str(job.items.mae_case.at) == "", "the couriers take Mae's case, and the job goes on")
	await JobHarness.clock_to(t, job, job.def.end)
	t.check(await _won(t, ends, "inside"), "but the Rose never left the hotel")
	JobHarness.done(job)
	await t.frames(2)


func test_case_rules(t) -> void:
	var job := JobHarness.start(t, MeridianCaseJob.new(), ["catering", "press"])
	await t.frames(3)
	t.check(job.venue.zone_at(job.crew_by_id(1).position()) == "outside", "catering comes in the back way")
	t.check(job.use(1, "item:rose_case").contains("You need Mae's copy"), "without Mae's copy, the case stays")
	t.check(job.use(1, "trolley").begins_with("The breakfast cart"), "the cart's only a cart until you've something to hide")
	t.check(job.use(2, "door:pass") != "" and not job.venue.doors.pass.is_open, "the pass is for waiters")
	await JobHarness.clock_to(t, job, MeridianCaseJob.SIGNING)
	JobHarness.walk(job, job.cast.wren, "wren_lobby")
	await JobHarness.clock_to(t, job, MeridianCaseJob.BACK)
	t.check(job.cast.wren.post == "wren" and job.cast.ingrid.post == "ingrid_stage", "at a quarter past, Wren's back by the case with Ingrid")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	_at(job, 2, "ballroom_in", "ballroom_out")
	t.check(job.heat.level == Heat.LOCKDOWN and job.use(2, "door:ballroom").contains("locked down"), "at Lockdown the ballroom's shut, even from inside")
	JobHarness.done(job)
	await t.frames(2)

#endregion
