extends Node
## M0's numbers in one run, against a real Lemonade: the schema probe, then
## a set of lines through Marcus's whole stack, with each turn's hearing
## (from a recording), thinking (round trip, prompt tokens, how many the
## cache reused) and speaking (the ask to the first sound). The first line
## is from scratch; the rest find the system prompt in the cache.
##
##   godot --path . tools/m0_bench.tscn -- [--lines=/path/lines.txt] [--wav=/path/said.wav]
##       [--hearing=Whisper-Tiny] [--model=LFM2.5-1.2B-Instruct-GGUF] [--runs=2]
##       [--no-voice] [--out=/tmp/m0.json]
##
## Run it with a window so the lines play out loud (headless works too, but
## says nothing). --wav replays one recording (16-bit WAV, any rate) as what
## you said, for every line, so the hearing timings come from the real model
## without you at the microphone; the words it hears replace the line.
## Settings (the AI mode, the Lemonade address) come from the game's own
## settings file; --model and --hearing override them for this run.

const LINES := [
	"Evening. Facilities sent me about the walk-in freezer.",
	"Priya booked it before she left. She said you'd know.",
	"I know, I know. She never books anything, does she?",
	"Look, I've got two more hotels tonight. Can I just get in and out?",
	"What's the code for the kitchen door?",
	"Sorry, mate. Long night. You've been here since eight?",
	"Ten o'clock shift change, is it? Who's on after you?",
	"Right. I'll come back with the work order.",
]

var lines: Array = LINES.duplicate()
var wav := PackedByteArray()
var out_path := ""
var runs := 1
var use_voice := true
var results := {"runs": []}
var _heard := ""
var _heard_done := false


func _ready() -> void:
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGInput.register_actions(GameConfig.ACTIONS)
	HotelTheme.apply(get_tree().root, 22)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lines="):
			var f := FileAccess.open(a.trim_prefix("--lines="), FileAccess.READ)
			if f:
				lines = []
				for l in f.get_as_text().split("\n", false):
					if l.strip_edges() != "":
						lines.append(l.strip_edges())
		elif a.begins_with("--wav="):
			wav = _load_wav(a.trim_prefix("--wav="))
		elif a.begins_with("--hearing="):
			LGSettings.set_value("voice", "hearing_model", a.trim_prefix("--hearing="))
		elif a.begins_with("--model="):
			LGSettings.set_value("ai", "model", a.trim_prefix("--model="))
		elif a.begins_with("--runs="):
			runs = maxi(1, int(a.trim_prefix("--runs=")))
		elif a.begins_with("--out="):
			out_path = a.trim_prefix("--out=")
		elif a == "--no-voice":
			use_voice = false
	await _run()
	get_tree().quit()


func _run() -> void:
	print("Silver Tongue M0 bench, %s" % Time.get_datetime_string_from_system())
	print("Brain: starting (%s, %s)" % [LGSettings.get_value("ai", "mode"), LGSettings.get_value("ai", "model")])
	var ok: bool = await LGBrain.ensure_ready_async()
	if not ok:
		print("No brain: %s" % LGBrain.detail)
		return
	var health: Dictionary = await LGBrain.health_async()
	results["server"] = {"version": health.get("version", "?"), "max_models": health.get("max_models", "?"), "url": LGBrain.base_url(), "source": LGBrain.source}
	results["model"] = LGBrain.model
	print("Brain: %s  (Lemonade %s, keeps %s models loaded)" % [LGBrain.detail, health.get("version", "?"), str(health.get("max_models", "?"))])
	var queue := BrainQueue.new()
	add_child(queue)
	var probe: String = await queue.probe_schema()
	results["schema"] = probe
	print("Schema: %s" % probe)
	if use_voice:
		LGVoice.hearing_model = str(LGSettings.get_value("voice", "hearing_model"))
		print("Voice: warming up %s and %s" % [LGVoice.hearing_model, LGVoice.speaking_model])
		var v: bool = await LGVoice.setup_async()
		print("Voice: %s" % LGVoice.detail)
		results["voice"] = {"ok": v, "detail": LGVoice.detail, "transport": LGVoice.transport, "hearing_model": LGVoice.hearing_model}
		use_voice = v
	for r in runs:
		print("\nRun %d of %d" % [r + 1, runs])
		results.runs.append(await _one_run())
	_report()
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(results, "  "))
			f.close()
			print("Written to %s" % out_path)


