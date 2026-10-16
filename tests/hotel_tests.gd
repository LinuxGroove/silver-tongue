extends RefCounted
## The Meridian (game/venues/meridian/meridian.gd), through the checks every
## venue passes ([VenueChecks]) and its own: it builds, people can stand at its
## spots and walk its links, its doors block when shut and not when open,
## locked doors stay shut, and its zones are the rooms of docs/m1.md. The
## wedding's and the press call's hotel (jobs 2 and 3) pass the same checks.
##   godot --headless --path . tests/run_tests.tscn -- --only=hotel

const DOORS: Array[String] = ["front", "ballroom", "pass", "staff", "service", "office", "loading", "manager"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"marcus": "corridor", "teo": "lobby", "dana": "lobby", "laurent": "kitchen", "benny": "lobby",
	"okafor": "lobby", "okafor_stage": "ballroom", "celeste": "lobby", "hugo": "lobby",
	"celeste_in": "ballroom", "hugo_in": "ballroom", "smoke": "outside", "office_guard": "corridor",
	"held": "office", "crew_0": "lobby", "crew_1": "lobby", "ballroom_in": "ballroom",
	"crew_bay": "outside", "okafor_office": "manager_office", "gus": "lobby", "pippa": "lobby", "pippa_in": "ballroom",
	"ingrid": "lobby", "wren_lobby": "lobby", "priya_lobby": "lobby", "wren": "ballroom", "priya": "ballroom",
	"ingrid_stage": "ballroom", "rafe": "ballroom", "okafor_bar": "lobby",
}
const VIEWS: Array[String] = ["entrance", "lobby", "reception", "bar", "ballroom_doors", "ballroom", "stage", "pass",
		"kitchen", "staff_room", "corridor", "service_door", "office", "manager_door", "manager_office", "loading_bay", "street"]
## Places in each room of the table in docs/m1.md.
const ROOM_SAMPLES := {
	"lobby": [Vector3(-4, 1, -9), Vector3(-13, 1, -1), Vector3(5, 1, -17), Vector3(-13, 1, -17)],
	"ballroom": [Vector3(-4, 1, -26), Vector3(-13, 1, -33), Vector3(5, 1, -19)],
	"kitchen": [Vector3(10, 1, -25), Vector3(7, 1, -33), Vector3(19, 1, -21), Vector3(13, 1, -29)],
	"staff_room": [Vector3(17, 1, -31), Vector3(15, 1, -33), Vector3(19, 1, -29)],
	"corridor": [Vector3(9, 1, -12), Vector3(7, 1, -19), Vector3(11, 1, -7)],
	"office": [Vector3(15, 1, -11), Vector3(17, 1, -7), Vector3(13, 1, -15)],
	"manager_office": [Vector3(15, 1, -18), Vector3(13, 1, -19.5), Vector3(19.5, 1, -16.5)],
	"outside": [Vector3(-4, 1, 5), Vector3(12, 1, -3), Vector3(19, 1, -1), Vector3(30, 1, 8)],
}


func _hotel(t: Node, open_doors := false, setting := "gala") -> Meridian:
	var h := Meridian.new()
	h.setting = setting
	return await VenueChecks.built(t, h, open_doors)


