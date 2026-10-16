extends RefCounted
## The gala's pieces: the rules round a character's reply, heat, the prompt,
## the scripted brain, covers and the crew, and the whole job in a bare
## stand-in hotel ([StubHotel]) with scripted brains: who's spoken to, papers,
## checks over the radio, doors, the keypad, the jacket, heat, the office,
## the clock and the report.


## A crew member's body for tests: where they are and which way they look.
class Body:
	extends Node3D
	var look := Vector3.FORWARD

	func mouth_position() -> Vector3:
		return global_position + Vector3(0, 1.6, 0)

	func look_dir() -> Vector3:
		return look


func test_rules(t) -> void:
	var teo := MeridianCast.sheet("teo")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var f := JobRules.new_face(teo)
	t.check(f.suspicion == 1 and f.turns == 0 and f.checks.is_empty(), "a new face starts at the character's usual")
	t.check(JobRules.new_face(teo, Heat.CURIOUS).suspicion == 2, "when the venue's curious, new faces start a step warier")
	t.check(JobRules.new_face(teo, Heat.LOCKDOWN).suspicion == 3, "at Lockdown a Halberd guard trusts nobody new")
	var r := JobRules.resolve({"say": "Go in.", "do": "let_through", "believes": ["a guest"], "suspicion": 0}, f, teo, {}, rng)
	t.check(r.do == "none" and r.vetoed == "let_through" and r.say in teo.hesitations, "nobody's let in on their first line")
	f.turns = 1
	f.checks = {"ask_reception": "good"}
	r = JobRules.resolve({"say": "Go in.", "do": "let_through", "believes": ["on the list"], "suspicion": 1}, f, teo, {}, rng)
	t.check(r.do == "let_through" and r.ended == "open", "a story a colleague vouched for opens the door sooner")
	f = JobRules.new_face(teo)
	f.turns = 3
	r = JobRules.resolve({"say": "Go in.", "do": "let_through", "believes": [], "suspicion": 1}, f, teo, {}, rng)
	t.check(r.vetoed == "let_through", "nor without believing something about them")
	r = JobRules.resolve({"say": "Go in.", "do": "let_through", "believes": ["a guest"], "suspicion": 1}, f, teo, {"heat": Heat.LOCKDOWN}, rng)
	t.check(r.vetoed == "let_through", "at Lockdown the doors stay shut")
	r = JobRules.resolve({"say": "Go in.", "do": "let_through", "believes": ["a guest"], "suspicion": 1}, f, teo, {"shut": true}, rng)
	t.check(r.vetoed == "let_through", "nor once they're shut for the speech")
	r = JobRules.resolve({"say": "Go.", "do": "release", "believes": ["a mistake"], "suspicion": 1}, f, teo, {"someone_held": true}, rng)
	t.check(r.vetoed == "release" and r.say == "Go.", "only whoever minds the office lets anyone go, and a silent veto keeps the line")
	r = JobRules.resolve({"say": "Go.", "do": "release", "believes": ["a mistake"], "suspicion": 2}, f, teo, {"someone_held": true, "minding": true}, rng)
	t.check(r.do == "release", "the one minding it can, a little more easily")
	r = JobRules.resolve({"say": "Hm.", "do": "radio_security", "believes": [], "suspicion": 3}, f, teo, {}, rng)
	t.check(r.do == "none" and r.vetoed == "radio_security", "no call to security under 4")
	f.suspicion = 4
	r = JobRules.resolve({"say": "Right.", "do": "none", "believes": [], "suspicion": 5}, f, teo, {}, rng)
	t.check(r.do == "radio_security" and r.ended == "caught" and r.tone == "alarmed", "5 calls it in whatever was meant")
	f = JobRules.new_face(teo)
	r = JobRules.resolve({"say": "One moment.", "do": "ask_reception", "believes": [], "suspicion": 1}, f, teo, {}, rng)
	JobRules.apply(r, f)
	t.check(r.do == "ask_reception" and f.checks.has("ask_reception"), "a check goes ahead and is remembered")
	r = JobRules.resolve({"say": "One moment.", "do": "ask_reception", "believes": [], "suspicion": 1}, f, teo, {}, rng)
	t.check(r.vetoed == "ask_reception", "but only once")
	var celeste := MeridianCast.sheet("celeste")
	r = JobRules.resolve({"say": "Hm.", "do": "ask_reception", "believes": [], "suspicion": 1}, JobRules.new_face(celeste), celeste, {}, rng)
	t.check(r.do == "none", "a guest can't call reception")
	f = JobRules.new_face(teo)
	f.suspicion = 3
	t.check(not JobRules.drift(f, teo, 60.0) and JobRules.drift(f, teo, 31.0) and f.suspicion == 2, "suspicion drifts down a step after ninety quiet seconds")
	JobRules.nudge(f, 2)
	t.check(f.suspicion == 4 and f.quiet == 0.0, "a nudge raises it and resets the quiet")
	var benny := MeridianCast.sheet("benny")
	f = JobRules.new_face(benny)
	f.turns = 2
	f.suspicion = 1
	var opened := JobRules.newly_open(f, benny)
	t.check(opened == [0], "Benny tells the first secret to someone he's warmed to (%s)" % str(opened))
	f.turns = 4
	f.suspicion = 0
	t.check(JobRules.newly_open(f, benny) == [1] and JobRules.newly_open(f, benny).is_empty(), "the kitchen code takes more, and nothing opens twice")


