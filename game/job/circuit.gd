class_name Circuit
extends RefCounted
## The Circuit: once the season's done, a night's number remixes a job. It
## picks the job, a rule or two (a fast clock, a jumpy staff, Halberd with
## your faces, a take that only pays clean), moves people's rounds a few
## minutes either way, and sets the take by how hard the rules are. The same
## number is the same night on every device, so a crew can share one, and
## each week's contract is one number for everyone (see [method week]).
##
## [method remix] changes a fresh [JobDef] in place and keeps what it did in
## [member JobDef.circuit]; [JobDef], [Job] and the report ask the hooks
## below, which do nothing for a job that isn't a Circuit night.

## The rules a night can have: what the board calls them, what they mean,
## and what they do to the take.
const RULES := {
	"fast_clock": {"name": "The clock runs fast", "text": "The night goes by a third quicker.", "pay": 1.2},
	"halberd_edge": {"name": "Halberd's on edge", "text": "Halberd's people start out warier.", "pay": 1.3},
	"staff_jumpy": {"name": "Jumpy staff", "text": "The staff start out warier.", "pay": 1.2},
	"easy_crowd": {"name": "A friendly crowd", "text": "The guests are in a good mood.", "pay": 0.8},
	"known_faces": {"name": "Halberd has your faces", "text": "Every face on the crew is in Halberd's file tonight.", "pay": 1.5},
	"clean_or_nothing": {"name": "Clean or nothing", "text": "It only pays if nobody's held and it never gets to Lockdown.", "pay": 1.4},
	"talk_only": {"name": "Talk only", "text": "It only pays if every door opens by talk.", "pay": 1.5},
}
## How far a character's rounds can move, in minutes.
const SHIFTS := [-10, -5, 0, 5, 10]
## Rounds keep clear of the end of the night, and of the job's events.
const CLEAR := 10
## Night numbers people roll: six digits.
const LOWEST := 100000
const HIGHEST := 999999


## The job a night's number plays.
static func job_for(seed: int) -> String:
	var jobs := Jobs.available()
	if jobs.is_empty():
		return "meridian_gala"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("circuit-job:%d" % seed)
	return str(jobs[rng.randi_range(0, jobs.size() - 1)])


## A fresh copy of a night's job, remixed.
static func make(seed: int) -> JobDef:
	var def := Jobs.make(job_for(seed))
	if def:
		remix(def, seed)
	return def


## A new night's number.
static func roll() -> int:
	return randi_range(LOWEST, HIGHEST)


