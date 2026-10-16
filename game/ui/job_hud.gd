class_name JobHud
extends Control
## The HUD on a job: the clock and the venue's heat at the top, who you're
## dealing with and what they make of you on the right, your cover, what
## to do and who's on the phone on the left, subtitles (with the speaker,
## where they are, or the radio) at the bottom,
## your crewmates' lines and the earpiece down the left side, what you can
## use in front of you in the middle, and the timing readout M0 started.

const SUBTITLE_TIME := 7.0
const CREW_TIME := 9.0
const FACE_TIME := 20.0
const HEAT_COLORS := [Color(0.55, 0.85, 0.5), Color(0.9, 0.72, 0.36), Color(1.0, 0.55, 0.25), Color(1.0, 0.35, 0.35)]
## What a suspicion means, in a word or two.
const SUSPICION := ["relaxed", "at ease", "unsure", "doesn't buy it", "about to call it in", "calling it in"]

var _brain: Label
var _voice: Label
var _cover: Label
var _goal: Label
var _call: Label
var _clock: Label
var _heat: Label
var _who: PanelContainer
var _who_name: Label
var _who_word: Label
var _pips: Array[ColorRect] = []
var _hint_panel: PanelContainer
var _hint: Label
var _timing_panel: PanelContainer
var _timing: Label
var _sub_panel: PanelContainer
var _speaker: Label
var _subtitle: Label
var _you_panel: PanelContainer
var _you_tag: Label
var _you: Label
var _mic: ProgressBar
var _crew_col: VBoxContainer
var _prompt: Label
var _toast_panel: PanelContainer
var _toast: Label
var _held: PanelContainer
var _held_line: Label
var _fade: ColorRect
var _sub_t := 0.0
var _toast_t := 0.0
var _face_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Top left: you and Lemonade.
	var state := HotelTheme.hud_panel()
	state.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	var col := VBoxContainer.new()
	state.add_child(col)
	_cover = HotelTheme.hud_label("", 17, HotelTheme.TEXT)
	_brain = HotelTheme.hud_label("Brain: starting", 14, HotelTheme.DIM)
	_voice = HotelTheme.hud_label("Voice: starting", 14, HotelTheme.DIM)
	col.add_child(_cover)
	_goal = HotelTheme.hud_label("", 15, HotelTheme.BRASS, false)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.custom_minimum_size.x = 320
	_goal.visible = false
	col.add_child(_goal)
	_call = HotelTheme.hud_label("", 15, HotelTheme.GREEN)
	_call.visible = false
	col.add_child(_call)
	col.add_child(_brain)
	col.add_child(_voice)
	add_child(state)
	# Top centre: the clock and the heat.
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.offset_top = 14
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clock = HotelTheme.title_label("8:45 pm", 30, HotelTheme.TEXT)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat = HotelTheme.hud_label("Calm", 16, HEAT_COLORS[0])
	_heat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_clock)
	top.add_child(_heat)
	add_child(top)
	# Top right: who you're dealing with.
	_who = HotelTheme.hud_panel()
	_who.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_who.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_who.visible = false
	var wcol := VBoxContainer.new()
	_who.add_child(wcol)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	wcol.add_child(row)
	_who_name = HotelTheme.hud_label("", 18)
	row.add_child(_who_name)
	for i in 5:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.color = Color(1, 1, 1, 0.12)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
		_pips.append(pip)
	_who_word = HotelTheme.hud_label("", 14, HotelTheme.DIM)
	_who_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wcol.add_child(_who_word)
	add_child(_who)
	# Left side: the crew's lines.
	_crew_col = VBoxContainer.new()
	_crew_col.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_crew_col.offset_left = 16
	_crew_col.offset_top = -120
	_crew_col.offset_bottom = 120
	_crew_col.custom_minimum_size.x = 360
	_crew_col.alignment = BoxContainer.ALIGNMENT_END
	_crew_col.add_theme_constant_override("separation", 6)
	_crew_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crew_col)
	# The middle: a dot to aim with, and what you can use.
	var dot := ColorRect.new()
	dot.color = Color(1, 1, 1, 0.55)
	dot.size = Vector2(4, 4)
	dot.set_anchors_preset(Control.PRESET_CENTER)
	dot.position = Vector2(-2, -2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dot)
	_prompt = HotelTheme.hud_label("", 18, HotelTheme.BRASS)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.offset_top = 24
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_prompt)
	# Bottom centre: subtitles, and your own words above them.
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 160
	bottom.offset_right = -160
	bottom.offset_top = -280
	bottom.offset_bottom = -84
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	_you_panel = HotelTheme.hud_panel(Color(HotelTheme.BRASS, 0.3))
	_you_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var you_row := HBoxContainer.new()
	you_row.add_theme_constant_override("separation", 12)
	_you_panel.add_child(you_row)
	_mic = HotelTheme.bar(HotelTheme.BRASS, 60, 8)
	you_row.add_child(_mic)
	_you_tag = HotelTheme.hud_label("", 15, HotelTheme.BRASS)
	you_row.add_child(_you_tag)
	_you = HotelTheme.hud_label("", 18, HotelTheme.DIM, false)
	_you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_you.custom_minimum_size.x = 480
	you_row.add_child(_you)
	_you_panel.visible = false
	bottom.add_child(_you_panel)
	_sub_panel = HotelTheme.hud_panel(Color(0, 0, 0, 0))
	_sub_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_sub_panel.visible = false
	var sub := VBoxContainer.new()
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker = HotelTheme.hud_label("", 16, HotelTheme.BRASS)
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle = HotelTheme.hud_label("", 24, HotelTheme.TEXT, false)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.custom_minimum_size.x = 640
	sub.add_child(_speaker)
	sub.add_child(_subtitle)
	_sub_panel.add_child(sub)
	bottom.add_child(_sub_panel)
	# Bottom left: what to press. Bottom right: the timings.
	_hint_panel = HotelTheme.hud_panel()
	_hint_panel.name = "Hint"
	_hint_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	_hint_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint = HotelTheme.hud_label("", 15, HotelTheme.TEXT)
	_hint_panel.add_child(_hint)
	add_child(_hint_panel)
	_timing_panel = HotelTheme.hud_panel()
	_timing_panel.name = "Readout"
	_timing_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_timing_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_timing_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_timing_panel.visible = false
	_timing = HotelTheme.hud_label("", 15, HotelTheme.TEXT)
	_timing.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timing_panel.add_child(_timing)
	add_child(_timing_panel)
	# Toasts, under the clock.
	_toast_panel = HotelTheme.hud_panel()
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.offset_top = 92
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.modulate.a = 0.0
	_toast = HotelTheme.hud_label("", 18, HotelTheme.BRASS)
	_toast_panel.add_child(_toast)
	add_child(_toast_panel)
	# Held: a banner across the top third.
	_held = HotelTheme.hud_panel(HotelTheme.BURGUNDY)
	_held.set_anchors_preset(Control.PRESET_CENTER)
	_held.offset_top = -170
	_held.offset_bottom = -170
	_held.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_held.grow_vertical = Control.GROW_DIRECTION_END
	_held.visible = false
	var hcol := VBoxContainer.new()
	_held.add_child(hcol)
	var ht := HotelTheme.title_label("HELD", 28, HotelTheme.WARN)
	ht.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hcol.add_child(ht)
	_held_line = HotelTheme.hud_label("In the security office. Talk the guard into letting you out through the door.", 16, HotelTheme.TEXT, false)
	_held_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hcol.add_child(_held_line)
	add_child(_held)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _process(delta: float) -> void:
	if _sub_t > 0.0:
		_sub_t -= delta
		if _sub_t <= 0.0:
			_sub_panel.visible = false
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast_panel.modulate.a = clampf(_toast_t, 0.0, 1.0)
	if _face_t > 0.0:
		_face_t -= delta
		if _face_t <= 0.0:
			_who.visible = false
	if _you_panel.visible:
		_mic.value = LGVoice.mic_level
	for c in _crew_col.get_children():
		var t := float(c.get_meta("t", 0.0)) - delta
		c.set_meta("t", t)
		c.modulate.a = clampf(t, 0.0, 1.0)
		if t <= 0.0:
			c.queue_free()
	if _fade.color.a > 0.0:
		_fade.color.a = maxf(0.0, _fade.color.a - delta * 1.2)


