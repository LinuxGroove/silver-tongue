class_name Venue
extends Node3D
## A venue built in code: its rooms (zones), the doors, where people stand
## (spots) and walk (points and links), things to use, the crowd (extras),
## camera views, and the building blocks every venue is made of (the Downtown
## City kit's walls and floors, materials, lights, the street outside). The
## Meridian is one; the Marlin, the Tideline, Vantage Tower and Mae's house
## are the others. docs/m2.md says how to build one.
##
## X runs east and Z south, the floor is y = 0 (a venue with more than one
## level puts its decks or floors where it likes, and its zones say which is
## which). Spots and points stand on the floor, a spot's +Z is the way it
## faces (people face +Z), and a view is a camera transform looking down -Z.
##
## Rooms keep their meshes on their own render layer, and a room's lights only
## light that layer and layer 1 (people, doors), so no light leaks through a
## wall. Something that moves between rooms takes [method light_layers_at]
## for where it stands.

## How far a room's wall face sits in from the line between two rooms: walls
## between rooms are twice this thick.
const T := 0.2
const WARM := Color(1.0, 0.86, 0.69)
const CANDLE := Color(1.0, 0.75, 0.5)
const COOL := Color(0.86, 0.93, 1.0)
const SODIUM := Color(1.0, 0.7, 0.42)

## Doors ([HotelDoor]) by name.
var doors := {}
## Things to Interact with, by id: each a StaticBody3D on
## [constant Kit.LAYER_INTERACT] with the meta "use" = its id ("keypad",
## "item:guest_list", "case", ...). The job decides what using one does.
var uses := {}
## Where people stand, by name: a Transform3D on the floor facing its +Z.
var spots := {}
## Where people walk: named points on the floor, and links between them, each
## [a, b, door] with the door they go through ("" for none).
var points := {}
var links: Array = []
## Where the crowd stands, by zone: lists of Transform3Ds like spots. Posed
## people, dressed by the job ([member JobDef.extras]).
var extras := {}
## Camera transforms for screenshots and the briefing, by name, and what
## each shows (for the screenshots' README).
var views := {}
var view_about := {}
## Wall clocks; [method set_clock] turns their hands.
var clocks: Array[Node3D] = []
## The rooms: name -> AABB, checked in [member zone_order] (smaller rooms
## inside bigger ones first).
var zones := {}
var zone_order: Array[String] = []
## Each zone's render layer, 2 to 20 (1 is for people and doors, lit
## everywhere). Zones sharing a layer share their lights.
var room_layers := {}

var _built := false
var _at: Node3D
var _rooms := {}
var _mats := {}


func _ready() -> void:
	if not _built:
		build()


## Builds it all (once): [method _build] does the venue's own work.
func build() -> void:
	if _built:
		return
	_built = true
	_build()


## The venue's rooms, doors, graph and views. Start with [method _make_rooms],
## end with [method _apply_layers] and [method _dress].
func _build() -> void:
	pass


## A node for each room's meshes and lights; [method _in] picks which one
## the building blocks add to.
func _make_rooms(names: Array) -> void:
	for zone in names:
		var n := Node3D.new()
		n.name = str(zone).capitalize().replace(" ", "")
		add_child(n)
		_rooms[zone] = n


## A venue's own materials, for names [method _mat] doesn't know: set up `m`
## and return true.
func _more_mat(_name: String, _m: StandardMaterial3D) -> bool:
	return false


## A venue's own wall styles, for [method _wall]: fill the face from s0 to s1
## and y0 to y1.
func _more_span(_style: String, _a: Vector2, _u: Vector2, _facing: Vector2, _s0: float, _s1: float, _y0: float, _y1: float, _h: float) -> void:
	pass


func _more_wall_top(_style: String, _a: Vector2, _u: Vector2, _facing: Vector2, _length: float, _h: float) -> void:
	pass


## The zone a point is in, or "" outside all of them.
func zone_at(p: Vector3) -> String:
	for z in zone_order:
		if (zones[z] as AABB).has_point(p):
			return z
	return ""


## The render layers something standing at `p` should be on so the room's
## lights light it: its room's, or every room's when it's between them.
func light_layers_at(p: Vector3) -> int:
	var z := zone_at(p)
	if z == "":
		return 0xFE
	return 1 << (int(room_layers.get(z, 1)) - 1)


