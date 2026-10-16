class_name TidelineRules
extends RefCounted
## What the Tideline's three jobs share: the cameras Dmitri watches from the eye
## (and the three ways to blind them: loop them at the junction box in the
## alley, keep Dmitri on the phone, or have him pull footage for the Gaming
## Board), the push bars on the back of the house's doors, the rooms with
## money in them, the crew's outfits and the numbers on the phone.
##
## Each job using these has `func cleared(job, c, zone) -> bool`: whether a
## crew member is allowed where they are, as the cameras and the staff see it.

## Where the cameras are, and what the staff call those rooms.
const CAMERA_ZONES := ["cage", "vault", "count_room", "corridor"]
const MONEY_ROOMS := {"cage": "the cage", "vault": "the vault", "count_room": "the count room"}
## Rooms the crew can be in without anyone minding.
const PUBLIC := ["floor", "pit", "lounge", "high_limit", "hl_table", "outside", "doorway"]
## Game minutes a loop at the junction box blinds the cameras, and that Dmitri
## spends pulling footage for the Board.
const LOOP_MINUTES := 10.0
const BUSY_MINUTES := 8.0
## Real seconds Marcus spends at the end of the corridor looking for whoever
## Dmitri saw on camera.
const CHECK_SECONDS := 35.0

## The outfits the Tideline's covers wear.
const OUTFITS := {
	"auditor": {"job": "auditor", "male": "a gray suit with a Gaming Board lanyard", "female": "a gray suit with a Gaming Board lanyard"},
	"cleaner": {"job": "cleaner", "male": "a teal cleaner's tunic", "female": "a teal cleaner's tunic"},
	"halberd_temp": {"job": "guard", "male": "Halberd's black suit and an earpiece", "female": "Halberd's black suit and an earpiece"},
	"croupier_temp": {"job": "croupier", "male": "a croupier's burgundy suit", "female": "a croupier's burgundy suit"},
	"cage_temp": {"job": "cashier", "male": "a cashier's teal suit", "female": "a cashier's teal suit"},
	"courier": {"job": "courier", "male": "a navy suit", "female": "a navy suit"},
}
const STAFF_LOOKING := ["cleaner", "halberd_temp", "croupier_temp", "cage_temp"]
const STAFF_ROOMS := {
	"corridor": "the back corridor", "count_room": "the count room", "cage": "the cage", "vault": "the vault",
	"eye": "the surveillance room", "office": "Halberd's office", "staff_room": "the staff room",
}
## What the crowd wears, room by room.
const EXTRAS := {"floor": "guest", "pit": "croupier", "lounge": "guest", "high_limit": "guest", "hl_table": "croupier", "doorway": "guard", "outside": "guest"}
## Numbers on the phone, by who answers.
const PHONE := {
	"anton": {"id": "manager", "name": "Anton Varga, night manager", "who": "anton"},
	"dmitri": {"id": "eye", "name": "Tideline surveillance", "who": "dmitri"},
	"pilar": {"id": "housekeeping", "name": "Tideline housekeeping", "who": "pilar"},
	"gloria": {"id": "count", "name": "The count room", "who": "gloria"},
	"augie": {"id": "pit", "name": "The pit", "who": "augie"},
	"marcus": {"id": "halberd", "name": "Halberd, the staff door", "who": "marcus"},
	"imani": {"id": "cage", "name": "The cage", "who": "imani"},
}
## Mae keeps Dmitri busy for the Gaming Board.
const FOOTAGE := {"id": "footage", "label": "Keep Dmitri busy pulling footage", "who": "dmitri", "as": "Caldera Gaming Board",
	"line": "Caldera Gaming Board. We need last Tuesday's footage from the cage pulled now, while I hold. All of it, please.",
	"answer": "Now? Fine. Give me a few minutes.",
	"mae": "I'll ring Dmitri as the Gaming Board and have him pull old tapes. He won't look at a live screen for a while."}
## The suggested lines that suit any cover at the Tideline.
const PLAYER_LINES := [
	"Evening. %s. I'm just here to play.",
	"What's good tonight? Cards or the wheel?",
	"Can I buy you a drink?",
	"Lovely place. Been coming here long?",
]


