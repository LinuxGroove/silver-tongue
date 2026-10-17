extends Node
## Hearing and speaking through Lemonade Server (autoload: LGVoice), on the
## server [LGBrain] uses.
##
## Hearing: the microphone goes to the realtime transcription API over a
## WebSocket, which sends words as it works them out, with a fallback to
## one WAV through /audio/transcriptions when the socket can't be had. Games
## call [method begin_hearing] and [method end_hearing] round a push to talk,
## or [method set_open_mic] to let the server find the pauses, and listen to
## [signal heard].
##
## Speaking: [method say] asks /audio/speech (Kokoro) for a line, sentence
## by sentence so the first one starts early, and plays it on the
## AudioStreamPlayer3D the game gives it, with the loudness in the
## [LGVoiceLine] it returns, for a mouth.
##
## Nothing here is ever sent anywhere but that server; with push to talk,
## the microphone is read only while the button is held.

signal state_changed(state: String, detail: String)
## Something the player said: partial words while they speak (`final`
## false, the whole utterance so far) and the finished line (`final` true;
## "" when nothing could be made out).
signal heard(text: String, final: bool)
## The server's own voice activity detection, in open mic mode.
signal speech_started
signal speech_stopped
## The microphone's audio as 16 kHz mono PCM16, in chunks, while [member relay]
## is on (for voice chat between players).
signal mic_audio(pcm: PackedByteArray)

const BUS := "Mic"
const RATE := 16000
## Audio goes to the server in chunks about this long.
const CHUNK := 0.1
## How long to wait for the words after letting go of the button.
const HEAR_TIMEOUT := 12.0
const WARM_TIMEOUT := 600.0

## off, starting, ready, listening, thinking, error, no_mic.
var state := "off"
var detail := ""
var hearing_model := "Whisper-Small"
var speaking_model := "kokoro-v1"
## "realtime" (the WebSocket) or "http" (one WAV per utterance).
var transport := ""
## The microphone's loudness right now, 0 to 1.
var mic_level := 0.0
## Send the microphone's audio out as [signal mic_audio] (voice chat).
var relay := false
## Timings of the last utterance, in seconds from letting go of the button:
## {"first_word": first partial after release (or before: negative),
## "final": the finished line, "spoken": how long the utterance was}.
var last_hearing := {}
## How many utterances came back empty.
var misheard := 0
## While starting: "hearing" or "speaking", the model being fetched or warmed.
var phase := ""
## The download in progress, 0 to 1.
var progress := 0.0

var _ready_flag := false
var _ready_model := ""
var _ready_base := ""
var _starting := false
var _mic: AudioStreamPlayer
var _capture: AudioEffectCapture
var _ws: WebSocketPeer
var _ws_open := false
var _listening := false
var _open_mic := false
var _utterance := PackedByteArray()
var _outgoing := PackedByteArray()
var _segments: Array[String] = []
var _partial := ""
var _pressed_at := 0
var _released_at := 0
var _waiting := false
var _first_word_at := 0
var _resample_t := 0.0
var _last_mono := 0.0
var _no_audio_for := 0.0
var _lines: Array[LGVoiceLine] = []
var _players := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_ready() -> bool:
	return _ready_flag


## Connects to the server LGBrain uses, downloads the hearing and speaking
## models if the server hasn't got them (with [member progress]), and warms
## them up. Returns true when both answer. Safe to call again: it returns at
## once while ready with the same hearing model, and joins a start under way.
func setup_async() -> bool:
	if _ready_flag:
		if is_ready_for(hearing_model):
			return true
		stop()
	if _starting:
		while _starting:
			await get_tree().create_timer(0.25).timeout
		return _ready_flag
	_starting = true
	var ok := await _setup()
	_starting = false
	return ok


## Whether hearing with `model` and speaking are ready, on the server LGBrain
## is using now.
func is_ready_for(model: String) -> bool:
	var brain := get_node_or_null("/root/LGBrain")
	return _ready_flag and _ready_model == model and brain != null and brain.is_ready() and brain.base_url() == _ready_base


