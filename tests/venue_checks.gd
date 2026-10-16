class_name VenueChecks
extends RefCounted
## The checks every venue and job passes, for a venue's own
## tests/<venue>_tests.gd (docs/m2.md):
##   var v: Venue = await VenueChecks.built(t, Marlin.new())
##   VenueChecks.structure(t, v, "marlin", SPOT_ZONES)
##   VenueChecks.standing_room(t, v, "marlin")
##   v.queue_free()
##   v = await VenueChecks.built(t, Marlin.new(), true)
##   VenueChecks.walkable(t, v, "marlin")
##   await VenueChecks.doors_block(t, await VenueChecks.built(t, Marlin.new()), "marlin")
##   VenueChecks.job_data(t, MarlinSafeJob.new())
##   await VenueChecks.routines(t, MarlinSafeJob.new())
## `t` is the test runner (tests/run_tests.gd): it checks, waits and parents.

## Head room: someone standing at a spot is a ball this big at hip and head.
const BODY := 0.25
## Heights to look for head room at, over a spot.
const HEIGHTS := [0.9, 1.6]
## Knee height, for walking a link.
const KNEE := 0.45


## Builds a venue into the tree (its doors open first, if asked) and waits
## for its collision to settle.
static func built(t: Node, v: Venue, open_doors := false) -> Venue:
	v.build()
	if open_doors:
		for d in v.doors.values():
			d.open()
	t.add_child(v)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	return v


## Doors, spots (with the zone each is in), views, uses, links, zones and the
## world: everything a venue lists is there and makes sense.
static func structure(t, v: Venue, label: String, spot_zones: Dictionary) -> void:
	t.check(not v.doors.is_empty(), "%s: has doors" % label)
	for d in v.doors:
		var door = v.doors[d]
		t.check(door is HotelDoor, "%s: the %s door is a HotelDoor" % [label, d])
	for s in spot_zones:
		t.check(v.spots.get(s) is Transform3D, "%s: spot %s" % [label, s])
		if v.spots.has(s):
			var z := v.zone_at((v.spots[s] as Transform3D).origin + Vector3.UP)
			t.check(z == spot_zones[s], "%s: spot %s is in the %s (%s)" % [label, s, spot_zones[s], z])
	for s in ["crew_0", "crew_1"]:
		t.check(v.spots.has(s), "%s: the crew's start, %s" % [label, s])
	t.check(v.views.size() >= 6, "%s: at least six views (%d)" % [label, v.views.size()])
	for name in v.views:
		t.check(v.views[name] is Transform3D, "%s: view %s" % [label, name])
		t.check(str(v.view_about.get(name, "")) != "", "%s: view %s says what it shows" % [label, name])
	for id in v.uses:
		var u: StaticBody3D = v.uses[id]
		t.check(u != null and u.get_meta("use", "") != "", "%s: %s can be used" % [label, id])
		if u:
			t.check(v.zone_at(u.global_position + Vector3(0, 0.1, 0)) != "", "%s: %s is in a room" % [label, id])
	for l in v.links:
		t.check(v.points.has(l[0]) and v.points.has(l[1]), "%s: link %s-%s joins two points" % [label, l[0], l[1]])
		t.check(str(l[2]) == "" or v.doors.has(l[2]), "%s: link %s-%s goes through a door there is" % [label, l[0], l[1]])
	for p in v.points:
		t.check(v.zone_at(v.points[p] + Vector3.UP) != "", "%s: point %s is in a room" % [label, p])
	for z in v.zones:
		t.check(v.zones[z] is AABB and z in v.zone_order, "%s: zone %s is a box, in the order" % [label, z])
		var layer := int(v.room_layers.get(z, 0))
		t.check(layer >= 2 and layer <= 20, "%s: zone %s has a render layer of its own (%d)" % [label, z, layer])
	for room in v.extras:
		t.check(v.zones.has(room), "%s: the crowd stands in a room there is (%s)" % [label, room])
	t.check(v.environment() is Environment, "%s: an environment" % label)


