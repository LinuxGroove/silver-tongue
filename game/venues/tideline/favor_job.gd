class_name TidelineFavorJob
extends JobDef
## Job 8, the pit boss's favor. Lyle Pruitt wins at wheel two night after
## night: he slides chips onto the winning number after the ball drops, and
## Tess, the croupier, is paid not to see. Augie, the pit boss, can't prove
## it, and Anton protects him. Get Pruitt caught so Augie owes the crew: get
## Dmitri's camera on wheel two (the Gaming Board's say-so), talk Tess into
## confessing on her break, bring Augie a witness (Hugo saw Pruitt cheat on
## the Marlin), or deal wheel two yourself while Tess is on her break.

## The wheel spins that matter, Tess's break and Pruitt cashing out.
const SPINS := [22 * 60 + 20, 22 * 60 + 30, 22 * 60 + 40, 22 * 60 + 50, 23 * 60]
const BREAK := 22 * 60 + 45
const BREAK_END := 22 * 60 + 57
const CASH_OUT := 23 * 60 + 5
## How close to wheel two's croupier spot the relief must stand.
const AT_WHEEL := 1.5
## Words that tell Augie the crew is behind it.
const TOLD := ["lyle", "pruitt", "wheel", "tess", "cheat", "dmitri", "camera", "board", "relief", "hugo"]
## Real seconds between Augie saying he owes the crew and the night ending.
const OWED_PAUSE := 3.5


