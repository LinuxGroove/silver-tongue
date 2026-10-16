class_name Jobs
extends RefCounted
## Every job in the campaign, in order: three at each venue, then Mae's
## house party. A job is a script extending [JobDef] at its path; jobs not
## built yet are left out of [method available].

## The job being played (or last set up): what [Covers] answers for.
static var current: JobDef

const CAMPAIGN := [
	"meridian_gala", "meridian_list", "meridian_case",
	"marlin_aboard", "marlin_safe", "marlin_auction",
	"tideline_count", "tideline_favor", "tideline_vault",
	"vantage_lift", "vantage_board", "vantage_research",
	"mae_party",
]
const PATHS := {
	"meridian_gala": "res://game/venues/meridian/gala_job.gd",
	"meridian_list": "res://game/venues/meridian/list_job.gd",
	"meridian_case": "res://game/venues/meridian/case_job.gd",
	"marlin_aboard": "res://game/venues/marlin/aboard_job.gd",
	"marlin_safe": "res://game/venues/marlin/safe_job.gd",
	"marlin_auction": "res://game/venues/marlin/auction_job.gd",
	"tideline_count": "res://game/venues/tideline/count_job.gd",
	"tideline_favor": "res://game/venues/tideline/favor_job.gd",
	"tideline_vault": "res://game/venues/tideline/vault_job.gd",
	"vantage_lift": "res://game/venues/vantage/lift_job.gd",
	"vantage_board": "res://game/venues/vantage/board_job.gd",
	"vantage_research": "res://game/venues/vantage/research_job.gd",
	"mae_party": "res://game/venues/mae/party_job.gd",
}
## The venues in campaign order, with their names.
const VENUES := {
	"meridian": "The Hotel Meridian",
	"marlin": "The Marlin",
	"tideline": "The Tideline",
	"vantage": "Vantage Tower",
	"mae": "Mae's house",
}


static func exists(job_id: String) -> bool:
	return PATHS.has(job_id) and ResourceLoader.exists(PATHS[job_id])


## A fresh copy of a job (null for one that isn't built).
static func make(job_id: String) -> JobDef:
	if not exists(job_id):
		return null
	var script: Script = load(PATHS[job_id])
	return script.new() as JobDef


## The jobs built so far, in campaign order.
static func available() -> Array:
	return CAMPAIGN.filter(func(j): return exists(j))


## A venue's jobs, in order.
static func at_venue(venue_id: String) -> Array:
	return CAMPAIGN.filter(func(j): return str(j).begins_with(venue_id + "_"))
