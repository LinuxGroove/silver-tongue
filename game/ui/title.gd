extends Node
## The title screen, over the service door: the gala (Auntie Mae's
## briefing, your cover, and a crew on the local network), the door itself
## (M0's proof), how to play, settings, about and quit.

const WIDTH := 540
const NAME := "SILVER\nTONGUE"
const SHADE_RIGHT := HotelTheme.SHADE_RIGHT

var backdrop: MenuBackdrop
var _ui: Control
var _col: VBoxContainer
var _page := ""
var _cover := "guest"
var _female := false
var _status: Label
var _hosts: VBoxContainer
var _code: LineEdit
var _lobby_queued := false
var _refocus := ""


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
	Session.roster_changed.connect(_on_roster_changed)
	Session.joined.connect(_on_joined)
	Session.left.connect(_on_left)
	Session.status.connect(_on_status)
	Session.hosts_found.connect(_on_hosts_found)
	var me := Session.me()
	_cover = str(me.get("cover", "guest"))
	_female = bool(me.get("female", false))
	if Session.is_lan():
		show_lobby()
	else:
		show_main()


func _clear(page := "") -> void:
	_page = page
	_status = null
	_hosts = null
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
	_col.add_child(LGUi.button("The gala", show_gala, WIDTH))
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


#region The gala

## Auntie Mae's briefing for the crew's job, your cover, and how you're
## playing.
func show_gala() -> void:
	Session.ensure_job()
	var def := Jobs.current
	if not Covers.has(_cover):
		_cover = Covers.first()
	_clear("gala")
	_heading(def.title)
	_text("Auntie Mae: \"%s\"" % def.briefing)
	_col.add_child(HotelTheme.hud_label("Your cover", 20, HotelTheme.BRASS))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_col.add_child(grid)
	for id in Covers.order():
		var b := LGUi.button(str(Covers.of(id).title), _pick_cover.bind(id), (WIDTH - 8) / 2)
		if id == _cover:
			b.add_theme_color_override("font_color", HotelTheme.BRASS)
			b.add_theme_color_override("font_focus_color", HotelTheme.BRASS)
			b.text = "> %s <" % b.text
		grid.add_child(b)
	var c: Dictionary = Covers.of(_cover)
	_text("%s, %s. %s Made for %s." % [Covers.cover_name(_cover, _female), c.job, c.story, c["for"]], true)
	_col.add_child(LGUi.button("You look like: %s" % ("a woman" if _female else "a man"), _toggle_body, WIDTH))
	_col.add_child(Control.new())
	_col.add_child(LGUi.button("Play alone", _play_alone, WIDTH))
	_col.add_child(LGUi.button("Host a crew on this network", _host, WIDTH))
	_col.add_child(LGUi.button("Join a crew", show_join, WIDTH))
	_back(show_main)
	LGUi.focus_first(_col)


func _pick_cover(id: String) -> void:
	_cover = id
	Session.set_cover(_cover, _female)
	if _page == "lobby":
		_queue_lobby("> %s <" % Covers.of(id).title)
		return
	show_gala()
	_focus_text("> %s <" % Covers.of(id).title)


func _toggle_body() -> void:
	_female = not _female
	Session.set_cover(_cover, _female)
	if _page == "lobby":
		_queue_lobby("You look like: %s" % ("a woman" if _female else "a man"))
		return
	show_gala()
	_focus_text("You look like: %s" % ("a woman" if _female else "a man"))


func _focus_text(text: String) -> void:
	for b in _col.find_children("", "Button", true, false):
		if b.text == text:
			b.grab_focus.call_deferred()


func _play_alone() -> void:
	Session.start_solo(_cover, _female)
	Session.start_job()


func _host() -> void:
	Session.host_lan(_cover, _female)


## Crews hosting on this network, and a code to type.
func show_join() -> void:
	_clear("join")
	_heading("Join a crew")
	_text("Crews hosting on this network show up here. Or type the code the host sees.", true)
	_hosts = VBoxContainer.new()
	_hosts.add_theme_constant_override("separation", 8)
	_col.add_child(_hosts)
	_on_hosts_found([])
	_code = LineEdit.new()
	_code.placeholder_text = "The host's code"
	_code.max_length = 16
	_code.custom_minimum_size.x = WIDTH
	_code.text_submitted.connect(_join_code)
	LGUi.gamepad_text_entry(_code)
	_col.add_child(_code)
	_col.add_child(LGUi.button("Join with the code", _join_code_pressed, WIDTH))
	_status = _text("", true)
	_back(_leave_join)
	Session.browse_lan()
	LGUi.focus_first(_col)


