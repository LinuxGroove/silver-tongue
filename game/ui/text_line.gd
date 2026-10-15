class_name TextLinePanel
extends Control
## A line you type instead of saying: a box at the bottom of the screen.
## Enter says it, Escape thinks better of it.

signal submitted(text: String)
signal cancelled

var _edit: LineEdit
var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_top = -120
	_panel.offset_bottom = -50
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size.x = 720
	add_child(_panel)
	var col := VBoxContainer.new()
	_panel.add_child(col)
	col.add_child(LGUi.label("Say", "DimLabel"))
	_edit = LineEdit.new()
	_edit.placeholder_text = "What you say to him"
	_edit.max_length = 240
	_edit.text_submitted.connect(_on_submitted)
	LGUi.gamepad_text_entry(_edit)
	col.add_child(_edit)


func is_open() -> bool:
	return visible


func ask() -> void:
	visible = true
	_edit.text = ""
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_edit.grab_focus.call_deferred()


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
