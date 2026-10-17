class_name MenuBackdrop
extends Node3D
## The corridor behind the title: the service door, Marcus with his arms
## folded, from a few steps down the corridor.

var room: ServiceDoorRoom
var guard: Person
var camera: Camera3D


static func make() -> MenuBackdrop:
	return MenuBackdrop.new()


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = ServiceDoorRoom.environment()
	add_child(env)
	room = ServiceDoorRoom.new()
	add_child(room)
	var sheet := CharacterSheet.marcus()
	guard = Person.make(sheet.person_job, sheet.female, sheet.seed, sheet.person_look())
	guard.transform = room.guard_spot
	add_child(guard)
	guard.play("Idle_FoldArms")
	Face.make(guard)
	camera = Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.look_at_from_position(Vector3(2.4, 1.55, ServiceDoorRoom.Z0 + 4.6), Vector3(-0.4, 1.3, ServiceDoorRoom.Z0 + 0.6))
	camera.make_current()
