class_name GameConfig
extends RefCounted
## Game-wide constants: identity, version, input map and setting defaults.

const GAME_ID := "silver-tongue"

## This round's own questions at the end of a play test (LGPlaytest), on top
## of the standard ones. M0 is one guard at one door, so they ask about him.
const PLAYTEST := {
	"questions": [
		{"id": "heard", "text": "Did the guard hear what you actually said? Where did he get it wrong?", "kind": "text"},
		{"id": "quick", "text": "How quickly did he answer? Did the wait ever break the moment?", "kind": "rating"},
		{"id": "fair", "text": "When he let you through or refused, did it feel fair?", "kind": "rating"},
		{"id": "line", "text": "What's the line that worked, or the one you wish had?", "kind": "text"},
	],
}

const SETTING_DEFAULTS := {
	"online": {
		"enabled": true,
		"host": OnlineServer.HOST,
		"port": OnlineServer.PORT,
		"scheme": OnlineServer.SCHEME,
		"server_key": OnlineServer.SERVER_KEY,
	},
	"player": {
		# The name the crew goes by ("" for "Stranger").
		"name": "",
	},
	"play": {
		"invert_look": false,
		"mouse_sensitivity": 0.25,
		"stick_sensitivity": 2.0,
		"toggle_crouch": true,
		# Comfort: head bob (0 to 1), the view rolling, and the field of view.
		# Calm by default, for players prone to motion sickness.
		"bob": 0.0,
		"tilt": false,
		"fov": 75.0,
		# Subtitles for everyone who speaks, and your own words as the guard heard them.
		"subtitles": true,
	},
	"voice": {
		# How you talk: "push" (hold to talk), "open" (the mic is always on)
		# or "text" (type a line). Push to talk by default, for privacy.
		"talk": "push",
		# The Whisper model Lemonade listens with: Whisper-Tiny on a handheld,
		# Whisper-Small on a desktop GPU.
		"hearing_model": "Whisper-Small",
		# Characters speak out loud (Kokoro through Lemonade), with subtitles either way.
		"speaking": true,
		# The timing readout on the HUD: heard, thought and spoke, in seconds.
		"timing": true,
		# Mind your language: characters keep it clean, and so does what they hear.
		"mind_language": false,
	},
}

## Every in-game action, with keyboard and controller bindings (see LGInput).
## Movement, interaction and menu names are Cogito's, so its player and
## interaction raycast read them as they are.
const ACTIONS := {
	"forward": ["key:W", "axis:ly-"],
	"back": ["key:S", "axis:ly+"],
	"left": ["key:A", "axis:lx-"],
	"right": ["key:D", "axis:lx+"],
	"jump": ["key:Space"],
	"crouch": ["key:Ctrl", "key:C", "joy:b"],
	# Nobody runs in a hotel.
	"sprint": [],
	"menu": ["key:Escape", "joy:start"],
	"free_look": [],
	"interact": ["key:F", "joy:x"],
	"interact2": [],
	"action_primary": [],
	"action_secondary": [],
	"reload": [],
	# Hold to talk; the guard hears what you say while it's held.
	"talk": ["key:V", "joy:a", "axis:rt+"],
	# Held with talk: a whisper carries a metre or two, a shout the whole room.
	"whisper": ["key:Shift", "joy:lb"],
	"shout": ["key:Alt", "joy:rb"],
	# Type a line instead of saying it.
	"text": ["key:T", "joy:y"],
	# Cogito reads these; Silver Tongue has no inventory screen.
	"inventory": [],
	"inventory_move_item": [],
	"inventory_use_item": [],
	"inventory_drop_item": [],
	"inventory_assign_item": [],
	"quickslot_1": [],
	"quickslot_2": [],
	"quickslot_3": [],
	"quickslot_4": [],
	"quickslot_prev_wieldable": [],
	"quickslot_next_wieldable": [],
	"lean_left": [],
	"lean_right": [],
	"ui_next_tab": ["key:E", "joy:rb"],
	"ui_prev_tab": ["key:Q", "joy:lb"],
}


static func version() -> String:
	return LGVersion.current()


## The name the crew goes by.
static func player_name() -> String:
	var n := str(LGSettings.get_value("player", "name", "")).strip_edges()
	return n if n != "" else "Stranger"