func test_heat(t) -> void:
	t.check(Heat.points([1, 1, 2]) == 1.0 and Heat.points([3, 3]) == 8.0 and Heat.points([0, 5]) == 16.0, "points are (s-1)² summed")
	var h := Heat.new()
	t.check(not h.update(1.0, 0.0) and h.level == Heat.CALM, "nothing suspected is calm")
	t.check(h.update(1.0, 5.0) and h.level == Heat.CURIOUS, "a couple of wary faces make it curious")
	h.bump(Heat.CAUGHT)
	h.update(0.0, 8.0)
	t.check(h.level == Heat.LOCKDOWN and h.peak == Heat.LOCKDOWN, "someone called in on top of that is Lockdown")
	h.update(60.0, 0.0)
	t.check(h.level == Heat.LOCKDOWN, "Lockdown holds while it's still recent")
	h.update(40.0, 0.0)
	t.check(h.level == Heat.ALERT, "and falls back to Alert after ninety quiet seconds")
	t.check(Heat.name_of(Heat.ALERT) == "Alert", "levels have names")


func test_prompt(t) -> void:
	var teo := MeridianCast.sheet("teo")
	var sys := CharacterPrompt.system(teo)
	t.check(sys.begins_with("You are Teo,") and sys.contains(MeridianCast.SITUATION), "the prompt says who they are and what tonight is")
	t.check(sys.contains("\"let_through\"") and sys.contains("\"ask_for_invitation\""), "it lists their actions")
	t.check(not sys.contains("4471"), "the kitchen code is in nobody's prompt")
	t.check(not CharacterPrompt.system(MeridianCast.sheet("benny")).contains("4471"), "not even Benny's, until he's warmed to you")
	var line := CharacterPrompt.crew_line("8:52 pm", "a man in a black dinner suit", "Evening.", 1.5, "whisper", "clear", true)
	t.check(line.contains("right in front of you") and line.contains("whispering") and line.contains("to you"), "a line says where, how and to whom: %s" % line)
	var over := CharacterPrompt.crew_line("8:52 pm", "a man", "the Rose", 8.0, "normal", "muffled", false, true)
	t.check(over.contains("Overheard") and over.contains("through a wall") and over.contains("some words lost"), "an overheard line says so: %s" % over)
	var history := [
		{"who": "crew", "text": "a"}, {"who": "event", "text": "b"}, {"who": "character", "text": "c"}, {"who": "crew", "text": "d"},
	]
	var msgs := CharacterPrompt.messages(teo, history)
	t.check(msgs.size() == 4 and msgs[1].content == "a\nb" and msgs[2].role == "assistant", "lines that aren't theirs go in one message")
	var long := []
	for i in CharacterPrompt.KEEP + 1:
		long.append({"who": "crew" if i % 2 == 0 else "character", "text": str(i)})
	CharacterPrompt.trim(long)
	t.check(long.size() < CharacterPrompt.KEEP and long[0].who != "character", "the oldest go in one big step, starting on someone else's line")


