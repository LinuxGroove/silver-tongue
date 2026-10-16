class_name TidelineVaultJob
extends JobDef
## Job 9, the vault. It takes two keys at once: Noor's, the cage manager's,
## and the one on a chain round Horace Bell's neck, the old comptroller's.
## Horace opens it for a release Anton confirms (Larkspur's courier), a
## transfer Marcus confirms (Halberd's team), or anyone Augie vouches for
## (the pit boss's favor). Or work the vault's own routine: hired as Noor's
## cage temp, wait for the float check at half past eleven, and have Marisol
## sing Horace's song while the vault stands open.

const FLOAT := 23 * 60 + 30
const TRAYS := 23 * 60 + 32
const SET := 23 * 60 + 33
const FLOAT_DONE := 23 * 60 + 38
## How near the cage's middle window to stand for Horace to hand the Rose over.
const AT_WINDOW := 2.5
## Real seconds Horace waits at the window before he puts the Rose back.
const WINDOW_WAIT := 60.0
const COURIER_WORDS := ["larkspur", "courier", "release", "buyer", "owner", "collect"]
const TRANSFER_WORDS := ["halberd", "transfer", "armored", "escort", "move"]
const TEMP_WORDS := ["staffing", "agency", "temp", "cashier", "relief"]

## The crew did Augie his favor at job 8 (from [Progress]; tests set it).
var owed := false


