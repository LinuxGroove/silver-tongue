class_name VantageTower
extends Venue
## Vantage Tower, the glass headquarters of Vantage in downtown Caldera, where
## the Rose is cut. Three floors of it are built, stacked well apart: the
## ground floor (a tall glass lobby with Halberd's speed gates, Dana's front
## desk and the cafe, the lift lobby, the security office and the plant
## room), the research floor on level 9 (the lift lobby, Halberd's
## high-security checkpoint and its scanner, the lab, the gem-cutting room
## behind glass, the lab manager's office and the break room) and the board
## floor on level 12 (the lift lobby, the assistants' desks, the boardroom,
## the catering pantry and the founder's office). Outside: the plaza, the
## street, the city at night and a sky.
##
## X runs east and Z south. The ground floor is y = 0, the research floor
## [constant R] and the board floor [constant B]; each upper room's node sits
## at its floor's height, so the building blocks work in the floor's own
## coordinates, while spots, points, doors and views are in the world's.
## People ride lift B straight up its links; the crew ride with
## [method Job.move_crew], when the job's call panel says they may.
##
## Built for one night (`"lift"`, `"board"` or `"research"`): where the crew
## starts, the crowd and the clocks are that night's.

## The rooms. Upper floors' zones run from a metre under their floor.
const ZONES := {
	"lobby": AABB(Vector3(-18.0, -1.0, -18.0), Vector3(36.0, 11.0, 18.0)),
	"lift_lobby": AABB(Vector3(-4.0, -1.0, -32.0), Vector3(10.0, 6.0, 14.0)),
	"office": AABB(Vector3(6.0, -1.0, -28.0), Vector3(12.0, 6.0, 10.0)),
	"plant": AABB(Vector3(-18.0, -1.0, -28.0), Vector3(14.0, 6.0, 10.0)),
	"outside": AABB(Vector3(-200.0, -2.0, 0.0), Vector3(400.0, 120.0, 200.0)),
	"r_lobby": AABB(Vector3(-4.0, R - 1.0, -32.0), Vector3(10.0, 6.0, 14.0)),
	"break_room": AABB(Vector3(-18.0, R - 1.0, -28.0), Vector3(14.0, 6.0, 10.0)),
	"checkpoint": AABB(Vector3(-4.0, R - 1.0, -18.0), Vector3(10.0, 6.0, 6.0)),
	"lab": AABB(Vector3(-8.0, R - 1.0, -12.0), Vector3(16.0, 6.0, 12.0)),
	"lab_office": AABB(Vector3(-18.0, R - 1.0, -12.0), Vector3(10.0, 6.0, 12.0)),
	"cutting": AABB(Vector3(8.0, R - 1.0, -12.0), Vector3(10.0, 6.0, 12.0)),
	"b_lobby": AABB(Vector3(-4.0, B - 1.0, -32.0), Vector3(10.0, 6.0, 14.0)),
	"assist": AABB(Vector3(-4.0, B - 1.0, -18.0), Vector3(10.0, 6.0, 18.0)),
	"boardroom": AABB(Vector3(-18.0, B - 1.0, -14.0), Vector3(14.0, 6.0, 14.0)),
	"pantry": AABB(Vector3(-12.0, B - 1.0, -22.0), Vector3(8.0, 6.0, 8.0)),
	"founder": AABB(Vector3(6.0, B - 1.0, -14.0), Vector3(12.0, 6.0, 14.0)),
}
const ZONE_ORDER: Array[String] = ["pantry", "checkpoint", "lab_office", "cutting", "office", "plant", "break_room",
	"lift_lobby", "r_lobby", "b_lobby", "lab", "founder", "boardroom", "assist", "lobby", "outside"]
const LAYERS := {
	"lobby": 2, "lift_lobby": 3, "office": 4, "plant": 5, "outside": 6,
	"r_lobby": 7, "break_room": 8, "checkpoint": 9, "lab": 10, "lab_office": 11, "cutting": 12,
	"b_lobby": 13, "assist": 14, "boardroom": 15, "pantry": 16, "founder": 17,
}
const RESEARCH_ROOMS := ["r_lobby", "break_room", "checkpoint", "lab", "lab_office", "cutting"]
const BOARD_ROOMS := ["b_lobby", "assist", "boardroom", "pantry", "founder"]

## The research floor (level 9) and the board floor (level 12), and the roof.
const R := 36.0
const B := 48.0
const TOP := 60.0
## Ceiling heights.
const LOBBY_H := 9.0
const BACK_H := 3.6
const CORE_H := 4.0
const R_H := 4.0
const B_H := 4.2
## The street: the plaza from the tower's glass (z = 0) to the kerb, the road,
## then the far pavement and the blocks across.
const KERB := 15.0
const FAR_KERB := 22.0
const ACROSS := 25.0

## The floors lift B stops at: their height and what they're called.
const FLOORS := {"g": 0.0, "r": R, "b": B}
const FLOOR_NAMES := {"g": "the lobby", "r": "the research floor", "b": "the board floor"}
## Where Halberd's scanner picks up a transmitter: the research floor's
## high-security rooms.
const SECURE := ["checkpoint", "lab", "lab_office", "cutting"]

## The swinging doors: the middle of the doorway on the floor (x, z), "y" for
## an upper floor, its size, the way it opens when nobody's given, the leaf.
const DOOR_SPECS := {
	"front": {"at": Vector2(0.0, 0.0), "w": 2.4, "h": 2.8, "double": true, "to": Vector2(0, -1), "model": "vantage_glass_leaf", "auto": true, "thick": 0.06},
	"gates": {"at": Vector2(3.15, -18.0), "w": 1.7, "h": 1.8, "double": true, "to": Vector2(0, -1), "model": "vantage_gate_flap", "thick": 0.05},
	"plant": {"at": Vector2(-11.0, -18.0), "w": 1.1, "h": 2.3, "to": Vector2(0, -1), "model": "vantage_door_oak"},
	"office": {"at": Vector2(12.0, -18.0), "w": 1.1, "h": 2.3, "to": Vector2(0, -1), "model": "vantage_door_oak"},
	"break": {"at": Vector2(-4.0, -23.0), "y": R, "w": 1.1, "h": 2.3, "to": Vector2(-1, 0), "model": "vantage_door_oak"},
	"lab_office": {"at": Vector2(-8.0, -8.0), "y": R, "w": 1.1, "h": 2.3, "to": Vector2(-1, 0), "model": "vantage_door_oak"},
	"pantry": {"at": Vector2(-4.0, -20.0), "y": B, "w": 1.1, "h": 2.3, "to": Vector2(-1, 0), "model": "vantage_door_oak"},
	"service": {"at": Vector2(-8.0, -14.0), "y": B, "w": 1.1, "h": 2.3, "to": Vector2(0, 1), "model": "vantage_door_oak"},
	"boardroom": {"at": Vector2(-4.0, -6.0), "y": B, "w": 1.8, "h": 2.5, "double": true, "to": Vector2(-1, 0), "model": "vantage_door_oak"},
	"founder": {"at": Vector2(6.0, -6.0), "y": B, "w": 1.1, "h": 2.3, "to": Vector2(1, 0), "model": "vantage_door_oak"},
}
## The sliding doors: lift B's on every floor, and the lab's glass.
const SLIDE_SPECS := {
	"lift_g": {"at": Vector2(3.5, -28.0), "y": 0.0, "w": 1.2, "h": 2.3, "double": true, "to": Vector2(0, -1), "model": "vantage_lift_leaf", "thick": 0.05},
	"lift_r": {"at": Vector2(3.5, -28.0), "y": R, "w": 1.2, "h": 2.3, "double": true, "to": Vector2(0, -1), "model": "vantage_lift_leaf", "thick": 0.05},
	"lift_b": {"at": Vector2(3.5, -28.0), "y": B, "w": 1.2, "h": 2.3, "double": true, "to": Vector2(0, -1), "model": "vantage_lift_leaf", "thick": 0.05},
	"secure": {"at": Vector2(1.0, -12.0), "y": R, "w": 1.6, "h": 2.4, "double": true, "to": Vector2(0, 1), "model": "vantage_glass_leaf", "thick": 0.05},
	"cutting": {"at": Vector2(8.0, -8.5), "y": R, "w": 1.2, "h": 2.4, "to": Vector2(1, 0), "model": "vantage_glass_leaf", "thick": 0.05},
}

## A door whose leaves slide aside along the doorway's line instead of
## swinging: lift doors, and the lab's glass. Otherwise a [HotelDoor].
class SlideDoor:
	extends HotelDoor

	func _swing_to(dir: int) -> void:
		if _tween:
			_tween.kill()
			_tween = null
		var leaf_w := width * 0.5 if double else width
		var targets: Array[float] = []
		for i in leaves.size():
			var base := 0.0 if i == 0 else -width
			targets.append(base + (0.0 if dir == 0 else leaf_w * 0.96 * (1.0 if i == 0 else -1.0)))
		if not is_inside_tree():
			for i in leaves.size():
				leaves[i].position.x = targets[i]
			return
		_tween = create_tween().set_parallel(true)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.set_trans(Tween.TRANS_SINE)
		for i in leaves.size():
			_tween.tween_property(leaves[i], "position:x", targets[i], SECONDS * 0.8)


## Which night it's built for: "lift" (6 pm), "board" (7:30 pm) or "research" (10:40 pm).
var night := "lift"


func _init(p_night := "lift") -> void:
	night = p_night
	zones = ZONES
	zone_order = ZONE_ORDER
	room_layers = LAYERS


## The doors are HotelDoors by name (front, gates, plant, office, the lifts'
## lift_g, lift_r and lift_b, break, secure, lab_office, cutting, pantry,
## service, boardroom, founder); the uses are the lift's call panels
## (lift_call_g, lift_call_r, lift_call_b), the cutting room's keypad
## (cutting_pad) and the Rose's cradle (cradle).
func _build() -> void:
	_make_rooms(ZONE_ORDER)
	for z in RESEARCH_ROOMS:
		_rooms[z].position.y = R
	for z in BOARD_ROOMS:
		_rooms[z].position.y = B
	_ground()
	_lobby()
	_gates()
	_front_desk()
	_cafe()
	_core("lift_lobby", "g")
	_office()
	_plant()
	_core("r_lobby", "r")
	_break_room()
	_checkpoint()
	_lab()
	_cutting()
	_lab_office()
	_core("b_lobby", "b")
	_assistants()
	_boardroom()
	_pantry()
	_founder()
	_tower()
	_plaza()
	_city()
	_doors()
	_graph()
	_crowd()
	_views()
	_apply_layers()
	_dress(self)
	set_clock({"lift": 18 * 60, "board": 19 * 60 + 30, "research": 22 * 60 + 40}.get(night, 18 * 60))


## Which floor a point is on: "g", "r" or "b".
static func floor_of(p: Vector3) -> String:
	if p.y > B - 3.0:
		return "b"
	if p.y > R - 3.0:
		return "r"
	return "g"


# --- The building's own rules, for the jobs ---------------------------------------------------

## Where car two goes from the ground floor, by night.
const UP_TO := {"lift": "b", "board": "b", "research": "r"}
const LEVEL_NAMES := {"g": "the lobby", "r": "level 9", "b": "level 12"}
## Crewmates this close go up with whoever calls the lift.
const RIDE_WITH := 3.0


## The lift's call button on `from_floor`: car two takes the crew member, and
## any crewmate beside them, to the night's other floor (the ground floor
## from upstairs). Going up needs `allowed`; going down is free. Nothing runs
## at Lockdown or once the tower's shut (the job's "shut" flag). Returns
## what to tell them.
static func ride_lift(job: Job, c: CrewInfo, from_floor: String, allowed: bool) -> String:
	if job.heat.level >= Heat.LOCKDOWN or job.flags.has("shut"):
		return "The lift doesn't come. The lifts are stopped."
	var night := str(job.flags.get("night", "lift"))
	var to: String = UP_TO.get(night, "b") if from_floor == "g" else "g"
	if from_floor == "g" and not allowed:
		return "The lift wants a pass for the upper floors."
	var riders := riders_with(job, c)
	job.open_for("lift_" + from_floor, 3.0)
	for r in riders:
		job.move_crew(r.id, "arrive_" + to)
		if r != c:
			job.toast_for.emit(r.id, "You ride with %s to %s." % [c.name, LEVEL_NAMES[to]])
	return "Car two takes you %s to %s." % ["up" if to != "g" else "down", LEVEL_NAMES[to]]


## A crew member and the free crewmates beside them on the same floor.
static func riders_with(job: Job, c: CrewInfo) -> Array:
	var out: Array = [c]
	var here := c.position()
	for o in job.free_crew():
		if o != c and o.node != null and floor_of(o.position()) == floor_of(here) and o.position().distance_to(here) < RIDE_WITH:
			out.append(o)
	return out


