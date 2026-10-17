extends Node
## Local LLM "brains" for AI players, through Lemonade Server (autoload: LGBrain).
##
## Modes (setting ai/mode):
##   off       never use a model; games fall back to their scripted AI
##   auto      the embedded Lemonade bundled with the game if present,
##             otherwise a Lemonade (or other OpenAI-compatible) server
##             already running at ai/external_url, otherwise off
##   embedded  start the bundled `lemond` privately on localhost
##   external  use ai/external_url only
##   switchboard  the game server's model, over the online connection, for
##             games that set `switchboard_rpc`. What the characters hear and
##             say is sent to the server, so a game asks first.
##
## The embedded server is started only when a game asks for it, with a random
## port and API key known only to this process, and is stopped on exit.
## Models download on first use into a folder that survives snap refreshes
## ($SNAP_USER_COMMON), so they are not copied on every update.

signal state_changed(state: String, detail: String)
## A download's progress (0 to 1), for the model being pulled.
signal download_progress(model_name: String, fraction: float)

const READY_TIMEOUT := 60.0
## Seconds to keep looking for an external server before giving up.
const EXTERNAL_WAIT := 6.0

var state := "off"
var detail := ""
## The download in progress, 0 to 1, over all of its files.
var progress := 0.0
## Its bytes so far and in all (0 when the server doesn't say).
var download_bytes := 0.0
var download_total := 0.0
var model := ""
var source := ""
## The server RPC that answers chats in switchboard mode, like
## "silver-tongue.switchboard"; a game sets it to offer the mode.
var switchboard_rpc := ""
## What's left of today's Switchboard allowance after the last answer (-1 if unknown).
var switchboard_left := -1

var _client: LlmClient
var _pid := -1
var _starting := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_client = LlmClient.new()
	add_child(_client)


func is_ready() -> bool:
	return state == "ready"


## Path to the bundled lemond binary, or "" if this build has none.
func embedded_binary() -> String:
	var candidates: Array[String] = []
	var settings := get_node_or_null("/root/LGSettings")
	if settings and str(settings.get_value("ai", "lemond_path", "")) != "":
		candidates.append(str(settings.get_value("ai", "lemond_path", "")))
	var snap := OS.get_environment("SNAP")
	if snap != "":
		candidates.append(snap.path_join("lemonade/lemond"))
	candidates.append(OS.get_executable_path().get_base_dir().path_join("lemonade/lemond"))
	for c in candidates:
		if FileAccess.file_exists(c):
			return c
	return ""


## Starts (or connects to) a model server and makes sure the model is loaded.
## Safe to call repeatedly; returns true once ready.
func ensure_ready_async() -> bool:
	if state == "ready":
		return true
	if _starting:
		while _starting:
			await get_tree().create_timer(0.25).timeout
		return state == "ready"
	_starting = true
	var ok := await _start()
	_starting = false
	return ok


## Asks the model for a reply. `messages` is OpenAI chat format; `schema`
## is a JSON schema the reply must follow (see [method LlmClient.chat]).
func chat_async(messages: Array, max_tokens := 160, temperature := 0.8, json_mode := false, schema := {}) -> String:
	if state != "ready":
		return ""
	if source == "switchboard":
		return str((await _switchboard_chat(messages, max_tokens, schema)).get("text", ""))
	return await _client.chat(model, messages, max_tokens, temperature, json_mode, schema)


## Asks the model for a reply and returns everything the server sent back
## with it (see [method LlmClient.chat_full]): text, token counts, timings.
func chat_full_async(messages: Array, max_tokens := 160, temperature := 0.8, json_mode := false, schema := {}) -> Dictionary:
	if state != "ready":
		return {"text": "", "ok": false, "usage": {}, "timings": {}, "seconds": 0.0, "error": "not ready"}
	if source == "switchboard":
		return await _switchboard_chat(messages, max_tokens, schema)
	return await _client.chat_full(model, messages, max_tokens, temperature, json_mode, schema)


## The client for the server in use (other services, like LGVoice, share
## its address and key).
func client() -> LlmClient:
	return _client


func base_url() -> String:
	return _client.base_url


func api_key() -> String:
	return _client.api_key


## The server's /health answer ({} if it can't be reached): its version,
## the models loaded, how many it keeps loaded, and `websocket_port`.
func health_async() -> Dictionary:
	var res := await _client.get_json("/health", 3.0)
	return res.data if res.ok and typeof(res.data) == TYPE_DICTIONARY else {}


func stop() -> void:
	if _pid > 0:
		OS.kill(_pid)
		_pid = -1
	if state != "off":
		_set_state("off", "")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _pid > 0:
			OS.kill(_pid)
			_pid = -1


