class_name MarlinAuctionJob
extends JobDef
## Job 3 aboard the Marlin: the charity auction itself, moored in the
## marina. Win the Rose with money the crew doesn't have: register on a
## forged letter of guarantee and have Caldera Mutual confirm it when the
## bidding passes two million, scare Margit Lindqvist out of the bidding
## with a whisper about the certificate so it never gets that high, or have
## Hugo Marlowe bid for a client, since Mr Ashcombe takes his word.
##
## The sale is the job's own: at eight Mr Ashcombe opens it, and every half
## minute (the "bid" events) the next bidder who can goes a step higher;
## when nobody does, he asks for an advance, goes once and twice, and the
## hammer falls on whoever has it.

const SEATS := 19 * 60 + 55
const SALE := 20 * 60
const LAST := 20 * 60 + 20
## Game minutes between the sale's rounds.
const ROUND := 0.5
## The opening bid and each step, and how high each bidder goes.
const OPENING := 1200000
const STEP := 100000
const PIETER_LIMIT := 1900000
const MARGIT_LIMIT := 2400000
const PROXY_LIMIT := 3000000
## Real seconds from the hammer to the end of the night.
const HAMMER_WAIT := 3.0
## The caller ID the bank rings from.
const BANK := "Caldera Mutual"
## The paddles Ms Castell gives out, in order, and how she says them.
const PADDLES := {"paddle_1": "forty-one", "paddle_2": "forty-two"}


