extends RefCounted
## Mae's house (game/venues/mae/): the building through the checks every
## venue passes ([VenueChecks]), and the house party played every way
## through, alone and with two, by [JobHarness].
##   godot --headless --path . tests/run_tests.tscn -- --only=mae

const DOORS: Array[String] = ["front", "back_room", "yard", "gate", "study", "safe", "terrace"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"crew_0": "street", "crew_1": "street", "gray_car": "street", "rocco_car": "street", "mae_street": "street",
	"gone": "street", "walt": "laundrette", "front_guard": "laundrette", "held": "back_room", "held_guard": "back_hall",
	"dot": "kitchen", "benny": "kitchen", "okafor": "kitchen", "mae": "living", "julian": "living", "rocco": "living",
	"dana": "living", "celeste": "living", "hugo": "living", "jojo": "living", "mae_dance": "living",
	"mae_desk": "study", "julian_study": "study", "rocco_study": "study", "safe_in": "study",
	"silas": "terrace", "nadia": "terrace", "mae_toast": "terrace", "julian_toast": "terrace", "rocco_toast": "terrace",
	"dot_toast": "terrace", "celeste_toast": "terrace", "hugo_toast": "terrace", "mae_fw": "terrace", "julian_fw": "terrace",
}


func _house(t: Node, open_doors := false) -> MaeHouse:
	return await VenueChecks.built(t, MaeHouse.new(), open_doors)


func test_builds(t) -> void:
	var h: MaeHouse = await _house(t)
	for d in DOORS:
		t.check(h.doors.get(d) is HotelDoor, "mae: the %s door" % d)
	t.check(h.doors.size() == DOORS.size(), "mae: no doors but the seven (%d)" % h.doors.size())
	VenueChecks.structure(t, h, "mae", SPOT_ZONES)
	for id in ["dial", "drawer", "safe_shelf", "case", "desk"]:
		t.check(h.uses.has(id), "mae: %s can be used" % id)
	var dial: Vector3 = h.uses.dial.global_position
	t.check(h.zone_at(dial) == "study" and dial.distance_to(h.doors.safe.centre()) < 2.0, "mae: the dial is beside the strongroom door, in the study")
	t.check(h.zone_at(h.uses.case.global_position + Vector3(0, 0.1, 0)) == "terrace", "mae: the buyer's case goes on the terrace")
	t.check(h.zone_at(h.uses.drawer.global_position + Vector3(0, 0.1, 0)) == "back_room", "mae: the drawer is in the back room")
	t.check(h.find_child("GrayCase", true, false) != null and h.find_child("Fireworks", true, false) != null, "mae: the case and the fireworks are there to show")
	t.check(h.extras.get("living", []).size() >= 5, "mae: a party in the living room")
	h.queue_free()


func test_spots(t) -> void:
	var h: MaeHouse = await _house(t)
	VenueChecks.standing_room(t, h, "mae")
	h.queue_free()


func test_links_clear(t) -> void:
	var h: MaeHouse = await _house(t, true)
	VenueChecks.walkable(t, h, "mae")
	h.queue_free()


func test_doors_block(t) -> void:
	var h: MaeHouse = await _house(t)
	await VenueChecks.doors_block(t, h, "mae")
	h.queue_free()
