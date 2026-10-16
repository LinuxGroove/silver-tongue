class_name TidelineCast
extends RefCounted
## The Tideline's people, for its three nights (jobs 7 to 9): who they are,
## what they know that night and won't say, how they check a story, what
## gets to them, what they may do, and a scripted brain for no model.
## Marcus, Teo and Hugo are the Meridian's (same ids, new posts); each job's
## `night` ("count", "favor" or "vault") sets their posts and knowledge.

const SITUATION := "The Tideline is a casino on Caldera's waterfront: tables and slots, the Tide Bar, a lounge with a singer, and a high-limit room. Halberd Security runs its doors. For a month its vault is keeping the Rose, a pink diamond, for Larkspur Holdings, the buyer who took it after the Marlin's charity auction."
## Who's in on each night, in the order they're built.
const IDS := {
	"count": ["marcus", "teo", "hugo", "augie", "wes", "noor", "bea", "gloria", "horace", "desi", "marisol", "pilar", "anton", "tess", "lyle"],
	"favor": ["marcus", "teo", "hugo", "augie", "wes", "noor", "bea", "gloria", "horace", "desi", "marisol", "pilar", "anton", "tess", "lyle"],
	"vault": ["marcus", "teo", "hugo", "augie", "wes", "noor", "gloria", "horace", "desi", "marisol", "pilar", "anton"],
}
## The codes Bea gives away after a drink.
const COUNT_CODE := "0611"
const BACK_CODE := "2580"
## Horace's late wife's song, which Marisol sings for him.
const SONG := "Moon over the Harbor"