func _start() -> bool:
	var settings := get_node("/root/LGSettings")
	var mode := str(settings.get_value("ai", "mode"))
	model = str(settings.get_value("ai", "model"))
	if mode == "off":
		_set_state("off", "AI brains are turned off")
		return false
	if mode == "switchboard":
		return await _start_switchboard()
	var binary := embedded_binary() if mode in ["auto", "embedded"] else ""
	if binary != "":
		if not await _start_embedded(binary):
			return false
	elif mode in ["auto", "external"]:
		_client.base_url = str(settings.get_value("ai", "external_url")).trim_suffix("/")
		_client.api_key = str(settings.get_value("ai", "external_key", ""))
		source = "external"
		_set_state("starting", "Looking for Lemonade at %s" % _client.base_url)
		if not await _find_external():
			_set_state("unavailable", "No local AI server found")
			return false
	else:
		_set_state("unavailable", "This build has no embedded Lemonade")
		return false
	if not await _ensure_model():
		return false
	_set_state("ready", "%s via %s Lemonade" % [model, source])
	return true


## Signs in to the game server and checks that its Switchboard answers.
func _start_switchboard() -> bool:
	source = "switchboard"
	if switchboard_rpc == "":
		_set_state("unavailable", "This game has no Switchboard")
		return false
	_set_state("starting", "Calling the Switchboard")
	var res := await _switchboard_chat([{"role": "user", "content": "Say ok."}], 4, {})
	if not bool(res.get("ok", false)):
		_set_state("unavailable", "The Switchboard isn't answering (%s)" % str(res.get("error", "")))
		return false
	model = "the game server's model"
	_set_state("ready", "%s via the Switchboard" % model)
	return true


## One chat through the game server. Needs the online connection, which the
## game opens (a game's own sign-in, with its name); the answer is the same
## shape as [method LlmClient.chat_full]'s.
func _switchboard_chat(messages: Array, max_tokens: int, schema: Dictionary) -> Dictionary:
	var out := {"text": "", "ok": false, "usage": {}, "timings": {}, "seconds": 0.0, "error": ""}
	var online := get_node_or_null("/root/LGOnline")
	if online == null or not online.is_connected_online():
		out.error = "not signed in"
		return out
	var payload := {"messages": messages, "max_tokens": mini(max_tokens, 400)}
	if not schema.is_empty():
		payload["json_schema"] = schema
	var t0 := Time.get_ticks_msec()
	var res: Variant = await online.rpc_async(switchboard_rpc, payload)
	out.seconds = (Time.get_ticks_msec() - t0) / 1000.0
	if typeof(res) != TYPE_DICTIONARY:
		out.error = "no answer"
		return out
	out.text = LlmClient.strip_thinking(str(res.get("text", "")))
	out.ok = out.text != ""
	if typeof(res.get("usage")) == TYPE_DICTIONARY:
		out.usage = res.usage
	switchboard_left = int(res.get("left", switchboard_left))
	return out


## Asks the external server's /health until it answers or EXTERNAL_WAIT
## seconds of real time pass: a slow first frame (shaders compiling, a scene
## loading) can outlast one request's timeout on its own.
func _find_external() -> bool:
	var deadline := Time.get_ticks_msec() + int(EXTERNAL_WAIT * 1000.0)
	while true:
		var health := await _client.get_json("/health", 3.0)
		if health.ok:
			return true
		if Time.get_ticks_msec() >= deadline:
			return false
		await get_tree().create_timer(0.5).timeout
	return false


func _start_embedded(binary: String) -> bool:
	source = "embedded"
	var base := OS.get_environment("SNAP_USER_COMMON")
	if base == "":
		base = OS.get_user_data_dir()
	var cache_dir := base.path_join("lemonade/cache")
	var config_dir := base.path_join("lemonade/config")
	DirAccess.make_dir_recursive_absolute(cache_dir)
	DirAccess.make_dir_recursive_absolute(config_dir)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var port := rng.randi_range(20000, 29999)
	var key := ""
	for i in 32:
		key += "%x" % rng.randi_range(0, 15)
	# The child inherits the environment, which is how lemond reads its key.
	OS.set_environment("LEMONADE_API_KEY", key)
	_pid = OS.create_process(binary, [
		"--host", "127.0.0.1", "--port", str(port), "--no-broadcast", cache_dir, config_dir])
	OS.unset_environment("LEMONADE_API_KEY")
	if _pid <= 0:
		_set_state("error", "Could not start the embedded Lemonade server")
		return false
	_client.base_url = "http://127.0.0.1:%d/api/v1" % port
	_client.api_key = key
	_set_state("starting", "Starting the local AI server")
	var waited := 0.0
	while waited < READY_TIMEOUT:
		if not OS.is_process_running(_pid):
			_pid = -1
			_set_state("error", "The local AI server stopped unexpectedly")
			return false
		var health := await _client.get_json("/health", 2.0)
		if health.ok:
			return true
		await get_tree().create_timer(0.5).timeout
		waited += 0.5 + 0.1
	_set_state("error", "The local AI server did not start in time")
	stop()
	return false


