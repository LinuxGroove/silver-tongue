class_name JobNet
extends Node
## A job between devices, for co-op on LAN: the host runs the [Job] and
## sends each guest what they need (characters' lines, where everyone is,
## doors, heat, their own toasts); guests send what their player says and
## does. Requests are `_c_*`, state is `_h_*`, always with `rpc_id`. Crew
## voices go through the host too ([VoiceRelay]). Solo, nothing is sent.
##
## The scene connects to the signals, which fire on the device that should
## act on them: requests on the host, state on the guests. A guest says
## its scene is up through [Session] (the host's may not be up yet), and
## only gets state from then on.

## A guest's scene is ready for the night's state.
signal guest_ready(peer: int)
signal line_requested(peer: int, text: String, voice: String, earpiece: bool, at: Vector3, look: Vector3)
signal use_requested(peer: int, what: String)
signal keypad_requested(peer: int, code: String, pad: String)
signal phone_requested(peer: int, number_id: String, as_who: String)
signal hang_up_requested(peer: int)
signal mae_requested(peer: int, call_id: String)
signal pose_received(crew_id: int, at: Vector3, look: Vector3, crouch: bool)
signal voice_received(crew_id: int, data: PackedByteArray, earpiece: bool)
signal line_received(char_id: String, text: String, tone: String, channel: String)
signal crew_line_received(crew_id: int, text: String, voice: String, earpiece: bool)
signal toast_received(text: String)
signal heat_received(level: int)
signal crew_received(info: Dictionary)
signal door_received(door_name: String, is_open: bool, locked: bool)
signal faced_received(char_id: String, suspicion: int)
signal clock_received(minute: int)
signal snapshot_received(chars: Dictionary)
signal item_received(item: String, holder: int, at: String)
signal shown_received(node_name: String, is_visible: bool)
signal goal_received(text: String)
signal mae_received(text: String)
signal call_received(char_id: String, number_name: String)
signal moved_received(at: Transform3D)
signal report_received(report: Dictionary)
signal peer_gone(peer: int)

var lan := false
## Guest: the host has sent the night's state, so its scene is up too and
## can take requests.
var synced := false
## Crew id -> team, so a crew's earpiece reaches only its own.
var teams := {}


func _ready() -> void:
	lan = multiplayer.has_multiplayer_peer() and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer and multiplayer.get_unique_id() != 0
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	Session.guest_ready.connect(_on_session_guest_ready)


func is_host() -> bool:
	return not lan or multiplayer.is_server()


func my_id() -> int:
	return multiplayer.get_unique_id() if lan else 1


## Host: the guests whose scene is up, who get the night's state.
func guests() -> PackedInt32Array:
	var out := PackedInt32Array()
	for p in expected():
		if Session.ready_peers.has(p):
			out.append(p)
	return out


## Host: every guest connected, ready or not.
func expected() -> PackedInt32Array:
	return multiplayer.get_peers() if lan and multiplayer.is_server() else PackedInt32Array()


func _on_session_guest_ready(peer: int) -> void:
	if lan and multiplayer.is_server():
		guest_ready.emit(peer)


func _on_peer_disconnected(peer: int) -> void:
	peer_gone.emit(peer)


func _sender() -> int:
	var p := multiplayer.get_remote_sender_id()
	return p if p != 0 else 1

#region Guest to host

func ready_for_state() -> void:
	if lan and not multiplayer.is_server():
		Session.job_ready()


## A line this device's player said, with where they stood and looked as
## they said it (poses are unreliable, and the first few are lost).
func send_line(text: String, voice: String, earpiece: bool, at: Vector3, look: Vector3) -> void:
	if lan and synced and not multiplayer.is_server():
		_c_line.rpc_id(1, text, voice, earpiece, at, look)


func send_use(what: String) -> void:
	if lan and synced and not multiplayer.is_server():
		_c_use.rpc_id(1, what)


func send_keypad(code: String, pad: String) -> void:
	if lan and synced and not multiplayer.is_server():
		_c_keypad.rpc_id(1, code, pad)


## Rings a number on the job's phone list, showing `as_who` as the caller.
func send_phone(number_id: String, as_who: String) -> void:
	if lan and synced and not multiplayer.is_server():
		_c_phone.rpc_id(1, number_id, as_who)


