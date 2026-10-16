class_name ScriptedBrain
extends RefCounted
## A gala character's replies with no model: the sheet's keyword rules
## (CharacterSheet.replies), a colleague's checked answer, papers, and what
## they saw, shaped like a model's reply so the same rules apply. Enough to
## play the job without Lemonade; nobody would call it listening.


## A reply to a turn. `turn`: "kind" ("line", "overheard", "event", "seen",
## "papers", "question", "answer"), "heard" (the words), and for some kinds
## "verdict" ("good" / "bad") and "answer" (the line to give).
static func reply(sheet: CharacterSheet, face: Dictionary, turn: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var s := int(face.get("suspicion", 1))
	var r := {"think": "", "say": "", "tone": "calm", "do": "none", "believes": [], "suspicion": s}
	var heard := " " + str(turn.get("heard", "")).to_lower() + " "
	match str(turn.get("kind", "line")):
		"question":
			r.say = str(turn.get("answer", ""))
			return r
		"answer":
			if str(turn.get("verdict", "")) == "good":
				r.say = _pick(["Right. Go on, then.", "That checks out. Go ahead.", "Fine. In you go."], rng)
				r.do = opening(sheet)
				r.suspicion = mini(s, JobRules.TRUST)
				r.believes = (face.get("believes", []) as Array).duplicate() if not (face.get("believes", []) as Array).is_empty() else ["checks out"]
				r.tone = "friendly"
			else:
				r.say = _pick(["That's not what I'm hearing. Who are you?", "So who sent you, then?"], rng)
				r.suspicion = s + 1
				r.tone = "wary"
			return r
		"overheard":
			if _hot(heard, sheet):
				r.suspicion = s + 1
				r.tone = "wary"
			return r
		"papers":
			if str(face.get("papers", "")) == "passed":
				r.say = "Thank you."
				r.believes = [str(turn.get("belief", "has an invitation"))]
				r.do = sheet.papers_do if sheet.papers_do in sheet.actions else "none"
				r.tone = "friendly"
			else:
				r.say = _pick(["This isn't right.", "Where did you get this?"], rng)
				r.tone = "annoyed"
			return r
		"seen":
			if sheet.staff or sheet.halberd:
				r.say = _pick(["Excuse me. You can't be back here.", "Can I help you? This is staff only."], rng)
				r.tone = "wary"
			return r
		"event":
			return r
		"phone":
			r.say = sheet.phone_hello
			return r
		"mae":
			r.say = str(turn.get("answer", "Right away."))
			return r
	if str(face.get("papers", "")) == "passed" and "let_through" in sheet.actions and sheet.papers_do == "let_through":
		r.say = "Enjoy the evening."
		r.do = "let_through"
		r.believes = ["has an invitation"]
		r.tone = "friendly"
		return r
	for rule in sheet.replies:
		var hit := false
		for w in rule.get("words", []):
			if heard.contains(str(w)):
				hit = true
				break
		if not hit:
			continue
		r.say = str(rule.get("say", ""))
		r.tone = str(rule.get("tone", "calm"))
		r.believes = (rule.get("believes", []) as Array).duplicate()
		r.suspicion = clampi(s + int(rule.get("up", 0)), 0, JobRules.CAUGHT)
		var act := str(rule.get("do", "none"))
		if act == "?check":
			act = "none"
			for a in sheet.actions:
				if sheet.is_check(a) and sheet.checks_with.has(a):
					act = a
					break
			if act != "none" and (face.get("checks", {}) as Dictionary).has(act):
				act = "none"
				r.say = "I already checked."
		if sheet.is_opening(act) and int(face.get("turns", 0)) < JobRules.MIN_TURNS and rule.has("first"):
			r.say = str(rule.first)
			act = "none"
		r.do = act
		if rule.has("secret"):
			var i := int(rule.secret)
			if i in face.get("secrets", []) and i < sheet.secrets.size():
				r.say = "Between us? " + str(sheet.secrets[i].text)
				r.tone = "friendly"
		return r
	if _hot(heard, sheet):
		r.suspicion = s + 1
		r.tone = "wary"
	r.say = _pick(sheet.fallbacks, rng)
	return r


## What a character does for someone whose story checked out.
static func opening(sheet: CharacterSheet) -> String:
	for a in ["let_through", "escort_in", "put_to_work", "plus_one", "add_to_list", "book_visit"]:
		if a in sheet.actions:
			return a
	for a in sheet.actions:
		if sheet.is_opening(a) and a != "release":
			return a
	return "none"


## Words that make anyone in earshot look up.
const HOT := ["forged", "forgery", "fake", "con ", "the rose", "diamond", "mae", "cameras", "steal", "heist", "the job", "the code"]


static func _hot(heard: String, sheet: CharacterSheet = null) -> bool:
	for w in HOT:
		if heard.contains(w):
			return true
	if sheet:
		for w in sheet.hot_words:
			if heard.contains(str(w)):
				return true
	return false


static func _pick(lines: Array, rng: RandomNumberGenerator) -> String:
	if lines.is_empty():
		return ""
	if rng == null:
		return str(lines[randi() % lines.size()])
	return str(lines[rng.randi() % lines.size()])
