class_name TextLinePanel
extends Control
## A line you type instead of saying: a box at the bottom of the screen,
## with lines your cover might say above it to pick instead.
## Enter says it, Escape thinks better of it.

signal submitted(text: String)
signal cancelled

var _edit: LineEdit
var _panel: PanelContainer
var _ideas: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_top = -120
	_panel.offset_bottom = -50
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size.x = 720
	add_child(_panel)
	var col := VBoxContainer.new()
	_panel.add_child(col)
	_ideas = VBoxContainer.new()
	_ideas.add_theme_constant_override("separation", 4)
	col.add_child(_ideas)
	col.add_child(LGUi.label("Say", "DimLabel"))
	_edit = LineEdit.new()
	_edit.placeholder_text = "What you say"
	_edit.max_length = 240
	_edit.text_submitted.connect(_on_submitted)
	LGUi.gamepad_text_entry(_edit)
	col.add_child(_edit)


func is_open() -> bool:
	return visible


## Opens the box, with `ideas` (lines for your cover) to pick from.
func ask(ideas := PackedStringArray()) -> void:
	visible = true
	_edit.text = ""
	for c in _ideas.get_children():
		_ideas.remove_child(c)
		c.queue_free()
	if not ideas.is_empty():
		_ideas.add_child(LGUi.label("Your cover might say", "DimLabel"))
	for l in ideas:
		var b := Button.new()
		b.text = l
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.pressed.connect(_on_idea.bind(l))
		_ideas.add_child(b)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_edit.grab_focus.call_deferred()


## The lines on offer (for tests).
func idea_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _ideas.get_children():
		if c is Button:
			out.append(c.text)
	return out


## A suggested line is said as it is.
func _on_idea(line: String) -> void:
	close()
	submitted.emit(line)


func close() -> void:
	visible = false
	if _edit.has_focus():
		_edit.release_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_submitted(text: String) -> void:
	var t := text.strip_edges()
	close()
	if t != "":
		submitted.emit(t)
	else:
		cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		cancelled.emit()
