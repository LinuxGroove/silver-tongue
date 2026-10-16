class_name Marlin
extends Venue
## The Marlin: a 60 m motor yacht, Halvorsen money, lent to the Caldera Museum
## for the Rose's charity auction. Moored stern-to at Caldera's marina, or out
## at sea on the night of the preview. Built in code on three decks over the
## hull (`tools/blender/marlin_props.py`):
##
## - the quay (y = 0): the gangway's gate, the purser's table, the chandler's
##   van, bollards and lamps, the road and the city across it;
## - the lower deck (y = -1.5): the crew's corridor, the galley, the crew mess,
##   the laundry and two crew cabins (the starboard one is where Halberd puts
##   anyone it holds), down the crew stair from the main deck;
## - the main deck (y = 1.2): the aft deck with its bar, the main saloon (where
##   the auction is held), the dining room and the lobby with the guest stair;
## - the upper deck (y = 4.2): the sun deck with its spa, the sky lounge, the
##   captain's cabin with its strongroom, and the bridge.
##
## X runs east (starboard), Z south (aft): the stern is at z = -2 and the bow
## points north. Spaces are tight and the walls thin; every room lights only
## itself, as every [Venue]'s do.

## The decks' floors, the water, and the rooms' heights.
const LOWER := -1.5
const MAIN := 1.2
const UPPER := 4.2
const SEA := -1.25
const LOWER_H := 2.2
const MAIN_H := 2.5
const UPPER_H := 2.4
## The house's sides: the rooms' faces, and the white skin outside.
const IN := 4.5
const SKIN := 4.8

## The rooms. The crew stair runs from the lower deck to the main deck; the
## strongroom is inside the captain's cabin, and the mess and cabins inside
## the crew's hall, so they come first.
const ZONES := {
	"crew_stair": AABB(Vector3(-4.6, -1.6, -16.25), Vector3(1.8, 5.75, 6.25)),
	"galley": AABB(Vector3(0.9, -1.6, -22.6), Vector3(3.7, 2.75, 7.25)),
	"mess": AABB(Vector3(-4.6, -1.6, -24.4), Vector3(3.7, 2.75, 6.75)),
	"cabin_a": AABB(Vector3(-4.6, -1.6, -31.0), Vector3(3.7, 2.75, 6.6)),
	"laundry": AABB(Vector3(0.9, -1.6, -26.2), Vector3(3.7, 2.75, 3.6)),
	"cabin_b": AABB(Vector3(0.9, -1.6, -31.0), Vector3(3.7, 2.75, 4.8)),
	"crew_hall": AABB(Vector3(-4.6, -1.6, -31.0), Vector3(5.5, 2.75, 15.65)),
	"aft_deck": AABB(Vector3(-4.8, 1.15, -10.0), Vector3(9.6, 3.0, 8.1)),
	"saloon": AABB(Vector3(-4.6, 1.15, -20.0), Vector3(9.2, 3.0, 10.0)),
	"dining": AABB(Vector3(-4.6, 1.15, -25.0), Vector3(9.2, 3.0, 5.0)),
	"lobby": AABB(Vector3(-4.6, 1.15, -31.2), Vector3(9.2, 3.0, 6.2)),
	"sun_deck": AABB(Vector3(-4.8, 4.15, -14.0), Vector3(9.6, 4.85, 10.2)),
	"sky_lounge": AABB(Vector3(-4.6, 4.15, -20.8), Vector3(9.2, 4.85, 6.8)),
	"safe": AABB(Vector3(-4.6, 4.15, -33.0), Vector3(2.6, 4.85, 2.4)),
	"captain": AABB(Vector3(-4.6, 4.15, -33.0), Vector3(5.6, 4.85, 12.2)),
	"upper_hall": AABB(Vector3(1.0, 4.15, -33.0), Vector3(3.6, 4.85, 12.2)),
	"bridge": AABB(Vector3(-4.6, 4.15, -38.5), Vector3(9.2, 4.85, 5.5)),
	"outside": AABB(Vector3(-60.0, -3.0, -80.0), Vector3(120.0, 40.0, 110.0)),
}
const ZONE_ORDER: Array[String] = [
	"crew_stair", "galley", "mess", "cabin_a", "laundry", "cabin_b", "crew_hall",
	"aft_deck", "saloon", "dining", "lobby",
	"sun_deck", "sky_lounge", "safe", "captain", "upper_hall", "bridge", "outside",
]
const LAYERS := {
	"outside": 2, "aft_deck": 3, "saloon": 4, "dining": 5, "lobby": 6, "crew_stair": 7, "galley": 8,
	"mess": 9, "crew_hall": 10, "cabin_a": 11, "laundry": 12, "cabin_b": 13, "sun_deck": 14,
	"sky_lounge": 15, "upper_hall": 16, "captain": 17, "safe": 17, "bridge": 18,
}

## Which night: "aboard" (moored, taking on crew and stores, the crew on the
## quay), "safe" (at sea for the preview, the Rose in the saloon) or
## "auction" (moored, the saloon set out for the sale).
var night := "aboard"
var _decks := {}


func _init(which := "aboard") -> void:
	night = which
	zones = ZONES
	zone_order = ZONE_ORDER
	room_layers = LAYERS


## Moored at the marina, with the quay and the gangway.
func moored() -> bool:
	return night != "safe"


## The doors are HotelDoors by name: gangway (the gate on the quay, moored
## nights only), crew, saloon, galley, cabin_a, cabin_b, sun, captain, safe
## and bridge. The uses are "stores" (crates of stores by the van, aboard),
## "safe_keypad" (beside the strongroom door), "safe_shelf" (the auction
## file, in the safe), "paddle" (the registration desk, at the auction) and
## "rostrum" (the auctioneer's, at the auction).
func _build() -> void:
	_make_rooms(ZONE_ORDER)
	_sea()
	if moored():
		_quay()
		_city()
	else:
		_coast()
	_hull()
	_floors()
	_lower_deck()
	_crew_stair()
	_aft_deck()
	_saloon()
	_dining()
	_lobby()
	_sun_deck()
	_sky_lounge()
	_upper_hall()
	_captain()
	_bridge()
	_house()
	_doors()
	_graph()
	_views()
	_apply_layers()
	_dress(self)


# --- Building blocks of the Marlin's own ------------------------------------------------------

## Builds in a room on a deck: the building blocks' y = 0 is `y`.
func _on(zone: String, y: float) -> void:
	var key := "%s@%.2f" % [zone, y]
	if not _decks.has(key):
		var n := Node3D.new()
		n.name = "Deck%s" % str(snappedf(y, 0.01)).replace("-", "m").replace(".", "_")
		n.position.y = y
		_rooms[zone].add_child(n)
		_decks[key] = n
	_at = _decks[key]


## A box from `a` to `b`, `w` across and `h` deep (square to its slope), its
## top `lift` over the line: a mesh in `mat`, or a blocking box with none.
func _along(a: Vector3, b: Vector3, w: float, h: float, lift: float, mat: Material = null) -> Node3D:
	var fwd := b - a
	var length := fwd.length()
	fwd /= length
	var right := fwd.cross(Vector3.UP)
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var up := right.cross(fwd)
	var xf := Transform3D(Basis(right, up, -fwd), (a + b) * 0.5 + up * (lift - h * 0.5))
	if mat:
		var mi := Kit.slab(_at, Vector3.ZERO, Vector3(w, h, length), mat)
		mi.transform = xf
		return mi
	var body := Kit.block(_at, Vector3.ZERO, Vector3(w, h, length))
	body.transform = xf
	return body


## A flight of stairs from `foot` up to `head` (straight along x or z), `w`
## wide: steps you see, each a block down to the floor in `mat` with a tread
## of `tread` on it, a slope to walk on, and blocks under it so nobody walks
## underneath.
func _stairs(foot: Vector3, head: Vector3, w: float, mat: String, tread: String) -> void:
	var rise := head.y - foot.y
	var run := Vector2(head.x - foot.x, head.z - foot.z)
	var length := run.length()
	var dir := run / length
	var across := Vector2(-dir.y, dir.x)
	var n := maxi(2, roundi(rise / 0.19))
	var g := length / n
	var r := rise / n
	for k in n:
		var top := (k + 0.5) * r
		var c := Vector2(foot.x, foot.z) + dir * (k + 0.5) * g
		var size := Vector3(absf(dir.x) * g + absf(across.x) * w, top, absf(dir.y) * g + absf(across.y) * w)
		_slab(Vector3(c.x, foot.y + top * 0.5, c.y), size, _mat(mat))
		_slab(Vector3(c.x, foot.y + top + 0.012, c.y), Vector3(size.x - absf(across.x) * 0.06, 0.025, size.z - absf(across.y) * 0.06), _mat(tread))
		var nose := c - dir * (g * 0.5 - 0.02)
		_slab(Vector3(nose.x, foot.y + top + 0.02, nose.y), Vector3(absf(dir.x) * 0.04 + absf(across.x) * (w - 0.06), 0.03, absf(dir.y) * 0.04 + absf(across.y) * (w - 0.06)), _mat("chrome"))
		if top > 0.35:
			_solid(Vector3(c.x, foot.y + (top - 0.25) * 0.5, c.y), Vector3(size.x, top - 0.25, size.z))
	var slope := (head - foot).normalized()
	_along(foot - slope * 0.6, head, w, 0.3, 0.0)


## A window through a wall: reveals from the room's face `depth` out to the
## other face, and the glass out there (blocking). `at` is its middle on the
## room's face, `facing` into the room, y0 to y1 on the deck.
func _win(at: Vector2, facing: Vector2, w: float, y0: float, y1: float, depth := 0.3) -> void:
	var along := Vector2(-facing.y, facing.x)
	var sz := func(a: float, hh: float, d: float) -> Vector3:
		return Vector3(absf(along.x) * a + absf(facing.x) * d, hh, absf(along.y) * a + absf(facing.y) * d)
	var mid := at - facing * depth * 0.5
	_slab(_v(mid, y0 - 0.02), sz.call(w + 0.04, 0.04, depth), _mat("lacquer"))
	_slab(_v(mid, y1 + 0.02), sz.call(w + 0.04, 0.04, depth), _mat("lacquer"))
	for side in [-1.0, 1.0]:
		_slab(_v(mid + along * side * (w * 0.5 + 0.02), (y0 + y1) * 0.5), sz.call(0.04, y1 - y0, depth), _mat("lacquer"))
	var glass := at - facing * (depth - 0.05)
	var g := _slab(_v(glass, (y0 + y1) * 0.5), sz.call(w, y1 - y0, 0.02), _mat("window"))
	g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid(_v(glass, (y0 + y1) * 0.5), sz.call(w, y1 - y0, 0.06))


## A run of the glass balustrade from `a` to `b` (on the deck), with a wall
## behind it a little taller than the rail.
func _rail(a: Vector2, b: Vector2) -> void:
	var length := a.distance_to(b)
	var u := (b - a) / length
	var n := maxi(1, ceili(length / 2.03 - 0.05))
	var yaw := atan2(-u.y, u.x)
	for i in n:
		var p := a + u * (i + 0.5) * length / n
		_m("marlin_rail", _v(p), yaw, Vector3(length / n / 2.03, 1.0, 1.0))
	var mid := (a + b) * 0.5
	_solid(_v(mid, 0.7), Vector3(absf(u.x) * length + absf(u.y) * 0.08, 1.4, absf(u.y) * length + absf(u.x) * 0.08))


## A chair you can't walk through, but whose seat leaves room above it.
func _chair(at: Vector3, yaw: float) -> void:
	_m("marlin_chair", at, yaw)
	_solid(at + Vector3(0.0, 0.25, 0.0), Vector3(0.5, 0.5, 0.5))


## A porthole on a wall's face, its middle at `y` on the deck.
func _porthole(at: Vector2, facing: Vector2, y: float) -> void:
	_m("marlin_porthole", _v(at, y - 0.21), atan2(facing.x, facing.y))


## A light set in the ceiling: a glowing disc, and its light.
func _downlight(at: Vector3, color: Color, energy: float, range_: float, shadow := false) -> OmniLight3D:
	_slab(at + Vector3(0.0, 0.02, 0.0), Vector3(0.16, 0.012, 0.16), _mat("led"))
	return _omni(at - Vector3(0.0, 0.3, 0.0), color, energy, range_, shadow)


static func _spot3(p: Vector3, dir: Vector2) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), p)


