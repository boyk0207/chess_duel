extends CanvasLayer
signal start_game

var net: Node
var panel: PanelContainer
var pages: Control
var home_page: VBoxContainer
var join_page: VBoxContainer
var room_page: VBoxContainer
var code_input: LineEdit
var host_ip_input: LineEdit
var room_code_label: Label
var address_label: Label
var info: Label
var status_label: Label
var ready_button: Button
var start_button: Button
var is_player_ready := false
var mode := "home"

func _button(parent: Node, label: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = label
    b.custom_minimum_size.y = 48
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _label(parent: Node, value: String, size: int = 18) -> Label:
    var l := Label.new()
    l.text = value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", size)
    parent.add_child(l)
    return l

func _page() -> VBoxContainer:
    var p := VBoxContainer.new()
    p.add_theme_constant_override("separation", 14)
    pages.add_child(p)
    return p

func _ready() -> void:
    net = get_node("/root/ChessNetwork")
    var overlay := Control.new()
    overlay.theme = preload("res://scripts/ui_style.gd").make_theme()
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(overlay)
    var dim := ColorRect.new()
    dim.color = Color(0.03, 0.05, 0.09, 0.90)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(dim)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(center)
    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(480, 0)
    center.add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#101a20")
    style.border_color = Color("#806c49")
    style.set_border_width_all(2)
    style.set_corner_radius_all(14)
    style.content_margin_left = 28
    style.content_margin_right = 28
    style.content_margin_top = 25
    style.content_margin_bottom = 25
    panel.add_theme_stylebox_override("panel", style)
    pages = VBoxContainer.new()
    panel.add_child(pages)

    home_page = _page()
    _label(home_page, "LAN MULTIPLAYER", 27)
    _label(home_page, "Host and Join from two computers on the same network")
    _label(home_page, "LAN PvP: Host runs combat; Join controls the second fighter. Same network, two PCs.", 15)
    _button(home_page, "HOST LAN ROOM", _create_room)
    _button(home_page, "JOIN LAN ROOM", func(): _show_page("join"))
    _button(home_page, "BACK TO MENU", _close)

    join_page = _page()
    _label(join_page, "JOIN ROOM", 27)
    _label(join_page, "Enter the Host computer's LAN IP and room code")
    host_ip_input = LineEdit.new()
    host_ip_input.placeholder_text = "Host IP, e.g. 192.168.1.10"
    host_ip_input.custom_minimum_size.y = 50
    join_page.add_child(host_ip_input)
    code_input = LineEdit.new()
    code_input.placeholder_text = "ABC123"
    code_input.max_length = 6
    code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
    code_input.custom_minimum_size.y = 50
    code_input.text_submitted.connect(func(_value: String): _join_room())
    join_page.add_child(code_input)
    _button(join_page, "JOIN", _join_room)
    _button(join_page, "BACK", func(): _show_page("home"))

    room_page = _page()
    _label(room_page, "GAME LOBBY", 27)
    address_label = _label(room_page, "", 17)
    room_code_label = _label(room_page, "------", 42)
    _label(room_page, "Share the Host IP and room code with your friend")
    info = _label(room_page, "Waiting for players...")
    ready_button = _button(room_page, "READY", _toggle_ready)
    start_button = _button(room_page, "START GAME", _start_match)
    _button(room_page, "LEAVE ROOM", _leave_room)

    status_label = _label(pages, "")
    net.state_changed.connect(_on_state)
    net.error_received.connect(_on_error)
    net.match_started.connect(func(_code: String): hide(); start_game.emit())
    _show_page("home")

func _show_page(page: String) -> void:
    mode = page
    home_page.visible = page == "home"
    join_page.visible = page == "join"
    room_page.visible = page == "room"
    status_label.text = ""
    if page == "room":
        address_label.text = "HOST IP: %s:8080" % net.host_address if net.player_id == 1 else "Connected to Host: " + net.server_url
        room_code_label.text = net.room_code
        _on_state(net.state)

func _create_room() -> void:
    status_label.text = "Creating room..."
    net.create_room(int(get_parent().get("stage_idx")))

func _join_room() -> void:
    var code := code_input.text.strip_edges().to_upper()
    if code.length() != 6:
        status_label.text = "Enter a valid 6-character code."
        return
    status_label.text = "Joining room..."
    net.join_room(code, host_ip_input.text)

func _toggle_ready() -> void:
    is_player_ready = not is_player_ready
    net.set_ready(is_player_ready)
    ready_button.text = "CANCEL READY" if is_player_ready else "READY"

func _start_match() -> void:
    if net.player_id == 1:
        net.start_match()

func _on_state(s: Dictionary) -> void:
    if s.is_empty():
        is_player_ready = false
        if mode == "room":
            _show_page("home")
        return
    if mode != "room":
        _show_page("room")
    room_code_label.text = net.room_code
    address_label.text = "HOST IP: %s:8080" % net.host_address if net.player_id == 1 else "Connected to Host: " + net.server_url
    var players: Array = s.get("players", [])
    info.text = "You: Player %d\n" % net.player_id
    for player in players:
        info.text += "Player %d: %s\n" % [int(player.get("id", 0)), "READY" if player.get("ready", false) else "Waiting"]
    if players.size() < 2:
        info.text += "Waiting for another player..."
    var own_ready := false
    var all_ready := players.size() == 2
    for player in players:
        if int(player.get("id", 0)) == net.player_id:
            own_ready = bool(player.get("ready", false))
        if not bool(player.get("ready", false)):
            all_ready = false
    is_player_ready = own_ready
    ready_button.text = "CANCEL READY" if own_ready else "READY"
    start_button.visible = net.player_id == 1
    start_button.disabled = not all_ready
    start_button.text = "START GAME" if all_ready else "WAITING FOR BOTH READY"

func _on_error(message: String) -> void:
    status_label.text = message

func _leave_room() -> void:
    net.leave_room()
    is_player_ready = false
    _show_page("home")

func _close() -> void:
    net.leave_room()
    hide()

func open() -> void:
    is_player_ready = false
    code_input.text = ""
    host_ip_input.text = ""
    _show_page("home")
    show()

func apply_map_theme(stage: int) -> void:
    var t := preload("res://scripts/ui_style.gd").make_theme(stage)
    panel.theme = t
    panel.remove_theme_stylebox_override("panel")
    preload("res://scripts/ui_style.gd").decorate(panel, stage)
