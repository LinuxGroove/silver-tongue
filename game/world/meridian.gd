class_name Meridian
extends Node3D
## The Hotel Meridian's ground floor, where the gala is: the lobby with
## reception and the bar, the ballroom and its stage, the kitchen with the pass
## and the staff room, the back corridor and its service door (M0's), the
## security office, the loading bay, and the street out front. Built in code
## from the Downtown City kit and the hotel's own props
## (`tools/blender/props.py`). X runs east and Z south, the floor is y = 0;
## docs/m1.md has the room table.
##
## Rooms keep their meshes on their own render layer, and a room's lights only
## light that layer and layer 1 (people, doors), so no light leaks through a
## wall. Something that moves between rooms can take [method light_layers_at]
## for where it stands.
##
## Spots, points and views are filled in by [method build]; spots and points
## stand on the floor, a spot's +Z is the way it faces, and a view is a camera
## transform (looking down its -Z).

## The rooms (and outside, the street and the loading bay). Some overlap:
## [method zone_at] checks them in [constant ZONE_ORDER].
const ZONES := {
	"lobby": AABB(Vector3(-14.0, -1.0, -18.0), Vector3(20.0, 13.0, 18.0)),
	"ballroom": AABB(Vector3(-14.0, -1.0, -34.0), Vector3(20.0, 13.0, 16.0)),
	"kitchen": AABB(Vector3(6.0, -1.0, -34.0), Vector3(14.0, 13.0, 14.0)),
	"staff_room": AABB(Vector3(14.0, -1.0, -34.0), Vector3(6.0, 13.0, 6.0)),
	"corridor": AABB(Vector3(6.0, -1.0, -20.0), Vector3(6.0, 13.0, 14.0)),
	"office": AABB(Vector3(12.0, -1.0, -16.0), Vector3(6.0, 13.0, 10.0)),
	"outside": AABB(Vector3(-40.0, -1.0, -6.0), Vector3(80.0, 31.0, 23.0)),
}
## The staff room is inside the kitchen, and outside's box takes in the lobby's
## front, so the smaller rooms come first.
const ZONE_ORDER: Array[String] = ["staff_room", "kitchen", "office", "corridor", "ballroom", "lobby", "outside"]
## Each zone's render layer (1 is for people and doors, lit everywhere).
const LAYERS := {"lobby": 2, "ballroom": 3, "kitchen": 4, "staff_room": 4, "corridor": 5, "office": 6, "outside": 7}

## Ceiling heights.
const LOBBY_H := 6.0
const BALLROOM_H := 7.0
const KITCHEN_H := 3.6
const CORRIDOR_H := 5.0
const OFFICE_H := 3.2
## How far a room's wall face sits in from the line between two rooms: walls
## between rooms are twice this thick.
const T := 0.2
## The street: pavement from the hotel's front (z = 0) to the kerb, the road,
## then the far pavement and the buildings across.
const KERB := 6.0
const FAR_KERB := 13.0
const ACROSS := 16.0

const WARM := Color(1.0, 0.86, 0.69)
const CANDLE := Color(1.0, 0.75, 0.5)
const COOL := Color(0.86, 0.93, 1.0)
const SODIUM := Color(1.0, 0.7, 0.42)

## The doors: the middle of the doorway on the floor (x, z), its size, the way
## it opens when nobody's given, and the leaf's model.
const DOOR_SPECS := {
	"front": {"at": Vector2(-4.0, -0.25), "w": 2.4, "h": 2.8, "double": true, "to": Vector2(0, -1), "model": "door_glass", "auto": true, "thick": 0.06},
	"ballroom": {"at": Vector2(-4.0, -18.0), "w": 2.4, "h": 3.0, "double": true, "to": Vector2(0, -1), "model": "door_grand"},
	"pass": {"at": Vector2(6.0, -27.0), "w": 1.1, "h": 2.2, "to": Vector2(-1, 0), "model": "door_kitchen"},
	"staff": {"at": Vector2(6.0, -10.0), "w": 1.1, "h": 2.2, "to": Vector2(1, 0), "model": "door_wood"},
	"service": {"at": Vector2(9.0, -19.8), "w": 1.12, "h": 2.2, "to": Vector2(0, -1), "model": "Door_1", "thick": 0.12},
	"office": {"at": Vector2(12.0, -11.0), "w": 1.1, "h": 2.2, "to": Vector2(1, 0), "model": "door_wood"},
	"loading": {"at": Vector2(9.0, -6.0), "w": 1.1, "h": 2.2, "to": Vector2(0, 1), "model": "door_steel"},
}

## HotelDoor by name: front, ballroom, pass, staff, service, office, loading.
var doors := {}
## Things to Interact with, by id: "jackets" (the rack in the staff room) and
## "keypad" (beside the service door). Each is a StaticBody3D on
## [constant Kit.LAYER_INTERACT] with the meta "use" = its id.
var uses := {}
## Where people stand, by name: a Transform3D on the floor facing its +Z.
var spots := {}
## Where people walk: named points on the floor, and links between them, each
## [a, b, door] with the door they go through ("" for none).
var points := {}
var links: Array = []
## Where the crowd stands: "ballroom", "lobby" and "kitchen", each a list of
## Transform3Ds like spots.
var extras := {}
## Camera transforms for screenshots and the briefing, by name.
var views := {}
## The wall clocks; [method set_clock] turns their hands.
var clocks: Array[Node3D] = []

var _built := false
var _at: Node3D
var _rooms := {}
var _mats := {}


func _ready() -> void:
	if not _built:
		build()


func build() -> void:
	if _built:
		return
	_built = true
	for zone in ["lobby", "ballroom", "kitchen", "corridor", "office", "outside"]:
		var n := Node3D.new()
		n.name = zone.capitalize().replace(" ", "")
		add_child(n)
		_rooms[zone] = n
	_ground()
	_lobby()
	_ballroom()
	_kitchen()
	_staff_room()
	_corridor()
	_office()
	_bay()
	_street()
	_facades()
	_doors()
	_graph()
	_views()
	_layers()
	_dress(self)
	set_clock(20 * 60 + 45)


## The zone a point is in, or "" outside all of them.
func zone_at(p: Vector3) -> String:
	for z in ZONE_ORDER:
		if (ZONES[z] as AABB).has_point(p):
			return z
	return ""


## The render layers something standing at `p` should be on so the room's
## lights light it: its room's, or every room's when it's between them.
func light_layers_at(p: Vector3) -> int:
	var z := zone_at(p)
	if z == "":
		return 0xFE
	return 1 << (int(LAYERS[z]) - 1)


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
			m.albedo_color = Color(0.95, 0.97, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.92, 0.96, 1.0)
			m.emission_energy_multiplier = 1.6
		"glow_warm":
			m.albedo_color = Color(1.0, 0.85, 0.6)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.5)
			m.emission_energy_multiplier = 3.0
		"frosted":
			m.albedo_color = Color(0.1, 0.095, 0.09)
			m.metallic = 0.3
			m.roughness = 0.22
		"glow_drapes":
			m.albedo_color = Color.BLACK
			m.emission_enabled = true
			m.emission_texture = load("res://assets/textures/hotel/silk_stripe.png")
			m.emission = Color(1.0, 0.62, 0.36)
			m.emission_energy_multiplier = 0.45
			_world(m, 0.6)
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
			push_error("Meridian: no material %s" % name)
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


# --- The ground under it all ------------------------------------------------------------------

