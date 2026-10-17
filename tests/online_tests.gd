extends RefCounted
## M3, the city online: the online modes of [Session], the job report the host
## sends, what [CityOnline] keeps and asks, the crew record folded into
## [Progress], the title's online pages, and the Switchboard mode of LGBrain.
## None of it needs a network: the server's side is game-server's tests, and
## `tools/net_check.tscn` plays a job between two copies.
##   godot --headless --path . tests/run_tests.tscn -- --only=online


func _report(extra := {}) -> Dictionary:
	var r := {"job": "marlin_safe", "venue": "marlin", "outcome": "in", "win": true, "take": 5000, "clean": true, "quiet": false,
		"silver": true, "circuit": 0, "memories": {"pieter": ["He let you through."]},
		"crew": [{"id": 1, "was_held": false}, {"id": 5, "was_held": true}, {"id": 9, "was_held": false}]}
	r.merge(extra, true)
	return r


func test_online_modes(t) -> void:
	Session.leave()
	Session.mode = Session.Mode.ONLINE_HOST
	t.check(Session.is_host() and Session.is_online() and Session.is_networked() and not Session.is_lan(), "the host of an online room is the host, online and networked, not on the LAN")
	Session.mode = Session.Mode.ONLINE_CLIENT
	t.check(not Session.is_host() and Session.is_online() and Session.is_networked(), "a guest of an online room isn't the host")
	Session.mode = Session.Mode.LAN_CLIENT
	t.check(Session.is_lan() and not Session.is_online() and Session.is_networked(), "and a LAN guest is still on the LAN")
	Session.mode = Session.Mode.SOLO
	t.check(Session.is_host() and not Session.is_networked() and Session.local_id() == 1, "alone isn't networked")
	Session.leave()
	t.check(Session.mode == Session.Mode.NONE and Session.jobs_reported == 0, "leaving resets it")
	t.check(not await Session.report_job(_report()), "only the host of an online room reports a job")
	LGSettings.set_value("online", "enabled", false)
	t.check(not await Session.host_online(), "an online room can't open with online play off")
	t.check(Session.mode == Session.Mode.NONE, "and the mode stays unset")
	LGSettings.set_value("online", "enabled", true)
	t.check(not await Session.join_online("!"), "a room code that can't be one is turned away")


func test_job_report_payload(t) -> void:
	var p := Session.job_report_payload(_report(), "match1", 3, {1: "uA", 5: "uB"})
	t.check(p.players.size() == 2, "players without an account aren't reported")
	t.check(p.players[0].user_id == "uA" and not p.players[0].held and p.players[1].user_id == "uB" and p.players[1].held, "each one's account, and whether they were held")
	t.check(p.players[0].memories.has("pieter"), "and what the characters will remember")
	t.check(p.match_id == "match1" and p.round == 3 and p.job == "marlin_safe" and p.take == 5000 and p.win and p.clean and p.silver and not p.quiet and p.venue == "marlin" and p.circuit == 0, "the job's result")
	t.check(Session.job_report_payload(_report(), "m", 1, {}).players.is_empty(), "no accounts, nothing to send")


func test_contract(t) -> void:
	var week := Circuit.week()
	t.check(CityOnline.is_contract(_report({"circuit": week})), "a won go at this week's contract counts")
	t.check(not CityOnline.is_contract(_report({"circuit": week, "win": false})), "a lost one doesn't")
	t.check(not CityOnline.is_contract(_report({"circuit": week, "take": 0})), "nor one with no take")
	t.check(not CityOnline.is_contract(_report({"circuit": week - 1})), "nor another night")
	t.check(not CityOnline.is_contract(_report()), "nor a plain job")
	LGSettings.set_value("online", "enabled", false)
	t.check(not await CityOnline.submit_contract(_report({"circuit": week})), "with online play off nothing is sent")
	t.check(await CityOnline.share_report(_report()) == "", "or shared")
	t.check(not await CityOnline.pull(), "or fetched")
	LGSettings.set_value("online", "enabled", true)


