extends Node
## Pictures of the venues and of the jobs in play:
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --resolution 1280x800 tools/screenshot.tscn -- --all=docs/screenshots [group=hotel|gala|jobs|<venue>]
## writes <dir>/hotel/<view>.png (the Meridian's views, with the gala's cast
## at their posts and the crowd), <dir>/<venue>/<view>.png for every other
## venue (marlin, tideline, vantage, mae: its views, with its first job's
## cast), <dir>/gala/<shot>.png (the gala with the staff on scripted lines:
## the briefing, the HUD, talking, papers, the keypad, the office, the
## report) and <dir>/jobs/<job>.png (each job's first moment, from where
## the crew starts), each with a README listing them.
##   ... tools/screenshot.tscn -- [--venue=marlin] --view=deck --out=/tmp/deck.png
## writes one view; `--only=lobby,bar` with --all shoots just those (and
## leaves the READMEs alone), and `--eye=x,y,z --at=x,y,z --out=<file>`
## looks from anywhere. For the real renderer on a machine with no GPU, set
## VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json (mesa-vulkan-drivers).

const SETTLE := 150
const FRAMES := 6
## The gala's shots, in order, for the README.
const GALA := {
	"board": "Mae's back room: the season's jobs venue by venue, how each came off, the take and Halberd's file",
	"circuit": "The Circuit: this week's contract, rolling a night, or playing one a friend shared",
	"briefing": "The title's gala page: Auntie Mae's briefing, the four covers and how to play",
	"crew": "Hosting a crew on the network: the code, who's in and in what cover",
	"start": "8:45 pm, just inside the front doors: the clock, the heat, your cover",
	"teo": "Talking to Teo at the ballroom doors: your words, his answer, what he makes of you",
	"papers": "Showing Teo the forged invitation; it passes, and he opens the doors",
	"inside": "Inside the ballroom, among the guests",
	"bar": "Celeste and Hugo at the bar, asked for a plus-one",
	"jackets": "The staff room's rack of waiters' jackets, and what Interact does",
	"keypad": "The keypad by the service door, with the kitchen code half typed",
	"held": "Called in: held in the security office, with its door locked",
	"report": "The job report: how it went, the scores, the night's best and worst lines",
}

var venue: Venue
var cam: Camera3D


func _ready() -> void:
	var view := ""
	var out := ""
	var all := ""
	var group := ""
	var only: Array = []
	var eye := ""
	var at := ""
	var venue_id := "meridian"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--eye="):
			eye = arg.trim_prefix("--eye=")
		elif arg.begins_with("--at="):
			at = arg.trim_prefix("--at=")
		elif arg.begins_with("--view="):
			view = arg.trim_prefix("--view=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--all="):
			all = arg.trim_prefix("--all=")
		elif arg.begins_with("--venue="):
			venue_id = arg.trim_prefix("--venue=")
		elif arg.begins_with("--only="):
			only = Array(arg.trim_prefix("--only=").split(","))
		elif arg.trim_prefix("--").begins_with("group="):
			group = arg.trim_prefix("--").trim_prefix("group=")
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	HotelTheme.apply(get_tree().root, 22)
	if all != "":
		for v in Jobs.VENUES:
			var folder := "hotel" if v == "meridian" else str(v)
			if (group == "" or group == folder) and not Jobs.at_venue(v).filter(func(j): return Jobs.exists(j)).is_empty():
				await _venue_shots(v, all.path_join(folder), only)
		if group in ["", "gala"]:
			await _gala_shots(all.path_join("gala"), only)
		if group in ["", "jobs"]:
			await _job_shots(all.path_join("jobs"), only)
		get_tree().quit()
		return
	await _build_venue(venue_id)
	if eye != "" and at != "":
		# Anywhere, for a closer look: --eye=x,y,z --at=x,y,z.
		var e := eye.split_floats(",")
		var a := at.split_floats(",")
		venue.views["_look"] = Transform3D.IDENTITY.looking_at(Vector3(a[0], a[1], a[2]) - Vector3(e[0], e[1], e[2]), Vector3.UP).translated(Vector3(e[0], e[1], e[2]))
		await _shoot("_look", out if out != "" else "/tmp/look.png")
	elif view != "":
		if not venue.views.has(view):
			printerr("No view called %s; there are %s" % [view, ", ".join(_order(venue.view_about))])
			get_tree().quit(1)
			return
		await _shoot(view, out if out != "" else "/tmp/%s.png" % view)
	else:
		printerr("Give --view=<name> [--out=<file>] or --all=<dir>")
		get_tree().quit(1)
		return
	get_tree().quit()


