extends Node3D
signal finished(left_won: bool)
signal lan_input_ready(input: Dictionary)
signal lan_state_ready(state: Dictionary)
const Data = preload("res://scripts/data.gd")
const Rig = preload("res://scripts/rig_factory.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const FloatingVisuals = preload("res://scripts/floating_visuals.gd")
const WindVortex = preload("res://scripts/wind_vortex.gd")
const LOOK_DOWN_MAX := 80.0
const BOMB_RADIUS := 2.4
const ISLAND_COLORS := [Color("d8ae4f"), Color("819092"), Color("55d6e5"), Color("62bd68")]
var heal_ready_at := 0.0
var heal_ring: MeshInstance3D
var heal_marks: Array[MeshInstance3D] = []
var crystal_on_east := false
var crystal_icon: Sprite3D
var shard_icons: Array[Sprite3D] = []
var shard_icon_time: Array[float] = [0.0, 0.0]
var shard_icon_kind: Array[int] = [0, 0]
var shard_popup_seq: Array[int] = [0, 0]
var lan_shard_seen_seq: Array[int] = [0, 0]
const SHARD_POPUP_DURATION := 2.0
const SHARD_TEXTURES := [
	preload("res://assets/arena/shards/power.png"),
	preload("res://assets/arena/shards/speed.png"),
	preload("res://assets/arena/shards/heal.png"),
	preload("res://assets/arena/shards/special.png"),
	preload("res://assets/arena/shards/knockback.png")
]
var visuals: FloatingVisuals
var bodies: Array[CharacterBody3D] = []
var models: Array[Node3D] = []
var stats: Array[Dictionary] = []
var hp: Array[float] = []
var cooldown: Array[float] = [0.0, 0.0]
var special: Array[float] = [0.0, 0.0]
var bars: Array[ProgressBar] = []
var camera: Camera3D
var yaw := 0.0
var pitch := -0.22
var over := false
var status: Label
var result_banner: Label
var pads: Array[Vector3] = [Vector3(-6,0,0), Vector3(6,0,0)]
var ai_jump := 0.0
var elapsed := 0.0
var arena_parts: Array[Node3D] = []
var bridges: Array[Node3D] = []
var edge_parts: Array[Node3D] = []
var arena_label: Label
var boost_timer := 10.0
var crystal: MeshInstance3D
var boost: Array[float] = [0.0, 0.0]
var speed_boost: Array[float] = [0.0, 0.0]
var push_boost: Array[float] = [0.0, 0.0]
var crystal_kind := 0
const CRYSTAL_COLORS := [Color.GOLD, Color.DODGER_BLUE, Color.LIME_GREEN, Color.MEDIUM_PURPLE, Color.TOMATO]
const ISLAND_DIRS := [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
var collapses: Array[Dictionary] = []
var bridge_info: Array[Dictionary] = []
var covers: Array[Dictionary] = []
var winds: Array[Dictionary] = []
var ferry: AnimatableBody3D
var ferry_x := 10.0
var ferry_direction := 1.0
var next_lightning := 35.0
var lightning_warning: MeshInstance3D
var lightning_at := 0.0
var storm_amount := 0.0
var storm_visual_at := 30.0
var sun: DirectionalLight3D
var arena_rng := RandomNumberGenerator.new()
var crystal_cycle: Array[int] = []
var danger_text := ""
var ai_retreat := false
var lan_role := 0 # 0 local, 1 authoritative Host, 2 Join replica
var lan_remote_input: Dictionary = {}
var lan_remote_age := 1.0
var lan_snapshot_clock := 0.0
var lan_input_clock := 0.0
var lan_attack_queued := false
var lan_special_queued := false
var lan_attack_buffer := 0.0
var lan_special_buffer := 0.0
var lan_dodge_cd := 0.0
var lan_dodge_time := 0.0
var lan_dodge_dir := Vector3.ZERO
var lan_dodge_clip := "DodgeForward"
var lan_guard_age := 1.0
var lan_projectile_meshes: Array[Node3D] = []
var lan_fx_sequence := 0
var lan_fx_seen := 0
var lan_fx_recent: Array[Array] = []
var lan_bomb_trail_clock := 0.0
var lan_target_positions: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var lan_target_velocities: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var lan_has_snapshot := false
var lan_snapshot_age := 0.0
var lan_state_samples := 0
var lan_state_rate := 0
var lan_stats_clock := 0.0
var collapse_shake := 0.0
var dodge_cd := 0.0
var dodge_time := 0.0
var dodge_dir := Vector3.ZERO
var guard_age := 1.0
const IslandMesh = preload("res://assets/arena/Flat.glb")
const SmallMesh = preload("res://assets/arena/Small.glb")
const BridgeMesh = preload("res://assets/arena/Bridge_Curved.glb")
const BRIDGE_PITCH := 3.3 / 17.0
const BRIDGE_SAG := 0.42
const TreeMesh = preload("res://assets/arena/tree.glb")
const FlowerMesh = preload("res://assets/arena/flowers.glb")
var flashes: Array[float] = [0.0, 0.0]
var knockback: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var cross: Label
var shake := 0.0
var guarding: Array[bool] = [false, false]
var shields: Array[MeshInstance3D] = []
var projectiles: Array[Dictionary] = []
var feedback := ""
var feedback_time := 0.0
var attack_queued := false
var special_queued := false
var attack_buffer := 0.0
var special_buffer := 0.0
var aim := Vector3.FORWARD
var kinds: Array[String] = []
const FireballFX = preload("res://addons/pyrolux_fx/presets/3d/fireball.tscn")
const MagmaBomb = preload("res://assets/magma_bomb.glb")
var held_bombs: Array[Node3D] = []
var pawn_weapons: Array[Node3D] = []
var spear_recovery: Array[float] = [0.0, 0.0]
var pawn_pending: Array[Dictionary] = [{}, {}]
var pose_time: Array[float] = [0.0, 0.0]
var pose_length: Array[float] = [0.0, 0.0]
var pose_power: Array[bool] = [false, false]
var gait: Array[float] = [0.0, 0.0]
var base_scales: Array[Vector3] = []
const SPECIES := {"P": 0, "N": 1, "B": 2, "R": 3, "Q": 4, "K": 5, "W": 6}
# gait rate, bob height, forward lean, lateral sway, guard crouch, dodge roll
const MOTION := {
	"P": [14.0, 0.10, -0.15, 0.09, 0.83, 1.12],
	"N": [17.0, 0.065, -0.10, 0.04, 0.70, 0.32],
	"B": [9.0, 0.045, -0.06, 0.12, 0.90, 0.36],
	"R": [8.0, 0.13, -0.19, 0.11, 0.75, 0.95],
	"Q": [11.0, 0.035, -0.09, 0.13, 0.88, 0.28],
	"K": [8.0, 0.055, -0.08, 0.08, 0.82, 0.38],
	"W": [15.0, 0.11, -0.20, 0.10, 0.78, 0.65]
}
const FX_COLORS := {
	"P": Color(0.95,0.95,0.85), "N": Color(0.55,0.90,0.26),
	"B": Color(1.0,0.38,0.12), "R": Color(0.82,0.48,0.25),
	"Q": Color(0.75,0.30,1.0), "K": Color(0.32,0.78,1.0), "W": Color(1.0,0.76,0.18)
}
var rig_players: Array[AnimationPlayer] = []
var rig_states: Array[String] = ["", ""]
var ground_previous: Array[bool] = [false, false]
var ground_known: Array[bool] = [false, false]
var jump_pose: Array[float] = [0.0, 0.0]
var landing_pose: Array[float] = [0.0, 0.0]
var perfect_pose: Array[float] = [0.0, 0.0]
var step_fx: Array[float] = [0.0, 0.0]
var end_clock := 0.0
var end_winner := -1
var polish: CombatFX
var hitstop_remaining := 0.0
var paused_rigs := false
var dodge_clip := "DodgeForward"
var combo_step: Array[int] = [0, 0]
var combo_window: Array[float] = [0.0, 0.0]
var combo_connected: Array[bool] = [false, false]
var combo_active: Array[int] = [1, 1]
var counter_time: Array[float] = [0.0, 0.0]
var victory_origin := Vector3.ZERO
var victory_start := Vector3.ZERO
var victory_angle := 0.0
var victory_emitted := false
var last_damage_was_finisher := false
const HIT_PAUSE := {"P":0.035,"N":0.042,"B":0.038,"R":0.065,"Q":0.038,"K":0.058,"W":0.045}
const FOOT_INTERVAL := {"P":0.22,"N":0.17,"B":0.34,"R":0.36,"Q":0.29,"K":0.34,"W":0.20}
# Bone-local endpoints from the separated OBJ geometry; fallback bones for unarmed pieces.
const TRAIL_BONES := {
	"P": [["WeaponJoint",Vector3(0.013,-0.53,0.147),Vector3(0.032,0.451,-0.004)]],
	"N": [["Head",Vector3.ZERO,Vector3(0,0,-0.30)]],
	"B": [["WeaponJoint",Vector3(0.001,-0.384,0.048),Vector3(0,0.275,-0.036)]],
	"R": [["Head",Vector3.ZERO,Vector3(0,0,-0.24)]],
	"Q": [["TailTip",Vector3.ZERO,Vector3(0,0,0.28)]],
	"K": [["Head",Vector3.ZERO,Vector3(0,0,-0.25)]],
	"W": [["WeaponJoint",Vector3(-0.005,-0.001,-0.005),Vector3(0.003,0.317,0.003)],["OffhandJoint",Vector3(-0.005,0.005,0.001),Vector3(0.003,-0.003,-0.317)]]
}
const POSES := {
	"P": Vector3(0.38, 0.12, 0.22), "N": Vector3(0.58, 0.08, 0.12),
	"B": Vector3(0.24, 0.30, 0.36), "R": Vector3(0.48, 0.18, 0.22),
	"Q": Vector3(0.34, 0.38, 0.32), "K": Vector3(0.55, 0.22, 0.38),
	"W": Vector3(0.48, 0.42, 0.42)
}
func setup(w: String, b: String, _ai: bool, stage: Dictionary) -> void:
	var light := DirectionalLight3D.new()
	sun = light
	arena_rng.randomize()
	add_child(light)
	visuals = FloatingVisuals.new()
	add_child(visuals)
	visuals.setup_sun(light)
	visuals.build_backdrop()
	var grass: Color = stage["grass"]
	var rock: Color = stage["rock"]
	build_islands(grass, rock)
	get_node("/root/Sound").start_ambience(self, Vector3.ZERO, "wind", 85.0)
	for waterfall_pos in [Vector3(14, -2, 0), Vector3(-14, -2, 0), Vector3(0, -2, 14), Vector3(0, -2, -14)]:
		get_node("/root/Sound").start_ambience(self, waterfall_pos, "waterfall", 30.0)
	polish = CombatFX.new()
	add_child(polish)
	spawn(w,true,Vector3(0,0.2,7))
	spawn(b,false,Vector3(0,0.2,-7))
	camera = Camera3D.new()
	camera.fov = 75
	camera.environment = visuals.make_environment()
	camera.far = 180.0
	add_child(camera)
	camera.current = true
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := VBoxContainer.new()
	panel.position = Vector2(24,24)
	hud.add_child(panel)
	for i in range(2):
		var label := Label.new()
		label.text = (("YOU: " if i == lan_role - 1 else "RIVAL: ") if lan_role > 0 else ("YOU: " if i == 0 else "AI: ")) + Data.NAMES[[w,b][i]]
		panel.add_child(label)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(280,22)
		bar.max_value = hp[i]
		bar.value = hp[i]
		panel.add_child(bar)
		bars.append(bar)
	cross = Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size", 28)
	hud.add_child(cross)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.offset_left = -16
	cross.offset_right = 16
	cross.offset_top = -20
	cross.offset_bottom = 20
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status = Label.new()
	status.text = "Move %s/%s/%s/%s | Jump %s | Sprint %s | Dodge %s | Attack %s | Block %s | Special %s | Esc mouse" % [Controls.display_name("arena_forward"), Controls.display_name("arena_left"), Controls.display_name("arena_back"), Controls.display_name("arena_right"), Controls.display_name("arena_jump"), Controls.display_name("arena_sprint"), Controls.display_name("arena_dodge"), Controls.display_name("arena_attack"), Controls.display_name("arena_block"), Controls.display_name("arena_special")]
	panel.add_child(status)
	result_banner = Label.new()
	result_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	result_banner.offset_left = -420
	result_banner.offset_right = 420
	result_banner.offset_top = -110
	result_banner.offset_bottom = 10
	result_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_banner.add_theme_font_size_override("font_size", 72)
	result_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12, 0.95))
	result_banner.add_theme_constant_override("outline_size", 12)
	result_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_banner.hide()
	hud.add_child(result_banner)
	arena_label = Label.new()
	panel.add_child(arena_label)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if lan_role == 2: yaw = PI
	camera.position = Vector3(0,3,12)
	camera.look_at(Vector3(0,1.6,7))