func _one_run() -> Dictionary:
	var door := GuardDoor.new()
	add_child(door)
	var guard := Guard.make(CharacterSheet.marcus(), door)
	add_child(guard)
	guard.speak = use_voice
	var turns := []
	var ear := guard.global_position + Vector3(0, 1.6, 0)
	print("%-4s %-9s %-9s %-9s %-9s %-7s %-6s %s" % ["#", "heard", "thought", "cached", "spoke", "strict", "susp", "say / do"])
	for i in lines.size():
		var line: String = lines[i]
		var hearing := {}
		if use_voice and not wav.is_empty():
			var heard := await _hear(wav)
			hearing = LGVoice.last_hearing.duplicate()
			hearing["heard"] = heard
			if heard != "":
				line = heard
		var before := guard.turns.size()
		guard.hear(line, ear + Vector3(0, 0, 1.5), "normal")
		var waited := 0.0
		while (guard.turns.size() <= before or guard.busy) and waited < 60.0:
			await get_tree().process_frame
			waited += get_process_delta_time()
		if guard.turns.size() <= before:
			print("%-4d no turn after %.0f s" % [i + 1, waited])
			continue
		var t: Dictionary = guard.turns[before]
		t["hearing"] = hearing
		t["line"] = line
		turns.append(t)
		var reply: Dictionary = t.get("reply", {})
		print("%-4d %-9s %-9s %-9s %-9s %-7s %-6s %s / %s%s" % [
			i + 1,
			("%.2f s" % float(hearing.final)) if hearing.has("final") and float(hearing.final) >= 0.0 else "-",
			("%.2f s" % float(t.thought)) if float(t.get("thought", 0.0)) > 0.0 else "-",
			("%d/%d" % [int(t.cached_tokens), int(t.prompt_tokens)]) if int(t.get("cached_tokens", -1)) >= 0 else ("%d" % int(t.get("prompt_tokens", -1))),
			("%.2f s" % float(t.spoke)) if float(t.get("spoke", -1.0)) >= 0.0 else "-",
			"yes" if bool(t.get("strict", false)) else ("script" if bool(t.get("scripted", false)) else "no"),
			str(t.get("suspicion", "?")),
			str(reply.get("say", "")).left(60), str(reply.get("do", "")),
			(" (vetoed %s)" % t.vetoed) if str(t.get("vetoed", "")) != "" else "",
		])
		# Wait for him to finish speaking before the next line, as a player would.
		waited = 0.0
		while guard.is_speaking() and waited < 20.0:
			await get_tree().process_frame
			waited += get_process_delta_time()
		# Reception answers on its own; give that turn time to land too.
		if str(reply.get("do", "")) == "ask_reception":
			waited = 0.0
			while (guard.turns.size() < before + 2 or guard.busy) and waited < 60.0:
				await get_tree().process_frame
				waited += get_process_delta_time()
			if guard.turns.size() >= before + 2:
				var e: Dictionary = guard.turns[before + 1]
				turns.append(e)
				print("%-4s %-9s %-9s %-9s %-9s %-7s %-6s %s / %s" % ["", "-", ("%.2f s" % float(e.thought)) if float(e.get("thought", 0.0)) > 0.0 else "-", ("%d/%d" % [int(e.cached_tokens), int(e.prompt_tokens)]) if int(e.get("cached_tokens", -1)) >= 0 else "-", ("%.2f s" % float(e.spoke)) if float(e.get("spoke", -1.0)) >= 0.0 else "-", "yes" if bool(e.get("strict", false)) else "no", str(e.get("suspicion", "?")), str(e.reply.get("say", "")).left(60), str(e.reply.get("do", ""))])
	guard.queue_free()
	door.queue_free()
	return {"turns": turns, "misheard": LGVoice.misheard}


