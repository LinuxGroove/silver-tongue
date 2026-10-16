class_name Tideline
extends Venue
## The Tideline, the casino on Caldera's waterfront where the Rose's buyer
## has put it in the vault for a month: the street front with its neon and
## its doormen, the casino floor (blackjack, two roulette wheels, craps,
## banks of slots, the pit boss's podium, the bar), the lounge and its
## singer, the high-limit room, the cage behind its windows and the vault
## behind the cage, and the back of the house off the staff door: the count
## room, the surveillance room (the eye in the sky), the security office and
## the staff room, with the back door onto the alley. Built in code from the
## Downtown City kit, the hotel's props and the casino's own
## (`tools/blender/tideline_props.py`). X runs east and Z south, the floor is
## y = 0, the front is z = 0 and the water is south, across the road.
##
## Casino light is low and warm over the tables and coloured round the
## slots; every room lights only itself, as every [Venue]'s do.

## The rooms, and outside. [method zone_at] checks them in [constant ZONE_ORDER].
const ZONES := {
	"floor": AABB(Vector3(-18.0, -1.0, -26.0), Vector3(28.0, 13.0, 26.0)),
	"lounge": AABB(Vector3(10.0, -1.0, -6.0), Vector3(16.0, 13.0, 6.0)),
	# The ring of tables' middle, where the dealers and the pit boss stand.
	"pit": AABB(Vector3(-10.5, -1.0, -18.3), Vector3(16.0, 13.0, 5.6)),
	"high_limit": AABB(Vector3(-18.0, -1.0, -38.0), Vector3(14.0, 13.0, 12.0)),
	# Behind the baccarat table, for its dealer.
	"hl_table": AABB(Vector3(-12.2, -1.0, -33.9), Vector3(2.4, 13.0, 0.85)),
	"cage": AABB(Vector3(10.0, -1.0, -14.0), Vector3(6.0, 13.0, 8.0)),
	"vault": AABB(Vector3(16.0, -1.0, -14.0), Vector3(5.0, 13.0, 8.0)),
	"staff_room": AABB(Vector3(21.0, -1.0, -14.0), Vector3(5.0, 13.0, 8.0)),
	"corridor": AABB(Vector3(10.0, -1.0, -18.0), Vector3(16.0, 13.0, 4.0)),
	"count_room": AABB(Vector3(10.0, -1.0, -26.0), Vector3(7.0, 13.0, 8.0)),
	"eye": AABB(Vector3(17.0, -1.0, -26.0), Vector3(5.0, 13.0, 8.0)),
	"office": AABB(Vector3(22.0, -1.0, -26.0), Vector3(4.0, 13.0, 8.0)),
	# The second doorman's post, under the canopy.
	"doorway": AABB(Vector3(-2.6, -1.0, 0.6), Vector3(1.2, 13.0, 1.2)),
	"outside": AABB(Vector3(-45.0, -1.0, -27.0), Vector3(90.0, 31.0, 59.0)),
}
const ZONE_ORDER: Array[String] = ["vault", "cage", "staff_room", "count_room", "eye", "office", "corridor",
		"hl_table", "high_limit", "pit", "lounge", "floor", "doorway", "outside"]
## Each zone's render layer: the floor, the pit and the lounge are one open room.
const LAYERS := {
	"floor": 2, "pit": 2, "lounge": 2, "high_limit": 3, "hl_table": 3, "cage": 4, "vault": 5,
	"corridor": 6, "count_room": 7, "eye": 8, "office": 9, "staff_room": 10, "outside": 11, "doorway": 11,
}

## Ceiling heights.
const FLOOR_H := 4.6
const LOUNGE_H := 3.8
const HL_H := 4.2
const BACK_H := 3.2
const VAULT_H := 3.0
## The street: pavement from the front (z = 0) to the kerb, the road, the
## boardwalk and its railing, then the harbour.
const KERB := 6.0
const FAR_KERB := 13.0
const RAIL := 18.0
## The cage's three windows onto the floor, along x = 10 (Bea's, closed, Imani's).
const WINDOWS := [-12.6, -10.0, -7.4]
## The tables: [model, centre, turned to face north].
const TABLES := [
	["tideline_blackjack", Vector2(-9.0, -12.0), false], ["tideline_blackjack", Vector2(-3.0, -12.0), false],
	["tideline_blackjack", Vector2(3.0, -12.0), false], ["tideline_roulette", Vector2(-8.5, -19.0), true],
	["tideline_roulette", Vector2(-3.0, -19.0), true], ["tideline_craps", Vector2(3.2, -19.0), true],
]

## The doors: the middle of the doorway on the floor (x, z), its size, the way
## it opens when nobody's given, and the leaf's model.
const DOOR_SPECS := {
	"front": {"at": Vector2(-4.0, -0.25), "w": 2.4, "h": 2.8, "double": true, "to": Vector2(0, -1), "model": "door_glass", "auto": true, "thick": 0.06},
	"high_limit": {"at": Vector2(-11.0, -26.0), "w": 2.0, "h": 2.6, "double": true, "to": Vector2(0, -1), "model": "door_grand"},
	"staff": {"at": Vector2(10.0, -16.0), "w": 1.1, "h": 2.2, "to": Vector2(1, 0), "model": "door_wood"},
	"cage": {"at": Vector2(12.0, -14.0), "w": 1.0, "h": 2.2, "to": Vector2(0, 1), "model": "tideline_cage_door", "thick": 0.1},
	"vault": {"at": Vector2(16.05, -10.0), "w": 2.2, "h": 2.2, "to": Vector2(1, 0), "model": "tideline_vault_door", "thick": 0.3},
	"count_room": {"at": Vector2(13.5, -18.0), "w": 1.1, "h": 2.2, "to": Vector2(0, -1), "model": "door_steel", "thick": 0.1},
	"eye": {"at": Vector2(19.5, -18.0), "w": 1.1, "h": 2.2, "to": Vector2(0, -1), "model": "door_steel", "thick": 0.1},
	"office": {"at": Vector2(24.0, -18.0), "w": 1.1, "h": 2.2, "to": Vector2(0, -1), "model": "door_wood"},
	"staff_room": {"at": Vector2(23.5, -14.0), "w": 1.1, "h": 2.2, "to": Vector2(0, 1), "model": "door_wood"},
	"back": {"at": Vector2(26.0, -16.0), "w": 1.1, "h": 2.2, "to": Vector2(-1, 0), "model": "door_steel", "thick": 0.1},
}

const PINK := Color(1.0, 0.36, 0.72)
const CYAN := Color(0.36, 0.9, 1.0)
const GOLD := Color(1.0, 0.78, 0.42)


func _init() -> void:
	zones = ZONES
	zone_order = ZONE_ORDER
	room_layers = LAYERS


## The doors are HotelDoors by name (front, high_limit, staff, cage, vault,
## count_room, eye, office, staff_room, back). The uses: "count_pad" (the
## count room's keypad), "back_pad" (the back door's, in the alley),
## "cam_panel" (the cameras' junction box in the alley), "count_desk" (where
## the count sheet lies), "vault_table" (where the Rose lies), "cage_window"
## (the closed middle window, for handing things through) and "request"
## (the stage, for asking the singer for a song).
func _build() -> void:
	_make_rooms(["floor", "high_limit", "cage", "vault", "corridor", "count_room", "eye", "office", "staff_room", "outside"])
	_ground()
	_casino_floor()
	_tables()
	_slots()
	_bar()
	_lounge()
	_high_limit()
	_cage()
	_vault()
	_corridor()
	_count_room()
	_eye()
	_office()
	_staff_room()
	_street()
	_facade()
	_alley()
	_waterfront()
	_doors()
	_graph()
	_views()
	_apply_layers()
	_dress(self)
	set_clock(23 * 60)


# --- Materials and wall styles ----------------------------------------------------------------

func _more_mat(name: String, m: StandardMaterial3D) -> bool:
	match name:
		"carpet_casino":
			_tex(m, "res://assets/textures/tideline/carpet_casino", 2.0)
			m.roughness = 0.96
		"damask_wine":
			_tex(m, "res://assets/textures/tideline/damask_wine", 1.0)
			m.roughness = 0.7
			m.metallic_specular = 0.35
		"damask_green":
			_tex(m, "res://assets/textures/tideline/damask_green", 1.0)
			m.roughness = 0.7
			m.metallic_specular = 0.35
		"planks":
			_tex(m, "res://assets/textures/tideline/planks", 2.4)
			m.roughness = 0.8
		"ceiling_casino":
			m.albedo_color = Color(0.06, 0.045, 0.05)
			m.roughness = 0.9
		"cove":
			m.albedo_color = Color(1.0, 0.7, 0.4)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.62, 0.32)
			m.emission_energy_multiplier = 2.2
		"downlight":
			m.albedo_color = Color(1.0, 0.9, 0.75)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.82, 0.6)
			m.emission_energy_multiplier = 4.0
		"neon_pink", "neon_cyan":
			var c := PINK if name == "neon_pink" else CYAN
			m.albedo_color = c
			m.emission_enabled = true
			m.emission = c
			m.emission_energy_multiplier = 5.0
		"back_low":
			m.albedo_color = Color(0.46, 0.48, 0.47)
			m.roughness = 0.6
		"back_high":
			m.albedo_color = Color(0.78, 0.77, 0.72)
			m.roughness = 0.9
		"eye_wall":
			m.albedo_color = Color(0.13, 0.14, 0.16)
			m.roughness = 0.85
		"vault_wall":
			m.albedo_color = Color(0.46, 0.48, 0.5)
			m.metallic = 0.85
			m.roughness = 0.42
		"vault_seam":
			m.albedo_color = Color(0.1, 0.1, 0.11)
			m.metallic = 0.6
			m.roughness = 0.5
		"vault_floor":
			m.albedo_color = Color(0.22, 0.23, 0.24)
			m.metallic = 0.7
			m.roughness = 0.5
		"water":
			m.albedo_color = Color(0.01, 0.025, 0.04)
			m.metallic = 0.75
			m.roughness = 0.06
		"seawall":
			m.albedo_color = Color(0.2, 0.2, 0.19)
			m.roughness = 0.9
		"hull_glow":
			m.albedo_color = Color(1.0, 0.86, 0.6)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.5)
			m.emission_energy_multiplier = 2.5
		_:
			return false
	return true


