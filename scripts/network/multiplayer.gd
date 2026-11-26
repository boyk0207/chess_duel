extends Node
signal state_changed(state: Dictionary)
signal error_received(message: String)
signal match_started(room: String)
signal move_requested(player: int, from: Vector2i, to: Vector2i)
signal move_committed(seq: int, player: int, from: Vector2i, to: Vector2i)
signal duel_started(seq: int, player: int, from: Vector2i, to: Vector2i)
signal duel_input_received(input: Dictionary)
signal duel_state_received(state: Dictionary)
signal duel_result_received(seq: int, white_won: bool)
signal promotion_selected(kind: String)

const LanHost = preload("res://scripts/network/lan_host.gd")
const LAN_PORT := 8080

var socket := WebSocketPeer.new()
var connected := false
var room_code := ""
var player_id := 0
var state: Dictionary = {}
var server_url := "ws://127.0.0.1:8080"
var _was_open := false
var _pending_action := ""
var _pending_code := ""
var _pending_stage := 0
var lan_host: Node
var host_address := ""
var match_stage := 0

func _ready() -> void:
    var configured := ProjectSettings.get_setting("chessduel/server_url", "") as String
    if configured != "": server_url = configured
    for address in IP.get_local_addresses():
        if address.contains(":") or address.begins_with("127."): continue
        host_address = address
        break
    if host_address.is_empty(): host_address = "127.0.0.1"

func _process(_delta: float) -> void:
    socket.poll()
    var status := socket.get_ready_state()
    if status == WebSocketPeer.STATE_OPEN:
        if not _was_open:
            _was_open = true
            connected = true
            _send({"type": _pending_action, "code": _pending_code, "stage": _pending_stage})
        var latest_duel_state: Dictionary = {}
        while socket.get_available_packet_count() > 0:
            var packet := socket.get_packet().get_string_from_utf8()
            var msg = JSON.parse_string(packet)
            if not msg is Dictionary: continue
            if str(msg.get("type", "")) == "duel_state":
                latest_duel_state = msg
                continue
            if not latest_duel_state.is_empty():
                _handle(latest_duel_state)
                latest_duel_state = {}
            _handle(msg)
        if not latest_duel_state.is_empty(): _handle(latest_duel_state)
    elif status == WebSocketPeer.STATE_CLOSED and (_was_open or not _pending_action.is_empty()):
        var was_connected := _was_open
        _was_open = false
        connected = false
        room_code = ""
        state = {}
        _pending_action = ""
        error_received.emit("Disconnected from Host" if was_connected else "Could not connect to Host. Check LAN IP and port 8080")
        state_changed.emit(state)

func _connect_and_send(action: String, code: String = "", stage: int = 0) -> void:
    if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        _send({"type": action, "code": code, "stage": stage})
        return
    socket = WebSocketPeer.new()
    _was_open = false
    _pending_action = action
    _pending_code = code
    _pending_stage = stage
    var err := socket.connect_to_url(server_url)
    if err != OK: error_received.emit("Connection failed: " + str(err))

func create_room(stage: int = 0) -> void:
    if not is_instance_valid(lan_host):
        lan_host = LanHost.new()
        add_child(lan_host)
        var result: Error = lan_host.start(LAN_PORT)
        if result != OK:
            lan_host.queue_free()
            lan_host = null
            error_received.emit("Cannot host LAN room on port %d (error %d)" % [LAN_PORT, result])
            return
    server_url = "ws://127.0.0.1:%d" % LAN_PORT
    _connect_and_send("create", "", stage)

func join_room(code: String, address: String = "127.0.0.1") -> void:
    var host_ip := address.strip_edges()
    if host_ip.is_empty(): host_ip = "127.0.0.1"
    if not host_ip.is_valid_ip_address():
        error_received.emit("Enter a valid Host LAN IP address")
        return
    server_url = "ws://%s:%d" % [host_ip, LAN_PORT]
    _connect_and_send("join", code.strip_edges().to_upper())
func start_match() -> void: _send({"type":"start"})
func set_ready(ready: bool) -> void: _send({"type":"ready", "ready":ready})
func request_move(from: Vector2i, to: Vector2i) -> void:
    _send({"type":"move_request", "from":[from.x,from.y], "to":[to.x,to.y]})
func accept_move(capture: bool = false, promotion: bool = false) -> void:
    _send({"type":"move_commit", "capture":capture, "promotion":promotion})
func reject_move(reason: String) -> void: _send({"type":"move_reject", "reason": reason})
func send_duel_input(input: Dictionary) -> void: _send({"type":"duel_input", "input":input})
func send_duel_state(state: Dictionary) -> void: _send({"type":"duel_state", "state":state})
func send_duel_result(white_won: bool) -> void: _send({"type":"duel_result", "white_won":white_won})
func choose_promotion(kind: String) -> void: _send({"type":"promotion_choice", "kind":kind})
func leave_room() -> void:
    _send({"type":"leave"})
    socket.close(-1)
    socket = WebSocketPeer.new()
    _was_open = false
    connected = false
    _pending_action = ""
    if is_instance_valid(lan_host):
        lan_host.stop_host()
        lan_host.queue_free()
        lan_host = null
    room_code = ""
    player_id = 0
    state = {}
    state_changed.emit(state)

func _send(msg: Dictionary) -> void:
    if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        socket.send_text(JSON.stringify(msg))

func _handle(msg: Dictionary) -> void:
    match str(msg.get("type", "")):
        "joined":
            _pending_action = ""
            room_code = str(msg.get("code", ""))
            player_id = int(msg.get("player", 0))
        "state":
            state = msg
            state_changed.emit(state)
        "start":
            match_stage = int(msg.get("stage", 0))
            match_started.emit(str(msg.get("code", "")))
        "move_request":
            var from: Array = msg.get("from", [])
            var to: Array = msg.get("to", [])
            if from.size() == 2 and to.size() == 2:
                move_requested.emit(int(msg.get("player", 0)), Vector2i(int(from[0]),int(from[1])), Vector2i(int(to[0]),int(to[1])))
        "move_commit":
            var from: Array = msg.get("from", [])
            var to: Array = msg.get("to", [])
            if from.size() == 2 and to.size() == 2:
                move_committed.emit(int(msg.get("seq", 0)), int(msg.get("player", 0)), Vector2i(int(from[0]),int(from[1])), Vector2i(int(to[0]),int(to[1])))
        "duel_start":
            var from: Array = msg.get("from", [])
            var to: Array = msg.get("to", [])
            if from.size() == 2 and to.size() == 2:
                duel_started.emit(int(msg.get("seq", 0)), int(msg.get("player", 0)), Vector2i(int(from[0]),int(from[1])), Vector2i(int(to[0]),int(to[1])))
        "duel_input": duel_input_received.emit(msg.get("input", {}))
        "duel_state": duel_state_received.emit(msg.get("state", {}))
        "duel_result": duel_result_received.emit(int(msg.get("seq", 0)), bool(msg.get("white_won", false)))
        "promotion_choice": promotion_selected.emit(str(msg.get("kind", "")))
        "error": error_received.emit(str(msg.get("message", "Unknown error")))
