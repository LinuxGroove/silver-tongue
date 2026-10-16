class_name CharacterPrompt
extends RefCounted
## The messages a gala character's brain gets: one stable system prompt from
## the sheet (so the server's prompt cache keeps it), then the night so far:
## what the crew said to them or near them (described by how they look,
## since nobody's name is known until it's given), what they saw, what
## colleagues said on the radio, and their own replies. Consecutive lines
## that aren't theirs go in one message, and the oldest are let go in big
## steps, so each turn adds only its own words and the cached part holds.

const SHAPE := '{"think": "one short line: what you make of this", "say": "what you say out loud, under 30 words, or \\"\\" if you say nothing", "tone": "calm, friendly, wary, annoyed or alarmed", "do": "one of the actions", "believes": ["up to three short things you now believe about this person"], "suspicion": 0}'
## History kept before the oldest are let go, and how many go at once.
const KEEP := 40
const DROP := 16


static func system(sheet: CharacterSheet, mind_language := false) -> String:
	var lines := PackedStringArray()
	lines.append("You are %s, %s, at %s. %s" % [sheet.name, sheet.job, sheet.post, sheet.situation])
	lines.append("People talk to you and near you. You hear what they say and answer as %s would, out loud, in character. You are never anything but %s." % [sheet.name, sheet.name])
	lines.append("You don't know strangers' names until they tell you; you know them by how they look. Each line you hear says the time, who said it, from where and how well you heard it, and whether it was said to you or overheard.")
	lines.append("")
	lines.append("Who you are: " + sheet.manner)
	lines.append("")
	lines.append("Your night:")
	for r in sheet.routine:
		lines.append("- " + r)
	lines.append("")
	lines.append("What you know:")
	for k in sheet.knows:
		lines.append("- " + k)
	lines.append("")
	lines.append("What you never do:")
	for n in sheet.never:
		lines.append("- " + n)
	lines.append("")
	lines.append("How you check a story:")
	for c in sheet.checks:
		lines.append("- " + c)
	lines.append("")
	lines.append("What gets to you:")
	for w in sheet.weaknesses:
		lines.append("- " + w)
	lines.append("")
	lines.append("You only know what is written here and what happens tonight. Anything else, you don't know and say so. If what you heard is broken up, ask them to say it again rather than guess. When something is overheard and not said to you, you usually say nothing (\"say\": \"\"), unless it concerns you or your job.")
	lines.append("")
	lines.append("Answer with one JSON object and nothing else, shaped like this:")
	lines.append(SHAPE)
	lines.append("")
	lines.append("\"suspicion\" is about the person in the last line: how sure you are that something's wrong with them. 0 relaxed, 1 your usual, 2 something's off, 3 you don't buy it, 4 about to call it in, 5 calling it in. It moves a step at a time, two when something is plainly wrong, and comes down slowly.")
	var acts := PackedStringArray()
	for a in sheet.actions:
		acts.append('"%s" (%s)' % [a, sheet.action_text(a)])
	lines.append("\"do\" is what you do right now about that person, one of: %s. Pick \"none\" unless you mean it. You only do something for someone when you believe who they are and why they're here; a good story alone isn't enough." % ", ".join(acts))
	lines.append("\"say\" is short and plain, the way you talk. Don't repeat yourself. Don't describe actions in it; \"do\" does that.")
	if mind_language:
		lines.append("Keep it clean: no swearing, nothing crude.")
	return "\n".join(lines)


## How far away a line came from.
static func distance_words(d: float) -> String:
	if d < 2.0:
		return "right in front of you"
	if d < 4.5:
		return "a few steps away"
	if d < 9.0:
		return "across the room"
	return "from far off"


## A crew member's line as the character heard it.
static func crew_line(clock: String, who: String, heard: String, distance: float, voice: String, how: String, addressed: bool, through_wall := false) -> String:
	var manner := "normal voice"
	match voice:
		"whisper":
			manner = "whispering"
		"shout":
			manner = "shouting"
	if voice == "phone":
		return "[%s. %s, on the phone, to you] \"%s\"" % [clock, _cap(who), heard]
	if through_wall:
		manner += ", through a wall"
	if how == "muffled":
		manner += ", some words lost"
	elif how == "faint":
		manner += ", barely heard"
	if addressed:
		return "[%s. %s, %s, %s, to you] \"%s\"" % [clock, _cap(who), distance_words(distance), manner, heard]
	return "[%s. Overheard: %s, %s, %s, talking to someone else] \"%s\"" % [clock, who, distance_words(distance), manner, heard]


## Something that happened, in square brackets.
static func event_line(clock: String, text: String) -> String:
	return "[%s. %s]" % [clock, text]


## The whole conversation for the model. History entries are {"who":
## "character" | anything else, "text"}; runs of non-character entries are
## one user message.
static func messages(sheet: CharacterSheet, history: Array, mind_language := false) -> Array:
	var out := [{"role": "system", "content": system(sheet, mind_language)}]
	for h in history:
		var role := "assistant" if h.get("who", "") == "character" else "user"
		var text := str(h.get("text", ""))
		var last: Dictionary = out[out.size() - 1]
		if role == "user" and last.role == "user":
			last["content"] = str(last.content) + "\n" + text
		else:
			out.append({"role": role, "content": text})
	# Chat templates want a user turn first and last.
	if out.size() > 1 and out[1].role == "assistant":
		out.insert(1, {"role": "user", "content": "[The evening so far.]"})
	return out


## Lets the oldest entries go in one big step once the history is long, so
## the cached prefix changes rarely.
static func trim(history: Array) -> void:
	if history.size() <= KEEP:
		return
	var cut := DROP
	# Start the kept part on a line that isn't the character's own.
	while cut < history.size() and history[cut].get("who", "") == "character":
		cut += 1
	history.assign(history.slice(cut))


## The character's reply as it went into the history: compact, and as the
## rules left it.
static func reply_text(reply: Dictionary) -> String:
	return JSON.stringify({
		"think": str(reply.get("think", "")),
		"say": str(reply.get("say", "")),
		"tone": str(reply.get("tone", "calm")),
		"do": str(reply.get("do", "none")),
		"believes": reply.get("believes", []),
		"suspicion": int(reply.get("suspicion", 1)),
	})


static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1) if s != "" else s
