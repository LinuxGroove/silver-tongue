class_name TidelineCountJob
extends JobDef
## Job 7, the Tideline's count room: learn the routine and the keys. The drop
## comes in at eleven and the count runs till a quarter to midnight; get a
## look inside while it's on, or walk out with the count sheet. Ways in:
## the Gaming Board's auditor (Marcus checks with Anton, Gloria with Marcus),
## Pilar's new cleaner (Gloria opens up for the cleaner at a quarter past),
## Halberd's relief for the drop (Marcus checks Wes's log), or Bea's codes
## after her shift and the ten minutes the room sits empty at twenty past,
## with the cameras blind.

const DROP := 23 * 60
const CLEAN := 23 * 60 + 15
const RUN := 23 * 60 + 20
const BACK := 23 * 60 + 28
## Seconds inside the count room during the count that make a look.
const LOOK_SECONDS := 6.0
## Real seconds the count room door stays open for the drop, the cleaner and
## the buzzer.
const DROP_OPEN := 40.0
const CLEAN_OPEN := 45.0
const BUZZ_OPEN := 30.0
const BOARD_WORDS := ["gaming board", "auditor", "inspector", "audit", "compliance", "observe"]
const CLEANER_WORDS := ["clean", "harbor", "housekeeping", "pilar", "mop"]
const RELIEF_WORDS := ["relief", "halberd", "dispatch", "drop"]


