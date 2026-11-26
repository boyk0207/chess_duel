extends Node3D
# Main scene: main menu (orbiting camera), stage select, chess board, duel launcher.

const UIStyle = preload("res://scripts/ui_style.gd")
const Data = preload("res://scripts/data.gd")
const Duel = preload("res://scripts/duel.gd")
const Duel3D = preload("res://scripts/duel_3d.gd")
const BoardScript = preload("res://scripts/board_visual.gd")
const BoardScene = preload("res://scenes/board_visual.tscn")
const CaptureIntroScene = preload("res://scenes/capture_intro.tscn")
const ChessRules = preload("res://scripts/chess_rules.gd")

const CAM_OFFSET := Vector3(0, 7.5, 6.4)

var bv: BoardScript
var board := {}          # Vector2i -> {t, w, node}
var selected = null
var white_turn := true
var mode := "menu"       # menu | intro | board | capture | duel | promotion
var game_over := false
var ai_black := true     # black fighter is computer-controlled in duels
var local_ai := false
var chess_rules = ChessRules.new()
var local_mode_panel: Control
var audio_settings_panel: PanelContainer
var audio_sliders: Dictionary = {}
var keybind_buttons: Dictionary = {}
var rebind_pending := ""
var rebind_status: Label
var piece_animating := false
var capture_progress := 0.0
var capture_intro: Node3D
var capture_hidden: Array[Node3D] = []
var camera_angle := 0.0
var camera_target_angle := 0.0
var ai_wait := false
var ai_rng := RandomNumberGenerator.new()
var stage_idx := 0
var cam: Camera3D
var sun: DirectionalLight3D
var royal_lights: Array[OmniLight3D] = []
var env: Environment
var sky_mat: ProceduralSkyMaterial
var scenery: Node3D
var label: Label
var menu_root: Control
var map_title: Label
var map_fx: Control
var menu_shade: ColorRect
var stage_label: Label
var ai_button: Button
var pending := {}
var online_lobby: CanvasLayer
var online_match := false
var lan_move_queue: Array[Dictionary] = []
var lan_last_seq := 0
var lan_notice := ""
var active_lan_duel: Node
var lan_result_pending := false
var lan_promotion_picker: CanvasLayer
var focus := Vector3.ZERO
var focus_target := Vector3.ZERO
var orbit := 0.6
var blend := 1.0
var blend_speed := 1.6
var blend_from := Vector3.ZERO
var blend_look := Vector3.ZERO
var look_pos := Vector3.ZERO

func _ready() -> void:
	chess_rules.allow_warlord = true
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)
	sky_mat = ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	bv = BoardScene.instantiate()
	add_child(bv)
	for side in [1.0, -1.0]:
		var light := OmniLight3D.new()
		light.light_color = BoardScript.WHITE_ACCENT if side > 0.0 else BoardScript.BLACK_ACCENT
		light.light_energy = 0.55
		light.omni_range = 7.0 * bv.square_size
		light.shadow_enabled = false
		light.position = Vector3(0, bv.surface_y + 3.2 * bv.square_size, side * 3.4 * bv.square_size)
		bv.add_child(light)
		royal_lights.append(light)
	scenery = Node3D.new()
	add_child(scenery)
	cam = Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.current = true
	_build_ui()
	online_lobby = load("res://scripts/network/lobby.gd").new()
	add_child(online_lobby)
	online_lobby.start_game.connect(_on_online_start)
	online_lobby.hide()
	ChessNetwork.move_requested.connect(_on_lan_move_requested)
	ChessNetwork.move_committed.connect(_on_lan_move_committed)
	ChessNetwork.duel_started.connect(_on_lan_duel_started)
	ChessNetwork.duel_input_received.connect(_on_lan_duel_input)
	ChessNetwork.duel_state_received.connect(_on_lan_duel_state)
	ChessNetwork.duel_result_received.connect(_on_lan_duel_result)
	ChessNetwork.promotion_selected.connect(_on_lan_promotion_selected)
	ChessNetwork.error_received.connect(_on_lan_error)
	_apply_stage(stage_idx)
	Sound.start_ambience(self, Vector3.ZERO, "wind", 90.0)
	_new_game()
	_enter_menu(true)

func _center() -> Vector3:
	return bv.global_position + Vector3(0, bv.surface_y, 0)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

# ---------------------------------------------------------------- stage / scenery
func _apply_stage(i: int) -> void:
	var st: Dictionary = Data.STAGES[i]
	sky_mat.sky_top_color = st["sky_top"]
	sky_mat.sky_horizon_color = st["sky_hor"]
	sky_mat.ground_horizon_color = st["sky_hor"]
	var gb: Color = st["sky_top"]
	sky_mat.ground_bottom_color = gb.darkened(0.3)
	env.ambient_light_color = st["ambient"]
	sun.light_color = st["sun"]
	sun.light_energy = float(st["sun_e"])
	for light in royal_lights:
		light.light_energy = 0.45 + 0.12 * float(st["sun_e"])
	bv.apply_stage(st)
	_build_scenery(st)
	if stage_label != null:
		stage_label.text = String(st["name"])
		_apply_map_ui()

