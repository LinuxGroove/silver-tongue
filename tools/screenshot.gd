extends Node
## Pictures of the Meridian and of the gala in play:
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --resolution 1280x800 tools/screenshot.tscn -- --all=docs/screenshots [group=hotel|gala]
## writes <dir>/hotel/<view>.png (the hotel's views, Meridian.views, with the
## cast at their posts and the crowd) and <dir>/gala/<shot>.png (the gala
## with the staff on scripted lines: the briefing, the HUD, talking, papers,
## the keypad, the office, the report), each with a README listing them.
##   ... tools/screenshot.tscn -- --view=lobby --out=/tmp/lobby.png
## writes one view; `--only=lobby,bar` with --all shoots just those (and
## leaves the READMEs alone), and `--eye=x,y,z --at=x,y,z --out=<file>`
## looks from anywhere. For the real renderer on a machine with no GPU, set
## VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json (mesa-vulkan-drivers).

const SETTLE := 150
const FRAMES := 6
## What each view shows, for the README.
const ABOUT := {
	"street": "The street out front: the Meridian's arch, canopy and red carpet, the buildings across",
	"entrance": "Just inside the front doors, where the crew starts, looking up the lobby",
	"lobby": "The lobby from its south-west corner: the lounges, the columns, the chandelier",
	"reception": "Reception in the north-east corner, Dana's desk, the key cabinet and the clock",
	"bar": "The lobby bar on the west side, Benny's counter and the back bar",
	"ballroom_doors": "The ballroom doors, where Teo checks invitations, with the rope and the easel",
	"ballroom": "The ballroom from its doors: tables of eight, the chandeliers, the stage",
	"stage": "The stage: the curtain, the lectern, the covered piece, the dance floor",
	"pass": "The kitchen's pass from the service door: Laurent's post and the pass door",
	"kitchen": "The kitchen: the cooking line under its hood, the pass, the walk-in freezer",
	"staff_room": "The staff room: lockers, the bench and the rack of waiters' jackets",
	"corridor": "The service corridor from the loading door, the service door at the end",
	"service_door": "The service door (M0's), Marcus's post, and the keypad",
	"office": "The security office: the CCTV monitors, the desk",
	"loading_bay": "The loading bay: the dumpster, the gate onto the street, the loading door",
}
## The gala's shots, in order, for the README.
const GALA := {
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

var hotel: Meridian
var cam: Camera3D


func _ready() -> void:
	var view := ""
	var out := ""
	var all := ""
	var group := ""
	var only: Array = []
	var eye := ""
	var at := ""
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
		elif arg.begins_with("--only="):
			only = Array(arg.trim_prefix("--only=").split(","))
		elif arg.trim_prefix("--").begins_with("group="):
			group = arg.trim_prefix("--").trim_prefix("group=")
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	HotelTheme.apply(get_tree().root, 22)
	if all != "" and group != "gala":
		await _hotel_shots(all, only)
	if all != "" and group != "hotel":
		await _gala_shots(all.path_join("gala"), only)
	if all != "":
		get_tree().quit()
		return
	await _build_hotel()
	if eye != "" and at != "":
		# Anywhere, for a closer look: --eye=x,y,z --at=x,y,z.
		var e := eye.split_floats(",")
		var a := at.split_floats(",")
		hotel.views["_look"] = Transform3D.IDENTITY.looking_at(Vector3(a[0], a[1], a[2]) - Vector3(e[0], e[1], e[2]), Vector3.UP).translated(Vector3(e[0], e[1], e[2]))
		await _shoot("_look", out if out != "" else "/tmp/look.png")
	elif view != "":
		if not hotel.views.has(view):
			printerr("No view called %s; there are %s" % [view, ", ".join(_order())])
			get_tree().quit(1)
			return
		await _shoot(view, out if out != "" else "/tmp/%s.png" % view)
	else:
		printerr("Give --view=<name> [--out=<file>] or --all=<dir>")
		get_tree().quit(1)
		return
	get_tree().quit()


#region The hotel

func _build_hotel() -> void:
	var env := WorldEnvironment.new()
	env.environment = Meridian.environment()
	add_child(env)
	hotel = Meridian.new()
	add_child(hotel)
	_cast()
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 200.0
	add_child(cam)
	cam.make_current()
	for i in SETTLE:
		await get_tree().process_frame


func _hotel_shots(all: String, only: Array) -> void:
	await _build_hotel()
	var dir := all.path_join("hotel")
	DirAccess.make_dir_recursive_absolute(dir)
	var lines := ["# The Meridian", "", "Made by `tools/screenshot.tscn -- --all=docs/screenshots group=hotel` (see `tools/screenshot.gd`).", ""]
	for v in _order():
		if only.is_empty() or v in only:
			await _shoot(v, dir.path_join(v + ".png"))
		lines.append("- [`%s`](%s.png): %s" % [v, v, ABOUT.get(v, v)])
	if only.is_empty():
		_readme(dir, lines)
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame


func _order() -> Array:
	var out := []
	for v in ABOUT:
		if hotel.views.has(v):
			out.append(v)
	for v in hotel.views:
		if not v in out:
			out.append(v)
	return out


func _shoot(view: String, path: String) -> void:
	cam.global_transform = hotel.views[view]
	for i in FRAMES:
		await get_tree().process_frame
	_save(path)


## The cast at their posts and the crowd, posed, lit by their rooms.
func _cast() -> void:
	var n := 0
	for sheet in Cast.all():
		var p := Person.make(sheet.person_job, sheet.female, sheet.seed, sheet.person_look())
		hotel.add_child(p)
		p.global_transform = hotel.spots[sheet.spot]
		p.pose("Idle_FoldArms" if sheet.halberd else "Idle", 0.3)
		p.set_light_layers(hotel.light_layers_at(p.global_position))
	for zone in hotel.extras:
		for t in hotel.extras[zone]:
			n += 1
			var p := Person.make("kitchen" if zone == "kitchen" else "guest", n % 2 == 0, 500 + n)
			hotel.add_child(p)
			p.global_transform = t
			var clips := ["Idle", "Idle_Talking", "Idle_FoldArms"] if zone != "kitchen" else ["Idle", "Interact"]
			p.pose(clips[n % clips.size()], fmod(n * 0.37, 1.0))
			p.set_light_layers(hotel.light_layers_at(t.origin))

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
		await _until(func(): return s.hotel.doors.ballroom.is_open)
		await _frames(70)
		if want.call("papers"):
			_save(dir.path_join("papers.png"))
	if want.call("inside"):
		s.hotel.doors.ballroom.locked = false
		s.hotel.doors.ballroom.open()
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
		var rack: Node3D = s.hotel.uses.jackets
		_face(s, rack.global_position + Vector3(1.0, 0, 2.3), rack.global_position)
		s.hud._sub_t = 0.01
		await _frames(FRAMES * 3)
		_save(dir.path_join("jackets.png"))
	if want.call("keypad"):
		var pad: Node3D = s.hotel.uses.keypad
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
		var guard: Vector3 = s.hotel.spots.office_guard.origin
		s.player.look_at(Vector3(guard.x, s.player.global_position.y + 0.1, guard.z), Vector3.UP)
		await _frames(FRAMES * 4)
		_save(dir.path_join("held.png"))
		job._release(s.me.id, s.cast.marcus)
		await _frames(FRAMES)
	if want.call("report"):
		s.player.global_transform = JobScene._player_at(s.hotel.spots.ballroom_in)
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