## The speed gates: going out to the lobby is free (except at Lockdown);
## coming in needs `pass_ok`. Returns what to tell them, or null when the
## gates are already open.
static func gates(job: Job, c: CrewInfo, pass_ok: bool) -> Variant:
	var d: HotelDoor = job.venue.doors.get("gates")
	if d == null or d.is_open:
		return null
	if job.heat.level >= Heat.LOCKDOWN or job.flags.has("shut"):
		return "The gates are locked down."
	if c.position().z < -18.0:
		job.open_for("gates", 5.0)
		return ""
	if pass_ok:
		job.open_for("gates", 6.0)
		return "The gate reads your pass and opens."
	return "The gates want a pass. Teo's watching them."


## What a crew member says on the phone that a check leans on later:
## `rules` are [who, words, flag]; a line to `who` with any of the words sets
## the job's flag. Returns the flag set, or "".
static func heard_on_phone(job: Job, c: CrewInfo, text: String, rules: Array) -> String:
	var rang: Dictionary = job.calls.get(c.id, {})
	if rang.is_empty():
		return ""
	var lower := " " + text.to_lower() + " "
	for r in rules:
		if str(rang.get("who", "")) == str(r[0]) and Job.any(lower, r[1]) and not job.flags.has(str(r[2])):
			job.flags[str(r[2])] = true
			return str(r[2])
	return ""


# --- Materials and walls ----------------------------------------------------------------------

func _more_mat(name: String, m: StandardMaterial3D) -> bool:
	match name:
		"terrazzo":
			_tex(m, "res://assets/textures/vantage/terrazzo", 2.0, true)
			m.roughness = 0.2
		"carpet_board":
			_tex(m, "res://assets/textures/vantage/carpet_board", 2.0)
			m.roughness = 0.95
		"limestone":
			_tex(m, "res://assets/textures/vantage/limestone", 2.0, true)
			m.roughness = 0.6
		"oak_slats":
			_tex(m, "res://assets/textures/vantage/oak_slats", 1.0, true)
			m.roughness = 0.55
		"facade":
			m.albedo_texture = load("res://assets/textures/vantage/tower_facade.png")
			m.albedo_color = Color(0.5, 0.5, 0.55)
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission_energy_multiplier = 0.8
			m.metallic = 0.4
			m.roughness = 0.12
			_world(m, 12.0)
		"city":
			m.albedo_color = Color(0.02, 0.02, 0.03)
			m.emission_enabled = true
			m.emission_texture = load("res://assets/textures/vantage/city_windows.png")
			m.emission_energy_multiplier = 1.1
			m.roughness = 0.6
			_world(m, 24.0)
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.5, 0.62, 0.68, 0.13)
			m.metallic = 0.25
			m.roughness = 0.03
			m.metallic_specular = 0.8
		"glass_frost":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.86, 0.9, 0.92, 0.62)
			m.roughness = 0.35
		"steel_black":
			m.albedo_color = Color(0.11, 0.12, 0.13)
			m.metallic = 0.7
			m.roughness = 0.38
		"steel_brushed":
			m.albedo_color = Color(0.66, 0.68, 0.7)
			m.metallic = 1.0
			m.roughness = 0.34
		"stone_pale":
			m.albedo_color = Color(0.8, 0.78, 0.73)
			m.roughness = 0.4
		"stone_dark":
			m.albedo_color = Color(0.1, 0.1, 0.11)
			m.roughness = 0.22
		"core_stone":
			# The lift lobbies' polished gray stone: dark, but not a hole.
			_tex(m, "res://assets/textures/vantage/limestone", 2.0, true)
			m.albedo_color = Color(0.46, 0.45, 0.44)
			m.roughness = 0.28
		"oak":
			m.albedo_color = Color(0.6, 0.45, 0.29)
			m.roughness = 0.5
		"lab_floor":
			m.albedo_color = Color(0.78, 0.81, 0.82)
			m.roughness = 0.28
		"lab_white":
			m.albedo_color = Color(0.88, 0.9, 0.9)
			m.roughness = 0.45
		"office_white":
			m.albedo_color = Color(0.84, 0.83, 0.8)
			m.roughness = 0.88
		"ceiling_white":
			m.albedo_color = Color(0.86, 0.86, 0.85)
			m.roughness = 0.92
		"paving":
			_tex(m, Kit.DOWNTOWN + "/T_Concrete", 3.0, true, true)
			m.albedo_color = Color(0.82, 0.8, 0.76)
		"roof":
			m.albedo_color = Color(0.07, 0.07, 0.08)
			m.roughness = 0.9
		"ground_far":
			m.albedo_color = Color(0.03, 0.03, 0.035)
			m.roughness = 0.95
		"light_strip":
			m.albedo_color = Color(0.9, 0.93, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.9, 0.95, 1.0)
			m.emission_energy_multiplier = 2.2
		"light_warm":
			m.albedo_color = Color(1.0, 0.9, 0.75)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.82, 0.6)
			m.emission_energy_multiplier = 2.4
		"crown":
			m.albedo_color = Color(0.7, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.55, 0.78, 1.0)
			m.emission_energy_multiplier = 3.0
		"led_red":
			m.albedo_color = Color(1.0, 0.1, 0.08)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.08, 0.05)
			m.emission_energy_multiplier = 4.0
		"sodium_glow":
			m.albedo_color = Color(1.0, 0.6, 0.3)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.55, 0.22)
			m.emission_energy_multiplier = 1.6
		"screen":
			m.albedo_color = Color(0.02, 0.03, 0.05)
			m.emission_enabled = true
			m.emission = Color(0.3, 0.5, 0.8)
			m.emission_energy_multiplier = 1.2
		"grass":
			m.albedo_color = Color(0.08, 0.13, 0.07)
			m.roughness = 0.95
		"rubber":
			m.albedo_color = Color(0.09, 0.09, 0.1)
			m.roughness = 0.9
		"paint_grey":
			m.albedo_color = Color(0.46, 0.48, 0.5)
			m.roughness = 0.75
		"safety_yellow":
			m.albedo_color = Color(0.9, 0.72, 0.1)
			m.roughness = 0.6
		_:
			return false
	return true


## Wall styles: "stone" (limestone panels over a dark plinth), "slats" (oak
## slats), "office" (white paint over an oak skirting), "lab" (white panels
## over a steel skirting), "core" (polished gray stone, the lift lobbies), "service"
## (gray paint, the plant room).
func _more_span(style: String, a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, _h: float) -> void:
	var skirt := {"stone": "stone_dark", "slats": "stone_dark", "office": "oak", "lab": "steel_brushed", "core": "steel_brushed", "service": "rubber"}.get(style, "stone_dark") as String
	var face := {"stone": "limestone", "slats": "oak_slats", "office": "office_white", "lab": "lab_white", "core": "core_stone", "service": "paint_grey"}.get(style, "office_white") as String
	if y0 < 0.12:
		_face(a, u, facing, s0, s1, y0, minf(y1, 0.12), _mat(skirt), 0.035)
	_face(a, u, facing, s0, s1, maxf(y0, 0.12), y1, _mat(face), 0.02)


func _more_wall_top(style: String, a: Vector2, u: Vector2, facing: Vector2, length: float, h: float) -> void:
	match style:
		"stone", "slats", "core":
			_face(a, u, facing, 0.0, length, h - 0.05, h, _mat("stone_dark"), 0.03)
		"lab", "office":
			_face(a, u, facing, 0.0, length, h - 0.04, h, _mat("ceiling_white"), 0.025)


## A curtain wall of glass on the room's side of the line `a`-`b`: panes, a
## mullion every `bay` metres, a sill and a head, and collision outside the
## line. `holes` are doorways ({at, w, h}).
func _curtain(a: Vector2, b: Vector2, facing: Vector2, h: float, holes: Array = [], bay := 1.5) -> void:
	var length := a.distance_to(b)
	var u := (b - a) / length
	var along_x := absf(u.x) > 0.5
	var cuts := []
	for hole in holes:
		var s := (float(hole.at) - (a.x if along_x else a.y)) * (signf(u.x) if along_x else signf(u.y))
		cuts.append([s - float(hole.w) * 0.5, s + float(hole.w) * 0.5, float(hole.h)])
	cuts.sort_custom(_by_start)
	var s0 := 0.0
	var spans := []
	for c in cuts:
		if c[0] > s0 + 0.01:
			spans.append([s0, c[0]])
		s0 = c[1]
	if length > s0 + 0.01:
		spans.append([s0, length])
	var glass := _mat("glass")
	var frame := _mat("steel_black")
	for sp in spans:
		_no_shadow(_face_glass(a, u, facing, sp[0], sp[1], 0.1, h - 0.12, glass))
		_wall_block(a, u, facing, sp[0], sp[1], 0.0, h + 0.5, 0.12)
		_face(a, u, facing, sp[0], sp[1], 0.0, 0.1, frame, 0.16, -0.08)
	for c in cuts:
		_no_shadow(_face_glass(a, u, facing, c[0], c[1], c[2] + 0.08, h - 0.12, glass))
		_wall_block(a, u, facing, c[0], c[1], c[2], h + 0.5, 0.12)
		_face(a, u, facing, c[0] - 0.04, c[1] + 0.04, c[2], c[2] + 0.08, frame, 0.16, -0.08)
	_face(a, u, facing, 0.0, length, h - 0.12, h, frame, 0.16, -0.08)
	var n := maxi(1, roundi(length / bay))
	for i in n + 1:
		var s := length * i / n
		var in_hole := false
		for c in cuts:
			if s > c[0] - 0.05 and s < c[1] + 0.05:
				in_hole = true
		if in_hole:
			continue
		_face(a, u, facing, maxf(s - 0.03, 0.0), minf(s + 0.03, length), 0.0, h, frame, 0.14, -0.07)
	for c in cuts:
		for e in [c[0], c[1]]:
			_face(a, u, facing, e - 0.03, e + 0.03, 0.0, h, frame, 0.14, -0.07)


## A pane of glass on a wall's line, for [method _curtain] and partitions.
func _face_glass(a: Vector2, u: Vector2, facing: Vector2, s0: float, s1: float, y0: float, y1: float, glass: Material) -> MeshInstance3D:
	var mid := a + u * (s0 + s1) * 0.5
	var size := Vector3(absf(u.x) * (s1 - s0) + absf(facing.x) * 0.024, y1 - y0, absf(u.y) * (s1 - s0) + absf(facing.y) * 0.024)
	return _slab(Vector3(mid.x, (y0 + y1) * 0.5, mid.y), size, glass)


## A floor you can stand on: the slab and its collision.
func _deck(r: Rect2, mat: String) -> void:
	_floor(r, mat)
	_solid(Vector3(r.get_center().x, -0.25, r.get_center().y), Vector3(r.size.x, 0.5, r.size.y))


## A row of recessed light panels in a ceiling, `h` up, along x from x0 to x1.
func _strips(x0: float, x1: float, z: float, h: float, mat := "light_strip") -> void:
	_slab(Vector3((x0 + x1) * 0.5, h - 0.01, z), Vector3(x1 - x0, 0.02, 0.18), _mat(mat))


static func _p(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


static func _face3(p: Vector3, dir: Vector2) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.y)), p)


static func _knot3(c: Vector3, n: int, r: float, turn := 0.4) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in n:
		var a := TAU * i / n + turn
		var p := c + Vector3(sin(a), 0.0, cos(a)) * r
		out.append(_face3(p, Vector2(c.x - p.x, c.z - p.z)))
	return out


# --- The ground floor -------------------------------------------------------------------------

func _ground() -> void:
	_in("outside")
	# Everything outside stands on y = 0 but the road, a kerb's height lower.
	_solid(Vector3(0.0, -0.25, KERB * 0.5 - 20.0), Vector3(180.0, 0.5, KERB + 40.0))
	_solid(Vector3(0.0, -0.4, (KERB + FAR_KERB) * 0.5), Vector3(180.0, 0.5, FAR_KERB - KERB))
	_solid(Vector3(0.0, -0.25, (FAR_KERB + ACROSS) * 0.5 + 1.0), Vector3(180.0, 0.5, ACROSS - FAR_KERB + 2.0))
	# Under the tower, so no gap between floors shows the sky.
	_slab(Vector3(0.0, -0.13, -16.0), Vector3(36.4, 0.1, 32.4), Kit.flat(Color(0.05, 0.05, 0.05)))