func _init() -> void:
	id = "marlin_auction"
	venue_id = "marlin"
	number = 3
	memory_from = ["meridian"]
	title = "The auction"
	venue_name = "The Marlin"
	briefing = "Eight o'clock, love, in the Marlin's saloon: the Rose goes under the hammer, and she's coming home with us on money we haven't got. Here's what the captain's file told us. Margit Lindqvist's bank will take her to two and a half; Pieter Achterberg's to two. Register with Ms Castell on my letter from Caldera Mutual, and when the bidding passes two million and she rings the bank, I'll be the bank. Or whisper about the certificate: Margit's been burned before, and Pieter will tell her anything. Or get Hugo Marlowe to bid for a client. Ashcombe takes Hugo's word for anything."
	goal = "Win the Rose at the auction at eight"
	situation = MarlinCast.SITUATIONS.auction
	prize = "the Rose"
	take = 12000
	start = 19 * 60 + 30
	end = LAST
	end_text = "the sale closes"
	covers = {
		"bidder": {
			"title": "Bidder",
			"names": ["Charles Wren", "Charlotte Wren"],
			"job": "a collector from out of town, bidding with a letter of guarantee from Caldera Mutual",
			"story": "Register at Ms Castell's desk with Mae's letter and she'll give you a paddle. Anything over two million, she rings the bank. Or make sure nobody pushes you that high.",
			"outfit": "guest",
			"for": "Ms Castell at the desk, then Mr Ashcombe at the rostrum",
			"lines": [
				"Good evening. I'd like to register to bid.",
				"%s. Here's my bank's letter of guarantee.",
				"Two million!",
				"Mrs Lindqvist, is it true what they're saying about the certificate?",
			],
		},
		"agent": {
			"title": "Buyer's agent",
			"names": ["Simon Fairley", "Sarah Fairley"],
			"job": "a buyer's agent for a private client who can't be seen bidding",
			"story": "Hugo Marlowe bids for clients for three percent, and Mr Ashcombe takes his word without a bank. Admire the boat he sold, then give him a client.",
			"outfit": "agent_suit",
			"for": "Hugo Marlowe, in the saloon",
			"lines": [
				"You sold the Halvorsens this boat? She's beautiful.",
				"%s. I act for a client who can't be seen bidding.",
				"Three percent, Mr Marlowe, if you'll bid for my client.",
				"As high as three million, if it comes to it.",
			],
		},
		"stew": {
			"title": "Stew",
			"names": ["Danny Price", "Dani Price"],
			"job": "a temp stew serving drinks in the saloon during the sale",
			"story": "Stews hear everything and pass on more. Pieter Achterberg repeats any whisper to Margit Lindqvist, and one doubt about the certificate takes her out of the bidding. A guest who can't be seen bidding might want Hugo Marlowe to bid for them.",
			"outfit": "stew_whites",
			"for": "Mr Achterberg, then Mrs Lindqvist, in the saloon",
			"lines": [
				"Champagne, Mr Achterberg?",
				"Between us, sir, I heard something about the certificate.",
				"They say it's a copy. The real one's in Antwerp.",
				"%s, sir. I'm with Bianca tonight.",
			],
		},
	}
	cover_order = ["bidder", "agent", "stew"]
	outfits = {
		"stew_whites": {"job": "yacht_stew", "male": "the Marlin's white steward's uniform", "female": "the Marlin's white stewardess's uniform"},
		"agent_suit": {"job": "agent", "male": "a gray suit and a pale blue shirt", "female": "a gray suit and a pale blue blouse"},
	}
	staff_looking = ["stew_whites"]
	staff_rooms = MarlinCast.CREW_ROOMS.duplicate()
	looks = MarlinCast.LOOKS
	extras = {"aft_deck": "guest", "saloon": {"job": "guest", "clips": ["Sitting_Idle", "Sitting_Talking"]}, "dining": "yacht_stew"}
	routine = [
		[SEATS, "nina", "nina_phone"],
		[SEATS, "teo", "saloon_in"],
	]
	chatter = [
		[19 * 60 + 32, "rupert", "Margaret and I are in fine voice tonight, Ms Castell.", "near"],
		[19 * 60 + 33, "nina", "He's named his gavel. Registration's at the desk, ladies and gentlemen.", "near"],
		[19 * 60 + 37, "pieter", "Margit! You look terrified already. Is it the price, or the stone?", "near"],
		[19 * 60 + 38, "margit", "Go away, Pieter.", "near"],
		[19 * 60 + 42, "celeste", "Hugo, if you bid for anyone tonight, at least make it someone with taste.", "near"],
		[19 * 60 + 43, "hugo", "Rupert's taken my word for twenty years, Celeste. I'd hate to waste it.", "near"],
		[19 * 60 + 48, "teo", "Kofi, Teo. Gangway's busy. Keep the crew door shut.", "radio"],
		[19 * 60 + 48, "kofi", "It's shut, Teo.", "radio"],
		[19 * 60 + 51, "nina", "Registration closes at eight, ladies and gentlemen.", "near"],
		[SEATS, "rupert", "Ladies and gentlemen, please take your seats.", "near"],
	]
	events = [[SEATS, "seats"], [SALE, "sale"]]
	var t := SALE + ROUND
	while t <= LAST - 2:
		events.append([t, "bid"])
		t += ROUND
	locked = ["crew", "captain", "safe", "bridge"]
	unlocked = ["galley", "cabin_a", "cabin_b", "sun"]
	open = ["saloon", "gangway"]
	lockdown_doors = ["gangway", "crew"]
	lockdown_text = "Lockdown. Halberd has shut the gangway, and the sale has stopped."
	door_texts = {"crew": "The crew door. Locked.", "captain": "The captain's cabin. Locked.", "bridge": "The bridge. Locked."}
	office = {"door": "cabin_b", "held": "held", "guard": "held_guard", "name": "a locked crew cabin below decks"}
	items = {
		"guarantee": {"name": "a letter of guarantee", "at": "", "carry": "",
			"papers": "a letter of guarantee from Caldera Mutual for %s, to three million dollars", "forged": true,
			"copy": "the bank's seal is printed, not pressed, and the account number is two digits short.",
			"belief": "registering to bid, with a letter of guarantee from Caldera Mutual", "to": ["nina"]},
		"paddle_1": {"name": "paddle 41", "at": "", "carry": "holding bidding paddle 41"},
		"paddle_2": {"name": "paddle 42", "at": "", "carry": "holding bidding paddle 42"},
	}
	actions = {
		"register": {"text": "register them to bid and give them a paddle, once they've shown a letter of guarantee", "kind": "opening"},
		"note_guarantee": {"text": "note a bank's confirmation of its client's letter of guarantee (only the bank, ringing you, confirms)", "kind": "opening"},
		"take_bid": {"text": "take their bid: they've raised their paddle or called out a bid", "kind": ""},
		"withdraw": {"text": "decide not to bid on the Rose at all, and leave the saloon", "kind": "opening"},
		"spread_word": {"text": "go straight over and tell Margit Lindqvist what you've just heard", "kind": "opening"},
		"bid_for": {"text": "agree to bid for their client at the sale tonight, for three percent", "kind": "opening"},
		"ask_registrar": {"text": "radio Ms Castell, the registrar, to check they're a registered bidder (takes a moment)", "kind": "check"},
		"ask_bosun": {"text": "radio Kofi, the bosun, to check they're crew (takes a moment)", "kind": "check"},
	}
	hot_words = ["fake letter", "no money", "can't pay", "the reserve"]
	# The Rose is the night's lot: everyone aboard talks about her.
	cool_words = ["the rose", "diamond"]
	phone = [
		{"id": "registrar", "name": "Ashcombe & Vale, Nina Castell", "who": "nina"},
		{"id": "hugo", "name": "Hugo Marlowe", "who": "hugo"},
		{"id": "chief_stew", "name": "Bianca, chief stew", "who": "bianca"},
	]
	caller_ids = ["Withheld", BANK, "Halvorsen Shipping", "Caldera Museum"]
	mae_calls = [
		{"id": "bank", "label": "Ring Ms Castell as the bank", "who": "nina", "as": BANK,
			"line": "Good evening, Caldera Mutual, private clients. I'm ringing to confirm our client's letter of guarantee for tonight's sale, to three million.",
			"answer": "Thank you. I'll note it against their paddle.",
			"mae": "I'll ring Ms Castell as Caldera Mutual, love. When the bidding passes two million, your letter will stand."},
		{"id": "client", "label": "Ring Hugo as a client", "who": "hugo", "as": "Withheld",
			"line": "Mr Marlowe? I can't be seen bidding tonight, but my agent's aboard, and I'm told you're the man to bid for me. Three percent. My agent will tell you the rest.",
			"answer": "Three percent? I'm listening.",
			"mae": "I'll ring Hugo as a client who can't be seen bidding. He'll be all ears when you find him."},
	]
	outcomes = {
		"won": ["SOLD TO THE CREW", "The hammer fell on the crew's paddle at %s, on money nobody has."],
		"proxy": ["SOLD, BY PROXY", "Hugo Marlowe bought the Rose for the crew's client at %s."],
		"sold": ["SOLD TO ANOTHER", "The Rose went to another bidder at %s."],
		"passed": ["NOT SOLD", "The Rose didn't sell tonight."],
		"unsold": ["NO SALE", "The sale never finished, and the Rose went back to the museum."],
	}
	wins = ["won", "proxy"]