func _more_mat(name: String, m: StandardMaterial3D) -> bool:
	match name:
		"teak":
			_tex(m, "res://assets/textures/marlin/teak", 2.0, true)
			m.roughness = 0.55
		"hull_paint":
			m.albedo_color = Color(0.93, 0.94, 0.93)
			m.roughness = 0.2
		"lacquer":
			m.albedo_color = Color(0.92, 0.91, 0.88)
			m.roughness = 0.16
		"lacquer_dark":
			m.albedo_color = Color(0.05, 0.05, 0.055)
			m.roughness = 0.2
		"yacht_cream":
			m.albedo_color = Color(0.86, 0.82, 0.74)
			m.roughness = 0.85
		"veneer":
			m.albedo_color = Color(0.36, 0.22, 0.13)
			m.roughness = 0.35
		"carpet_sand":
			m.albedo_color = Color(0.7, 0.64, 0.54)
			m.roughness = 1.0
		"carpet_navy":
			m.albedo_color = Color(0.09, 0.12, 0.19)
			m.roughness = 1.0
		"rug_sand":
			m.albedo_color = Color(0.82, 0.77, 0.68)
			m.roughness = 1.0
		"crew_white":
			m.albedo_color = Color(0.85, 0.86, 0.86)
			m.roughness = 0.6
		"crew_floor":
			m.albedo_color = Color(0.36, 0.39, 0.42)
			m.roughness = 0.7
		"ceiling_white":
			m.albedo_color = Color(0.9, 0.9, 0.88)
			m.roughness = 0.9
		"bridge_grey":
			m.albedo_color = Color(0.3, 0.31, 0.33)
			m.roughness = 0.6
		"bridge_floor":
			m.albedo_color = Color(0.26, 0.27, 0.28)
			m.roughness = 0.9
		"safe_wall":
			m.albedo_color = Color(0.42, 0.44, 0.46)
			m.metallic = 0.6
			m.roughness = 0.45
		"chrome":
			m.albedo_color = Color(0.85, 0.86, 0.88)
			m.metallic = 1.0
			m.roughness = 0.08
		"window":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.02, 0.035, 0.045, 0.42)
			m.metallic = 0.5
			m.roughness = 0.03
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.6, 0.7, 0.72, 0.16)
			m.metallic = 0.3
			m.roughness = 0.03
		"water":
			m.albedo_color = Color(0.006, 0.02, 0.03)
			m.metallic = 0.25
			m.roughness = 0.07
			m.metallic_specular = 0.9
		"quay_wall":
			m.albedo_color = Color(0.2, 0.19, 0.18)
			m.roughness = 0.9
		"navy":
			m.albedo_color = Color(0.06, 0.09, 0.16)
			m.roughness = 0.5
		"rope":
			m.albedo_color = Color(0.8, 0.77, 0.68)
			m.roughness = 0.95
		"led":
			m.albedo_color = Color(1.0, 0.95, 0.85)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.9, 0.75)
			m.emission_energy_multiplier = 3.0
		"led_cool":
			m.albedo_color = Color(0.9, 0.95, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.85, 0.92, 1.0)
			m.emission_energy_multiplier = 2.0
		"led_strip":
			m.albedo_color = Color(1.0, 0.9, 0.7)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.82, 0.55)
			m.emission_energy_multiplier = 2.2
		"screen":
			m.albedo_color = Color(0.02, 0.03, 0.04)
			m.emission_enabled = true
			m.emission = Color(0.12, 0.3, 0.4)
			m.emission_energy_multiplier = 1.0
		"shore_light":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1.0, 0.78, 0.5)
		_:
			return false
	return true


## The Marlin's walls: "yacht" (cream panels over a veneer skirting, a veneer
## band at the top), "veneer" (walnut over a black skirting), "crew" (white
## laminate over grey), "skin" (the white outside), "bridge" (dark grey) and
## "steel" (the strongroom).
func _more_span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, h: float) -> void:
	match style:
		"yacht":
			if y0 < 0.1:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.1), _mat("veneer"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.1), minf(y1, h - 0.08), _mat("yacht_cream"), 0.02)
		"veneer":
			if y0 < 0.08:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.08), _mat("lacquer_dark"), 0.03)
			_face(a, u, facing, s0, s1, maxf(y0, 0.08), y1, _mat("veneer"), 0.02)
		"crew":
			if y0 < 0.1:
				_face(a, u, facing, s0, s1, y0, minf(y1, 0.1), _mat("crew_floor"), 0.025)
			_face(a, u, facing, s0, s1, maxf(y0, 0.1), y1, _mat("crew_white"), 0.015)
		"skin":
			_face(a, u, facing, s0, s1, y0, y1, _mat("hull_paint"), 0.02)
		"bridge":
			_face(a, u, facing, s0, s1, y0, y1, _mat("bridge_grey"), 0.02)
		"steel":
			_face(a, u, facing, s0, s1, y0, y1, _mat("safe_wall"), 0.02)


func _more_wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	match style:
		"yacht":
			_face(a, u, facing, 0.0, length, h - 0.08, h, _mat("veneer"), 0.035)
		"veneer":
			_face(a, u, facing, 0.0, length, h - 0.04, h, _mat("chrome"), 0.03)


# --- The sea, the quay and the city -----------------------------------------------------------

func _sea() -> void:
	_in("outside")
	# The water, with a hole where the crew's rooms sit below it in the hull.
	for r in [Rect2(-260.0, -300.0, 520.0, 268.9), Rect2(-260.0, -10.0, 520.0, 220.0),
			Rect2(-260.0, -31.1, 255.4, 21.1), Rect2(4.6, -31.1, 255.4, 21.1)]:
		var w := _slab(Vector3(r.get_center().x, SEA - 0.05, r.get_center().y), Vector3(r.size.x, 0.1, r.size.y), _mat("water"))
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.14
	moon.rotation_degrees = Vector3(-30.0, 200.0, 0.0)
	_at.add_child(moon)
	_probe(Rect2(-40.0, -40.0, 80.0, 70.0), 20.0, Color(0.12, 0.13, 0.18), 0.25)


func _quay() -> void:
	_in("outside")
	# The quay: concrete from its granite edge (z = 0) back to the road, on a
	# stone face down to the water.
	_floor(Rect2(-60.0, 0.5, 120.0, 13.5), "concrete")
	_floor(Rect2(-60.0, 0.0, 120.0, 0.5), "kerb")
	_solid(Vector3(0.0, -0.8, 7.0), Vector3(120.0, 1.6, 14.0))
	_slab(Vector3(0.0, -0.9, -0.05), Vector3(120.0, 1.8, 0.1), _mat("quay_wall"))
	# Nobody walks off the edge but up the gangway.
	_solid(Vector3(-30.3, 1.0, -0.1), Vector3(59.4, 2.6, 0.2))
	_solid(Vector3(30.3, 1.0, -0.1), Vector3(59.4, 2.6, 0.2))
	# The road behind the quay, and the far pavement.
	_slab(Vector3(0.0, -0.2, 17.5), Vector3(120.0, 0.1, 7.0), _mat("asphalt"))
	_solid(Vector3(0.0, -0.4, 17.5), Vector3(120.0, 0.5, 7.0))
	for kz in [14.12, 20.88]:
		_slab(Vector3(0.0, -0.07, kz), Vector3(120.0, 0.16, 0.24), _mat("kerb"))
	var x := -58.0
	while x < 60.0:
		_slab(Vector3(x + 1.5, -0.148, 17.5), Vector3(3.0, 0.006, 0.14), _mat("road_paint"))
		x += 7.0
	_floor(Rect2(-60.0, 21.0, 120.0, 3.0), "concrete")
	_solid(Vector3(0.0, -0.25, 22.5), Vector3(120.0, 0.5, 3.0))
	for ex in [-60.0, 60.0]:
		_solid(Vector3(ex, 3.0, 12.0), Vector3(0.4, 6.0, 24.0))
	# Lamps along the back of the quay and across the road.
	for lx in [-30.0, -18.0, -6.0, 6.0, 18.0, 30.0]:
		_lamp(Vector3(lx, 0.0, 13.4), absf(lx) < 20.0)
	for lx in [-24.0, -12.0, 12.0, 24.0]:
		_lamp(Vector3(lx, 0.0, 21.6), absf(lx) < 14.0)
	# Bollards, and the Marlin's lines to them.
	for bx in [-21.0, -11.5, -5.4, 5.4, 11.5, 21.0]:
		_box("marlin_bollard", Vector3(bx, 0.0, 0.7))
	for side in [-1.0, 1.0]:
		_along(Vector3(side * 4.3, 1.75, -2.4), Vector3(side * 5.4, 0.5, 0.7), 0.035, 0.035, 0.0175, _mat("rope"))
		_along(Vector3(side * 4.4, 1.75, -6.0), Vector3(side * 11.5, 0.5, 0.7), 0.035, 0.035, 0.0175, _mat("rope"))
	# The gangway, its gate on the quay and the rails round its foot.
	_m("marlin_gangway", Vector3(0.0, 0.0, 1.6))
	_ramp(Vector3(0.0, 0.0, 1.6), Vector3(0.0, MAIN, -2.2), 1.0)
	for side in [-1.0, 1.0]:
		_solid(Vector3(side * 0.56, 1.0, -0.3), Vector3(0.06, 2.8, 3.8))
	_m("marlin_gate_frame", Vector3(0.0, 0.0, 2.4))
	for side in [-1.0, 1.0]:
		_solid(Vector3(side * 1.12, 1.15, 2.4), Vector3(1.16, 2.3, 0.1))
		_m("marlin_rail", Vector3(side * 1.7, 0.0, 1.2), PI * 0.5, Vector3(1.2, 1.0, 1.0))
		_solid(Vector3(side * 1.7, 0.7, 1.2), Vector3(0.08, 1.4, 2.4))
	_sign("MARLIN", Vector3(0.0, 2.46, 2.47), 0.0, 56, Color(0.85, 0.7, 0.4), 0.004)
	_spot(Vector3(0.0, 2.55, 2.0), Vector3(0.0, 0.3, 0.2), WARM, 3.2, 7.0, 42.0, true)
	_omni(Vector3(0.0, 2.2, 3.4), WARM, 0.7, 5.0)
	# The purser's table, and the stores by the chandler's van.
	_box("marlin_trestle", Vector3(-4.6, 0.0, 3.8))
	_omni(Vector3(-4.0, 1.25, 3.7), CANDLE, 0.5, 3.0)
	_box("marlin_van", Vector3(9.0, 0.0, 5.6), PI * 0.5)
	_box("marlin_crates", Vector3(5.6, 0.0, 5.4))
	_box("marlin_crates", Vector3(6.9, 0.0, 7.6), 0.3)
	if night == "aboard":
		_use("stores", Vector3(5.6, 0.8, 5.4), Vector3(0.7, 0.62, 0.5), "marlin_crate")
		uses.stores.set_meta("use", "item:crate")
	_omni(Vector3(9.4, 2.6, 4.2), COOL, 0.5, 4.0)
	# Neighbors in the marina, and the breakwater's lights far off.
	for side in [-1.0, 1.0]:
		_no_shadow(_m("marlin_neighbor", Vector3(side * 16.0, 0.0, -2.6)))
		_no_shadow(_m("marlin_neighbor", Vector3(side * 30.0, 0.0, -3.0), 0.0, Vector3.ONE * 0.85))
		_no_shadow(_m("marlin_neighbor", Vector3(side * 43.0, 0.0, -3.0), 0.0, Vector3.ONE * 0.75))
	_slab(Vector3(0.0, -0.2, -135.0), Vector3(320.0, 2.6, 8.0), _mat("quay_wall"))
	var dots := []
	for i in 24:
		dots.append(Vector3(-150.0 + i * 13.0, 1.8, -134.0))
	_dots(dots, 0.35, SODIUM)
	_dots([Vector3(60.0, 4.0, -134.0)], 0.6, Color(1.0, 0.15, 0.1))
	_dots([Vector3(84.0, 4.0, -134.0)], 0.6, Color(0.1, 1.0, 0.3))


func _city() -> void:
	_in("outside")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1960
	_block(-60.0, -22.0, 24.0, true, 12.0, "white", rng)
	_block(-22.0, 14.0, 24.0, true, 15.0, "inset", rng)
	_block(14.0, 60.0, 24.0, true, 12.0, "double", rng)
	_sign("CALDERA MARINA", Vector3(-3.0, 3.35, 23.9), PI, 72, Color(0.9, 0.75, 0.45), 0.006)


## At sea: Caldera's lights on the shore behind the stern, a lighthouse, and
## nothing else.
func _coast() -> void:
	_in("outside")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1998
	var pts := []
	for i in 420:
		var x := rng.randf_range(-260.0, 260.0)
		var hill := 10.0 + 18.0 * sin(x * 0.012) + 8.0 * sin(x * 0.031 + 1.0)
		pts.append(Vector3(x, rng.randf() * maxf(2.0, hill) * rng.randf(), 175.0 + rng.randf_range(-6.0, 12.0)))
	_dots(pts, 0.45, SODIUM)
	var white := []
	for i in 90:
		white.append(Vector3(rng.randf_range(-120.0, 120.0), rng.randf() * 6.0, 172.0 + rng.randf() * 6.0))
	_dots(white, 0.4, Color(0.9, 0.92, 1.0))
	_dots([Vector3(-90.0, 14.0, 168.0)], 1.2, Color(1.0, 0.95, 0.8))
	# Out here nobody steps off the stern.
	_solid(Vector3(0.0, MAIN + 1.0, -2.1), Vector3(9.0, 2.6, 0.2))


## Little lights far off, all in one draw.
func _dots(pts: Array, size: float, color: Color) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color * 1.6
	box.material = m
	mm.mesh = box
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, pts[i]))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_at.add_child(mi)


## A sloped way to walk on from `bottom` to `top`.
func _ramp(bottom: Vector3, top: Vector3, w: float) -> void:
	var slope := (top - bottom).normalized()
	_along(bottom - slope * 0.4, top, w, 0.3, 0.0)