func test_scripted(t) -> void:
	var teo := MeridianCast.sheet("teo")
	var f := JobRules.new_face(teo)
	var r := ScriptedBrain.reply(teo, f, {"kind": "line", "heard": "I'm Felix Halvorsen, the owner's nephew."})
	t.check(r.do == "ask_reception" and not r.believes.is_empty(), "with no model, Teo checks a name with reception")
	f.checks["ask_reception"] = "asked"
	r = ScriptedBrain.reply(teo, f, {"kind": "line", "heard": "My name's on the list."})
	t.check(r.do == "none" and r.say == "I already checked.", "but only once")
	r = ScriptedBrain.reply(teo, f, {"kind": "answer", "heard": "", "verdict": "good"})
	t.check(r.do == "let_through" and r.suspicion <= JobRules.TRUST, "a good answer opens the door")
	r = ScriptedBrain.reply(teo, JobRules.new_face(teo), {"kind": "question", "answer": "Yes, he's on the list."})
	t.check(r.say == "Yes, he's on the list." and r.do == "none", "a question on the radio gets the answer it was given")
	var marcus := MeridianCast.sheet("marcus")
	r = ScriptedBrain.reply(marcus, JobRules.new_face(marcus), {"kind": "overheard", "heard": "the invitation's forged"})
	t.check(r.suspicion == 2, "a hot word overheard puts anyone on edge")
	r = ScriptedBrain.reply(marcus, JobRules.new_face(marcus), {"kind": "seen", "heard": ""})
	t.check(r.say != "" and r.tone == "wary", "staff see strangers in the back")


func test_covers(t) -> void:
	t.check(Covers.describe("guest", true) == "a woman in a long evening dress", "a cover is seen as its clothes")
	t.check(Covers.looks_staff("waiter_jacket") and not Covers.looks_staff("guest"), "a waiter's jacket looks like staff")
	var c := CrewInfo.make(7, 7, "Ken", "press", false)
	c.has_invitation = true
	var back := CrewInfo.from_dict(c.to_dict())
	t.check(back.id == 7 and back.cover == "press" and back.cover_name == "Sam Okoye" and back.has_invitation and back.outfit == "press", "a crew member goes over the network and back")
	t.check(CrewInfo.make(1, 1, "x", "nonsense", false).cover == Covers.first(), "an unknown cover is the first on offer")
	Session.leave()
	Session.start_solo("facilities", false)
	var crew := Session.job_crew()
	t.check(crew.size() == 1 and "invitation" in crew[0].items, "alone, you carry the invitation whatever your cover")
	Session.crew[5] = {"name": "Drew", "cover": "guest", "female": true}
	crew = Session.job_crew()
	t.check(not "invitation" in crew[0].items and "invitation" in crew[1].items and crew[1].cover == "guest", "in a crew, the guest carries it")
	Session.leave()
	for job in Person.JOBS:
		t.check(Person.JOBS[job].has("outfit") and Person.JOBS[job].has("main"), "%s has clothes" % job)
	for o in Covers.OUTFITS:
		t.check(Person.JOBS.has(str(Covers.OUTFITS[o].job)), "the %s outfit dresses a person" % o)
	for sheet in MeridianCast.all():
		t.check(Person.JOBS.has(sheet.person_job), "%s has clothes for their job" % sheet.name)


## A job in the stand-in hotel, with one crew member (or two), scripted.
func _job(t, covers := ["guest"]) -> Job:
	LGSettings.set_value("ai", "mode", "off")
	var root := Node3D.new()
	root.name = "GalaTest"
	t.add_child(root)
	var hotel := StubHotel.new()
	root.add_child(hotel)
	var crew: Array[CrewInfo] = []
	var i := 0
	for cv in covers:
		var c := CrewInfo.make(i + 1, i + 1, "Crew%d" % i, cv, false)
		if i == 0:
			c.items.append("invitation")
		var b := Body.new()
		root.add_child(b)
		b.global_transform = hotel.spots["crew_%d" % i]
		c.node = b
		crew.append(c)
		i += 1
	var job := Job.new()
	root.add_child(job)
	job.setup(MeridianGalaJob.new(), hotel, crew, 7)
	job.brains = false
	return job