func send_hang_up() -> void:
	if lan and synced and not multiplayer.is_server():
		_c_hang_up.rpc_id(1)


## Asks Auntie Mae to make one of her calls.
func send_mae(call_id: String) -> void:
	if lan and synced and not multiplayer.is_server():
		_c_mae.rpc_id(1, call_id)


## Where this device's player is (guests send it to the host; the host
## sends its own and everyone else's to the guests).
func send_pose(crew_id: int, at: Vector3, look: Vector3, crouch: bool) -> void:
	if not lan:
		return
	if multiplayer.is_server():
		for p in guests():
			if p != crew_id:
				_h_pose.rpc_id(p, crew_id, at, look, crouch)
	elif synced:
		_c_pose.rpc_id(1, at, look, crouch)


## A frame of a crew voice: from a guest to the host, and from the host on
## to everyone but its speaker.
func send_voice(crew_id: int, data: PackedByteArray, earpiece: bool) -> void:
	if not lan:
		return
	if multiplayer.is_server():
		for p in guests():
			if p != crew_id and (not earpiece or _mates(p, crew_id)):
				_h_voice.rpc_id(p, crew_id, data, earpiece)
	elif synced:
		_c_voice.rpc_id(1, data, earpiece)


@rpc("any_peer", "call_remote", "reliable")
func _c_line(text: String, voice: String, earpiece: bool, at: Vector3, look: Vector3) -> void:
	if multiplayer.is_server():
		line_requested.emit(_sender(), text.left(400), voice, earpiece, at, look)


@rpc("any_peer", "call_remote", "reliable")
func _c_use(what: String) -> void:
	if multiplayer.is_server():
		use_requested.emit(_sender(), what.left(64))


@rpc("any_peer", "call_remote", "reliable")
func _c_keypad(code: String, pad: String) -> void:
	if multiplayer.is_server():
		keypad_requested.emit(_sender(), code.left(8), pad.left(64))


@rpc("any_peer", "call_remote", "reliable")
func _c_phone(number_id: String, as_who: String) -> void:
	if multiplayer.is_server():
		phone_requested.emit(_sender(), number_id.left(64), as_who.left(64))


@rpc("any_peer", "call_remote", "reliable")
func _c_hang_up() -> void:
	if multiplayer.is_server():
		hang_up_requested.emit(_sender())


@rpc("any_peer", "call_remote", "reliable")
func _c_mae(call_id: String) -> void:
	if multiplayer.is_server():
		mae_requested.emit(_sender(), call_id.left(64))


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _c_pose(at: Vector3, look: Vector3, crouch: bool) -> void:
	if multiplayer.is_server():
		pose_received.emit(_sender(), at, look, crouch)
		send_pose(_sender(), at, look, crouch)


@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _c_voice(data: PackedByteArray, earpiece: bool) -> void:
	if multiplayer.is_server() and data.size() <= 4000:
		voice_received.emit(_sender(), data, earpiece)
		send_voice(_sender(), data, earpiece)

#endregion

#region Host to guests

## A character's line, to every guest.
func line(char_id: String, text: String, tone: String, channel: String) -> void:
	for p in guests():
		_h_line.rpc_id(p, char_id, text, tone, channel)


## Whether two crew members are on the same crew.
func _mates(a: int, b: int) -> bool:
	return int(teams.get(a, 0)) == int(teams.get(b, 0))


func crew_line(crew_id: int, text: String, voice: String, earpiece: bool) -> void:
	for p in guests():
		if p != crew_id and (not earpiece or _mates(p, crew_id)):
			_h_crew_line.rpc_id(p, crew_id, text, voice, earpiece)


## Something to tell one guest (0: every guest).
func toast(peer: int, text: String) -> void:
	for p in guests():
		if peer == 0 or p == peer:
			_h_toast.rpc_id(p, text)


func heat(level: int, to := 0) -> void:
	for p in guests():
		if to == 0 or p == to:
			_h_heat.rpc_id(p, level)


func crew(info: Dictionary, to := 0) -> void:
	for p in guests():
		if to == 0 or p == to:
			_h_crew.rpc_id(p, info)


func door(door_name: String, is_open: bool, locked: bool, to := 0) -> void:
	for p in guests():
		if to == 0 or p == to:
			_h_door.rpc_id(p, door_name, is_open, locked)