## "casino" (walnut dado, brass rail, wine damask), "salon" (the same in green
## damask, for the high-limit room), "back" (painted, back of the house),
## "eye" (dark, for the surveillance room), "vault" (steel plate) and
## "facade" (black marble with brass fins).
func _more_span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, h: float) -> void:
	match style:
		"casino", "salon":
			var silk := _mat("damask_wine" if style == "casino" else "damask_green")
			if y0 < 0.14:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.14), _mat("black_marble"), 0.05)
			_face(a, u, facing, s0, s1, maxf(y0, 0.14), minf(y1, 1.0), _mat("walnut"), 0.035)
			if y1 >= 1.06 and y0 <= 1.0:
				_face(a, u, facing, s0, s1, 1.0, 1.06, _mat("brass"), 0.05)
			var top := h - 0.5
			_face(a, u, facing, s0, s1, maxf(y0, 1.06), minf(y1, top), silk, 0.015)
			if y1 > top:
				_face(a, u, facing, s0, s1, maxf(y0, top), y1, _mat("walnut"), 0.03)
		"back", "eye":
			var low := _mat("back_low" if style == "back" else "eye_wall")
			var high := _mat("back_high" if style == "back" else "eye_wall")
			if y0 < 0.1:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.1), _mat("bronze"), 0.025)
			_face(a, u, facing, s0, s1, maxf(y0, 0.1), minf(y1, 1.1), low, 0.015)
			_face(a, u, facing, s0, s1, maxf(y0, 1.1), y1, high, 0.015)
		"vault":
			_face(a, u, facing, s0, s1, y0, y1, _mat("vault_wall"), 0.03)
			var s := ceilf(s0 / 1.2) * 1.2
			while s < s1 - 0.05:
				_face(a, u, facing, s - 0.01, s + 0.01, y0, y1, _mat("vault_seam"), 0.04)
				s += 1.2
		"facade":
			_face(a, u, facing, s0, s1, y0, y1, _mat("black_marble"), 0.06)
			var s := ceilf(s0 / 2.0) * 2.0
			while s < s1 - 0.05:
				_face(a, u, facing, s - 0.04, s + 0.04, maxf(y0, 3.6), y1, _mat("brass"), 0.12)
				s += 2.0


func _more_wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	match style:
		"casino", "salon":
			_face(a, u, facing, 0.0, length, h - 0.52, h - 0.46, _mat("gilt"), 0.06)
			_face(a, u, facing, 0.0, length, h - 0.12, h, _mat("gilt"), 0.05)
		"back", "eye":
			_face(a, u, facing, 0.0, length, h - 0.08, h, _mat("plaster_white"), 0.03)
		"facade":
			_face(a, u, facing, 0.0, length, 3.5, 3.62, _mat("gilt"), 0.16)
			_face(a, u, facing, 0.0, length, h - 0.3, h, _mat("gilt"), 0.2)


## The slots' art and the eye's screens glow from their own pictures.
func _dress(n: Node) -> void:
	_glow(n)
	super._dress(n)


func _glow(n: Node) -> void:
	if n is MeshInstance3D and n.mesh:
		for i in n.mesh.get_surface_count():
			var m := n.mesh.surface_get_material(i) as StandardMaterial3D
			if m == null or m.has_meta("glow") or not m.resource_name in ["slot_art", "feed"]:
				continue
			m.set_meta("glow", true)
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission = Color.WHITE
			# Multiplied, so the picture glows rather than washing out to white.
			m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			m.emission_energy_multiplier = 1.8 if m.resource_name == "slot_art" else 1.4
	for c in n.get_children():
		_glow(c)


# --- The ground under it all ------------------------------------------------------------------

func _ground() -> void:
	_in("outside")
	# Everything stands on y = 0 but the road, a kerb's height lower.
	_solid(Vector3(0.0, -0.25, (-40.0 + KERB) * 0.5), Vector3(90.0, 0.5, KERB + 40.0))
	_solid(Vector3(0.0, -0.4, (KERB + FAR_KERB) * 0.5), Vector3(90.0, 0.5, FAR_KERB - KERB))
	_solid(Vector3(0.0, -0.25, (FAR_KERB + RAIL) * 0.5 + 0.5), Vector3(90.0, 0.5, RAIL - FAR_KERB + 1.0))
	# Under the building, so no gap between rooms' floors shows the sky.
	_slab(Vector3(4.0, -0.12, -19.0), Vector3(46.0, 0.1, 40.0), Kit.flat(Color(0.04, 0.035, 0.035)))


# --- The casino floor -------------------------------------------------------------------------

func _casino_floor() -> void:
	_in("floor")
	var r := Rect2(-17.8, -25.8, 27.6, 25.3)
	_floor(r, "carpet_casino")
	_floor(Rect2(9.8, -5.8, 16.0, 5.3), "carpet_casino")
	# Black marble inside the doors, edged in brass.
	_floor(Rect2(-6.4, -3.2, 4.8, 2.7), "black_marble", 0.004, 0.02)
	for x in [-6.4, -1.6]:
		_slab(Vector3(x, 0.01, -1.85), Vector3(0.04, 0.02, 2.7), _mat("brass"))
	_slab(Vector3(-4.0, 0.01, -3.2), Vector3(4.84, 0.02, 0.04), _mat("brass"))
	# The pit's edge, a brass line in the carpet.
	var pit := Rect2(-10.5, -18.3, 16.0, 5.6)
	for z in [pit.position.y, pit.end.y]:
		_slab(Vector3(pit.get_center().x, 0.006, z), Vector3(pit.size.x, 0.012, 0.05), _mat("brass"))
	for x in [pit.position.x, pit.end.x]:
		_slab(Vector3(x, 0.006, pit.get_center().y), Vector3(0.05, 0.012, pit.size.y), _mat("brass"))
	var windows := []
	for z in WINDOWS:
		windows.append({"at": z, "w": 1.8, "h": 2.6})
	_wall("casino", Vector2(-17.8, -0.5), Vector2(-17.8, -25.8), Vector2(1, 0), FLOOR_H)
	_wall("casino", Vector2(-17.8, -25.8), Vector2(9.8, -25.8), Vector2(0, 1), FLOOR_H, [{"at": -11.0, "w": 2.0, "h": 2.6}])
	_wall("casino", Vector2(9.8, -25.8), Vector2(9.8, -5.8), Vector2(-1, 0), FLOOR_H, [{"at": -16.0, "w": 1.1, "h": 2.2}] + windows)
	_wall("casino", Vector2(9.8, -5.8), Vector2(25.8, -5.8), Vector2(0, 1), LOUNGE_H)
	_wall("casino", Vector2(25.8, -5.8), Vector2(25.8, -0.5), Vector2(-1, 0), LOUNGE_H)
	_wall("casino", Vector2(25.8, -0.5), Vector2(-17.8, -0.5), Vector2(0, -1), FLOOR_H, [{"at": -4.0, "w": 2.4, "h": 3.12}])
	_ceiling(r, FLOOR_H, "ceiling_casino")
	_ceiling(Rect2(9.8, -5.8, 16.0, 5.3), LOUNGE_H, "ceiling_casino")
	# Over the lounge's opening, a bulkhead down to its lower ceiling.
	_slab(Vector3(10.0, (LOUNGE_H + FLOOR_H) * 0.5, -3.15), Vector3(0.4, FLOOR_H - LOUNGE_H, 5.3), _mat("walnut"))
	_slab(Vector3(10.0, LOUNGE_H - 0.03, -3.15), Vector3(0.44, 0.06, 5.3), _mat("gilt"))
	# The cage's windows: counters, bars and glass you talk through but can't
	# climb through (it stops bodies, not sight or sound).
	for z in WINDOWS:
		_m("tideline_cage_window", Vector3(10.0, 0.0, z), -PI * 0.5)
		_solid(Vector3(10.0, 0.55, z), Vector3(0.4, 1.1, 1.8))
		_solid(Vector3(10.0, 2.4, z), Vector3(0.4, 0.4, 1.8))
		Kit.block(_at, Vector3(10.0, 1.65, z), Vector3(0.4, 1.1, 1.8), Kit.LAYER_PEOPLE)
	_sign("CASHIER", Vector3(9.76, 3.3, -10.0), -PI * 0.5, 72, GOLD * 1.3)
	_sign("WINDOW\nCLOSED", Vector3(9.79, 1.6, -10.0), -PI * 0.5, 22, Color(0.9, 0.85, 0.75), 0.003)
	# A coffer over the pit, its cove lit.
	var cof := pit.grow(0.6)
	for e in [Rect2(cof.position.x, cof.position.y, cof.size.x, 0.3), Rect2(cof.position.x, cof.end.y - 0.3, cof.size.x, 0.3),
			Rect2(cof.position.x, cof.position.y, 0.3, cof.size.y), Rect2(cof.end.x - 0.3, cof.position.y, 0.3, cof.size.y)]:
		_slab(Vector3(e.get_center().x, FLOOR_H - 0.25, e.get_center().y), Vector3(e.size.x, 0.5, e.size.y), _mat("ceiling_casino"))
	var inner := cof.grow(-0.32)
	for e in [Rect2(inner.position.x, inner.position.y, inner.size.x, 0.04), Rect2(inner.position.x, inner.end.y - 0.04, inner.size.x, 0.04),
			Rect2(inner.position.x, inner.position.y, 0.04, inner.size.y), Rect2(inner.end.x - 0.04, inner.position.y, 0.04, inner.size.y)]:
		_slab(Vector3(e.get_center().x, FLOOR_H - 0.48, e.get_center().y), Vector3(e.size.x, 0.04, e.size.y), _mat("cove"))
	for e in [Rect2(cof.position.x, cof.position.y, cof.size.x, 0.05), Rect2(cof.position.x, cof.end.y - 0.05, cof.size.x, 0.05)]:
		_slab(Vector3(e.get_center().x, FLOOR_H - 0.52, e.get_center().y), Vector3(e.size.x, 0.05, e.size.y), _mat("gilt"))
	# Downlights across the ceiling, and the cameras' domes.
	var x := -15.0
	while x < 9.0:
		var z := -2.5
		while z > -25.0:
			if not cof.has_point(Vector2(x, z)):
				_slab(Vector3(x, FLOOR_H - 0.01, z), Vector3(0.2, 0.02, 0.2), _mat("downlight"))
			z -= 4.0
		x += 4.0
	for p in [Vector2(-12.0, -6.0), Vector2(-3.0, -15.5), Vector2(3.0, -6.0), Vector2(-12.0, -20.0), Vector2(6.0, -22.0), Vector2(8.6, -10.0)]:
		_m("tideline_dome_camera", Vector3(p.x, FLOOR_H - 0.12, p.y))
	# Brass stanchions and ropes inside the doors, and palms.
	for side in [-1.0, 1.0]:
		var px: float = -4.0 + side * 2.6
		_m("rope_post", Vector3(px, 0.0, -1.2))
		_m("rope_post", Vector3(px, 0.0, -3.0))
		_m("rope", Vector3(px, 0.0, -2.1), PI * 0.5, Vector3(1.125, 1.0, 1.0))
		_solid(Vector3(px, 0.5, -2.1), Vector3(0.36, 1.0, 2.2))
		_m("potted_palm", Vector3(-4.0 + side * 3.6, 0.0, -1.2))
		_solid(Vector3(-4.0 + side * 3.6, 0.45, -1.2), Vector3(0.6, 0.9, 0.6))
	# The high-limit room's doors: a surround, a sign, ropes.
	_m("door_surround", Vector3(-11.0, 0.0, -25.8), 0.0, Vector3(2.0 / 2.4, 2.6 / 3.0, 1.0))
	_sign("HIGH LIMIT", Vector3(-11.0, 3.42, -25.72), 0.0, 52, GOLD * 1.2)
	for px in [-13.0, -9.0]:
		_m("rope_post", Vector3(px, 0.0, -24.9))
		_solid(Vector3(px, 0.5, -24.9), Vector3(0.36, 1.0, 0.36))
	# The staff door: its frame, a sign.
	_m("doorframe_walnut", Vector3(9.8, 0.0, -16.0), -PI * 0.5)
	_sign("STAFF ONLY", Vector3(9.76, 2.62, -16.0), -PI * 0.5, 34)
	# Sconces between the bays.
	for z in [-3.0, -8.5, -19.0, -23.5]:
		_m("wall_sconce", Vector3(-17.8, 2.2, z), PI * 0.5)
	for xx in [-15.5, -6.5, 1.0, 7.5]:
		_m("wall_sconce", Vector3(xx, 2.2, -25.8))
	# Light: a low warm wash; the tables and slots light themselves (below).
	for p in [Vector3(-12.5, 3.9, -4.0), Vector3(1.5, 3.9, -4.0), Vector3(-13.0, 3.9, -21.5), Vector3(4.0, 3.9, -23.0), Vector3(7.5, 3.6, -13.5)]:
		_omni(p, WARM, 0.55, 10.0)
	_omni(Vector3(-2.4, 4.0, -15.5), Color(1.0, 0.7, 0.42), 0.8, 8.0)
	# Inside the front doors, and the cage's windows.
	_omni(Vector3(-4.0, 3.8, -4.5), WARM, 0.6, 7.0)
	_omni(Vector3(8.2, 3.3, -10.0), WARM, 0.7, 5.5)
	_probe(r, FLOOR_H, Color(0.4, 0.27, 0.22), 0.3)