# --- The hull ---------------------------------------------------------------------------------

func _hull() -> void:
	_in("outside")
	_m("marlin_hull", Vector3.ZERO)
	_sign("MARLIN", Vector3(0.0, 0.42, -1.97), 0.0, 96, Color(0.8, 0.64, 0.34), 0.006)
	_sign("CALDERA", Vector3(0.0, -0.05, -1.97), 0.0, 40, Color(0.8, 0.64, 0.34), 0.006)
	# Lights under the swim platform, in the water.
	for x in [-2.6, 2.6]:
		_omni(Vector3(x, -0.95, -1.3), Color(0.35, 0.8, 1.0), 1.4, 5.0)
	# The mast on the hardtop.
	_m("marlin_mast", Vector3(0.0, UPPER + UPPER_H + 0.42, -26.0))


# --- Floors ------------------------------------------------------------------------------------

## What everyone stands on, deck by deck, with the stair wells left open.
func _floors() -> void:
	_in("crew_hall")
	_solid(Vector3(0.0, LOWER - 0.2, -20.55), Vector3(9.2, 0.4, 21.1))
	_in("saloon")
	for r in [Rect2(-4.8, -10.0, 9.6, 8.0), Rect2(-2.8, -16.25, 7.6, 6.25), Rect2(-4.8, -11.0, 2.0, 1.0),
			Rect2(-4.8, -38.6, 9.6, 22.35)]:
		var c: Vector2 = r.get_center()
		_solid(Vector3(c.x, MAIN - 0.25, c.y), Vector3(r.size.x, 0.5, r.size.y))
	_in("sky_lounge")
	for r in [Rect2(-4.8, -25.6, 8.0, 21.6), Rect2(3.2, -25.6, 1.6, 17.2), Rect2(-4.8, -31.2, 7.8, 5.6),
			Rect2(-4.8, -38.6, 9.6, 7.4)]:
		var c: Vector2 = r.get_center()
		_solid(Vector3(c.x, UPPER - 0.25, c.y), Vector3(r.size.x, 0.5, r.size.y))


# --- The lower deck ---------------------------------------------------------------------------

func _lower_deck() -> void:
	var h := LOWER_H
	# The crew's hall: a corridor down the middle, a passage to the stair.
	_on("crew_hall", LOWER)
	for r in [Rect2(-0.9, -31.0, 1.8, 15.65), Rect2(-4.5, -17.65, 3.6, 1.4), Rect2(-2.8, -16.25, 1.9, 0.9)]:
		_floor(r, "crew_floor")
		_ceiling(r.grow(-0.2), h, "ceiling_white")
	_wall("crew", Vector2(-2.8, -15.45), Vector2(0.8, -15.45), Vector2(0, -1), h, [], 0.1)
	_wall("crew", Vector2(-4.5, -16.25), Vector2(-4.5, -17.55), Vector2(1, 0), h, [], 0.1)
	_wall("crew", Vector2(-4.5, -17.55), Vector2(-0.9, -17.55), Vector2(0, 1), h, [], 0.1)
	_wall("crew", Vector2(-0.8, -17.55), Vector2(-0.8, -30.9), Vector2(1, 0), h,
			[{"at": -21.0, "w": 1.2, "h": 2.0}, {"at": -27.6, "w": 0.8, "h": 2.0}], 0.1)
	_wall("crew", Vector2(0.8, -30.9), Vector2(0.8, -15.45), Vector2(-1, 0), h,
			[{"at": -19.2, "w": 0.9, "h": 2.0}, {"at": -24.4, "w": 0.9, "h": 2.0}, {"at": -28.6, "w": 0.9, "h": 2.0}], 0.1)
	_wall("crew", Vector2(0.8, -30.9), Vector2(-0.8, -30.9), Vector2(0, 1), h, [], 0.1)
	# Doors nobody uses tonight: the engine room aft, the forepeak forward.
	_m("marlin_door_crew", Vector3(-0.45, 0.0, -15.47), PI)
	_sign("ENGINE ROOM\nCREW ONLY", Vector3(0.0, 2.05, -15.48), PI, 22, Color(0.75, 0.1, 0.1), 0.003)
	_m("marlin_door_crew", Vector3(0.45, 0.0, -30.88))
	_sign("FOREPEAK", Vector3(0.0, 2.05, -30.87), 0.0, 22, Color(0.2, 0.22, 0.25), 0.003)
	_m("notice_board", Vector3(-2.7, 1.1, -17.55), 0.0)
	clocks.append(_m("wall_clock", Vector3(-3.9, 1.65, -17.55)))
	for z in [-17.0, -22.0, -27.0, -30.0]:
		_slab(Vector3(0.0, h - 0.01, z), Vector3(0.5, 0.02, 0.3), _mat("led_cool"))
	for z in [-17.0, -23.0, -29.0]:
		_omni(Vector3(0.0, h - 0.3, z), COOL, 0.75, 5.0)
	_omni(Vector3(-3.2, h - 0.3, -16.9), COOL, 0.5, 3.5)
	_probe(Rect2(-4.5, -31.0, 5.4, 15.6), h, Color(0.42, 0.45, 0.48), 0.4)
	_reveal(Vector2(0.9, -19.2), Vector2(0, 1), 0.9, 2.0, 0.2, _mat("lacquer"))
	_reveal(Vector2(-0.9, -27.6), Vector2(0, 1), 0.8, 2.0, 0.2, _mat("lacquer"))
	_reveal(Vector2(0.9, -28.6), Vector2(0, 1), 0.9, 2.0, 0.2, _mat("lacquer"))
	_reveal(Vector2(0.9, -24.4), Vector2(0, 1), 0.9, 2.0, 0.2, _mat("lacquer"))
	_reveal(Vector2(-0.9, -21.0), Vector2(0, 1), 1.2, 2.0, 0.2, _mat("lacquer"))

	# The galley: the range on the hull side under its hood, the island, the
	# pass along the forward wall.
	_on("galley", LOWER)
	var g := Rect2(1.0, -22.5, 3.5, 7.05)
	_floor(g, "quarry")
	_ceiling(g, h, "ceiling_white")
	_wall("tile", Vector2(1.0, -15.45), Vector2(4.5, -15.45), Vector2(0, -1), h, [], 0.1)
	_wall("tile", Vector2(4.5, -15.45), Vector2(4.5, -22.5), Vector2(-1, 0), h, [], 0.3)
	_wall("tile", Vector2(4.5, -22.5), Vector2(1.0, -22.5), Vector2(0, 1), h, [], 0.1)
	_wall("tile", Vector2(1.0, -22.5), Vector2(1.0, -15.45), Vector2(1, 0), h, [{"at": -19.2, "w": 0.9, "h": 2.0}], 0.1)
	_box("kitchen_counter_wall", Vector3(4.15, 0.0, -16.5), -PI * 0.5)
	_box("kitchen_counter_wall", Vector3(4.15, 0.0, -18.5), -PI * 0.5)
	_box("range_stove", Vector3(4.07, 0.0, -20.15), -PI * 0.5)
	_slab(Vector3(4.05, 1.9, -20.15), Vector3(0.9, 0.5, 1.5), _mat("steel"))
	_slab(Vector3(4.05, 1.64, -20.15), Vector3(0.86, 0.02, 1.46), _mat("led_cool"))
	_box("pot_shelf", Vector3(4.25, 0.0, -21.7), -PI * 0.5)
	_box("kitchen_counter", Vector3(2.5, 0.0, -17.6), PI * 0.5)
	_box("kitchen_counter_wall", Vector3(2.0, 0.0, -22.15))
	_box("pot_shelf", Vector3(2.0, 0.0, -15.7), PI)
	_porthole(Vector2(4.5, -18.0), Vector2(-1, 0), 1.55)
	if night == "aboard":
		# Where the night's stores go, and the crate that turns up there.
		_use("stores_drop", Vector3(2.0, 0.9, -22.05), Vector3(1.3, 0.3, 0.5))
		var crate := _m("marlin_crate", Vector3(2.3, 0.92, -22.1), 0.2)
		crate.name = "GalleyCrate"
		crate.visible = false
	for z in [-17.0, -19.8]:
		_slab(Vector3(2.6, h - 0.01, z), Vector3(0.6, 0.02, 0.6), _mat("led_cool"))
		_omni(Vector3(2.6, h - 0.35, z), COOL, 0.9, 5.0)
	_probe(g, h, Color(0.45, 0.47, 0.48), 0.45)

	# The crew mess: the dinette on the hull side, a counter, a television.
	_on("mess", LOWER)
	var m := Rect2(-4.5, -24.3, 3.5, 6.55)
	_floor(m, "crew_floor")
	_ceiling(m, h, "ceiling_white")
	_wall("crew", Vector2(-1.0, -17.75), Vector2(-4.5, -17.75), Vector2(0, -1), h, [], 0.1)
	_wall("crew", Vector2(-4.5, -17.75), Vector2(-4.5, -24.3), Vector2(1, 0), h, [], 0.3)
	_wall("crew", Vector2(-4.5, -24.3), Vector2(-1.0, -24.3), Vector2(0, 1), h, [], 0.1)
	_wall("crew", Vector2(-1.0, -24.3), Vector2(-1.0, -17.75), Vector2(-1, 0), h, [{"at": -21.0, "w": 1.2, "h": 2.0}], 0.1)
	_box("marlin_dinette", Vector3(-3.55, 0.0, -21.6), PI * 0.5)
	_box("kitchen_counter_wall", Vector3(-2.75, 0.0, -18.1), PI)
	_slab(Vector3(-2.6, 1.35, -24.28), Vector3(1.1, 0.64, 0.04), _mat("lacquer_dark"))
	_slab(Vector3(-2.6, 1.35, -24.255), Vector3(1.02, 0.56, 0.01), _mat("screen"))
	for z in [-18.0, -20.6]:
		_porthole(Vector2(-4.5, z), Vector2(1, 0), 1.55)
	_slab(Vector3(-2.8, h - 0.01, -21.0), Vector3(0.6, 0.02, 0.6), _mat("led_cool"))
	_omni(Vector3(-2.8, h - 0.35, -21.0), WARM, 0.8, 5.0)
	_omni(Vector3(-2.6, 1.3, -23.8), Color(0.4, 0.6, 0.8), 0.25, 2.5)
	_probe(m, h, Color(0.42, 0.43, 0.45), 0.4)

	# The laundry.
	_on("laundry", LOWER)
	var l := Rect2(1.0, -26.1, 3.5, 3.4)
	_floor(l, "crew_floor")
	_ceiling(l, h, "ceiling_white")
	_wall("crew", Vector2(1.0, -22.7), Vector2(4.5, -22.7), Vector2(0, -1), h, [], 0.1)
	_wall("crew", Vector2(4.5, -22.7), Vector2(4.5, -26.1), Vector2(-1, 0), h, [], 0.3)
	_wall("crew", Vector2(4.5, -26.1), Vector2(1.0, -26.1), Vector2(0, 1), h, [], 0.1)
	_wall("crew", Vector2(1.0, -26.1), Vector2(1.0, -22.7), Vector2(1, 0), h, [{"at": -24.4, "w": 0.9, "h": 2.0}], 0.1)
	_box("marlin_washers", Vector3(4.17, 0.0, -24.4), -PI * 0.5)
	_box("kitchen_counter", Vector3(2.6, 0.0, -25.7))
	_box("service_trolley", Vector3(1.7, 0.0, -23.25))
	_omni(Vector3(2.6, h - 0.35, -24.4), COOL, 0.7, 4.0)
	_slab(Vector3(2.6, h - 0.01, -24.4), Vector3(0.6, 0.02, 0.6), _mat("led_cool"))
	_probe(l, h, Color(0.45, 0.46, 0.47), 0.4)

	# The crew's cabins: bunks, lockers. The starboard one locks from outside.
	for side in [-1.0, 1.0]:
		var zone := "cabin_a" if side < 0 else "cabin_b"
		_on(zone, LOWER)
		var aft := -24.5 if side < 0 else -26.3
		var inner := -1.0 if side < 0 else 1.0
		var r := Rect2(minf(inner, side * IN), -30.9, 3.5, 30.9 + aft)
		_floor(r, "carpet_navy")
		_ceiling(r, h, "ceiling_white")
		_wall("crew", Vector2(inner, aft), Vector2(side * IN, aft), Vector2(0, -1), h, [], 0.1)
		_wall("crew", Vector2(side * IN, aft), Vector2(side * IN, -30.9), Vector2(-side, 0), h, [], 0.3)
		_wall("crew", Vector2(side * IN, -30.9), Vector2(inner, -30.9), Vector2(0, 1), h, [], 0.1)
		_wall("crew", Vector2(inner, -30.9), Vector2(inner, aft), Vector2(side, 0), h,
				[{"at": -27.6 if side < 0 else -28.6, "w": 0.8 if side < 0 else 0.9, "h": 2.0}], 0.1)
		if side < 0:
			_box("marlin_bunks", Vector3(-4.075, 0.0, -27.0), PI * 0.5)
			_box("marlin_bunks", Vector3(-4.075, 0.0, -29.6), PI * 0.5)
			_box("lockers", Vector3(-2.3, 0.0, -24.75), PI)
		else:
			_box("marlin_bunks", Vector3(4.075, 0.0, -28.4), -PI * 0.5)
			_box("lockers", Vector3(2.9, 0.0, -30.65))
		_porthole(Vector2(side * IN, -30.2), Vector2(-side, 0), 1.55)
		_omni(Vector3(side * 2.6, h - 0.35, -28.2), WARM, 0.5, 4.0)
		_probe(r, h, Color(0.35, 0.36, 0.4), 0.35)


