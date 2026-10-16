class_name Covers
extends RefCounted
## The crew's covers for the gala: a name, a job, a reason to be there and
## the clothes that go with it. What characters see is the outfit; what
## they're told is up to you.

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
	"facilities": {"job": "facilities", "male": "a grey work jacket, carrying a tool bag", "female": "a grey work jacket, carrying a tool bag"},
	"guest": {"job": "guest", "male": "a black dinner suit", "female": "a long evening dress"},
	"press": {"job": "press", "male": "a brown jacket with a press lanyard", "female": "a brown jacket with a press lanyard"},
	"agency": {"job": "agency", "male": "a black waiter's suit", "female": "a black waiter's suit"},
	"waiter_jacket": {"job": "waiter", "male": "the Meridian's white waiter's jacket", "female": "the Meridian's white waiter's jacket"},
}
## Outfits staff take for staff, in the back of the house.
const STAFF_LOOKING := ["facilities", "agency", "waiter_jacket"]
## Rooms only staff should be in.
const STAFF_ROOMS := {"corridor": "the back corridor", "kitchen": "the kitchen", "staff_room": "the staff room", "office": "the security office"}


static func looks_staff(outfit: String) -> bool:
	return outfit in STAFF_LOOKING


## "a man in a grey work jacket, carrying a tool bag".
static func describe(outfit: String, female: bool) -> String:
	var o: Dictionary = OUTFITS.get(outfit, OUTFITS["guest"])
	return "%s in %s" % ["a woman" if female else "a man", o["female" if female else "male"]]


static func cover_name(cover: String, female: bool) -> String:
	var names: Array = ALL.get(cover, ALL["guest"]).names
	return str(names[1 if female else 0])
