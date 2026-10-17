class_name Language
extends RefCounted
## Mind your language: with the setting on, swearing in what's shown and
## spoken (subtitles, the characters' voices, your own words as they were
## heard) comes out as something you'd say in front of your gran. The
## characters' prompts ask them to keep it clean too ([CharacterPrompt]);
## this catches what gets through, and what players say.

## Whole words, and what they become.
const WORDS := {
	"fuck": "flip", "fucks": "flips", "fucking": "flipping", "fuckin": "flippin", "fucked": "flipped",
	"fucker": "so-and-so", "fuckers": "so-and-sos", "motherfucker": "so-and-so", "motherfuckers": "so-and-sos",
	"shit": "shoot", "shits": "shoots", "shitty": "rotten", "bullshit": "nonsense", "horseshit": "nonsense",
	"bitch": "pain", "bitches": "pains", "bastard": "rotter", "bastards": "rotters",
	"asshole": "idiot", "assholes": "idiots", "arsehole": "idiot", "arseholes": "idiots", "ass": "backside", "arse": "backside",
	"damn": "darn", "dammit": "darn it", "goddamn": "gosh darn", "goddamned": "gosh darned", "hell": "heck",
	"crap": "rubbish", "crappy": "rubbish", "dick": "idiot", "dicks": "idiots", "prick": "idiot", "pricks": "idiots",
	"piss": "push", "pissed": "cross", "cunt": "so-and-so", "cunts": "so-and-sos", "wanker": "idiot", "wankers": "idiots",
	"bollocks": "rubbish", "bloody": "blooming", "twat": "twit", "twats": "twits",
}
## Parts of longer words ("shithead"), checked in order.
const PARTS := [["motherfuck", "so-and-so"], ["fuck", "flip"], ["shit", "shoot"], ["cunt", "so-and-so"]]

static var _word: RegEx


## Whether the setting's on.
static func on() -> bool:
	return bool(LGSettings.get_value("voice", "mind_language", false))


## `text` cleaned up when the setting's on (or `always`), keeping each
## word's capitals.
static func clean(text: String, always := false) -> String:
	if text == "" or not (always or on()):
		return text
	if _word == null:
		_word = RegEx.create_from_string("[A-Za-z]+")
	var out := ""
	var last := 0
	for m in _word.search_all(text):
		var w := m.get_string()
		out += text.substr(last, m.get_start() - last) + _cased(w, _soft(w.to_lower()))
		last = m.get_end()
	return out + text.substr(last)


static func _soft(low: String) -> String:
	if WORDS.has(low):
		return str(WORDS[low])
	for p in PARTS:
		if low.contains(p[0]):
			return low.replace(p[0], p[1])
	return low


## `soft` with the capitals `w` had: all, the first, or none.
static func _cased(w: String, soft: String) -> String:
	if soft == w.to_lower():
		return w
	if w.length() > 1 and w == w.to_upper():
		return soft.to_upper()
	if w[0] == w[0].to_upper():
		return soft[0].to_upper() + soft.substr(1)
	return soft
