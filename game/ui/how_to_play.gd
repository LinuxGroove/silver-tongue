class_name HowToPlay
extends RefCounted
## The pages of How to play, for the title and the pause menu. Lines with
## {action} get the key or button for that action.

const PAGES := [
	["The service door", [
		"Marcus guards the Meridian's service door. He hears what you say and answers in his own words. Nobody wrote his lines.",
		"Talk him into letting you through. A good story isn't enough: he lets you through when he believes who you are and why you're here.",
		"Push him and he'll check with reception, or radio Halberd for backup, and then it's over.",
	]],
	["Talking", [
		"Hold {talk} and talk. Let go when you're done; he hears you a moment later. Your words show up as he heard them.",
		"Hold {whisper} as well to whisper (it carries a metre or two) or {shout} to shout (the whole corridor hears).",
		"{text} types a line instead. Stand close: from down the corridor he only catches some of it.",
	]],
	["Getting about", [
		"Move with {forward} {left} {back} {right}, look with the mouse or the right stick, {crouch} to crouch.",
		"{menu} pauses. Settings choose how you talk (hold to talk, open mic or typing), the hearing model, whether he speaks out loud, and the timing readout.",
		"Head bob and view roll are off unless you turn them on.",
	]],
]


## Fills in the keys and buttons.
static func fill(text: String) -> String:
	var out := text
	for a in ["talk", "whisper", "shout", "text", "forward", "left", "back", "right", "crouch", "menu", "interact"]:
		out = out.replace("{%s}" % a, LGInput.label_for_action(a))
	return out