## Forgets the server: closes the socket, stops the microphone. The next
## [method setup_async] starts over.
func stop() -> void:
	_close_socket()
	for player in _players.keys():
		if is_instance_valid(player):
			hush(player)
	_players.clear()
	_lines.clear()
	_ready_flag = false
	_listening = false
	_waiting = false
	_open_mic = false
	phase = ""
	transport = ""
	if _mic:
		_mic.queue_free()
		_mic = null
	if state != "off":
		_set_state("off", "")


func _setup() -> bool:
	var brain := get_node_or_null("/root/LGBrain")
	if brain == null:
		_set_state("error", "No LGBrain autoload")
		return false
	if not await brain.ensure_ready_async():
		_set_state("error", brain.detail)
		return false
	var client: LlmClient = brain.client()
	phase = "hearing"
	await _fetch(brain, hearing_model)
	_set_state("starting", "Warming up %s" % hearing_model)
	var wav := _wav(_silence(0.6))
	var heard_res := await client.request_bytes(HTTPClient.METHOD_POST, "/audio/transcriptions", _multipart_headers(), _multipart(wav), WARM_TIMEOUT)
	if not heard_res.ok:
		_set_state("error", "Hearing (%s) failed: %s" % [hearing_model, heard_res.error])
		return false
	phase = "speaking"
	await _fetch(brain, speaking_model)
	_set_state("starting", "Warming up %s" % speaking_model)
	var spoke := await client.request_bytes(HTTPClient.METHOD_POST, "/audio/speech", PackedStringArray(["Content-Type: application/json"]),
		JSON.stringify({"model": speaking_model, "input": "Ready.", "response_format": "wav"}).to_utf8_buffer(), WARM_TIMEOUT)
	if not spoke.ok:
		_set_state("error", "Speaking (%s) failed: %s" % [speaking_model, spoke.error])
		return false
	phase = ""
	await _connect_realtime(brain)
	_start_mic()
	_ready_flag = true
	_ready_model = hearing_model
	_ready_base = brain.base_url()
	_set_state("ready", "Hearing with %s (%s), speaking with %s" % [hearing_model, transport, speaking_model])
	return true


## Downloads a model the server hasn't got, with progress. A server that
## can't pull it by name fetches it on the first request instead, so a
## failure here isn't one.
func _fetch(brain: Node, model_name: String) -> void:
	if await brain.is_downloaded_async(model_name):
		return
	progress = 0.0
	_set_state("downloading", "Downloading %s" % model_name)
	brain.download_progress.connect(_on_pull_progress)
	await brain.pull_async(model_name, false)
	brain.download_progress.disconnect(_on_pull_progress)
	progress = 1.0


func _on_pull_progress(model_name: String, fraction: float) -> void:
	progress = fraction
	_set_state("downloading", "Downloading %s (%d%%)" % [model_name, int(fraction * 100.0)])


## Tries the realtime socket on the main port, then the port /health names;
## settles for HTTP when neither opens.
func _connect_realtime(brain: Node) -> void:
	var base: String = brain.base_url()
	var key: String = brain.api_key()
	var urls: Array[String] = []
	var ws_base := base.replace("https://", "wss://").replace("http://", "ws://")
	urls.append(ws_base.trim_suffix("/") + "/realtime")
	var health: Dictionary = await brain.health_async()
	if health.has("websocket_port"):
		var host := base.get_slice("://", 1).get_slice("/", 0).get_slice(":", 0)
		urls.append("ws://%s:%d/realtime" % [host, int(health.websocket_port)])
	for url in urls:
		var full := url + "?model=" + hearing_model.uri_encode()
		if key != "":
			full += "&api_key=" + key.uri_encode()
		if await _open_socket(full):
			transport = "realtime"
			return
	transport = "http"


func _open_socket(url: String) -> bool:
	_close_socket()
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 20
	_ws.outbound_buffer_size = 1 << 20
	if _ws.connect_to_url(url) != OK:
		_ws = null
		return false
	var waited := 0.0
	while waited < 4.0:
		_ws.poll()
		var s := _ws.get_ready_state()
		if s == WebSocketPeer.STATE_OPEN:
			_ws_open = true
			_send({"type": "session.update", "session": {"model": hearing_model, "turn_detection": {"threshold": 0.01, "silence_duration_ms": 900, "prefix_padding_ms": 250}}})
			return true
		if s == WebSocketPeer.STATE_CLOSED:
			break
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	_ws = null
	return false