func _init() -> void:
	id = "tideline_favor"
	venue_id = "tideline"
	number = 2
	memory_from = ["meridian"]
	title = "The pit boss's favor"
	venue_name = "The Tideline"
	briefing = "The pit boss at the Tideline is Augie Ferrante, love, thirty years on the floor and he never forgets a debt. Right now he's drowning in one problem: a big player called Lyle Pruitt wins at wheel two every night, and Augie can't prove he's cheating, not with the night manager licking Pruitt's boots. Get Pruitt caught, properly caught, and make sure Augie knows it was you. A pit boss who owes you is worth more than any key. Mind Halberd while you're about it."
	goal = "Get Lyle Pruitt caught cheating at wheel two, and make sure Augie knows it was you, by 11:10"
	situation = TidelineCast.SITUATION + " Tonight Augie, the pit boss, is watching wheel two again, where Lyle Pruitt has been winning for weeks."
	prize = "Augie's favor"
	take = 5000
	start = 22 * 60 + 10
	end = 23 * 60 + 10
	end_text = "Pruitt cashing out"
	seconds_per_minute = 18.0
	covers = {
		"player": {
			"title": "Player", "names": ["Nick Sato", "Nina Sato"],
			"job": "a player from out of town, here for the tables",
			"story": "Nobody minds a player at the bar, the wheel or the baccarat table. Hugo Marlowe plays in the high-limit room tonight, and the bartender hears everything.",
			"outfit": "guest", "for": "Hugo in the high-limit room, Desi at the bar, Augie",
			"lines": TidelineRules.PLAYER_LINES.duplicate(),
		},
		"inspector": {
			"title": "Gaming Board inspector", "names": ["Martin Kessler", "Marta Kessler"],
			"job": "an inspector from the Caldera Gaming Board",
			"story": "The Board's word is an order to the eye: if the Board asks Dmitri to watch a table, he watches it. Your card is a good copy. Tess is frightened of the Board.",
			"outfit": "auditor", "for": "Dmitri, on the phone, and Tess",
			"lines": [
				"%s, Caldera Gaming Board. We've had a complaint about wheel two.",
				"I'd like a camera on that table tonight, please.",
				"Are you all right? You look frightened.",
				"If there's something you want to tell your pit boss, tonight's the night.",
			],
		},
		"croupier": {
			"title": "Relief croupier", "names": ["Sam Novak", "Sasha Novak"],
			"job": "a relief croupier from Caldera Staffing",
			"story": "Tess takes her break at a quarter to eleven, and wheel two needs a relief. Augie will check with Anton, who books the agency. Pruitt thinks anyone new at the wheel is blind.",
			"outfit": "croupier_temp", "for": "Augie, at the pit boss's podium",
			"lines": [
				"Evening. Caldera Staffing sent me as relief for wheel two.",
				"Mr Varga booked me. Check with him.",
				"I've dealt roulette for six years.",
				"Where do you want me when she goes on her break?",
			],
		},
	}
	cover_order = ["player", "inspector", "croupier"]
	outfits = TidelineRules.OUTFITS.duplicate(true)
	staff_looking = TidelineRules.STAFF_LOOKING.duplicate()
	staff_rooms = TidelineRules.STAFF_ROOMS.duplicate()
	looks = TidelineCast.LOOKS
	extras = TidelineRules.EXTRAS.duplicate()
	routine = [
		[BREAK, "tess", "tess_smoke"],
		[BREAK_END, "tess", "tess"],
		[CASH_OUT, "lyle", "kerb"],
	]
	chatter = TidelineCast.chatter("favor", start, end)
	chatter.append_array([
		[22 * 60 + 14, "augie", "Watch wheel two. Watch it.", "near"],
		[22 * 60 + 44, "tess", "Augie, I'm on my break.", "near"],
	])
	events = []
	for t in SPINS:
		events.append([t, "spin"])
	events.append_array([[BREAK, "break"], [BREAK_END, "back"], [CASH_OUT, "cash_out"]])
	locked = ["staff", "count_room", "eye", "office", "cage", "vault", "back", "staff_room"]
	open = ["high_limit"]
	lockdown_doors = ["staff", "count_room", "cage", "back"]
	lockdown_text = "Lockdown. The back of the house is shut."
	door_texts = {
		"staff": "It's locked. Marcus keeps this door.",
		"count_room": "It's locked.",
		"eye": "It's locked. A sign says SURVEILLANCE. NO ENTRY.",
		"cage": "It's locked.",
		"back": "It's locked. There's a keypad.",
	}
	keypads = {
		"count_pad": {"door": "count_room", "code": TidelineCast.COUNT_CODE, "label": "Count room"},
		"back_pad": {"door": "back", "code": TidelineCast.BACK_CODE, "label": "Back door"},
	}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's office"}
	items = {
		"card": {
			"name": "the Board card", "at": "", "carry": "",
			"papers": "a Caldera Gaming Board inspector's card in the name of %s", "forged": true,
			"copy": "the hologram's a sticker. It's a fake.",
			"belief": "has a Gaming Board inspector's card", "to": ["tess", "augie", "anton"],
		},
	}
	actions = {
		"throw_out": {"text": "throw Lyle Pruitt out for cheating, now that you have proof", "kind": "opening", "lockdown": true},
		"take_relief": {"text": "put them on wheel two as the relief croupier for Tess's break", "kind": "opening", "lockdown": true},
		"ask_surveillance": {"text": "radio Dmitri in the eye to ask what his cameras saw (takes a moment)", "kind": "check"},
		"ask_regular": {"text": "go and ask Hugo Marlowe if it's true (takes a moment)", "kind": "check"},
		"watch_wheel": {"text": "keep a camera on wheel two tonight, as the Gaming Board asks", "kind": ""},
		"expect_temp": {"text": "tell Augie a relief croupier from Caldera Staffing is coming", "kind": ""},
		"confess": {"text": "go to Augie yourself and tell him everything about Pruitt", "kind": "opening", "lockdown": true},
	}
	actions["take_request"] = {"text": "take their song request for your next set", "kind": ""}
	effects = {"take_request": {"flag": "requested", "toast": "%s will sing it in her next set."}}
	hot_words = ["past post", "past-post", "pruitt's a cheat", "slides chips"]
	phone = TidelineRules.phone_for(["anton", "dmitri", "augie"])
	caller_ids = ["Withheld", "Caldera Gaming Board", "Caldera Staffing"]
	mae_calls = [
		{"id": "board", "label": "Get Dmitri watching wheel two", "who": "dmitri", "as": "Caldera Gaming Board",
			"line": "Caldera Gaming Board. We've had a complaint about your wheel two. Keep a camera on it tonight, please, and call your pit boss if you see anything.",
			"answer": "Wheel two. Right. I'm on it.",
			"mae": "I'll ring the eye as the Gaming Board, love. Dmitri will have a camera on that wheel."},
		{"id": "staffing", "label": "Book a relief croupier", "who": "anton", "as": "Caldera Staffing",
			"line": "Caldera Staffing. Your relief croupier for wheel two is on the way, for the quarter to eleven break.",
			"answer": "Relief? Fine, fine. I'll tell Augie.",
			"mae": "I'll ring Anton from the agency. Augie will hear a relief is booked."},
		{"id": "scare", "label": "Give Tess a fright", "who": "tess", "as": "Caldera Gaming Board",
			"line": "Ms Whitlock? Caldera Gaming Board. We're looking at wheel two. If there's anything you'd like to tell your pit boss first, tonight would be the night.",
			"answer": "I... yes. I understand.",
			"mae": "I'll ring Tess as the Board. Poor lamb. She'll be ready to talk to anyone kind."},
	]
	outcomes = {
		"owed": ["AUGIE OWES YOU", "Pruitt's out on the kerb, and at %s the pit boss owes the crew a favor."],
		"caught": ["NOBODY TOLD AUGIE", "Pruitt's out on the kerb, but Augie never found out who to thank."],
		"late": ["PRUITT CASHED OUT", "Pruitt walked out with his winnings, and Augie owes nobody anything."],
	}
	wins = ["owed"]