func _lobby() -> void:
	_in("lobby")
	var r := Rect2(-18.0, -18.0, 36.0, 18.0)
	_floor(r, "terrazzo")
	# A dark stone border round the floor and a mat at the door.
	for e in [Rect2(-18.0, -0.6, 36.0, 0.6), Rect2(-18.0, -18.0, 0.5, 18.0), Rect2(17.5, -18.0, 0.5, 18.0)]:
		_floor(e, "stone_dark", 0.004, 0.02)
	_floor(Rect2(-1.6, -2.6, 3.2, 2.2), "rubber", 0.008, 0.02)
	# The glass on three sides, the front doors in the middle.
	_curtain(Vector2(-18.0, 0.0), Vector2(18.0, 0.0), Vector2(0, -1), LOBBY_H, [{"at": 0.0, "w": 2.4, "h": 2.8}])
	_curtain(Vector2(-18.0, -18.0), Vector2(-18.0, 0.0), Vector2(1, 0), LOBBY_H)
	_curtain(Vector2(18.0, 0.0), Vector2(18.0, -18.0), Vector2(-1, 0), LOBBY_H)
	# The north wall: limestone, the plant room's door, the opening to the gates, the office's door.
	_wall("stone", Vector2(-18.0, -17.8), Vector2(18.0, -17.8), Vector2(0, 1), LOBBY_H,
			[{"at": -11.0, "w": 1.1, "h": 2.3}, {"at": 1.0, "w": 10.0, "h": CORE_H}, {"at": 12.0, "w": 1.1, "h": 2.3}])
	_sign("VANTAGE", Vector3(1.0, 5.6, -17.76), 0.0, 220, Color(0.86, 0.84, 0.8), 0.006)
	_sign("LIFTS", Vector3(1.0, 4.35, -17.76), 0.0, 48, Color(0.75, 0.73, 0.7))
	_sign("STAFF ONLY", Vector3(-11.0, 2.6, -17.76), 0.0, 30, Color(0.4, 0.38, 0.36))
	_sign("SECURITY", Vector3(12.0, 2.6, -17.76), 0.0, 30, Color(0.4, 0.38, 0.36))
	# A ceiling of dark oak slats, the ring of light over the middle.
	_ceiling(r, LOBBY_H, "oak_slats")
	_no_shadow(_m("vantage_ring_light", Vector3(0.0, LOBBY_H - 3.0, -9.0)))
	for x in [-12.0, -6.0, 6.0, 12.0]:
		for z in [-4.0, -14.0]:
			_slab(Vector3(x, LOBBY_H - 0.02, z), Vector3(0.36, 0.03, 0.36), _mat("light_strip"))
	# Two trees in planters by the doors, the sculpture under the ring.
	for x in [-5.0, 5.0]:
		_m("vantage_planter", Vector3(x, 0.0, -3.6))
		_solid(Vector3(x, 0.45, -3.6), Vector3(1.3, 0.9, 1.3))
	_box("vantage_sculpture", Vector3(-6.4, 0.0, -10.0))
	# Benches round the middle, a lounge by each wall of glass.
	for b in [[Vector3(-4.2, 0.0, -6.6), 0.0], [Vector3(4.2, 0.0, -6.6), 0.0], [Vector3(-9.4, 0.0, -10.0), PI * 0.5]]:
		_box("vantage_bench", b[0], b[1])
	for side in [-1.0, 1.0]:
		var wx: float = 18.0 * side
		_box("vantage_sofa", Vector3(wx - side * 1.05, 0.0, -5.0), -side * PI * 0.5)
		_box("vantage_coffee_table", Vector3(wx - side * 2.3, 0.0, -5.0), PI * 0.5)
		_box("vantage_sofa", Vector3(wx - side * 3.6, 0.0, -5.0), side * PI * 0.5)
		_box("vantage_plant", Vector3(wx - side * 1.0, 0.0, -2.0))
	# Light: the ring (the lobby's one shadow) and a wash from each corner.
	var ring := _omni(Vector3(0.0, 6.2, -9.0), COOL, 3.0, 20.0, true)
	ring.shadow_bias = 0.08
	for p in [Vector3(-12.0, 7.0, -5.0), Vector3(12.0, 7.0, -5.0), Vector3(-12.0, 7.0, -14.0), Vector3(12.0, 7.0, -14.0)]:
		_omni(p, WARM, 1.0, 11.0)
	_omni(Vector3(1.0, 3.4, -15.6), WARM, 0.9, 7.0)
	_probe(r, LOBBY_H, Color(0.38, 0.36, 0.34), 0.35)


## The speed gates across the lift lobby's opening, and Teo's podium.
func _gates() -> void:
	_in("lobby")
	for x in [-3.85, -1.85, 0.15, 2.15, 4.15]:
		_m("vantage_gate", Vector3(x, 0.0, -18.0))
		_solid(Vector3(x, 0.9, -18.0), Vector3(0.26, 1.8, 1.6))
	# The lanes Teo's gate doesn't open: their flaps stay shut.
	for x in [-2.85, -0.85, 1.15]:
		for side in [-1.0, 1.0]:
			var f := _m("vantage_gate_flap", Vector3(x + side * 0.88, 0.0, -18.0), 0.0 if side > 0 else PI, Vector3(0.86, 1.96, 1.0))
			_no_shadow(f)
		_solid(Vector3(x, 0.9, -18.0), Vector3(1.76, 1.8, 0.06))
	# Glass from the last gate to the wall.
	_face_glass(Vector2(4.27, -18.0), Vector2(1, 0), Vector2(0, 1), 0.0, 1.73, 0.05, 1.8, _mat("glass"))
	_slab(Vector3(5.135, 1.82, -18.0), Vector3(1.73, 0.04, 0.05), _mat("steel_brushed"))
	_solid(Vector3(5.135, 0.9, -18.0), Vector3(1.73, 1.8, 0.1))
	_box("vantage_gate_desk", Vector3(5.0, 0.0, -15.95))
	_slab(Vector3(1.0, 0.004, -18.0), Vector3(10.0, 0.01, 2.4), _mat("stone_dark"))


func _front_desk() -> void:
	_in("lobby")
	_box("vantage_front_desk", Vector3(14.6, 0.0, -9.0), -PI * 0.5)
	# A wall of dark stone behind Dana, with the name on it.
	_slab(Vector3(17.15, 1.7, -9.0), Vector3(0.3, 3.4, 7.0), _mat("stone_dark"))
	_solid(Vector3(17.15, 1.7, -9.0), Vector3(0.3, 3.4, 7.0))
	_sign("VANTAGE", Vector3(16.98, 2.55, -9.0), -PI * 0.5, 96, Color(0.85, 0.75, 0.55))
	_sign("Visitors, please sign in", Vector3(16.98, 2.05, -9.0), -PI * 0.5, 28, Color(0.6, 0.58, 0.55))
	_slab(Vector3(16.99, 3.05, -9.0), Vector3(0.02, 0.03, 6.6), _mat("light_warm"))
	_omni(Vector3(14.8, 2.8, -9.0), WARM, 0.9, 5.5)


func _cafe() -> void:
	_in("lobby")
	_box("vantage_cafe_counter", Vector3(-15.0, 0.0, -14.6))
	_box("vantage_cafe_back", Vector3(-15.0, 0.0, -17.45))
	_sign("CAFE", Vector3(-15.0, 3.3, -17.76), 0.0, 64, Color(0.9, 0.75, 0.5))
	for x in [-16.2, -15.0, -13.8]:
		_slab(Vector3(x, 3.0, -14.6), Vector3(0.012, 6.0, 0.012), _mat("steel_black"))
		_slab(Vector3(x, 2.5, -14.6), Vector3(0.22, 0.12, 0.22), _mat("light_warm"))
	_floor(Rect2(-17.5, -13.6, 6.4, 7.4), "oak", 0.006, 0.02)
	for t in [Vector2(-16.0, -11.4), Vector2(-13.0, -11.4), Vector2(-16.0, -8.0), Vector2(-13.0, -8.0)]:
		_box("vantage_cafe_table", _v(t))
		_box("vantage_cafe_chair", _v(t + Vector2(-0.62, 0.0)), PI * 0.5)
		_box("vantage_cafe_chair", _v(t + Vector2(0.62, 0.0)), -PI * 0.5)
	_omni(Vector3(-15.0, 2.4, -14.8), CANDLE, 1.0, 5.0)
	_omni(Vector3(-14.5, 2.6, -9.6), WARM, 0.7, 6.0)


## A lift lobby, the same on every floor: dark stone, lift A (out of
## service) and lift B with its car and call panel.
func _core(zone: String, fl: String) -> void:
	_in(zone)
	var r := Rect2(-4.0, -32.0, 10.0, 14.0)
	_deck(Rect2(-4.0, -28.0, 10.0, 10.0), "terrazzo")
	_ceiling(Rect2(-4.0, -28.0, 10.0, 10.0), CORE_H, "ceiling_white")
	var west_holes := []
	if fl == "r":
		west_holes = [{"at": -23.0, "w": 1.1, "h": 2.3}]
	elif fl == "b":
		west_holes = [{"at": -20.0, "w": 1.1, "h": 2.3}]
	_wall("core", Vector2(-3.8, -28.0), Vector2(-3.8, -18.0), Vector2(1, 0), CORE_H, west_holes)
	_wall("core", Vector2(5.8, -18.0), Vector2(5.8, -28.0), Vector2(-1, 0), CORE_H)
	_wall("core", Vector2(-4.0, -27.8), Vector2(6.0, -27.8), Vector2(0, 1), CORE_H,
			[{"at": -0.5, "w": 1.2, "h": 2.3}, {"at": 3.5, "w": 1.2, "h": 2.3}])
	# Upstairs the lobby has a south wall with a way through; downstairs it opens onto the gates.
	if fl == "r":
		_wall("core", Vector2(6.0, -18.2), Vector2(-4.0, -18.2), Vector2(0, -1), CORE_H, [{"at": 1.0, "w": 4.0, "h": 2.7}])
		_sign("LEVEL 9  RESEARCH", Vector3(-2.2, 2.9, -27.76), 0.0, 40, Color(0.75, 0.73, 0.7))
		_sign("HIGH SECURITY AREA\nNo phones, radios or earpieces\nbeyond this point", Vector3(4.6, 2.2, -18.17), PI, 30, Color(0.95, 0.75, 0.3))
	elif fl == "b":
		_wall("core", Vector2(6.0, -18.2), Vector2(-4.0, -18.2), Vector2(0, -1), CORE_H, [{"at": 1.0, "w": 6.0, "h": 3.0}])
		_sign("LEVEL 12", Vector3(-2.2, 2.9, -27.76), 0.0, 40, Color(0.75, 0.73, 0.7))
	else:
		_sign("LIFTS  G - 12", Vector3(-2.2, 2.9, -27.76), 0.0, 40, Color(0.75, 0.73, 0.7))
	# Lift A: shut, and has been for weeks.
	_m("vantage_lift_frame", Vector3(-0.5, 0.0, -27.8))
	for side in [-1.0, 1.0]:
		_m("vantage_lift_leaf", Vector3(-0.5 + (0.6 if side > 0 else 0.0), 0.0, -28.0), 0.0 if side > 0 else PI)
	_solid(Vector3(-0.5, 1.15, -28.0), Vector3(1.2, 2.3, 0.1))
	_sign("Car one is out of service.\nSorry for any trouble.", Vector3(-0.5, 1.55, -27.95), 0.0, 22, Color(0.95, 0.85, 0.5))
	_m("vantage_call_panel", Vector3(-1.5, 0.95, -27.78))
	# Lift B: the frame, the car behind its doors, the call panel.
	_m("vantage_lift_frame", Vector3(3.5, 0.0, -27.8))
	_m("vantage_lift_car", Vector3(3.5, 0.0, -28.2))
	_solid(Vector3(2.15, 1.3, -29.5), Vector3(0.1, 2.6, 2.6))
	_solid(Vector3(4.85, 1.3, -29.5), Vector3(0.1, 2.6, 2.6))
	_solid(Vector3(3.5, 1.3, -30.85), Vector3(2.8, 2.6, 0.1))
	_omni(Vector3(3.5, 2.3, -29.5), COOL, 0.8, 3.5)
	_use("lift_call_" + fl, Vector3(5.0, 0.85, -27.72), Vector3(0.3, 0.5, 0.16), "vantage_call_panel")
	# A long bench and a plant.
	_box("vantage_bench", Vector3(-3.4, 0.0, -22.0), PI * 0.5)
	_box("vantage_plant", Vector3(-3.2, 0.0, -26.8))
	for z in [-20.5, -25.0]:
		_strips(-2.0, 4.0, z, CORE_H)
		_omni(Vector3(1.0, CORE_H - 0.4, z), WARM if fl == "g" else COOL, 0.9, 7.0)
	_probe(Rect2(-4.0, -28.0, 10.0, 10.0), CORE_H, Color(0.32, 0.31, 0.3), 0.3)


