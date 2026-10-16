class_name MaeHouse
extends Venue
## Auntie Mae's house, where the finale's party is: her laundrette on an old
## Caldera street, the back room where she has briefed the crew all season,
## the back hall and its stairs, the yard with the bins and the gate onto the
## alley, and her flat over the shop (the living room with the records and
## the big old sofa, the kitchen everyone stands in, her study with the
## strongroom and her files on the crew, and the little terrace on the roof
## of the back). Built in code from the Downtown City kit, the hotel's props
## and Mae's own (`tools/blender/mae_props.py`).
##
## X runs east and Z south. The shop floor is y = 0 and the flat's floor
## [constant FLAT]: the flat's rooms are raised that far, so their building
## blocks work in the room's own height, while spots, points and views are
## in the world's.

## The rooms, outside and in. The flat sits over the shop, so its rooms
## share their plan with the ones below and differ by height.
const ZONES := {
	"study": AABB(Vector3(-6.0, 3.5, -9.0), Vector3(6.0, 4.0, 9.0)),
	"kitchen": AABB(Vector3(0.0, 3.5, -9.0), Vector3(6.0, 4.0, 9.0)),
	"living": AABB(Vector3(-6.0, 3.5, -18.0), Vector3(8.0, 4.0, 9.0)),
	"landing": AABB(Vector3(2.0, 3.5, -18.0), Vector3(4.0, 4.0, 9.0)),
	"terrace": AABB(Vector3(-6.0, 3.5, -26.5), Vector3(8.4, 5.0, 8.5)),
	"laundrette": AABB(Vector3(-6.0, -1.0, -9.0), Vector3(12.0, 4.5, 9.0)),
	"back_hall": AABB(Vector3(2.0, -1.0, -18.0), Vector3(4.0, 4.5, 9.0)),
	"back_room": AABB(Vector3(-6.0, -1.0, -18.0), Vector3(8.0, 4.5, 9.0)),
	"yard": AABB(Vector3(1.0, -1.0, -26.5), Vector3(5.0, 4.5, 8.5)),
	"alley": AABB(Vector3(-14.0, -1.0, -32.0), Vector3(28.0, 9.0, 5.5)),
	"street": AABB(Vector3(-30.0, -1.0, 0.0), Vector3(60.0, 21.0, 20.0)),
}
const ZONE_ORDER: Array[String] = ["study", "kitchen", "living", "landing", "terrace", "laundrette", "back_hall", "back_room", "yard", "alley", "street"]
## Each room's render layer. The back hall and the landing share one (the
## stairs join them), and so do the yard and the alley (the gate).
const LAYERS := {
	"street": 2, "laundrette": 3, "back_hall": 4, "landing": 4, "back_room": 5, "living": 6,
	"kitchen": 7, "study": 8, "terrace": 9, "yard": 10, "alley": 10,
}

## The flat's floor, over the shop.
const FLAT := 3.6
## Ceilings: the shop floor's, and the flat's (over its own floor).
const SHOP_H := 3.0
const FLAT_H := 3.0
## The street: pavement from the shop's front (z = 0) to the kerb, the road,
## the far pavement, and the buildings across.
const KERB := 4.0
const FAR_KERB := 11.0
const ACROSS := 14.0
## The stairs in the back hall: from the foot by the shop to the head on
## the landing, and the hole in the landing's floor over them.
const STAIRS_FOOT := Vector3(5.175, 0.0, -10.15)
const STAIRS_RUN := 6.3
const STAIRS_W := 1.25
const WELL := Rect2(4.5, -16.45, 1.3, 4.65)
## The iron stairs from the yard up to the terrace.
const IRON_FOOT := Vector3(1.7, 0.0, -25.75)

## The doors: the middle of the doorway on its floor (x, z), its size, the
## way it opens when nobody's given, and the leaf's model.
const DOOR_SPECS := {
	"front": {"at": Vector2(-5.0, -0.15), "w": 1.0, "h": 2.2, "to": Vector2(0, -1), "model": "mae_shop_door", "thick": 0.06},
	"back_room": {"at": Vector2(2.0, -11.2), "w": 0.95, "h": 2.1, "to": Vector2(-1, 0), "model": "mae_panel_door"},
	"yard": {"at": Vector2(3.3, -17.9), "w": 0.95, "h": 2.15, "to": Vector2(0, -1), "model": "mae_back_door"},
	"gate": {"at": Vector2(4.0, -26.4), "w": 1.2, "h": 1.95, "to": Vector2(0, -1), "model": "mae_gate"},
	"study": {"at": Vector2(-3.6, -9.0), "w": 0.95, "h": 2.1, "to": Vector2(0, 1), "y": FLAT, "model": "mae_panel_door"},
	"safe": {"at": Vector2(-2.8, -7.1), "w": 0.9, "h": 2.0, "to": Vector2(1, 0), "y": FLAT, "model": "mae_strongroom_door", "thick": 0.12},
	"terrace": {"at": Vector2(-3.0, -17.9), "w": 0.95, "h": 2.15, "to": Vector2(0, 1), "y": FLAT, "model": "mae_glazed_door"},
}

var _raised_nodes := {}


func _init() -> void:
	zones = ZONES
	zone_order = ZONE_ORDER
	room_layers = LAYERS


## The doors are HotelDoors by name (front, back_room, yard, gate, study,
## safe, terrace). The uses: "dial" (the strongroom's combination), where
## the Rose can lie ("safe_shelf", "desk", "case") and where Silas's copy
## can ("drawer", "copy_safe", "copy_desk", "copy_case"), and things to look
## at ("files", "plans", "kettle", "records"). "GrayCase" (the buyer's case
## on the terrace table), "Fireworks" and "GrayCar" are nodes the job shows
## and hides.
func _build() -> void:
	_make_rooms(["street", "laundrette", "back_hall", "back_room", "yard", "alley", "landing", "living", "kitchen", "study", "terrace"])
	for z in ["landing", "living", "kitchen", "study", "terrace"]:
		(_rooms[z] as Node3D).position.y = FLAT
	_ground()
	_laundrette()
	_back_hall()
	_back_room()
	_yard()
	_alley()
	_landing()
	_living()
	_kitchen()
	_study()
	_terrace()
	_street()
	_facades()
	_doors()
	_graph()
	_views()
	_apply_layers()
	_dress(self)
	set_clock(22 * 60)


# --- Materials and walls of the house's own ---------------------------------------------------

func _more_mat(name: String, m: StandardMaterial3D) -> bool:
	match name:
		"checker":
			var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
			for py in 2:
				for px in 2:
					img.set_pixel(px, py, Color(0.86, 0.83, 0.74) if px == py else Color(0.14, 0.3, 0.27))
			m.albedo_texture = ImageTexture.create_from_image(img)
			_world(m, 0.6)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
			m.roughness = 0.32
		"mint_tile":
			_tex(m, "res://assets/textures/hotel/tile_white", 1.2, true)
			m.albedo_color = Color(0.7, 0.88, 0.8)
			m.roughness = 0.2
		"cream_paint":
			m.albedo_color = Color(0.88, 0.85, 0.76)
			m.roughness = 0.85
		"boards":
			_tex(m, "res://assets/textures/hotel/parquet", 0.85, true)
			m.albedo_color = Color(0.78, 0.6, 0.45)
			m.roughness = 0.45
		"lino":
			m.albedo_color = Color(0.36, 0.3, 0.25)
			m.roughness = 0.5
		"paper":
			_tex(m, "res://assets/textures/hotel/silk_stripe", 1.1)
			m.albedo_color = Color(0.86, 0.5, 0.38)
			m.roughness = 0.8
		"study_green":
			m.albedo_color = Color(0.17, 0.27, 0.22)
			m.roughness = 0.75
		"kitchen_yellow":
			m.albedo_color = Color(0.86, 0.74, 0.46)
			m.roughness = 0.8
		"hall_low":
			m.albedo_color = Color(0.24, 0.3, 0.27)
			m.roughness = 0.6
		"hall_high":
			m.albedo_color = Color(0.76, 0.72, 0.6)
			m.roughness = 0.88
		"strong_grey":
			m.albedo_color = Color(0.4, 0.41, 0.4)
			m.metallic = 0.3
			m.roughness = 0.6
		"iron":
			m.albedo_color = Color(0.06, 0.065, 0.06)
			m.metallic = 0.6
			m.roughness = 0.55
		"bulb":
			m.albedo_color = Color(1.0, 0.9, 0.7)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.5)
			m.emission_energy_multiplier = 4.0
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.7, 0.8, 0.85, 0.12)
			m.roughness = 0.05
			m.metallic_specular = 0.8
		"cable":
			m.albedo_color = Color(0.03, 0.03, 0.03)
			m.roughness = 0.6
		"coping":
			m.albedo_color = Color(0.5, 0.48, 0.45)
			m.roughness = 0.9
		"terrace_tile":
			_tex(m, "res://assets/textures/hotel/tile_quarry", 0.9, true)
			m.albedo_color = Color(0.92, 0.84, 0.78)
			m.roughness = 0.6
		"fascia":
			m.albedo_color = Color(0.08, 0.24, 0.21)
			m.roughness = 0.4
		"fire":
			m.albedo_color = Color(1.0, 0.5, 0.2)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.42, 0.12)
			m.emission_energy_multiplier = 3.0
		"tar":
			m.albedo_color = Color(0.09, 0.09, 0.09)
			m.roughness = 0.95
		"void":
			m.albedo_color = Color(0.05, 0.045, 0.04)
			m.roughness = 1.0
		"spark_gold", "spark_rose", "spark_teal":
			var c := {"spark_gold": Color(1.0, 0.75, 0.3), "spark_rose": Color(1.0, 0.35, 0.55), "spark_teal": Color(0.35, 0.95, 0.85)}[name] as Color
			m.albedo_color = c
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = 6.0
		_:
			return false
	return true


## The house's walls: "laundrette" (mint tile to the shoulder, cream over),
## "living" (wallpaper over a skirting, a picture rail), "study" (walnut
## panelling to the dado, green over), "kitchen", "landing", "hall" (a dark
## dado and worn cream), "strongroom" (painted steel), and "garden" (brick
## with a coping on top, for the yard's walls and the terrace's parapet).
func _more_span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, h: float) -> void:
	match style:
		"laundrette":
			if y0 < 0.12:
				_face(a, u, facing, s0, s1, y0, 0.12, _mat("steel"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.12), minf(y1, 1.5), _mat("mint_tile"), 0.02)
			if y0 <= 1.5 and y1 >= 1.53:
				_face(a, u, facing, s0, s1, 1.5, 1.53, _mat("steel"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 1.53), y1, _mat("cream_paint"), 0.015)
		"living", "landing":
			if y0 < 0.15:
				_face(a, u, facing, s0, s1, y0, 0.15, _mat("walnut"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.15), y1, _mat("paper" if style == "living" else "cream_paint"), 0.015)
			if style == "living" and y0 <= 2.25 and y1 >= 2.29:
				_face(a, u, facing, s0, s1, 2.25, 2.29, _mat("walnut"), 0.04)
		"study":
			_face(a, u, facing, s0, s1, y0, minf(y1, 1.1), _mat("walnut"), 0.03)
			if y0 <= 1.08 and y1 >= 1.14:
				_face(a, u, facing, s0, s1, 1.08, 1.14, _mat("walnut"), 0.05)
			_face(a, u, facing, s0, s1, maxf(y0, 1.1), y1, _mat("study_green"), 0.015)
		"kitchen":
			if y0 < 0.1:
				_face(a, u, facing, s0, s1, y0, 0.1, _mat("walnut"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.1), y1, _mat("kitchen_yellow"), 0.015)
		"hall":
			if y0 < 0.12:
				_face(a, u, facing, s0, s1, y0, 0.12, _mat("walnut"), 0.025)
			_face(a, u, facing, s0, s1, maxf(y0, 0.12), minf(y1, 1.0), _mat("hall_low"), 0.015)
			if y0 <= 0.98 and y1 >= 1.03:
				_face(a, u, facing, s0, s1, 0.98, 1.03, _mat("walnut"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 1.0), y1, _mat("hall_high"), 0.015)
		"strongroom":
			_face(a, u, facing, s0, s1, y0, y1, _mat("strong_grey"), 0.02)
		"garden":
			var y := y0
			while y < y1 - 0.01:
				var hh := minf(4.0, y1 - y)
				_panels("WornBrick_Plain_4", a, u, facing, s0, s1, y, hh / 4.0)
				y += 4.0