func _ground() -> void:
	_in("outside")
	# Everything stands on y = 0 but the road, a kerb's height lower.
	_solid(Vector3(0.0, -0.25, (-40.0 + KERB) * 0.5), Vector3(80.0, 0.5, KERB + 40.0))
	_solid(Vector3(0.0, -0.4, (KERB + FAR_KERB) * 0.5), Vector3(80.0, 0.5, FAR_KERB - KERB))
	_solid(Vector3(0.0, -0.25, (FAR_KERB + ACROSS) * 0.5 + 1.0), Vector3(80.0, 0.5, ACROSS - FAR_KERB + 2.0))
	# Under the building, so no gap between rooms' floors shows the sky.
	_slab(Vector3(3.0, -0.12, -17.0), Vector3(34.0, 0.1, 34.0), Kit.flat(Color(0.05, 0.045, 0.04)))


# --- The lobby --------------------------------------------------------------------------------

func _lobby() -> void:
	_in("lobby")
	var r := Rect2(-13.8, -17.8, 19.6, 17.3)
	_floor(r, "marble_floor")
	# A black marble border, and the bar on parquet.
	for e in [Rect2(-13.8, -17.8, 19.6, 0.35), Rect2(-13.8, -0.85, 19.6, 0.35), Rect2(-13.8, -17.8, 0.35, 17.3), Rect2(5.45, -17.8, 0.35, 17.3)]:
		_floor(e, "black_marble", 0.004, 0.02)
	_floor(Rect2(-13.45, -17.45, 4.2, 10.4), "parquet", 0.004, 0.02)
	_wall("lobby", Vector2(-13.8, -0.5), Vector2(-13.8, -17.8), Vector2(1, 0), LOBBY_H)
	_wall("lobby", Vector2(-13.8, -17.8), Vector2(5.8, -17.8), Vector2(0, 1), LOBBY_H, [{"at": -4.0, "w": 2.4, "h": 3.0}])
	_wall("lobby", Vector2(5.8, -17.8), Vector2(5.8, -0.5), Vector2(-1, 0), LOBBY_H, [{"at": -10.0, "w": 1.1, "h": 2.2}])
	_wall("lobby", Vector2(5.8, -0.5), Vector2(-13.8, -0.5), Vector2(0, -1), LOBBY_H,
			[{"at": -4.0, "w": 2.4, "h": 3.12}, {"at": -10.0, "w": 3.0, "h": 3.9, "y0": 0.6}, {"at": 2.0, "w": 3.0, "h": 3.9, "y0": 0.6}])
	_ceiling(r, LOBBY_H, "plaster")
	# Coffers: beams over the columns, and a cornice round the middle.
	for x in [-8.9, 0.9]:
		_slab(Vector3(x, LOBBY_H - 0.22, -9.15), Vector3(0.6, 0.44, 17.3), _mat("plaster"))
		_slab(Vector3(x, LOBBY_H - 0.46, -9.15), Vector3(0.66, 0.05, 17.3), _mat("gilt"))
	for z in [-5.0, -12.0]:
		_slab(Vector3(-4.0, LOBBY_H - 0.22, z), Vector3(19.6, 0.44, 0.6), _mat("plaster"))
		_slab(Vector3(-4.0, LOBBY_H - 0.46, z), Vector3(19.6, 0.05, 0.66), _mat("gilt"))
	# Columns under the beams' crossings.
	for p in [Vector2(-8.9, -5.0), Vector2(0.9, -5.0), Vector2(-8.9, -12.0), Vector2(0.9, -12.0)]:
		_column(p, LOBBY_H - 0.44)
	# The front: windows behind drapes, the doors' transom, palms.
	for x in [-10.0, 2.0]:
		_window(Vector2(x, -0.5), Vector2(0, -1), 3.0, 0.6, 3.9, 0.17)
		_m("drapes", Vector3(x, 0.0, -0.5), PI)
	_slab(Vector3(-4.0, 2.96, -0.25), Vector3(2.4, 0.32, 0.02), _mat("night_glass"))
	_slab(Vector3(-4.0, 2.81, -0.25), Vector3(2.44, 0.04, 0.1), _mat("brass"))
	_reveal(Vector2(-4.0, -0.25), Vector2(1, 0), 2.4, 3.12, 0.5, _mat("cream"), "brass")
	_m("door_surround", Vector3(-4.0, 0.0, -0.5), PI, Vector3(1.0, 1.04, 1.0))
	for x in [-6.9, -1.1]:
		_m("potted_palm", Vector3(x, 0.0, -1.3))
		_solid(Vector3(x, 0.45, -1.3), Vector3(0.6, 0.9, 0.6))
	# Reception, in the north-east corner, facing the front doors.
	_box("reception_desk", Vector3(3.6, 0.0, -15.2))
	_box("key_cabinet", Vector3(3.6, 0.0, -17.585))
	clocks.append(_m("wall_clock", Vector3(3.6, 3.0, -17.8)))
	for x in [2.4, 4.8]:
		_pendant(x, -15.2, 2.75, LOBBY_H)
	_omni(Vector3(3.6, 2.5, -15.6), WARM, 0.9, 5.0)
	_omni(Vector3(3.2, 3.2, -12.6), WARM, 0.8, 6.0)
	_m("desk_lamp", Vector3(5.15, 1.1, -14.88))
	_omni(Vector3(5.15, 1.35, -14.8), CANDLE, 0.35, 2.5)
	_m("cctv_camera", Vector3(5.3, 4.4, -17.8))
	_box("luggage_cart", Vector3(5.1, 0.0, -12.6), -PI * 0.5)
	# The bar on the west side: the counter faces east, the back bar behind.
	_box("bar_counter", Vector3(-12.0, 0.0, -12.5), PI * 0.5)
	_box("back_bar", Vector3(-13.5, 0.0, -12.5), PI * 0.5)
	for z in [-15.0, -11.4, -10.3]:
		_box("bar_stool", Vector3(-11.05, 0.0, z))
	for z in [-14.6, -12.5, -10.4]:
		_pendant(-11.9, z, 2.45, LOBBY_H)
	_omni(Vector3(-11.6, 2.2, -12.5), WARM, 1.1, 5.0)
	_omni(Vector3(-13.0, 1.9, -12.5), CANDLE, 0.7, 3.0)
	# Two lounges by the windows.
	for side in [-1.0, 1.0]:
		var wall_x: float = -13.8 if side < 0 else 5.8
		var cx: float = -11.6 if side < 0 else 3.6
		var turn: float = PI * 0.5 * -side
		_m("rug", Vector3(cx, 0.0, -3.3), PI * 0.5)
		_box("sofa", Vector3(wall_x - side * 0.47, 0.0, -3.3), turn)
		_box("low_table", Vector3(cx - 0.1 * side, 0.0, -3.3), PI * 0.5)
		for z in [-4.0, -2.6]:
			_box("armchair", Vector3(cx + side * 1.3, 0.0, z), -turn)
		_box("floor_lamp", Vector3(wall_x - side * 0.4, 0.0, -5.3))
		_omni(Vector3(wall_x - side * 0.4, 1.55, -5.3), CANDLE, 0.6, 4.0)
		_box("side_table", Vector3(wall_x - side * 0.4, 0.0, -1.4))
	# The ballroom doors: a surround, the sign, the rope and the easel.
	_m("door_surround", Vector3(-4.0, 0.0, -17.8))
	_sign("BALLROOM", Vector3(-4.0, 4.72, -17.74), 0.0, 72)
	_m("rope_post", Vector3(-5.7, 0.0, -15.4))
	_m("rope_post", Vector3(-5.7, 0.0, -17.0))
	_m("rope", Vector3(-5.7, 0.0, -16.2), PI * 0.5)
	for z in [-15.4, -17.0]:
		_solid(Vector3(-5.7, 0.5, z), Vector3(0.36, 1.0, 0.36))
	_m("easel", Vector3(-7.6, 0.0, -16.9))
	_solid(Vector3(-7.6, 0.9, -16.95), Vector3(0.9, 1.8, 0.6))
	var poster := _sign("THE CALDERA MUSEUM\nAutumn Gala\n\nIn the Ballroom\nfrom eight o'clock", Vector3(-7.6, 1.3, -16.82), 0.0, 40, Color(0.2, 0.15, 0.1), 0.0028)
	# The middle: flowers under the chandelier.
	_box("flower_table", Vector3(-4.0, 0.0, -8.5))
	_chandelier(-4.0, -8.5, LOBBY_H, 1.6)
	# Sconces on the walls.
	for z in [-3.2, -6.4]:
		_m("wall_sconce", Vector3(-13.8, 2.3, z), PI * 0.5)
	for z in [-6.4, -13.6]:
		_m("wall_sconce", Vector3(5.8, 2.3, z), -PI * 0.5)
	for x in [-11.6, -8.4, 1.4]:
		_m("wall_sconce", Vector3(x, 2.3, -17.8))
	# Gilt mirrors over the sofas and on the north wall.
	_mirror(Vector2(-13.8, -3.3), Vector2(1, 0), 1.7, 1.6, 2.0)
	_mirror(Vector2(5.8, -3.3), Vector2(-1, 0), 1.7, 1.6, 2.0)
	_mirror(Vector2(-10.0, -17.8), Vector2(0, 1), 2.0, 1.4, 2.6)
	_sign("STAFF ONLY", Vector3(5.76, 2.62, -10.0), -PI * 0.5, 36)
	# Light: the chandelier (the lobby's one shadow), a wash from each corner.
	var ch := _omni(Vector3(-4.0, 3.4, -8.5), WARM, 3.2, 15.0, true)
	ch.shadow_bias = 0.08
	for p in [Vector3(-10.5, 4.6, -4.0), Vector3(2.5, 4.6, -4.0), Vector3(-9.0, 4.6, -15.0), Vector3(1.0, 4.6, -16.0)]:
		_omni(p, WARM, 0.75, 9.0)
	_probe(r, LOBBY_H, Color(0.42, 0.33, 0.24), 0.35)
	# The kit's marble is a yellow beige; the lobby's is creamier.
	_tint(_at, "MI_Trim", Color(1.0, 0.95, 0.92))


