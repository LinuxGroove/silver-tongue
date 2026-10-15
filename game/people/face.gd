class_name Face
extends Node3D
## A mouth that moves while a [Person] speaks: a small dark shape just below
## the eyes, riding the head bone, that opens with the voice's loudness.
## The body's own eyes and brows stay as they are.

## How far the mouth opens at full loudness, in metres.
const OPEN := 0.028
const REST := 0.005

## The voice's loudness right now, 0 to 1 (set by whoever plays the voice).
var level := 0.0
var _mouth: MeshInstance3D
var _box: BoxMesh
var _shown := 0.0


## Puts a face on a person, under the head's rest-space node.
static func make(person: Person) -> Face:
	var rest := person.on_head()
	var f := Face.new()
	f.name = "Face"
	if rest:
		rest.add_child(f)
		f.position = person.eyes_at + Vector3(0, -0.082, 0.028)
	f._build()
	return f


func _build() -> void:
	_box = BoxMesh.new()
	_box.size = Vector3(0.046, REST, 0.012)
	_mouth = MeshInstance3D.new()
	_mouth.mesh = _box
	_mouth.material_override = Kit.flat(Color(0.22, 0.07, 0.07), 0.6)
	_mouth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mouth)


func _process(delta: float) -> void:
	# Opens quickly, closes a little slower, so syllables read as syllables.
	var target := clampf(level, 0.0, 1.0)
	var k := 1.0 - exp(-delta * (30.0 if target > _shown else 18.0))
	_shown = lerpf(_shown, target, k)
	_box.size = Vector3(0.046 - _shown * 0.012, REST + OPEN * _shown, 0.012)
	_mouth.position.y = -(_box.size.y - REST) * 0.5