func _done(job: Job) -> void:
	job.get_parent().queue_free()


## Puts a crew member somewhere, looking at a point.
func _stand(job: Job, id: int, at: Vector3, look_at: Vector3) -> void:
	var b: Body = job.crew_node(id)
	b.global_position = at
	var d := look_at - at
	d.y = 0.0
	b.look = d.normalized()


func _quiet(job: Job) -> bool:
	for ch in job.cast.values():
		if ch.busy:
			return false
	return true


func test_job_basics(t) -> void:
	var job := _job(t)
	await t.frames(2)
	t.check(job.cast.size() == 8 and job.clock_text() == "8:45 pm", "the night starts at 8:45 with a cast of eight")
	t.check(job.venue.doors.front.is_open and job.venue.doors.ballroom.locked and not job.venue.doors.office.locked, "the front is open, the ballroom locked, the office not")
	t.check(job.describe(1) == "a man in a black dinner suit", "the crew are described by their clothes")
	var teo: Character = job.cast.teo
	t.check(teo.global_position.distance_to(job.spot("teo").origin) < 0.01, "everyone starts at their spot")
	var route := job.route(teo.global_position, "okafor_stage")
	t.check("ballroom" in route.doors and (route.points.back() as Vector3).distance_to(job.spot("okafor_stage").origin) < 0.01, "a route into the ballroom goes through its doors")
	var lookups := job.lookup("dana", 1, teo)
	t.check(lookups.verdict == "bad", "Dana doesn't know a stranger")
	job._told["teo|1"] = " I'm Felix Halvorsen."
	t.check(job.lookup("dana", 1, teo).verdict == "good", "Felix Halvorsen is on her list")
	job._told["teo|1"] = " We're the Marlowes."
	t.check(job.lookup("dana", 1, teo).verdict == "bad", "the Marlowes already checked in, so it isn't them")
	job.crew_by_id(1).flags["listed"] = true
	t.check(job.lookup("dana", 1, teo).verdict == "good", "a name she added herself checks out")
	t.check(job.lookup("okafor", 1, teo).verdict == "bad", "Okafor doesn't know you")
	job._told["teo|1"] = " I'm his nephew."
	t.check(job.lookup("okafor", 1, teo).verdict == "good", "but he won't risk upsetting the owner's nephew")
	_done(job)
	await t.frames(2)


func test_job_talk(t) -> void:
	var job := _job(t)
	await t.frames(2)
	var teo: Character = job.cast.teo
	_stand(job, 1, teo.global_position + Vector3(0, 0, 1.4), teo.global_position)
	var hearers: Array = []
	for ch in job.cast.values():
		hearers.append({"ch": ch, "d": ch.ear().distance_to(job.crew_by_id(1).mouth()), "wall": false, "hearing": Earshot.hear("Good evening.", ch.ear().distance_to(job.crew_by_id(1).mouth()))})
	t.check(job.addressed(job.crew_by_id(1), hearers) == teo, "the one you face, close by, is the one you're talking to")
	job.crew_said(1, "Good evening.")
	t.check(await t.until(func(): return teo.turns.size() >= 1 and not teo.busy, 5.0), "Teo answers")
	t.check(teo.turns[0].reply.do == "ask_for_invitation" and job.cast.dana.turns.is_empty(), "he asks for the invitation, and nobody across the lobby thinks about it")
	t.check(job.lines.size() == 1 and job.lines[0].to == "teo", "the line is logged with who it was for")
	job.show_papers(1, teo)
	t.check(await t.until(func(): return not job._open.is_empty() or teo.turns.size() >= 2 and not teo.busy, 5.0), "he looks at the invitation")
	t.check(job.venue.doors.ballroom.is_open and job._open.has("ballroom"), "it passes a glance, and he opens the doors (%s)" % str(teo.turns.back().get("reply", {})))
	_stand(job, 1, Vector3(-4, 0, -24), Vector3(-4, 0, -30))
	t.check(await t.until(func(): return job.done, 3.0), "walking in ends the job")
	_done(job)
	await t.frames(2)


