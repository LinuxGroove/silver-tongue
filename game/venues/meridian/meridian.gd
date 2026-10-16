class_name Meridian
extends Venue
## The Hotel Meridian's ground floor, where the gala is: the lobby with
## reception and the bar, the ballroom and its stage, the kitchen with the pass
## and the staff room, the back corridor and its service door (M0's), the
## security office, Mr Okafor's office, the loading bay, and the street out
## front. Built in code from the Downtown City kit and the hotel's own props
## (`tools/blender/props.py`). X runs east and Z south, the floor is y = 0;
## docs/m1.md has the room table.
##
## What's on changes it a little ([member setting]): the gala, a wedding a
## week later, and the Rose's press call the morning it leaves. Its rooms
## light only themselves, as every [Venue]'s do.

## The rooms (and outside, the street and the loading bay). Some overlap:
## [method zone_at] checks them in [constant ZONE_ORDER].
const ZONES := {
	"lobby": AABB(Vector3(-14.0, -1.0, -18.0), Vector3(20.0, 13.0, 18.0)),
	"ballroom": AABB(Vector3(-14.0, -1.0, -34.0), Vector3(20.0, 13.0, 16.0)),
	"kitchen": AABB(Vector3(6.0, -1.0, -34.0), Vector3(14.0, 13.0, 14.0)),
	"staff_room": AABB(Vector3(14.0, -1.0, -34.0), Vector3(6.0, 13.0, 6.0)),
	"corridor": AABB(Vector3(6.0, -1.0, -20.0), Vector3(6.0, 13.0, 14.0)),
	"office": AABB(Vector3(12.0, -1.0, -16.0), Vector3(6.0, 13.0, 10.0)),
	"manager_office": AABB(Vector3(12.0, -1.0, -20.0), Vector3(8.0, 13.0, 4.0)),
	"outside": AABB(Vector3(-40.0, -1.0, -6.0), Vector3(80.0, 31.0, 23.0)),
}
## The staff room is inside the kitchen, and outside's box takes in the lobby's
## front, so the smaller rooms come first.
const ZONE_ORDER: Array[String] = ["staff_room", "kitchen", "manager_office", "office", "corridor", "ballroom", "lobby", "outside"]
## Each zone's render layer (1 is for people and doors, lit everywhere).
const LAYERS := {"lobby": 2, "ballroom": 3, "kitchen": 4, "staff_room": 4, "corridor": 5, "office": 6, "outside": 7, "manager_office": 8}

## Ceiling heights.
const LOBBY_H := 6.0
const BALLROOM_H := 7.0
const KITCHEN_H := 3.6
const CORRIDOR_H := 5.0
const OFFICE_H := 3.2
const MANAGER_H := 3.2
## The street: pavement from the hotel's front (z = 0) to the kerb, the road,
## then the far pavement and the buildings across.
const KERB := 6.0
const FAR_KERB := 13.0
const ACROSS := 16.0

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
	"manager": {"at": Vector2(12.0, -18.0), "w": 1.1, "h": 2.2, "to": Vector2(1, 0), "model": "door_wood"},
}
## Where the Rose's case stands on the stage at the press call (the top of
## its plinth).
const CASE_AT := Vector3(-4.0, 1.66, -30.7)

## What's on: "gala" (the museum's gala, job 1), "wedding" (the Achterberg
## wedding a week later, job 2: the guest list on Mr Okafor's desk) or
## "press" (the morning the Rose leaves, job 3: daylight, the press
## breakfast, the Rose's case on the stage). Set it before building.
var setting := "gala"

func _init() -> void:
	zones = ZONES
	zone_order = ZONE_ORDER
	room_layers = LAYERS


## The doors are HotelDoors by name (front, ballroom, pass, staff, service,
## office, loading, manager); the uses are "jackets" (the rack in the staff
## room) and "keypad" (beside the service door), at the wedding
## "okafor_desk" (the guest list), and at the press call "plinth" and
## "plinth_copy" (the Rose's case and Mae's) and "trolley" (in the kitchen).
func _build() -> void:
	_make_rooms(["lobby", "ballroom", "kitchen", "corridor", "office", "manager_office", "outside"])
	_ground()
	_lobby()
	_ballroom()
	_kitchen()
	_staff_room()
	_corridor()
	_office()
	_manager_office()
	_bay()
	_street()
	_facades()
	_doors()
	_graph()
	_views()
	_apply_layers()
	_daylight()
	_dress(self)
	set_clock({"gala": 20 * 60 + 45, "wedding": 21 * 60 + 30, "press": 9 * 60 + 40}.get(setting, 20 * 60 + 45))