#region The venues

## A venue's first job built so far, for its cast and crowd.
func _first_job(venue_id: String) -> JobDef:
	for j in Jobs.at_venue(venue_id):
		if Jobs.exists(j):
			return Jobs.make(j)
	return null


func _build_venue(venue_id: String) -> void:
	var def := _first_job(venue_id)
	Jobs.current = def
	Person.add_looks(def.looks)
	venue = def.venue()
	var env := WorldEnvironment.new()
	env.environment = venue.environment()
	add_child(env)
	add_child(venue)
	if venue.spots.is_empty():
		venue.build()
	_cast(def)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 200.0
	add_child(cam)
	cam.make_current()
	for i in SETTLE:
		await get_tree().process_frame


func _venue_shots(venue_id: String, dir: String, only: Array) -> void:
	await _build_venue(venue_id)
	DirAccess.make_dir_recursive_absolute(dir)
	var lines := ["# %s" % Jobs.VENUES[venue_id], "", "Made by `tools/screenshot.tscn -- --all=docs/screenshots group=%s` (see `tools/screenshot.gd`)." % dir.get_file(), ""]
	var about: Dictionary = venue.view_about
	for v in _order(about):
		if only.is_empty() or v in only:
			await _shoot(v, dir.path_join(v + ".png"))
		lines.append("- [`%s`](%s.png): %s" % [v, v, about.get(v, v)])
	if only.is_empty():
		_readme(dir, lines)
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame


func _order(about: Dictionary) -> Array:
	var out := []
	for v in about:
		if venue.views.has(v):
			out.append(v)
	for v in venue.views:
		if not v in out:
			out.append(v)
	return out


func _shoot(view: String, path: String) -> void:
	cam.global_transform = venue.views[view]
	for i in FRAMES:
		await get_tree().process_frame
	_save(path)


## The cast at their posts and the crowd, posed, lit by their rooms.
func _cast(def: JobDef) -> void:
	var n := 0
	for sheet in def.sheets():
		var p := Person.make(sheet.person_job, sheet.female, sheet.seed, sheet.person_look())
		venue.add_child(p)
		p.global_transform = venue.spots.get(sheet.spot, Transform3D.IDENTITY)
		p.pose("Idle_FoldArms" if sheet.halberd else "Idle", 0.3)
		p.set_light_layers(venue.light_layers_at(p.global_position))
	for zone in venue.extras:
		var dress: Variant = def.extras.get(zone, "guest")
		var as_job := str(dress.get("job", "guest")) if dress is Dictionary else str(dress)
		var clips: Array = dress.get("clips", []) if dress is Dictionary else []
		if clips.is_empty():
			clips = ["Idle", "Interact"] if as_job == "kitchen" else ["Idle", "Idle_Talking", "Idle_FoldArms"]
		for t in venue.extras[zone]:
			n += 1
			var p := Person.make(as_job, n % 2 == 0, 500 + n)
			venue.add_child(p)
			p.global_transform = t
			p.pose(clips[n % clips.size()], fmod(n * 0.37, 1.0))
			p.set_light_layers(venue.light_layers_at(t.origin))

#endregion

#region Every job's first moment

