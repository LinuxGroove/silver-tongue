class_name JobHarness
extends RefCounted
## Plays a job in tests with no scene, no player and no model: the venue,
## a crew of stand-in bodies at crew_0, crew_1..., and the cast on scripted
## brains. docs/m2.md shows a way through a job played with it:
##   var job := JobHarness.start(t, MarlinSafeJob.new(), ["steward"])
##   await t.frames(2)
##   JobHarness.face(job, 1, "purser")
##   t.check(await JobHarness.say_to(t, job, 1, "purser", "Evening. Agency sent me for the late shift."), "the purser answers")
##   ...
##   JobHarness.done(job)
##   await t.frames(2)


## A crew member's body: where they are and which way they look.
class Body:
	extends Node3D
	var look := Vector3.FORWARD

	func mouth_position() -> Vector3:
		return global_position + Vector3(0, 1.6, 0)

	func look_dir() -> Vector3:
		return look


## Sets up a job in its own venue (or `venue`, a stand-in like [StubHotel]), with a crew member
## per cover (the job's first cover when none are given; a body is a woman's
## where `female` says so), the job's items handed out, and scripted brains.
static func start(t: Node, def: JobDef, covers: Array = [], venue: Node3D = null, seed := 7, female: Array = []) -> Job:
	LGSettings.set_value("ai", "mode", "off")
	Jobs.current = def
	Person.add_looks(def.looks)
	if covers.is_empty():
		covers = [def.first_cover()]
	var root := Node3D.new()
	root.name = "JobTest"
	t.add_child(root)
	var v = venue if venue else def.venue()
	root.add_child(v)
	var crew: Array[CrewInfo] = []
	for i in covers.size():
		var c := CrewInfo.make(i + 1, i + 1, "Crew%d" % i, str(covers[i]), i < female.size() and bool(female[i]))
		var b := Body.new()
		root.add_child(b)
		b.global_transform = v.spots.get("crew_%d" % i, v.spots.get("crew_0", Transform3D()))
		c.node = b
		crew.append(c)
	def.give_items(crew)
	var job := Job.new()
	root.add_child(job)
	job.setup(def, v, crew, seed)
	job.brains = false
	return job


## Frees the job, its venue and the crew's bodies.
static func done(job: Job) -> void:
	job.get_parent().queue_free()


## Puts a crew member somewhere, looking at a point.
static func stand(job: Job, id: int, at: Vector3, look_at: Vector3) -> void:
	var b: Body = job.crew_node(id)
	b.global_position = at
	var d := look_at - at
	d.y = 0.0
	b.look = d.normalized() if d.length() > 0.001 else Vector3.FORWARD


## Puts a crew member in front of a character, `distance` away, facing them.
static func face(job: Job, id: int, char_id: String, distance := 1.4) -> void:
	var ch: Character = job.cast[char_id]
	var at := ch.global_position + ch.global_basis.z.normalized() * distance
	stand(job, id, at, ch.global_position)


## Puts a crew member at a spot, looking the way it faces.
static func stand_at(job: Job, id: int, spot_name: String) -> void:
	var s: Transform3D = job.venue.spots[spot_name]
	stand(job, id, s.origin, s.origin + s.basis.z)


## A crew member says something out loud (or on the earpiece).
static func say(job: Job, id: int, text: String, voice := "normal") -> void:
	job.crew_said(id, text, voice)


## A crew member says something to a character, and waits for the answer
## (scripted brains answer before [method say] returns, so count first).
## False if they never answered.
static func say_to(t, job: Job, id: int, char_id: String, text: String, voice := "normal", seconds := 6.0) -> bool:
	var ch: Character = job.cast[char_id]
	var want := ch.turns.size() + 1
	say(job, id, text, voice)
	return await t.until(func() -> bool: return ch.turns.size() >= want and not ch.busy, seconds)


## Waits until a character has answered `more` more times than they had, and
## is done thinking. False if they never did. For the answer to a line of
## the crew's own, use [method say_to], which counts from before the line.
static func answered(t, job: Job, char_id: String, more := 1, seconds := 6.0) -> bool:
	var ch: Character = job.cast[char_id]
	var want := ch.turns.size() + more
	return await t.until(func() -> bool: return ch.turns.size() >= want and not ch.busy, seconds)


## What a character did on their last turn ("none" if nothing).
static func last_do(job: Job, char_id: String) -> String:
	var ch: Character = job.cast[char_id]
	return str(ch.turns.back().get("reply", {}).get("do", "none")) if not ch.turns.is_empty() else "none"


## Nobody in the cast is thinking.
static func quiet(job: Job) -> bool:
	for ch in job.cast.values():
		if ch.busy:
			return false
	return true


## Walks a character to a spot at once (no frames go by). True if they got
## there.
static func walk(job: Job, ch: Character, spot_name: String) -> bool:
	ch.walk_to(spot_name)
	for i in 6000:
		if not ch.walking:
			break
		ch._walk(0.05)
	var to: Vector3 = job.venue.spots[spot_name].origin
	return not ch.walking and ch.global_position.distance_to(to) < 0.1


## Moves the clock on to `minute` (minutes after midnight) and lets the job
## catch up: routines walk, events fire.
static func clock_to(t, job: Job, minute: float) -> void:
	job.minutes = minute
	await t.frames(3)
