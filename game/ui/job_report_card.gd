class_name JobReportCard
extends Control
## The job report: how it went, who ended up held, how hot the venue got,
## the take, the three scores (Clean, Quiet, Silver), and the night's best
## and worst lines, each with the character's answer and a button that
## plays it again in their voice. It saves as a picture and copies as text,
## to share.

signal again
signal to_title
## Play a character's line again.
signal replay(char_id: String, text: String)

## For a report with no heading of its own.
const TITLES := {
	"held": ["ALL HELD", "The whole crew ended up in the security office."],
	"lost": ["THE HOST LEFT", "The night ended when the host's game did."],
}
const SCORES := [
	["clean", "Clean", "Nobody held, no Lockdown"],
	["quiet", "Quiet", "The venue never got past Curious"],
	["silver", "Silver", "Every door opened by talk"],
]

## Where saved pictures go.
const PICTURES := "user://reports"

var _col: VBoxContainer
var _buttons: Array[Button] = []
var _row: HBoxContainer
var _note: Label
var _report := {}


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
	_report = r
	var outcome := str(r.get("outcome", "late"))
	var t: Array = [r.title, r.get("text", "")] if r.has("title") else TITLES.get(outcome, [outcome.to_upper(), ""])
	var won := bool(r.get("win", outcome == "in"))
	if str(r.get("job_title", "")) != "":
		_col.add_child(HotelTheme.hud_label("%s, %s%s" % [r.job_title, str(r.get("venue_name", "")), night(r)], 16, HotelTheme.DIM))
	_col.add_child(HotelTheme.title_label(str(t[0]), 40, HotelTheme.BRASS if won else HotelTheme.WARN))
	_col.add_child(_text(str(t[1]) % str(r.get("clock", "")) if "%s" in str(t[1]) else str(t[1])))
	if won and int(r.get("take", 0)) > 0:
		_col.add_child(HotelTheme.hud_label("The take: %s" % money(int(r.take)), 20, HotelTheme.BRASS))
	elif won and str(r.get("unpaid", "")) != "":
		_col.add_child(HotelTheme.hud_label("No take: the rule was %s." % str(r.unpaid).to_lower(), 18, HotelTheme.WARN))
	# The finale's last word, and what happened next.
	if str(r.get("mae_says", "")) != "":
		_add_said("Mae", "mae", str(r.mae_says))
	if str(r.get("epilogue", "")) != "":
		_col.add_child(_text(str(r.epilogue), true))
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
	_note = _text("", true)
	_note.visible = false
	_col.add_child(_note)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 12)
	_col.add_child(_row)
	if not bool(r.get("lan", false)):
		_add_button("Again", _again, 120)
	_add_button("Back to Mae's", _title, 190)
	_add_button("Save a picture", save_picture, 170)
	_add_button("Copy the text", copy_text, 160)
	if CityOnline.enabled():
		_add_button("Share by code", share_by_code, 170)
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
		_add_said(str(l.get("name", "")), str(l.get("char", "")), str(l.reply))


## Someone's line, with a button to hear it again in their voice.
func _add_said(who: String, char_id: String, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var said := _text("%s: \"%s\"" % [who, text])
	said.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(said)
	var b := LGUi.button("Play", _replay.bind(char_id, text), 100)
	row.add_child(b)
	_buttons.append(b)
	_col.add_child(row)


func _add_button(text: String, call: Callable, w: int) -> void:
	var b := LGUi.button(text, call, w)
	_row.add_child(b)
	_buttons.append(b)


## The report as text, to paste anywhere.
static func as_text(r: Dictionary) -> String:
	var outcome := str(r.get("outcome", "late"))
	var t: Array = [r.title, r.get("text", "")] if r.has("title") else TITLES.get(outcome, [outcome.to_upper(), ""])
	var lines := PackedStringArray()
	lines.append("Silver Tongue: %s, %s%s" % [r.get("job_title", "a job"), r.get("venue_name", "Caldera"), night(r)])
	var line := str(t[1]) % str(r.get("clock", "")) if "%s" in str(t[1]) else str(t[1])
	var head := str(t[0]).to_lower()
	lines.append("%s. %s" % [head.left(1).to_upper() + head.substr(1), line])
	if bool(r.get("win", false)) and int(r.get("take", 0)) > 0:
		lines.append("The take: %s" % money(int(r.take)))
	elif bool(r.get("win", false)) and str(r.get("unpaid", "")) != "":
		lines.append("No take: the rule was %s." % str(r.unpaid).to_lower())
	if not r.get("rules", []).is_empty():
		lines.append("Rules: %s." % ". ".join(PackedStringArray(r.rules)))
	if str(r.get("mae_says", "")) != "":
		lines.append("Mae: \"%s\"" % str(r.mae_says))
	if str(r.get("epilogue", "")) != "":
		lines.append(str(r.epilogue))
	var scores := PackedStringArray()
	for sc in SCORES:
		scores.append("%s: %s" % [sc[1], "yes" if bool(r.get(sc[0], false)) else "no"])
	lines.append(", ".join(scores))
	for c in r.get("crew", []):
		lines.append("%s, as %s" % [c.get("name", ""), c.get("cover_name", "")])
	for k in [["best", "The best line"], ["worst", "The worst line"]]:
		var l: Dictionary = r.get(k[0], {})
		if l.is_empty():
			continue
		lines.append("")
		lines.append("%s%s:" % [k[1], (", at " + str(l.clock)) if str(l.get("clock", "")) != "" else ""])
		lines.append("You: \"%s\"" % Language.clean(str(l.get("said", ""))))
		if str(l.get("reply", "")) != "":
			lines.append("%s: \"%s\"" % [l.get("name", ""), Language.clean(str(l.reply))])
	return "\n".join(lines)


## Copies the report as text.
func copy_text() -> void:
	DisplayServer.clipboard_set(as_text(_report))
	_say("Copied. Paste it anywhere.")


## Puts the report on the game server and shows its code.
func share_by_code() -> void:
	_say("Sharing...")
	var code := await CityOnline.share_report(_report)
	if code == "":
		_say("Couldn't share it. Is online play on?")
		return
	DisplayServer.clipboard_set(code)
	_say("Shared. The code is %s (copied). Anyone can read it from Join a crew." % code)


## Saves the card as a picture in user://reports, the buttons left out.
## Returns where it went ("" when it couldn't).
func save_picture() -> String:
	_row.visible = false
	_note.visible = false
	# With no screen (headless) nothing is drawn and the frame never comes.
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	var tex := get_viewport().get_texture()
	var img := tex.get_image() if tex else null
	_row.visible = true
	if img == null or img.is_empty():
		_say("Couldn't take the picture.")
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PICTURES))
	var path := "%s/%s-%s.png" % [PICTURES, str(_report.get("job", "job")), Time.get_datetime_string_from_system(true).replace(":", "-")]
	if img.save_png(path) != OK:
		_say("Couldn't save the picture.")
		return ""
	_say("Saved to " + ProjectSettings.globalize_path(path))
	return path


func _say(text: String) -> void:
	_note.text = text
	_note.visible = true


## ", Circuit night 482913" for a Circuit night's report, else "".
static func night(r: Dictionary) -> String:
	var n := int(r.get("circuit", 0))
	return ", Circuit night %d" % n if n != 0 else ""


## Dollars as the crew would write them: "$12,500".
static func money(dollars: int) -> String:
	var digits := str(absi(dollars))
	var out := ""
	while digits.length() > 3:
		out = "," + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-$" if dollars < 0 else "$") + digits + out


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