func _lan_vec(values: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if not (values is Array) or values.size() != 3: return fallback
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _lan_array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func _lan_fx(kind: String, values: Array) -> void:
	if lan_role != 1: return
	lan_fx_sequence += 1
	lan_fx_recent.append([lan_fx_sequence, elapsed, kind] + values)
	if lan_fx_recent.size() > 24: lan_fx_recent.pop_front()

func _lan_fx_snapshot() -> Array:
	while not lan_fx_recent.is_empty() and elapsed - float(lan_fx_recent[0][1]) > 0.8:
		lan_fx_recent.pop_front()
	return lan_fx_recent.duplicate(true)

func fx_popup(point: Vector3, value: float, color: Color, word: String = "") -> void:
	polish.popup(point, value, color, word)
	_lan_fx("popup", [_lan_array(point), value, color.to_html(), word])

func fx_ring(point: Vector3, color: Color, size: float, duration: float = 0.28, upright: bool = false) -> void:
	polish.shock_ring(point, color, size, duration, upright)
	_lan_fx("ring", [_lan_array(point), color.to_html(), size, duration, upright])

func fx_sound(cue: String, point: Vector3, kind: String = "") -> void:
	get_node("/root/Sound").play_spatial(cue, point, self, kind)
	_lan_fx("sound", [_lan_array(point), cue, kind])

func _lan_apply_fx(events: Array, host_time: float) -> void:
	for event in events:
		if not event is Array or event.size() < 4: continue
		var sequence := int(event[0])
		if sequence <= lan_fx_seen: continue
		lan_fx_seen = sequence
		if host_time - float(event[1]) > 0.8: continue
		var point := _lan_vec(event[3])
		match str(event[2]):
			"burst":
				if event.size() == 7: burst(point, Color(str(event[4])), int(event[5]), float(event[6]))
			"ring":
				if event.size() == 8: fx_ring(point, Color(str(event[4])), float(event[5]), float(event[6]), bool(event[7]))
			"popup":
				if event.size() == 7: fx_popup(point, float(event[4]), Color(str(event[5])), str(event[6]))
			"orb":
				if event.size() == 6: effect(point, Color(str(event[4])), float(event[5]))
			"spear": spear_impact(point)
			"lightning":
				_lightning_visual(point)
				collapse_shake = maxf(collapse_shake, 0.35)
			"sound":
				if event.size() == 6: fx_sound(str(event[4]), point, str(event[5]))

func lan_receive_input(input: Dictionary) -> void:
	if lan_role != 1: return
	lan_remote_input = input
	lan_remote_age = 0.0
	lan_attack_queued = lan_attack_queued or bool(input.get("a", false))
	lan_special_queued = lan_special_queued or bool(input.get("s", false))

func _lan_snapshot() -> Dictionary:
	var fighters_state := []
	for i in range(2):
		fighters_state.append([_lan_array(bodies[i].position), _lan_array(bodies[i].velocity), models[i].rotation.y, hp[i], guarding[i], cooldown[i], special[i], pose_time[i], pose_length[i], pose_power[i], flashes[i], combo_active[i], ground_known[i], perfect_pose[i], dodge_time if i == 0 else lan_dodge_time])
	var shots := []
	for projectile in projectiles:
		if is_instance_valid(projectile["mesh"]): shots.append([str(projectile["kind"]), _lan_array(projectile["mesh"].position), _lan_array(projectile["mesh"].rotation), _lan_array(projectile.get("velocity", Vector3.ZERO))])
	var islands := []
	for event in collapses:
		var part: Variant = event.get("part")
		islands.append([int(event["state"]), _lan_array(part.position) if is_instance_valid(part) else [], _lan_array(part.rotation) if is_instance_valid(part) else []])
	var broken := []
	for bridge in bridge_info:
		var intact := []
		for plank in bridge["planks"]: intact.append(is_instance_valid(plank) and not plank.has_meta("dropping"))
		broken.append([bool(bridge["broken"]), bool(bridge["cut"]), float(bridge["gap_min"]), float(bridge["gap_max"]), intact])
	var covers_alive := []
	for cover in covers: covers_alive.append(is_instance_valid(cover["node"]) and not cover["node"].is_queued_for_deletion())
	var shard_popups := []
	for i in range(2): shard_popups.append([shard_popup_seq[i], shard_icon_kind[i], shard_icon_time[i]])
	return {"f": fighters_state, "p": shots, "fx": _lan_fx_snapshot(), "e": elapsed, "over": over, "winner": end_winner, "islands": islands, "bridges": broken, "covers": covers_alive, "ferry": ferry_x, "crystal": [crystal.visible, _lan_array(crystal.position), crystal_kind], "shards": shard_popups, "heal": heal_ready_at, "lightning": [is_instance_valid(lightning_warning), _lan_array(lightning_warning.position) if is_instance_valid(lightning_warning) else []], "storm": storm_amount, "boost": boost, "speed": speed_boost, "push": push_boost}

func _lan_publish(dt: float) -> void:
	if lan_role != 1: return
	lan_snapshot_clock += dt
	if lan_snapshot_clock >= 1.0 / 30.0:
		lan_snapshot_clock = 0.0
		lan_state_ready.emit(_lan_snapshot())

func lan_apply_state(state: Dictionary) -> void:
	if lan_role != 2 or bodies.size() != 2: return
	var pair: Array = state.get("f", [])
	if pair.size() != 2: return
	for i in range(2):
		var values: Array = pair[i]
		if values.size() != 15: return
		var old_hp := hp[i]
		var old_pose := pose_time[i]
		lan_target_positions[i] = _lan_vec(values[0], bodies[i].position)
		lan_target_velocities[i] = _lan_vec(values[1], bodies[i].velocity)
		if not lan_has_snapshot:
			bodies[i].position = lan_target_positions[i]
			bodies[i].velocity = lan_target_velocities[i]
		models[i].rotation.y = float(values[2])
		hp[i] = float(values[3]); guarding[i] = bool(values[4]); cooldown[i] = float(values[5]); special[i] = float(values[6])
		pose_time[i] = float(values[7]); pose_length[i] = float(values[8]); pose_power[i] = bool(values[9]); flashes[i] = float(values[10]); combo_active[i] = int(values[11]); ground_known[i] = bool(values[12]); perfect_pose[i] = float(values[13])
		if i == 0: dodge_time = float(values[14])
		else: lan_dodge_time = float(values[14])
		if pose_time[i] > old_pose + 0.08:
			get_node("/root/Sound").play_spatial("special" if pose_power[i] else ("heavy_swing" if kinds[i] in ["R", "K", "W"] else "swing"), bodies[i].global_position + Vector3.UP, self, kinds[i])
		if hp[i] < old_hp:
			flashes[i] = maxf(flashes[i], 0.12)
			if i == 1: shake = maxf(shake, 0.15)
	lan_has_snapshot = true
	lan_snapshot_age = 0.0
	lan_state_samples += 1
	elapsed = float(state.get("e", elapsed))
	_lan_apply_fx(state.get("fx", []), elapsed)
	var was_over := over
	over = bool(state.get("over", false))
	end_winner = int(state.get("winner", -1))
	if over and not was_over:
		begin_victory_camera()
		_show_result_banner()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		cross.hide()
		get_node("/root/Sound").play_flat("victory" if end_winner == 1 else "defeat")
	var island_state: Array = state.get("islands", [])
	danger_text = ""
	for i in mini(island_state.size(), collapses.size()):
		var item: Array = island_state[i]
		var event: Dictionary = collapses[i]
		if item.size() != 3: continue
		var old_state := int(event["state"])
		event["state"] = int(item[0])
		var part: Variant = event.get("part")
		if is_instance_valid(part):
			if old_state == 0 and int(event["state"]) == 1: mark_cracks(part, int(event["index"]))
			if item[1] is Array and item[1].size() == 3:
				part.position = _lan_vec(item[1])
				part.rotation = _lan_vec(item[2], part.rotation)
			else: part.queue_free() # Remove stale collision as well as the visual.
		if int(event["state"]) == 1:
			var remaining := maxf(0.0, float(event["at"]) - elapsed)
			if danger_text.is_empty(): danger_text = "%.1fs" % remaining
			if is_instance_valid(part) and bodies[1].position.distance_to(part.global_position) < 15.0:
				collapse_shake = maxf(collapse_shake, 0.20 * clampf((5.0 - remaining) / 5.0, 0.0, 1.0))
	var bridge_state: Array = state.get("bridges", [])
	for i in mini(bridge_state.size(), bridge_info.size()):
		var item: Array = bridge_state[i]
		if item.size() != 5: continue
		if bool(item[1]) and not bool(bridge_info[i]["cut"]): cut_bridge(i)
		elif bool(item[0]):
			bridge_info[i]["broken"] = true
			bridge_info[i]["gap_min"] = float(item[2])
			bridge_info[i]["gap_max"] = float(item[3])
			var intact: Array = item[4]
			for j in mini(intact.size(), bridge_info[i]["planks"].size()):
				var plank: Variant = bridge_info[i]["planks"][j]
				if not bool(intact[j]) and is_instance_valid(plank) and not plank.has_meta("dropping"): drop_piece(plank, 0.9)
	var cover_state: Array = state.get("covers", [])
	for i in mini(cover_state.size(), covers.size()):
		if not bool(cover_state[i]) and is_instance_valid(covers[i]["node"]): covers[i]["node"].queue_free()
	if is_instance_valid(ferry): ferry.position.x = float(state.get("ferry", ferry.position.x))
	heal_ready_at = float(state.get("heal", heal_ready_at))
	var crystal_state: Array = state.get("crystal", [])
	if crystal_state.size() == 3:
		crystal.visible = bool(crystal_state[0])
		crystal.position = _lan_vec(crystal_state[1], crystal.position)
		crystal_kind = int(crystal_state[2])
		crystal.material_override = luminous(CRYSTAL_COLORS[crystal_kind])
		crystal_icon.texture = SHARD_TEXTURES[crystal_kind]
	var lightning_state: Array = state.get("lightning", [])
	if lightning_state.size() == 2:
		if bool(lightning_state[0]):
			if not is_instance_valid(lightning_warning): lightning_warning = ring_at(self, _lan_vec(lightning_state[1]), 1.8, Color("ffb348"))
			else: lightning_warning.position = _lan_vec(lightning_state[1])
		elif is_instance_valid(lightning_warning):
			lightning_warning.queue_free()
			lightning_warning = null
	storm_amount = float(state.get("storm", storm_amount))
	var next_boost: Array = state.get("boost", [])
	var next_speed: Array = state.get("speed", [])
	var next_push: Array = state.get("push", [])
	if next_boost.size() == 2 and next_speed.size() == 2 and next_push.size() == 2:
		for i in range(2):
			boost[i] = float(next_boost[i])
			speed_boost[i] = float(next_speed[i])
			push_boost[i] = float(next_push[i])
	var popup_state: Array = state.get("shards", [])
	for i in mini(popup_state.size(), shard_icons.size()):
		var entry: Array = popup_state[i]
		if entry.size() != 3: continue
		var seq := int(entry[0])
		var remaining := maxf(0.0, float(entry[2]))
		if seq != lan_shard_seen_seq[i]:
			lan_shard_seen_seq[i] = seq
			if remaining > 0.0: _display_shard_icon(i, int(entry[1]), remaining)
			else:
				shard_icon_time[i] = 0.0
				shard_icons[i].hide()
		elif remaining <= 0.0:
			shard_icon_time[i] = 0.0
			shard_icons[i].hide()
	var sky_mat := camera.environment.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color("3179bb").lerp(Color("29324c"), storm_amount)
	sky_mat.sky_horizon_color = Color("d4efff").lerp(Color("838da9"), storm_amount)
	camera.environment.fog_light_color = Color("b2d5ee").lerp(Color("747e9a"), storm_amount)
	camera.environment.fog_density = lerpf(0.009, 0.018, storm_amount)
	var shots: Array = state.get("p", [])
	while lan_projectile_meshes.size() < shots.size():
		lan_projectile_meshes.append(null)
	for i in lan_projectile_meshes.size():
		if i >= shots.size():
			if is_instance_valid(lan_projectile_meshes[i]):
				if str(lan_projectile_meshes[i].get_meta("lan_kind", "")) == "fire":
					lan_projectile_meshes[i].queue_free()
					lan_projectile_meshes[i] = null
				else: lan_projectile_meshes[i].hide()
			continue
		var shot: Array = shots[i]
		if shot.size() != 4: continue
		var kind := str(shot[0])
		var mesh: Node3D = lan_projectile_meshes[i] if is_instance_valid(lan_projectile_meshes[i]) else null
		if not is_instance_valid(mesh) or str(mesh.get_meta("lan_kind", "")) != kind:
			if is_instance_valid(mesh): mesh.queue_free()
			if kind == "spear": mesh = make_flying_spear()
			elif kind == "bomb":
				mesh = MagmaBomb.instantiate() as Node3D
				mesh.scale = Vector3.ONE * 0.65
			elif kind == "fire":
				var fire := FireballFX.instantiate() as PyroluxFireball3D
				fire.autoplay = false
				fire.hit_mode = PyroluxFireball3D.HitMode.NONE
				fire.impact_scorch = false
				mesh = fire
			elif kind == "quake": mesh = make_wave(Color.GOLD)
			else: mesh = orb(Color.ORANGE_RED, 0.22)
			mesh.set_meta("lan_kind", kind)
			add_child(mesh)
			lan_projectile_meshes[i] = mesh
			if kind == "fire": (mesh as PyroluxFireball3D).launch_direction(_lan_vec(shot[1]), _lan_vec(shot[3]), _lan_vec(shot[3]).length())
		mesh.show()
		if kind != "fire":
			mesh.position = _lan_vec(shot[1], mesh.position)
			mesh.rotation = _lan_vec(shot[2], mesh.rotation)

func _lan_guest_motion(dt: float) -> void:
	if not lan_has_snapshot or over: return
	lan_snapshot_age += dt
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var direction := Vector3.ZERO
	if captured:
		direction = (forward * (int(Controls.is_pressed("arena_forward")) - int(Controls.is_pressed("arena_back"))) + right * (int(Controls.is_pressed("arena_right")) - int(Controls.is_pressed("arena_left")))).normalized()
	_lan_predict_local(dt, direction if lan_snapshot_age < 0.35 else Vector3.ZERO, captured and Controls.is_pressed("arena_sprint"), captured and Controls.is_pressed("arena_block"), captured and Controls.is_pressed("arena_jump"))
	_lan_reconcile(dt)

func _lan_predict_local(dt: float, direction: Vector3, sprinting: bool, blocking: bool, jumping: bool) -> void:
	var local := bodies[1]
	var local_speed := float(stats[1]["speed"])
	if sprinting: local_speed *= 1.45
	if speed_boost[1] > 0.0: local_speed *= 1.25
	if blocking: local_speed *= 0.45
	if lan_dodge_time > 0.0 and direction.length() > 0.1: local_speed = 14.0
	local.velocity.x = direction.x * local_speed
	local.velocity.z = direction.z * local_speed
	local.velocity.y -= 22.0 * dt
	if local.is_on_floor():
		local.velocity.y = 8.0 if jumping else 0.0
	local.move_and_slide()

func _lan_reconcile(dt: float) -> void:
	if not lan_has_snapshot: return
	for i in range(2):
		var body := bodies[i]
		var target := lan_target_positions[i] + lan_target_velocities[i] * minf(lan_snapshot_age, 0.12)
		var error := target - body.position
		if error.length() > 4.0:
			body.position = target # Genuine knockback, respawn or large correction.
		elif i == 0:
			body.position = body.position.lerp(target, 1.0 - exp(-16.0 * dt))
		else:
			# Keep local input immediate; gently correct drift against Host authority.
			var horizontal := Vector3(error.x, 0.0, error.z)
			body.position += horizontal.limit_length(2.5 * dt) if horizontal.length() > 0.12 else Vector3.ZERO
			body.position.y = lerpf(body.position.y, target.y, 1.0 - exp(-8.0 * dt))
		if i == 0: body.velocity = lan_target_velocities[i]

func _lan_guest_tick(dt: float) -> void:
	if hitstop_remaining > 0.0:
		hitstop_remaining = maxf(0.0, hitstop_remaining - dt)
		if hitstop_remaining <= 0.0: _set_rig_pause(false)
	get_node("/root/Sound").set_battle_intensity(clampf((1.0 - minf(hp[0] / float(stats[0]["hp"]), hp[1] / float(stats[1]["hp"]))) * 0.75 + elapsed / 120.0, 0.0, 1.0))
	polish.tick(dt)
	shake = maxf(0.0, shake - dt)
	collapse_shake = maxf(0.0, collapse_shake - dt)
	_lan_guest_motion(dt)
	lan_stats_clock += dt
	if lan_stats_clock >= 1.0:
		lan_state_rate = roundi(lan_state_samples / lan_stats_clock)
		lan_state_samples = 0
		lan_stats_clock = 0.0
	update_shard_icons(dt)
	lan_bomb_trail_clock += dt
	if lan_bomb_trail_clock >= 0.05:
		lan_bomb_trail_clock = 0.0
		for mesh in lan_projectile_meshes:
			if is_instance_valid(mesh) and mesh.visible and str(mesh.get_meta("lan_kind", "")) == "bomb":
				burst(mesh.position, Color.ORANGE_RED, 2, 0.25, false)
	lan_input_clock += dt
	if lan_input_clock >= 0.025 and not over:
		lan_input_clock = 0.0
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		var target := crosshair_target()
		var face := (target - bodies[1].position - Vector3.UP).normalized()
		lan_input_ready.emit({"f": captured and Controls.is_pressed("arena_forward"), "b": captured and Controls.is_pressed("arena_back"), "r": captured and Controls.is_pressed("arena_right"), "l": captured and Controls.is_pressed("arena_left"), "j": captured and Controls.is_pressed("arena_jump"), "sp": captured and Controls.is_pressed("arena_sprint"), "d": captured and Controls.is_pressed("arena_dodge"), "g": captured and Controls.is_pressed("arena_block"), "a": attack_queued or (captured and Controls.is_pressed("arena_attack")), "s": special_queued, "y": yaw, "aim": _lan_array(face)})
		attack_queued = false
		special_queued = false
	for i in range(2):
		if over: animate_end(i)
		else: animate_pose(i, dt, bodies[i].velocity.length() > 0.4)
		if not over: update_weapon_trail(i)
		bars[i].value = hp[i]
		shields[i].visible = not over and (guarding[i] or perfect_pose[i] > 0.0)
		shields[i].scale = Vector3.ONE * (1.0 + perfect_pose[i] * 1.4)
	for wind in winds:
		if is_instance_valid(wind["root"]):
			wind["root"].visible = elapsed < 20.0 + float(wind["index"]) * 4.0
			if wind["root"].visible: wind["root"].update_visual(dt, storm_amount)
	visuals.update_storm(storm_amount)
	if is_instance_valid(sun):
		sun.light_energy = lerpf(1.15, 0.48, storm_amount)
		sun.light_color = Color("fff0d2").lerp(Color("aab9f0"), storm_amount)
	if is_instance_valid(lightning_warning):
		lightning_warning.scale = Vector3(1.0 + sin(elapsed * 24.0) * 0.07, 0.25, 1.0 + sin(elapsed * 24.0) * 0.07)
	if crystal.visible:
		crystal.rotation.y += dt * 2.0
	_update_heal_visual()
	if over:
		end_clock += dt
		update_victory_camera(dt)
	else: update_camera()
	status.text = ("VICTORY" if end_winner == 1 else "DEFEAT") if over else "LAN PvP | %s Attack | %s Block | %s Special: %s" % [Controls.display_name("arena_attack"), Controls.display_name("arena_block"), Controls.display_name("arena_special"), "READY" if special[1] <= 0.0 else "%.1fs" % special[1]]
	var phase := "SUDDEN DEATH" if elapsed >= 45.0 else ("SKY STORM" if elapsed >= 35.0 else ("COLLAPSE" if elapsed >= 15.0 else "FIGHT"))
	arena_label.text = "%ds | %s | Power %.1fs | Speed %.1fs | Push %.1fs\nFPS %d | States %d/s | Last %d ms%s" % [int(elapsed), phase, boost[1], speed_boost[1], push_boost[1], Engine.get_frames_per_second(), lan_state_rate, roundi(lan_snapshot_age * 1000.0), " | COLLAPSE " + danger_text if not danger_text.is_empty() else ""]
func block(size: Vector3, pos: Vector3, color: Color, solid: bool = true) -> StaticBody3D:
	var root := StaticBody3D.new()
	add_child(root)
	root.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		root.add_child(col)
	return root
func spawn(kind: String, white: bool, pos: Vector3) -> void:
	var body := CharacterBody3D.new()
	body.platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	# Maintain floor contact on the descending deck, without cancelling upward jumps.
	body.floor_snap_length = 0.32
	add_child(body)
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.48
	shape.height = 1.7
	col.shape = shape
	col.position.y = 0.85
	body.add_child(col)
	var model := Rig.build(kind, Data.FIGHT_H[kind], not white)
	body.add_child(model)
	models.append(model)
	var anim := Rig.player(model)
	rig_players.append(anim)
	if anim != null and anim.has_animation("Idle"): anim.play("Idle")
	var weapon: Node3D = Rig.weapon(model) if kind == "P" else null
	var held: Node3D = null
	if kind == "R":
		held = MagmaBomb.instantiate() as Node3D
		var skel := Rig.skeleton(model)
		if skel != null and skel.find_bone("WeaponJoint") >= 0:
			var attach := BoneAttachment3D.new()
			skel.add_child(attach)
			attach.bone_name = "WeaponJoint"
			attach.add_child(held)
		else:
			model.add_child(held)
			held.position = Vector3(0.32, 0.65, -0.30)
		held.scale = Vector3.ONE * 0.30
		held.hide()
	held_bombs.append(held)
	pawn_weapons.append(weapon)
	kinds.append(kind)
	base_scales.append(model.scale)
	var shield := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.85
	sphere.height = 1.7
	shield.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var shield_color: Color = FX_COLORS[kind]
	shield_color.a = 0.24
	mat.albedo_color = shield_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield.material_override = mat
	body.add_child(shield)
	shield.position.y = 0.9
	shield.hide()
	shields.append(shield)
	var shard_icon := make_shard_icon(body, Vector3.UP*(float(Data.FIGHT_H[kind])+0.46), 0.0040)
	shard_icon.hide()
	shard_icons.append(shard_icon)
	bodies.append(body)
	stats.append(Data.STATS[kind])
	hp.append(float(Data.STATS[kind]["hp"]))
func _input(event: InputEvent) -> void:
	if over: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if Controls.matches(event, "arena_attack"):
		attack_queued = true
	if Controls.matches(event, "arena_special"):
		special_queued = true
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * 0.003
		pitch = clampf(pitch-event.relative.y*0.003,-deg_to_rad(LOOK_DOWN_MAX),0.35)
func _physics_process(dt: float) -> void:
	if bodies.size() != 2: return
	if lan_role == 2:
		_lan_guest_tick(dt)
		return
	if lan_role == 1: lan_remote_age += dt
	get_node("/root/Sound").set_battle_intensity(clampf((1.0 - minf(hp[0] / float(stats[0]["hp"]), hp[1] / float(stats[1]["hp"]))) * 0.75 + elapsed / 120.0, 0.0, 1.0))
	polish.tick(dt)
	# Local simulation pause: never change Engine.time_scale or pause the scene tree.
	if hitstop_remaining > 0.0:
		hitstop_remaining = maxf(0.0, hitstop_remaining - dt)
		if hitstop_remaining > 0.0:
			_lan_publish(dt)
			return
		_set_rig_pause(false)
	update_shard_icons(dt)
	if over:
		end_clock += dt
		for i in range(2): animate_end(i)
		update_victory_camera(dt)
		if end_clock >= 2.4 and not victory_emitted:
			victory_emitted = true
			finished.emit(hp[1] <= 0.0 and hp[0] > 0.0)
		_lan_publish(dt)
		return
	update_arena(dt)
	for i in range(2):
		combo_window[i] = maxf(0.0, combo_window[i] - dt)
		counter_time[i] = maxf(0.0, counter_time[i] - dt)
		if combo_window[i] <= 0.0: combo_step[i] = 0
	var forward := Vector3(-sin(yaw),0,-cos(yaw))
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var move := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		move = forward * (float(Controls.is_pressed("arena_forward"))-float(Controls.is_pressed("arena_back"))) + right * (float(Controls.is_pressed("arena_right"))-float(Controls.is_pressed("arena_left")))
	var enemy_dir := bodies[0].position-bodies[1].position
	enemy_dir.y = 0
	var ai_move := arena_ai_move() if lan_role != 1 else Vector3.ZERO
	var remote_held := lan_remote_input if lan_role == 1 and lan_remote_age < 0.35 else {}
	var remote_yaw := float(remote_held.get("y", 0.0))
	var remote_forward := Vector3(-sin(remote_yaw), 0, -cos(remote_yaw))
	var remote_right := Vector3(cos(remote_yaw), 0, -sin(remote_yaw))
	var remote_move := (remote_forward * (int(bool(remote_held.get("f", false))) - int(bool(remote_held.get("b", false)))) + remote_right * (int(bool(remote_held.get("r", false))) - int(bool(remote_held.get("l", false))))).normalized()
	ai_jump = maxf(0,ai_jump-dt)
	guarding[0] = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Controls.is_pressed("arena_block")
	guarding[1] = bool(remote_held.get("g", false)) if lan_role == 1 else false
	guard_age = guard_age + dt if guarding[0] else 0.0
	lan_guard_age = lan_guard_age + dt if guarding[1] else 0.0
	dodge_cd = maxf(0.0, dodge_cd-dt)
	dodge_time = maxf(0.0, dodge_time-dt)
	lan_dodge_cd = maxf(0.0, lan_dodge_cd-dt)
	lan_dodge_time = maxf(0.0, lan_dodge_time-dt)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Controls.is_pressed("arena_dodge") and dodge_cd <= 0.0 and move.length() > 0.1 and not guarding[0] and bodies[0].is_on_floor():
		dodge_cd = 2.0
		dodge_time = 0.20
		fx_sound("dodge", bodies[0].global_position)
		dodge_dir = move.normalized()
		var front := dodge_dir.dot(forward)
		var side := dodge_dir.dot(right)
		dodge_clip = ("DodgeRight" if side > 0.0 else "DodgeLeft") if absf(side) > absf(front) else ("DodgeForward" if front > 0.0 else "DodgeBack")
		combo_step[0] = 0
		combo_window[0] = 0.0
		rig_states[0] = ""
		pawn_pending[0] = {}
		pose_time[0] = 0.0
		burst(bodies[0].position + Vector3.UP * 0.25, FX_COLORS[kinds[0]], 6, 0.75)
	if lan_role == 1 and bool(remote_held.get("d", false)) and lan_dodge_cd <= 0.0 and remote_move.length() > 0.1 and not guarding[1] and bodies[1].is_on_floor():
		lan_dodge_cd = 2.0
		lan_dodge_time = 0.20
		lan_dodge_dir = remote_move
		fx_sound("dodge", bodies[1].global_position)
		var front := lan_dodge_dir.dot(remote_forward)
		var side := lan_dodge_dir.dot(remote_right)
		lan_dodge_clip = ("DodgeRight" if side > 0.0 else "DodgeLeft") if absf(side) > absf(front) else ("DodgeForward" if front > 0.0 else "DodgeBack")
		combo_step[1] = 0
		combo_window[1] = 0.0
		rig_states[1] = ""
		pawn_pending[1] = {}
		pose_time[1] = 0.0
		burst(bodies[1].position + Vector3.UP * 0.25, FX_COLORS[kinds[1]], 6, 0.75)
	feedback_time = maxf(0, feedback_time-dt)
	for i in range(2):
		var body := bodies[i]
		var dir := move.normalized() if i == 0 else (remote_move if lan_role == 1 else ai_move)
		var speed := float(stats[i]["speed"])
		if (i == 0 and Controls.is_pressed("arena_sprint")) or (i == 1 and ((lan_role == 1 and bool(remote_held.get("sp", false))) or (lan_role != 1 and ai_retreat))): speed *= 1.45
		if speed_boost[i] > 0.0: speed *= 1.25
		if guarding[i]: speed *= 0.45
		if i == 0 and dodge_time > 0.0:
			dir = dodge_dir
			speed = 14.0
		if i == 1 and lan_role == 1 and lan_dodge_time > 0.0:
			dir = lan_dodge_dir
			speed = 14.0
		shields[i].visible = guarding[i] or perfect_pose[i] > 0.0
		shields[i].scale = Vector3.ONE * (1.0 + perfect_pose[i] * 1.4)
		flashes[i] = maxf(0.0, flashes[i]-dt)
		body.velocity.x = dir.x*speed + knockback[i].x
		body.velocity.z = dir.z*speed + knockback[i].z
		knockback[i] = knockback[i].move_toward(Vector3.ZERO, 20.0*dt)
		body.velocity.y -= 22*dt
		if body.is_on_floor():
			body.velocity.y = 0
			if (i == 0 and Controls.is_pressed("arena_jump")) or (i == 1 and ((lan_role == 1 and bool(remote_held.get("j", false))) or (lan_role != 1 and ai_jump <= 0 and (body.is_on_wall() or arena_ai_jump(body, dir) or bodies[0].position.y > body.position.y+0.7)))):
				body.velocity.y = 8
				if i == 1 and lan_role != 1: ai_jump = 0.8
			for p in pads:
				if body.position.distance_to(p)<1.2: body.velocity.y = 12
		apply_wind(body, dt)
		var was_grounded := body.is_on_floor()
		var vertical_speed := body.velocity.y
		body.move_and_slide()
		if was_grounded and not body.is_on_floor() and vertical_speed > 0.0:
			jump_pose[i] = 0.16
		if ground_known[i] and not ground_previous[i] and body.is_on_floor():
			landing_pose[i] = 0.24
			if vertical_speed < -2.0:
				footstep(i, true)
		ground_known[i] = true
		ground_previous[i] = body.is_on_floor()
		var face := forward if i == 0 else (remote_forward if lan_role == 1 else (dir if ai_retreat else enemy_dir.normalized()))
		if face.length()>0.1: models[i].rotation.y = atan2(-face.x,-face.z)
		animate_pose(i, dt, dir.length() > 0.1 and body.is_on_floor(), (i == 0 and Controls.is_pressed("arena_sprint")) or (i == 1 and ((lan_role == 1 and bool(remote_held.get("sp", false))) or (lan_role != 1 and ai_retreat))))
		update_weapon_trail(i)
		if body.position.y < -10:
			hp[i] = 0.0
			body.velocity = Vector3.ZERO
		cooldown[i] = maxf(0,cooldown[i]-dt)
		special[i] = maxf(0,special[i]-dt)
	update_camera()
	shake = maxf(0.0, shake-dt)
	collapse_shake = maxf(0.0, collapse_shake-dt)
	var aim_point := crosshair_target()
	var aim_delta := aim_point - (bodies[0].position + Vector3.UP)
	aim = aim_delta.normalized() if aim_delta.length() > 0.05 else -camera.global_transform.basis.z
	cross.modulate = Color.GOLD if flashes[1] > 0.0 else Color.WHITE
	attack_buffer = 0.24 if attack_queued else maxf(0.0, attack_buffer-dt)
	special_buffer = 0.30 if special_queued else maxf(0.0, special_buffer-dt)
	attack_queued = false
	special_queued = false
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not guarding[0]:
		# Special has priority over held Attack; a short buffer avoids losing a press in recovery.
		var cast := false
		if special_buffer > 0.0 and special[0] <= 0.0:
			cast = attack(0,aim,true)
			if cast: special_buffer = 0.0
		if not cast and (attack_buffer > 0.0 or Controls.is_pressed("arena_attack")):
			if attack(0,aim,false): attack_buffer = 0.0
	else:
		attack_buffer = 0.0
		special_buffer = 0.0
	var ai_face := (bodies[0].position-bodies[1].position).normalized()
	if lan_role == 1:
		var remote_aim := _lan_vec(remote_held.get("aim", []), ai_face).normalized()
		lan_attack_buffer = 0.24 if lan_attack_queued else maxf(0.0, lan_attack_buffer-dt)
		lan_special_buffer = 0.30 if lan_special_queued else maxf(0.0, lan_special_buffer-dt)
		lan_attack_queued = false
		lan_special_queued = false
		if not guarding[1]:
			var cast := false
			if lan_special_buffer > 0.0 and special[1] <= 0.0:
				cast = attack(1, remote_aim, true)
				if cast: lan_special_buffer = 0.0
			if not cast and (lan_attack_buffer > 0.0 or bool(remote_held.get("a", false))):
				if attack(1, remote_aim, false): lan_attack_buffer = 0.0
	else:
		if not ai_retreat:
			attack(1,ai_face,false)
			if bodies[0].position.distance_to(bodies[1].position)<4.0: attack(1,ai_face,true)
	for i in range(2):
		if not pawn_pending[i].is_empty():
			pawn_pending[i]["delay"] = float(pawn_pending[i]["delay"]) - dt
			if float(pawn_pending[i]["delay"]) <= 0.0:
				var action: Dictionary = pawn_pending[i]
				pawn_pending[i] = {}
				if hp[i] > 0.0 and hp[1-i] > 0.0 and not guarding[i] and not (i == 1 and ai_retreat):
					resolve_attack(i, action["face"], action["power"])
					if kinds[i] == "Q" and not action["power"] and not action.get("second", false):
						pawn_pending[i] = {"delay": 0.14, "face": action["face"], "power": false, "second": true}
	update_projectiles(dt)
	status.text = "%s Attack | %s Block | %s %s: %s\n%s" % [Controls.display_name("arena_attack"), Controls.display_name("arena_block"), Controls.display_name("arena_special"), stats[0]["sp_name"], "READY" if special[0]<=0 else "%.1fs" % special[0], "BLOCKING" if guarding[0] else (feedback if feedback_time>0 else "Attack: READY" if cooldown[0]<=0 else "Attack: cooldown")]
	if counter_time[0] > 0.0: status.text += " | COUNTER READY %.1fs" % counter_time[0]
	elif combo_window[0] > 0.0 and combo_step[0] > 0 and combo_connected[0]: status.text += " | COMBO %d/3" % combo_step[0]
	for i in range(2): bars[i].value = hp[i]
	if hp[0]<=0 or hp[1]<=0:
		over = true
		end_winner = 0 if hp[1] <= 0.0 and hp[0] > 0.0 else (1 if hp[0] <= 0.0 and hp[1] > 0.0 else -1)
		for i in range(2):
			shields[i].hide()
			shard_icons[i].hide()
			shard_icon_time[i] = 0.0
			if i == end_winner:
				burst(bodies[i].position + Vector3.UP, FX_COLORS[kinds[i]], 12, 1.1)
		status.text = "VICTORY" if end_winner == 0 else ("DEFEAT" if end_winner == 1 else "DOUBLE K.O.")
		_show_result_banner()
		cross.hide()
		attack_queued = false
		special_queued = false
		for i in range(2): pawn_pending[i] = {}
		get_node("/root/Sound").play_flat("victory" if end_winner == 0 else "defeat")
		begin_victory_camera()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_lan_publish(dt)
func crosshair_target() -> Vector3:
	var center := get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var direction := camera.project_ray_normal(center)
	var end := origin + direction * 60.0
	var query := PhysicsRayQueryParameters3D.create(origin,end)
	query.exclude = [bodies[1].get_rid()] if lan_role == 2 else [bodies[0].get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("position",end)
func clear_path(i: int, start: Vector3, end: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(start,end)
	query.exclude = [bodies[i].get_rid(),bodies[1-i].get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func notify(message: String) -> void:
	feedback = message
	feedback_time = 1.0
func _set_rig_pause(on: bool) -> void:
	paused_rigs = on
	for anim in rig_players:
		if is_instance_valid(anim): anim.speed_scale = 0.0 if on else 1.0

func request_hitstop(duration: float) -> void:
	hitstop_remaining = maxf(hitstop_remaining, duration)
	if not paused_rigs: _set_rig_pause(true)

func damage(i: int, amount: float, power: bool = false, point: Vector3 = Vector3.INF, impact_played: bool = false) -> void:
	var target := 1-i
	if over or hp[target] <= 0.0: return
	if (target == 0 and dodge_time > 0.0) or (target == 1 and lan_role == 1 and lan_dodge_time > 0.0): return
	var contact := point if point.is_finite() else bodies[target].position + Vector3.UP * 0.95
	if target == 0 and guarding[0] and guard_age < 0.18:
		fx_sound("perfect_block", contact)
		notify("PERFECT BLOCK")
		guard_age = 0.18 # Consume the parry window once per guard press.
		perfect_pose[0] = 0.26
		counter_time[0] = 2.0
		burst(contact, FX_COLORS[kinds[0]], 14, 1.0)
		fx_ring(contact, Color.WHITE, 2.4, 0.32, true)
		fx_ring(contact, FX_COLORS[kinds[0]], 3.2, 0.42, true)
		fx_popup(bodies[0].position + Vector3.UP * (float(Data.FIGHT_H[kinds[0]]) + 0.35), 0.0, Color.CYAN, "PARRY")
		shake = maxf(shake, 0.12)
		request_hitstop(0.055)
		return
	if target == 1 and lan_role == 1 and guarding[1] and lan_guard_age < 0.18:
		fx_sound("perfect_block", contact)
		lan_guard_age = 0.18
		perfect_pose[1] = 0.26
		counter_time[1] = 2.0
		burst(contact, FX_COLORS[kinds[1]], 14, 1.0)
		fx_ring(contact, Color.WHITE, 2.4, 0.32, true)
		request_hitstop(0.055)
		return
	amount *= 1.6 if elapsed >= 45.0 else (1.3 if elapsed >= 30.0 else (1.15 if elapsed >= 15.0 else 1.0))
	# Preserve the previous 25% perfect-block bonus without consuming a Power Shard.
	var counter := counter_time[i] > 0.0
	if boost[i] > 0.0 or counter: amount *= 1.25
	if counter: counter_time[i] = 0.0
	var blocked := guarding[target]
	if blocked: amount *= float(stats[target].get("block", 0.35))
	var old_hp := hp[target]
	hp[target] = maxf(0.0, hp[target] - amount)
	var actual := old_hp - hp[target]
	var audio_cue := "block" if blocked else ("counter" if counter else ("special_impact" if power and kinds[i] != "P" else ("heavy_hit" if power or hp[target] <= 0.0 or combo_active[i] == 3 else "body_hit")))
	if not (power and impact_played and not blocked and not counter):
		fx_sound(audio_cue, contact, kinds[i])
	if not blocked:
		if not power:
			fx_sound("attack", contact, kinds[i])
		fx_sound("hit", contact, kinds[target])
	flashes[target] = 0.22
	if not power:
		combo_connected[i] = true
		combo_window[i] = float(stats[i]["cd"]) + 0.48
	if not blocked:
		combo_step[target] = 0
		combo_window[target] = 0.0
	var push := bodies[target].position-bodies[i].position
	push.y = 0.0
	var chain_push := 1.20 if not power and combo_active[i] == 3 and not blocked else 1.0
	knockback[target] = push.normalized() * (2.0 if blocked else 8.0) * (1.4 if push_boost[i] > 0.0 else 1.0) * chain_push
	var tint: Color = Color.CYAN if blocked else FX_COLORS[kinds[i]]
	var lethal := hp[target] <= 0.0
	last_damage_was_finisher = lethal
	if target == 0 or lethal: shake = maxf(shake, 0.27 if lethal else 0.15)
	effect(contact, Color.CYAN if blocked else Color.GOLD, 0.38 if blocked else 0.55)
	burst(contact, tint, 6 if blocked else (15 if power or lethal else 8), 1.15 if power or lethal else 0.65)
	fx_ring(contact, tint, 1.8 if power else 1.25, 0.25, true)
	var label_color := Color.CYAN if blocked else (Color.GOLD if counter or lethal else Color.WHITE)
	fx_popup(bodies[target].position + Vector3.UP * (float(Data.FIGHT_H[kinds[target]]) + 0.25), actual, label_color)
	if lethal:
		burst(contact, Color.GOLD, 20, 1.8)
		fx_ring(contact, Color.GOLD, 3.4, 0.5, true)
		fx_popup(bodies[target].position + Vector3.UP * (float(Data.FIGHT_H[kinds[target]]) + 0.95), 0.0, Color.GOLD, "K.O.")
	elif counter:
		fx_popup(contact+Vector3.UP*1.0, 0.0, Color.GOLD, "COUNTER")
	var pause := 0.10 if lethal else (0.07 if power else float(HIT_PAUSE[kinds[i]]))
	request_hitstop(pause * (0.65 if blocked else 1.0))
	notify(("COUNTER" if counter else ("BLOCKED" if blocked else "HIT")) + " -%.1f HP" % actual)
func effect(pos: Vector3, color: Color, size: float) -> void:
	_lan_fx("orb", [_lan_array(pos), color.to_html(), size])
	var mesh := orb(color,size)
	add_child(mesh)
	mesh.position = pos
	var tw := create_tween()
	tw.tween_property(mesh,"scale",Vector3.ONE*0.05,0.25)
	tw.tween_callback(mesh.queue_free)
func orb(color: Color, size: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size
	sphere.height = size*2
	# Most burst particles are tiny: keep them inexpensive on WebGL.
	if size <= 0.12:
		sphere.radial_segments = 8
		sphere.rings = 4
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	return mesh
func attack(i: int, face: Vector3, power: bool) -> bool:
	if over or hp[i] <= 0.0 or hp[1-i] <= 0.0 or guarding[i] or (i == 0 and dodge_time > 0.0) or (i == 1 and lan_role == 1 and lan_dodge_time > 0.0) or (special[i] if power else cooldown[i])>0: return false
	var target := 1-i
	var delta := bodies[target].position-bodies[i].position
	if i == 1 and lan_role != 1 and delta.length() > (4.0 if power else float(stats[i]["reach"])+1.2): return false
	if not pawn_pending[i].is_empty() or pose_time[i] > 0.0: return false
	if power:
		combo_step[i] = 0
		combo_window[i] = 0.0
	else:
		combo_step[i] = combo_step[i] % 3 + 1 if combo_window[i] > 0.0 and combo_connected[i] else 1
		combo_active[i] = combo_step[i]
		combo_connected[i] = false
		combo_window[i] = float(stats[i]["cd"]) + 0.48
	for index in range(TRAIL_BONES[kinds[i]].size()):
		polish.reset_trail("%d_%d" % [i,index])
	rig_states[i] = ""
	pose_power[i] = power
	pose_length[i] = 0.42 if power else minf(0.30, float(stats[i]["cd"]))
	pose_time[i] = pose_length[i]
	if power: special[i] = float(stats[i]["sp_cd"])
	else: cooldown[i] = float(stats[i]["cd"])
	if kinds[i] != "P" and power:
		pose_length[i] = 0.60
		pose_time[i] = pose_length[i]
	var delay := 0.20 if power else 0.12
	if kinds[i] != "P" and power: delay = 0.34
	pawn_pending[i] = {"delay": delay, "face": face, "power": power}
	if power:
		get_node("/root/Sound").play_spatial("special", bodies[i].global_position + Vector3.UP, self, kinds[i])
	else:
		get_node("/root/Sound").play_spatial("heavy_swing" if kinds[i] in ["R", "K", "W"] else "swing", bodies[i].global_position + Vector3.UP, self, kinds[i])
	return true

func resolve_attack(i: int, face: Vector3, power: bool) -> void:
	var target := 1-i
	var delta := bodies[target].position-bodies[i].position
	var start := bodies[i].position+Vector3.UP
	var end := bodies[target].position+Vector3.UP
	if power:
		fx_sound("cast_release", bodies[i].global_position + Vector3.UP)
		var kind: String = stats[i]["special"]
		if i == 0: notify(String(stats[i]["sp_name"]))
		if kind == "charge":
			var horizontal := Vector3(face.x,0,face.z).normalized()
			for step in range(8):
				var collision := bodies[i].move_and_collide(horizontal*0.4)
				if collision != null:
					strike_prop(collision.get_collider(), float(stats[i]["sp_dmg"]), true)
					break
				burst(bodies[i].position + Vector3.UP * 0.15, Color(0.65, 0.48, 0.30), 4, 0.5)
			if bodies[i].position.distance_to(bodies[target].position)<2.4 and clear_path(i,bodies[i].position+Vector3.UP,end): damage(i,float(stats[i]["sp_dmg"]), true)
			effect(bodies[i].position+Vector3.UP,Color.YELLOW,0.8)
		elif kind == "smite":
			# Resolve from the cast direction, not a fresh mouse ray after wind-up.
			# The aerial bonus only applies to a downward cast.
			var cast_range := 24.0 if not bodies[i].is_on_floor() and face.y < -0.15 else 10.0
			var cast_query := PhysicsRayQueryParameters3D.create(start,start+face*cast_range)
			cast_query.exclude = [bodies[i].get_rid()]
			var cast_hit := get_world_3d().direct_space_state.intersect_ray(cast_query)
			var point: Vector3 = cast_hit.get("position",start+face*cast_range)
			fx_sound("special_impact", point, kinds[i])
			effect(point,Color.GOLD,1.2)
			burst(point, Color(0.8, 0.35, 1.0), 20, 1.5)
			strike_area(point, 1.8, float(stats[i]["sp_dmg"]))
			if point.distance_to(end)<1.8 and clear_path(i,start,end):
				damage(i,float(stats[i]["sp_dmg"]), true, point, true)
		else:
			var color := Color.SILVER if kind == "spear" else (Color.ORANGE_RED if kind == "fire" else (Color.DARK_ORANGE if kind == "bomb" else Color.GOLD))
			var mesh: Node3D
			if kind == "spear": mesh = make_flying_spear()
			elif kind == "bomb":
				mesh = MagmaBomb.instantiate() as Node3D
				mesh.scale = Vector3.ONE * 0.65
			elif kind == "quake": mesh = make_wave(Color.GOLD if kinds[i] == "W" else Color(0.5, 0.85, 1.0))
			else: mesh = orb(color, 0.22)
			add_child(mesh)
			mesh.position = start
			if kind == "spear":
				mesh.look_at(start + face, Vector3.FORWARD if absf(face.y) > 0.98 else Vector3.UP)
				spear_recovery[i] = 0.38
				if is_instance_valid(pawn_weapons[i]): pawn_weapons[i].hide()
			if kind == "quake":
				mesh.look_at(start + face, Vector3.FORWARD if absf(face.y) > 0.98 else Vector3.UP)
			if kind == "fire":
				mesh.hide()
				var fx := FireballFX.instantiate() as PyroluxFireball3D
				fx.autoplay = false
				fx.hit_mode = PyroluxFireball3D.HitMode.RAYCAST
				fx.travel_range = 24.0
				fx.impact_scorch = false
				add_child(fx)
				fx.launch_direction(start, face, 12.0)
				if is_instance_valid(fx._ray): fx._ray.add_exception(bodies[i])
				get_tree().create_timer(6.0).timeout.connect(fx.queue_free)
			var velocity := face.normalized()*(8.0 if kind == "quake" else 12.0)
			if kind == "bomb": velocity *= 0.85
			if kind == "quake": velocity = face.normalized()*9.0
			projectiles.append({"mesh":mesh,"owner":i,"velocity":velocity,"kind":kind,"life":2.0})
	else:
		var horizontal := Vector3(delta.x,0,delta.z)
		if horizontal.length() <= float(stats[i]["reach"])+1.2 and absf(delta.y)<1.8 and face.dot((end-start).normalized())>=0.65 and clear_path(i,start,end):
			damage(i,float(stats[i]["dmg"]) * (0.5 if kinds[i] == "Q" else 1.0))
		else:
			var hit := prop_ray(i, start, start + face * (float(stats[i]["reach"])+1.2))
			if not strike_prop(hit.get("collider"), float(stats[i]["dmg"]), false) and i == 0: notify("MISS - move closer / face enemy")
		if i == 0: effect(start+face*1.0,Color.WHITE,0.25)
func update_projectiles(dt: float) -> void:
	for index in range(projectiles.size()-1,-1,-1):
		var p := projectiles[index]
		var mesh: Node3D = p["mesh"]
		var i: int = p["owner"]
		var velocity: Vector3 = p["velocity"]
		if p["kind"] == "bomb":
			velocity.y -= 9.0*dt
			mesh.rotate_x(dt * 5.0)
			mesh.rotate_z(dt * 3.0)
			if int(p["life"] * 20.0) != int((p["life"] - dt) * 20.0):
				burst(mesh.position, Color.ORANGE_RED, 2, 0.25, false)
		p["velocity"] = velocity
		var next := mesh.position+velocity*dt
		var query := PhysicsRayQueryParameters3D.create(mesh.position,next)
		query.exclude = [bodies[i].get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		p["life"] -= dt
		if not hit.is_empty() or p["life"]<=0:
			var pos: Vector3 = hit.get("position",next)
			var impact_played: bool = not hit.is_empty() or p["kind"] == "bomb"
			if impact_played:
				fx_sound("projectile_impact" if p["kind"] == "spear" else "special_impact", pos, kinds[i])
			if p["kind"] == "bomb": strike_area(pos, BOMB_RADIUS, float(stats[i]["sp_dmg"]))
			else: strike_prop(hit.get("collider"), float(stats[i]["sp_dmg"]), true)
			if hit.get("collider") == bodies[1-i] or (p["kind"] == "bomb" and pos.distance_to(bodies[1-i].position+Vector3.UP) <= BOMB_RADIUS and clear_path(i,pos+Vector3.UP*0.1,bodies[1-i].position+Vector3.UP)):
				damage(i,float(stats[i]["sp_dmg"]), true, pos, impact_played)
			if p["kind"] == "spear":
				spear_impact(pos)
			elif p["kind"] == "bomb":
				fx_ring(pos, Color.ORANGE_RED, BOMB_RADIUS / 0.51, 0.38)
				burst(pos, Color.ORANGE_RED, 28, BOMB_RADIUS)
				effect(pos, Color.GOLD, 1.2)
				shake = 0.22
			elif p["kind"] == "quake":
				burst(pos, Color.GOLD, 14, 1.0)
			else:
				effect(pos,Color.ORANGE,0.9)
			mesh.queue_free()
			projectiles.remove_at(index)
		else: mesh.position = next
func update_camera() -> void:
	var subject := 1 if lan_role == 2 else 0
	var pivot := bodies[subject].position+Vector3(0,1.8,0)
	var steep := smoothstep(deg_to_rad(35.0),deg_to_rad(75.0),-pitch)
	var offset := Vector3(1.65*steep,0,5.2).rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
	var query := PhysicsRayQueryParameters3D.create(pivot,pivot+offset)
	query.exclude = [bodies[0].get_rid(),bodies[1].get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var distance := offset.length() if hit.is_empty() else maxf(0.15,pivot.distance_to(hit.position)-0.2)
	camera.position = pivot+offset.normalized()*distance
	# Keep the reticle direction stable even when the camera boom is shortened.
	camera.rotation = Vector3(pitch,yaw,0.0)
	camera.h_offset = sin(shake*110.0)*shake*0.35 + sin(elapsed*38.0)*collapse_shake*0.12
	camera.v_offset = cos(elapsed*31.0)*collapse_shake*0.07
func _exit_tree() -> void:
	get_node("/root/Sound").stop_ambience(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Visual-only poses: no collision or aiming transforms are changed.
# Animation selection uses the imported, independently authored bone clips.
# Timed actions use a custom playback rate. A short crossfade avoids per-frame seeks.
func play_rig(i: int, clip: String, duration: float = -1.0) -> void:
	var anim := rig_players[i]
	if anim == null or not anim.has_animation(clip): return
	if rig_states[i] == clip: return
	var same_clip := String(anim.assigned_animation) == clip
	rig_states[i] = clip
	var blend := 0.045 if duration > 0.0 else 0.10
	var speed := anim.get_animation(clip).length / duration if duration > 0.0 else 1.0
	if same_clip:
		anim.stop(true)
	anim.play(clip, blend if not same_clip else 0.0, speed)

func animate_pose(i: int, dt: float, running: bool, sprinting: bool = false) -> void:
	var model := models[i]
	var grounded := ground_known[i] if lan_role == 2 else bodies[i].is_on_floor()
	pose_time[i] = maxf(0.0, pose_time[i] - dt)
	jump_pose[i] = maxf(0.0, jump_pose[i] - dt)
	landing_pose[i] = maxf(0.0, landing_pose[i] - dt)
	perfect_pose[i] = maxf(0.0, perfect_pose[i] - dt)
	step_fx[i] = maxf(0.0, step_fx[i] - dt)
	Rig.flash(model, flashes[i] / 0.22)
	if kinds[i] == "P":
		spear_recovery[i] = maxf(0.0, spear_recovery[i] - dt)
		if is_instance_valid(pawn_weapons[i]): pawn_weapons[i].visible = spear_recovery[i] <= 0.0
	if kinds[i] == "R" and is_instance_valid(held_bombs[i]):
		held_bombs[i].visible = pose_power[i] and pose_time[i] > pose_length[i] - 0.34
	if (i == 0 and dodge_time > 0.0) or (i == 1 and lan_role > 0 and lan_dodge_time > 0.0):
		play_rig(i, lan_dodge_clip if i == 1 else dodge_clip, 0.20)
		if step_fx[i] <= 0.0:
			step_fx[i] = 0.09
			burst(bodies[i].position + Vector3.UP * 0.35, FX_COLORS[kinds[i]], 4, 0.4, false)
	elif perfect_pose[i] > 0.0:
		play_rig(i, "PerfectBlock", 0.26)
	elif guarding[i]:
		play_rig(i, "Block")
	elif flashes[i] > 0.0:
		play_rig(i, "Hit", 0.22)
	elif pose_time[i] > 0.0:
		var clip := "Special" if pose_power[i] else ("Attack" if combo_active[i] == 1 else "Attack%d" % combo_active[i])
		play_rig(i, clip, pose_length[i])
	elif not grounded:
		if jump_pose[i] > 0.0:
			play_rig(i, "JumpStart", 0.16)
		else:
			play_rig(i, "Airborne")
	elif landing_pose[i] > 0.0:
		play_rig(i, "Landing", 0.24)
	elif running:
		play_rig(i, "Run" if sprinting or i == 1 else "Walk")
		if step_fx[i] <= 0.0:
			step_fx[i] = float(FOOT_INTERVAL[kinds[i]]) * (0.80 if sprinting else 1.3)
			footstep(i, false)
	else:
		play_rig(i, "Idle")

func animate_end(i: int) -> void:
	Rig.flash(models[i], 0.0)
	if i == end_winner:
		play_rig(i, "Victory", 1.4)
		if kinds[i] == "P" and is_instance_valid(pawn_weapons[i]): pawn_weapons[i].show()
		if kinds[i] == "R" and is_instance_valid(held_bombs[i]): held_bombs[i].show()
	else:
		play_rig(i, "Death", 0.75)
		if kinds[i] == "R" and is_instance_valid(held_bombs[i]): held_bombs[i].hide()

# Lightweight voxel spear, aligned along local -Z (flight direction).
func make_flying_spear() -> MeshInstance3D:
	var root := MeshInstance3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.055, 0.055, 1.05)
	root.mesh = shaft
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.45, 0.24, 0.10)
	root.material_override = wood
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.12
	cone.height = 0.32
	cone.radial_segments = 4
	tip.mesh = cone
	tip.rotation.x = -PI / 2.0
	tip.position.z = -0.65
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.85, 0.9, 0.95)
	metal.metallic = 0.6
	tip.material_override = metal
	root.add_child(tip)
	for j in range(5):
		var streak := MeshInstance3D.new()
		var strip := BoxMesh.new()
		strip.size = Vector3(0.025, 0.025, 0.22)
		streak.mesh = strip
		streak.position.z = 0.65 + float(j) * 0.23
		var glow := StandardMaterial3D.new()
		glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow.albedo_color = Color(1.0, 0.85, 0.45, 0.75 - float(j) * 0.13)
		streak.material_override = glow
		root.add_child(streak)
	return root

func spear_impact(pos: Vector3) -> void:
	_lan_fx("spear", [_lan_array(pos)])
	for j in range(8):
		var spark := orb(Color.GOLD, 0.045)
		add_child(spark)
		spark.position = pos
		var angle := float(j) * TAU / 8.0
		var offset := Vector3(cos(angle), 0.35 + float(j % 3) * 0.15, sin(angle)) * 0.65
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", pos + offset, 0.22)
		tw.tween_property(spark, "scale", Vector3.ONE * 0.02, 0.22)
		tw.chain().tween_callback(spark.queue_free)

func burst(pos: Vector3, color: Color, count: int, radius: float, replicate: bool = true) -> void:
	if replicate: _lan_fx("burst", [_lan_array(pos), color.to_html(), count, radius])
	for j in range(count):
		var spark := orb(color, 0.045 + float(j % 3) * 0.025)
		add_child(spark)
		spark.position = pos
		var angle := float(j) * 2.39996
		var offset := Vector3(cos(angle), 0.15 + float(j % 5) * 0.18, sin(angle)) * radius
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spark, "position", pos + offset, 0.32)
		tw.tween_property(spark, "scale", Vector3.ONE * 0.01, 0.32)
		tw.chain().tween_callback(spark.queue_free)

func make_wave(color: Color) -> Node3D:
	var root := Node3D.new()
	for j in range(9):
		var angle := (float(j) - 4.0) * 0.22
		var segment := orb(color, 0.14)
		root.add_child(segment)
		segment.position = Vector3(sin(angle) * 1.25, 0.0, -cos(angle) * 0.65)
		segment.scale = Vector3(1.6, 0.55, 1.0)
	return root

func arena_visual(scene: PackedScene, parent: Node3D, pos: Vector3, sizing: Vector3, angle: float = 0.0) -> Node3D:
	var visual := scene.instantiate() as Node3D
	parent.add_child(visual)
	visual.position = pos
	visual.scale = sizing
	visual.rotation.y = angle
	return visual

func moving_block(size: Vector3, pos: Vector3, color: Color) -> AnimatableBody3D:
	var root := AnimatableBody3D.new()
	root.sync_to_physics = false
	add_child(root)
	root.position = pos
	visuals.box_at(root, size, Vector3.ZERO, visuals.material(color))
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	root.add_child(col)
	return root

func build_islands(grass: Color, rock: Color) -> void:
	var center := block(Vector3(16, 0.8, 16), Vector3(0,-0.4,0), grass)
	center.get_child(0).material_override = visuals.grass_material(grass)
	arena_visual(IslandMesh, center, Vector3(0,-0.46,0), Vector3(0.76,0.76,0.74))
	visuals.decorate_center(center)
	for index in range(4):
		var d: Vector3 = ISLAND_DIRS[index]
		var size := Vector3(4,0.8,16) if absf(d.x)>0.5 else Vector3(16,0.8,4)
		var edge := moving_block(size, d*10.0+Vector3.DOWN*0.4, grass)
		edge_parts.append(edge)
		visuals.decorate_edge(edge,size,grass,rock)
		var island := moving_block(Vector3(8,0.8,8), d*19.0+Vector3.DOWN*0.4, grass)
		var theme: Color = ISLAND_COLORS[index]
		island.get_child(0).material_override = visuals.grass_material(grass.lerp(theme,0.35))
		arena_visual(SmallMesh,island,Vector3(0,-0.45,0),Vector3(0.38,0.38,0.37))
		visuals.decorate_satellite(island,index)
		arena_parts.append(island)
		build_bridge(index, d)
		decorate_island_role(island,index,d,rock)
		make_wind(d*13.5+Vector3(-d.z,0,d.x)*2.4,index)
		register_collapse(island, 20.0+index*4.0, index)
		register_collapse(edge, 36.0+index*3.0, -1)
	make_cover(center, Vector3(-5.2,0.85,-4.8), Vector3(2.4,1.7,0.65),rock,false)
	make_cover(center, Vector3(5.2,0.85,4.8), Vector3(0.65,1.7,2.4),rock,false)
	make_cover(center, Vector3(5.2,1.15,-4.8), Vector3(1.0,2.3,1.0),rock,true)
	make_cover(center, Vector3(-5.2,1.15,4.8), Vector3(1.0,2.3,1.0),rock,true)
	ferry = moving_block(Vector3(3.2,0.5,2.5), Vector3(ferry_x,-0.25,3.0),rock)
	ferry.get_child(0).material_override = visuals.grass_material(grass)
	visuals.box_at(ferry,Vector3(2.5,0.55,1.9),Vector3.DOWN*0.5,visuals.material(rock.darkened(0.2)))
	visuals.pad(ferry,Vector3(0,0.25,0))
	pads = [Vector3(-6,0,0),Vector3(6,0,0)]
	for p in pads: visuals.pad(self,p)
	crystal = orb(Color.GOLD,0.42)
	var gem := SphereMesh.new()
	gem.radius = 0.42
	gem.height = 1.18
	gem.radial_segments = 6
	gem.rings = 2
	crystal.mesh = gem
	add_child(crystal)
	crystal_icon = make_shard_icon(crystal,Vector3.UP*0.94,0.0030)
	crystal.hide()

func make_shard_icon(parent: Node3D, pos: Vector3, icon_pixel_size: float) -> Sprite3D:
	var icon := Sprite3D.new()
	icon.texture = SHARD_TEXTURES[0]
	icon.pixel_size = icon_pixel_size
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(icon)
	icon.position = pos
	return icon

func show_shard_icon(i: int, kind: int) -> void:
	shard_popup_seq[i] += 1
	_display_shard_icon(i, kind, SHARD_POPUP_DURATION)

func _display_shard_icon(i: int, kind: int, duration: float) -> void:
	var icon := shard_icons[i]
	shard_icon_kind[i] = kind
	icon.texture = SHARD_TEXTURES[kind]
	icon.position.y = float(Data.FIGHT_H[kinds[i]])+0.46
	icon.modulate = Color.WHITE
	icon.scale = Vector3.ONE * 0.8
	shard_icon_time[i] = duration
	icon.show()

func update_shard_icons(dt: float) -> void:
	for i in range(shard_icons.size()):
		if shard_icon_time[i] <= 0.0: continue
		var icon := shard_icons[i]
		shard_icon_time[i] = maxf(0.0,shard_icon_time[i]-dt)
		var remaining := shard_icon_time[i]
		if remaining <= 0.0 or hp[i] <= 0.0:
			icon.hide()
			shard_icon_time[i] = 0.0
			continue
		var age := SHARD_POPUP_DURATION-remaining
		icon.position.y = float(Data.FIGHT_H[kinds[i]])+0.46+0.22*clampf(age/SHARD_POPUP_DURATION,0.0,1.0)
		var popup_scale := lerpf(0.8,1.0,clampf(age/0.14,0.0,1.0))
		icon.scale = Vector3.ONE*popup_scale
		icon.modulate = Color(1.0,1.0,1.0,clampf(remaining/0.50,0.0,1.0))

func decorate_island_role(island: Node3D, index: int, d: Vector3, rock: Color) -> void:
	var theme: Color = ISLAND_COLORS[index]
	match index:
		0:
			# Low ceremonial altar and gold pylons, no invisible collision obstacles.
			visuals.box_at(island,Vector3(2.8,0.08,2.8),Vector3.UP*0.44,visuals.material(rock.darkened(0.2)))
			ring_at(island,Vector3.UP*0.51,1.2,theme)
			var diamond := visuals.box_at(island,Vector3(0.64,0.035,0.64),Vector3.UP*0.53,luminous(theme),false)
			diamond.rotation.y = PI/4.0
			for x in [-1.2,1.2]:
				for z in [-1.2,1.2]:
					visuals.box_at(island,Vector3(0.18,0.50,0.18),Vector3(x,0.69,z),luminous(theme),false)
		1:
			var gray := Color("77838c")
			# Open center lane from bridge; collision-backed ruins to either side.
			make_cover(island,d*19.0+Vector3(0,1.2,-2.45),Vector3(1.15,2.4,1.15),gray,true)
			make_cover(island,d*19.0+Vector3(-1.5,0.8,2.45),Vector3(2.4,1.6,0.65),gray,false)
			make_cover(island,d*19.0+Vector3(1.9,1.0,2.45),Vector3(1.0,2.0,1.0),gray,true)
		2:
			# The dedicated wind island has the widest, highest vortex.
			make_wind(Vector3.UP*0.4,index,island,1.9,9.0)
			for x in [-2.8,2.8]:
				visuals.box_at(island,Vector3(0.22,1.2,0.22),Vector3(x,1.0,2.7),luminous(theme),false)
		3:
			visuals.box_at(island,Vector3(2.7,0.08,2.7),Vector3.UP*0.44,visuals.material(rock))
			heal_ring = ring_at(island,Vector3.UP*0.51,1.3,theme)
			heal_marks.append(visuals.box_at(island,Vector3(1.12,0.04,0.27),Vector3.UP*0.53,luminous(theme),false))
			heal_marks.append(visuals.box_at(island,Vector3(0.27,0.04,1.12),Vector3.UP*0.53,luminous(theme),false))
			arena_visual(TreeMesh,island,Vector3(2.65,0.4,2.65),Vector3.ONE)
			arena_visual(FlowerMesh,island,Vector3(-2.65,0.4,2.65),Vector3.ONE)

func update_heal() -> void:
	_update_heal_visual()
	if not is_instance_valid(heal_ring) or elapsed >= 32.0: return
	var remaining := maxf(0.0,heal_ready_at-elapsed)
	if remaining > 0.0: return
	var point := heal_ring.global_position
	for i in range(2):
		var delta := bodies[i].global_position-point
		var max_hp := float(stats[i]["hp"])
		if Vector2(delta.x,delta.z).length() < 1.3 and absf(delta.y) < 0.8 and hp[i] > 0.0 and hp[i] < max_hp-0.01:
			hp[i] = minf(max_hp,hp[i]+max_hp*0.10)
			heal_ready_at = elapsed+8.0
			burst(point+Vector3.UP*0.3,Color.LIME_GREEN,12,0.9)
			show_shard_icon(i,2)
			fx_sound("shard", point)
			break

func _update_heal_visual() -> void:
	if not is_instance_valid(heal_ring): return
	if elapsed >= 32.0:
		heal_ring.hide()
		for mark in heal_marks:
			if is_instance_valid(mark): mark.hide()
		return
	var remaining := maxf(0.0,heal_ready_at-elapsed)
	heal_ring.visible = remaining <= 0.0
	for mark in heal_marks:
		if is_instance_valid(mark):
			var mat := mark.material_override as StandardMaterial3D
			var shade := ISLAND_COLORS[3].lerp(Color("274d35"),clampf(remaining/0.35,0.0,1.0))
			mat.albedo_color = shade
			mat.emission = shade

func bridge_deck_height(boundary: int) -> float:
	# The first and last planks are flat, overlapping the island at Y=0.
	var t := clampf((float(boundary)-1.0)/15.0,0.0,1.0)
	return -BRIDGE_SAG*4.0*t*(1.0-t)

func build_bridge(index: int, d: Vector3) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = d*13.5
	root.rotation.y = 0.0 if absf(d.x)>0.5 else PI/2.0
	var visual := BridgeMesh.instantiate() as Node3D
	root.add_child(visual)
	var planks: Array[Node3D] = []
	var ropes: Array[Node3D] = []
	var posts: Array[Node3D] = []
	for child in visual.find_children("*", "MeshInstance3D", true, false):
		var part := child as MeshInstance3D
		var part_name := String(part.name)
		if part_name.begins_with("Plank_"):
			var body := AnimatableBody3D.new()
			body.sync_to_physics = false
			root.add_child(body)
			body.global_transform = part.global_transform
			part.reparent(body, true)
			var number := int(part_name.get_slice("_",1))
			var bounds := part.mesh.get_aabb()
			# A separate sloped convex prism per plank follows the same profile as the GLB.
			# Tiny overlap at the seams; no collider remains across a destroyed plank.
			var slope := (bridge_deck_height(number+1)-bridge_deck_height(number))/BRIDGE_PITCH
			var half_span := BRIDGE_PITCH*0.5+0.001
			var points := PackedVector3Array()
			for x in [-half_span, half_span]:
				for z in [bounds.position.z, bounds.end.z]:
					var top: float = slope*float(x)
					points.append(Vector3(x,top,z))
					points.append(Vector3(x,top-0.09,z))
			var ramp := ConvexPolygonShape3D.new()
			ramp.points = points
			ramp.margin = 0.001
			var shape := CollisionShape3D.new()
			shape.shape = ramp
			body.add_child(shape)
			body.set_meta("bridge", index)
			body.set_meta("plank", number)
			planks.append(body)
		elif part_name.begins_with("Rope_"):
			part.reparent(root,true)
			ropes.append(part)
		else:
			part.reparent(root,true)
			posts.append(part)
	visual.queue_free()
	bridges.append(root)
	bridge_info.append({"root":root,"planks":planks,"ropes":ropes,"posts":posts,"broken":false,"gap_min":99.0,"gap_max":-99.0,"cut":false,"base":root.position,"rotation":root.rotation})

func drop_piece(node: Node3D, duration: float, delay: float = 0.0) -> void:
	if not is_instance_valid(node) or node.has_meta("dropping"): return
	node.set_meta("dropping", true)
	var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).bind_node(node)
	if delay > 0.0: tw.tween_interval(delay)
	tw.tween_callback(func():
		for child in node.find_children("*", "CollisionShape3D", true, false): child.set_deferred("disabled", true)
	)
	tw.tween_property(node,"position:y",node.position.y-12.0,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node,"rotation",node.rotation+Vector3(0.8,0.2,1.0),duration)
	tw.tween_callback(node.queue_free)

func cut_bridge(index: int) -> void:
	var info := bridge_info[index]
	if info["cut"]: return
	info["cut"] = true
	var root: Node3D = info["root"]
	if not is_instance_valid(root): return
	if lan_role != 2:
		fx_sound("impactPlank_medium_001", root.global_position)
		burst(root.global_position+Vector3.UP*0.5,Color("b78e62"),10,1.0)
	# Each original rope half snaps and rotates down independently.
	for rope in info["ropes"]:
		if is_instance_valid(rope): drop_piece(rope,1.05)
	for plank in info["planks"]:
		if is_instance_valid(plank):
			var delay := float(abs(int(plank.get_meta("plank"))-8))*0.035
			drop_piece(plank,1.2,delay)
	for post in info["posts"]:
		if is_instance_valid(post): drop_piece(post,1.4,0.25)

func break_planks(index: int, plank_index: int) -> bool:
	var info := bridge_info[index]
	if info["broken"] or info["cut"]: return false
	info["broken"] = true
	fx_sound("impactWood_heavy_003", info["root"].global_position)
	var first := clampi(plank_index-2, 1, 10)
	for plank in info["planks"]:
		if not is_instance_valid(plank): continue
		var number := int(plank.get_meta("plank"))
		if number >= first and number < first+6:
			var d: Vector3 = ISLAND_DIRS[index]
			var along: float = plank.global_position.dot(d)
			info["gap_min"] = minf(float(info["gap_min"]),along-0.11)
			info["gap_max"] = maxf(float(info["gap_max"]),along+0.11)
			burst(plank.global_position,Color("b78e62"),3,0.45)
			drop_piece(plank,0.9,float(abs(number-plank_index))*0.035)
	notify("BRIDGE DAMAGED - JUMP THE GAP")
	return true

func register_collapse(part: Node3D, at: float, index: int) -> void:
	collapses.append({"part":part,"at":at,"index":index,"base":part.position,"rot":part.rotation,"state":0,"dust":0.0})

func mark_cracks(part: Node3D, index: int) -> void:
	var mat := luminous(Color("c47a36"))
	var direction := Vector3.RIGHT
	var length := 5.0
	if index < 0:
		var local_dir := Vector3(part.position.x,0,part.position.z)
		direction = Vector3.FORWARD if absf(local_dir.x)>absf(local_dir.z) else Vector3.RIGHT
		length = 10.0
	var sideways := Vector3(-direction.z,0,direction.x)
	for i in range(6):
		var a := direction*(-length*0.5+length*float(i)/6.0)+sideways*(0.18 if i%2==0 else -0.18)+Vector3.UP*0.415
		var b := direction*(-length*0.5+length*float(i+1)/6.0)+sideways*(-0.18 if i%2==0 else 0.18)+Vector3.UP*0.415
		var seg := visuals.box_at(part,Vector3(0.055,0.022,a.distance_to(b)),(a+b)*0.5,mat,false)
		seg.rotation.y = atan2(b.x-a.x,b.z-a.z)

func update_collapses() -> void:
	danger_text = ""
	for event in collapses:
		if int(event["state"]) >= 2 or not is_instance_valid(event["part"]): continue
		var part: Node3D = event["part"]
		var until := float(event["at"])-elapsed
		var index := int(event["index"])
		if until > 5.0: continue
		if until > 0.0:
			if int(event["state"]) == 0:
				event["state"] = 1
				mark_cracks(part, index)
				notify("COLLAPSE WARNING")
			var strength := clampf((5.0-until)/5.0,0.0,1.0)
			var base: Vector3 = event["base"]
			var rot: Vector3 = event["rot"]
			var tilt := maxf(0.0, 1.0-until/1.4)*0.17
			part.position = base + Vector3(sin(elapsed*34.0)*0.07,cos(elapsed*31.0)*0.035,cos(elapsed*38.0)*0.07)*strength
			part.rotation = rot + Vector3(sin(elapsed*28.0)*0.012+tilt,0,cos(elapsed*27.0)*0.012)*strength
			if elapsed >= float(event["dust"]):
				event["dust"] = elapsed + 0.35
				burst(part.global_position+Vector3(arena_rng.randf_range(-1.8,1.8),0.5,arena_rng.randf_range(-1.8,1.8)),Color("ab9072"),4,0.55)
			if index >= 0:
				var info := bridge_info[index]
				var bridge: Node3D = info["root"]
				var bbase: Vector3 = info["base"]
				var brot: Vector3 = info["rotation"]
				# Preserve the curved walkable profile until the ropes actually snap.
				var d: Vector3 = ISLAND_DIRS[index]
				bridge.position = bbase + Vector3(-d.z,0,d.x)*sin(elapsed*24.0)*0.025*strength
				bridge.rotation = brot
			if danger_text.is_empty(): danger_text = "%.1fs" % until
			if bodies[0].position.distance_to(part.global_position)<15.0: collapse_shake = maxf(collapse_shake,0.20*strength)
		elif int(event["state"]) < 2:
			event["state"] = 2
			fx_sound("impactMining_003", part.global_position)
			if index >= 0: cut_bridge(index)
			collapse_shake = maxf(collapse_shake,0.75)
			burst(part.global_position+Vector3.UP*0.6,Color("9f866d"),14,2.8)
			# Animatable body carries grounded fighters during the initial drop.
			# Disable collisions only after it has descended well below the walkable surface.
			var tw := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).bind_node(part)
			tw.set_parallel(true)
			tw.tween_property(part,"position:y",part.position.y-18.0,1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(part,"rotation",part.rotation+Vector3(0.35,0.05,0.22),1.8)
			tw.chain().tween_callback(part.queue_free)

func make_cover(parent: Node3D, pos: Vector3, size: Vector3, rock: Color, pillar: bool) -> void:
	var cover := block(size,pos,rock.lightened(0.12))
	cover.reparent(parent,true)
	cover.set_meta("cover_index",covers.size())
	var top := visuals.material(rock.darkened(0.17))
	if pillar:
		visuals.box_at(cover, Vector3(size.x*1.2,0.18,size.z*1.2),Vector3.UP*(size.y*0.5-0.08),top)
		visuals.box_at(cover, Vector3(size.x*1.15,0.18,size.z*1.15),Vector3.DOWN*(size.y*0.5-0.08),top)
	else:
		for i in range(3):
			visuals.box_at(cover,Vector3(size.x*1.02,0.04,size.z*1.02),Vector3.UP*(-size.y*0.34+float(i)*size.y*0.33),top)
	covers.append({"node":cover,"hp":36.0 if pillar else 28.0,"size":size,"color":rock})

func prop_ray(i: int, start: Vector3, end: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start,end)
	query.exclude = [bodies[i].get_rid(), bodies[1-i].get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func strike_prop(collider: Object, amount: float, power: bool) -> bool:
	if not is_instance_valid(collider): return false
	if collider.has_meta("cover_index"):
		var info := covers[int(collider.get_meta("cover_index"))]
		if not is_instance_valid(info["node"]): return false
		var node: Node3D = info["node"]
		if node.is_queued_for_deletion(): return false
		info["hp"] = float(info["hp"])-amount
		burst(node.global_position,info["color"],5,0.65)
		if float(info["hp"]) <= 0.0:
			for child in node.find_children("*","CollisionShape3D",true,false): child.set_deferred("disabled",true)
			var size: Vector3 = info["size"]
			for i in range(7):
				var debris := visuals.box_at(self,size*0.24,node.global_position+Vector3(arena_rng.randf_range(-0.45,0.45),arena_rng.randf_range(-0.5,0.5),arena_rng.randf_range(-0.45,0.45)),visuals.material(info["color"]))
				drop_piece(debris,0.65)
			node.queue_free()
			notify("COVER DESTROYED")
		else: notify("COVER HIT")
		return true
	if power and collider.has_meta("bridge") and collider.has_meta("plank"):
		return break_planks(int(collider.get_meta("bridge")),int(collider.get_meta("plank")))
	return false

func strike_area(point: Vector3, radius: float, amount: float) -> void:
	for info in covers:
		if not is_instance_valid(info["node"]): continue
		var node: Node3D = info["node"]
		if not node.is_queued_for_deletion() and node.global_position.distance_to(point)<radius:
			strike_prop(node,amount,true)
	for index in range(bridge_info.size()):
		var info := bridge_info[index]
		if info["cut"] or info["broken"]: continue
		var nearest: Node3D = null
		var dist := radius
		for plank in info["planks"]:
			if is_instance_valid(plank) and plank.global_position.distance_to(point)<dist:
				dist = plank.global_position.distance_to(point)
				nearest = plank
		if nearest != null: break_planks(index,int(nearest.get_meta("plank")))

func luminous(color: Color) -> StandardMaterial3D:
	var mat := visuals.material(color)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color
	return mat

func ring_at(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius*0.91
	mesh.outer_radius = radius
	mesh.rings = 20
	mesh.ring_segments = 8
	return visuals.mesh_at(parent,mesh,pos,luminous(color),Vector3(1,0.25,1),false)

func make_wind(pos: Vector3, index: int, parent: Node3D = null, radius: float = 1.45, height: float = 7.5) -> void:
	var root := WindVortex.new()
	if parent == null: add_child(root)
	else: parent.add_child(root)
	root.position = pos
	root.setup(radius,height)
	winds.append({"root":root,"index":index,"radius":radius,"height":height})

func apply_wind(body: CharacterBody3D, dt: float) -> void:
	for wind in winds:
		if not is_instance_valid(wind["root"]): continue
		var root: Node3D = wind["root"]
		if not root.visible: continue
		var offset := body.global_position-root.global_position
		if Vector2(offset.x,offset.z).length() < float(wind["radius"]) and offset.y > -2.0 and offset.y < float(wind["height"]):
			body.velocity.y = minf(11.0,maxf(body.velocity.y,3.0)+dt*46.0)
			break

func update_ferry(dt: float) -> void:
	if not is_instance_valid(ferry): return
	if elapsed < 15.0:
		ferry_x += ferry_direction*2.5*dt
		if ferry_x >= 16.4:
			ferry_x = 16.4
			ferry_direction = -1.0
		elif ferry_x <= 10.0:
			ferry_x = 10.0
			ferry_direction = 1.0
	else:
		# Ferry returns to the center, stays as alternate footing until edge collapse.
		ferry_x = move_toward(ferry_x,7.0,dt*3.8)
	ferry.position.x = ferry_x

func update_crystals(dt: float) -> void:
	for i in range(2):
		boost[i] = maxf(0.0,boost[i]-dt)
		speed_boost[i] = maxf(0.0,speed_boost[i]-dt)
		push_boost[i] = maxf(0.0,push_boost[i]-dt)
	boost_timer -= dt
	if boost_timer <= 0.0 and elapsed < 45.0:
		if crystal_cycle.is_empty():
			crystal_cycle.assign([0,1,2,3,4])
			crystal_cycle.shuffle()
		crystal_kind = crystal_cycle.pop_back()
		crystal.material_override = luminous(CRYSTAL_COLORS[crystal_kind])
		var spots := [Vector3(0,0.8,0),Vector3(3.5,0.8,2.5),Vector3(-3.5,0.8,-2.5),Vector3(3.5,0.8,-2.5),Vector3(-3.5,0.8,2.5)]
		crystal_on_east = not island_warning(0)
		crystal.position = Vector3(19,0.8,0) if crystal_on_east else spots[arena_rng.randi_range(0,spots.size()-1)]
		crystal_icon.texture = SHARD_TEXTURES[crystal_kind]
		crystal.show()
		boost_timer = 8.0
	if crystal.visible and elapsed < 45.0:
		if crystal_on_east and elapsed >= 20.0:
			crystal_on_east = false
			crystal.position = Vector3(0,0.8,0)
		crystal.rotation.y += dt*2.0
		crystal.position.y = 0.8+sin(elapsed*3.5)*0.10
		var collector := -1
		var closest := 1.4
		for i in range(2):
			var distance := bodies[i].position.distance_to(crystal.position)
			if hp[i] > 0.0 and distance < closest:
				collector = i
				closest = distance
		if collector >= 0:
			match crystal_kind:
				0: boost[collector] = 5.0
				1: speed_boost[collector] = 5.0
				2: hp[collector] = minf(float(stats[collector]["hp"]),hp[collector]+float(stats[collector]["hp"])*0.10)
				3: special[collector] = 0.0
				4: push_boost[collector] = 5.0
			burst(crystal.global_position,CRYSTAL_COLORS[crystal_kind],10,0.7)
			crystal.hide()
			show_shard_icon(collector,crystal_kind)
			fx_sound("shard", crystal.global_position)
	else: crystal.hide()

func update_storm(_dt: float) -> void:
	storm_amount = clampf((elapsed-30.0)/12.0,0.0,1.0)
	visuals.update_storm(storm_amount)
	if is_instance_valid(sun):
		sun.light_energy = lerpf(1.15,0.48,storm_amount)
		sun.light_color = Color("fff0d2").lerp(Color("aab9f0"),storm_amount)
	if elapsed >= storm_visual_at and elapsed < 42.3 and is_instance_valid(camera) and camera.environment != null:
		storm_visual_at = elapsed + 0.20
		var env := camera.environment
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
		sky_mat.sky_top_color = Color("3179bb").lerp(Color("29324c"),storm_amount)
		sky_mat.sky_horizon_color = Color("d4efff").lerp(Color("838da9"),storm_amount)
		env.fog_light_color = Color("b2d5ee").lerp(Color("747e9a"),storm_amount)
		env.fog_density = lerpf(0.009,0.018,storm_amount)
	if is_instance_valid(lightning_warning):
		lightning_warning.scale = Vector3(1.0+sin(elapsed*24.0)*0.07,0.25,1.0+sin(elapsed*24.0)*0.07)
		if elapsed >= lightning_at:
			var point := lightning_warning.global_position
			lightning_warning.queue_free()
			lightning_warning = null
			lightning_strike(point)
	elif elapsed >= next_lightning:
		var target := bodies[arena_rng.randi_range(0,1)].position
		var point := Vector3(clampf(target.x,-6.2,6.2),0.07,clampf(target.z,-6.2,6.2))
		lightning_warning = ring_at(self,point,1.8,Color("ffb348"))
		lightning_at = elapsed+1.25
		next_lightning = elapsed+4.0
		notify("LIGHTNING - LEAVE THE ORANGE RING")

func lightning_strike(point: Vector3) -> void:
	_lan_fx("lightning", [_lan_array(point)])
	_lightning_visual(point)
	burst(point,Color("c8e6ff"),16,1.6)
	strike_area(point,1.7,18.0)
	collapse_shake = maxf(collapse_shake,0.35)
	for i in range(2):
		var delta := bodies[i].position-point
		if Vector2(delta.x,delta.z).length()<1.8 and absf(delta.y)<3.5 and not ((i == 0 and dodge_time > 0) or (i == 1 and lan_role == 1 and lan_dodge_time > 0)):
			var before := hp[i]
			hp[i] = maxf(0.0,hp[i]-float(stats[i]["hp"])*0.08)
			fx_popup(bodies[i].position + Vector3.UP * (float(Data.FIGHT_H[kinds[i]])+0.3), before-hp[i], Color("c8e6ff"))
			flashes[i] = 0.22
			knockback[i] = Vector3(delta.x,0,delta.z).normalized()*3.0
			notify("LIGHTNING HIT")

func _lightning_visual(point: Vector3) -> void:
	get_node("/root/Sound").play_spatial("thunder", point, self)
	var mat := luminous(Color("d6e9ff"))
	for i in range(5):
		var a := point+Vector3(float(i%2)*0.35,float(i)*2.1,0)
		var b := point+Vector3(float((i+1)%2)*0.35,float(i+1)*2.1,0)
		var beam := visuals.box_at(self,Vector3(0.13,a.distance_to(b),0.13),(a+b)*0.5,mat,false)
		beam.rotation.z = -atan2(b.x-a.x,b.y-a.y)
		var tw := create_tween().bind_node(beam)
		tw.tween_interval(0.16)
		tw.tween_callback(beam.queue_free)

func outer_index(pos: Vector3) -> int:
	if maxf(absf(pos.x),absf(pos.z)) <= 8.0: return -1
	if absf(pos.x)>absf(pos.z): return 0 if pos.x>0 else 1
	return 2 if pos.z<0 else 3

func island_warning(index: int) -> bool:
	return index >= 0 and elapsed >= 15.0+float(index)*4.0

func arena_ai_move() -> Vector3:
	var pos := bodies[1].position
	var enemy := bodies[0].position
	var my_index := outer_index(pos)
	var enemy_index := outer_index(enemy)
	ai_retreat = false
	var target := enemy
	if my_index >= 0 and (island_warning(my_index) or elapsed >= 31.0):
		ai_retreat = true
		var d: Vector3 = ISLAND_DIRS[my_index]
		var lateral := pos-d*pos.dot(d)
		lateral.y = 0.0
		# Reach the bridge centerline while still on the island before crossing.
		target = d*16.1 if pos.dot(d)>15.2 and lateral.length()>0.65 else d*5.0
	elif enemy_index >= 0 and (island_warning(enemy_index) or elapsed >= 31.0):
		# Do not follow a player onto a bridge with a collapse warning.
		ai_retreat = true
		target = ISLAND_DIRS[enemy_index]*5.0
	elif my_index >= 0 and my_index != enemy_index:
		var d: Vector3 = ISLAND_DIRS[my_index]
		var lateral := pos-d*pos.dot(d)
		lateral.y = 0.0
		target = d*16.1 if pos.dot(d)>15.2 and lateral.length()>0.65 else d*5.0
	elif enemy_index >= 0 and my_index != enemy_index:
		var d: Vector3 = ISLAND_DIRS[enemy_index]
		target = d*7.0 if absf(pos.dot(Vector3(-d.z,0,d.x)))>0.65 else d*18.0
	if is_instance_valid(lightning_warning):
		var away := pos-lightning_warning.position
		away.y = 0.0
		if away.length()<2.4 and my_index == -1:
			if away.length()<0.05: away = Vector3.RIGHT
			var safe := pos+away.normalized()*3.0
			target = Vector3(clampf(safe.x,-6.5,6.5),0,clampf(safe.z,-6.5,6.5))
			if Vector2(target.x-lightning_warning.position.x,target.z-lightning_warning.position.z).length()<2.2:
				var inward := Vector3(-pos.x,0,-pos.z).normalized()
				target = pos+inward*3.0
			ai_retreat = true
	var direction := target-pos
	direction.y = 0.0
	if direction.length() < (0.5 if ai_retreat else 1.55): return Vector3.ZERO
	var result := direction.normalized()
	# Steer around destructible obstacles rather than repeatedly walking into them.
	var hit := prop_ray(1,pos+Vector3.UP*0.7,pos+Vector3.UP*0.7+result*1.6)
	if is_instance_valid(hit.get("collider")) and hit["collider"].has_meta("cover_index"):
		var side := result.rotated(Vector3.UP,PI/3.0)
		var alt := result.rotated(Vector3.UP,-PI/3.0)
		result = side if prop_ray(1,pos+Vector3.UP*0.7,pos+Vector3.UP*0.7+side*1.5).is_empty() else alt
	# Don't blindly walk off a corner or ledge. Preserve deliberate bridge jumps.
	if bodies[1].is_on_floor() and not arena_ai_jump(bodies[1],result) and not ai_has_floor(pos+result*0.8):
		var inward := Vector3(-pos.x,0,-pos.z).normalized()
		if inward.length()>0.1 and ai_has_floor(pos+inward*0.8): result = inward
		else: result = Vector3.ZERO
	return result

func ai_has_floor(pos: Vector3) -> bool:
	return not prop_ray(1,pos+Vector3.UP*1.2,pos+Vector3.DOWN*2.2).is_empty()

func arena_ai_jump(body: CharacterBody3D, dir: Vector3) -> bool:
	if dir.length()<0.1: return false
	var index := outer_index(body.position)
	if index < 0 or index >= bridge_info.size(): return false
	var info := bridge_info[index]
	if not info["broken"] or info["cut"]: return false
	var d: Vector3 = ISLAND_DIRS[index]
	var along := body.position.dot(d)
	# Jump just before the damaged deck, using the real gap location.
	var direction := dir.dot(d)
	if direction < -0.65:
		return along <= float(info["gap_max"])+0.9 and along >= float(info["gap_min"])
	if direction > 0.65:
		return along >= float(info["gap_min"])-0.9 and along <= float(info["gap_max"])
	return false

func update_arena(dt: float) -> void:
	elapsed += dt
	update_collapses()
	update_ferry(dt)
	for wind in winds:
		if not is_instance_valid(wind["root"]): continue
		var root: WindVortex = wind["root"]
		root.visible = elapsed < 20.0+float(wind["index"])*4.0
		if root.visible: root.update_visual(dt,storm_amount)
	update_crystals(dt)
	update_heal()
	update_storm(dt)
	if elapsed >= 45.0:
		for i in range(2): hp[i] = maxf(0.0,hp[i]-float(stats[i]["hp"])*0.025*dt)
	var phase := "SUDDEN DEATH" if elapsed>=45.0 else ("SKY STORM" if elapsed>=35.0 else ("COLLAPSE" if elapsed>=15.0 else "FIGHT"))
	var air_hint := " | AIR AIM %.0f°" % maxf(0.0,-rad_to_deg(pitch)) if not bodies[0].is_on_floor() else ""
	arena_label.text = "%ds | %s | %s %.1fs%s\nPower %.1fs | Speed %.1fs | Push %.1fs%s" % [int(elapsed),phase,Controls.display_name("arena_dodge"),dodge_cd,air_hint,boost[0],speed_boost[0],push_boost[0],"\nCOLLAPSE: "+danger_text if not danger_text.is_empty() else ""]


func update_weapon_trail(i: int) -> void:
	if pose_time[i] <= 0.0 or guarding[i] or flashes[i] > 0.0: return
	if i == 0 and dodge_time > 0.0: return
	var progress := 1.0 - pose_time[i] / maxf(0.01, pose_length[i])
	if progress < 0.18 or progress > 0.84: return
	if kinds[i] == "P" and spear_recovery[i] > 0.0: return
	var skeleton := Rig.skeleton(models[i])
	if skeleton == null: return
	var entries: Array = TRAIL_BONES[kinds[i]]
	for j in range(entries.size()):
		var data: Array = entries[j]
		var bone := skeleton.find_bone(String(data[0]))
		if bone < 0: continue
		var pose := skeleton.get_bone_global_pose(bone)
		var base: Vector3 = data[1]
		var tip: Vector3 = data[2]
		var a: Vector3 = skeleton.to_global(pose * base)
		var b: Vector3 = skeleton.to_global(pose * tip)
		polish.sample("%d_%d" % [i,j], a, b, FX_COLORS[kinds[i]])

func footstep(i: int, landing: bool) -> void:
	var pos := bodies[i].global_position + Vector3.UP * 0.06
	var kind := kinds[i]
	get_node("/root/Sound").play_spatial("landing" if landing else "step", pos, self, kind)
	var count := 4 if kind == "R" or kind == "N" else 2
	if landing: count *= 2
	var species_color: Color = FX_COLORS[kind]
	var color := Color("b5a184") if kind in ["P", "N", "R", "K"] else species_color.lerp(Color("c4b6a4"),0.35)
	burst(pos, color, count, 0.65 if landing else 0.25, false)
	if landing and kind in ["R","K","W"]:
			fx_ring(pos, color, 1.7 if kind == "R" else 1.2, 0.34)

func begin_victory_camera() -> void:
	victory_start = camera.global_position
	var focus: int = end_winner if end_winner >= 0 else 0
	# Ring-out and double K.O. may leave the body below the arena.
	victory_origin = bodies[focus].global_position
	if victory_origin.y < -3.0: victory_origin = Vector3.ZERO
	var offset := victory_start - victory_origin
	victory_angle = atan2(offset.x, offset.z)
	for i in range(2):
		rig_states[i] = ""
		bodies[i].velocity = Vector3.ZERO
	if not last_damage_was_finisher: request_hitstop(0.045)

func _show_result_banner() -> void:
	var local_index := 1 if lan_role == 2 else 0
	result_banner.text = "DOUBLE K.O." if end_winner < 0 else ("VICTORY" if end_winner == local_index else "DEFEAT")
	result_banner.add_theme_color_override("font_color", Color.GOLD if end_winner == local_index else (Color("e7edf5") if end_winner < 0 else Color("ff7974")))
	result_banner.show()

func lan_show_result(white_won: bool) -> void:
	if lan_role != 2: return
	if over:
		_show_result_banner()
		return
	over = true
	end_winner = 0 if white_won else 1
	hp[1 - end_winner] = 0.0
	begin_victory_camera()
	_show_result_banner()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cross.hide()
	get_node("/root/Sound").play_flat("victory" if end_winner == 1 else "defeat")

func lan_result_remaining() -> float:
	return maxf(0.0, 2.4 - end_clock)

func update_victory_camera(dt: float) -> void:
	var focus := end_winner if end_winner >= 0 else 0
	var height := float(Data.FIGHT_H[kinds[focus]])
	var pivot := victory_origin + Vector3.UP * (height * 0.55)
	var angle := victory_angle + smoothstep(0.0, 2.4, end_clock) * 1.35
	var desired := pivot + Vector3(sin(angle)*4.2, 1.25, cos(angle)*4.2)
	var query := PhysicsRayQueryParameters3D.create(pivot, desired)
	query.exclude = [bodies[0].get_rid(), bodies[1].get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty(): desired = pivot + (desired-pivot).normalized() * maxf(0.4,pivot.distance_to(hit.position)-0.20)
	var blend := 1.0 - exp(-dt*7.0)
	camera.global_position = camera.global_position.lerp(desired, blend)
	if camera.global_position.distance_to(pivot) > 0.1: camera.look_at(pivot)
	camera.fov = lerpf(camera.fov, 61.0, blend)
	var finish_shake := maxf(0.0, 0.20-end_clock) if last_damage_was_finisher else 0.0
	camera.h_offset = sin(end_clock*90.0)*finish_shake*0.24
	camera.v_offset = cos(end_clock*82.0)*finish_shake*0.12