func test_job_check(t) -> void:
	var job := _job(t, ["press"])
	await t.frames(2)
	var teo: Character = job.cast.teo
	var dana: Character = job.cast.dana
	_stand(job, 1, teo.global_position + Vector3(0, 0, 1.4), teo.global_position)
	job.crew_said(1, "Good evening. I'm Felix Halvorsen, the owner's nephew.")
	t.check(await t.until(func(): return dana.turns.size() >= 1, 6.0), "Teo radios Dana and she thinks about it")
	t.check(dana.turns[0].kind == "question" and dana.turns[0].reply.do == "none", "her answer is words only")
	t.check(await t.until(func(): return teo.turns.size() >= 2 and not teo.busy, 8.0), "then Teo makes up his mind")
	t.check(teo.face_of(1).checks.get("ask_reception", "") == "good", "Felix is on the list: it checks out")
	t.check(job.venue.doors.ballroom.is_open, "and he opens the doors on the strength of it (%s)" % str(teo.turns.back().get("reply", {})))
	_done(job)
	await t.frames(2)


func test_job_back_of_house(t) -> void:
	var job := _job(t, ["facilities", "agency"])
	await t.frames(2)
	t.check(job.use(1, "door:service") != "" and not job.venue.doors.service.is_open, "the service door's locked")
	t.check(job.keypad(1, "1234") == "Wrong code." and not job.flags.has("keypad:keypad"), "a wrong code does nothing")
	_stand(job, 1, Vector3(9, 0, -12), Vector3(9, 0, -30))
	job.cast.marcus.walk_to("smoke")
	await t.frames(2)
	t.check(job.keypad(1, "4471") == "The lock clicks." and job.venue.doors.service.is_open and job.flags.has("keypad:keypad"), "the kitchen code opens it")
	t.check(job.use(2, "door:pass") != "" and not job.venue.doors.pass.is_open, "the pass is for waiters")
	t.check(job.use(2, "jackets") == "You put on a waiter's jacket." and job.crew_by_id(2).outfit == "waiter_jacket", "the jacket goes on")
	job.use(2, "door:pass")
	t.check(job.venue.doors.pass.is_open, "in the jacket, the pass opens")
	t.check(job.use(2, "jackets") == "You hang the jacket back up." and job.crew_by_id(2).outfit == "agency", "and comes off again")
	job.heat.bump(Heat.CAUGHT * 2.0)
	await t.frames(3)
	t.check(job.heat.level == Heat.LOCKDOWN and not job.venue.doors.service.is_open and not job.venue.doors.pass.is_open, "at Lockdown the kitchen's shut")
	t.check(job.keypad(1, "4471").contains("dead"), "and the keypad's dead")
	_done(job)
	await t.frames(2)


func test_job_office(t) -> void:
	var job := _job(t, ["guest", "press"])
	await t.frames(2)
	var marcus: Character = job.cast.marcus
	job._hold(1, marcus)
	t.check(job.crew_by_id(1).held and job.venue.doors.office.locked and not job.done, "one called in is held, the office locked, and the job goes on")
	var minder: Character = null
	for ch in job.cast.values():
		if ch.minding:
			minder = ch
	t.check(minder != null and minder.sheet.halberd and minder.post == "office_guard", "a Halberd guard goes to mind the office")
	t.check(job.heat.events >= Heat.CAUGHT, "and the venue heats up")
	job.on_reply(minder, 2, {"kind": "line"}, {"do": "release"})
	t.check(not job.crew_by_id(1).held and not job.venue.doors.office.locked and not minder.minding, "talked round by a crewmate, the guard lets them go")
	job._hold(1, marcus)
	job._hold(2, marcus)
	t.check(not job.done, "with the whole crew held, there's still time to talk their way out")
	job.on_reply(minder, 1, {"kind": "line"}, {"do": "release"})
	job.minutes += Job.POLICE + 0.5
	await t.frames(2)
	t.check(not job.done, "one talked out before the police came, and the job goes on")
	job._hold(1, marcus)
	await t.frames(2)
	job.minutes += Job.POLICE + 0.5
	await t.frames(2)
	t.check(job.done, "with the whole crew held when the police come, it's over")
	_done(job)
	await t.frames(2)