## The press call's morning has a bright sky; the other nights are dark.
func environment() -> Environment:
	var env := super.environment()
	if setting != "press":
		return env
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.33, 0.5, 0.78)
	sky_mat.sky_horizon_color = Color(0.72, 0.78, 0.84)
	sky_mat.ground_horizon_color = Color(0.62, 0.64, 0.66)
	sky_mat.ground_bottom_color = Color(0.3, 0.3, 0.3)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_color = Color(0.55, 0.6, 0.68)
	env.ambient_light_energy = 0.35
	env.fog_light_color = Color(0.62, 0.68, 0.76)
	env.fog_density = 0.0025
	env.glow_hdr_threshold = 1.2
	return env


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
			[{"at": -4.0, "w": 2.4, "h": 3.12}, {"at": -10.0, "w": 2.7, "h": 3.7, "y0": 0.6}, {"at": 2.0, "w": 2.7, "h": 3.7, "y0": 0.6}])
	_ceiling(r, LOBBY_H, "plaster")
	# Coffers: beams over the columns, and a cornice round the middle.
	for x in [-8.9, 0.9]:
		_slab(Vector3(x, LOBBY_H - 0.22, -9.15), Vector3(0.6, 0.44, 17.3), _mat("plaster"))
		_slab(Vector3(x, LOBBY_H - 0.46, -9.15), Vector3(0.66, 0.05, 17.3), _mat("gilt"))
	for z in [-5.0, -12.0]:
		_slab(Vector3(-4.0, LOBBY_H - 0.22, z), Vector3(19.6, 0.44, 0.6), _mat("plaster"))
		_slab(Vector3(-4.0, LOBBY_H - 0.46, z), Vector3(19.6, 0.05, 0.66), _mat("gilt"))
	# A gilt moulding round each coffer.
	for xs in [Vector2(-13.8, -9.2), Vector2(-8.6, 0.6), Vector2(1.2, 5.8)]:
		for zs in [Vector2(-4.7, -0.5), Vector2(-11.7, -5.3), Vector2(-17.8, -12.3)]:
			var c := Rect2(xs.x, zs.x, xs.y - xs.x, zs.y - zs.x).grow(-0.5)
			for z in [c.position.y, c.end.y]:
				_slab(Vector3(c.get_center().x, LOBBY_H - 0.03, z), Vector3(c.size.x + 0.08, 0.06, 0.08), _mat("gilt"))
			for x in [c.position.x, c.end.x]:
				_slab(Vector3(x, LOBBY_H - 0.03, c.get_center().y), Vector3(0.08, 0.06, c.size.y), _mat("gilt"))
	# Columns under the beams' crossings.
	for p in [Vector2(-8.9, -5.0), Vector2(0.9, -5.0), Vector2(-8.9, -12.0), Vector2(0.9, -12.0)]:
		_column(p, LOBBY_H - 0.44)
	# The front: windows behind drapes, the doors' transom, palms.
	for x in [-10.0, 2.0]:
		_window(Vector2(x, -0.5), Vector2(0, -1), 2.7, 0.6, 3.7, 0.3)
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
	_sign("THE MERIDIAN", Vector3(3.6, 4.25, -17.76), 0.0, 60, Color(0.8, 0.62, 0.34))
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
	var poster := {
		"gala": "THE CALDERA\nMUSEUM\n\nAutumn Gala\n\nIn the Ballroom\nfrom eight o'clock",
		"wedding": "THE WEDDING OF\n\nAnneke Achterberg\n&\nTomas Lindgren\n\nIn the Ballroom",
		"press": "THE CALDERA\nMUSEUM\n\nThe Rose\nPress call\n\nIn the Ballroom\nhalf past nine",
	}
	_sign(str(poster.get(setting, poster.gala)), Vector3(-7.6, 1.27, -16.82), 0.0, 40, Color(0.2, 0.15, 0.1), 0.0018)
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
	# Paintings over the sofas, and the museum's volcano by the ballroom.
	_painting(Vector2(-13.8, -3.3), Vector2(1, 0), 2.3, 1.55, 1.53, "painting_coast")
	_painting(Vector2(5.8, -3.3), Vector2(-1, 0), 2.3, 1.55, 1.53, "painting_valley")
	_painting(Vector2(-10.0, -17.8), Vector2(0, 1), 1.8, 1.45, 2.4, "painting_caldera")
	_sign("STAFF ONLY", Vector3(5.76, 2.62, -10.0), -PI * 0.5, 36)
	# Light: the chandelier (the lobby's one shadow), a wash from each corner.
	var ch := _omni(Vector3(-4.0, 3.4, -8.5), WARM, 3.2, 15.0, true)
	ch.shadow_bias = 0.08
	for p in [Vector3(-10.5, 4.6, -4.0), Vector3(2.5, 4.6, -4.0), Vector3(-9.0, 4.6, -15.0), Vector3(1.0, 4.6, -16.0)]:
		_omni(p, WARM, 0.75, 9.0)
	if setting == "press":
		for x in [-10.0, 2.0]:
			_omni(Vector3(x, 2.4, -1.8), Color(0.9, 0.95, 1.0), 1.4, 9.0)
	_probe(r, LOBBY_H, Color(0.42, 0.33, 0.24), 0.35)
	# The kit's marble is a yellow beige; the lobby's is creamier.
	_tint(_at, "MI_Trim", Color(1.0, 0.95, 0.92))


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
	match setting:
		"gala":
			var plinth := _box("display_plinth", Vector3(-6.4, 0.6, -31.4))
			_tint(plinth, "paint_white", Color(0.5, 0.47, 0.43))
		"wedding":
			_box("meridian_cake_table", Vector3(-6.4, 0.6, -31.4))
			_omni(Vector3(-6.4, 2.2, -30.6), CANDLE, 0.5, 3.0)
		"press":
			_press_call()
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


