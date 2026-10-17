class_name LGVoiceLine
extends RefCounted
## One line a character speaks through [LGVoice]: its text, how it went,
## and the loudness of the voice right now (for a mouth).

signal started
signal finished

var text := ""
var voice := ""
## "asked", "playing", "done", "failed" or "hushed".
var state := "asked"
## 0 to 1 while playing: how loud the voice is at this moment.
var level := 0.0
## Seconds from the ask to the first sound, and the whole line's length.
var first_sound := -1.0
var length := 0.0
var error := ""
var _t0 := 0


func is_playing() -> bool:
	return state == "playing"
