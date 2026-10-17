extends Node
## The title screen, over the service door: Mae's back room (the season's
## jobs, her briefings, the take and a new face), the Circuit (remixed
## nights and the weekly contract), each job's briefing with your cover and
## a crew on the local network, joining a crew, the door itself (M0's
## proof), how to play, settings, about and quit.

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
var _night: LineEdit
var _lobby_queued := false
var _refocus := ""
var _forget_asked := false
## Mae, reading her briefing out.
var _mae: AudioStreamPlayer


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
	_mae = AudioStreamPlayer.new()
	_mae.bus = "Master"
	add_child(_mae)
	var me := Session.me()
	_cover = str(me.get("cover", "guest"))
	_female = bool(me.get("female", false))
	var back := Session.back_to
	Session.back_to = ""
	if Session.is_lan():
		show_lobby()
	elif back == "board":
		show_board()
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
	_col.add_child(LGUi.button("Mae's back room", show_board, WIDTH))
	var circuit := LGUi.button("The Circuit", show_circuit, WIDTH)
	circuit.disabled = not Progress.circuit_open()
	circuit.tooltip_text = "" if Progress.circuit_open() else "Opens after Mae's party"
	_col.add_child(circuit)
	_col.add_child(LGUi.button("Join a crew", show_join, WIDTH))
	var boards := LGUi.button("Leaderboards", show_boards.bind(0), WIDTH)
	boards.disabled = not CityOnline.enabled()
	boards.tooltip_text = "" if CityOnline.enabled() else "Online play is off in Settings"
	_col.add_child(boards)
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


#region Mae's back room

## The season: every job built so far, venue by venue, open in order, with
## how each one came off; the take; and a new face when Halberd has yours.
func show_board() -> void:
	LGVoice.hush(_mae)
	_clear("board")
	_heading("Mae's back room")
	_text("The season's take: %s" % JobReportCard.money(Progress.take))
	if Progress.burned:
		_text("Halberd has your face on file: their people know it at every venue.", true)
		var face := LGUi.button("Buy a new face (%s)" % JobReportCard.money(Progress.NEW_FACE), _buy_face, WIDTH)
		face.disabled = Progress.take < Progress.NEW_FACE
		_col.add_child(face)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH + 20, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var titles := {}
	for id in Jobs.CAMPAIGN:
		if Jobs.exists(id):
			titles[id] = Jobs.make(id).title
	var before := ""
	for v in Jobs.VENUES:
		var jobs: Array = Jobs.at_venue(v).filter(func(j): return Jobs.exists(j))
		if jobs.is_empty():
			continue
		list.add_child(HotelTheme.hud_label(str(Jobs.VENUES[v]), 18, HotelTheme.BRASS))
		for j in jobs:
			var b := LGUi.button(_job_line(j, titles, before), show_job.bind(j), WIDTH)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = not Progress.is_open(j)
			list.add_child(b)
			before = j
	_back(show_main)
	LGUi.focus_first(_col)


## A job on the board: its title, and how it came off or what opens it.
func _job_line(id: String, titles: Dictionary, before: String) -> String:
	var t := str(titles.get(id, id))
	if Progress.is_done(id):
		var d: Dictionary = Progress.done[id]
		var marks := PackedStringArray()
		for k in ["clean", "quiet", "silver"]:
			if bool(d.get(k, false)):
				marks.append(k.capitalize())
		return "%s: done%s" % [t, (", " + ", ".join(marks)) if not marks.is_empty() else ""]
	if not Progress.is_open(id):
		return "%s: after %s" % [t, str(titles.get(Jobs.CAMPAIGN[Jobs.CAMPAIGN.find(id) - 1], before)).to_lower()]
	return t


func _buy_face() -> void:
	if Progress.buy_face():
		if CityOnline.enabled() and LGOnline.is_connected_online():
			CityOnline.buy_face()
		show_board()
		_text("A new face. Halberd's photo is of somebody else now.", true)

#endregion

#region The Circuit

## The Circuit: this week's contract, a night rolled at random, or one
## whose number a friend shared.
func show_circuit() -> void:
	LGVoice.hush(_mae)
	_clear("circuit")
	_heading("The Circuit")
	_text("Every job again, remixed by a night's number: people's rounds moved, new rules, a new take. The same number is the same night for everyone, so share it.", true)
	var week := Circuit.week()
	_col.add_child(HotelTheme.hud_label("This week's contract", 20, HotelTheme.BRASS))
	_text(_night_text(week))
	_col.add_child(LGUi.button("Take the contract", show_night.bind(week), WIDTH))
	if CityOnline.enabled():
		_col.add_child(LGUi.button("The contract's board", show_boards.bind(0), WIDTH))
	_col.add_child(HotelTheme.hud_label("Any night", 20, HotelTheme.BRASS))
	_col.add_child(LGUi.button("Roll a night", _roll_night, WIDTH))
	_night = LineEdit.new()
	_night.placeholder_text = "A night's number"
	_night.max_length = 7
	_night.custom_minimum_size.x = WIDTH
	_night.text_submitted.connect(_night_entered)
	LGUi.gamepad_text_entry(_night)
	_col.add_child(_night)
	_col.add_child(LGUi.button("Play that night", _night_pressed, WIDTH))
	_status = _text("", true)
	_back(show_main)
	LGUi.focus_first(_col)