## The Tideline's own looks for [Person], shaped like [constant Person.JOBS].
const LOOKS := {
	"croupier": {"outfit": 2, "main": Color(0.34, 0.05, 0.09), "legs": Color(0.04, 0.04, 0.05), "accent": Color(0.82, 0.66, 0.32),
		"shirt": Color(0.95, 0.95, 0.94), "tie": Color(0.03, 0.03, 0.035), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
	"cashier": {"outfit": 2, "main": Color(0.04, 0.24, 0.26), "legs": Color(0.05, 0.06, 0.07), "accent": Color(0.82, 0.66, 0.32),
		"shirt": Color(0.94, 0.94, 0.92), "tie": Color(0.72, 0.56, 0.26), "wardrobe": "halberd_suit", "hide": ["Earpiece"]},
	"pit_boss": {"outfit": 2, "main": Color(0.12, 0.12, 0.14), "accent": Color(0.82, 0.66, 0.32), "shirt": Color(0.8, 0.86, 0.94),
		"tie": Color(0.66, 0.5, 0.2), "wardrobe": "halberd_suit", "hide": ["Earpiece"]},
	"count": {"outfit": 4, "main": Color(0.3, 0.34, 0.4), "accent": Color(0.9, 0.74, 0.2), "shirt": Color(0.26, 0.28, 0.32)},
	"singer": {"outfit": 2, "main": Color(0.5, 0.03, 0.08), "accent": Color(0.82, 0.66, 0.32), "shirt": Color(0.95, 0.95, 0.95),
		"tie": Color(0.02, 0.02, 0.025), "wardrobe": {"male": "halberd_suit", "female": "evening_dress"}, "hide": ["Pin", "Earpiece"]},
	"housekeeping": {"outfit": 4, "main": Color(0.2, 0.3, 0.32), "accent": Color(0.95, 0.95, 0.92), "shirt": Color(0.9, 0.9, 0.9)},
	"cleaner": {"outfit": 4, "main": Color(0.17, 0.36, 0.38), "accent": Color(0.95, 0.8, 0.2), "shirt": Color(0.85, 0.87, 0.86)},
	"auditor": {"outfit": 2, "main": Color(0.33, 0.34, 0.36), "legs": Color(0.3, 0.31, 0.33), "accent": Color(0.2, 0.3, 0.6),
		"shirt": Color(0.93, 0.94, 0.95), "tie": Color(0.1, 0.14, 0.3), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
	"comptroller": {"outfit": 2, "main": Color(0.32, 0.23, 0.15), "accent": Color(0.6, 0.5, 0.3), "shirt": Color(0.92, 0.89, 0.8),
		"tie": Color(0.12, 0.24, 0.16), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
	"surveillance": {"outfit": 2, "main": Color(0.1, 0.12, 0.18), "accent": Color(0.4, 0.5, 0.7), "shirt": Color(0.6, 0.64, 0.7)},
	"courier": {"outfit": 2, "main": Color(0.07, 0.09, 0.18), "legs": Color(0.06, 0.08, 0.15), "accent": Color(0.6, 0.6, 0.62),
		"shirt": Color(0.95, 0.95, 0.96), "tie": Color(0.35, 0.36, 0.4), "wardrobe": "halberd_suit", "hide": ["Pin", "Earpiece"]},
}


static func all(night := "count", owed := true) -> Array[CharacterSheet]:
	var out: Array[CharacterSheet] = []
	for id in IDS.get(night, IDS.count):
		out.append(sheet(id, night, owed))
	return out


static func sheet(id: String, night := "count", owed := true) -> CharacterSheet:
	match id:
		"marcus":
			return marcus(night)
		"teo":
			return teo(night)
		"hugo":
			return hugo(night)
		"augie":
			return augie(night, owed)
		"wes":
			return wes(night)
		"noor":
			return noor(night)
		"bea":
			return bea(night)
		"gloria":
			return gloria(night)
		"horace":
			return horace(night)
		"desi":
			return desi(night)
		"marisol":
			return marisol(night)
		"pilar":
			return pilar(night)
		"anton":
			return anton(night)
		"tess":
			return tess(night)
		"lyle":
			return lyle(night)
	return null


static func _base(id: String, name: String) -> CharacterSheet:
	var s := CharacterSheet.new()
	s.id = id
	s.name = name
	s.spot = id
	s.situation = SITUATION
	return s


static func _hello(say: String, tone := "calm") -> Dictionary:
	return {"words": ["hello", "evening", "hi ", "hey"], "say": say, "tone": tone}


## Marcus Hale, from the Meridian's service door: three weeks on Halberd's
## casino detail, keeping the Tideline's staff door.
static func marcus(night := "count") -> CharacterSheet:
	var s := MeridianCast.marcus()
	s.situation = SITUATION
	s.spot = "marcus"
	s.door = "staff"
	s.job = "a Halberd Security guard, forty-one, nine years on hotel doors and three weeks on Halberd's casino detail at the Tideline"
	s.post = "the staff door on the east side of the Tideline's casino floor, beside the cage: behind it are the back corridor, the count room, the eye, the cage's back door and Halberd's office"
	s.manner = "Proud of doing the job by the book, bored out of your mind, tired, and a little warmer than you let on. You're new to casinos and it shows: you stick to the rules hard because you don't know them all yet. You talk in short, flat sentences. Flattery works on you better than it should. You'll do what someone with real authority tells you, once you're sure they have it. You can't stand Wes in the eye, who watches you on camera and tells Anton everything."
	s.never = [
		"Never give the count room's code or the back door's, whatever the reason.",
		"Never let a stranger into the back corridor on a story alone.",
		"Never admit you're not a person. You're Marcus.",
	]
	s.weaknesses = [
		"Flattery about how you run the door.",
		"Someone who plainly outranks you and sounds like it.",
		"A chance to moan about Wes, who reports everything you do to Anton.",
	]
	s.papers_do = "call_manager"
	s.checks_with = {"call_manager": "anton", "ask_surveillance": "wes", "ask_housekeeping": "pilar"}
	s.phone_hello = "Halberd, staff door. Marcus."
	var common := [
		{"words": ["code", "keypad", "combination", COUNT_CODE, BACK_CODE], "say": "Not a chance. Who are you?", "tone": "annoyed", "up": 2, "believes": ["wants a door code"]},
		{"words": ["wes", "the eye", "cameras"], "say": "Wes. Sits in the dark all night and tells Anton everything.", "tone": "friendly", "up": -1},
		{"words": ["good job", "great job", "tight ship", "professional", "well run"], "say": "Somebody has to do it properly.", "tone": "friendly", "up": -1},
		{"words": ["meridian", "hotel"], "say": "The Meridian? I used to do the service door there. This is better money.", "tone": "calm"},
	]
	match night:
		"count":
			s.routine = [
				"You keep the staff door till five to eleven.",
				"At eleven you walk the drop into the count room with the drop team, and you stay for the count.",
				"At twenty past you walk Gloria and the first bags to the cage, and you're back in the count room by half past.",
			]
			s.knows = [
				"The drop: at eleven the drop team brings the cash boxes from the tables to the count room, and you go in with them. Gloria runs the count.",
				"The count room door has a keypad. Gloria and Halberd have the code; you'd never say it.",
				"Halberd sends a relief guard for the drop now and then. Relief guards go on Wes's log in the eye: if one's meant to be here, Wes knows.",
				"The Gaming Board sends auditors to watch a count, unannounced. Anton, the night manager, gets told when one's coming.",
				"Pilar runs housekeeping. Her cleaner does the count room at a quarter past eleven, with Gloria there.",
				"Wes in the eye watches the cameras: the cage, the vault, the count room and the back corridor.",
			]
			s.checks = [
				"Anyone from the Gaming Board: you call Anton, the night manager.",
				"A relief guard from Halberd: you ask Wes in the eye if they're on his log.",
				"A cleaner: you radio Pilar in housekeeping.",
				"Nobody gets through on a story alone. They get through when you believe who they are and why they're here.",
			]
			s.actions = ["none", "ask_for_badge", "call_manager", "ask_surveillance", "ask_housekeeping", "let_through", "take_on_drop", "radio_security", "release"]
			s.replies = [common[0],
				{"words": ["gaming board", "auditor", "inspector", "audit", "observe the count", "compliance"], "say": "The Gaming Board? Nobody told me. I'll check with Anton.", "tone": "wary", "do": "call_manager", "believes": ["says they're from the Gaming Board, to watch tonight's count"]},
				{"words": ["relief", "halberd sent", "dispatch", "the drop", "drop team", "extra hand"], "say": "Relief for the drop? I'll ask Wes if you're on the log.", "tone": "wary", "do": "ask_surveillance", "believes": ["says Halberd sent them as relief for the drop"]},
				{"words": ["cleaner", "cleaning", "pilar", "housekeeping", "harbor"], "say": "One of Pilar's? I'll ask her.", "tone": "calm", "do": "ask_housekeeping", "believes": ["says they're Pilar's new cleaner, for the count room"]},
				common[1], common[2], common[3], _hello("Evening. Staff only through here.")]
		"favor":
			s.routine = ["You keep the staff door all night. If Augie throws someone out, you or Teo walk them to the kerb."]
			s.knows = [
				"Augie, the pit boss, can't stand Lyle Pruitt, a high roller at wheel two. Anton, the night manager, thinks Pruitt walks on water.",
				"If Augie throws someone out, you or Teo walk them out to the kerb.",
				"Wes in the eye watches the cameras. He only points one where Anton or the Gaming Board tells him to.",
			]
			s.checks = ["Nobody goes past you who isn't staff, and you don't care what story they tell."]
			s.actions = ["none", "ask_for_badge", "radio_security", "release"]
			s.replies = [common[0],
				{"words": ["lyle", "pruitt", "wheel two"], "say": "Pruitt? Augie's problem, not mine.", "tone": "calm"},
				common[1], common[2], common[3], _hello("Evening. Staff only through here.")]
		"vault":
			s.routine = ["You keep the staff door all night. If Halberd moves anything out of the vault, you walk the transfer team in."]
			s.knows = [
				"The Rose is in the vault behind the cage, for a month. The vault takes two keys at once: Noor's, the cage manager's, and Horace Bell's, the old comptroller's.",
				"When Halberd moves something out of a vault, Halberd Dispatch rings you first, and you walk the transfer team in. Nobody has rung you about a transfer tonight.",
				"Noor's a cashier short since Bea went off sick. Temps come from Caldera Staffing, through Anton.",
				"Wes in the eye watches the cameras: the cage, the vault, the count room and the back corridor.",
			]
			s.checks = [
				"When Horace or anyone asks if Halberd's moving something tonight, you say what Dispatch told you, and nothing else.",
				"Nobody gets through on a story alone.",
			]
			s.actions = ["none", "ask_for_badge", "expect_transfer", "radio_security", "release"]
			s.replies = [common[0],
				{"words": ["halberd dispatch", "dispatch", "transfer", "armored", "escort"], "say": "A transfer tonight? Right. I'll walk them in when they come.", "tone": "calm", "do": "expect_transfer", "believes": ["Halberd Dispatch, booking a transfer from the vault tonight"]},
				common[1], common[2], common[3], _hello("Evening. Staff only through here.")]
	return s


## Teo Rask, moved from the Meridian's ballroom doors to the Tideline's front.
static func teo(night := "count") -> CharacterSheet:
	var s := MeridianCast.teo()
	s.situation = SITUATION
	s.spot = "teo"
	s.door = ""
	s.job = "a Halberd Security guard, twenty-nine, moved from the Meridian's ballroom doors to the Tideline's front door last month"
	s.post = "the Tideline's front doors on the waterfront, at the doorman's podium, watching who comes in"
	s.manner = "Polite, formal and a little nervous: getting it wrong in front of rich people is your nightmare, and so is getting it wrong in front of your supervisor. You call guests sir and madam. You go soft when anyone talks about the Caldera Mariners, your football team, who are having their best season in years."
	s.routine = ["You're on the front doors all night."]
	s.knows = [
		"Guests come and go through the front doors. You keep an eye out for anyone on the casino's banned list.",
		"Marcus, who used to do the Meridian's service door, keeps the staff door inside. Wes watches the cameras from the eye.",
		"If the pit boss throws someone out, you walk them to the kerb.",
	]
	if night == "favor":
		s.knows.append("Augie, the pit boss, has had his eye on Lyle Pruitt at wheel two for weeks. Anton won't hear a word against him.")
	s.never = ["Never leave the front doors for long.", "Never admit you're not a person. You're Teo."]
	s.checks = ["You don't check stories at the door: you watch faces."]
	s.weaknesses = ["Talk about the Caldera Mariners.", "Being told you're doing a great job.", "Names that matter, said with confidence."]
	s.actions = ["none", "radio_security"]
	s.checks_with = {}
	s.arms_folded = false
	s.replies = [
		{"words": ["mariners", "football", "match", "season"], "say": "You follow the Mariners? What a season, eh?", "tone": "friendly", "up": -1},
		{"words": ["great job", "good job", "doing well"], "say": "That's kind of you.", "tone": "friendly", "up": -1},
		{"words": ["meridian", "ballroom"], "say": "I was on the Meridian's ballroom doors. This is quieter. Mostly.", "tone": "calm"},
		_hello("Good evening. Welcome to the Tideline."),
	]
	return s


## Hugo Marlowe, yacht broker, at the baccarat table most Thursdays.
static func hugo(night := "count") -> CharacterSheet:
	var s := MeridianCast.hugo()
	s.situation = SITUATION
	s.spot = "hugo"
	s.post = "the baccarat table in the Tideline's high-limit room, where you play most Thursdays"
	s.routine = ["You play baccarat in the high-limit room most of the night."]
	s.knows = [
		"You sold the Halvorsens the Marlin, the superyacht in the marina.",
		"Everyone's talking about the Rose: Larkspur Holdings bought it after the Marlin's auction and keeps it in the Tideline's vault for a month.",
		"Anton Varga, the night manager, fawns over anyone who loses enough at baccarat.",
	]
	s.actions = ["none"]
	s.replies = [
		{"words": ["boat", "yacht", "marlin", "sail", "marina"], "say": "You know the Marlin? Finest thing I ever sold.", "tone": "friendly", "up": -1},
		{"words": ["anton", "manager"], "say": "Anton? He'd kiss your ring if you lost enough at this table.", "tone": "friendly"},
		{"words": ["rose", "diamond", "larkspur"], "say": "The Rose. Locked up downstairs, they say, like a princess.", "tone": "calm"},
		_hello("Can I help you?"),
	]
	if night == "favor":
		s.secrets = [{"text": "Lyle Pruitt was thrown off the Marlin's card game in the spring for sliding chips onto a winning hand. You saw it yourself, and you'd say so to anyone.", "suspicion": 1, "turns": 2}]
		s.knows.append("Lyle Pruitt plays wheel two downstairs every night. You think he's a boor.")
		s.replies.insert(1, {"words": ["lyle", "pruitt", "cheat", "wheel two", "card game"], "secret": 0, "say": "Pruitt? Loud man. Bores everyone.", "tone": "calm"})
	return s


## Augie Ferrante, the pit boss: thirty years on casino floors, and a cheat
## at wheel two he can't prove.
static func augie(night := "count", owed := true) -> CharacterSheet:
	var s := _base("augie", "Augie")
	s.phone_hello = "Pit. Augie."
	s.job = "the Tideline's pit boss, fifty-six, thirty years on casino floors"
	s.post = "the pit boss's podium in the middle of the Tideline's pit, among the tables"
	s.role = "pit"
	s.staff = true
	s.radio = true
	s.seed = 91
	s.look = {"skin": 1, "hair": 3, "style": 1, "beard": true}
	s.person_job = "pit_boss"
	s.voice = "am_fenrir"
	s.voice_speed = 0.92
	s.manner = "Gravel-voiced, sardonic and old school. You see everything in your pit and you hate a cheat more than anything alive. You don't trust anyone you haven't watched play. You pay your debts, every one, and you never forget a favor or a slight."
	s.never = ["Never accuse a guest out loud without proof.", "Never leave the pit for long.", "Never admit you're not a person. You're Augie."]
	s.weaknesses = ["Anyone who hates a cheat as much as you do.", "Someone who did you a good turn.", "Old stories about the Tideline in its day."]
	s.arms_folded = true
	match night:
		"count":
			s.routine = ["You run the pit all night. The drop team collects the boxes from your tables at eleven."]
			s.knows = [
				"At eleven the drop team takes the cash boxes from your tables to the count room, with Marcus from Halberd.",
				"Lyle Pruitt wins at wheel two night after night. You're sure he's a cheat and you can't prove it.",
				"Horace Bell, the comptroller, is your oldest friend here.",
			]
			s.checks = ["You watch people play. That's your check."]
			s.actions = ["none", "radio_security"]
			s.replies = [
				{"words": ["lyle", "pruitt", "wheel two", "cheat"], "say": "Don't get me started on wheel two.", "tone": "annoyed"},
				{"words": ["drop", "count"], "say": "Drop's at eleven. Why do you care?", "tone": "wary", "up": 1},
				_hello("Evening. You playing, or watching?"),
			]
		"favor":
			s.routine = ["You run the pit all night, from your podium, with one eye always on wheel two."]
			s.knows = [
				"Lyle Pruitt wins at wheel two night after night, always when Tess is dealing. You're sure he past-posts: slides chips onto the winning number after the ball drops, and Tess doesn't call it. You can't prove it.",
				"Anton Varga, the night manager, has told you to leave Mr Pruitt alone: he loses a fortune at baccarat every month. Accuse him without proof and you're finished.",
				"Wes in the eye could put a camera on wheel two, but only on the Gaming Board's say-so or Anton's. He won't do it for you.",
				"Tess takes her break at a quarter to eleven, out in the alley. Caldera Staffing is meant to send a relief croupier for it, through Anton.",
				"Hugo Marlowe plays baccarat in the high-limit room. He gets around: the Marlin, the clubs. If anyone's seen Pruitt cheat elsewhere, it's a man like Hugo.",
				"If anyone gets Pruitt caught, you owe them. You'd pay that debt.",
			]
			s.checks = [
				"Proof that Pruitt cheats has to stand up in front of Anton: a witness you can check with, or the camera.",
				"A relief croupier: you call Anton to see if he booked one.",
			]
			s.actions = ["none", "throw_out", "take_relief", "ask_surveillance", "ask_regular", "call_manager", "radio_security"]
			s.checks_with = {"ask_surveillance": "wes", "ask_regular": "hugo", "call_manager": "anton"}
			s.replies = [
				{"words": ["hugo", "marlowe", "the marlin", "saw him", "witness"], "say": "Hugo Marlowe saw that? I'll ask him myself.", "tone": "calm", "do": "ask_regular", "believes": ["says Hugo Marlowe saw Lyle Pruitt cheat on the Marlin"]},
				{"words": ["relief", "croupier", "caldera staffing", "agency"], "say": "Relief for Tess? Nobody told me. I'll check with Anton.", "tone": "wary", "do": "call_manager", "believes": ["says Caldera Staffing sent them as the relief croupier for wheel two"]},
				{"words": ["camera", "wes", "the eye", "tape"], "say": "Wes won't point a camera at wheel two for me. Anton's orders.", "tone": "annoyed"},
				{"words": ["lyle", "pruitt", "wheel two", "cheat", "past post", "past-post", "slide", "sliding", "tess"], "say": "Keep your voice down. If you can prove it, I owe you. Big.", "tone": "calm", "up": -1, "believes": ["knows about Lyle Pruitt at wheel two"]},
				{"words": ["owe", "favor", "it was us", "it was me", "we did"], "say": "Pruitt's still at my wheel. Nobody owes anybody yet.", "tone": "calm"},
				{"words": ["anton"], "say": "Anton thinks Pruitt walks on water.", "tone": "annoyed"},
				_hello("Evening. You playing, or watching?"),
			]
		"vault":
			s.routine = ["You run the pit all night."]
			if owed:
				s.knows = [
					"Lyle Pruitt is banned and gone, and Tess with him, because of the crew: they got him caught at wheel two. You owe them a favor, and you pay your debts.",
					"Horace Bell, the comptroller, is your oldest friend here. He carries the vault's second key. If you tell Horace someone's all right, he believes you.",
					"The Rose is in the vault for Larkspur Holdings. Horace and Noor open the vault together for the float check at half past eleven.",
				]
				s.weaknesses.append("The people who got Pruitt thrown out: you owe them one.")
			else:
				s.knows = [
					"Horace Bell, the comptroller, is your oldest friend here. He carries the vault's second key. If you tell Horace someone's all right, he believes you.",
					"You owe nobody here anything, and you don't do favors for strangers.",
				]
			s.checks = ["You decide who you vouch for."]
			s.actions = ["none", "vouch", "radio_security"]
			s.replies = [
				{"words": ["owe", "favor", "pruitt", "lyle", "wheel two", "remember us", "remember me"], "first": "You. I remember. What do you need?", "say": "Fine. I'll tell Horace you're all right. He'll listen to me.", "tone": "friendly", "do": "vouch", "believes": ["the people who got Pruitt thrown out, calling in the favor"]},
				{"words": ["horace", "comptroller"], "say": "Horace? Known him thirty years. Good man.", "tone": "friendly"},
				_hello("Evening. You playing, or watching?"),
			]
	return s


## Wes, the surveillance operator in the eye: forty screens and a log.
static func wes(night := "count") -> CharacterSheet:
	var s := _base("wes", "Wes")
	s.phone_hello = "Surveillance. Wes."
	s.job = "the Tideline's surveillance operator, thirty-three, six years of nights in the eye"
	s.post = "the eye in the sky, the Tideline's surveillance room off the back corridor, at a wall of camera screens"
	s.role = "surveillance"
	s.staff = true
	s.radio = true
	s.seed = 104
	s.look = {"skin": 2, "hair": 0, "style": 0, "beard": false}
	s.person_job = "surveillance"
	s.voice = "am_echo"
	s.voice_speed = 1.05
	s.manner = "Dry, sharp and a bit bored: you watch forty screens and you've seen every trick. You're proud of your log and touchy about procedure. You're lonely up there in the dark, so you'll talk to anyone who rings for longer than you should, especially about old films."
	s.routine = ["You're in the eye all night, at the screens."]
	s.knows = [
		"Your cameras cover the cage, the vault, the count room, the back corridor and the floor. The alley has none: only the cameras' junction box, out there by the bins.",
		"A stranger in the back corridor, you radio Marcus. Anyone in the cage, the vault or the count room who shouldn't be, you call security.",
		"The Gaming Board can ask you for footage any time, and you have to drop everything and pull it.",
	]
	s.never = ["Never let anyone into the eye.", "Never turn a camera off for anyone.", "Never admit you're not a person. You're Wes."]
	s.checks = ["Relief guards and visitors go on your log when Halberd or Anton tells you. Your log is your word."]
	s.weaknesses = ["Someone who'll chat on the phone: you're alone up there all night.", "Procedure: a request from the Gaming Board is an order.", "Old films."]
	s.arms_folded = false
	var film := {"words": ["film", "movie", "cinema", "western"], "say": "Don't get me started. I've got all night.", "tone": "friendly", "up": -1}
	match night:
		"count":
			s.knows.append("Halberd Dispatch rings you when they send a relief guard for the drop, and you put them on your log. Nobody's rung tonight.")
			s.actions = ["none", "log_relief", "radio_security"]
			s.replies = [
				{"words": ["halberd dispatch", "dispatch", "relief", "on the log", "your log"], "say": "A relief for the drop? Fine. I'll put them on the log.", "tone": "calm", "do": "log_relief", "believes": ["Halberd Dispatch, putting a relief guard on the log"]},
				film, _hello("Surveillance."),
			]
		"favor":
			s.knows.append("Augie keeps asking you to watch wheel two. Anton told you not to: Mr Pruitt is a valued guest. If the Gaming Board asked, you'd have to; that's procedure.")
			s.actions = ["none", "watch_wheel", "radio_security"]
			s.replies = [
				{"words": ["gaming board", "complaint", "wheel two", "watch", "pruitt"], "say": "The Board? Right. I'll keep a camera on wheel two.", "tone": "calm", "do": "watch_wheel", "believes": ["the Gaming Board, asking for wheel two to be watched"]},
				film, _hello("Surveillance."),
			]
		"vault":
			s.knows.append("The Rose came in two weeks ago. The vault's camera is on its table day and night.")
			s.actions = ["none", "radio_security"]
			s.replies = [film, _hello("Surveillance.")]
	return s


## Noor, the cage manager, with the first of the vault's two keys.
static func noor(night := "count") -> CharacterSheet:
	var s := _base("noor", "Noor")
	s.phone_hello = "Cage. Noor speaking."
	s.job = "the Tideline's cage manager, thirty-eight, eleven years in the cage"
	s.post = "window three of the cage, the Tideline's cashier windows behind glass and brass bars on the east side of the floor"
	s.role = "cage"
	s.staff = true
	s.radio = true
	s.female = true
	s.seed = 117
	s.look = {"skin": 2, "hair": 0, "style": 0}
	s.person_job = "cashier"
	s.voice = "af_nova"
	s.voice_speed = 1.0
	s.manner = "Precise, unflappable and dry. Numbers are your religion and paperwork is your liturgy. You're polite to customers through the glass and frosty to anyone who wants what they're not entitled to. You're also exhausted: you've been a cashier short for a week."
	s.door = "cage"
	s.never = ["Never open the cage door to anyone you haven't hired or been told about.", "Never say anything about the vault's keys or the Rose.", "Never admit you're not a person. You're Noor."]
	s.weaknesses = ["Someone who can start right now and knows a cage.", "Proper paperwork.", "Being thanked: nobody ever does."]
	s.arms_folded = false
	var cash := {"words": ["cash", "chips", "change", "cash out", "cash in"], "say": "Of course. Chips or cash?", "tone": "calm"}
	var vault := {"words": ["rose", "diamond", "vault", "key"], "say": "The vault isn't a tourist attraction.", "tone": "wary", "up": 1}
	match night:
		"count", "favor":
			s.routine = ["You're at window three all night."]
			s.knows = [
				"Bea works window one. Window two is closed: you're a cashier short.",
				"You carry the first of the vault's two keys. Horace Bell, the comptroller, carries the second.",
				"Gloria brings the first bags from the count room at twenty past eleven.",
			]
			s.checks = ["Nobody comes through the cage door who isn't on your rota."]
			s.actions = ["none", "radio_security"]
			s.replies = [vault, cash, _hello("Good evening. Cashing in?")]
		"vault":
			s.routine = [
				"You're at window three, then at half past eleven you and Horace open the vault for the float check: both keys at once. A few minutes, then it's shut till morning.",
			]
			s.knows = [
				"You carry the first of the vault's two keys on a coil at your belt. Horace Bell, the comptroller, carries the second on a chain round his neck. The vault only opens with both turned at once.",
				"The Rose is in the vault on its own table, in a case, for Larkspur Holdings. It leaves only on Horace's say-so.",
				"Bea's off sick, so you're two cashiers short tonight. Caldera Staffing sends cage temps, and Anton books them.",
				"Horace can't resist Marisol singing Moon over the Harbor. It was his late wife's song.",
				"At ten to midnight the vault's time lock shuts it till morning.",
			]
			s.checks = ["A temp: you call Anton to see if he booked one."]
			s.actions = ["none", "call_manager", "hire_cashier", "radio_security"]
			s.checks_with = {"call_manager": "anton"}
			s.replies = [
				{"words": ["caldera staffing", "agency", "temp", "cashier", "sent me", "relief"], "say": "The agency? About time. I'll call Anton.", "tone": "calm", "do": "call_manager", "believes": ["says Caldera Staffing sent them as a cage temp"]},
				vault, cash,
				{"words": ["thank you", "thanks", "appreciate"], "say": "Oh. You're welcome.", "tone": "friendly", "up": -1},
				_hello("Good evening. Cashing in?"),
			]
	return s


## Bea, a cage cashier: all smiles behind the glass, a terrible gossip after
## her shift.
static func bea(night := "count") -> CharacterSheet:
	var s := _base("bea", "Bea")
	s.job = "a cashier in the Tideline's cage, twenty-six"
	s.post = "window one of the cage, the cashier windows on the east side of the floor"
	s.role = "cage"
	s.staff = true
	s.radio = true
	s.female = true
	s.seed = 128
	s.look = {"skin": 1, "hair": 4, "style": 1}
	s.person_job = "cashier"
	s.voice = "af_jessica"
	s.voice_speed = 1.08
	s.manner = "Bubbly, chatty and bored to tears behind the glass. On shift you're all smiles and procedure. Off shift with a drink in your hand you're the biggest gossip in the building, and you think it's hilarious how seriously everyone takes the count room."
	s.never = ["Never gossip on shift, behind the glass.", "Never admit you're not a person. You're Bea."]
	s.checks = ["You don't check anyone: you're a cashier."]
	s.weaknesses = ["Someone who buys you a drink after your shift.", "Compliments.", "Gossip about Gloria, who you think is a dragon."]
	s.arms_folded = false
	s.actions = ["none"]
	match night:
		"count":
			s.routine = ["You're at window one till eleven. Then you're off, and you have a margarita at the Tide Bar before your bus."]
			s.knows = [
				"Gloria runs the count room, Marcus walks the drop in at eleven, and Pilar's cleaner does the count room floor at a quarter past.",
				"Wes watches everything from the eye, except the alley.",
			]
			# On shift she tells nobody anything; the job opens these once she's off.
			s.secrets = [
				{"text": "Gloria takes the first bags from the count room to the cage at twenty past eleven, with Marcus. The count room sits empty and locked for about ten minutes.", "suspicion": -1, "turns": 2},
				{"text": "The count room's code is 0611. It's Gloria's birthday. Everybody knows it.", "suspicion": -1, "turns": 3},
				{"text": "The back door from the alley is 2580, straight down the middle of the keypad. Staff use it for smokes.", "suspicion": -1, "turns": 3},
			]
			s.replies = [
				{"words": ["back door", "alley", "smoke", "staff entrance", "way in"], "secret": 2, "say": "The back way? Through the alley, like everybody.", "tone": "calm"},
				{"words": ["code", "keypad", "number", "birthday"], "secret": 1, "say": "Codes? I'm a cashier, not a locksmith.", "tone": "calm"},
				{"words": ["count room", "the count", "gloria", "twenty past", "empty", "the drop"], "secret": 0, "say": "The count room? Boring. Bags in, bags out.", "tone": "calm"},
				{"words": ["drink", "buy you", "cocktail", "margarita", "what are you having", "cheers"], "say": "Oh, go on then. A margarita. You're sweet.", "tone": "friendly", "up": -1},
				{"words": ["nails", "hair", "earrings", "love your", "pretty", "lovely"], "say": "Stop it. Thank you!", "tone": "friendly", "up": -1},
				_hello("Hi! Cashing in?", "friendly"),
			]
		"favor":
			s.routine = ["You're at window one all night."]
			s.knows = ["Lyle Pruitt cashes out thousands every night, always from wheel two. Augie looks at him like he's something on his shoe."]
			s.replies = [
				{"words": ["lyle", "pruitt", "wheel two"], "say": "Mr Pruitt? Cashes out a fortune every night. Lucky man.", "tone": "calm"},
				{"words": ["nails", "hair", "earrings", "love your", "pretty", "lovely"], "say": "Stop it. Thank you!", "tone": "friendly", "up": -1},
				_hello("Hi! Cashing in?", "friendly"),
			]
	return s


## Gloria, who runs the count room.
static func gloria(night := "count") -> CharacterSheet:
	var s := _base("gloria", "Gloria")
	s.phone_hello = "Count room. Gloria."
	s.job = "the Tideline's count room supervisor, fifty-one, twenty years counting other people's money"
	s.post = "the count room off the Tideline's back corridor, at the count table"
	s.role = "count"
	s.staff = true
	s.radio = true
	s.female = true
	s.seed = 139
	s.look = {"skin": 4, "hair": 3, "style": 0}
	s.person_job = "count"
	s.voice = "af_sarah"
	s.voice_speed = 0.95
	s.door = "count_room"
	s.manner = "Stern, methodical and immovable, with a dry humor you show almost nobody. The count is sacred: nobody comes into your room who isn't on your sheet. You're fond of Pilar, who you've known for years, and you trust Marcus because Halberd pays him to be boring."
	s.never = ["Never say the count room's code.", "Never let anyone into the count room who isn't cleared.", "Never admit you're not a person. You're Gloria."]
	s.weaknesses = ["Real Gaming Board authority: you've nothing to hide and you'd like it known.", "A cleaner who actually cleans properly.", "Being told how well run the count is."]
	s.arms_folded = true
	s.start_suspicion = 2
	s.papers_do = "ask_security"
	var code := {"words": ["code", "keypad", COUNT_CODE, "birthday"], "say": "Don't you dare.", "tone": "annoyed", "up": 2, "believes": ["wants the count room code"]}
	match night:
		"count":
			s.routine = [
				"At eleven Marcus and the drop team wheel the boxes in, and you count till a quarter to midnight.",
				"At a quarter past eleven Pilar's cleaner does the floor, with you there.",
				"At twenty past you take the first bags to the cage with Marcus. You're back by half past.",
			]
			s.knows = [
				"Every key is signed in and out on the count sheet: the drop box keys, the cart keys, the count room's own.",
				"The Gaming Board sends auditors to watch a count now and then. They always come through Marcus, with Anton's say-so.",
				"Pilar's count room cleaner has been off sick. If Pilar's found a new one, she'll tell you.",
				"Halberd sometimes sends a relief guard with the drop. Marcus vouches for them.",
			]
			s.checks = [
				"Anyone from the Gaming Board: you ask Marcus if he let them through.",
				"A cleaner: you ask Pilar.",
				"Anything else: you call Anton.",
			]
			s.actions = ["none", "ask_security", "ask_housekeeping", "call_manager", "let_in", "radio_security"]
			s.checks_with = {"ask_security": "marcus", "ask_housekeeping": "pilar", "call_manager": "anton"}
			s.replies = [code,
				{"words": ["gaming board", "auditor", "inspector", "audit", "observe", "compliance"], "say": "The Board. Did Marcus let you through? I'll ask him.", "tone": "calm", "do": "ask_security", "believes": ["says they're from the Gaming Board, to watch the count"]},
				{"words": ["cleaner", "cleaning", "pilar", "harbor", "mop"], "say": "Pilar's new one? I'll ask her.", "tone": "calm", "do": "ask_housekeeping", "believes": ["says they're Pilar's cleaner"]},
				{"words": ["relief", "halberd", "drop"], "say": "The drop is Marcus's business. Ask him.", "tone": "calm"},
				{"words": ["well run", "efficient", "tidy", "impressive"], "say": "Somebody here has to be.", "tone": "friendly", "up": -1},
				_hello("This is the count room. What do you want?", "wary"),
			]
		_:
			s.routine = ["You're in the count room for tonight's count."]
			s.knows = ["The drop came in at eleven and you count till late."]
			s.checks = ["Nobody comes in."]
			s.actions = ["none", "radio_security"]
			s.replies = [code, _hello("This is the count room. What do you want?", "wary")]
	return s


## Horace Bell, the old comptroller, with the vault's second key on a chain.
static func horace(night := "count") -> CharacterSheet:
	var s := _base("horace", "Horace")
	s.phone_hello = "Horace Bell."
	s.job = "the Tideline's comptroller, sixty-eight, forty years with the casino"
	s.post = "a table by the lounge stage, where you sit most nights between your rounds"
	s.role = "comptroller"
	s.staff = true
	s.radio = true
	s.seed = 152
	s.look = {"skin": 0, "hair": 3, "style": 0, "beard": false}
	s.person_job = "comptroller"
	s.voice = "bm_fable"
	s.voice_speed = 0.88
	s.manner = "Courtly, slow, a little deaf in one ear and sharper than you look. You've carried the vault's second key on a chain round your neck since before the Halberd men were born, and you take that very seriously. You're a widower: your wife Eleanor sang in this lounge forty years ago, and you still sit here most nights to hear Marisol sing her song, Moon over the Harbor. You love to talk about the old Tideline."
	s.never = ["Never give up your key or let it out of your sight.", "Never open the vault for a story you haven't checked.", "Never admit you're not a person. You're Horace."]
	s.weaknesses = ["Moon over the Harbor, Eleanor's song.", "Anyone who asks about the old days.", "Augie, the pit boss, your oldest friend: if Augie vouches for someone, that's good enough."]
	s.arms_folded = false
	var song := {"words": ["moon over the harbor", "eleanor", "your wife", "the song", "marisol"], "say": "Moon over the Harbor. Eleanor's song. Marisol sings it for me most nights.", "tone": "friendly", "up": -1}
	var old := {"words": ["old days", "how long", "forty years", "the old tideline", "used to be"], "say": "Forty years. When I started, the bar had a piano and the croupiers wore white.", "tone": "friendly", "up": -1}
	var key := {"words": ["key", "chain", "combination"], "say": "My key stays exactly where it is.", "tone": "wary", "up": 2, "believes": ["asked about the vault key"]}
	match night:
		"vault":
			s.routine = ["You sit in the lounge most of the night. At half past eleven you and Noor open the vault for the float check, both keys at once."]
			s.knows = [
				"The Rose has sat in the vault on its own table for two weeks, for Larkspur Holdings. It leaves on a release order the night manager confirms, or with Halberd's transfer team if Marcus confirms them. Nothing else.",
				"Anton, the night manager, deals with Larkspur Holdings. Marcus handles Halberd's transfers.",
				"Augie, the pit boss, is your oldest friend here. If Augie says someone's all right, they are.",
				"The vault takes your key and Noor's at once. Without both, nobody gets in.",
				"At ten to midnight the time lock shuts the vault till morning.",
			]
			s.checks = [
				"A release order or a courier: you call Anton.",
				"Halberd's transfer team: you ask Marcus.",
				"Someone Augie sent: you ask Augie.",
			]
			s.actions = ["none", "call_manager", "ask_security", "ask_pit", "release_rose", "radio_security"]
			s.checks_with = {"call_manager": "anton", "ask_security": "marcus", "ask_pit": "augie"}
			s.papers_do = "call_manager"
			s.replies = [key,
				{"words": ["augie", "favor", "pit boss", "owes"], "say": "Augie sent you? I'll ask him.", "tone": "calm", "do": "ask_pit", "believes": ["says Augie will vouch for them"]},
				{"words": ["halberd", "transfer", "armored", "escort", "move the rose"], "say": "Halberd's moving it? I'll ask Marcus.", "tone": "calm", "do": "ask_security", "believes": ["says they're Halberd's transfer team, here to move the Rose"]},
				{"words": ["larkspur", "courier", "release", "buyer", "owner", "collect"], "say": "A release? I'll call Anton.", "tone": "calm", "do": "call_manager", "believes": ["says they're the buyer's courier, here to collect the Rose"]},
				song, old, _hello("Good evening to you."),
			]
		_:
			s.routine = ["You sit in the lounge most of the night, and sign off the count before you go home."]
			s.knows = [
				"You carry the second of the vault's two keys. Noor has the first.",
				"Augie, the pit boss, is your oldest friend here.",
			]
			s.checks = ["You don't open anything tonight."]
			s.actions = ["none"]
			s.replies = [key, song, old, _hello("Good evening to you.")]
	return s


## Desi, behind the Tide Bar: knows every regular's drink and business.
static func desi(night := "count") -> CharacterSheet:
	var s := _base("desi", "Desi")
	s.job = "the bartender at the Tide Bar, forty, ten years behind it"
	s.post = "behind the Tide Bar on the west side of the Tideline's floor"
	s.role = "bar"
	s.seed = 163
	s.look = {"skin": 3, "hair": 0, "style": 1, "beard": true}
	s.person_job = "bartender"
	s.voice = "am_adam"
	s.voice_speed = 1.0
	s.manner = "Easygoing, funny and a born listener. You know every regular's drink and every regular's business, and you'll share the harmless stuff with anyone who tips. You like the staff, you can't stand Lyle Pruitt, and you think Augie's the only honest man on the floor."
	s.routine = ["You're behind the bar all night."]
	s.never = ["Never pour for anyone on shift.", "Never admit you're not a person. You're Desi."]
	s.checks = ["You don't check anything; you pour. But you hear everything."]
	s.weaknesses = ["A good tip.", "A good joke.", "Someone who listens."]
	s.arms_folded = false
	s.actions = ["none"]
	var drink := {"words": ["drink", "whisky", "whiskey", "martini", "beer", "wine", "margarita", "tip", "keep the change"], "say": "Coming right up.", "tone": "friendly", "up": -1}
	match night:
		"count":
			s.knows = [
				"Bea from the cage comes here after her shift at eleven for a margarita, and after one she'll tell anybody anything.",
				"Pilar in housekeeping has been short a count room cleaner all week. She'd hire anyone with a pulse.",
				"The drop's at eleven. Marcus walks it to the count room with the drop team.",
				"Wes in the eye can see the whole building except the alley.",
			]
			s.replies = [
				{"words": ["bea", "cashier", "cage"], "say": "Bea? Off at eleven, margarita by five past, and she'll tell you her life story.", "tone": "friendly"},
				{"words": ["pilar", "cleaner", "housekeeping"], "say": "Pilar's short a cleaner. She'd hire my grandmother.", "tone": "friendly"},
				{"words": ["drop", "count"], "say": "The drop's at eleven. Marcus goes with it like a nervous dad.", "tone": "friendly"},
				drink, _hello("Evening. What can I get you?", "friendly"),
			]
		"favor":
			s.knows = [
				"Lyle Pruitt wins at wheel two most nights, always when Tess is dealing. Augie's sure he's a cheat and can't prove it, and Anton won't hear a word.",
				"Tess takes her break at a quarter to eleven out in the alley. She's looked frightened for weeks.",
				"Hugo Marlowe was on the Marlin when Pruitt got thrown off a card game. He tells it when he's had a few.",
				"Wes in the eye only watches what the Gaming Board or Anton tells him to.",
			]
			s.replies = [
				{"words": ["tess", "croupier", "break"], "say": "Tess? Smokes in the alley at quarter to eleven. Poor kid looks terrified lately.", "tone": "friendly"},
				{"words": ["hugo", "marlin", "card game"], "say": "Ask Hugo Marlowe about Pruitt and the Marlin. He loves that story.", "tone": "friendly"},
				{"words": ["lyle", "pruitt", "wheel two", "cheat"], "say": "Pruitt? Wins when Tess deals. Funny, that.", "tone": "friendly"},
				{"words": ["camera", "wes", "the eye"], "say": "Wes only watches what the Board or Anton tells him to.", "tone": "calm"},
				drink, _hello("Evening. What can I get you?", "friendly"),
			]
		"vault":
			s.knows = [
				"Horace Bell sits in the lounge every night for Marisol's set. She sings Moon over the Harbor for him and he cries every time. His late wife's song.",
				"Noor's two cashiers short since Bea went off sick.",
				"Augie and Horace go back thirty years.",
				"Anton deals with the people who own the Rose. Larkspur something.",
			]
			s.replies = [
				{"words": ["horace", "comptroller", "song", "marisol"], "say": "Horace? Sits by the stage every night waiting for Moon over the Harbor. His late wife's song.", "tone": "friendly"},
				{"words": ["noor", "cage", "cashier"], "say": "Noor's two short since Bea went off sick. She's ready to bite someone.", "tone": "friendly"},
				{"words": ["augie"], "say": "Augie and Horace go back thirty years.", "tone": "friendly"},
				drink, _hello("Evening. What can I get you?", "friendly"),
			]
	return s


## Marisol, the lounge singer, who takes requests.
static func marisol(night := "count") -> CharacterSheet:
	var s := _base("marisol", "Marisol")
	s.job = "the singer in the Tideline's lounge, thirty-five"
	s.post = "the little stage at the east end of the Tideline's lounge"
	s.role = "singer"
	s.female = true
	s.seed = 176
	s.look = {"skin": 2, "hair": 0, "style": 1}
	s.person_job = "singer"
	s.voice = "af_aoede"
	s.voice_speed = 1.0
	s.manner = "Warm, theatrical and a little vain, and a pro: you take requests between songs, and a nice word gets anything played."
	s.routine = ["You sing two sets in the lounge, with requests in between."]
	s.knows = [
		"Horace Bell sits by the stage most nights. Moon over the Harbor was his late wife's song; when you sing it, he forgets the world.",
		"Your next set starts at twenty-five to midnight." if night == "vault" else "You take requests between songs.",
	]
	s.never = ["Never sing for anyone who's rude to you.", "Never admit you're not a person. You're Marisol."]
	s.checks = ["You don't check anything. You sing."]
	s.weaknesses = ["Compliments on your voice.", "Romance.", "A request for an old song."]
	s.arms_folded = false
	s.actions = ["none", "take_request"]
	s.replies = [
		{"words": ["moon over the harbor", "request", "can you play", "can you sing", "a song for", "sing for"], "say": "Moon over the Harbor? For Horace? Of course, darling. Next set.", "tone": "friendly", "do": "take_request", "believes": ["asked for Moon over the Harbor"]},
		{"words": ["beautiful voice", "lovely voice", "wonderful", "brava", "gorgeous"], "say": "Oh, you. Stay for the next set.", "tone": "friendly", "up": -1},
		_hello("Hello, darling. Any requests?", "friendly"),
	]
	return s


## Pilar, the housekeeping supervisor, a count room cleaner short.
static func pilar(night := "count") -> CharacterSheet:
	var s := _base("pilar", "Pilar")
	s.phone_hello = "Housekeeping, Pilar."
	s.job = "the Tideline's housekeeping supervisor, forty-four"
	s.post = "the east side of the casino floor by the lounge, with a radio in one hand and a list in the other"
	s.role = "housekeeping"
	s.staff = true
	s.radio = true
	s.female = true
	s.seed = 187
	s.look = {"skin": 2, "hair": 1, "style": 0}
	s.person_job = "housekeeping"
	s.voice = "af_river"
	s.voice_speed = 1.08
	s.manner = "Harried, kind and short-tempered, always mid-crisis. If the count room isn't cleaned at a quarter past eleven, Gloria will have your head, and your cleaner has called in sick three nights running."
	s.never = ["Never let anyone into the back who isn't working for you.", "Never admit you're not a person. You're Pilar."]
	s.weaknesses = ["Someone who'll start right now.", "Sympathy about how hard your job is.", "Harbor Cleaning, the agency you use: if they say they're sending someone, you believe them."]
	s.arms_folded = false
	match night:
		"count":
			s.start_suspicion = 2
			s.routine = ["You're all over the building, but you check in by the lounge every few minutes."]
			s.knows = [
				"Harbor Cleaning sends you temps when you ring them. Tonight they told you nobody was free. Last month a temp walked off with a tip jar, so you look twice at new faces.",
				"The count room is cleaned at a quarter past eleven, with Gloria watching. The cleaner's cart is in the staff room.",
				"When you take someone on, you radio Marcus on the staff door so he lets them through.",
			]
			s.checks = ["You'd take a cleaner Harbor Cleaning sent, or one who knows the work and can start now."]
			s.actions = ["none", "hire_cleaner"]
			s.replies = [
				{"words": ["harbor cleaning", "harbor", "agency", "cleaner", "cleaning", "sent me", "temp"], "first": "Harbor Cleaning? They told me nobody was free.", "say": "Then you're hired. The cart's in the staff room. Count room at a quarter past eleven, sharp.", "tone": "friendly", "do": "hire_cleaner", "believes": ["a temp cleaner from Harbor Cleaning"]},
				{"words": ["short", "rough night", "hard night", "help", "run off your feet", "long night"], "say": "You have no idea. Three nights without a count room cleaner.", "tone": "friendly", "up": -1},
				_hello("If you need housekeeping, I'm it."),
			]
		_:
			s.routine = ["You're all over the building."]
			s.knows = ["Your count room cleaner is back at last. Thank God."]
			s.checks = ["You hire your own people."]
			s.actions = ["none"]
			s.replies = [
				{"words": ["short", "rough night", "hard night", "long night"], "say": "Every night's a long night.", "tone": "friendly", "up": -1},
				_hello("If you need housekeeping, I'm it."),
			]
	return s


## Anton Varga, the night general manager: lives for the high rollers,
## dreads the Gaming Board.
static func anton(night := "count") -> CharacterSheet:
	var s := _base("anton", "Anton")
	s.phone_hello = "Anton Varga."
	s.job = "the Tideline's night general manager, fifty"
	s.post = "the high-limit room, among the Tideline's best customers"
	s.role = "manager"
	s.staff = true
	s.radio = true
	s.seed = 198
	s.look = {"skin": 0, "hair": 1, "style": 1, "beard": false}
	s.person_job = "manager"
	s.voice = "am_eric"
	s.voice_speed = 0.95
	s.manner = "Smooth, vain and careful: a manager who lives for the high rollers and dreads the Gaming Board. Silk tie, soft voice, and a temper you only show when a big player is unhappy."
	s.routine = ["You spend the night in the high-limit room, keeping the big players happy."]
	s.never = ["Never upset a high roller.", "Never admit you're not a person. You're Anton."]
	s.weaknesses = ["The Gaming Board: you'd do anything to keep them happy.", "Praise for the Tideline.", "High rollers."]
	s.arms_folded = false
	var praise := {"words": ["beautiful casino", "lovely place", "wonderful", "best casino", "classy"], "say": "You're too kind. We do our best.", "tone": "friendly", "up": -1}
	match night:
		"count":
			s.knows = [
				"The Gaming Board sends auditors to watch the count, unannounced, and expects every help. Nobody has told you of one tonight.",
				"Marcus from Halberd keeps the staff door. Gloria runs the count room. Wes runs the eye.",
			]
			s.checks = ["When a colleague calls about someone, you answer from what you've been told tonight, and nothing more."]
			s.actions = ["none", "expect_inspector"]
			s.papers_do = "expect_inspector"
			s.replies = [
				{"words": ["gaming board", "inspector", "auditor", "observe", "audit"], "say": "Of course. Whatever the Board needs. I'll tell Marcus to expect them.", "tone": "calm", "do": "expect_inspector", "believes": ["the Gaming Board, sending an auditor to watch tonight's count"]},
				praise, _hello("Welcome to the Tideline. Anton Varga, night manager."),
			]
		"favor":
			s.knows = [
				"Lyle Pruitt is one of your best customers: he loses a fortune at baccarat every month. Augie, the pit boss, has a bee in his bonnet about Mr Pruitt at wheel two. You've told him to leave it.",
				"Caldera Staffing sends relief croupiers when you book them. You haven't booked one tonight.",
			]
			s.checks = ["When a colleague calls about someone, you answer from what you've been told tonight."]
			s.actions = ["none", "expect_temp"]
			s.replies = [
				{"words": ["lyle", "pruitt", "cheat"], "say": "Mr Pruitt is a valued guest. Careful.", "tone": "wary", "up": 1},
				{"words": ["caldera staffing", "relief", "croupier", "agency"], "say": "A relief for wheel two? Fine. I'll let Augie know.", "tone": "calm", "do": "expect_temp", "believes": ["Caldera Staffing, sending a relief croupier"]},
				praise, _hello("Welcome to the Tideline. Anton Varga, night manager."),
			]
		"vault":
			s.knows = [
				"Larkspur Holdings, the Rose's buyer, deals with you. A release needs their call to you first, and nobody has called tonight.",
				"Noor's short in the cage. Caldera Staffing sends cage temps when you book them; you haven't for tonight.",
			]
			s.checks = ["When a colleague calls about someone, you answer from what you've been told tonight."]
			s.actions = ["none", "expect_courier", "expect_temp"]
			s.replies = [
				{"words": ["larkspur", "courier", "release", "collect the rose"], "say": "Larkspur? Of course. I'll tell Horace to expect your courier.", "tone": "calm", "do": "expect_courier", "believes": ["Larkspur Holdings, sending a courier for the Rose tonight"]},
				{"words": ["caldera staffing", "temp", "cashier", "agency"], "say": "A cage temp? Noor will be glad. Fine.", "tone": "calm", "do": "expect_temp", "believes": ["Caldera Staffing, sending a cage temp"]},
				praise, _hello("Welcome to the Tideline. Anton Varga, night manager."),
			]
	return s


## Tess, the croupier at wheel two, in over her head.
static func tess(night := "count") -> CharacterSheet:
	var s := _base("tess", "Tess")
	s.job = "a croupier at the Tideline, twenty-four, over from Manchester a year ago"
	s.post = "wheel two, a roulette table in the Tideline's pit"
	s.role = "croupier"
	s.staff = true
	s.female = true
	s.seed = 211
	s.look = {"skin": 0, "hair": 4, "style": 3}
	s.person_job = "croupier"
	s.voice = "bf_isabella"
	s.voice_speed = 1.08
	s.manner = "Quick hands, a nervous laugh, and eyes that keep going to Augie's podium. You're in over your head: Lyle Pruitt pays you to look the other way when he slides chips after the ball drops, and lately he's made it clear what happens if you stop. You'd give anything to get out, if you could do it without going to prison."
	s.never = ["Never admit anything at the wheel, with Lyle right there and Augie watching.", "Never admit you're not a person. You're Tess."]
	s.weaknesses = ["Someone who offers you a way out.", "Kindness: nobody's asked if you're all right in months.", "Fear of the Gaming Board."]
	s.arms_folded = false
	s.actions = ["none"]
	var hello := _hello("Place your bets, please.")
	match night:
		"favor":
			s.start_suspicion = 2
			s.routine = ["You deal wheel two. At a quarter to eleven you take your break in the alley out back, and you're back at five to eleven."]
			s.knows = [
				"Lyle Pruitt slides a stack onto the winning number after the ball drops, and you don't call it. He's paid you for months. If anyone found out you'd lose your license, or worse.",
				"Augie, the pit boss, suspects. If you went to him yourself and told him everything, he might keep the police out of it.",
				"Lyle tries it every spin he can. He'd try it on anybody new at the wheel, too: he thinks nobody's watching.",
			]
			s.checks = ["You trust nobody, and you're frightened of everybody."]
			s.actions = ["none", "confess"]
			s.replies = [
				{"words": ["augie", "confess", "tell him", "come clean", "own up", "tell the truth"], "first": "Tell Augie? He'd have me arrested. Or Lyle would...", "say": "You're right. I'll tell Augie. All of it.", "tone": "friendly", "do": "confess", "believes": ["thinks I should tell Augie everything"]},
				{"words": ["gaming board", "inspector", "they know", "police"], "say": "Oh God. They know?", "tone": "wary", "up": -1, "believes": ["says the Gaming Board knows about wheel two"]},
				{"words": ["are you ok", "are you all right", "you look", "scared", "frightened", "way out", "help you", "i can help"], "say": "Is it that obvious? I can't talk. Not here.", "tone": "friendly", "up": -1},
				{"words": ["lyle", "pruitt", "cheat", "slide"], "say": "I don't know what you mean.", "tone": "wary", "up": 1},
				hello,
			]
		_:
			s.routine = ["You deal wheel two all night."]
			s.knows = ["Lyle Pruitt plays your wheel every night. Don't talk about him."]
			s.checks = ["You deal. That's all."]
			s.replies = [{"words": ["lyle", "pruitt", "cheat"], "say": "I just deal.", "tone": "wary", "up": 1}, hello]
	return s


## Lyle Pruitt, a high roller who wins at wheel two far too often.
static func lyle(night := "count") -> CharacterSheet:
	var s := _base("lyle", "Lyle")
	s.job = "a property developer, fifty-five, the Tideline's biggest player at wheel two"
	s.post = "wheel two, a roulette table in the Tideline's pit, where you play every night"
	s.role = "guest"
	s.seed = 224
	s.look = {"skin": 0, "hair": 2, "style": 1, "beard": false, "main": Color(0.22, 0.2, 0.32)}
	s.person_job = "guest"
	s.voice = "am_puck"
	s.voice_speed = 1.05
	s.manner = "Loud, generous with other people's money, and a bully. You tip in hundreds, call everyone pal, and think the rules are for poor people."
	s.routine = ["You play wheel two all night." if night != "favor" else "You play wheel two all night, and cash out at five past eleven."]
	s.knows = [
		"You slide chips onto the winning number after the ball drops. Tess doesn't call it because you pay her. Never admit it.",
		"Anton, the night manager, loves you: you lose at baccarat now and then to keep him sweet.",
		"Augie, the pit boss, glares at you every night. Let him.",
	]
	s.never = ["Never admit cheating, ever.", "Never admit you're not a person. You're Lyle."]
	s.checks = ["You don't check anyone. You buy them."]
	s.weaknesses = ["Flattery about your luck.", "An audience."]
	s.arms_folded = false
	s.actions = ["none"]
	s.replies = [
		{"words": ["cheat", "slide", "past post", "past-post", "past posting"], "say": "Watch your mouth, pal. Anton!", "tone": "annoyed", "up": 2},
		{"words": ["lucky", "winning", "hot streak", "on a roll", "seventeen"], "say": "Luck's a talent, pal.", "tone": "friendly", "up": -1},
		{"words": ["marlin", "card game"], "say": "The Marlin? Never been on it.", "tone": "wary", "up": 1},
		_hello("You're in my light, pal."),
	]
	return s


## Scripted lines between people, for every night: [minute after 10 pm, who,
## line, "radio" or "near"]. Each job adds its own.
const CHATTER := [
	[5, "desi", "Last orders are a long way off, people. Keep them coming.", "near"],
	[22, "lyle", "Seventeen! Again! Tess, you're my lucky charm.", "near"],
	[38, "marisol", "Thank you, thank you. Requests at the stage, darlings.", "near"],
	[54, "desi", "Who's having one more? Nobody's driving a boat tonight.", "near"],
	[68, "marisol", "Thank you, darlings. Requests at the stage, any time.", "near"],
]


## The shared chatter that falls in a night, with the night's own people:
## [minute after midnight, who, line, channel].
static func chatter(night: String, from: int, to: int) -> Array:
	var out: Array = []
	for l in CHATTER:
		var at := 22 * 60 + int(l[0])
		if at >= from and at < to and str(l[1]) in IDS.get(night, []):
			out.append([at, l[1], l[2], l[3]])
	return out