func _build_scenery(st: Dictionary) -> void:
	for c in scenery.get_children():
		c.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234 + stage_idx
	var cc: Color = st["cloud"]
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(cc.r, cc.g, cc.b, 0.85)
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 16:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(20.0, 42.0)
		var cl := Node3D.new()
		cl.position = Vector3(sin(ang) * rad, rng.randf_range(-6.0, 8.0), cos(ang) * rad)
		scenery.add_child(cl)
		for j in 4:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 1.0
			sm.height = 2.0
			mi.mesh = sm
			mi.material_override = cmat
			mi.position = Vector3(rng.randf_range(-2.5, 2.5), rng.randf_range(-0.4, 0.4), rng.randf_range(-2.5, 2.5))
			var sc := rng.randf_range(1.5, 3.0)
			mi.scale = Vector3(sc * 1.6, sc * 0.7, sc)
			cl.add_child(mi)
	for i in 7:
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(24.0, 40.0)
		var r := rng.randf_range(2.5, 5.0)
		var isl := Node3D.new()
		isl.position = Vector3(sin(ang) * rad, rng.randf_range(-5.0, 3.0), cos(ang) * rad)
		scenery.add_child(isl)
		var rock := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = r
		rm.bottom_radius = r * 0.15
		rm.height = r * 1.2
		rock.mesh = rm
		rock.material_override = _mat(st["rock"])
		rock.position.y = -r * 0.6
		isl.add_child(rock)
		var gr := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = r * 1.02
		gm.bottom_radius = r
		gm.height = 0.35
		gr.mesh = gm
		gr.material_override = _mat(st["grass"])
		isl.add_child(gr)
	if stage_idx == 0:
		_build_sky_kingdom_details()
	if bool(st["lava"]):
		var lava := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(160, 0.2, 160)
		lava.mesh = bm
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.95, 0.3, 0.05)
		lm.emission_enabled = true
		lm.emission = Color(0.95, 0.3, 0.05)
		lm.emission_energy_multiplier = 2.5
		lava.material_override = lm
		lava.position.y = -16.0
		scenery.add_child(lava)
		var gl := OmniLight3D.new()
		gl.light_color = Color(1.0, 0.45, 0.15)
		gl.light_energy = 6.0
		gl.omni_range = 30.0
		gl.position = Vector3(0, -8, 0)
		scenery.add_child(gl)
	var surrounds = preload("res://scenes/board_environment.tscn").instantiate()
	surrounds.preview_stage = stage_idx
	scenery.add_child(surrounds)