func _init() -> void:
	id = "tideline_count"
	venue_id = "tideline"
	number = 1
	memory_from = ["meridian"]
	title = "The count room"
	venue_name = "The Tideline"
	briefing = "The Rose is sitting in the Tideline's vault for a month, love, and that vault sits behind the cage and the count room. Before we go anywhere near it I want to know how the place moves its money: when the drop comes in, who carries which key, what goes on the count sheet. Get a look inside the count room while they're counting, or bring me the sheet. Halberd has the doors, and you'll know one of them. There's a man in a dark room watching every camera in the back. Mind him."
	goal = "Get a look inside the count room during the count, or the count sheet out, by 11:45"
	situation = TidelineCast.SITUATION + " Tonight is an ordinary Thursday: the drop comes in to the count room at eleven, and the count runs till a quarter to midnight."
	prize = "the count room's routine"
	take = 9000
	start = 22 * 60 + 30
	end = 23 * 60 + 45
	end_text = "the end of the count"
	seconds_per_minute = 18.0
	covers = {
		"auditor": {
			"title": "Gaming Board auditor", "names": ["Martin Kessler", "Marta Kessler"],
			"job": "a compliance auditor from the Caldera Gaming Board",
			"story": "The Board sends auditors to watch a count, unannounced. Your letter of inspection is a good copy: it passes a glance. Marcus will check with Anton, so somebody had better tell Anton you're coming.",
			"outfit": "auditor", "for": "Marcus on the staff door, then Gloria in the count room",
			"lines": [
				"Evening. %s, Caldera Gaming Board. I'm here to observe tonight's count.",
				"Your night manager will have been told. Check with Mr Varga.",
				"Unannounced is rather the point.",
				"I'll stand by the wall and touch nothing.",
			],
		},
		"cleaner": {
			"title": "Cleaner", "names": ["Danny Ruiz", "Dani Ruiz"],
			"job": "a temp from Harbor Cleaning",
			"story": "Pilar, the housekeeping supervisor, has been short a count room cleaner all week. The count room is cleaned at a quarter past eleven, with the count supervisor watching.",
			"outfit": "cleaner", "for": "Pilar, on the floor by the lounge",
			"lines": [
				"Hi, Harbor Cleaning sent me. I hear you're short tonight.",
				"Rough night? I can start right now.",
				"Where do you want me? Count room, they said.",
				"Just point me at the mop.",
			],
		},
		"halberd_temp": {
			"title": "Halberd relief", "names": ["Ray Doyle", "Rae Doyle"],
			"job": "a Halberd Security relief guard",
			"story": "Halberd sends a relief guard for the drop now and then, and Wes in the eye puts them on his log when Dispatch rings ahead. Marcus walks the drop into the count room at eleven.",
			"outfit": "halberd_temp", "for": "Marcus, on the staff door",
			"lines": [
				"Evening. Dispatch sent me as relief for the drop.",
				"I'm on Wes's log. Check with him.",
				"Where do you want me at eleven?",
				"You used to do the Meridian, didn't you?",
			],
		},
		"player": {
			"title": "Player", "names": ["Nick Sato", "Nina Sato"],
			"job": "a player from out of town, here for the tables",
			"story": "Nobody minds a player. Bea from the cage drinks at the Tide Bar after her shift at eleven, and she talks. The alley has no cameras, and the camera lines run through a junction box out there.",
			"outfit": "guest", "for": "Bea at the bar, after her shift",
			"lines": TidelineRules.PLAYER_LINES.duplicate(),
		},
	}
	cover_order = ["auditor", "cleaner", "halberd_temp", "player"]
	outfits = TidelineRules.OUTFITS.duplicate(true)
	staff_looking = TidelineRules.STAFF_LOOKING.duplicate()
	staff_rooms = TidelineRules.STAFF_ROOMS.duplicate()
	looks = TidelineCast.LOOKS
	extras = TidelineRules.EXTRAS.duplicate()
	routine = [
		[22 * 60 + 56, "marcus", "count_out"],
		[DROP, "marcus", "marcus_count"],
		[DROP, "bea", "bea_bar"],
		[CLEAN, "gloria", "count_door"],
		[RUN, "gloria", "cage_in"],
		[RUN, "marcus", "cage_c"],
		[BACK, "gloria", "gloria"],
		[BACK, "marcus", "marcus_count"],
		[23 * 60 + 40, "marcus", "marcus"],
	]
	chatter = TidelineCast.chatter("count", start, end)
	chatter.append_array([
		[22 * 60 + 50, "marcus", "Drop team, ten minutes. Meet me at the staff door.", "radio"],
		[22 * 60 + 59, "bea", "Window one closing. That's me done, Noor.", "near"],
		[DROP, "gloria", "Drop's in. Count starts now.", "radio"],
		[CLEAN, "gloria", "Pilar, I'm ready for your cleaner. Door's open.", "radio"],
		[RUN, "gloria", "First bags to the cage. Marcus, with me.", "radio"],
		[BACK, "marcus", "Back in the count room with Gloria.", "radio"],
	])
	events = [[DROP, "drop"], [CLEAN, "clean"], [RUN, "run"], [BACK, "back"], [23 * 60 + 40, "done"]]
	locked = ["staff", "count_room", "eye", "office", "cage", "vault", "back", "staff_room"]
	open = ["high_limit"]
	lockdown_doors = ["staff", "count_room", "cage", "back"]
	lockdown_text = "Lockdown. The back of the house is shut."
	door_texts = {
		"staff": "It's locked. Marcus keeps this door.",
		"count_room": "It's locked. There's a keypad, and a buzzer.",
		"eye": "It's locked. A sign says SURVEILLANCE. NO ENTRY.",
		"cage": "It's locked. The cage door opens from inside.",
		"vault": "The vault. Two keys, and neither is yours.",
		"back": "It's locked. There's a keypad.",
		"office": "It's locked.",
		"staff_room": "It's locked.",
	}
	keypads = {
		"count_pad": {"door": "count_room", "code": TidelineCast.COUNT_CODE, "label": "Count room"},
		"back_pad": {"door": "back", "code": TidelineCast.BACK_CODE, "label": "Back door"},
	}
	office = {"door": "office", "held": "held", "guard": "office_guard", "name": "Halberd's office"}
	items = {
		"count_sheet": {"name": "the count sheet", "at": "count_desk", "carry": "", "hot": true},
		"letter": {
			"name": "the Board letter", "at": "", "carry": "carrying a leather folder",
			"papers": "a Caldera Gaming Board letter of inspection in the name of %s", "forged": true,
			"copy": "the Board's seal is printed, not pressed, and the signature's a scan. It's a copy.",
			"belief": "has a Gaming Board letter of inspection", "to": ["marcus", "gloria", "anton"],
		},
	}
	actions = {
		"take_on_drop": {"text": "take them on as Halberd's relief for the drop: they walk the boxes into the count room with you at eleven", "kind": "opening", "lockdown": true},
		"ask_surveillance": {"text": "radio Wes in the eye to check his log (takes a moment)", "kind": "check"},
		"ask_housekeeping": {"text": "radio Pilar in housekeeping to check (takes a moment)", "kind": "check"},
		"ask_security": {"text": "radio Marcus on the staff door to check (takes a moment)", "kind": "check"},
		"let_in": {"text": "let them into the count room", "kind": "opening", "lockdown": true},
		"hire_cleaner": {"text": "take them on as tonight's count room cleaner", "kind": "opening"},
		"expect_cleaner": {"text": "expect the cleaner Harbor Cleaning is sending, and take them gladly", "kind": ""},
		"log_relief": {"text": "put a Halberd relief guard on your log for tonight's drop", "kind": ""},
		"expect_inspector": {"text": "tell Marcus to expect a Gaming Board auditor and give them every help", "kind": ""},
	}
	actions["take_request"] = {"text": "take their song request for your next set", "kind": ""}
	effects = {"take_request": {"flag": "requested", "toast": "%s will sing it in her next set."}}
	hot_words = ["count sheet", "count room code", "back door code", "loop the cameras"]
	phone = TidelineRules.phone_for(["anton", "wes", "pilar", "gloria"])
	caller_ids = ["Withheld", "Caldera Gaming Board", "Harbor Cleaning", "Halberd Dispatch"]
	mae_calls = [
		{"id": "board", "label": "Tell Anton the Board's coming", "who": "anton", "as": "Caldera Gaming Board",
			"line": "Caldera Gaming Board, compliance. One of our auditors will observe tonight's count. Unannounced, as always. Please give them every help.",
			"answer": "Of course. Of course. I'll tell my people.",
			"mae": "I'll ring Anton as the Gaming Board, love. He'll be expecting an auditor."},
		{"id": "agency", "label": "Tell Pilar a cleaner's coming", "who": "pilar", "as": "Harbor Cleaning",
			"line": "Harbor Cleaning here. We found you someone for the count room tonight after all. They're on their way.",
			"answer": "Oh, thank God. Send them to me, I'm on the floor.",
			"mae": "I'll ring Pilar from Harbor Cleaning. She'll be glad of anyone."},
		{"id": "dispatch", "label": "Put a relief on Wes's log", "who": "wes", "as": "Halberd Dispatch",
			"line": "Halberd Dispatch. We're sending a relief guard for tonight's drop. Put them on your log, would you?",
			"answer": "Relief for the drop. Fine, they're on the log.",
			"mae": "I'll ring Wes as Halberd Dispatch. You'll be on his log."},
		TidelineRules.FOOTAGE,
	]
	outcomes = {
		"look": ["A LOOK INSIDE", "Out of the count room at %s with the whole routine in your head."],
		"sheet": ["THE COUNT SHEET", "Out with the count sheet at %s: every key and every time on it."],
		"late": ["THE COUNT'S DONE", "The count ended with nobody the wiser and nothing learned."],
	}
	wins = ["look", "sheet"]