## Spots stand on a floor with room round them, spots are points people walk
## to, and the crowd has room where it stands.
static func standing_room(t, v: Venue, label: String) -> void:
	for s in v.spots:
		var p: Vector3 = (v.spots[s] as Transform3D).origin
		var down := _ray(t, p + Vector3(0, 0.4, 0), p - Vector3(0, 0.3, 0), Kit.LAYER_SOLID)
		t.check(not down.is_empty() and absf(down.position.y - p.y) < 0.06, "%s: spot %s stands on a floor (%s)" % [label, s, down.position if down else "nothing"])
		t.check(v.points.has(s) and (v.points[s] as Vector3).is_equal_approx(p), "%s: spot %s is a point people walk to" % [label, s])
		for y in HEIGHTS:
			var hit := _touching(t, p + Vector3(0, y, 0), BODY, Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "%s: room to stand at %s (%s)" % [label, s, hit[0].collider.name if hit else ""])
	for room in v.extras:
		for x in v.extras[room]:
			var p: Vector3 = (x as Transform3D).origin
			t.check(v.zone_at(p + Vector3.UP) == room, "%s: the %s's crowd is in it (%s)" % [label, room, p])
			var hit := _touching(t, p + Vector3(0, 1.2, 0), 0.22, Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "%s: room for someone at %s (%s)" % [label, p, hit[0].collider.name if hit else ""])


## With every door open (build it with `open_doors`), each link is clear at
## knee height a body's width across, and every point can be reached from
## `start`. A link straight up (a lift) isn't walked, only ridden.
static func walkable(t, v: Venue, label: String, start := "crew_0") -> void:
	for l in v.links:
		var a: Vector3 = v.points[l[0]]
		var b: Vector3 = v.points[l[1]]
		if Vector2(b.x - a.x, b.z - a.z).length() < 0.05:
			continue
		for side in [-0.2, 0.0, 0.2]:
			var off: Vector3 = Vector3(b.x - a.x, 0, b.z - a.z).cross(Vector3.UP).normalized() * side
			var hit := _ray(t, a + off + Vector3(0, KNEE, 0), b + off + Vector3(0, KNEE, 0), Kit.LAYER_SOLID)
			t.check(hit.is_empty(), "%s: %s to %s is clear at knee height (%s at %s)" % [label, l[0], l[1], hit.collider.name if hit else "", hit.position if hit else ""])
	var seen := {start: true}
	var todo := [start]
	while not todo.is_empty():
		var n = todo.pop_back()
		for l in v.links:
			for k in 2:
				if l[k] == n and not seen.has(l[1 - k]):
					seen[l[1 - k]] = true
					todo.append(l[1 - k])
	for p in v.points:
		t.check(seen.has(p), "%s: %s can be reached from %s" % [label, p, start])


## Every door blocks shut, says what it is, opens, lets people through open,
## and stays shut locked. Build the venue with its doors shut.
static func doors_block(t, v: Venue, label: String) -> void:
	for name in v.doors:
		var d: HotelDoor = v.doors[name]
		var c := d.centre() + Vector3(0, 1.0, 0)
		var across := d.global_basis.z.normalized()
		var hit := _ray(t, c - across, c + across, Kit.LAYER_SOLID)
		t.check(not hit.is_empty() and hit.collider.get_parent() == d, "%s: the shut %s door blocks" % [label, name])
		t.check(not hit.is_empty() and str(hit.collider.get_meta("use", "")) == "door:" + name, "%s: the %s door's leaf says what it is" % [label, name])
		t.check(d.open(), "%s: the %s door opens" % [label, name])
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	for name in v.doors:
		var d: HotelDoor = v.doors[name]
		var c := d.centre() + Vector3(0, 1.0, 0)
		var across := d.global_basis.z.normalized()
		var hit := _ray(t, c - across * 1.5, c + across * 1.5, Kit.LAYER_SOLID)
		t.check(hit.is_empty(), "%s: the open %s door lets you through (%s)" % [label, name, hit.collider.name if hit else ""])
		d.close()
	await t.until(func() -> bool: return false, HotelDoor.SECONDS + 0.3)
	for name in v.doors:
		var d: HotelDoor = v.doors[name]
		d.locked = true
		t.check(not d.open() and not d.is_open, "%s: the locked %s door stays shut" % [label, name])
		d.locked = false