func _sky_mesh(mesh: Mesh, pos: Vector3, color: Color, parent: Node3D, scale_v: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	obj.scale = scale_v
	obj.material_override = _mat(color)
	parent.add_child(obj)
	return obj

func _build_sky_kingdom_details() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261123
	var stone := Color(0.48, 0.46, 0.43)
	var moss := Color(0.24, 0.46, 0.22)
	var leaves := Color(0.18, 0.49, 0.30)
	var trunk := Color(0.35, 0.25, 0.18)
	# Ruined towers and evergreen trees on the surrounding floating islands.
	for n in 10:
		var angle := TAU * float(n) / 10.0 + 0.23
		var radius := rng.randf_range(17.0, 31.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var y := rng.randf_range(-3.0, 0.0)
		var rock := CylinderMesh.new()
		rock.top_radius = rng.randf_range(1.7, 3.0)
		rock.bottom_radius = 0.25
		rock.height = 4.0
		_sky_mesh(rock, Vector3(x, y - 2.0, z), stone, scenery)
		var grass := CylinderMesh.new()
		grass.top_radius = rock.top_radius
		grass.bottom_radius = rock.top_radius * 0.94
		grass.height = 0.3
		_sky_mesh(grass, Vector3(x, y + 0.12, z), moss, scenery)
		if n % 3 == 0:
			var tower := CylinderMesh.new()
			tower.top_radius = 0.7
			tower.bottom_radius = 0.95
			tower.height = 3.6
			_sky_mesh(tower, Vector3(x, y + 1.9, z), stone.lightened(0.2), scenery)
			var roof := CylinderMesh.new()
			roof.top_radius = 0.15
			roof.bottom_radius = 1.25
			roof.height = 1.4
			_sky_mesh(roof, Vector3(x, y + 4.3, z), Color(0.23, 0.34, 0.46), scenery)
		else:
			var stem := CylinderMesh.new()
			stem.top_radius = 0.16
			stem.bottom_radius = 0.25
			stem.height = 1.8
			_sky_mesh(stem, Vector3(x, y + 1.0, z), trunk, scenery)
			var crown := SphereMesh.new()
			_sky_mesh(crown, Vector3(x, y + 2.35, z), leaves, scenery, Vector3(1.15, 1.5, 1.15))
	# Sparse hanging rock fragments provide depth below the islands.
	for n in 24:
		var a := rng.randf_range(0.0, TAU)
		var d := rng.randf_range(14.0, 37.0)
		var shard := SphereMesh.new()
		_sky_mesh(shard, Vector3(cos(a) * d, rng.randf_range(-10.0, -4.0), sin(a) * d), stone, scenery, Vector3(0.3, rng.randf_range(0.45, 1.1), 0.4))

func _cycle_stage(dir: int) -> void:
	stage_idx = wrapi(stage_idx + dir, 0, Data.STAGES.size())
	_apply_stage(stage_idx)

# ---------------------------------------------------------------- UI
func _style(l: Label, size: int) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 56)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(func(): Sound.play_flat("ui_click"))
	b.pressed.connect(cb)
	return b

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	label = Label.new()
	label.position = Vector2(16, 12)
	_style(label, 20)
	label.visible = false
	layer.add_child(label)
	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.theme = UIStyle.make_theme()
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(menu_root)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.055, 0.38)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(shade)
	menu_shade = shade
	map_fx = preload("res://scripts/map_ui_fx.gd").new()
	map_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(map_fx)
	map_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dock := CenterContainer.new()
	dock.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	dock.offset_left = 40
	dock.offset_right = 460
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(dock)
	var frame := PanelContainer.new()
	frame.custom_minimum_size.x = 400
	dock.add_child(frame)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	frame.add_child(vb)
	var title := Label.new()
	title.text = "CHESS DUEL"
	_style(title, 46)
	title.add_theme_color_override("font_color", Color("e8c98c"))
	vb.add_child(title)
	map_title = title
	var sub := Label.new()
	sub.text = "S N A K E S  &  L I Z A R D S"
	_style(sub, 16)
	vb.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	vb.add_child(_menu_button("PLAY LOCAL", _show_local_modes))
	vb.add_child(_menu_button("PLAY LAN (2 PCs)", _open_online))
	vb.add_child(_menu_button("SETTINGS", _show_audio_settings))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	var prev := _menu_button("<", func(): _cycle_stage(-1))
	prev.custom_minimum_size = Vector2(56, 56)
	row.add_child(prev)
	stage_label = Label.new()
	stage_label.custom_minimum_size = Vector2(212, 56)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_style(stage_label, 21)
	row.add_child(stage_label)
	var nxt := _menu_button(">", func(): _cycle_stage(1))
	nxt.custom_minimum_size = Vector2(56, 56)
	row.add_child(nxt)
	ai_button = _menu_button("", _toggle_ai)
	vb.add_child(ai_button)
	vb.add_child(_menu_button("EXIT GAME", func(): get_tree().quit()))
	local_mode_panel = PanelContainer.new()
	local_mode_panel.theme = UIStyle.make_theme()
	local_mode_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	local_mode_panel.custom_minimum_size = Vector2(420, 230)
	var modes := VBoxContainer.new()
	modes.add_theme_constant_override("separation", 12)
	local_mode_panel.add_child(modes)
	modes.add_child(_menu_button("HUMAN VS AI", func(): _start_local(true)))
	modes.add_child(_menu_button("HUMAN VS HUMAN", func(): _start_local(false)))
	modes.add_child(_menu_button("BACK", func(): local_mode_panel.hide()))
	layer.add_child(local_mode_panel)
	local_mode_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	local_mode_panel.hide()
	audio_settings_panel = PanelContainer.new()
	audio_settings_panel.theme = UIStyle.make_theme()
	var settings_content := VBoxContainer.new()
	settings_content.add_theme_constant_override("separation", 10)
	audio_settings_panel.add_child(settings_content)
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_content.add_child(settings_title)
	var settings_tabs := TabContainer.new()
	settings_tabs.custom_minimum_size = Vector2(650, 470)
	settings_content.add_child(settings_tabs)
	var sound_controls := VBoxContainer.new()
	sound_controls.name = "Audio"
	sound_controls.add_theme_constant_override("separation", 12)
	settings_tabs.add_child(sound_controls)
	var sound_title := Label.new()
	sound_title.text = "AUDIO SETTINGS"
	sound_controls.add_child(sound_title)
	for bus_name in ["Master", "Music", "SFX", "UI", "Ambience"]:
		var row_audio := HBoxContainer.new()
		sound_controls.add_child(row_audio)
		var bus_label := Label.new()
		bus_label.text = bus_name
		bus_label.custom_minimum_size.x = 110
		row_audio.add_child(bus_label)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(240, 32)
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = Sound.get_volume(bus_name)
		audio_sliders[bus_name] = slider
		slider.value_changed.connect(func(value: float): Sound.set_volume(bus_name, value))
		row_audio.add_child(slider)
	sound_controls.add_child(_menu_button("RESET AUDIO", _reset_audio))
	var controls_scroll := ScrollContainer.new()
	controls_scroll.name = "Controls"
	controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_tabs.add_child(controls_scroll)
	var controls_list := VBoxContainer.new()
	controls_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_list.add_theme_constant_override("separation", 7)
	controls_scroll.add_child(controls_list)
	var help := Label.new()
	help.text = "Click a binding, then press a key or mouse button. Esc cancels. Conflicts swap."
	controls_list.add_child(help)
	var groups := {
		"3D Arena": ["arena_forward", "arena_back", "arena_left", "arena_right", "arena_jump", "arena_sprint", "arena_dodge", "arena_attack", "arena_block", "arena_special"],
		"2.5D Player 1": ["p1_left", "p1_right", "p1_jump", "p1_block", "p1_attack", "p1_special"],
		"2.5D Player 2": ["p2_left", "p2_right", "p2_jump", "p2_block", "p2_attack", "p2_special"],
	}
	for group_name in groups:
		var group_label := Label.new()
		group_label.text = group_name
		controls_list.add_child(group_label)
		for action in groups[group_name]:
			var row_binding := HBoxContainer.new()
			controls_list.add_child(row_binding)
			var action_label := Label.new()
			action_label.text = action.get_slice("_", 1).capitalize()
			action_label.custom_minimum_size.x = 170
			row_binding.add_child(action_label)
			var binding_button := Button.new()
			binding_button.custom_minimum_size.x = 190
			binding_button.text = Controls.display_name(action)
			binding_button.pressed.connect(_begin_rebind.bind(action))
			row_binding.add_child(binding_button)
			keybind_buttons[action] = binding_button
	rebind_status = Label.new()
	rebind_status.text = ""
	controls_list.add_child(rebind_status)
	controls_list.add_child(_menu_button("RESET CONTROLS", _reset_controls))
	settings_content.add_child(_menu_button("BACK", _close_settings))
	layer.add_child(audio_settings_panel)
	audio_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	audio_settings_panel.hide()
	_refresh_menu()

