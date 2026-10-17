extends SceneTree
## Prints the size of the kit's pieces and the people's rigs, for laying
## rooms out in code and placing things on a body:
##   godot --headless --path . -s tools/probe_models.gd [-- Door_1 Floor_4x4]
## With no names it prints every vendored Downtown City piece, then the
## Universal Base Characters: their height, head bone and eyes, and the
## clips in the animation libraries.

const DOWNTOWN := "res://addons/quaternius/downtowncity"


func _init() -> void:
	var names: Array = Array(OS.get_cmdline_user_args())
	if names.is_empty():
		var d := DirAccess.open(DOWNTOWN)
		if d:
			for f in d.get_files():
				if f.ends_with(".gltf") or f.ends_with(".glb"):
					names.append(f.get_basename())
		names.sort()
	for n in names:
		var p := DOWNTOWN.path_join(n + ".gltf")
		if not ResourceLoader.exists(p):
			p = DOWNTOWN.path_join(n + ".glb")
		if not ResourceLoader.exists(p):
			print("%s: not found" % n)
			continue
		var scene: PackedScene = load(p)
		var inst: Node3D = scene.instantiate()
		var box := _aabb(inst, Transform3D())
		print("%-28s pos %s  size %s  end %s" % [n, _v(box.position), _v(box.size), _v(box.end)])
		inst.free()
	if OS.get_cmdline_user_args().is_empty():
		for body in ["Superhero_Male_FullBody", "Superhero_Female_FullBody"]:
			_probe_body("res://assets/people/%s.gltf" % body)
		for lib in ["UAL1_Standard", "UAL2_Standard"]:
			var l: AnimationLibrary = load("res://assets/people/%s.glb" % lib)
			if l:
				var clips: Array = Array(l.get_animation_list())
				clips.sort()
				print("%s: %s" % [lib, ", ".join(PackedStringArray(clips))])
	quit()


func _probe_body(path: String) -> void:
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var box := _aabb(inst, Transform3D())
	print("%s: size %s" % [path.get_file(), _v(box.size)])
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if skel:
		for b in ["Head", "neck_01", "jaw", "spine_03", "hand_r"]:
			var i := skel.find_bone(b)
			if i >= 0:
				print("  bone %-9s rest %s" % [b, _v(skel.get_bone_global_rest(i).origin)])
		print("  bones: %d" % skel.get_bone_count())
	for mi in inst.find_children("", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var mb := m.mesh.get_aabb() if m.mesh else AABB()
		print("  mesh %-12s pos %s size %s" % [m.name, _v(mb.position), _v(mb.size)])
	inst.free()


static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var acc := AABB()
	var first := true
	var stack := [[n, xf]]
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var t: Transform3D = item[1]
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var b: AABB = t * (node as MeshInstance3D).mesh.get_aabb()
			acc = b if first else acc.merge(b)
			first = false
		for c in node.get_children():
			stack.append([c, t * c.transform if c is Node3D else t])
	return acc


static func _v(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