## The press call: the Rose's case on a plinth in the middle of the stage
## (its use, and Mae's copy's in the same place), cameras on tripods, and
## breakfast along the walls.
func _press_call() -> void:
	_box("meridian_case_plinth", CASE_AT - Vector3(0.0, 1.06, 0.0))
	for id in ["plinth", "plinth_copy"]:
		var u := _use(id, CASE_AT, Vector3(0.55, 0.55, 0.55), "meridian_display_case")
		u.set_meta("use", "item:" + ("rose_case" if id == "plinth" else "mae_case"))
	_omni(CASE_AT + Vector3(0.0, 1.2, 0.9), Color(1.0, 0.92, 0.85), 0.7, 3.0)
	_sign("THE ROSE", Vector3(-4.0, 4.3, -33.4), 0.0, 96, Color(0.86, 0.7, 0.4))
	for p in [Vector2(-10.3, -26.9), Vector2(0.9, -27.0)]:
		_box("meridian_tripod", _v(p), atan2(-4.0 - p.x, -30.7 - p.y))
	_box("meridian_buffet", Vector3(-13.2, 0.0, -25.0), PI * 0.5)
	_box("meridian_buffet", Vector3(5.2, 0.0, -31.6), -PI * 0.5)


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
	if setting == "press":
		_use("trolley", Vector3(6.85, 0.0, -30.2), Vector3(0.8, 1.05, 1.1))
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
	_wall("marble", Vector2(11.8, -19.8), Vector2(11.8, -6.2), Vector2(-1, 0), CORRIDOR_H, [{"at": -11.0, "w": 1.1, "h": 2.2}, {"at": -18.0, "w": 1.1, "h": 2.2}])
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
	_m("doorframe_walnut", Vector3(11.8, 0.0, -18.0), -PI * 0.5)
	_sign("MANAGER", Vector3(11.76, 2.62, -18.0), -PI * 0.5, 40)
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
	_box("office_chair", Vector3(14.6, 0.0, -14.4), PI)
	# The guards' lockers, and a bench for whoever's held.
	_box("lockers", Vector3(17.535, 0.0, -8.0), -PI * 0.5)
	_box("locker_bench", Vector3(14.6, 0.0, -6.45))
	for x in [16.9, 17.42]:
		_box("filing_cabinet", Vector3(x, 0.0, -15.47))
	_m("notice_board", Vector3(12.2, 1.3, -14.0), PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(15.0, 2.2, -6.2), PI, Vector3.ONE * 0.45))
	_m("doorframe_plain", Vector3(12.2, 0.0, -11.0), PI * 0.5)
	for z in [-13.5, -8.5]:
		_slab(Vector3(15.0, OFFICE_H - 0.03, z), Vector3(1.2, 0.05, 0.6), _mat("panel_light"))
		_omni(Vector3(15.0, OFFICE_H - 0.4, z), COOL, 0.55, 6.0)
	_omni(Vector3(16.5, 1.5, -11.0), Color(0.6, 0.75, 1.0), 0.7, 3.5)
	_omni(Vector3(13.95, 1.0, -15.2), CANDLE, 0.4, 2.5)
	_probe(r, OFFICE_H, Color(0.3, 0.32, 0.34), 0.3)


