class_name ProofHud
extends Control
## The HUD at the service door: who's saying what (subtitles), your own
## words as they're heard, the guard's suspicion, the microphone, what
## Lemonade is doing, and the timing readout M0 is for.

const SUBTITLE_TIME := 7.0

var _brain: Label
var _voice: Label
var _schema: Label
var _name: Label
var _pips: Array[ColorRect] = []
var _speaker: Label
var _subtitle: Label
var _you: Label
var _you_panel: PanelContainer
var _mic: ProgressBar
var _hint: Label
var _timing: Label
var _toast: Label
var _sub_t := 0.0
var _toast_t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Top left: Lemonade.
	var state := HotelTheme.hud_panel()
	state.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	var col := VBoxContainer.new()
	state.add_child(col)
	_brain = HotelTheme.hud_label("Brain: starting", 15, HotelTheme.DIM)
	_voice = HotelTheme.hud_label("Voice: starting", 15, HotelTheme.DIM)
	_schema = HotelTheme.hud_label("", 15, HotelTheme.DIM)
	col.add_child(_brain)
	col.add_child(_voice)
	col.add_child(_schema)
	add_child(state)
	# Top right: the guard and his suspicion.
	var who := HotelTheme.hud_panel()
	who.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	who.add_child(row)
	_name = HotelTheme.hud_label("Marcus", 18)
	row.add_child(_name)
	for i in 5:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(14, 14)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.color = Color(1, 1, 1, 0.12)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
		_pips.append(pip)
	add_child(who)
	# Bottom centre: subtitles, and your own words above them.
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 160
	bottom.offset_right = -160
	bottom.offset_top = -190
	bottom.offset_bottom = -40
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
	_you = HotelTheme.hud_label("", 18, HotelTheme.DIM, false)
	_you.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_you.custom_minimum_size.x = 520
	you_row.add_child(_you)
	_you_panel.visible = false
	bottom.add_child(_you_panel)
	var sub := VBoxContainer.new()
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker = HotelTheme.hud_label("", 16, HotelTheme.BRASS)
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle = HotelTheme.hud_label("", 24, HotelTheme.TEXT, false)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_child(_speaker)
	sub.add_child(_subtitle)
	bottom.add_child(sub)
	# Bottom left: what to press.
	_hint = HotelTheme.hud_label("", 15, HotelTheme.DIM)
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(_hint)
	# Bottom right: the timings.
	_timing = HotelTheme.hud_label("", 15, HotelTheme.DIM)
	_timing.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_timing.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_timing)
	# Toasts, under the top panels.
	_toast = HotelTheme.hud_label("", 18, HotelTheme.BRASS)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 90
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.modulate.a = 0.0
	add_child(_toast)


func _process(delta: float) -> void:
	if _sub_t > 0.0:
		_sub_t -= delta
		if _sub_t <= 0.0:
			_speaker.text = ""
			_subtitle.text = ""
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
	if _you_panel.visible:
		_mic.value = LGVoice.mic_level


func set_brain(state: String, detail: String) -> void:
	var color := HotelTheme.GREEN if state == "ready" else (HotelTheme.BURGUNDY if state in ["error", "unavailable", "off"] else HotelTheme.DIM)
	_brain.text = "Brain: " + (detail if detail != "" else state)
	_brain.add_theme_color_override("font_color", color)


func set_voice(state: String, detail: String) -> void:
	var color := HotelTheme.GREEN if state == "ready" else (HotelTheme.BURGUNDY if state in ["error", "no_mic"] else HotelTheme.DIM)
	var text := detail if detail != "" else state
	if state == "ready" and detail == "":
		text = "ready"
	_voice.text = "Voice: " + text
	_voice.add_theme_color_override("font_color", color)


func set_schema(result: String) -> void:
	_schema.text = "Schema: " + result
	_schema.add_theme_color_override("font_color", HotelTheme.GREEN if result == "enforced" else HotelTheme.BURGUNDY)
	_schema.visible = result != ""


func set_guard_name(n: String) -> void:
	_name.text = n


func set_suspicion(n: int) -> void:
	for i in _pips.size():
		var on := i < n
		var c := HotelTheme.BRASS if n <= 2 else (Color(1.0, 0.5, 0.2) if n <= 3 else HotelTheme.BURGUNDY)
		_pips[i].color = c if on else Color(1, 1, 1, 0.12)


## Someone spoke.
func say(speaker: String, text: String) -> void:
	if not bool(LGSettings.get_value("play", "subtitles", true)):
		return
	_speaker.text = speaker
	_subtitle.text = text
	_sub_t = SUBTITLE_TIME + text.length() * 0.03


## Your own words, as they're heard: partial while you speak, then final.
func you(text: String, final: bool) -> void:
	_you_panel.visible = true
	_you.text = text if text != "" else ("..." if not final else "(nothing heard)")
	_you.add_theme_color_override("font_color", HotelTheme.TEXT if final else HotelTheme.DIM)
	if final:
		get_tree().create_timer(4.0).timeout.connect(_hide_you.bind(text))


func _hide_you(text: String) -> void:
	if _you.text == text or _you.text == "(nothing heard)":
		_you_panel.visible = false


func listening(on: bool) -> void:
	if on:
		_you_panel.visible = true
		_you.text = "..."
		_you.add_theme_color_override("font_color", HotelTheme.DIM)


func set_hint(text: String) -> void:
	_hint.text = text


## The timings of the last turn: heard (end of your words to the last
## word), thought (the round trip, with the tokens the cache reused) and
## spoke (the ask to the first sound).
func set_timing(turn: Dictionary) -> void:
	if not bool(LGSettings.get_value("voice", "timing", true)):
		_timing.text = ""
		return
	var parts := PackedStringArray()
	var hearing: Dictionary = turn.get("hearing", {})
	if hearing.has("final") and float(hearing.final) >= 0.0:
		var first := float(hearing.get("first_word", -1.0))
		parts.append("heard %.1f s" % float(hearing.final) + (" (first word %.1f)" % first if first >= 0.0 else ""))
	if str(turn.get("kind", "")) == "line" and str(turn.get("heard", "")) == "":
		parts.append("too far off to hear you" if float(turn.get("clarity", 0.0)) <= 0.0 else "he didn't catch that")
	elif bool(turn.get("scripted", false)):
		parts.append("scripted line" + (" (timed out after %.1f s)" % float(turn.get("thought", 0.0)) if bool(turn.get("timed_out", false)) else ""))
	elif turn.has("thought") and float(turn.thought) > 0.0:
		var t := "thought %.1f s" % float(turn.thought)
		if int(turn.get("cached_tokens", -1)) >= 0:
			t += " (%d of %d cached)" % [int(turn.cached_tokens), int(turn.get("prompt_tokens", 0))]
		elif int(turn.get("prompt_tokens", -1)) >= 0:
			t += " (%d tokens)" % int(turn.prompt_tokens)
		if not bool(turn.get("strict", true)):
			t += " loose"
		parts.append(t)
	if float(turn.get("spoke", -1.0)) >= 0.0:
		parts.append("spoke %.2f s" % float(turn.spoke))
	if str(turn.get("vetoed", "")) != "":
		parts.append("vetoed " + str(turn.vetoed))
	_timing.text = "  ·  ".join(parts)


func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 3.0
	_toast.modulate.a = 1.0