func set_brain(state: String, detail: String) -> void:
	var color := HotelTheme.GREEN if state == "ready" else (HotelTheme.WARN if state in ["error", "unavailable", "off"] else HotelTheme.DIM)
	_brain.text = "Brain: " + (detail if detail != "" else state)
	_brain.add_theme_color_override("font_color", color)


func set_voice(state: String, detail: String) -> void:
	var color := HotelTheme.GREEN if state == "ready" else (HotelTheme.WARN if state in ["error", "no_mic"] else HotelTheme.DIM)
	_voice.text = "Voice: " + (detail if detail != "" else ("ready" if state == "ready" else state))
	_voice.add_theme_color_override("font_color", color)


## Your cover, and what you're carrying.
func set_cover(c: CrewInfo) -> void:
	var cover := Covers.of(c.cover)
	var t := "%s, %s" % [c.cover_name, str(cover.get("title", c.cover)).to_lower()]
	if c.outfit != str(cover.get("outfit", c.outfit)):
		t += " · in " + Covers.wearing(c.outfit, c.female)
	for it in c.items:
		var info: Dictionary = Jobs.current.items.get(it, {}) if Jobs.current else {}
		t += " · " + str(info.get("name", it))
	_cover.text = t


## What to do now.
func set_goal(text: String) -> void:
	_goal.text = text
	_goal.visible = text != ""