## A mirror in a gilt frame on a wall face: `at` on the face, `w` by `h`, its
## bottom at `y0`.
func _mirror(at: Vector2, facing: Vector2, w: float, y0: float, h: float) -> void:
	var along := Vector2(-facing.y, facing.x)
	var sz := func(a: float, hh: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, hh, absf(along.y) * a + absf(facing.y) * d)
	var glass := at + facing * 0.03
	_slab(_v(glass, y0 + h * 0.5), sz.call(w, h, 0.01), _mat("mirror"))
	var f := 0.09
	for side in [-1.0, 1.0]:
		_slab(_v(at + facing * 0.035 + along * side * (w + f) * 0.5, y0 + h * 0.5), sz.call(f, h + f * 2.0, 0.07), _mat("gilt"))
	for y in [y0 - f * 0.5, y0 + h + f * 0.5]:
		_slab(_v(at + facing * 0.035, y), sz.call(w + f * 2.0, f, 0.07), _mat("gilt"))
	# A crest on top.
	_slab(_v(at + facing * 0.04, y0 + h + f + 0.08), sz.call(w * 0.35, 0.16, 0.05), _mat("gilt"))


## A marble column, the kit's large one at half size, up to `top`.
func _column(p: Vector2, top: float) -> void:
	var s := top / 3.0
	_m("Marble_Column_Large_Bottom", _v(p), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_m("Marble_Column_Large_Center", _v(p, s), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_m("Marble_Column_Large_Top", _v(p, s * 2.0), 0.0, Vector3(0.55, s / 4.0, 0.55))
	_solid(_v(p, top * 0.5), Vector3(1.1, top, 1.1))


## A window seen from inside: night glass set `depth` back in the wall,
## glazing bars, a sill and reveals. `at` is its middle on the room's face.
func _window(at: Vector2, facing: Vector2, w: float, y0: float, y1: float, depth: float) -> void:
	var along := Vector2(-facing.y, facing.x)
	var back := at - facing * depth
	var size := func(a: float, h: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, h, absf(along.y) * a + absf(facing.y) * d)
	_slab(_v(back, (y0 + y1) * 0.5), size.call(w, y1 - y0, 0.02), _mat("night_glass"))
	for k in [-1.0, 1.0]:
		var p: Vector2 = back + along * k * w / 6.0
		_slab(_v(p + facing * 0.02, (y0 + y1) * 0.5), size.call(0.05, y1 - y0, 0.04), _mat("bronze"))
	_slab(_v(back + facing * 0.02, y0 + (y1 - y0) * 0.7), size.call(w, 0.05, 0.04), _mat("bronze"))
	var mid := at - facing * depth * 0.5
	_slab(_v(mid + facing * 0.06, y0 - 0.03), size.call(w + 0.2, 0.06, depth + 0.12), _mat("cream"))
	for side in [-1.0, 1.0]:
		_slab(_v(mid + along * side * (w * 0.5 + 0.02), (y0 + y1) * 0.5), size.call(0.04, y1 - y0, depth), _mat("cream"))
	_slab(_v(mid, y1 + 0.02), size.call(w + 0.08, 0.04, depth), _mat("cream"))


# --- The ballroom -----------------------------------------------------------------------------

func _ballroom() -> void:
	_in("ballroom")
	var r := Rect2(-13.8, -33.8, 19.6, 15.6)
	_floor(r, "carpet")
	# The dance floor, in front of the stage.
	_floor(Rect2(-9.5, -29.8, 11.0, 3.4), "parquet", 0.008, 0.02)
	for z in [-26.4]:
		_slab(Vector3(-4.0, 0.009, z), Vector3(11.0, 0.018, 0.04), _mat("brass"))
	for x in [-9.5, 1.5]:
		_slab(Vector3(x, 0.009, -28.1), Vector3(0.04, 0.018, 3.4), _mat("brass"))
	_wall("ballroom", Vector2(5.8, -18.2), Vector2(-13.8, -18.2), Vector2(0, -1), BALLROOM_H, [{"at": -4.0, "w": 2.4, "h": 3.0}])
	_wall("ballroom", Vector2(-13.8, -18.2), Vector2(-13.8, -33.8), Vector2(1, 0), BALLROOM_H)
	_wall("ballroom", Vector2(-13.8, -33.8), Vector2(5.8, -33.8), Vector2(0, 1), BALLROOM_H)
	_wall("ballroom", Vector2(5.8, -33.8), Vector2(5.8, -18.2), Vector2(-1, 0), BALLROOM_H, [{"at": -27.0, "w": 1.1, "h": 2.2}])
	_ceiling(r, BALLROOM_H, "plaster")
	# A deep frame round the ceiling's middle, gilt on its edge.
	var inner := Rect2(-11.4, -31.6, 14.8, 11.2)
	for e in [Rect2(inner.position.x, inner.position.y, inner.size.x, 0.5), Rect2(inner.position.x, inner.end.y - 0.5, inner.size.x, 0.5),
			Rect2(inner.position.x, inner.position.y, 0.5, inner.size.y), Rect2(inner.end.x - 0.5, inner.position.y, 0.5, inner.size.y)]:
		_slab(Vector3(e.get_center().x, BALLROOM_H - 0.15, e.get_center().y), Vector3(e.size.x, 0.3, e.size.y), _mat("plaster"))
	for e in [Rect2(inner.position.x + 0.5, inner.position.y + 0.5, inner.size.x - 1.0, 0.04), Rect2(inner.position.x + 0.5, inner.end.y - 0.54, inner.size.x - 1.0, 0.04),
			Rect2(inner.position.x + 0.5, inner.position.y + 0.5, 0.04, inner.size.y - 1.0), Rect2(inner.end.x - 0.54, inner.position.y + 0.5, 0.04, inner.size.y - 1.0)]:
		_slab(Vector3(e.get_center().x, BALLROOM_H - 0.2, e.get_center().y), Vector3(e.size.x, 0.4, e.size.y), _mat("gilt"))
	# The stage, its curtain, the lectern and the covered piece.
	_m("stage", Vector3(-4.0, 0.0, -31.8))
	_solid(Vector3(-4.0, 0.3, -31.8), Vector3(8.0, 0.6, 4.0))
	for side in [-1.0, 1.0]:
		var x0: float = -4.0 + side * 3.4
		for k in 3:
			var y := 0.2 * (k + 1)
			var z0 := -31.8 + 1.95
			var z1 := -31.8 + 2.75 - 0.25 * k
			_solid(Vector3(x0, y * 0.5, (z0 + z1) * 0.5), Vector3(1.2, y, z1 - z0))
	_m("curtain_stage", Vector3(-4.0, 0.0, -33.66))
	_box("lectern", Vector3(-1.6, 0.6, -31.0))
	_box("display_plinth", Vector3(-6.4, 0.6, -31.4))
	# Tables of eight.
	for x in [-10.9, -6.9, -1.1, 2.9]:
		for z in [-21.4, -25.0]:
			_table(Vector2(x, z))
	# Chandeliers over the tables and the dance floor.
	for p in [Vector2(-8.9, -23.2), Vector2(0.9, -23.2), Vector2(-4.0, -28.2), Vector2(-4.0, -21.0)]:
		_chandelier(p.x, p.y, BALLROOM_H, 1.5 if p.x == -4.0 and p.y > -22.0 else 1.8)
		_omni(_v(p, 4.0), WARM, 1.6, 9.5)
	# Sconces between the bays.
	for z in [-21.0, -25.0, -29.0, -32.6]:
		_m("wall_sconce", Vector3(-13.8, 2.6, z), PI * 0.5)
	for z in [-21.0, -24.0, -30.4, -32.6]:
		_m("wall_sconce", Vector3(5.8, 2.6, z), -PI * 0.5)
	for x in [-10.0, 2.0]:
		_m("wall_sconce", Vector3(x, 2.6, -18.2), PI)
	for p in [Vector3(-12.9, 2.4, -23.0), Vector3(-12.9, 2.4, -31.0), Vector3(4.9, 2.4, -22.5), Vector3(4.9, 2.4, -31.5)]:
		_omni(p, CANDLE, 0.55, 5.0)
	_m("door_surround", Vector3(-4.0, 0.0, -18.2), PI)
	_m("doorframe_walnut", Vector3(5.8, 0.0, -27.0), -PI * 0.5)
	_sign("KITCHEN", Vector3(5.76, 2.62, -27.0), -PI * 0.5, 32)
	# The stage's light: a spot from over the dance floor (the ballroom's shadow).
	_spot(Vector3(1.5, 6.6, -25.0), Vector3(-3.2, 1.0, -31.4), Color(1.0, 0.86, 0.7), 14.0, 15.0, 26.0, true)
	_omni(Vector3(-4.0, 3.0, -30.6), CANDLE, 0.6, 5.0)
	_probe(r, BALLROOM_H, Color(0.42, 0.3, 0.22), 0.3)


## A round table laid for eight, its chairs facing it.
func _table(c: Vector2) -> void:
	_m("banquet_table", _v(c))
	var body := StaticBody3D.new()
	body.position = _v(c, 0.5)
	body.collision_layer = Kit.LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.96
	shape.height = 1.0
	cs.shape = shape
	body.add_child(cs)
	_at.add_child(body)
	for k in 8:
		var a := deg_to_rad(22.5 + 45.0 * k)
		var p := c + Vector2(sin(a), cos(a)) * 1.15
		_m("banquet_chair", _v(p), a + PI)
		_solid_turned(_v(p, 0.46), Vector3(0.4, 0.92, 0.42), a + PI)


# --- The kitchen ------------------------------------------------------------------------------

func _kitchen() -> void:
	_in("kitchen")
	var r := Rect2(6.2, -33.8, 13.6, 13.6)
	_floor(r, "quarry")
	_wall("tile", Vector2(19.8, -20.2), Vector2(6.2, -20.2), Vector2(0, -1), KITCHEN_H, [{"at": 9.0, "w": 1.2, "h": 2.2}])
	_wall("tile", Vector2(6.2, -20.2), Vector2(6.2, -33.8), Vector2(1, 0), KITCHEN_H, [{"at": -27.0, "w": 1.1, "h": 2.2}])
	_wall("tile", Vector2(6.2, -33.8), Vector2(13.9, -33.8), Vector2(0, 1), KITCHEN_H)
	_wall("tile", Vector2(19.8, -27.9), Vector2(19.8, -20.2), Vector2(-1, 0), KITCHEN_H)
	# The staff room's walls, from the kitchen side.
	_wall("tile", Vector2(13.9, -33.8), Vector2(13.9, -27.9), Vector2(-1, 0), KITCHEN_H, [], 0.1)
	_wall("tile", Vector2(13.9, -27.9), Vector2(19.8, -27.9), Vector2(0, 1), KITCHEN_H, [{"at": 16.6, "w": 1.1, "h": 2.2}], 0.1)
	_reveal(Vector2(16.6, -28.0), Vector2(1, 0), 1.1, 2.2, 0.2, _mat("steel"), "steel")
	_ceiling(r, KITCHEN_H, "plaster_grey")
	# The pass, on the west side: waiters take plates from it on the pass door's side.
	_box("pass_counter", Vector3(9.2, 0.0, -24.6), -PI * 0.5)
	_omni(Vector3(9.0, 1.5, -24.6), Color(1.0, 0.5, 0.25), 0.9, 2.6)
	# The cooking line: three ranges under one hood.
	for z in [-25.4, -24.2, -23.0]:
		_box("range_stove", Vector3(12.6, 0.0, z), -PI * 0.5)
	_m("range_hood", Vector3(12.75, KITCHEN_H - 0.7, -24.2), -PI * 0.5)
	_box("kitchen_counter", Vector3(15.6, 0.0, -24.4), PI * 0.5)
	for z in [-21.4, -23.4, -25.4]:
		_box("kitchen_counter_wall", Vector3(19.45, 0.0, z), -PI * 0.5)
	for x in [12.4, 14.4, 16.4]:
		_box("kitchen_counter_wall", Vector3(x, 0.0, -20.55), PI)
	for x in [7.0, 8.6]:
		_box("pot_shelf", Vector3(x, 0.0, -33.52))
	_box("service_trolley", Vector3(6.8, 0.0, -30.2), PI * 0.5)
	# The walk-in freezer: an insulated box against the north wall.
	var fz := -30.6
	_slab(Vector3(11.7, 1.5, fz - 0.05), Vector3(4.0, 3.0, 0.1), _mat("freezer"))
	for x in [9.7, 13.7]:
		_slab(Vector3(x, 1.5, (fz - 33.8) * 0.5), Vector3(0.1, 3.0, 33.8 + fz), _mat("freezer"))
	_slab(Vector3(11.7, 3.02, (fz - 33.8) * 0.5), Vector3(4.1, 0.04, 33.8 + fz), _mat("freezer"))
	_slab(Vector3(11.7, 3.3, fz - 0.03), Vector3(4.0, 0.6, 0.06), _mat("paint_kitchen"))
	_solid(Vector3(11.7, 1.5, (fz - 33.8) * 0.5), Vector3(4.1, 3.0, 33.8 + fz))
	_m("freezer_door", Vector3(11.7, 0.0, fz))
	# Strip lights.
	for p in [Vector2(8.0, -23.0), Vector2(11.0, -21.8), Vector2(11.0, -27.5), Vector2(16.6, -22.6), Vector2(16.6, -25.6), Vector2(8.0, -30.0)]:
		_slab(_v(p, KITCHEN_H - 0.03), Vector3(0.3, 0.05, 1.5), _mat("panel_light"))
	for p in [Vector3(8.0, 3.2, -23.5), Vector3(11.0, 3.2, -27.5), Vector3(16.6, 3.2, -24.0), Vector3(8.0, 3.2, -30.0), Vector3(11.6, 3.2, -21.6)]:
		_omni(p, COOL, 0.85, 7.5)
	_m("doorframe_plain", Vector3(9.0, 0.0, -20.2), PI)
	_m("doorframe_plain", Vector3(6.2, 0.0, -27.0), PI * 0.5)
	_probe(Rect2(6.2, -27.9, 13.6, 7.7), KITCHEN_H, Color(0.34, 0.36, 0.38), 0.35)


func _staff_room() -> void:
	_in("kitchen")
	var r := Rect2(14.1, -33.8, 5.7, 5.7)
	_wall("paint", Vector2(14.1, -28.1), Vector2(14.1, -33.8), Vector2(1, 0), KITCHEN_H, [], 0.1)
	_wall("paint", Vector2(14.1, -33.8), Vector2(19.8, -33.8), Vector2(0, 1), KITCHEN_H)
	_wall("paint", Vector2(19.8, -33.8), Vector2(19.8, -28.1), Vector2(-1, 0), KITCHEN_H)
	_wall("paint", Vector2(19.8, -28.1), Vector2(14.1, -28.1), Vector2(0, -1), KITCHEN_H, [{"at": 16.6, "w": 1.1, "h": 2.2}], 0.1)
	for z in [-32.6, -30.6]:
		_box("lockers", Vector3(19.535, 0.0, z), -PI * 0.5)
	_box("locker_bench", Vector3(18.2, 0.0, -31.6), PI * 0.5)
	# The waiters' jackets: a rack you can Interact with.
	var rack_at := Vector3(16.2, 0.0, -33.3)
	_m("jacket_rack", rack_at)
	_solid(rack_at + Vector3(0.0, 0.85, 0.0), Vector3(1.5, 1.7, 0.6))
	var use := StaticBody3D.new()
	use.name = "Jackets"
	use.collision_layer = Kit.LAYER_INTERACT
	use.collision_mask = 0
	use.position = rack_at + Vector3(0.0, 1.2, 0.05)
	use.set_meta("use", "jackets")
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.4, 1.0, 0.7)
	cs.shape = shape
	use.add_child(cs)
	_at.add_child(use)
	uses["jackets"] = use
	_m("notice_board", Vector3(14.1, 1.2, -31.2), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(17.2, 2.35, -33.8), 0.0, Vector3.ONE * 0.5))
	_slab(Vector3(16.9, KITCHEN_H - 0.03, -31.0), Vector3(0.3, 0.05, 1.5), _mat("panel_light"))
	_omni(Vector3(16.9, 3.2, -31.0), Color(0.95, 0.93, 0.88), 1.0, 6.0)
	_probe(r, KITCHEN_H, Color(0.36, 0.35, 0.33), 0.3)


