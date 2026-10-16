class_name JobDef
extends RefCounted
## One job: its venue, cast, covers, clock, routine, doors, things to take,
## numbers to ring, and the rules that are only its own. [Job] runs any job
## from one of these: the data says what the night is, and the hooks (the
## methods below, all optional) do what the data can't. A job's script
## extends this and sets the data in `_init()`. docs/m2.md has the whole
## contract, and game/venues/meridian/gala_job.gd is the first job.
##
## Times are minutes after midnight (`21 * 60 + 30` for 9:30 pm; a night
## that runs past midnight goes on counting past 1440).

## The job's id ("meridian_gala"), its venue's ("meridian"), and where it is
## in the venue's three (1 to 3).
var id := ""
var venue_id := ""
var number := 1
## Other venues whose people this job's cast shares, with what they
## remember of the crew (the finale's guests come from all over Caldera).
## Character ids are the same person wherever they turn up.
var memory_from: Array = []
## For the board and the HUD: "The gala", "The Hotel Meridian".
var title := ""
var venue_name := ""
## Auntie Mae's briefing, in her words (spoken in her voice on the board).
var briefing := ""
## Who gives the briefing, when it isn't Mae: a name for the board and a
## Kokoro voice to speak it in ("" for Mae).
var briefer := ""
var briefer_voice := ""
## What the crew has to do, short, for the HUD and the board.
var goal := ""
## What the whole job is about, for every character's prompt.
var situation := ""
## The prize, as the crew would say it ("the guest list"), and the take in
## dollars when the job comes off.
var prize := ""
var take := 0

## The clock: the start, the end (when [method at_end] decides how it went),
## what happens then (for the HUD: "the speech"), and how many real seconds a
## game minute takes.
var start := 20 * 60
var end := 21 * 60
var end_text := ""
var seconds_per_minute := 16.0

## The covers on offer, by id, like [constant Covers.ALL]: "title", "names"
## ([man's, woman's]), "job", "story", "outfit", "for" (who it's made for),
## and "lines" (suggested lines for text mode).
var covers := {}
var cover_order: Array = []
## Outfits this job adds to [constant Covers.OUTFITS]: id -> {"job" (the
## [Person] job it dresses as), "male", "female" (how it's described)}.
var outfits := {}
## Outfits the staff take for staff in the back of the house.
var staff_looking: Array = []
## Rooms only staff should be in: zone -> how a character would say it.
var staff_rooms := {}
## Looks for [Person] this job adds (see [method Person.add_looks]).
var looks := {}
## What the crowd in each zone wears (a [Person] job), for the venue's extras.
var extras := {}

## Who goes where and when: [minute, character id, spot], walked when the
## time comes (see [method on_routine]).
var routine: Array = []
## Scripted lines, by time: [minute, character id, line, "radio" or "near"].
var chatter: Array = []
## Named events, by time: [minute, name], handed to [method on_event].
var events: Array = []

## Doors at the start: locked to the crew, unlocked, and open.
var locked: Array = []
var unlocked: Array = []
var open: Array = []
## Doors shut and kept shut at Lockdown, and what the crew is told.
var lockdown_doors: Array = []
var lockdown_text := "Lockdown. The doors are shut."
## What the crew hears trying a locked door, by door ("It's locked." if none).
var door_texts := {}
## Keypads, by the use id beside them: {"door", "code" (four digits),
## "for" (seconds open), "label" (on the keypad: "Kitchen door")}.
var keypads := {}
## Where the crew's held: the office's door, the spot they're put at, and
## where the guard minding them stands.
var office := {"door": "office", "held": "held", "guard": "office_guard", "name": "the security office"}

## Things to take, carry, show or leave: id -> {"name" (what it's called),
## "at" (the use id it lies at in the venue, "" for carried from the start),
## "carry" (what anyone sees: "carrying a leather folder", "" for hidden),
## "hot" (taking it in view of staff is trouble), "papers" (when it can be
## shown: what it says, with %s for the cover's name), "forged" (a close look
## finds it out), "copy" (what that close look finds), "belief" (what a pass
## makes them believe), "to" (who'll look at it; empty for anyone)}.
var items := {}
## Actions this job adds to [constant CharacterSheet.ACTIONS]: name ->
## {"text" (for the prompt), "kind" ("opening", "check" or ""), "lockdown"
## (nobody does it at Lockdown)}.
var actions := {}
## What happens when a character takes an action for a crew member, by
## action (the job's own actions or the usual ones): "open" (a door, or
## "@door" for the character's own), "for" (seconds), "flag" (set on the
## crew member), "outfit" (they're put in), "walk" (the character goes to a
## spot), "toast" (said to the crew member, %s for the character's name).
## [method on_action] comes first and can do the rest.
var effects := {}
## Words that make anyone overhearing look up, on top of the usual ones.
var hot_words: Array = []
## Numbers on the phone: [{"id", "name", "who" (character id)}], and the
## names the crew can make the caller ID say.
var phone: Array = []
var caller_ids: Array = ["Withheld"]
## Calls Auntie Mae makes for a crew on its own: [{"id", "label" (on the
## phone), "who" (the character), "as" (who she says she is), "line" (what
## she tells them), "answer" (what they say back), "mae" (what she says to
## you first)}]. Each one once a job; [method on_mae] does what it does.
var mae_calls: Array = []
## The report's heading and line for each way the night can end: outcome ->
## [title, text with an optional %s for the clock]. "held" and "lost" have
## defaults; every other outcome needs one.
var outcomes := {}
## Outcomes that count as the job coming off.
var wins: Array = ["done"]
## When a crew member is "inside" (the HUD and the report say so): in this
## zone. "" for jobs with no inside.
var inside_zone := ""
var inside_text := ""
## A Circuit night's remix ({} for the campaign's own): its number, rules,
## who's rounds moved and the take before (see [Circuit]).
var circuit := {}