## Each table under its own light, its dealer behind it, and the pit boss's
## podium in the middle of the pit.
func _tables() -> void:
	_in("floor")
	for t in TABLES:
		var c: Vector2 = t[1]
		_box(str(t[0]), _v(c), PI if bool(t[2]) else 0.0)
		var lamp := _m("tideline_table_light", Vector3(c.x, 2.3, c.y), PI * 0.5 if str(t[0]) == "tideline_craps" else 0.0)
		_no_shadow(lamp)
		_slab(Vector3(c.x, (3.2 + FLOOR_H) * 0.5, c.y), Vector3(0.03, FLOOR_H - 3.2, 0.03), _mat("bronze"))
		_spot(Vector3(c.x, 2.35, c.y), Vector3(c.x, 0.8, c.y), CANDLE, 7.0, 4.0, 58.0)
	# The pit boss's podium, looking at wheel two.
	_box("tideline_podium", Vector3(-3.0, 0.0, -16.3), PI)
	_m("desk_lamp", Vector3(-3.25, 1.12, -16.42), PI)
	_omni(Vector3(-3.0, 1.5, -16.0), CANDLE, 0.35, 2.4)


## Banks of slots: islands of two back to back, and banks along the walls,
## each with its stools and its coloured glow.
func _slots() -> void:
	_in("floor")
	var k := 0
	for c in [Vector2(-11.5, -3.8), Vector2(-11.5, -7.8), Vector2(3.5, -3.8), Vector2(3.5, -7.8)]:
		_bank(c + Vector2(0, 0.36), Vector2(0, 1))
		_bank(c - Vector2(0, 0.36), Vector2(0, -1))
		_solid(Vector3(c.x, 1.15, c.y), Vector3(2.8, 2.3, 1.58))
		_omni(Vector3(c.x, 2.7, c.y), PINK if k % 2 == 0 else CYAN, 1.0, 4.2)
		k += 1
	# Along the west wall, the north wall and the east wall.
	for z in [-2.2, -5.2]:
		_bank(Vector2(-17.44, z), Vector2(1, 0))
	_solid(Vector3(-17.4, 1.15, -3.7), Vector3(0.8, 2.3, 5.6))
	_omni(Vector3(-16.6, 2.5, -3.7), CYAN, 0.9, 4.0)
	for x in [-15.4, -1.0, 2.0, 5.0]:
		_bank(Vector2(x, -25.44), Vector2(0, 1))
		_solid(Vector3(x, 1.15, -25.4), Vector3(2.8, 2.3, 0.8))
	_omni(Vector3(-15.4, 2.5, -24.6), PINK, 0.8, 4.0)
	_omni(Vector3(2.0, 2.5, -24.6), GOLD, 1.0, 5.0)
	_bank(Vector2(9.44, -22.5), Vector2(-1, 0))
	_solid(Vector3(9.4, 1.15, -22.5), Vector3(0.8, 2.3, 2.8))
	_omni(Vector3(8.6, 2.5, -22.5), PINK, 0.8, 4.0)


## A bank of four machines with its back at `at`, facing `facing`, and a
## stool in front of each.
func _bank(at: Vector2, facing: Vector2) -> void:
	var yaw := atan2(facing.x, facing.y)
	_m("tideline_slots", _v(at), yaw)
	var along := Vector2(facing.y, -facing.x)
	for i in 4:
		var p := at + along * (-1.05 + i * 0.7) + facing * 0.82
		_m("tideline_slot_stool", _v(p), yaw)
		_solid(_v(p, 0.4), Vector3(0.4, 0.8, 0.4))


## The bar on the west wall: the counter faces east, the back bar behind.
func _bar() -> void:
	_in("floor")
	_box("bar_counter", Vector3(-16.0, 0.0, -13.0), PI * 0.5)
	_box("back_bar", Vector3(-17.5, 0.0, -13.0), PI * 0.5)
	for z in [-15.0, -14.0, -11.6, -10.6]:
		_box("bar_stool", Vector3(-15.05, 0.0, z))
	for z in [-15.0, -13.0, -11.0]:
		_pendant(-15.9, z, 2.45, FLOOR_H)
	_omni(Vector3(-15.6, 2.2, -13.0), WARM, 1.1, 5.0)
	_omni(Vector3(-17.0, 1.9, -13.0), CANDLE, 0.7, 3.0)
	_sign("THE TIDE BAR", Vector3(-17.76, 3.4, -13.0), PI * 0.5, 56, CYAN * 1.4)


## The lounge at the east end: banquettes, cocktail tables, the stage and
## Marisol's microphone, lit pink.
func _lounge() -> void:
	_in("floor")
	_m("tideline_stage", Vector3(23.6, 0.0, -3.2), -PI * 0.5)
	_solid(Vector3(23.6, 0.11, -3.2), Vector3(3.4, 0.22, 3.4))
	_m("tideline_mic", Vector3(23.3, 0.22, -2.5), -PI * 0.5)
	_m("tideline_neon_wave", Vector3(25.8, 2.4, -3.2), -PI * 0.5, Vector3(0.7, 0.7, 1.0))
	for x in [12.5, 15.5, 18.5]:
		_m("tideline_banquette", Vector3(x, 0.0, -5.3))
		_solid(Vector3(x, 0.5, -5.5), Vector3(2.5, 1.0, 0.6))
		_box("tideline_cocktail_table", Vector3(x, 0.0, -4.35))
		_omni(Vector3(x, 1.1, -4.35), CANDLE, 0.4, 2.6)
	# Asking for a song: the stage's edge.
	_use("request", Vector3(22.3, 0.0, -1.8), Vector3(0.5, 0.5, 0.5))
	# The stage's light (the lounge's shadow), and a wash.
	_spot(Vector3(18.5, LOUNGE_H - 0.3, -1.2), Vector3(23.8, 1.2, -3.2), Color(1.0, 0.6, 0.78), 14.0, 9.0, 24.0, true)
	_omni(Vector3(16.0, LOUNGE_H - 0.5, -2.5), Color(0.9, 0.55, 0.75), 1.3, 9.0)
	_omni(Vector3(21.0, LOUNGE_H - 0.6, -4.2), Color(1.0, 0.72, 0.6), 0.8, 6.0)
	_sign("THE LOUNGE", Vector3(17.0, 3.3, -5.76), 0.0, 48, PINK * 1.5)


