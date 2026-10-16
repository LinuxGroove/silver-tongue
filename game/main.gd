extends Node
## Boots the game: settings, input map, theme and window, then the title.
##
## Developer shortcuts (after `--`):
##   --door            straight to the service door (the M0 proof), through the setup screen
##   --gala            straight into the gala, alone, through the setup screen
##   --job=marlin_safe straight into any job, alone
##   --cover=press     with --gala or --job: your cover (the gala's: facilities, guest, press, agency)
##   --female          with --gala or --job: a woman's body
##   --text            with --door or --gala: type your lines instead of talking
##   --playtest        record a play test (see LGPlaytest)
##   --set=section/key=value   any setting, for one run (LGSettings reads it)


func _ready() -> void:
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGLaunchPing.send(GameConfig.GAME_ID)
	LGPlaytest.setup(GameConfig.GAME_ID, GameConfig.PLAYTEST)
	LGInput.register_actions(GameConfig.ACTIONS, float(LGSettings.get_value("input", "stick_deadzone", 0.2)))
	LGInput.extend_ui_actions()
	HotelTheme.apply(get_tree().root, 22)
	get_window().title = "Silver Tongue"
	var args := OS.get_cmdline_user_args()
	if "--text" in args:
		LGSettings.set_value("voice", "talk", "text")
	if "--door" in args:
		SetupScreen.play_door()
		return
	var job := ""
	for a in args:
		if a.begins_with("--job="):
			job = a.trim_prefix("--job=")
	if "--gala" in args or job != "":
		var cover := ""
		for a in args:
			if a.begins_with("--cover="):
				cover = a.trim_prefix("--cover=")
		Session.start_solo(cover if cover != "" else "guest", "--female" in args)
		Session.set_job(job if job != "" else "meridian_gala")
		if cover != "":
			Session.set_cover(cover, "--female" in args)
		Session.start_job()
		return
	LGScenes.change_scene("res://game/ui/title.tscn")
