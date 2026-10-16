class_name Person
extends Node3D
## Someone in the Meridian: a guard, a member of staff or a guest, a
## Universal Base Character animated with the Universal Animation Libraries.
## A job with real clothes ([constant WARDROBE], made by
## [code]tools/blender/wardrobe.py[/code]) wears them, with the body's own
## skin and eyes; anyone else is dressed by [code]person.gdshader[/code], which
## draws clothes on the rest pose (the shader and the bake come from Burn
## Rate's tower staff).

const MALE := "res://assets/people/Superhero_Male_FullBody.gltf"
const FEMALE := "res://assets/people/Superhero_Female_FullBody.gltf"
const UAL1 := "res://assets/people/UAL1_Standard.glb"
const UAL2 := "res://assets/people/UAL2_Standard.glb"
const HAIR := "res://assets/people/hair/%s.gltf"
const SHADER := preload("res://game/people/person.gdshader")
const WARDROBE_SHADER := preload("res://game/people/wardrobe.gdshader")
## An outfit fitted to a body: the outfit's name, then "male" or "female".
const OUTFIT := "res://assets/people/outfits/%s_%s.gltf"
const SKIN_TEXTURE := "res://assets/people/textures/T_Superhero_%s_Skin.png"
const EYE_TEXTURE := "res://assets/people/textures/T_Eye_Brown.png"
## The skin texture's own average colour, which it's tinted from to each skin.
const SKIN_MEAN := Color(0.65, 0.46, 0.32)

## What each job wears: the painted outfit (see the shader), its colours, and
## real clothes ("wardrobe", a key of [constant WARDROBE]) where it has them.
const JOBS := {
	"guard": {"outfit": 3, "main": Color(0.19, 0.195, 0.21), "accent": Color(0.85, 0.08, 0.12), "shirt": Color(0.86, 0.87, 0.88),
		"tie": Color(0.36, 0.05, 0.07), "wardrobe": "halberd_suit"},
	"staff": {"outfit": 2, "main": Color(0.16, 0.17, 0.22), "accent": Color(0.75, 0.15, 0.2), "shirt": Color(0.9, 0.9, 0.92)},
	"guest": {"outfit": 2, "main": Color(0.3, 0.22, 0.16), "accent": Color(0.4, 0.55, 0.3), "shirt": Color(0.85, 0.82, 0.75)},
	"kitchen": {"outfit": 4, "main": Color(0.9, 0.9, 0.9), "accent": Color(0.2, 0.2, 0.2), "shirt": Color(0.95, 0.95, 0.95)},
}
## Real clothes, piece by piece (the outfit's mesh names): a colour (or the
## job's colour of that name), roughness, mottle, sheen and metallic.
const WARDROBE := {
	"halberd_suit": {
		"Suit": ["main", 0.82, 0.14, 0.3, 0.0], "Skirt": ["main", 0.82, 0.14, 0.3, 0.0],
		"Trousers": ["main", 0.82, 0.14, 0.3, 0.0], "Shirt": ["shirt", 0.7, 0.05, 0.15, 0.0],
		"Tie": ["tie", 0.55, 0.12, 0.35, 0.0], "Shoes": [Color(0.03, 0.03, 0.035), 0.22, 0.0, 0.0, 0.0],
		"Buttons": [Color(0.04, 0.04, 0.045), 0.35, 0.0, 0.0, 0.0], "Pin": ["accent", 0.3, 0.0, 0.0, 0.6],
		"Earpiece": [Color(0.05, 0.05, 0.06), 0.4, 0.0, 0.0, 0.0],
	},
}
const SKINS := [Color(0.88, 0.69, 0.56), Color(0.78, 0.56, 0.44), Color(0.6, 0.42, 0.3), Color(0.42, 0.28, 0.2), Color(0.3, 0.2, 0.15)]
const HAIR_COLORS := [Color(0.08, 0.06, 0.05), Color(0.25, 0.15, 0.08), Color(0.5, 0.35, 0.18), Color(0.62, 0.58, 0.52), Color(0.55, 0.22, 0.1), Color(0.75, 0.6, 0.35)]
const HAIR_STYLES := {
	"female": ["Hair_Buns", "Hair_Long", "Hair_BuzzedFemale", "Hair_SimpleParted"],
	"male": ["Hair_SimpleParted", "Hair_Buzzed", "Hair_Long", "Hair_SimpleParted"],
}
## Clips that loop.
const LOOPS := ["Idle", "Jump", "Sprint", "Jog_Fwd", "Walk", "Walk_Formal", "Crouch_Idle", "Crouch_Fwd",
	"Driving", "Slide", "Idle_TalkingPhone", "NinjaJump_Idle", "Sitting_Idle", "Idle_Talking",
	"Sitting_Talking", "Dance", "Swim_Idle", "Swim_Fwd", "Idle_FoldArms", "Idle_No", "Push",
	"Spell_Simple_Idle", "Zombie_Idle", "Idle_Rail", "Idle_Lantern", "Idle_Torch"]