## Sets every wall clock to `minutes` past midnight.
func set_clock(minutes: float) -> void:
	for c in clocks:
		var h := c.get_node_or_null("HourHand") as Node3D
		var m := c.get_node_or_null("MinuteHand") as Node3D
		if h:
			h.rotation.z = -deg_to_rad(fmod(minutes / 60.0, 12.0) * 30.0)
		if m:
			m.rotation.z = -deg_to_rad(fmod(minutes, 60.0) * 6.0)


# --- Building blocks --------------------------------------------------------------------------

func _in(zone: String) -> void:
	_at = _rooms[zone]


static func _v(p: Vector2, y := 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)


## A model with no collision.
func _m(name: String, at: Vector3, yaw := 0.0, scale := Vector3.ONE) -> Node3D:
	return Kit.model(_at, name, at, yaw, scale)


## A model that blocks with a box round it; `at` is the middle of its footprint.
func _box(name: String, at: Vector3, yaw := 0.0) -> StaticBody3D:
	return Kit.boxed(_at, name, at, yaw)


func _solid(center: Vector3, size: Vector3) -> void:
	Kit.block(_at, center, size)


func _slab(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return Kit.slab(_at, center, size, mat)


## A blocking box turned `yaw` about its middle.
func _solid_turned(center: Vector3, size: Vector3, yaw: float) -> void:
	var body := Kit.block(_at, center, size)
	body.rotation.y = yaw


## Materials by name, cached: textured ones are mapped in world space, so
## floors and walls line up across slabs.
func _mat(name: String) -> Material:
	if _mats.has(name):
		return _mats[name]
	var m := StandardMaterial3D.new()
	m.resource_name = name
	match name:
		"marble_floor":
			_tex(m, "res://assets/textures/hotel/marble_lobby", 2.4, true)
			m.roughness = 0.14
		"kit_marble":
			_tex(m, Kit.DOWNTOWN + "/T_MarbleFloor", 4.0, true, true)
		"carpet":
			_tex(m, "res://assets/textures/hotel/carpet_ballroom", 2.0)
			m.roughness = 0.95
		"parquet":
			_tex(m, "res://assets/textures/hotel/parquet", 0.85, true)
			m.roughness = 0.32
		"quarry":
			_tex(m, "res://assets/textures/hotel/tile_quarry", 1.2, true)
			m.roughness = 0.55
		"tile_white":
			_tex(m, "res://assets/textures/hotel/tile_white", 1.2, true)
			m.roughness = 0.18
		"carpet_office":
			_tex(m, "res://assets/textures/hotel/carpet_office", 2.0)
			m.roughness = 0.95
		"concrete":
			_tex(m, Kit.DOWNTOWN + "/T_Concrete", 4.0, true, true)
		"asphalt":
			m.albedo_texture = load(Kit.DOWNTOWN + "/T_Concrete_Asphalt_BaseColor.png")
			_world(m, 6.0)
			m.roughness = 0.82
		"plaster":
			m.albedo_color = Color(0.86, 0.81, 0.71)
			m.roughness = 0.9
		"plaster_grey":
			m.albedo_color = Color(0.5, 0.52, 0.52)
			m.roughness = 0.9
		"plaster_white":
			m.albedo_color = Color(0.82, 0.83, 0.82)
			m.roughness = 0.9
		"ceiling_dark":
			m.albedo_color = Color(0.16, 0.13, 0.11)
			m.roughness = 0.9
		"paint_kitchen":
			m.albedo_color = Color(0.6, 0.64, 0.62)
			m.roughness = 0.7
		"paint_low":
			m.albedo_color = Color(0.2, 0.27, 0.24)
			m.roughness = 0.6
		"paint_high":
			m.albedo_color = Color(0.72, 0.67, 0.56)
			m.roughness = 0.85
		"cream":
			m.albedo_color = Color(0.9, 0.85, 0.74)
			m.roughness = 0.6
		"walnut":
			m.albedo_color = Color(0.22, 0.12, 0.07)
			m.roughness = 0.4
		"gilt":
			m.albedo_color = Color(0.83, 0.64, 0.33)
			m.metallic = 1.0
			m.roughness = 0.3
		"brass":
			m.albedo_color = Color(0.78, 0.58, 0.3)
			m.metallic = 1.0
			m.roughness = 0.26
		"steel":
			m.albedo_color = Color(0.72, 0.73, 0.75)
			m.metallic = 1.0
			m.roughness = 0.32
		"bronze":
			m.albedo_color = Color(0.2, 0.14, 0.09)
			m.metallic = 0.8
			m.roughness = 0.4
		"night_glass":
			m.albedo_color = Color(0.015, 0.02, 0.03)
			m.metallic = 0.5
			m.roughness = 0.04
		"black_marble":
			m.albedo_color = Color(0.03, 0.03, 0.03)
			m.roughness = 0.12
		"red_carpet":
			m.albedo_color = Color(0.36, 0.03, 0.05)
			m.roughness = 0.95
		"kerb":
			m.albedo_color = Color(0.42, 0.41, 0.4)
			m.roughness = 0.85
		"road_paint":
			m.albedo_color = Color(0.75, 0.74, 0.7)
			m.roughness = 0.7
		"panel_light":
			m.albedo_color = Color(0.08, 0.08, 0.08)
			m.emission_enabled = true
			m.emission = Color(0.92, 0.96, 1.0)
			m.emission_energy_multiplier = 1.0
		"glow_warm":
			m.albedo_color = Color(1.0, 0.85, 0.6)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.5)
			m.emission_energy_multiplier = 3.0
		"frosted":
			m.albedo_color = Color(0.1, 0.095, 0.09)
			m.metallic = 0.3
			m.roughness = 0.22
		"mirror":
			m.albedo_color = Color(0.75, 0.74, 0.7)
			m.metallic = 1.0
			m.roughness = 0.04
		"freezer":
			m.albedo_color = Color(0.86, 0.87, 0.86)
			m.metallic = 0.3
			m.roughness = 0.45
		"hidden":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0, 0, 0, 0)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_:
			if not _more_mat(name, m):
				push_error("%s: no material %s" % [get_script().resource_path.get_file(), name])
	_mats[name] = m
	return m