func _init() -> void:
	id = "tideline_vault"
	venue_id = "tideline"
	number = 3
	memory_from = ["meridian"]
	title = "The vault"
	venue_name = "The Tideline"
	briefing = "This is the one, love. The Rose is in the Tideline's vault, and the vault takes two keys turned at once: Noor's, who runs the cage, and old Horace Bell's, on a chain round his neck since before you were born. Horace is the way in. He'll open it for a release the manager confirms, or for Halberd's own transfer, or for a friend of Augie's, if Augie owes you. Or there's the float check at half past eleven, when the vault stands open and Horace's mind is on his late wife's song. In, out, and out the front door with the Rose before the time lock at ten to midnight."
	goal = "Get the Rose out of the vault and out of the Tideline by 11:50"
	situation = TidelineCast.SITUATION + " Tonight the vault's float check is at half past eleven, and the time lock shuts the vault till morning at ten to midnight."
	prize = "the Rose"
	take = 15000
	start = 22 * 60 + 50
	end = 23 * 60 + 50
	end_text = "the time lock"
	seconds_per_minute = 18.0
	owed = Progress.is_done("tideline_favor")
	covers = {
		"courier": {
			"title": "Larkspur courier", "names": ["Peter Wren", "Petra Wren"],
			"job": "a courier for Larkspur Holdings, the Rose's buyer",
			"story": "Larkspur keeps the Rose here for a month. A release needs Larkspur's call to Anton, the night manager, and Horace will check with him. Your release order is a good copy.",
			"outfit": "courier", "for": "Horace, in the lounge",
			"lines": [
				"Mr Bell? %s, from Larkspur Holdings. I'm here to collect the Rose.",
				"Here's the release order. Mr Varga has been told.",
				"Larkspur would rather it moved tonight, quietly.",
				"I'll wait wherever you like.",
			],
		},
		"halberd_escort": {
			"title": "Halberd transfer", "names": ["Ray Doyle", "Rae Doyle"],
			"job": "a guard on Halberd's transfer team",
			"story": "When Halberd moves something out of a vault, Dispatch rings the guard on the door first. Horace will ask Marcus, so Marcus had better have heard.",
			"outfit": "halberd_temp", "for": "Horace, then Marcus on the radio",
			"lines": [
				"Mr Bell. Halberd transfer team. We're moving the Rose tonight.",
				"Marcus on the staff door will have been told. Ask him.",
				"Two minutes and it's off your hands.",
				"Here's the transfer order.",
			],
		},
		"cage_temp": {
			"title": "Cage temp", "names": ["Leo Brandt", "Lena Brandt"],
			"job": "a cashier temp from Caldera Staffing",
			"story": "Noor's two cashiers short tonight. Caldera Staffing sends temps through Anton. At half past eleven the vault opens for the float check. Horace can't resist Marisol singing Moon over the Harbor, and the cameras have a junction box in the alley.",
			"outfit": "cage_temp", "for": "Noor, at the cage's third window",
			"lines": [
				"Hi, Caldera Staffing sent me. You're short tonight?",
				"Mr Varga booked me. Check with him.",
				"I've done cage work at the Harbor Club for three years.",
				"Where do you want me? Window one?",
			],
		},
		"player": {
			"title": "Player", "names": ["Nick Sato", "Nina Sato"],
			"job": "a player from out of town, here for the tables",
			"story": "Nobody minds a player. If Augie owes the crew a favor, a player can call it in. Marisol takes requests.",
			"outfit": "guest", "for": "Augie, at the pit, and Marisol",
			"lines": [
				"Evening, Augie. Remember us?",
				"You said you owed us one.",
				"Could you put in a word with Horace?",
				"Could you sing Moon over the Harbor? It's for Horace.",
			],
		},
	}
	cover_order = ["courier", "halberd_escort", "cage_temp", "player"]
	outfits = TidelineRules.OUTFITS.duplicate(true)
	staff_looking = TidelineRules.STAFF_LOOKING.duplicate()
	staff_rooms = TidelineRules.STAFF_ROOMS.duplicate()
	looks = TidelineCast.LOOKS
	extras = TidelineRules.EXTRAS.duplicate()
	routine = [
		[FLOAT - 2, "horace", "horace_vault"],
		[FLOAT - 2, "noor", "noor_vault"],
		[TRAYS, "noor", "noor"],
		[FLOAT_DONE, "horace", "horace"],
	]
	chatter = TidelineCast.chatter("vault", start, end)
	chatter.append_array([
		[FLOAT - 2, "noor", "Horace, it's the float. Meet me at the vault.", "radio"],
		[TRAYS, "noor", "Float trays to window one, please.", "near"],
		[FLOAT_DONE, "noor", "Vault's shut. Float's done.", "radio"],
	])
	events = [[FLOAT, "float"], [TRAYS, "trays"], [SET, "set"], [FLOAT_DONE, "float_done"]]
	locked = ["staff", "count_room", "eye", "office", "cage", "vault", "back", "staff_room"]
	open = ["high_limit"]
	lockdown_doors = ["staff", "count_room", "cage", "vault", "back"]
	lockdown_text = "Lockdown. The doors are shut and Halberd's on the front."
	door_texts = {
		"staff": "It's locked. Marcus keeps this door.",
		"count_room": "It's locked.",
		"eye": "It's locked. A sign says SURVEILLANCE. NO ENTRY.",
		"cage": "It's locked. The cage door opens from inside.",
		"vault": "Two keys, turned at once. Neither is yours.",
		"back": "It's locked. There's a keypad.",
	}
	keypads = {
		"count_pad": {"door": "count_room", "code": TidelineCast.COUNT_CODE, "label": "Count room"},
		"back_pad": {"door": "back", "code": TidelineCast.BACK_CODE, "label": "Back door"},
	}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's office"}
	items = {
		"rose": {"name": "the Rose", "at": "vault_table", "carry": "carrying a small black case", "hot": true},
		"release": {
			"name": "the release order", "at": "", "carry": "carrying a Larkspur Holdings envelope",
			"papers": "a release order from Larkspur Holdings for the Rose, to their courier %s", "forged": true,
			"copy": "the letterhead's a photocopy and the signature's printed. It's not real.",
			"belief": "has a release order from Larkspur Holdings for the Rose", "to": ["horace", "noor", "anton", "marcus"],
		},
		"transfer": {
			"name": "the transfer order", "at": "", "carry": "",
			"papers": "a Halberd transfer order for one item from the Tideline's vault, escort %s", "forged": true,
			"copy": "the order number's the wrong format. It's a fake.",
			"belief": "has a Halberd transfer order", "to": ["horace", "marcus", "noor"],
		},
	}
	actions = {
		"release_rose": {"text": "open the vault with Noor and hand them the Rose through the cage's middle window", "kind": "opening", "lockdown": true},
		"ask_security": {"text": "radio Marcus on the staff door to check (takes a moment)", "kind": "check"},
		"ask_pit": {"text": "radio Augie in the pit to check (takes a moment)", "kind": "check"},
		"hire_cashier": {"text": "take them on as tonight's cage temp: through the staff door and into the cage", "kind": "opening", "lockdown": true},
		"vouch": {"text": "tell Horace on the radio that they're friends of yours and he can trust them", "kind": "opening"},
		"take_request": {"text": "take their song request for your next set", "kind": ""},
		"expect_courier": {"text": "tell Horace that Larkspur's courier is coming for the Rose tonight", "kind": ""},
		"expect_temp": {"text": "tell Noor that a cage temp from Caldera Staffing is coming", "kind": ""},
		"expect_transfer": {"text": "expect Halberd's transfer team tonight, and say so if anyone asks", "kind": ""},
	}
	hot_words = ["the vault", "both keys", "horace's key", "loop the cameras"]
	phone = TidelineRules.phone_for(["anton", "marcus", "noor", "wes"])
	caller_ids = ["Withheld", "Larkspur Holdings", "Halberd Dispatch", "Caldera Staffing", "Caldera Gaming Board"]
	mae_calls = [
		{"id": "buyer", "label": "Tell Anton Larkspur's collecting", "who": "anton", "as": "Larkspur Holdings",
			"line": "Larkspur Holdings, for Mr Varga. Our courier will collect the Rose tonight with a release order. Please let Mr Bell know.",
			"answer": "Tonight? Of course. I'll tell Horace.",
			"mae": "I'll ring Anton as Larkspur, love. When Horace checks, Anton will say yes."},
		{"id": "dispatch", "label": "Book a Halberd transfer", "who": "marcus", "as": "Halberd Dispatch",
			"line": "Marcus, Halberd Dispatch. Transfer team coming for one item from the Tideline's vault tonight. Walk them in.",
			"answer": "Transfer tonight. Copy that.",
			"mae": "I'll ring Marcus as Halberd Dispatch. He'll vouch for a transfer team."},
		{"id": "staffing", "label": "Book a cage temp", "who": "anton", "as": "Caldera Staffing",
			"line": "Caldera Staffing. Your cage temp for tonight is on the way. So sorry it's late notice.",
			"answer": "A temp? Noor will be thrilled. Fine.",
			"mae": "I'll ring Anton from the agency. Noor will get her temp."},
		TidelineRules.FOOTAGE,
	]
	outcomes = {
		"out": ["THE ROSE", "Out of the Tideline with the Rose at %s."],
		"late": ["THE TIME LOCK", "At ten to midnight the time lock shut the vault with the Rose still inside."],
	}
	wins = ["out"]