func venue() -> Venue:
	return Tideline.new()


func cast() -> Array[CharacterSheet]:
	return TidelineCast.all("count")


func give_items(crew: Array) -> void:
	for c in crew:
		if c.cover == "auditor":
			c.items.append("letter")
			return


func setup(job: Job) -> void:
	job.add_to_group("tideline_job")


## Whether the cameras and the staff are fine with a crew member being here.
func cleared(job: Job, c: CrewInfo, zone: String) -> bool:
	match zone:
		"corridor":
			return allowed_back(job, c) or Covers.looks_staff(c.outfit)
		"count_room":
			return c.flags.has("in_count") or c.flags.has("drop_temp") or c.flags.has("cleaner")
	return false


func allowed_back(job: Job, c: CrewInfo) -> bool:
	return c.flags.has("cleared") or c.flags.has("drop_temp") or c.flags.has("cleaner") or c.flags.has("in_count") \
		or "let_through" in job.cast["marcus"].face_of(c.id).opened


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	var said: Variant = TidelineRules.use(job, c, what)
	if said != null:
		return said
	if what == "door:count_room":
		var d = job.venue.doors.count_room
		if not d.is_open and d.locked:
			return _buzz(job, c)
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	var job := _job(c)
	var said: Variant = TidelineRules.prompt_for(job, c, what)
	if said != null:
		return said
	if what == "door:count_room" and job and not job.venue.doors.count_room.is_open and job.venue.zone_at(c.position()) == "corridor":
		return "Press the buzzer"
	return null