func _tex(m: StandardMaterial3D, base: String, metres: float, normal := false, kit := false) -> void:
	m.albedo_texture = load(base + ("_BaseColor.png" if kit else ".png"))
	if normal:
		var n := base + ("_Normal.png" if kit else "_n.png")
		if ResourceLoader.exists(n):
			m.normal_enabled = true
			m.normal_texture = load(n)
	if kit and ResourceLoader.exists(base + "_ORM.png"):
		m.roughness_texture = load(base + "_ORM.png")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	_world(m, metres)


func _world(m: StandardMaterial3D, metres: float) -> void:
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / metres
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


## A material standing in for the kit's flat "rooms behind the window": a lit
## room (1 or 2), or a dark one (0).
func _window_mat(kind: int, tint := Color.WHITE) -> Material:
	var key := "window_%d_%s" % [kind, tint.to_html()]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	var tex: Texture2D = load(Kit.DOWNTOWN + ("/T_dark_interior.png" if kind == 0 else "/T_lit_interior_%d.png" % kind))
	m.albedo_color = Color.BLACK
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission = tint
	m.emission_energy_multiplier = 0.25 if kind == 0 else 0.75
	_mats[key] = m
	return m


func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadow(c)


## Finishes the props' materials by name (tools/blender/props.py): velvet
## gets a soft sheen and no hard highlights.
func _dress(n: Node) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var m := n.mesh.surface_get_material(i) as StandardMaterial3D
			if m == null or m.has_meta("dressed"):
				continue
			m.set_meta("dressed", true)
			if m.resource_name.begins_with("velvet") or m.resource_name == "rope_velvet":
				m.roughness = 1.0
				m.metallic_specular = 0.12
				m.rim_enabled = true
				m.rim = 0.4
				m.rim_tint = 0.7
	for c in n.get_children():
		_dress(c)


## Tints one of the kit's materials on every mesh under `n` (a copy, so the
## kit's own stays as it is).
func _tint(n: Node, kit_material: String, color: Color) -> void:
	var key := "%s/%s" % [kit_material, color.to_html()]
	if not _mats.has(key):
		var found := _find_material(n, kit_material)
		if found == null:
			return
		var m := found.duplicate() as StandardMaterial3D
		m.albedo_color = color
		_mats[key] = m
	_override(n, kit_material, _mats[key])


func _find_material(n: Node, name: String) -> StandardMaterial3D:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var m := n.mesh.surface_get_material(i) as StandardMaterial3D
			if m and m.resource_name == name:
				return m
	for c in n.get_children():
		var m := _find_material(c, name)
		if m:
			return m
	return null