# --- The crew stair ---------------------------------------------------------------------------

## From the aft deck's crew door down to the crew's passage, in a well of its
## own on the port side.
func _crew_stair() -> void:
	_on("crew_stair", LOWER)
	var full := MAIN_H + MAIN - LOWER
	_floor(Rect2(-4.5, -16.25, 1.6, 0.9), "crew_floor")
	_wall("crew", Vector2(-4.5, -10.1), Vector2(-4.5, -16.25), Vector2(1, 0), full, [], 0.3)
	_wall("crew", Vector2(-2.9, -15.35), Vector2(-2.9, -10.1), Vector2(-1, 0), full, [], 0.1)
	_wall("crew", Vector2(-2.9, -10.1), Vector2(-4.5, -10.1), Vector2(0, -1), full,
			[{"at": -3.6, "w": 0.9, "y0": MAIN - LOWER, "h": MAIN - LOWER + 2.0}], 0.1)
	# Where the well opens onto the passage below, the deck's edge above.
	_slab(Vector3(-2.85, MAIN - LOWER - 0.25, -15.8), Vector3(0.1, 0.5, 0.9), _mat("crew_white"))
	_slab(Vector3(-3.7, MAIN - LOWER - 0.25, -16.2), Vector3(1.6, 0.5, 0.1), _mat("crew_white"))
	_on("crew_stair", MAIN)
	_floor(Rect2(-4.5, -11.0, 1.6, 0.9), "crew_floor")
	_ceiling(Rect2(-4.5, -16.25, 1.6, 6.15), MAIN_H, "ceiling_white")
	_wall("crew", Vector2(-2.9, -16.25), Vector2(-2.9, -15.35), Vector2(-1, 0), MAIN_H, [], 0.1)
	_wall("crew", Vector2(-4.5, -16.15), Vector2(-2.9, -16.15), Vector2(0, 1), MAIN_H, [], 0.1)
	_sign("CREW", Vector3(-3.6, 2.15, -10.12), PI, 28, Color(0.2, 0.22, 0.25), 0.003)
	_on("crew_stair", 0.0)
	_stairs(Vector3(-3.7, LOWER, -15.9), Vector3(-3.7, MAIN, -11.0), 1.4, "crew_white", "crew_floor")
	_along(Vector3(-4.42, LOWER + 0.9, -15.9), Vector3(-4.42, MAIN + 0.9, -11.0), 0.04, 0.04, 0.0, _mat("steel"))
	_along(Vector3(-2.98, LOWER + 0.9, -15.9), Vector3(-2.98, MAIN + 0.9, -11.0), 0.04, 0.04, 0.0, _mat("steel"))
	_omni(Vector3(-3.7, MAIN + 2.1, -11.0), COOL, 0.7, 4.5)
	_omni(Vector3(-3.7, MAIN - 0.3, -15.0), COOL, 0.6, 4.0)
	_slab(Vector3(-3.7, MAIN + MAIN_H - 0.01, -11.0), Vector3(0.4, 0.02, 0.3), _mat("led_cool"))
	_probe(Rect2(-4.5, -16.25, 1.6, 6.15), full, Color(0.42, 0.44, 0.46), 0.4)


# --- The main deck ----------------------------------------------------------------------------

func _aft_deck() -> void:
	_on("aft_deck", MAIN)
	var h := MAIN_H
	_floor(Rect2(-4.4, -10.0, 8.8, 8.0), "teak")
	# Bulwarks round the deck, white inside with a teak cap; the gangway's
	# gap in the transom on moored nights.
	for side in [-1.0, 1.0]:
		_wall("skin", Vector2(side * 4.4, -2.2), Vector2(side * 4.4, -9.9), Vector2(-side, 0), 1.0, [], 0.15)
		_slab(Vector3(side * 4.475, 1.03, -6.05), Vector3(0.21, 0.06, 7.9), _mat("teak"))
		_solid(Vector3(side * 4.47, 1.25, -6.0), Vector3(0.15, 2.5, 8.0))
		_m("marlin_lifering", Vector3(side * 2.9, 0.2, -2.2), PI)
	var gap := [{"at": 0.0, "w": 1.2, "h": 1.0}] if moored() else []
	_wall("skin", Vector2(4.4, -2.2), Vector2(-4.4, -2.2), Vector2(0, -1), 1.0, gap, 0.15)
	for x0 in ([-4.4, 0.6] if moored() else [-4.4]):
		var w := 3.8 if moored() else 8.8
		_slab(Vector3(x0 + w * 0.5, 1.03, -2.125), Vector3(w, 0.06, 0.21), _mat("teak"))
		_solid(Vector3(x0 + w * 0.5, 1.25, -2.12), Vector3(w, 2.5, 0.15))
	if not moored():
		_m("marlin_gate", Vector3(0.5, 0.0, -2.12), 0.0, Vector3(1.0, 0.5, 1.0))
	# Posts under the sun deck's overhang.
	for side in [-1.0, 1.0]:
		_slab(Vector3(side * 4.45, 1.75, -4.15), Vector3(0.12, 1.5, 0.12), _mat("hull_paint"))
	# The ceiling, open over the stair well to starboard.
	_ceiling(Rect2(-4.6, -10.0, 7.8, 6.0), h, "ceiling_white")
	_ceiling(Rect2(3.2, -10.0, 1.4, 1.6), h, "ceiling_white")
	# The saloon's aft wall, seen from out here.
	_wall("skin", Vector2(-SKIN, -9.9), Vector2(SKIN, -9.9), Vector2(0, 1), h,
			[{"at": -3.6, "w": 0.9, "h": 2.0}, {"at": -1.2, "w": 2.6, "h": 2.3, "y0": 0.5},
			{"at": 1.4, "w": 2.0, "h": 2.2}, {"at": 3.5, "w": 1.6, "h": 2.3, "y0": 0.5}], 0.1)
	_reveal(Vector2(-3.6, -10.0), Vector2(1, 0), 0.9, 2.0, 0.2, _mat("lacquer"))
	_reveal(Vector2(1.4, -10.0), Vector2(1, 0), 2.0, 2.2, 0.2, _mat("chrome"))
	# The bar on the port side, the lounge, the stair up to the sun deck.
	_box("marlin_bar", Vector3(-3.3, 0.0, -4.8), PI * 0.5)
	for z in [-4.3, -5.3]:
		_box("bar_stool", Vector3(-2.45, 0.0, z))
	_pendant(-3.3, -4.3, 1.75, h)
	_pendant(-3.3, -5.4, 1.75, h)
	_omni(Vector3(-3.7, 1.7, -4.8), CANDLE, 0.9, 3.5)
	_box("marlin_sofa", Vector3(-1.0, 0.0, -9.4))
	if night != "auction":
		_box("marlin_table", Vector3(-1.0, 0.0, -7.6))
		_box("marlin_armchair", Vector3(0.4, 0.0, -7.6), -PI * 0.5)
	else:
		_box("marlin_reg_desk", Vector3(-1.0, 0.0, -7.6))
		_use("paddle", Vector3(-1.0, 0.0, -7.6), Vector3(1.6, 1.0, 0.75))
		_sign("REGISTRATION", Vector3(-1.0, 0.86, -7.24), 0.0, 24, Color(0.92, 0.88, 0.78), 0.003)
	_on("aft_deck", 0.0)
	_stairs(Vector3(3.8, MAIN, -3.0), Vector3(3.8, UPPER, -8.4), 1.0, "hull_paint", "teak")
	_solid(Vector3(4.42, UPPER - 0.2, -5.7), Vector3(0.06, 4.0, 5.4))
	_along(Vector3(3.27, MAIN + 0.95, -3.0), Vector3(3.27, UPPER + 0.95, -8.4), 0.04, 0.04, 0.0, _mat("chrome"))
	_along(Vector3(3.27, MAIN + 0.9, -3.0), Vector3(3.27, UPPER + 0.9, -8.4), 0.012, 0.75, 0.0, _mat("glass"))
	_along(Vector3(3.27, MAIN + 1.0, -3.0), Vector3(3.27, UPPER + 1.0, -8.4), 0.06, 0.9, 0.0)
	_on("aft_deck", MAIN)
	_downlight(Vector3(0.5, h, -6.5), WARM, 1.5, 8.0, true)
	_downlight(Vector3(-2.2, h, -8.4), WARM, 0.5, 4.0)
	_downlight(Vector3(2.4, h, -8.4), WARM, 0.5, 4.0)
	_omni(Vector3(0.0, 2.0, -3.0), WARM, 0.6, 5.0)
	_probe(Rect2(-4.4, -10.0, 8.8, 8.0), h, Color(0.3, 0.3, 0.33), 0.35)


func _saloon() -> void:
	_on("saloon", MAIN)
	var h := MAIN_H
	var aft := Rect2(-2.7, -16.35, 7.2, 6.25)
	var fwd := Rect2(-4.5, -19.9, 9.0, 3.55)
	for r in [aft, fwd]:
		_floor(r, "carpet_sand")
		_ceiling(r, h, "ceiling_white")
	_wall("yacht", Vector2(-2.7, -10.1), Vector2(IN, -10.1), Vector2(0, -1), h,
			[{"at": -1.2, "w": 2.6, "h": 2.3, "y0": 0.5}, {"at": 1.4, "w": 2.0, "h": 2.2}, {"at": 3.5, "w": 1.6, "h": 2.3, "y0": 0.5}], 0.1)
	_wall("yacht", Vector2(-2.7, -16.35), Vector2(-2.7, -10.1), Vector2(1, 0), h, [], 0.1)
	_wall("yacht", Vector2(-IN, -16.35), Vector2(-2.7, -16.35), Vector2(0, -1), h, [], 0.1)
	_wall("yacht", Vector2(-IN, -19.9), Vector2(-IN, -16.35), Vector2(1, 0), h, [{"at": -18.1, "w": 2.8, "h": 2.3, "y0": 0.7}], 0.3)
	_wall("yacht", Vector2(IN, -19.9), Vector2(-IN, -19.9), Vector2(0, 1), h, [{"at": 2.2, "w": 1.8, "h": 2.2}], 0.1)
	_wall("yacht", Vector2(IN, -10.1), Vector2(IN, -19.9), Vector2(-1, 0), h, [{"at": -15.0, "w": 8.4, "h": 2.3, "y0": 0.7}], 0.3)
	_win(Vector2(-1.2, -10.1), Vector2(0, -1), 2.6, 0.5, 2.3, 0.2)
	_win(Vector2(3.5, -10.1), Vector2(0, -1), 1.6, 0.5, 2.3, 0.2)
	_win(Vector2(-IN, -18.1), Vector2(1, 0), 2.8, 0.7, 2.3)
	_win(Vector2(IN, -15.0), Vector2(-1, 0), 8.4, 0.7, 2.3)
	_reveal(Vector2(2.2, -20.0), Vector2(1, 0), 1.8, 2.2, 0.2, _mat("veneer"))
	# Light strips along the ceiling's edges.
	for x in [-2.6, 4.4]:
		_slab(Vector3(x, h - 0.03, -15.0), Vector3(0.03, 0.02, 9.6), _mat("led_strip"))
	match night:
		"auction":
			_auction_room()
		_:
			_lounge()
	_omni(Vector3(0.9, 2.15, -14.6), WARM, 1.3, 9.0, true)
	_omni(Vector3(-1.6, 2.15, -18.4), WARM, 0.8, 6.0)
	_probe(Rect2(-4.5, -19.9, 9.0, 9.8), h, Color(0.42, 0.38, 0.33), 0.4)


## The saloon as a lounge: sofas round a table by the starboard windows, a
## sideboard and a painting, and a second corner forward (where the Rose
## stands for the preview).
func _lounge() -> void:
	_m("rug", Vector3(2.4, 0.0, -14.0), PI * 0.5, Vector3(0.85, 1.0, 0.8))
	_box("marlin_sofa", Vector3(4.0, 0.0, -14.0), -PI * 0.5)
	_box("marlin_table", Vector3(2.4, 0.0, -14.0), PI * 0.5)
	for z in [-13.3, -14.7]:
		_box("marlin_armchair", Vector3(0.9, 0.0, z), PI * 0.5)
	_box("marlin_sideboard", Vector3(-2.47, 0.0, -13.2), PI * 0.5)
	_painting(Vector2(-2.7, -13.2), Vector2(1, 0), 1.6, 1.2, 1.07, "painting_coast")
	_box("marlin_sofa", Vector3(-2.4, 0.0, -19.4))
	if night == "safe":
		_box("marlin_case", Vector3(-2.4, 0.0, -17.6))
		_spot(Vector3(-2.4, MAIN_H - 0.05, -17.0), Vector3(-2.4, 1.1, -17.6), WARM, 3.0, 4.0, 22.0)
		_sign("THE ROSE OF CALDERA", Vector3(-2.4, 0.9, -17.29), 0.0, 18, Color(0.8, 0.64, 0.34), 0.002)
	else:
		_box("marlin_table", Vector3(-2.4, 0.0, -18.1))
		_box("marlin_armchair", Vector3(-2.4, 0.0, -16.95), PI)
	_box("floor_lamp", Vector3(-4.1, 0.0, -19.5))
	_omni(Vector3(-4.1, 1.55, -19.5), CANDLE, 0.6, 3.5)


