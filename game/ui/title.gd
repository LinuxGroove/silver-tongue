extends Node
## The title screen, over the service door: the door itself (M0's proof),
## how to play, settings, about and quit.

const WIDTH := 540
const NAME := "SILVER\nTONGUE"
const SHADE_RIGHT := HotelTheme.SHADE_RIGHT

var backdrop: MenuBackdrop
var _ui: Control
var _col: VBoxContainer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	backdrop = MenuBackdrop.make()
	add_child(backdrop)
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	var shade := TextureRect.new()
	shade.texture = HotelTheme.shade_texture()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.anchor_right = SHADE_RIGHT
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)
	var version := LGUi.label("v%s" % GameConfig.version(), "DimLabel")
	_ui.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_col = LGUi.centered_column(_ui, WIDTH)
	_col.get_parent().anchor_right = SHADE_RIGHT
	LGScreenFit.center(_col)
	show_main()


func _clear() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()


func _heading(text: String) -> void:
	_col.add_child(HotelTheme.hud_label(text, 32, HotelTheme.TEXT))


func _text(text: String, dim := false) -> Label:
	var l := LGUi.label(text, "DimLabel" if dim else "")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH, 0)
	_col.add_child(l)
	return l


func _back(to: Callable) -> void:
	_col.add_child(LGUi.button("Back", to, WIDTH))


## The labels of the buttons showing now (for tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for b in _col.find_children("", "Button", true, false):
		if not b.is_queued_for_deletion() and b.is_visible_in_tree():
			out.append(b.text)
	return out


func show_main() -> void:
	_clear()
	_col.add_child(HotelTheme.title_label(NAME, 72, HotelTheme.BRASS))
	_text("Say the right thing. Not too loud.", true)
	_col.add_child(Control.new())
	_col.add_child(LGUi.button("The service door", _play, WIDTH))
	_col.add_child(LGUi.button("How to play", show_how.bind(0), WIDTH))
	_col.add_child(LGUi.button("Settings", show_settings, WIDTH))
	_col.add_child(LGUi.button("About", show_about, WIDTH))
	var quit := LGUi.button("Quit", _quit, WIDTH)
	quit.theme_type_variation = "DangerButton"
	_col.add_child(quit)
	LGUi.focus_first(_col)


func _play() -> void:
	SetupScreen.play_door()


func show_how(page: int) -> void:
	_clear()
	var pages := HowToPlay.PAGES
	page = clampi(page, 0, pages.size() - 1)
	_heading(pages[page][0])
	for p in pages[page][1]:
		_text(HowToPlay.fill(p))
	_text("%d of %d" % [page + 1, pages.size()], true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_col.add_child(row)
	if page > 0:
		row.add_child(LGUi.button("Before", show_how.bind(page - 1), 264))
	if page < pages.size() - 1:
		row.add_child(LGUi.button("Next", show_how.bind(page + 1), 264))
	_back(show_main)
	LGUi.focus_first(_col)


func show_settings() -> void:
	_clear()
	_heading("Settings")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH + 20, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_col.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	scroll.add_child(inner)
	var name_row := HBoxContainer.new()
	var name_label := LGUi.label("Your name")
	name_label.custom_minimum_size.x = 240
	name_row.add_child(name_label)
	var name_edit := LineEdit.new()
	name_edit.text = GameConfig.player_name()
	name_edit.max_length = 20
	name_edit.custom_minimum_size.x = WIDTH - 250
	name_edit.text_changed.connect(_on_name_changed)
	LGUi.gamepad_text_entry(name_edit)
	name_row.add_child(name_edit)
	inner.add_child(name_row)
	inner.add_child(PlaySettings.make(WIDTH))
	inner.add_child(SettingsPanel.new())
	_back(show_main)
	LGUi.focus_first(_col)


func _on_name_changed(text: String) -> void:
	LGSettings.set_value("player", "name", text.strip_edges())


func show_about() -> void:
	_clear()
	_heading("About Silver Tongue")
	_text("A co-op con game where the guards, staff and guests hear what you say and answer in their own words. This is the first proof: one room, one guard, one door.")
	_text("Created by", true)
	_text("Drew VanDine\nKaden VanDine\nKen VanDine")
	_text("A LinuxGroove game, made with Godot and COGITO, Quaternius' characters and city kit, and Lemonade for the hearing, the brains and the voice.", true)
	_text("Version %s" % GameConfig.version(), true)
	_back(show_main)
	LGUi.focus_first(_col)


func _quit() -> void:
	LGScenes.quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _col.get_child_count() > 0:
		var title := _col.get_child(0) as Label
		if title and title.text != NAME:
			get_viewport().set_input_as_handled()
			show_main()