func can_take(job: Job, c: CrewInfo, item: String) -> String:
	if item == "count_sheet":
		var space: PhysicsDirectSpaceState3D = job.venue.get_world_3d().direct_space_state
		for id in ["gloria", "marcus"]:
			var ch: Character = job.cast.get(id)
			if ch and ch.look([c], space).has(c.id) and not c.flags.has("in_count"):
				return "Not with %s watching." % ch.sheet.name
	return ""


## The buzzer by the count room door: Gloria comes and opens it to see who's there.
func _buzz(job: Job, c: CrewInfo) -> String:
	var g: Character = job.cast.get("gloria")
	if g == null or g.minding or g.walking or g.on_call != 0 or job.venue.zone_at(g.global_position) != "count_room":
		return "You press the buzzer. Nobody comes."
	if job.elapsed < float(job.flags.get("buzz_until", -1.0)):
		return "You've buzzed. Gloria's coming."
	job.flags["buzz_until"] = job.elapsed + BUZZ_OPEN
	g.walk_to("count_door")
	job.open_for("count_room", BUZZ_OPEN)
	g.attend(c.node)
	g.note("The count room's buzzer went: %s is at the door. You've opened it to see who it is." % job.describe(c.id))
	g.say_scripted("Count room. Who is it?")
	return "You press the buzzer. The door opens a little way, and Gloria looks out."


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	var checks: Dictionary = ch.face_of(c.id).checks
	match act:
		"let_through", "take_on_drop":
			if ch.sheet.id != "marcus":
				return false
			if act == "take_on_drop" or checks.get("ask_surveillance", "") == "good":
				c.flags["drop_temp"] = true
				job.open_for("staff", Job.OPEN_FOR)
				ch.note("You've taken %s on as Halberd's relief for the drop. They walk the boxes in with you at eleven." % job.describe(c.id))
				job.toast_for.emit(c.id, "Marcus takes you on for the drop. Through the staff door: at eleven the drop goes into the count room, and you with it.")
				return true
			c.flags["cleared"] = "board" if checks.get("call_manager", "") == "good" else "cleaner" if checks.get("ask_housekeeping", "") == "good" else "marcus"
			job.open_for("staff", Job.OPEN_FOR)
			job.toast_for.emit(c.id, "Marcus lets you through the staff door.")
			return true
		"let_in":
			c.flags["in_count"] = true
			job.open_for("count_room", 15.0)
			job.flags["buzz_until"] = -1.0
			ch.walk_to(job.post_now(ch))
			job.toast_for.emit(c.id, "Gloria lets you into the count room. Stand by the wall and touch nothing.")
			if not job.flags.has("count_on"):
				job.toast_for.emit(c.id, "The drop comes in at eleven. Wait for the count.")
			return true
		"hire_cleaner":
			if TidelineRules.on_phone(job, c, ch):
				if TidelineRules.calling_as(job, c, ch, "Harbor Cleaning"):
					_cleaner_expected(job, ch)
				return true
			c.flags["cleaner"] = true
			if c.outfit != "cleaner":
				c.outfit = "cleaner"
				job.crew_changed.emit(c.id)
			job.open_for("staff", Job.OPEN_FOR)
			for id in ["marcus", "gloria"]:
				var other: Character = job.cast.get(id)
				if other:
					other.note("On the radio, Pilar: \"I've a new cleaner from Harbor Cleaning, %s, doing the count room at a quarter past.\"" % job.describe(c.id))
			job.toast_for.emit(c.id, "Pilar hires you and buzzes the staff door open. The count room is cleaned at 11:15, with Gloria there.")
			return true
		"expect_cleaner":
			if TidelineRules.calling_as(job, c, ch, "Harbor Cleaning"):
				_cleaner_expected(job, ch)
			return true
		"log_relief":
			if not TidelineRules.on_phone(job, c, ch) or TidelineRules.calling_as(job, c, ch, "Halberd Dispatch"):
				job.flags["relief_logged"] = true
			return true
		"expect_inspector":
			var phoned := TidelineRules.on_phone(job, c, ch)
			if (phoned and TidelineRules.calling_as(job, c, ch, "Caldera Gaming Board")) or (not phoned and c.outfit == "auditor"):
				job.flags["board_expected"] = true
				ch.note("You're expecting a Gaming Board auditor at tonight's count. They're to have every help.")
			return true
	return false


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	match who:
		"anton":
			if Job.any(said, BOARD_WORDS):
				if job.flags.has("board_expected"):
					return Job.fact("good", "The Gaming Board told you an auditor is coming to watch tonight's count.", "Yes, the Board rang. An auditor's watching the count tonight. Give them every help.")
				return Job.fact("bad", "Nobody has told you of any Gaming Board auditor tonight.", "The Board? Nobody's told me about any auditor tonight.")
			if Job.any(said, CLEANER_WORDS):
				return Job.fact("bad", "Cleaners are Pilar's business, not yours.", "Housekeeping's Pilar's business. Ask her.")
			return Job.fact("bad", "You don't know them.", "I've no idea who that is.")
		"wes":
			if job.flags.has("relief_logged") and Job.any(said, RELIEF_WORDS):
				return Job.fact("good", "Halberd Dispatch rang: a relief guard for tonight's drop is on your log.", "Yeah, Dispatch rang. Relief for the drop, on my log.")
			return Job.fact("bad", "Nobody's on your log tonight.", "Nobody on my log tonight.")
		"pilar":
			if c and c.flags.has("cleaner"):
				return Job.fact("good", "You hired them yourself tonight, from Harbor Cleaning, for the count room.", "Yes, that's my new cleaner. Let them through.")
			if job.flags.has("cleaner_expected") and Job.any(said, CLEANER_WORDS):
				return Job.fact("bad", "Harbor Cleaning said they'd send someone, but you haven't met them yet.", "Harbor said they'd send someone. Send them to me first.")
			return Job.fact("bad", "You haven't hired anyone tonight.", "I haven't hired anyone. Who is it?")
		"marcus":
			if c and str(c.flags.get("cleared", "")) == "board":
				return Job.fact("good", "You let a Gaming Board auditor through the staff door; Anton confirmed them.", "Yeah, the Board's auditor. Anton cleared them. They're good.")
			if c and (c.flags.has("drop_temp") or c.flags.has("cleaner") or c.flags.has("cleared")):
				return Job.fact("good", "You let them through the staff door tonight.", "Yeah, I let them through. They're good.")
			return Job.fact("bad", "Nobody like that came through your door.", "Nobody like that came through my door.")
	return {}