func venue() -> Venue:
	return Marlin.new("auction")


func cast() -> Array[CharacterSheet]:
	return MarlinCast.all("auction")


func give_items(crew: Array) -> void:
	for c in crew:
		if c.cover == "bidder":
			c.items.append("guarantee")


func use(job: Job, c: CrewInfo, what: String) -> Variant:
	match what:
		"rostrum":
			return _crew_bid(job, c) if _paddle(c) != "" else "Mr Ashcombe's rostrum. Only registered paddles bid."
		"character:rupert":
			if _paddle(c) != "":
				return _crew_bid(job, c)
		"paddle":
			var nina: Character = job.cast.get("nina")
			if _paddle(c) != "":
				return "You're registered: paddle %s." % _paddle_number(_paddle(c))
			if nina == null or not _at(job, "nina", ["nina_desk"]):
				return "Nobody's at the desk. Ms Castell has gone to the telephones in the saloon."
			if "guarantee" in c.items:
				job.show_papers(c.id, nina, "guarantee")
				return ""
			return "Ms Castell registers bidders here. She'll want a letter of guarantee from your bank."
		"safe_keypad":
			return "The captain's strongroom. Nothing in it for you tonight."
	return null


func prompt_for(c: CrewInfo, what: String) -> Variant:
	match what:
		"rostrum", "character:rupert":
			if _paddle(c) != "":
				return "Raise your paddle"
			return "" if what == "rostrum" else null
		"paddle":
			return "Register to bid" if "guarantee" in c.items and _paddle(c) == "" else ""
		"safe_keypad":
			return ""
	return null