static func phone_for(ids: Array) -> Array:
	var out: Array = []
	for id in ids:
		out.append(PHONE[id])
	return out


#region The cameras

## Dmitri is looking at his screens: in the eye, not on a call, not pulling
## footage, and the cameras aren't looped.
static func watching(job: Job) -> bool:
	var dmitri: Character = job.cast.get("dmitri")
	if dmitri == null:
		return false
	if job.minutes < float(job.flags.get("cams_looped_until", -1.0)):
		return false
	if job.minutes < float(job.flags.get("dmitri_busy_until", -1.0)):
		return false
	return not (dmitri.walking or dmitri.minding or dmitri.on_call != 0)


## Every half second: crew on camera somewhere they shouldn't be are seen
## (once a room each). Marcus is sent to the corridor; anyone in the money
## rooms is called in. Also says when a loop runs out, and brings Marcus back.
static func tick(job: Job, def: JobDef, delta: float) -> void:
	var looped := float(job.flags.get("cams_looped_until", -1.0))
	if looped > 0.0 and job.minutes >= looped and not job.flags.has("loop_over"):
		job.flags["loop_over"] = true
		job.toast_for.emit(0, "The camera loop has run out. The eye can see again.")
	var back := float(job.flags.get("marcus_back_at", -1.0))
	if back > 0.0 and job.elapsed >= back:
		job.flags.erase("marcus_back_at")
		var m: Character = job.cast.get("marcus")
		if m and not m.minding and m.post == "corridor_check":
			m.walk_to(job.post_now(m))
	job.flags["cam_t"] = float(job.flags.get("cam_t", 0.0)) - delta
	if float(job.flags.cam_t) > 0.0:
		return
	job.flags["cam_t"] = 0.5
	if not watching(job):
		return
	for c in job.free_crew():
		if c.node == null:
			continue
		var zone: String = job.venue.zone_at(c.position())
		if not zone in CAMERA_ZONES:
			continue
		var key := "cam:%d:%s" % [c.id, zone]
		if job.flags.has(key) or def.call("cleared", job, c, zone):
			continue
		job.flags[key] = true
		spotted(job, c, zone)


## Dmitri sees a crew member on camera where they shouldn't be.
static func spotted(job: Job, c: CrewInfo, zone: String) -> void:
	var dmitri: Character = job.cast.get("dmitri")
	if dmitri == null:
		return
	var f := dmitri.face_of(c.id)
	f["met"] = true
	if zone == "corridor":
		JobRules.nudge(f, 2)
		job.heat.bump(Heat.KEYPAD_SEEN)
		dmitri.event("On the back corridor's camera: %s, a face you don't know, where only staff should be." % job.describe(c.id), c.id, "event")
		var m: Character = job.cast.get("marcus")
		if m and not m.minding and not m.walking:
			dmitri.say_scripted("Marcus, it's Dmitri. Someone I don't know in the back corridor: %s." % job.describe(c.id), m)
			m.walk_to("corridor_check")
			job.flags["marcus_back_at"] = job.elapsed + CHECK_SECONDS
		job.toast_for.emit(c.id, "The corridor's camera has you. Dmitri is radioing Marcus.")
		return
	JobRules.nudge(f, JobRules.CAUGHT)
	dmitri.event("On the camera in %s: %s, where nobody should be. That's a call to security." % [MONEY_ROOMS.get(zone, zone), job.describe(c.id)], c.id, "event")


## The Rose (or anything) taken where a camera can see it.
static func seen_taking(job: Job, c: CrewInfo, what: String) -> bool:
	var zone: String = job.venue.zone_at(c.position())
	if not zone in CAMERA_ZONES or not watching(job):
		return false
	var dmitri: Character = job.cast.get("dmitri")
	var f := dmitri.face_of(c.id)
	f["met"] = true
	JobRules.nudge(f, JobRules.CAUGHT)
	dmitri.event("On the camera in %s: %s just took %s." % [MONEY_ROOMS.get(zone, zone), job.describe(c.id), what], c.id, "event")
	return true

#endregion

#region What the crew uses