## A night in a line: which job, its rules, the take, and your best.
func _night_text(seed: int) -> String:
	var def := Circuit.make(seed)
	if def == null:
		return ""
	var best := Progress.circuit_best(seed)
	return "%s at %s. %s The take: %s.%s" % [def.title, _the(def.venue_name), Circuit.rules_text(def), JobReportCard.money(def.take),
		(" Your best: %s." % JobReportCard.money(int(best.take))) if not best.is_empty() else ""]


## "The Hotel Meridian" as "the Hotel Meridian", mid-sentence.
static func _the(venue: String) -> String:
	return "the" + venue.substr(3) if venue.begins_with("The ") else venue


## A Circuit night's page: the job's, remixed.
func show_night(seed: int) -> void:
	Session.set_job(Circuit.job_for(seed), seed)
	show_job()


func _roll_night() -> void:
	show_night(Circuit.roll())


func _night_entered(text: String) -> void:
	var digits := text.strip_edges().replace(" ", "")
	if digits.is_valid_int() and int(digits) >= Circuit.LOWEST and int(digits) <= Circuit.HIGHEST:
		show_night(int(digits))
	elif _status:
		_status.text = "A night's number is six digits."


func _night_pressed() -> void:
	_night_entered(_night.text)

#endregion

#region A job

## The gala's page (the first job's).
func show_gala() -> void:
	show_job("meridian_gala")


## A job's page: the briefing (read out in Mae's voice when it can be),
## your cover, and how you're playing. On a Circuit night it says so, with
## the night's rules and take.
func show_job(id := "") -> void:
	if id != "" and (id != Session.job_id or Session.circuit != 0):
		Session.set_job(id)
	Session.ensure_job()
	var def := Jobs.current
	if not Covers.has(_cover):
		_cover = Covers.first()
	var fresh := _page != "job"
	_clear("job")
	var night := int(def.circuit.get("seed", 0))
	if night != 0:
		_heading("This week's contract" if night == Circuit.week() else "Circuit night %d" % night)
		_text("%s at %s. The take: %s." % [def.title, _the(def.venue_name), JobReportCard.money(def.take)], true)
		for r in def.circuit.rules:
			_text("%s: %s" % [Circuit.RULES[r].name, Circuit.RULES[r].text])
	else:
		_heading(def.title)
		_text("%s. The take: %s." % [def.venue_name, JobReportCard.money(def.take)], true)
	_text("%s: \"%s\"" % [_briefer(def), def.briefing])
	_text("The job: %s." % def.goal.trim_suffix("."), true)
	if fresh:
		_read_out(def)
	_col.add_child(HotelTheme.hud_label("Your cover", 20, HotelTheme.BRASS))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_col.add_child(grid)
	for c_id in Covers.order():
		var b := LGUi.button(str(Covers.of(c_id).title), _pick_cover.bind(c_id), (WIDTH - 8) / 2)
		if c_id == _cover:
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
	if CityOnline.enabled():
		_col.add_child(LGUi.button("Host a crew online", _host_online, WIDTH))
	_status = _text("", true)
	_col.add_child(LGUi.button("Join a crew", show_join, WIDTH))
	_back(show_circuit if night != 0 else show_board)
	LGUi.focus_first(_col)


## Who gives a job's briefing.
static func _briefer(def: JobDef) -> String:
	return def.briefer if def.briefer != "" else "Auntie Mae"


## Reads the briefing out in its teller's voice, when the voices are up.
func _read_out(def: JobDef) -> void:
	LGVoice.hush(_mae)
	if not LGVoice.is_ready() or not bool(LGSettings.get_value("voice", "speaking", true)):
		return
	var voice := def.briefer_voice if def.briefer_voice != "" else GameConfig.MAE_VOICE
	LGVoice.say(Language.clean(def.briefing), voice, _mae, 0.95)


func _pick_cover(id: String) -> void:
	_cover = id
	Session.set_cover(_cover, _female)
	if _page == "lobby":
		_queue_lobby("> %s <" % Covers.of(id).title)
		return
	show_job()
	_focus_text("> %s <" % Covers.of(id).title)


