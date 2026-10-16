class_name PlaySettings
extends VBoxContainer
## Silver Tongue's own settings, for the pause menu and the title's
## settings: looking and crouching, the comfort settings, and the voice
## (how you talk, how the guard hears and speaks). Each change is saved at
## once. The add-on's [SettingsPanel] adds the AI model rows under these.

const LOOK := [[0.15, "Slow"], [0.25, "Normal"], [0.35, "Quick"], [0.5, "Fast"]]
const BOB := [[0.0, "Off"], [0.5, "Gentle"], [1.0, "Full"]]
const FOV := [[65.0, "Narrow"], [75.0, "Normal"], [90.0, "Wide"]]
const TALK := [["push", "Hold to talk"], ["open", "Open mic"], ["text", "Type"]]
const HEARING := [["Whisper-Tiny", "Tiny (handheld)"], ["Whisper-Base", "Base"], ["Whisper-Small", "Small (desktop)"]]
const VIEW := [["first", "Through your eyes"], ["third", "Over your shoulder"]]

signal changed

var width := 480


static func make(p_width := 480) -> PlaySettings:
	var p := PlaySettings.new()
	p.width = p_width
	p.add_theme_constant_override("separation", 8)
	p.rebuild()
	return p


func rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_head("Talking")
	add_child(LGCycler.make("How you talk", TALK, LGSettings.get_value("voice", "talk"), _on_set.bind("voice", "talk"), width))
	add_child(LGCycler.make("Hearing model", HEARING, LGSettings.get_value("voice", "hearing_model"), _on_set.bind("voice", "hearing_model"), width))
	add_child(LGCycler.make("They speak out loud", SettingsPanel.ON_OFF, LGSettings.get_value("voice", "speaking"), _on_set.bind("voice", "speaking"), width))
	add_child(LGCycler.make("Timing readout", SettingsPanel.ON_OFF, LGSettings.get_value("voice", "timing"), _on_set.bind("voice", "timing"), width))
	add_child(LGCycler.make("Mind your language", SettingsPanel.ON_OFF, LGSettings.get_value("voice", "mind_language"), _on_set.bind("voice", "mind_language"), width))
	add_child(LGCycler.make("Subtitles", SettingsPanel.ON_OFF, LGSettings.get_value("play", "subtitles"), _on_set.bind("play", "subtitles"), width))
	add_child(LGCycler.make("Subtitles say where", SettingsPanel.ON_OFF, LGSettings.get_value("play", "subtitle_where"), _on_set.bind("play", "subtitle_where"), width))
	_head("Looking")
	add_child(LGCycler.make("Look speed", LOOK, _nearest(LOOK, LGSettings.get_value("play", "mouse_sensitivity")), _on_set.bind("play", "mouse_sensitivity"), width))
	add_child(LGCycler.make("Invert look", SettingsPanel.ON_OFF, LGSettings.get_value("play", "invert_look"), _on_set.bind("play", "invert_look"), width))
	add_child(LGCycler.make("Hold to crouch", [[false, "On"], [true, "Off"]], LGSettings.get_value("play", "toggle_crouch"), _on_set.bind("play", "toggle_crouch"), width))
	_head("Comfort")
	add_child(LGCycler.make("View", VIEW, LGSettings.get_value("play", "view"), _on_set.bind("play", "view"), width))
	add_child(LGCycler.make("Head bob", BOB, LGSettings.get_value("play", "bob"), _on_set.bind("play", "bob"), width))
	add_child(LGCycler.make("View roll", SettingsPanel.ON_OFF, LGSettings.get_value("play", "tilt"), _on_set.bind("play", "tilt"), width))
	add_child(LGCycler.make("Field of view", FOV, LGSettings.get_value("play", "fov"), _on_set.bind("play", "fov"), width))
	_head("The season")
	add_child(LGCycler.make("Open every job", SettingsPanel.ON_OFF, LGSettings.get_value("play", "all_jobs"), _on_set.bind("play", "all_jobs"), width))


func _head(text: String) -> void:
	var l := LGUi.label(text.to_upper(), "DimLabel")
	l.add_theme_color_override("font_color", HotelTheme.BRASS)
	add_child(l)


## The option nearest a stored value, so odd values still show.
static func _nearest(options: Array, v: Variant) -> Variant:
	var best: Variant = options[0][0]
	var d := INF
	for o in options:
		var dd := absf(float(o[0]) - float(v))
		if dd < d:
			d = dd
			best = o[0]
	return best


func _on_set(value: Variant, section: String, key: String) -> void:
	LGSettings.set_value(section, key, value)
	var job := JobScene.current
	if job and is_instance_valid(job) and job.player and section == "play":
		job.player._reload_options()
	var scene := ProofScene.current
	if scene and is_instance_valid(scene):
		if section == "play" and scene.player:
			scene.player._reload_options()
		if section == "voice":
			if key == "talk" and LGVoice.is_ready():
				LGVoice.set_open_mic(str(value) == "open")
			if key == "speaking" and scene.guard:
				scene.guard.speak = bool(value) and LGVoice.is_ready()
			if scene.hud:
				scene.hud.set_hint(scene._hint())
	changed.emit()