func _close_socket() -> void:
	if _ws:
		_ws.close()
	_ws = null
	_ws_open = false


## Starts the microphone without the hearing service (for voice chat with
## no models).
func start_mic() -> void:
	_start_mic()


func _start_mic() -> void:
	if _mic:
		return
	var idx := AudioServer.get_bus_index(BUS)
	if idx < 0:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS)
		AudioServer.set_bus_mute(idx, true)
	_capture = null
	for i in AudioServer.get_bus_effect_count(idx):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectCapture:
			_capture = AudioServer.get_bus_effect(idx, i)
	if _capture == null:
		_capture = AudioEffectCapture.new()
		_capture.buffer_length = 2.0
		AudioServer.add_bus_effect(idx, _capture)
	_mic = AudioStreamPlayer.new()
	_mic.name = "Mic"
	_mic.stream = AudioStreamMicrophone.new()
	_mic.bus = BUS
	add_child(_mic)
	_mic.play()


## Starts an utterance (the talk button went down).
func begin_hearing() -> void:
	if not _ready_flag or _listening:
		return
	_listening = true
	_waiting = false
	_utterance.clear()
	_outgoing.clear()
	_segments.clear()
	_partial = ""
	_pressed_at = Time.get_ticks_msec()
	_first_word_at = 0
	_no_audio_for = 0.0
	if _ws_open:
		_send({"type": "input_audio_buffer.clear"})
	_set_state("listening", "Listening")


## Ends the utterance (the talk button came up) and asks for the words.
func end_hearing() -> void:
	if not _listening:
		return
	_listening = false
	_released_at = Time.get_ticks_msec()
	last_hearing = {"first_word": (_first_word_at - _released_at) / 1000.0 if _first_word_at > 0 else -1.0, "final": -1.0, "spoken": (_released_at - _pressed_at) / 1000.0}
	_set_state("thinking", "Working out what you said")
	if _ws_open:
		_flush_outgoing()
		_send({"type": "input_audio_buffer.commit"})
		_waiting = true
		_wait_for_final()
	else:
		_transcribe_http()


func _wait_for_final() -> void:
	var start := _released_at
	await get_tree().create_timer(HEAR_TIMEOUT).timeout
	if _waiting and _released_at == start:
		_finish_utterance(_joined())


## One WAV through /audio/transcriptions.
func _transcribe_http() -> void:
	var brain := get_node_or_null("/root/LGBrain")
	if brain == null or _utterance.size() < RATE * 2 / 5:
		_finish_utterance("")
		return
	var res: Dictionary = await brain.client().request_bytes(HTTPClient.METHOD_POST, "/audio/transcriptions", _multipart_headers(), _multipart(_wav(_utterance)), HEAR_TIMEOUT)
	var text := ""
	if res.ok:
		var data: Variant = JSON.parse_string(res.bytes.get_string_from_utf8())
		if typeof(data) == TYPE_DICTIONARY:
			text = str(data.get("text", ""))
	_finish_utterance(text)


func _finish_utterance(text: String) -> void:
	_waiting = false
	text = text.strip_edges()
	if last_hearing.get("final", -1.0) < 0.0:
		last_hearing["final"] = (Time.get_ticks_msec() - _released_at) / 1000.0
	if text == "":
		misheard += 1
	_set_state("ready", "")
	heard.emit(text, true)


## In open mic mode the server finds the pauses itself; each finished
## utterance comes out of [signal heard] as a final line.
func set_open_mic(on: bool) -> void:
	_open_mic = on and _ws_open
	if _open_mic:
		_listening = false
		_set_state("listening", "Open mic")
	elif state == "listening":
		_set_state("ready", "")


## A typed line, treated as something heard perfectly.
func text_line(text: String) -> void:
	last_hearing = {"first_word": 0.0, "final": 0.0, "spoken": 0.0}
	heard.emit(text.strip_edges(), true)


