class_name StubDoor
extends Node3D
## A door for [StubHotel]: a slab on the Doors layer that's there when shut
## and gone when open, with the same signals and calls as a [HotelDoor]
## (a locked one won't open).

signal opened
signal closed

var door_name := ""
var locked := false
var auto := false
var is_open := false
var _shape: CollisionShape3D


func _ready() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Kit.LAYER_DOORS
	body.collision_mask = 0
	body.set_meta("use", "door:" + door_name)
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 2.4, 0.15)
	_shape.shape = box
	_shape.position = Vector3(0, 1.2, 0)
	body.add_child(_shape)
	add_child(body)


func open(_from := Vector3.INF) -> bool:
	if locked:
		return false
	if is_open:
		return true
	is_open = true
	if _shape:
		_shape.set_deferred("disabled", true)
	opened.emit()
	return true


func close() -> void:
	if not is_open:
		return
	is_open = false
	if _shape:
		_shape.set_deferred("disabled", false)
	closed.emit()