## Swaps one of the kit's materials (by name) on every mesh under `n`.
func _override(n: Node, kit_material: String, with: Material) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var sm: Material = n.mesh.surface_get_material(i)
			if sm and sm.resource_name == kit_material:
				n.set_surface_override_material(i, with)
	for c in n.get_children():
		_override(c, kit_material, with)


## A floor: `r` is (x, z, width, depth) on the plan, the top at `y`.
func _floor(r: Rect2, mat: String, y := 0.0, thick := 0.1) -> void:
	_slab(Vector3(r.get_center().x, y - thick * 0.5, r.get_center().y), Vector3(r.size.x, thick, r.size.y), _mat(mat))


func _ceiling(r: Rect2, h: float, mat: String) -> void:
	_slab(Vector3(r.get_center().x, h + 0.05, r.get_center().y), Vector3(r.size.x + 0.4, 0.1, r.size.y + 0.4), _mat(mat))


## A light; `shadow` only for the few that need it (four at most in the hotel).
func _omni(at: Vector3, color: Color, energy: float, range_: float, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.light_specular = 0.6
	_at.add_child(l)
	return l


func _spot(at: Vector3, target: Vector3, color: Color, energy: float, range_: float, angle: float, shadow := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.spot_range = range_
	l.spot_angle = angle
	l.spot_attenuation = 1.0
	l.shadow_enabled = shadow
	_at.add_child(l)
	l.look_at_from_position(at, target, Vector3.UP if absf((target - at).normalized().y) < 0.99 else Vector3.FORWARD)
	return l


## A box-projected reflection probe for a room, with its own ambient light.
func _probe(r: Rect2, h: float, ambient: Color, energy: float) -> void:
	var p := ReflectionProbe.new()
	p.position = Vector3(r.get_center().x, h * 0.5, r.get_center().y)
	p.size = Vector3(r.size.x, h, r.size.y)
	p.origin_offset = Vector3(0.0, 1.6 - h * 0.5, 0.0)
	p.box_projection = true
	p.interior = true
	p.update_mode = ReflectionProbe.UPDATE_ONCE
	p.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	p.ambient_color = ambient
	p.ambient_color_energy = energy
	p.intensity = 0.8
	p.max_distance = maxf(r.size.x, r.size.y) * 1.5
	_at.add_child(p)


func _sign(text: String, at: Vector3, yaw: float, size := 64, color := Color(0.86, 0.7, 0.4), pixel := 0.004) -> Label3D:
	var s := Label3D.new()
	s.text = text
	s.font_size = size
	s.pixel_size = pixel
	s.modulate = color
	s.outline_size = 0
	s.font = HotelTheme.heading_font if HotelTheme.heading_font else load(HotelTheme.MONTSERRAT + "Montserrat-SemiBold.ttf")
	s.position = at
	s.rotation.y = yaw
	_at.add_child(s)
	return s


## Hangs a pendant light with its globe's bottom at `y`, on a rod to `top`.
func _pendant(x: float, z: float, y: float, top: float) -> void:
	_no_shadow(_m("pendant", Vector3(x, y, z)))
	if top > y + 1.2:
		_slab(Vector3(x, (y + 1.2 + top) * 0.5, z), Vector3(0.014, top - y - 1.2, 0.014), _mat("bronze"))


func _chandelier(x: float, z: float, ceiling: float, size: float) -> void:
	_no_shadow(_m("chandelier", Vector3(x, ceiling - 1.9 * size, z), 0.0, Vector3.ONE * size))
	# A ceiling rose.
	var rose := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42 * size
	cyl.bottom_radius = 0.5 * size
	cyl.height = 0.08
	rose.mesh = cyl
	rose.material_override = _mat("gilt")
	rose.position = Vector3(x, ceiling - 0.04, z)
	_at.add_child(rose)


# --- Walls ------------------------------------------------------------------------------------

## A wall's face from `a` to `b` on the plan (x, z), looking into its room
## along `facing`, `h` tall, in a style: "marble" (the kit's marble under its
## cornice), "ballroom" (panelling and silk under a coved cornice), "tile"
## (white tile to 2.4 m, paint above), "paint" (plaster over a dado) or "brick".
## `holes` are doorways and windows, {at = x or z along the wall, w, h, y0 =
## the sill}. Every solid stretch gets a collision box `t` deep behind the
## face, a little taller than the wall.
func _wall(style: String, a: Vector2, b: Vector2, facing: Vector2, h: float, holes: Array = [], t := T) -> void:
	var length := a.distance_to(b)
	var u := (b - a) / length
	var along_x := absf(u.x) > 0.5
	var cuts := []
	for hole in holes:
		var at: float = hole.at
		var s := (at - (a.x if along_x else a.y)) * (signf(u.x) if along_x else signf(u.y))
		cuts.append([s - float(hole.w) * 0.5, s + float(hole.w) * 0.5, hole])
	cuts.sort_custom(_by_start)
	var s := 0.0
	var spans := []
	for c in cuts:
		if c[0] > s + 0.01:
			spans.append([s, c[0]])
		s = c[1]
	if length > s + 0.01:
		spans.append([s, length])
	for sp in spans:
		_span(style, a, u, facing, sp[0], sp[1], 0.0, h, h)
		_wall_block(a, u, facing, sp[0], sp[1], 0.0, h + 0.5, t)
	for c in cuts:
		var hole: Dictionary = c[2]
		var y0: float = hole.get("y0", 0.0)
		if y0 > 0.0:
			_span(style, a, u, facing, c[0], c[1], 0.0, y0, h)
			_wall_block(a, u, facing, c[0], c[1], 0.0, y0, t)
		_span(style, a, u, facing, c[0], c[1], float(hole.h), h, h)
		_wall_block(a, u, facing, c[0], c[1], float(hole.h), h + 0.5, t)
	_wall_top(style, a, u, facing, length, h)


func _by_start(p: Array, q: Array) -> bool:
	return p[0] < q[0]


func _wall_block(a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, t: float) -> void:
	var mid := a + u * (s0 + s1) * 0.5 - facing * t * 0.5
	var size := Vector3(absf(u.x) * (s1 - s0) + absf(facing.x) * t, y1 - y0, absf(u.y) * (s1 - s0) + absf(facing.y) * t)
	_solid(Vector3(mid.x, (y0 + y1) * 0.5, mid.y), size)


## A slab on the wall's face, `out` in front of it and `depth` deep.
func _face(a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, mat: Material, depth := 0.02, out := 0.0) -> void:
	if y1 - y0 < 0.001 or s1 - s0 < 0.001:
		return
	var mid := a + u * (s0 + s1) * 0.5 + facing * (out + depth * 0.5)
	var size := Vector3(absf(u.x) * (s1 - s0) + absf(facing.x) * depth, y1 - y0, absf(u.y) * (s1 - s0) + absf(facing.y) * depth)
	_slab(Vector3(mid.x, (y0 + y1) * 0.5, mid.y), size, mat)


## Kit panels `width` wide (scaled to fill), along s0..s1.
func _panels(name: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y: float, sy := 1.0, width := 2.0) -> void:
	var length := s1 - s0
	var n := maxi(1, roundi(length / width))
	var sx := length / (width * n)
	var yaw := atan2(facing.x, facing.y)
	for i in n:
		var p := a + u * (s0 + (i + 0.5) * length / n)
		_m(name, _v(p, y), yaw, Vector3(sx, sy, 1.0))


## Fills the wall's face from s0 to s1 and y0 to y1 (part of a wall `h` tall).
func _span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, h: float) -> void:
	match style:
		"marble", "lobby":
			if style == "lobby" and y0 < 1.1:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.16), _mat("black_marble"), 0.05)
				_face(a, u, facing, s0, s1, maxf(y0, 0.16), minf(y1, 1.04), _mat("walnut"), 0.035)
				if y1 >= 1.1:
					_face(a, u, facing, s0, s1, 1.04, 1.1, _mat("gilt"), 0.05)
			var top := h - 1.0
			y1 = minf(y1, top)
			if y1 <= y0:
				return
			if y0 == 0.0 and y1 >= 4.0:
				_panels("Marble_Plain_4", a, u, facing, s0, s1, 0.0)
				var y := 4.0
				while y < y1 - 0.01:
					var hh := minf(1.0, y1 - y)
					_panels("Marble_Plain_1", a, u, facing, s0, s1, y, hh)
					y += 1.0
			else:
				_panels("Marble_Plain_1", a, u, facing, s0, s1, y0, y1 - y0)
		"ballroom":
			if y0 == 0.0 and y1 >= 4.4:
				_panels("wall_ballroom", a, u, facing, s0, s1, 0.0)
			else:
				var y1b := minf(y1, 4.4)
				_face(a, u, facing, s0, s1, y0, y1b, _mat("cream"), 0.04)
				if y1b >= 4.3:
					_face(a, u, facing, s0, s1, 4.28, 4.4, _mat("cream"), 0.09)
		"tile":
			if y0 < 0.15:
				_face(a, u, facing, s0, s1, y0, 0.15, _mat("steel"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.15), minf(y1, 2.4), _mat("tile_white"), 0.02)
			if y1 >= 2.4 and y0 <= 2.4:
				_face(a, u, facing, s0, s1, 2.38, 2.43, _mat("steel"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 2.4), y1, _mat("paint_kitchen"), 0.015)
		"paint":
			if y0 < 0.14:
				_face(a, u, facing, s0, s1, y0, 0.14, _mat("walnut"), 0.025)
			_face(a, u, facing, s0, s1, maxf(y0, 0.14), minf(y1, 0.95), _mat("paint_low"), 0.015)
			if y1 >= 1.0 and y0 <= 0.95:
				_face(a, u, facing, s0, s1, 0.93, 1.0, _mat("walnut"), 0.035)
			_face(a, u, facing, s0, s1, maxf(y0, 1.0), y1, _mat("paint_high"), 0.015)
		"brick":
			var y := y0
			while y < y1 - 0.01:
				var hh := minf(4.0, y1 - y)
				_panels("WornBrick_Plain_4", a, u, facing, s0, s1, y, hh / 4.0)
				y += 4.0
		_:
			_more_span(style, a, u, facing, s0, s1, y0, y1, h)