func _reset_audio() -> void:
	Sound.reset_volumes()
	for bus_name in audio_sliders:
		audio_sliders[bus_name].set_value_no_signal(Sound.get_volume(bus_name))

func _show_audio_settings() -> void:
	audio_settings_panel.show()

func _close_settings() -> void:
	if not rebind_pending.is_empty():
		keybind_buttons[rebind_pending].text = Controls.display_name(rebind_pending)
		rebind_pending = ""
	audio_settings_panel.hide()

func _begin_rebind(action: String) -> void:
	if not rebind_pending.is_empty():
		keybind_buttons[rebind_pending].text = Controls.display_name(rebind_pending)
	rebind_pending = action
	keybind_buttons[action].text = "Press a key..."
	rebind_status.text = "Press a key or mouse button for " + action.replace("_", " ")

func _reset_controls() -> void:
	rebind_pending = ""
	Controls.reset_bindings()
	for action in keybind_buttons:
		keybind_buttons[action].text = Controls.display_name(action)
	rebind_status.text = "Default controls restored."

func _input(event: InputEvent) -> void:
	if rebind_pending.is_empty(): return
	var kind := ""
	var code := 0
	if event is InputEventKey:
		if not event.pressed or event.echo: return
		if event.keycode == KEY_ESCAPE:
			keybind_buttons[rebind_pending].text = Controls.display_name(rebind_pending)
			rebind_pending = ""
			rebind_status.text = "Binding cancelled."
			get_viewport().set_input_as_handled()
			return
		kind = "key"
		code = event.physical_keycode
	elif event is InputEventMouseButton:
		if not event.pressed: return
		kind = "mouse"
		code = event.button_index
	else:
		return
	get_viewport().set_input_as_handled()
	if code <= 0: return
	var action := rebind_pending
	var swapped: String = Controls.rebind(action, kind, code)
	if swapped == "INVALID":
		rebind_status.text = "That key or button is reserved."
		return
	rebind_pending = ""
	keybind_buttons[action].text = Controls.display_name(action)
	if not swapped.is_empty(): keybind_buttons[swapped].text = Controls.display_name(swapped)
	rebind_status.text = "Saved " + action.replace("_", " ") + ("; swapped " + swapped.replace("_", " ") if not swapped.is_empty() else "")

func _apply_map_ui() -> void:
	var theme_now := UIStyle.make_theme(stage_idx)
	menu_root.theme = theme_now
	local_mode_panel.theme = theme_now
	audio_settings_panel.theme = theme_now
	map_fx.set("stage", stage_idx)
	var base: Color = [Color("639c50"), Color("9c1808"), Color("9b6333"), Color("b6984b"), Color("529bc9")][stage_idx]
	var bright: Color = [Color("eaffb9"), Color("fff078"), Color("ffe2a4"), Color("fffbe3"), Color("f2ffff")][stage_idx]
	menu_shade.color = Color(base.darkened(0.8), 0.28)
	UIStyle.decorate(menu_root, stage_idx)
	UIStyle.decorate(local_mode_panel, stage_idx)
	if is_instance_valid(online_lobby):
		online_lobby.call("apply_map_theme", stage_idx)

func _show_local_modes() -> void:
	local_mode_panel.show()

func _start_local(vs_ai: bool) -> void:
	local_ai = vs_ai
	ai_black = vs_ai
	local_mode_panel.hide()
	_on_play()

func _refresh_board_status() -> void:
	white_turn = chess_rules.white_turn
	game_over = not chess_rules.result.is_empty()
	bv.clear_king_warning()
	for side in [white_turn, not white_turn]:
		if chess_rules.in_check(side):
			var king: Vector2i = chess_rules._king(side, chess_rules.pieces)
			bv.set_king_warning(king, chess_rules.result_reason == "checkmate")
			break
	_update_label()

func _refresh_menu() -> void:
	if ai_button != null:
		ai_button.text = "Black duel fighter: " + ("AI" if ai_black else "Human")

func _toggle_ai() -> void:
	ai_black = not ai_black
	_refresh_menu()
	_update_label()

func _update_label() -> void:
	if online_match:
		label.text = "LAN PvP | %s turn | You: %s | [Esc] menu%s" % ["White" if white_turn else "Black", "White" if ChessNetwork.player_id == 1 else "Black", " | " + lan_notice if not lan_notice.is_empty() else ""]
		return
	if game_over:
		label.text = "CHESS DUEL | %s — %s | [Esc] menu" % ["Draw" if chess_rules.result == "draw" else ("White wins" if chess_rules.result == "white" else "Black wins"), chess_rules.result_reason]
		return
	label.text = "%s turn%s | Legal move or capture starts a duel | [T] Black duel AI: %s | [Esc] menu" % ["White" if white_turn else "Black", " — CHECK" if chess_rules.in_check(white_turn) else "", "ON" if ai_black else "OFF"]

