class_name SetupScreen
extends Node
## Before the door: Marcus's brain, ears and voice downloaded, loaded and
## warmed up, a bar for each, so the corridor starts with him ready to
## listen. Goes on to the door by itself once everything is ready; the
## player can go in early (he answers with scripted lines until he's
## ready) or go back, and the downloads carry on either way.

const SCENE := "res://game/ui/setup_screen.tscn"
const TITLE := "res://game/ui/title.tscn"
const WIDTH := 560
## How long "Ready" shows before the door.
const READY_PAUSE := 0.8
const NAMES := {"brain": "His brain", "ears": "His ears", "voice": "His voice"}
const ABOUT := {"brain": "the language model he thinks with", "ears": "the speech model that hears you", "voice": "the voice he answers in"}

## Goes on to the door by itself once ready (tests turn it off).
var go_on := true
var setup: ModelSetup
var backdrop: MenuBackdrop
## The run has finished (ready or not).
var finished := false
var _col: VBoxContainer
var _rows := {}
var _note: Label
var _buttons: VBoxContainer
var _leaving := false


## The door, through this screen when there's anything to get ready.
static func play_door() -> void:
	if ModelSetup.needed():
		LGScenes.change_scene(SCENE)
	else:
		ProofScene.play()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	backdrop = MenuBackdrop.make()
	add_child(backdrop)
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var shade := TextureRect.new()
	shade.texture = HotelTheme.shade_texture()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = HotelTheme.SHADE_RIGHT + 0.08
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	_col = LGUi.centered_column(ui, WIDTH)
	_col.get_parent().anchor_right = HotelTheme.SHADE_RIGHT
	LGScreenFit.center(_col)
	_col.add_child(HotelTheme.title_label("Getting Marcus ready", 44, HotelTheme.BRASS))
	var intro := LGUi.label("Marcus thinks, hears and speaks on this computer. The first time, his models download, which can take a few minutes. After that he's ready in seconds.", "DimLabel")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = WIDTH
	_col.add_child(intro)
	setup = ModelSetup.start(get_tree())
	for step in ModelSetup.STEPS:
		_add_row(step)
	_note = LGUi.label("", "DimLabel")
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size.x = WIDTH
	_col.add_child(_note)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	_col.add_child(_buttons)
	setup.changed.connect(_on_changed)
	setup.finished.connect(_on_finished)
	for step in ModelSetup.STEPS:
		_on_changed(step)
	_waiting_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back()


func _add_row(step: String) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	var name_label := HotelTheme.hud_label(NAMES[step], 22, HotelTheme.TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var status := HotelTheme.hud_label("Waiting", 18, HotelTheme.DIM, false)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status)
	box.add_child(top)
	var bar := HotelTheme.bar(HotelTheme.BRASS, WIDTH, 12)
	box.add_child(bar)
	var detail := HotelTheme.hud_label("", 15, HotelTheme.DIM, false)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size.x = WIDTH
	box.add_child(detail)
	_col.add_child(box)
	_rows[step] = {"status": status, "bar": bar, "detail": detail}


## The status shown for a step (for tests).
func row_status(step: String) -> String:
	return (_rows[step].status as Label).text


## How full a step's bar is, 0 to 1 (for tests).
func bar_value(step: String) -> float:
	return float((_rows[step].bar as ProgressBar).value)


## The labels of the buttons showing now (for tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _buttons.get_children():
		if b is Button and not b.is_queued_for_deletion():
			out.append(b.text)
	return out


func _on_changed(step: String) -> void:
	if not _rows.has(step) or setup == null:
		return
	var s: Dictionary = setup.steps[step]
	var row: Dictionary = _rows[step]
	var status := row.status as Label
	var bar := row.bar as ProgressBar
	var detail := row.detail as Label
	var fraction := float(s.fraction)
	var color := HotelTheme.DIM
	bar.indeterminate = fraction < 0.0 and str(s.status) in ["starting", "loading", "warming", "downloading"]
	if fraction >= 0.0:
		bar.value = fraction
	match str(s.status):
		"waiting":
			status.text = "Waiting"
		"starting":
			status.text = "Starting the AI server"
		"downloading":
			status.text = "Downloading %d%%" % int(round(maxf(fraction, 0.0) * 100.0))
			color = HotelTheme.BRASS
		"loading":
			status.text = "Loading"
			color = HotelTheme.BRASS
		"warming":
			status.text = "Warming up"
			color = HotelTheme.BRASS
		"ready":
			status.text = "Ready"
			color = HotelTheme.GREEN
		"skipped":
			status.text = "Not needed"
		"failed":
			status.text = "Failed"
			color = HotelTheme.BURGUNDY
	status.add_theme_color_override("font_color", color)
	bar.add_theme_stylebox_override("fill", HotelTheme.box(HotelTheme.GREEN if str(s.status) == "ready" else HotelTheme.BRASS, Color(0, 0, 0, 0), 0, 2))
	var parts := PackedStringArray()
	parts.append(_pretty(str(s.model)) + ", " + ABOUT[step])
	if str(s.detail) != "":
		parts.append(str(s.detail))
	detail.text = "  ·  ".join(parts)


func _on_finished() -> void:
	finished = true
	var brain_ok := setup.brain_ok
	var voice_ok := setup.voice_ok or not ModelSetup.voice_wanted()
	# The run frees itself once it's done.
	setup = null
	_clear_buttons()
	if brain_ok and voice_ok:
		_note.text = "Ready. In you go."
		_note.add_theme_color_override("font_color", HotelTheme.GREEN)
		_add_button("Go in", _go_in)
		_add_button("Back", _back)
		if go_on:
			get_tree().create_timer(READY_PAUSE).timeout.connect(_go_in)
		return
	if not brain_ok:
		_note.text = "Marcus needs Lemonade, the local AI server. It comes with the game; when running from source, start one and choose it in Settings. You can still go in: he answers with scripted lines."
	else:
		_note.text = "His brain is ready, but he can't hear or speak. Go in and type your lines with %s." % LGInput.label_for_action("text")
	_note.add_theme_color_override("font_color", HotelTheme.WARN)
	_add_button("Try again", _again)
	_add_button("Go in anyway", _go_in)
	_add_button("Back", _back)


func _waiting_buttons() -> void:
	_clear_buttons()
	_note.text = "You can go in now: he answers with scripted lines until he's ready."
	_add_button("Go in now", _go_in)
	_add_button("Back", _back)


func _again() -> void:
	finished = false
	_note.remove_theme_color_override("font_color")
	setup = ModelSetup.start(get_tree())
	setup.changed.connect(_on_changed)
	setup.finished.connect(_on_finished)
	for step in ModelSetup.STEPS:
		_on_changed(step)
	_waiting_buttons()


func _add_button(text: String, on_pressed: Callable) -> void:
	_buttons.add_child(LGUi.button(text, on_pressed, WIDTH))
	if _buttons.get_child_count() == 1:
		LGUi.focus_first(_buttons)


func _clear_buttons() -> void:
	for c in _buttons.get_children():
		_buttons.remove_child(c)
		c.queue_free()


func _go_in() -> void:
	if _leaving:
		return
	_leaving = true
	ProofScene.play()


func _back() -> void:
	if _leaving:
		return
	_leaving = true
	LGScenes.change_scene(TITLE)


## "Qwen3-4B-Instruct-2507-GGUF" as "Qwen3 4B Instruct 2507".
static func _pretty(model: String) -> String:
	if model.to_lower().begins_with("kokoro"):
		return "Kokoro"
	return model.trim_suffix("-GGUF").replace("-", " ")