## What runs the whole length of a wall at the top: the cornice.
func _wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	match style:
		"marble", "lobby":
			_panels("Cornice_Marble_Center", a, u, facing, 0.0, length, h - 1.0)
		"ballroom":
			_panels("frieze_ballroom", a, u, facing, 0.0, length, 4.4)
		"paint":
			_face(a, u, facing, 0.0, length, h - 0.1, h, _mat("cream"), 0.05)
		"tile":
			_face(a, u, facing, 0.0, length, h - 0.06, h, _mat("paint_kitchen"), 0.04)
		_:
			_more_wall_top(style, a, u, facing, length, h)


## Lines a doorway through a wall: jambs and a head across the wall's
## thickness, and a threshold. `at` is the doorway's middle on the wall's line,
## `along` the wall's direction.
func _reveal(at: Vector2, along: Vector2, w: float, h: float, thick: float, mat: Material, sill := "") -> void:
	var across := Vector2(along.y, -along.x)
	for side in [-1.0, 1.0]:
		var p: Vector2 = at + along * side * (w * 0.5 + 0.02)
		_slab(Vector3(p.x, h * 0.5, p.y), Vector3(absf(along.x) * 0.04 + absf(across.x) * thick, h, absf(along.y) * 0.04 + absf(across.y) * thick), mat)
	_slab(Vector3(at.x, h + 0.02, at.y), Vector3(absf(along.x) * (w + 0.08) + absf(across.x) * thick, 0.04, absf(along.y) * (w + 0.08) + absf(across.y) * thick), mat)
	if sill != "":
		_slab(Vector3(at.x, 0.003, at.y), Vector3(absf(along.x) * w + absf(across.x) * thick, 0.006, absf(along.y) * w + absf(across.y) * thick), _mat(sill))