func test_record_text(t) -> void:
	t.check("No online jobs" in CityOnline.record_text({}), "a new account has no record")
	var s := CityOnline.record_text({"jobs": 3, "clean": 1, "take": 12500})
	t.check("3 jobs" in s and "1 clean" in s and "$12,500" in s, "the record in a line (%s)" % s)
	t.check(CityOnline.BOARDS[0][0] == "contract_weekly" and CityOnline.BOARDS.size() == 5, "the contract's board comes first")


func test_server_record(t) -> void:
	Progress.reset()
	Progress.take = 1000
	Progress.memories = {"marlin": {"pieter": ["Local line."]}}
	Progress.merge_server({"burned": true, "faces": 0, "take": 7500, "done": {"meridian_gala": {"outcome": "in", "take": 2000}, "nowhere_job": {}},
		"memories": {"marlin": {"pieter": ["Local line.", "Server line."], "ines": ["She waved."]}}})
	t.check(Progress.take == 7500 and Progress.burned, "the larger take, and a burned face, come from the server")
	t.check(Progress.is_done("meridian_gala") and not Progress.done.has("nowhere_job"), "jobs it knows are done, jobs nobody has aren't")
	t.check(Progress.memories.marlin.pieter == ["Local line.", "Server line."] and Progress.memories.marlin.ines.size() == 1, "memories join without repeating")
	Progress.merge_server({"burned": true, "faces": 2, "take": 100})
	t.check(Progress.faces == 2 and Progress.take == 7500, "new faces are kept and a smaller take isn't")
	var before := Progress.take
	Progress.merge_server({})
	t.check(Progress.take == before, "an empty record changes nothing")
	Progress.reset()


func test_title_online(t) -> void:
	var wanted: Dictionary = Session.wanted.duplicate()
	LGSettings.set_value("online", "enabled", true)
	Progress.reset()
	var title: Node = load("res://game/ui/title.tscn").instantiate()
	t.add_child(title)
	await t.frames(3)
	t.check("Leaderboards" in title.button_texts(), "the title has the Leaderboards")
	title.show_job("meridian_gala")
	await t.frames(1)
	t.check("Host a crew online" in title.button_texts() and "Host a crew on this network" in title.button_texts(), "a job can be hosted online or on the network")
	title.show_join()
	await t.frames(1)
	var texts: PackedStringArray = title.button_texts()
	t.check("Join an online crew with the code" in texts and "Read a shared report with the code" in texts, "joining has the online code and shared reports")
	Session.leave()
	title.show_main()
	LGSettings.set_value("online", "enabled", false)
	title.show_main()
	await t.frames(1)
	var off := false
	for b in title.find_children("", "Button", true, false):
		off = off or (b.text == "Leaderboards" and b.disabled)
	t.check(off, "with online play off the Leaderboards wait")
	title.show_job("meridian_gala")
	await t.frames(1)
	t.check(not "Host a crew online" in title.button_texts(), "and no crew is hosted online")
	title.show_shared({"title": "The Gala, Done", "text": "Silver Tongue: The Gala"})
	await t.frames(1)
	t.check("Copy the text" in title.button_texts(), "a shared report can be copied")
	LGSettings.set_value("online", "enabled", true)
	title.queue_free()
	await t.frames(1)
	Session.set_job("meridian_gala")
	Session.wanted = wanted
	Progress.reset()


func test_boards_panel(t) -> void:
	var panel := LGLeaderboardPanel.new()
	panel.setup(GameConfig.GAME_ID, "Tester", CityOnline.BOARDS, CityOnline.record_text)
	panel.build()
	t.check(panel.get_child_count() >= 3, "the Leaderboards build their rows")
	panel.free()


