extends Node
## Plays a job between two copies of the game over the local network, with
## the cast on scripted lines (no models). Run both at once, each with its
## own settings folder (a job id and a Circuit night's number are optional,
## the gala by default, and the host's matter):
##   XDG_DATA_HOME=/tmp/a godot --headless --path . tools/net_check.tscn -- host /tmp/code [marlin_safe [482913]] &
##   XDG_DATA_HOME=/tmp/b godot --headless --path . tools/net_check.tscn -- join /tmp/code
## The guest joins, picks the second cover and walks up to someone (Teo at
## the gala); the host sees them arrive, and the answer reaches the guest's
## subtitles. The guest rings the job's first number and hears it answered.
## At the gala the host opens the ballroom and both walk in; any other job
## the host ends as it comes off. Both get the report. Each prints "NET OK"
## and exits 0 when its side worked.

const TIMEOUT := 40.0

var _role := ""
var _code_file := ""
var _job := "meridian_gala"
var _night := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_role = args[0] if args.size() > 0 else "host"
	_code_file = args[1] if args.size() > 1 else "/tmp/silver-tongue-net-code"
	_job = args[2] if args.size() > 2 else _job
	_night = int(args[3]) if args.size() > 3 else 0
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	LGSettings.set_value("player", "name", "Host" if _role == "host" else "Guest", false)
	LGSettings.set_value("ai", "mode", "off", false)
	LGSettings.set_value("voice", "talk", "text", false)
	LGSettings.set_value("voice", "speaking", false, false)
	Session.status.connect(_on_status)
	# Scene changes would free this node if it stayed the current scene.
	get_tree().current_scene = null
	var ok: bool
	if _role == "host":
		ok = await _host()
	else:
		ok = await _join()
	print("NET %s %s" % ["OK" if ok else "FAILED", _role])
	Session.leave()
	get_tree().quit(0 if ok else 1)


func _host() -> bool:
	if FileAccess.file_exists(_code_file):
		DirAccess.remove_absolute(_code_file)
	if not Session.host_lan("guest"):
		return _fail("could not host")
	Session.set_job(_job, _night)
	Session.set_cover(Covers.first(), false)
	var gala := _job == "meridian_gala"
	var f := FileAccess.open(_code_file, FileAccess.WRITE)
	f.store_string(Session.join_code if Session.join_code != "" else "lan")
	f.close()
	print("join code ", Session.join_code)
	if not await _until(func(): return Session.crew.size() >= 2):
		return _fail("the guest never arrived")
	var guest_id := 0
	for id in Session.crew:
		if int(id) != 1:
			guest_id = int(id)
	if not await _until(func(): return str(Session.crew[guest_id].cover) == _guest_cover()):
		return _fail("the guest's cover never changed")
	var crew := Session.job_crew()
	if gala and not ("invitation" in crew[0].items and not "invitation" in crew[1].items):
		return _fail("the invitation should go to the host, the one guest: %s" % str(crew))
	Session.start_job()
	if not await _until(func(): return _scene() != null and _scene().job != null and not _scene().job.hold):
		return _fail("the guest's scene never said it was ready")
	var s := _scene()
	var avatar: CrewAvatar = s.avatars.get(guest_id)
	if avatar == null:
		return _fail("no body for the guest")
	print("the guest is here, dressed as %s, in %s%s" % [s.job.crew_by_id(guest_id).outfit, s.def.title, JobReportCard.night({"circuit": _night})])
	var heard := func() -> Character:
		for ch in s.cast.values():
			if ch.turns.any(func(t): return int(t.get("subject", 0)) == guest_id):
				return ch
		return null
	if not await _until(func(): return heard.call() != null):
		return _fail("nobody heard the guest (lines %s, the guest at %s looking %s)" % [str(s.job.lines), avatar.global_position, avatar.look_dir()])
	var ch: Character = heard.call()
	if ch.global_position.distance_to(avatar.global_position) > 3.0:
		return _fail("%s heard the guest from %.1f m away" % [ch.sheet.name, ch.global_position.distance_to(avatar.global_position)])
	print("%s heard the guest: %s" % [ch.sheet.name, str(ch.turns.back().get("reply", {}).get("say", ""))])
	await get_tree().create_timer(2.0).timeout
	var want := "in" if gala else str(s.def.wins[0])
	if gala:
		s.job._open_for("ballroom", 20.0)
		s.player.global_transform = JobScene._player_at(s.venue.spots.ballroom_in)
	else:
		await get_tree().create_timer(6.0).timeout
		s.job.finish(want)
	if not await _until(func(): return s.over):
		return _fail("the job never ended")
	print("the job ended: %s, %s" % [s.report.get("outcome"), s.report.get("clock")])
	if str(s.report.get("outcome", "")) != want:
		return _fail("the job should end '%s'" % want)
	# Give the report time to reach the guest before leaving.
	await get_tree().create_timer(3.0).timeout
	return true


