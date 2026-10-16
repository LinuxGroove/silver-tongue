extends Node
## Plays the gala between two copies of the game over the local network,
## with the staff on scripted lines (no models). Run both at once, each with
## its own settings folder:
##   XDG_DATA_HOME=/tmp/a godot --headless --path . tools/net_check.tscn -- host /tmp/code &
##   XDG_DATA_HOME=/tmp/b godot --headless --path . tools/net_check.tscn -- join /tmp/code
## The guest joins, picks a cover and walks up to Teo; the host sees them
## arrive and move, and Teo's answer reaches the guest's subtitles. Then the
## host opens the ballroom, both walk in, and both get the report. Each
## prints "NET OK" and exits 0 when its side worked.

const TIMEOUT := 40.0

var _role := ""
var _code_file := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_role = args[0] if args.size() > 0 else "host"
	_code_file = args[1] if args.size() > 1 else "/tmp/silver-tongue-net-code"
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
	if not await _until(func(): return str(Session.crew[guest_id].cover) == "press"):
		return _fail("the guest's cover never changed")
	var crew := Session.job_crew()
	if not (crew[0].has_invitation and not crew[1].has_invitation):
		return _fail("the invitation should go to the host, the one guest: %s" % str(crew))
	Session.start_job()
	if not await _until(func(): return _scene() != null and _scene().job != null and not _scene().job.hold):
		return _fail("the guest's scene never said it was ready")
	var s := _scene()
	var avatar: CrewAvatar = s.avatars.get(guest_id)
	if avatar == null:
		return _fail("no body for the guest")
	print("the guest is here, dressed as %s" % s.job.crew_by_id(guest_id).outfit)
	var teo: Character = s.cast.teo
	if not await _until(func(): return avatar.global_position.distance_to(teo.global_position) < 3.0):
		return _fail("the guest never walked up to Teo (at %s)" % avatar.global_position)
	print("the guest walked up to Teo")
	if not await _until(func(): return teo.turns.any(func(t): return int(t.get("subject", 0)) == guest_id)):
		return _fail("Teo never heard the guest (lines %s, Teo's turns %d, busy %s, the guest at %s looking %s)" % [str(s.job.lines), teo.turns.size(), teo.busy, avatar.global_position, avatar.look_dir()])
	print("Teo heard the guest: %s" % str(teo.turns.back().get("reply", {}).get("say", "")))
	await get_tree().create_timer(2.0).timeout
	s.job._open_for("ballroom", 20.0)
	s.player.global_transform = JobScene._player_at(s.hotel.spots.ballroom_in)
	if not await _until(func(): return s.over):
		return _fail("the job never ended")
	print("the job ended: %s, %s" % [s.report.get("outcome"), s.report.get("clock")])
	if str(s.report.get("outcome", "")) != "in":
		return _fail("both inside should be 'in'")
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
	Session.set_cover("press", false)
	if not await _until(func(): return _scene() != null and _scene().net.synced):
		return _fail("the job never started here")
	var s := _scene()
	if s.job != null or s.cast.size() != 8:
		return _fail("a guest has puppets, not a job (%d)" % s.cast.size())
	print("in the gala as %s" % s.me.cover)
	var teo: Character = s.cast.teo
	var at := teo.global_position + teo.global_basis.z * 1.3
	s.player.global_position = Vector3(at.x, s.player.global_position.y, at.z)
	s.player.look_at(Vector3(teo.global_position.x, s.player.global_position.y, teo.global_position.z), Vector3.UP)
	await get_tree().create_timer(1.0).timeout
	s._on_text_submitted("Good evening. Daily Ledger, I'm on the press list.")
	if not await _until(func(): return s.hud._speaker.text.begins_with("Teo")):
		return _fail("Teo's answer never reached here")
	print("Teo answered: %s" % s.hud._subtitle.text)
	if not await _until(func(): return s.hotel.doors.ballroom.is_open):
		return _fail("never saw the ballroom open")
	s.player.global_transform = JobScene._player_at(s.hotel.spots.ballroom_in)
	if not await _until(func(): return s.over):
		return _fail("no report from the host")
	print("report from the host: %s at %s" % [s.report.get("outcome"), s.report.get("clock")])
	if str(s.report.get("outcome", "")) != "in":
		return _fail("the report should say we're in")
	if not await _until(func(): return Session.mode == Session.Mode.NONE):
		return _fail("still in the crew after the host left")
	print("left when the host did")
	return true


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