## What a character makes of one guest's player: to that guest only.
func faced(peer: int, char_id: String, suspicion: int) -> void:
	if peer in guests():
		_h_faced.rpc_id(peer, char_id, suspicion)


func clock(minute: int) -> void:
	for p in guests():
		_h_clock.rpc_id(p, minute)


func snapshot(chars: Dictionary) -> void:
	for p in guests():
		_h_snap.rpc_id(p, chars)


func report(r: Dictionary) -> void:
	for p in guests():
		_h_report.rpc_id(p, r)


func item(item_id: String, holder: int, at: String, to := 0) -> void:
	for p in guests():
		if to == 0 or p == to:
			_h_item.rpc_id(p, item_id, holder, at)


func shown(node_name: String, is_visible: bool, to := 0) -> void:
	for p in guests():
		if to == 0 or p == to:
			_h_shown.rpc_id(p, node_name, is_visible)


## What one guest (0: every guest) should do now.
func goal(peer: int, text: String) -> void:
	for p in guests():
		if peer == 0 or p == peer:
			_h_goal.rpc_id(p, text)


## Auntie Mae, in one guest's ear.
func mae(peer: int, text: String) -> void:
	if peer in guests():
		_h_mae.rpc_id(peer, text)


## One guest was taken somewhere at once.
func move(peer: int, at: Transform3D) -> void:
	if peer in guests():
		_h_move.rpc_id(peer, at)


## One guest's phone call started (or ended: both "").
func call_state(peer: int, char_id: String, number_name: String) -> void:
	if peer in guests():
		_h_call.rpc_id(peer, char_id, number_name)


@rpc("authority", "call_remote", "reliable")
func _h_line(char_id: String, text: String, tone: String, channel: String) -> void:
	line_received.emit(char_id, text, tone, channel)


@rpc("authority", "call_remote", "reliable")
func _h_crew_line(crew_id: int, text: String, voice: String, earpiece: bool) -> void:
	crew_line_received.emit(crew_id, text, voice, earpiece)


@rpc("authority", "call_remote", "reliable")
func _h_toast(text: String) -> void:
	toast_received.emit(text)


@rpc("authority", "call_remote", "reliable")
func _h_heat(level: int) -> void:
	heat_received.emit(level)


@rpc("authority", "call_remote", "reliable")
func _h_crew(info: Dictionary) -> void:
	synced = true
	crew_received.emit(info)


@rpc("authority", "call_remote", "reliable")
func _h_door(door_name: String, is_open: bool, locked: bool) -> void:
	door_received.emit(door_name, is_open, locked)


@rpc("authority", "call_remote", "reliable")
func _h_faced(char_id: String, suspicion: int) -> void:
	faced_received.emit(char_id, suspicion)


@rpc("authority", "call_remote", "reliable")
func _h_clock(minute: int) -> void:
	clock_received.emit(minute)


@rpc("authority", "call_remote", "unreliable_ordered")
func _h_snap(chars: Dictionary) -> void:
	snapshot_received.emit(chars)


@rpc("authority", "call_remote", "unreliable_ordered")
func _h_pose(crew_id: int, at: Vector3, look: Vector3, crouch: bool) -> void:
	pose_received.emit(crew_id, at, look, crouch)


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func _h_voice(crew_id: int, data: PackedByteArray, earpiece: bool) -> void:
	voice_received.emit(crew_id, data, earpiece)


@rpc("authority", "call_remote", "reliable")
func _h_report(r: Dictionary) -> void:
	report_received.emit(r)


@rpc("authority", "call_remote", "reliable")
func _h_item(item_id: String, holder: int, at: String) -> void:
	item_received.emit(item_id, holder, at)


@rpc("authority", "call_remote", "reliable")
func _h_shown(node_name: String, is_visible: bool) -> void:
	shown_received.emit(node_name, is_visible)


@rpc("authority", "call_remote", "reliable")
func _h_goal(text: String) -> void:
	goal_received.emit(text)


@rpc("authority", "call_remote", "reliable")
func _h_mae(text: String) -> void:
	mae_received.emit(text)


@rpc("authority", "call_remote", "reliable")
func _h_call(char_id: String, number_name: String) -> void:
	call_received.emit(char_id, number_name)


@rpc("authority", "call_remote", "reliable")
func _h_move(at: Transform3D) -> void:
	moved_received.emit(at)

#endregion