func venue() -> Venue:
	return Tideline.new()


func cast() -> Array[CharacterSheet]:
	return TidelineCast.all("favor")


func give_items(crew: Array) -> void:
	for c in crew:
		if c.cover == "inspector":
			c.items.append("card")
			return


func setup(job: Job) -> void:
	job.add_to_group("tideline_job")


func cleared(job: Job, c: CrewInfo, zone: String) -> bool:
	return zone == "corridor" and (Covers.looks_staff(c.outfit) or allowed_back(job, c))


func allowed_back(_job: Job, _c: CrewInfo) -> bool:
	return false


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	return TidelineRules.use(job, c, what)


func prompt_for(c: CrewInfo, what: String) -> Variant:
	var job: Job = null
	if c and c.node and c.node.is_inside_tree():
		job = c.node.get_tree().get_first_node_in_group("tideline_job") as Job
	return TidelineRules.prompt_for(job, c, what)


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	var checks: Dictionary = ch.face_of(c.id).checks
	match act:
		"throw_out", "take_relief":
			if job.flags.has("caught"):
				ch.say_scripted("He's already gone.")
				return true
			if checks.get("ask_regular", "") == "good" or checks.get("ask_surveillance", "") == "good":
				_catch(job, "hugo" if checks.get("ask_regular", "") == "good" else "camera", c.id)
				return true
			if act == "take_relief" or checks.get("call_manager", "") == "good":
				c.flags["relief"] = true
				if c.outfit != "croupier_temp":
					c.outfit = "croupier_temp"
					job.crew_changed.emit(c.id)
				ch.note("You've put %s on wheel two as the relief for Tess's break at a quarter to eleven." % job.describe(c.id))
				job.toast_for.emit(c.id, "Augie puts you on wheel two for Tess's break at 10:45. Stand behind the wheel when she goes.")
				return true
			ch.say_scripted("On what proof? Anton would have my job.")
			return true
		"confess":
			var lyle: Character = job.cast.get("lyle")
			if lyle and not job.flags.has("caught") and lyle.global_position.distance_to(ch.global_position) < 8.0:
				# She'll go to Augie on her break, away from Pruitt.
				ch.say_scripted("Not here. Not with him watching. On my break.")
				job.flags["tess_later"] = c.id
				return true
			if job.flags.has("caught") or job.flags.has("tess_confessing"):
				return true
			job.flags["tess_confessing"] = c.id
			ch.walk_to("pit_c")
			job.toast_for.emit(c.id, "Tess is going to tell Augie everything.")
			return true
		"watch_wheel":
			var phoned := TidelineRules.on_phone(job, c, ch)
			if not phoned or TidelineRules.calling_as(job, c, ch, "Caldera Gaming Board"):
				job.flags["watch_wheel"] = c.id
				ch.note("You've a camera on wheel two now. If Pruitt slides a single chip, you call Augie.")
			return true
		"expect_temp":
			var phoned := TidelineRules.on_phone(job, c, ch)
			if not phoned or TidelineRules.calling_as(job, c, ch, "Caldera Staffing"):
				job.flags["relief_booked"] = true
				var a: Character = job.cast.get("augie")
				if a:
					a.note("On the radio, Anton: \"Augie, Caldera Staffing's sending a relief for wheel two's break.\"")
			return true
	return false


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"hugo":
			# He'll back up any of the crew he's warmed to.
			var h: Character = job.cast.get("hugo")
			var warm := false
			for other in job.crew:
				var f: Dictionary = h.faces.get(other.id, {}) if h else {}
				if 0 in f.get("secrets", []) or (bool(f.get("met", false)) and int(f.get("suspicion", 2)) <= JobRules.TRUST):
					warm = true
			if warm:
				return Job.fact("good", "You saw Lyle Pruitt thrown off the Marlin's card game for sliding chips, and you like the person asking.", "Pruitt? Sliding chips on the Marlin's card game. I saw it myself, and I'll tell Anton so.")
			return Job.fact("bad", "You don't know who that is, and you're not getting dragged into anything.", "Who? I'm not getting dragged into anything, Augie.")
		"dmitri":
			if job.flags.has("caught") and str(job.flags.caught) == "camera":
				return Job.fact("good", "You have Pruitt on tape sliding chips at wheel two.", "Got him on tape, Augie. Clear as day.")
			return Job.fact("bad", "You haven't been watching wheel two; Anton told you not to.", "I've had no reason to look at wheel two.")
		"anton":
			if Job.any(said, ["relief", "croupier", "staffing", "agency"]):
				if job.flags.has("relief_booked"):
					return Job.fact("good", "Caldera Staffing told you a relief croupier is coming for wheel two's break.", "Yes, the agency rang. Relief for wheel two. Use them.")
				return Job.fact("bad", "You haven't booked any relief croupier tonight.", "Relief? I didn't book anyone.")
			if c and Job.any(said, ["pruitt", "lyle"]):
				return Job.fact("bad", "Mr Pruitt is a valued guest and you won't hear a word against him.", "Leave Mr Pruitt alone, Augie.")
			return Job.fact("bad", "You don't know them.", "No idea who that is.")
	return {}


