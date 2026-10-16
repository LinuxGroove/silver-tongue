class_name PhonePanel
extends Control
## Your phone on a job: the numbers Mae got you, what the caller ID shows
## when you ring them, and (alone) the calls Auntie Mae will make for you.
## On a call, it hangs up. What you say goes to whoever you rang while
## you're on, wherever they are.

signal dialed(number_id: String, as_who: String)
signal mae_asked(call_id: String)
signal hung_up
signal closed

const WIDTH := 460

var _col: VBoxContainer
var _buttons: Array[Button] = []
var _def: JobDef
var _as := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 8)
	panel.add_child(_col)


func is_open() -> bool:
	return visible


## Opens the phone for a job: `on_call` is who you're talking to ("" for
## nobody), `mae` the calls Mae can still make, offered only when `alone`.
func ask(def: JobDef, on_call := "", mae: Array = [], alone := true) -> void:
	_def = def
	_build(on_call, mae, alone)
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not _buttons.is_empty():
		_buttons[0].grab_focus.call_deferred()


func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _build(on_call: String, mae: Array, alone: bool) -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	_buttons.clear()
	_col.add_child(HotelTheme.hud_label("Phone", 22, HotelTheme.BRASS))
	if on_call != "":
		var s := _def.sheet(on_call)
		_label("On a call with %s. Talk as you would to anyone; they hear you, not the room." % (s.name if s else "someone"))
		_button("Hang up", _hang_up)
		_button("Back", _close)
		return
	if not _def.phone.is_empty():
		_label("Ring a number. The caller ID shows what you pick.")
		_button(_as_text(), _next_as)
		for n in _def.phone:
			_button("Ring %s" % str(n.get("name", n.get("id", ""))), _dial.bind(str(n.get("id", ""))))
	if alone and not mae.is_empty():
		_col.add_child(HSeparator.new())
		_col.add_child(HotelTheme.hud_label("Auntie Mae", 18, HotelTheme.BRASS))
		_label("She'll make one call for you, as someone else.")
		for m in mae:
			_button(str(m.get("label", m.get("id", ""))), _mae.bind(str(m.get("id", ""))))
	_button("Put it away", _close)


func _as_text() -> String:
	var ids: Array = _def.caller_ids if not _def.caller_ids.is_empty() else ["Withheld"]
	return "Caller ID: %s" % str(ids[_as % ids.size()])


func _label(text: String) -> void:
	var l := HotelTheme.hud_label(text, 15, HotelTheme.DIM, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = WIDTH
	_col.add_child(l)


func _button(text: String, call: Callable) -> Button:
	var b := LGUi.button(text, call, WIDTH)
	_col.add_child(b)
	_buttons.append(b)
	return b


## The buttons' texts (for tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _buttons:
		out.append(b.text)
	return out


## Presses the button with this text (for tests).
func press(text: String) -> void:
	for b in _buttons:
		if b.text == text:
			b.pressed.emit()
			return


func _next_as() -> void:
	_as += 1
	_buttons[0].text = _as_text()


func _dial(number_id: String) -> void:
	var ids: Array = _def.caller_ids if not _def.caller_ids.is_empty() else ["Withheld"]
	close()
	dialed.emit(number_id, str(ids[_as % ids.size()]))


func _mae(call_id: String) -> void:
	close()
	mae_asked.emit(call_id)


func _hang_up() -> void:
	close()
	hung_up.emit()


func _close() -> void:
	close()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("phone")):
		get_viewport().set_input_as_handled()
		_close()
