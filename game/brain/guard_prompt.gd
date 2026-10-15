class_name GuardPrompt
extends RefCounted
## Builds the messages a character's brain gets: one stable system prompt
## from the sheet (so the server's prompt cache can keep it) and the
## conversation so far, with the player's lines marked by how well they
## were heard. The system prompt never changes during a night, and the
## history only grows, so each turn adds only its own words.

## The reply format, in the prompt as well as the schema, for models that
## are given no grammar.
const SHAPE := '{"think": "one short line: what you make of this", "say": "what you say out loud, under 30 words, or \\"\\" if you say nothing", "tone": "calm, friendly, wary, annoyed or alarmed", "do": "one of the actions", "believes": ["up to three short things you now believe about this person"], "suspicion": 0}'

## How far away a line came from, for the prompt.
static func distance_words(d: float) -> String:
	if d < 2.0:
		return "right in front of you"
	if d < 4.5:
		return "a few steps away"
	if d < 8.0:
		return "from down the corridor"
	return "from the far end of the corridor"


static func system(sheet: CharacterSheet, mind_language := false) -> String:
	var lines := PackedStringArray()
	lines.append("You are %s, %s, on %s. Someone has walked up to your door. You hear what they say and answer as %s would, out loud, in character. You are never anything but %s." % [sheet.name, sheet.job, sheet.post, sheet.name, sheet.name])
	lines.append("")
	lines.append("Who you are: " + sheet.manner)
	lines.append("")
	lines.append("Your shift:")
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
	lines.append("You only know what is written here. Anything else, you don't know and say so. If what you heard is broken up, you heard it badly: ask them to say it again rather than guess.")
	lines.append("")
	lines.append("Answer with one JSON object and nothing else, shaped like this:")
	lines.append(SHAPE)
	lines.append("")
	lines.append("\"suspicion\" is how sure you are that something's wrong: 0 relaxed, 1 your usual, 2 something's off, 3 you don't buy it, 4 about to call it in, 5 calling it in. It moves a step at a time, two when something is plainly wrong, and comes down slowly.")
	var acts := PackedStringArray()
	for a in sheet.actions:
		acts.append('"%s" (%s)' % [a, CharacterSheet.ACTIONS.get(a, a)])
	lines.append("\"do\" is what you do right now, one of: %s. Pick \"none\" unless you mean it. You only let someone through when you believe who they are and why they're here; a good story alone isn't enough. You only radio for backup when you're sure." % ", ".join(acts))
	lines.append("\"say\" is short and plain, the way you talk. Don't repeat what you said before. Don't describe actions in it; \"do\" does that.")
	if mind_language:
		lines.append("Keep it clean: no swearing, nothing crude.")
	return "\n".join(lines)


## The player's line as the character heard it, with how it came across.
static func player_line(heard: String, distance: float, voice: String, how: String) -> String:
	var where := distance_words(distance)
	var manner := ""
	match voice:
		"whisper":
			manner = "whispering"
		"shout":
			manner = "shouting"
		_:
			manner = "normal voice"
	if how == "muffled":
		manner += ", some words lost"
	elif how == "faint":
		manner += ", barely heard"
	return "[%s, %s] \"%s\"" % [where, manner, heard]


## An event the character notices, as a line in the conversation.
static func event_line(text: String) -> String:
	return "[%s]" % text


## The whole conversation for the model: the system prompt, then the
## history as it happened (player lines and events as the user, the
## character's own replies as the assistant).
static func messages(sheet: CharacterSheet, history: Array, mind_language := false) -> Array:
	var out := [{"role": "system", "content": system(sheet, mind_language)}]
	for h in history:
		var role := "assistant" if h.get("who", "") == "character" else "user"
		out.append({"role": role, "content": str(h.get("text", ""))})
	return out


## The character's reply, as it went into the history: compact, and as the
## rules left it (so the model's past is what actually happened).
static func reply_text(reply: Dictionary) -> String:
	return JSON.stringify({
		"think": str(reply.get("think", "")),
		"say": str(reply.get("say", "")),
		"tone": str(reply.get("tone", "calm")),
		"do": str(reply.get("do", "none")),
		"believes": reply.get("believes", []),
		"suspicion": int(reply.get("suspicion", 1)),
	})