## The saloon set out for the sale: rows of chairs facing the rostrum, the
## Rose in her case beside it, the telephone desk on the starboard side.
func _auction_room() -> void:
	for x in [-2.2, -1.6, -1.0, 0.9, 1.5, 2.1]:
		for z in [-13.2, -14.4, -15.6, -16.8]:
			_chair(Vector3(x, 0.0, z), PI)
	_box("marlin_rostrum", Vector3(-0.6, 0.0, -18.8))
	_use("rostrum", Vector3(-0.6, 0.0, -18.8), Vector3(0.96, 1.2, 0.7))
	_box("marlin_case", Vector3(-2.0, 0.0, -19.0))
	_spot(Vector3(-2.0, MAIN_H - 0.05, -18.4), Vector3(-2.0, 1.1, -19.0), WARM, 3.0, 4.0, 22.0)
	_sign("ASHCOMBE & VALE", Vector3(-0.6, 2.05, -19.86), 0.0, 40, Color(0.8, 0.64, 0.34), 0.004)
	_sign("Lot 1  The Rose of Caldera", Vector3(-0.6, 1.8, -19.86), 0.0, 22, Color(0.25, 0.2, 0.15), 0.003)
	_box("office_desk", Vector3(3.35, 0.0, -17.2), -PI * 0.5)
	_m("desk_lamp", Vector3(3.2, 0.76, -16.6))
	_omni(Vector3(3.3, 1.2, -16.6), CANDLE, 0.4, 2.5)
	_box("marlin_sideboard", Vector3(4.27, 0.0, -11.4), -PI * 0.5)


func _dining() -> void:
	_on("dining", MAIN)
	var h := MAIN_H
	var r := Rect2(-IN, -24.9, 9.0, 4.8)
	_floor(r, "parquet")
	_ceiling(r, h, "ceiling_white")
	_wall("veneer", Vector2(-IN, -20.1), Vector2(IN, -20.1), Vector2(0, -1), h, [{"at": 2.2, "w": 1.8, "h": 2.2}], 0.1)
	_wall("veneer", Vector2(-IN, -24.9), Vector2(-IN, -20.1), Vector2(1, 0), h, [{"at": -22.5, "w": 3.6, "h": 2.3, "y0": 0.9}], 0.3)
	_wall("veneer", Vector2(IN, -20.1), Vector2(IN, -24.9), Vector2(-1, 0), h, [{"at": -22.5, "w": 3.6, "h": 2.3, "y0": 0.9}], 0.3)
	_wall("veneer", Vector2(IN, -24.9), Vector2(-IN, -24.9), Vector2(0, 1), h, [{"at": 2.6, "w": 1.2, "h": 2.2}], 0.1)
	_win(Vector2(-IN, -22.5), Vector2(1, 0), 3.6, 0.9, 2.3)
	_win(Vector2(IN, -22.5), Vector2(-1, 0), 3.6, 0.9, 2.3)
	_reveal(Vector2(2.6, -25.0), Vector2(1, 0), 1.2, 2.2, 0.2, _mat("veneer"))
	_m("marlin_dining_table", Vector3(-0.4, 0.0, -22.5))
	for i in 5:
		var x := -2.0 + i * 0.8
		_m("marlin_chair", Vector3(x, 0.0, -21.65), PI)
		_m("marlin_chair", Vector3(x, 0.0, -23.35))
	_solid(Vector3(-0.4, 0.5, -22.5), Vector3(4.4, 1.0, 2.4))
	_box("marlin_sideboard", Vector3(-4.27, 0.0, -22.5), PI * 0.5)
	_box("marlin_sideboard", Vector3(4.27, 0.0, -22.5), -PI * 0.5)
	_painting(Vector2(-1.4, -24.9), Vector2(0, 1), 1.8, 1.0, 1.2, "painting_valley")
	for x in [-1.5, 0.7]:
		_pendant(x, -22.5, 1.55, h)
	_omni(Vector3(-0.4, 1.9, -22.5), CANDLE, 1.0, 6.0)
	_probe(r, h, Color(0.38, 0.3, 0.24), 0.4)


func _lobby() -> void:
	_on("lobby", MAIN)
	var h := MAIN_H
	var r := Rect2(-IN, -31.1, 9.0, 6.0)
	_floor(r, "marble_floor")
	_ceiling(Rect2(-IN, -31.1, 7.5, 6.0), h, "ceiling_white")
	_ceiling(Rect2(3.0, -25.6, 1.5, 0.5), h, "ceiling_white")
	_wall("yacht", Vector2(-IN, -25.1), Vector2(IN, -25.1), Vector2(0, -1), h, [{"at": 2.6, "w": 1.2, "h": 2.2}], 0.1)
	_wall("yacht", Vector2(-IN, -31.1), Vector2(-IN, -25.1), Vector2(1, 0), h, [{"at": -28.2, "w": 3.0, "h": 2.3, "y0": 0.8}], 0.3)
	_wall("yacht", Vector2(IN, -31.1), Vector2(-IN, -31.1), Vector2(0, 1), h, [], 0.1)
	_wall("yacht", Vector2(IN, -25.1), Vector2(IN, -31.1), Vector2(-1, 0), h, [], 0.3)
	_win(Vector2(-IN, -28.2), Vector2(1, 0), 3.0, 0.8, 2.3)
	# The owner's suite, forward, its doors shut.
	_m("marlin_door", Vector3(-2.0, 0.0, -31.07), PI, Vector3(0.889, 1.0, 1.0))
	_m("marlin_door", Vector3(-0.4, 0.0, -31.07), 0.0, Vector3(0.889, 1.0, 1.0))
	_sign("OWNER'S SUITE", Vector3(-1.2, 2.28, -31.06), 0.0, 22, Color(0.7, 0.55, 0.3), 0.003)
	# The guest stair up to the captain's deck, with glass on its open side.
	_on("lobby", 0.0)
	_stairs(Vector3(3.8, MAIN, -25.8), Vector3(3.8, UPPER, -31.2), 1.3, "lacquer", "carpet_navy")
	_along(Vector3(3.12, MAIN + 0.95, -25.8), Vector3(3.12, UPPER + 0.95, -31.2), 0.04, 0.04, 0.0, _mat("chrome"))
	_along(Vector3(3.12, MAIN + 0.9, -25.8), Vector3(3.12, UPPER + 0.9, -31.2), 0.012, 0.75, 0.0, _mat("glass"))
	_along(Vector3(3.12, MAIN + 1.0, -25.8), Vector3(3.12, UPPER + 1.0, -31.2), 0.06, 0.9, 0.0)
	_on("lobby", MAIN)
	# The upper deck's edge round the stair well.
	_slab(Vector3(3.0, h + 0.25, -28.4), Vector3(0.06, 0.5, 5.6), _mat("lacquer"))
	_slab(Vector3(3.75, h + 0.25, -25.6), Vector3(1.5, 0.5, 0.06), _mat("lacquer"))
	_box("marlin_sculpture", Vector3(-1.6, 0.0, -28.1))
	_spot(Vector3(-1.0, h - 0.05, -27.4), Vector3(-1.6, 1.6, -28.1), WARM, 2.2, 4.0, 25.0)
	_box("marlin_sideboard", Vector3(1.4, 0.0, -30.87))
	_slab(Vector3(1.4, 1.65, -31.08), Vector3(1.4, 0.9, 0.02), _mat("mirror"))
	_omni(Vector3(0.0, 2.15, -28.0), WARM, 0.9, 6.0)
	_slab(Vector3(0.0, h - 0.01, -28.0), Vector3(0.5, 0.02, 0.5), _mat("led"))
	_probe(r, h, Color(0.42, 0.4, 0.36), 0.4)


# --- The upper deck ---------------------------------------------------------------------------

func _sun_deck() -> void:
	_on("sun_deck", UPPER)
	_floor(Rect2(-4.7, -14.0, 7.9, 10.0), "teak")
	_floor(Rect2(3.2, -14.0, 1.5, 5.6), "teak")
	_rail(Vector2(-4.7, -4.0), Vector2(4.7, -4.0))
	_rail(Vector2(-4.7, -4.0), Vector2(-4.7, -14.0))
	_rail(Vector2(4.7, -4.0), Vector2(4.7, -14.0))
	_rail(Vector2(3.2, -4.0), Vector2(3.2, -8.4))
	_box("marlin_spa", Vector3(-1.6, 0.0, -7.0))
	_omni(Vector3(-1.6, 1.0, -7.0), Color(0.3, 0.85, 0.95), 0.9, 4.0)
	for x in [-3.7, -2.8, -1.9]:
		_box("marlin_lounger", Vector3(x, 0.0, -11.5))
	_box("marlin_table", Vector3(2.2, 0.0, -11.8))
	_box("marlin_armchair", Vector3(2.2, 0.0, -10.75), PI)
	_box("marlin_armchair", Vector3(2.2, 0.0, -12.85))
	for p in [Vector2(-4.4, -4.3), Vector2(4.4, -13.7), Vector2(-4.4, -13.7), Vector2(0.4, -4.3)]:
		_slab(_v(p, 0.2), Vector3(0.1, 0.4, 0.1), _mat("hull_paint"))
		_slab(_v(p, 0.36), Vector3(0.11, 0.05, 0.11), _mat("led"))
	_omni(Vector3(1.0, 2.2, -9.0), WARM, 0.8, 7.0)
	_omni(Vector3(-2.8, 1.6, -12.0), WARM, 0.5, 4.0)
	_probe(Rect2(-4.7, -14.0, 9.4, 10.0), 3.0, Color(0.25, 0.26, 0.3), 0.3)


func _sky_lounge() -> void:
	_on("sky_lounge", UPPER)
	var h := UPPER_H
	var r := Rect2(-IN, -20.7, 9.0, 6.6)
	_floor(r, "carpet_sand")
	_ceiling(r, h, "ceiling_white")
	_wall("yacht", Vector2(IN, -14.1), Vector2(-IN, -14.1), Vector2(0, -1), h,
			[{"at": 0.0, "w": 1.0, "h": 2.2}, {"at": -2.6, "w": 3.0, "h": 2.2, "y0": 0.6}, {"at": 2.6, "w": 3.0, "h": 2.2, "y0": 0.6}], 0.1)
	_wall("yacht", Vector2(-IN, -14.1), Vector2(-IN, -20.7), Vector2(1, 0), h, [{"at": -17.5, "w": 5.6, "h": 2.2, "y0": 0.7}], 0.3)
	_wall("yacht", Vector2(IN, -20.7), Vector2(IN, -14.1), Vector2(-1, 0), h, [{"at": -17.5, "w": 5.6, "h": 2.2, "y0": 0.7}], 0.3)
	_wall("yacht", Vector2(-IN, -20.7), Vector2(IN, -20.7), Vector2(0, 1), h, [{"at": 2.7, "w": 1.2, "h": 2.2}], 0.1)
	for x in [-2.6, 2.6]:
		_win(Vector2(x, -14.1), Vector2(0, -1), 3.0, 0.6, 2.2, 0.2)
	_win(Vector2(-IN, -17.5), Vector2(1, 0), 5.6, 0.7, 2.2)
	_win(Vector2(IN, -17.5), Vector2(-1, 0), 5.6, 0.7, 2.2)
	_reveal(Vector2(2.7, -20.8), Vector2(1, 0), 1.2, 2.2, 0.2, _mat("veneer"))
	_reveal(Vector2(0.0, -14.0), Vector2(1, 0), 1.0, 2.2, 0.2, _mat("chrome"))
	_box("marlin_sofa", Vector3(-4.0, 0.0, -17.4), PI * 0.5)
	_box("marlin_table", Vector3(-2.6, 0.0, -17.4), PI * 0.5)
	for z in [-16.8, -18.0]:
		_box("marlin_armchair", Vector3(-1.3, 0.0, z), -PI * 0.5)
	_box("marlin_sideboard", Vector3(4.27, 0.0, -17.4), -PI * 0.5)
	_m("rug", Vector3(-2.6, 0.0, -17.4), PI * 0.5, Vector3(0.8, 1.0, 0.75))
	_painting(Vector2(-1.4, -20.7), Vector2(0, 1), 1.6, 1.0, 1.07, "painting_caldera")
	_omni(Vector3(-1.4, 2.05, -17.4), WARM, 1.0, 7.0)
	_omni(Vector3(3.0, 2.05, -17.4), WARM, 0.6, 5.0)
	_slab(Vector3(-1.4, h - 0.01, -17.4), Vector3(0.5, 0.02, 0.5), _mat("led"))
	_probe(r, h, Color(0.4, 0.37, 0.33), 0.4)