func on_routine(job: Job, ch: Character, spot_name: String) -> bool:
	match ch.sheet.id:
		"tess":
			if job.flags.has("caught") or job.flags.has("tess_confessing"):
				return false
			if spot_name == "tess_smoke" and job.flags.has("tess_later"):
				job.flags["tess_out"] = true
				job.flags["tess_confessing"] = job.flags.tess_later
				ch.walk_to("pit_c")
				return false
			job.flags["tess_out"] = spot_name == "tess_smoke"
		"lyle":
			if job.flags.has("caught"):
				return false
	return true


func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"spin":
			_spin(job)
		"break":
			for c in job.crew:
				if c.flags.has("relief"):
					job.toast_for.emit(c.id, "Tess is on her break. Take wheel two.")
		"cash_out":
			if not job.flags.has("caught"):
				var l: Character = job.cast.get("lyle")
				if l:
					l.say_scripted("That's me done, Tess. Same time tomorrow.")


## The ball drops at wheel two. Pruitt slides a stack if the croupier's
## his, or tries it on a relief he thinks is blind.
func _spin(job: Job) -> void:
	if job.flags.has("caught"):
		return
	var lyle: Character = job.cast.get("lyle")
	var tess: Character = job.cast.get("tess")
	if lyle == null or lyle.walking or not TidelineRules.at(job, lyle, "lyle", 0.6):
		return
	var tess_dealing := tess != null and not bool(job.flags.get("tess_out", false)) and not job.flags.has("tess_confessing") and TidelineRules.at(job, tess, "tess", 0.6)
	if tess_dealing:
		if job.flags.has("watch_wheel") and TidelineRules.watching(job):
			_catch(job, "camera", int(job.flags.watch_wheel))
			return
		lyle.say_scripted("Seventeen! Again! Tess, you're my lucky charm.")
		var a: Character = job.cast.get("augie")
		if a:
			a.note("Pruitt won again at wheel two. You'd swear you saw his hand move, but you can't prove a thing.")
		return
	var spot: Vector3 = job.spot("tess").origin
	for c in job.free_crew():
		if c.flags.has("relief") and c.node and c.position().distance_to(spot) < AT_WHEEL:
			_catch(job, "relief", c.id)
			return