func on_action(job: Job, ch: Character, c: CrewInfo, act: String) -> bool:
	match act:
		"take_bid":
			var said := str(_crew_bid(job, c))
			if said != "":
				job.toast_for.emit(c.id, said)
			return true
		"register":
			if job.flags.has("sale"):
				ch.say_scripted("I'm sorry, registration closed at eight.")
				return true
			if _paddle(c) != "":
				return true
			for p in PADDLES:
				if job.holder(p) == null and not job.flags.has("given:" + p):
					job.flags["given:" + p] = true
					c.flags["paddle"] = p
					job.give_item(c.id, p)
					ch.say_scripted("You're paddle %s. The sale's at eight, in the saloon. Good luck." % PADDLES[p])
					ch.note("You registered %s to bid: paddle %s." % [job.describe(c.id), PADDLES[p]])
					job.toast_for.emit(c.id, "Ms Castell registers you: paddle %s." % _paddle_number(p))
					return true
			ch.say_scripted("I'm sorry, I'm out of paddles.")
			return true
		"note_guarantee":
			var rang: Dictionary = job.calls.get(c.id, {})
			if str(rang.get("who", "")) != "nina":
				ch.say_scripted("The bank will need to ring me itself, I'm afraid.")
				return true
			if str(rang.get("as", "")) != BANK:
				ch.say_scripted("I'll ring the bank back on its own number, thank you.")
				JobRules.nudge(ch.face_of(c.id), 1)
				return true
			_bank_ok(job, ch)
			job.toast_for.emit(c.id, "Ms Castell has noted Caldera Mutual's guarantee. Bids over two million will stand.")
			return true
		"withdraw":
			_margit_out(job, c.id)
			return true
		"spread_word":
			job.flags["rumor"] = c.id
			ch.note("%s told you there's doubt about the Rose's certificate. You're off to tell Margit." % job.describe(c.id).capitalize())
			ch.walk_to("pieter_margit")
			job.toast_for.emit(c.id, "Mr Achterberg is off to tell Mrs Lindqvist.")
			return true
		"bid_for":
			job.flags["proxy"] = c.id
			ch.note("You've agreed to bid for %s's client tonight, for three percent, as high as three million." % job.describe(c.id))
			var rupert: Character = job.cast.get("rupert")
			if rupert:
				rupert.note("Hugo Marlowe has told you he's bidding tonight, for a client.")
			job.toast_for.emit(c.id, "Hugo Marlowe will bid for your client, as high as three million. Mr Ashcombe takes his word.")
			return true
	return false


func lookup(job: Job, who: String, crew_id: int, said: String, _asker: Character) -> Dictionary:
	var c := job.crew_by_id(crew_id)
	if c == null:
		return {}
	match who:
		"nina":
			if _paddle(c) != "":
				var n: String = PADDLES[_paddle(c)]
				return Job.fact("good", "You registered them yourself tonight: paddle %s." % n, "Yes, paddle %s. I registered them myself." % n)
			if int(job.flags.get("proxy", 0)) == crew_id and Job.any(said, ["hugo", "marlowe", "client", "agent"]):
				return Job.fact("good", "Mr Marlowe is bidding for a client tonight, and their agent is aboard. Mr Ashcombe takes Mr Marlowe's word.", "They're with Mr Marlowe. That's Mr Ashcombe's business. Fine.")
			if c.cover == "bidder" and not job.flags.has("sale") and Job.any(said, ["register", "bid", "paddle", "collector"]):
				return Job.fact("good", "Bidders register at your desk until eight.", "Send them to my desk. I'll register them.")
			return Job.fact("bad", "They haven't registered with you.", "Not one of mine.")
		"kofi":
			if c.cover == "stew" and Job.any(said, ["stew", "bianca", "drinks", "serving", "crew"]):
				return Job.fact("good", "Bianca took on a temp stew for the sale tonight.", "Bianca's temp. She's serving in the saloon tonight.")
			return Job.fact("bad", "They're not crew.", "Not one of ours.")
	return {}


func on_mae(job: Job, call_id: String, ch: Character) -> void:
	match call_id:
		"bank":
			_bank_ok(job, ch)
		"client":
			job.flags["client_rang"] = true
			ch.note("A client who can't be seen bidding rang you: their agent is aboard tonight and will tell you the rest. Three percent.")
			for c in job.crew:
				JobRules.nudge(ch.face_of(c.id), -1)


func on_event(job: Job, event_name: String) -> void:
	var rupert: Character = job.cast.get("rupert")
	match event_name:
		"seats":
			job.toast_for.emit(0, "Five minutes to the sale. Registration closes at eight.")
			for ch in job.cast.values():
				ch.note("The sale starts in five minutes, in the saloon.")
		"sale":
			job.flags["sale"] = true
			job.flags["quiet"] = 0
			if rupert:
				rupert.say_scripted("Ladies and gentlemen, Lot 1: the Rose of Caldera. Eleven carats, every cent to the museum. Who'll start me at %s?" % money(OPENING))
			for ch in job.cast.values():
				ch.note("The sale has started: Lot 1, the Rose. Registration is closed.")
			job.toast_for.emit(0, "The sale has started.")
		"bid":
			_round(job)


