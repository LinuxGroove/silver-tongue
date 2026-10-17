class_name StubHotel
extends Node3D
## A bare stand-in for the Meridian, for tests of the job: the same rooms,
## spots, points, links and doors (as [StubDoor]s with a slab each), a floor
## and no walls or models, so it builds in no time and nothing blocks a line.

const ZONES := {
	"staff_room": AABB(Vector3(14, -1, -34), Vector3(6, 6, 6)),
	"kitchen": AABB(Vector3(6, -1, -34), Vector3(14, 6, 14)),
	"ballroom": AABB(Vector3(-14, -1, -34), Vector3(20, 6, 16)),
	"office": AABB(Vector3(12, -1, -16), Vector3(6, 6, 10)),
	"corridor": AABB(Vector3(6, -1, -20), Vector3(6, 6, 14)),
	"lobby": AABB(Vector3(-14, -1, -18), Vector3(20, 6, 18)),
	"outside": AABB(Vector3(-30, -1, -6), Vector3(60, 6, 20)),
}

var spots := {}
var points := {}
var links: Array = []
var doors := {}
var extras := {"ballroom": [], "lobby": [], "kitchen": []}
var uses := {}


func _ready() -> void:
	build()


func build() -> void:
	if not spots.is_empty():
		return
	_spot("marcus", Vector3(9, 0, -19), 0.0)
	_spot("teo", Vector3(-4, 0, -17), 0.0)
	_spot("dana", Vector3(2, 0, -9), -PI / 2)
	_spot("laurent", Vector3(8, 0, -27), PI / 2)
	_spot("benny", Vector3(-12, 0, -9), PI / 2)
	_spot("okafor", Vector3(0, 0, -6), 0.0)
	_spot("okafor_stage", Vector3(-4, 0, -32), 0.0)
	_spot("celeste", Vector3(-10, 0, -8), PI)
	_spot("hugo", Vector3(-10, 0, -9.2), 0.0)
	_spot("celeste_in", Vector3(-8, 0, -24), 0.0)
	_spot("hugo_in", Vector3(-7, 0, -24), 0.0)
	_spot("smoke", Vector3(14, 0, -3), 0.0)
	_spot("office_guard", Vector3(11, 0, -11), PI / 2)
	_spot("held", Vector3(15, 0, -11), -PI / 2)
	_spot("crew_0", Vector3(-4, 0, -2), PI)
	_spot("crew_1", Vector3(-2.5, 0, -2), PI)
	_spot("ballroom_in", Vector3(-4, 0, -21), PI)
	points = {
		"lobby_front": Vector3(-4, 0, -3), "lobby_mid": Vector3(-4, 0, -10), "lobby_ball": Vector3(-4, 0, -16.5),
		"ball_in": Vector3(-4, 0, -20), "ball_stage": Vector3(-4, 0, -30), "lobby_east": Vector3(4, 0, -10),
		"corr_staff": Vector3(7.5, 0, -10), "corr_north": Vector3(9, 0, -18.5), "kitchen_in": Vector3(9, 0, -22),
		"kitchen_pass": Vector3(7.5, 0, -27), "ball_pass": Vector3(4.5, 0, -27), "corr_south": Vector3(9, 0, -7.5),
		"loading": Vector3(9, 0, -4), "corr_office": Vector3(11, 0, -11), "office_in": Vector3(13.5, 0, -11),
		"bar": Vector3(-9, 0, -9),
	}
	links = [
		["lobby_front", "lobby_mid", ""], ["lobby_mid", "lobby_ball", ""], ["lobby_ball", "ball_in", "ballroom"],
		["ball_in", "ball_stage", ""], ["lobby_mid", "lobby_east", ""], ["lobby_east", "corr_staff", "staff"],
		["corr_staff", "corr_north", ""], ["corr_north", "kitchen_in", "service"], ["kitchen_in", "kitchen_pass", ""],
		["kitchen_pass", "ball_pass", "pass"], ["ball_pass", "ball_in", ""], ["corr_staff", "corr_south", ""],
		["corr_south", "loading", "loading"], ["corr_staff", "corr_office", ""], ["corr_office", "office_in", "office"],
		["lobby_mid", "bar", ""],
	]
	_door("front", Vector3(-4, 0, 0), 0.0)
	_door("ballroom", Vector3(-4, 0, -18), 0.0)
	_door("pass", Vector3(6, 0, -27), PI / 2)
	_door("staff", Vector3(6, 0, -10), PI / 2)
	_door("service", Vector3(9, 0, -20), 0.0)
	_door("office", Vector3(12, 0, -11), PI / 2)
	_door("loading", Vector3(9, 0, -6), 0.0)
	var floor := StaticBody3D.new()
	floor.collision_layer = Kit.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 60)
	cs.shape = box
	cs.position = Vector3(0, -0.5, -15)
	floor.add_child(cs)
	add_child(floor)


func zone_at(p: Vector3) -> String:
	for z in ZONES:
		if (ZONES[z] as AABB).has_point(Vector3(p.x, 0.5, p.z)):
			return z
	return ""


func _spot(n: String, at: Vector3, yaw: float) -> void:
	spots[n] = Transform3D(Basis(Vector3.UP, yaw), at)


func _door(n: String, at: Vector3, yaw: float) -> void:
	var d := StubDoor.new()
	d.name = "Door_" + n
	d.door_name = n
	add_child(d)
	d.position = at
	d.rotation.y = yaw
	doors[n] = d


func environment() -> Environment:
	return Environment.new()