func _on_hosts_found(hosts: Array) -> void:
	if _hosts == null:
		return
	for c in _hosts.get_children():
		_hosts.remove_child(c)
		c.queue_free()
	if hosts.is_empty():
		var l := LGUi.label("Looking...", "DimLabel")
		_hosts.add_child(l)
		return
	for h in hosts:
		var full := int(h.get("players", 0)) >= int(h.get("max", GameConfig.MAX_CREW)) or str(h.get("state", "")) != "lobby"
		var b := LGUi.button("%s (%d of %d)" % [h.get("name", "A crew"), int(h.get("players", 0)), int(h.get("max", GameConfig.MAX_CREW))], _join_host.bind(str(h.get("ip", "")), int(h.get("port", 0))), WIDTH)
		b.disabled = full or int(h.get("protocol", 0)) != GameConfig.PROTOCOL
		_hosts.add_child(b)


func _join_host(ip: String, port: int) -> void:
	Session.join_lan(ip, port)


func _join_code(text: String) -> void:
	if text.strip_edges() != "":
		Session.join_lan_code(text)


func _join_code_pressed() -> void:
	_join_code(_code.text)


func _leave_join() -> void:
	Session.leave()
	Session.stop_browsing()
	show_gala()


## The crew before the job: who's in, in what cover, and the code.
func show_lobby() -> void:
	_clear("lobby")
	_heading("Your crew")
	if Session.join_code != "":
		_text("Code: %s" % JoinCode.pretty(Session.join_code))
		_text("On another computer on this network: The gala, Join a crew, then pick this crew or type the code.", true)
	var ids := Session.crew.keys()
	ids.sort()
	for id in ids:
		var c: Dictionary = Session.crew[id]
		var you := " (you)" if int(id) == Session.local_id() else ""
		_text("%s%s: %s, %s" % [c.name, you, Covers.cover_name(str(c.cover), bool(c.female)), str(Covers.of(str(c.cover)).title).to_lower()])
	var row := GridContainer.new()
	row.columns = 2
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	_col.add_child(row)
	for id in Covers.order():
		var b := LGUi.button(str(Covers.of(id).title), _pick_cover.bind(id), (WIDTH - 8) / 2)
		if id == _cover:
			b.text = "> %s <" % b.text
			b.add_theme_color_override("font_color", HotelTheme.BRASS)
		row.add_child(b)
	_col.add_child(LGUi.button("You look like: %s" % ("a woman" if _female else "a man"), _toggle_body, WIDTH))
	if Session.is_host():
		_col.add_child(LGUi.button("Start the job", _start, WIDTH))
	else:
		_text("Waiting for the host to start the job.", true)
	_status = _text("", true)
	_col.add_child(LGUi.button("Leave the crew", _leave_lobby, WIDTH))
	LGUi.focus_first(_col)


func _start() -> void:
	Session.start_job()


func _leave_lobby() -> void:
	Session.leave()
	if _page == "lobby":
		show_gala()


func _on_roster_changed() -> void:
	if _page == "lobby":
		_queue_lobby()


## Rebuilds the lobby once at the end of the frame, however many changes
## came in it (a rebuild frees the buttons a deferred focus would grab),
## keeping focus on `focus` when given.
func _queue_lobby(focus := "") -> void:
	if focus != "":
		_refocus = focus
	if _lobby_queued:
		return
	_lobby_queued = true
	_rebuild_lobby.call_deferred()


func _rebuild_lobby() -> void:
	_lobby_queued = false
	if _page != "lobby":
		return
	show_lobby()
	if _refocus != "":
		_focus_text(_refocus)
		_refocus = ""


func _on_joined() -> void:
	if _page != "lobby":
		Session.stop_browsing()
		show_lobby()


func _on_left(reason: String) -> void:
	if _page in ["lobby", "join"]:
		show_gala()
		if reason != "":
			_status = _text(reason, true)


func _on_status(text: String) -> void:
	if _status:
		_status.text = text

#endregion


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
	_text("A co-op con game where the guards, staff and guests hear what you say and answer in their own words. This is the first job: get into the Meridian's gala. The service door is M0's proof, kept for measuring.")
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
			if _page in ["join", "lobby"]:
				Session.leave()
				Session.stop_browsing()
				show_gala()
			else:
				show_main()