func _upper_hall() -> void:
	_on("upper_hall", UPPER)
	var h := UPPER_H
	_floor(Rect2(1.1, -32.9, 3.4, 12.0), "carpet_navy")
	_ceiling(Rect2(1.1, -32.9, 3.4, 12.0), h, "ceiling_white")
	_wall("yacht", Vector2(IN, -20.9), Vector2(1.1, -20.9), Vector2(0, -1), h, [{"at": 2.7, "w": 1.2, "h": 2.2}], 0.1)
	_wall("yacht", Vector2(1.1, -20.9), Vector2(1.1, -32.9), Vector2(1, 0), h, [{"at": -22.4, "w": 0.9, "h": 2.1}], 0.1)
	_wall("yacht", Vector2(1.1, -32.9), Vector2(IN, -32.9), Vector2(0, 1), h, [{"at": 2.2, "w": 0.9, "h": 2.1}], 0.1)
	_wall("yacht", Vector2(IN, -32.9), Vector2(IN, -20.9), Vector2(-1, 0), h, [{"at": -23.0, "w": 2.0, "h": 2.2, "y0": 0.8}], 0.3)
	_win(Vector2(IN, -23.0), Vector2(-1, 0), 2.0, 0.8, 2.2)
	_reveal(Vector2(1.0, -22.4), Vector2(0, 1), 0.9, 2.1, 0.2, _mat("veneer"))
	_reveal(Vector2(2.2, -33.0), Vector2(1, 0), 0.9, 2.1, 0.2, _mat("veneer"))
	# Glass round the stair well.
	_rail(Vector2(2.95, -25.6), Vector2(2.95, -31.2))
	_rail(Vector2(2.95, -25.6), Vector2(IN, -25.6))
	_painting(Vector2(1.1, -27.4), Vector2(1, 0), 1.2, 1.0, 1.0, "painting_coast")
	for z in [-22.5, -28.0, -31.8]:
		_slab(Vector3(2.0, h - 0.01, z), Vector3(0.18, 0.02, 0.18), _mat("led"))
	_omni(Vector3(2.2, 2.0, -23.0), WARM, 0.6, 5.0)
	_omni(Vector3(2.2, 2.0, -30.0), WARM, 0.6, 5.0)
	_probe(Rect2(1.1, -32.9, 3.4, 12.0), h, Color(0.38, 0.36, 0.34), 0.4)


func _captain() -> void:
	_on("captain", UPPER)
	var h := UPPER_H
	_floor(Rect2(-IN, -30.5, 5.4, 9.6), "carpet_navy")
	_ceiling(Rect2(-IN, -30.5, 5.4, 9.6), h, "ceiling_white")
	_wall("veneer", Vector2(0.9, -20.9), Vector2(-IN, -20.9), Vector2(0, -1), h, [], 0.1)
	_wall("veneer", Vector2(-IN, -20.9), Vector2(-IN, -30.5), Vector2(1, 0), h, [{"at": -25.6, "w": 5.6, "h": 2.2, "y0": 0.8}], 0.3)
	_wall("veneer", Vector2(0.9, -29.6), Vector2(0.9, -20.9), Vector2(-1, 0), h, [{"at": -22.4, "w": 0.9, "h": 2.1}], 0.1)
	# The strongroom's wall and the bathroom's, forward.
	_wall("veneer", Vector2(-IN, -30.5), Vector2(-2.05, -30.5), Vector2(0, 1), h, [{"at": -3.25, "w": 0.9, "h": 2.0}], 0.1)
	_wall("veneer", Vector2(-2.05, -30.5), Vector2(-2.05, -29.6), Vector2(1, 0), h, [], 0.1)
	_wall("veneer", Vector2(-2.05, -29.6), Vector2(0.9, -29.6), Vector2(0, 1), h, [{"at": -0.5, "w": 0.8, "h": 2.1}], 0.1)
	_win(Vector2(-IN, -25.6), Vector2(1, 0), 5.6, 0.8, 2.2)
	_reveal(Vector2(-3.25, -30.6), Vector2(1, 0), 0.9, 2.0, 0.2, _mat("steel"))
	_reveal(Vector2(-0.5, -29.7), Vector2(1, 0), 0.8, 2.1, 0.2, _mat("veneer"))
	# The bed against the aft wall, the desk under the window, and the model
	# of his first boat on the credenza.
	_box("marlin_bed", Vector3(-2.2, 0.0, -22.0), PI)
	for x in [-3.55, -0.85]:
		_box("side_table", Vector3(x, 0.0, -21.25))
		_m("desk_lamp", Vector3(x, 0.55, -21.15))
	_omni(Vector3(-3.55, 0.95, -21.3), CANDLE, 0.4, 2.5)
	_box("office_desk", Vector3(-4.1, 0.0, -26.4), PI * 0.5)
	_box("office_chair", Vector3(-3.3, 0.0, -26.4), -PI * 0.5)
	_m("desk_lamp", Vector3(-4.25, 0.76, -25.8))
	_box("marlin_armchair", Vector3(-4.0, 0.0, -28.75), PI * 0.5)
	_box("marlin_sideboard", Vector3(0.67, 0.0, -26.5), -PI * 0.5)
	_m("marlin_neighbor", Vector3(0.67, 0.8, -26.5 + 0.36), PI * 0.5, Vector3.ONE * 0.02)
	_sign("KESTREL  1998", Vector3(0.43, 0.84, -26.5), -PI * 0.5, 16, Color(0.8, 0.64, 0.34), 0.002)
	_painting(Vector2(-1.3, -20.9), Vector2(0, -1), 1.4, 1.35, 0.9, "painting_coast")
	_omni(Vector3(-1.8, 2.0, -25.2), WARM, 1.1, 7.0, true)
	_slab(Vector3(-1.8, h - 0.01, -25.2), Vector3(0.5, 0.02, 0.5), _mat("led"))
	_probe(Rect2(-IN, -30.5, 5.4, 9.6), h, Color(0.36, 0.33, 0.3), 0.4)
	# The captain's bathroom.
	var b := Rect2(-1.85, -32.9, 2.75, 3.2)
	_floor(b, "marble_floor")
	_ceiling(b, h, "ceiling_white")
	_wall("yacht", Vector2(0.9, -29.8), Vector2(-1.85, -29.8), Vector2(0, -1), h, [{"at": -0.5, "w": 0.8, "h": 2.1}], 0.1)
	_wall("yacht", Vector2(-1.85, -29.8), Vector2(-1.85, -32.9), Vector2(1, 0), h, [], 0.1)
	_wall("yacht", Vector2(-1.85, -32.9), Vector2(0.9, -32.9), Vector2(0, 1), h, [], 0.1)
	_wall("yacht", Vector2(0.9, -32.9), Vector2(0.9, -29.8), Vector2(-1, 0), h, [], 0.1)
	_slab(Vector3(-0.5, 0.42, -32.65), Vector3(1.4, 0.84, 0.5), _mat("veneer"))
	_slab(Vector3(-0.5, 0.87, -32.65), Vector3(1.44, 0.06, 0.54), _mat("black_marble"))
	_solid(Vector3(-0.5, 0.45, -32.65), Vector3(1.4, 0.9, 0.5))
	_slab(Vector3(-0.5, 1.55, -32.89), Vector3(1.3, 0.9, 0.02), _mat("mirror"))
	_slab(Vector3(0.45, 1.1, -31.3), Vector3(0.02, 2.0, 1.2), _mat("glass"))
	_solid(Vector3(0.45, 1.1, -31.3), Vector3(0.05, 2.2, 1.2))
	_omni(Vector3(-0.5, 2.0, -31.8), WARM, 0.6, 4.0)
	# The strongroom: steel walls, the safe in the corner.
	_on("safe", UPPER)
	var s := Rect2(-IN, -32.9, 2.45, 2.2)
	_floor(s, "steel")
	_ceiling(s, h, "ceiling_white")
	_wall("steel", Vector2(-2.05, -30.7), Vector2(-IN, -30.7), Vector2(0, -1), h, [{"at": -3.25, "w": 0.9, "h": 2.0}], 0.1)
	_wall("steel", Vector2(-IN, -30.7), Vector2(-IN, -32.9), Vector2(1, 0), h, [], 0.3)
	_wall("steel", Vector2(-IN, -32.9), Vector2(-2.05, -32.9), Vector2(0, 1), h, [], 0.1)
	_wall("steel", Vector2(-2.05, -32.9), Vector2(-2.05, -30.7), Vector2(-1, 0), h, [], 0.1)
	# The safe stands open; its box and door block, and the shelf stays in reach.
	_m("marlin_safe_cabinet", Vector3(-4.03, 0.0, -32.6))
	_solid(Vector3(-4.03, 0.7, -32.6), Vector3(0.8, 1.4, 0.55))
	_solid_turned(Vector3(-4.36, 0.7, -31.94), Vector3(0.08, 1.4, 0.78), 0.1745)
	if night == "safe":
		_use("safe_shelf", Vector3(-4.03, 0.92, -32.45), Vector3(0.5, 0.3, 0.5), "marlin_file")
		uses.safe_shelf.set_meta("use", "item:auction_file")
	_omni(Vector3(-3.3, 2.0, -31.6), COOL, 0.9, 3.5)
	_slab(Vector3(-3.3, h - 0.01, -31.8), Vector3(0.3, 0.02, 0.3), _mat("led_cool"))
	# The keypad by the strongroom door, on the cabin's side.
	_on("captain", UPPER)
	_m("keypad", Vector3(-2.45, 1.15, -30.47))
	_use("safe_keypad", Vector3(-2.45, 1.05, -30.45), Vector3(0.2, 0.3, 0.1))


func _bridge() -> void:
	_on("bridge", UPPER)
	var h := UPPER_H
	var r := Rect2(-IN, -38.4, 9.0, 5.3)
	_floor(r, "bridge_floor")
	_ceiling(r, h, "bridge_grey")
	_wall("bridge", Vector2(-IN, -33.1), Vector2(IN, -33.1), Vector2(0, -1), h, [{"at": 2.2, "w": 0.9, "h": 2.1}], 0.1)
	_wall("bridge", Vector2(-IN, -38.4), Vector2(-IN, -33.1), Vector2(1, 0), h, [{"at": -35.6, "w": 3.6, "h": 2.2, "y0": 0.9}], 0.3)
	_wall("bridge", Vector2(IN, -33.1), Vector2(IN, -38.4), Vector2(-1, 0), h, [{"at": -35.6, "w": 3.6, "h": 2.2, "y0": 0.9}], 0.3)
	_wall("bridge", Vector2(IN, -38.4), Vector2(-IN, -38.4), Vector2(0, 1), h, [{"at": 0.0, "w": 8.6, "h": 2.2, "y0": 0.95}], 0.2)
	_win(Vector2(-IN, -35.6), Vector2(1, 0), 3.6, 0.9, 2.2)
	_win(Vector2(IN, -35.6), Vector2(-1, 0), 3.6, 0.9, 2.2)
	_win(Vector2(0.0, -38.4), Vector2(0, 1), 8.6, 0.95, 2.2, 0.2)
	_box("marlin_helm", Vector3(0.0, 0.0, -37.45))
	for x in [-0.8, 0.8]:
		_box("marlin_helm_chair", Vector3(x, 0.0, -36.45), PI)
	_box("marlin_chart_table", Vector3(4.08, 0.0, -34.0), -PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(-2.5, 1.7, -33.1), PI))
	_omni(Vector3(0.0, 1.3, -36.8), Color(0.4, 0.75, 0.9), 0.9, 4.5)
	_omni(Vector3(3.9, 1.4, -34.0), CANDLE, 0.7, 3.5)
	_omni(Vector3(0.0, 2.1, -34.6), Color(0.85, 0.3, 0.25), 0.45, 6.0)
	_omni(Vector3(-2.6, 2.0, -34.2), WARM, 0.5, 5.0)
	_omni(Vector3(1.6, 1.6, -34.0), WARM, 0.35, 4.0)
	_omni(Vector3(0.0, 2.2, -35.4), WARM, 0.45, 5.5)
	_probe(r, h, Color(0.26, 0.28, 0.32), 0.5)


# --- The outside of the house ------------------------------------------------------------------

