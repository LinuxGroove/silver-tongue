class_name Heat
extends RefCounted
## The venue's heat: Calm, Curious, Alert, Lockdown. It climbs from what
## everyone suspects (each character's highest suspicion of anyone free,
## (s - 1)² summed, so one wary guard is nothing and two are something) and
## from loud events (a call to security, a shout, a code punched in front
## of staff), which fade. Lockdown holds until it's been quiet a while.

const CALM := 0
const CURIOUS := 1
const ALERT := 2
const LOCKDOWN := 3
const NAMES := ["Calm", "Curious", "Alert", "Lockdown"]
## Where each level starts.
const LEVELS := [0.0, 4.0, 10.0, 18.0]
## Event points lost per second.
const DECAY := 0.08
## Quiet seconds before Lockdown falls back to Alert.
const LOCKDOWN_QUIET := 90.0
## Loud events.
const CAUGHT := 10.0
const SHOUT := 2.0
const KEYPAD_SEEN := 4.0
const EARPIECE := 1.0

var events := 0.0
var from_suspicion := 0.0
var value := 0.0
var level := CALM
var peak := CALM
var _quiet := 0.0


## Points from suspicions (one per character: their highest of anyone free).
static func points(suspicions: Array) -> float:
	var p := 0.0
	for s in suspicions:
		var over := maxi(int(s) - 1, 0)
		p += over * over
	return p


static func level_for(v: float) -> int:
	for i in range(LEVELS.size() - 1, -1, -1):
		if v >= LEVELS[i]:
			return i
	return CALM


static func name_of(l: int) -> String:
	return NAMES[clampi(l, 0, NAMES.size() - 1)]


## Moves heat on by `dt` seconds; returns true when the level changed.
func update(dt: float, suspicion_points: float) -> bool:
	events = maxf(0.0, events - DECAY * dt)
	from_suspicion = suspicion_points
	value = from_suspicion + events
	var want := level_for(value)
	if level == LOCKDOWN and want < LOCKDOWN:
		_quiet += dt
		want = LOCKDOWN if _quiet < LOCKDOWN_QUIET else ALERT
	else:
		_quiet = 0.0
	if want == level:
		return false
	level = want
	peak = maxi(peak, level)
	return true


## A loud event.
func bump(by: float) -> void:
	events += by
	_quiet = 0.0