# --- The service corridor and the office ------------------------------------------------------

func _corridor() -> void:
	_in("corridor")
	var r := Rect2(6.2, -19.8, 5.6, 13.6)
	_floor(r, "kit_marble")
	_wall("marble", Vector2(6.2, -6.2), Vector2(6.2, -19.8), Vector2(1, 0), CORRIDOR_H, [{"at": -10.0, "w": 1.1, "h": 2.2}])
	_wall("marble", Vector2(6.2, -19.8), Vector2(11.8, -19.8), Vector2(0, 1), CORRIDOR_H, [{"at": 9.0, "w": 3.98, "h": 4.0}])
	_wall("marble", Vector2(11.8, -19.8), Vector2(11.8, -6.2), Vector2(-1, 0), CORRIDOR_H, [{"at": -11.0, "w": 1.1, "h": 2.2}])
	_wall("marble", Vector2(11.8, -6.2), Vector2(6.2, -6.2), Vector2(0, -1), CORRIDOR_H, [{"at": 9.0, "w": 1.1, "h": 2.2}])
	_ceiling(r, CORRIDOR_H, "ceiling_dark")
	# M0's service door: pilasters, the wooden frame, a short panel over it.
	for x in [7.4, 10.6]:
		_m("Marble_BevelColumn_Bottom", Vector3(x, 0.0, -19.8))
	var frame := _m("DoorFrame_Wooden", Vector3(9.0, 0.0, -19.8))
	_override(frame, "MI_Glass", _mat("hidden"))
	for side in [-1.0, 1.0]:
		_slab(Vector3(9.0 + side * 0.645, 1.29, -19.88), Vector3(0.29, 2.53, 0.02), _mat("frosted"))
	_slab(Vector3(9.0, 2.38, -19.88), Vector3(1.0, 0.36, 0.02), _mat("frosted"))
	for e in [[7.01, 8.44, 0.0, 4.0], [9.56, 10.99, 0.0, 4.0], [8.44, 9.56, 2.2, 4.0]]:
		_slab(Vector3((e[0] + e[1]) * 0.5, (e[2] + e[3]) * 0.5, -19.97), Vector3(e[1] - e[0], e[3] - e[2], 0.04), _mat("ceiling_dark"))
	_m("Marble_Plain_1", Vector3(9.0, 3.0, -19.8), 0.0, Vector3(1.25, 1.0, 1.0))
	_solid(Vector3(7.75, 2.0, -19.9), Vector3(1.5, 4.0, 0.2))
	_solid(Vector3(10.25, 2.0, -19.9), Vector3(1.5, 4.0, 0.2))
	_solid(Vector3(9.0, 3.1, -19.9), Vector3(1.0, 1.8, 0.2))
	_sign("SERVICE", Vector3(9.0, 2.65, -19.56), 0.0)
	# The keypad, on the wall to the door's right.
	var pad_at := Vector3(11.3, 1.17, -19.8)
	_m("keypad", pad_at)
	var pad := StaticBody3D.new()
	pad.name = "Keypad"
	pad.collision_layer = Kit.LAYER_INTERACT
	pad.collision_mask = 0
	pad.position = pad_at + Vector3(0.0, 0.08, 0.05)
	pad.set_meta("use", "keypad")
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.24, 0.3, 0.12)
	cs.shape = shape
	pad.add_child(cs)
	_at.add_child(pad)
	uses["keypad"] = pad
	# The other doors' frames on this side.
	_m("doorframe_walnut", Vector3(6.2, 0.0, -10.0), PI * 0.5)
	_m("doorframe_walnut", Vector3(11.8, 0.0, -11.0), -PI * 0.5)
	_sign("SECURITY", Vector3(11.76, 2.62, -11.0), -PI * 0.5, 40)
	_m("doorframe_plain", Vector3(9.0, 0.0, -6.2), PI)
	# Dressing, as in M0.
	for corner in [Vector3(6.5, 0.0, -6.5), Vector3(11.5, 0.0, -6.5)]:
		_box("Prop_Column_Trim", corner)
	for z in [-16.0, -8.0]:
		_m("Prop_Ornament_1", Vector3(6.2, 3.2, z), PI * 0.5)
	_m("Prop_Ornament_1", Vector3(11.8, 3.2, -15.5), -PI * 0.5)
	_m("cctv_camera", Vector3(11.8, 3.6, -17.6), -PI * 0.5)
	# Light as in M0: the lamp by the service door casts the corridor's shadow.
	_omni(Vector3(9.0, CORRIDOR_H - 0.4, -18.6), WARM, 2.0, 9.0, true)
	for z in [-13.6, -8.4]:
		_omni(Vector3(9.0, CORRIDOR_H - 0.4, z), WARM, 1.6, 8.0)
	_probe(r, CORRIDOR_H, Color(0.4, 0.34, 0.28), 0.35)