# ---------------------------------------------------------------- flow
func _start_blend(speed: float) -> void:
	blend = 0.0
	blend_speed = speed
	blend_from = cam.position
	blend_look = look_pos

func _enter_menu(first: bool = false) -> void:
	if online_match: ChessNetwork.leave_room()
	online_match = false
	lan_move_queue.clear()
	active_lan_duel = null
	mode = "menu"
	menu_root.visible = true
	if local_mode_panel != null:
		local_mode_panel.hide()
	audio_settings_panel.hide()
	label.visible = false
	Sound.set_music("menu")
	_select(null)
	if first:
		blend = 1.0
		look_pos = _center()
	else:
		_start_blend(1.6)

func _open_online() -> void:
	online_lobby.open()

func _on_online_start() -> void:
	local_ai = false
	ai_black = false
	stage_idx = clampi(ChessNetwork.match_stage, 0, Data.STAGES.size() - 1)
	_apply_stage(stage_idx)
	_on_play()
	online_match = true
	lan_move_queue.clear()
	lan_last_seq = 0
	lan_notice = ""
	camera_target_angle = 0.0 if ChessNetwork.player_id == 1 else PI
	_update_label()

func _on_lan_move_requested(player: int, from: Vector2i, to: Vector2i) -> void:
	if ChessNetwork.player_id != 1: return
	if not online_match or mode != "board" or piece_animating or game_over or not board.has(from) or board[from].w != white_turn or player != (1 if white_turn else 2) or to not in _moves(from):
		ChessNetwork.reject_move("Invalid move or wrong turn")
		return
	ChessNetwork.accept_move(_is_capture(from, to), board[from].t == "P" and to.y in [0, 7])

func _on_lan_move_committed(seq: int, _player: int, from: Vector2i, to: Vector2i) -> void:
	if not online_match or seq <= lan_last_seq: return
	lan_last_seq = seq
	lan_move_queue.append({"from": from, "to": to})

func _on_lan_duel_started(seq: int, _player: int, from: Vector2i, to: Vector2i) -> void:
	if not online_match or seq <= lan_last_seq: return
	lan_last_seq = seq
	lan_move_queue.append({"from": from, "to": to, "capture": true})

func _on_lan_duel_input(input: Dictionary) -> void:
	if ChessNetwork.player_id == 1 and is_instance_valid(active_lan_duel):
		active_lan_duel.lan_receive_input(input)

func _on_lan_duel_state(state: Dictionary) -> void:
	if ChessNetwork.player_id == 2 and not lan_result_pending and is_instance_valid(active_lan_duel) and not active_lan_duel.is_queued_for_deletion():
		active_lan_duel.lan_apply_state(state)

func _on_lan_duel_result(_seq: int, white_won: bool) -> void:
	if not online_match or lan_result_pending or not is_instance_valid(active_lan_duel) or active_lan_duel.is_queued_for_deletion(): return
	lan_result_pending = true
	var duel := active_lan_duel
	if ChessNetwork.player_id == 2:
		duel.lan_show_result(white_won)
		var remaining: float = duel.lan_result_remaining()
		if remaining > 0.0: await get_tree().create_timer(remaining).timeout
		if not is_inside_tree() or not online_match or active_lan_duel != duel or mode != "duel": return
	active_lan_duel = null
	lan_result_pending = false
	_resolve_duel_finished(white_won, duel)

func _on_lan_promotion_selected(kind: String) -> void:
	if not online_match or mode != "promotion" or kind not in ["N", "B", "R", "Q", "W"]: return
	if is_instance_valid(lan_promotion_picker): lan_promotion_picker.queue_free()
	lan_promotion_picker = null
	mode = "board"
	if _apply_move(pending["from"], pending["to"], kind): _end_turn()

func _on_lan_error(message: String) -> void:
	if not online_match: return
	if message.contains("left the LAN room") or message.begins_with("Disconnected from Host"):
		_abort_lan_match.call_deferred(message)
		return
	lan_notice = message
	_update_label()

func _abort_lan_match(message: String) -> void:
	if not online_match: return
	lan_result_pending = false
	_clear_capture_intro()
	if is_instance_valid(active_lan_duel): active_lan_duel.queue_free()
	if is_instance_valid(lan_promotion_picker): lan_promotion_picker.queue_free()
	lan_promotion_picker = null
	active_lan_duel = null
	scenery.show()
	bv.visible = true
	sun.visible = true
	cam.make_current()
	_enter_menu()
	online_lobby.open()
	online_lobby.status_label.text = message

func _on_play() -> void:
	_new_game()
	menu_root.visible = false
	mode = "intro"
	Sound.set_music("board")
	_start_blend(2.4)

