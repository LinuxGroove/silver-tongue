class_name ReplySchema
extends RefCounted
## The shape of a character's reply: a JSON schema the server turns into a
## grammar (so the model can only write a valid reply), and a parser that
## makes the best of a reply from a server that didn't.

const TONES := ["calm", "friendly", "wary", "annoyed", "alarmed"]
const THINK_MAX := 160
const SAY_MAX := 220
const BELIEF_MAX := 60


static func schema(actions: Array[String]) -> Dictionary:
	return {
		"title": "character_reply",
		"type": "object",
		"properties": {
			"think": {"type": "string", "maxLength": THINK_MAX},
			"say": {"type": "string", "maxLength": SAY_MAX},
			"tone": {"type": "string", "enum": TONES},
			"do": {"type": "string", "enum": actions},
			"believes": {"type": "array", "items": {"type": "string", "maxLength": BELIEF_MAX}, "maxItems": 3},
			"suspicion": {"type": "integer", "minimum": 0, "maximum": 5},
		},
		"required": ["think", "say", "tone", "do", "believes", "suspicion"],
		"additionalProperties": false,
	}


## A tiny schema whose only valid answer is one word, to see whether the
## server enforces schemas at all (M0's check that `response_format`
## reaches llama.cpp).
static func probe_schema() -> Dictionary:
	return {
		"title": "probe",
		"type": "object",
		"properties": {"word": {"type": "string", "enum": ["pineapple"]}},
		"required": ["word"],
		"additionalProperties": false,
	}


## The reply as a dictionary with every field present and sane, or {} if
## there's no JSON in the text at all. `actions` is what "do" may be.
static func parse(text: String, actions: Array[String]) -> Dictionary:
	var d := LlmClient.extract_json(text)
	if d.is_empty():
		return {}
	var out := {}
	out["think"] = str(d.get("think", "")).left(THINK_MAX)
	out["say"] = str(d.get("say", "")).strip_edges().left(SAY_MAX)
	var tone := str(d.get("tone", "calm")).to_lower().strip_edges()
	out["tone"] = tone if tone in TONES else "calm"
	var act := str(d.get("do", "none")).to_lower().strip_edges()
	out["do"] = act if act in actions else "none"
	var believes: Array = []
	var raw: Variant = d.get("believes", [])
	if typeof(raw) == TYPE_ARRAY:
		for b in raw:
			if believes.size() < 3 and str(b).strip_edges() != "":
				believes.append(str(b).strip_edges().left(BELIEF_MAX))
	elif typeof(raw) == TYPE_STRING and str(raw).strip_edges() != "":
		believes.append(str(raw).strip_edges().left(BELIEF_MAX))
	out["believes"] = believes
	var s: Variant = d.get("suspicion", 1)
	out["suspicion"] = clampi(int(s) if typeof(s) in [TYPE_INT, TYPE_FLOAT] else int(str(s).to_int()), 0, 5)
	return out


## Whether a reply follows the schema to the letter (what a grammar
## guarantees; counted to tell an enforced schema from a lucky model).
static func is_strict(text: String, actions: Array[String]) -> bool:
	var d: Variant = JSON.parse_string(text.strip_edges())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for k in ["think", "say", "tone", "do", "believes", "suspicion"]:
		if not d.has(k):
			return false
	if d.keys().size() != 6:
		return false
	if typeof(d.think) != TYPE_STRING or typeof(d.say) != TYPE_STRING:
		return false
	if not str(d.tone) in TONES or not str(d.do) in actions:
		return false
	if typeof(d.believes) != TYPE_ARRAY or (d.believes as Array).size() > 3:
		return false
	if typeof(d.suspicion) != TYPE_FLOAT and typeof(d.suspicion) != TYPE_INT:
		return false
	var s := float(d.suspicion)
	return s == floorf(s) and s >= 0.0 and s <= 5.0
