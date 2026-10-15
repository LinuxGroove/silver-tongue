class_name Kit
extends RefCounted
## The hotel's pieces: Quaternius' Downtown City MegaKit, found by name,
## plus the collision layers and helpers for placing models in code. Rooms
## are built from these in code (see [ServiceDoorRoom]).
##
## Names are the kit's own file names without the extension ("Marble_Plain_4",
## "DoorFrame_Wooden", "Door_1"). `tools/probe_models.gd` prints their sizes:
## wall panels are 2 m wide, centred on x, standing on y = 0 with their face
## at z = 0 looking down +z; floor tiles are 4 m square with their top at y = 0.

const DOWNTOWN := "res://addons/quaternius/downtowncity"
const MODELS := "res://assets/models"

## Collision layers.
const LAYER_WORLD := 1
const LAYER_INTERACT := 2
const LAYER_PEOPLE := 4
const LAYER_PLAYER := 8
const LAYER_DOORS := 16
## What blocks sight and movement.
const LAYER_SOLID := LAYER_WORLD | LAYER_DOORS

static var _paths := {}
static var _scenes := {}
static var _materials := {}


## The file for a model name, or "" if there's none.
static func path(name: String) -> String:
	if _paths.is_empty():
		_index(DOWNTOWN)
		_index(MODELS)
	return _paths.get(name, "")


static func _index(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		# Exported games list "X.gltf.import" in place of "X.gltf".
		var file := f.trim_suffix(".import").trim_suffix(".remap")
		if file.ends_with(".gltf") or file.ends_with(".glb"):
			var key := file.get_basename()
			if not _paths.has(key):
				_paths[key] = dir.path_join(file)
	for sub in d.get_directories():
		_index(dir.path_join(sub))


static func has(name: String) -> bool:
	return path(name) != ""


static func scene(name: String) -> PackedScene:
	if not _scenes.has(name):
		var p := path(name)
		if p == "":
			push_error("Kit: no model called %s" % name)
			_scenes[name] = null
		else:
			_scenes[name] = load(p)
	return _scenes[name]


## Places a model with no collision. `yaw` is in radians.
static func model(parent: Node, name: String, pos: Vector3, yaw := 0.0, scale := Vector3.ONE) -> Node3D:
	var ps := scene(name)
	if ps == null:
		var n := Node3D.new()
		n.position = pos
		parent.add_child(n)
		return n
	var n: Node3D = ps.instantiate()
	n.name = name
	_strip_collision(n)
	n.position = pos
	n.rotation.y = yaw
	if scale != Vector3.ONE:
		n.scale = scale
	parent.add_child(n)
	return n


## The kit's own collision shapes come in as static bodies; rooms make their
## own, simpler ones, so those are dropped.
static func _strip_collision(n: Node) -> void:
	for c in n.get_children():
		if c is CollisionObject3D:
			# Keep what's visible under it.
			for m in c.get_children():
				if m is VisualInstance3D or (m is Node3D and m.get_child_count() > 0 and not m is CollisionShape3D):
					c.remove_child(m)
					n.add_child(m)
					m.transform = c.transform * m.transform
			n.remove_child(c)
			c.free()
		else:
			_strip_collision(c)


## Places a prop that blocks with a box around it. `pos` is the middle of
## its footprint, on the floor. Returns the body; the model is its child.
static func boxed(parent: Node, name: String, pos: Vector3, yaw := 0.0, layer := LAYER_WORLD) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.rotation.y = yaw
	body.collision_layer = layer
	body.collision_mask = 0
	parent.add_child(body)
	var n := model(body, name, Vector3.ZERO)
	var box := aabb_of(n)
	var c := box.get_center()
	n.position = Vector3(-c.x, 0, -c.z)
	box.position -= Vector3(c.x, 0, c.z)
	if box.size.length() > 0.0:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size.max(Vector3(0.05, 0.05, 0.05))
		cs.shape = shape
		cs.position = box.get_center()
		body.add_child(cs)
	return body


## An invisible box that blocks.
static func block(parent: Node, center: Vector3, size: Vector3, layer := LAYER_WORLD) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	body.collision_layer = layer
	body.collision_mask = 0
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


## A plain box mesh (ceilings, skirting, the odd prop), with no collision.
static func slab(parent: Node, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.position = center
	parent.add_child(mi)
	return mi


## The bounds of a node's meshes, in the node's parent's space.
static func aabb_of(n: Node3D) -> AABB:
	var acc := [null]
	_merge_aabb(n, n.transform, acc)
	return acc[0] if acc[0] != null else AABB()


static func _merge_aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is MeshInstance3D and n.mesh:
		var b: AABB = xf * n.mesh.get_aabb()
		acc[0] = b if acc[0] == null else acc[0].merge(b)
	for c in n.get_children():
		if c is Node3D:
			_merge_aabb(c, xf * c.transform, acc)


## A plain coloured material, cached.
static func flat(color: Color, roughness := 0.8, emission := Color.BLACK, energy := 1.0) -> StandardMaterial3D:
	var key := "%s/%s/%s/%s" % [color.to_html(), roughness, emission.to_html(), energy]
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		if emission != Color.BLACK:
			m.emission_enabled = true
			m.emission = emission
			m.emission_energy_multiplier = energy
		if color.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = m
	return _materials[key]