func test_switchboard(t) -> void:
	var mode := str(LGSettings.get_value("ai", "mode"))
	LGBrain.stop()
	LGBrain.switchboard_rpc = ""
	LGSettings.set_value("ai", "mode", "switchboard")
	t.check(not await LGBrain.ensure_ready_async() and LGBrain.state == "unavailable", "a game with no Switchboard can't use it")
	LGBrain.switchboard_rpc = "%s.switchboard" % GameConfig.GAME_ID
	LGOnline.disconnect_online()
	var res: Dictionary = await LGBrain._switchboard_chat([{"role": "user", "content": "hi"}], 10, {})
	t.check(not res.ok and res.error == "not signed in", "the Switchboard needs the online connection")
	LGBrain.stop()
	LGSettings.set_value("ai", "mode", mode)
	LGBrain.source = ""
	var panel := SettingsPanel.new()
	t.add_child(panel)
	await t.frames(1)
	t.check(panel.get_child_count() > 5, "the settings build with the Switchboard on offer")
	panel.queue_free()
	await t.frames(1)
	LGBrain.switchboard_rpc = ""


func test_crew_of_four(t) -> void:
	t.check(GameConfig.MAX_CREW == 4, "a crew is up to four")
	for id in Jobs.CAMPAIGN:
		if not Jobs.exists(id):
			continue
		var def := Jobs.make(id)
		var covers := []
		for i in GameConfig.MAX_CREW:
			covers.append(Covers.order()[i % Covers.order().size()])
		var job := JobHarness.start(t, def, covers)
		t.check(job.crew.size() == 4, "%s: four on the crew" % id)
		var spots := []
		for i in 4:
			t.check(job.venue.spots.has("crew_%d" % i), "%s: a start for crew %d" % [id, i])
			spots.append((job.venue.spots.get("crew_%d" % i, Transform3D()) as Transform3D).origin)
		for a in 4:
			for b in range(a + 1, 4):
				t.check(spots[a].distance_to(spots[b]) > 0.6, "%s: crew %d and %d don't stand on each other" % [id, a, b])
		JobHarness.done(job)


func _rival_job(t, id := "meridian_gala", covers := ["guest", "press", "guest", "press"]) -> Job:
	return JobHarness.start(t, Jobs.make(id), covers, null, 7, [], [0, 0, 1, 1])


func test_two_crews_session(t) -> void:
	Session.leave()
	Session.mode = Session.Mode.LAN_HOST
	Session.crew = {1: {"name": "A", "cover": "guest", "female": false, "team": 0}}
	t.check(Session.team_of(1) == 0 and not Session.rival, "one crew by default")
	for i in range(2, 6):
		Session.crew[i] = {"name": "P%d" % i, "cover": "guest", "female": false, "team": 0}
	t.check(Session.set_rival(false) and not Session.rival, "turning it off is fine")
	t.check(Session.set_rival(true) and Session.rival, "the host turns two crews on")
	t.check(Session.team_size(0) == 3 and Session.team_size(1) == 2, "the players are split between the crews (%d, %d)" % [Session.team_size(0), Session.team_size(1)])
	t.check(not Session.set_rival(false), "and it can't go off while more than a crew is in")
	t.check(Session._open_team() == 1, "a newcomer joins the smaller crew")
	Session.switch_team()
	t.check(Session.team_of(1) == 1 and Session.team_size(1) == 3, "you can switch crews when there's room")
	for id in [2, 3, 4]:
		Session.crew[id]["team"] = 0
	Session.crew[5]["team"] = 1
	Session.crew[6] = {"name": "P6", "cover": "guest", "female": false, "team": 1}
	t.check(Session.team_size(0) == 3 and Session.team_size(1) == 3, "three each")
	Session.crew[7] = {"name": "P7", "cover": "guest", "female": false, "team": 0}
	Session._move_team(1, 0)
	t.check(Session.team_of(1) == 1, "a full crew takes no more")
	var cfg := Session.job_crew()
	t.check(cfg.size() == 7 and cfg.any(func(c): return int(c.team) == 1), "the job's crew carries the teams")
	Session.leave()
	t.check(not Session.rival, "leaving puts the crews back to one")