func _process(delta: float) -> void:
	_poll_socket()
	_pump_mic(delta)
	_pump_lines()


func _poll_socket() -> void:
	if _ws == null:
		return
	_ws.poll()
	var s := _ws.get_ready_state()
	if s != WebSocketPeer.STATE_OPEN:
		if _ws_open and s == WebSocketPeer.STATE_CLOSED:
			_ws_open = false
			transport = "http"
			_ws = null
			if _waiting:
				_transcribe_http()
		return
	while _ws.get_available_packet_count() > 0:
		var pkt := _ws.get_packet()
		var msg: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if typeof(msg) == TYPE_DICTIONARY:
			_on_event(msg)


func _on_event(msg: Dictionary) -> void:
	var type := str(msg.get("type", ""))
	match type:
		"conversation.item.input_audio_transcription.delta":
			_partial = str(msg.get("delta", msg.get("transcript", "")))
			if _first_word_at == 0 and _partial.strip_edges() != "":
				_first_word_at = Time.get_ticks_msec()
				if _waiting:
					last_hearing["first_word"] = (_first_word_at - _released_at) / 1000.0
			heard.emit(_joined(), false)
		"conversation.item.input_audio_transcription.completed":
			var text := str(msg.get("transcript", "")).strip_edges()
			_partial = ""
			if _open_mic and not _listening and not _waiting:
				if text != "":
					last_hearing = {"first_word": 0.0, "final": 0.0, "spoken": 0.0}
					heard.emit(text, true)
				return
			if text != "":
				_segments.append(text)
				if _first_word_at == 0:
					_first_word_at = Time.get_ticks_msec()
					if _waiting:
						last_hearing["first_word"] = (_first_word_at - _released_at) / 1000.0
			if _waiting:
				_finish_utterance(_joined())
			elif _listening:
				heard.emit(_joined(), false)
		"input_audio_buffer.speech_started":
			speech_started.emit()
		"input_audio_buffer.speech_stopped":
			speech_stopped.emit()
		"error":
			var e: Variant = msg.get("error", msg.get("message", ""))
			push_warning("LGVoice: realtime error: %s" % str(e))
			if _waiting:
				_transcribe_http()


func _joined() -> String:
	var parts := PackedStringArray(_segments)
	if _partial != "":
		parts.append(_partial)
	return " ".join(parts).strip_edges()


## Reads the microphone, keeps the utterance and streams it to the socket.
func _pump_mic(delta: float) -> void:
	if _capture == null:
		return
	var n := _capture.get_frames_available()
	if n <= 0:
		if _listening:
			_no_audio_for += delta
			if _no_audio_for > 1.5 and state == "listening":
				_set_state("no_mic", "No microphone")
		return
	var frames := _capture.get_buffer(n)
	var mix := AudioServer.get_mix_rate()
	var step := mix / float(RATE)
	var peak := 0.0
	var out := PackedByteArray()
	var i := _resample_t
	while i < frames.size():
		var f := frames[int(i)]
		var mono := (f.x + f.y) * 0.5
		peak = maxf(peak, absf(mono))
		var v := int(clampf(mono, -1.0, 1.0) * 32767.0)
		out.append(v & 0xFF)
		out.append((v >> 8) & 0xFF)
		i += step
	_resample_t = i - frames.size()
	mic_level = lerpf(mic_level, clampf(peak * 2.5, 0.0, 1.0), 0.5)
	if relay:
		mic_audio.emit(out)
	if not (_listening or _open_mic):
		return
	_no_audio_for = 0.0
	feed_audio(out)


## Audio for the utterance under way, as 16 kHz mono PCM16 (what the
## microphone gives while the button is held; tests and the bench feed a
## recording the same way).
func feed_audio(pcm: PackedByteArray) -> void:
	if _listening:
		_utterance.append_array(pcm)
	if _ws_open and (_listening or _open_mic):
		_outgoing.append_array(pcm)
		if _outgoing.size() >= int(RATE * CHUNK) * 2:
			_flush_outgoing()


