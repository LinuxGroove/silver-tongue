extends Node
## The crew's season (autoload: Progress), kept on this device in
## user://progress.cfg: the jobs pulled off and how, the take, whether
## Halberd has this face on file, what the people at each venue remember
## of the crew, and the Circuit's best nights. Every device keeps its own;
## the host's memories are the ones the characters use.

const PATH := "user://progress.cfg"
## What a new face costs, in dollars.
const NEW_FACE := 6000
## Memories kept per character: the newest.
const MEMORIES := 4

## Job id -> {"outcome", "clean", "quiet", "silver", "take", "when"}: the
## best go at each job that came off.
var done := {}
## Job id -> how many times it was tried.
var tries := {}
var take := 0
## Held at a job this season: Halberd has this face on file.
var burned := false
## New faces bought.
var faces := 0
## Venue id -> character id -> lines they remember about the crew.
var memories := {}
## Circuit seed -> the best go: {"outcome", "take", "when"}.
var circuit := {}
var _file := PATH


func _ready() -> void:
	load_from(PATH)


## Reads the season (tests point it at their own file).
func load_from(path: String) -> void:
	_file = path
	_clear()
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	done = cfg.get_value("season", "done", {})
	tries = cfg.get_value("season", "tries", {})
	take = int(cfg.get_value("season", "take", 0))
	burned = bool(cfg.get_value("season", "burned", false))
	faces = int(cfg.get_value("season", "faces", 0))
	memories = cfg.get_value("season", "memories", {})
	circuit = cfg.get_value("circuit", "best", {})


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("season", "done", done)
	cfg.set_value("season", "tries", tries)
	cfg.set_value("season", "take", take)
	cfg.set_value("season", "burned", burned)
	cfg.set_value("season", "faces", faces)
	cfg.set_value("season", "memories", memories)
	cfg.set_value("circuit", "best", circuit)
	cfg.save(_file)


## Starts the season again.
func reset() -> void:
	_clear()
	save()


func _clear() -> void:
	done = {}
	tries = {}
	take = 0
	burned = false
	faces = 0
	memories = {}
	circuit = {}


func is_done(job_id: String) -> bool:
	return done.has(job_id)


## A job is open when the one before it in the campaign came off (or every
## job is, with the setting on).
func is_open(job_id: String) -> bool:
	if bool(LGSettings.get_value("play", "all_jobs", false)):
		return true
	var i := Jobs.CAMPAIGN.find(job_id)
	if i <= 0:
		return i == 0
	return is_done(str(Jobs.CAMPAIGN[i - 1]))


## The Circuit opens once Mae's party has come off (or with every job open).
func circuit_open() -> bool:
	return is_done("mae_party") or bool(LGSettings.get_value("play", "all_jobs", false))


## The best go at a Circuit night ({} if none came off).
func circuit_best(seed: int) -> Dictionary:
	return circuit.get(str(seed), {})


## The next job to play: the first open one not done.
func next_job() -> String:
	for j in Jobs.available():
		if is_open(j) and not is_done(j):
			return j
	var all := Jobs.available()
	return str(all[0]) if not all.is_empty() else "meridian_gala"


## Keeps a job's report for this device's crew member `me` (see
## [method Job.report]): the take when it came off, a burned face when they
## were held, and what the characters will remember. A Circuit night keeps
## its best under its seed instead.
func record(r: Dictionary, me: int) -> void:
	var job_id := str(r.get("job", ""))
	if job_id == "":
		return
	var circuit_seed := int(r.get("circuit", 0))
	tries[job_id] = int(tries.get(job_id, 0)) + 1
	var won := bool(r.get("win", false))
	var got := int(r.get("take", 0)) if won else 0
	take += got
	for c in r.get("crew", []):
		if int(c.get("id", 0)) == me and bool(c.get("was_held", false)):
			burned = true
	var entry := {"outcome": str(r.get("outcome", "")), "clean": bool(r.get("clean", false)), "quiet": bool(r.get("quiet", false)),
		"silver": bool(r.get("silver", false)), "take": got, "when": Time.get_date_string_from_system()}
	if circuit_seed != 0:
		var key := str(circuit_seed)
		if won and int(circuit.get(key, {}).get("take", -1)) < got:
			circuit[key] = entry
	elif won:
		var was: Dictionary = done.get(job_id, {})
		for k in ["clean", "quiet", "silver"]:
			entry[k] = entry[k] or bool(was.get(k, false))
		done[job_id] = entry
	var venue := str(r.get("venue", ""))
	if venue != "" and circuit_seed == 0:
		var v: Dictionary = memories.get(venue, {})
		var said: Dictionary = r.get("memories", {})
		for ch in said:
			var lines: Array = v.get(ch, [])
			for l in said[ch]:
				lines.append(str(l))
			v[ch] = lines.slice(maxi(0, lines.size() - MEMORIES))
		memories[venue] = v
	save()


## What the people at a venue remember of the crew: character id -> lines.
func memories_for(venue_id: String) -> Dictionary:
	return memories.get(venue_id, {})


## What the people of several venues remember, together.
func memories_of(venues: Array) -> Dictionary:
	var out := {}
	for v in venues:
		var m: Dictionary = memories.get(str(v), {})
		for ch in m:
			var lines: Array = out.get(ch, [])
			lines.append_array(m[ch])
			out[ch] = lines
	return out


## Buys a new face, so Halberd's photo is of someone else. False when the
## take won't cover it or the face isn't burned.
func buy_face() -> bool:
	if not burned or take < NEW_FACE:
		return false
	take -= NEW_FACE
	burned = false
	faces += 1
	save()
	return true


## Folds in the crew record the game server keeps for this account (see
## [CityOnline.pull]): a burned face and the faces bought, the biggest take,
## the jobs done, and what the characters remember. Nothing local is lost:
## memories keep the newest lines of both, and the rest take the larger.
func merge_server(doc: Dictionary) -> void:
	if doc.is_empty():
		return
	burned = burned or (bool(doc.get("burned", false)) and int(doc.get("faces", 0)) >= faces)
	faces = maxi(faces, int(doc.get("faces", 0)))
	take = maxi(take, int(doc.get("take", 0)))
	var theirs: Variant = doc.get("done", {})
	if typeof(theirs) == TYPE_DICTIONARY:
		for j in theirs:
			if Jobs.exists(str(j)) and not done.has(j):
				done[j] = theirs[j] if typeof(theirs[j]) == TYPE_DICTIONARY else {"outcome": "won", "take": 0}
	var mem: Variant = doc.get("memories", {})
	if typeof(mem) == TYPE_DICTIONARY:
		for venue in mem:
			if typeof(mem[venue]) != TYPE_DICTIONARY:
				continue
			var v: Dictionary = memories.get(venue, {})
			for ch in mem[venue]:
				var lines: Array = v.get(ch, [])
				for l in mem[venue][ch]:
					if not str(l) in lines:
						lines.append(str(l))
				v[ch] = lines.slice(maxi(0, lines.size() - MEMORIES))
			memories[venue] = v
	save()