func _process(delta: float) -> void:
	if online_match and mode == "board" and not piece_animating and not lan_move_queue.is_empty():
		var move: Dictionary = lan_move_queue.pop_front()
		if bool(move.get("capture", false)): _start_duel(move["from"], move["to"])
		else: _animate_move(move["from"], move["to"])
	scenery.rotation.y += delta * 0.015
	var c := _center()
	var sq := bv.square_size
	camera_angle = lerp_angle(camera_angle, camera_target_angle, clampf(delta * 2.2, 0.0, 1.0))
	if mode == "menu":
		orbit += delta * 0.12
		var tpos := c + Vector3(sin(orbit) * 15.0 * sq, (6.0 + sin(orbit * 0.7) * 1.4) * sq, cos(orbit) * 15.0 * sq)
		var tlook := c + Vector3(0, 0.3, 0)
		if blend < 1.0:
			blend = minf(blend + delta / blend_speed, 1.0)
			var u := smoothstep(0.0, 1.0, blend)
			cam.position = blend_from.lerp(tpos, u)
			look_pos = blend_look.lerp(tlook, u)
		else:
			cam.position = tpos
			look_pos = tlook
		cam.look_at(look_pos, Vector3.UP)
	elif mode == "intro":
		blend = minf(blend + delta / blend_speed, 1.0)
		var u2 := smoothstep(0.0, 1.0, blend)
		var gpos := c + Vector3(sin(camera_angle) * CAM_OFFSET.z, CAM_OFFSET.y, cos(camera_angle) * CAM_OFFSET.z) * sq
		var glook := c + Vector3(0, 0, 0.3 * sq)
		cam.position = blend_from.lerp(gpos, u2)
		look_pos = blend_look.lerp(glook, u2)
		cam.look_at(look_pos, Vector3.UP)
		if blend >= 1.0:
			mode = "board"
			label.visible = true
			focus = Vector3.ZERO
	elif mode == "board":
		focus = focus.lerp(focus_target, clampf(delta * 2.5, 0.0, 1.0))
		cam.position = c + focus + Vector3(sin(camera_angle) * CAM_OFFSET.z, CAM_OFFSET.y, cos(camera_angle) * CAM_OFFSET.z) * sq
		look_pos = c + focus + Vector3(0, 0, 0.3 * sq)
		cam.look_at(look_pos, Vector3.UP)
	elif mode == "capture":
		focus = focus.lerp(focus_target, clampf(delta * 5.0, 0.0, 1.0))
		var zoom := lerpf(1.0, 0.46, capture_progress)
		cam.position = c + focus + Vector3(sin(camera_angle) * CAM_OFFSET.z, CAM_OFFSET.y, cos(camera_angle) * CAM_OFFSET.z) * sq * zoom
		look_pos = c + focus + Vector3(0, 0.25 * sq, 0)
		cam.look_at(look_pos, Vector3.UP)

# Camera glides a little toward the square the action is on.
func _focus_on(sqr: Vector2i) -> void:
	var p := bv.square_pos(sqr)
	focus_target = Vector3(p.x * 0.45, 0, p.z * 0.3)

# ---------------------------------------------------------------- board
func _new_game() -> void:
	_clear_capture_intro()
	lan_result_pending = false
	chess_rules.reset()
	for k in board.keys():
		board[k].node.queue_free()
	board.clear()
	selected = null
	bv.clear_all_marks()
	white_turn = true
	camera_angle = 0.0
	camera_target_angle = 0.0
	piece_animating = false
	ai_wait = false
	game_over = false
	focus = Vector3.ZERO
	focus_target = Vector3.ZERO
	_setup_pieces()
	_refresh_board_status()