func _join() -> bool:
	if not await _until(func(): return FileAccess.file_exists(_code_file) and FileAccess.get_file_as_string(_code_file) != ""):
		return _fail("no word from the host")
	if not Session.join_lan("127.0.0.1", int(LGSettings.get_value("lan", "port"))):
		return _fail("could not join")
	if not await _until(func(): return Session.crew.size() >= 2):
		return _fail("never got the crew")
	Session.set_cover(_guest_cover(), false)
	if not await _until(func(): return _scene() != null and _scene().net.synced):
		return _fail("the job never started here")
	var s := _scene()
	var gala := s.def.id == "meridian_gala"
	if s.job != null or s.cast.size() != s.def.cast().size():
		return _fail("a guest has puppets, not a job (%d)" % s.cast.size())
	if int(s.def.circuit.get("seed", 0)) != Session.circuit:
		return _fail("the host's Circuit night never came here (%d, %s)" % [Session.circuit, str(s.def.circuit)])
	print("in %s%s as %s" % [s.def.title, JobReportCard.night({"circuit": Session.circuit}), s.me.cover])
	# Up to Teo at the gala; anywhere else, whoever's nearest.
	var ch: Character = s.cast.get("teo") if gala else null
	if ch == null:
		for c in s.cast.values():
			if ch == null or c.global_position.distance_to(s.player.global_position) < ch.global_position.distance_to(s.player.global_position):
				ch = c
	var at := ch.global_position + ch.global_basis.z * 1.3
	s.player.global_position = Vector3(at.x, at.y + CrewMember.FEET, at.z)
	s.player.look_at(Vector3(ch.global_position.x, s.player.global_position.y, ch.global_position.z), Vector3.UP)
	await get_tree().create_timer(1.0).timeout
	var lines: Array = Covers.of(s.me.cover).get("lines", [])
	s._on_text_submitted("Good evening. Daily Ledger, I'm on the press list." if gala else str(lines[0]) if not lines.is_empty() else "Good evening.")
	if not await _until(func(): return s.hud._speaker.text.begins_with(ch.sheet.name)):
		return _fail("%s's answer never reached here (%s)" % [ch.sheet.name, s.hud._speaker.text])
	print("%s answered: %s" % [ch.sheet.name, s.hud._subtitle.text])
	if not s.def.phone.is_empty():
		var num: Dictionary = s.def.phone[0]
		var who := s.def.sheet(str(num.who))
		s._on_dialed(str(num.id), str(s.def.caller_ids.back()))
		if not await _until(func(): return s.hud._speaker.text == "%s (phone)" % who.name and s._call == who.id):
			return _fail("%s never picked up the phone (%s: %s)" % [who.name, s.hud._speaker.text, s.hud._subtitle.text])
		print("%s on the phone: %s" % [who.name, s.hud._subtitle.text])
		s._on_hung_up()
		if not await _until(func(): return s._call == ""):
			return _fail("the call never ended")
	if gala:
		if not await _until(func(): return s.venue.doors.ballroom.is_open):
			return _fail("never saw the ballroom open")
		s.player.global_transform = JobScene._player_at(s.venue.spots.ballroom_in)
	if not await _until(func(): return s.over):
		return _fail("no report from the host")
	print("report from the host: %s at %s" % [s.report.get("outcome"), s.report.get("clock")])
	if gala and str(s.report.get("outcome", "")) != "in":
		return _fail("the report should say we're in")
	if not bool(s.report.get("win", false)):
		return _fail("the report should say it came off")
	if not await _until(func(): return Session.mode == Session.Mode.NONE):
		return _fail("still in the crew after the host left")
	print("left when the host did")
	return true


## The cover the guest picks: the press at the gala, else the job's second.
func _guest_cover() -> String:
	Session.ensure_job()
	if Jobs.current.id == "meridian_gala":
		return "press"
	var order := Covers.order()
	return str(order[1] if order.size() > 1 else order[0])


func _scene() -> JobScene:
	return JobScene.current if is_instance_valid(JobScene.current) and JobScene.current.is_inside_tree() else null


func _on_status(text: String) -> void:
	print("  (%s) %s" % [_role, text])


func _until(cond: Callable) -> bool:
	var t := 0.0
	while not cond.call():
		if t > TIMEOUT:
			return false
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return true


func _fail(why: String) -> bool:
	printerr("net check (%s): %s" % [_role, why])
	return false