func _office() -> void:
	_in("office")
	var r := Rect2(6.0, -28.0, 12.0, 10.0)
	_floor(r, "carpet_office")
	_ceiling(r, BACK_H, "ceiling_white")
	_wall("office", Vector2(6.2, -27.8), Vector2(6.2, -18.2), Vector2(1, 0), BACK_H)
	_wall("office", Vector2(17.8, -18.2), Vector2(17.8, -27.8), Vector2(-1, 0), BACK_H)
	_wall("office", Vector2(6.0, -27.8), Vector2(18.0, -27.8), Vector2(0, 1), BACK_H)
	_wall("office", Vector2(18.0, -18.2), Vector2(6.0, -18.2), Vector2(0, -1), BACK_H, [{"at": 12.0, "w": 1.1, "h": 2.3}])
	# The monitors, Renata's desk, the files and the safe.
	_box("cctv_monitors", Vector3(11.0, 0.0, -27.4))
	_box("vantage_office_desk", Vector3(8.6, 0.0, -23.6), PI * 0.5)
	_box("office_chair", Vector3(7.7, 0.0, -23.6), PI * 0.5)
	_m("desk_lamp", Vector3(8.5, 0.76, -24.1))
	for z in [-26.9, -26.3]:
		_box("filing_cabinet", Vector3(6.55, 0.0, z), PI * 0.5)
	_box("vantage_safe", Vector3(17.2, 0.0, -26.9), -PI * 0.5)
	_m("notice_board", Vector3(17.8, 1.2, -21.6), -PI * 0.5)
	clocks.append(_m("wall_clock", Vector3(14.6, 2.3, -27.8)))
	_box("locker_bench", Vector3(17.2, 0.0, -24.8), PI * 0.5)
	_m("cctv_camera", Vector3(17.6, 3.3, -18.4), -PI * 0.75)
	for z in [-21.0, -25.4]:
		_strips(8.0, 16.0, z, BACK_H)
		_omni(Vector3(12.0, BACK_H - 0.4, z), COOL, 0.7, 7.0)
	_omni(Vector3(11.0, 1.4, -26.4), Color(0.6, 0.75, 1.0), 0.6, 3.5)
	_probe(r, BACK_H, Color(0.3, 0.32, 0.34), 0.3)


func _plant() -> void:
	_in("plant")
	var r := Rect2(-18.0, -28.0, 14.0, 10.0)
	_floor(r, "concrete")
	_ceiling(r, BACK_H, "ceiling_dark")
	_wall("service", Vector2(-17.8, -18.2), Vector2(-17.8, -27.8), Vector2(1, 0), BACK_H)
	_wall("service", Vector2(-4.2, -27.8), Vector2(-4.2, -18.2), Vector2(-1, 0), BACK_H)
	_wall("service", Vector2(-18.0, -27.8), Vector2(-4.0, -27.8), Vector2(0, 1), BACK_H)
	_wall("service", Vector2(-4.0, -18.2), Vector2(-18.0, -18.2), Vector2(0, -1), BACK_H, [{"at": -11.0, "w": 1.1, "h": 2.3}])
	# The air handlers along the west wall, pipes overhead.
	for z in [-26.0, -22.4]:
		_slab(Vector3(-16.4, 1.1, z), Vector3(2.4, 2.2, 3.0), _mat("paint_grey"))
		_slab(Vector3(-15.18, 1.6, z), Vector3(0.04, 0.6, 1.6), _mat("steel_brushed"))
		_solid(Vector3(-16.4, 1.1, z), Vector3(2.4, 2.2, 3.0))
		_box("Prop_ACUnit", Vector3(-16.4, 2.2, z), PI * 0.5)
	for y in [3.05, 3.25]:
		_slab(Vector3(-11.0, y, -27.2), Vector3(13.6, 0.18, 0.18), _mat("steel_brushed"))
	_slab(Vector3(-13.0, 3.15, -22.0), Vector3(0.24, 0.24, 9.6), _mat("safety_yellow"))
	# Stan's desk of building screens against the north wall, his shelves of parts.
	_m("vantage_screen_wall", Vector3(-9.0, 1.0, -27.8))
	_box("vantage_office_desk", Vector3(-9.0, 0.0, -26.9))
	_box("office_chair", Vector3(-9.0, 0.0, -26.0), PI)
	for x in [-6.0, -4.8]:
		_box("vantage_shelves", Vector3(x - 0.05, 0.0, -27.4))
	_slab(Vector3(-4.24, 1.6, -21.0), Vector3(0.06, 0.6, 0.45), _mat("steel_black"))
	_sign("LIFT KEYS", Vector3(-4.28, 2.0, -21.0), -PI * 0.5, 22, Color(0.9, 0.85, 0.6))
	_m("wheelie_bin", Vector3(-5.0, 0.0, -19.0))
	_solid(Vector3(-5.0, 0.53, -19.0), Vector3(0.66, 1.06, 0.82))
	for z in [-20.6, -25.6]:
		_strips(-15.0, -6.0, z, BACK_H)
		_omni(Vector3(-10.0, BACK_H - 0.4, z), COOL, 0.75, 7.5)
	_omni(Vector3(-9.0, 1.6, -27.0), Color(0.5, 0.7, 1.0), 0.6, 3.0)
	_probe(r, BACK_H, Color(0.3, 0.31, 0.32), 0.3)


# --- The research floor (level 9) -------------------------------------------------------------

func _break_room() -> void:
	_in("break_room")
	var r := Rect2(-18.0, -28.0, 14.0, 10.0)
	_deck(r, "lab_floor")
	_ceiling(r, R_H, "ceiling_white")
	_curtain(Vector2(-18.0, -28.0), Vector2(-18.0, -18.0), Vector2(1, 0), R_H)
	_wall("office", Vector2(-4.2, -27.8), Vector2(-4.2, -18.2), Vector2(-1, 0), R_H, [{"at": -23.0, "w": 1.1, "h": 2.3}])
	_wall("office", Vector2(-18.0, -27.8), Vector2(-4.0, -27.8), Vector2(0, 1), R_H)
	_wall("office", Vector2(-4.0, -18.2), Vector2(-18.0, -18.2), Vector2(0, -1), R_H)
	# The kitchenette along the north wall, a table, a sofa by the window.
	_box("vantage_pantry_counter", Vector3(-11.0, 0.0, -27.45))
	_box("vantage_fridge", Vector3(-13.0, 0.0, -27.4))
	_box("vantage_cafe_table", Vector3(-10.4, 0.0, -22.4))
	for d in [Vector2(-0.62, 0.0), Vector2(0.62, 0.0)]:
		_box("vantage_cafe_chair", _v(Vector2(-10.4, -22.4) + d), -signf(d.x) * PI * 0.5)
	_box("vantage_sofa", Vector3(-16.6, 0.0, -22.6), PI * 0.5)
	_box("vantage_coffee_table", Vector3(-15.2, 0.0, -22.6), PI * 0.5)
	_box("vantage_plant", Vector3(-17.0, 0.0, -19.0))
	_m("notice_board", Vector3(-7.0, 1.2, -18.2), PI)
	clocks.append(_m("wall_clock", Vector3(-7.0, 2.6, -27.8)))
	for z in [-20.6, -25.4]:
		_strips(-15.0, -7.0, z, R_H)
		_omni(Vector3(-11.0, R_H - 0.4, z), WARM, 0.8, 7.5)
	_probe(r, R_H, Color(0.34, 0.33, 0.32), 0.3)


func _checkpoint() -> void:
	_in("checkpoint")
	var r := Rect2(-4.0, -18.0, 10.0, 6.0)
	_deck(r, "terrazzo")
	_ceiling(r, R_H, "ceiling_white")
	_wall("core", Vector2(-3.8, -18.0), Vector2(-3.8, -12.0), Vector2(1, 0), R_H)
	_wall("core", Vector2(5.8, -12.0), Vector2(5.8, -18.0), Vector2(-1, 0), R_H)
	_wall("core", Vector2(-4.0, -17.8), Vector2(6.0, -17.8), Vector2(0, 1), R_H, [{"at": 1.0, "w": 4.0, "h": 2.7}])
	# The glass between the checkpoint and the lab, the secure door in it.
	_partition(Vector2(-4.0, -12.0), Vector2(6.0, -12.0), R_H, [{"at": 1.0, "w": 1.6, "h": 2.4}])
	# Bram's desk, the scanner arch in front of the door, the phone lockers.
	_box("vantage_check_desk", Vector3(3.6, 0.0, -15.6), PI)
	_m("vantage_scanner", Vector3(1.0, 0.0, -12.95))
	for side in [-1.0, 1.0]:
		_solid(Vector3(1.0 + side * 0.55, 1.15, -12.95), Vector3(0.2, 2.3, 0.6))
	_box("lockers", Vector3(-3.5, 0.0, -15.0), PI * 0.5)
	_sign("PHONES AND RADIOS", Vector3(-3.76, 2.2, -15.0), PI * 0.5, 22, Color(0.95, 0.75, 0.3))
	_m("cctv_camera", Vector3(5.6, 3.6, -17.6), PI * 0.75)
	_strips(-2.0, 4.0, -15.0, R_H)
	_omni(Vector3(1.0, R_H - 0.4, -15.0), COOL, 1.6, 8.0)
	_omni(Vector3(-2.4, R_H - 0.5, -15.0), COOL, 0.7, 5.0)
	_omni(Vector3(1.0, 2.5, -13.3), Color(0.5, 1.0, 0.6), 0.25, 2.5)
	_probe(r, R_H, Color(0.3, 0.32, 0.34), 0.4)


## A glass wall between two rooms on the same line, with doorways: panes,
## a frame and collision down the middle.
func _partition(a: Vector2, b: Vector2, h: float, holes: Array) -> void:
	var length := a.distance_to(b)
	var u := (b - a) / length
	var along_x := absf(u.x) > 0.5
	var facing := Vector2(-u.y, u.x)
	var s0 := 0.0
	var glass := _mat("glass")
	var frame := _mat("steel_black")
	var cuts := []
	for hole in holes:
		var s := (float(hole.at) - (a.x if along_x else a.y)) * (signf(u.x) if along_x else signf(u.y))
		cuts.append([s - float(hole.w) * 0.5, s + float(hole.w) * 0.5, float(hole.h)])
	var spans := []
	for c in cuts:
		spans.append([s0, c[0]])
		s0 = c[1]
	spans.append([s0, length])
	for sp in spans:
		if sp[1] - sp[0] < 0.01:
			continue
		_no_shadow(_face_glass(a, u, facing, sp[0], sp[1], 0.05, h, glass))
		var mid: Vector2 = a + u * (float(sp[0]) + float(sp[1])) * 0.5
		_solid(Vector3(mid.x, h * 0.5, mid.y), Vector3(absf(u.x) * (sp[1] - sp[0]) + absf(facing.x) * 0.1, h, absf(u.y) * (sp[1] - sp[0]) + absf(facing.y) * 0.1))
		_face(a, u, facing, sp[0], sp[1], 0.0, 0.05, frame, 0.08, -0.04)
		# A frosted band at eye height, as office glass has.
		_face(a, u, facing, sp[0], sp[1], 1.2, 1.5, _mat("glass_frost"), 0.03, -0.015)
		var n := maxi(1, roundi((sp[1] - sp[0]) / 1.5))
		for i in n + 1:
			var s: float = sp[0] + (sp[1] - sp[0]) * i / n
			_face(a, u, facing, s - 0.025, s + 0.025, 0.0, h, frame, 0.08, -0.04)
	for c in cuts:
		_no_shadow(_face_glass(a, u, facing, c[0], c[1], c[2] + 0.06, h, glass))
		var mid: Vector2 = a + u * (float(c[0]) + float(c[1])) * 0.5
		_solid(Vector3(mid.x, (c[2] + h) * 0.5 + 0.25, mid.y), Vector3(absf(u.x) * (c[1] - c[0]) + absf(facing.x) * 0.1, h - c[2] + 0.5, absf(u.y) * (c[1] - c[0]) + absf(facing.y) * 0.1))
		_face(a, u, facing, c[0] - 0.03, c[1] + 0.03, c[2], c[2] + 0.06, frame, 0.1, -0.05)
	_face(a, u, facing, 0.0, length, h - 0.05, h, frame, 0.1, -0.05)


