class_name MaeHousePartyJob
extends JobDef
## The finale, at Mae's house: her party, and the one job she never briefed
## the crew for. Mae has sold the Rose to Julian Gray behind their backs; he
## sees it in her study at 10:20, takes it up to the toast in his case, and
## drives off after the fireworks. Take it back: with the strongroom's
## combination from Dot, by talking Gray out of the sale (Silas has to back
## the story), by swapping in Silas's second copy when nobody's looking, or
## by turning Mae herself. No calls from Mae tonight: the phone and the
## people in the room are all the crew has.

## The night's moments.
const VIEWING := 22 * 60 + 20
const ROSE_OUT := 22 * 60 + 23
const DEAL := 22 * 60 + 27
const TOAST := 22 * 60 + 32
const FIREWORKS := 22 * 60 + 35
const FIREWORKS_END := 22 * 60 + 40
const LEAVING := 22 * 60 + 45
const DRIVE_OFF := 22 * 60 + 50
## Real seconds: Mae looking the stone over before she runs after Gray, Gray
## at his car before he drives off without it, and the longest Mae takes to
## fetch the Rose for the crew.
const MAE_LOOKS := 12.0
const GRAY_WAITS := 10.0
const GIVE_WAIT := 45.0
## Game minutes Mae dances to her song.
const DANCE := 3.0
## Where the stone lies at each stage, the Rose or Silas's copy in its place.
const PLACES := {
	"safe": {"rose": "safe_shelf", "copy": "copy_safe"},
	"desk": {"rose": "desk", "copy": "copy_desk"},
	"case": {"rose": "case", "copy": "copy_case"},
}
## Where Mae stands to fetch the stone from each place.
const FETCH := {"safe": "safe_in", "desk": "mae_desk", "case": "mae_toast", "gray": "mae_street"}
## Who'd see a hand going for the Rose.
const WATCHERS := ["mae", "julian", "brock", "dot"]
## The toast's spots and the fireworks', by who stands there.
const TOAST_SPOTS := {"mae": "mae_toast", "julian": "julian_toast", "brock": "brock_toast", "dot": "dot_toast",
	"celeste": "celeste_toast", "hugo": "hugo_toast", "silas": "silas", "nadia": "nadia"}
const FIREWORK_SPOTS := {"mae": "mae_fw", "julian": "julian_fw", "brock": "brock_fw", "dot": "dot_fw",
	"celeste": "celeste_fw", "hugo": "hugo_fw", "silas": "silas_fw", "nadia": "nadia_fw"}
## Out of Mae's house.
const OUTSIDE := ["street", "alley"]
## What Mae remembers of each job the crew pulled off this season.
const SEASON := {
	"meridian_gala": "the gala at the Meridian, talking their way into the ballroom",
	"meridian_list": "the Halvorsens' guest list, out of the manager's office",
	"meridian_case": "the Rose's display case, swapped for your copy under Halberd's nose",
	"marlin_aboard": "getting aboard the Marlin as crew",
	"marlin_safe": "the captain's safe on the Marlin",
	"marlin_auction": "the charity auction on the Marlin",
	"tideline_count": "the Tideline's count room",
	"tideline_favor": "the pit boss's favor at the Tideline",
	"tideline_vault": "the Tideline's vault",
	"vantage_lift": "the lift at Vantage Tower",
	"vantage_board": "the board meeting at Vantage Tower",
	"vantage_research": "the Rose itself, off Vantage Tower's research floor before they could cut it",
}
## How each ending leaves the Rose, Mae and the buyer, what became of them,
## and Mae's last word, for the report and an ending screen.
const ENDINGS := {
	"forgiven": {"rose": "crew", "mae": "forgiven", "buyer": "refunded", "mae_says": "Go on, love. Before I change my mind.",
		"epilogue": "Mae gave Julian Gray his money back on the pavement and sent him home. The Halvorsens still want the street, but Mae has a crew who said they'd help, and she's holding you to it."},
	"back": {"rose": "crew", "mae": "ruined", "buyer": "waiting", "mae_says": "You were always my best, love. That's what hurts.",
		"epilogue": "Gray waited upstairs for a stone that never came. Mae paid him back with the laundrette's money, and the Halvorsens had the building by spring. She still sends you a card at Christmas."},
	"ruined": {"rose": "crew", "mae": "ruined", "buyer": "walked", "mae_says": "Paste. In my house. You could have just asked, love.",
		"epilogue": "By morning every buyer in Caldera had heard that Mae sells paste. Nobody's rung the back room since. Silas says she sits in the laundrette most nights, folding other people's shirts."},
	"swapped": {"rose": "crew", "mae": "fooled", "buyer": "fooled", "mae_says": "Wasn't that a lovely night? Come again next year.",
		"epilogue": "Gray found Silas's copy out under a loupe a week later, and he's coming for Mae, not you: she sold it to him. Mae kept the money and bought the building. She still thinks you came for the stew."},
	"gone": {"rose": "buyer", "mae": "rich", "buyer": "paid", "mae_says": "Business, love. I taught you that too.",
		"epilogue": "Gray sailed at midnight with the Rose. Mae bought the building in the morning and never said a word about your share. The sign over the laundrette's been repainted."},
	"kept": {"rose": "mae", "mae": "kept", "buyer": "waiting", "mae_says": "More stew, love? No? Then off you go.",
		"epilogue": "The party ended with the Rose still Mae's. She'll find another buyer, and now she knows that you know."},
	"held": {"rose": "buyer", "mae": "rich", "buyer": "paid", "mae_says": "I'm sorry it came to this, love. I really am.",
		"epilogue": "You spent the fireworks in Mae's back room with Brock on the door. Mae never came down, and by the time he let you go, Gray's car was gone."},
}