func test_job_clock(t) -> void:
	var job := _job(t)
	var ended := []
	job.ended.connect(func(r): ended.append(r))
	await t.frames(2)
	job.minutes = 21 * 60 + 0.5
	await t.frames(2)
	t.check(job.cast.marcus.walking and job.cast.marcus.post == "smoke", "at nine Marcus goes out for his smoke")
	job.minutes = 21 * 60 + 5.5
	await t.frames(2)
	t.check(job.cast.celeste.post == "celeste_in" and job.venue.doors.ballroom.is_open, "at five past the Marlowes go in")
	job.minutes = MeridianGalaJob.SHUT + 0.5
	await t.frames(2)
	t.check(not job.venue.doors.ballroom.is_open and job.context_for(job.cast.teo, 1).shut, "at twenty past the doors shut for the speech")
	job.minutes = MeridianGalaJob.SPEECH + 0.1
	await t.frames(2)
	t.check(job.done and ended.size() == 1 and ended[0].outcome == "late", "the speech with nobody inside ends it")
	var r: Dictionary = ended[0]
	t.check(r.has("clean") and r.has("quiet") and r.has("silver") and r.crew.size() == 1, "the report has the scores and the crew")
	_done(job)
	await t.frames(2)


func test_job_report(t) -> void:
	var job := _job(t)
	await t.frames(2)
	var teo: Character = job.cast.teo
	teo.turns.append({"kind": "line", "said": "Evening, Teo. How about those Mariners?", "before": 2, "after": 1, "subject": 1, "clock": "8:50 pm", "reply": {"say": "What a season!", "ended": ""}})
	teo.turns.append({"kind": "line", "said": "The invitation's forged, obviously.", "before": 1, "after": 3, "subject": 1, "clock": "8:51 pm", "reply": {"say": "Excuse me?", "ended": ""}})
	var r := job.report("in")
	t.check(r.best.said.contains("Mariners") and r.best.voice == "am_liam", "the best line is the one that bought trust, with the voice to play it")
	t.check(r.worst.said.contains("forged") and r.worst.reply == "Excuse me?", "the worst is the one that cost it")
	var card := JobReportCard.new()
	t.add_child(card)
	card.show_report(r)
	t.check(card.visible and "Play" in card.button_texts() and "Back to the title" in card.button_texts(), "the card shows them, with a way to hear them again")
	card.queue_free()
	_done(job)
	await t.frames(2)


func test_keypad_panel(t) -> void:
	var k := KeypadPanel.new()
	t.add_child(k)
	var got := []
	k.entered.connect(func(c): got.append(c))
	k.ask()
	for d in ["4", "4", "7", "<", "7", "1"]:
		k.press(d)
	k.press("9")
	t.check(k.code == "4471", "four digits, with a step back (%s)" % k.code)
	k.press("OK")
	t.check(got == ["4471"] and not k.visible, "OK tries them")
	k.queue_free()
	await t.frames(1)


func test_voice_relay(t) -> void:
	var pcm := PackedByteArray()
	pcm.resize(400)
	for i in 200:
		pcm.encode_s16(i * 2, int(sin(i * 0.1) * 20000.0))
	var enc := VoiceRelay.encode(pcm)
	t.check(enc.size() == 200, "a byte a sample")
	var dec := VoiceRelay.decode(enc)
	var worst := 0.0
	for i in 200:
		worst = maxf(worst, absf(dec[i] - pcm.decode_s16(i * 2) / 32768.0))
	t.check(worst < 0.04, "mu-law comes back close (off by %.3f at most)" % worst)
	t.check(VoiceRelay.linear(VoiceRelay.ulaw(0)) == 0 and VoiceRelay.linear(VoiceRelay.ulaw(-1000)) < 0, "silence stays silent and signs survive")