func venue() -> Venue:
	return Tideline.new()


func cast() -> Array[CharacterSheet]:
	return TidelineCast.all("vault", owed)


func give_items(crew: Array) -> void:
	for c in crew:
		if c.cover == "courier":
			c.items.append("release")
		elif c.cover == "halberd_escort":
			c.items.append("transfer")


func setup(job: Job) -> void:
	job.add_to_group("tideline_job")


func cleared(job: Job, c: CrewInfo, zone: String) -> bool:
	match zone:
		"corridor":
			return Covers.looks_staff(c.outfit) or allowed_back(job, c)
		"cage":
			return c.flags.has("cage_temp")
		"vault":
			return c.flags.has("cage_temp") and job.flags.has("vault_open")
	return false


func allowed_back(_job: Job, c: CrewInfo) -> bool:
	return c.flags.has("cage_temp")


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	if what == "item:rose":
		var said := job.take(c.id, "rose")
		if job.holder("rose") == c:
			job.flags["rose_taken"] = c.id
			if TidelineRules.seen_taking(job, c, "the Rose's case"):
				return said + " The vault's camera saw that."
		return said
	return TidelineRules.use(job, c, what)


func prompt_for(c: CrewInfo, what: String) -> Variant:
	var job: Job = null
	if c and c.node and c.node.is_inside_tree():
		job = c.node.get_tree().get_first_node_in_group("tideline_job") as Job
	return TidelineRules.prompt_for(job, c, what)


