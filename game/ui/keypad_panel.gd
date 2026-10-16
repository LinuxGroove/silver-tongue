class_name KeypadPanel
extends Control
## The service door's keypad: four digits, typed or picked with the pad.
## Enter tries them, Escape steps back.

signal entered(code: String)
signal cancelled

const DIGITS := 4

var code := ""
var _panel: PanelContainer
var _display: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)
	col.add_child(LGUi.label("Kitchen door", "DimLabel"))
	_display = HotelTheme.title_label("_ _ _ _", 34, HotelTheme.BRASS)
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_display)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	col.add_child(grid)
	for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", "OK"]:
		var b := Button.new()
		b.text = k
		b.custom_minimum_size = Vector2(72, 56)
		b.pressed.connect(_on_key.bind(k))
		grid.add_child(b)
		_buttons.append(b)


func is_open() -> bool:
	return visible


func ask() -> void:
	code = ""
	_show()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_buttons[4].grab_focus.call_deferred()


func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


## A key, from a button or the keyboard.
func press(k: String) -> void:
	_on_key(k)


func _on_key(k: String) -> void:
	match k:
		"<":
			code = code.left(code.length() - 1)
		"OK":
			if code.length() == DIGITS:
				var c := code
				close()
				entered.emit(c)
				return
		_:
			if code.length() < DIGITS:
				code += k
				if code.length() == DIGITS:
					_buttons[11].grab_focus()
	_show()


func _show() -> void:
	var parts := PackedStringArray()
	for i in DIGITS:
		parts.append(code[i] if i < code.length() else "_")
	_display.text = " ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		cancelled.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.unicode >= 48 and k.unicode <= 57:
			_on_key(char(k.unicode))
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_BACKSPACE:
			_on_key("<")
			get_viewport().set_input_as_handled()
		elif k.keycode in [KEY_ENTER, KEY_KP_ENTER] and code.length() == DIGITS:
			_on_key("OK")
			get_viewport().set_input_as_handled()