## The venue, unbuilt (the scene adds it to the tree, which builds it).
func venue() -> Venue:
	return null


## The cast, as sheets: each with its spot, door, actions and replies.
func cast() -> Array[CharacterSheet]:
	return []


## The sheets with this job's actions and hot words on them.
func sheets() -> Array[CharacterSheet]:
	var out := cast()
	for s in out:
		s.more_actions = actions
		for w in hot_words:
			if not w in s.hot_words:
				s.hot_words.append(w)
		if s.situation == "":
			s.situation = situation
	Circuit.on_sheets(self, out)
	return out


func sheet(char_id: String) -> CharacterSheet:
	for s in sheets():
		if s.id == char_id:
			return s
	return null


## The clock as the crew reads it: "9:05 pm".
static func clock_text(minute: float) -> String:
	var m := int(minute) % 1440
	var h := m / 60
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m % 60, "am" if h < 12 else "pm"]


## The cover's name for a body.
func cover_name(cover: String, female: bool) -> String:
	var c: Dictionary = covers.get(cover, {})
	var names: Array = c.get("names", ["Stranger", "Stranger"])
	return str(names[1 if female else 0])


## The cover to fall back on.
func first_cover() -> String:
	return str(cover_order[0]) if not cover_order.is_empty() else str(covers.keys()[0]) if not covers.is_empty() else ""


## The papers a crew member carrying `held` would show a character: the
## first item with "papers" that character looks at ("" for none).
func papers_for(held: Array, char_id: String) -> String:
	for it in held:
		var info: Dictionary = items.get(it, {})
		if not info.has("papers"):
			continue
		var to: Array = info.get("to", [])
		if to.is_empty() or char_id in to:
			return str(it)
	return ""


## What the crew carries at the start: sets each [CrewInfo]'s items.
func give_items(_crew: Array) -> void:
	pass


#region Hooks

## The night's set up: the cast are at their spots, the doors as they start.
func setup(_job: Job) -> void:
	pass


## A crew member used something. Return what to tell them ("" for nothing),
## or null to let the job do the usual: take an item ("item:<id>"), show
## papers ("character:<id>"), open or close a door ("door:<name>").
func use(_job: Job, _c: CrewInfo, _what: String) -> Variant:
	return null


## What Interact says for one of the venue's uses ("" for nothing), or null
## for the usual (doors, items, papers).
func prompt_for(_c: CrewInfo, _what: String) -> Variant:
	return null


## Whether a crew member may take an item now: "" yes, or what to tell them.
func can_take(_job: Job, _c: CrewInfo, _item: String) -> String:
	return ""


## A character took an action for a crew member (after the rules). Return
## true when it's handled; false lets [member effects] do it.
func on_action(_job: Job, _ch: Character, _c: CrewInfo, _act: String) -> bool:
	return false


## What a colleague says when asked about a crew member over the radio or
## the phone, from the game's facts and what the crew told the asker
## (`said`, lower case): [method Job.fact], or {} for "they don't know them".
func lookup(_job: Job, _who: String, _crew_id: int, _said: String, _asker: Character) -> Dictionary:
	return {}


## A routine walk is due. Return false to skip it.
func on_routine(_job: Job, _ch: Character, _spot: String) -> bool:
	return true


func on_event(_job: Job, _name: String) -> void:
	pass


## Every frame on the host, after the job's own.
func tick(_job: Job, _delta: float) -> void:
	pass


## How the night has ended, if it has: an outcome, or "".
func check_end(_job: Job) -> String:
	return ""


## How it went when the clock reaches [member end].
func at_end(_job: Job) -> String:
	return "late"


## The venue's heat went from `was` to `now` (after the job's own notes).
func on_heat(_job: Job, _was: int, _now: int) -> void:
	pass


## A character saw a crew member somewhere (each zone once). Return true
## when it's handled, false for the usual: a stranger in a staff room.
func on_seen(_job: Job, _ch: Character, _c: CrewInfo, _zone: String) -> bool:
	return false


## Someone let this crew member into the back of the house.
func allowed_back(_job: Job, _c: CrewInfo) -> bool:
	return false


## One of Mae's calls went through: do what it does.
func on_mae(_job: Job, _call_id: String, _ch: Character) -> void:
	pass


## Adds the job's own lines to the report (the take is already there).
func report(_job: Job, _outcome: String, _r: Dictionary) -> void:
	pass

#endregion
