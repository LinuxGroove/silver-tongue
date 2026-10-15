class_name LlmClient
extends Node
## Minimal JSON-over-HTTP client for OpenAI-compatible servers (Lemonade,
## llama.cpp server, Ollama...). One request at a time per call; each call
## gets its own HTTPRequest so several can be in flight.

var base_url := "http://127.0.0.1:13305/api/v1"
var api_key := ""
var timeout := 30.0


## Returns {"ok": bool, "code": int, "data": Variant, "error": String}.
func request_json(method: int, path: String, body: Variant = null, p_timeout := -1.0) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = timeout if p_timeout < 0.0 else p_timeout
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if api_key != "":
		headers.append("Authorization: Bearer " + api_key)
	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(base_url + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "data": null, "error": "request failed to start (%d)" % err}
	var res: Array = await http.request_completed
	http.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "code": code, "data": null, "error": "network error (%d)" % result}
	var data: Variant = JSON.parse_string(text) if text != "" else null
	return {"ok": code >= 200 and code < 300, "code": code, "data": data, "error": "" if code < 300 else text.left(300)}


func get_json(path: String, p_timeout := -1.0) -> Dictionary:
	return await request_json(HTTPClient.METHOD_GET, path, null, p_timeout)


func post_json(path: String, body: Variant, p_timeout := -1.0) -> Dictionary:
	return await request_json(HTTPClient.METHOD_POST, path, body, p_timeout)


## Chat completion. Returns the assistant text, or "" on failure. `schema`
## is a JSON schema the reply must follow (sent as a `json_schema`
## response_format, which llama.cpp turns into a grammar); `json_mode`
## alone only asks for some JSON object.
func chat(model: String, messages: Array, max_tokens := 160, temperature := 0.8, json_mode := false, schema := {}) -> String:
	var res := await chat_full(model, messages, max_tokens, temperature, json_mode, schema)
	return str(res.get("text", ""))


## Chat completion with everything the server sent back: {"text", "ok",
## "usage" (prompt and completion token counts), "timings" (llama.cpp's
## prompt and generation times, and `cache_n`, the prompt tokens it reused),
## "seconds" (the whole round trip), "error"}.
func chat_full(model: String, messages: Array, max_tokens := 160, temperature := 0.8, json_mode := false, schema := {}) -> Dictionary:
	var body := {
		"model": model,
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": temperature,
		"stream": false,
	}
	if not schema.is_empty():
		body["response_format"] = {"type": "json_schema", "json_schema": {"name": str(schema.get("title", "reply")), "strict": true, "schema": schema}}
	elif json_mode:
		body["response_format"] = {"type": "json_object"}
	var t0 := Time.get_ticks_msec()
	var res := await post_json("/chat/completions", body)
	var out := {"text": "", "ok": false, "usage": {}, "timings": {}, "seconds": (Time.get_ticks_msec() - t0) / 1000.0, "error": ""}
	if not res.ok or typeof(res.data) != TYPE_DICTIONARY:
		push_warning("LLM: chat failed: %s" % res.error)
		out.error = str(res.error)
		return out
	var choices: Array = res.data.get("choices", [])
	if choices.is_empty():
		out.error = "no choices"
		return out
	var msg: Dictionary = choices[0].get("message", {})
	out.text = strip_thinking(str(msg.get("content", "")))
	out.ok = true
	if typeof(res.data.get("usage")) == TYPE_DICTIONARY:
		out.usage = res.data.usage
	if typeof(res.data.get("timings")) == TYPE_DICTIONARY:
		out.timings = res.data.timings
	return out


## A request with a body of bytes (audio, multipart forms). Returns
## {"ok", "code", "bytes", "headers", "error"}.
func request_bytes(method: int, path: String, headers: PackedStringArray, body: PackedByteArray, p_timeout := -1.0) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = timeout if p_timeout < 0.0 else p_timeout
	add_child(http)
	var all := PackedStringArray(headers)
	if api_key != "":
		all.append("Authorization: Bearer " + api_key)
	var err := http.request_raw(base_url + path, all, method, body)
	if err != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "bytes": PackedByteArray(), "headers": PackedStringArray(), "error": "request failed to start (%d)" % err}
	var res: Array = await http.request_completed
	http.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "code": code, "bytes": PackedByteArray(), "headers": res[2], "error": "network error (%d)" % result}
	var bytes: PackedByteArray = res[3]
	return {"ok": code >= 200 and code < 300, "code": code, "bytes": bytes, "headers": res[2], "error": "" if code < 300 else bytes.get_string_from_utf8().left(300)}


## Removes <think>...</think> blocks some models emit before the answer.
static func strip_thinking(text: String) -> String:
	var out := text
	while true:
		var start := out.find("<think>")
		if start < 0:
			break
		var end := out.find("</think>", start)
		if end < 0:
			out = out.substr(0, start)
			break
		out = out.substr(0, start) + out.substr(end + 8)
	return out.strip_edges()


## Finds the first JSON object in a model reply, tolerating code fences and
## chatter around it. Returns {} if none parses.
static func extract_json(text: String) -> Dictionary:
	var start := text.find("{")
	while start >= 0:
		var depth := 0
		for i in range(start, text.length()):
			var ch := text[i]
			if ch == "{":
				depth += 1
			elif ch == "}":
				depth -= 1
				if depth == 0:
					var parsed: Variant = JSON.parse_string(text.substr(start, i - start + 1))
					if typeof(parsed) == TYPE_DICTIONARY:
						return parsed
					break
		start = text.find("{", start + 1)
	return {}