## The whole gala scene against the fake Lemonade: the brain and voice come
## up, Teo asks for your invitation, you show it, he opens the doors, you
## walk in, and the report says so and is written to user://jobs.
func test_fake_gala(t) -> void:
	if not await t._start_fake():
		return
	await t._fake_post("/fake/reset", {})
	LGSettings.set_value("voice", "talk", "text")
	LGSettings.set_value("voice", "speaking", true)
	LGBrain.stop()
	LGVoice.stop()
	BrainQueue.forget_probes()
	JobScene.setup = JobScene.solo("guest", false, "Tester")
	var s: JobScene = load(JobScene.SCENE).instantiate()
	t.add_child(s)
	await t.frames(3)
	t.check(s.job != null and s.cast.size() == 8 and s.me.has_invitation, "the job starts with the cast of eight and your invitation")
	t.check(await t.until(func(): return LGBrain.is_ready() and s.job.brains, 15.0), "the staff have brains against the fake")
	t.check(await t.until(func(): return LGVoice.is_ready(), 20.0), "the voices are ready: %s" % LGVoice.detail)
	var teo: Character = s.cast.teo
	var at := teo.global_position + teo.global_basis.z * 1.3
	s.player.global_position = Vector3(at.x, s.player.global_position.y, at.z)
	s.player.look_at(Vector3(teo.global_position.x, s.player.global_position.y, teo.global_position.z), Vector3.UP)
	await t.frames(3)
	s._on_text_submitted("Good evening. I was invited, I'm on the list.")
	t.check(await t.until(func(): return teo.turns.size() >= 1 and not teo.busy, 10.0), "Teo hears you and thinks")
	var t0: Dictionary = teo.turns[0]
	t.check(not t0.scripted and t0.reply.do == "ask_for_invitation", "he asks for your invitation: %s" % str(t0.get("reply")))
	t.check(await t.until(func(): return s.hud._speaker.text.begins_with("Teo"), 5.0), "his line is subtitled")
	t.check(await t.until(func(): return s.hud.prompt_text().contains("invitation"), 3.0), "facing him, Interact shows the invitation: '%s'" % s.hud.prompt_text())
	s._on_use_pressed()
	t.check(await t.until(func(): return teo.turns.size() >= 2 and not teo.busy, 10.0), "he looks it over")
	t.check(teo.turns[1].reply.do == "let_through" and s.venue.doors.ballroom.is_open, "it looks right, and he opens the doors: %s" % str(teo.turns[1].get("reply")))
	s.player.global_transform = JobScene._player_at(s.venue.spots.ballroom_in)
	t.check(await t.until(func(): return s.over, 5.0) and str(s.report.get("outcome", "")) == "in", "walking in ends it: you're in")
	t.check(s.report_card.visible and not s.report_card.button_texts().is_empty(), "the job report shows")
	t.check(FileAccess.file_exists(str(s.report.get("file", ""))), "and is written to user://jobs")
	var log: Dictionary = await t._fake_log()
	var chats: Array = log.get("chat", [])
	var teos := chats.filter(func(c): return str(c.get("who", "")) == "teo")
	t.check(teos.size() >= 2, "the fake saw Teo's two turns (%d)" % teos.size())
	var speech: Array = log.get("speech", [])
	t.check(speech.any(func(sp): return str(sp.get("voice", "")) == teo.sheet.voice), "Teo speaks in his own voice")
	s.queue_free()
	await t.frames(2)
	JobScene.setup = {}


## The title's gala pages: the briefing and covers, hosting a crew, the
## lobby, and leaving it.
func test_title_gala(t) -> void:
	var title: Node = load("res://game/ui/title.tscn").instantiate()
	t.add_child(title)
	await t.frames(2)
	title.show_gala()
	await t.frames(1)
	var texts: PackedStringArray = title.button_texts()
	for b in ["Play alone", "Host a crew on this network", "Join a crew", "> Guest <", "Press", "Back"]:
		t.check(b in texts, "the briefing has %s (%s)" % [b, ", ".join(texts)])
	title._pick_cover("press")
	await t.frames(1)
	t.check("> Press <" in title.button_texts() and Session.me().cover == "press", "a picked cover is marked and kept for joining")
	title._toggle_body()
	await t.frames(1)
	t.check("You look like: a woman" in title.button_texts() and Session.me().female, "and so is the body")
	title._host()
	await t.frames(2)
	t.check(Session.mode == Session.Mode.LAN_HOST and Session.crew.size() == 1 and str(Session.crew[1].cover) == "press", "hosting puts you in the crew as you are")
	t.check("Start the job" in title.button_texts() and "Leave the crew" in title.button_texts(), "the host's lobby can start the job")
	title._pick_cover("agency")
	await t.frames(1)
	t.check(str(Session.crew[1].cover) == "agency" and "> Agency waiter <" in title.button_texts(), "changing cover in the lobby changes the crew")
	title._leave_lobby()
	await t.frames(1)
	t.check(Session.mode == Session.Mode.NONE and Session.crew.is_empty() and "Play alone" in title.button_texts(), "leaving goes back to the briefing")
	Session.set_cover("guest", false)
	title.queue_free()
	await t.frames(2)


