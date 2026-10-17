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
## Interact was pressed (the scene works out what's in front of you).
signal use_pressed
## The phone button.
signal phone_pressed

## Cogito player nodes Silver Tongue doesn't use.
const UNUSED := ["CogtoTestCurrency", "StrengthAttribute", "LightMeterAttribute",
	"SanityAttribute", "StaminaAttribute", "HealthAttribute", "HealthAutoConsume",
	"StaminaAutoConsume", "AutoPickUpZone"]
## How far the body's origin is above the floor (Cogito's standing box is
## 1.7 m tall, centred 0.05 m above it).
const FEET := 0.8
const BOB_WALK := 0.03
const BOB_CROUCH := 0.04
## The over-the-shoulder view: how far behind, to the right and above your
## eyes the camera sits, how close a wall may bring it, and how gently it
## follows (higher is quicker).
const BEHIND := 2.4
const SHOULDER := 0.45
const ABOVE := 0.15
const NEAREST := 0.35
const FOLLOW := 9.0

## The pause menu to use in place of Cogito's, set before entering the tree.
var hotel_pause: Node
var talking := false
## The talk under way is on the earpiece, to the crew only.
var on_earpiece := false
## Seen over your shoulder rather than through your eyes (the View setting).
var third_person := false
## Your own body, for the over-the-shoulder view (the scene dresses it).
var person: Person
var _tilt := false
var _view_cam: Camera3D
var _view_at := Vector3.INF


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
	_set_view(str(LGSettings.get_value("play", "view", "first")) == "third")


## Through your eyes, or over your shoulder. The eyes' camera stays where
## it is either way (Interact aims from it); the shoulder camera only shows.
func _set_view(third: bool) -> void:
	var changed := third != third_person or (third and _view_cam == null)
	third_person = third
	if third and _view_cam == null:
		_view_cam = Camera3D.new()
		_view_cam.name = "ShoulderCamera"
		_view_cam.top_level = true
		_view_cam.near = 0.05
		add_child(_view_cam)
		_view_at = Vector3.INF
	if _view_cam:
		_view_cam.fov = camera.fov
		if changed and third:
			_view_cam.make_current()
		elif changed:
			camera.make_current()
	if person:
		person.visible = third


## Dresses your body (the scene calls it again when your clothes change).
func set_person(p: Person) -> void:
	if person:
		person.queue_free()
	person = p
	body.add_child(person)
	person.position = Vector3(0, -FEET, 0)
	person.rotation.y = PI
	person.visible = third_person
	person.play("Idle")


## The shoulder camera follows gently, and comes in front of any wall
## behind you rather than through it.
func _process(delta: float) -> void:
	if not third_person or _view_cam == null:
		return
	var look := camera.global_transform.basis
	var pivot := camera.global_position + look.x * SHOULDER + Vector3.UP * ABOVE
	var want := pivot + look.z * BEHIND
	var q := PhysicsRayQueryParameters3D.create(pivot, want, Kit.LAYER_SOLID)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		want = pivot + (hit.position - pivot).normalized() * maxf(NEAREST, pivot.distance_to(hit.position) - 0.2)
	if _view_at == Vector3.INF or _view_at.distance_to(want) > 4.0:
		_view_at = want
	else:
		_view_at = _view_at.lerp(want, 1.0 - exp(-delta * FOLLOW))
	_view_cam.global_transform = Transform3D(look, _view_at)
	if person:
		var moving := Vector2(velocity.x, velocity.z).length() > 0.3
		if is_crouching:
			person.play("Crouch_Fwd" if moving else "Crouch_Idle")
		else:
			person.play("Walk" if moving else "Idle")


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


## Where you're standing, on the floor.
func feet_position() -> Vector3:
	return global_position - Vector3(0, FEET, 0)


## Where your mouth is.
func mouth_position() -> Vector3:
	return camera.global_position


## Which way you're looking.
func look_dir() -> Vector3:
	return -camera.global_transform.basis.z


## Your view's pitch, for your body on other devices.
func look_pitch() -> float:
	return head.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or is_movement_paused or is_showing_ui:
		if talking:
			end_talk()
		return
	if event.is_action_pressed("talk") and not talking:
		talking = true
		on_earpiece = false
		talk_started.emit()
	elif event.is_action_pressed("earpiece") and not talking:
		talking = true
		on_earpiece = true
		talk_started.emit()
	elif (event.is_action_released("talk") and not on_earpiece or event.is_action_released("earpiece") and on_earpiece) and talking:
		end_talk()
	elif event.is_action_pressed("text"):
		text_requested.emit()
	elif event.is_action_pressed("interact"):
		use_pressed.emit()
	elif event.is_action_pressed("phone"):
		phone_pressed.emit()


func end_talk() -> void:
	talking = false
	talk_ended.emit()
