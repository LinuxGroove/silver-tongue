class_name ModelSetup
extends Node
## Gets Marcus ready before the door: starts Lemonade (through [LGBrain]),
## downloads and loads his brain, runs the schema probe, then downloads and
## warms up his hearing and his voice (through [LGVoice]). Each of the three
## steps keeps a status and a fraction for the setup screen's bars.
##
## It runs on the tree's root rather than in a scene, so leaving the setup
## screen mid-download doesn't stop the download; the door, or the screen
## opened again, picks up whatever is still going.

## A step's status, fraction or detail changed.
signal changed(step: String)
signal finished

const STEPS := ["brain", "ears", "voice"]

## The one running now, if any.
static var running: ModelSetup

## Per step: {"model", "status" (waiting, starting, downloading, loading,
## warming, ready, skipped or failed), "fraction" (0 to 1, or -1 while it
## can't be measured), "detail"}.
var steps := {}
var done := false
var brain_ok := false
var voice_ok := false
## The schema probe's answer (see [method BrainQueue.probe_schema]).
var probe := ""

var _queue: BrainQueue


## The run in progress, or a new one.
static func start(tree: SceneTree) -> ModelSetup:
	if running != null and is_instance_valid(running) and not running.done:
		return running
	var s := ModelSetup.new()
	s.name = "ModelSetup"
	running = s
	# Deferred: this is usually called while a scene is entering the tree.
	tree.root.add_child.call_deferred(s)
	return s


## Whether this run of the door wants hearing and speaking at all.
static func voice_wanted() -> bool:
	var talk := str(LGSettings.get_value("voice", "talk", "push"))
	return bool(LGSettings.get_value("voice", "speaking", true)) or talk != "text"


## Whether there's anything to get ready: AI on, and the brain, the probe
## and (when wanted) the voice not all ready already.
static func needed() -> bool:
	if str(LGSettings.get_value("ai", "mode", "auto")) == "off":
		return false
	if not LGBrain.is_ready() or BrainQueue.cached_probe() == "":
		return true
	return voice_wanted() and not LGVoice.is_ready_for(str(LGSettings.get_value("voice", "hearing_model", "Whisper-Small")))


func _init() -> void:
	for step in STEPS:
		steps[step] = {"model": "", "status": "waiting", "fraction": 0.0, "detail": ""}
	steps.brain.model = str(LGSettings.get_value("ai", "model", ""))
	steps.ears.model = str(LGSettings.get_value("voice", "hearing_model", "Whisper-Small"))
	steps.voice.model = LGVoice.speaking_model


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_queue = BrainQueue.new()
	_queue.name = "Brain"
	add_child(_queue)
	LGBrain.state_changed.connect(_on_brain_state)
	LGBrain.download_progress.connect(_on_download)
	LGVoice.state_changed.connect(_on_voice_state)
	_run()


func _run() -> void:
	_set_step("brain", "starting", -1.0)
	if str(LGSettings.get_value("ai", "mode", "auto")) == "switchboard":
		# The Switchboard answers over the online connection.
		steps.brain.model = "the Switchboard"
		await LGOnline.connect_async(GameConfig.player_name(), GameConfig.GAME_ID)
	brain_ok = await LGBrain.ensure_ready_async()
	if brain_ok:
		steps.brain.model = LGBrain.model if LGBrain.source != "switchboard" else "the Switchboard"
		probe = BrainQueue.cached_probe()
		if probe == "":
			_set_step("brain", "warming", -1.0)
			probe = await _queue.probe_schema()
		_set_step("brain", "ready", 1.0)
	else:
		_set_step("brain", "failed", 0.0, LGBrain.detail)
	if not brain_ok:
		_set_step("ears", "skipped", 0.0, "Needs his brain first")
		_set_step("voice", "skipped", 0.0, "Needs his brain first")
	elif LGBrain.source == "switchboard":
		_set_step("ears", "skipped", 0.0, "You're typing your lines")
		_set_step("voice", "skipped", 0.0, "They speak in subtitles only")
	elif not voice_wanted():
		_set_step("ears", "skipped", 0.0, "You're typing your lines")
		_set_step("voice", "skipped", 0.0, "He speaks in subtitles only")
	else:
		LGVoice.hearing_model = str(steps.ears.model)
		voice_ok = await LGVoice.setup_async()
		if voice_ok:
			_set_step("ears", "ready", 1.0)
			_set_step("voice", "ready", 1.0)
		elif LGVoice.phase == "speaking":
			_set_step("ears", "ready", 1.0)
			_set_step("voice", "failed", 0.0, LGVoice.detail)
		else:
			_set_step("ears", "failed", 0.0, LGVoice.detail)
			_set_step("voice", "skipped", 0.0, "Needs his ears first")
	done = true
	if running == self:
		running = null
	finished.emit()
	queue_free()


## Which step `model_name` belongs to ("" for none).
func step_for(model_name: String) -> String:
	for step in STEPS:
		if str(steps[step].model) == model_name:
			return step
	return ""


func _set_step(step: String, status: String, fraction: float, detail := "") -> void:
	var s: Dictionary = steps[step]
	s.status = status
	s.fraction = fraction
	s.detail = detail
	changed.emit(step)


func _final(step: String) -> bool:
	return str(steps[step].status) in ["ready", "failed", "skipped"]


func _on_brain_state(state: String, _detail: String) -> void:
	if _final("brain"):
		return
	match state:
		"starting":
			_set_step("brain", "starting", -1.0)
		"downloading":
			_set_step("brain", "downloading", LGBrain.progress, _bytes())
		"loading":
			_set_step("brain", "loading", -1.0)


func _on_download(model_name: String, fraction: float) -> void:
	var step := step_for(model_name)
	if step == "" or _final(step):
		return
	_set_step(step, "downloading", fraction, _bytes())


func _on_voice_state(state: String, _detail: String) -> void:
	var step := "ears" if LGVoice.phase == "hearing" else ("voice" if LGVoice.phase == "speaking" else "")
	if step == "":
		return
	if step == "voice" and not _final("ears"):
		_set_step("ears", "ready", 1.0)
	if _final(step):
		return
	match state:
		"downloading":
			_set_step(step, "downloading", maxf(LGVoice.progress, 0.0), _bytes())
		"starting":
			_set_step(step, "warming", -1.0)


## "1.2 of 2.5 GB" for the download in progress, when the server says.
static func _bytes() -> String:
	if LGBrain.download_total <= 0.0:
		return ""
	var gb := 1024.0 * 1024.0 * 1024.0
	if LGBrain.download_total >= gb:
		return "%.1f of %.1f GB" % [LGBrain.download_bytes / gb, LGBrain.download_total / gb]
	var mb := 1024.0 * 1024.0
	return "%d of %d MB" % [int(LGBrain.download_bytes / mb), int(LGBrain.download_total / mb)]