func test_builds(t) -> void:
	var h: Meridian = await _hotel(t)
	for d in DOORS:
		t.check(h.doors.get(d) is HotelDoor, "hotel: the %s door" % d)
	t.check(h.doors.size() == DOORS.size(), "hotel: no doors but the eight (%d)" % h.doors.size())
	for s in SPOT_ZONES:
		t.check(h.spots.has(s), "hotel: spot %s" % s)
	for v in VIEWS:
		t.check(h.views.get(v) is Transform3D, "hotel: view %s" % v)
	for id in ["jackets", "keypad"]:
		var u: StaticBody3D = h.uses.get(id)
		t.check(u != null and u.collision_layer == Kit.LAYER_INTERACT and u.get_meta("use", "") == id, "hotel: %s can be used" % id)
	t.check(h.zone_at(h.uses.jackets.global_position) == "staff_room", "hotel: the jackets are in the staff room")
	var pad: Vector3 = h.uses.keypad.global_position
	t.check(pad.y > 1.0 and pad.y < 1.5, "hotel: the keypad is at hand height (%.2f)" % pad.y)
	t.check(h.zone_at(pad) == "corridor" and pad.distance_to(h.doors.service.centre()) < 3.0, "hotel: the keypad is beside the service door, corridor side")
	t.check(h.extras.get("ballroom", []).size() >= 12, "hotel: a crowd in the ballroom")
	t.check(h.extras.get("lobby", []).size() >= 3, "hotel: people in the lobby")
	t.check(h.extras.get("kitchen", []).size() >= 2, "hotel: cooks in the kitchen")
	for l in h.links:
		t.check(h.points.has(l[0]) and h.points.has(l[1]), "hotel: link %s-%s joins two points" % [l[0], l[1]])
		t.check(l[2] == "" or h.doors.has(l[2]), "hotel: link %s-%s goes through a door there is" % [l[0], l[1]])
	VenueChecks.structure(t, h, "hotel", SPOT_ZONES)
	h.queue_free()


func test_spots(t) -> void:
	var h: Meridian = await _hotel(t)
	VenueChecks.standing_room(t, h, "hotel")
	h.queue_free()


func test_links_clear(t) -> void:
	var h: Meridian = await _hotel(t, true)
	VenueChecks.walkable(t, h, "hotel")
	h.queue_free()


func test_doors_block(t) -> void:
	var h: Meridian = await _hotel(t)
	t.check(h.doors.size() == DOORS.size(), "hotel: no doors but the eight (%d)" % h.doors.size())
	await VenueChecks.doors_block(t, h, "hotel")
	# The staff door swings away from whoever opens it.
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	var staff: HotelDoor = h.doors.staff
	staff.open(Vector3(4.0, 0.0, -10.0))
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	var leaf_mid := staff.leaves[0].global_transform * Vector3(-staff.width * 0.5, 1.0, 0.0)
	t.check(leaf_mid.x > 6.2, "hotel: opened from the lobby, the staff door swings into the corridor (%.2f)" % leaf_mid.x)
	staff.close()
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	staff.open(Vector3(8.0, 0.0, -10.0))
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	leaf_mid = staff.leaves[0].global_transform * Vector3(-staff.width * 0.5, 1.0, 0.0)
	t.check(leaf_mid.x < 5.8, "hotel: opened from the corridor, it swings into the lobby (%.2f)" % leaf_mid.x)
	h.queue_free()


func test_front_doors_open_for_people(t) -> void:
	var h: Meridian = await _hotel(t)
	var front: HotelDoor = h.doors.front
	var someone := StaticBody3D.new()
	someone.collision_layer = Kit.LAYER_PEOPLE
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	someone.add_child(cs)
	someone.position = Vector3(-4.0, 0.0, 1.6)
	t.add_child(someone)
	t.check(await t.until(func() -> bool: return front.is_open, 2.0), "hotel: the front doors open for someone outside")
	someone.position = Vector3(-4.0, 0.0, 8.0)
	t.check(await t.until(func() -> bool: return not front.is_open, HotelDoor.LINGER + 2.0), "hotel: and shut once they've gone")
	front.open()
	await t.until(func() -> bool: return false, HotelDoor.LINGER + 0.5)
	t.check(front.is_open, "hotel: opened on purpose, the front doors stay open")
	front.close()
	front.locked = true
	someone.position = Vector3(-4.0, 0.0, 1.6)
	await t.until(func() -> bool: return false, 1.0)
	t.check(not front.is_open, "hotel: locked, the front doors stay shut")
	someone.queue_free()
	h.queue_free()


