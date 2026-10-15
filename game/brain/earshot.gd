class_name Earshot
extends RefCounted
## What a character makes of a line said from some way off: a whisper
## carries a metre or two, a normal voice a few steps, a shout the whole
## corridor. Past full clarity words drop out (marked with "..."), and past
## the edge nothing is heard at all.

## Metres at which every word still arrives, and at which nothing does.
const RANGES := {
	"whisper": [1.6, 3.2],
	"normal": [3.5, 9.0],
	"shout": [14.0, 30.0],
}
## Under this clarity nothing is heard.
const NOTHING := 0.15


## Clarity, 0 to 1, of a voice at a distance.
static func clarity(distance: float, voice := "normal") -> float:
	var r: Array = RANGES.get(voice, RANGES["normal"])
	if distance <= float(r[0]):
		return 1.0
	if distance >= float(r[1]):
		return 0.0
	return 1.0 - (distance - float(r[0])) / (float(r[1]) - float(r[0]))


## The line as heard: {"clarity", "heard" (the words, "" for nothing),
## "how" ("clear", "muffled" or "faint")}. `rng` decides which words drop.
static func hear(text: String, distance: float, voice := "normal", rng: RandomNumberGenerator = null) -> Dictionary:
	var c := clarity(distance, voice)
	var out := {"clarity": c, "heard": "", "how": "clear"}
	var clean := text.strip_edges()
	if clean == "" or c < NOTHING:
		out.how = "faint"
		return out
	if c >= 0.999:
		out.heard = clean
		return out
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = hash(clean)
	var words := clean.split(" ", false)
	var kept := PackedStringArray()
	var dropped := 0
	var keep_chance := sqrt(c)
	for w in words:
		if rng.randf() < keep_chance:
			kept.append(w)
		else:
			dropped += 1
			if kept.is_empty() or kept[kept.size() - 1] != "...":
				kept.append("...")
	if dropped == words.size():
		out.how = "faint"
		return out
	out.heard = " ".join(kept)
	out.how = "muffled" if c >= 0.5 else "faint"
	return out