func can_take(job: Job, c: CrewInfo, item: String) -> String:
	if item != "rose":
		return ""
	var space: PhysicsDirectSpaceState3D = job.venue.get_world_3d().direct_space_state
	for ch in job.cast.values():
		if (ch.sheet.staff or ch.sheet.halberd) and ch.look([c], space).has(c.id):
			return "Not with %s watching." % ch.sheet.name
	return ""


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"release_rose":
			if job.flags.has("release") or job.holder("rose") != null or job.flags.has("released"):
				return true
			job.flags["release"] = "keys"
			job.flags["release_for"] = c.id
			ch.say_scripted("Noor, it's Horace. I need the vault open. A release.", job.cast.get("noor"))
			ch.walk_to("horace_vault")
			var noor: Character = job.cast.get("noor")
			if noor and not noor.minding:
				noor.walk_to("noor_vault")
			job.toast_for.emit(c.id, "Horace is opening the vault. Wait at the cage's middle window.")
			return true
		"hire_cashier":
			c.flags["cage_temp"] = true
			if c.outfit != "cage_temp":
				c.outfit = "cage_temp"
				job.crew_changed.emit(c.id)
			job.open_for("staff", Job.OPEN_FOR)
			job.open_for("cage", Job.OPEN_FOR * 1.6)
			var m: Character = job.cast.get("marcus")
			if m:
				m.note("On the radio, Noor: \"Marcus, I've a temp from Caldera Staffing coming through to the cage. %s.\"" % job.describe(c.id))
			job.toast_for.emit(c.id, "Noor takes you on. The staff door and the cage door are open for you: window one is yours. The float check is at 11:30.")
			return true
		"vouch":
			if not owed:
				ch.say_scripted("I don't owe you a thing. Who are you?")
				return true
			c.flags["vouched"] = true
			job.flags["vouched"] = true
			var h: Character = job.cast.get("horace")
			if h:
				h.note("On the radio, Augie: \"Horace, the people coming to see you are friends of mine, %s. Whatever they need, they're good for it.\"" % job.describe(c.id))
			job.toast_for.emit(c.id, "Augie's told Horace you're friends of his. Go and see Horace in the lounge.")
			return true
		"take_request":
			job.flags["song"] = true
			ch.note("You've a request for your next set: %s, for Horace." % TidelineCast.SONG)
			job.toast_for.emit(c.id, "Marisol will sing it in her next set, at 11:33.")
			return true
		"expect_courier":
			if not TidelineRules.on_phone(job, c, ch) or TidelineRules.calling_as(job, c, ch, "Larkspur Holdings"):
				job.flags["courier_expected"] = true
				ch.note("Larkspur Holdings rang: their courier collects the Rose tonight with a release order.")
			return true
		"expect_temp":
			if not TidelineRules.on_phone(job, c, ch) or TidelineRules.calling_as(job, c, ch, "Caldera Staffing"):
				job.flags["temp_expected"] = true
				ch.note("Caldera Staffing rang: a cage temp for Noor is on the way.")
			return true
		"expect_transfer":
			if not TidelineRules.on_phone(job, c, ch) or TidelineRules.calling_as(job, c, ch, "Halberd Dispatch"):
				job.flags["transfer_expected"] = true
				ch.note("Halberd Dispatch rang: a transfer team is coming for one item from the vault tonight.")
			return true
	return false


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"anton":
			if Job.any(said, COURIER_WORDS):
				if job.flags.has("courier_expected"):
					return Job.fact("good", "Larkspur Holdings rang you: their courier collects the Rose tonight.", "Larkspur rang this evening, Horace. Their courier's collecting tonight. Release it.")
				return Job.fact("bad", "Larkspur Holdings hasn't said anything to you about a courier tonight.", "Larkspur? Nobody's called me about a courier. Don't release anything.")
			if Job.any(said, TEMP_WORDS):
				if job.flags.has("temp_expected"):
					return Job.fact("good", "Caldera Staffing told you a cage temp is coming tonight.", "Yes, the agency rang. Your temp's expected, Noor.")
				return Job.fact("bad", "You haven't booked a cage temp tonight.", "A temp? I didn't book one.")
			return Job.fact("bad", "You don't know them.", "No idea who that is.")
		"marcus":
			if job.flags.has("transfer_expected") and Job.any(said, TRANSFER_WORDS):
				return Job.fact("good", "Halberd Dispatch told you a transfer team is coming for one item from the vault tonight.", "Yeah, Dispatch rang. Transfer team for one item. They're ours.")
			return Job.fact("bad", "Nobody's told you of any transfer tonight.", "Nobody's told me about any transfer, Horace. Hold it.")
		"augie":
			# Augie vouches for the whole crew, not just whoever asked him.
			if c and job.flags.has("vouched"):
				return Job.fact("good", "You vouched for them: they're the people you owe.", "They're with me, Horace. Whatever they need, they're good for it.")
			return Job.fact("bad", "You've never vouched for them.", "Never seen them, Horace. Don't open anything.")
	return {}


