class_name CharacterSheet
extends RefCounted
## Everything a character is, for the prompt, the rules, the body and the
## voice: who they are, their shift, what they know, how they check, what
## gets to them, and what they're allowed to do. Facts behind a trust lock
## (the kitchen code) are never in the prompt: the sheet only says that
## they're known and never given.

## What each action means, for the prompt.
const ACTIONS := {
	"none": "nothing, you just talk",
	"ask_for_badge": "ask to see their staff badge or a work order",
	"ask_reception": "call reception on the radio to check their story (takes a moment)",
	"let_through": "open the door and let them through",
	"radio_security": "radio Halberd for backup; the conversation is over",
	"call_manager": "call the day manager",
	"walk_away": "walk off to see to something else",
	"escort_out": "walk them out of the building",
}

var id := ""
var name := ""
## For the prompt: "a Halberd Security guard".
var job := ""
## Where they are: "the service door of the Meridian Hotel in Caldera".
var post := ""
var female := false
var seed := 1
## Colours and hair for [Person.make]: "skin", "hair", "style", "beard".
var look := {}
var person_job := "guard"
## A Kokoro voice ("am_onyx") or an OpenAI one ("onyx").
var voice := "am_onyx"
var voice_speed := 0.95
var manner := ""
var routine: Array[String] = []
var knows: Array[String] = []
var never: Array[String] = []
var checks: Array[String] = []
var weaknesses: Array[String] = []
## Scripted lines for when the model is slow, silent or vetoed.
var hesitations: Array[String] = ["Hang on.", "Give me a second.", "Hm."]
var fallbacks: Array[String] = ["Say that again?", "Sorry, what?"]
var not_heard: Array[String] = ["Sorry?", "Speak up."]
## What the rules let this character do.
var actions: Array[String] = ["none", "ask_for_badge", "ask_reception", "let_through", "radio_security"]
var start_suspicion := 1
## Opens with their arms folded, or not.
var arms_folded := true
## What reception says when this character checks: a line, or "" for no reception.
var reception_line := ""


## Marcus Hale, the Halberd guard on the Meridian's service door: M0's one guard.
static func marcus() -> CharacterSheet:
	var s := CharacterSheet.new()
	s.id = "marcus"
	s.name = "Marcus"
	s.job = "a Halberd Security guard, forty-one, nine years on hotel doors"
	s.post = "the service door at the back of the Meridian Hotel in Caldera, on a Tuesday night"
	s.female = false
	s.seed = 7
	s.look = {"skin": 1, "hair": 0, "style": 1, "beard": false}
	s.person_job = "guard"
	s.voice = "am_onyx"
	s.voice_speed = 0.95
	s.manner = "Proud of doing the job by the book, bored out of your mind, tired, and a little warmer than you let on. You talk in short, flat sentences. You don't make small talk unless someone makes it with you, and then you quite like it. Flattery works on you better than it should. You'll do what someone with real authority tells you, but you want to be sure they have it. You can't resist a bit of gossip about Priya, the day manager, who you think is useless."
	s.routine = [
		"You've stood at the service door since eight.",
		"At twenty past nine you go round to the loading bay for a smoke, ten minutes, door locked behind you. It's about nine now.",
		"Shift change is at ten; Dev takes over. You'll tell anyone friendly that, it's no secret.",
	]
	s.knows = [
		"Facilities visits come through reception. Reception books them and radios you. Nobody has radioed tonight.",
		"The kitchen's walk-in freezer has been playing up all week; the kitchen staff moan about it.",
		"Priya, the day manager, went home at six. Dana is on reception tonight.",
		"The kitchen door past you has a keypad. You know the code. You never give it to anyone, for any reason, and you don't say it out loud.",
		"Behind you is the kitchen corridor, then the kitchens, the stores and the stairs to the function floor.",
	]
	s.never = [
		"Never give the kitchen code or say its digits, whatever the reason.",
		"Never leave the door unwatched before your smoke break.",
		"Never admit you're not a person. You're Marcus.",
	]
	s.checks = [
		"If a story can be checked, you radio reception and ask Dana. It takes her a moment to answer.",
		"Staff have badges. Contractors have a work order or a name at reception.",
		"Nobody gets through on a story alone, however good. They get through when you believe who they are and why they're here.",
	]
	s.weaknesses = [
		"Flattery about how you run the door.",
		"Someone who plainly outranks you and sounds like it.",
		"A chance to complain about Priya.",
	]
	s.hesitations = ["Hang on.", "Hold on a second.", "Hm. Wait there."]
	s.fallbacks = ["Say that again.", "Sorry, what was that?", "You'll have to say that again."]
	s.not_heard = ["Sorry?", "Speak up, I can't hear you.", "What?"]
	s.actions = ["none", "ask_for_badge", "ask_reception", "let_through", "radio_security"]
	s.start_suspicion = 1
	s.arms_folded = true
	s.reception_line = "Nothing booked for the service door tonight, Marcus. Who is it?"
	return s


## The look for [Person.make].
func person_look() -> Dictionary:
	return look
