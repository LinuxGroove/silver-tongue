class_name HowToPlay
extends RefCounted
## The pages of How to play, for the title and the pause menu. Lines with
## {action} get the key or button for that action.

const PAGES := [
	["The season", [
		"Auntie Mae has a season of jobs around one prize, the Rose: the Hotel Meridian, the Marlin, the Tideline and Vantage Tower, then her own house party. Pick them in Mae's back room.",
		"Each job opens when the one before it comes off. Each pays a take, and every job has more than one way in: find yours.",
		"Get held and your face goes in Halberd's file. People who know it look twice. A new face costs $6,000 of the take.",
		"People remember you from one job to the next, and a Halberd guard you fooled at the gala may be on the next door.",
	]],
	["Talking", [
		"Hold {talk} and talk. Let go when you're done. Whoever you're facing answers; anyone else close enough overhears.",
		"Hold {whisper} as well to whisper (it carries a meter or two) or {shout} to shout (the whole room hears, and it doesn't look good).",
		"Hold {earpiece} to talk to your crew on the earpiece, wherever they are. Nobody else hears it, unless they're standing right next to you.",
		"{text} types a line instead, and offers a few your cover might say. Stand close: from across a room they only catch some of it.",
	]],
	["Lies that hold up", [
		"The staff and guests answer in their own words. Nobody wrote their lines. They believe you until it stops adding up.",
		"They check stories with each other over the radio and the phone, so a lie told at the front desk can open a door later, and a lie nobody else heard can sink you.",
		"{phone} brings out your phone: ring a number on the job's list as anyone you like, since the caller ID says what you tell it to. Alone, Mae makes calls for you.",
	]],
	["Covers and heat", [
		"Each of you picks a cover in the briefing. People go by what you're wearing and who you say you are.",
		"{interact} shows what you're carrying to whoever you're facing, opens doors and works keypads.",
		"The heat at the top is how jumpy the place is: Calm, Curious, Alert, then Lockdown, when the doors stay shut. Anyone who calls security has you held: talk your way out, or get a crewmate to, before the police come.",
	]],
	["The service door", [
		"The service door on the title is the first test of the talking: Marcus guards it alone, and every turn is timed.",
		"Talk him into letting you through. He lets you through when he believes who you are and why you're here. Push him and he radios Halberd, and it's over.",
	]],
	["Getting about", [
		"Move with {forward} {left} {back} {right}, look with the mouse or the right stick, {crouch} to crouch.",
		"{menu} pauses. Settings choose how you talk, whether people speak out loud, subtitles, minding your language, and seeing through your eyes or over your shoulder.",
		"Head bob and view roll are off unless you turn them on.",
	]],
]


## Fills in the keys and buttons.
static func fill(text: String) -> String:
	var out := text
	for a in ["talk", "whisper", "shout", "earpiece", "text", "phone", "forward", "left", "back", "right", "crouch", "menu", "interact"]:
		out = out.replace("{%s}" % a, LGInput.label_for_action(a))
	return out