# --- The high-limit room ----------------------------------------------------------------------

func _high_limit() -> void:
	_in("high_limit")
	var r := Rect2(-17.8, -37.8, 13.6, 11.6)
	_floor(r, "carpet")
	_wall("salon", Vector2(-4.2, -26.2), Vector2(-17.8, -26.2), Vector2(0, -1), HL_H, [{"at": -11.0, "w": 2.0, "h": 2.6}])
	_wall("salon", Vector2(-17.8, -26.2), Vector2(-17.8, -37.8), Vector2(1, 0), HL_H)
	_wall("salon", Vector2(-17.8, -37.8), Vector2(-4.2, -37.8), Vector2(0, 1), HL_H)
	_wall("salon", Vector2(-4.2, -37.8), Vector2(-4.2, -26.2), Vector2(-1, 0), HL_H)
	_ceiling(r, HL_H, "plaster")
	# A gilt frame round the ceiling.
	var inner := r.grow(-1.2)
	for e in [Rect2(inner.position.x, inner.position.y, inner.size.x, 0.06), Rect2(inner.position.x, inner.end.y - 0.06, inner.size.x, 0.06),
			Rect2(inner.position.x, inner.position.y, 0.06, inner.size.y), Rect2(inner.end.x - 0.06, inner.position.y, 0.06, inner.size.y)]:
		_slab(Vector3(e.get_center().x, HL_H - 0.04, e.get_center().y), Vector3(e.size.x, 0.08, e.size.y), _mat("gilt"))
	# Baccarat under the chandelier.
	_box("tideline_baccarat", Vector3(-11.0, 0.0, -32.2))
	_chandelier(-11.0, -32.2, HL_H, 1.25)
	var ch := _omni(Vector3(-11.0, 2.7, -32.2), WARM, 2.4, 10.0, true)
	ch.shadow_bias = 0.08
	# The private bar along the west wall, and a corner to sit in.
	_box("back_bar", Vector3(-17.5, 0.0, -31.0), PI * 0.5)
	_omni(Vector3(-17.0, 1.9, -31.0), CANDLE, 0.6, 3.0)
	_m("rug", Vector3(-7.0, 0.0, -35.0), 0.0, Vector3(0.8, 1.0, 0.8))
	_box("sofa", Vector3(-7.0, 0.0, -37.33))
	_box("low_table", Vector3(-7.0, 0.0, -35.4))
	for xx in [-8.9, -5.1]:
		_box("armchair", Vector3(xx, 0.0, -34.9), PI * 0.5 if xx < -7.0 else -PI * 0.5)
	_box("floor_lamp", Vector3(-4.6, 0.0, -37.4))
	_omni(Vector3(-4.6, 1.55, -37.3), CANDLE, 0.6, 4.0)
	for p in [Vector2(-17.2, -37.2), Vector2(-17.2, -26.9), Vector2(-4.8, -26.9)]:
		_m("potted_palm", _v(p))
		_solid(_v(p, 0.45), Vector3(0.6, 0.9, 0.6))
	_painting(Vector2(-4.2, -31.5), Vector2(-1, 0), 2.0, 1.45, 1.33, "painting_coast")
	_painting(Vector2(-11.0, -37.8), Vector2(0, 1), 2.4, 1.5, 1.6, "painting_valley")
	for z in [-28.5, -34.5]:
		_m("wall_sconce", Vector3(-4.2, 2.3, z), -PI * 0.5)
		_m("wall_sconce", Vector3(-17.8, 2.3, z), PI * 0.5)
	_m("door_surround", Vector3(-11.0, 0.0, -26.2), PI, Vector3(2.0 / 2.4, 2.6 / 3.0, 1.0))
	_m("tideline_dome_camera", Vector3(-11.0, HL_H - 0.12, -29.0))
	for p in [Vector3(-15.0, 3.2, -29.0), Vector3(-6.5, 3.2, -29.5), Vector3(-15.0, 3.2, -35.5)]:
		_omni(p, CANDLE, 0.55, 6.0)
	_probe(r, HL_H, Color(0.32, 0.3, 0.2), 0.3)


# --- The cage and the vault -------------------------------------------------------------------

func _cage() -> void:
	_in("cage")
	var r := Rect2(10.2, -13.8, 5.6, 7.6)
	_floor(r, "carpet_office")
	var windows := []
	for z in WINDOWS:
		windows.append({"at": z, "w": 1.8, "h": 2.6})
	_wall("back", Vector2(10.2, -6.2), Vector2(10.2, -13.8), Vector2(1, 0), BACK_H, windows)
	_wall("back", Vector2(10.2, -13.8), Vector2(15.8, -13.8), Vector2(0, 1), BACK_H, [{"at": 12.0, "w": 1.0, "h": 2.2}])
	_wall("back", Vector2(15.8, -13.8), Vector2(15.8, -6.2), Vector2(-1, 0), BACK_H, [{"at": -10.0, "w": 2.2, "h": 2.3}], 0.25)
	_wall("back", Vector2(15.8, -6.2), Vector2(10.2, -6.2), Vector2(0, -1), BACK_H)
	_ceiling(r, BACK_H, "plaster_white")
	# The vault door's frame on the cage side.
	_m("tideline_vault_frame", Vector3(15.8, 0.0, -10.0), -PI * 0.5)
	_sign("TIME LOCK", Vector3(15.74, 2.75, -10.0), -PI * 0.5, 24, Color(0.85, 0.82, 0.7), 0.003)
	# Imani's desk, the key box, cash carts.
	_box("office_desk", Vector3(14.6, 0.0, -13.37))
	_m("desk_lamp", Vector3(14.0, 0.76, -13.55), 0.3)
	_m("tideline_key_box", Vector3(13.2, 1.2, -13.8))
	_box("tideline_drop_cart", Vector3(15.3, 0.0, -7.0), PI * 0.5)
	_box("filing_cabinet", Vector3(15.5, 0.0, -12.6), -PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(13.0, 2.2, -6.2), PI, Vector3.ONE * 0.45))
	_m("tideline_dome_camera", Vector3(13.0, BACK_H - 0.12, -10.0))
	_m("doorframe_plain", Vector3(12.0, 0.0, -13.8))
	for z in [-12.0, -8.0]:
		_slab(Vector3(12.8, BACK_H - 0.03, z), Vector3(1.2, 0.05, 0.6), _mat("panel_light"))
		_omni(Vector3(12.8, BACK_H - 0.4, z), COOL, 0.75, 6.0)
	_omni(Vector3(10.9, 1.9, -10.0), WARM, 0.45, 3.5)
	_probe(r, BACK_H, Color(0.34, 0.34, 0.33), 0.3)


func _vault() -> void:
	_in("vault")
	var r := Rect2(16.3, -13.7, 4.4, 7.4)
	_floor(r, "vault_floor")
	_wall("vault", Vector2(16.3, -6.3), Vector2(16.3, -13.7), Vector2(1, 0), VAULT_H, [{"at": -10.0, "w": 2.2, "h": 2.3}], 0.25)
	_wall("vault", Vector2(16.3, -13.7), Vector2(20.7, -13.7), Vector2(0, 1), VAULT_H, [], 0.3)
	_wall("vault", Vector2(20.7, -13.7), Vector2(20.7, -6.3), Vector2(-1, 0), VAULT_H, [], 0.3)
	_wall("vault", Vector2(20.7, -6.3), Vector2(16.3, -6.3), Vector2(0, -1), VAULT_H, [], 0.3)
	_ceiling(r, VAULT_H, "vault_wall")
	_m("tideline_vault_frame", Vector3(16.3, 0.0, -10.0), PI * 0.5)
	for x in [17.4, 19.5]:
		_box("tideline_vault_shelves", Vector3(x, 0.0, -13.45))
	_m("tideline_deposit_boxes", Vector3(20.7, 0.0, -11.2), -PI * 0.5)
	_solid(Vector3(20.66, 1.1, -11.2), Vector3(0.1, 2.2, 2.4))
	_box("tideline_vault_table", Vector3(18.6, 0.0, -11.4), PI * 0.5)
	var case_at := Vector3(18.6, 0.9, -11.4)
	var rose := _use("vault_table", case_at, Vector3(0.45, 0.35, 0.45), "tideline_rose_case", -PI * 0.5)
	rose.set_meta("use", "item:rose")
	_omni(case_at + Vector3(0.0, 0.6, 0.0), Color(1.0, 0.8, 0.9), 0.35, 1.6)
	_box("tideline_drop_cart", Vector3(19.7, 0.0, -7.0), PI * 0.5)
	_m("tideline_dome_camera", Vector3(18.5, VAULT_H - 0.12, -12.5))
	_slab(Vector3(18.5, VAULT_H - 0.03, -10.0), Vector3(0.4, 0.05, 2.4), _mat("panel_light"))
	var l := _omni(Vector3(18.5, VAULT_H - 0.45, -10.4), COOL, 1.3, 7.0, true)
	l.shadow_bias = 0.06
	_probe(r, VAULT_H, Color(0.3, 0.32, 0.34), 0.3)


# --- The back of the house --------------------------------------------------------------------

