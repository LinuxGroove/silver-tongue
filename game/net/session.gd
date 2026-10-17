extends Node
## The crew's lobby and transport (autoload: Session): one player alone, or
## a crew on the local network (ENet, found by [LanBeacon] or a join code) or
## in an online room (a code, through the game server) with the host's device
## running the job. Peer 1 is the host; each player's crew id is their peer id.
##
## The job itself goes through [JobNet]; this only gathers the crew, says
## which job it is and who's wearing what, and starts everyone together.

signal roster_changed
signal hosts_found(hosts: Array)
signal joined
signal left(reason: String)
signal status(text: String)
## Host: a guest's job scene is up and wants the night's state.
signal guest_ready(peer: int)

enum Mode { NONE, SOLO, LAN_HOST, LAN_CLIENT, ONLINE_HOST, ONLINE_CLIENT }

const HELLO_TIMEOUT := 6.0

var mode := Mode.NONE
## peer -> {"name", "cover", "female"}
var crew := {}
var join_code := ""
var lan_address := ""
var in_job := false
## The job the crew will play (see [Jobs]); the host picks it.
var job_id := "meridian_gala"
## The Circuit night's number when the job is one (see [Circuit]), else 0.
var circuit := 0
## Two rival crews on the same job: each player is in team 0 or 1.
var rival := false
## Where the title opens next: "board" (Mae's back room) after a job.
var back_to := ""
## This device's pick before it's in a crew, for the hello.
var wanted := {"cover": "guest", "female": false}
## Host: guests whose job scene is up (it can load before the host's).
var ready_peers := {}
## Host: online jobs reported in this room, for the server's round counter.
var jobs_reported := 0
var _beacon: LanBeacon
var _pending_hello := {}