func on_routine(job: Job, ch: Character, _spot: String) -> bool:
	if ch.sheet.id in ["horace", "noor"] and str(job.flags.get("release", "")) in ["keys", "fetch", "window"]:
		return false
	if ch.sheet.id == "horace" and job.flags.has("horace_away"):
		return false
	return true


func on_event(job: Job, event_name: String) -> void:
	var noor: Character = job.cast.get("noor")
	var horace: Character = job.cast.get("horace")
	match event_name:
		"float":
			job.flags["float_due"] = true
		"trays":
			for c in job.crew:
				if c.flags.has("cage_temp"):
					job.toast_for.emit(c.id, "Noor wants the float trays at window one. The vault's standing open.")
		"set":
			var m: Character = job.cast.get("marisol")
			if not job.flags.has("song"):
				if m:
					m.say_scripted("Thank you, darlings. Something a little faster now.")
				return
			if m:
				m.say_scripted("This one's for Horace. %s." % TidelineCast.SONG)
			if horace and not horace.minding and str(job.flags.get("release", "")) == "":
				job.flags["horace_away"] = true
				if job.venue.zone_at(horace.global_position) != "lounge":
					horace.say_scripted("Noor, two minutes. It's Eleanor's song.")
					horace.walk_to("horace")
				for id in horace.faces:
					horace.faces[id]["suspicion"] = maxi(int(horace.faces[id].suspicion) - 1, 0)
				horace.note("Marisol's singing Moon over the Harbor. Eleanor's song. For a few minutes, nothing else in the world matters.")
		"float_done":
			job.flags.erase("float_due")
			job.flags.erase("horace_away")
			if job.flags.has("vault_open"):
				job.flags.erase("vault_open")
				job.set_door("vault", false)
			if noor and str(job.items.get("rose", {}).get("at", "")) != "vault_table" and not job.flags.has("released"):
				_missing(job, noor)


## Noor finds the Rose gone after the float.
func _missing(job: Job, noor: Character) -> void:
	job.flags["missing"] = true
	noor.say_scripted("Marcus! The Rose is gone! Lock it all down!", job.cast.get("marcus"))
	job.heat.bump(Heat.CAUGHT * 2.0)
	for c in job.free_crew():
		if c.flags.has("cage_temp"):
			JobRules.nudge(noor.face_of(c.id), JobRules.CAUGHT)
			noor.event("The Rose is gone from the vault, and the only stranger in the cage tonight was %s." % job.describe(c.id), c.id, "event")


func tick(job: Job, delta: float) -> void:
	TidelineRules.tick(job, self, delta)
	var noor: Character = job.cast.get("noor")
	var horace: Character = job.cast.get("horace")
	# The float: once Horace and Noor are both at the vault, it opens.
	if job.flags.has("float_due") and not job.flags.has("vault_open") and str(job.flags.get("release", "")) == "" \
			and TidelineRules.at(job, horace, "horace_vault") and TidelineRules.at(job, noor, "noor_vault"):
		job.flags["vault_open"] = true
		job.set_door("vault", true)
		horace.say_scripted("Both keys. Three, two, one.")
	_release(job, horace, noor)
	# The Rose goes back to the vault from anyone held.
	var h := job.holder("rose")
	if h and h.held:
		job.place_item(h.id, "rose", "vault_table")
		job.toast_for.emit(0, "Halberd took the Rose back to the vault.")