func _corridor() -> void:
	_in("corridor")
	var r := Rect2(10.2, -17.8, 15.6, 3.6)
	_floor(r, "concrete")
	_wall("back", Vector2(10.2, -17.8), Vector2(25.8, -17.8), Vector2(0, 1), BACK_H,
			[{"at": 13.5, "w": 1.1, "h": 2.2}, {"at": 19.5, "w": 1.1, "h": 2.2}, {"at": 24.0, "w": 1.1, "h": 2.2}])
	_wall("back", Vector2(25.8, -14.2), Vector2(10.2, -14.2), Vector2(0, -1), BACK_H,
			[{"at": 12.0, "w": 1.0, "h": 2.2}, {"at": 23.5, "w": 1.1, "h": 2.2}])
	_wall("back", Vector2(10.2, -14.2), Vector2(10.2, -17.8), Vector2(1, 0), BACK_H, [{"at": -16.0, "w": 1.1, "h": 2.2}])
	_wall("back", Vector2(25.8, -17.8), Vector2(25.8, -14.2), Vector2(-1, 0), BACK_H, [{"at": -16.0, "w": 1.1, "h": 2.2}])
	_ceiling(r, BACK_H, "plaster_grey")
	for d in [[Vector2(13.5, -17.8), 0.0, "COUNT ROOM"], [Vector2(19.5, -17.8), 0.0, "SURVEILLANCE"], [Vector2(24.0, -17.8), 0.0, "SECURITY"],
			[Vector2(12.0, -14.2), PI, "CAGE"], [Vector2(23.5, -14.2), PI, "STAFF ROOM"], [Vector2(10.2, -16.0), PI * 0.5, "CASINO FLOOR"],
			[Vector2(25.8, -16.0), -PI * 0.5, "EXIT"]]:
		var at: Vector2 = d[0]
		var yaw: float = d[1]
		_m("doorframe_plain", _v(at), yaw)
		var out := Vector2(sin(yaw), cos(yaw)) * 0.04
		_sign(str(d[2]), _v(at + out, 2.55), yaw, 26, Color(0.25, 0.25, 0.27) if d[2] != "EXIT" else Color(0.2, 1.4, 0.4), 0.003)
	# The count room's keypad, beside its door.
	_m("keypad", Vector3(12.6, 1.17, -17.8))
	var pad := _use("count_pad", Vector3(12.6, 1.13, -17.75), Vector3(0.24, 0.3, 0.12))
	pad.set_meta("use", "count_pad")
	_m("cctv_camera", Vector3(10.4, 2.7, -17.8))
	_m("cctv_camera", Vector3(25.6, 2.7, -14.2), PI)
	_m("notice_board", Vector3(16.5, 1.2, -14.2), PI)
	_m("bulkhead_light", Vector3(25.8, 2.55, -16.0), -PI * 0.5)
	for x in [12.5, 17.5, 22.5]:
		_slab(Vector3(x, BACK_H - 0.03, -16.0), Vector3(1.4, 0.05, 0.3), _mat("panel_light"))
		_omni(Vector3(x, BACK_H - 0.4, -16.0), COOL, 0.7, 6.5)
	_probe(r, BACK_H, Color(0.32, 0.33, 0.33), 0.3)


func _count_room() -> void:
	_in("count_room")
	var r := Rect2(10.2, -25.8, 6.6, 7.6)
	_floor(r, "tile_white")
	_wall("back", Vector2(16.8, -18.2), Vector2(10.2, -18.2), Vector2(0, -1), BACK_H, [{"at": 13.5, "w": 1.1, "h": 2.2}])
	_wall("back", Vector2(10.2, -18.2), Vector2(10.2, -25.8), Vector2(1, 0), BACK_H)
	_wall("back", Vector2(10.2, -25.8), Vector2(16.8, -25.8), Vector2(0, 1), BACK_H)
	_wall("back", Vector2(16.8, -25.8), Vector2(16.8, -18.2), Vector2(-1, 0), BACK_H)
	_ceiling(r, BACK_H, "plaster_white")
	_box("tideline_count_table", Vector3(13.8, 0.0, -22.6))
	var sheet := _use("count_desk", Vector3(12.9, 0.92, -22.45), Vector3(0.4, 0.12, 0.45), "tideline_count_sheet", 0.2)
	sheet.set_meta("use", "item:count_sheet")
	for z in [-21.2, -23.4]:
		_box("tideline_drop_cart", Vector3(11.0, 0.0, z), PI * 0.5)
	_m("tideline_key_box", Vector3(16.8, 1.25, -20.0), -PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(13.8, 2.1, -25.8), 0.0, Vector3.ONE * 0.5))
	_m("tideline_dome_camera", Vector3(13.8, BACK_H - 0.12, -21.0))
	_m("doorframe_plain", Vector3(13.5, 0.0, -18.2), PI)
	for z in [-20.6, -23.6]:
		_slab(Vector3(13.8, BACK_H - 0.03, z), Vector3(2.4, 0.05, 0.5), _mat("panel_light"))
		_omni(Vector3(13.8, BACK_H - 0.4, z), COOL, 1.0, 6.5)
	_probe(r, BACK_H, Color(0.38, 0.38, 0.38), 0.35)


func _eye() -> void:
	_in("eye")
	var r := Rect2(17.2, -25.8, 4.6, 7.6)
	_floor(r, "carpet_office")
	_wall("eye", Vector2(21.8, -18.2), Vector2(17.2, -18.2), Vector2(0, -1), BACK_H, [{"at": 19.5, "w": 1.1, "h": 2.2}])
	_wall("eye", Vector2(17.2, -18.2), Vector2(17.2, -25.8), Vector2(1, 0), BACK_H)
	_wall("eye", Vector2(17.2, -25.8), Vector2(21.8, -25.8), Vector2(0, 1), BACK_H)
	_wall("eye", Vector2(21.8, -25.8), Vector2(21.8, -18.2), Vector2(-1, 0), BACK_H)
	_ceiling(r, BACK_H, "ceiling_dark")
	_m("tideline_monitor_wall", Vector3(19.5, 0.65, -25.8))
	_box("cctv_monitors", Vector3(19.5, 0.0, -24.9))
	_box("filing_cabinet", Vector3(21.5, 0.0, -21.0), -PI * 0.5)
	_box("office_chair", Vector3(17.8, 0.0, -21.5), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(17.2, 2.2, -21.0), PI * 0.5, Vector3.ONE * 0.45))
	_m("doorframe_plain", Vector3(19.5, 0.0, -18.2), PI)
	_omni(Vector3(19.5, 1.7, -24.2), Color(0.5, 0.68, 1.0), 1.0, 5.5)
	_slab(Vector3(19.5, BACK_H - 0.03, -20.5), Vector3(0.6, 0.05, 0.6), _mat("panel_light"))
	_omni(Vector3(19.5, BACK_H - 0.4, -20.5), COOL, 0.6, 4.5)
	# Behind Dmitri's chair, so he isn't only a shape against the screens.
	_omni(Vector3(20.2, 2.1, -22.0), COOL, 0.4, 3.0)
	_probe(r, BACK_H, Color(0.18, 0.22, 0.3), 0.3)


func _office() -> void:
	_in("office")
	var r := Rect2(22.2, -25.8, 3.6, 7.6)
	_floor(r, "carpet_office")
	_wall("paint", Vector2(25.8, -18.2), Vector2(22.2, -18.2), Vector2(0, -1), BACK_H, [{"at": 24.0, "w": 1.1, "h": 2.2}])
	_wall("paint", Vector2(22.2, -18.2), Vector2(22.2, -25.8), Vector2(1, 0), BACK_H)
	_wall("paint", Vector2(22.2, -25.8), Vector2(25.8, -25.8), Vector2(0, 1), BACK_H)
	_wall("paint", Vector2(25.8, -25.8), Vector2(25.8, -18.2), Vector2(-1, 0), BACK_H)
	_ceiling(r, BACK_H, "plaster_white")
	_box("office_desk", Vector3(24.0, 0.0, -25.37))
	_box("office_chair", Vector3(24.0, 0.0, -24.4), PI)
	_m("desk_lamp", Vector3(23.4, 0.76, -25.55), 0.3)
	_box("lockers", Vector3(22.465, 0.0, -21.5), PI * 0.5)
	_box("locker_bench", Vector3(25.35, 0.0, -23.0), PI * 0.5)
	_box("filing_cabinet", Vector3(25.5, 0.0, -25.4))
	_m("notice_board", Vector3(22.2, 1.3, -24.4), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(25.8, 2.2, -20.5), -PI * 0.5, Vector3.ONE * 0.4))
	_m("doorframe_plain", Vector3(24.0, 0.0, -18.2), PI)
	for z in [-20.6, -23.8]:
		_slab(Vector3(24.0, BACK_H - 0.03, z), Vector3(1.2, 0.05, 0.6), _mat("panel_light"))
		_omni(Vector3(24.0, BACK_H - 0.4, z), COOL, 0.55, 5.5)
	_probe(r, BACK_H, Color(0.3, 0.32, 0.34), 0.3)


func _staff_room() -> void:
	_in("staff_room")
	var r := Rect2(21.2, -13.8, 4.6, 7.6)
	_floor(r, "quarry")
	_wall("back", Vector2(21.2, -13.8), Vector2(25.8, -13.8), Vector2(0, 1), BACK_H, [{"at": 23.5, "w": 1.1, "h": 2.2}])
	_wall("back", Vector2(25.8, -13.8), Vector2(25.8, -6.2), Vector2(-1, 0), BACK_H)
	_wall("back", Vector2(25.8, -6.2), Vector2(21.2, -6.2), Vector2(0, -1), BACK_H)
	_wall("back", Vector2(21.2, -6.2), Vector2(21.2, -13.8), Vector2(1, 0), BACK_H, [], 0.3)
	_ceiling(r, BACK_H, "plaster_grey")
	for z in [-12.2, -10.2]:
		_box("lockers", Vector3(25.535, 0.0, z), -PI * 0.5)
	_box("locker_bench", Vector3(24.3, 0.0, -11.2), PI * 0.5)
	_box("side_table", Vector3(22.4, 0.0, -8.4))
	for p in [Vector2(22.4, -9.2), Vector2(23.2, -8.4)]:
		_box("banquet_chair", _v(p), atan2(22.4 - p.x, -8.4 - p.y))
	_box("tideline_cleaning_cart", Vector3(24.8, 0.0, -6.75), PI)
	_box("service_trolley", Vector3(21.6, 0.0, -12.6), PI * 0.5)
	_m("notice_board", Vector3(21.2, 1.2, -10.8), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(23.5, 2.2, -6.2), PI, Vector3.ONE * 0.45))
	_m("doorframe_plain", Vector3(23.5, 0.0, -13.8))
	_slab(Vector3(23.5, BACK_H - 0.03, -10.0), Vector3(1.4, 0.05, 0.4), _mat("panel_light"))
	_omni(Vector3(23.5, BACK_H - 0.4, -10.0), Color(0.95, 0.93, 0.88), 0.9, 6.0)
	_probe(r, BACK_H, Color(0.36, 0.35, 0.33), 0.3)


