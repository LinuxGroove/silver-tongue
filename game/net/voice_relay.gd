class_name VoiceRelay
extends RefCounted
## Crew voices between devices: the microphone's 16 kHz PCM16 squeezed to
## 8-bit mu-law (16 KB/s, nothing on a LAN), and back to samples played
## from a crewmate's mouth, or in your ear on the earpiece.

const RATE := 16000
const BIAS := 0x84
const CLIP := 32635

static var _table := PackedFloat32Array()


## PCM16 (little-endian) to mu-law, a byte a sample.
static func encode(pcm: PackedByteArray) -> PackedByteArray:
	var n := pcm.size() / 2
	var out := PackedByteArray()
	out.resize(n)
	for i in n:
		out[i] = ulaw(pcm.decode_s16(i * 2))
	return out


## Mu-law to samples, -1 to 1.
static func decode(data: PackedByteArray) -> PackedFloat32Array:
	if _table.is_empty():
		_table.resize(256)
		for u in 256:
			_table[u] = linear(u) / 32768.0
	var out := PackedFloat32Array()
	out.resize(data.size())
	for i in data.size():
		out[i] = _table[data[i]]
	return out


static func ulaw(sample: int) -> int:
	var sign := 0
	if sample < 0:
		sample = -sample
		sign = 0x80
	sample = mini(sample, CLIP) + BIAS
	var exponent := 7
	var mask := 0x4000
	while exponent > 0 and (sample & mask) == 0:
		exponent -= 1
		mask >>= 1
	var mantissa := (sample >> (exponent + 3)) & 0x0F
	return ~(sign | (exponent << 4) | mantissa) & 0xFF


static func linear(u: int) -> int:
	u = ~u & 0xFF
	var exponent := (u >> 4) & 0x07
	var sample := ((((u & 0x0F) << 3) + BIAS) << exponent) - BIAS
	return -sample if u & 0x80 else sample


## Readies a player to play relayed voice.
static func prepare(player: Node) -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.5
	player.set("stream", gen)


## Plays a frame of relayed voice on a prepared player.
static func play(player: Node, data: PackedByteArray) -> void:
	if not player.get("playing"):
		player.call("play")
	var pb = player.call("get_stream_playback")
	if pb == null:
		return
	var samples := decode(data)
	var frames := PackedVector2Array()
	var room: int = pb.get_frames_available()
	var n := mini(samples.size(), room)
	frames.resize(n)
	for i in n:
		frames[i] = Vector2(samples[i], samples[i])
	pb.push_buffer(frames)