func _more_wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	match style:
		"laundrette", "living", "landing", "study", "kitchen", "hall":
			_face(a, u, facing, 0.0, length, h - 0.08, h, _mat("cream"), 0.05)
		"garden":
			_face(a, u, facing, -0.05, length + 0.05, h, h + 0.07, _mat("coping"), 0.32, -0.26)


# --- Helpers ------------------------------------------------------------------------------------

## Builds on a node `y` up in a room (the outside of the flat's walls, over
## the yard).
func _raised(zone: String, y: float) -> void:
	var key := "%s@%.2f" % [zone, y]
	if not _raised_nodes.has(key):
		var n := Node3D.new()
		n.name = "%sAt%d" % [str(zone).capitalize().replace(" ", ""), int(y * 10.0)]
		n.position.y = y
		_rooms[zone].add_child(n)
		_raised_nodes[key] = n
	_at = _raised_nodes[key]


## A transform at the middle of `a` to `b`, its -z along the way and its +y
## as near up as it goes.
static func _along(a: Vector3, b: Vector3) -> Transform3D:
	var d := (b - a).normalized()
	return Transform3D(Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.99 else Vector3.FORWARD), (a + b) * 0.5)


## A bar from `a` to `b`, `w` wide and `h` deep: a rail, a cable, a strut.
func _beam(a: Vector3, b: Vector3, w: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w, h, maxf(a.distance_to(b), 0.001))
	mi.mesh = box
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_at.add_child(mi)
	mi.transform = _along(a, b)
	return mi


## A slope people walk up: a blocking slab whose top runs from `foot` to
## `head`, `width` wide (stairs under 30 degrees).
func _ramp(foot: Vector3, head: Vector3, width: float) -> void:
	var xf := _along(foot, head)
	xf.origin -= xf.basis.y * 0.1
	_sloped_block(xf, Vector3(width, 0.2, foot.distance_to(head)))


## A thin blocking rail standing `h` over the line from `a` to `b`.
func _rail_block(a: Vector3, b: Vector3, h: float) -> void:
	var xf := _along(a, b)
	xf.origin += xf.basis.y * h * 0.5
	_sloped_block(xf, Vector3(0.06, h, a.distance_to(b)))


func _sloped_block(xf: Transform3D, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Kit.LAYER_WORLD
	body.collision_mask = 0
	_at.add_child(body)
	body.transform = xf
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)


