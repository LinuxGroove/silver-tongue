class_name JobReportCard
extends Control
## The job report: in or not, when, who ended up held, how hot the venue
## got, the three scores (Clean, Quiet, Silver), and the night's best and
## worst lines, each with the character's answer and a button that plays
## it again in their voice.

signal again
signal to_title
## Play a character's line again.
signal replay(char_id: String, text: String)

const TITLES := {
	"in": ["YOU'RE IN", "Inside the ballroom at %s."],
	"held": ["ALL HELD", "The whole crew ended up in the security office."],
	"late": ["TOO LATE", "The speech started with nobody inside."],
	"lost": ["THE HOST LEFT", "The night ended when the host's game did."],
}
const SCORES := [
	["clean", "Clean", "Nobody held, no Lockdown"],
	["quiet", "Quiet", "The venue never got past Curious"],
	["silver", "Silver", "Every door opened by talk"],
]

var _col: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 640
	center.add_child(panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	panel.add_child(_col)


## Shows the report (see [method Job.report]) for the crew member `me`.
func show_report(r: Dictionary, me := 1) -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	_buttons.clear()
	var outcome := str(r.get("outcome", "late"))
	var t: Array = TITLES.get(outcome, TITLES["late"])
	_col.add_child(HotelTheme.title_label(str(t[0]), 40, HotelTheme.BRASS if outcome == "in" else HotelTheme.WARN))
	_col.add_child(_text(str(t[1]) % str(r.get("clock", "")) if "%s" in str(t[1]) else str(t[1])))
	for c in r.get("crew", []):
		var bits := PackedStringArray()
		if bool(c.get("inside", false)):
			bits.append("inside")
		elif bool(c.get("held", false)):
			bits.append("held")
		else:
			bits.append("outside")
		if bool(c.get("was_held", false)) and not bool(c.get("held", false)):
			bits.append("held for a while")
		_col.add_child(_text("%s, as %s: %s" % [c.get("name", ""), c.get("cover_name", ""), ", ".join(bits)], true))
	if r.has("heat_peak_name"):
		_col.add_child(_text("The venue got as far as %s." % str(r.heat_peak_name), true))
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 24)
	_col.add_child(scores)
	for s in SCORES:
		var got := bool(r.get(s[0], false))
		var box := VBoxContainer.new()
		box.add_child(HotelTheme.hud_label(str(s[1]) + (": yes" if got else ": no"), 20, HotelTheme.BRASS if got else HotelTheme.DIM))
		var why := HotelTheme.hud_label(str(s[2]), 13, HotelTheme.DIM, false)
		box.add_child(why)
		scores.add_child(box)
	_add_line("The best line", r.get("best", {}))
	_add_line("The worst line", r.get("worst", {}))
	if r.has("file") and str(r.file) != "":
		var f := _text("Saved to " + str(r.file), true)
		f.add_theme_font_size_override("font_size", 13)
		_col.add_child(f)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_col.add_child(row)
	if not bool(r.get("lan", false)):
		var a := LGUi.button("Again", _again, 200)
		row.add_child(a)
		_buttons.append(a)
	var b := LGUi.button("Back to the title", _title, 260)
	row.add_child(b)
	_buttons.append(b)
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_buttons[0].grab_focus.call_deferred()


func _add_line(heading: String, l: Dictionary) -> void:
	if l.is_empty():
		return
	_col.add_child(HSeparator.new())
	_col.add_child(HotelTheme.hud_label(heading + (", at " + str(l.clock) if str(l.get("clock", "")) != "" else ""), 16, HotelTheme.BRASS))
	_col.add_child(_text("You: \"%s\"" % str(l.get("said", ""))))
	if str(l.get("reply", "")) != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var said := _text("%s: \"%s\"" % [l.get("name", ""), l.reply])
		said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(said)
		var b := LGUi.button("Play", _replay.bind(str(l.get("char", "")), str(l.reply)), 100)
		row.add_child(b)
		_buttons.append(b)
		_col.add_child(row)


func _text(s: String, dim := false) -> Label:
	var l := Label.new()
	l.text = s
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 600
	if dim:
		l.add_theme_color_override("font_color", HotelTheme.DIM)
	return l


## The buttons' texts (for tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _buttons:
		out.append(b.text)
	return out


func _replay(char_id: String, text: String) -> void:
	replay.emit(char_id, text)


func _again() -> void:
	again.emit()


func _title() -> void:
	to_title.emit()