func _flush_outgoing() -> void:
	if _outgoing.is_empty() or not _ws_open:
		return
	_send({"type": "input_audio_buffer.append", "audio": Marshalls.raw_to_base64(_outgoing)})
	_outgoing.clear()


func _send(msg: Dictionary) -> void:
	if _ws and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(msg))


## Speaks a line on `player` (a 3D player at the mouth, or any
## AudioStreamPlayer): asks for it a sentence at a time so the first
## sentence starts early, and returns the line, whose `level` follows the
## voice. `voice` is a Kokoro voice ("am_onyx", "af_sky") or an OpenAI one.
func say(text: String, voice: String, player: Node, speed := 1.0) -> LGVoiceLine:
	var line := LGVoiceLine.new()
	line.text = text
	line.voice = voice
	line._t0 = Time.get_ticks_msec()
	if text.strip_edges() == "" or not _ready_flag or player == null:
		line.state = "failed"
		line.error = "nothing to say" if text.strip_edges() == "" else "not ready"
		line.finished.emit.call_deferred()
		return line
	hush(player)
	_lines.append(line)
	_players[player] = {"line": line, "queue": [], "envelopes": [], "env": PackedFloat32Array(), "playing": false}
	_speak_async(line, voice, player, speed)
	return line


## Stops whatever `player` is saying.
func hush(player: Node) -> void:
	if not _players.has(player):
		return
	var p: Dictionary = _players[player]
	var line: LGVoiceLine = p.line
	if line.state in ["asked", "playing"]:
		line.state = "hushed"
		line.finished.emit()
	if player.has_method("stop"):
		player.stop()
	_players.erase(player)
	_lines.erase(line)


func _speak_async(line: LGVoiceLine, voice: String, player: Node, speed: float) -> void:
	var brain := get_node_or_null("/root/LGBrain")
	if brain == null:
		_fail(line, "no LGBrain")
		return
	var client: LlmClient = brain.client()
	var sentences := split_sentences(line.text)
	var expected := sentences.size()
	for s in sentences:
		if line.state in ["hushed", "failed"]:
			return
		var body := {"model": speaking_model, "input": s, "voice": voice, "speed": speed, "response_format": "wav"}
		var res := await client.request_bytes(HTTPClient.METHOD_POST, "/audio/speech", PackedStringArray(["Content-Type: application/json"]), JSON.stringify(body).to_utf8_buffer(), 60.0)
		if not is_instance_valid(player):
			# Freed while the sentence was on its way (its scene closed).
			_players.erase(player)
			_lines.erase(line)
			return
		if line.state in ["hushed", "failed"] or not _players.has(player) or _players[player].line != line:
			return
		if not res.ok:
			_fail(line, res.error)
			return
		var stream := AudioStreamWAV.load_from_buffer(res.bytes)
		if stream == null or stream.data.is_empty():
			_fail(line, "bad audio")
			return
		var p: Dictionary = _players[player]
		p.queue.append(stream)
		p.envelopes.append(envelope(stream))
		line.length += stream.get_length()
		if not p.playing:
			_play_next(player)
	var p: Dictionary = _players.get(player, {})
	if not p.is_empty():
		p["expected"] = expected


func _fail(line: LGVoiceLine, why: String) -> void:
	push_warning("LGVoice: speaking failed: %s" % why)
	line.state = "failed"
	line.error = why
	line.finished.emit()


func _play_next(player: Node) -> void:
	var p: Dictionary = _players.get(player, {})
	if p.is_empty():
		return
	var line: LGVoiceLine = p.line
	if p.queue.is_empty():
		p.playing = false
		if p.has("expected") and p.get("played", 0) >= int(p.expected):
			line.state = "done"
			line.level = 0.0
			line.finished.emit()
			_players.erase(player)
			_lines.erase(line)
		return
	p.playing = true
	p["env"] = p.envelopes.pop_front()
	player.stream = p.queue.pop_front()
	player.play()
	p["played"] = int(p.get("played", 0)) + 1
	if line.state == "asked":
		line.state = "playing"
		line.first_sound = (Time.get_ticks_msec() - line._t0) / 1000.0
		line.started.emit()
	if not player.finished.is_connected(_on_player_finished):
		player.finished.connect(_on_player_finished.bind(player))


