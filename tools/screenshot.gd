extends Node
## Pictures of the Meridian from its views (Meridian.views):
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --resolution 1280x800 tools/screenshot.tscn -- --all=docs/screenshots
## writes <dir>/hotel/<view>.png and a README listing them, and
##   ... tools/screenshot.tscn -- --view=lobby --out=/tmp/lobby.png
## writes one; `--only=lobby,bar` with --all shoots just those (and leaves the
## README alone), and `--eye=x,y,z --at=x,y,z --out=<file>` looks from
## anywhere. For the real renderer on a machine with no GPU, set
## VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json (mesa-vulkan-drivers).
## The hotel is empty for now: people go in _cast() once the cast stands in it.

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

var hotel: Meridian
var cam: Camera3D


func _ready() -> void:
	var view := ""
	var out := ""
	var all := ""
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
	HotelTheme.apply(get_tree().root, 22)
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
	if eye != "" and at != "":
		# Anywhere, for a closer look: --eye=x,y,z --at=x,y,z.
		var e := eye.split_floats(",")
		var a := at.split_floats(",")
		hotel.views["_look"] = Transform3D.IDENTITY.looking_at(Vector3(a[0], a[1], a[2]) - Vector3(e[0], e[1], e[2]), Vector3.UP).translated(Vector3(e[0], e[1], e[2]))
		await _shoot("_look", out if out != "" else "/tmp/look.png")
	elif all != "":
		var dir := all.path_join("hotel")
		DirAccess.make_dir_recursive_absolute(dir)
		var lines := ["# The Meridian", "", "Made by `tools/screenshot.tscn -- --all=docs/screenshots` (see `tools/screenshot.gd`).", ""]
		for v in _order():
			if only.is_empty() or v in only:
				await _shoot(v, dir.path_join(v + ".png"))
			lines.append("- [`%s`](%s.png): %s" % [v, v, ABOUT.get(v, v)])
		if only.is_empty():
			var f := FileAccess.open(dir.path_join("README.md"), FileAccess.WRITE)
			f.store_string("\n".join(lines) + "\n")
			f.close()
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
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("wrote ", path)


## Where the cast and the crowd will stand once people are in the hotel
## (hotel.spots and hotel.extras).
func _cast() -> void:
	pass
