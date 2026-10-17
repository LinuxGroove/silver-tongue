class_name GuardRules
extends RefCounted
## The rules round a character's reply: what the model may decide and what
## the game vetoes. Suspicion moves a step or two at a time, nobody is let
## through on the first line or while suspicious, backup is only called
## when suspicion is high, and a vetoed action turns into a hesitation.

## Suspicion at which the character calls it in, whatever the model said.
const CAUGHT := 5
## Let through needs suspicion at or under this...
const TRUST := 1
## ... and at least this many of the player's lines heard.
const MIN_TURNS := 2
## Radio for backup needs at least this.
const ALARM := 4


## The character's state: {"suspicion", "turns" (player lines heard so
## far, this one included), "believes", "reception" ("" / "asked" / "answered")}.
static func new_state(sheet: CharacterSheet) -> Dictionary:
	return {"suspicion": sheet.start_suspicion, "turns": 0, "believes": [], "reception": ""}


## Applies the rules to a parsed reply and returns what actually happens:
## the reply's fields as they stand after the rules, "vetoed" (the action
## the model wanted but can't have, or ""), and "ended" ("" while the talk
## goes on, "through" when the door opens, "caught" when backup's called).
static func resolve(reply: Dictionary, state: Dictionary, sheet: CharacterSheet, rng: RandomNumberGenerator = null) -> Dictionary:
	var out := reply.duplicate(true)
	var before := int(state.get("suspicion", 1))
	var wanted := int(reply.get("suspicion", before))
	out["suspicion"] = clampi(wanted, maxi(before - 1, 0), mini(before + 2, CAUGHT))
	out["vetoed"] = ""
	out["ended"] = ""
	var act := str(reply.get("do", "none"))
	if not act in sheet.actions:
		act = "none"
	var believes: Array = out.get("believes", [])
	match act:
		"let_through":
			if int(out.suspicion) > TRUST or int(state.get("turns", 0)) < MIN_TURNS or believes.is_empty():
				out["vetoed"] = act
				act = "none"
				out["say"] = _pick(sheet.hesitations, rng)
				out["tone"] = "wary" if int(out.suspicion) > TRUST else str(out.get("tone", "calm"))
		"radio_security":
			if int(out.suspicion) < ALARM:
				out["vetoed"] = act
				act = "none"
		"ask_reception":
			if str(state.get("reception", "")) != "" or sheet.reception_line == "":
				out["vetoed"] = act
				act = "none"
	if int(out.suspicion) >= CAUGHT:
		act = "radio_security"
		out["tone"] = "alarmed"
	out["do"] = act
	if act == "let_through":
		out["ended"] = "through"
	elif act == "radio_security":
		out["ended"] = "caught"
	return out


## Moves the state on by a resolved reply.
static func apply(out: Dictionary, state: Dictionary) -> void:
	state["suspicion"] = int(out.get("suspicion", state.get("suspicion", 1)))
	var believes: Array = out.get("believes", [])
	if not believes.is_empty():
		state["believes"] = believes.duplicate()
	if str(out.get("do", "")) == "ask_reception":
		state["reception"] = "asked"


static func _pick(lines: Array[String], rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return "Hang on."
	if rng == null:
		return lines[randi() % lines.size()]
	return lines[rng.randi() % lines.size()]
