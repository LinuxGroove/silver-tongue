class_name HowToPlay
extends RefCounted
## The pages of How to play, for the title and the pause menu. Lines with
## {action} get the key or button for that action.

const PAGES := [
	["The gala", [
		"Get into the Caldera Museum's gala in the Meridian's ballroom before Halvorsen's speech at half past nine. Nobody on the crew is invited.",
		"The staff and guests hear what you say and answer in their own words. Nobody wrote their lines. They believe you until it stops adding up.",
		"They check stories with each other over the radio, so a lie told to reception can open a door later, and a lie nobody else heard can sink you.",
	]],
	["Talking", [
		"Hold {talk} and talk. Let go when you're done. Whoever you're facing answers; anyone else close enough overhears.",
		"Hold {whisper} as well to whisper (it carries a meter or two) or {shout} to shout (the whole room hears, and it doesn't look good).",
		"Hold {earpiece} to talk to your crew on the earpiece, wherever they are. Nobody else hears it, unless they're standing right next to you.",
		"{text} types a line instead. Stand close: from across a room they only catch some of it.",
	]],
	["Covers and heat", [
		"Each of you picks a cover in the briefing: a guest with the forged invitation, facilities, press or an agency waiter. People go by what you're wearing.",
		"{interact} shows the invitation to whoever you're facing, opens doors and works keypads. A waiter's jacket hangs in the kitchen's staff room.",
		"The heat at the top is how jumpy the building is: Calm, Curious, Alert, then Lockdown, when the doors stay shut. Anyone who calls security sends you to the security office: talk the guard round through the door, or get a crewmate to, before the police come.",
	]],
	["The service door", [
		"The service door on the title is the first test of the talking: Marcus guards it alone, and every turn is timed.",
		"Talk him into letting you through. He lets you through when he believes who you are and why you're here. Push him and he radios Halberd, and it's over.",
	]],
	["Getting about", [
		"Move with {forward} {left} {back} {right}, look with the mouse or the right stick, {crouch} to crouch.",
		"{menu} pauses. Settings choose how you talk (hold to talk, open mic or typing), the hearing model, whether people speak out loud, and the timing readout.",
		"Head bob and view roll are off unless you turn them on.",
	]],
]


## Fills in the keys and buttons.
static func fill(text: String) -> String:
	var out := text
	for a in ["talk", "whisper", "shout", "earpiece", "text", "forward", "left", "back", "right", "crouch", "menu", "interact"]:
		out = out.replace("{%s}" % a, LGInput.label_for_action(a))
	return out