## One round of the sale: the next bidder who can goes a step higher, or
## nobody does and the hammer comes a step nearer.
func _round(job: Job) -> void:
	if not job.flags.has("sale") or job.flags.has("sold") or job.heat.level >= Heat.LOCKDOWN:
		return
	var rupert: Character = job.cast.get("rupert")
	var next := _next(job)
	var who := _bidder(job, next)
	if who != "":
		_bid(job, who, next)
		return
	var quiet := int(job.flags.get("quiet", 0)) + 1
	job.flags["quiet"] = quiet
	var price := int(job.flags.get("price", 0))
	match quiet:
		1:
			if rupert:
				rupert.say_scripted("At %s. Any advance?" % money(price) if price > 0 else "Come now. Who'll start me?")
		2:
			if rupert:
				rupert.say_scripted("Going once. Going twice.")
		_:
			_hammer(job)


## The next bid the room can make.
func _next(job: Job) -> int:
	return int(job.flags.price) + STEP if str(job.flags.get("high", "")) != "" else OPENING


## Who bids next at `next`: Hugo for his client, Margit, then Pieter, but
## never against themselves (and Hugo never against the crew).
func _bidder(job: Job, next: int) -> String:
	var high := str(job.flags.get("high", ""))
	if job.flags.has("proxy") and high != "hugo" and not high.begins_with("crew:") and next <= PROXY_LIMIT:
		return "hugo"
	if not job.flags.has("margit_out") and high != "margit" and next <= MARGIT_LIMIT:
		return "margit"
	if high != "pieter" and next <= PIETER_LIMIT:
		return "pieter"
	return ""


func _bid(job: Job, who: String, amount: int) -> void:
	job.flags["price"] = amount
	job.flags["high"] = who
	job.flags["quiet"] = 0
	var said := money(amount)
	var line := ""
	match who:
		"pieter":
			line = "%s, Mr Achterberg." % said
		"margit":
			line = "%s, with Mrs Lindqvist." % said
		"hugo":
			line = "%s, Mr Marlowe, for his client." % said
		_:
			var c := job.crew_by_id(int(who.trim_prefix("crew:")))
			line = "%s, paddle %s!" % [said, PADDLES.get(_paddle(c), "")] if c else said
	var rupert: Character = job.cast.get("rupert")
	if rupert:
		rupert.say_scripted(line.left(1).to_upper() + line.substr(1))


## A crew member bids through Mr Ashcombe: a registered paddle, and over two
## million only with the bank's word. Returns what to tell them.
func _crew_bid(job: Job, c: CrewInfo) -> String:
	var rupert: Character = job.cast.get("rupert")
	if rupert == null or job.done:
		return ""
	if job.flags.has("sold"):
		return "The hammer's down."
	if not job.flags.has("sale"):
		rupert.say_scripted("Patience! We start at eight.")
		return ""
	if job.heat.level >= Heat.LOCKDOWN:
		rupert.say_scripted("A moment, ladies and gentlemen, please.")
		return ""
	var paddle := _paddle(c)
	if paddle == "":
		rupert.say_scripted("I'm sorry, I can only take registered paddles.")
		return ""
	var me := "crew:%d" % c.id
	if str(job.flags.get("high", "")) == me:
		rupert.say_scripted("It's with you already, paddle %s." % PADDLES[paddle])
		return ""
	var next := _next(job)
	if next > MarlinCast.CHECK_ABOVE:
		var nina: Character = job.cast.get("nina")
		if not job.flags.has("bank_ok"):
			if nina:
				nina.say_scripted("Mr Ashcombe, I can't get paddle %s's bank to confirm." % PADDLES[paddle])
			rupert.say_scripted("Then I'm afraid I can't take it, paddle %s." % PADDLES[paddle])
			for ch in [rupert, nina]:
				if ch:
					JobRules.nudge(ch.face_of(c.id), 1)
					ch.note("Paddle %s, %s, bid over two million and their bank couldn't confirm it." % [PADDLES[paddle], job.describe(c.id)])
					job.faced.emit(c.id, ch.sheet.id, ch.suspicion_of(c.id))
			return "Your bid wasn't taken: the bank didn't confirm."
		if nina and not job.flags.has("bank_said"):
			job.flags["bank_said"] = true
			nina.say_scripted("Mr Ashcombe, Caldera Mutual confirmed paddle %s this evening." % PADDLES[paddle])
	_bid(job, me, next)
	return ""


