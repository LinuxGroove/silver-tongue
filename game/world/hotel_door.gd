class_name HotelDoor
extends Node3D
## A door in the Meridian: one leaf or two, hung from this node's origin.
## The doorway runs from the origin along local -x for `width` metres, in the
## plane z = 0; the first leaf hinges at the origin, and a double door's second
## leaf hinges at the far jamb (x = -width). A shut door blocks the way and
## sight; an open one swings its leaves out of the doorway, away from whoever
## opened it ([method open] with their position), or to -z when nobody's given.
##
## Each leaf is a StaticBody3D on [constant Kit.LAYER_DOORS] with the meta
## `"use"` = `"door:<id>"`. A `locked` door won't open. An `auto` door opens by
## itself for anyone who comes near (the front doors) and shuts again when
## they've gone, unless it was opened on purpose with [method open].
##
## [method build] makes the leaves and works before the door is in the tree;
## `_ready` builds it if nobody has.

signal opened
signal closed

const SWING := deg_to_rad(92.0)
const SECONDS := 1.1
## How far an `auto` door looks for people, either side of it.
const SENSE := 2.6
## How long an `auto` door stays open after the last person has gone.
const LINGER := 1.5

## The name the game knows the door by ("staff", "front"); the node's name if empty.
@export var id := ""
## The doorway's width, jamb to jamb.
@export var width := 1.1
@export var height := 2.2
## Two leaves meeting in the middle.
@export var double := false
## A kit or hotel model for the leaf, hinged at its origin and spanning -x; it's
## scaled to the leaf's width and height. Empty gives a plain painted leaf.
@export var model := ""
## How thick the leaf's collision is.
@export var thickness := 0.08
@export var locked := false
## Opens by itself for anyone near it.
@export var auto := false

var is_open := false
## The leaves, first (at the origin) then second (double doors only).
var leaves: Array[StaticBody3D] = []
var _tween: Tween
var _sensor: Area3D
var _auto_opened := false
var _linger := 0.0


func _ready() -> void:
	if leaves.is_empty():
		build()


func build() -> void:
	if not leaves.is_empty():
		return
	var leaf_w := width * 0.5 if double else width
	leaves.append(_leaf(leaf_w, Vector3.ZERO, 0.0))
	if double:
		leaves.append(_leaf(leaf_w, Vector3(-width, 0.0, 0.0), PI))
	if auto:
		_sensor = Area3D.new()
		_sensor.name = "Sensor"
		_sensor.collision_layer = 0
		_sensor.collision_mask = Kit.LAYER_PLAYER | Kit.LAYER_PEOPLE
		_sensor.monitorable = false
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(width + 1.0, 2.0, SENSE * 2.0)
		cs.shape = shape
		cs.position = Vector3(-width * 0.5, 1.0, 0.0)
		_sensor.add_child(cs)
		add_child(_sensor)
		_sensor.body_entered.connect(_on_body_entered)


func _leaf(w: float, at: Vector3, base_yaw: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Leaf%d" % (leaves.size() + 1)
	body.collision_layer = Kit.LAYER_DOORS
	body.collision_mask = 0
	body.position = at
	body.rotation.y = base_yaw
	body.set_meta("use", "door:" + door_id())
	body.set_meta("base_yaw", base_yaw)
	add_child(body)
	if model != "" and Kit.has(model):
		var n := Kit.model(body, model, Vector3.ZERO)
		var b := Kit.aabb_of(n)
		if b.size.x > 0.0 and b.size.y > 0.0:
			n.scale = Vector3(w / b.size.x, height / b.size.y, 1.0)
	else:
		var gap := 0.005
		Kit.slab(body, Vector3(-w * 0.5, height * 0.5, 0.0), Vector3(w - gap * 2.0, height - gap, thickness * 0.6), Kit.flat(Color(0.33, 0.24, 0.17), 0.5))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, height, thickness)
	cs.shape = shape
	cs.position = Vector3(-w * 0.5, height * 0.5, 0.0)
	body.add_child(cs)
	return body


## The name used in the leaves' "use" meta.
func door_id() -> String:
	return id if id != "" else String(name)


## The middle of the doorway, on the floor, in world space (local space before
## the door is in the tree).
func centre() -> Vector3:
	var c := Vector3(-width * 0.5, 0.0, 0.0)
	return to_global(c) if is_inside_tree() else transform * c


## Which side of the door `p` (world space) is on: 1 for local +z, -1 for -z.
func side_of(p: Vector3) -> int:
	var l := to_local(p) if is_inside_tree() else transform.affine_inverse() * p
	return 1 if l.z >= 0.0 else -1


## Swings the door open, away from `from` when it's given (world space).
## Returns false (and stays shut) when it's locked.
func open(from := Vector3.INF) -> bool:
	if locked:
		return false
	_auto_opened = false
	if is_open:
		return true
	var away := -1 if from == Vector3.INF else -side_of(from)
	_swing_to(away)
	is_open = true
	opened.emit()
	return true


func close() -> void:
	_auto_opened = false
	if not is_open:
		return
	is_open = false
	_swing_to(0)
	closed.emit()


## 0 shuts the leaves; 1 or -1 swings them toward that side (local z).
func _swing_to(dir: int) -> void:
	if _tween:
		_tween.kill()
		_tween = null
	var targets := []
	for i in leaves.size():
		var base: float = leaves[i].get_meta("base_yaw")
		# The first leaf swings toward -z with a negative turn; the second,
		# turned half round, with a positive one.
		var turn := 0.0 if dir == 0 else SWING * (1.0 if dir < 0 else -1.0) * (-1.0 if i == 0 else 1.0)
		targets.append(base + turn)
	if not is_inside_tree():
		for i in leaves.size():
			leaves[i].rotation.y = targets[i]
		return
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	for i in leaves.size():
		_tween.tween_property(leaves[i], "rotation:y", targets[i], SECONDS)


func _on_body_entered(body: Node3D) -> void:
	if locked:
		return
	_linger = LINGER
	if not is_open:
		open(body.global_position)
		_auto_opened = true


func _physics_process(delta: float) -> void:
	if not auto or _sensor == null or not _auto_opened or not is_open:
		return
	if _sensor.has_overlapping_bodies():
		_linger = LINGER
		return
	_linger -= delta
	if _linger <= 0.0:
		close()