func _on_player_finished(player: Node) -> void:
	_play_next(player)


## Follows each playing line's loudness.
func _pump_lines() -> void:
	for player in _players.keys():
		var p: Dictionary = _players[player]
		if not p.playing or not is_instance_valid(player):
			continue
		var env: PackedFloat32Array = p.env
		var at := float(player.get_playback_position())
		var i := int(at / 0.02)
		var line: LGVoiceLine = p.line
		line.level = env[i] if i >= 0 and i < env.size() else 0.0


## The loudness of a WAV in 20 ms steps, 0 to 1.
static func envelope(stream: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var data := stream.data
	var channels := 2 if stream.stereo else 1
	var bytes_per := 2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var frame := channels * bytes_per
	var per := int(stream.mix_rate * 0.02)
	if per <= 0 or frame <= 0:
		return out
	var n := data.size() / frame
	var pos := 0
	while pos < n:
		var acc := 0.0
		var count := 0
		var end := mini(pos + per, n)
		var j := pos
		while j < end:
			var v: float
			if bytes_per == 2:
				var raw := data.decode_s16(j * frame)
				v = raw / 32768.0
			else:
				v = (data[j * frame] - 128) / 128.0
			acc += v * v
			count += 1
			j += 4
		out.append(clampf(sqrt(acc / maxf(count, 1)) * 4.0, 0.0, 1.0))
		pos = end
	return out


## Splits a line at sentence ends, keeping short pieces together.
static func split_sentences(text: String) -> Array[String]:
	var out: Array[String] = []
	var cur := ""
	for ch in text:
		cur += ch
		if ch in [".", "!", "?"] and cur.strip_edges().length() > 24:
			out.append(cur.strip_edges())
			cur = ""
	if cur.strip_edges() != "":
		if not out.is_empty() and cur.strip_edges().length() < 12:
			out[out.size() - 1] += " " + cur.strip_edges()
		else:
			out.append(cur.strip_edges())
	if out.is_empty():
		out.append(text.strip_edges())
	return out


static func _silence(seconds: float) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(int(RATE * seconds) * 2)
	return b


## A 16 kHz mono 16-bit WAV round PCM bytes.
static func _wav(pcm: PackedByteArray) -> PackedByteArray:
	var w := StreamPeerBuffer.new()
	w.big_endian = false
	w.put_data("RIFF".to_ascii_buffer())
	w.put_u32(36 + pcm.size())
	w.put_data("WAVEfmt ".to_ascii_buffer())
	w.put_u32(16)
	w.put_u16(1)
	w.put_u16(1)
	w.put_u32(RATE)
	w.put_u32(RATE * 2)
	w.put_u16(2)
	w.put_u16(16)
	w.put_data("data".to_ascii_buffer())
	w.put_u32(pcm.size())
	w.put_data(pcm)
	return w.data_array


const BOUNDARY := "----LGVoiceBoundary7d4a1"


func _multipart_headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: multipart/form-data; boundary=" + BOUNDARY])


func _multipart(wav: PackedByteArray) -> PackedByteArray:
	var b := PackedByteArray()
	b.append_array(("--%s\r\nContent-Disposition: form-data; name=\"model\"\r\n\r\n%s\r\n" % [BOUNDARY, hearing_model]).to_utf8_buffer())
	b.append_array(("--%s\r\nContent-Disposition: form-data; name=\"language\"\r\n\r\nen\r\n" % BOUNDARY).to_utf8_buffer())
	b.append_array(("--%s\r\nContent-Disposition: form-data; name=\"response_format\"\r\n\r\njson\r\n" % BOUNDARY).to_utf8_buffer())
	b.append_array(("--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"talk.wav\"\r\nContent-Type: audio/wav\r\n\r\n" % BOUNDARY).to_utf8_buffer())
	b.append_array(wav)
	b.append_array(("\r\n--%s--\r\n" % BOUNDARY).to_utf8_buffer())
	return b


func _set_state(s: String, d: String) -> void:
	state = s
	detail = d
	state_changed.emit(s, d)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_close_socket()