func on_routine(job: Job, ch: Character, spot_name: String) -> bool:
	if ch.sheet.id == "bea" and spot_name == "bea_bar":
		# Off shift with a drink in her hand, she tells anyone she likes.
		var limits := [1, 0, 1]
		for i in ch.sheet.secrets.size():
			ch.sheet.secrets[i]["suspicion"] = limits[i]
		ch.note("Your shift's over. You're off to the Tide Bar for a margarita, and you're in the mood to chat.")
	return true


func on_event(job: Job, event_name: String) -> void:
	match event_name:
		"drop":
			job.flags["count_on"] = true
			job.open_for("count_room", DROP_OPEN)
			for ch in job.cast.values():
				if ch.sheet.staff or ch.sheet.halberd:
					ch.note("The drop's gone into the count room. The count has started.")
			for c in job.crew:
				if c.flags.has("drop_temp"):
					job.toast_for.emit(c.id, "The drop's going in. Into the count room with Marcus, now.")
		"clean":
			job.flags["clean_window"] = true
			job.flags["buzz_until"] = job.elapsed + CLEAN_OPEN
			job.open_for("count_room", CLEAN_OPEN)
			for c in job.crew:
				if c.flags.has("cleaner"):
					job.toast_for.emit(c.id, "Gloria's opened the count room for the cleaner.")
		"run":
			job.flags["room_empty"] = true
		"back":
			job.flags.erase("room_empty")
		"done":
			job.flags.erase("count_on")


