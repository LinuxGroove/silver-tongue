extends RefCounted
## The Marlin (game/venues/marlin/) and its three jobs: the yacht on each of
## its nights through the checks every venue passes ([VenueChecks]), and
## every way through Aboard, The captain's safe and The auction, alone and
## with two, by [JobHarness].
##   godot --headless --path . tests/run_tests.tscn -- --only=marlin

const NIGHTS: Array[String] = ["aboard", "safe", "auction"]
## Spots on every night, and the zone each is in.
const SPOT_ZONES := {
	"teo_gang": "aft_deck", "kofi_aft": "aft_deck", "freya_stern": "aft_deck", "bianca_bar": "aft_deck",
	"celeste_aft": "aft_deck", "hugo_aft": "aft_deck", "aft_port": "aft_deck", "aft_sb": "aft_deck",
	"rocco": "galley", "galley_c": "galley", "ollie": "mess", "laundry": "laundry", "held": "cabin_b",
	"held_guard": "crew_hall", "saloon_in": "saloon", "saloon_c": "saloon", "dining_e": "dining", "lobby_c": "lobby",
	"sun_c": "sun_deck", "sky_c": "sky_lounge", "captain_c": "captain", "ollie_bed": "captain",
	"anders_cabin": "captain", "safe_out": "captain", "safe_in": "safe", "ollie_ensuite": "captain",
	"freya": "bridge", "anders": "bridge",
}
## And each night's own.
const NIGHT_SPOTS := {
	"aboard": {"crew_0": "outside", "crew_1": "outside", "kofi": "outside", "jun": "outside", "bianca_quay": "outside", "sal": "outside"},
	"safe": {"crew_0": "aft_deck", "crew_1": "aft_deck", "anders_saloon": "saloon", "teo_rose": "saloon", "rupert_rose": "saloon"},
	"auction": {"crew_0": "aft_deck", "crew_1": "aft_deck", "nina_desk": "aft_deck", "rupert": "saloon", "nina_phone": "saloon",
		"margit": "saloon", "joost": "saloon", "celeste_side": "saloon", "hugo_side": "saloon"},
}
const DOORS: Array[String] = ["crew", "saloon", "galley", "cabin_a", "cabin_b", "sun", "captain", "safe", "bridge"]
## Places in each room.
const ROOM_SAMPLES := {
	"aft_deck": [Vector3(0, 2, -5), Vector3(-3, 2, -8)], "saloon": [Vector3(1, 2, -14), Vector3(-3, 2, -19)],
	"dining": [Vector3(0, 2, -22)], "lobby": [Vector3(0, 2, -28)], "crew_stair": [Vector3(-3.7, 0, -14)],
	"galley": [Vector3(2.5, -0.5, -20)], "mess": [Vector3(-3, -0.5, -21)], "crew_hall": [Vector3(0, -0.5, -25)],
	"cabin_a": [Vector3(-3, -0.5, -28)], "laundry": [Vector3(2.5, -0.5, -24.4)], "cabin_b": [Vector3(3, -0.5, -29)],
	"sun_deck": [Vector3(0, 5, -8)], "sky_lounge": [Vector3(0, 5, -17)], "captain": [Vector3(-2, 5, -25)],
	"safe": [Vector3(-3.3, 5, -32)], "upper_hall": [Vector3(2.5, 5, -27)], "bridge": [Vector3(0, 5, -36)],
	"outside": [Vector3(0, 1, 6), Vector3(10, 1, 20)],
}


func _spots(night: String) -> Dictionary:
	var s := SPOT_ZONES.duplicate()
	s.merge(NIGHT_SPOTS[night])
	return s


func test_builds(t) -> void:
	for night in NIGHTS:
		var label := "marlin (%s)" % night
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night))
		for d in DOORS:
			t.check(v.doors.get(d) is HotelDoor, "%s: the %s door" % [label, d])
		t.check(v.doors.has("gangway") == (night != "safe"), "%s: a gangway only when she's moored" % label)
		t.check(v.uses.has("stores") == (night == "aboard"), "%s: the stores on the quay only tonight" % label)
		t.check(v.uses.has("safe_shelf") == (night == "safe"), "%s: the file in the safe only tonight" % label)
		t.check(v.uses.has("paddle") == (night == "auction") and v.uses.has("rostrum") == (night == "auction"), "%s: the desk and rostrum only at the sale" % label)
		t.check(v.uses.has("safe_keypad"), "%s: the strongroom's keypad" % label)
		var pad: Vector3 = v.uses.safe_keypad.global_position
		t.check(v.zone_at(pad) == "captain" and pad.distance_to(v.doors.safe.centre()) < 1.5, "%s: the keypad is by the strongroom door, cabin side" % label)
		VenueChecks.structure(t, v, label, _spots(night))
		VenueChecks.standing_room(t, v, label)
		v.queue_free()


func test_walkable(t) -> void:
	for night in NIGHTS:
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night), true)
		VenueChecks.walkable(t, v, "marlin (%s)" % night)
		v.queue_free()


func test_doors_block(t) -> void:
	for night in ["aboard", "safe"]:
		var v: Marlin = await VenueChecks.built(t, Marlin.new(night))
		await VenueChecks.doors_block(t, v, "marlin (%s)" % night)
		v.queue_free()


func test_zones(t) -> void:
	var v := Marlin.new()
	for room in ROOM_SAMPLES:
		for p in ROOM_SAMPLES[room]:
			t.check(v.zone_at(p) == room, "marlin: %s is in the %s (%s)" % [p, room, v.zone_at(p)])
	v.free()