## The junction box, the push bars and the request card: what to tell them,
## or null when it's none of these.
static func use(job: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"cam_panel":
			if job.minutes < float(job.flags.get("cams_looped_until", -1.0)):
				return "The loop's already in."
			if job.flags.has("looped"):
				return "The loop won't take twice. Someone would notice."
			job.flags["looped"] = true
			job.flags["cams_looped_until"] = job.minutes + LOOP_MINUTES
			job.flags.erase("loop_over")
			job.tools_used += 1
			return "You clip a loop into the camera lines. For ten minutes the eye sees empty rooms."
		"request":
			if job.flags.has("song"):
				return "Your request's already on the stand."
			job.flags["song"] = true
			var m: Character = job.cast.get("marisol")
			if m:
				m.note("Someone left a request on your stand: %s, for Horace." % TidelineCast.SONG)
			return "You leave a request on the stand: %s, for Horace." % TidelineCast.SONG
	if not what.begins_with("door:"):
		return null
	var door := what.trim_prefix("door:")
	var d = job.venue.doors.get(door)
	if d == null or d.is_open or not d.locked:
		return null
	if _inside(job, c, door):
		job.open_for(door, 6.0)
		return "You push the bar."
	return null


static func prompt_for(job_or_null: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"cam_panel":
			return "Loop the cameras"
		"request":
			return "Leave a request for Marisol"
		"count_pad", "back_pad":
			return "Use the keypad"
	if what.begins_with("door:") and job_or_null and c:
		var door := what.trim_prefix("door:")
		var d = job_or_null.venue.doors.get(door)
		if d and not d.is_open and d.locked and _inside(job_or_null, c, door):
			return "Push the bar"
	return null


## On the inside of a door that opens with a push bar from there.
static func _inside(job: Job, c: CrewInfo, door: String) -> bool:
	if c.node == null:
		return false
	var zone: String = job.venue.zone_at(c.position())
	match door:
		"back", "staff":
			return zone in ["corridor", "staff_room"]
		"count_room":
			return zone == "count_room"
		"cage":
			return zone in ["cage", "vault"]
		"staff_room":
			return zone == "staff_room"
	return false

#endregion

#region The staff

## A stranger seen in a room with money in it: the staff who saw them call
## it in. Returns true when it's handled.
static func seen_in_money_room(job: Job, ch: Character, c: CrewInfo, zone: String, cleared: bool) -> bool:
	if not MONEY_ROOMS.has(zone) or cleared or not (ch.sheet.staff or ch.sheet.halberd):
		return false
	JobRules.nudge(ch.face_of(c.id), JobRules.CAUGHT)
	ch.event("%s is in %s. Nobody comes in here who isn't cleared." % [job.describe(c.id).capitalize(), MONEY_ROOMS[zone]], c.id, "event")
	return true


## Whether a crew member is on the phone to a character, showing `as_who`.
static func calling_as(job: Job, c: CrewInfo, ch: Character, as_who: String) -> bool:
	var rang: Dictionary = job.calls.get(c.id, {})
	return str(rang.get("who", "")) == ch.sheet.id and str(rang.get("as", "")) == as_who


## Whether a crew member is on the phone to a character at all.
static func on_phone(job: Job, c: CrewInfo, ch: Character) -> bool:
	return str(job.calls.get(c.id, {}).get("who", "")) == ch.sheet.id


## A crew member somewhere anyone can be.
static func in_public(job: Job, c: CrewInfo) -> bool:
	return c != null and not c.held and c.node != null and job.venue.zone_at(c.position()) in PUBLIC


## A character is standing at a spot (arrived, not walking).
static func at(job: Job, ch: Character, spot_name: String, within := 0.4) -> bool:
	return ch != null and not ch.walking and ch.global_position.distance_to(job.spot(spot_name).origin) < within


## Dmitri is busy with old footage for a while.
static func keep_busy(job: Job, ch: Character) -> void:
	job.flags["dmitri_busy_until"] = job.minutes + BUSY_MINUTES
	ch.note("The Gaming Board rang: you're pulling last Tuesday's cage footage for them now, and you're not watching the live screens till it's done.")

#endregion