## A painting in a gilt frame on a wall face, under a brass picture light:
## `at` on the face, `w` by `h`, its bottom at `y0`; `picture` is one of
## assets/textures/hotel/painting_*.png.
func _painting(at: Vector2, facing: Vector2, w: float, y0: float, h: float, picture: String) -> void:
	var along := Vector2(-facing.y, facing.x)
	var sz := func(a: float, hh: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, hh, absf(along.y) * a + absf(facing.y) * d)
	var canvas := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(w, h)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/hotel/%s.png" % picture)
	m.roughness = 0.42
	m.metallic_specular = 0.3
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	quad.material = m
	canvas.mesh = quad
	canvas.position = _v(at + facing * 0.045, y0 + h * 0.5)
	canvas.rotation.y = atan2(facing.x, facing.y)
	canvas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_at.add_child(canvas)
	_slab(_v(at + facing * 0.02, y0 + h * 0.5), sz.call(w, h, 0.04), _mat("walnut"))
	var f := 0.11
	for side in [-1.0, 1.0]:
		_slab(_v(at + facing * 0.05 + along * side * (w + f) * 0.5, y0 + h * 0.5), sz.call(f, h + f * 2.0, 0.1), _mat("gilt"))
	for y in [y0 - f * 0.5, y0 + h + f * 0.5]:
		_slab(_v(at + facing * 0.05, y), sz.call(w + f * 2.0, f, 0.1), _mat("gilt"))
	# The picture light: a brass hood on an arm, and its light.
	var top := y0 + h + f + 0.06
	_slab(_v(at + facing * 0.12, top), sz.call(0.04, 0.04, 0.2), _mat("brass"))
	_slab(_v(at + facing * 0.24, top + 0.02), sz.call(w * 0.45, 0.06, 0.09), _mat("brass"))
	_slab(_v(at + facing * 0.24, top - 0.015), sz.call(w * 0.43, 0.012, 0.05), _mat("glow_warm"))
	var light := _spot(_v(at + facing * 0.26, top - 0.04), _v(at, y0 + h * 0.4), CANDLE, 2.2, h + 1.2, 48.0)
	light.spot_attenuation = 0.6