## The job in the real Meridian: everyone's routine walks get where
## they're going, through doors locked to the crew, and the spots are in
## the rooms the job expects.
func test_job_move(t) -> void:
	var job := JobHarness.start(t, MeridianGalaJob.new(), ["guest", "press"], StubHotel.new())
	await t.frames(2)
	var moved := []
	job.moved.connect(func(id, at): moved.append([id, at]))
	job.move_crew(1, "ballroom_in")
	job.move_crew(2, "ballroom_in")
	var spot: Transform3D = job.venue.spots.ballroom_in
	t.check(job.crew_node(1).global_position.distance_to(spot.origin) < 0.01, "taken somewhere, a crew member is there at once")
	t.check(job.crew_node(2).global_position.distance_to(spot.origin) > 0.7, "and a crewmate taken to the same spot stands beside them")
	t.check(moved.size() == 2 and moved[0][0] == 1, "their devices are told")
	job.move_crew(1, "nowhere")
	t.check(moved.size() == 2, "a spot that isn't there goes nowhere")
	JobHarness.done(job)
	await t.frames(2)


func test_job_data(t) -> void:
	VenueChecks.job_data(t, MeridianGalaJob.new())
	await VenueChecks.routines(t, MeridianGalaJob.new())


func test_job_in_meridian(t) -> void:
	LGSettings.set_value("ai", "mode", "off")
	var root := Node3D.new()
	t.add_child(root)
	var hotel := Meridian.new()
	root.add_child(hotel)
	var crew: Array[CrewInfo] = []
	var c := CrewInfo.make(1, 1, "Crew", "guest", false)
	c.has_invitation = true
	var b := Body.new()
	root.add_child(b)
	b.global_transform = hotel.spots.crew_0
	c.node = b
	crew.append(c)
	var job := Job.new()
	root.add_child(job)
	job.setup(MeridianGalaJob.new(), hotel, crew, 3)
	job.brains = false
	await t.frames(2)
	var zones := {"teo": "lobby", "dana": "lobby", "benny": "lobby", "marcus": "corridor", "laurent": "kitchen", "held": "office",
		"office_guard": "corridor", "ballroom_in": "ballroom", "okafor_stage": "ballroom", "smoke": "outside", "crew_0": "lobby"}
	for s in zones:
		t.check(hotel.zone_at(hotel.spots[s].origin) == zones[s], "%s's spot is in the %s (%s)" % [s, zones[s], hotel.zone_at(hotel.spots[s].origin)])
	t.check(hotel.doors.ballroom.locked and hotel.doors.service.locked and not hotel.doors.front.is_open, "the ballroom and service doors are locked to the crew, and the front opens by itself")
	t.check(hotel.uses.has("jackets") and hotel.zone_at(hotel.uses.jackets.global_position) == "staff_room", "the jackets hang in the staff room")
	for r in job.def.routine:
		var ch: Character = job.cast[r[1]]
		ch.walk_to(str(r[2]))
		for i in 4000:
			if not ch.walking:
				break
			ch._walk(0.05)
		var to: Vector3 = hotel.spots[str(r[2])].origin
		t.check(not ch.walking and ch.global_position.distance_to(to) < 0.1, "%s walks to %s (%.1f m off)" % [r[1], r[2], ch.global_position.distance_to(to)])
	t.check(hotel.doors.ballroom.locked and not hotel.doors.ballroom.is_open, "the doors staff walked through shut and stay locked behind them")
	hotel.set_clock(20 * 60 + 45)
	root.queue_free()
	await t.frames(2)
