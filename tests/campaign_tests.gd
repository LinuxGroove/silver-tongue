extends RefCounted
## The season around the jobs: Progress (the take, what's open, Halberd's
## file, memories), Mae's board and a job's page on the title, the report
## card's picture and text, minding your language, the phone, suggested
## lines, and the view over your shoulder.
##   godot --headless --path . tests/run_tests.tscn -- --only=campaign


func _win(job_id: String, extra := {}) -> Dictionary:
	var r := {"job": job_id, "venue": job_id.get_slice("_", 0), "outcome": "in", "win": true, "take": 2000, "clean": true,
		"quiet": false, "silver": true, "crew": [{"id": 1, "was_held": false}], "memories": {}}
	r.merge(extra, true)
	return r


func test_progress(t) -> void:
	Progress.reset()
	LGSettings.set_value("play", "all_jobs", false)
	t.check(Progress.is_open("meridian_gala") and not Progress.is_open("meridian_list"), "the season starts with the gala open, and only the gala")
	t.check(Progress.next_job() == "meridian_gala", "the gala is next")
	Progress.record(_win("meridian_gala"), 1)
	t.check(Progress.is_done("meridian_gala") and Progress.take == 2000, "a job that came off is done, and its take kept")
	t.check(Progress.is_open("meridian_list"), "and the next one opens")
	Progress.record(_win("meridian_gala", {"clean": false, "quiet": true, "take": 2000}), 1)
	var d: Dictionary = Progress.done.meridian_gala
	t.check(d.clean and d.quiet and d.silver and Progress.take == 4000, "playing it again keeps every score it ever got, and adds the take")
	t.check(int(Progress.tries.meridian_gala) == 2, "and counts the tries")
	Progress.record({"job": "meridian_list", "venue": "meridian", "outcome": "held", "win": false, "take": 4000,
		"crew": [{"id": 1, "was_held": true}, {"id": 2, "was_held": false}], "memories": {"dana": ["At the guest list, a man gave you a bad feeling."]}}, 1)
	t.check(not Progress.is_done("meridian_list") and Progress.take == 4000, "a job that went wrong pays nothing")
	t.check(Progress.burned, "and being held puts your face in Halberd's file")
	t.check(Progress.memories_for("meridian").dana.size() == 1, "the people there remember you")
	var both := Progress.memories_of(["meridian", "marlin"])
	t.check(both.has("dana"), "memories from several venues come together")
	t.check(not Progress.buy_face() and Progress.burned, "a new face costs more than the take")
	Progress.take = Progress.NEW_FACE + 500
	t.check(Progress.buy_face() and not Progress.burned and Progress.take == 500 and Progress.faces == 1, "and buys you out of Halberd's file when you can pay")
	t.check(not Progress.buy_face(), "a face that isn't burned needn't be bought")
	LGSettings.set_value("play", "all_jobs", true)
	t.check(Progress.is_open("mae_party"), "with every job open, the finale is too")
	LGSettings.set_value("play", "all_jobs", false)
	Progress.record(_win("meridian_gala", {"circuit": 1234, "take": 9000}), 1)
	t.check(Progress.take == 9500 and Progress.circuit.has("1234"), "a Circuit night keeps its best under its seed")
	Progress.load_from(Progress._file)
	t.check(Progress.take == 9500 and Progress.is_done("meridian_gala") and Progress.faces == 1, "the season is saved and comes back")
	Progress.reset()