func _lab() -> void:
	_in("lab")
	var r := Rect2(-8.0, -12.0, 16.0, 12.0)
	_deck(r, "lab_floor")
	_ceiling(r, R_H, "ceiling_white")
	_curtain(Vector2(-8.0, 0.0), Vector2(8.0, 0.0), Vector2(0, -1), R_H)
	_wall("lab", Vector2(-7.8, -12.0), Vector2(-7.8, 0.0), Vector2(1, 0), R_H, [{"at": -8.0, "w": 1.1, "h": 2.3}])
	# The glass to the cutting room, its door and keypad.
	_partition(Vector2(8.0, 0.0), Vector2(8.0, -12.0), R_H, [{"at": -8.5, "w": 1.2, "h": 2.4}])
	_use("cutting_pad", Vector3(7.88, 1.2, -9.55), Vector3(0.16, 0.24, 0.2), "keypad", -PI * 0.5)
	_sign("GEM ROOM\nAuthorized staff only", Vector3(7.93, 2.65, -8.5), -PI * 0.5, 26, Color(0.25, 0.27, 0.3))
	# The benches, a fume hood, shelves and a printer.
	for b in [Vector3(-3.6, 0.0, -7.2), Vector3(-3.6, 0.0, -3.0), Vector3(3.6, 0.0, -2.6)]:
		_box("vantage_lab_bench", b)
	for s in [Vector3(-5.0, 0.0, -6.2), Vector3(-2.2, 0.0, -6.2), Vector3(-3.6, 0.0, -2.0)]:
		_box("vantage_lab_stool", s)
	_box("vantage_fume_hood", Vector3(-7.3, 0.0, -3.0), PI * 0.5)
	_box("vantage_shelves", Vector3(-7.45, 0.0, -10.6), PI * 0.5)
	_box("vantage_printer", Vector3(6.0, 0.0, -11.4))
	_m("cctv_camera", Vector3(7.6, 3.6, -11.6), -PI * 0.75)
	for z in [-9.0, -5.0, -1.5]:
		_strips(-6.0, 6.0, z, R_H)
	var main := _omni(Vector3(0.0, R_H - 0.5, -6.0), COOL, 2.2, 13.0, true)
	main.shadow_bias = 0.08
	for p in [Vector3(-5.0, R_H - 0.5, -3.0), Vector3(5.0, R_H - 0.5, -9.0)]:
		_omni(p, COOL, 0.8, 8.0)
	_probe(r, R_H, Color(0.34, 0.36, 0.38), 0.35)


func _cutting() -> void:
	_in("cutting")
	var r := Rect2(8.0, -12.0, 10.0, 12.0)
	_deck(r, "lab_floor")
	_ceiling(r, R_H, "ceiling_white")
	_curtain(Vector2(8.0, 0.0), Vector2(18.0, 0.0), Vector2(0, -1), R_H)
	_curtain(Vector2(18.0, 0.0), Vector2(18.0, -12.0), Vector2(-1, 0), R_H)
	_wall("lab", Vector2(8.0, -11.8), Vector2(18.0, -11.8), Vector2(0, 1), R_H)
	# The scaife (the cutter's wheel), a bench, the safe, and the Rose on her plinth.
	_box("vantage_scaife", Vector3(13.6, 0.0, -4.6))
	_box("vantage_lab_stool", Vector3(13.6, 0.0, -3.7))
	_box("vantage_lab_bench", Vector3(15.6, 0.0, -1.2))
	_box("vantage_safe", Vector3(17.3, 0.0, -11.0), -PI * 0.5)
	_box("vantage_rose_plinth", Vector3(15.4, 0.0, -9.6))
	var cradle := _use("cradle", Vector3(15.4, 1.06, -9.6), Vector3(0.24, 0.24, 0.24), "vantage_rose")
	cradle.set_meta("use", "item:rose")
	_sign("NO ENTRY WITHOUT A LAB ESCORT", Vector3(9.0, 2.7, -11.78), 0.0, 24, Color(0.25, 0.27, 0.3))
	_strips(10.0, 16.0, -6.0, R_H)
	_omni(Vector3(13.0, R_H - 0.5, -5.0), COOL, 1.3, 9.0)
	_spot(Vector3(15.4, R_H - 0.1, -8.4), Vector3(15.4, 1.1, -9.6), Color(1.0, 0.92, 0.95), 4.0, 6.0, 18.0)
	_omni(Vector3(13.6, 1.8, -4.6), Color(1.0, 0.95, 0.85), 0.5, 2.5)
	_probe(r, R_H, Color(0.34, 0.35, 0.37), 0.35)


func _lab_office() -> void:
	_in("lab_office")
	var r := Rect2(-18.0, -12.0, 10.0, 12.0)
	_deck(r, "carpet_office")
	_ceiling(r, R_H, "ceiling_white")
	_curtain(Vector2(-18.0, 0.0), Vector2(-8.0, 0.0), Vector2(0, -1), R_H)
	_curtain(Vector2(-18.0, -12.0), Vector2(-18.0, 0.0), Vector2(1, 0), R_H)
	_wall("office", Vector2(-18.0, -11.8), Vector2(-8.0, -11.8), Vector2(0, 1), R_H)
	_wall("office", Vector2(-8.2, 0.0), Vector2(-8.2, -12.0), Vector2(-1, 0), R_H, [{"at": -8.0, "w": 1.1, "h": 2.3}])
	# Margot's desk facing the door, shelves of reports, a sofa by the glass.
	_box("vantage_office_desk", Vector3(-13.2, 0.0, -6.4), PI * 0.5)
	_box("office_chair", Vector3(-14.3, 0.0, -4.9), PI * 0.7)
	_m("desk_lamp", Vector3(-13.3, 0.76, -6.9))
	for x in [-16.0, -14.6]:
		_box("vantage_shelves", Vector3(x, 0.0, -11.4))
	_box("filing_cabinet", Vector3(-12.6, 0.0, -11.3))
	_box("vantage_sofa", Vector3(-16.9, 0.0, -2.8), PI * 0.5)
	_box("vantage_plant", Vector3(-9.0, 0.0, -1.0))
	_strips(-16.0, -10.0, -6.0, R_H, "light_warm")
	_omni(Vector3(-13.0, R_H - 0.5, -6.0), WARM, 1.0, 8.0)
	_omni(Vector3(-13.3, 1.15, -6.9), CANDLE, 0.4, 2.5)
	_probe(r, R_H, Color(0.36, 0.33, 0.3), 0.3)


# --- The board floor (level 12) ---------------------------------------------------------------

func _assistants() -> void:
	_in("assist")
	var r := Rect2(-4.0, -18.0, 10.0, 18.0)
	_deck(r, "carpet_board")
	_ceiling(r, B_H, "ceiling_white")
	_curtain(Vector2(-4.0, 0.0), Vector2(6.0, 0.0), Vector2(0, -1), B_H)
	_wall("slats", Vector2(-3.8, -18.0), Vector2(-3.8, 0.0), Vector2(1, 0), B_H, [{"at": -6.0, "w": 1.8, "h": 2.5}])
	_wall("slats", Vector2(5.8, 0.0), Vector2(5.8, -18.0), Vector2(-1, 0), B_H, [{"at": -6.0, "w": 1.1, "h": 2.3}])
	_wall("slats", Vector2(6.0, -17.8), Vector2(-4.0, -17.8), Vector2(0, 1), B_H, [{"at": 1.0, "w": 6.0, "h": 3.0}])
	_sign("MR HOLT", Vector3(5.77, 2.75, -6.0), -PI * 0.5, 30, Color(0.85, 0.75, 0.55))
	_sign("BOARDROOM", Vector3(-3.77, 2.95, -6.0), PI * 0.5, 30, Color(0.85, 0.75, 0.55))
	# Noor's desk facing the lifts, two more desks by the window, a sofa to wait on.
	_box("vantage_office_desk", Vector3(1.0, 0.0, -13.0), PI)
	_box("office_chair", Vector3(2.3, 0.0, -11.7), PI * 0.8)
	_m("desk_lamp", Vector3(1.5, 0.76, -13.2))
	for x in [-1.6, 3.6]:
		_box("vantage_office_desk", Vector3(x, 0.0, -2.2))
		_box("office_chair", Vector3(x, 0.0, -3.1), PI)
	_box("vantage_sofa", Vector3(5.2, 0.0, -14.6), -PI * 0.5)
	_box("vantage_plant", Vector3(-3.2, 0.0, -16.9))
	_box("vantage_printer", Vector3(5.3, 0.0, -10.2), -PI * 0.5)
	for z in [-15.0, -10.0, -4.0]:
		_strips(-2.0, 4.0, z, B_H)
	for z in [-14.0, -5.0]:
		_omni(Vector3(1.0, B_H - 0.5, z), WARM, 1.0, 8.5)
	_probe(r, B_H, Color(0.34, 0.32, 0.3), 0.3)


func _boardroom() -> void:
	_in("boardroom")
	var r := Rect2(-18.0, -14.0, 14.0, 14.0)
	_deck(r, "carpet_board")
	_ceiling(r, B_H, "oak_slats")
	_curtain(Vector2(-18.0, 0.0), Vector2(-4.0, 0.0), Vector2(0, -1), B_H)
	_curtain(Vector2(-18.0, -14.0), Vector2(-18.0, 0.0), Vector2(1, 0), B_H)
	_wall("slats", Vector2(-18.0, -13.8), Vector2(-4.0, -13.8), Vector2(0, 1), B_H, [{"at": -8.0, "w": 1.1, "h": 2.3}])
	_wall("slats", Vector2(-4.2, 0.0), Vector2(-4.2, -14.0), Vector2(-1, 0), B_H, [{"at": -6.0, "w": 1.8, "h": 2.5}])
	# The long table and its chairs, the head at the west end, the city beyond.
	_box("vantage_board_table", Vector3(-11.0, 0.0, -7.0))
	# The chairs block at seat height only, so the board can sit in them.
	for i in 4:
		var x := -14.0 + i * 2.5
		_chair(Vector3(x, 0.0, -8.6), 0.0)
		_chair(Vector3(x, 0.0, -5.4), PI)
	_chair(Vector3(-15.95, 0.0, -7.0), PI * 0.5)
	_chair(Vector3(-6.05, 0.0, -7.0), -PI * 0.5)
	_box("vantage_sideboard", Vector3(-13.0, 0.0, -13.5))
	_m("vantage_screen_wall", Vector3(-4.2, 1.0, -10.6), -PI * 0.5)
	_sign("PROJECT ROSE\nCutting plan", Vector3(-4.24, 1.75, -10.6), -PI * 0.5, 34, Color(0.8, 0.88, 1.0))
	_box("vantage_plant", Vector3(-17.1, 0.0, -13.0))
	for x in [-13.4, -8.6]:
		_no_shadow(_m("vantage_ceiling_light", Vector3(x, B_H - 0.6, -7.0)))
	var main := _omni(Vector3(-11.0, B_H - 0.9, -7.0), WARM, 3.0, 13.0, true)
	main.shadow_bias = 0.08
	# Light over the table itself, and the corners.
	_spot(Vector3(-11.0, B_H - 0.1, -7.0), Vector3(-11.0, 0.8, -7.0), WARM, 2.5, 6.0, 55.0)
	_omni(Vector3(-6.0, B_H - 0.5, -12.0), WARM, 0.9, 7.0)
	_omni(Vector3(-16.0, B_H - 0.5, -2.0), WARM, 0.8, 7.0)
	_probe(r, B_H, Color(0.36, 0.33, 0.3), 0.4)


## A board chair, solid to its seat.
func _chair(at: Vector3, yaw: float) -> void:
	_m("vantage_board_chair", at, yaw)
	_solid_turned(at + Vector3(0.0, 0.25, 0.0), Vector3(0.62, 0.5, 0.62), yaw)


func _pantry() -> void:
	_in("pantry")
	var r := Rect2(-12.0, -22.0, 8.0, 8.0)
	_deck(r, "tile_white")
	_ceiling(r, B_H, "ceiling_white")
	_wall("lab", Vector2(-11.8, -14.0), Vector2(-11.8, -22.0), Vector2(1, 0), B_H)
	_wall("lab", Vector2(-12.0, -21.8), Vector2(-4.0, -21.8), Vector2(0, 1), B_H)
	_wall("lab", Vector2(-4.2, -22.0), Vector2(-4.2, -14.0), Vector2(-1, 0), B_H, [{"at": -20.0, "w": 1.1, "h": 2.3}])
	_wall("lab", Vector2(-4.0, -14.2), Vector2(-12.0, -14.2), Vector2(0, -1), B_H, [{"at": -8.0, "w": 1.1, "h": 2.3}])
	# The counter and the coffee, the fridge, the trolley ready to go in.
	_box("vantage_pantry_counter", Vector3(-8.6, 0.0, -21.45))
	_box("vantage_fridge", Vector3(-11.25, 0.0, -21.3))
	_box("vantage_trolley", Vector3(-10.6, 0.0, -15.2))
	_box("vantage_shelves", Vector3(-11.45, 0.0, -18.6), PI * 0.5)
	_strips(-11.0, -5.0, -18.0, B_H)
	_omni(Vector3(-8.0, B_H - 0.5, -18.0), Color(0.98, 0.95, 0.9), 1.0, 7.0)
	_probe(r, B_H, Color(0.34, 0.34, 0.33), 0.3)