func _inb(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < 8 and p.y >= 0 and p.y < 8

# White pieces face -Z (toward black), black pieces are turned around.
func _make_piece_node(t: String, w: bool) -> Node3D:
	var n := Node3D.new()
	var ps := bv.piece_scale
	var m := Data.make_model(t, float(Data.BOARD_H[t]) * ps, Color(1, 1, 1), not w)
	m.rotation.y = 0.0 if w else PI
	n.add_child(m)
	# glowing ring shows the team (cyan = white, red = black)
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.4 * ps
	cm.bottom_radius = 0.4 * ps
	cm.height = 0.03
	ring.mesh = cm
	var rm := StandardMaterial3D.new()
	var rc := Color(0.35, 0.9, 1.0) if w else Color(1.0, 0.3, 0.3)
	rm.albedo_color = rc
	rm.emission_enabled = true
	rm.emission = rc
	rm.emission_energy_multiplier = 1.5
	ring.material_override = rm
	ring.position.y = 0.02
	n.add_child(ring)
	return n

func _add_piece(p: Vector2i, t: String, w: bool) -> void:
	var node := _make_piece_node(t, w)
	node.position = bv.square_pos(p)
	bv.pieces_root().add_child(node)
	board[p] = {"t": t, "w": w, "node": node}

func _setup_pieces() -> void:
	var back := ["R", "N", "B", "Q", "K", "B", "N", "R"]
	for x in 8:
		_add_piece(Vector2i(x, 0), back[x], true)
		_add_piece(Vector2i(x, 1), "P", true)
		_add_piece(Vector2i(x, 6), "P", false)
		_add_piece(Vector2i(x, 7), back[x], false)

func _moves(p: Vector2i) -> Array:
	var res: Array = []
	if not board.has(p) or board[p].w != white_turn: return res
	for move in chess_rules.legal_moves_from(p):
		if move.to not in res: res.append(move.to)
	return res

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and mode == "board":
			_enter_menu()
			return
		if event.keycode == KEY_T and not online_match and (mode == "board" or mode == "menu"):
			_toggle_ai()
	if mode != "board" or game_over or piece_animating or (local_ai and not white_turn):
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(event.position)

func _available_targets(p: Vector2i) -> Array:
	return _moves(p)

func _is_capture(from: Vector2i, to: Vector2i) -> bool:
	var move: Dictionary = chess_rules.find_move(from, to)
	return not move.is_empty() and (board.has(to) or bool(move.ep))

func _click(mpos: Vector2) -> void:
	if online_match and ChessNetwork.player_id != (1 if white_turn else 2):
		return
	var o := bv.to_local(cam.project_ray_origin(mpos))
	var d := bv.global_transform.basis.inverse() * cam.project_ray_normal(mpos)
	if absf(d.y) < 0.0001:
		return
	var t := (bv.surface_y - o.y) / d.y
	var hit := o + d * t
	var sq := Vector2i(floori(hit.x / bv.square_size + 4.0), floori(4.0 - hit.z / bv.square_size))
	if not _inb(sq):
		return
	if selected != null and sq in _available_targets(selected):
		var from: Vector2i = selected
		_select(null)
		_focus_on(sq)
		if online_match:
			ChessNetwork.request_move(from, sq)
			return
		if _is_capture(from, sq):
			_start_duel(from, sq)
		else:
			_animate_move(from, sq)
	elif board.has(sq) and board[sq].w == white_turn:
		_select(sq)
	else:
		_select(null)

func _select(p) -> void:
	bv.clear_highlights()
	selected = p
	if p != null:
		Sound.play_flat("board_select")
		_focus_on(p)
		bv.show_selected(p, bool(board[p].w))
		for m in _available_targets(p):
			if _is_capture(p, m):
				bv.show_capture(m)
			else:
				bv.show_legal_move(m)

func _sync_rule_visual() -> void:
	for pos in board.keys():
		if not chess_rules.pieces.has(pos) or board[pos].t != chess_rules.pieces[pos].t or board[pos].w != chess_rules.pieces[pos].w:
			board[pos].node.queue_free()
			board.erase(pos)
	for pos in chess_rules.pieces:
		if not board.has(pos):
			_add_piece(pos, chess_rules.pieces[pos].t, chess_rules.pieces[pos].w)
		else:
			board[pos].node.position = bv.square_pos(pos)

func _apply_move(from: Vector2i, to: Vector2i, promotion: String = "Q") -> bool:
	var captured := _is_capture(from, to)
	if not chess_rules.play_move(from, to, promotion): return false
	_sync_rule_visual()
	bv.mark_last_move(from, to)
	Sound.play_flat("board_capture" if captured else "board_move")
	_refresh_board_status()
	return true

func _on_promotion_chosen(kind: String, from: Vector2i, to: Vector2i, picker: CanvasLayer) -> void:
	if mode != "promotion" or not board.has(from): return
	picker.queue_free()
	mode = "board"
	if _apply_move(from, to, kind): _end_turn()

func _complete_board_move(from: Vector2i, to: Vector2i) -> void:
	if board[from].t == "P" and to.y in [0, 7]:
		if online_match:
			pending = {"from": from, "to": to}
			mode = "promotion"
			if ChessNetwork.player_id == (1 if board[from].w else 2):
				var picker = load("res://scripts/promotion_picker.gd").new()
				picker.name = "PromotionPicker"
				picker.configure(stage_idx, bool(board[from].w))
				add_child(picker)
				lan_promotion_picker = picker
				picker.chosen.connect(func(kind: String): ChessNetwork.choose_promotion(kind))
			return
		if local_ai and not board[from].w:
			if _apply_move(from, to, "W"): _end_turn()
		else:
			mode = "promotion"
			var picker = load("res://scripts/promotion_picker.gd").new()
			picker.name = "PromotionPicker"
			picker.configure(stage_idx, bool(board[from].w))
			add_child(picker)
			picker.chosen.connect(_on_promotion_chosen.bind(from, to, picker))
	else:
		if _apply_move(from, to): _end_turn()

func _animate_move(from: Vector2i, to: Vector2i) -> void:
	var move: Dictionary = chess_rules.find_move(from, to)
	if piece_animating or move.is_empty() or _is_capture(from, to):
		return
	piece_animating = true
	var moving: Node3D = board[from].node
	var origin := moving.position
	var dest := bv.square_pos(to)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(moving, "position", (origin + dest) * 0.5 + Vector3.UP * bv.square_size * 0.35, 0.24)
	tween.tween_property(moving, "position", dest, 0.26)
	if not String(move.castle).is_empty():
		var rook_from := Vector2i(7 if to.x == 6 else 0, from.y)
		var rook_to := Vector2i(5 if to.x == 6 else 3, from.y)
		var rook_tween := create_tween()
		rook_tween.tween_property(board[rook_from].node, "position", bv.square_pos(rook_to), 0.50)
	await tween.finished
	if mode != "board":
		moving.position = origin
		piece_animating = false
		return
	piece_animating = false
	_complete_board_move(from, to)

func _end_turn() -> void:
	_refresh_board_status()
	camera_target_angle = (0.0 if ChessNetwork.player_id == 1 else PI) if online_match else (0.0 if local_ai or white_turn else PI)
	focus_target = Vector3.ZERO
	if local_ai and not white_turn and not game_over and mode == "board":
		_ai_turn()

func _ai_turn() -> void:
	if ai_wait:
		return
	ai_wait = true
	await get_tree().create_timer(0.8).timeout
	if mode != "board" or game_over or white_turn or not local_ai:
		ai_wait = false
		return
	var options: Array = []
	for pos in board.keys():
		if not board.has(pos) or board[pos].w:
			continue
		for target in _moves(pos):
			var score := ai_rng.randf_range(0.0, 0.4)
			if _is_capture(pos, target):
				var values := {"P": 1.0, "N": 3.0, "B": 3.0, "R": 5.0, "Q": 9.0, "K": 50.0, "W": 12.0}
				var victim: Vector2i = target if board.has(target) else Vector2i(target.x, pos.y)
				score += float(values.get(board[victim].t, 1.0)) + 2.0
			score += 0.1 * (3.5 - absf(float(target.x) - 3.5))
			options.append({"from": pos, "to": target, "score": score})
	ai_wait = false
	if options.is_empty():
		return
	options.sort_custom(func(a, b): return a["score"] > b["score"])
	var choice: Dictionary = options[0]
	var from: Vector2i = choice["from"]
	var to: Vector2i = choice["to"]
	_focus_on(to)
	if _is_capture(from, to):
		_start_duel(from, to)
	else:
		_animate_move(from, to)

# ---------------------------------------------------------------- duel
func _clear_capture_intro() -> void:
	if is_instance_valid(capture_intro):
		capture_intro.hide()
		capture_intro.queue_free()
	capture_intro = null
	for node in capture_hidden:
		if is_instance_valid(node): node.show()
	capture_hidden.clear()

func _start_duel(from: Vector2i, to: Vector2i) -> void:
	if not _is_capture(from, to): return
	var move: Dictionary = chess_rules.find_move(from, to)
	var defender_pos := Vector2i(to.x, from.y) if bool(move.ep) else to
	mode = "capture"
	capture_progress = 0.0
	bv.clear_highlights()
	bv.show_selected(from, bool(board[from].w))
	bv.show_capture(to)
	_focus_on(to)
	var attacker_piece: Dictionary = board[from]
	var defender_piece: Dictionary = board[defender_pos]
	var cinematic: Node3D = CaptureIntroScene.instantiate()
	bv.pieces_root().add_child(cinematic)
	capture_intro = cinematic
	capture_hidden = [attacker_piece.node, defender_piece.node]
	for node in capture_hidden: node.hide()
	var toward_camera := Vector3(sin(camera_angle), 0.0, cos(camera_angle))
	cinematic.call("configure", str(attacker_piece.t), bool(attacker_piece.w), str(defender_piece.t), bool(defender_piece.w), bv.square_pos(from), bv.square_pos(defender_pos), bv.piece_scale, toward_camera, Data.STAGES[stage_idx]["frame"])
	Sound.play_flat("board_capture")
	var transition := create_tween()
	transition.tween_property(self, "capture_progress", 1.0, 2.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await transition.finished
	_clear_capture_intro()
	if not is_inside_tree() or mode != "capture": return
	mode = "duel"
	capture_progress = 0.0
	Sound.stop_ambience(self)
	Sound.set_battle_intensity(0.0)
	Sound.set_music("island_battle" if stage_idx == 0 else "battle")
	pending = {"from": from, "to": to, "defender": defender_pos}
	bv.visible = false
	sun.visible = false
	label.visible = false
	var a: Dictionary = board[from]
	var d: Dictionary = board[defender_pos]
	var white_kind: String = a.t if a.w else d.t
	var black_kind: String = d.t if a.w else a.t
	var use_3d := stage_idx == 0 and (ai_black or online_match)
	var dn = Duel3D.new() if use_3d else Duel.new()
	if online_match:
		dn.lan_role = ChessNetwork.player_id
		active_lan_duel = dn
		lan_result_pending = false
		dn.lan_input_ready.connect(ChessNetwork.send_duel_input)
		dn.lan_state_ready.connect(ChessNetwork.send_duel_state)
	if use_3d:
		scenery.hide()
	add_child(dn)
	dn.setup(white_kind, black_kind, ai_black, Data.STAGES[stage_idx])
	dn.finished.connect(_on_duel_finished.bind(dn))

func _on_duel_finished(left_won: bool, dn: Node) -> void:
	if online_match:
		if ChessNetwork.player_id == 1 and dn == active_lan_duel:
			ChessNetwork.send_duel_result(left_won)
		return
	_resolve_duel_finished(left_won, dn)

func _resolve_duel_finished(left_won: bool, dn: Node) -> void:
	dn.queue_free()
	scenery.show()
	bv.visible = true
	sun.visible = true
	label.visible = true
	cam.make_current()
	mode = "board"
	bv.clear_highlights()
	Sound.set_music("board")
	Sound.start_ambience(self, Vector3.ZERO, "wind", 90.0)
	var from: Vector2i = pending["from"]
	var to: Vector2i = pending["to"]
	var a: Dictionary = board[from]
	var attacker_won: bool = left_won if a.w else not left_won
	if attacker_won:
		_complete_board_move(from, to)
	else:
		if chess_rules.resolve_failed_capture(from, to):
			_sync_rule_visual()
			bv.mark_last_move(from, to)
			_end_turn()
