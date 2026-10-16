class_name CrewAvatar
extends Node3D
## A crewmate from another device: their body in their cover's clothes,
## moved by the poses their device sends, with their voice played from
## their mouth. On the host it's also what the characters see and hear.

const WALK_SPEED := 0.4

var info: CrewInfo
var person: Person
var face: Face
## Their voice, relayed from their device.
var voice_player: AudioStreamPlayer3D
var _outfit := ""
var _target := Vector3.ZERO
var _look := Vector3.FORWARD
var _crouch := false
var _has_pose := false


static func make(p_info: CrewInfo) -> CrewAvatar:
	var a := CrewAvatar.new()
	a.name = "Crew%d" % p_info.id
	a.info = p_info
	return a


func _ready() -> void:
	voice_player = AudioStreamPlayer3D.new()
	voice_player.name = "Voice"
	voice_player.position = Vector3(0, 1.6, 0.05)
	voice_player.unit_size = 4.0
	voice_player.max_distance = 30.0
	add_child(voice_player)
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = Kit.LAYER_PEOPLE
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	body.add_child(cs)
	add_child(body)
	dress()


## Puts on their current outfit (after the jacket goes on or off).
func dress() -> void:
	if info.outfit == _outfit and person:
		return
	_outfit = info.outfit
	if person:
		person.queue_free()
	var o: Dictionary = Covers.outfit(info.outfit)
	person = Person.make(str(o.job), info.female, 1000 + info.id, info.look)
	add_child(person)
	face = Face.make(person)
	person.play("Idle")


## Where they are and which way they look, from their device.
func apply_pose(at: Vector3, look: Vector3, crouch: bool) -> void:
	_target = at
	if look.length() > 0.01:
		_look = look.normalized()
	_crouch = crouch
	if not _has_pose:
		_has_pose = true
		global_position = at


## Puts them exactly where their device says, now (when they speak).
func snap(at: Vector3, look: Vector3) -> void:
	apply_pose(at, look, _crouch)
	global_position = at
	var flat := Vector3(_look.x, 0, _look.z)
	if flat.length() > 0.01:
		rotation.y = atan2(flat.x, flat.z)


func mouth_position() -> Vector3:
	return global_position + Vector3(0, 1.05 if _crouch else 1.6, 0)


func look_dir() -> Vector3:
	return _look


func _process(delta: float) -> void:
	# Until their first pose comes, they stay where the scene put them.
	if not _has_pose:
		_target = global_position
	var to := _target - global_position
	var moving := Vector2(to.x, to.z).length() > 0.05
	if to.length() > 3.0:
		global_position = _target
	else:
		global_position = global_position.lerp(_target, 1.0 - exp(-delta * 10.0))
	var flat := Vector3(_look.x, 0, _look.z)
	if flat.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(flat.x, flat.z), 1.0 - exp(-delta * 10.0))
	if person == null:
		return
	if _crouch:
		person.play("Crouch_Fwd" if moving else "Crouch_Idle")
	elif moving:
		person.play("Walk")
	elif voice_player.playing:
		person.play("Idle_Talking")
	else:
		person.play("Idle")
	if face:
		face.level = clampf(_voice_level(), 0.0, 1.0)


func _voice_level() -> float:
	if not voice_player.playing:
		return 0.0
	return 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025)