func _founder() -> void:
	_in("founder")
	var r := Rect2(6.0, -14.0, 12.0, 14.0)
	_deck(r, "carpet_board")
	_ceiling(r, B_H, "oak_slats")
	_curtain(Vector2(6.0, 0.0), Vector2(18.0, 0.0), Vector2(0, -1), B_H)
	_curtain(Vector2(18.0, 0.0), Vector2(18.0, -14.0), Vector2(-1, 0), B_H)
	_wall("slats", Vector2(6.0, -13.8), Vector2(18.0, -13.8), Vector2(0, 1), B_H)
	_wall("slats", Vector2(6.2, -14.0), Vector2(6.2, 0.0), Vector2(1, 0), B_H, [{"at": -6.0, "w": 1.1, "h": 2.3}])
	# Holt's desk, back to the glass, a sofa and a low table, his shelves.
	_box("vantage_exec_desk", Vector3(14.2, 0.0, -7.5), -PI * 0.5)
	_box("office_chair", Vector3(15.1, 0.0, -7.5), -PI * 0.5)
	_box("vantage_sofa", Vector3(10.0, 0.0, -12.9))
	_box("vantage_coffee_table", Vector3(10.0, 0.0, -11.5))
	for x in [12.6, 14.0, 15.4]:
		_box("vantage_shelves", Vector3(x, 0.0, -13.4))
	_box("vantage_sculpture", Vector3(9.0, 0.0, -2.0), 0.6)
	_box("vantage_plant", Vector3(17.1, 0.0, -13.0))
	_omni(Vector3(12.0, B_H - 0.5, -7.0), WARM, 2.0, 11.0)
	_omni(Vector3(14.2, 1.4, -7.5), CANDLE, 0.8, 3.5)
	_omni(Vector3(10.0, 2.2, -11.8), CANDLE, 0.6, 4.0)
	_probe(r, B_H, Color(0.36, 0.32, 0.28), 0.4)


# --- Outside ----------------------------------------------------------------------------------

## The tower's outside: dark glass and lit offices between the floors that are
## built, the crown and its name on top.
func _tower() -> void:
	_in("outside")
	var facade := _mat("facade")
	var stone := _mat("stone_dark")
	var thick := 0.3
	# The back of the ground floor, up to the lobby's roof.
	for s in [[Vector3(-18.15, 4.5, -25.0), Vector3(thick, 9.0, 14.0)], [Vector3(18.15, 4.5, -25.0), Vector3(thick, 9.0, 14.0)],
			[Vector3(0.0, 4.5, -32.15), Vector3(36.6, 9.0, thick)]]:
		_slab(s[0], s[1], stone)
		_solid(s[0], s[1])
	# Bands of facade between the floors that are built.
	var bands := [[LOBBY_H, R], [R + R_H, B], [B + B_H, TOP]]
	for band in bands:
		var y0: float = band[0]
		var y1: float = band[1]
		var c := (y0 + y1) * 0.5
		var hgt := y1 - y0
		_slab(Vector3(0.0, c, 0.15), Vector3(36.6, hgt, thick), facade)
		_slab(Vector3(0.0, c, -32.15), Vector3(36.6, hgt, thick), facade)
		_slab(Vector3(-18.15, c, -16.0), Vector3(thick, hgt, 32.0), facade)
		_slab(Vector3(18.15, c, -16.0), Vector3(thick, hgt, 32.0), facade)
	# On the built floors, facade where no room meets the outside.
	for p in [[R, R_H, [[-18.15, -15.0, 6.0], [-18.15, -30.0, 4.0], [18.15, -22.0, 20.0]]],
			[B, B_H, [[-18.15, -23.0, 18.0], [18.15, -23.0, 18.0]]]]:
		var y: float = p[0] + float(p[1]) * 0.5
		for s in p[2]:
			_slab(Vector3(s[0], y, s[1]), Vector3(thick, float(p[1]), s[2]), facade)
		_slab(Vector3(0.0, y, -32.15), Vector3(36.6, float(p[1]), thick), facade)
	# Slab edges between the glass and the facade, so every floor shows.
	for y in [LOBBY_H, R, R + R_H, B, B + B_H]:
		_slab(Vector3(0.0, y, 0.12), Vector3(36.7, 0.3, 0.24), _mat("steel_black"))
	# The crown: a roof, a lit band, the name.
	_slab(Vector3(0.0, TOP + 0.15, -16.0), Vector3(36.8, 0.3, 32.8), _mat("roof"))
	_slab(Vector3(0.0, TOP + 1.2, 0.2), Vector3(36.8, 1.8, 0.2), stone)
	_slab(Vector3(0.0, TOP + 0.4, 0.32), Vector3(36.8, 0.08, 0.04), _mat("crown"))
	for side in [-1.0, 1.0]:
		_slab(Vector3(18.3 * side, TOP + 1.2, -16.0), Vector3(0.2, 1.8, 32.8), stone)
		_slab(Vector3(18.42 * side, TOP + 0.4, -16.0), Vector3(0.04, 0.08, 32.8), _mat("crown"))
	_sign("VANTAGE", Vector3(0.0, TOP + 1.2, 0.33), 0.0, 400, Color(1.5, 1.55, 1.6), 0.008)
	_m("Prop_ACUnit", Vector3(-8.0, TOP + 0.3, -20.0))
	_m("Prop_ACUnit", Vector3(6.0, TOP + 0.3, -24.0))
	var red := MeshInstance3D.new()
	var bulb := SphereMesh.new()
	bulb.radius = 0.25
	bulb.height = 0.5
	red.mesh = bulb
	red.material_override = _mat("led_red")
	red.position = Vector3(0.0, TOP + 4.2, -16.0)
	_at.add_child(red)
	_slab(Vector3(0.0, TOP + 2.1, -16.0), Vector3(0.12, 3.8, 0.12), _mat("steel_black"))


## The plaza in front of the tower and the street.
func _plaza() -> void:
	_in("outside")
	_slab(Vector3(0.0, -0.05, KERB * 0.5), Vector3(180.0, 0.1, KERB), _mat("paving"))
	for kz in [KERB - 0.12, FAR_KERB + 0.12]:
		_slab(Vector3(0.0, -0.07, kz), Vector3(180.0, 0.16, 0.24), _mat("kerb"))
	_slab(Vector3(0.0, -0.2, (KERB + FAR_KERB) * 0.5), Vector3(180.0, 0.1, FAR_KERB - KERB), _mat("asphalt"))
	_slab(Vector3(0.0, -0.05, (FAR_KERB + ACROSS) * 0.5 + 1.0), Vector3(180.0, 0.1, ACROSS - FAR_KERB + 2.0), _mat("paving"))
	var mid := (KERB + FAR_KERB) * 0.5
	var x := -88.0
	while x < 88.0:
		_slab(Vector3(x + 1.5, -0.148, mid), Vector3(3.0, 0.006, 0.14), _mat("road_paint"))
		x += 7.0
	for z in [KERB + 0.35, FAR_KERB - 0.35]:
		_slab(Vector3(0.0, -0.148, z), Vector3(180.0, 0.006, 0.1), _mat("road_paint"))
	# A dark stone apron along the tower, the canopy over the doors.
	_slab(Vector3(0.0, 0.004, 1.5), Vector3(36.0, 0.012, 3.0), _mat("stone_dark"))
	_no_shadow(_m("vantage_canopy", Vector3(0.0, 4.2, 0.0)))
	_spot(Vector3(0.0, 4.1, 2.0), Vector3(0.0, 0.0, 2.2), COOL, 3.5, 6.0, 60.0, true)
	for cx in [-3.0, 3.0]:
		_omni(Vector3(cx, 3.9, 1.6), WARM, 0.6, 4.5)
	# The name on a stone plinth, planters with trees, benches.
	_slab(Vector3(-8.0, 0.45, 6.0), Vector3(5.0, 0.9, 0.7), _mat("stone_dark"))
	_solid(Vector3(-8.0, 0.45, 6.0), Vector3(5.0, 0.9, 0.7))
	_sign("VANTAGE", Vector3(-8.0, 0.48, 6.36), 0.0, 120, Color(1.2, 1.2, 1.25), 0.006)
	for p in [Vector2(-14.0, 5.0), Vector2(-14.0, 10.5), Vector2(14.0, 5.0), Vector2(14.0, 10.5), Vector2(8.0, 8.0)]:
		_m("vantage_planter", _v(p))
		_solid(_v(p, 0.45), Vector3(1.3, 0.9, 1.3))
		_omni(_v(p, 0.3), Color(0.8, 0.9, 1.0), 0.35, 3.5)
	for b in [Vector3(-11.6, 0.0, 7.8), Vector3(11.6, 0.0, 7.8), Vector3(4.6, 0.0, 8.0)]:
		_box("vantage_bench", b, PI * 0.5)
	for bx in [-6.0, -3.0, 3.0, 6.0]:
		_box("Prop_Bollard", Vector3(bx, 0.0, KERB - 0.8))
	# Street lamps along both kerbs.
	for lx in [-60.0, -36.0, -18.0, 0.0, 18.0, 36.0, 60.0]:
		_lamp(Vector3(lx + 6.0, 0.0, KERB - 0.6), absf(lx) < 40.0)
		_lamp(Vector3(lx, 0.0, FAR_KERB + 0.6), absf(lx) < 30.0)
	# Nobody leaves the block: the street's ends.
	for ex in [-90.0, 90.0]:
		_solid(Vector3(ex, 3.0, (ACROSS - 20.0) * 0.5), Vector3(0.4, 6.0, ACROSS + 20.0))
	# A moon, for the plaza and the tower's glass.
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.14
	moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	moon.rotation_degrees = Vector3(-35.0, 150.0, 0.0)
	_at.add_child(moon)
	_probe(Rect2(-40.0, 0.0, 80.0, 25.0), 20.0, Color(0.12, 0.13, 0.18), 0.25)


## The city round the tower at night: street fronts either side and across
## the road, and towers of lit windows out to the edge of sight.
func _city() -> void:
	_in("outside")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2207
	# Next door, either side of the plaza, and across the street.
	_block(-70.0, -24.0, 0.0, false, 15.0, "white", rng)
	_block(24.0, 70.0, 0.0, false, 12.0, "red", rng)
	_block(-70.0, -20.0, ACROSS, true, 15.0, "double", rng)
	_block(-20.0, 20.0, ACROSS, true, 18.0, "inset", rng)
	_block(20.0, 70.0, ACROSS, true, 15.0, "white", rng)
	# Their roofs and ends, seen from upstairs.
	for blk in [[-70.0, -24.0, -30.0, 0.0, 15.0], [24.0, 70.0, -30.0, 0.0, 12.0], [-70.0, -20.0, ACROSS, ACROSS + 20.0, 15.0],
			[-20.0, 20.0, ACROSS, ACROSS + 20.0, 18.0], [20.0, 70.0, ACROSS, ACROSS + 20.0, 15.0]]:
		var x0: float = blk[0]
		var x1: float = blk[1]
		var z0: float = blk[2]
		var z1: float = blk[3]
		var h: float = blk[4] + 0.8
		_slab(Vector3((x0 + x1) * 0.5, h, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.2, z1 - z0), _mat("roof"))
		for ex in [x0, x1]:
			_slab(Vector3(ex, h * 0.5, (z0 + z1) * 0.5), Vector3(0.3, h, z1 - z0 - 0.4), _mat("city"))
		for k in 3:
			_m("Prop_ACUnit", Vector3(lerpf(x0, x1, 0.2 + 0.3 * k), h + 0.1, lerpf(z0, z1, 0.3 + 0.2 * (k % 2))))
	# The ground out to the edge, and the streets on it.
	_slab(Vector3(0.0, -0.32, 0.0), Vector3(440.0, 0.1, 440.0), _mat("ground_far"))
	for k in range(-5, 6):
		_slab(Vector3(0.0, -0.26, 60.0 + k * 34.0), Vector3(440.0, 0.02, 0.5), _mat("sodium_glow"))
		_slab(Vector3(k * 40.0 + 10.0, -0.26, 0.0), Vector3(0.5, 0.02, 440.0), _mat("sodium_glow"))
	# Towers of lit windows, keeping clear of the street in front and the tower's own block.
	var city := _mat("city")
	var cap := _mat("roof")
	var placed := 0
	var tries := 0
	while placed < 70 and tries < 600:
		tries += 1
		var a := rng.randf() * TAU
		var d := rng.randf_range(70.0, 175.0)
		var p := Vector2(sin(a) * d, cos(a) * d - 10.0)
		if absf(p.x) < 80.0 and p.y > -40.0 and p.y < 50.0:
			continue
		var w := rng.randf_range(14.0, 30.0)
		var dpt := rng.randf_range(14.0, 30.0)
		var h := rng.randf_range(18.0, 40.0) + (rng.randf_range(20.0, 55.0) if rng.randf() < 0.35 else 0.0)
		_slab(Vector3(p.x, h * 0.5 - 0.3, p.y), Vector3(w, h, dpt), city)
		_slab(Vector3(p.x, h - 0.15, p.y), Vector3(w + 0.4, 0.4, dpt + 0.4), cap)
		if h > 45.0:
			var light := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.4
			s.height = 0.8
			light.mesh = s
			light.material_override = _mat("led_red")
			light.position = Vector3(p.x, h + 0.4, p.y)
			_at.add_child(light)
		placed += 1


