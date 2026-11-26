extends Node
## Embedded LAN lobby host. It lives inside the Host game's process.

const DEFAULT_PORT := 8080
const ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var listener := TCPServer.new()
var peers: Dictionary = {}
var next_peer_id := 1
var owner_id := 0
var guest_id := 0
var room_code := ""
var ready_flags := {1: false, 2: false}
var match_started := false
var turn_role := 1
var move_seq := 0
var pending_move: Dictionary = {}
var battle_active := false
var battle_promotion := false
var promotion_role := 0
var match_stage := 0
var rng := RandomNumberGenerator.new()

func start(port: int = DEFAULT_PORT) -> Error:
	rng.randomize()
	var result := listener.listen(port, "0.0.0.0")
	set_process(result == OK)
	return result

func stop_host() -> void:
	for peer in peers.values():
		(peer as WebSocketPeer).close()
	peers.clear()
	listener.stop()
	set_process(false)

func _exit_tree() -> void:
	stop_host()

func _process(_delta: float) -> void:
	while listener.is_connection_available():
		var peer := WebSocketPeer.new()
		if peer.accept_stream(listener.take_connection()) == OK:
			peers[next_peer_id] = peer
			next_peer_id += 1
	for id in peers.keys():
		if not peers.has(id): continue
		var peer: WebSocketPeer = peers[id]
		peer.poll()
		if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var packet := peer.get_packet()
				if not peer.was_string_packet() or packet.size() > 4096: continue
				var message: Variant = JSON.parse_string(packet.get_string_from_utf8())
				if message is Dictionary: _handle(id, message)
		elif peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			_drop(id)

func _code() -> String:
	var code := ""
	for i in 6: code += ALPHABET[rng.randi_range(0, ALPHABET.length() - 1)]
	return code

func _send(id: int, message: Dictionary) -> void:
	if peers.has(id) and (peers[id] as WebSocketPeer).get_ready_state() == WebSocketPeer.STATE_OPEN:
		(peers[id] as WebSocketPeer).send_text(JSON.stringify(message))

func _state() -> Dictionary:
	var players := []
	if owner_id != 0: players.append({"id": 1, "ready": ready_flags[1]})
	if guest_id != 0: players.append({"id": 2, "ready": ready_flags[2]})
	return {"type": "state", "code": room_code, "players": players, "started": match_started}

func _broadcast(message: Dictionary) -> void:
	if owner_id != 0: _send(owner_id, message)
	if guest_id != 0: _send(guest_id, message)

func _error(id: int, message: String) -> void:
	_send(id, {"type": "error", "message": message})

func _handle(id: int, message: Dictionary) -> void:
	match str(message.get("type", "")):
		"create":
			if owner_id != 0:
				_error(id, "A LAN room is already hosted on this computer")
				return
			owner_id = id
			room_code = _code()
			ready_flags = {1: false, 2: false}
			match_started = false
			turn_role = 1
			move_seq = 0
			pending_move = {}
			battle_active = false
			battle_promotion = false
			promotion_role = 0
			match_stage = clampi(int(message.get("stage", 0)), 0, 4)
			_send(id, {"type": "joined", "code": room_code, "player": 1})
			_broadcast(_state())
		"join":
			if owner_id == 0 or str(message.get("code", "")).to_upper() != room_code:
				_error(id, "Room code not found on this Host")
				return
			if guest_id != 0 or id == owner_id or match_started:
				_error(id, "Room is full or match already started")
				return
			guest_id = id
			ready_flags[2] = false
			_send(id, {"type": "joined", "code": room_code, "player": 2})
			_broadcast(_state())
		"ready":
			var role := 1 if id == owner_id else (2 if id == guest_id else 0)
			if role == 0 or match_started: return
			ready_flags[role] = bool(message.get("ready", false))
			_broadcast(_state())
		"start":
			if id != owner_id or guest_id == 0 or not ready_flags[1] or not ready_flags[2]:
				_error(id, "Both players must be ready")
				return
			match_started = true
			_broadcast({"type": "start", "code": room_code, "stage": match_stage})
		"move_request":
			var role := 1 if id == owner_id else (2 if id == guest_id else 0)
			var from: Variant = message.get("from", [])
			var to: Variant = message.get("to", [])
			if not match_started or role != turn_role or battle_active or promotion_role != 0 or not pending_move.is_empty() or not _square(from) or not _square(to):
				_error(id, "Move rejected: wrong turn or invalid square")
				return
			pending_move = {"player": role, "from": from, "to": to}
			_send(owner_id, {"type": "move_request", "player": role, "from": from, "to": to})
		"move_commit":
			if id != owner_id or pending_move.is_empty(): return
			var capture := bool(message.get("capture", false))
			var promotion := bool(message.get("promotion", false))
			move_seq += 1
			_broadcast({"type": "duel_start" if capture else "move_commit", "seq": move_seq, "player": pending_move["player"], "from": pending_move["from"], "to": pending_move["to"], "promotion": promotion})
			battle_active = capture
			battle_promotion = promotion and capture
			promotion_role = int(pending_move["player"]) if promotion and not capture else 0
			pending_move = {}
			if not capture and not promotion: turn_role = 3 - turn_role
		"duel_input":
			if id == guest_id and battle_active and message.get("input", {}) is Dictionary:
				_send(owner_id, {"type": "duel_input", "input": message["input"]})
		"duel_state":
			if id == owner_id and battle_active and message.get("state", {}) is Dictionary:
				_send(guest_id, {"type": "duel_state", "state": message["state"]})
		"duel_result":
			if id != owner_id or not battle_active: return
			var white_won := bool(message.get("white_won", false))
			battle_active = false
			_broadcast({"type": "duel_result", "seq": move_seq, "white_won": white_won})
			if battle_promotion and white_won == (turn_role == 1):
				promotion_role = turn_role
			else:
				turn_role = 3 - turn_role
			battle_promotion = false
		"promotion_choice":
			var role := 1 if id == owner_id else (2 if id == guest_id else 0)
			var kind := str(message.get("kind", ""))
			if role != promotion_role or kind not in ["N", "B", "R", "Q", "W"]: return
			_broadcast({"type": "promotion_choice", "kind": kind})
			promotion_role = 0
			turn_role = 3 - turn_role
		"move_reject":
			if id != owner_id or pending_move.is_empty(): return
			var target := owner_id if pending_move["player"] == 1 else guest_id
			_error(target, str(message.get("reason", "Invalid chess move")))
			pending_move = {}
		"leave":
			_drop(id)

func _square(value: Variant) -> bool:
	return value is Array and value.size() == 2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float) and float(value[0]) == float(int(value[0])) and float(value[1]) == float(int(value[1])) and int(value[0]) >= 0 and int(value[0]) < 8 and int(value[1]) >= 0 and int(value[1]) < 8

func _drop(id: int) -> void:
	if peers.has(id):
		(peers[id] as WebSocketPeer).close()
		peers.erase(id)
	if id == owner_id:
		if guest_id != 0:
			_send(guest_id, {"type": "error", "message": "Host left the LAN room"})
			_drop(guest_id)
		owner_id = 0
		room_code = ""
		ready_flags = {1: false, 2: false}
		match_started = false
		pending_move = {}
		battle_active = false
		battle_promotion = false
		promotion_role = 0
	elif id == guest_id:
		guest_id = 0
		ready_flags[2] = false
		match_started = false
		pending_move = {}
		battle_active = false
		battle_promotion = false
		promotion_role = 0
		_send(owner_id, {"type": "error", "message": "Join player left the LAN room"})
		_broadcast(_state())