func test_board(t) -> void:
	Progress.reset()
	LGSettings.set_value("play", "all_jobs", false)
	var title: Node = load("res://game/ui/title.tscn").instantiate()
	t.add_child(title)
	await t.frames(3)
	title.show_board()
	await t.frames(1)
	var texts: PackedStringArray = title.button_texts()
	t.check("The gala" in texts and "Back" in texts, "Mae's board lists the gala (%s)" % ", ".join(texts))
	t.check(not texts.has("Buy a new face ($6,000)"), "nobody offers a new face before Halberd has yours")
	title.show_job("meridian_gala")
	await t.frames(1)
	texts = title.button_texts()
	for b in ["Play alone", "Host a crew on this network", "Join a crew", "Back"]:
		t.check(b in texts, "a job's page has " + b)
	var briefing := false
	for l in title.find_children("", "Label", true, false):
		briefing = briefing or (l as Label).text.begins_with("Auntie Mae: \"")
	t.check(briefing, "and Mae's briefing")
	Progress.record(_win("meridian_gala"), 1)
	Progress.burned = true
	title.show_board()
	await t.frames(1)
	texts = title.button_texts()
	t.check("The gala: done, Clean, Silver" in texts, "a job that came off says how (%s)" % ", ".join(texts))
	var face: Button = null
	for b in title.find_children("", "Button", true, false):
		if b.text == "Buy a new face ($6,000)":
			face = b
	t.check(face != null and face.disabled, "a burned face can be bought out, once the take covers it")
	Progress.take = 7000
	title.show_board()
	await t.frames(1)
	title._buy_face()
	await t.frames(1)
	t.check(not Progress.burned and Progress.take == 1000, "buying one spends the take")
	title.queue_free()
	await t.frames(1)
	Progress.reset()


func test_report_card(t) -> void:
	var r := {"job": "meridian_gala", "job_title": "The gala", "venue_name": "The Hotel Meridian", "outcome": "in", "win": true,
		"title": "YOU'RE IN", "text": "Inside the ballroom at %s.", "clock": "9:12 pm", "take": 2000, "clean": true, "quiet": false, "silver": true,
		"crew": [{"name": "Ruby", "cover_name": "Vivian Hart", "inside": true}],
		"best": {"said": "Felix Halvorsen, damn it.", "reply": "Of course, sir.", "name": "Teo", "char": "teo", "clock": "9:01 pm"}}
	var text := JobReportCard.as_text(r)
	t.check(text.begins_with("Silver Tongue: The gala, The Hotel Meridian"), "the text says which job: %s" % text)
	t.check(text.contains("You're in. Inside the ballroom at 9:12 pm.") and text.contains("The take: $2,000"), "how it went, and the take")
	t.check(text.contains("Clean: yes, Quiet: no, Silver: yes") and text.contains("Teo: \"Of course, sir.\""), "the scores and the best line")
	LGSettings.set_value("voice", "mind_language", true)
	t.check(JobReportCard.as_text(r).contains("darn it"), "minding your language, the text is clean too")
	LGSettings.set_value("voice", "mind_language", false)
	var layer := CanvasLayer.new()
	t.add_child(layer)
	var card := JobReportCard.new()
	layer.add_child(card)
	card.show_report(r)
	await t.frames(2)
	for b in ["Again", "Back to Mae's", "Save a picture", "Copy the text"]:
		t.check(b in card.button_texts(), "the card has " + b)
	var path: String = await card.save_picture()
	t.check(path == "" or FileAccess.file_exists(path), "a picture is saved when there's a screen to take it from (%s)" % path)
	layer.queue_free()
	await t.frames(1)


func test_language(t) -> void:
	t.check(Language.clean("What the hell is this shit?", true) == "What the heck is this shoot?", "swearing comes out clean: %s" % Language.clean("What the hell is this shit?", true))
	t.check(Language.clean("Hello, class. Shell out.", true) == "Hello, class. Shell out.", "words that only look like swearing stay")
	t.check(Language.clean("DAMN. Bloody Hell.", true) == "DARN. Blooming Heck.", "capitals are kept: %s" % Language.clean("DAMN. Bloody Hell.", true))
	t.check(Language.clean("you shithead", true) == "you shoothead", "inside a longer word too")
	LGSettings.set_value("voice", "mind_language", false)
	t.check(Language.clean("hell") == "hell", "with the setting off, words are left alone")