func test_locked_doors(t) -> void:
	var h: Meridian = await _hotel(t)
	for name in DOORS:
		var d: HotelDoor = h.doors[name]
		d.locked = true
		var yaw := d.leaves[0].rotation.y
		t.check(not d.open(), "hotel: the locked %s door won't open" % name)
		t.check(not d.is_open and is_equal_approx(d.leaves[0].rotation.y, yaw), "hotel: the locked %s door stays shut" % name)
		d.locked = false
		t.check(d.open(Vector3.ZERO), "hotel: unlocked, the %s door opens" % name)
	h.queue_free()


func test_zones(t) -> void:
	var h := Meridian.new()
	for room in ROOM_SAMPLES:
		for p in ROOM_SAMPLES[room]:
			t.check(h.zone_at(p) == room, "hotel: %s is in the %s (%s)" % [p, room, h.zone_at(p)])
	t.check(h.zone_at(Vector3(15, 1, -18)) == "manager_office", "hotel: Mr Okafor's office is behind the security office")
	t.check(h.zone_at(Vector3(19, 1, -10)) == "", "hotel: the void east of the security office is nowhere")
	t.check(h.zone_at(Vector3(11.5, 1, -18)) == "corridor" and h.zone_at(Vector3(12.5, 1, -18)) == "manager_office", "hotel: the manager's door is between the corridor and his office")
	t.check(h.zone_at(Vector3(-4, 1, -18.5)) == "ballroom" and h.zone_at(Vector3(-4, 1, -17.5)) == "lobby", "hotel: the ballroom doors are between the lobby and the ballroom")
	h.build()
	for p in h.points:
		t.check(h.zone_at(h.points[p] + Vector3.UP) != "", "hotel: point %s is somewhere" % p)
	h.free()


## The wedding and the press call change a few things in the rooms: each
## still passes every check, and has its own things to use.
func test_settings(t) -> void:
	for setting in ["wedding", "press"]:
		var label := "hotel (%s)" % setting
		var h: Meridian = await _hotel(t, false, setting)
		VenueChecks.structure(t, h, label, SPOT_ZONES)
		VenueChecks.standing_room(t, h, label)
		t.check(h.doors.size() == DOORS.size(), "%s: the same eight doors" % label)
		h.queue_free()
		h = await _hotel(t, true, setting)
		VenueChecks.walkable(t, h, label)
		h.queue_free()
	var gala: Meridian = await _hotel(t)
	for id in ["okafor_desk", "plinth", "plinth_copy", "trolley"]:
		t.check(not gala.uses.has(id), "hotel: nothing at %s at the gala" % id)
	gala.queue_free()
	var wedding: Meridian = await _hotel(t, false, "wedding")
	t.check(str(wedding.uses.get("okafor_desk").get_meta("use", "")) == "item:guest_list", "hotel: the guest list lies on Mr Okafor's desk at the wedding")
	t.check(wedding.zone_at(wedding.uses.okafor_desk.global_position + Vector3(0, 0.1, 0)) == "manager_office", "hotel: and his desk is in his office")
	wedding.queue_free()
	var press: Meridian = await _hotel(t, false, "press")
	t.check(str(press.uses.get("plinth").get_meta("use", "")) == "item:rose_case" and str(press.uses.get("plinth_copy").get_meta("use", "")) == "item:mae_case", "hotel: the Rose's case and Mae's share the plinth at the press call")
	t.check(press.zone_at(press.uses.plinth.global_position + Vector3(0, 0.1, 0)) == "ballroom", "hotel: the plinth is in the ballroom")
	t.check(press.zone_at(press.uses.trolley.global_position + Vector3(0, 0.1, 0)) == "kitchen", "hotel: the trolley is in the kitchen")
	t.check(press.environment().background_mode == Environment.BG_SKY, "hotel: a morning sky for the press call")
	press.queue_free()