## Whether the server has `name` on disk. A model the server doesn't list
## counts as downloaded: it's not one the server can pull by name.
func is_downloaded_async(name: String) -> bool:
	var models := await _client.get_json("/models", 10.0)
	if models.ok and typeof(models.data) == TYPE_DICTIONARY:
		for m in models.data.get("data", []):
			if str(m.get("id", "")) == name:
				return bool(m.get("downloaded", true))
	return true


func _ensure_model() -> bool:
	if not await is_downloaded_async(model):
		if not await pull_async(model):
			return false
	_set_state("loading", "Loading %s" % model)
	var load_res := await _client.post_json("/load", {"model_name": model, "ctx_size": 4096}, 300.0)
	if not load_res.ok and load_res.code != 404:
		_set_state("error", "Could not load %s: %s" % [model, load_res.error])
		return false
	return true


## Downloads `name` through the server, reporting [signal download_progress]
## (and `progress`) as it goes. With `announce`, this service's own state
## follows the download (for its own model); without, only the signal does
## (for another service's models, like LGVoice's). Returns true once the
## server has the model, or at once on a server that can't pull by name.
func pull_async(name: String, announce := true) -> bool:
	progress = 0.0
	download_bytes = 0.0
	download_total = 0.0
	if announce:
		_set_state("downloading", "Downloading %s" % name)
	download_progress.emit(name, 0.0)
	var start := await _client.post_json("/pull", {"model_name": name, "stream": true, "subscribe": false}, 30.0)
	if start.code == 404:
		return true  # Not Lemonade (plain OpenAI server): assume the model exists.
	var refused := typeof(start.data) == TYPE_DICTIONARY and str(start.data.get("status", "")) == "error"
	if not start.ok or refused:
		var why := str(start.data.get("message", start.error)) if typeof(start.data) == TYPE_DICTIONARY else str(start.error)
		if announce:
			_set_state("error", "Could not download %s: %s" % [name, why])
		return false
	var missing_for := 0
	while missing_for < 30:
		await get_tree().create_timer(1.0).timeout
		var jobs := await _client.get_json("/downloads", 10.0)
		if not jobs.ok or typeof(jobs.data) != TYPE_ARRAY:
			missing_for += 1
			continue
		var found := false
		for job in jobs.data:
			if str(job.get("model_name", "")) == name:
				found = true
		missing_for = 0 if found else missing_for + 1
		for job in jobs.data:
			if str(job.get("model_name", "")) != name:
				continue
			_read_job(job)
			var status := str(job.get("status", ""))
			if bool(job.get("complete", false)) or status == "completed":
				progress = 1.0
				download_progress.emit(name, 1.0)
				return true
			if status in ["error", "cancelled"]:
				if announce:
					_set_state("error", "Download failed: %s" % str(job.get("error", status)))
				return false
			download_progress.emit(name, progress)
			if announce:
				_set_state("downloading", "Downloading %s (%d%%)" % [name, int(progress * 100.0)])
	# The job finished and was cleared before we saw it complete; check the list.
	if await is_downloaded_async(name):
		progress = 1.0
		download_progress.emit(name, 1.0)
		return true
	if announce:
		_set_state("error", "Download of %s did not finish" % name)
	return false


## Progress over the whole download from a /downloads job: its overall
## bytes when the server gives them, otherwise the file it's on and how far
## through that file it is (`percent` is per file).
func _read_job(job: Dictionary) -> void:
	var total := float(job.get("total_download_size", 0.0))
	var got := float(job.get("overall_bytes_downloaded", -1.0))
	var files := maxi(int(job.get("total_files", 1)), 1)
	var file := clampi(int(job.get("file_index", 1)), 1, files)
	var percent := clampf(float(job.get("percent", 0.0)) / 100.0, 0.0, 1.0)
	if total > 0.0 and got >= 0.0:
		progress = clampf(got / total, 0.0, 1.0)
		download_bytes = got
		download_total = total
	else:
		progress = (float(file - 1) + percent) / float(files)
		download_bytes = 0.0
		download_total = 0.0


func _set_state(s: String, d: String) -> void:
	state = s
	detail = d
	state_changed.emit(s, d)
