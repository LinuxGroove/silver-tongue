class_name JobRules
extends RefCounted
## The rules round a character's reply at the gala, per crew member: what
## the model may decide and what the game vetoes. As at M0's door,
## suspicion moves a step or two a turn, nobody is let anywhere on a first
## line or while suspicious, and backup is only called when suspicion is
## high; now for every opening action, every check, and the office.

## Suspicion at which a character calls it in, whatever the model said.
const CAUGHT := 5
## Opening actions need suspicion at or under this...
const TRUST := 1
## ... (release is a little easier: it was probably a mistake) ...
const RELEASE_TRUST := 2
## ... and at least this many of that person's lines (papers count as one,
## and a story a colleague vouched for needs no more).
const MIN_TURNS := 2
## Radio for backup needs at least this.
const ALARM := 4
## Seconds of nothing new before suspicion drifts down a step.
const DRIFT := 90.0
## Actions that open something for the crew member: a door, the list, a job.
const OPENING := ["let_through", "escort_in", "add_to_list", "book_visit", "put_to_work", "plus_one", "release"]
## Actions that check a story with a colleague.
const CHECKS := ["ask_reception", "call_manager"]
## Opening actions nobody takes at Lockdown.
const LOCKED_DOWN := ["let_through", "escort_in", "plus_one", "put_to_work"]


## What a character holds about one crew member.
static func new_face(sheet: CharacterSheet, heat_level := Heat.CALM) -> Dictionary:
	var s := sheet.start_suspicion
	if heat_level >= Heat.CURIOUS:
		s += 1
	if heat_level >= Heat.LOCKDOWN and sheet.halberd:
		s = maxi(s, 3)
	return {
		"suspicion": clampi(s, 0, ALARM), "turns": 0, "believes": [], "checks": {},
		"papers": "", "opened": [], "secrets": [], "seen": "", "zones": [],
		"earpiece": false, "quiet": 0.0, "met": false,
	}


## Applies the rules to a parsed reply about one crew member and returns
## what actually happens: the reply's fields after the rules, "vetoed" (the
## action the model wanted but can't have, or "") and "ended" ("" while the
## talk goes on, "open" when an opening action happens, "caught" when
## backup's called). `ctx`: "heat" (a Heat level), "held" (that crew member
## is in the office), "someone_held" (any of the crew is), "minding" (this
## character minds the office), "shut" (their door is shut for the night).
static func resolve(reply: Dictionary, face: Dictionary, sheet: CharacterSheet, ctx := {}, rng: RandomNumberGenerator = null) -> Dictionary:
	var out := reply.duplicate(true)
	var before := int(face.get("suspicion", 1))
	var wanted := int(reply.get("suspicion", before))
	out["suspicion"] = clampi(wanted, maxi(before - 1, 0), mini(before + 2, CAUGHT))
	out["vetoed"] = ""
	out["ended"] = ""
	var act := str(reply.get("do", "none"))
	if not act in sheet.actions:
		act = "none"
	var believes: Array = out.get("believes", [])
	var held := bool(ctx.get("held", false))
	var lockdown := int(ctx.get("heat", Heat.CALM)) >= Heat.LOCKDOWN
	if sheet.is_opening(act):
		var trust := RELEASE_TRUST if act == "release" else TRUST
		var why := ""
		if act == "release":
			if not ((held or bool(ctx.get("someone_held", false))) and bool(ctx.get("minding", false))):
				why = "silent"
		elif held:
			why = "silent"
		if why == "" and ((lockdown and sheet.locks_down(act)) or (bool(ctx.get("shut", false)) and act == "let_through")):
			why = "locked"
		var vouched := (face.get("checks", {}) as Dictionary).values().has("good")
		if why == "" and (int(out.suspicion) > trust or (int(face.get("turns", 0)) < MIN_TURNS and not vouched) or (believes.is_empty() and (face.get("believes", []) as Array).is_empty())):
			why = "wary"
		if why != "":
			out["vetoed"] = act
			act = "none"
			if why != "silent":
				out["say"] = _pick(sheet.hesitations, rng)
				if int(out.suspicion) > trust:
					out["tone"] = "wary"
	elif act == "radio_security":
		if int(out.suspicion) < ALARM:
			out["vetoed"] = act
			act = "none"
	elif sheet.is_check(act):
		if (face.get("checks", {}) as Dictionary).has(act) or not sheet.checks_with.has(act) or held:
			out["vetoed"] = act
			act = "none"
	if int(out.suspicion) >= CAUGHT and "radio_security" in sheet.actions and not held:
		act = "radio_security"
		out["tone"] = "alarmed"
	out["do"] = act
	out["checked"] = sheet.is_check(act)
	if sheet.is_opening(act):
		out["ended"] = "open"
	elif act == "radio_security":
		out["ended"] = "caught"
	return out


## Moves a face on by a resolved reply.
static func apply(out: Dictionary, face: Dictionary) -> void:
	face["suspicion"] = int(out.get("suspicion", face.get("suspicion", 1)))
	var believes: Array = out.get("believes", [])
	if not believes.is_empty():
		face["believes"] = believes.duplicate()
	var act := str(out.get("do", ""))
	if bool(out.get("checked", false)) or act in CHECKS:
		face["checks"][act] = "asked"
	if (str(out.get("ended", "")) == "open" or act in OPENING) and not act in face["opened"]:
		face["opened"].append(act)
	face["quiet"] = 0.0


## Suspicion drifts down a step after DRIFT seconds without cause, to where
## the character started. Returns true when it moved.
static func drift(face: Dictionary, sheet: CharacterSheet, dt: float) -> bool:
	face["quiet"] = float(face.get("quiet", 0.0)) + dt
	if float(face.quiet) < DRIFT:
		return false
	face["quiet"] = 0.0
	if int(face.suspicion) > sheet.start_suspicion and int(face.suspicion) < CAUGHT:
		face["suspicion"] = int(face.suspicion) - 1
		return true
	return false


## Something that raises suspicion by rule, not by the model (a face in a
## new outfit, a stranger in the kitchen, a murmur into an earpiece).
static func nudge(face: Dictionary, by: int) -> void:
	face["suspicion"] = clampi(int(face.suspicion) + by, 0, CAUGHT)
	face["quiet"] = 0.0


## The secrets this face has opened, by index, that weren't open before.
static func newly_open(face: Dictionary, sheet: CharacterSheet) -> Array:
	var out := []
	for i in sheet.secrets.size():
		if i in face["secrets"]:
			continue
		var s: Dictionary = sheet.secrets[i]
		if int(face.suspicion) <= int(s.get("suspicion", 0)) and int(face.turns) >= int(s.get("turns", 99)):
			face["secrets"].append(i)
			out.append(i)
	return out


static func _pick(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return "Hang on."
	if rng == null:
		return lines[randi() % lines.size()]
	return lines[rng.randi() % lines.size()]