## The white house over the hull: its sides with their windows, the front,
## the hardtop over the upper deck and the sun deck's edge over the aft deck.
func _house() -> void:
	_on("outside", MAIN)
	var mh := UPPER - MAIN
	for side in [-1.0, 1.0]:
		var a := Vector2(side * SKIN, -9.9)
		var b := Vector2(side * SKIN, -38.6)
		var holes := [{"at": -22.5, "w": 3.6, "h": 2.3, "y0": 0.9}]
		if side < 0:
			holes += [{"at": -18.1, "w": 2.8, "h": 2.3, "y0": 0.7}, {"at": -28.2, "w": 3.0, "h": 2.3, "y0": 0.8}]
		else:
			holes += [{"at": -15.0, "w": 8.4, "h": 2.3, "y0": 0.7}]
		_wall("skin", a if side > 0 else b, b if side > 0 else a, Vector2(side, 0), mh, holes, 0.02)
		# The owner's suite's windows, dark tonight.
		_slab(Vector3(side * (SKIN + 0.01), 1.5, -34.5), Vector3(0.02, 1.4, 5.0), _mat("night_glass"))
		# A stainless band along the deck line.
		_slab(Vector3(side * (SKIN + 0.015), mh - 0.02, -24.25), Vector3(0.03, 0.04, 28.7), _mat("chrome"))
	_wall("skin", Vector2(SKIN, -38.6), Vector2(-SKIN, -38.6), Vector2(0, -1), mh, [], 0.02)
	_slab(Vector3(0.0, 1.5, -38.62), Vector3(6.0, 1.2, 0.02), _mat("night_glass"))
	_on("outside", UPPER)
	var uh := UPPER_H + 0.5
	for side in [-1.0, 1.0]:
		var a := Vector2(side * SKIN, -14.0)
		var b := Vector2(side * SKIN, -38.6)
		var holes := [{"at": -17.5, "w": 5.6, "h": 2.2, "y0": 0.7}, {"at": -35.6, "w": 3.6, "h": 2.2, "y0": 0.9}]
		holes.append({"at": -25.6, "w": 5.6, "h": 2.2, "y0": 0.8} if side < 0 else {"at": -23.0, "w": 2.0, "h": 2.2, "y0": 0.8})
		_wall("skin", a if side > 0 else b, b if side > 0 else a, Vector2(side, 0), uh, holes, 0.02)
	_wall("skin", Vector2(SKIN, -38.6), Vector2(-SKIN, -38.6), Vector2(0, -1), uh, [{"at": 0.0, "w": 8.6, "h": 2.2, "y0": 0.95}], 0.02)
	# The sky lounge's aft face, from the sun deck.
	_on("sun_deck", UPPER)
	_wall("skin", Vector2(-SKIN, -13.9), Vector2(SKIN, -13.9), Vector2(0, 1), uh,
			[{"at": 0.0, "w": 1.0, "h": 2.2}, {"at": -2.6, "w": 3.0, "h": 2.2, "y0": 0.6}, {"at": 2.6, "w": 3.0, "h": 2.2, "y0": 0.6}], 0.1)
	# The hardtop over the house, overhanging the sun deck a little.
	_on("outside", UPPER)
	_slab(Vector3(0.0, UPPER_H + 0.27, -26.1), Vector3(9.8, 0.3, 25.0), _mat("hull_paint"))
	_slab(Vector3(0.0, UPPER_H + 0.11, -13.8), Vector3(9.6, 0.02, 0.3), _mat("ceiling_white"))
	for x in [-2.0, 2.0]:
		_slab(Vector3(x, UPPER_H + 0.1, -13.75), Vector3(0.16, 0.012, 0.16), _mat("led"))
	# The sun deck's slab over the aft deck, seen from the quay.
	_on("outside", 0.0)
	var between := UPPER - MAIN - MAIN_H - 0.04
	_slab(Vector3(-0.8, (UPPER + MAIN + MAIN_H) * 0.5, -7.0), Vector3(8.0, between, 6.0), _mat("hull_paint"))
	_slab(Vector3(4.0, (UPPER + MAIN + MAIN_H) * 0.5, -9.2), Vector3(1.6, between, 1.6), _mat("hull_paint"))
	_slab(Vector3(0.0, UPPER - 0.02, -4.02), Vector3(9.6, 0.04, 0.04), _mat("chrome"))


# --- Doors ------------------------------------------------------------------------------------

func _doors() -> void:
	var specs := {
		"crew": {"at": Vector2(-3.6, -10.0), "w": 0.9, "h": 2.0, "to": Vector2(0, -1), "model": "marlin_door_crew", "y": MAIN},
		"saloon": {"at": Vector2(1.4, -10.0), "w": 2.0, "h": 2.2, "double": true, "to": Vector2(0, -1), "model": "marlin_door_glass", "y": MAIN, "thick": 0.06},
		"galley": {"at": Vector2(0.9, -19.2), "w": 0.9, "h": 2.0, "to": Vector2(1, 0), "model": "marlin_door_crew", "y": LOWER},
		"cabin_a": {"at": Vector2(-0.9, -27.6), "w": 0.8, "h": 2.0, "to": Vector2(-1, 0), "model": "marlin_door_crew", "y": LOWER},
		"cabin_b": {"at": Vector2(0.9, -28.6), "w": 0.9, "h": 2.0, "to": Vector2(1, 0), "model": "marlin_door_crew", "y": LOWER},
		"sun": {"at": Vector2(0.0, -14.0), "w": 1.0, "h": 2.2, "to": Vector2(0, -1), "model": "marlin_door_glass", "y": UPPER, "thick": 0.06},
		"captain": {"at": Vector2(1.0, -22.4), "w": 0.9, "h": 2.1, "to": Vector2(-1, 0), "model": "marlin_door", "y": UPPER},
		"safe": {"at": Vector2(-3.25, -30.6), "w": 0.9, "h": 2.0, "to": Vector2(0, -1), "model": "marlin_door_safe", "y": UPPER, "thick": 0.1},
		"bridge": {"at": Vector2(2.2, -33.0), "w": 0.9, "h": 2.1, "to": Vector2(0, -1), "model": "marlin_door", "y": UPPER},
	}
	if moored():
		specs["gangway"] = {"at": Vector2(0.0, 2.4), "w": 1.0, "h": 2.0, "to": Vector2(0, -1), "model": "marlin_gate", "thick": 0.06}
	_make_doors(specs)


# --- Where people go --------------------------------------------------------------------------

func _graph() -> void:
	var P := {
		# The aft deck.
		"gang_top": Vector3(0.0, MAIN, -2.75), "teo_gang": Vector3(1.1, MAIN, -3.3), "kofi_aft": Vector3(-0.9, MAIN, -3.3),
		"freya_stern": Vector3(-2.0, MAIN, -2.85), "aft_c": Vector3(1.1, MAIN, -5.0), "aft_mid": Vector3(1.3, MAIN, -7.0),
		"aft_port": Vector3(-2.4, MAIN, -6.6), "bar_end": Vector3(-4.0, MAIN, -6.6), "bianca_bar": Vector3(-4.03, MAIN, -4.8),
		"crew_out": Vector3(-3.6, MAIN, -8.9), "saloon_out": Vector3(1.4, MAIN, -8.9), "aft_sb": Vector3(2.4, MAIN, -3.3),
		"stair1_foot": Vector3(3.8, MAIN, -2.75), "celeste_aft": Vector3(-2.3, MAIN, -3.7), "hugo_aft": Vector3(-1.5, MAIN, -3.9),
		# The crew stair and the lower deck.
		"crew_top": Vector3(-3.6, MAIN, -10.55), "crew_foot": Vector3(-3.7, LOWER, -16.1),
		"passage": Vector3(-1.8, LOWER, -16.6), "hall_aft": Vector3(0.0, LOWER, -16.6),
		"hall_galley": Vector3(0.0, LOWER, -19.2), "galley_in": Vector3(1.8, LOWER, -19.2), "rocco": Vector3(3.0, LOWER, -20.15),
		"galley_c": Vector3(1.9, LOWER, -21.2),
		"hall_mess": Vector3(0.0, LOWER, -21.0), "mess_in": Vector3(-1.8, LOWER, -21.0), "ollie": Vector3(-2.3, LOWER, -19.6),
		"hall_laundry": Vector3(0.0, LOWER, -24.4), "laundry": Vector3(2.2, LOWER, -24.4),
		"hall_a": Vector3(0.0, LOWER, -27.6), "cabin_a_in": Vector3(-2.1, LOWER, -27.6),
		"hall_b": Vector3(0.0, LOWER, -28.6), "cabin_b_in": Vector3(1.9, LOWER, -28.6), "held": Vector3(2.5, LOWER, -29.3),
		"held_guard": Vector3(0.0, LOWER, -29.6), "hall_fwd": Vector3(0.0, LOWER, -30.3),
		# The saloon, dining room and lobby.
		"saloon_in": Vector3(1.4, MAIN, -11.2), "saloon_aisle": Vector3(-0.05, MAIN, -12.0),
		"saloon_fwd": Vector3(2.2, MAIN, -18.8), "dining_in": Vector3(2.2, MAIN, -20.9), "dining_e": Vector3(2.6, MAIN, -23.0),
		"dining_fwd": Vector3(2.6, MAIN, -24.3), "lobby_in": Vector3(2.6, MAIN, -25.9), "lobby_c": Vector3(0.6, MAIN, -28.0),
		"stair2_foot": Vector3(3.8, MAIN, -25.45),
		# The upper deck.
		"stair1_head": Vector3(3.8, UPPER, -8.7), "sun_e": Vector3(3.8, UPPER, -10.0), "sun_c": Vector3(1.0, UPPER, -9.5), "sun_door_out": Vector3(0.0, UPPER, -13.0),
		"sky_in": Vector3(0.0, UPPER, -15.2), "sky_c": Vector3(1.6, UPPER, -17.6), "sky_fwd": Vector3(2.7, UPPER, -20.0),
		"hall_up_aft": Vector3(2.7, UPPER, -21.7), "captain_out": Vector3(2.0, UPPER, -22.4), "hall_mid": Vector3(2.0, UPPER, -27.0),
		"hall_up_fwd": Vector3(2.0, UPPER, -32.2), "stair2_head": Vector3(3.8, UPPER, -31.6),
		"captain_in": Vector3(-0.1, UPPER, -22.4), "captain_c": Vector3(-1.6, UPPER, -24.6), "ollie_bed": Vector3(-0.7, UPPER, -23.8),
		"anders_cabin": Vector3(-0.8, UPPER, -26.5), "safe_out": Vector3(-3.25, UPPER, -29.9), "safe_in": Vector3(-3.25, UPPER, -31.4),
		"ensuite_door": Vector3(-0.5, UPPER, -29.0), "ollie_ensuite": Vector3(-0.5, UPPER, -31.7),
		"bridge_in": Vector3(2.2, UPPER, -34.0), "freya": Vector3(-0.2, UPPER, -35.6), "anders": Vector3(1.6, UPPER, -35.2),
	}
	var L := [
		["gang_top", "teo_gang", ""], ["gang_top", "kofi_aft", ""], ["gang_top", "freya_stern", ""], ["gang_top", "aft_c", ""],
		["gang_top", "hugo_aft", ""], ["hugo_aft", "celeste_aft", ""], ["hugo_aft", "aft_port", ""],
		["aft_c", "aft_mid", ""], ["aft_mid", "saloon_out", ""], ["aft_c", "aft_sb", ""], ["aft_sb", "teo_gang", ""],
		["aft_sb", "stair1_foot", ""], ["aft_c", "aft_port", ""], ["aft_port", "bar_end", ""], ["bar_end", "bianca_bar", ""],
		["aft_port", "crew_out", ""], ["crew_out", "crew_top", "crew"], ["crew_top", "crew_foot", ""],
		["crew_foot", "passage", ""], ["passage", "hall_aft", ""], ["hall_aft", "hall_galley", ""],
		["hall_galley", "galley_in", "galley"], ["galley_in", "rocco", ""], ["galley_in", "galley_c", ""], ["galley_c", "rocco", ""],
		["hall_galley", "hall_mess", ""], ["hall_mess", "mess_in", ""], ["mess_in", "ollie", ""],
		["hall_mess", "hall_laundry", ""], ["hall_laundry", "laundry", ""], ["hall_laundry", "hall_a", ""],
		["hall_a", "cabin_a_in", "cabin_a"], ["hall_a", "hall_b", ""], ["hall_b", "cabin_b_in", "cabin_b"], ["cabin_b_in", "held", ""],
		["hall_b", "held_guard", ""], ["held_guard", "hall_fwd", ""],
		["saloon_out", "saloon_in", "saloon"], ["saloon_in", "saloon_aisle", ""], ["saloon_fwd", "dining_in", ""],
		["dining_in", "dining_e", ""], ["dining_e", "dining_fwd", ""], ["dining_fwd", "lobby_in", ""],
		["lobby_in", "lobby_c", ""], ["lobby_in", "stair2_foot", ""], ["stair2_foot", "stair2_head", ""],
		["stair1_foot", "stair1_head", ""], ["stair1_head", "sun_e", ""], ["sun_e", "sun_c", ""], ["sun_c", "sun_door_out", ""],
		["sun_door_out", "sky_in", "sun"], ["sky_in", "sky_c", ""], ["sky_c", "sky_fwd", ""], ["sky_fwd", "hall_up_aft", ""],
		["hall_up_aft", "captain_out", ""], ["captain_out", "hall_mid", ""], ["hall_mid", "hall_up_fwd", ""],
		["hall_up_fwd", "stair2_head", ""], ["captain_out", "captain_in", "captain"], ["captain_in", "captain_c", ""],
		["captain_in", "ollie_bed", ""], ["captain_c", "ollie_bed", ""], ["captain_c", "anders_cabin", ""],
		["captain_c", "safe_out", ""], ["captain_c", "ensuite_door", ""], ["ensuite_door", "ollie_ensuite", ""],
		["safe_out", "safe_in", "safe"], ["hall_up_fwd", "bridge_in", "bridge"], ["bridge_in", "anders", ""], ["bridge_in", "freya", ""],
	]
	var face := {
		"teo_gang": Vector2(0, 1), "kofi_aft": Vector2(0, 1), "freya_stern": Vector2(0, 1), "bianca_bar": Vector2(1, 0),
		"celeste_aft": Vector2(-1, 0.2), "hugo_aft": Vector2(-1, 0.3), "rocco": Vector2(1, 0), "ollie": Vector2(1, -0.8),
		"held": Vector2(-1, 0.5), "held_guard": Vector2(1, 0), "ollie_bed": Vector2(0, 1), "anders_cabin": Vector2(-1, 0),
		"safe_out": Vector2(0, -1), "safe_in": Vector2(0, -1), "ollie_ensuite": Vector2(0, -1), "freya": Vector2(0, -1),
		"anders": Vector2(0, 1), "galley_c": Vector2(0, -1), "laundry": Vector2(1, 0), "lobby_c": Vector2(-1, 0),
		"sky_c": Vector2(-1, 0), "sun_c": Vector2(0, 1), "aft_port": Vector2(-1, 0), "aft_sb": Vector2(0, 1),
		"saloon_in": Vector2(0, -1), "dining_e": Vector2(-1, 0), "captain_c": Vector2(0, -1),
	}
	match night:
		"aboard":
			P.merge({
				"crew_0": Vector3(-0.9, 0.0, 9.0), "crew_1": Vector3(0.9, 0.0, 9.0), "quay_c": Vector3(0.0, 0.0, 5.8),
				"gate_out": Vector3(0.0, 0.0, 3.3), "gang_foot": Vector3(0.0, 0.0, 1.9), "kofi": Vector3(1.1, 0.0, 3.1),
				"jun": Vector3(-4.6, 0.0, 3.0), "jun_back": Vector3(-3.2, 0.0, 3.0), "bianca_quay": Vector3(2.6, 0.0, 3.4),
				"quay_e": Vector3(4.6, 0.0, 3.6), "sal": Vector3(9.4, 0.0, 3.9), "rocco_quay": Vector3(7.3, 0.0, 3.1),
				"saloon_c": Vector3(-0.2, MAIN, -16.0),
			})
			L.append_array([
				["crew_0", "quay_c", ""], ["crew_1", "quay_c", ""], ["quay_c", "gate_out", ""], ["gate_out", "kofi", ""],
				["gate_out", "gang_foot", "gangway"], ["gang_foot", "gang_top", ""], ["gate_out", "jun_back", ""],
				["jun_back", "jun", ""], ["gate_out", "bianca_quay", ""], ["bianca_quay", "quay_e", ""], ["quay_c", "quay_e", ""],
				["quay_e", "sal", ""], ["quay_e", "rocco_quay", ""], ["saloon_aisle", "saloon_c", ""], ["saloon_c", "saloon_fwd", ""],
			])
			face.merge({"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "kofi": Vector2(0, 1), "jun": Vector2(0, 1),
				"bianca_quay": Vector2(-0.3, 1), "sal": Vector2(-1, -0.4), "saloon_c": Vector2(0, -1), "rocco_quay": Vector2(1, 0.3)})
		"safe":
			P.merge({
				"crew_0": Vector3(-0.6, MAIN, -4.6), "crew_1": Vector3(0.6, MAIN, -4.6), "saloon_c": Vector3(-0.2, MAIN, -16.0),
				"anders_saloon": Vector3(0.6, MAIN, -16.4), "teo_rose": Vector3(-3.4, MAIN, -17.1), "rupert_rose": Vector3(-1.4, MAIN, -17.4),
			})
			L.append_array([
				["crew_0", "gang_top", ""], ["crew_1", "aft_c", ""], ["crew_0", "crew_1", ""], ["saloon_aisle", "saloon_c", ""],
				["saloon_c", "saloon_fwd", ""], ["saloon_c", "anders_saloon", ""], ["saloon_c", "teo_rose", ""], ["saloon_c", "rupert_rose", ""],
			])
			face.merge({"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "anders_saloon": Vector2(-1, -0.4),
				"teo_rose": Vector2(1, -0.3), "rupert_rose": Vector2(-1, 0), "saloon_c": Vector2(0, -1)})
		"auction":
			P.merge({
				"crew_0": Vector3(-0.6, MAIN, -4.6), "crew_1": Vector3(0.6, MAIN, -4.6),
				"nina_side": Vector3(-2.3, MAIN, -8.3), "nina_desk": Vector3(-1.0, MAIN, -8.45),
				"saloon_c": Vector3(-0.05, MAIN, -17.8), "rostrum_side": Vector3(0.35, MAIN, -19.45), "rupert": Vector3(-0.6, MAIN, -19.62),
				"phone_side": Vector3(4.15, MAIN, -18.8), "nina_phone": Vector3(4.15, MAIN, -17.2),
				"margit": Vector3(3.3, MAIN, -12.3), "joost": Vector3(-1.9, MAIN, -12.0),
				"celeste_side": Vector3(-2.3, MAIN, -11.6), "hugo_side": Vector3(3.4, MAIN, -14.6), "joost_margit": Vector3(2.3, MAIN, -12.4),
			})
			L.append_array([
				["crew_0", "gang_top", ""], ["crew_1", "aft_c", ""], ["crew_0", "crew_1", ""], ["aft_port", "nina_side", ""],
				["nina_side", "nina_desk", ""], ["saloon_aisle", "saloon_c", ""], ["saloon_c", "saloon_fwd", ""],
				["saloon_c", "rostrum_side", ""], ["rostrum_side", "rupert", ""], ["saloon_fwd", "phone_side", ""],
				["phone_side", "nina_phone", ""], ["saloon_in", "margit", ""], ["margit", "hugo_side", ""],
				["saloon_aisle", "joost", ""], ["joost", "celeste_side", ""], ["margit", "joost_margit", ""],
			])
			face.merge({"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "nina_desk": Vector2(0, 1), "rupert": Vector2(0, 1),
				"nina_phone": Vector2(-1, 0), "margit": Vector2(-0.3, -1), "joost": Vector2(0.2, -1), "celeste_side": Vector2(0.4, -1),
				"hugo_side": Vector2(-0.6, -1), "saloon_c": Vector2(0, 1), "joost_margit": Vector2(1, 0.1)})
	points = P
	links = L
	for k in face:
		spots[k] = _spot3(P[k], face[k])
	_crowd()


