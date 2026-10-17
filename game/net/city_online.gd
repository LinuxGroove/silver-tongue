class_name CityOnline
extends RefCounted
## What Silver Tongue asks of the game server, apart from the crew's room
## (see [Session]): the crew record and what the characters remember, the
## weekly contract's board, new faces, and reports shared by code. Every call
## signs in on its own when online play is on, and quietly does nothing
## (returns null or false) when it isn't or the server can't be reached, so
## nothing here ever stands between a player and a job.

## The boards the Leaderboards page shows: [board, title].
const BOARDS := [
	["contract_weekly", "This week's contract"],
	["take", "The biggest take"],
	["jobs_weekly", "Jobs this week"],
	["jobs", "Jobs, all time"],
	["clean_jobs", "Clean jobs"],
]
## The share kind for job reports.
const REPORT := "report"


static func enabled() -> bool:
	return LGOnline.is_enabled()


static func _sign_in() -> bool:
	return enabled() and await LGOnline.connect_async(GameConfig.player_name(), GameConfig.GAME_ID)


static func _rpc(name: String, payload := {}) -> Variant:
	if not await _sign_in():
		return null
	return await LGOnline.rpc_async("%s.%s" % [GameConfig.GAME_ID, name], payload)


## Fetches this account's crew record from the server into [Progress].
## Returns whether it came.
static func pull() -> bool:
	var doc: Variant = await _rpc("memory")
	if typeof(doc) != TYPE_DICTIONARY:
		return false
	Progress.merge_server(doc)
	return true


## Tells the server a new face was bought (the local record is already
## updated; the server's take and burned flag follow).
static func buy_face() -> bool:
	var res: Variant = await _rpc("buy_face")
	return typeof(res) == TYPE_DICTIONARY


## Puts a take on the weekly contract's board when the report is this week's
## contract, won. Works for solo play too. Returns whether it was sent.
static func submit_contract(r: Dictionary) -> bool:
	if not is_contract(r):
		return false
	if not await _sign_in():
		return false
	var res: Variant = await LGOnline.rpc_async("core.score_submit", {
		"board": "contract_weekly",
		"score": int(r.take),
		"metadata": {"seed": int(r.circuit), "job": str(r.job)},
	})
	return res != null


## Whether a report is a won go at this week's contract.
static func is_contract(r: Dictionary) -> bool:
	return bool(r.get("win", false)) and int(r.get("take", 0)) > 0 and int(r.get("circuit", 0)) == Circuit.week()


## Shares a report as text; returns its code ("" when it couldn't).
static func share_report(r: Dictionary) -> String:
	if not await _sign_in():
		return ""
	var res: Variant = await LGOnline.rpc_async("core.share_create", {
		"kind": REPORT,
		"title": "%s, %s" % [r.get("job_title", "A job"), str(r.get("title", "")).capitalize()],
		"data": {"text": JobReportCard.as_text(r)},
		"meta": {"job": str(r.get("job", "")), "outcome": str(r.get("outcome", "")), "take": int(r.get("take", 0))},
	})
	return str(res.get("code", "")) if typeof(res) == TYPE_DICTIONARY else ""


## A shared report's {"title", "text"} by code ({} when there's none).
static func read_report(code: String) -> Dictionary:
	if not await _sign_in():
		return {}
	var res: Variant = await LGOnline.rpc_async("core.share_get", {"code": LGOnline.normalize_code(code)})
	if typeof(res) != TYPE_DICTIONARY or str(res.get("kind", "")) != REPORT:
		return {}
	var data: Variant = res.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return {"title": str(res.get("title", "")), "text": str(data.get("text", ""))}


## The line under the Leaderboards: this account's online record.
static func record_text(stats: Dictionary) -> String:
	var jobs := int(stats.get("jobs", 0))
	if jobs == 0:
		return "No online jobs yet. Pull one off with a crew to start your record."
	var parts := ["%d %s" % [jobs, "job" if jobs == 1 else "jobs"]]
	var clean := int(stats.get("clean", 0))
	if clean > 0:
		parts.append("%d clean" % clean)
	var take := int(stats.get("take", 0))
	if take > 0:
		parts.append("%s taken" % JobReportCard.money(take))
	return ", ".join(parts) + "."
