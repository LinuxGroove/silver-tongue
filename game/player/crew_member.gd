class_name CrewMember
extends CogitoPlayer
## The player: one of the crew, walking the Meridian's back corridor. Cogito's
## first person controller with its health, stamina, inventory and pause menu
## left out, at a walking pace (nobody runs in a hotel), and the talk controls:
## hold to talk, whisper or shout while held, or type a line.
##
## Comfort first (see [method _reload_options]): no head bob or view roll
## unless the settings ask for it.

## Hold to talk has started or ended; the scene passes it to [LGVoice].
signal talk_started
signal talk_ended
## The text line was asked for.
signal text_requested

## Cogito player nodes Silver Tongue doesn't use.
const UNUSED := ["CogtoTestCurrency", "StrengthAttribute", "LightMeterAttribute",
	"SanityAttribute", "StaminaAttribute", "HealthAttribute", "HealthAutoConsume",
	"StaminaAutoConsume", "AutoPickUpZone"]
const BOB_WALK := 0.03
const BOB_CROUCH := 0.04

## The pause menu to use in place of Cogito's, set before entering the tree.
var hotel_pause: Node
var talking := false
var _tilt := false


func _ready():
	$PlayerInteractionComponent.stamina_attribute = null
	for n in UNUSED:
		var node := get_node_or_null(n)
		if node:
			remove_child(node)
			node.free()
	var cogito_pause := get_node_or_null(pause_menu)
	if cogito_pause:
		cogito_pause.get_parent().remove_child(cogito_pause)
		cogito_pause.free()
	if hotel_pause:
		pause_menu = hotel_pause.get_path()
	fall_damage = 0
	collision_layer = Kit.LAYER_PLAYER
	collision_mask = Kit.LAYER_SOLID | Kit.LAYER_PEOPLE
	CAN_BUNNYHOP = false
	disable_roll_anim = true
	WALKING_SPEED = 2.4
	SPRINTING_SPEED = 2.4
	CROUCHING_SPEED = 1.4
	walk_volume_db = -16.0
	sprint_volume_db = -16.0
	crouch_volume_db = -24.0
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	head.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	neck.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	eyes.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	camera.near = 0.04
	_reload_options()
	super()
	# Cogito's options menu, in the player's scene, turns the window's stretch off as it starts.
	get_window().content_scale_size = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	# It also loads Cogito's own key bindings over the game's; put the game's back.
	LGInput.register_actions(GameConfig.ACTIONS, float(LGSettings.get_value("input", "stick_deadzone", 0.25)))
	LGInput.extend_ui_actions()
	var hud := get_node_or_null(player_hud)
	if hud:
		for n in ["FixedStaminaBar", "InventoryInterface", "MarginContainer_BottomUI", "Crosshair"]:
			var c := hud.get_node_or_null(n) as CanvasItem
			if c:
				c.hide()
				c.process_mode = Node.PROCESS_MODE_DISABLED
		for n in ["PromptUI/PromptArea", "HintArea"]:
			var c := hud.get_node_or_null(n) as CanvasItem
			if c:
				c.modulate.a = 0.0
	add_to_group("crew")


## Settings come from LGSettings, not Cogito's own options file.
func _reload_options():
	MOUSE_SENS = float(LGSettings.get_value("play", "mouse_sensitivity", 0.25))
	INVERT_Y_AXIS = bool(LGSettings.get_value("play", "invert_look", false))
	TOGGLE_CROUCH = bool(LGSettings.get_value("play", "toggle_crouch", true))
	var bob := float(LGSettings.get_value("play", "bob", 0.0))
	HEADBOBBLE = 1
	WIGGLE_ON_WALKING_INTENSITY = BOB_WALK * bob
	WIGGLE_ON_SPRINTING_INTENSITY = BOB_WALK * bob
	WIGGLE_ON_CROUCHING_INTENSITY = BOB_CROUCH * bob
	_tilt = bool(LGSettings.get_value("play", "tilt", false))
	camera.fov = float(LGSettings.get_value("play", "fov", 75.0))
	JOY_H_SENS = float(LGSettings.get_value("play", "stick_sensitivity", 2.0))
	JOY_V_SENS = JOY_H_SENS


func _physics_process(delta):
	if is_dead:
		velocity = Vector3.ZERO
		return
	super(delta)
	if not _tilt:
		eyes.rotation.z = 0.0


## Opens the pause menu as the menu button does, unless something else has
## you (a text line, a result).
func open_pause() -> void:
	if is_showing_ui or is_movement_paused or is_dead or currently_tweening or CogitoSceneManager.is_currently_loading:
		return
	_on_pause_movement()
	get_node(pause_menu).open_pause_menu()


## How you're speaking right now: "whisper", "shout" or "normal".
func voice() -> String:
	if Input.is_action_pressed("whisper"):
		return "whisper"
	if Input.is_action_pressed("shout"):
		return "shout"
	return "normal"


## Where your mouth is.
func mouth_position() -> Vector3:
	return camera.global_position


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or is_movement_paused or is_showing_ui:
		if talking:
			end_talk()
		return
	if event.is_action_pressed("talk") and not talking:
		talking = true
		talk_started.emit()
	elif event.is_action_released("talk") and talking:
		end_talk()
	elif event.is_action_pressed("text"):
		text_requested.emit()


func end_talk() -> void:
	talking = false
	talk_ended.emit()