## Lit bulbs along a sagging cable from `a` to `b`: `n` of them, the middle
## `sag` lower than the ends. One multimesh a string.
func _string(a: Vector3, b: Vector3, n: int, sag: float) -> void:
	var pts: Array[Vector3] = []
	for i in n + 1:
		var f := float(i) / n
		pts.append(a.lerp(b, f) - Vector3(0, sag * 4.0 * f * (1.0 - f), 0))
	for i in n:
		_beam(pts[i], pts[i + 1], 0.012, 0.012, _mat("cable"))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	s.radial_segments = 8
	s.rings = 4
	s.material = _mat("bulb")
	mm.mesh = s
	mm.instance_count = n - 1
	for i in range(1, n):
		mm.set_instance_transform(i - 1, Transform3D(Basis.IDENTITY, pts[i] - Vector3(0, 0.06, 0)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_at.add_child(mmi)


## A bare bulb on a flex from the ceiling at `top`, hanging to `y`.
func _bare_bulb(x: float, z: float, y: float, top: float) -> void:
	_slab(Vector3(x, (y + top) * 0.5 + 0.04, z), Vector3(0.01, top - y - 0.08, 0.01), _mat("cable"))
	_slab(Vector3(x, y + 0.06, z), Vector3(0.04, 0.05, 0.04), _mat("bronze"))
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.045
	s.height = 0.1
	mi.mesh = s
	mi.material_override = _mat("bulb")
	mi.position = Vector3(x, y, z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_at.add_child(mi)


## Stairs from `foot` (the bottom of the first riser) up `rise` over `run`
## along `dir`, `width` wide: solid steps to the floor with boards on the
## treads, a slope to walk on, and blocks under it so nobody walks into
## the steps.
func _stairs(foot: Vector3, dir: Vector2, rise: float, run: float, width: float, steps: int) -> void:
	var d := Vector3(dir.x, 0.0, dir.y)
	var going := run / steps
	var step_h := rise / steps
	var along := Vector3(absf(d.x), 0.0, absf(d.z))
	var wide := Vector3(absf(d.z), 0.0, absf(d.x)) * width
	for i in steps:
		var top := step_h * (i + 1)
		var c := foot + d * (going * (i + 0.5))
		_slab(Vector3(c.x, foot.y + top * 0.5, c.z), wide + along * going + Vector3(0, top, 0), _mat("cream_paint"))
		var nose := c + d * -0.02
		_slab(Vector3(nose.x, foot.y + top - 0.012, nose.z), wide + along * (going + 0.04) + Vector3(0, 0.03, 0), _mat("walnut"))
	_ramp(foot, foot + d * run + Vector3(0, rise, 0), width)
	var s := 1.0
	while s < run - 0.05:
		var s1 := minf(s + 1.0, run)
		var low := rise * s / run - 0.14
		var c := foot + d * ((s + s1) * 0.5)
		_solid(Vector3(c.x, foot.y + low * 0.5, c.z), wide + along * (s1 - s) + Vector3(0, low, 0))
		s = s1


## A sash window seen from outside, set in the middle of a wall `0.2` deep:
## a painted frame, a bar across, and glass you can see the room through.
func _sash(at: Vector2, facing: Vector2, w: float, y0: float, y1: float) -> void:
	var along := Vector2(-facing.y, facing.x)
	var size := func(a: float, hh: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, hh, absf(along.y) * a + absf(facing.y) * d)
	var mid := at - facing * 0.1
	_slab(_v(mid, (y0 + y1) * 0.5), size.call(w, y1 - y0, 0.01), _mat("glass"))
	for side in [-1.0, 1.0]:
		_slab(_v(mid + along * side * (w * 0.5 - 0.03), (y0 + y1) * 0.5), size.call(0.06, y1 - y0, 0.06), _mat("cream"))
	for y in [y0 + 0.03, (y0 + y1) * 0.5, y1 - 0.03]:
		_slab(_v(mid, y), size.call(w, 0.06, 0.06), _mat("cream"))
	_slab(_v(at + facing * 0.04, y0 - 0.03), size.call(w + 0.12, 0.06, 0.16), _mat("coping"))


## A use the job puts an item at: its meta is "item:<item>".
func _item_at(id: String, item: String, at: Vector3, size: Vector3, model := "", yaw := 0.0) -> StaticBody3D:
	var u := _use(id, at, size, model, yaw)
	u.set_meta("use", "item:" + item)
	return u


# --- The ground under it all ------------------------------------------------------------------

func _ground() -> void:
	_in("street")
	# Everything stands on y = 0 but the road, a kerb's height lower.
	_solid(Vector3(0.0, -0.25, (-34.0 + KERB) * 0.5), Vector3(64.0, 0.5, KERB + 34.0))
	_solid(Vector3(0.0, -0.4, (KERB + FAR_KERB) * 0.5), Vector3(64.0, 0.5, FAR_KERB - KERB))
	_solid(Vector3(0.0, -0.25, (FAR_KERB + ACROSS) * 0.5 + 1.0), Vector3(64.0, 0.5, ACROSS - FAR_KERB + 2.0))
	# Under the house, so no gap between floors shows the sky.
	_slab(Vector3(0.0, -0.12, -13.0), Vector3(14.0, 0.1, 28.0), _mat("void"))


# --- The laundrette ---------------------------------------------------------------------------

func _laundrette() -> void:
	_in("laundrette")
	var r := Rect2(-5.8, -8.8, 11.6, 8.55)
	_floor(r, "checker")
	_wall("laundrette", Vector2(-5.8, -0.25), Vector2(-5.8, -8.8), Vector2(1, 0), SHOP_H)
	_wall("laundrette", Vector2(-5.8, -8.8), Vector2(5.8, -8.8), Vector2(0, 1), SHOP_H, [{"at": 3.5, "w": 1.1, "h": 2.3}])
	_wall("laundrette", Vector2(5.8, -8.8), Vector2(5.8, -0.25), Vector2(-1, 0), SHOP_H)
	var holes := [{"at": -5.0, "w": 1.04, "h": 2.8}]
	for x in [-3.0, -1.0, 1.0, 3.0]:
		holes.append({"at": x, "w": 1.8, "h": 2.85, "y0": 0.62})
	holes.append({"at": 4.95, "w": 1.7, "h": 2.85, "y0": 0.62})
	_wall("laundrette", Vector2(5.8, -0.25), Vector2(-5.8, -0.25), Vector2(0, -1), SHOP_H, holes)
	_ceiling(r, SHOP_H, "plaster_white")
	# A window counter all along the front, under the glass.
	_slab(Vector3(0.9, 0.6, -0.4), Vector3(9.8, 0.05, 0.32), _mat("walnut"))
	_reveal(Vector2(-5.0, -0.25), Vector2(1, 0), 1.04, 2.8, 0.1, _mat("steel"), "steel")
	# Washers down the west wall, dryers along the back.
	for i in 8:
		_box("mae_washer", Vector3(-5.46, 0.0, -2.6 - i * 0.7), PI * 0.5)
	for i in 8:
		_box("mae_dryer", Vector3(-4.5 + i * 0.82, 0.0, -8.365))
	_slab(Vector3(-1.63, 2.06, -8.5), Vector3(6.66, 0.22, 0.6), _mat("cream_paint"))
	# Folding tables down the middle, baskets on them.
	for x in [-2.4, -0.4]:
		_box("mae_folding_table", Vector3(x, 0.0, -4.6))
	_m("mae_basket", Vector3(-2.9, 0.9, -4.5), 0.2)
	_m("mae_basket", Vector3(0.1, 0.9, -4.7), -0.3)
	_m("mae_basket", Vector3(-4.6, 0.0, -3.6), 0.4)
	# Mae's counter by the back, the drinks machine, chairs under the windows.
	_box("mae_counter", Vector3(4.6, 0.0, -6.0), -PI * 0.5)
	_box("mae_vending", Vector3(5.54, 0.0, -3.0), -PI * 0.5)
	_box("mae_waiting_chairs", Vector3(-1.4, 0.0, -0.85), PI)
	_box("mae_bench", Vector3(4.6, 0.0, -0.85), PI)
	_m("potted_palm", Vector3(5.4, 0.0, -1.75), 0.0, Vector3.ONE * 0.6)
	_solid(Vector3(5.4, 0.45, -1.75), Vector3(0.4, 0.9, 0.4))
	# The bell over the door, the clock, and the way through to the back.
	_m("mae_door_bell", Vector3(-4.35, 2.3, -0.25), PI)
	clocks.append(_m("wall_clock", Vector3(1.9, 2.25, -8.8), 0.0, Vector3.ONE * 0.45))
	_sign("PRIVATE", Vector3(3.5, 2.55, -8.76), 0.0, 30, Color(0.2, 0.3, 0.27))
	_sign("SERVICE WASH\nWASH AND FOLD\nOPEN 7 TILL 9", Vector3(5.77, 2.1, -4.6), -PI * 0.5, 28, Color(0.2, 0.3, 0.27), 0.004)
	_sign("LAUNDRETTE", Vector3(1.0, 2.62, -0.33), 0.0, 48, Color(2.4, 0.6, 1.1), 0.005)
	# Strip lights, cool and flat, as a laundrette is.
	for x in [-3.5, -1.0, 1.5, 4.0]:
		for z in [-2.6, -6.2]:
			_no_shadow(_m("mae_strip_light", Vector3(x, SHOP_H - 0.2, z), PI * 0.5))
	var main := _omni(Vector3(-1.0, 2.6, -4.4), COOL, 1.2, 8.0, true)
	main.shadow_bias = 0.08
	_omni(Vector3(3.6, 2.6, -4.4), COOL, 0.9, 6.5)
	_omni(Vector3(-4.0, 2.6, -6.4), COOL, 0.6, 5.0)
	_omni(Vector3(1.0, 2.3, -0.9), Color(1.0, 0.45, 0.7), 0.25, 3.0)
	_probe(r, SHOP_H, Color(0.32, 0.36, 0.36), 0.4)


# --- The back hall and the stairs -------------------------------------------------------------

func _back_hall() -> void:
	_in("back_hall")
	var r := Rect2(2.2, -17.8, 3.6, 8.6)
	_floor(r, "lino")
	_wall("hall", Vector2(2.2, -9.2), Vector2(2.2, -17.8), Vector2(1, 0), SHOP_H, [{"at": -11.2, "w": 0.95, "h": 2.1}])
	_wall("hall", Vector2(2.2, -17.8), Vector2(5.8, -17.8), Vector2(0, 1), SHOP_H, [{"at": 3.3, "w": 0.95, "h": 2.15}])
	_wall("hall", Vector2(5.8, -17.8), Vector2(5.8, -9.2), Vector2(-1, 0), SHOP_H)
	_wall("hall", Vector2(5.8, -9.2), Vector2(2.2, -9.2), Vector2(0, -1), SHOP_H, [{"at": 3.5, "w": 1.1, "h": 2.3}])
	_reveal(Vector2(3.5, -9.0), Vector2(1, 0), 1.1, 2.3, 0.4, _mat("walnut"))
	# The ceiling, with the stairwell open over the stairs.
	var ceil := _mat("plaster_white")
	_slab(Vector3((2.0 + WELL.position.x) * 0.5, SHOP_H + 0.05, -13.5), Vector3(WELL.position.x - 2.0, 0.1, 9.0), ceil)
	_slab(Vector3((WELL.position.x + 6.0) * 0.5, SHOP_H + 0.05, (WELL.end.y - 9.0) * 0.5), Vector3(6.0 - WELL.position.x, 0.1, -9.0 - WELL.end.y), ceil)
	_slab(Vector3((WELL.position.x + 6.0) * 0.5, SHOP_H + 0.05, (WELL.position.y - 18.0) * 0.5), Vector3(6.0 - WELL.position.x, 0.1, WELL.position.y + 18.0), ceil)
	# The well's sides, from the ceiling up to the landing's floor.
	var lining := _mat("hall_high")
	_slab(Vector3(WELL.position.x, (SHOP_H + FLAT) * 0.5, WELL.get_center().y), Vector3(0.04, FLAT - SHOP_H, WELL.size.y), lining)
	_slab(Vector3(WELL.get_center().x, (SHOP_H + FLAT) * 0.5, WELL.end.y), Vector3(WELL.size.x, FLAT - SHOP_H, 0.04), lining)
	_slab(Vector3(WELL.get_center().x, (SHOP_H + FLAT) * 0.5 - 0.05, WELL.position.y), Vector3(WELL.size.x, FLAT - SHOP_H - 0.1, 0.04), lining)
	_slab(Vector3(5.78, FLAT * 0.5 + SHOP_H * 0.5, WELL.get_center().y), Vector3(0.04, FLAT - SHOP_H, WELL.size.y), lining)
	# The stairs up to the flat, along the east wall.
	_stairs(STAIRS_FOOT, Vector2(0, -1), FLAT, STAIRS_RUN, STAIRS_W, 18)
	var rail_a := Vector3(4.5, 0.95, STAIRS_FOOT.z - 0.4)
	var rail_b := Vector3(4.5, FLAT + 0.95, STAIRS_FOOT.z - STAIRS_RUN)
	_beam(rail_a, rail_b, 0.06, 0.05, _mat("walnut"))
	_m("mae_panel_door", Vector3(4.53, 0.0, -14.4), -PI * 0.5, Vector3(0.7, 0.62, 1.0))
	# Coats on hooks, laundry waiting, the fuse box.
	_slab(Vector3(2.24, 1.7, -14.5), Vector3(0.06, 0.08, 1.4), _mat("walnut"))
	for z in [-14.0, -14.45, -14.95]:
		_slab(Vector3(2.36, 1.3, z), Vector3(0.22, 0.8, 0.34), Kit.flat(Color(0.22 + absf(z + 14.4) * 0.3, 0.2, 0.2), 0.9))
	_m("mae_basket", Vector3(2.55, 0.0, -16.6), 0.3)
	_m("mae_basket", Vector3(2.6, 0.31, -16.65), -0.2)
	_slab(Vector3(5.75, 1.9, -9.8), Vector3(0.1, 0.5, 0.36), Kit.flat(Color(0.5, 0.48, 0.42), 0.7))
	_bare_bulb(3.4, -13.0, SHOP_H - 0.5, SHOP_H)
	_omni(Vector3(3.4, SHOP_H - 0.6, -13.0), WARM, 1.0, 7.0)
	_omni(Vector3(3.4, SHOP_H - 0.6, -16.4), WARM, 0.5, 4.0)
	_probe(r, SHOP_H, Color(0.36, 0.32, 0.26), 0.35)


# --- Mae's back room --------------------------------------------------------------------------

func _back_room() -> void:
	_in("back_room")
	var r := Rect2(-5.8, -17.8, 7.6, 8.6)
	_floor(r, "lino")
	_m("rug", Vector3(-2.0, 0.0, -13.6))
	_wall("paint", Vector2(-5.8, -9.2), Vector2(-5.8, -17.8), Vector2(1, 0), SHOP_H)
	_wall("paint", Vector2(-5.8, -17.8), Vector2(1.8, -17.8), Vector2(0, 1), SHOP_H)
	_wall("paint", Vector2(1.8, -17.8), Vector2(1.8, -9.2), Vector2(-1, 0), SHOP_H, [{"at": -11.2, "w": 0.95, "h": 2.1}])
	_wall("paint", Vector2(1.8, -9.2), Vector2(-5.8, -9.2), Vector2(0, -1), SHOP_H)
	_ceiling(r, SHOP_H, "plaster")
	# The briefing table, chairs round it, the drawer where Silas's copy is.
	_box("mae_briefing_table", Vector3(-2.0, 0.0, -13.6))
	for x in [-2.6, -1.4]:
		_box("mae_chair", Vector3(x, 0.0, -14.6))
		_box("mae_chair", Vector3(x, 0.0, -12.6), PI)
	_box("mae_chair", Vector3(-3.55, 0.0, -13.6), PI * 0.5)
	_box("mae_chair", Vector3(-0.45, 0.0, -13.6), -PI * 0.5)
	_item_at("drawer", "copy", Vector3(-2.0, 0.5, -13.0), Vector3(0.5, 0.18, 0.2))
	_m("mae_files", Vector3(-2.5, 0.78, -13.75), 0.2)
	_m("mae_files", Vector3(-1.3, 0.78, -13.5), -0.4)
	# The floor plans of the season on the west wall.
	_m("mae_plans_board", Vector3(-5.8, 1.0, -13.6), PI * 0.5)
	_use("plans", Vector3(-5.7, 1.0, -13.6), Vector3(0.2, 1.3, 2.4))
	# The kettle on the sideboard, the sofa, the stock.
	_box("mae_sideboard", Vector3(-3.5, 0.0, -17.55))
	_use("kettle", Vector3(-3.5, 0.9, -17.5), Vector3(1.4, 0.3, 0.45))
	_box("mae_sofa_small", Vector3(-4.0, 0.0, -9.63), PI)
	_box("mae_crates", Vector3(1.4, 0.0, -17.5))
	_box("mae_crates", Vector3(0.85, 0.0, -17.55), 0.15)
	_m("mae_crates", Vector3(1.38, 0.96, -17.5), -0.1)
	_box("filing_cabinet", Vector3(-5.45, 0.0, -10.4), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(-1.0, 1.9, -17.8), 0.0, Vector3.ONE * 0.4))
	_sign("CALDERA\nSEASON", Vector3(-5.77, 2.48, -13.6), PI * 0.5, 30, Color(0.2, 0.16, 0.12), 0.004)
	# The green lamp over the table, and the room's one shadow.
	_no_shadow(_m("mae_pendant_green", Vector3(-2.0, SHOP_H - 0.95, -13.6)))
	var lamp := _omni(Vector3(-2.0, SHOP_H - 0.98, -13.6), Color(1.0, 0.82, 0.58), 1.6, 6.5, true)
	lamp.shadow_bias = 0.06
	_omni(Vector3(-3.5, 1.9, -16.8), CANDLE, 0.4, 3.0)
	_omni(Vector3(0.6, 2.4, -10.6), WARM, 0.35, 4.0)
	_probe(r, SHOP_H, Color(0.34, 0.3, 0.22), 0.3)


# --- The yard and the alley -------------------------------------------------------------------

func _yard() -> void:
	_in("yard")
	_floor(Rect2(1.0, -26.3, 4.8, 8.3), "concrete")
	# The house's back wall, the neighbor's wall, the yard wall with the gate.
	_wall("brick", Vector2(1.0, -18.0), Vector2(6.0, -18.0), Vector2(0, -1), FLAT, [{"at": 3.3, "w": 0.95, "h": 2.15}])
	_reveal(Vector2(3.3, -17.9), Vector2(1, 0), 0.95, 2.15, 0.2, _mat("cream_paint"), "concrete")
	_wall("brick", Vector2(5.8, -18.0), Vector2(5.8, -26.3), Vector2(-1, 0), 9.6)
	_wall("garden", Vector2(5.8, -26.3), Vector2(1.0, -26.3), Vector2(0, 1), 2.4, [{"at": 4.0, "w": 1.2, "h": 2.4}])
	# The back of the outbuilding under the terrace, with the parapet on top.
	_wall("brick", Vector2(1.0, -26.3), Vector2(1.0, -19.45), Vector2(1, 0), FLAT + 1.0)
	# Under the landing at the top of the iron stairs, no parapet: the way onto the terrace.
	_panels("WornBrick_Plain_4", Vector2(1.0, -19.45), Vector2(0, 1), Vector2(1, 0), 0.0, 1.45, 0.0, 3.5 / 4.0, 1.45)
	_solid(Vector3(0.9, 1.75, -18.725), Vector3(0.2, 3.5, 1.45))
	_solid(Vector3(-2.5, 1.7, -22.25), Vector3(7.0, 3.4, 8.5))
	# The iron stairs up to the terrace.
	_m("mae_iron_stairs", IRON_FOOT, PI)
	var head := IRON_FOOT + Vector3(0.0, FLAT, STAIRS_RUN)
	_ramp(IRON_FOOT, head, 1.1)
	var s1 := IRON_FOOT + Vector3(0.0, FLAT / STAIRS_RUN, 1.0)
	_rail_block(s1 + Vector3(0.6, 0.0, 0.0), head + Vector3(0.6, 0.0, 0.0), 1.0)
	# Bins, crates, the washing line.
	for z in [-20.4, -21.15]:
		_box("wheelie_bin", Vector3(5.4, 0.0, z), -PI * 0.5)
	_box("mae_crates", Vector3(5.5, 0.0, -24.9), -PI * 0.5)
	_box("mae_crates", Vector3(5.45, 0.0, -24.25), -PI * 0.5 + 0.2)
	_m("mae_whirligig", Vector3(4.85, 0.0, -22.4), 0.3, Vector3(0.75, 1.0, 0.75))
	_solid(Vector3(4.85, 0.9, -22.4), Vector3(0.1, 1.8, 0.1))
	_m("Prop_Drain", Vector3(3.6, 0.002, -21.0))
	# A light over the back door.
	_m("bulkhead_light", Vector3(3.3, 2.5, -18.0), PI)
	_omni(Vector3(3.3, 2.3, -18.5), SODIUM, 1.4, 7.5)
	_omni(Vector3(3.0, 2.0, -24.5), SODIUM, 0.35, 5.0)
	# The flat's back wall over the yard, with the landing's window.
	_raised("yard", FLAT)
	_wall("brick", Vector2(2.4, -18.0), Vector2(6.0, -18.0), Vector2(0, -1), FLAT_H, [{"at": 3.4, "w": 1.0, "h": 2.3, "y0": 0.9}])
	_sash(Vector2(3.4, -18.0), Vector2(0, -1), 1.0, 0.9, 2.3)
	_raised("yard", FLAT + FLAT_H)
	var w2 := _m("WornBrick_WindowLarge", Vector3(4.2, 0.0, -18.0), PI, Vector3(0.9, 1.0, 1.0))
	_override(w2, "MI_FakeInterior", _window_mat(1, Color(1.0, 0.8, 0.6)))
	_panels("Cornice_WornBrick_Center", Vector2(6.0, -18.0), Vector2(-1, 0), Vector2(0, -1), 0.0, 3.6, FLAT_H)
	_probe(Rect2(1.0, -26.3, 4.8, 8.3), 6.0, Color(0.2, 0.18, 0.16), 0.25)


func _alley() -> void:
	_in("alley")
	_floor(Rect2(-12.0, -30.0, 24.0, 3.5), "asphalt")
	_wall("brick", Vector2(-12.0, -30.0), Vector2(12.0, -30.0), Vector2(0, 1), 6.0)
	_wall("brick", Vector2(-12.0, -26.5), Vector2(-12.0, -30.0), Vector2(1, 0), 6.0)
	_wall("brick", Vector2(12.0, -30.0), Vector2(12.0, -26.5), Vector2(-1, 0), 6.0)
	_wall("garden", Vector2(-6.0, -26.5), Vector2(-12.0, -26.5), Vector2(0, -1), 2.4)
	_wall("garden", Vector2(12.0, -26.5), Vector2(6.0, -26.5), Vector2(0, -1), 2.4)
	_wall("brick", Vector2(1.0, -26.5), Vector2(-6.0, -26.5), Vector2(0, -1), FLAT + 1.0)
	_wall("brick", Vector2(6.0, -26.5), Vector2(1.0, -26.5), Vector2(0, -1), 2.4, [{"at": 4.0, "w": 1.2, "h": 2.4}])
	# The neighbors' bins, a dumpster, a lamp on the far wall.
	_box("dumpster", Vector3(-8.0, 0.0, -29.4))
	_box("wheelie_bin", Vector3(8.2, 0.0, -29.6))
	_box("wheelie_bin", Vector3(8.9, 0.0, -29.6), 0.2)
	_box("pallet", Vector3(-3.2, 0.0, -29.5), 0.15)
	_m("Prop_Drain", Vector3(0.0, 0.002, -28.4))
	_m("bulkhead_light", Vector3(2.0, 2.8, -30.0))
	_omni(Vector3(2.0, 2.6, -29.6), SODIUM, 1.4, 9.0)
	_omni(Vector3(-7.0, 2.6, -29.6), SODIUM, 0.6, 6.0)
	_probe(Rect2(-12.0, -30.0, 24.0, 3.5), 6.0, Color(0.14, 0.13, 0.13), 0.2)


# --- The flat: the landing ----------------------------------------------------------------------

func _landing() -> void:
	_in("landing")
	var r := Rect2(2.2, -17.8, 3.6, 8.6)
	# The floor round the stairwell.
	_floor(Rect2(2.2, -17.8, WELL.position.x - 2.2, 8.6), "boards")
	_floor(Rect2(WELL.position.x, WELL.end.y, 5.8 - WELL.position.x, -9.2 - WELL.end.y), "boards")
	_floor(Rect2(WELL.position.x, -17.8, 5.8 - WELL.position.x, WELL.position.y + 17.8), "boards")
	_solid(Vector3((2.0 + WELL.position.x) * 0.5, -0.1, -13.5), Vector3(WELL.position.x - 2.0, 0.2, 9.0))
	_solid(Vector3((WELL.position.x + 6.0) * 0.5, -0.1, (WELL.end.y - 9.0) * 0.5), Vector3(6.0 - WELL.position.x, 0.2, -9.0 - WELL.end.y))
	_solid(Vector3((WELL.position.x + 6.0) * 0.5, -0.1, (WELL.position.y - 18.0) * 0.5), Vector3(6.0 - WELL.position.x, 0.2, WELL.position.y + 18.0))
	_wall("landing", Vector2(2.2, -9.2), Vector2(2.2, -17.8), Vector2(1, 0), FLAT_H, [{"at": -14.0, "w": 1.6, "h": 2.4}])
	_wall("landing", Vector2(2.2, -17.8), Vector2(5.8, -17.8), Vector2(0, 1), FLAT_H, [{"at": 3.4, "w": 1.0, "h": 2.3, "y0": 0.9}])
	_wall("landing", Vector2(5.8, -17.8), Vector2(5.8, -9.2), Vector2(-1, 0), FLAT_H)
	_wall("landing", Vector2(5.8, -9.2), Vector2(2.2, -9.2), Vector2(0, -1), FLAT_H, [{"at": 3.4, "w": 1.0, "h": 2.1}])
	_window(Vector2(3.4, -17.8), Vector2(0, 1), 1.0, 0.9, 2.3, 0.2)
	_solid(Vector3(3.4, 1.6, -17.95), Vector3(1.0, 1.4, 0.06))
	_ceiling(r, FLAT_H, "plaster_white")
	# Banisters round the well.
	var x0 := WELL.position.x - 0.03
	_solid(Vector3(x0, 0.5, WELL.get_center().y), Vector3(0.06, 1.0, WELL.size.y))
	_solid(Vector3(WELL.get_center().x, 0.5, WELL.end.y + 0.03), Vector3(WELL.size.x, 1.0, 0.06))
	_beam(Vector3(x0, 0.95, WELL.position.y), Vector3(x0, 0.95, WELL.end.y + 0.03), 0.07, 0.05, _mat("walnut"))
	_beam(Vector3(x0, 0.95, WELL.end.y + 0.03), Vector3(5.8, 0.95, WELL.end.y + 0.03), 0.07, 0.05, _mat("walnut"))
	var z := WELL.position.y + 0.12
	while z < WELL.end.y:
		_slab(Vector3(x0, 0.47, z), Vector3(0.03, 0.94, 0.03), _mat("cream"))
		z += 0.16
	var x := x0 + 0.16
	while x < 5.8:
		_slab(Vector3(x, 0.47, WELL.end.y + 0.03), Vector3(0.03, 0.94, 0.03), _mat("cream"))
		x += 0.16
	# The bathroom door, shut, and a few pictures.
	_m("mae_panel_door", Vector3(5.78, 0.0, -10.05), -PI * 0.5)
	_slab(Vector3(5.77, 2.13, -10.52), Vector3(0.05, 0.06, 1.06), _mat("walnut"))
	for zz in [-11.02, -10.02]:
		_slab(Vector3(5.77, 1.05, zz), Vector3(0.05, 2.1, 0.06), _mat("walnut"))
	_painting(Vector2(2.2, -16.4), Vector2(1, 0), 0.7, 1.4, 0.5, "painting_valley")
	_sign("Mind the stairs, love", Vector3(4.6, 2.1, -17.77), 0.0, 24, Color(0.3, 0.2, 0.15), 0.004)
	_bare_bulb(3.4, -13.5, FLAT_H - 0.45, FLAT_H)
	_omni(Vector3(3.4, FLAT_H - 0.6, -13.5), WARM, 0.9, 6.5)
	_omni(Vector3(3.6, FLAT_H - 0.6, -10.3), WARM, 0.45, 4.0)
	_probe(r, FLAT_H, Color(0.38, 0.32, 0.26), 0.3)


# --- The living room ----------------------------------------------------------------------------

func _living() -> void:
	_in("living")
	var r := Rect2(-5.8, -17.8, 7.6, 8.6)
	_floor(r, "boards")
	_solid(Vector3(-2.0, -0.1, -13.5), Vector3(8.0, 0.2, 9.0))
	_wall("living", Vector2(-5.8, -9.2), Vector2(-5.8, -17.8), Vector2(1, 0), FLAT_H)
	_wall("living", Vector2(-5.8, -17.8), Vector2(1.8, -17.8), Vector2(0, 1), FLAT_H,
			[{"at": -3.0, "w": 0.95, "h": 2.15}, {"at": -5.0, "w": 1.2, "h": 2.3, "y0": 0.9}])
	_wall("living", Vector2(1.8, -17.8), Vector2(1.8, -9.2), Vector2(-1, 0), FLAT_H, [{"at": -14.0, "w": 1.6, "h": 2.4}])
	_wall("living", Vector2(1.8, -9.2), Vector2(-5.8, -9.2), Vector2(0, -1), FLAT_H,
			[{"at": -3.6, "w": 0.95, "h": 2.1}, {"at": 1.0, "w": 0.9, "h": 2.1}])
	_reveal(Vector2(2.0, -14.0), Vector2(0, 1), 1.6, 2.4, 0.4, _mat("cream"))
	_reveal(Vector2(1.0, -9.0), Vector2(1, 0), 0.9, 2.1, 0.4, _mat("cream"))
	_window(Vector2(-5.0, -17.8), Vector2(0, 1), 1.2, 0.9, 2.3, 0.2)
	_solid(Vector3(-5.0, 1.6, -17.95), Vector3(1.2, 1.4, 0.06))
	_ceiling(r, FLAT_H, "plaster")
	# The fireplace on the west wall, a painting over it, photos on the mantel.
	_m("mae_fireplace", Vector3(-5.8, 0.0, -13.6), PI * 0.5)
	_solid(Vector3(-5.56, 0.6, -13.6), Vector3(0.48, 1.2, 1.8))
	_slab(Vector3(-5.45, 0.32, -13.6), Vector3(0.12, 0.16, 0.5), _mat("fire"))
	_painting(Vector2(-5.8, -13.6), Vector2(1, 0), 1.2, 1.62, 0.8, "painting_coast")
	for p in [[-14.15, 0.24], [-13.8, 0.18], [-13.05, 0.22]]:
		_slab(Vector3(-5.5, 1.35 + float(p[1]) * 0.5, float(p[0])), Vector3(0.03, float(p[1]), 0.18), _mat("gilt"))
	clocks.append(_m("wall_clock", Vector3(-5.6, 1.35, -13.35), PI * 0.5, Vector3.ONE * 0.25))
	# The big old sofa facing the fire, the coffee table, two armchairs.
	_m("rug", Vector3(-3.9, 0.0, -13.6), PI * 0.5)
	_box("mae_sofa_big", Vector3(-2.9, 0.0, -13.6), -PI * 0.5)
	_box("mae_coffee_table", Vector3(-4.2, 0.0, -13.6), PI * 0.5)
	_box("mae_armchair", Vector3(-4.2, 0.0, -15.3))
	_box("mae_armchair", Vector3(-4.2, 0.0, -11.9), PI)
	_box("mae_sideboard", Vector3(-5.55, 0.0, -16.3), PI * 0.5)
	# The records on the south wall, the decks and speakers by the dance floor.
	_box("mae_record_shelf", Vector3(-1.6, 0.0, -9.46), PI)
	_use("records", Vector3(-1.6, 0.6, -9.6), Vector3(1.7, 0.6, 0.3))
	_box("mae_dj_table", Vector3(0.2, 0.0, -16.6))
	for x in [-0.9, 1.3]:
		_box("mae_speaker", Vector3(x, 0.0, -16.5))
	_floor(Rect2(-1.0, -16.2, 2.6, 2.6), "parquet", 0.006, 0.012)
	# Lamps and the pendant.
	for p in [Vector2(-3.9, -17.45), Vector2(-5.4, -9.65)]:
		_box("mae_floor_lamp", _v(p))
		_omni(_v(p, 1.4), CANDLE, 0.55, 4.0)
	_pendant(-4.0, -13.6, FLAT_H - 1.2, FLAT_H)
	var main := _omni(Vector3(-3.0, 2.2, -13.0), WARM, 1.3, 8.0, true)
	main.shadow_bias = 0.08
	_omni(Vector3(-5.0, 0.5, -13.6), Color(1.0, 0.55, 0.25), 0.9, 3.5)
	_omni(Vector3(0.6, 2.4, -11.4), WARM, 0.5, 5.0)
	_spot(Vector3(0.2, 2.8, -17.4), Vector3(0.2, 0.0, -14.4), Color(1.0, 0.42, 0.7), 2.4, 6.0, 38.0)
	_spot(Vector3(1.4, 2.8, -12.0), Vector3(-0.2, 0.0, -15.2), Color(0.4, 0.6, 1.0), 1.4, 6.0, 30.0)
	# String lights along the picture rail.
	_string(Vector3(-5.7, 2.35, -9.3), Vector3(1.7, 2.35, -9.3), 22, 0.12)
	_string(Vector3(-5.7, 2.35, -17.7), Vector3(1.7, 2.35, -17.7), 22, 0.12)
	_probe(r, FLAT_H, Color(0.42, 0.3, 0.22), 0.35)


# --- The kitchen --------------------------------------------------------------------------------

func _kitchen() -> void:
	_in("kitchen")
	var r := Rect2(0.2, -8.8, 5.6, 8.55)
	_floor(r, "quarry")
	_solid(Vector3(3.0, -0.1, -4.5), Vector3(6.0, 0.2, 9.0))
	_wall("kitchen", Vector2(0.2, -0.25), Vector2(0.2, -8.8), Vector2(1, 0), FLAT_H)
	_wall("kitchen", Vector2(0.2, -8.8), Vector2(5.8, -8.8), Vector2(0, 1), FLAT_H, [{"at": 1.0, "w": 0.9, "h": 2.1}, {"at": 3.4, "w": 1.0, "h": 2.1}])
	_wall("kitchen", Vector2(5.8, -8.8), Vector2(5.8, -0.25), Vector2(-1, 0), FLAT_H)
	_wall("kitchen", Vector2(5.8, -0.25), Vector2(0.2, -0.25), Vector2(0, -1), FLAT_H, [{"at": 3.0, "w": 3.1, "h": 2.39, "y0": 0.8}])
	_reveal(Vector2(3.4, -9.0), Vector2(1, 0), 1.0, 2.1, 0.4, _mat("cream"))
	_window(Vector2(3.0, -0.25), Vector2(0, -1), 3.1, 0.8, 2.39, 0.1)
	_solid(Vector3(3.0, 1.6, -0.2), Vector3(3.1, 1.6, 0.06))
	_ceiling(r, FLAT_H, "plaster_white")
	# The cooking side: the fridge, the units with cupboards over, the cooker.
	_box("mae_fridge", Vector3(5.42, 0.0, -8.35), -PI * 0.5)
	_box("mae_kitchen_run", Vector3(5.48, 0.0, -6.0), -PI * 0.5)
	_m("mae_wall_cupboards", Vector3(5.8, 1.45, -6.0), -PI * 0.5)
	_face(Vector2(5.8, -7.5), Vector2(0, 1), Vector2(-1, 0), 0.0, 3.0, 0.9, 1.45, _mat("tile_white"), 0.02)
	_box("mae_cooker", Vector3(5.45, 0.0, -3.9), -PI * 0.5)
	_face(Vector2(5.8, -4.3), Vector2(0, 1), Vector2(-1, 0), 0.0, 0.8, 0.9, 1.6, _mat("tile_white"), 0.02)
	# The card on the fridge.
	_slab(Vector3(5.06, 1.3, -8.35), Vector3(0.01, 0.06, 0.09), _mat("cream"))
	# Benny's drinks, out from the wall so he can stand behind them.
	_box("mae_drinks_table", Vector3(1.3, 0.0, -5.4), PI * 0.5)
	# The table in the middle that nobody sits at.
	_box("mae_kitchen_table", Vector3(3.2, 0.0, -3.2))
	_box("mae_chair", Vector3(2.75, 0.0, -3.95))
	_box("mae_chair", Vector3(3.65, 0.0, -2.45), PI)
	clocks.append(_m("wall_clock", Vector3(1.9, 2.0, -8.8), 0.0, Vector3.ONE * 0.38))
	_m("potted_palm", Vector3(0.6, 0.0, -0.75), 0.0, Vector3.ONE * 0.5)
	_solid(Vector3(0.6, 0.4, -0.75), Vector3(0.36, 0.8, 0.36))
	_pendant(3.2, -3.2, FLAT_H - 1.2, FLAT_H)
	var main := _omni(Vector3(3.2, 2.0, -3.6), WARM, 1.4, 7.5, true)
	main.shadow_bias = 0.08
	_omni(Vector3(4.6, 2.3, -6.6), WARM, 0.7, 5.0)
	_omni(Vector3(1.2, 2.2, -5.4), CANDLE, 0.5, 3.5)
	_probe(r, FLAT_H, Color(0.4, 0.34, 0.24), 0.35)


# --- Mae's study and the strongroom -------------------------------------------------------------

func _study() -> void:
	_in("study")
	var r := Rect2(-5.8, -8.8, 5.6, 8.55)
	_floor(r, "boards")
	_solid(Vector3(-3.0, -0.1, -4.5), Vector3(6.0, 0.2, 9.0))
	_m("rug", Vector3(-3.8, 0.0, -3.4), PI * 0.5, Vector3(0.75, 1.0, 0.75))
	_wall("study", Vector2(-5.8, -0.25), Vector2(-5.8, -8.8), Vector2(1, 0), FLAT_H)
	_wall("study", Vector2(-5.8, -8.8), Vector2(-3.0, -8.8), Vector2(0, 1), FLAT_H, [{"at": -3.6, "w": 0.95, "h": 2.1}])
	_wall("study", Vector2(-3.0, -8.8), Vector2(-3.0, -5.0), Vector2(-1, 0), FLAT_H, [{"at": -7.1, "w": 0.9, "h": 2.0}])
	_wall("study", Vector2(-3.0, -5.0), Vector2(-0.2, -5.0), Vector2(0, 1), FLAT_H)
	_wall("study", Vector2(-0.2, -5.0), Vector2(-0.2, -0.25), Vector2(-1, 0), FLAT_H)
	_wall("study", Vector2(-0.2, -0.25), Vector2(-5.8, -0.25), Vector2(0, -1), FLAT_H, [{"at": -3.0, "w": 3.1, "h": 2.39, "y0": 0.8}])
	_reveal(Vector2(-3.6, -9.0), Vector2(1, 0), 0.95, 2.1, 0.4, _mat("walnut"))
	_window(Vector2(-3.0, -0.25), Vector2(0, -1), 3.1, 0.8, 2.39, 0.1)
	_solid(Vector3(-3.0, 1.6, -0.2), Vector3(3.1, 1.6, 0.06))
	_ceiling(r, FLAT_H, "plaster")
	# The strongroom in the corner: steel inside, its door and dial on the study side.
	_wall("strongroom", Vector2(-2.6, -5.4), Vector2(-2.6, -8.8), Vector2(1, 0), FLAT_H, [{"at": -7.1, "w": 0.9, "h": 2.0}])
	_wall("strongroom", Vector2(-2.6, -8.8), Vector2(-0.2, -8.8), Vector2(0, 1), FLAT_H)
	_wall("strongroom", Vector2(-0.2, -8.8), Vector2(-0.2, -5.4), Vector2(-1, 0), FLAT_H)
	_wall("strongroom", Vector2(-0.2, -5.4), Vector2(-2.6, -5.4), Vector2(0, -1), FLAT_H)
	_reveal(Vector2(-2.8, -7.1), Vector2(0, 1), 0.9, 2.0, 0.4, _mat("strong_grey"), "steel")
	_m("mae_strongroom_frame", Vector3(-3.0, 0.0, -7.1), -PI * 0.5)
	_m("mae_dial", Vector3(-3.0, 1.0, -6.25), -PI * 0.5)
	_use("dial", Vector3(-3.0, 0.98, -6.25), Vector3(0.14, 0.36, 0.28))
	_box("mae_strongroom_shelves", Vector3(-1.4, 0.0, -8.59))
	_box("mae_strongroom_shelves", Vector3(-1.4, 0.0, -5.61), PI)
	# The Rose on its plinth against the far wall.
	_slab(Vector3(-0.4, 0.5, -7.1), Vector3(0.4, 1.0, 0.7), _mat("walnut"))
	_slab(Vector3(-0.4, 1.005, -7.1), Vector3(0.42, 0.01, 0.72), _mat("red_carpet"))
	_solid(Vector3(-0.4, 0.5, -7.1), Vector3(0.4, 1.0, 0.7))
	_item_at("safe_shelf", "rose", Vector3(-0.4, 1.01, -7.25), Vector3(0.2, 0.16, 0.2), "mae_rose", PI * 0.5)
	_item_at("copy_safe", "copy", Vector3(-0.4, 1.01, -6.92), Vector3(0.2, 0.16, 0.2), "mae_rose", PI * 0.5)
	_bare_bulb(-1.4, -7.1, FLAT_H - 0.4, FLAT_H)
	_omni(Vector3(-1.4, FLAT_H - 0.55, -7.1), WARM, 0.9, 4.5)
	# Mae's desk under the window, her files, the buyer's view of the stone.
	_box("mae_desk", Vector3(-3.0, 0.0, -0.75))
	_box("mae_desk_chair", Vector3(-4.25, 0.0, -0.9), PI * 0.5)
	_item_at("desk", "rose", Vector3(-3.5, 0.76, -0.62), Vector3(0.2, 0.16, 0.2), "mae_rose")
	_item_at("copy_desk", "copy", Vector3(-3.2, 0.76, -0.55), Vector3(0.2, 0.16, 0.2), "mae_rose")
	_use("files", Vector3(-2.9, 0.76, -0.95), Vector3(0.4, 0.2, 0.34))
	# Books, files, a reading chair.
	for z in [-7.4, -6.3]:
		_box("mae_bookcase", Vector3(-5.61, 0.0, z), PI * 0.5)
	for x in [-2.2, -1.6]:
		_box("filing_cabinet", Vector3(x, 0.0, -4.675))
	_box("mae_armchair", Vector3(-5.1, 0.0, -3.6), PI * 0.5)
	_box("mae_floor_lamp", Vector3(-5.45, 0.0, -2.4))
	_m("notice_board", Vector3(-5.8, 1.15, -4.6), PI * 0.5)
	_painting(Vector2(-0.2, -2.6), Vector2(-1, 0), 1.3, 1.25, 0.9, "painting_caldera")
	clocks.append(_m("wall_clock", Vector3(-4.6, 2.1, -8.8), 0.0, Vector3.ONE * 0.36))
	# The desk lamp, the reading lamp, a dim wash.
	_omni(Vector3(-2.45, 1.15, -0.9), CANDLE, 0.7, 3.6)
	_omni(Vector3(-5.45, 1.45, -2.4), CANDLE, 0.45, 3.5)
	_omni(Vector3(-3.6, 2.5, -4.6), WARM, 0.6, 6.0)
	_probe(r, FLAT_H, Color(0.32, 0.3, 0.22), 0.3)


# --- The terrace --------------------------------------------------------------------------------

func _terrace() -> void:
	_in("terrace")
	_floor(Rect2(-5.8, -26.3, 6.8, 8.3), "terrace_tile")
	_solid(Vector3(-2.5, -0.1, -22.25), Vector3(7.0, 0.2, 8.5))
	# The parapets, the neighbor's wall, the back of the flat.
	_wall("garden", Vector2(0.75, -26.3), Vector2(-5.8, -26.3), Vector2(0, 1), 1.0)
	_wall("garden", Vector2(0.75, -19.45), Vector2(0.75, -26.3), Vector2(-1, 0), 1.0)
	_wall("brick", Vector2(-5.8, -26.3), Vector2(-5.8, -18.0), Vector2(1, 0), 6.0)
	_wall("brick", Vector2(-6.0, -18.0), Vector2(2.4, -18.0), Vector2(0, -1), FLAT_H,
			[{"at": -3.0, "w": 0.95, "h": 2.15}, {"at": -5.0, "w": 1.2, "h": 2.3, "y0": 0.9}])
	_reveal(Vector2(-3.0, -17.9), Vector2(1, 0), 0.95, 2.15, 0.2, _mat("cream"), "walnut")
	_sash(Vector2(-5.0, -18.0), Vector2(0, -1), 1.2, 0.9, 2.3)
	_raised("terrace", FLAT_H)
	for x in [-4.0, 0.0]:
		var up := _m("WornBrick_WindowLarge", Vector3(x, 0.0, -18.0), PI)
		_override(up, "MI_FakeInterior", _window_mat(0 if x < 0.0 else 2, Color(1.0, 0.8, 0.6)))
	_m("WornBrick_Plain_3", Vector3(2.2, 0.0, -18.0), PI, Vector3(0.2, 1.0, 1.0))
	_panels("Cornice_WornBrick_Center", Vector2(2.4, -18.0), Vector2(-1, 0), Vector2(0, -1), 0.0, 8.4, FLAT_H)
	_in("terrace")
	# The landing outside the flat at the top of the iron stairs.
	_slab(Vector3(1.575, -0.05, -18.725), Vector3(1.65, 0.1, 1.45), _mat("iron"))
	_solid(Vector3(1.7, -0.1, -18.725), Vector3(1.4, 0.2, 1.45))
	_beam(Vector3(2.37, 1.0, -19.45), Vector3(2.37, 1.0, -18.0), 0.05, 0.05, _mat("iron"))
	for zz in [-19.4, -18.7, -18.05]:
		_slab(Vector3(2.37, 0.5, zz), Vector3(0.04, 1.0, 0.04), _mat("iron"))
	_solid(Vector3(2.37, 0.5, -18.725), Vector3(0.06, 1.0, 1.45))
	# The table where the buyer leaves his case, a chair, planters, trees.
	_box("mae_terrace_table", Vector3(-0.8, 0.0, -19.65))
	_box("mae_terrace_chair", Vector3(-1.85, 0.0, -19.65), PI * 0.5)
	var case_node := Node3D.new()
	case_node.name = "GrayCase"
	case_node.visible = false
	_at.add_child(case_node)
	Kit.model(case_node, "mae_case", Vector3(-0.8, 0.74, -19.6), 0.1)
	_item_at("case", "rose", Vector3(-0.88, 0.79, -19.55), Vector3(0.2, 0.16, 0.2), "mae_rose")
	_item_at("copy_case", "copy", Vector3(-0.7, 0.79, -19.55), Vector3(0.2, 0.16, 0.2), "mae_rose")
	for z in [-20.6, -23.5]:
		_box("mae_planter", Vector3(-5.59, 0.0, z), PI * 0.5)
	_box("mae_pot_tree", Vector3(-5.4, 0.0, -18.6))
	_box("mae_pot_tree", Vector3(0.35, 0.0, -23.2))
	_m("mae_chimney", Vector3(-4.6, 6.0, -16.0))
	# String lights from the flat's wall out to the parapet, and a candle.
	_beam(Vector3(0.6, 0.0, -26.1), Vector3(0.6, 2.6, -26.1), 0.05, 0.05, _mat("iron"))
	_beam(Vector3(-5.6, 0.0, -26.1), Vector3(-5.6, 2.6, -26.1), 0.05, 0.05, _mat("iron"))
	_string(Vector3(-5.6, 2.55, -18.2), Vector3(0.6, 2.55, -26.1), 26, 0.35)
	_string(Vector3(0.6, 2.55, -18.2), Vector3(-5.6, 2.55, -26.1), 26, 0.35)
	_string(Vector3(-5.6, 2.55, -26.1), Vector3(0.6, 2.55, -26.1), 18, 0.25)
	_slab(Vector3(-0.4, 0.8, -19.75), Vector3(0.05, 0.1, 0.05), _mat("glow_warm"))
	_omni(Vector3(-2.5, 2.3, -22.0), WARM, 1.2, 8.0)
	_omni(Vector3(-0.6, 1.0, -19.7), CANDLE, 0.5, 3.0)
	_omni(Vector3(-2.5, 2.3, -19.0), WARM, 0.6, 5.0)
	# The fireworks over the city, shown when they go up.
	var fw := Node3D.new()
	fw.name = "Fireworks"
	fw.visible = false
	_at.add_child(fw)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2209
	var at := _at
	_at = fw
	for burst in [[Vector3(-14.0, 22.0, -70.0), "spark_gold"], [Vector3(6.0, 27.0, -80.0), "spark_rose"], [Vector3(-2.0, 18.0, -60.0), "spark_teal"]]:
		var c: Vector3 = burst[0]
		for i in 26:
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.4)).normalized()
			_beam(c + dir * 1.5, c + dir * rng.randf_range(4.0, 6.5), 0.12, 0.12, _mat(str(burst[1])))
	_omni(Vector3(-2.5, 6.0, -27.0), Color(1.0, 0.6, 0.7), 1.2, 14.0)
	_at = at
	_probe(Rect2(-5.8, -26.3, 8.2, 8.3), 4.0, Color(0.16, 0.15, 0.16), 0.25)