## Mr Okafor's office, through the door opposite the service door: walnut
## panelling under a green wall, his desk facing the door with his chair
## behind it, a safe in the corner, filing cabinets, a sideboard under the
## window with its blind down. At the wedding his guest list lies on the
## desk ("okafor_desk").
func _manager_office() -> void:
	_in("manager_office")
	var r := Rect2(12.2, -19.8, 7.6, 3.6)
	_floor(r, "parquet")
	_m("rug", Vector3(15.6, 0.0, -18.0), 0.0, Vector3(0.7, 1.0, 0.75))
	_wall("study", Vector2(12.2, -16.2), Vector2(12.2, -19.8), Vector2(1, 0), MANAGER_H, [{"at": -18.0, "w": 1.1, "h": 2.2}])
	_wall("study", Vector2(12.2, -19.8), Vector2(19.8, -19.8), Vector2(0, 1), MANAGER_H)
	_wall("study", Vector2(19.8, -19.8), Vector2(19.8, -16.2), Vector2(-1, 0), MANAGER_H)
	_wall("study", Vector2(19.8, -16.2), Vector2(12.2, -16.2), Vector2(0, -1), MANAGER_H)
	_ceiling(r, MANAGER_H, "plaster")
	_m("doorframe_walnut", Vector3(12.2, 0.0, -18.0), PI * 0.5)
	# The desk, side on to the door, and the chair behind it.
	_box("meridian_manager_desk", Vector3(16.9, 0.0, -18.3), -PI * 0.5)
	_m("desk_lamp", Vector3(16.95, 0.78, -19.0), -PI * 0.5)
	_box("meridian_desk_chair", Vector3(17.95, 0.0, -18.35), -PI * 0.5)
	for z in [-18.75, -17.95]:
		_box("meridian_side_chair", Vector3(15.5, 0.0, z), PI * 0.5)
	if setting == "wedding":
		_use("okafor_desk", Vector3(16.8, 0.78, -17.95), Vector3(0.36, 0.1, 0.42), "meridian_list_folder", -PI * 0.5).set_meta("use", "item:guest_list")
	# The safe in the corner behind him, the sideboard under the window.
	_box("meridian_safe", Vector3(19.47, 0.0, -19.47), -PI * 0.5)
	_box("meridian_credenza", Vector3(19.55, 0.0, -17.3), -PI * 0.5)
	_m("meridian_blinds", Vector3(19.8, 1.2, -17.3), -PI * 0.5)
	# Filing cabinets by the door, a painting over the visitors' chairs.
	for x in [12.75, 13.3]:
		_box("meridian_file_cabinet", Vector3(x, 0.0, -19.47))
	_painting(Vector2(15.4, -19.8), Vector2(0, 1), 1.5, 1.35, 1.05, "painting_valley")
	clocks.append(_m("wall_clock", Vector3(15.4, 2.3, -16.2), PI, Vector3.ONE * 0.4))
	_m("potted_palm", Vector3(13.0, 0.0, -16.75), 0.0, Vector3.ONE * 0.7)
	_solid(Vector3(13.0, 0.4, -16.75), Vector3(0.45, 0.8, 0.45))
	# Light: a warm ceiling light, the banker's lamp, a little over the sideboard.
	_pendant(15.6, -18.0, 2.0, MANAGER_H)
	_omni(Vector3(15.6, 2.6, -18.0), WARM, 0.9, 6.5)
	_omni(Vector3(16.95, 1.05, -18.95), CANDLE, 0.55, 2.8)
	_omni(Vector3(18.8, 1.6, -17.3), WARM, 0.3, 3.0)
	_probe(r, MANAGER_H, Color(0.36, 0.3, 0.24), 0.3)


func _more_mat(mat_name: String, m: StandardMaterial3D) -> bool:
	match mat_name:
		"paint_study":
			m.albedo_color = Color(0.13, 0.22, 0.17)
			m.roughness = 0.8
		_:
			return false
	return true