## Bones that make up each region, for the shader.
const HEAD_BONES := ["Head", "neck_01"]
const FOOT_BONES := ["foot_l", "foot_r", "ball_l", "ball_r", "ball_leaf_l", "ball_leaf_r"]

static var _libs := {}
static var _baked := {}
static var _mats := {}
static var _hair_mats := {}
static var _piece_mats := {}

var job := "staff"
var female := false
## The outfit this person wears ("" when the shader paints one on).
var outfit := ""
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var meshes: Array[MeshInstance3D] = []
## Where the eyes are in the model's space (from the Eyes mesh), for the face.
var eyes_at := Vector3(0, 1.68, 0.065)
var _current := ""


## A person. `look` can set "skin", "hair" and "style" (indexes), "beard"
## and the "main", "accent", "shirt" and "tie" colours; anything missing comes from
## `seed`. `p_job` is a key of [constant JOBS].
static func make(p_job := "staff", p_female := false, seed := 0, look := {}) -> Person:
	var c := Person.new()
	c.name = "Person"
	c.job = p_job if JOBS.has(p_job) else "staff"
	c.female = p_female
	c._build(seed, look)
	return c


func _build(seed: int, look: Dictionary) -> void:
	var j: Dictionary = JOBS[job].duplicate()
	var dressed := OUTFIT % [j.get("wardrobe", ""), "female" if female else "male"]
	if j.has("wardrobe") and ResourceLoader.exists(dressed):
		outfit = str(j.wardrobe)
	var ps: PackedScene = load(dressed if outfit != "" else (FEMALE if female else MALE))
	model = ps.instantiate()
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var skin_i := int(look.get("skin", r.randi() % SKINS.size())) % SKINS.size()
	var hair_i := int(look.get("hair", r.randi() % HAIR_COLORS.size())) % HAIR_COLORS.size()
	var styles: Array = HAIR_STYLES["female" if female else "male"]
	var style_i := int(look.get("style", r.randi() % styles.size())) % styles.size()
	for k in ["main", "accent", "shirt", "legs", "tie"]:
		if look.has(k):
			j[k] = look[k]
	j["wrist"] = 0.6 if female else 0.66
	var mat := _material(j, skin_i)
	for mi in model.find_children("", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		meshes.append(m)
		if m.name.begins_with("Eye"):
			if m.name == "Eyes" and m.mesh:
				eyes_at = m.mesh.get_aabb().get_center()
			m.material_override = _eye_material() if m.name == "Eyes" else Kit.flat(HAIR_COLORS[hair_i] * 0.7, 0.4)
			continue
		m.mesh = bake(m.mesh, m.skin, skeleton)
		m.material_override = _piece_material(outfit, String(m.name), j, skin_i) if outfit != "" else mat
	_add_hair(str(styles[style_i]), HAIR_COLORS[hair_i])
	if not female and bool(look.get("beard", r.randf() < 0.3)):
		_add_hair("Hair_Beard", HAIR_COLORS[hair_i])
	anim = AnimationPlayer.new()
	anim.name = "Anim"
	model.add_child(anim)
	anim.add_animation_library("ual1", _lib(UAL1))
	anim.add_animation_library("ual2", _lib(UAL2))
	anim.playback_default_blend_time = 0.2


## Hair models are made in the rest pose's space, so they ride the head bone
## offset by its rest.
func _add_hair(style: String, color: Color) -> void:
	var path := HAIR % style
	if skeleton == null or not ResourceLoader.exists(path):
		return
	var at := on_head()
	if at == null:
		return
	var hair: Node3D = (load(path) as PackedScene).instantiate()
	at.add_child(hair)
	var key := color.to_html()
	for mi in hair.find_children("", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var base: Material = m.mesh.surface_get_material(0) if m.mesh else null
		if base is StandardMaterial3D:
			var k := "%s/%s" % [key, base.resource_name]
			if not _hair_mats.has(k):
				var hm: StandardMaterial3D = base.duplicate()
				hm.albedo_color = color * 2.2
				_hair_mats[k] = hm
			m.material_override = _hair_mats[k]


## A node that rides the head, in the model's rest space (so a point from
## [member eyes_at] can be placed under it as it is).
func on_head() -> Node3D:
	if skeleton == null:
		return null
	var head := skeleton.find_bone("Head")
	if head < 0:
		return null
	var at := BoneAttachment3D.new()
	at.bone_name = "Head"
	skeleton.add_child(at)
	var rest := Node3D.new()
	rest.name = "Rest"
	rest.transform = skeleton.get_bone_global_rest(head).affine_inverse()
	at.add_child(rest)
	return rest


static func _material(j: Dictionary, skin_i: int) -> ShaderMaterial:
	var key := "%s/%s/%s/%s/%s/%s/%d" % [j.outfit, j.main.to_html(), j.accent.to_html(), j.get("shirt", Color.WHITE).to_html(), j.get("legs", Color.BLACK).to_html(), j.get("wrist", 0.66), skin_i]
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("outfit", int(j.outfit))
		m.set_shader_parameter("main_color", j.main)
		m.set_shader_parameter("accent", j.accent)
		for k in ["shirt", "legs"]:
			if j.has(k):
				m.set_shader_parameter(k, j[k])
		m.set_shader_parameter("wrist", float(j.get("wrist", 0.66)))
		m.set_shader_parameter("skin", SKINS[skin_i])
		_mats[key] = m
	return _mats[key]


## A piece of an outfit, or the skin under it (any mesh the outfit doesn't list).
func _piece_material(p_outfit: String, piece: String, j: Dictionary, skin_i: int) -> ShaderMaterial:
	var look: Array = WARDROBE[p_outfit].get(piece, [])
	var col: Color = SKINS[skin_i]
	if not look.is_empty():
		col = look[0] if look[0] is Color else j.get(look[0], Color.MAGENTA)
	var key := "%s/%s/%s/%s" % [p_outfit, piece, col.to_html(), "f" if female else "m"]
	if _piece_mats.has(key):
		return _piece_mats[key]
	var m := ShaderMaterial.new()
	m.shader = WARDROBE_SHADER
	m.set_shader_parameter("color", col)
	if look.is_empty():
		var tex_path := SKIN_TEXTURE % ("Female" if female else "Male")
		if ResourceLoader.exists(tex_path):
			m.set_shader_parameter("textured", true)
			m.set_shader_parameter("tex", load(tex_path))
			m.set_shader_parameter("tex_mean", SKIN_MEAN)
		m.set_shader_parameter("roughness", 0.62)
		m.set_shader_parameter("specular", 0.35)
	else:
		m.set_shader_parameter("roughness", float(look[1]))
		m.set_shader_parameter("mottle", float(look[2]))
		m.set_shader_parameter("sheen", float(look[3]))
		m.set_shader_parameter("metallic", float(look[4]))
	_piece_mats[key] = m
	return m


static func _eye_material() -> Material:
	if not _piece_mats.has("eyes"):
		var m := StandardMaterial3D.new()
		m.albedo_texture = load(EYE_TEXTURE)
		m.roughness = 0.25
		_piece_mats["eyes"] = m
	return _piece_mats["eyes"]


static func _lib(path: String) -> AnimationLibrary:
	if not _libs.has(path):
		var lib: AnimationLibrary = load(path)
		for n in lib.get_animation_list():
			var a := lib.get_animation(n)
			a.loop_mode = Animation.LOOP_LINEAR if String(n) in LOOPS else Animation.LOOP_NONE
		_libs[path] = lib
	return _libs[path]


## A copy of a skinned body mesh with its rest pose in CUSTOM0 and how much
## of each vertex is head, hand and foot in CUSTOM1 (cached per mesh).
static func bake(mesh: Mesh, skin: Skin, skel: Skeleton3D) -> Mesh:
	if mesh == null or _baked.has(mesh):
		return _baked.get(mesh, mesh)
	var region_of := {}
	if skin:
		for i in skin.get_bind_count():
			var bname := String(skin.get_bind_name(i))
			if bname == "" and skel:
				bname = skel.get_bone_name(skin.get_bind_bone(i))
			var reg := Vector3.ZERO
			if bname in HEAD_BONES:
				reg = Vector3(1, 0, 0)
			elif bname.begins_with("hand_") or bname.begins_with("index_") or bname.begins_with("middle_") or bname.begins_with("ring_") or bname.begins_with("pinky_") or bname.begins_with("thumb_"):
				reg = Vector3(0, 1, 0)
			elif bname in FOOT_BONES:
				reg = Vector3(0, 0, 1)
			region_of[i] = reg
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		var fmt: int = (mesh as ArrayMesh).surface_get_format(s) if mesh is ArrayMesh else 0
		var per := 8 if fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS else 4
		var c0 := PackedFloat32Array()
		var c1 := PackedFloat32Array()
		c0.resize(verts.size() * 3)
		c1.resize(verts.size() * 4)
		for i in verts.size():
			c0[i * 3] = verts[i].x
			c0[i * 3 + 1] = verts[i].y
			c0[i * 3 + 2] = verts[i].z
			var reg := Vector3.ZERO
			if bones != null and weights != null and bones.size() >= (i + 1) * per:
				for k in per:
					reg += region_of.get(int(bones[i * per + k]), Vector3.ZERO) * float(weights[i * per + k])
			c1[i * 4] = reg.x
			c1[i * 4 + 1] = reg.y
			c1[i * 4 + 2] = reg.z
			c1[i * 4 + 3] = 0.0
		arrays[Mesh.ARRAY_CUSTOM0] = c0
		arrays[Mesh.ARRAY_CUSTOM1] = c1
		var flags: int = (fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) | (Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
		out.add_surface_from_arrays(mesh.surface_get_primitive_type(s), arrays, [], {}, flags)
	_baked[mesh] = out
	return out


## Plays a clip from either library by name ("Idle_Talking", "Yes").
func play(clip: String, blend := -1.0, speed := 1.0, restart := false) -> void:
	var full := clip_path(clip)
	if full == "":
		return
	anim.speed_scale = speed
	if full == _current and not restart and anim.is_playing():
		return
	_current = full
	anim.play(full, blend)
	if restart:
		anim.seek(0.0, true)


## Holds a clip at a moment (0 to 1 of its length).
func pose(clip: String, at := 1.0) -> void:
	var full := clip_path(clip)
	if full == "":
		return
	anim.play(full, 0.0)
	var a := anim.get_animation(full)
	anim.seek(a.length * clampf(at, 0.0, 0.999), true)
	anim.pause()
	_current = full


func current() -> String:
	return _current.get_slice("/", 1)


func clip_path(clip: String) -> String:
	for lib in ["ual1", "ual2"]:
		var p := "%s/%s" % [lib, clip]
		if anim.has_animation(p):
			return p
	push_warning("Person: no clip %s" % clip)
	return ""


func clip_length(clip: String) -> float:
	var p := clip_path(clip)
	return anim.get_animation(p).length if p != "" else 0.0


func bone_position(bone: String) -> Vector3:
	var i := skeleton.find_bone(bone)
	if i < 0:
		return global_position
	return skeleton.global_transform * skeleton.get_bone_global_pose(i).origin