# --- The street ---------------------------------------------------------------------------------

func _street() -> void:
	_in("street")
	# Pavements, kerbs, the road.
	var x := -30.0
	while x < 31.0:
		_m("Sidewalk_NoCurb_3m", Vector3(x, 0.0, KERB * 0.5), 0.0, Vector3(1.0, 1.0, KERB / 3.0))
		_m("Sidewalk_NoCurb_3m", Vector3(x, 0.0, FAR_KERB + 1.5))
		x += 3.0
	for kz in [KERB - 0.12, FAR_KERB + 0.12]:
		_slab(Vector3(0.0, -0.07, kz), Vector3(64.0, 0.16, 0.24), _mat("kerb"))
	_slab(Vector3(0.0, -0.2, (KERB + FAR_KERB) * 0.5), Vector3(64.0, 0.1, FAR_KERB - KERB), _mat("asphalt"))
	x = -30.0
	while x < 31.0:
		_slab(Vector3(x + 1.5, -0.148, (KERB + FAR_KERB) * 0.5), Vector3(3.0, 0.006, 0.14), _mat("road_paint"))
		x += 7.0
	# Parked cars, the buyer's black one by Mae's door.
	var cars := [[-14.0, KERB + 1.05, PI * 0.5, Color(0.12, 0.2, 0.36)], [-8.2, KERB + 1.05, PI * 0.5, Color(0.36, 0.4, 0.3)],
			[10.6, KERB + 1.05, PI * 0.5, Color(0.8, 0.74, 0.6)], [-4.0, FAR_KERB - 1.05, -PI * 0.5, Color(0.5, 0.1, 0.08)],
			[14.0, FAR_KERB - 1.05, -PI * 0.5, Color(0.7, 0.72, 0.74)]]
	for c in cars:
		var car := _m("mae_car", Vector3(float(c[0]), -0.15, float(c[1])), float(c[2]))
		_tint(car, "car_paint", c[3])
		_solid(Vector3(float(c[0]), 0.5, float(c[1])), Vector3(4.5, 1.2, 1.7))
	var gray := Node3D.new()
	gray.name = "GrayCar"
	_at.add_child(gray)
	var black := Kit.model(gray, "mae_car", Vector3(3.4, -0.15, KERB + 1.05), PI * 0.5)
	_tint(black, "car_paint", Color(0.02, 0.02, 0.025))
	# Lamps, the bollard by the door, nobody leaves the block.
	for lx in [-22.0, -12.0, 8.0, 20.0]:
		_lamp(Vector3(lx, 0.0, KERB - 0.5), true)
	for lx in [-18.0, -2.0, 12.0, 26.0]:
		_lamp(Vector3(lx, 0.0, FAR_KERB + 0.5), absf(lx) < 15.0)
	_m("Prop_ManholeCover", Vector3(1.0, -0.148, 7.5))
	for ex in [-30.0, 30.0]:
		_solid(Vector3(ex, 3.0, ACROSS * 0.5), Vector3(0.4, 6.0, ACROSS + 2.0))
	_solid(Vector3(0.0, 3.0, ACROSS + 0.2), Vector3(64.0, 6.0, 0.4))
	# Strings of lights across the street for the party.
	for sx in [-8.0, -2.0, 4.0]:
		_string(Vector3(sx, 5.2, 0.15), Vector3(sx + 3.0, 5.6, ACROSS - 0.15), 30, 0.9)
	_string(Vector3(-6.0, 3.85, 0.2), Vector3(6.0, 3.85, 0.2), 24, 0.15)
	for p in [Vector3(-3.0, 4.0, 5.0), Vector3(3.0, 4.0, 8.0)]:
		_omni(p, WARM, 0.9, 8.0)
	# The laundrette's glow on the pavement.
	_omni(Vector3(0.0, 2.2, 1.0), Color(0.8, 0.9, 1.0), 0.6, 5.0)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
	_at.add_child(moon)
	_probe(Rect2(-30.0, 0.0, 60.0, 15.0), 16.0, Color(0.12, 0.13, 0.18), 0.25)