func _office() -> void:
	_in("office")
	var r := Rect2(12.2, -15.8, 5.6, 9.6)
	_floor(r, "carpet_office")
	_wall("paint", Vector2(12.2, -6.2), Vector2(12.2, -15.8), Vector2(1, 0), OFFICE_H, [{"at": -11.0, "w": 1.1, "h": 2.2}])
	_wall("paint", Vector2(12.2, -15.8), Vector2(17.8, -15.8), Vector2(0, 1), OFFICE_H)
	_wall("paint", Vector2(17.8, -15.8), Vector2(17.8, -6.2), Vector2(-1, 0), OFFICE_H)
	_wall("paint", Vector2(17.8, -6.2), Vector2(12.2, -6.2), Vector2(0, -1), OFFICE_H)
	_ceiling(r, OFFICE_H, "plaster_white")
	_box("cctv_monitors", Vector3(17.435, 0.0, -11.0), -PI * 0.5)
	_box("office_chair", Vector3(16.4, 0.0, -11.0), PI * 0.5)
	_box("office_desk", Vector3(14.6, 0.0, -15.37))
	_m("desk_lamp", Vector3(13.95, 0.76, -15.55), 0.3)
	for x in [16.9, 17.42]:
		_box("filing_cabinet", Vector3(x, 0.0, -15.47))
	_m("notice_board", Vector3(12.2, 1.3, -14.0), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(15.0, 2.2, -6.2), PI, Vector3.ONE * 0.45))
	_m("doorframe_plain", Vector3(12.2, 0.0, -11.0), PI * 0.5)
	for z in [-13.5, -8.5]:
		_slab(Vector3(15.0, OFFICE_H - 0.03, z), Vector3(1.2, 0.05, 0.6), _mat("panel_light"))
		_omni(Vector3(15.0, OFFICE_H - 0.4, z), COOL, 0.9, 6.0)
	_omni(Vector3(16.5, 1.5, -11.0), Color(0.6, 0.75, 1.0), 0.7, 3.5)
	_omni(Vector3(13.95, 1.0, -15.2), CANDLE, 0.4, 2.5)
	_probe(r, OFFICE_H, Color(0.3, 0.32, 0.34), 0.3)


