extends RefCounted
## The Meridian (game/world/meridian.gd): it builds, people can stand at its
## spots and walk its links, its doors block when shut and not when open,
## locked doors stay shut, and its zones are the rooms of docs/m1.md.
##   godot --headless --path . tests/run_tests.tscn -- --only=hotel

const DOORS: Array[String] = ["front", "ballroom", "pass", "staff", "service", "office", "loading"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"marcus": "corridor", "teo": "lobby", "dana": "lobby", "laurent": "kitchen", "benny": "lobby",
	"okafor": "lobby", "okafor_stage": "ballroom", "celeste": "lobby", "hugo": "lobby",
	"celeste_in": "ballroom", "hugo_in": "ballroom", "smoke": "outside", "office_guard": "corridor",
	"held": "office", "crew_0": "lobby", "crew_1": "lobby", "ballroom_in": "ballroom",
}
const VIEWS: Array[String] = ["entrance", "lobby", "reception", "bar", "ballroom_doors", "ballroom", "stage", "pass",
		"kitchen", "staff_room", "corridor", "service_door", "office", "loading_bay", "street"]
## Places in each room of the table in docs/m1.md.
const ROOM_SAMPLES := {
	"lobby": [Vector3(-4, 1, -9), Vector3(-13, 1, -1), Vector3(5, 1, -17), Vector3(-13, 1, -17)],
	"ballroom": [Vector3(-4, 1, -26), Vector3(-13, 1, -33), Vector3(5, 1, -19)],
	"kitchen": [Vector3(10, 1, -25), Vector3(7, 1, -33), Vector3(19, 1, -21), Vector3(13, 1, -29)],
	"staff_room": [Vector3(17, 1, -31), Vector3(15, 1, -33), Vector3(19, 1, -29)],
	"corridor": [Vector3(9, 1, -12), Vector3(7, 1, -19), Vector3(11, 1, -7)],
	"office": [Vector3(15, 1, -11), Vector3(17, 1, -7), Vector3(13, 1, -15)],
	"outside": [Vector3(-4, 1, 5), Vector3(12, 1, -3), Vector3(19, 1, -1), Vector3(30, 1, 8)],
}
## Head room: a spot's or extra's person is a 0.25 m ball at hip and at head height.
const BODY := 0.25


func _hotel(t: Node, open_doors := false) -> Meridian:
	var h := Meridian.new()
	h.build()
	if open_doors:
		for d in h.doors.values():
			d.open()
	t.add_child(h)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	return h


func _space(t: Node) -> PhysicsDirectSpaceState3D:
	return t.get_tree().root.get_world_3d().direct_space_state


func _ray(t: Node, a: Vector3, b: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b, mask)
	return _space(t).intersect_ray(q)


## What solid things a ball at `p` touches.
func _touching(t: Node, p: Vector3, r: float, mask: int) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	q.shape = s
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = mask
	return _space(t).intersect_shape(q, 4)


func test_builds(t) -> void:
	var h: Meridian = await _hotel(t)
	for d in DOORS:
		t.check(h.doors.get(d) is HotelDoor, "hotel: the %s door" % d)
	t.check(h.doors.size() == DOORS.size(), "hotel: no doors but the seven (%d)" % h.doors.size())
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
	t.check(h.environment() is Environment, "hotel: an environment")
	h.queue_free()


func test_spots(t) -> void:
	var h: Meridian = await _hotel(t)
	for s in SPOT_ZONES:
		var p: Vector3 = (h.spots[s] as Transform3D).origin
		t.check(absf(p.y) < 0.01, "hotel: spot %s is on the floor" % s)
		t.check(h.zone_at(p + Vector3.UP) == SPOT_ZONES[s], "hotel: spot %s is in the %s (%s)" % [s, SPOT_ZONES[s], h.zone_at(p + Vector3.UP)])
		t.check(h.points.has(s) and h.points[s].is_equal_approx(p), "hotel: spot %s is a point people walk to" % s)
		for y in [0.9, 1.6]:
			var hit := _touching(t, p + Vector3(0, y, 0), BODY, Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "hotel: room to stand at %s (%s)" % [s, hit[0].collider.name if hit else ""])
	for room in h.extras:
		for x in h.extras[room]:
			var p: Vector3 = (x as Transform3D).origin
			t.check(h.zone_at(p + Vector3.UP) == room, "hotel: the %s's crowd is in it (%s)" % [room, p])
			var hit := _touching(t, p + Vector3(0, 1.2, 0), 0.22, Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "hotel: room for a guest at %s (%s)" % [p, hit[0].collider.name if hit else ""])
	h.queue_free()


func test_links_clear(t) -> void:
	var h: Meridian = await _hotel(t, true)
	for l in h.links:
		var a: Vector3 = h.points[l[0]]
		var b: Vector3 = h.points[l[1]]
		for side in [-0.2, 0.0, 0.2]:
			var off: Vector3 = (b - a).cross(Vector3.UP).normalized() * side
			var hit := _ray(t, a + off + Vector3(0, 0.45, 0), b + off + Vector3(0, 0.45, 0), Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "hotel: %s to %s is clear at knee height (%s at %s)" % [l[0], l[1], hit.collider.name if hit else "", hit.position if hit else ""])
	# Everyone can get everywhere from where the crew starts.
	var seen := {"crew_0": true}
	var todo := ["crew_0"]
	while not todo.is_empty():
		var n = todo.pop_back()
		for l in h.links:
			for k in 2:
				if l[k] == n and not seen.has(l[1 - k]):
					seen[l[1 - k]] = true
					todo.append(l[1 - k])
	for p in h.points:
		t.check(seen.has(p), "hotel: %s can be reached from the front" % p)
	h.queue_free()


func test_doors_block(t) -> void:
	var h: Meridian = await _hotel(t)
	for name in DOORS:
		var d: HotelDoor = h.doors[name]
		var c := d.centre() + Vector3(0, 1.0, 0)
		var across := d.global_basis.z.normalized()
		var hit := _ray(t, c - across, c + across, Kit.LAYER_SOLID)
		t.check(not hit.is_empty() and hit.collider.get_parent() == d, "hotel: the shut %s door blocks" % name)
		t.check(not hit.is_empty() and str(hit.collider.get_meta("use", "")) == "door:" + name, "hotel: the %s door's leaf says what it is" % name)
		t.check(d.open(), "hotel: the %s door opens" % name)
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	for name in DOORS:
		var d: HotelDoor = h.doors[name]
		var c := d.centre() + Vector3(0, 1.0, 0)
		var across := d.global_basis.z.normalized()
		var hit := _ray(t, c - across * 1.5, c + across * 1.5, Kit.LAYER_SOLID)
		t.check(hit.is_empty(), "hotel: the open %s door lets you through (%s)" % [name, hit.collider.name if hit else ""])
		d.close()
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
	t.check(h.zone_at(Vector3(15, 1, -18)) == "", "hotel: the void behind the office is nowhere")
	t.check(h.zone_at(Vector3(-4, 1, -18.5)) == "ballroom" and h.zone_at(Vector3(-4, 1, -17.5)) == "lobby", "hotel: the ballroom doors are between the lobby and the ballroom")
	h.build()
	for p in h.points:
		t.check(h.zone_at(h.points[p] + Vector3.UP) != "", "hotel: point %s is somewhere" % p)
	h.free()