## Mae's front and the street's other buildings.
func _facades() -> void:
	_in("street")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1958
	# The shop: the door, four windows and a narrow one, the fascia with her name.
	var door := _m("DoorFrame_Trim", Vector3(-5.0, 0.0, 0.0))
	_override(door, "MI_InteriorWall", _mat("hidden"))
	_tint(door, "MI_Trim_Green", Color(0.1, 0.32, 0.28))
	for wx in [-3.0, -1.0, 1.0, 3.0, 5.0]:
		var shop := _m("Trim_FirstFloor_Window", Vector3(wx, 0.0, 0.0))
		_override(shop, "MI_FakeInterior", _mat("hidden"))
		_override(shop, "MI_InteriorWall", _mat("hidden"))
		_tint(shop, "MI_Trim_Green", Color(0.1, 0.32, 0.28))
	_slab(Vector3(0.0, 3.3, 0.06), Vector3(12.0, 0.6, 0.12), _mat("fascia"))
	_slab(Vector3(0.0, 3.62, 0.08), Vector3(12.1, 0.05, 0.18), _mat("cream"))
	_sign("MAE'S LAUNDRETTE", Vector3(0.0, 3.3, 0.125), 0.0, 96, Color(1.0, 0.9, 0.66), 0.004)
	_sign("SERVICE WASH  -  EST. 1979", Vector3(4.2, 3.1, 0.125), 0.0, 36, Color(0.9, 0.84, 0.66), 0.003)
	_m("Prop_Awning", Vector3(-5.0, 0.0, 0.0))
	# The flat over it: the study's and the kitchen's windows, rooms above.
	for p in [[-5.5, 0.5], [0.0, 1.0], [5.5, 0.5]]:
		_m("WornBrick_Plain_3", Vector3(float(p[0]), FLAT, 0.0), 0.0, Vector3(float(p[1]), 1.0, 1.0))
	for wx in [-3.0, 3.0]:
		var win := _m("WornBrick_WindowLarge", Vector3(wx, FLAT, 0.0))
		_override(win, "MI_FakeInterior", _mat("hidden"))
		_override(win, "MI_InteriorWall", _mat("hidden"))
	for wx in [-4.0, 0.0, 4.0]:
		var win := _m("WornBrick_WindowLarge", Vector3(wx, FLAT + 3.0, 0.0))
		_override(win, "MI_FakeInterior", _window_mat(0 if wx < 0.0 else 1, Color(1.0, 0.8, 0.6)))
	_panels("Cornice_WornBrick_Center", Vector2(-6.0, 0.0), Vector2(1, 0), Vector2(0, 1), 0.0, 12.0, FLAT + 6.0)
	_solid(Vector3(0.0, (FLAT + 9.6) * 0.5, -0.1), Vector3(12.0, 9.6 - FLAT, 0.2))
	# Next door west, a salon; east, flats over a deli; across, the bakery's row.
	_block(-30.0, -6.0, 0.0, false, 12.0, "red", rng)
	_block(6.0, 30.0, 0.0, false, 12.0, "double", rng)
	_block(-30.0, -8.0, ACROSS, true, 12.0, "inset", rng)
	_block(-8.0, 8.0, ACROSS, true, 9.0, "red", rng)
	_block(8.0, 30.0, ACROSS, true, 12.0, "white", rng)
	_m("Prop_Sign_Mays", Vector3(-9.0, 3.5, 0.02))
	_m("Prop_Sign_Deli", Vector3(10.0, 3.8, 0.02))
	_m("Prop_Awning_Bakery", Vector3(-3.0, 0.0, ACROSS), PI)
	_m("Prop_Awning_Bakery", Vector3(-5.9, 0.0, ACROSS), PI)
	_m("Prop_Sign_Bakery", Vector3(-4.4, 4.3, ACROSS - 0.02), PI)
	# The roof of Mae's house, seen from the terrace.
	_slab(Vector3(0.0, FLAT + 6.05, -9.0), Vector3(12.0, 0.1, 18.0), _mat("tar"))