## The hammer falls on whoever has it.
func _hammer(job: Job) -> void:
	job.flags["sold"] = true
	var high := str(job.flags.get("high", ""))
	var price := int(job.flags.get("price", 0))
	var result := "sold"
	var line := ""
	if high == "" or price < MarlinCast.RESERVE:
		result = "passed"
		line = "I'm afraid I can't sell her at that. The Rose is not sold tonight."
	elif high.begins_with("crew:"):
		var c := job.crew_by_id(int(high.trim_prefix("crew:")))
		if c and not c.held:
			result = "won"
			line = "Sold! To paddle %s, for %s." % [PADDLES.get(_paddle(c), ""), money(price)]
		else:
			result = "passed"
			line = "Our paddle seems to have left us. The Rose is not sold tonight."
	elif high == "hugo":
		result = "proxy"
		line = "Sold! To Mr Marlowe, for his client, for %s." % money(price)
	else:
		line = "Sold! To %s, for %s." % ["Mrs Lindqvist" if high == "margit" else "Mr Achterberg", money(price)]
	job.flags["result"] = result
	job.flags["end_at"] = job.elapsed + HAMMER_WAIT
	var rupert: Character = job.cast.get("rupert")
	if rupert:
		rupert.say_scripted(line)


func _bank_ok(job: Job, nina: Character) -> void:
	job.flags["bank_ok"] = true
	nina.note("Caldera Mutual rang to confirm their client's letter of guarantee, to three million. You've noted it: their bids over two million stand.")


## Margit is out of the bidding (her last bid, if she has it, stands).
func _margit_out(job: Job, crew_id: int) -> void:
	if job.flags.has("margit_out"):
		return
	job.flags["margit_out"] = true
	var margit: Character = job.cast.get("margit")
	if margit:
		margit.note("You've heard the Rose's certificate may be a copy. You won't bid on her.")
		if not job.flags.has("sold"):
			margit.walk_to("aft_port")
	if crew_id != 0:
		job.toast_for.emit(crew_id, "Mrs Lindqvist won't bid on the Rose now.")


func tick(job: Job, _delta: float) -> void:
	# Pieter gets to Margit with the gossip.
	if job.flags.has("rumor") and not job.flags.has("rumor_told") and _at(job, "pieter", ["pieter_margit"]):
		job.flags["rumor_told"] = true
		var pieter: Character = job.cast.get("pieter")
		var margit: Character = job.cast.get("margit")
		pieter.say_scripted("Margit, darling. They're saying the Rose's certificate is a copy.")
		if margit and not job.flags.has("margit_out"):
			margit.say_scripted("What? Then I'm not bidding on her. Enjoy her, Pieter.")
		_margit_out(job, int(job.flags.rumor))
		pieter.walk_to("pieter")


## Whether a character stands at one of these spots, done walking.
func _at(job: Job, char_id: String, spots: Array) -> bool:
	var ch: Character = job.cast.get(char_id)
	return ch != null and not ch.walking and ch.post in spots and ch.global_position.distance_to(job.spot(ch.post).origin) < 0.3


## The paddle a crew member holds ("" for none).
func _paddle(c: CrewInfo) -> String:
	if c == null:
		return ""
	for p in PADDLES:
		if p in c.items:
			return p
	return ""


static func _paddle_number(p: String) -> String:
	return "41" if p == "paddle_1" else "42"


func check_end(job: Job) -> String:
	if job.flags.has("result") and job.elapsed >= float(job.flags.end_at):
		return str(job.flags.result)
	return ""


func at_end(job: Job) -> String:
	return str(job.flags.get("result", "unsold"))


func report(job: Job, outcome: String, r: Dictionary) -> void:
	var price := int(job.flags.get("price", 0))
	if price > 0 and outcome in ["won", "proxy", "sold"]:
		r["text"] = "%s The hammer price: %s." % [str(r.text), dollars(price)]


## A sum as Mr Ashcombe says it: "two million five hundred thousand".
static func money(n: int) -> String:
	var parts: Array[String] = []
	if n >= 1000000:
		parts.append("%s million" % _words(n / 1000000))
	if (n % 1000000) / 1000 > 0:
		parts.append("%s thousand" % _words((n % 1000000) / 1000))
	return " ".join(parts)


## A sum as the report writes it: "$2,500,000".
static func dollars(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return "$" + s + out


static func _words(n: int) -> String:
	const ONES := ["", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
		"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
	const TENS := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
	var parts: Array[String] = []
	if n >= 100:
		parts.append("%s hundred" % ONES[n / 100])
		n %= 100
	if n >= 20:
		parts.append(TENS[n / 10] + ("-" + ONES[n % 10] if n % 10 > 0 else ""))
	elif n > 0:
		parts.append(ONES[n])
	return " ".join(parts)