## Mr Okafor's office's walls: walnut panelling to a brass rail, deep green
## above.
func _more_span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, _h: float) -> void:
	if style != "study":
		return
	if y0 < 0.14:
		_face(a, u, facing, s0, s1, y0, minf(y1, 0.14), _mat("walnut"), 0.03)
	_face(a, u, facing, s0, s1, maxf(y0, 0.14), minf(y1, 1.1), _mat("walnut"), 0.02)
	if y1 >= 1.16 and y0 <= 1.1:
		_face(a, u, facing, s0, s1, 1.1, 1.16, _mat("brass"), 0.035)
	_face(a, u, facing, s0, s1, maxf(y0, 1.16), y1, _mat("paint_study"), 0.012)


func _more_wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	if style == "study":
		_face(a, u, facing, 0.0, length, h - 0.12, h, _mat("cream"), 0.06)


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
	var night := setting != "press"
	if night:
		_spot(Vector3(-4.0, 3.2, 2.2), Vector3(-4.0, 0.0, 1.6), WARM, 4.0, 6.0, 55.0, true)
	_omni(Vector3(-4.0, 2.6, 0.9), WARM, 0.8 if night else 0.4, 5.0)
	# Street lamps, lit on the near side and across from the door.
	for lx in [-26.0, -14.0, 7.0, 22.0, 34.0]:
		_lamp(Vector3(lx, 0.0, KERB - 0.6), night and absf(lx - (-4.0)) < 20.0)
	for lx in [-30.0, -16.0, -4.0, 8.0, 20.0, 32.0]:
		_lamp(Vector3(lx, 0.0, FAR_KERB + 0.6), night and absf(lx - (-4.0)) < 14.0)
	for bx in [-7.6, -0.4]:
		_box("Prop_Bollard", Vector3(bx, 0.0, KERB - 0.5))
	_m("Prop_ManholeCover", Vector3(3.0, -0.148, 8.0))
	# Nobody leaves the block: the street's ends and the buildings' fronts.
	for ex in [-40.0, 40.0]:
		_solid(Vector3(ex, 3.0, (ACROSS - 6.0) * 0.5), Vector3(0.4, 6.0, ACROSS + 6.0))
	_solid(Vector3(0.0, 3.0, ACROSS + 0.2), Vector3(80.0, 6.0, 0.4))
	# A dim moon over the street (the sun in the morning: see _daylight()).
	if night:
		var moon := DirectionalLight3D.new()
		moon.light_color = Color(0.55, 0.65, 0.95)
		moon.light_energy = 0.12
		moon.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
		_at.add_child(moon)
	_probe(Rect2(-40.0, -6.0, 80.0, 22.0), 16.0, Color(0.12, 0.13, 0.18) if night else Color(0.5, 0.55, 0.62), 0.25 if night else 0.55)


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
		# Glass both ways: the lobby shows through.
		var shop := _m("Marble_ShopWindow", Vector3(wx, 0.0, 0.0))
		_override(shop, "MI_FakeInterior", _mat("hidden"))
		_override(shop, "MI_InteriorWall", _mat("hidden"))
	for floor_ in 3:
		var y := 7.0 + floor_ * 3.0
		for wx in [-12.0, -8.0, -4.0, 0.0, 4.0]:
			var win := _m("Marble_Window_Single", Vector3(wx, y, 0.0))
			_override(win, "MI_FakeInterior", _window_mat(0 if rng.randf() < 0.45 else 1 + rng.randi() % 2, Color(1.0, 0.8, 0.6)))
	_panels("Cornice_Marble_Center", Vector2(-14.0, 0.0), Vector2(1, 0), Vector2(0, 1), 0.0, 20.0, 16.0)
	# Lit from below, between the windows, at night.
	if setting != "press":
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


## The press call's morning sun, on the street only: indoors, everyone and
## the doors keep their rooms' light. The windows across the street go dark.
func _daylight() -> void:
	if setting != "press":
		return
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.95, 0.86)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.rotation_degrees = Vector3(-38.0, 205.0, 0.0)
	sun.light_cull_mask = 1 << (int(LAYERS.outside) - 1)
	_rooms.outside.add_child(sun)
	for k in _mats:
		if str(k).begins_with("window_"):
			(_mats[k] as StandardMaterial3D).emission_energy_multiplier = 0.06


# --- Doors ------------------------------------------------------------------------------------