func _job_shots(dir: String, only: Array) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	LGSettings.set_value("ai", "mode", "off", false)
	LGSettings.set_value("voice", "talk", "text", false)
	LGSettings.set_value("voice", "speaking", false, false)
	var lines := ["# The jobs", "", "Made by `tools/screenshot.tscn -- --all=docs/screenshots group=jobs` (see `tools/screenshot.gd`): each job's first moment, alone, in its first cover, from where the crew starts.", ""]
	for j in Jobs.available():
		var def := Jobs.make(j)
		lines.append("- [`%s`](%s.png): %s, %s. %s" % [j, j, def.title, def.venue_name, def.goal])
		if not only.is_empty() and not j in only:
			continue
		Session.start_solo(def.first_cover(), j.hash() % 2 == 0)
		JobScene.setup = JobScene.solo(def.first_cover(), j.hash() % 2 == 0, "Ruby", j)
		var s: JobScene = load(JobScene.SCENE).instantiate()
		add_child(s)
		await _frames(SETTLE)
		s.job.hold = true
		await _frames(FRAMES)
		_save(dir.path_join(j + ".png"))
		s.queue_free()
		Session.leave()
		await _frames(4)
	if only.is_empty():
		_readme(dir, lines)

#endregion

#region The gala

func _gala_shots(dir: String, only: Array) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	LGSettings.set_value("ai", "mode", "off", false)
	LGSettings.set_value("voice", "talk", "text", false)
	LGSettings.set_value("voice", "speaking", false, false)
	LGSettings.set_value("player", "name", "Ruby", false)
	var want := func(shot: String) -> bool: return only.is_empty() or shot in only
	# The title's pages.
	var title: Node = load("res://game/ui/title.tscn").instantiate()
	add_child(title)
	await _frames(SETTLE)
	if want.call("board") or want.call("circuit"):
		# A season a job in, on its own file so a real one is never touched.
		Progress.load_from("user://shot_progress.cfg")
		Progress.reset()
		Progress.record({"job": "meridian_gala", "venue": "meridian", "outcome": "in", "win": true, "take": 2000,
			"clean": true, "quiet": false, "silver": true, "crew": [{"id": 1, "was_held": false}]}, 1)
		Progress.record({"job": "meridian_list", "venue": "meridian", "outcome": "held", "win": false,
			"crew": [{"id": 1, "was_held": true}]}, 1)
		if want.call("board"):
			title.show_board()
			await _frames(FRAMES)
			_save(dir.path_join("board.png"))
		if want.call("circuit"):
			LGSettings.set_value("play", "all_jobs", true, false)
			title.show_circuit()
			await _frames(FRAMES)
			_save(dir.path_join("circuit.png"))
			LGSettings.set_value("play", "all_jobs", false, false)
		Progress.reset()
	if want.call("briefing"):
		title.show_gala()
		await _frames(FRAMES)
		_save(dir.path_join("briefing.png"))
	if want.call("crew"):
		title._host()
		await _frames(FRAMES)
		_save(dir.path_join("crew.png"))
	Session.leave()
	title.queue_free()
	await _frames(2)
	# The night itself, alone, as the guest with the invitation.
	Session.start_solo("guest", true)
	JobScene.setup = JobScene.solo("guest", true, "Ruby")
	var s: JobScene = load(JobScene.SCENE).instantiate()
	add_child(s)
	await _frames(SETTLE)
	var job := s.job
	job.hold = true
	if want.call("start"):
		_save(dir.path_join("start.png"))
	var teo: Character = s.cast.teo
	_face(s, teo.global_position + teo.global_basis.z * 1.4, teo.global_position)
	await _frames(FRAMES)
	if want.call("teo") or want.call("papers"):
		s._on_text_submitted("Good evening. I'm on the guest list, I was invited.")
		await _until(func(): return teo.turns.size() >= 1 and not teo.busy and s.hud._subtitle.text != "")
		await _frames(30)
		if want.call("teo"):
			_save(dir.path_join("teo.png"))
		await _frames(2)
		s._on_use_pressed()
		await _until(func(): return s.venue.doors.ballroom.is_open)
		await _frames(70)
		if want.call("papers"):
			_save(dir.path_join("papers.png"))
	if want.call("inside"):
		s.venue.doors.ballroom.locked = false
		s.venue.doors.ballroom.open()
		_face(s, Vector3(-5.5, 0, -21.5), Vector3(-1.0, 1.0, -28.0))
		await _frames(FRAMES * 4)
		_save(dir.path_join("inside.png"))
	if want.call("bar"):
		var celeste: Character = s.cast.celeste
		var hugo: Character = s.cast.hugo
		var mid := (celeste.global_position + hugo.global_position) * 0.5
		_face(s, mid + Vector3(0.2, 0, 1.6), mid)
		await _frames(FRAMES)
		s._on_text_submitted("Would you take me in on your arm? I'll be the perfect plus-one.")
		await _until(func(): return (celeste.turns.size() >= 1 or hugo.turns.size() >= 1) and s.hud._subtitle.text != "")
		await _frames(30)
		_save(dir.path_join("bar.png"))
	if want.call("jackets"):
		var rack: Node3D = s.venue.uses.jackets
		_face(s, rack.global_position + Vector3(1.0, 0, 2.3), rack.global_position)
		s.hud._sub_t = 0.01
		await _frames(FRAMES * 3)
		_save(dir.path_join("jackets.png"))
	if want.call("keypad"):
		var pad: Node3D = s.venue.uses.keypad
		# Back far enough that the service door shows beside the panel.
		_face(s, pad.global_position + Vector3(-1.9, 0, 2.4), pad.global_position + Vector3(-1.1, 0, 0))
		await _frames(FRAMES)
		s.keypad.ask()
		for k in ["4", "4", "7"]:
			s.keypad.press(k)
		await _frames(FRAMES)
		_save(dir.path_join("keypad.png"))
		s.keypad.close()
		s.player.is_movement_paused = false
	if want.call("held"):
		job._hold(s.me.id, s.cast.marcus)
		await _frames(60)
		var guard: Vector3 = s.venue.spots.office_guard.origin
		s.player.look_at(Vector3(guard.x, s.player.global_position.y + 0.1, guard.z), Vector3.UP)
		await _frames(FRAMES * 4)
		_save(dir.path_join("held.png"))
		job._release(s.me.id, s.cast.marcus)
		await _frames(FRAMES)
	if want.call("report"):
		s.player.global_transform = JobScene._player_at(s.venue.spots.ballroom_in)
		s.player.reset_physics_interpolation()
		s.hud._toast_t = 0.01
		job.hold = false
		await _until(func(): return s.over)
		await _frames(FRAMES * 2)
		_save(dir.path_join("report.png"))
	if only.is_empty():
		var lines := ["# The gala", "", "Made by `tools/screenshot.tscn -- --all=docs/screenshots group=gala` (see `tools/screenshot.gd`): the gala alone, as the guest, with the staff on scripted lines.", ""]
		for shot in GALA:
			lines.append("- [`%s`](%s.png): %s" % [shot, shot, GALA[shot]])
		_readme(dir, lines)
	s.queue_free()
	await _frames(2)


## Stands the player at `at` looking at `target`.
func _face(s: JobScene, at: Vector3, target: Vector3) -> void:
	var feet := Vector3(at.x, 0.0, at.z)
	s.player.global_position = feet + Vector3(0, CrewMember.FEET, 0)
	s.player.look_at(Vector3(target.x, s.player.global_position.y, target.z), Vector3.UP)
	s.player.reset_physics_interpolation()

#endregion

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _until(cond: Callable, seconds := 15.0) -> void:
	var t := 0.0
	while not cond.call() and t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()


func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("wrote ", path)


func _readme(dir: String, lines: Array) -> void:
	var f := FileAccess.open(dir.path_join("README.md"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
