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