# --- Outside: the street, the front, the alley, the water --------------------------------------

func _street() -> void:
	_in("outside")
	var x := -43.5
	while x < 45.0:
		for z in [1.5, 4.5]:
			_m("Sidewalk_NoCurb_3m", Vector3(x, 0.0, z))
		x += 3.0
	for kz in [KERB - 0.12, FAR_KERB + 0.12]:
		_slab(Vector3(0.0, -0.07, kz), Vector3(90.0, 0.16, 0.24), _mat("kerb"))
	_slab(Vector3(0.0, -0.2, (KERB + FAR_KERB) * 0.5), Vector3(90.0, 0.1, FAR_KERB - KERB), _mat("asphalt"))
	var mid := (KERB + FAR_KERB) * 0.5
	x = -44.0
	while x < 45.0:
		_slab(Vector3(x + 1.5, -0.148, mid), Vector3(3.0, 0.006, 0.14), _mat("road_paint"))
		x += 7.0
	for z in [KERB + 0.35, FAR_KERB - 0.35]:
		_slab(Vector3(0.0, -0.148, z), Vector3(90.0, 0.006, 0.1), _mat("road_paint"))
	for lx in [-36.0, -20.0, 10.0, 22.0, 38.0]:
		_lamp(Vector3(lx, 0.0, KERB - 0.6), absf(lx - (-4.0)) < 30.0)
	for bx in [-8.0, 0.0]:
		_box("Prop_Bollard", Vector3(bx, 0.0, KERB - 0.5))
	_m("Prop_ManholeCover", Vector3(6.0, -0.148, 9.0))
	# Nobody leaves the block: the street's ends.
	for ex in [-45.0, 45.0]:
		_solid(Vector3(ex, 3.0, (RAIL - 6.0) * 0.5), Vector3(0.4, 6.0, RAIL + 6.0))
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.12
	moon.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
	_at.add_child(moon)
	_probe(Rect2(-45.0, -26.0, 90.0, 44.0), 16.0, Color(0.12, 0.13, 0.18), 0.25)


## The Tideline's front: black marble and brass, its name in pink neon over
## a wave, the canopy, Teo's podium, and the buildings either side.
func _facade() -> void:
	_in("outside")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	_wall("facade", Vector2(-18.0, 0.0), Vector2(26.0, 0.0), Vector2(0, 1), 10.0, [{"at": -4.0, "w": 2.4, "h": 3.12}])
	_reveal(Vector2(-4.0, -0.25), Vector2(1, 0), 2.4, 3.12, 0.5, _mat("gilt"), "brass")
	_slab(Vector3(-4.0, 2.96, -0.25), Vector3(2.4, 0.32, 0.02), _mat("night_glass"))
	_m("canopy", Vector3(-4.0, 0.0, 0.42))
	for px in [-5.85, -2.15]:
		_solid(Vector3(px, 1.65, 3.77), Vector3(0.22, 3.3, 0.22))
	_slab(Vector3(-4.0, 0.006, 1.95), Vector3(2.0, 0.012, 3.9), _mat("red_carpet"))
	for sx in [-5.02, -2.98]:
		_slab(Vector3(sx, 0.008, 1.95), Vector3(0.04, 0.016, 3.9), _mat("brass"))
	# The name, in neon, over a wave.
	_sign("THE TIDELINE", Vector3(-4.0, 6.1, 0.14), 0.0, 128, PINK * 1.8, 0.011)
	_m("tideline_neon_wave", Vector3(-4.0, 4.3, 0.02), 0.0, Vector3(1.9, 1.9, 1.0))
	_sign("CASINO   BAR   LOUNGE", Vector3(-4.0, 3.84, 0.2), 0.0, 40, CYAN * 1.5, 0.007)
	_sign("LIVE MUSIC NIGHTLY", Vector3(17.5, 3.0, 0.08), 0.0, 48, PINK * 1.4, 0.006)
	_omni(Vector3(-4.0, 6.0, 1.8), PINK, 2.2, 13.0)
	_omni(Vector3(17.5, 3.0, 1.4), Color(1.0, 0.5, 0.8), 0.9, 6.0)
	# Teo's podium, and the canopy's light (the street's shadow).
	_box("tideline_podium", Vector3(-6.2, 0.0, 1.9))
	_spot(Vector3(-4.0, 3.2, 2.2), Vector3(-4.0, 0.0, 1.6), WARM, 4.0, 6.0, 55.0, true)
	_omni(Vector3(-4.0, 2.6, 0.9), WARM, 0.8, 5.0)
	# Uplights between the bays.
	for ux in [-15.0, 6.0, 14.0, 23.0]:
		_spot(Vector3(ux, 0.15, 0.8), Vector3(ux, 8.0, 0.0), Color(1.0, 0.5, 0.82), 4.0, 11.0, 22.0)
	# Next door: a brick block west, white brick east of the alley.
	_block(-45.0, -18.0, 0.0, false, 12.0, "red", rng)
	_block(34.0, 45.0, 0.0, false, 12.0, "white", rng)