# --- Doors --------------------------------------------------------------------------------------

func _doors() -> void:
	_make_doors(DOOR_SPECS)
	_in("back_room")
	_reveal(Vector2(2.0, -11.2), Vector2(0, 1), 0.95, 2.1, 0.4, _mat("walnut"))
	_in("living")
	_reveal(Vector2(-3.6, -9.0), Vector2(1, 0), 0.95, 2.1, 0.4, _mat("walnut"))
	_in("yard")
	_reveal(Vector2(4.0, -26.4), Vector2(1, 0), 1.2, 2.0, 0.22, _mat("coping"))


# --- Where people go ----------------------------------------------------------------------------

func _graph() -> void:
	var F := FLAT
	var P := {
		# The street.
		"crew_0": Vector3(-5.6, 0, 2.4), "crew_1": Vector3(-4.4, 0, 2.4), "front_out": Vector3(-5.0, 0, 1.1),
		"street_c": Vector3(-1.6, 0, 2.0), "mae_street": Vector3(0.4, 0, 2.0), "gray_car": Vector3(2.4, 0, 3.3),
		"rocco_car": Vector3(4.6, 0, 3.3), "street_e": Vector3(12.0, 0, 2.4), "gone": Vector3(26.0, 0, 2.4),
		# The laundrette.
		"front_in": Vector3(-5.0, 0, -1.2), "front_guard": Vector3(-4.3, 0, -1.9), "laund_w": Vector3(-4.3, 0, -3.1),
		"laund_c": Vector3(-1.4, 0, -3.1), "laund_e": Vector3(2.6, 0, -3.1), "walt": Vector3(2.8, 0, -1.6),
		"laund_ne": Vector3(3.5, 0, -7.4),
		# The back hall and the back room.
		"hall_s": Vector3(3.4, 0, -10.2), "stairs_foot": Vector3(5.15, 0, -9.8), "back_room_out": Vector3(3.1, 0, -11.2),
		"held_guard": Vector3(3.1, 0, -12.6), "hall_n": Vector3(3.3, 0, -16.9),
		"back_room_in": Vector3(0.9, 0, -11.2), "held": Vector3(-4.0, 0, -10.5),
		# The yard and the alley.
		"yard_out": Vector3(3.3, 0, -19.0), "yard_c": Vector3(3.6, 0, -22.6), "gate_in": Vector3(4.0, 0, -25.4),
		"stairs_low": Vector3(1.7, 0, -26.0), "alley_in": Vector3(4.0, 0, -28.1), "alley_w": Vector3(-4.0, 0, -28.2),
		"alley_e": Vector3(9.0, 0, -28.2),
		# The landing and the kitchen.
		"stairs_head": Vector3(5.15, F, -16.6), "landing_n": Vector3(3.4, F, -17.0), "landing_c": Vector3(3.4, F, -14.0),
		"landing_s": Vector3(3.4, F, -10.4), "kitchen_in": Vector3(3.4, F, -7.8), "kitchen_c": Vector3(2.6, F, -6.2),
		"kitchen_bar": Vector3(0.6, F, -7.2), "benny": Vector3(0.55, F, -5.4), "dot": Vector3(4.5, F, -3.9),
		"kitchen_s": Vector3(1.9, F, -2.8), "okafor": Vector3(1.4, F, -1.5), "kitchen_door_k": Vector3(1.0, F, -8.1),
		# The living room.
		"kitchen_door_l": Vector3(1.0, F, -10.0), "living_e": Vector3(1.0, F, -14.0), "living_c": Vector3(-1.4, F, -12.0),
		"living_mid": Vector3(-1.6, F, -14.6), "living_sw": Vector3(-3.6, F, -10.2), "living_nw": Vector3(-3.0, F, -16.6),
		"mae": Vector3(-3.2, F, -11.4), "julian": Vector3(-0.9, F, -12.6), "rocco": Vector3(0.9, F, -11.4),
		"dana": Vector3(-1.6, F, -10.3), "celeste": Vector3(-1.9, F, -15.6), "hugo": Vector3(-1.1, F, -15.4),
		"dj_w": Vector3(-1.1, F, -17.3), "jojo": Vector3(0.2, F, -17.3), "mae_dance": Vector3(-0.3, F, -14.9),
		# The study.
		"study_in": Vector3(-3.6, F, -8.0), "study_c": Vector3(-3.6, F, -4.4), "mae_desk": Vector3(-3.4, F, -1.65),
		"julian_study": Vector3(-2.4, F, -1.65), "rocco_study": Vector3(-4.3, F, -7.2), "safe_out": Vector3(-3.5, F, -7.1),
		"safe_in": Vector3(-1.6, F, -7.1),
		# The terrace.
		"terrace_in": Vector3(-3.0, F, -17.0), "terrace_out": Vector3(-3.0, F, -19.0), "terrace_e": Vector3(0.0, F, -18.7), "terrace_se": Vector3(0.5, F, -19.9),
		"platform": Vector3(1.7, F, -18.7), "iron_top": Vector3(1.7, F, -19.45), "terrace_c": Vector3(-2.6, F, -22.4),
		"terrace_n": Vector3(-2.6, F, -24.6), "silas": Vector3(-4.8, F, -21.6), "nadia": Vector3(-3.9, F, -21.9),
		"mae_toast": Vector3(-2.4, F, -20.3), "julian_toast": Vector3(-0.4, F, -20.8), "rocco_toast": Vector3(0.3, F, -21.6),
		"dot_toast": Vector3(-3.4, F, -21.6), "celeste_toast": Vector3(-2.8, F, -22.7), "hugo_toast": Vector3(-2.0, F, -22.8),
		"silas_fw": Vector3(-5.0, F, -25.6), "dot_fw": Vector3(-4.2, F, -25.6), "mae_fw": Vector3(-3.4, F, -25.6),
		"julian_fw": Vector3(-2.6, F, -25.6), "rocco_fw": Vector3(-1.8, F, -25.6), "celeste_fw": Vector3(-1.0, F, -25.6),
		"hugo_fw": Vector3(-0.2, F, -25.6), "nadia_fw": Vector3(0.4, F, -25.6),
	}
	points = P.duplicate()
	links = [
		["crew_0", "front_out", ""], ["crew_1", "front_out", ""], ["front_out", "street_c", ""], ["street_c", "mae_street", ""],
		["mae_street", "gray_car", ""], ["gray_car", "rocco_car", ""], ["rocco_car", "street_e", ""], ["street_e", "gone", ""],
		["front_out", "front_in", "front"], ["front_in", "front_guard", ""], ["front_in", "laund_w", ""], ["front_guard", "laund_w", ""],
		["laund_w", "laund_c", ""], ["laund_c", "laund_e", ""], ["laund_e", "walt", ""], ["laund_e", "laund_ne", ""],
		["laund_ne", "hall_s", ""], ["hall_s", "stairs_foot", ""], ["hall_s", "back_room_out", ""], ["back_room_out", "held_guard", ""],
		["held_guard", "hall_n", ""], ["back_room_out", "back_room_in", "back_room"], ["back_room_in", "held", ""],
		["hall_n", "yard_out", "yard"], ["yard_out", "yard_c", ""], ["yard_c", "gate_in", ""], ["gate_in", "stairs_low", ""],
		["gate_in", "alley_in", "gate"], ["alley_in", "alley_w", ""], ["alley_in", "alley_e", ""],
		["stairs_low", "iron_top", ""], ["iron_top", "platform", ""], ["platform", "terrace_e", ""],
		["stairs_foot", "stairs_head", ""], ["stairs_head", "landing_n", ""], ["landing_n", "landing_c", ""], ["landing_c", "landing_s", ""],
		["landing_s", "kitchen_in", ""], ["kitchen_in", "kitchen_c", ""], ["kitchen_c", "kitchen_bar", ""], ["kitchen_bar", "benny", ""],
		["kitchen_c", "dot", ""], ["kitchen_c", "kitchen_s", ""], ["kitchen_s", "okafor", ""], ["kitchen_bar", "kitchen_door_k", ""],
		["kitchen_door_k", "kitchen_door_l", ""], ["kitchen_door_l", "living_c", ""], ["landing_c", "living_e", ""],
		["living_e", "living_c", ""], ["living_e", "rocco", ""], ["living_e", "living_mid", ""], ["living_c", "julian", ""],
		["living_c", "dana", ""], ["living_c", "living_sw", ""], ["living_sw", "mae", ""], ["living_c", "mae", ""],
		["living_mid", "mae_dance", ""], ["living_mid", "hugo", ""], ["living_mid", "celeste", ""], ["celeste", "dj_w", ""],
		["dj_w", "jojo", ""], ["living_mid", "living_nw", ""], ["living_nw", "terrace_in", ""],
		["living_sw", "study_in", "study"], ["study_in", "rocco_study", ""], ["study_in", "study_c", ""], ["rocco_study", "safe_out", ""],
		["study_c", "safe_out", ""], ["safe_out", "safe_in", "safe"], ["study_c", "mae_desk", ""], ["study_c", "julian_study", ""],
		["mae_desk", "julian_study", ""],
		["terrace_in", "terrace_out", "terrace"], ["terrace_out", "terrace_e", ""], ["terrace_out", "terrace_c", ""],
		["terrace_out", "mae_toast", ""], ["terrace_e", "terrace_se", ""], ["terrace_se", "julian_toast", ""], ["terrace_se", "rocco_toast", ""], ["julian_toast", "rocco_toast", ""],
		["terrace_c", "dot_toast", ""], ["terrace_c", "celeste_toast", ""], ["terrace_c", "hugo_toast", ""], ["terrace_c", "silas", ""],
		["terrace_c", "nadia", ""], ["terrace_c", "terrace_n", ""], ["mae_toast", "terrace_c", ""], ["julian_toast", "terrace_c", ""],
		["terrace_n", "silas_fw", ""], ["terrace_n", "dot_fw", ""], ["terrace_n", "mae_fw", ""], ["terrace_n", "julian_fw", ""],
		["terrace_n", "rocco_fw", ""], ["terrace_n", "celeste_fw", ""], ["terrace_n", "hugo_fw", ""], ["terrace_n", "nadia_fw", ""],
	]
	var face := {
		"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "walt": Vector2(-0.3, 1), "front_guard": Vector2(-0.4, 1),
		"held": Vector2(0, -1), "held_guard": Vector2(-1, 0.6), "gray_car": Vector2(0, 1), "rocco_car": Vector2(0, 1),
		"mae_street": Vector2(1, 0.5), "gone": Vector2(1, 0),
		"dot": Vector2(-1, 0.2), "benny": Vector2(1, 0), "okafor": Vector2(1, -0.4),
		"mae": Vector2(1, -0.5), "julian": Vector2(-1, 0.5), "rocco": Vector2(-1, -0.4), "dana": Vector2(-1, -0.1),
		"celeste": Vector2(1, 0.3), "hugo": Vector2(-1, -0.1), "jojo": Vector2(0, 1), "mae_dance": Vector2(0.5, -1),
		"mae_desk": Vector2(0.2, 1), "julian_study": Vector2(-0.2, 1), "rocco_study": Vector2(0.4, 1), "safe_in": Vector2(1, 0),
		"silas": Vector2(1, -0.3), "nadia": Vector2(-1, 0.3),
		"mae_toast": Vector2(0, -1), "julian_toast": Vector2(-1, -0.3), "rocco_toast": Vector2(-1, 0.2), "dot_toast": Vector2(1, 0.5),
		"celeste_toast": Vector2(0.2, 1), "hugo_toast": Vector2(-0.1, 1),
	}
	for k in face:
		spots[k] = Transform3D(Basis(Vector3.UP, atan2(face[k].x, face[k].y)), P[k])
	for k in ["silas_fw", "dot_fw", "mae_fw", "julian_fw", "rocco_fw", "celeste_fw", "hugo_fw", "nadia_fw"]:
		spots[k] = Transform3D(Basis(Vector3.UP, PI), P[k])
	# The crowd: dancing, talking by the records, in the kitchen, on the
	# terrace, a couple downstairs and two smoking outside.
	extras["living"] = [_at3(0.1, F, -14.0, Vector2(0.3, -1)), _at3(0.9, F, -14.6, Vector2(-1, 0.2)), _at3(0.5, F, -15.4, Vector2(-0.2, 1)),
			_at3(-2.4, F, -10.5, Vector2(1, 0.1)), _at3(-1.9, F, -13.2, Vector2(1, 0.3)), _at3(-1.2, F, -13.6, Vector2(-1, 0.2))] as Array[Transform3D]
	extras["kitchen"] = [_at3(2.6, F, -1.6, Vector2(1, 0.2)), _at3(3.6, F, -1.1, Vector2(-0.4, -0.4)), _at3(3.8, F, -1.9, Vector2(-0.6, 0.4)),
			_at3(4.2, F, -5.8, Vector2(-0.6, -1)), _at3(4.0, F, -6.8, Vector2(0.3, 1))] as Array[Transform3D]
	extras["terrace"] = [_at3(0.0, F, -22.4, Vector2(-1, 0)), _at3(-0.7, F, -22.9, Vector2(1, 0.3))] as Array[Transform3D]
	extras["laundrette"] = [_at3(1.0, 0.0, -2.0, Vector2(1, 0)), _at3(1.8, 0.0, -2.1, Vector2(-1, 0))] as Array[Transform3D]
	extras["street"] = [_at3(-8.6, 0.0, 1.4, Vector2(1, 0.2)), _at3(-7.8, 0.0, 1.6, Vector2(-1, 0)), _at3(7.6, 0.0, 2.2, Vector2(1, -0.2)), _at3(8.3, 0.0, 1.8, Vector2(-1, 0.3))] as Array[Transform3D]