## Remixes `def` (a fresh copy) for the night `seed`: its rules, its
## people's rounds and its take.
static func remix(def: JobDef, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("circuit:%d:%s" % [seed, def.id])
	var pool: Array = RULES.keys()
	var rules: Array = []
	var count := 1 + rng.randi_range(0, 1)
	while rules.size() < count and not pool.is_empty():
		rules.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var pay := 1.0
	for r in rules:
		pay *= float(RULES[r].pay)
	var base := def.take
	def.take = maxi(500, roundi(def.take * pay / 500.0) * 500)
	if "fast_clock" in rules:
		def.seconds_per_minute *= 0.75
	var shifts := _shift(def, rng)
	def.circuit = {"seed": seed, "rules": rules, "shifts": shifts, "base_take": base}


## Moves each character's rounds (after the start) by a few minutes, the
## same for all of a character's rounds so they keep their order, and their
## lines with them. Characters whose rounds come near the job's events or
## the end stay put, since the job may count on them being there.
static func _shift(def: JobDef, rng: RandomNumberGenerator) -> Dictionary:
	var by: Dictionary = {}
	for r in def.routine:
		if float(r[0]) > def.start:
			by[str(r[1])] = by.get(str(r[1]), []) + [float(r[0])]
	var ids := by.keys()
	ids.sort()
	var events: Array = def.events.map(func(e): return float(e[0]))
	var shifts := {}
	for id in ids:
		var off := int(SHIFTS[rng.randi_range(0, SHIFTS.size() - 1)])
		if off == 0 or not _fits(def, by[id], off, events):
			continue
		shifts[id] = off
	if shifts.is_empty():
		return shifts
	def.routine = def.routine.duplicate(true)
	def.chatter = def.chatter.duplicate(true)
	for r in def.routine:
		if shifts.has(str(r[1])) and float(r[0]) > def.start:
			r[0] = r[0] + shifts[str(r[1])]
	for c in def.chatter:
		if shifts.has(str(c[1])) and float(c[0]) > def.start:
			c[0] = clamp(c[0] + shifts[str(c[1])], def.start + 1, def.end - 1)
	def.routine.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	def.chatter.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	return shifts


static func _fits(def: JobDef, minutes: Array, off: int, events: Array) -> bool:
	for m in minutes:
		var to := float(m) + off
		if to <= def.start or to > def.end - CLEAR:
			return false
		for e in events:
			if absf(float(m) - float(e)) < CLEAR or absf(to - float(e)) < CLEAR:
				return false
	return true


## The night's rules, by name ("Talk only").
static func rule_names(def: JobDef) -> Array:
	return def.circuit.get("rules", []).map(func(r): return str(RULES[r].name))


## A night on the board: "Talk only, Jumpy staff."
static func rules_text(def: JobDef) -> String:
	return ", ".join(PackedStringArray(rule_names(def))) + "."


#region Hooks

## The sheets for the night: warier or friendlier, by the rules.
static func on_sheets(def: JobDef, sheets: Array) -> void:
	var rules: Array = def.circuit.get("rules", [])
	if rules.is_empty():
		return
	for s in sheets:
		if "halberd_edge" in rules and s.halberd:
			s.start_suspicion = mini(3, s.start_suspicion + 1)
		if "staff_jumpy" in rules and s.staff and not s.halberd:
			s.start_suspicion = mini(3, s.start_suspicion + 1)
		if "easy_crowd" in rules and not s.staff and not s.halberd:
			s.start_suspicion = maxi(0, s.start_suspicion - 1)


## The crew for the night: everyone's face burned, by the rules.
static func on_setup(job: Job) -> void:
	if "known_faces" in job.def.circuit.get("rules", []):
		for c in job.crew:
			c.burned = true


## The report for the night: its number and rules, and no take when a rule
## that pays only one way wasn't met.
static func on_report(def: JobDef, r: Dictionary) -> void:
	if def.circuit.is_empty():
		return
	var rules: Array = def.circuit.get("rules", [])
	r["circuit"] = int(def.circuit.seed)
	r["rules"] = rule_names(def)
	if not bool(r.get("win", false)):
		return
	for rule in [["clean_or_nothing", "clean"], ["talk_only", "silver"]]:
		if rule[0] in rules and not bool(r.get(rule[1], false)):
			r["take"] = 0
			r["unpaid"] = str(RULES[rule[0]].name)

#endregion

#region The weekly contract

## The week a time falls in, as releases count them: weeks run Sunday to
## Saturday (UTC) and are numbered like ISO weeks, a Sunday starting the ISO
## week of the Monday after it. [year, week].
static func week_of(unix: int) -> Array:
	var day := unix + 86400
	var d := Time.get_datetime_dict_from_unix_time(day)
	var iso_day := (int(d.weekday) + 6) % 7
	var thursday := day + (3 - iso_day) * 86400
	var t := Time.get_datetime_dict_from_unix_time(thursday)
	var jan1 := Time.get_unix_time_from_datetime_dict({"year": t.year, "month": 1, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return [int(t.year), int((thursday - jan1) / 86400) / 7 + 1]


## This week's contract: one night's number for everyone ("2026" and week
## "42" make 202642).
static func week(unix := -1) -> int:
	var w := week_of(unix if unix >= 0 else int(Time.get_unix_time_from_system()))
	return int(w[0]) * 100 + int(w[1])


## The weekly contract's name for the board: "Week 42".
static func week_name(seed: int) -> String:
	return "Week %d" % (seed % 100)

#endregion