func _doors() -> void:
	_make_doors(DOOR_SPECS)
	for name in SLIDE_SPECS:
		var spec: Dictionary = SLIDE_SPECS[name]
		var d := SlideDoor.new()
		d.name = String(name).capitalize().replace(" ", "") + "Door"
		d.id = name
		d.width = spec.w
		d.height = spec.h
		d.double = spec.get("double", false)
		d.model = spec.model
		d.thickness = spec.get("thick", 0.08)
		var to: Vector2 = spec.to
		var basis := Basis(Vector3.UP, atan2(-to.x, -to.y))
		d.transform = Transform3D(basis, _v(spec.at, float(spec.get("y", 0.0))) + basis.x * float(spec.w) * 0.5)
		d.build()
		add_child(d)
		doors[name] = d
	# Linings through the walls.
	_in("lobby")
	_reveal(Vector2(-11.0, -18.0), Vector2(1, 0), 1.1, 2.3, 0.4, _mat("stone_dark"), "steel_brushed")
	_reveal(Vector2(12.0, -18.0), Vector2(1, 0), 1.1, 2.3, 0.4, _mat("stone_dark"), "steel_brushed")
	_in("r_lobby")
	_reveal(Vector2(-4.0, -23.0), Vector2(0, 1), 1.1, 2.3, 0.4, _mat("oak"))
	_reveal(Vector2(1.0, -18.0), Vector2(1, 0), 4.0, 2.7, 0.4, _mat("steel_brushed"))
	_in("lab")
	_reveal(Vector2(-8.0, -8.0), Vector2(0, 1), 1.1, 2.3, 0.4, _mat("oak"))
	_in("b_lobby")
	_reveal(Vector2(-4.0, -20.0), Vector2(0, 1), 1.1, 2.3, 0.4, _mat("oak"))
	_reveal(Vector2(1.0, -18.0), Vector2(1, 0), 6.0, 3.0, 0.4, _mat("oak"))
	_in("assist")
	_reveal(Vector2(-4.0, -6.0), Vector2(0, 1), 1.8, 2.5, 0.4, _mat("stone_dark"))
	_reveal(Vector2(6.0, -6.0), Vector2(0, 1), 1.1, 2.3, 0.4, _mat("stone_dark"))
	_in("pantry")
	_reveal(Vector2(-8.0, -14.0), Vector2(1, 0), 1.1, 2.3, 0.4, _mat("steel_brushed"))


# --- Where people go --------------------------------------------------------------------------

func _graph() -> void:
	var P := {
		# The plaza and the lobby.
		"plaza": _p(4.0, 0.0, 9.0), "front_out": _p(0.0, 0.0, 1.8), "front_in": _p(0.0, 0.0, -1.8),
		"lobby_s": _p(0.0, 0.0, -5.0), "lobby_c": _p(1.4, 0.0, -9.6), "lobby_w": _p(-8.0, 0.0, -13.4), "lobby_e": _p(8.4, 0.0, -12.6),
		"cafe_front": _p(-11.4, 0.0, -12.8), "philippa": _p(-12.4, 0.0, -13.6), "cafe_side": _p(-12.8, 0.0, -15.9), "lupe": _p(-15.0, 0.0, -15.9),
		"plant_out": _p(-11.0, 0.0, -16.4), "plant_in": _p(-11.0, 0.0, -19.6), "stan": _p(-9.0, 0.0, -23.0),
		"desk_n": _p(12.6, 0.0, -12.6), "desk_front": _p(12.8, 0.0, -9.0), "desk_back": _p(16.0, 0.0, -12.9), "dana": _p(16.0, 0.0, -9.0),
		"office_out": _p(12.0, 0.0, -16.4), "office_guard": _p(13.4, 0.0, -16.0), "office_in": _p(12.0, 0.0, -19.6),
		"renata": _p(10.6, 0.0, -21.2), "held": _p(15.8, 0.0, -24.8),
		"gates_out": _p(3.15, 0.0, -16.4), "teo": _p(5.0, 0.0, -16.9), "gates_in": _p(3.15, 0.0, -19.6),
		# The lift lobbies: the same on every floor.
		"lift_lobby_c": _p(1.0, 0.0, -22.4), "arrive_g": _p(2.6, 0.0, -25.2), "lift_wait_g": _p(4.8, 0.0, -25.6),
		"lift_out_g": _p(3.5, 0.0, -26.6), "car_g": _p(3.5, 0.0, -29.6),
		"r_lobby_c": _p(1.0, R, -21.4), "arrive_r": _p(2.6, R, -25.2), "lift_wait_r": _p(4.8, R, -25.6),
		"lift_out_r": _p(3.5, R, -26.6), "car_r": _p(3.5, R, -29.6),
		"b_lobby_c": _p(1.0, B, -21.4), "arrive_b": _p(2.6, B, -25.2), "lift_wait_b": _p(4.8, B, -25.6),
		"lift_out_b": _p(3.5, B, -26.6), "car_b": _p(3.5, B, -29.6),
		# The research floor.
		"break_out": _p(-2.6, R, -23.0), "break_in": _p(-5.6, R, -23.0), "break_c": _p(-8.0, R, -24.6),
		"joost_break": _p(-12.6, R, -22.4), "wes_break": _p(-13.4, R, -24.6), "odile": _p(-6.4, R, -26.4),
		"r_south": _p(1.0, R, -19.4), "check_n": _p(1.0, R, -16.6), "check_c": _p(1.0, R, -14.2),
		"bram": _p(3.6, R, -14.6), "check_desk": _p(3.6, R, -16.8), "odile_check": _p(-1.2, R, -16.4), "renata_r": _p(-1.6, R, -14.0),
		"lab_in": _p(1.0, R, -10.6), "lab_c": _p(1.0, R, -5.0), "lab_w": _p(-6.2, R, -8.0), "lab_e": _p(6.4, R, -8.5),
		"wes": _p(3.6, R, -4.2), "margot_lab": _p(5.6, R, -10.0), "odile_lab": _p(-1.0, R, -9.8),
		"lo_in": _p(-9.6, R, -8.0), "margot": _p(-14.6, R, -6.4), "lo_c": _p(-11.2, R, -6.4),
		"lo_n": _p(-11.6, R, -8.8), "lo_back": _p(-14.6, R, -8.6),
		"cut_in": _p(9.6, R, -8.5), "cut_c": _p(12.0, R, -7.6), "joost_cut": _p(13.6, R, -6.0), "rose": _p(14.0, R, -9.6),
		# The board floor.
		"b_south": _p(1.0, B, -19.2), "assist_n": _p(1.0, B, -16.2), "assist_w": _p(-2.4, B, -13.0),
		"noor": _p(1.0, B, -12.0), "assist_c": _p(1.0, B, -8.6), "assist_bw": _p(-2.4, B, -6.0), "assist_be": _p(4.4, B, -6.0),
		"renata_b": _p(-2.6, B, -8.0), "philippa_b": _p(-1.4, B, -10.4), "assist_s": _p(1.0, B, -4.6),
		"pantry_out": _p(-2.6, B, -20.0), "pantry_in": _p(-5.6, B, -20.0), "mirela": _p(-7.6, B, -18.6),
		"service_in": _p(-8.0, B, -15.6), "service_out": _p(-8.0, B, -12.4), "service_ear": _p(-7.2, B, -15.4),
		"board_in": _p(-5.4, B, -6.0), "board_ne": _p(-5.4, B, -9.6), "board_se": _p(-5.4, B, -4.4),
		"seat_n4": _p(-6.5, B, -9.6), "seat_n3": _p(-9.0, B, -9.6), "seat_n2": _p(-11.5, B, -9.6), "seat_n1": _p(-14.0, B, -9.6),
		"seat_s4": _p(-6.5, B, -4.4), "seat_s3": _p(-9.0, B, -4.4), "seat_s2": _p(-11.5, B, -4.4), "seat_s1": _p(-14.0, B, -4.4),
		"board_nw": _p(-16.9, B, -9.6), "ezra": _p(-16.9, B, -7.0), "board_sw": _p(-16.9, B, -4.4),
		"mirela_serve": _p(-9.8, B, -11.6), "margot_board": _p(-5.4, B, -12.6), "joost_board": _p(-6.6, B, -12.9),
		"founder_in": _p(7.6, B, -6.0), "founder_c": _p(11.0, B, -4.4), "founder_se": _p(16.4, B, -4.4), "ezra_office": _p(16.4, B, -7.5),
	}
	# Where the crew starts, by night.
	match night:
		"board":
			P["crew_0"] = _p(-0.2, B, -24.0)
			P["crew_1"] = _p(1.2, B, -24.0)
		"research":
			P["crew_0"] = _p(-0.2, R, -24.0)
			P["crew_1"] = _p(1.2, R, -24.0)
		_:
			P["crew_0"] = _p(-1.0, 0.0, -3.2)
			P["crew_1"] = _p(1.0, 0.0, -3.2)
	points = P
	var L := [
		["plaza", "front_out", ""], ["front_out", "front_in", "front"], ["front_in", "lobby_s", ""],
		["lobby_s", "lobby_c", ""], ["lobby_c", "lobby_w", ""], ["lobby_c", "lobby_e", ""], ["lobby_c", "gates_out", ""],
		["lobby_w", "cafe_front", ""], ["cafe_front", "philippa", ""], ["cafe_front", "cafe_side", ""], ["cafe_side", "lupe", ""],
		["lobby_w", "plant_out", ""], ["plant_out", "plant_in", "plant"], ["plant_in", "stan", ""],
		["lobby_e", "desk_n", ""], ["lobby_e", "desk_front", ""], ["desk_n", "desk_back", ""], ["desk_back", "dana", ""],
		["lobby_e", "office_out", ""], ["office_out", "office_guard", ""], ["office_out", "office_in", "office"],
		["office_in", "renata", ""], ["office_in", "held", ""], ["renata", "held", ""],
		["gates_out", "teo", ""], ["gates_out", "gates_in", "gates"], ["gates_in", "lift_lobby_c", ""],
		# Every lift lobby, and the lift up through them.
		["lift_lobby_c", "arrive_g", ""], ["arrive_g", "lift_out_g", ""], ["lift_out_g", "lift_wait_g", ""], ["lift_out_g", "car_g", "lift_g"],
		["r_lobby_c", "arrive_r", ""], ["arrive_r", "lift_out_r", ""], ["lift_out_r", "lift_wait_r", ""], ["lift_out_r", "car_r", "lift_r"],
		["b_lobby_c", "arrive_b", ""], ["arrive_b", "lift_out_b", ""], ["lift_out_b", "lift_wait_b", ""], ["lift_out_b", "car_b", "lift_b"],
		["car_g", "car_r", ""], ["car_r", "car_b", ""],
		# The research floor.
		["r_lobby_c", "break_out", ""], ["break_out", "break_in", "break"], ["break_in", "break_c", ""],
		["break_c", "joost_break", ""], ["break_c", "wes_break", ""], ["break_c", "odile", ""], ["break_in", "odile", ""],
		["r_lobby_c", "r_south", ""], ["r_south", "check_n", ""], ["check_n", "check_c", ""], ["check_n", "check_desk", ""],
		["check_c", "bram", ""], ["check_n", "odile_check", ""], ["odile_check", "renata_r", ""], ["renata_r", "check_c", ""],
		["check_c", "lab_in", "secure"], ["lab_in", "lab_c", ""], ["lab_in", "lab_w", ""], ["lab_in", "lab_e", ""],
		["lab_in", "margot_lab", ""], ["lab_in", "odile_lab", ""], ["lab_c", "wes", ""], ["lab_w", "odile_lab", ""],
		["lab_w", "lo_in", "lab_office"], ["lo_in", "lo_c", ""], ["lo_c", "lo_n", ""], ["lo_in", "lo_n", ""], ["lo_n", "lo_back", ""], ["lo_back", "margot", ""],
		["lab_e", "margot_lab", ""], ["lab_e", "cut_in", "cutting"], ["cut_in", "cut_c", ""], ["cut_c", "joost_cut", ""], ["cut_c", "rose", ""],
		# The board floor.
		["b_lobby_c", "b_south", ""], ["b_south", "assist_n", ""], ["assist_n", "assist_w", ""], ["assist_w", "assist_c", ""],
		["assist_w", "philippa_b", ""], ["philippa_b", "renata_b", ""], ["assist_c", "noor", ""], ["assist_c", "renata_b", ""],
		["assist_c", "assist_bw", ""], ["assist_c", "assist_be", ""], ["assist_c", "assist_s", ""], ["renata_b", "assist_bw", ""],
		["b_lobby_c", "pantry_out", ""], ["pantry_out", "pantry_in", "pantry"], ["pantry_in", "mirela", ""],
		["mirela", "service_in", ""], ["service_in", "service_ear", ""], ["service_in", "service_out", "service"],
		["service_out", "mirela_serve", ""], ["service_out", "seat_n3", ""],
		["assist_bw", "board_in", "boardroom"], ["board_in", "board_ne", ""], ["board_in", "board_se", ""],
		["board_ne", "seat_n4", ""], ["seat_n4", "seat_n3", ""], ["seat_n3", "seat_n2", ""], ["seat_n2", "seat_n1", ""], ["seat_n1", "board_nw", ""],
		["board_se", "seat_s4", ""], ["seat_s4", "seat_s3", ""], ["seat_s3", "seat_s2", ""], ["seat_s2", "seat_s1", ""], ["seat_s1", "board_sw", ""],
		["board_nw", "ezra", ""], ["ezra", "board_sw", ""], ["mirela_serve", "seat_n2", ""],
		["board_ne", "margot_board", ""], ["margot_board", "joost_board", ""], ["joost_board", "mirela_serve", ""],
		["assist_be", "founder_in", "founder"], ["founder_in", "founder_c", ""], ["founder_c", "founder_se", ""], ["founder_se", "ezra_office", ""],
	]
	match night:
		"board", "research":
			var c := "b_lobby_c" if night == "board" else "r_lobby_c"
			var arrive := "arrive_b" if night == "board" else "arrive_r"
			L.append_array([["crew_0", c, ""], ["crew_1", c, ""], ["crew_0", "crew_1", ""], ["crew_1", arrive, ""]])
		_:
			L.append_array([["crew_0", "front_in", ""], ["crew_1", "front_in", ""], ["crew_0", "lobby_s", ""], ["crew_1", "lobby_s", ""]])
	links = L
	var face := {
		"dana": Vector2(-1, 0), "teo": Vector2(0, 1), "lupe": Vector2(0, 1), "philippa": Vector2(-1, -0.5), "stan": Vector2(0, 1),
		"renata": Vector2(0.4, 1), "held": Vector2(-1, 0), "office_guard": Vector2(0, 1), "plaza": Vector2(0, -1),
		"arrive_g": Vector2(0, 1), "arrive_r": Vector2(0, 1), "arrive_b": Vector2(0, 1),
		"lift_wait_g": Vector2(-0.3, -1), "lift_wait_r": Vector2(-0.3, -1), "lift_wait_b": Vector2(-0.3, -1),
		"joost_break": Vector2(-1, -0.3), "wes_break": Vector2(1, 0.3), "odile": Vector2(1, 0.4), "bram": Vector2(0, -1),
		"odile_check": Vector2(1, 0.3), "renata_r": Vector2(1, -0.4), "wes": Vector2(0, 1), "margot_lab": Vector2(-1, 0),
		"odile_lab": Vector2(-1, 0.2), "margot": Vector2(1, 0), "joost_cut": Vector2(0, 1), "rose": Vector2(1, -0.2),
		"noor": Vector2(0, -1), "renata_b": Vector2(0.3, -1), "philippa_b": Vector2(1, -0.3), "mirela": Vector2(1, 0.4),
		"service_ear": Vector2(-0.4, 1), "mirela_serve": Vector2(0, 1), "ezra": Vector2(1, 0), "ezra_office": Vector2(-1, 0),
		"seat_n1": Vector2(0, 1), "seat_n2": Vector2(0, 1), "seat_n3": Vector2(0, 1), "seat_n4": Vector2(0, 1),
		"seat_s1": Vector2(0, -1), "seat_s2": Vector2(0, -1), "seat_s3": Vector2(0, -1), "seat_s4": Vector2(0, -1),
		"check_desk": Vector2(0, 1), "lo_c": Vector2(-1, 0), "margot_board": Vector2(-1, 0.4), "joost_board": Vector2(-1, 0.5),
	}
	if night == "lift":
		face["crew_0"] = Vector2(0, -1)
		face["crew_1"] = Vector2(0, -1)
	else:
		face["crew_0"] = Vector2(0, 1)
		face["crew_1"] = Vector2(0, 1)
	for k in face:
		spots[k] = _face3(P[k], face[k])


