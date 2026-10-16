class_name Face
extends Node3D
## A mouth that moves while a [Person] speaks: a dark oval between the lips,
## riding the head bone, that opens with the voice's loudness and is gone
## when they're quiet. The body's own eyes, brows and lips stay as they are.

## How far the mouth opens at full loudness, in meters.
const OPEN := 0.02
const WIDE := 0.036

## The voice's loudness right now, 0 to 1 (set by whoever plays the voice).
var level := 0.0
var _mouth: MeshInstance3D
var _shown := 0.0


## Puts a face on a person, under the head's rest-space node.
static func make(person: Person) -> Face:
	var rest := person.on_head()
	var f := Face.new()
	f.name = "Face"
	if rest:
		rest.add_child(f)
		# The line between the lips, measured on the male body, a little behind
		# their front so they frame it.
		f.position = person.eyes_at + Vector3(0, -0.073, 0.018)
	f._build()
	return f


func _build() -> void:
	var oval := SphereMesh.new()
	oval.radius = 0.5
	oval.height = 1.0
	oval.radial_segments = 16
	oval.rings = 8
	_mouth = MeshInstance3D.new()
	_mouth.mesh = oval
	_mouth.material_override = Kit.flat(Color(0.12, 0.04, 0.04), 0.7)
	_mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mouth.visible = false
	add_child(_mouth)


func _process(delta: float) -> void:
	# Opens quickly, closes a little slower, so syllables read as syllables.
	var target := clampf(level, 0.0, 1.0)
	var k := 1.0 - exp(-delta * (30.0 if target > _shown else 18.0))
	_shown = lerpf(_shown, target, k)
	_mouth.visible = _shown > 0.04
	var open := OPEN * _shown
	_mouth.scale = Vector3(WIDE - _shown * 0.01, open, 0.014)
	# The top stays at the upper lip; the jaw drops.
	_mouth.position.y = -open * 0.4