## A job's data names only things there are: its venue's spots, doors, uses
## and zones, its cast, outfits, looks, actions, items and outcomes. And it
## has what the board, the HUD and the report need.
static func job_data(t, def: JobDef) -> void:
	var label := def.id if def.id != "" else "a job"
	t.check(def.id in Jobs.CAMPAIGN and Jobs.make(def.id).get_script() == def.get_script(), "%s: listed in Jobs, at this script" % label)
	t.check(Jobs.VENUES.has(def.venue_id) and def.venue_name != "", "%s: a venue there is (%s)" % [label, def.venue_id])
	t.check(def.number >= 1 and def.number <= 3, "%s: one of its venue's three" % label)
	for k in ["title", "briefing", "goal", "situation", "prize", "end_text"]:
		t.check(str(def.get(k)).strip_edges() != "", "%s: has a %s" % [label, k])
	t.check(def.briefing.length() > 200, "%s: Mae's briefing says enough" % label)
	t.check(def.take > 0, "%s: a take" % label)
	t.check(def.start < def.end and def.end - def.start >= 20 and def.end - def.start <= 90, "%s: a night of 20 to 90 game minutes (%d)" % [label, def.end - def.start])
	Jobs.current = def
	Person.add_looks(def.looks)
	var v: Venue = def.venue()
	t.check(v != null, "%s: a venue" % label)
	if v == null:
		return
	v.build()
	# Covers.
	t.check(def.covers.size() >= 2, "%s: at least two covers" % label)
	for id in def.covers:
		var c: Dictionary = def.covers[id]
		for k in ["title", "names", "job", "story", "outfit", "for", "lines"]:
			t.check(c.has(k), "%s: cover %s has %s" % [label, id, k])
		t.check(c.get("names", []).size() == 2, "%s: cover %s has a man's and a woman's name" % [label, id])
		t.check(c.get("lines", []).size() >= 3, "%s: cover %s suggests at least three lines" % [label, id])
		var outfit := str(c.get("outfit", ""))
		t.check(def.outfits.has(outfit) or Covers.OUTFITS.has(outfit), "%s: cover %s wears an outfit there is (%s)" % [label, id, outfit])
	for id in def.cover_order:
		t.check(def.covers.has(id), "%s: cover %s in the order is a cover" % [label, id])
	for o in def.outfits:
		t.check(Person.has_look(str(def.outfits[o].get("job", ""))), "%s: outfit %s dresses as a look there is" % [label, o])
		t.check(str(def.outfits[o].get("male", "")) != "" and str(def.outfits[o].get("female", "")) != "", "%s: outfit %s says how it looks" % [label, o])
	for o in def.staff_looking:
		t.check(def.outfits.has(o) or Covers.OUTFITS.has(o), "%s: staff-looking outfit %s is an outfit" % [label, o])
	for z in def.staff_rooms:
		t.check(v.zones.has(z), "%s: staff room %s is a zone" % [label, z])
	for z in def.extras:
		t.check(v.zones.has(z), "%s: the crowd's zone %s is a zone" % [label, z])
		var dress = def.extras[z]
		var as_job := str(dress.get("job", "")) if dress is Dictionary else str(dress)
		t.check(Person.has_look(as_job), "%s: the %s's crowd wears a look there is (%s)" % [label, z, as_job])
	# The cast.
	var sheets := def.sheets()
	var ids := {}
	t.check(sheets.size() >= 8, "%s: a cast of at least eight (%d)" % [label, sheets.size()])
	for s in sheets:
		t.check(not ids.has(s.id), "%s: one %s" % [label, s.id])
		ids[s.id] = s
		t.check(v.spots.has(s.spot), "%s: %s's spot is there (%s)" % [label, s.id, s.spot])
		t.check(s.door == "" or v.doors.has(s.door), "%s: %s's door is there (%s)" % [label, s.id, s.door])
		t.check(Person.has_look(s.person_job), "%s: %s wears a look there is (%s)" % [label, s.id, s.person_job])
		t.check(s.id == "mae" or s.voice != GameConfig.MAE_VOICE, "%s: only Mae has Mae's voice (%s)" % [label, s.id])
		t.check(s.manner != "" and not s.knows.is_empty(), "%s: %s has a manner and knows things" % [label, s.id])
		t.check(not s.replies.is_empty(), "%s: %s has scripted replies, for no model" % [label, s.id])
		for a in s.actions:
			t.check(CharacterSheet.ACTIONS.has(a) or def.actions.has(a), "%s: %s's action %s is one there is" % [label, s.id, a])
		for c in s.checks_with:
			t.check(s.checks_with[c] is String, "%s: %s checks %s with someone" % [label, s.id, c])
	# The night.
	for r in def.routine:
		t.check(r.size() == 3 and ids.has(str(r[1])) and v.spots.has(str(r[2])), "%s: routine %s names someone and a spot there is" % [label, str(r)])
		t.check(float(r[0]) >= def.start and float(r[0]) < def.end, "%s: routine %s is in the night" % [label, str(r)])
	for c in def.chatter:
		t.check(c.size() == 4 and ids.has(str(c[1])) and str(c[3]) in ["radio", "near"], "%s: chatter %s is someone's, radio or near" % [label, str(c)])
	for e in def.events:
		t.check(e.size() == 2 and float(e[0]) >= def.start and float(e[0]) <= def.end, "%s: event %s is in the night" % [label, str(e)])
	for list in [def.locked, def.unlocked, def.open, def.lockdown_doors, def.door_texts.keys()]:
		for d in list:
			t.check(v.doors.has(d), "%s: door %s is there" % [label, d])
	for k in def.keypads:
		var pad: Dictionary = def.keypads[k]
		t.check(v.uses.has(k), "%s: keypad %s is something to use" % [label, k])
		t.check(v.doors.has(str(pad.get("door", ""))), "%s: keypad %s opens a door there is" % [label, k])
		t.check(str(pad.get("code", "")).length() == 4 and str(pad.get("code", "")).is_valid_int(), "%s: keypad %s has a four-digit code" % [label, k])
	t.check(v.doors.has(str(def.office.get("door", ""))) and v.spots.has(str(def.office.get("held", ""))) and v.spots.has(str(def.office.get("guard", ""))), "%s: somewhere to hold the crew, with a guard's spot" % label)
	for it in def.items:
		var info: Dictionary = def.items[it]
		t.check(str(info.get("name", "")) != "", "%s: item %s has a name" % [label, it])
		var at := str(info.get("at", ""))
		t.check(at == "" or (v.uses.has(at) and str(v.uses[at].get_meta("use", "")) == "item:" + it), "%s: item %s lies at a use for it (%s)" % [label, it, at])
		for who in info.get("to", []):
			t.check(ids.has(str(who)), "%s: item %s is shown to someone there is (%s)" % [label, it, who])
	for act in def.effects:
		t.check(CharacterSheet.ACTIONS.has(act) or def.actions.has(act), "%s: the effect of %s is for an action there is" % [label, act])
		var e: Dictionary = def.effects[act]
		var door := str(e.get("open", ""))
		t.check(door == "" or door == "@door" or v.doors.has(door), "%s: %s opens a door there is (%s)" % [label, act, door])
		t.check(not e.has("walk") or v.spots.has(str(e.walk)), "%s: %s walks to a spot there is" % [label, act])
		t.check(not e.has("outfit") or def.outfits.has(str(e.outfit)) or Covers.OUTFITS.has(str(e.outfit)), "%s: %s puts them in an outfit there is" % [label, act])
		t.check(not e.has("item") or def.items.has(str(e.item)), "%s: %s gives an item there is" % [label, act])
	for n in def.phone:
		t.check(ids.has(str(n.get("who", ""))) and str(n.get("name", "")) != "", "%s: number %s rings someone there is" % [label, n.get("id", "")])
	t.check(not def.caller_ids.is_empty(), "%s: something for the caller ID to say" % label)
	for m in def.mae_calls:
		t.check(ids.has(str(m.get("who", ""))), "%s: Mae's %s call is to someone there is" % [label, m.get("id", "")])
		for k in ["label", "as", "line", "answer", "mae"]:
			t.check(str(m.get(k, "")) != "", "%s: Mae's %s call has %s" % [label, m.get("id", ""), k])
	t.check(not def.wins.is_empty(), "%s: a way to win" % label)
	for o in def.wins:
		t.check(def.outcomes.has(o) and def.outcomes[o].size() == 2, "%s: outcome %s has a title and a line" % [label, o])
	t.check(def.inside_zone == "" or v.zones.has(def.inside_zone), "%s: inside is a zone there is" % label)
	v.free()


## Every routine walk gets there: each character walks from their spot to
## each place their routine sends them, through the venue's doors.
static func routines(t, def: JobDef) -> void:
	var job := JobHarness.start(t, def)
	await t.frames(2)
	for r in def.routine:
		var ch: Character = job.cast.get(str(r[1]))
		if ch == null:
			continue
		var ok := JobHarness.walk(job, ch, str(r[2]))
		var to: Vector3 = job.venue.spots[str(r[2])].origin
		t.check(ok, "%s: %s walks to %s (%.1f m off)" % [def.id, r[1], r[2], ch.global_position.distance_to(to)])
	JobHarness.done(job)
	await t.frames(2)


static func _ray(t: Node, a: Vector3, b: Vector3, mask: int) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b, mask)
	return t.get_tree().root.get_world_3d().direct_space_state.intersect_ray(q)


## What solid things a ball at `p` touches.
static func _touching(t: Node, p: Vector3, r: float, mask: int) -> Array:
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = r
	q.shape = s
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = mask
	return t.get_tree().root.get_world_3d().direct_space_state.intersect_shape(q, 4)