## Who you're on the phone with ("" when you're not).
func set_call(number_name: String) -> void:
	_call.text = "On the phone: " + number_name if number_name != "" else ""
	_call.visible = number_name != ""


func goal_text() -> String:
	return _goal.text


func set_clock(text: String) -> void:
	_clock.text = text


func set_heat(level: int) -> void:
	_heat.text = Heat.name_of(level)
	_heat.add_theme_color_override("font_color", HEAT_COLORS[clampi(level, 0, 3)])


## What a character makes of you: their name, five pips and a word.
func set_face(who: String, suspicion: int) -> void:
	_who.visible = true
	_face_t = FACE_TIME
	_who_name.text = who
	_who_word.text = SUSPICION[clampi(suspicion, 0, SUSPICION.size() - 1)]
	for i in _pips.size():
		var c := HotelTheme.BRASS if suspicion <= 2 else (Color(1.0, 0.5, 0.2) if suspicion <= 3 else HotelTheme.WARN)
		_pips[i].color = c if i < suspicion else Color(1, 1, 1, 0.12)


## A character spoke where you could hear: who, and which way they are
## ("left", "right", "behind", or "" ahead) when the setting shows it.
func say(speaker: String, text: String, where := "") -> void:
	if not bool(LGSettings.get_value("play", "subtitles", true)):
		return
	if where != "" and bool(LGSettings.get_value("play", "subtitle_where", true)):
		speaker += {"left": ", to your left", "right": ", to your right", "behind": ", behind you"}.get(where, "")
	text = Language.clean(text)
	_speaker.text = speaker
	_subtitle.text = text
	_sub_panel.visible = text != ""
	_sub_t = SUBTITLE_TIME + text.length() * 0.03


## A crewmate's line (on the earpiece, or near enough to hear).
func crew(who: String, text: String, earpiece: bool) -> void:
	var l := HotelTheme.hud_label("%s%s: %s" % [who, " (earpiece)" if earpiece else "", Language.clean(text)], 16, HotelTheme.BRASS if earpiece else HotelTheme.TEXT, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 360
	l.set_meta("t", CREW_TIME)
	_crew_col.add_child(l)
	while _crew_col.get_child_count() > 4:
		var old := _crew_col.get_child(0)
		_crew_col.remove_child(old)
		old.queue_free()


## Your own words, as they're heard.
func you(text: String, final: bool) -> void:
	_you_panel.visible = true
	_you.text = Language.clean(text) if text != "" else ("..." if not final else "(nothing heard)")
	_you.add_theme_color_override("font_color", HotelTheme.TEXT if final else HotelTheme.DIM)
	if final:
		get_tree().create_timer(4.0).timeout.connect(_hide_you.bind(_you.text))


func _hide_you(text: String) -> void:
	if _you.text == text:
		_you_panel.visible = false


func listening(on: bool, earpiece := false) -> void:
	_you_tag.text = "Earpiece" if earpiece else ""
	_you_tag.visible = earpiece
	if on:
		_you_panel.visible = true
		_you.text = "..."
		_you.add_theme_color_override("font_color", HotelTheme.DIM)


func set_hint(text: String) -> void:
	_hint.text = text
	_hint_panel.visible = text != ""


func set_prompt(text: String) -> void:
	_prompt.text = text


func prompt_text() -> String:
	return _prompt.text


## The timings of your last line to a character (see [ProofHud]).
func set_timing(turn: Dictionary) -> void:
	if not bool(LGSettings.get_value("voice", "timing", true)):
		_timing_panel.visible = false
		return
	var parts := PackedStringArray()
	var hearing: Dictionary = turn.get("hearing", {})
	if hearing.has("final") and float(hearing.final) >= 0.0:
		parts.append("heard %.1f s" % float(hearing.final))
	if bool(turn.get("scripted", false)):
		parts.append("scripted line" + (" (timed out)" if bool(turn.get("timed_out", false)) else ""))
	elif float(turn.get("thought", 0.0)) > 0.0:
		var t := "thought %.1f s" % float(turn.thought)
		if int(turn.get("cached_tokens", -1)) >= 0:
			t += " (%d of %d cached)" % [int(turn.cached_tokens), int(turn.get("prompt_tokens", 0))]
		parts.append(t)
	if str(turn.get("vetoed", "")) != "":
		parts.append("vetoed " + str(turn.vetoed))
	_timing.text = "  ·  ".join(parts)
	_timing_panel.visible = _timing.text != ""


func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 3.5
	_toast_panel.modulate.a = 1.0


func set_held(on: bool, where := "the security office") -> void:
	_held_line.text = "In %s. Talk the guard into letting you out through the door." % where
	_held.visible = on


func speaker_text() -> String:
	return _speaker.text


func is_held() -> bool:
	return _held.visible


## A quick fade to black and back (being taken to the office).
func fade() -> void:
	_fade.color.a = 1.0


## The panels against the screen's edges (for tests).
func edge_controls() -> Array[Control]:
	return [_who, _hint_panel, _timing_panel]