static func _at3(x: float, y: float, z: float, dir: Vector2) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), Vector3(x, y, z))


func _views() -> void:
	var F := FLAT
	_set_views({
		"street": [Vector3(4.0, 1.7, 10.0), Vector3(-1.0, 3.8, 0.0)],
		"front_door": [Vector3(-5.0, 1.65, 4.6), Vector3(-5.0, 1.4, -4.0)],
		"laundrette": [Vector3(5.0, 2.1, -0.9), Vector3(-3.0, 1.0, -6.0)],
		"back_hall": [Vector3(2.7, 1.7, -9.7), Vector3(4.8, 2.4, -16.5)],
		"back_room": [Vector3(1.2, 1.8, -9.8), Vector3(-3.5, 0.9, -15.0)],
		"landing": [Vector3(2.6, F + 1.7, -9.8), Vector3(4.6, F + 0.6, -16.6)],
		"living": [Vector3(1.4, F + 1.9, -9.8), Vector3(-4.2, F + 1.0, -15.4)],
		"dance": [Vector3(-4.4, F + 1.7, -11.0), Vector3(0.6, F + 1.1, -16.4)],
		"kitchen": [Vector3(0.7, F + 1.8, -8.3), Vector3(4.6, F + 0.9, -2.4)],
		"study": [Vector3(-4.8, F + 1.75, -8.3), Vector3(-2.4, F + 0.8, -0.8)],
		"strongroom": [Vector3(-3.7, F + 1.7, -6.2), Vector3(-0.5, F + 0.9, -7.2)],
		"terrace": [Vector3(0.2, F + 1.8, -18.5), Vector3(-3.4, F + 0.8, -25.6)],
		"yard": [Vector3(5.3, 1.8, -18.6), Vector3(2.0, 1.5, -26.0)],
		"alley": [Vector3(10.4, 1.7, -28.2), Vector3(0.0, 1.6, -27.0)],
	})
	view_about = {
		"street": "The street at night: Mae's laundrette and her flat over it, strings of lights, the buyer's black car",
		"front_door": "The laundrette's door from the pavement, where the crew starts",
		"laundrette": "The laundrette: washers and dryers, the folding tables, Mae's counter, the bell over the door",
		"back_hall": "The back hall behind the shop: the stairs up to the flat, the back room's door, the yard door",
		"back_room": "Mae's back room, where she briefs the crew: the table, the plans on the wall, the kettle",
		"landing": "The landing at the top of the stairs, the kitchen's door and the arch into the living room",
		"living": "The living room: the fire, the big old sofa, the records, the party",
		"dance": "The dance floor, Jojo's decks and the speakers",
		"kitchen": "The kitchen everyone stands in: Benny's drinks, Dot at the cooker, the table",
		"study": "Mae's study: her desk under the window, the files, the strongroom door and its dial",
		"strongroom": "Inside the strongroom: the shelves, and the Rose on its plinth",
		"terrace": "The roof terrace: the table where the buyer leaves his case, the lights, the parapet",
		"yard": "The yard: the bins, the washing line, the iron stairs, the gate onto the alley",
		"alley": "The alley behind the house, Mae's gate in the wall",
	}
