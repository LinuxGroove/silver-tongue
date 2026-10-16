extends Node
## Boots the game: settings, input map, theme and window, then the title.
##
## Developer shortcuts (after `--`):
##   --door            straight to the service door (the M0 proof), through the setup screen
##   --text            with --door: type your lines instead of talking
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
	LGScenes.change_scene("res://game/ui/title.tscn")
