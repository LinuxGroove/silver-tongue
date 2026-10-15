class_name BrainQueue
extends Node
## One brain request at a time through [LGBrain], with a timeout, and the
## numbers M0 wants from each: the round trip, the tokens, and what the
## server's cache reused.

## Seconds before a slow reply is given up on and a scripted line used.
const TIMEOUT := 9.0

var busy := false
var _waiting := 0


## Asks the model. Returns {"ok", "text", "seconds", "timed_out",
## "prompt_tokens", "completion_tokens", "cached_tokens" (-1 when the server
## doesn't say), "prompt_ms", "predicted_ms", "error"}.
func ask(messages: Array, schema := {}, max_tokens := 220, temperature := 0.7) -> Dictionary:
	_waiting += 1
	while busy:
		await get_tree().process_frame
	_waiting -= 1
	busy = true
	var out := {"ok": false, "text": "", "seconds": 0.0, "timed_out": false, "prompt_tokens": -1, "completion_tokens": -1, "cached_tokens": -1, "prompt_ms": -1.0, "predicted_ms": -1.0, "error": ""}
	if not LGBrain.is_ready():
		out.error = "brain not ready"
		busy = false
		return out
	var client: LlmClient = LGBrain.client()
	var old_timeout: float = client.timeout
	client.timeout = TIMEOUT
	var res: Dictionary = await LGBrain.chat_full_async(messages, max_tokens, temperature, true, schema)
	client.timeout = old_timeout
	out.seconds = float(res.get("seconds", 0.0))
	out.text = str(res.get("text", ""))
	out.ok = bool(res.get("ok", false)) and out.text != ""
	out.error = str(res.get("error", ""))
	out.timed_out = not out.ok and out.seconds >= TIMEOUT - 0.5
	var usage: Dictionary = res.get("usage", {})
	if not usage.is_empty():
		out.prompt_tokens = int(usage.get("prompt_tokens", -1))
		out.completion_tokens = int(usage.get("completion_tokens", -1))
		var details: Variant = usage.get("prompt_tokens_details", {})
		if typeof(details) == TYPE_DICTIONARY and details.has("cached_tokens"):
			out.cached_tokens = int(details.cached_tokens)
	var timings: Dictionary = res.get("timings", {})
	if not timings.is_empty():
		if timings.has("cache_n"):
			out.cached_tokens = int(timings.cache_n)
		out.prompt_ms = float(timings.get("prompt_ms", -1.0))
		out.predicted_ms = float(timings.get("predicted_ms", -1.0))
		if out.prompt_tokens < 0 and timings.has("prompt_n"):
			out.prompt_tokens = int(timings.prompt_n)
		if out.completion_tokens < 0 and timings.has("predicted_n"):
			out.completion_tokens = int(timings.predicted_n)
	busy = false
	return out


## Whether the server enforces a JSON schema: "enforced" when a schema that
## allows one word gets that word, "not enforced" when the model answers
## freely, "failed" when there's no answer at all.
func probe_schema() -> String:
	var res := await ask([
		{"role": "system", "content": "You answer in JSON."},
		{"role": "user", "content": "Say hello in one word."},
	], ReplySchema.probe_schema(), 20, 0.0)
	if not res.ok:
		return "failed"
	var d := LlmClient.extract_json(res.text)
	return "enforced" if str(d.get("word", "")) == "pineapple" else "not enforced"