func test_phone_panel(t) -> void:
	var def := MeridianGalaJob.new()
	var layer := CanvasLayer.new()
	t.add_child(layer)
	var phone := PhonePanel.new()
	layer.add_child(phone)
	await t.frames(1)
	var rang := []
	phone.dialed.connect(func(n, as_who): rang.append([n, as_who]))
	phone.ask(def, "", def.mae_calls, true)
	var texts := phone.button_texts()
	t.check("Caller ID: Withheld" in texts and "Ring Meridian reception" in texts and "Put it away" in texts, "the phone lists the numbers (%s)" % ", ".join(texts))
	t.check("Book the freezer repair" in texts, "and, alone, Mae's calls")
	phone.press("Caller ID: Withheld")
	t.check("Caller ID: Caldera Museum" in phone.button_texts(), "the caller ID can say someone else")
	phone.press("Ring Meridian reception")
	t.check(rang == [["reception", "Caldera Museum"]] and not phone.is_open(), "ringing goes out as them, and puts the phone away")
	phone.ask(def, "", def.mae_calls, false)
	t.check(not "Book the freezer repair" in phone.button_texts(), "with a crew, Mae leaves the calls to you")
	phone.ask(def, "dana", [], true)
	t.check("Hang up" in phone.button_texts(), "on a call, the phone hangs up")
	phone.close()
	layer.queue_free()
	await t.frames(1)


func test_suggested_lines(t) -> void:
	var layer := CanvasLayer.new()
	t.add_child(layer)
	var line := TextLinePanel.new()
	layer.add_child(line)
	await t.frames(1)
	var said := []
	line.submitted.connect(func(x): said.append(x))
	line.ask(PackedStringArray(["Good evening.", "Here's my invitation."]))
	t.check(line.idea_texts() == PackedStringArray(["Good evening.", "Here's my invitation."]), "text mode offers your cover's lines")
	for b in line.find_children("", "Button", true, false):
		if b.text == "Here's my invitation.":
			b.pressed.emit()
	t.check(said == ["Here's my invitation."] and not line.is_open(), "and picking one says it")
	layer.queue_free()
	await t.frames(1)


func test_over_the_shoulder(t) -> void:
	LGSettings.set_value("ai", "mode", "off")
	LGSettings.set_value("voice", "talk", "text")
	LGSettings.set_value("play", "view", "third")
	JobScene.setup = JobScene.solo("press", false, "Tester")
	var s: JobScene = load(JobScene.SCENE).instantiate()
	t.add_child(s)
	await t.frames(5)
	var p: CrewMember = s.player
	t.check(p.third_person and p.person != null and p.person.visible, "over your shoulder, you see yourself")
	var cam := s.get_viewport().get_camera_3d()
	t.check(cam != null and cam.name == "ShoulderCamera", "through the shoulder camera")
	await t.frames(10)
	var behind := cam.global_position - p.camera.global_position
	t.check(behind.dot(p.camera.global_transform.basis.z) > 0.2, "which sits behind you (%s)" % behind)
	t.check(p.mouth_position().distance_to(p.camera.global_position) < 0.01, "and you still speak from your own mouth")
	LGSettings.set_value("play", "view", "first")
	p._reload_options()
	t.check(not p.third_person and not p.person.visible and s.get_viewport().get_camera_3d() == p.camera, "back through your eyes")
	s.queue_free()
	await t.frames(2)
	JobScene.setup = {}


func test_setup_words(t) -> void:
	var was := SetupScreen.target
	Jobs.current = MeridianGalaJob.new()
	SetupScreen.target = "job"
	var screen := SetupScreen.new()
	t.check(screen._text("title") == "Getting the Hotel Meridian ready", "the setup screen names the job's venue (%s)" % screen._text("title"))
	t.check(str(screen._text("no_brain")).begins_with("The Hotel Meridian needs Lemonade"), "and says what needs Lemonade")
	screen.free()
	SetupScreen.target = was
