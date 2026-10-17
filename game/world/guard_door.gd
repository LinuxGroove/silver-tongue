class_name GuardDoor
extends Node3D
## The service door: a wooden leaf that stays shut until the guard lets you
## through, then swings away from you. The hinge is this node's origin, at the
## right jamb seen from the corridor; the leaf hangs to -x from it.

signal opened

const WIDTH := 1.12
const HEIGHT := 2.2
const SWING := deg_to_rad(105.0)

var is_open := false
var body: StaticBody3D
var _leaf: Node3D
var _tween: Tween


func _ready() -> void:
	if body == null:
		build()


func build() -> void:
	body = StaticBody3D.new()
	body.name = "Leaf"
	body.collision_layer = Kit.LAYER_DOORS
	body.collision_mask = 0
	add_child(body)
	_leaf = Kit.model(body, "Door_1", Vector3.ZERO, 0.0, Vector3(WIDTH, 1.0, 1.0))
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(WIDTH, HEIGHT, 0.12)
	cs.shape = shape
	cs.position = Vector3(-WIDTH * 0.5, HEIGHT * 0.5, 0.0)
	body.add_child(cs)


## Swings the door open (the guard has let you through).
func open() -> void:
	if is_open:
		return
	is_open = true
	_swing(-SWING)
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_swing(0.0)


func _swing(to: float) -> void:
	if _tween:
		_tween.kill()
	if not is_inside_tree():
		body.rotation.y = to
		return
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(body, "rotation:y", to, 1.3)
