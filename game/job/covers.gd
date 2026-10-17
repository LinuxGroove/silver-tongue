class_name Covers
extends RefCounted
## The crew's covers: a name, a job, a reason to be there and the clothes
## that go with it. What characters see is the outfit; what they're told is
## up to you. Each job has its own ([member JobDef.covers]); the functions
## here answer for the job being played ([member Jobs.current]), and the
## constants are the gala's and the outfits every job can use.

const ALL := {
	"facilities": {
		"title": "Facilities",
		"names": ["Dave Russo", "Dee Russo"],
		"job": "a facilities engineer from Caldera Building Services",
		"story": "Reception has asked twice this week for someone to fix the kitchen's walk-in freezer. Tonight, you're someone.",
		"outfit": "facilities",
		"for": "Marcus, on the service door",
	},
	"guest": {
		"title": "Guest",
		"names": ["Victor Hart", "Vivian Hart"],
		"job": "a guest of the museum",
		"story": "You have an invitation with your name on it. It's a good copy: it passes a glance, not a close look.",
		"outfit": "guest",
		"invitation": true,
		"for": "Teo, on the ballroom doors",
	},
	"press": {
		"title": "Press",
		"names": ["Sam Okoye", "Sam Okoye"],
		"job": "a society writer for the Caldera Courier",
		"story": "The Courier always covers the museum gala. Nobody told you that you needed an invitation.",
		"outfit": "press",
		"for": "Mr Okafor, the night manager, and the guests",
	},
	"agency": {
		"title": "Agency waiter",
		"names": ["Leo Brandt", "Lena Brandt"],
		"job": "a temp from Caldera Staffing",
		"story": "The agency sent you to wait tables at the gala. You're an hour late.",
		"outfit": "agency",
		"for": "Laurent, the head waiter, in the kitchen",
	},
}
## The order they're offered in.
const ORDER := ["facilities", "guest", "press", "agency"]

## What each outfit is to a Person (the job it dresses as) and to anyone
## looking (how they'd describe it).
const OUTFITS := {
	"facilities": {"job": "facilities", "male": "a gray work jacket, carrying a tool bag", "female": "a gray work jacket, carrying a tool bag"},
	"guest": {"job": "guest", "male": "a black dinner suit", "female": "a long evening dress"},
	"press": {"job": "press", "male": "a brown jacket with a press lanyard", "female": "a brown jacket with a press lanyard"},
	"agency": {"job": "agency", "male": "a black waiter's suit", "female": "a black waiter's suit"},
	"waiter_jacket": {"job": "waiter", "male": "the Meridian's white waiter's jacket", "female": "the Meridian's white waiter's jacket"},
}
## Outfits staff take for staff, in the back of the house.
const STAFF_LOOKING := ["facilities", "agency", "waiter_jacket"]
## Rooms only staff should be in.
const STAFF_ROOMS := {"corridor": "the back corridor", "kitchen": "the kitchen", "staff_room": "the staff room", "office": "the security office"}


## The covers on offer, by id.
static func all() -> Dictionary:
	return Jobs.current.covers if Jobs.current and not Jobs.current.covers.is_empty() else ALL


## The order they're offered in.
static func order() -> Array:
	if Jobs.current and not Jobs.current.covers.is_empty():
		return Jobs.current.cover_order if not Jobs.current.cover_order.is_empty() else Jobs.current.covers.keys()
	return ORDER


static func has(cover: String) -> bool:
	return all().has(cover)


## A cover's data (the first on offer for one that isn't).
static func of(cover: String) -> Dictionary:
	var a := all()
	if a.has(cover):
		return a[cover]
	var o := order()
	return a.get(o[0], {}) if not o.is_empty() else {}


## The first cover on offer.
static func first() -> String:
	var o := order()
	return str(o[0]) if not o.is_empty() else "guest"


## An outfit: {"job", "male", "female"}.
static func outfit(name: String) -> Dictionary:
	if Jobs.current and Jobs.current.outfits.has(name):
		return Jobs.current.outfits[name]
	return OUTFITS.get(name, OUTFITS["guest"])


static func looks_staff(outfit_name: String) -> bool:
	return outfit_name in (Jobs.current.staff_looking if Jobs.current and not Jobs.current.covers.is_empty() else STAFF_LOOKING)


## What an outfit is, as someone would say it: "a black dinner suit".
static func wearing(outfit_name: String, female: bool) -> String:
	return str(outfit(outfit_name)["female" if female else "male"])


## "a man in a gray work jacket, carrying a tool bag".
static func describe(outfit_name: String, female: bool) -> String:
	return "%s in %s" % ["a woman" if female else "a man", wearing(outfit_name, female)]


static func cover_name(cover: String, female: bool) -> String:
	var names: Array = of(cover).get("names", ["Stranger", "Stranger"])
	return str(names[1 if female else 0])


## A cover's title in the middle of a line: "agency waiter", but "Gaming
## Board auditor" for a cover whose title starts with a name (`keep_case`).
static func role(cover: String) -> String:
	var c := of(cover)
	var title := str(c.get("title", cover))
	return title if bool(c.get("keep_case", false)) else title.to_lower()