## Horace's release: both keys, the Rose from its table, and through the
## cage's middle window to whoever it's for.
func _release(job: Job, horace: Character, noor: Character) -> void:
	match str(job.flags.get("release", "")):
		"keys":
			if TidelineRules.at(job, horace, "horace_vault") and TidelineRules.at(job, noor, "noor_vault"):
				job.flags["release"] = "fetch"
				horace.say_scripted("Both keys. Three, two, one.")
				horace.walk_to("rose_table")
		"fetch":
			if TidelineRules.at(job, horace, "rose_table"):
				job.flags["release"] = "window"
				job.place_item(0, "rose", "")
				horace.walk_to("horace_window")
				noor.walk_to("noor")
				job.flags["window_until"] = job.elapsed + WINDOW_WAIT
		"window":
			if not TidelineRules.at(job, horace, "horace_window"):
				return
			var to := _at_window(job)
			if to:
				job.flags["release"] = "done"
				job.flags["released"] = to.id
				job.give_item(to.id, "rose")
				horace.attend(to.node)
				horace.say_scripted("Here she is. Sign nothing, tell nobody, and mind the step.")
				horace.walk_to("horace")
				job.toast_for.emit(to.id, "Horace passes you the Rose's case through the window. Walk it out the front.")
				return
			if not job.flags.has("window_told"):
				job.flags["window_told"] = true
				job.toast_for.emit(int(job.flags.get("release_for", 0)), "Horace is waiting at the cage's middle window with the Rose.")
			if job.elapsed >= float(job.flags.get("window_until", INF)):
				job.flags["release"] = ""
				job.flags.erase("window_told")
				job.place_item(0, "rose", "vault_table")
				horace.say_scripted("Nobody? Then back it goes.")
				horace.walk_to("horace")
				job.toast_for.emit(0, "Horace got tired of waiting and put the Rose back.")


## Who's at the cage's middle window for the Rose: the one it's for, or any of the crew.
func _at_window(job: Job) -> CrewInfo:
	var spot: Vector3 = job.spot("window_2").origin
	var want := job.crew_by_id(int(job.flags.get("release_for", 0)))
	if want and not want.held and want.node and want.position().distance_to(spot) < AT_WINDOW:
		return want
	for c in job.free_crew():
		if c.node and c.position().distance_to(spot) < AT_WINDOW:
			return c
	return null


func check_end(job: Job) -> String:
	var h := job.holder("rose")
	if h and not h.held and h.node and job.venue.zone_at(h.position()) in ["outside", "doorway"]:
		return "out"
	return ""


func at_end(job: Job) -> String:
	var h := job.holder("rose")
	return "out" if h and not h.held else "late"


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	return TidelineRules.seen_in_money_room(job, ch, c, zone, cleared(job, c, zone))


func on_heat(job: Job, was: int, now: int) -> void:
	if now == Heat.LOCKDOWN and was < now:
		job.lock("front", true)
	elif was == Heat.LOCKDOWN and now < was:
		job.lock("front", false)


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"buyer":
			job.flags["courier_expected"] = true
			ch.note("Larkspur Holdings rang: their courier collects the Rose tonight with a release order.")
		"dispatch":
			job.flags["transfer_expected"] = true
			ch.note("Halberd Dispatch rang: a transfer team is coming for one item from the vault tonight. You walk them in.")
		"staffing":
			job.flags["temp_expected"] = true
			ch.note("Caldera Staffing rang: a cage temp for Noor is on the way.")
		"footage":
			TidelineRules.keep_busy(job, ch)


func report(job: Job, outcome: String, r: Dictionary) -> void:
	if outcome == "out":
		r["text"] = str(r.text) + (" Horace handed it over himself." if job.flags.has("released") else " Nobody saw it go.")