func test_two_crews_race(t) -> void:
	var job := _rival_job(t)
	t.check(job.rival() and job.team_crew(0).size() == 2 and job.team_crew(1).size() == 2, "two crews of two")
	var a: Vector3 = job.crew_node(1).global_position
	var b: Vector3 = job.crew_node(3).global_position
	t.check(a.distance_to(b) > 1.0, "the rival crew starts apart from yours")
	for c in job.team_crew(1):
		c.inside = true
	job._check_end()
	t.check(job.done, "the night ends when a crew gets what it came for")
	JobHarness.done(job)
	job = _rival_job(t)
	for c in job.team_crew(0):
		c.inside = true
	for c in job.team_crew(1):
		c.inside = true
	job._check_end()
	t.check(job.done, "both crews at once")
	JobHarness.done(job)


func test_two_crews_report(t) -> void:
	var job := _rival_job(t)
	var got: Array = []
	job.ended.connect(got.append)
	for c in job.team_crew(1):
		c.inside = true
	job._check_end()
	var rep: Dictionary = got[0] if not got.is_empty() else {}
	t.check(rep.get("rival", false) and rep.get("winners", []) == [1] and rep.get("win", false), "the report says which crew won (%s)" % str(rep.get("winners")))
	t.check(rep.crew.size() == 4 and int(rep.crew[2].team) == 1, "and who was on which crew")
	var accounts := {1: "uA", 2: "uB", 3: "uC", 4: "uD"}
	var won := Session.job_report_payload(rep, "m", 1, accounts, 1)
	var lost := Session.job_report_payload(rep, "m", 2, accounts, 0)
	t.check(won.win and won.take > 0 and won.players.size() == 2 and won.players[0].user_id == "uC", "the winners are reported with the take")
	t.check(not lost.win and lost.take == 0 and not lost.clean and lost.players.size() == 2 and lost.players[0].user_id == "uA", "the others are reported as beaten")
	JobHarness.done(job)
	# All of one crew held: the other plays on.
	job = _rival_job(t)
	for c in job.team_crew(0):
		c.held = true
	job._check_end()
	t.check(not job.done, "a crew that's all held is out, and the other plays on")
	for c in job.team_crew(1):
		c.held = true
	job._check_end()
	job.minutes += Job.POLICE + 1.0
	job._check_end()
	t.check(job.done, "everyone held ends it")
	JobHarness.done(job)


func test_two_crews_snitch(t) -> void:
	var job := _rival_job(t)
	var guard: Character = job.cast.get("priya")
	if guard == null:
		guard = job.cast.values()[0]
	var snitch: CrewInfo = job.crew_by_id(1)
	var rival: CrewInfo = job.crew_by_id(3)
	JobHarness.stand(job, 1, guard.global_position + Vector3(0, 0, 1.2), guard.global_position)
	JobHarness.stand(job, 3, guard.global_position + Vector3(2.0, 0, 0), guard.global_position)
	var before := guard.suspicion_of(3)
	guard.face_of(1)["suspicion"] = 1
	job._snitch(snitch, guard, " that man has an earpiece ")
	t.check(guard.suspicion_of(3) == before + 2, "a believed tip about the rival raises their suspicion (%d to %d)" % [before, guard.suspicion_of(3)])
	job._snitch(snitch, guard, " that man has an earpiece ")
	t.check(guard.suspicion_of(3) == before + 2, "the same tip counts once")
	var other := _rival_job(t)
	JobHarness.done(other)
	guard.face_of(2)["suspicion"] = 4
	var ally: CrewInfo = job.crew_by_id(2)
	JobHarness.stand(job, 2, guard.global_position + Vector3(0, 0, 1.2), guard.global_position)
	var mine := guard.suspicion_of(2)
	job._snitch(ally, guard, " he is lying, he is not a waiter ")
	t.check(guard.suspicion_of(2) == mine + 1, "a tip nobody trusts costs the one who gave it")
	job._snitch(rival, guard, " just chatting about the weather ")
	t.check(guard.suspicion_of(1) <= 2, "ordinary talk isn't a tip")
	JobHarness.done(job)