func _doors() -> void:
	_make_doors(DOOR_SPECS)
	# Linings through the walls.
	_in("lobby")
	_reveal(Vector2(-4.0, -18.0), Vector2(1, 0), 2.4, 3.0, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(6.0, -10.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_in("ballroom")
	_reveal(Vector2(6.0, -27.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("steel"), "steel")
	_in("corridor")
	_reveal(Vector2(12.0, -11.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
	_reveal(Vector2(12.0, -18.0), Vector2(0, 1), 1.1, 2.2, 0.4, _mat("walnut"), "brass")
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
		"crew_bay": Vector2(9.6, -3.4),
		# Mr Okafor's office.
		"manager_out": Vector2(10.9, -18.0), "manager_in": Vector2(13.2, -18.0), "manager_c": Vector2(15.2, -16.95),
		"okafor_office": Vector2(18.1, -16.95),
		# The wedding's and the press call's people.
		"gus": Vector2(4.3, -11.4), "pippa": Vector2(-7.0, -14.6), "pippa_in": Vector2(-3.0, -29.2),
		"front_watch": Vector2(-6.7, -2.6), "wren_lobby": Vector2(-6.2, -4.0), "priya_lobby": Vector2(-7.4, -3.8),
		"wren": Vector2(-5.4, -29.2), "priya": Vector2(-1.4, -28.7), "ingrid_stage": Vector2(-2.4, -28.8),
		"rafe": Vector2(1.6, -27.6), "okafor_bar": Vector2(-10.3, -11.0),
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
		["loading_in", "loading_out", "loading"], ["loading_out", "smoke", ""], ["loading_out", "crew_bay", ""],
		["corridor_n", "manager_out", ""], ["service_out", "manager_out", ""], ["manager_out", "manager_in", "manager"],
		["manager_in", "manager_c", ""], ["manager_c", "okafor_office", ""],
		["staff_lobby", "gus", ""], ["reception", "gus", ""], ["lobby_n", "pippa", ""],
		["front_in", "front_watch", ""], ["crew_0", "front_watch", ""], ["lobby_s", "wren_lobby", ""], ["wren_lobby", "priya_lobby", ""], ["front_watch", "priya_lobby", ""],
		["stage_front", "pippa_in", ""], ["stage_front", "wren", ""], ["stage_front", "priya", ""], ["stage_front", "ingrid_stage", ""],
		["okafor_stage", "rafe", ""], ["lobby_w", "okafor_bar", ""], ["celeste", "okafor_bar", ""],
	]
	links = L
	var face := {
		"marcus": Vector2(0, 1), "teo": Vector2(0, 1), "dana": Vector2(0, 1), "laurent": Vector2(0, 1),
		"benny": Vector2(1, 0), "okafor": Vector2(-1, 1), "okafor_stage": Vector2(-1, -1),
		"celeste": Vector2(1, 0), "hugo": Vector2(-1, 0), "celeste_in": Vector2(1, 0), "hugo_in": Vector2(-1, 0),
		"smoke": Vector2(0, 1), "office_guard": Vector2(-1, 0), "held": Vector2(-1, 0),
		"crew_0": Vector2(0, -1), "crew_1": Vector2(0, -1), "ballroom_in": Vector2(0, -1),
		"crew_bay": Vector2(0, -1), "okafor_office": Vector2(-1, -0.4), "gus": Vector2(-1, 0.2), "pippa": Vector2(0.4, 1),
		"pippa_in": Vector2(0, 1), "front_watch": Vector2(1, -0.3), "wren_lobby": Vector2(-0.3, 1), "priya_lobby": Vector2(0.4, 1),
		"wren": Vector2(0.3, 1), "priya": Vector2(-0.3, 1), "ingrid_stage": Vector2(-0.6, -1), "rafe": Vector2(-0.5, -1),
		"okafor_bar": Vector2(-1, -0.2),
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
		"manager_door": [Vector3(8.0, 1.65, -13.6), Vector3(12.0, 1.3, -18.4)],
		"manager_office": [Vector3(12.7, 1.65, -16.7), Vector3(18.6, 1.0, -18.9)],
		"loading_bay": [Vector3(18.6, 1.8, -0.8), Vector3(9.0, 1.3, -5.6)],
		"street": [Vector3(0.5, 1.7, 11.4), Vector3(-4.0, 3.6, 0.0)],
	}
	_set_views(v)
	view_about = {
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
		"manager_door": "Mr Okafor's door, across the corridor from the service door",
		"manager_office": "Mr Okafor's office: his desk and chair, the safe, the sideboard under the blind",
		"loading_bay": "The loading bay: the dumpster, the gate onto the street, the loading door",
	}