## The night's crowd: people leaving work at six, the board at half past
## seven, nearly nobody at twenty to eleven.
func _crowd() -> void:
	match night:
		"lift":
			extras["lobby"] = _knot3(_p(-4.6, 0.0, -13.6), 3, 0.7) + _knot3(_p(9.0, 0.0, -4.0), 2, 0.55) + [
				_face3(_p(-14.5, 0.0, -9.7), Vector2(0.2, -1)), _face3(_p(-11.8, 0.0, -9.7), Vector2(-1, -0.3)),
				_face3(_p(-16.4, 0.0, -6.6), Vector2(1, 0)), _face3(_p(12.6, 0.0, -7.6), Vector2(1, 0)),
				_face3(_p(-7.2, 0.0, -4.2), Vector2(1, 0.4)), _face3(_p(4.0, 0.0, -11.6), Vector2(-0.4, 1)),
			] as Array[Transform3D]
			extras["lift_lobby"] = [_face3(_p(0.0, 0.0, -25.4), Vector2(0.5, -1)), _face3(_p(-1.4, 0.0, -21.0), Vector2(1, -0.5))] as Array[Transform3D]
			extras["outside"] = _knot3(_p(9.6, 0.0, 5.0), 2, 0.6) + [_face3(_p(-3.4, 0.0, 11.6), Vector2(1, 0))] as Array[Transform3D]
			extras["assist"] = [_face3(_p(-1.6, B, -3.9), Vector2(0, 1)), _face3(_p(3.6, B, -3.9), Vector2(0.3, 1))] as Array[Transform3D]
			extras["lab"] = [_face3(_p(-3.6, R, -5.8), Vector2(0, 1)), _face3(_p(-5.6, R, -8.4), Vector2(1, 0.5))] as Array[Transform3D]
		"board":
			# The board, sitting: four along the window side and one across.
			extras["boardroom"] = [_face3(_p(-14.0, B, -5.4), Vector2(0, -1)), _face3(_p(-11.5, B, -5.4), Vector2(0, -1)),
				_face3(_p(-9.0, B, -5.4), Vector2(0, -1)), _face3(_p(-6.5, B, -5.4), Vector2(0, -1)),
				_face3(_p(-14.0, B, -8.6), Vector2(0, 1))] as Array[Transform3D]
			extras["assist"] = [_face3(_p(3.6, B, -3.9), Vector2(0.3, 1))] as Array[Transform3D]
			extras["lobby"] = [_face3(_p(-3.0, 0.0, -11.0), Vector2(0.5, 1)), _face3(_p(-2.2, 0.0, -10.6), Vector2(-0.6, 0.4))] as Array[Transform3D]
			extras["outside"] = [_face3(_p(10.6, 0.0, 9.4), Vector2(-1, -0.4))] as Array[Transform3D]
		_:
			extras["lobby"] = [_face3(_p(-6.0, 0.0, -6.0), Vector2(1, 0.2))] as Array[Transform3D]
			extras["outside"] = _knot3(_p(-10.0, 0.0, 11.0), 2, 0.6) as Array[Transform3D]


func _views() -> void:
	var v := {
		"plaza": [Vector3(11.0, 1.7, 13.4), Vector3(0.0, 3.2, 0.0)],
		"tower": [Vector3(9.0, 1.6, 21.0), Vector3(0.0, 33.0, -12.0)],
		"lobby": [Vector3(-15.6, 2.3, -1.4), Vector3(5.0, 1.8, -15.0)],
		"front_desk": [Vector3(8.6, 1.7, -5.0), Vector3(16.2, 1.4, -9.6)],
		"cafe": [Vector3(-9.0, 1.7, -6.8), Vector3(-15.6, 1.3, -16.0)],
		"gates": [Vector3(-1.4, 1.7, -9.4), Vector3(3.0, 1.3, -18.6)],
		"lift_lobby": [Vector3(-2.8, 1.7, -19.4), Vector3(3.4, 1.4, -28.0)],
		"security_office": [Vector3(6.9, 1.7, -19.0), Vector3(14.0, 1.1, -26.6)],
		"plant_room": [Vector3(-4.9, 1.7, -18.9), Vector3(-13.0, 1.1, -26.6)],
		"research_lobby": [Vector3(4.8, R + 1.7, -27.0), Vector3(0.0, R + 1.4, -18.0)],
		"checkpoint": [Vector3(-3.0, R + 1.7, -17.2), Vector3(3.4, R + 1.1, -12.4)],
		"lab": [Vector3(-6.9, R + 1.8, -11.2), Vector3(6.0, R + 0.9, -3.0)],
		"cutting_room": [Vector3(13.9, R + 1.55, -7.7), Vector3(15.6, R + 0.95, -10.2)],
		"lab_office": [Vector3(-9.0, R + 1.7, -11.2), Vector3(-16.6, R + 1.0, -3.0)],
		"break_room": [Vector3(-4.9, R + 1.7, -19.0), Vector3(-15.0, R + 0.9, -26.4)],
		"board_lobby": [Vector3(4.8, B + 1.7, -27.0), Vector3(0.0, B + 1.4, -18.0)],
		"assistants": [Vector3(-1.4, B + 1.7, -16.6), Vector3(3.6, B + 1.0, -4.0)],
		"boardroom": [Vector3(-5.0, B + 2.0, -13.0), Vector3(-15.0, B + 0.9, -5.0)],
		"pantry": [Vector3(-4.9, B + 1.7, -15.0), Vector3(-11.0, B + 1.0, -21.0)],
		"founder": [Vector3(7.0, B + 1.7, -13.2), Vector3(16.0, B + 1.0, -3.0)],
		"city": [Vector3(-10.0, B + 1.7, -3.0), Vector3(-34.0, B - 9.0, 40.0)],
	}
	_set_views(v)
	view_about = {
		"plaza": "The plaza at night: the canopy over the doors, the planters, the tower's glass lobby",
		"tower": "Vantage Tower from across the street: the glass lobby, the lit floors, the crown and its name",
		"lobby": "The lobby from its south-west corner: the ring of light, the sculpture, the gates and the front desk",
		"front_desk": "Dana's front desk on the east side, the stone wall with the company's name",
		"cafe": "The cafe in the north-west corner, Lupe's counter and the tables",
		"gates": "Halberd's speed gates under the name, Teo's podium beside them",
		"lift_lobby": "The ground floor's lift lobby: car one out of service, car two open",
		"security_office": "Halberd's security office: the camera screens, Renata's desk, the bench where they hold people",
		"plant_room": "The plant room: the air handlers, Stan's building screens and his shelves of parts",
		"research_lobby": "Level 9's lift lobby and the way through to Halberd's checkpoint, with the scanner's warning",
		"checkpoint": "The high-security checkpoint: Bram's desk, the scanner arch, the glass door to the lab",
		"lab": "The research lab: the benches, the fume hood, the glass wall of the gem room",
		"cutting_room": "The gem room: the Rose under glass on her plinth, the safe behind her, the city through the glass",
		"lab_office": "Dr Lind's office off the lab, her desk facing the door",
		"break_room": "The research floor's break room: the kitchenette, the table, the sofa by the glass",
		"board_lobby": "Level 12's lift lobby, the pantry door and the way through to the assistants",
		"assistants": "The assistants' floor: Noor's desk facing the lifts, the boardroom's doors, Mr Holt's door",
		"boardroom": "The boardroom: the long table, the screen with the cutting plan, the city through the glass",
		"pantry": "The catering pantry: the counter, the coffee trolley, the service door to the boardroom",
		"founder": "Ezra Holt's office: his desk with its back to the glass, the sofa, the shelves",
		"city": "Caldera at night from the board floor: the street below, the blocks across, towers to the edge",
	}


## The night: a dark sky over the city's glow, the rooms lit by their probes.
func environment() -> Environment:
	var env := super.environment()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.008, 0.012, 0.035)
	sky_mat.sky_horizon_color = Color(0.1, 0.08, 0.09)
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color(0.01, 0.01, 0.012)
	sky_mat.ground_horizon_color = Color(0.08, 0.065, 0.07)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.fog_density = 0.0035
	env.fog_light_color = Color(0.06, 0.06, 0.08)
	return env
