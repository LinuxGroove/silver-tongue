extends RefCounted
## The Tideline (game/venues/tideline/) and its three jobs: the building
## through the checks every venue passes ([VenueChecks]), each job's data and
## routines, every way through each job played with scripted brains, the
## ways it goes wrong, the cameras, and the cast's scripted replies.
##   godot --headless --path . tests/run_tests.tscn -- --only=tideline

const DOORS: Array[String] = ["front", "high_limit", "staff", "cage", "vault", "count_room", "eye", "office", "staff_room", "back"]
## Every spot, and the zone it's in.
const SPOT_ZONES := {
	"crew_0": "outside", "crew_1": "outside", "teo": "outside", "kerb": "outside", "tess_smoke": "outside",
	"panel": "outside", "back_out": "outside", "desi": "floor", "bea_bar": "floor", "pilar": "floor",
	"marcus": "floor", "lyle": "floor", "window_2": "floor", "staff_out": "floor", "front_in": "floor",
	"augie": "pit", "tess": "pit", "horace": "lounge", "marisol": "lounge", "anton": "high_limit",
	"hugo": "high_limit", "hl_in": "high_limit", "corridor_check": "corridor", "office_guard": "corridor",
	"count_out": "corridor", "staff_in": "corridor", "count_in": "count_room", "marcus_count": "count_room",
	"gloria": "count_room", "count_look": "count_room", "wes": "eye", "eye_in": "eye", "held": "office",
	"office_in": "office", "lockers": "staff_room", "staff_room_in": "staff_room", "bea": "cage", "noor": "cage",
	"horace_window": "cage", "horace_listen": "cage", "noor_vault": "cage", "horace_vault": "cage",
	"cage_in": "cage", "vault_in": "vault", "rose_table": "vault",
}
## Places in each room, for the zones.
const ROOM_SAMPLES := {
	"floor": [Vector3(-4, 1, -9), Vector3(-15, 1, -3), Vector3(7, 1, -23), Vector3(-16, 1, -24)],
	"pit": [Vector3(-3, 1, -15)],
	"lounge": [Vector3(15, 1, -3), Vector3(24, 1, -1)],
	"high_limit": [Vector3(-11, 1, -30), Vector3(-6, 1, -36)],
	"cage": [Vector3(13, 1, -10), Vector3(11, 1, -7)],
	"vault": [Vector3(18.5, 1, -10)],
	"corridor": [Vector3(18, 1, -16)],
	"count_room": [Vector3(13, 1, -22)],
	"eye": [Vector3(19.5, 1, -22)],
	"office": [Vector3(24, 1, -22)],
	"staff_room": [Vector3(23.5, 1, -10)],
	"outside": [Vector3(-4, 1, 5), Vector3(30, 1, -10), Vector3(0, 1, 16)],
}


func _venue(t: Node, open_doors := false) -> Tideline:
	return await VenueChecks.built(t, Tideline.new(), open_doors)


#region The building

func test_builds(t) -> void:
	var v: Tideline = await _venue(t)
	for d in DOORS:
		t.check(v.doors.get(d) is HotelDoor, "tideline: the %s door" % d)
	t.check(v.doors.size() == DOORS.size(), "tideline: no doors but the ten (%d)" % v.doors.size())
	for z in ROOM_SAMPLES:
		for p in ROOM_SAMPLES[z]:
			t.check(v.zone_at(p) == z, "tideline: %s is in the %s (%s)" % [p, z, v.zone_at(p)])
	for id in ["count_pad", "back_pad", "cam_panel", "count_desk", "vault_table", "request"]:
		t.check(v.uses.has(id), "tideline: %s can be used" % id)
	t.check(str(v.uses.count_desk.get_meta("use", "")) == "item:count_sheet", "tideline: the count sheet lies on the count table")
	t.check(str(v.uses.vault_table.get_meta("use", "")) == "item:rose", "tideline: the Rose lies on the vault's table")
	t.check(v.zone_at(v.uses.count_pad.global_position) == "corridor" and v.uses.count_pad.global_position.distance_to(v.doors.count_room.centre()) < 2.0, "tideline: the count room's keypad is beside its door")
	t.check(v.zone_at(v.uses.back_pad.global_position) == "outside" and v.uses.back_pad.global_position.distance_to(v.doors.back.centre()) < 2.0, "tideline: the back door's keypad is outside it")
	t.check(v.zone_at(v.uses.vault_table.global_position) == "vault", "tideline: the Rose is in the vault")
	t.check(v.extras.get("floor", []).size() >= 12, "tideline: a crowd on the floor")
	t.check(v.extras.get("pit", []).size() >= 4, "tideline: dealers in the pit")
	t.check(v.extras.get("lounge", []).size() >= 4, "tideline: people in the lounge")
	VenueChecks.structure(t, v, "tideline", SPOT_ZONES)
	v.queue_free()


func test_spots(t) -> void:
	var v: Tideline = await _venue(t)
	VenueChecks.standing_room(t, v, "tideline")
	v.queue_free()


func test_links_clear(t) -> void:
	var v: Tideline = await _venue(t, true)
	VenueChecks.walkable(t, v, "tideline")
	v.queue_free()


func test_doors_block(t) -> void:
	var v: Tideline = await _venue(t)
	await VenueChecks.doors_block(t, v, "tideline")
	v.queue_free()


## The cage's windows: you can talk through them and see through them, but
## nobody climbs through.
func test_cage_windows(t) -> void:
	var v: Tideline = await _venue(t)
	for z in Tideline.WINDOWS:
		var a := Vector3(9.0, 1.6, z)
		var b := Vector3(11.0, 1.6, z)
		t.check(VenueChecks._ray(t, a, b, Kit.LAYER_SOLID).is_empty(), "tideline: you can see through the cage's window at %.1f" % z)
		t.check(not VenueChecks._ray(t, a, b, Kit.LAYER_PEOPLE).is_empty(), "tideline: nobody climbs through the cage's window at %.1f" % z)
	v.queue_free()

#endregion


#region The jobs' data

func test_job_data(t) -> void:
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		VenueChecks.job_data(t, def)
	var ids := {}
	for night in ["count", "favor", "vault"]:
		for s in TidelineCast.all(night):
			t.check(s.voice != GameConfig.MAE_VOICE, "tideline: %s doesn't speak in Mae's voice" % s.id)
			ids[s.id] = s.voice
	var voices := {}
	for id in ids:
		t.check(not voices.has(ids[id]), "tideline: %s has a voice of their own (%s)" % [id, ids[id]])
		voices[ids[id]] = id
	t.check(ids.size() == 15, "tideline: a cast of fifteen (%d)" % ids.size())
	for id in ["marcus", "teo", "hugo"]:
		t.check(MeridianCast.IDS.has(id), "tideline: %s is the Meridian's %s" % [id, id])
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		t.check(def.memory_from == ["meridian"], "%s: the cast remembers the Meridian" % def.id)


func test_routines(t) -> void:
	for def in [TidelineCountJob.new(), TidelineFavorJob.new(), TidelineVaultJob.new()]:
		await VenueChecks.routines(t, def)

#endregion