## A marble column, the kit's large one at half size, up to `top`.
func _column(p: Vector2, top: float) -> void:
	var s := top / 3.0
	_m("Marble_Column_Large_Bottom", _v(p), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_m("Marble_Column_Large_Center", _v(p, s), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_m("Marble_Column_Large_Top", _v(p, s * 2.0), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_solid(_v(p, top * 0.5), Vector3(1.1, top, 1.1))


## A window seen from inside, `w` wide from `y0` to `y1`: reveals and a sill
## `depth` deep to the glass in the front (a kit shop window, so it's glass
## both ways). `at` is its middle on the room's face.
func _window(at: Vector2, facing: Vector2, w: float, y0: float, y1: float, depth: float) -> void:
	var along := Vector2(-facing.y, facing.x)
	var size := func(a: float, h: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, h, absf(along.y) * a + absf(facing.y) * d)
	var mid := at - facing * depth * 0.5
	_slab(_v(mid + facing * 0.06, y0 - 0.03), size.call(w + 0.2, 0.06, depth + 0.12), _mat("cream"))
	# Under the sill, seen through the glass from the street.
	_slab(_v(at - facing * (depth - 0.02), y0 * 0.5), size.call(w, y0, 0.02), _mat("walnut"))
	for side in [-1.0, 1.0]:
		_slab(_v(mid + along * side * (w * 0.5 + 0.02), (y0 + y1) * 0.5), size.call(0.04, y1 - y0, depth), _mat("cream"))
	_slab(_v(mid, y1 + 0.02), size.call(w + 0.08, 0.04, depth), _mat("cream"))


func _lamp(at: Vector3, lit: bool) -> void:
	_m("street_lamp", at)
	_solid(at + Vector3(0.0, 1.5, 0.0), Vector3(0.3, 3.0, 0.3))
	if lit:
		_omni(at + Vector3(0.0, 4.0, 0.0), SODIUM, 2.4, 11.0)


## A block of buildings along a street front from x0 to x1 at z, its face
## toward the street (+z, or -z when `across`): shop fronts on the ground
## floor, `h` metres of windows over them, a cornice.
func _block(x0: float, x1: float, z: float, across: bool, h: float, kind: String, rng: RandomNumberGenerator) -> void:
	var a := Vector2(x1, z) if across else Vector2(x0, z)
	var b := Vector2(x0, z) if across else Vector2(x1, z)
	var facing := Vector2(0, -1) if across else Vector2(0, 1)
	var u := (b - a).normalized()
	var yaw := atan2(facing.x, facing.y)
	var length := x1 - x0
	# The ground floor: shop windows with a door every so often, lit.
	var n := int(length / 2.0)
	for i in n:
		var p := a + u * (i + 0.5) * 2.0
		var piece := "DoorFrame_Trim" if i % 5 == 2 else ("Metal_FirstFloor_Window" if kind == "white" else "Trim_FirstFloor_Window")
		var g := _m(piece, _v(p), yaw)
		_override(g, "MI_FakeInterior", _window_mat(1 + i % 2, Color(1.0, 0.85, 0.65)) if rng.randf() < 0.6 else _window_mat(0))
	# Awnings and a sign over some shops.
	var k := 0
	var s := 6.0
	while s < length - 6.0:
		var p := a + u * s
		if k % 3 == 1:
			_m("Prop_Sign_Hannigan", _v(p + facing * 0.02, 3.05), yaw)
		else:
			_m("Prop_Awning_Pub_Long" if k % 2 == 0 else "Prop_Awning_Long", _v(p, 0.0), yaw)
		k += 1
		s += 9.0
	# Floors above.
	var y := 3.0
	while y < h - 0.5:
		var w := 4.0
		var piece := {"red": "Brick_Window_Trim", "white": "WhiteBrick_Window", "double": "Brick_RedWhite_DoubleWindow", "inset": "Brick_Inset_Window"}[kind] as String
		if piece == "Brick_Window_Trim":
			w = 2.0
		var m := int(length / w)
		for i in m:
			var p := a + u * (i + 0.5) * w
			var win := _m(piece, _v(p, y), yaw)
			var lit := rng.randf()
			_override(win, "MI_FakeInterior", _window_mat(0) if lit < 0.55 else _window_mat(1 + rng.randi() % 2, Color(1.0, 0.82, 0.62)))
		y += 3.0
	_panels("Cornice_WhiteBrick_Center" if kind == "white" else "Cornice_Brick_Center", a, u, facing, 0.0, length, y)
	_solid(Vector3((x0 + x1) * 0.5, 3.0, z + (0.2 if across else -0.2)), Vector3(length, 6.0, 0.4))

# --- Doors, the graph, views ------------------------------------------------------------------

## Makes a [HotelDoor] for each spec, by name: "at" (the middle of the
## doorway on the floor, x and z), "w", "h", "to" (the way it swings when
## nobody's given), "model" (the leaf), and "double", "auto" (opens itself
## for anyone near, on every device) and "thick" if wanted.
func _make_doors(specs: Dictionary) -> void:
	for name in specs:
		var spec: Dictionary = specs[name]
		var d := HotelDoor.new()
		d.name = String(name).capitalize().replace(" ", "") + "Door"
		d.id = name
		d.width = spec.w
		d.height = spec.h
		d.double = spec.get("double", false)
		d.model = spec.model
		d.auto = spec.get("auto", false)
		d.thickness = spec.get("thick", 0.08)
		var to: Vector2 = spec.to
		var basis := Basis(Vector3.UP, atan2(-to.x, -to.y))
		var c := _v(spec.at, float(spec.get("y", 0.0)))
		d.transform = Transform3D(basis, c + basis.x * float(spec.w) * 0.5)
		d.build()
		add_child(d)
		doors[name] = d


## Adds a thing to use: a box of `size` round `at` (its bottom middle) on
## the Interact layer, with the meta "use" = `id`. Its model (if any) goes in
## as a child; the job can hide it (a taken item).
func _use(id: String, at: Vector3, size: Vector3, model := "", yaw := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Use_" + id.replace(":", "_")
	body.collision_layer = Kit.LAYER_INTERACT
	body.collision_mask = 0
	body.set_meta("use", id)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	cs.position = Vector3(0.0, size.y * 0.5, 0.0)
	body.add_child(cs)
	(_at if _at else self).add_child(body)
	body.position = at
	body.rotation.y = yaw
	if model != "":
		Kit.model(body, model, Vector3.ZERO)
	uses[id] = body
	return body


## Camera views from {name: [from, looking at]}.
func _set_views(v: Dictionary) -> void:
	for k in v:
		views[k] = Transform3D.IDENTITY.looking_at(v[k][1] - v[k][0], Vector3.UP).translated(v[k][0])


static func _facing(p: Vector2, dir: Vector2) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), _v(p))


## `n` people in a ring of radius `r` round `c`, facing in.
static func _knot(c: Vector2, n: int, r: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in n:
		var a := TAU * i / n + 0.4
		var p := c + Vector2(sin(a), cos(a)) * r
		out.append(_facing(p, c - p))
	return out


## Puts each room's meshes on its layer and its lights on that layer and layer 1.
func _apply_layers() -> void:
	for zone in _rooms:
		var bit := 1 << (int(room_layers.get(zone, 1)) - 1)
		_layer(_rooms[zone], bit)


func _layer(n: Node, bit: int) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).layers = bit
	elif n is Light3D:
		(n as Light3D).light_cull_mask = bit | 1
	elif n is ReflectionProbe:
		(n as ReflectionProbe).cull_mask = bit | 1
	for c in n.get_children():
		_layer(c, bit)


## The venue's world: by default a city at night, a dark sky, a warm low ambient (rooms set their own
## through their probes), glow for the lamps and SSAO.
func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.016, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_energy = 0.25
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.05, 0.07)
	env.fog_density = 0.004
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.05
	return env