func _ready() -> void:
	_beacon = LanBeacon.new()
	_beacon.name = "Beacon"
	add_child(_beacon)
	_beacon.hosts_changed.connect(_on_hosts_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_host() -> bool:
	return mode in [Mode.SOLO, Mode.LAN_HOST, Mode.ONLINE_HOST, Mode.NONE]


func is_lan() -> bool:
	return mode in [Mode.LAN_HOST, Mode.LAN_CLIENT]


func is_online() -> bool:
	return mode in [Mode.ONLINE_HOST, Mode.ONLINE_CLIENT]


## Whether the crew is spread over a network, LAN or online.
func is_networked() -> bool:
	return is_lan() or is_online()


## The host of a network crew (not alone).
func _hosting() -> bool:
	return mode in [Mode.LAN_HOST, Mode.ONLINE_HOST]


func local_id() -> int:
	return multiplayer.get_unique_id() if is_networked() else 1


## This device's choices: the cover and the body.
func me() -> Dictionary:
	return crew.get(local_id(), {"name": GameConfig.player_name(), "cover": wanted.cover, "female": wanted.female})


#region Starting and joining

func start_solo(cover := "guest", female := false) -> void:
	leave()
	mode = Mode.SOLO
	crew = {1: {"name": GameConfig.player_name(), "cover": cover, "female": female, "team": 0}}
	roster_changed.emit()


func host_lan(cover := "guest", female := false) -> bool:
	leave()
	var port := int(LGSettings.get_value("lan", "port"))
	var peer := LanNet.create_host(port, GameConfig.MAX_PLAYERS - 1)
	if peer == null:
		status.emit("Couldn't host on port %d. Is another game already hosting?" % port)
		return false
	multiplayer.multiplayer_peer = peer
	mode = Mode.LAN_HOST
	crew = {1: {"name": GameConfig.player_name(), "cover": cover, "female": female, "team": 0}}
	lan_address = LanNet.local_address()
	join_code = JoinCode.encode(lan_address, port, port) if lan_address != "" else ""
	_beacon.start_advertising(_beacon_info(), int(LGSettings.get_value("lan", "beacon_port")))
	joined.emit()
	roster_changed.emit()
	return true


func browse_lan() -> void:
	_beacon.start_listening(int(LGSettings.get_value("lan", "beacon_port")))


func stop_browsing() -> void:
	if mode == Mode.NONE:
		_beacon.stop()


func join_lan(address: String, port: int) -> bool:
	leave()
	var peer := LanNet.create_client(address, port)
	if peer == null:
		status.emit("Couldn't reach %s." % address)
		return false
	multiplayer.multiplayer_peer = peer
	mode = Mode.LAN_CLIENT
	status.emit("Connecting to %s..." % address)
	return true


func join_lan_code(code: String) -> bool:
	var port := int(LGSettings.get_value("lan", "port"))
	var target := JoinCode.decode(code, port)
	if target.is_empty():
		status.emit("That code doesn't look right.")
		return false
	return join_lan(target.ip, target.port)


## Opens an online room: the crew joins with its code. Needs the game server.
func host_online(cover := "guest", female := false) -> bool:
	leave()
	status.emit("Connecting to the game server...")
	if not await LGOnline.connect_async(GameConfig.player_name(), GameConfig.GAME_ID):
		status.emit(LGOnline.last_error)
		return false
	var code: String = await LGOnline.host_room_async(GameConfig.GAME_ID)
	if code == "":
		status.emit(LGOnline.last_error)
		return false
	mode = Mode.ONLINE_HOST
	join_code = code
	crew = {1: {"name": GameConfig.player_name(), "cover": cover, "female": female, "team": 0}}
	joined.emit()
	roster_changed.emit()
	return true


func join_online(code: String, cover := "guest", female := false) -> bool:
	if not LGOnline.is_valid_code(code):
		status.emit("Type the room code shown on the host's screen.")
		return false
	leave()
	wanted = {"cover": cover, "female": female}
	status.emit("Connecting to the game server...")
	if not await LGOnline.connect_async(GameConfig.player_name(), GameConfig.GAME_ID):
		status.emit(LGOnline.last_error)
		return false
	if not await LGOnline.join_room_async(GameConfig.GAME_ID, code):
		var shown := LGOnline.normalize_code(code)
		if LGOnline.last_error == LGOnline.NO_ROOM:
			status.emit("No room with code %s. Check the code with the host." % shown)
		elif LGOnline.last_error.begins_with("room_full"):
			status.emit("Room %s is full." % shown)
		else:
			status.emit("Couldn't join room %s." % shown)
		return false
	# No await between joining and setting the mode: the bridge has already
	# announced the host, so connected_to_server has sent the hello.
	mode = Mode.ONLINE_CLIENT
	join_code = LGOnline.normalize_code(code)
	return true


func leave(reason := "") -> void:
	var was := mode
	_beacon.stop()
	if is_online() or LGOnline.bridge:
		# The bridge's peer can't be closed directly; leaving the room does it.
		LGOnline.leave_room()
	elif multiplayer.multiplayer_peer and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = Mode.NONE
	crew.clear()
	join_code = ""
	in_job = false
	jobs_reported = 0
	rival = false
	ready_peers.clear()
	_pending_hello.clear()
	if was != Mode.NONE:
		left.emit(reason)

#endregion

#region The crew

## Host (or alone): picks the job (a Circuit night's when `night` isn't 0),
## and makes every cover one it has.
func set_job(p_job: String, night := 0) -> void:
	if not is_host() or not Jobs.exists(p_job):
		return
	job_id = p_job
	circuit = night
	Jobs.current = null
	ensure_job()
	if not Covers.has(str(wanted.cover)):
		wanted["cover"] = Covers.first()
	for id in crew:
		if not Covers.has(str(crew[id].cover)):
			crew[id].cover = Covers.first()
	_broadcast_roster()


## Makes sure [member Jobs.current] is the crew's job.
func ensure_job() -> void:
	if Jobs.current == null or Jobs.current.id != job_id or int(Jobs.current.circuit.get("seed", 0)) != circuit:
		Jobs.current = Jobs.make(job_id if Jobs.exists(job_id) else "meridian_gala")
		if circuit != 0:
			Circuit.remix(Jobs.current, circuit)


## Picks this device's cover and body.
func set_cover(cover: String, female: bool) -> void:
	ensure_job()
	if not Covers.has(cover):
		return
	wanted = {"cover": cover, "female": female}
	if mode == Mode.NONE:
		return
	if is_host():
		crew[local_id()] = {"name": GameConfig.player_name(), "cover": cover, "female": female}
		_broadcast_roster()
	elif mode in [Mode.LAN_CLIENT, Mode.ONLINE_CLIENT]:
		_c_set_cover.rpc_id(1, cover, female)


## Which crew a player is in (0 unless two crews are on).
func team_of(id: int) -> int:
	return int(crew.get(id, {}).get("team", 0)) if rival else 0


## How many players a crew has.
func team_size(team: int) -> int:
	var n := 0
	for id in crew:
		if int(crew[id].get("team", 0)) == team:
			n += 1
	return n


## The crew a new player joins: the smaller one with room (-1 when both are full).
func _open_team() -> int:
	if not rival:
		return 0 if crew.size() < GameConfig.MAX_CREW else -1
	var t := 0 if team_size(0) <= team_size(1) else 1
	return t if team_size(t) < GameConfig.MAX_CREW else -1


## Host: two crews race for the same prize, or one crew works together.
## Turning it on splits the players between the crews; it stays off while
## more than one crew's worth of players are in.
func set_rival(on: bool) -> bool:
	if not is_host() or in_job:
		return false
	if on == rival:
		return true
	if not on and crew.size() > GameConfig.MAX_CREW:
		return false
	rival = on
	var ids := crew.keys()
	ids.sort()
	for i in ids.size():
		crew[ids[i]]["team"] = (i % 2) if on else 0
	_broadcast_roster()
	return true


## Moves you to the other crew, if it has room.
func switch_team() -> void:
	if not rival:
		return
	var mine := team_of(local_id())
	if is_host():
		_move_team(local_id(), 1 - mine)
	elif mode in [Mode.LAN_CLIENT, Mode.ONLINE_CLIENT]:
		_c_switch_team.rpc_id(1)


func _move_team(id: int, team: int) -> void:
	if crew.has(id) and team_size(team) < GameConfig.MAX_CREW:
		crew[id]["team"] = team
		_broadcast_roster()


func can_start() -> bool:
	return is_host() and not in_job and not crew.is_empty()


## Host: the night's crew, as [CrewInfo] dicts: their covers, and what
## the job gives them to carry (the gala's invitation goes to the guest).
func job_crew() -> Array:
	ensure_job()
	var ids := crew.keys()
	ids.sort()
	var crews: Array = []
	for id in ids:
		var c := CrewInfo.make(int(id), int(id), str(crew[id].name), str(crew[id].cover), bool(crew[id].female))
		c.burned = Progress.burned if int(id) == local_id() else bool(crew[id].get("burned", false))
		c.team = team_of(int(id))
		crews.append(c)
	for t in 2:
		Jobs.current.give_items(crews.filter(func(c): return c.team == t))
	return crews.map(func(c): return c.to_dict())


## Host: starts the job on every device.
func start_job() -> void:
	if not can_start():
		return
	var config := {"job": job_id, "circuit": circuit, "crew": job_crew(), "seed": randi(), "rival": rival}
	in_job = true
	ready_peers.clear()
	_beacon.update_info({"state": "playing"})
	if is_lan():
		for p in multiplayer.get_peers():
			_h_start.rpc_id(p, config)
	_start(config)


## Guest: this device's job scene is up. It goes through here, not the
## scene, since the host's scene may not be up yet.
func job_ready() -> void:
	if mode in [Mode.LAN_CLIENT, Mode.ONLINE_CLIENT]:
		_c_job_ready.rpc_id(1)


## Host of an online room: reports the job to the game server, which writes
## the crew's stats and boards and what the characters will remember. Each
## device's player is the signed-in account; only the host's game calls this.
func report_job(r: Dictionary) -> bool:
	if mode != Mode.ONLINE_HOST or LGOnline.bridge == null:
		return false
	var accounts := {}
	for c in r.get("crew", []):
		accounts[int(c.get("id", 0))] = LGOnline.user_id_for_peer(int(c.get("id", 0)))
	var sent := false
	# Two crews are two reports: each crew's own result.
	for team in ([0, 1] if bool(r.get("rival", false)) else [-1]):
		var payload := job_report_payload(r, LGOnline.bridge.match_id, jobs_reported + 1, accounts, team)
		if payload.players.is_empty():
			continue
		jobs_reported += 1
		sent = await LGOnline.rpc_async("%s.job_report" % GameConfig.GAME_ID, payload) != null or sent
	return sent


## The server's job report for a [method Job.report]: `accounts` maps each
## crew member's id to their account id (left out when they have none). With
## two crews, `team` picks one crew's players and result.
static func job_report_payload(r: Dictionary, match_id: String, round_number: int, accounts: Dictionary, team := -1) -> Dictionary:
	var players := []
	for c in r.get("crew", []):
		if team >= 0 and int(c.get("team", 0)) != team:
			continue
		var uid := str(accounts.get(int(c.get("id", 0)), ""))
		if uid == "":
			continue
		players.append({"user_id": uid, "held": bool(c.get("was_held", false)), "memories": r.get("memories", {})})
	var win: bool = bool(r.get("win", false)) and (team < 0 or team in r.get("winners", []))
	return {
		"match_id": match_id,
		"round": round_number,
		"job": str(r.get("job", "")),
		"circuit": int(r.get("circuit", 0)),
		"win": win,
		"clean": bool(r.get("clean", false)) and win,
		"quiet": bool(r.get("quiet", false)) and win,
		"silver": bool(r.get("silver", false)) and win,
		"take": int(r.get("take", 0)) if win else 0,
		"venue": str(r.get("venue", "")),
		"players": players,
	}


func _start(config: Dictionary) -> void:
	config["me"] = local_id()
	job_id = str(config.get("job", job_id))
	circuit = int(config.get("circuit", 0))
	ensure_job()
	JobScene.setup = config
	SetupScreen.play_job()

#endregion

#region Network events

func _on_hosts_changed(hosts: Array) -> void:
	hosts_found.emit(hosts.filter(_is_ours))


func _is_ours(h: Dictionary) -> bool:
	return str(h.get("game", "")) == GameConfig.GAME_ID


func _on_peer_connected(id: int) -> void:
	if _hosting():
		_pending_hello[id] = Time.get_ticks_msec()
		get_tree().create_timer(HELLO_TIMEOUT).timeout.connect(_hello_overdue.bind(id))


func _hello_overdue(id: int) -> void:
	if _pending_hello.has(id):
		_pending_hello.erase(id)
		_kick(id, "No hello from this game version.")


func _on_peer_disconnected(id: int) -> void:
	_pending_hello.erase(id)
	ready_peers.erase(id)
	if is_online() and id == 1 and not _hosting():
		# Deferred: this runs inside the bridge peer's poll.
		leave.call_deferred("The host left.")
		return
	if _hosting() and crew.has(id):
		var n: String = crew[id].name
		crew.erase(id)
		_broadcast_roster()
		status.emit("%s left." % n)


func _on_connected_to_server() -> void:
	var m := me()
	_c_hello.rpc_id(1, GameConfig.PROTOCOL, GameConfig.player_name(), str(m.get("cover", "guest")), bool(m.get("female", false)))
	# After the hello, which stays the same from version to version.
	_c_face.rpc_id(1, Progress.burned)


func _on_connection_failed() -> void:
	status.emit("Couldn't connect to the host.")
	leave("Couldn't connect to the host.")


func _on_server_disconnected() -> void:
	leave("The host left.")


@rpc("any_peer", "reliable")
func _c_hello(protocol: int, p_name: String, cover: String, female: bool) -> void:
	if not _hosting():
		return
	var id := multiplayer.get_remote_sender_id()
	_pending_hello.erase(id)
	if protocol != GameConfig.PROTOCOL:
		_kick(id, "This game is version %s. Update Silver Tongue to play together." % GameConfig.version())
		return
	if in_job:
		_kick(id, "The job's already under way.")
		return
	var team := _open_team()
	if team < 0:
		_kick(id, "The crew's full.")
		return
	crew[id] = {"name": _unique_name(p_name.strip_edges().left(16)), "cover": cover if Covers.has(cover) else Covers.first(), "female": female, "team": team}
	_broadcast_roster()
	status.emit("%s joined." % crew[id].name)


## Whether Halberd has this guest's face on file.
@rpc("any_peer", "reliable")
func _c_face(burned: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if _hosting() and crew.has(id):
		crew[id]["burned"] = burned


@rpc("any_peer", "reliable")
func _c_set_cover(cover: String, female: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if _hosting() and crew.has(id) and Covers.has(cover):
		crew[id].cover = cover
		crew[id].female = female
		_broadcast_roster()


@rpc("any_peer", "reliable")
func _c_switch_team() -> void:
	var id := multiplayer.get_remote_sender_id()
	if _hosting() and rival and crew.has(id):
		_move_team(id, 1 - team_of(id))


@rpc("any_peer", "reliable")
func _c_job_ready() -> void:
	var id := multiplayer.get_remote_sender_id()
	if _hosting() and crew.has(id):
		ready_peers[id] = true
		guest_ready.emit(id)


@rpc("authority", "reliable")
func _h_roster(p_crew: Dictionary, p_code: String, p_job: String, p_circuit: int, p_rival: bool) -> void:
	var first := crew.is_empty()
	crew = p_crew
	rival = p_rival
	join_code = p_code
	if Jobs.exists(p_job):
		job_id = p_job
		circuit = p_circuit
		ensure_job()
	if first:
		joined.emit()
	roster_changed.emit()


@rpc("authority", "reliable")
func _h_kicked(reason: String) -> void:
	leave(reason)


@rpc("authority", "reliable")
func _h_start(config: Dictionary) -> void:
	in_job = true
	_start(config)


func _broadcast_roster() -> void:
	if _hosting():
		for p in multiplayer.get_peers():
			if not _pending_hello.has(p):
				_h_roster.rpc_id(p, crew, join_code, job_id, circuit, rival)
		_beacon.update_info({"players": crew.size()})
	roster_changed.emit()


func _kick(id: int, reason: String) -> void:
	_h_kicked.rpc_id(id, reason)
	get_tree().create_timer(0.5).timeout.connect(_drop.bind(id))


func _drop(id: int) -> void:
	if id in multiplayer.get_peers():
		multiplayer.multiplayer_peer.disconnect_peer(id)


func _unique_name(n: String) -> String:
	if n == "":
		n = "Stranger"
	var names := []
	for c in crew.values():
		names.append(c.name)
	var out := n
	var i := 2
	while out in names:
		out = "%s %d" % [n, i]
		i += 1
	return out


func _beacon_info() -> Dictionary:
	return {
		"game": GameConfig.GAME_ID,
		"version": GameConfig.version(),
		"protocol": GameConfig.PROTOCOL,
		"name": "%s's crew" % GameConfig.player_name(),
		"port": int(LGSettings.get_value("lan", "port")),
		"players": crew.size(),
		"max": GameConfig.MAX_PLAYERS,
		"state": "lobby",
		"code": join_code,
	}

#endregion
