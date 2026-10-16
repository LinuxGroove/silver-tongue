class_name ServiceDoorRoom
extends Node3D
## The Meridian's back corridor: marble walls under a cornice, a planter
## nobody waters, and at the far end the wooden service door to the kitchens,
## with a Halberd guard beside it. Built in code from the Downtown City kit;
## X runs east and Z south, the door is at the north end (z = -2) and you
## come in from the south.

## The corridor: x from -W/2 to W/2, z from Z0 to Z0 + L, walls H tall under
## a 1 m cornice.
const W := 8.0
const L := 12.0
const Z0 := -2.0
const H := 4.0
const CEILING := 5.0
## Where the door's hinge is (the right jamb, seen from the corridor).
const HINGE := Vector3(0.56, 0.0, Z0)
const WARM := Color(1.0, 0.88, 0.72)

var door: GuardDoor
## Where the guard stands, facing down the corridor.
var guard_spot := Transform3D(Basis.IDENTITY, Vector3(-1.1, 0.0, Z0 + 1.0))
## Where you start, facing the door.
var start := Transform3D(Basis.from_euler(Vector3(0, PI, 0)), Vector3(0.0, 0.0, Z0 + L - 2.5))
## Past the door: stepping in here means you're through.
var through: Area3D


func _ready() -> void:
	if door == null:
		build()


func build() -> void:
	_floor()
	_walls()
	_ceiling()
	_door()
	_beyond()
	_props()
	_lights()


func _floor() -> void:
	for x in [-2.0, 2.0]:
		for z in [0.0, 4.0, 8.0]:
			Kit.model(self, "Floor_4x4", Vector3(x, 0.0, z))
	Kit.block(self, Vector3(0.0, -0.15, Z0 + L * 0.5), Vector3(W, 0.3, L))


## Walls are 2 m panels with their face on the room's edge, a cornice on top
## and one collision box behind.
func _walls() -> void:
	var z1 := Z0 + L
	# North (the door's wall): a panel either side, pilasters, the frame and
	# a short panel over it.
	for x in [-3.0, 3.0]:
		_panel("Marble_Plain_4", Vector3(x, 0.0, Z0), 0.0)
	for x in [-1.6, 1.6]:
		Kit.model(self, "Marble_BevelColumn_Bottom", Vector3(x, 0.0, Z0))
	Kit.model(self, "DoorFrame_Wooden", Vector3(0.0, 0.0, Z0))
	Kit.model(self, "Marble_Plain_1", Vector3(0.0, 3.0, Z0), 0.0, Vector3(1.25, 1.0, 1.0))
	for x in [-3.0, -1.0, 1.0, 3.0]:
		Kit.model(self, "Cornice_Marble_Center", Vector3(x, H, Z0))
	Kit.block(self, Vector3(-2.3, CEILING * 0.5, Z0 - 0.15), Vector3(3.4, CEILING, 0.3))
	Kit.block(self, Vector3(2.3, CEILING * 0.5, Z0 - 0.15), Vector3(3.4, CEILING, 0.3))
	Kit.block(self, Vector3(0.0, 3.0 + (CEILING - 3.0) * 0.5, Z0 - 0.15), Vector3(1.3, CEILING - 3.0, 0.3))
	# South.
	for x in [-3.0, -1.0, 1.0, 3.0]:
		_panel("Marble_Plain_4", Vector3(x, 0.0, z1), PI)
		Kit.model(self, "Cornice_Marble_Center", Vector3(x, H, z1), PI)
	Kit.block(self, Vector3(0.0, CEILING * 0.5, z1 + 0.15), Vector3(W, CEILING, 0.3))
	# East and west.
	for i in int(L / 2.0):
		var z := Z0 + 1.0 + i * 2.0
		_panel("Marble_Plain_4", Vector3(W * 0.5, 0.0, z), -PI * 0.5)
		Kit.model(self, "Cornice_Marble_Center", Vector3(W * 0.5, H, z), -PI * 0.5)
		_panel("Marble_Plain_4", Vector3(-W * 0.5, 0.0, z), PI * 0.5)
		Kit.model(self, "Cornice_Marble_Center", Vector3(-W * 0.5, H, z), PI * 0.5)
	Kit.block(self, Vector3(W * 0.5 + 0.15, CEILING * 0.5, Z0 + L * 0.5), Vector3(0.3, CEILING, L))
	Kit.block(self, Vector3(-W * 0.5 - 0.15, CEILING * 0.5, Z0 + L * 0.5), Vector3(0.3, CEILING, L))