func _init() -> void:
	id = "mae_party"
	venue_id = "mae"
	number = 1
	title = "The house party"
	venue_name = "Mae's house"
	memory_from = ["meridian", "marlin", "tideline", "vantage"]
	briefer = "Benny"
	briefer_voice = "am_michael"
	briefing = "It's Benny. Mae doesn't know I'm calling, and she can never know. She's sold the Rose, the one you took from Vantage Tower, to a buyer called Julian Gray, and your share went with it. He collects it tonight at her party and he's gone after the fireworks. It's in the strongroom off her study. Dot might know the dial, Silas made the copies, and Gray is scared to death of buying another fake. Or talk to Mae. She taught you everything, so don't lie to her. Just come to the party."
	goal = "Take the Rose back before Gray leaves with it"
	situation = MaeCast.SITUATION
	prize = "the Rose"
	take = 25000
	start = 22 * 60
	end = 23 * 60
	end_text = "the end of the party"
	covers = {
		"crew": {
			"title": "One of the crew",
			"names": ["Nicky Lane", "Nicky Lane"],
			"job": "one of Mae's crew, at her party like every year",
			"story": "Mae invited the whole crew, like every year. She doesn't know you know. Don't lie to her: she taught you how.",
			"outfit": "party",
			"for": "Mae herself, Dot and Silas",
			"lines": [
				"Mae, you look wonderful. Lovely party.",
				"We know you sold the Rose, Mae. Benny told us.",
				"Is it the laundrette? We'll help you keep it.",
				"Silas, Mae's cut you out of the sale.",
			],
		},
		"appraiser": {
			"title": "Gem appraiser",
			"names": ["Martin Shaw", "Martha Shaw"],
			"job": "a gemologist from the Caldera Assay Office",
			"story": "Gray's a careful buyer who was burned once. A quiet word from someone who looks at stones for a living might be just what he's afraid of.",
			"outfit": "appraiser",
			"for": "Julian Gray, the buyer",
			"lines": [
				"%s, Caldera Assay Office. I look at stones for a living.",
				"Remember Antwerp, Mr Gray?",
				"The stone Mae's selling you is paste. Silas made it.",
				"Ask Silas if you don't believe me.",
			],
		},
		"help": {
			"title": "Party help",
			"names": ["Joey Pike", "Josie Pike"],
			"job": "help Dot took on for the night, carrying trays",
			"story": "Dot always takes on help for Mae's party. Nobody looks twice at whoever's clearing glasses, even in Mae's study.",
			"outfit": "help",
			"for": "Dot in the kitchen, and anyone in the study",
			"lines": [
				"Dot, that stew smells amazing.",
				"Mae's not herself tonight, is she? I'm worried about her.",
				"Do you know the combination to the strongroom?",
				"Just clearing glasses from the study.",
			],
		},
	}
	cover_order = ["crew", "appraiser", "help"]
	outfits = {
		"party": {"job": "party_guest", "male": "a dark suit with an open collar", "female": "a party dress"},
		"appraiser": {"job": "appraiser", "male": "a tweed jacket, with a loupe on a cord", "female": "a tweed jacket, with a loupe on a cord"},
		"help": {"job": "party_help", "male": "a black shirt and an apron, carrying a tray", "female": "a black shirt and an apron, carrying a tray"},
	}
	staff_looking = ["help"]
	staff_rooms = {"study": "Mae's study"}
	looks = {
		"party_guest": {"outfit": 2, "main": Color(0.3, 0.12, 0.1), "accent": Color(0.7, 0.55, 0.3), "shirt": Color(0.9, 0.88, 0.84),
			"tie": Color(0.9, 0.88, 0.84), "wardrobe": {"male": "halberd_suit", "female": "evening_dress"}, "hide": ["Pin", "Earpiece", "Tie"],
			"palette": [Color(0.3, 0.12, 0.1), Color(0.12, 0.2, 0.3), Color(0.42, 0.3, 0.12), Color(0.1, 0.24, 0.18), Color(0.32, 0.1, 0.26),
				Color(0.18, 0.18, 0.2), Color(0.5, 0.2, 0.14), Color(0.08, 0.08, 0.1)]},
		"appraiser": {"outfit": 2, "main": Color(0.4, 0.31, 0.2), "legs": Color(0.22, 0.2, 0.18), "accent": Color(0.2, 0.32, 0.22),
			"shirt": Color(0.86, 0.84, 0.78), "tie": Color(0.2, 0.32, 0.22), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
		"party_help": {"outfit": 4, "main": Color(0.1, 0.1, 0.11), "accent": Color(0.5, 0.4, 0.3), "shirt": Color(0.06, 0.06, 0.07)},
		"mae_cook": {"outfit": 1, "main": Color(0.55, 0.18, 0.14), "legs": Color(0.16, 0.15, 0.2), "accent": Color(0.85, 0.7, 0.3), "shirt": Color(0.86, 0.82, 0.72)},
		"bodyguard": {"outfit": 3, "main": Color(0.06, 0.06, 0.07), "legs": Color(0.06, 0.06, 0.07), "accent": Color(0.08, 0.08, 0.09),
			"shirt": Color(0.12, 0.12, 0.13), "tie": Color(0.04, 0.04, 0.045), "wardrobe": "halberd_suit", "hide": ["Pin"]},
		"buyer": {"outfit": 2, "main": Color(0.55, 0.56, 0.58), "legs": Color(0.5, 0.51, 0.53), "accent": Color(0.3, 0.1, 0.35),
			"shirt": Color(0.95, 0.95, 0.95), "tie": Color(0.32, 0.12, 0.36), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
	}
	extras = {"living": "party_guest", "kitchen": "party_guest", "terrace": "party_guest", "laundrette": "party_guest", "street": "party_guest"}
	for l in MaeCast.CHATTER:
		chatter.append([22 * 60 + int(l[0]), l[1], l[2], l[3]])
	events = [
		[VIEWING, "viewing"], [ROSE_OUT, "rose_out"], [DEAL, "deal"], [TOAST, "toast"],
		[FIREWORKS, "fireworks"], [FIREWORKS_END, "fireworks_end"], [LEAVING, "leaving"], [DRIVE_OFF, "drive_off"],
	]
	locked = ["safe"]
	unlocked = ["front", "back_room", "yard", "gate", "study", "terrace"]
	open = ["terrace"]
	lockdown_doors = ["front", "yard", "gate"]
	lockdown_text = "Brock's locked the doors. Nobody leaves Mae's until he says so."
	door_texts = {
		"safe": "Mae's strongroom. There's a dial beside the door.",
		"front": "Locked. Brock has the key.",
		"yard": "Locked. Brock has the key.",
		"gate": "Locked, and it sticks.",
	}
	keypads = {"dial": {"door": "safe", "code": MaeCast.COMBINATION, "for": 40.0, "label": "Mae's strongroom"}}
	office = {"door": "back_room", "held": "held", "guard": "held_guard", "name": "Mae's back room"}
	held_text = "Brock's ringing Gray's people to come and collect you. Talk your way out before they get here."
	cool_words = ["mae"]
	items = {
		"rose": {"name": "the Rose", "at": "safe_shelf", "carry": "", "hot": true},
		"copy": {"name": "Silas's copy of the Rose", "at": "drawer", "carry": ""},
	}
	actions = {
		"give_back": {"text": "give the crew the Rose back tonight, and call off the sale", "kind": "opening"},
		"call_off": {"text": "call off the sale: you won't pay for a stone you think is paste", "kind": "opening"},
		"ask_silas": {"text": "ring Silas Venn and ask him straight out whether Mae's stone is one of his copies (takes a moment)", "kind": "check"},
		"ask_mae": {"text": "ask Mae whether she knows them (takes a moment)", "kind": "check"},
		"play_song": {"text": "put on the song they asked for", "kind": ""},
	}
	phone = [
		{"id": "mae", "name": "Auntie Mae", "who": "mae"},
		{"id": "silas", "name": "Silas Venn", "who": "silas"},
		{"id": "gray", "name": "Julian Gray", "who": "julian"},
		{"id": "dot", "name": "Dot", "who": "dot"},
		{"id": "benny", "name": "Benny", "who": "benny"},
	]
	caller_ids = ["Withheld", "Caldera Assay Office", "Silas Venn", "Halberd Security", "Tanner Street Laundrette"]
	mae_calls = []
	outcomes = {
		"forgiven": ["MAE'S BLESSING", "Mae put the Rose in your hand at %s, and Gray went home without it."],
		"back": ["THE ROSE IS BACK", "Out of Mae's house with the Rose at %s, and Gray still waiting upstairs."],
		"ruined": ["PASTE, HE SAID", "Gray walked out sure the Rose was paste, and the Rose walked out with you at %s."],
		"swapped": ["A VERY GOOD COPY", "Silas's copy went home in Gray's case, and the Rose is yours. It's %s."],
		"gone": ["GONE WITH GRAY", "Gray drove off at %s with the Rose in his case."],
		"kept": ["MAE KEEPS IT", "The party's over, and the Rose is still Mae's. So is your share."],
		"held": ["IN THE BACK ROOM", "The whole crew ended up in Mae's back room, with Brock on the door."],
	}
	wins = ["forgiven", "back", "ruined", "swapped"]


func venue() -> Venue:
	return MaeHouse.new()


func cast() -> Array[CharacterSheet]:
	return MaeCast.all()


## How Mae feels about the crew after the season: "proud" (most of it pulled
## off, and clean), "sore" (Halberd has one of their faces) or "fond".
func season_mood() -> String:
	if Progress.burned:
		return "sore"
	var jobs: Array = Progress.done.keys().filter(func(j): return j != id)
	var clean := jobs.filter(func(j): return bool(Progress.done[j].get("clean", false))).size()
	if jobs.size() >= 6 and clean * 2 >= jobs.size():
		return "proud"
	return "fond"


func setup(job: Job) -> void:
	job.flags["away"] = []
	job.flags["mood"] = season_mood()
	var mae: Character = job.cast.get("mae")
	if mae:
		match str(job.flags.mood):
			"sore":
				mae.sheet.start_suspicion = mini(3, mae.sheet.start_suspicion + 1)
				mae.note("One of your crew got held this season, and Halberd has their face on file now. It cost you to keep it quiet, and you're still sore about it.")
			"proud":
				mae.note("This crew pulled off more for you this season than anyone ever has, and clean. You've never been prouder of anyone, which makes tonight worse.")
			_:
				mae.note("You trained this crew yourself this season. You're fond of them, whatever you're doing tonight.")
		var did: Array = []
		for j in SEASON:
			if Progress.done.has(j):
				did.append(SEASON[j])
		if not did.is_empty():
			mae.note("This season your crew pulled off %s." % "; ".join(PackedStringArray(did)))
		for c in job.crew:
			mae.note("%s is one of your crew. You'd know them anywhere, whatever they're wearing." % job.describe(c.id).capitalize())
	job.show_node("GrayCase", false)
	job.show_node("Fireworks", false)


#region Using things

func use(job: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"plans":
			return "The plans of every job this season, pinned up in Mae's hand. Vantage Tower's is still on top."
		"kettle":
			return "Mae's kettle. Still warm."
		"records":
			return "Thirty years of Mae's records. The sleeve for Caldera Moon is empty: it's on the decks."
		"files":
			return "Mae's file on the crew. Every job this season is in it, in her hand, and on the first page: The best I ever had."
		"item:rose":
			return _take_rose(job, c)
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	match what:
		"plans":
			return "Look at the plans"
		"kettle":
			return "Feel the kettle"
		"records":
			return "Look through the records"
		"files":
			return "Read Mae's file on the crew"
		"dial":
			return "Turn the dial"
		"item:rose":
			if "copy" in c.items:
				return "Swap the Rose for Silas's copy"
	return null


## A hand going for the Rose, wherever it lies: not with Mae, Gray, Brock or
## Dot watching; with Silas's copy in the other hand it's a swap.
func _take_rose(job: Job, c: CrewInfo) -> Variant:
	var at := str(job.items.get("rose", {}).get("at", ""))
	if at == "" or job.holder("rose") != null:
		return null
	var eyes := watching(job, c, WATCHERS)
	if not eyes.is_empty():
		for ch in eyes:
			var f: Dictionary = ch.face_of(c.id)
			JobRules.nudge(f, 1)
			job.faced.emit(c.id, ch.sheet.id, int(f.suspicion))
			ch.event("%s reaches for the Rose." % job.describe(c.id).capitalize(), c.id, "seen")
		return "Not with %s watching." % eyes[0].sheet.name
	if "copy" in c.items:
		var place := ""
		for p in PLACES:
			if PLACES[p].rose == at:
				place = p
		if place != "":
			job.give_item(c.id, "rose")
			job.place_item(c.id, "copy", PLACES[place].copy)
			job.flags["swapped"] = true
			job.tools_used += 1
			return "You swap the Rose for Silas's copy. Nobody saw."
	job.give_item(c.id, "rose")
	return "You take the Rose."


## Which of `ids` can see a crew member now.
static func watching(job: Job, c: CrewInfo, ids: Array) -> Array:
	var out: Array = []
	if job.venue == null or not job.venue.is_inside_tree():
		return out
	var space := job.venue.get_world_3d().direct_space_state
	for char_id in ids:
		var ch: Character = job.cast.get(char_id)
		if ch and ch.look([c], space).has(c.id):
			out.append(ch)
	return out

#endregion

#region What people do

func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"give_back":
			_give_back(job, ch, c)
			return true
		"call_off":
			_call_off(job, ch, c)
			return true
		"play_song":
			_song(job, ch)
			return true
	return false


## Mae gives the Rose back to someone who knows what she did and offers her
## a way to keep the laundrette; anyone else gets a no.
func _give_back(job: Job, mae: Character, c: CrewInfo) -> void:
	var said := ""
	for other in job.crew:
		said += " " + job.told(mae, other.id)
	if not (Job.any(said, MaeCast.KNOWS_WORDS) and Job.any(said, MaeCast.HELP_WORDS)):
		(mae.face_of(c.id).opened as Array).erase("give_back")
		mae.say_scripted("It's sold, love. Leave it.")
		return
	if job.flags.has("giving") or job.flags.has("forgiven"):
		return
	mae.say_scripted("Thirty years on this street, and it's you lot who'd save it. Wait here, love.")
	var h := job.holder("rose")
	if h:
		job.flags["forgiven"] = true
		job.toast_for.emit(c.id, "Mae knows you've got it. She lets you keep it.")
		return
	var where := _stone_where(job)
	job.flags["giving"] = c.id
	job.flags["give_t"] = 0.0
	job.flags["give_at"] = str(FETCH.get(where, "mae"))
	_away(job, "mae")
	mae.walk_to(str(job.flags.give_at))
	job.toast_for.emit(c.id, "Mae's gone to fetch the Rose for you.")
	var gray: Character = job.cast.get("julian")
	if gray:
		gray.note("Mae says the sale's off. She's giving you your money back.")


## Mae hands it over, wherever she found it.
func _hand_over(job: Job, mae: Character) -> void:
	var to := int(job.flags.giving)
	job.flags.erase("giving")
	if job.holder("rose") == null:
		job.give_item(to, "rose")
	job.flags.erase("gray_has")
	job.show_node("GrayCase", false)
	mae.say_scripted(str(ENDINGS.forgiven.mae_says))
	job.toast_for.emit(to, "Mae puts the Rose in your hand.")
	job.flags["forgiven"] = true


## Gray won't pay for paste: he leaves, and Mae has to see the stone for
## herself before she runs down after him.
func _call_off(job: Job, gray: Character, _c: CrewInfo) -> void:
	if job.flags.has("no_sale") or job.flags.has("gray_gone"):
		return
	job.flags["no_sale"] = true
	gray.say_scripted("Tell Mae the sale's off. I won't be made a fool of twice.")
	_away(job, "julian")
	gray.walk_to("gray_car")
	var brock: Character = job.cast.get("brock")
	if brock and not brock.minding:
		_away(job, "brock")
		brock.walk_to("brock_car")
	job.show_node("GrayCase", false)
	job.toast_for.emit(0, "Gray's called off the sale. He's leaving.")
	var mae: Character = job.cast.get("mae")
	if mae and not job.flags.has("giving"):
		mae.note("Julian has called off the sale: someone told him your Rose is paste. You have to see it for yourself.")
		_away(job, "mae")
		mae.walk_to("mae_desk")
		job.flags["mae_check"] = "desk"


func _song(job: Job, jojo: Character) -> void:
	if job.flags.has("song"):
		return
	job.flags["song"] = true
	jojo.say_scripted("This one's for Auntie Mae!")
	job.toast_for.emit(0, "Jojo puts on Caldera Moon. Mae's song.")
	var mae: Character = job.cast.get("mae")
	if mae == null:
		return
	for c in job.crew:
		var f: Dictionary = mae.face_of(c.id)
		f["suspicion"] = maxi(0, int(f.suspicion) - 1)
		job.faced.emit(c.id, "mae", int(f.suspicion))
	mae.note("Jojo's playing Caldera Moon, your song: thirty years of Tanner Street in four minutes. You're feeling soft.")
	if not _is_away(job, "mae") and not mae.minding and job.minutes < VIEWING - DANCE - 1.0:
		mae.walk_to("mae_dance")
		job.flags["dance_until"] = job.minutes + DANCE


## What a colleague answers a check with: Silas, asked by Gray whether
## Mae's stone is one of his; Mae, asked by Brock whether she knows them.
func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	match who:
		"silas":
			if silas_sore(job):
				return Job.fact("good", "You made Mae two copies of the Rose, and tonight she cut you out of the sale. You'd love to see Gray walk away from it.",
					"Did I make Mae a Rose? I made her two, Julian. Which one she's selling you, I couldn't say.")
			return Job.fact("bad", "As far as you know Mae's selling Gray the real Rose, and you've no reason to spoil her deal.",
				"Mae's stone? That's the real thing, Julian. I'd know.")
		"mae":
			var mae: Character = job.cast.get("mae")
			var f: Dictionary = mae.face_of(crew_id) if mae else {}
			if int(f.get("suspicion", 1)) <= 2:
				if Job.any(said, ["assay", "appraiser", "gemologist", "caterer", "dot hired", "agency"]):
					JobRules.nudge(f, 1)
					return Job.fact("good", "Brock's asking about one of your own crew, who told him a cover story. You'd like to know why.",
						"That's one of mine, Brock, whatever they told you. Leave them to me.")
				return Job.fact("good", "That's one of your crew. You invited them.", "That's one of mine, Brock. Leave them be.")
			return Job.fact("bad", "That's one of your crew, and they're up to something tonight.", "I know them. Keep an eye on them for me.")
	return {}


## Someone's told Silas that Mae cut him out of the sale.
func silas_sore(job: Job) -> bool:
	var silas: Character = job.cast.get("silas")
	if silas == null:
		return false
	for c in job.crew:
		if Job.any(job.told(silas, c.id), MaeCast.CUT_WORDS):
			return true
	return false


func on_seen(job: Job, ch: Character, c: CrewInfo, _zone: String) -> bool:
	# Mae knows her crew in any clothes, and wonders why they're in these.
	if ch.sheet.id == "mae" and c.outfit in ["help", "appraiser"] and not c.flags.has("mae_saw"):
		c.flags["mae_saw"] = true
		var f: Dictionary = ch.face_of(c.id)
		JobRules.nudge(f, 1)
		job.faced.emit(c.id, "mae", int(f.suspicion))
		ch.event("One of your own crew, %s, is dressed as %s tonight. What are they up to?" % [job.describe(c.id), Covers.wearing(c.outfit, c.female)], c.id, "event")
	return false


func allowed_back(job: Job, c: CrewInfo) -> bool:
	return int(job.flags.get("giving", 0)) == c.id

#endregion

#region The night

func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"viewing":
			if _sale_off(job):
				return
			_walk(job, "mae", "mae_desk")
			_walk(job, "julian", "julian_study")
			_walk(job, "brock", "brock_study")
			job.toast_for.emit(0, "Mae's taking Gray into her study to see the Rose.")
		"rose_out":
			if _sale_off(job):
				return
			if _stone_where(job) == "safe":
				job.open_for("safe", 6.0)
				_move_stone(job, "desk")
				_say(job, "mae", "There she is, Julian. Isn't she lovely?")
				var gray: Character = job.cast.get("julian")
				if gray:
					gray.note("Mae has put the Rose on her desk for you to look at.")
			else:
				_alarm(job, "Mae opens her strongroom and finds the shelf empty. The Rose is gone.")
		"deal":
			if _sale_off(job) or job.flags.has("alarm"):
				return
			if _stone_where(job) == "desk":
				_move_stone(job, "case")
				job.show_node("GrayCase", true)
				_walk(job, "mae", "mae_toast")
				_walk(job, "julian", "julian_toast")
				_walk(job, "brock", "brock_toast")
				job.toast_for.emit(0, "Gray has the Rose in his case. They're taking it up to the roof for the toast.")
			else:
				_alarm(job, "The Rose is gone from Mae's desk.")
		"toast":
			for char_id in ["dot", "celeste", "hugo"]:
				_walk(job, char_id, TOAST_SPOTS[char_id])
			if not _is_away(job, "mae"):
				_walk(job, "mae", "mae_toast")
				_say(job, "mae", "To thirty years on Tanner Street, and to old friends. Drink up, the lot of you.")
			job.toast_for.emit(0, "Mae's toast, up on the roof terrace.")
		"fireworks":
			job.flags["fireworks"] = true
			job.show_node("Fireworks", true)
			for char_id in FIREWORK_SPOTS:
				var ch: Character = job.cast.get(char_id)
				if ch and _free(job, char_id) and (str(ch.post) == str(TOAST_SPOTS[char_id]) or job.venue.zone_at(ch.global_position + Vector3.UP) == "terrace"):
					ch.walk_to(FIREWORK_SPOTS[char_id])
			job.toast_for.emit(0, "Fireworks over the river. Everyone on the roof is looking up.")
		"fireworks_end":
			job.flags.erase("fireworks")
			job.show_node("Fireworks", false)
			for char_id in FIREWORK_SPOTS:
				var ch: Character = job.cast.get(char_id)
				if ch and _free(job, char_id) and str(ch.post) == str(FIREWORK_SPOTS[char_id]):
					ch.walk_to(TOAST_SPOTS[char_id])
		"leaving":
			if _sale_off(job) or job.flags.has("gray_gone"):
				return
			if _stone_where(job) == "case":
				var it := _stone(job)
				job.place_item(0, it, "")
				job.flags["gray_has"] = it
				job.show_node("GrayCase", false)
				_walk(job, "julian", "gray_car")
				_walk(job, "brock", "brock_car")
				_walk(job, "mae", "mae_street")
				_away(job, "julian")
				job.toast_for.emit(0, "Gray's leaving, with his case.")
			else:
				_alarm(job, "Julian opens his case to leave and finds it empty.")
		"drive_off":
			if job.flags.has("gray_gone"):
				return
			var has := str(job.flags.get("gray_has", ""))
			_drive_off(job)
			if has == "rose":
				job.finish("gone")
			elif has == "copy" and job.holder("rose") != null:
				job.finish("swapped")


func tick(job: Job, delta: float) -> void:
	var mae: Character = job.cast.get("mae")
	if job.flags.has("giving") and mae:
		job.flags["give_t"] = float(job.flags.give_t) + delta
		if arrived(job, mae, str(job.flags.give_at)) or float(job.flags.give_t) >= GIVE_WAIT:
			_hand_over(job, mae)
	if job.flags.has("dance_until") and mae and job.minutes >= float(job.flags.dance_until):
		job.flags.erase("dance_until")
		if str(mae.post) == "mae_dance" and not _is_away(job, "mae"):
			mae.walk_to("mae")
	if job.flags.has("no_sale"):
		_no_sale(job, mae, delta)


## After Gray calls it off: Mae looks at the stone at her desk, then runs
## down after him; he waits at his car a moment, then drives off.
func _no_sale(job: Job, mae: Character, delta: float) -> void:
	var step := str(job.flags.get("mae_check", ""))
	if mae and step == "desk" and arrived(job, mae, "mae_desk"):
		if _stone_where(job) in ["safe", "case", "gray"]:
			_move_stone(job, "desk")
		job.flags.erase("gray_has")
		job.flags["mae_check"] = "looking"
		job.flags["look_t"] = 0.0
		mae.say_scripted("Paste? My Rose? Let me look at you.")
	elif mae and step == "looking":
		job.flags["look_t"] = float(job.flags.look_t) + delta
		if float(job.flags.look_t) >= MAE_LOOKS:
			job.flags["mae_check"] = "street"
			mae.say_scripted("Julian! Wait, Julian, it's real!")
			mae.walk_to("mae_street")
			job.toast_for.emit(0, "Mae's run down after Gray. The Rose is on her desk.")
	var gray: Character = job.cast.get("julian")
	if gray and not job.flags.has("gray_gone") and arrived(job, gray, "gray_car"):
		job.flags["gray_wait"] = float(job.flags.get("gray_wait", 0.0)) + delta
		if float(job.flags.gray_wait) >= GRAY_WAITS:
			_drive_off(job)


## Gray's car pulls away (Brock with him, unless he's minding someone).
func _drive_off(job: Job) -> void:
	job.flags["gray_gone"] = true
	_away(job, "julian")
	_away(job, "brock")
	var gray: Character = job.cast.get("julian")
	if gray:
		gray.walk_to("gone")
	var brock: Character = job.cast.get("brock")
	if brock and not brock.minding:
		brock.walk_to("gone")
	job.show_node("GrayCar", false)
	job.toast_for.emit(0, "Gray's car pulls away.")


## The stone's gone missing: Mae, Gray and Brock turn on the crew, and
## Brock watches the front door.
func _alarm(job: Job, text: String) -> void:
	if job.flags.has("alarm"):
		return
	job.flags["alarm"] = true
	for char_id in ["mae", "julian", "brock"]:
		var ch: Character = job.cast.get(char_id)
		if ch == null:
			continue
		ch.note(text)
		for c in job.crew:
			var f: Dictionary = ch.face_of(c.id)
			if bool(f.met) or char_id == "mae":
				f["suspicion"] = maxi(int(f.suspicion), 3)
				job.faced.emit(c.id, char_id, int(f.suspicion))
	job.heat.bump(Heat.CAUGHT)
	_walk(job, "brock", "front_guard")
	job.toast_for.emit(0, "The Rose is missing, and Mae knows it. Brock's watching the front door.")


func on_heat(job: Job, was: int, now: int) -> void:
	if now >= Heat.LOCKDOWN and was < Heat.LOCKDOWN:
		for d in lockdown_doors:
			job.lock(d, true)
		_walk(job, "brock", "front_guard")
	elif was >= Heat.LOCKDOWN and now < Heat.LOCKDOWN:
		for d in lockdown_doors:
			job.lock(d, false)


func check_end(job: Job) -> String:
	if job.flags.has("forgiven"):
		return "forgiven"
	var h := job.holder("rose")
	if h and not h.held and h.node and job.venue.zone_at(h.position()) in OUTSIDE:
		return _taken(job)
	return ""


func at_end(job: Job) -> String:
	var h := job.holder("rose")
	if h and not h.held:
		return _taken(job)
	if str(job.flags.get("gray_has", "")) == "rose":
		return "gone"
	return "kept"


## How the crew came by the Rose: Gray talked out of it, a swap, or simply taken.
func _taken(job: Job) -> String:
	if job.flags.has("no_sale"):
		return "ruined"
	if job.flags.has("swapped"):
		return "swapped"
	return "back"


func report(job: Job, outcome: String, r: Dictionary) -> void:
	var e: Dictionary = ENDINGS.get(outcome, {})
	if e.is_empty():
		return
	var buyer := str(e.buyer)
	if outcome in ["kept", "held"]:
		buyer = "walked" if job.flags.has("no_sale") else ("paid" if str(job.flags.get("gray_has", "")) == "rose" else "waiting")
	r["ending"] = {"rose": str(e.rose), "mae": str(e.mae), "buyer": buyer}
	r["epilogue"] = str(e.epilogue)
	r["mae_says"] = str(e.mae_says)
	r["mood"] = str(job.flags.get("mood", "fond"))

#endregion

#region Helpers

## The stone Mae and Gray think is the Rose: Silas's copy once it's been swapped in.
func _stone(job: Job) -> String:
	return "copy" if job.flags.has("swapped") else "rose"


## Where that stone is: "safe", "desk", "case", "gray" (in his hands),
## "crew" or "" (nowhere it should be).
func _stone_where(job: Job) -> String:
	var it := _stone(job)
	if job.holder(it) != null:
		return "crew"
	var at := str(job.items.get(it, {}).get("at", ""))
	for p in PLACES:
		if str(PLACES[p][it]) == at:
			return p
	if str(job.flags.get("gray_has", "")) == it:
		return "gray"
	return ""


func _move_stone(job: Job, place: String) -> void:
	var it := _stone(job)
	if job.holder(it) == null:
		job.place_item(0, it, str(PLACES[place][it]))


## The sale's off, or Mae's giving the Rose back: nobody keeps the night's
## appointments with it.
func _sale_off(job: Job) -> bool:
	return job.flags.has("no_sale") or job.flags.has("giving") or job.flags.has("forgiven")


## Someone busy with something of their own, whom the night's moments leave be.
func _away(job: Job, char_id: String) -> void:
	var a: Array = job.flags.get("away", [])
	if not char_id in a:
		a.append(char_id)
	job.flags["away"] = a


func _is_away(job: Job, char_id: String) -> bool:
	return char_id in job.flags.get("away", [])


func _free(job: Job, char_id: String) -> bool:
	var ch: Character = job.cast.get(char_id)
	return ch != null and not ch.minding and not _is_away(job, char_id)


func _walk(job: Job, char_id: String, spot_name: String) -> void:
	if _free(job, char_id):
		job.cast[char_id].walk_to(spot_name)


func _say(job: Job, char_id: String, line: String) -> void:
	var ch: Character = job.cast.get(char_id)
	if ch and not ch.busy and ch.on_call == 0:
		ch.say_scripted(line)


## A character has walked to a spot and stopped there.
static func arrived(job: Job, ch: Character, spot_name: String) -> bool:
	if ch == null or ch.walking or str(ch.post) != spot_name or not job.venue.spots.has(spot_name):
		return false
	return ch.global_position.distance_to(job.spot(spot_name).origin) < 0.3

#endregion