func _toggle_body() -> void:
	_female = not _female
	Session.set_cover(_cover, _female)
	if _page == "lobby":
		_queue_lobby("You look like: %s" % ("a woman" if _female else "a man"))
		return
	show_job()
	_focus_text("You look like: %s" % ("a woman" if _female else "a man"))


func _focus_text(text: String) -> void:
	for b in _col.find_children("", "Button", true, false):
		if b.text == text:
			b.grab_focus.call_deferred()


func _play_alone() -> void:
	LGVoice.hush(_mae)
	Session.start_solo(_cover, _female)
	Session.start_job()


func _host() -> void:
	LGVoice.hush(_mae)
	Session.host_lan(_cover, _female)


func _host_online() -> void:
	LGVoice.hush(_mae)
	if _status:
		_status.text = "Connecting to the game server..."
	if await Session.host_online(_cover, _female):
		# Brings the characters' memories of this account along.
		CityOnline.pull()

#endregion

#region A crew


## Crews hosting on this network, and a code to type.
func show_join() -> void:
	LGVoice.hush(_mae)
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
	if CityOnline.enabled():
		_col.add_child(LGUi.button("Join an online crew with the code", _join_online_pressed, WIDTH))
		_col.add_child(LGUi.button("Read a shared report with the code", _read_report_pressed, WIDTH))
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


func _join_online_pressed() -> void:
	if _code.text.strip_edges() == "":
		_on_status("Type the room code shown on the host's screen.")
		return
	await Session.join_online(_code.text, _cover, _female)


func _read_report_pressed() -> void:
	var code := _code.text.strip_edges()
	if code == "":
		_on_status("Type the report's code.")
		return
	_on_status("Looking for that report...")
	var found := await CityOnline.read_report(code)
	if _page != "join":
		return
	if found.is_empty():
		_on_status("No report with that code.")
		return
	show_shared(found)


func _leave_join() -> void:
	Session.leave()
	Session.stop_browsing()
	show_main()


## The crew before the job: who's in, in what cover, and the code.
func show_lobby() -> void:
	_clear("lobby")
	_heading("Your crew")
	Session.ensure_job()
	_text("%s, %s%s" % [Jobs.current.title, Jobs.current.venue_name, JobReportCard.night({"circuit": Session.circuit})], true)
	if Session.is_online():
		if Session.join_code != "":
			_text("Room code: %s" % LGOnline.normalize_code(Session.join_code))
			if Session.is_host():
				_text("Anywhere: Join a crew, then type the code and Join an online crew.", true)
	elif Session.join_code != "":
		_text("Code: %s" % JoinCode.pretty(Session.join_code))
		_text("On another computer on this network: Join a crew, then pick this crew or type the code.", true)
	var ids := Session.crew.keys()
	ids.sort()
	for id in ids:
		var c: Dictionary = Session.crew[id]
		var you := " (you)" if int(id) == Session.local_id() else ""
		_text("%s%s: %s, %s" % [c.name, you, Covers.cover_name(str(c.cover), bool(c.female)), Covers.role(str(c.cover))])
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
	if _page != "lobby":
		return
	_page = "leaving"
	Session.leave()
	show_job()


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
		show_main()
		if reason != "":
			_status = _text(reason, true)


func _on_status(text: String) -> void:
	if _status:
		_status.text = text

#endregion

#region Online boards and reports

## The Leaderboards: your online record, then a board of the crews' takes
## and jobs. `first` is the board shown first (an index of [constant CityOnline.BOARDS]).
func show_boards(first := 0) -> void:
	LGVoice.hush(_mae)
	_clear("boards")
	_heading("Leaderboards")
	_text("From online jobs. The contract's board takes your take from any go at this week's contract, alone too.", true)
	var panel := LGLeaderboardPanel.new()
	panel.setup(GameConfig.GAME_ID, GameConfig.player_name(), CityOnline.BOARDS.slice(first) + CityOnline.BOARDS.slice(0, first), CityOnline.record_text)
	_col.add_child(panel)
	_back(show_main)
	LGUi.focus_first(_col)


## A report someone shared: its title and text.
func show_shared(found: Dictionary) -> void:
	_clear("shared")
	_heading(str(found.get("title", "A report")))
	var text := _text(str(found.get("text", "")))
	text.custom_minimum_size.x = WIDTH
	_col.add_child(LGUi.button("Copy the text", DisplayServer.clipboard_set.bind(str(found.get("text", ""))), WIDTH))
	_back(show_join)
	LGUi.focus_first(_col)

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
	_text("A co-op con game where the guards, staff and guests hear what you say and answer in their own words. Auntie Mae finds the jobs: a season of them, after the Rose, across Caldera. The service door is M0's proof, kept for measuring.")
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
				show_main()
			elif _page == "job":
				LGVoice.hush(_mae)
				if Session.circuit != 0:
					show_circuit()
				else:
					show_board()
			else:
				show_main()