func _panel(name: String, at: Vector3, yaw: float) -> void:
	Kit.model(self, name, at, yaw)


func _ceiling() -> void:
	Kit.slab(self, Vector3(0.0, CEILING + 0.05, Z0 + L * 0.5), Vector3(W + 1.2, 0.1, L + 1.2), Kit.flat(Color(0.16, 0.13, 0.11), 0.9))


func _door() -> void:
	door = GuardDoor.new()
	door.name = "ServiceDoor"
	door.position = HINGE
	add_child(door)
	var sign := Label3D.new()
	sign.text = "SERVICE"
	sign.font_size = 64
	sign.pixel_size = 0.004
	sign.modulate = Color(0.85, 0.7, 0.4)
	sign.outline_size = 0
	if HotelTheme.heading_font:
		sign.font = HotelTheme.heading_font
	sign.position = Vector3(0.0, 2.65, Z0 + 0.24)
	add_child(sign)


## A few meters of kitchen corridor past the door, so an open door shows
## somewhere to go, and the area that counts you as through.
func _beyond() -> void:
	var z := Z0 - 2.0
	Kit.model(self, "Floor_4x4", Vector3(0.0, 0.0, z))
	Kit.block(self, Vector3(0.0, -0.15, z), Vector3(4.0, 0.3, 4.0))
	for x in [-1.0, 1.0]:
		_panel("Marble_Plain_4", Vector3(x, 0.0, Z0 - 4.0), 0.0)
	for zz in [Z0 - 1.0, Z0 - 3.0]:
		_panel("Marble_Plain_4", Vector3(2.0, 0.0, zz), -PI * 0.5)
		_panel("Marble_Plain_4", Vector3(-2.0, 0.0, zz), PI * 0.5)
	Kit.block(self, Vector3(0.0, CEILING * 0.5, Z0 - 4.15), Vector3(4.0, CEILING, 0.3))
	Kit.block(self, Vector3(2.15, CEILING * 0.5, z), Vector3(0.3, CEILING, 4.0))
	Kit.block(self, Vector3(-2.15, CEILING * 0.5, z), Vector3(0.3, CEILING, 4.0))
	Kit.slab(self, Vector3(0.0, H + 0.05, z), Vector3(4.6, 0.1, 4.6), Kit.flat(Color(0.14, 0.12, 0.1), 0.9))
	through = Area3D.new()
	through.name = "Through"
	through.collision_layer = 0
	through.collision_mask = Kit.LAYER_PLAYER
	through.position = Vector3(0.0, 1.0, Z0 - 1.2)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.5, 2.0, 1.2)
	cs.shape = shape
	through.add_child(cs)
	add_child(through)


func _props() -> void:
	var z1 := Z0 + L
	for corner in [Vector3(-3.7, 0, Z0 + 0.3), Vector3(3.7, 0, Z0 + 0.3), Vector3(-3.7, 0, z1 - 0.3), Vector3(3.7, 0, z1 - 0.3)]:
		Kit.boxed(self, "Prop_Column_Trim", corner)
	Kit.boxed(self, "Prop_Planter_Single", Vector3(2.9, 0.0, z1 - 1.1))
	Kit.boxed(self, "Prop_Planter_Single", Vector3(-2.9, 0.0, Z0 + 5.0))
	for z in [Z0 + 3.0, Z0 + 7.0]:
		Kit.model(self, "Prop_Ornament_1", Vector3(-W * 0.5, 3.2, z), PI * 0.5)
		Kit.model(self, "Prop_Ornament_1", Vector3(W * 0.5, 3.2, z), -PI * 0.5)


func _lights() -> void:
	for z in [Z0 + 1.2, Z0 + 5.0, Z0 + 9.0]:
		var l := OmniLight3D.new()
		l.light_color = WARM
		l.light_energy = 2.2
		l.omni_range = 9.0
		l.omni_attenuation = 1.3
		l.position = Vector3(0.0, CEILING - 0.4, z)
		l.shadow_enabled = z == Z0 + 1.2
		add_child(l)
	var beyond := OmniLight3D.new()
	beyond.light_color = Color(0.8, 0.9, 1.0)
	beyond.light_energy = 1.2
	beyond.omni_range = 6.0
	beyond.position = Vector3(0.0, H - 0.4, Z0 - 2.0)
	add_child(beyond)


## An environment for the corridor: a dark warm ambient, no sky.
static func environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.015, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.36)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	return env