func _alley() -> void:
	_in("outside")
	_floor(Rect2(26.0, -26.0, 8.0, 26.0), "concrete")
	_wall("brick", Vector2(26.0, 0.0), Vector2(26.0, -26.0), Vector2(1, 0), 10.0, [{"at": -16.0, "w": 1.1, "h": 2.2}])
	_wall("brick", Vector2(26.0, -26.0), Vector2(34.0, -26.0), Vector2(0, 1), 12.0)
	_wall("brick", Vector2(34.0, -26.0), Vector2(34.0, 0.0), Vector2(-1, 0), 12.0)
	_reveal(Vector2(26.0, -16.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_m("doorframe_plain", Vector3(26.0, 0.0, -16.0), PI * 0.5)
	_m("bulkhead_light", Vector3(26.0, 2.55, -16.0), PI * 0.5)
	_sign("STAFF ONLY", Vector3(26.04, 2.35, -16.0), PI * 0.5, 26, Color(0.85, 0.85, 0.8), 0.003)
	_m("keypad", Vector3(26.0, 1.17, -15.15), PI * 0.5)
	var pad := _use("back_pad", Vector3(26.05, 1.13, -15.15), Vector3(0.12, 0.3, 0.24))
	pad.set_meta("use", "back_pad")
	# The cameras' junction box, padlocked, its conduit running up the wall.
	_m("tideline_cam_panel", Vector3(26.0, 1.0, -21.0), PI * 0.5)
	var panel := _use("cam_panel", Vector3(26.15, 1.0, -21.0), Vector3(0.3, 0.75, 0.6))
	panel.set_meta("use", "cam_panel")
	_m("cctv_camera", Vector3(26.0, 3.2, -12.0), PI * 0.5)
	_box("dumpster", Vector3(30.5, 0.0, -25.25))
	for z in [-22.0, -21.2]:
		_box("wheelie_bin", Vector3(33.37, 0.0, z), -PI * 0.5)
	_box("pallet", Vector3(28.0, 0.0, -24.9), 0.2)
	_m("Prop_ACUnit", Vector3(26.0, 4.2, -9.0), PI * 0.5)
	_m("Prop_ACUnit", Vector3(34.0, 5.4, -18.0), -PI * 0.5)
	_m("Prop_Drain", Vector3(30.0, 0.002, -12.0))
	_m("bulkhead_light", Vector3(34.0, 3.0, -8.0), -PI * 0.5)
	_omni(Vector3(26.6, 2.4, -16.0), SODIUM, 1.6, 7.0)
	_omni(Vector3(33.4, 2.8, -8.0), SODIUM, 1.1, 7.0)
	_omni(Vector3(30.0, 3.0, -23.0), SODIUM, 0.6, 6.0)


## Across the road: the boardwalk and its railing, the harbour and the
## yachts moored in it.
func _waterfront() -> void:
	_in("outside")
	_floor(Rect2(-45.0, FAR_KERB, 90.0, RAIL - FAR_KERB + 0.2), "planks")
	var x := -44.0
	while x < 45.0:
		_m("tideline_railing", Vector3(x, 0.0, RAIL - 0.05))
		x += 2.0
	_solid(Vector3(0.0, 0.6, RAIL), Vector3(90.0, 1.2, 0.2))
	_slab(Vector3(0.0, -0.7, RAIL + 0.15), Vector3(90.0, 1.4, 0.3), _mat("seawall"))
	_slab(Vector3(0.0, -1.25, RAIL + 60.0), Vector3(300.0, 0.1, 120.0), _mat("water"))
	for b in [[Vector3(-26.0, -1.2, 31.0), 0.0], [Vector3(6.0, -1.2, 36.0), PI], [Vector3(34.0, -1.2, 30.0), 0.0], [Vector3(-2.0, -1.2, 62.0), 0.2]]:
		_no_shadow(_m("tideline_yacht", b[0], b[1]))
	for lx in [-30.0, -15.0, 0.0, 15.0, 30.0]:
		_lamp(Vector3(lx, 0.0, FAR_KERB + 0.6), absf(lx) < 20.0)
	for bx in [-9.0, 9.0]:
		_box("locker_bench", Vector3(bx, 0.0, RAIL - 0.8))
	# Far lights across the harbour.
	for i in 14:
		var fx := -120.0 + i * 18.0
		_slab(Vector3(fx, 1.5 + float(i % 3), 140.0), Vector3(6.0, 3.0 + float(i % 4) * 2.0, 1.0), _mat("hull_glow"))


# --- Doors ------------------------------------------------------------------------------------

func _doors() -> void:
	_make_doors(DOOR_SPECS)
	_in("floor")
	_reveal(Vector2(10.0, -16.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(-11.0, -26.0), Vector2(1, 0), 2.0, 2.6, 0.4, _mat("walnut"), "brass")
	_in("corridor")
	_reveal(Vector2(13.5, -18.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_reveal(Vector2(19.5, -18.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_reveal(Vector2(24.0, -18.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(12.0, -14.0), Vector2(1, 0), 1.0, 2.2, 0.4, _mat("steel"), "steel")
	_reveal(Vector2(23.5, -14.0), Vector2(1, 0), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_in("cage")
	_reveal(Vector2(16.05, -10.0), Vector2(0, 1), 2.2, 2.3, 0.5, _mat("vault_wall"), "vault_floor")


# --- Where people go --------------------------------------------------------------------------

func _graph() -> void:
	var P := {
		# The front.
		"crew_0": Vector2(-4.6, 3.4), "crew_1": Vector2(-3.4, 3.4), "front_out": Vector2(-4.0, 1.6),
		"teo": Vector2(-6.2, 1.1), "kerb": Vector2(4.0, 4.4), "pavement_e": Vector2(8.0, 2.8),
		"alley_mouth": Vector2(30.0, 2.6), "alley_s": Vector2(30.0, -5.0), "alley_c": Vector2(30.0, -14.0),
		"alley_n": Vector2(30.0, -21.5), "panel": Vector2(27.0, -21.0), "back_out": Vector2(27.2, -16.0),
		"tess_smoke": Vector2(27.3, -13.4),
		# The floor.
		"front_in": Vector2(-4.0, -1.6), "entry": Vector2(-4.0, -3.8), "floor_c": Vector2(-4.0, -9.6),
		"west_aisle": Vector2(-14.3, -9.6), "bar_end": Vector2(-16.85, -9.4), "desi": Vector2(-16.85, -13.0),
		"bea_bar": Vector2(-14.6, -12.8), "floor_e": Vector2(6.8, -9.6), "pilar": Vector2(7.8, -3.0),
		"east_c": Vector2(7.8, -13.6), "staff_out": Vector2(8.8, -16.0), "marcus": Vector2(9.0, -17.0),
		"east_n": Vector2(8.0, -19.6), "north_e": Vector2(6.0, -22.2), "north_w": Vector2(-5.75, -22.2),
		"lyle": Vector2(-3.9, -20.1), "hl_out": Vector2(-11.0, -24.3),
		"window_1": Vector2(9.2, -12.6), "window_2": Vector2(9.2, -10.0), "window_3": Vector2(9.2, -7.4),
		# The pit.
		"pit_w": Vector2(-6.0, -12.2), "pit_e": Vector2(0.0, -12.2), "pit_c": Vector2(-4.6, -15.6),
		"augie": Vector2(-3.0, -15.45), "pit_s": Vector2(-4.2, -17.6), "tess": Vector2(-2.6, -17.95),
		"pit_nw": Vector2(-5.75, -19.0), "pit_ne": Vector2(0.0, -19.0), "pit_se": Vector2(-0.75, -17.9),
		"pit_n": Vector2(0.0, -21.2),
		# The lounge.
		"lounge_w": Vector2(11.5, -2.6), "lounge_c": Vector2(17.0, -2.4), "horace": Vector2(20.4, -2.9),
		"stage_foot": Vector2(21.3, -3.2), "marisol": Vector2(24.0, -3.2),
		# The high-limit room.
		"hl_in": Vector2(-11.0, -27.6), "anton": Vector2(-8.2, -28.4), "hl_c": Vector2(-8.0, -30.4),
		"hugo": Vector2(-11.6, -31.0),
		# The back of the house.
		"staff_in": Vector2(11.2, -16.0), "corr_w": Vector2(12.0, -16.0), "cage_out": Vector2(12.0, -15.2),
		"count_out": Vector2(13.5, -16.6), "corridor_check": Vector2(17.5, -16.0), "eye_out": Vector2(19.5, -16.6),
		"office_guard": Vector2(22.6, -16.6), "office_out": Vector2(24.0, -16.6), "staff_room_out": Vector2(23.5, -15.2),
		"back_in": Vector2(25.0, -16.0),
		"count_in": Vector2(13.5, -19.4), "count_e": Vector2(16.0, -20.2), "marcus_count": Vector2(16.0, -21.8),
		"count_ne": Vector2(16.0, -23.7), "gloria": Vector2(13.4, -23.6), "count_look": Vector2(12.0, -19.8),
		"count_door": Vector2(13.5, -19.0),
		"eye_in": Vector2(19.5, -19.4), "dmitri": Vector2(19.5, -23.6),
		"office_in": Vector2(24.0, -19.4), "held": Vector2(24.5, -23.0),
		"staff_room_in": Vector2(23.5, -12.6), "lockers": Vector2(23.0, -10.4),
		# The cage and the vault.
		"cage_in": Vector2(12.0, -12.8), "bea": Vector2(10.95, -12.6), "imani": Vector2(10.95, -7.4),
		"cage_c": Vector2(13.0, -10.0), "horace_window": Vector2(11.0, -10.0), "horace_listen": Vector2(13.4, -6.9),
		"vault_out": Vector2(14.9, -10.0), "imani_vault": Vector2(15.0, -11.4), "horace_vault": Vector2(15.0, -8.6),
		"vault_in": Vector2(17.3, -10.0), "rose_table": Vector2(17.6, -11.4),
	}
	for k in P:
		points[k] = _v(P[k], 0.22 if k == "marisol" else 0.0)
	var L := [
		# The front and the street.
		["crew_0", "front_out", ""], ["crew_1", "front_out", ""], ["crew_0", "crew_1", ""], ["front_out", "teo", ""],
		["front_out", "kerb", ""], ["kerb", "pavement_e", ""], ["front_out", "pavement_e", ""], ["pavement_e", "alley_mouth", ""],
		["alley_mouth", "alley_s", ""], ["alley_s", "alley_c", ""], ["alley_c", "back_out", ""], ["alley_c", "tess_smoke", ""],
		["tess_smoke", "back_out", ""], ["alley_c", "alley_n", ""], ["alley_n", "panel", ""],
		["front_out", "front_in", "front"],
		# The floor.
		["front_in", "entry", ""], ["entry", "floor_c", ""], ["floor_c", "west_aisle", ""], ["west_aisle", "bar_end", ""],
		["bar_end", "desi", ""], ["west_aisle", "bea_bar", ""], ["floor_c", "floor_e", ""], ["floor_e", "pilar", ""],
		["floor_e", "east_c", ""], ["east_c", "staff_out", ""], ["east_c", "marcus", ""], ["staff_out", "marcus", ""],
		["marcus", "east_n", ""], ["east_n", "north_e", ""], ["north_e", "north_w", ""], ["north_w", "lyle", ""],
		["north_w", "hl_out", ""], ["floor_e", "window_1", ""], ["floor_e", "window_2", ""], ["floor_e", "window_3", ""],
		["window_1", "east_c", ""], ["pilar", "lounge_w", ""], ["window_3", "pilar", ""],
		# The pit.
		["floor_c", "pit_w", ""], ["floor_c", "pit_e", ""], ["pit_w", "pit_c", ""], ["pit_e", "augie", ""],
		["pit_c", "augie", ""], ["pit_c", "pit_s", ""], ["pit_s", "tess", ""], ["pit_s", "pit_nw", ""],
		["tess", "pit_se", ""], ["pit_se", "pit_ne", ""], ["pit_nw", "north_w", ""], ["pit_ne", "pit_n", ""],
		["pit_n", "north_e", ""],
		# The lounge.
		["lounge_w", "lounge_c", ""], ["lounge_c", "horace", ""], ["horace", "stage_foot", ""], ["stage_foot", "marisol", ""],
		# The high-limit room.
		["hl_out", "hl_in", "high_limit"], ["hl_in", "anton", ""], ["hl_in", "hugo", ""], ["anton", "hl_c", ""], ["hl_c", "hugo", ""],
		# The back of the house.
		["staff_out", "staff_in", "staff"], ["staff_in", "corr_w", ""], ["corr_w", "cage_out", ""], ["corr_w", "count_out", ""],
		["count_out", "corridor_check", ""], ["corridor_check", "eye_out", ""], ["eye_out", "office_guard", ""],
		["office_guard", "office_out", ""], ["office_guard", "staff_room_out", ""], ["office_out", "back_in", ""],
		["staff_room_out", "back_in", ""], ["back_in", "back_out", "back"],
		["count_out", "count_door", "count_room"], ["count_door", "count_in", ""], ["count_in", "count_look", ""], ["count_in", "count_e", ""],
		["count_e", "marcus_count", ""], ["marcus_count", "count_ne", ""], ["count_ne", "gloria", ""],
		["eye_out", "eye_in", "eye"], ["eye_in", "dmitri", ""],
		["office_out", "office_in", "office"], ["office_in", "held", ""],
		["staff_room_out", "staff_room_in", "staff_room"], ["staff_room_in", "lockers", ""],
		# The cage and the vault.
		["cage_out", "cage_in", "cage"], ["cage_in", "bea", ""], ["cage_in", "cage_c", ""], ["cage_c", "imani", ""],
		["cage_c", "horace_window", ""], ["cage_c", "horace_listen", ""], ["cage_c", "vault_out", ""],
		["vault_out", "imani_vault", ""], ["vault_out", "horace_vault", ""], ["vault_out", "vault_in", "vault"],
		["vault_in", "rose_table", ""],
	]
	links = L
	var face := {
		"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "teo": Vector2(0, 1), "kerb": Vector2(0, 1),
		"tess_smoke": Vector2(1, 0.3), "panel": Vector2(-1, 0), "desi": Vector2(1, 0), "bea_bar": Vector2(-1, 0),
		"pilar": Vector2(-1, -0.4), "marcus": Vector2(-1, 0.2), "lyle": Vector2(0, 1), "augie": Vector2(0, -1),
		"tess": Vector2(0, -1), "horace": Vector2(1, -0.1), "marisol": Vector2(-1, 0), "anton": Vector2(-1, -0.4),
		"hugo": Vector2(0, -1), "corridor_check": Vector2(-1, 0), "office_guard": Vector2(1, 0), "count_in": Vector2(0, -1),
		"marcus_count": Vector2(-1, 0), "gloria": Vector2(0, 1), "count_look": Vector2(0, -1), "dmitri": Vector2(0, -1),
		"held": Vector2(-1, 0), "lockers": Vector2(1, 0), "bea": Vector2(-1, 0), "imani": Vector2(-1, 0),
		"horace_window": Vector2(-1, 0), "horace_listen": Vector2(0, 1), "imani_vault": Vector2(1, 0),
		"horace_vault": Vector2(1, 0), "vault_out": Vector2(1, 0), "vault_in": Vector2(1, 0), "rose_table": Vector2(1, 0), "count_out": Vector2(0, -1),
		"window_2": Vector2(1, 0), "back_out": Vector2(1, 0), "staff_in": Vector2(1, 0), "staff_out": Vector2(-1, 0),
		"cage_in": Vector2(0, 1), "cage_c": Vector2(-1, 0), "pit_c": Vector2(1, 0), "count_door": Vector2(0, 1), "front_in": Vector2(0, -1), "hl_in": Vector2(0, -1), "eye_in": Vector2(0, -1),
		"office_in": Vector2(0, -1), "staff_room_in": Vector2(0, 1),
	}
	for k in face:
		var t := _facing(P[k], face[k])
		t.origin = points[k]
		spots[k] = t
	_crowd()


## The crowd: players at the tables and the slots, drinkers at the bar,
## dealers in the pit, couples in the lounge and the high-limit room, a
## second doorman, people by the water.
func _crowd() -> void:
	var floor_: Array[Transform3D] = []
	for t in TABLES:
		var c: Vector2 = t[1]
		if str(t[0]) == "tideline_blackjack":
			for dx in [-0.75, 0.75]:
				floor_.append(_facing(c + Vector2(dx, 1.05), Vector2(-dx * 0.4, -1)))
		elif c.x < -5.0:
			for dx in [-0.6, 0.9]:
				floor_.append(_facing(c + Vector2(dx, -1.12), Vector2(0, 1)))
	for p in [Vector2(2.2, -20.3), Vector2(3.4, -20.4), Vector2(4.6, -20.25), Vector2(-2.3, -20.1)]:
		floor_.append(_facing(p, Vector2(0, 1)))
	for p in [[Vector2(-12.55, -2.0), Vector2(0, -1)], [Vector2(-10.45, -5.6), Vector2(0, 1)], [Vector2(3.15, -8.95 - 0.35), Vector2(0, 1)],
			[Vector2(4.55, -2.0), Vector2(0, -1)], [Vector2(-16.25, -2.55), Vector2(-1, 0)], [Vector2(1.65, -24.3), Vector2(0, -1)]]:
		floor_.append(_facing(p[0], p[1]))
	for p in [Vector2(-14.5, -15.0), Vector2(-14.5, -10.6)]:
		floor_.append(_facing(p, Vector2(-1, 0)))
	extras["floor"] = floor_
	var pit: Array[Transform3D] = []
	for t in TABLES:
		var c: Vector2 = t[1]
		if str(t[0]) == "tideline_blackjack":
			pit.append(_facing(c + Vector2(0, -1.05), Vector2(0, 1)))
		elif str(t[0]) == "tideline_craps":
			for dx in [-0.6, 0.6]:
				pit.append(_facing(c + Vector2(dx, 1.2), Vector2(0, -1)))
		elif c.x < -5.0:
			pit.append(_facing(c + Vector2(0.4, 1.05), Vector2(0, -1)))
	extras["pit"] = pit
	extras["lounge"] = [_facing(Vector2(12.0, -3.65), Vector2(0.2, -1)), _facing(Vector2(13.1, -3.65), Vector2(-0.3, -1)),
			_facing(Vector2(15.5, -3.55), Vector2(0, -1)), _facing(Vector2(18.1, -3.6), Vector2(1, -0.3)),
			_facing(Vector2(14.2, -1.4), Vector2(1, -0.4)), _facing(Vector2(15.0, -1.3), Vector2(-1, -0.2))] as Array[Transform3D]
	extras["high_limit"] = [_facing(Vector2(-10.2, -31.0), Vector2(0, -1)), _facing(Vector2(-12.6, -31.05), Vector2(0.2, -1)),
			_facing(Vector2(-15.9, -30.4), Vector2(-1, 0)), _facing(Vector2(-15.9, -31.6), Vector2(-1, 0))] as Array[Transform3D]
	extras["hl_table"] = [_facing(Vector2(-11.0, -33.4), Vector2(0, 1))] as Array[Transform3D]
	extras["doorway"] = [_facing(Vector2(-2.0, 1.2), Vector2(0, 1))] as Array[Transform3D]
	extras["outside"] = [_facing(Vector2(-12.0, 16.9), Vector2(0, 1)), _facing(Vector2(-11.3, 16.9), Vector2(-0.3, 1)),
			_facing(Vector2(12.0, 16.8), Vector2(0.2, 1)), _facing(Vector2(8.5, 2.2), Vector2(-1, 0.3)),
			_facing(Vector2(7.8, 2.6), Vector2(1, -0.2))] as Array[Transform3D]


func _views() -> void:
	var v := {
		"street": [Vector3(4.5, 1.7, 12.0), Vector3(-4.0, 4.0, 0.0)],
		"front": [Vector3(-4.0, 1.65, 6.8), Vector3(-4.0, 1.8, 0.0)],
		"entrance": [Vector3(-4.6, 1.65, -1.2), Vector3(-3.6, 1.4, -14.0)],
		"floor": [Vector3(-16.2, 2.6, -1.4), Vector3(-3.0, 0.8, -16.0)],
		"pit": [Vector3(-0.6, 1.75, -13.2), Vector3(-3.2, 1.0, -19.0)],
		"wheel_two": [Vector3(-4.2, 1.7, -21.6), Vector3(-2.6, 1.0, -17.4)],
		"slots": [Vector3(0.0, 1.7, -1.6), Vector3(4.0, 1.2, -8.0)],
		"bar": [Vector3(-11.0, 1.7, -8.4), Vector3(-16.4, 1.4, -13.4)],
		"lounge": [Vector3(10.6, 2.6, -2.2), Vector3(22.6, 0.8, -3.0)],
		"high_limit": [Vector3(-5.0, 2.0, -27.0), Vector3(-12.0, 1.0, -33.0)],
		"cage": [Vector3(5.0, 1.7, -10.0), Vector3(10.6, 1.5, -10.0)],
		"cage_inside": [Vector3(13.8, 1.9, -6.4), Vector3(15.9, 1.1, -11.2)],
		"vault": [Vector3(16.6, 2.0, -6.7), Vector3(19.8, 0.8, -12.2)],
		"corridor": [Vector3(11.0, 1.7, -16.0), Vector3(25.0, 1.4, -16.0)],
		"count_room": [Vector3(11.0, 1.8, -19.0), Vector3(14.6, 0.8, -23.6)],
		"eye": [Vector3(21.2, 1.8, -19.2), Vector3(18.4, 1.3, -25.4)],
		"office": [Vector3(23.0, 1.7, -18.8), Vector3(25.0, 0.9, -24.6)],
		"staff_room": [Vector3(22.0, 1.7, -13.2), Vector3(24.6, 1.0, -7.4)],
		"alley": [Vector3(31.5, 1.7, -2.0), Vector3(27.0, 1.4, -17.0)],
		"waterfront": [Vector3(-8.0, 2.4, 14.6), Vector3(14.0, 0.2, 27.0)],
	}
	_set_views(v)
	view_about = {
		"street": "The street at night: the Tideline's pink neon over its black marble front, the canopy, the doormen",
		"front": "The front doors from the pavement, where the crew starts, Teo at his podium",
		"entrance": "Just inside the front doors, looking up the floor to the pit",
		"floor": "The casino floor from its south-west corner: slots, the bar, the tables under their lamps",
		"pit": "The pit: Augie's podium in the middle of the tables, wheel two beyond it",
		"wheel_two": "Wheel two from the players' side: Tess's wheel, where Lyle plays",
		"slots": "The banks of slots by the front, glowing pink and blue",
		"bar": "The Tide Bar on the west wall: Desi's counter, the back bar, the stools",
		"lounge": "The lounge at the east end: banquettes, cocktail tables, Marisol on her stage",
		"high_limit": "The high-limit room: baccarat under the chandelier, the private bar, Hugo's table",
		"cage": "The cage from the floor: three windows behind brass bars, Bea's and Imani's open, the middle one closed",
		"cage_inside": "Inside the cage: the counters, Imani's desk, the vault door in its frame",
		"vault": "Inside the vault: shelves of cash, deposit boxes, the Rose on its table",
		"corridor": "The back corridor off the staff door: the count room, the eye, security, the cage, the back door",
		"count_room": "The count room: the count table, the drop carts, the key box and the count sheet",
		"eye": "The eye in the sky: the wall of camera feeds and Dmitri's console",
		"office": "Halberd's security office, where anyone held is kept",
		"staff_room": "The staff room: lockers, a bench, the cleaner's cart",
		"alley": "The alley out the back: the back door and its keypad, the cameras' junction box, the bins",
		"waterfront": "Across the road: the boardwalk, the railing, the yachts in the harbor",
	}