func tick(job: Job, delta: float) -> void:
	TidelineRules.tick(job, self, delta)
	# Gloria back to her table once the buzzer or the cleaner's time is up.
	var until := float(job.flags.get("buzz_until", -1.0))
	var g: Character = job.cast.get("gloria")
	if g and until > 0.0 and job.elapsed >= until and g.post == "count_door" and not g.walking and not g.minding:
		job.flags["buzz_until"] = -1.0
		g.walk_to("gloria")
	if not job.flags.has("count_on"):
		return
	for c in job.free_crew():
		if c.node == null or job.venue.zone_at(c.position()) != "count_room":
			continue
		c.flags["count_look"] = float(c.flags.get("count_look", 0.0)) + delta
		if float(c.flags.count_look) >= LOOK_SECONDS and not c.flags.has("looked"):
			c.flags["looked"] = true
			job.toast_for.emit(c.id, "You've seen the count: the carts, the key box, who signs for what. Now get out clean.")
			job.set_goal(c.id, "Get out of the back of the house with what you've seen")


func check_end(job: Job) -> String:
	var sheet := job.holder("count_sheet")
	if sheet and TidelineRules.in_public(job, sheet):
		return "sheet"
	for c in job.crew:
		if c.flags.has("looked") and TidelineRules.in_public(job, c):
			return "look"
	return ""


func at_end(job: Job) -> String:
	if job.holder("count_sheet") and not job.holder("count_sheet").held:
		return "sheet"
	return "look" if job.crew.any(func(c): return c.flags.has("looked") and not c.held) else "late"


func on_seen(job: Job, ch: Character, c: CrewInfo, zone: String) -> bool:
	return TidelineRules.seen_in_money_room(job, ch, c, zone, cleared(job, c, zone))


func on_heat(job: Job, was: int, now: int) -> void:
	if now == Heat.LOCKDOWN and was < now:
		job.flags.erase("count_on")
		job.toast_for.emit(0, "Gloria's stopped the count and locked her room.")


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"board":
			job.flags["board_expected"] = true
			ch.note("The Gaming Board rang: one of their auditors is observing tonight's count. They're to have every help.")
		"agency":
			_cleaner_expected(job, ch)
		"dispatch":
			job.flags["relief_logged"] = true
			ch.note("Halberd Dispatch rang: a relief guard for tonight's drop is on your log.")
		"footage":
			TidelineRules.keep_busy(job, ch)


func report(job: Job, outcome: String, r: Dictionary) -> void:
	if outcome == "look" and job.holder("count_sheet"):
		r["text"] = str(r.text) + " And the count sheet with it."


## Harbor Cleaning rang Pilar: she'll take their cleaner gladly.
func _cleaner_expected(job: Job, ch: Character) -> void:
	job.flags["cleaner_expected"] = true
	ch.sheet.start_suspicion = 1
	for id in ch.faces:
		ch.faces[id]["suspicion"] = mini(int(ch.faces[id].suspicion), 1)
	ch.note("Harbor Cleaning rang: they've found you a cleaner for the count room tonight after all, on the way now. You'll take them gladly.")


## The job a crew member's in, for prompts (which aren't handed the job).
func _job(c: CrewInfo) -> Job:
	if c == null or c.node == null or not c.node.is_inside_tree():
		return null
	for n in c.node.get_tree().get_nodes_in_group("tideline_job"):
		return n as Job
	return null