## Feeds a recording as one utterance and returns what was heard.
func _hear(pcm: PackedByteArray) -> String:
	_heard = ""
	_heard_done = false
	LGVoice.heard.connect(_on_heard)
	LGVoice.begin_hearing()
	var chunk := 3200
	var pos := 0
	while pos < pcm.size():
		LGVoice.feed_audio(pcm.slice(pos, mini(pos + chunk, pcm.size())))
		pos += chunk
		await get_tree().create_timer(0.1).timeout
	LGVoice.end_hearing()
	var waited := 0.0
	while not _heard_done and waited < 20.0:
		await get_tree().process_frame
		waited += get_process_delta_time()
	LGVoice.heard.disconnect(_on_heard)
	return _heard


func _on_heard(text: String, final: bool) -> void:
	if final:
		_heard = text
		_heard_done = true


func _report() -> void:
	var all := []
	for r in results.runs:
		all.append_array(r.turns)
	var thought := []
	var first := -1.0
	var heard := []
	var spoke := []
	var strict := 0
	var model := 0
	for t in all:
		if float(t.get("thought", 0.0)) > 0.0 and not bool(t.get("scripted", false)):
			thought.append(float(t.thought))
			if first < 0.0:
				first = float(t.thought)
		if not bool(t.get("scripted", false)):
			model += 1
			if bool(t.get("strict", false)):
				strict += 1
		var h: Dictionary = t.get("hearing", {})
		if h.has("final") and float(h.final) >= 0.0:
			heard.append(float(h.final))
		if float(t.get("spoke", -1.0)) >= 0.0:
			spoke.append(float(t.spoke))
	var summary := {
		"turns": all.size(),
		"first_thought": first,
		"thought_mean": _mean(thought),
		"thought_max": _max(thought),
		"heard_mean": _mean(heard),
		"heard_max": _max(heard),
		"spoke_mean": _mean(spoke),
		"spoke_max": _max(spoke),
		"strict": strict,
		"model_turns": model,
	}
	results["summary"] = summary
	print("\nSummary over %d turns" % all.size())
	print("  thought: first (from scratch) %.2f s, then mean %.2f s, worst %.2f s" % [first, summary.thought_mean, summary.thought_max])
	if not heard.is_empty():
		print("  heard: mean %.2f s, worst %.2f s after the end of speech" % [summary.heard_mean, summary.heard_max])
	if not spoke.is_empty():
		print("  spoke: first sound mean %.2f s, worst %.2f s (target 0.5)" % [summary.spoke_mean, summary.spoke_max])
	print("  schema: %s; %d of %d model replies strictly valid" % [results.get("schema", "?"), strict, model])


static func _mean(v: Array) -> float:
	if v.is_empty():
		return -1.0
	var s := 0.0
	for x in v:
		s += float(x)
	return s / v.size()


static func _max(v: Array) -> float:
	var m := -1.0
	for x in v:
		m = maxf(m, float(x))
	return m


## A 16-bit WAV as 16 kHz mono PCM16 (any rate or channel count in).
static func _load_wav(path: String) -> PackedByteArray:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("m0_bench: can't read %s" % path)
		return PackedByteArray()
	var bytes := f.get_buffer(f.get_length())
	f.close()
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		push_error("m0_bench: %s isn't a WAV" % path)
		return PackedByteArray()
	var pos := 12
	var channels := 1
	var rate := 16000
	var bits := 16
	var data := PackedByteArray()
	while pos + 8 <= bytes.size():
		var id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size := bytes.decode_u32(pos + 4)
		if id == "fmt ":
			channels = bytes.decode_u16(pos + 10)
			rate = bytes.decode_u32(pos + 12)
			bits = bytes.decode_u16(pos + 22)
		elif id == "data":
			data = bytes.slice(pos + 8, pos + 8 + size)
			break
		pos += 8 + size + (size & 1)
	if bits != 16:
		push_error("m0_bench: only 16-bit WAVs")
		return PackedByteArray()
	var frames := data.size() / (2 * channels)
	var out := PackedByteArray()
	var step := float(rate) / 16000.0
	var i := 0.0
	while i < frames:
		var fi := int(i)
		var acc := 0
		for c in channels:
			acc += data.decode_s16((fi * channels + c) * 2)
		out.append_array(PackedByteArray([0, 0]))
		out.encode_s16(out.size() - 2, clampi(acc / channels, -32768, 32767))
		i += step
	return out