## The crowd: deckhands and cooks taking on stores, guests at the preview,
## bidders at the sale.
func _crowd() -> void:
	match night:
		"aboard":
			extras["outside"] = [_spot3(Vector3(-6.6, 0.0, 1.6), Vector2(1, -0.4)), _spot3(Vector3(7.4, 0.0, 3.6), Vector2(1, 0.3)),
				_spot3(Vector3(-2.6, 0.0, 6.4), Vector2(-0.6, -1))] as Array[Transform3D]
			extras["galley"] = [_spot3(Vector3(2.0, LOWER, -21.35), Vector2(0, -1))] as Array[Transform3D]
			extras["mess"] = [_spot3(Vector3(-2.0, LOWER, -23.6), Vector2(-1, 0.4))] as Array[Transform3D]
		"safe":
			var aft: Array[Transform3D] = []
			aft.append_array(_knot3(Vector2(-1.2, -6.2), MAIN, 3, 0.6))
			extras["aft_deck"] = aft
			var saloon: Array[Transform3D] = []
			saloon.append_array(_knot3(Vector2(-0.8, -18.8), MAIN, 3, 0.55))
			saloon.append_array([_spot3(Vector3(1.0, MAIN, -18.6), Vector2(-1, 0.3)), _spot3(Vector3(-1.4, MAIN, -11.5), Vector2(0.5, -1))])
			extras["saloon"] = saloon
			extras["sky_lounge"] = [_spot3(Vector3(-2.6, UPPER, -19.4), Vector2(0, 1)), _spot3(Vector3(-2.0, UPPER, -15.6), Vector2(-0.6, -1))] as Array[Transform3D]
			extras["galley"] = [_spot3(Vector3(2.0, LOWER, -21.35), Vector2(0, -1))] as Array[Transform3D]
		"auction":
			var seats: Array[Transform3D] = []
			var taken := [[-2.2, -13.2], [-1.0, -13.2], [1.5, -13.2], [2.1, -13.2], [-1.6, -14.4], [0.9, -14.4], [2.1, -14.4],
				[-2.2, -15.6], [-1.0, -15.6], [1.5, -15.6], [-1.6, -16.8], [0.9, -16.8], [2.1, -16.8]]
			for s in taken:
				seats.append(_spot3(Vector3(s[0], MAIN, s[1]), Vector2(0, -1)))
			extras["saloon"] = seats
			var aft: Array[Transform3D] = []
			aft.append_array(_knot3(Vector2(1.6, -6.3), MAIN, 2, 0.45))
			aft.append_array([_spot3(Vector3(-2.0, MAIN, -4.6), Vector2(-1, 0.2))])
			extras["aft_deck"] = aft
			extras["dining"] = _knot3(Vector2(3.1, -21.9), MAIN, 2, 0.45)


static func _knot3(c: Vector2, y: float, n: int, r: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for t in _knot(c, n, r):
		t.origin.y = y
		out.append(t)
	return out


func _views() -> void:
	var v := {
		"marina": [Vector3(-13.0, 9.0, 16.0), Vector3(0.0, 2.0, -12.0)],
		"quay": [Vector3(5.5, 1.7, 11.5), Vector3(-0.5, 2.0, -2.0)],
		"gangway": [Vector3(-1.4, 1.65, 6.4), Vector3(0.2, 1.5, -2.5)],
		"aft_deck": [Vector3(2.6, 2.9, -2.6), Vector3(-2.2, 1.7, -8.4)],
		"bar": [Vector3(0.9, 2.8, -7.6), Vector3(-3.6, 2.0, -4.4)],
		"saloon": [Vector3(3.8, 2.95, -10.7), Vector3(-2.0, 1.7, -18.4)],
		"dining": [Vector3(3.2, 2.9, -20.6), Vector3(-2.6, 1.6, -23.8)],
		"lobby": [Vector3(-3.8, 2.9, -25.6), Vector3(3.0, 2.6, -30.4)],
		"crew_stair": [Vector3(-3.7, 3.35, -10.35), Vector3(-3.7, -0.9, -15.6)],
		"corridor": [Vector3(0.0, 0.25, -16.0), Vector3(0.0, -0.3, -30.5)],
		"galley": [Vector3(1.3, 0.4, -15.9), Vector3(3.6, -0.6, -21.6)],
		"mess": [Vector3(-1.25, 0.4, -18.0), Vector3(-3.9, -0.8, -23.5)],
		"cabin": [Vector3(1.25, 0.3, -26.6), Vector3(4.0, -0.8, -30.4)],
		"sun_deck": [Vector3(3.9, 6.0, -4.4), Vector3(-2.2, 4.6, -12.0)],
		"sky_lounge": [Vector3(3.8, 6.2, -14.5), Vector3(-3.0, 4.8, -19.6)],
		"upper_hall": [Vector3(2.0, 6.2, -21.2), Vector3(3.0, 4.9, -32.5)],
		"captain": [Vector3(0.5, 6.1, -21.3), Vector3(-3.6, 4.6, -28.6)],
		"strongroom": [Vector3(-2.9, 5.85, -30.85), Vector3(-4.0, 4.95, -32.55)],
		"bridge": [Vector3(3.7, 6.1, -33.5), Vector3(-1.0, 4.9, -38.4)],
	}
	_set_views(v)
	view_about = {
		"marina": "The Marlin moored stern-to at Caldera's marina, her neighbors, the quay and the city behind",
		"quay": "The quay at the stern: the gangway and its gate, the purser's table, the chandler's van and stores",
		"gangway": "The gangway's gate, where the bosun checks the crew list, from where the crew starts",
		"aft_deck": "The aft deck: the bar to port, the lounge, the saloon's glass doors and the stair up",
		"bar": "The aft deck's bar, where the chief stewardess sets up for the night",
		"saloon": "The main saloon from its doors: the sofas by the windows, the sideboard and the corner forward",
		"dining": "The dining room, laid for ten, with the archway to the saloon",
		"lobby": "The lobby: the bronze, the owner's suite's doors and the guest stair up to the captain's deck",
		"crew_stair": "The crew stair from the aft deck's crew door down to the lower deck",
		"corridor": "The crew corridor on the lower deck: the galley, mess, laundry and cabins off it",
		"galley": "The galley: the range under its hood, the island and the pass, where the chef works",
		"mess": "The crew mess: the dinette, the counter and the television",
		"cabin": "A crew cabin on the starboard side, where Halberd puts anyone it holds",
		"sun_deck": "The sun deck: the spa, the loungers and the sky lounge's doors",
		"sky_lounge": "The sky lounge on the upper deck",
		"upper_hall": "The upper deck's hall: the captain's door, the guest stair's well and the bridge door",
		"captain": "The captain's cabin: the bed, the desk under the window, the Kestrel on the credenza, the strongroom door",
		"strongroom": "Inside the captain's strongroom, the safe in the corner",
		"bridge": "The bridge: the helm, the chairs, the chart table and the windscreen",
	}