# --- Outside: the loading bay, the street, the buildings ---------------------------------------

func _bay() -> void:
	_in("outside")
	_floor(Rect2(6.2, -5.8, 13.6, 5.8), "concrete")
	_wall("brick", Vector2(6.2, -5.8), Vector2(19.8, -5.8), Vector2(0, 1), 12.0, [{"at": 9.0, "w": 1.1, "h": 2.2}])
	_wall("brick", Vector2(6.2, 0.0), Vector2(6.2, -5.8), Vector2(1, 0), 16.0)
	_wall("brick", Vector2(19.8, -5.8), Vector2(19.8, 0.0), Vector2(-1, 0), 12.0)
	_reveal(Vector2(9.0, -6.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_m("doorframe_plain", Vector3(9.0, 0.0, -5.8))
	_m("bulkhead_light", Vector3(9.0, 2.55, -5.8))
	_m("bulkhead_light", Vector3(16.8, 2.9, -5.8))
	_omni(Vector3(9.0, 2.3, -5.4), SODIUM, 1.6, 7.0)
	_omni(Vector3(16.8, 2.6, -5.4), SODIUM, 1.2, 6.0)
	_box("dumpster", Vector3(16.8, 0.0, -5.2))
	for x in [13.7, 14.4]:
		_box("wheelie_bin", Vector3(x, 0.0, -5.37))
	_box("pallet", Vector3(18.8, 0.0, -2.6), 0.3)
	_m("Prop_ACUnit", Vector3(12.5, 3.4, -5.8))
	_m("Prop_ACUnit", Vector3(18.2, 6.6, -5.8))
	_m("Prop_Drain", Vector3(12.5, 0.002, -2.5))
	# The gate onto the street.
	for i in 4:
		_m("bay_gate", Vector3(6.2 + 1.7 + i * 3.4, 0.0, 0.0), 0.0, Vector3(3.4 / 3.56, 1.0, 1.0))
	_solid(Vector3(13.0, 1.4, 0.0), Vector3(13.6, 2.8, 0.12))


func _street() -> void:
	_in("outside")
	# Pavements of the kit's slabs, the kerbs, the road.
	var x := -39.0
	while x < 40.0:
		for z in [1.5, 4.5]:
			_m("Sidewalk_NoCurb_3m", Vector3(x, 0.0, z))
		_m("Sidewalk_NoCurb_3m", Vector3(x, 0.0, FAR_KERB + 1.5))
		x += 3.0
	for kz in [KERB - 0.12, FAR_KERB + 0.12]:
		_slab(Vector3(0.0, -0.07, kz), Vector3(80.0, 0.16, 0.24), _mat("kerb"))
	_slab(Vector3(0.0, -0.2, (KERB + FAR_KERB) * 0.5), Vector3(80.0, 0.1, FAR_KERB - KERB), _mat("asphalt"))
	var mid := (KERB + FAR_KERB) * 0.5
	x = -39.0
	while x < 40.0:
		_slab(Vector3(x + 1.5, -0.148, mid), Vector3(3.0, 0.006, 0.14), _mat("road_paint"))
		x += 7.0
	for z in [KERB + 0.35, FAR_KERB - 0.35]:
		_slab(Vector3(0.0, -0.148, z), Vector3(80.0, 0.006, 0.1), _mat("road_paint"))
	# The entrance: an arch round the doors, the canopy, a red carpet.
	_m("Prop_EntranceArch", Vector3(-4.0, 0.0, -0.15), 0.0, Vector3(4.0 / 3.0, 1.0, 1.0))
	_m("canopy", Vector3(-4.0, 0.0, 0.42))
	for px in [-5.85, -2.15]:
		_solid(Vector3(px, 1.65, 3.77), Vector3(0.22, 3.3, 0.22))
	_slab(Vector3(-4.0, 0.006, 1.95), Vector3(2.0, 0.012, 3.9), _mat("red_carpet"))
	for sx in [-5.02, -2.98]:
		_slab(Vector3(sx, 0.008, 1.95), Vector3(0.04, 0.016, 3.9), _mat("brass"))
	_sign("THE MERIDIAN", Vector3(-4.0, 5.25, 0.06), 0.0, 128, Color(1.3, 1.05, 0.62), 0.006)
	_spot(Vector3(-4.0, 3.2, 2.2), Vector3(-4.0, 0.0, 1.6), WARM, 4.0, 6.0, 55.0, true)
	_omni(Vector3(-4.0, 2.6, 0.9), WARM, 0.8, 5.0)
	# Street lamps, lit on the near side and across from the door.
	for lx in [-26.0, -14.0, 7.0, 22.0, 34.0]:
		_lamp(Vector3(lx, 0.0, KERB - 0.6), absf(lx - (-4.0)) < 20.0)
	for lx in [-30.0, -16.0, -4.0, 8.0, 20.0, 32.0]:
		_lamp(Vector3(lx, 0.0, FAR_KERB + 0.6), absf(lx - (-4.0)) < 14.0)
	for bx in [-7.6, -0.4]:
		_box("Prop_Bollard", Vector3(bx, 0.0, KERB - 0.5))
	_m("Prop_ManholeCover", Vector3(3.0, -0.148, 8.0))
	# Nobody leaves the block: the street's ends and the buildings' fronts.
	for ex in [-40.0, 40.0]:
		_solid(Vector3(ex, 3.0, (ACROSS - 6.0) * 0.5), Vector3(0.4, 6.0, ACROSS + 6.0))
	_solid(Vector3(0.0, 3.0, ACROSS + 0.2), Vector3(80.0, 6.0, 0.4))
	# A dim moon over the street.
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
	_at.add_child(moon)
	_probe(Rect2(-40.0, -6.0, 80.0, 22.0), 16.0, Color(0.12, 0.13, 0.18), 0.25)


func _lamp(at: Vector3, lit: bool) -> void:
	_m("street_lamp", at)
	_solid(at + Vector3(0.0, 1.5, 0.0), Vector3(0.3, 3.0, 0.3))
	if lit:
		_omni(at + Vector3(0.0, 4.0, 0.0), SODIUM, 2.4, 11.0)


## The hotel's front and the buildings either side and across the street.
func _facades() -> void:
	_in("outside")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1923
	# The Meridian: marble, the ground floor's two great windows either side of
	# the arch, three floors of rooms above, a cornice on top.
	_wall("marble", Vector2(-14.0, 0.0), Vector2(6.0, 0.0), Vector2(0, 1), 7.0,
			[{"at": -10.0, "w": 4.0, "h": 4.0}, {"at": -4.0, "w": 2.4, "h": 3.12}, {"at": 2.0, "w": 4.0, "h": 4.0}])
	for wx in [-10.0, 2.0]:
		var shop := _m("Marble_ShopWindow", Vector3(wx, 0.0, 0.0))
		_override(shop, "MI_FakeInterior", _mat("glow_drapes"))
	for floor_ in 3:
		var y := 7.0 + floor_ * 3.0
		for wx in [-12.0, -8.0, -4.0, 0.0, 4.0]:
			var win := _m("Marble_Window_Single", Vector3(wx, y, 0.0))
			_override(win, "MI_FakeInterior", _window_mat(0 if rng.randf() < 0.45 else 1 + rng.randi() % 2, Color(1.0, 0.8, 0.6)))
	_panels("Cornice_Marble_Center", Vector2(-14.0, 0.0), Vector2(1, 0), Vector2(0, 1), 0.0, 20.0, 16.0)
	# Lit from below, between the windows.
	for ux in [-13.2, -6.9, -1.1, 5.2]:
		_spot(Vector3(ux, 0.15, 0.9), Vector3(ux, 9.0, 0.0), WARM, 5.0, 16.0, 22.0)
	# Next door, west: a brick block with a pub on the ground floor.
	_block(-40.0, -14.0, 0.0, false, 12.0, "red", rng)
	# East, past the loading bay: white brick offices.
	_block(20.0, 40.0, 0.0, false, 12.0, "white", rng)
	# Across the street.
	_block(-40.0, -14.0, ACROSS, true, 12.0, "double", rng)
	_block(-14.0, 10.0, ACROSS, true, 15.0, "inset", rng)
	_block(10.0, 40.0, ACROSS, true, 12.0, "red", rng)


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


# --- Doors ------------------------------------------------------------------------------------

func _doors() -> void:
	for name in DOOR_SPECS:
		var spec: Dictionary = DOOR_SPECS[name]
		var d := HotelDoor.new()
		d.name = String(name).capitalize() + "Door"
		d.id = name
		d.width = spec.w
		d.height = spec.h
		d.double = spec.get("double", false)
		d.model = spec.model
		d.auto = spec.get("auto", false)
		d.thickness = spec.get("thick", 0.08)
		var to: Vector2 = spec.to
		var basis := Basis(Vector3.UP, atan2(-to.x, -to.y))
		var c := _v(spec.at)
		d.transform = Transform3D(basis, c + basis.x * float(spec.w) * 0.5)
		d.build()
		add_child(d)
		doors[name] = d
	# Linings through the walls.
	_in("lobby")
	_reveal(Vector2(-4.0, -18.0), Vector2(1, 0), 2.4, 3.0, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(6.0, -10.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_in("ballroom")
	_reveal(Vector2(6.0, -27.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_in("corridor")
	_reveal(Vector2(12.0, -11.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(9.0, -20.0), Vector2(1, 0), 1.2, 2.2, 0.4, _mat("walnut"))
	_reveal(Vector2(9.0, -6.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("steel"), "steel")


# --- Where people go --------------------------------------------------------------------------

func _graph() -> void:
	var P := {
		# Lobby.
		"front_out": Vector2(-4.0, 1.6), "front_in": Vector2(-4.0, -1.6),
		"crew_0": Vector2(-4.9, -2.6), "crew_1": Vector2(-3.1, -2.6),
		"lobby_s": Vector2(-4.0, -3.6), "lobby_c": Vector2(-4.0, -6.2),
		"lobby_w": Vector2(-6.6, -8.5), "lobby_e": Vector2(-1.4, -8.5), "lobby_n": Vector2(-4.0, -13.2),
		"ballroom_out": Vector2(-4.0, -16.4), "teo": Vector2(-2.0, -16.9),
		"celeste": Vector2(-10.9, -8.4), "hugo": Vector2(-9.7, -8.4),
		"bar_end": Vector2(-12.85, -8.6), "benny": Vector2(-12.85, -12.5),
		"reception": Vector2(2.0, -13.6), "okafor": Vector2(-0.2, -14.8),
		"reception_end": Vector2(0.9, -16.4), "dana": Vector2(3.6, -16.4),
		"staff_lobby": Vector2(4.9, -10.0),
		# Ballroom.
		"ballroom_in": Vector2(-4.0, -19.6), "ballroom_c": Vector2(-4.0, -23.2),
		"ballroom_w": Vector2(-8.9, -23.2), "ballroom_e": Vector2(0.9, -23.2), "ballroom_e2": Vector2(5.0, -23.2),
		"stage_front": Vector2(-4.0, -28.4), "okafor_stage": Vector2(1.2, -28.8),
		"celeste_in": Vector2(-9.4, -27.8), "hugo_in": Vector2(-8.6, -27.8),
		"pass_ballroom": Vector2(4.9, -27.0),
		# Kitchen and staff room.
		"pass_kitchen": Vector2(7.2, -27.0), "laurent": Vector2(7.9, -24.4), "lane_s": Vector2(7.2, -21.8),
		"service_in": Vector2(9.0, -21.3), "kitchen_c": Vector2(11.0, -21.4), "kitchen_e": Vector2(16.6, -21.6),
		"staff_room_out": Vector2(16.6, -26.8), "staff_room_in": Vector2(16.6, -29.2), "jackets": Vector2(16.2, -32.2),
		# Corridor, office, loading bay.
		"service_out": Vector2(9.0, -18.8), "marcus": Vector2(7.9, -19.0), "corridor_n": Vector2(9.0, -16.0),
		"corridor_c": Vector2(9.0, -12.0), "staff_corridor": Vector2(7.1, -10.0),
		"office_out": Vector2(10.8, -11.0), "office_guard": Vector2(11.0, -12.6),
		"office_in": Vector2(13.2, -11.0), "held": Vector2(14.6, -8.4),
		"loading_in": Vector2(9.0, -7.2), "loading_out": Vector2(9.0, -4.8), "smoke": Vector2(11.2, -4.4),
	}
	for k in P:
		points[k] = _v(P[k])
	var L := [
		["front_out", "front_in", "front"], ["front_in", "crew_0", ""], ["front_in", "crew_1", ""],
		["front_in", "lobby_s", ""], ["crew_0", "lobby_s", ""], ["crew_1", "lobby_s", ""],
		["lobby_s", "lobby_c", ""], ["lobby_c", "lobby_w", ""], ["lobby_c", "lobby_e", ""],
		["lobby_w", "lobby_n", ""], ["lobby_e", "lobby_n", ""], ["lobby_n", "ballroom_out", ""],
		["ballroom_out", "teo", ""], ["teo", "okafor", ""], ["lobby_w", "celeste", ""], ["lobby_w", "hugo", ""],
		["celeste", "hugo", ""], ["celeste", "bar_end", ""], ["bar_end", "benny", ""],
		["staff_lobby", "reception", ""], ["lobby_n", "okafor", ""], ["reception", "okafor", ""],
		["okafor", "reception_end", ""], ["reception_end", "dana", ""],
		["lobby_e", "staff_lobby", ""], ["staff_lobby", "staff_corridor", "staff"],
		["ballroom_out", "ballroom_in", "ballroom"], ["ballroom_in", "ballroom_c", ""],
		["ballroom_c", "ballroom_w", ""], ["ballroom_c", "ballroom_e", ""], ["ballroom_e", "ballroom_e2", ""],
		["ballroom_e2", "pass_ballroom", ""], ["ballroom_c", "stage_front", ""], ["stage_front", "okafor_stage", ""],
		["stage_front", "celeste_in", ""], ["celeste_in", "hugo_in", ""], ["okafor_stage", "pass_ballroom", ""],
		["pass_ballroom", "pass_kitchen", "pass"], ["pass_kitchen", "laurent", ""], ["laurent", "lane_s", ""],
		["lane_s", "service_in", ""], ["service_in", "kitchen_c", ""], ["kitchen_c", "kitchen_e", ""],
		["kitchen_e", "staff_room_out", ""], ["staff_room_out", "staff_room_in", ""], ["staff_room_in", "jackets", ""],
		["service_in", "service_out", "service"], ["service_out", "marcus", ""], ["service_out", "corridor_n", ""],
		["corridor_n", "corridor_c", ""], ["corridor_c", "staff_corridor", ""], ["corridor_c", "office_out", ""],
		["office_out", "office_guard", ""], ["office_guard", "corridor_n", ""], ["office_out", "office_in", "office"],
		["office_in", "held", ""], ["corridor_c", "loading_in", ""], ["staff_corridor", "loading_in", ""],
		["loading_in", "loading_out", "loading"], ["loading_out", "smoke", ""],
	]
	links = L
	var face := {
		"marcus": Vector2(0, 1), "teo": Vector2(0, 1), "dana": Vector2(0, 1), "laurent": Vector2(0, 1),
		"benny": Vector2(1, 0), "okafor": Vector2(-1, 1), "okafor_stage": Vector2(-1, -1),
		"celeste": Vector2(1, 0), "hugo": Vector2(-1, 0), "celeste_in": Vector2(1, 0), "hugo_in": Vector2(-1, 0),
		"smoke": Vector2(0, 1), "office_guard": Vector2(-1, 0), "held": Vector2(-1, 0),
		"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "ballroom_in": Vector2(0, -1),
	}
	for k in face:
		spots[k] = _facing(P[k], face[k])
	# The crowd: knots of guests in the ballroom, a few in the lobby, two cooks.
	var ballroom: Array[Transform3D] = []
	for g in [[Vector2(-11.6, -28.6), 3, 0.7], [Vector2(3.4, -28.9), 3, 0.7], [Vector2(-6.4, -27.6), 3, 0.6],
			[Vector2(-1.8, -27.5), 2, 0.5], [Vector2(-12.4, -19.1), 3, 0.5], [Vector2(2.0, -19.2), 2, 0.5]]:
		ballroom.append_array(_knot(g[0], g[1], g[2]))
	extras["ballroom"] = ballroom
	extras["lobby"] = [_facing(Vector2(-10.85, -13.8), Vector2(-1, 0)), _facing(Vector2(-10.85, -12.8), Vector2(-1, 0)),
			_facing(Vector2(4.2, -14.05), Vector2(0, -1)), _facing(Vector2(5.1, -14.05), Vector2(-0.3, -1))] as Array[Transform3D]
	extras["kitchen"] = [_facing(Vector2(11.5, -25.4), Vector2(1, 0)), _facing(Vector2(11.5, -23.6), Vector2(1, 0))] as Array[Transform3D]


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


func _views() -> void:
	var v := {
		"entrance": [Vector3(-4.6, 1.65, -2.2), Vector3(-4.0, 1.8, -12.0)],
		"lobby": [Vector3(-12.6, 2.4, -1.4), Vector3(-1.0, 1.4, -12.0)],
		"reception": [Vector3(1.6, 1.7, -8.6), Vector3(3.8, 1.4, -16.6)],
		"bar": [Vector3(-7.4, 1.7, -7.0), Vector3(-12.6, 1.3, -13.2)],
		"ballroom_doors": [Vector3(-4.0, 1.7, -10.0), Vector3(-4.0, 2.1, -18.0)],
		"ballroom": [Vector3(-4.0, 2.3, -19.0), Vector3(-4.0, 1.5, -30.0)],
		"stage": [Vector3(-2.8, 1.7, -25.6), Vector3(-4.0, 1.9, -32.0)],
		"pass": [Vector3(6.9, 1.7, -21.0), Vector3(8.9, 1.2, -26.0)],
		"kitchen": [Vector3(18.6, 2.3, -21.0), Vector3(10.0, 1.1, -26.0)],
		"staff_room": [Vector3(15.0, 1.7, -28.6), Vector3(17.8, 1.2, -33.0)],
		"corridor": [Vector3(9.0, 1.7, -6.9), Vector3(9.0, 1.6, -19.0)],
		"service_door": [Vector3(9.6, 1.65, -15.6), Vector3(9.0, 1.4, -20.0)],
		"office": [Vector3(12.8, 1.7, -6.8), Vector3(17.0, 1.1, -12.4)],
		"loading_bay": [Vector3(18.6, 1.8, -0.8), Vector3(9.0, 1.3, -5.6)],
		"street": [Vector3(0.5, 1.7, 11.4), Vector3(-4.0, 3.6, 0.0)],
	}
	for k in v:
		views[k] = Transform3D.IDENTITY.looking_at(v[k][1] - v[k][0], Vector3.UP).translated(v[k][0])


## Puts each room's meshes on its layer and its lights on that layer and layer 1.
func _layers() -> void:
	for zone in _rooms:
		var bit := 1 << (int(LAYERS[zone]) - 1)
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


## The Meridian at night: a dark sky, a warm low ambient (rooms set their own
## through their probes), glow for the lamps and SSAO.
static func environment() -> Environment:
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