## Pruitt's caught. Augie throws him out; Tess goes off the floor.
func _catch(job: Job, how: String, crew_id := 0) -> void:
	job.flags["caught"] = how
	if crew_id != 0:
		job.flags["caught_by"] = crew_id
	var a: Character = job.cast.get("augie")
	var lyle: Character = job.cast.get("lyle")
	var tess: Character = job.cast.get("tess")
	var teo: Character = job.cast.get("teo")
	match how:
		"camera":
			var w: Character = job.cast.get("dmitri")
			if w and a:
				w.say_scripted("Augie, it's Dmitri. Got Pruitt on tape, wheel two, sliding a stack after the ball dropped.", a)
		"relief":
			if lyle:
				lyle.say_scripted("Seventeen! That's mine, pal.")
			job.toast_for.emit(crew_id, "Pruitt slides a stack onto seventeen after the ball drops. You saw it, and so did Augie.")
		"tess":
			if tess:
				tess.say_scripted("Augie. It's Pruitt. He slides chips after the ball drops. He pays me not to see. I'm sorry.")
		"hugo":
			pass
	if a:
		a.say_scripted("Mr Pruitt. You're done here. Teo, walk him out.")
		a.sheet.replies.push_front({"words": TOLD + ["owe", "favor", "it was us", "it was me", "we did"], "say": "You did that? Then I owe you one. I pay my debts.", "tone": "friendly", "up": -1})
		a.note("Pruitt's caught cheating and thrown out, and Tess with him. Whoever put you onto it, you owe them a favor.")
	if teo and not teo.minding:
		teo.say_scripted("Copy, Augie. Mr Pruitt, this way please.")
	if lyle:
		lyle.say_scripted("This is a mistake! Anton! Anton!")
		lyle.walk_to("kerb")
	if tess:
		tess.walk_to("staff_out")
	for ch in job.cast.values():
		if ch.sheet.staff or ch.sheet.halberd:
			ch.note("Lyle Pruitt has been caught cheating at wheel two and thrown out.")
	if not _owes(job):
		job.set_goal(0, "Pruitt's out. Tell Augie it was you.")


## Augie knows the crew put him onto Pruitt.
func _owes(job: Job) -> bool:
	if not job.flags.has("caught"):
		return false
	if str(job.flags.caught) in ["relief", "tess", "hugo"]:
		return true
	var a: Character = job.cast.get("augie")
	for c in job.free_crew():
		if a and a.faces.has(c.id) and Job.any(job.told(a, c.id), TOLD):
			return true
	return false


func tick(job: Job, delta: float) -> void:
	TidelineRules.tick(job, self, delta)
	var tess: Character = job.cast.get("tess")
	if job.flags.has("tess_confessing") and not job.flags.has("caught") and TidelineRules.at(job, tess, "pit_c"):
		_catch(job, "tess", int(job.flags.tess_confessing))
	if _owes(job) and not job.flags.has("owed_at"):
		job.flags["owed_at"] = job.elapsed + OWED_PAUSE
		var a: Character = job.cast.get("augie")
		if a:
			a.say_scripted("Whoever you are, I owe you one. Don't forget to collect.")


func check_end(job: Job) -> String:
	if job.flags.has("owed_at") and job.elapsed >= float(job.flags.owed_at):
		return "owed"
	return ""


func at_end(job: Job) -> String:
	if _owes(job):
		return "owed"
	return "caught" if job.flags.has("caught") else "late"


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	return TidelineRules.seen_in_money_room(job, ch, c, zone, false)


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"board":
			job.flags["watch_wheel"] = -1
			ch.note("The Gaming Board rang about wheel two. You've a camera on it now. If Pruitt slides a chip, you call Augie.")
		"staffing":
			job.flags["relief_booked"] = true
			ch.note("Caldera Staffing rang: a relief croupier for wheel two's break is on the way.")
			var a: Character = job.cast.get("augie")
			if a:
				a.note("On the radio, Anton: \"Augie, Caldera Staffing's sending a relief for wheel two's break.\"")
		"scare":
			job.flags["tess_scared"] = true
			ch.sheet.start_suspicion = 1
			for id in ch.faces:
				ch.faces[id]["suspicion"] = mini(int(ch.faces[id].suspicion), 1)
			ch.note("The Gaming Board rang you. They're looking at wheel two. You're terrified, and you'd talk to anyone kind about what to do.")


func report(job: Job, outcome: String, r: Dictionary) -> void:
	if outcome != "owed":
		return
	var how := {
		"camera": "Dmitri caught him on tape.", "relief": "He tried it on the crew's relief croupier.",
		"tess": "Tess told Augie everything.", "hugo": "Hugo Marlowe was the witness.",
	}
	r["text"] = str(r.text) + " " + str(how.get(str(job.flags.get("caught", "")), ""))
