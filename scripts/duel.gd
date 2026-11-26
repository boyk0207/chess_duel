extends Node3D
# 2.5D side-view duel (Tekken / Street Fighter style).
# Characters move along the screen's horizontal axis "s"; world position = (0, y, -s).
# White fighter is always on the left, black on the right.

signal finished(left_won: bool)
signal lan_input_ready(input: Dictionary)
signal lan_state_ready(state: Dictionary)

const Data = preload("res://scripts/data.gd")

const ARENA := 6.0
const GRAVITY := 26.0
const JUMP_V := 10.0

const BOMB_RADIUS := 2.4

# attack feel per piece: wind-up lean back, strike lean/forward, hop height
const ATK_STYLE := {
	"W": {"wind": 0.25, "lean": 0.65, "fwd": 0.65, "hop": 0.1},
	"P": {"wind": 0.15, "lean": 0.20, "fwd": 0.70, "hop": 0.0},
	"N": {"wind": 0.25, "lean": 0.50, "fwd": 0.50, "hop": 0.05},
	"B": {"wind": 0.10, "lean": 0.15, "fwd": 0.30, "hop": 0.30},
	"R": {"wind": 0.30, "lean": 0.30, "fwd": 0.40, "hop": 0.15},
	"Q": {"wind": 0.40, "lean": 0.45, "fwd": 0.60, "hop": 0.25},
	"K": {"wind": 0.55, "lean": 0.55, "fwd": 0.50, "hop": 0.0},
}
const SP_HOP := {"W": 0.2, "P": 0.0, "N": 0.0, "B": 0.25, "R": 0.1, "Q": 0.4, "K": 0.0}

class Fighter:
	var kind := "P"
	var is_white := true
	var node: Node3D
	var model: Node3D
	var flame: MeshInstance3D
	var s := 0.0
	var y := 0.0
	var vy := 0.0
	var facing := 1
	var hp := 100.0
	var max_hp := 100.0
	var atk_cd := 0.0
	var sp_cd := 0.0
	var stun := 0.0
	var hurt := 0.0
	var lunge := 0.0
	var dash_t := 0.0
	var dash_hit := false
	var burn_t := 0.0
	var burn_tick := 0.0
	var blocking := false
	var ai := false
	var ai_t := 0.0
	var ai_in := {}
	var prev := {}
	var stats := {}
	var bar: ProgressBar
	var info: Label
	var atk_t := 9.0
	var sp_t := 9.0
	var melee_in := -1.0
	var spec_in := -1.0
	var land_t := 0.0
	var vel := 0.0
	var step_clock := 0.0
	var ko_t := 0.0
	var prev_vy := 0.0
	var mats: Array = []

class Proj:
	var kind := ""
	var src
	var node: Node3D
	var s := 0.0
	var y := 0.0
	var vs := 0.0
	var vy := 0.0
	var t := 0.0
	var dmg := 0.0
	var fired := false

var sky_arena := false
var pad_meshes: Array[MeshInstance3D] = []
var fighters: Array = []
var projs: Array = []
var cam: Camera3D
var banner: Label
var over := false
var clock := 0.0
var hitstop := 0.0
var shake := 0.0
var cam_base := Vector3(14, 3.4, 0)
var lan_role := 0 # 0 local, 1 authoritative Host, 2 Join replica
var lan_remote_input: Dictionary = {}
var lan_remote_previous: Dictionary = {}
var lan_remote_pressed: Dictionary = {}
var lan_remote_age := 1.0
var lan_send_clock := 0.0
var lan_projectile_meshes: Array[Node3D] = []
var lan_fx_sequence := 0
var lan_fx_seen := 0
var lan_fx_recent: Array[Array] = []

func _lan_fx(kind: String, values: Array) -> void:
	if lan_role != 1: return
	lan_fx_sequence += 1
	lan_fx_recent.append([lan_fx_sequence, clock, kind] + values)
	if lan_fx_recent.size() > 8: lan_fx_recent.pop_front()

func _lan_fx_snapshot() -> Array:
	while not lan_fx_recent.is_empty() and clock - float(lan_fx_recent[0][1]) > 0.8:
		lan_fx_recent.pop_front()
	return lan_fx_recent.duplicate(true)

func _lan_apply_fx(events: Array) -> void:
	for event in events:
		if not event is Array or event.size() < 4: continue
		var sequence := int(event[0])
		if sequence <= lan_fx_seen: continue
		lan_fx_seen = sequence
		if clock - float(event[1]) > 0.8: continue
		match str(event[2]):
			"bomb":
				if event.size() == 6: _show_explosion(float(event[3]), float(event[4]), str(event[5]))
			"smite":
				if event.size() == 5: _show_smite(float(event[3]), str(event[4]))

func lan_receive_input(input: Dictionary) -> void:
	if lan_role != 1: return
	for act in ["attack", "special", "jump"]:
		var down := bool(input.get(act, false))
		if down and not bool(lan_remote_previous.get(act, false)): lan_remote_pressed[act] = true
		lan_remote_previous[act] = down
	lan_remote_input = input
	lan_remote_age = 0.0

func lan_apply_state(state: Dictionary) -> void:
	if lan_role != 2 or fighters.size() != 2: return
	var pair: Array = state.get("f", [])
	if pair.size() != 2: return
	for i in 2:
		var v: Array = pair[i]
		if v.size() != 18: return
		var fi: Fighter = fighters[i]
		var old_hp := fi.hp
		var old_attack := fi.atk_t
		var old_special := fi.sp_t
		fi.s = float(v[0]); fi.y = float(v[1]); fi.vy = float(v[2]); fi.facing = int(v[3])
		fi.hp = float(v[4]); fi.atk_cd = float(v[5]); fi.sp_cd = float(v[6]); fi.stun = float(v[7])
		fi.hurt = float(v[8]); fi.lunge = float(v[9]); fi.dash_t = float(v[10]); fi.burn_t = float(v[11])
		fi.blocking = bool(v[12]); fi.atk_t = float(v[13]); fi.sp_t = float(v[14]); fi.land_t = float(v[15])
		fi.vel = float(v[16]); fi.ko_t = float(v[17])
		if fi.atk_t < old_attack - 0.08: Sound.play_spatial("heavy_swing" if fi.kind in ["R", "K", "W"] else "swing", fi.node.global_position, self, fi.kind)
		if fi.sp_t < old_special - 0.08: Sound.play_spatial("special", fi.node.global_position, self, fi.kind)
		if fi.hp < old_hp:
			_spark(fi, Color.WHITE)
			Sound.play_spatial("body_hit", fi.node.global_position, self, fi.kind)
	clock = float(state.get("t", clock))
	_lan_apply_fx(state.get("fx", []))
	var was_over := over
	over = bool(state.get("over", false))
	if over and not was_over:
		var winner: Fighter = fighters[1] if fighters[0].hp <= 0.0 else fighters[0]
		banner.text = "K.O.!   %s wins" % Data.NAMES[winner.kind]
		banner.show()
		Sound.play_flat("victory" if not winner.is_white else "defeat")
	var shots: Array = state.get("p", [])
	while lan_projectile_meshes.size() < shots.size():
		lan_projectile_meshes.append(null)
	for i in lan_projectile_meshes.size():
		if i >= shots.size():
			if is_instance_valid(lan_projectile_meshes[i]): lan_projectile_meshes[i].hide()
			continue
		var shot: Array = shots[i]
		if shot.size() != 3: continue
		var kind := str(shot[0])
		var mesh: Node3D = lan_projectile_meshes[i]
		if not is_instance_valid(mesh) or str(mesh.get_meta("lan_kind", "")) != kind:
			if is_instance_valid(mesh): mesh.queue_free()
			mesh = _make_proj_node(kind)
			mesh.set_meta("lan_kind", kind)
			add_child(mesh)
			lan_projectile_meshes[i] = mesh
		mesh.show()
		_place(mesh, float(shot[1]), float(shot[2]))

func _lan_snapshot() -> Dictionary:
	var pair := []
	for fi in fighters:
		pair.append([fi.s, fi.y, fi.vy, fi.facing, fi.hp, fi.atk_cd, fi.sp_cd, fi.stun, fi.hurt, fi.lunge, fi.dash_t, fi.burn_t, fi.blocking, fi.atk_t, fi.sp_t, fi.land_t, fi.vel, fi.ko_t])
	var shots := []
	for projectile in projs:
		shots.append([projectile.kind, projectile.s, projectile.y])
	return {"f": pair, "p": shots, "fx": _lan_fx_snapshot(), "t": clock, "over": over}

func _lan_publish(delta: float) -> void:
	if lan_role != 1: return
	lan_send_clock += delta
	if lan_send_clock >= 0.05:
		lan_send_clock = 0.0
		lan_state_ready.emit(_lan_snapshot())

func setup(white_kind: String, black_kind: String, ai_black: bool, stage: Dictionary = {}) -> void:
	sky_arena = String(stage.get("name", "Floating Island")) == "Floating Island"
	_build_world(stage)
	Sound.start_ambience(self, Vector3.ZERO, "wind", 35.0)
	fighters.append(_make_fighter(white_kind, true, -3.0, false))
	fighters.append(_make_fighter(black_kind, false, 3.0, ai_black))
	_build_hud()

# ---------------------------------------------------------------- world
func _box(size: Vector3, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	mi.material_override = m
	mi.position = pos
	add_child(mi)

func _build_world(stage: Dictionary) -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 90, 0)
	sun.light_color = stage.get("sun", Color(1, 1, 1))
	add_child(sun)
	cam = Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(14, 3.4, 0)
	add_child(cam)
	cam.look_at(Vector3(0, 2.4, 0), Vector3.UP)
	cam.current = true
	var floor_col: Color = stage.get("floor", Color(0.28, 0.26, 0.3))
	var wall_col: Color = stage.get("wall", Color(0.22, 0.2, 0.32))
	if sky_arena:
		_build_sky_trial(floor_col, wall_col)
		return
	# floating arena platform: the stage sky and clouds stay visible behind it
	_box(Vector3(20, 6, 26), Vector3(0, -3.0, 0), floor_col)
	_box(Vector3(0.6, 1.0, 26), Vector3(-9.7, 0.5, 0), wall_col.lightened(0.1))
	var hs := [5.5, 3.5, 6.0, 4.0, 5.0, 3.8, 6.0]
	for i in hs.size():
		var z := -6.0 + 2.0 * i
		_box(Vector3(1.0, hs[i], 1.0), Vector3(-8.0, hs[i] / 2.0, z), wall_col)

	# The selected stage controls the arena palette and decorative silhouettes.
	_build_stage_arena_details(stage)

# The existing duel is side-view; raised platforms run along its combat lane.
func _build_sky_trial(stone: Color, wall: Color) -> void:
	_box(Vector3(8, 1, 14), Vector3(0, -0.5, 0), stone)
	_box(Vector3(8.3, 0.18, 14.3), Vector3(0, -0.09, 0), Color(0.30, 0.49, 0.24))
	for side in [-1.0, 1.0]:
		_box(Vector3(3.0, 0.35, 2.4), Vector3(0, 0.925, side * 3.8), wall.lightened(0.2))
		for j in 3:
			_box(Vector3(1.1, 2.0 + j * 0.5, 1.1), Vector3(-3.5, 1.0 + j * 0.25, side * (2.0 + j * 1.6)), wall)
		var pad := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.55
		mesh.bottom_radius = 0.55
		mesh.height = 0.06
		pad.mesh = mesh
		pad.material_override = _glow(Color(0.2, 0.85, 1.0), 1.5)
		pad.position = Vector3(0, 0.04, side * 1.65)
		add_child(pad)
		pad_meshes.append(pad)
	for i in 7:
		var z := -15.0 + i * 5.0
		var h := float(i % 3) * 1.2 - 3.0
		_box(Vector3(4, 0.4, 3.5), Vector3(-12, h, z), Color(0.3, 0.52, 0.25))
		_box(Vector3(3.5, 3, 3), Vector3(-12, h - 1.7, z), stone)
		_box(Vector3(1.5, 2, 1.4), Vector3(-12, h - 4, z), wall)
		_box(Vector3(0.8, 4, 0.8), Vector3(-13, h + 2, z), wall.lightened(0.15))

func _sky_platform(s: float) -> float:
	return 1.1 if sky_arena and absf(absf(s) - 3.8) <= 1.2 else 0.0

func _build_stage_arena_details(stage: Dictionary) -> void:
	var name := String(stage.get("name", "Floating Island"))
	var stone: Color = stage.get("wall", Color(0.5, 0.5, 0.5))
	var accent: Color = stage.get("grass", Color(0.3, 0.5, 0.3))
	# Keep gameplay corridor unobstructed: details are beyond the fighter lane.
	for i in 7:
		var z := -11.0 + float(i) * 3.7
		var height := 2.3 + float(i % 3) * 0.8
		_box(Vector3(1.0, height, 1.0), Vector3(-7.0, height * 0.5, z), stone.lightened(0.12))
		_box(Vector3(1.4, 0.3, 1.4), Vector3(-7.0, height + 0.15, z), accent)
	if name == "Floating Island":
		# Sky Kingdom: distant suspended slabs and temple-like pillars.
		for i in 5:
			var z := -13.0 + float(i) * 6.5
			_box(Vector3(3.0, 0.5, 3.0), Vector3(-16.0, -1.0 + float(i % 2), z), accent)
			_box(Vector3(1.2, 4.0, 1.2), Vector3(-16.0, 1.2 + float(i % 2), z), stone)
	elif name == "Hell Gate":
		for i in 6:
			_box(Vector3(1.2, 0.3, 1.8), Vector3(-13.0, -0.3, -12.0 + i * 5.0), Color(1.0, 0.24, 0.06))
	elif name == "Frozen Peak":
		for i in 6:
			_box(Vector3(0.8, 3.0 + float(i % 2), 0.8), Vector3(-13.0, 1.2, -12.0 + i * 5.0), Color(0.56, 0.86, 1.0))

func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m

func _place(n: Node3D, s: float, y: float) -> void:
	n.position = Vector3(0, y, -s)

# ---------------------------------------------------------------- fighters
func _make_fighter(kind: String, white: bool, start_s: float, ai: bool) -> Fighter:
	var fi := Fighter.new()
	fi.kind = kind
	fi.is_white = white
	fi.stats = Data.STATS[kind]
	fi.max_hp = float(fi.stats["hp"])
	fi.hp = fi.max_hp
	fi.s = start_s
	fi.facing = 1 if white else -1
	fi.ai = ai
	fi.node = Node3D.new()
	add_child(fi.node)
	fi.model = Data.make_model(kind, Data.FIGHT_H[kind], Color(1, 1, 1), not white)
	for c in fi.model.get_children():
		var mt: StandardMaterial3D = c.material_override
		mt.emission_enabled = true
		mt.emission_energy_multiplier = 0.0
		fi.mats.append(mt)
	fi.node.add_child(fi.model)
	var ring := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = float(Data.RAD[kind]) + 0.2
	cm.bottom_radius = cm.top_radius
	cm.height = 0.04
	ring.mesh = cm
	ring.material_override = _glow(Color(0.35, 0.9, 1.0) if white else Color(1.0, 0.3, 0.3), 2.0)
	ring.position.y = 0.03
	fi.node.add_child(ring)
	# flame effect shown while burning
	fi.flame = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	fi.flame.mesh = sm
	fi.flame.material_override = _glow(Color(1.0, 0.45, 0.1), 3.0)
	fi.flame.position = Vector3(0, float(Data.FIGHT_H[kind]) * 0.5, 0)
	fi.flame.visible = false
	fi.node.add_child(fi.flame)
	fi.y = _sky_platform(fi.s)
	_place(fi.node, fi.s, fi.y)
	return fi

func _foe_of(me: Fighter) -> Fighter:
	return fighters[1] if me == fighters[0] else fighters[0]

# ---------------------------------------------------------------- input
func _read_input(fi: Fighter, delta: float) -> Dictionary:
	if fi.ai:
		return _ai_input(fi, delta)
	if lan_role == 1 and not fi.is_white:
		var held := lan_remote_input if lan_remote_age < 0.35 else {}
		var remote := {"dir": clampi(int(held.get("dir", 0)), -1, 1), "block": bool(held.get("block", false)), "attack": false, "special": false, "jump": false}
		for act in ["attack", "special", "jump"]:
			remote[act] = bool(lan_remote_pressed.get(act, false)) and lan_remote_age < 0.35
			lan_remote_pressed[act] = false
		return remote
	var prefix := "p1_" if fi.is_white else "p2_"
	var inp := {
		"dir": int(Controls.is_pressed(prefix + "right")) - int(Controls.is_pressed(prefix + "left")),
		"block": Controls.is_pressed(prefix + "block"),
		"attack": false, "special": false, "jump": false,
	}
	for act in ["attack", "special", "jump"]:
		var down: bool = Controls.is_pressed(prefix + act)
		inp[act] = down and not bool(fi.prev.get(act, false))
		fi.prev[act] = down
	return inp

func _ai_input(me: Fighter, delta: float) -> Dictionary:
	me.ai_t -= delta
	if me.ai_t > 0.0 and not me.ai_in.is_empty():
		var keep: Dictionary = me.ai_in.duplicate()
		keep["attack"] = false
		keep["special"] = false
		keep["jump"] = false
		return keep
	me.ai_t = randf_range(0.12, 0.3)
	var foe := _foe_of(me)
	var d := foe.s - me.s
	var ad := absf(d)
	var sg := 1 if d >= 0.0 else -1
	var reach := float(me.stats["reach"]) + float(Data.RAD[foe.kind]) + float(Data.RAD[me.kind]) * 0.2
	var inp := {"dir": 0, "block": false, "attack": false, "special": false, "jump": false}
	if ad > reach * 0.9:
		inp["dir"] = sg
	if ad <= reach and randf() < 0.7:
		inp["attack"] = true
	if me.sp_cd <= 0.0 and ad > 2.2 and randf() < 0.5:
		inp["special"] = true
	if randf() < 0.06 or (sky_arena and foe.y > me.y + 0.5 and ad < 4.0):
		inp["jump"] = true
	if ad <= reach + 0.8 and foe.atk_cd > 0.2 and randf() < 0.35:
		inp["block"] = true
		inp["attack"] = false
	me.ai_in = inp
	return inp

# ---------------------------------------------------------------- main loop
func _process(delta: float) -> void:
	if fighters.size() < 2:
		return
	if lan_role == 2:
		var input := {"dir": int(Controls.is_pressed("p2_right")) - int(Controls.is_pressed("p2_left")), "block": Controls.is_pressed("p2_block"), "attack": Controls.is_pressed("p2_attack"), "special": Controls.is_pressed("p2_special"), "jump": Controls.is_pressed("p2_jump")}
		lan_input_ready.emit(input)
		Sound.set_battle_intensity(clampf(1.0 - minf(fighters[0].hp / fighters[0].max_hp, fighters[1].hp / fighters[1].max_hp), 0.0, 1.0))
		_update_visuals(delta)
		_update_camera(delta)
		_update_hud()
		return
	if lan_role == 1: lan_remote_age += delta
	clock += delta
	Sound.set_battle_intensity(clampf(1.0 - minf(fighters[0].hp / fighters[0].max_hp, fighters[1].hp / fighters[1].max_hp), 0.0, 1.0))
	if hitstop > 0.0:
		hitstop -= delta
		_update_camera(delta)
		_update_hud()
		_lan_publish(delta)
		return
	if not over:
		for i in 2:
			_update_fighter(fighters[i], _foe_of(fighters[i]), delta)
		var a: Fighter = fighters[0]
		var b: Fighter = fighters[1]
		if absf(a.y - b.y) < 0.6:
			var d := b.s - a.s
			var minsep := float(Data.RAD[a.kind]) + float(Data.RAD[b.kind])
			if absf(d) < minsep:
				var push := (minsep - absf(d)) * 0.5
				var sg := 1.0 if d >= 0.0 else -1.0
				a.s -= sg * push
				b.s += sg * push
				a.s = clampf(a.s, -ARENA, ARENA)
				b.s = clampf(b.s, -ARENA, ARENA)
		_update_projs(delta)
	_update_visuals(delta)
	_update_camera(delta)
	_update_hud()
	_lan_publish(delta)

func _exit_tree() -> void:
	Sound.stop_ambience(self)

func _update_fighter(me: Fighter, foe: Fighter, delta: float) -> void:
	me.atk_cd = maxf(me.atk_cd - delta, 0.0)
	me.sp_cd = maxf(me.sp_cd - delta, 0.0)
	me.stun = maxf(me.stun - delta, 0.0)
	me.lunge = maxf(me.lunge - delta, 0.0)
	me.hurt = maxf(me.hurt - delta, 0.0)
	me.land_t = maxf(me.land_t - delta, 0.0)
	me.atk_t += delta
	me.sp_t += delta
	if me.burn_t > 0.0:
		me.burn_t -= delta
		me.burn_tick -= delta
		if me.burn_tick <= 0.0:
			me.burn_tick = 0.5
			_damage(me, 3.0, 0.0, false, 0.0)
			if over:
				return
	# delayed actions (wind-up first, then the hit / projectile appears)
	if me.melee_in >= 0.0:
		me.melee_in -= delta
		if me.melee_in < 0.0:
			_resolve_melee(me, foe)
	if me.spec_in >= 0.0:
		me.spec_in -= delta
		if me.spec_in < 0.0:
			_resolve_special(me, foe)
	var inp := _read_input(me, delta)
	var grounded := absf(me.y - _sky_platform(me.s)) < 0.02 and me.vy <= 0.0
	var s_before := me.s
	me.blocking = false
	if me.dash_t > 0.0:
		_do_dash(me, foe, delta)
	elif me.stun <= 0.0:
		me.blocking = bool(inp["block"]) and grounded
		var spd := float(me.stats["speed"])
		if me.blocking:
			spd *= 0.3
		me.s += float(inp["dir"]) * spd * delta
		if bool(inp["jump"]) and grounded and not me.blocking:
			me.vy = JUMP_V
			_puff(me.s, 0.1, Color(0.9, 0.9, 0.85), 0.35)
		if bool(inp["attack"]) and me.atk_cd <= 0.0 and not me.blocking:
			_melee(me, foe)
		if bool(inp["special"]) and me.sp_cd <= 0.0 and not me.blocking:
			_special(me, foe)
	if sky_arena and grounded and absf(absf(me.s) - 1.65) < 0.45 and me.vy <= 0.0:
		me.vy = 13.0
		_puff(me.s, 0.1, Color(0.3, 0.9, 1.0), 0.6)
	var old_y := me.y
	me.prev_vy = me.vy
	me.vy -= GRAVITY * delta
	me.y += me.vy * delta
	var floor_y := _sky_platform(me.s)
	if old_y < floor_y - 0.02:
		floor_y = 0.0
	if me.y <= floor_y and me.vy <= 0.0:
		if me.prev_vy < -4.0:
			me.land_t = 0.14
			Sound.play_spatial("landing", me.node.global_position, self)
			_puff(me.s, 0.1, Color(0.9, 0.9, 0.85), 0.5)
		me.y = floor_y
		me.vy = 0.0
	me.s = clampf(me.s, -ARENA, ARENA)
	me.vel = (me.s - s_before) / maxf(delta, 0.0001)
	me.step_clock = maxf(0.0, me.step_clock - delta)
	if absf(me.vel) > 0.7 and me.vy == 0.0 and me.step_clock <= 0.0:
		me.step_clock = 0.28
		Sound.play_spatial("step", me.node.global_position, self, me.kind)
	if me.dash_t <= 0.0 and absf(foe.s - me.s) > 0.1:
		me.facing = 1 if foe.s > me.s else -1

# ---------------------------------------------------------------- combat
func _body_hit(foe: Fighter, s: float, y: float, r: float) -> bool:
	var h := float(Data.FIGHT_H[foe.kind])
	return absf(foe.s - s) < float(Data.RAD[foe.kind]) + r and y > foe.y - 0.2 and y < foe.y + h

func _damage(target: Fighter, amount: float, kb: float, blockable: bool, stun_t: float, source_kind: String = "", special_attack: bool = false, impact_played: bool = false) -> void:
	if over:
		return
	var dmg := amount
	var push := kb
	var st := stun_t
	var blocked := blockable and target.blocking
	if blocked:
		dmg *= float(target.stats.get("block", 0.2))
		push *= 0.3
		st = 0.0
	target.hp = maxf(target.hp - dmg, 0.0)
	if blocked:
		Sound.play_spatial("block", target.node.global_position, self)
	elif not (special_attack and impact_played):
		var impact_cue := "special_impact" if special_attack and source_kind in Sound.DISTINCT_SFX_KINDS else ("projectile_impact" if special_attack and source_kind == "P" else ("heavy_hit" if dmg >= 15.0 else "body_hit"))
		Sound.play_spatial(impact_cue, target.node.global_position, self, source_kind)
	if not blocked:
		if not special_attack and not source_kind.is_empty():
			Sound.play_spatial("attack", target.node.global_position, self, source_kind)
		Sound.play_spatial("hit", target.node.global_position, self, target.kind)
	target.s = clampf(target.s + push, -ARENA, ARENA)
	if st > 0.0:
		target.stun = maxf(target.stun, st)
		target.melee_in = -1.0   # a hit interrupts wind-ups
		target.spec_in = -1.0
	target.hurt = 0.2
	if dmg >= 1.5:
		hitstop = 0.05 if dmg < 15.0 else 0.1
		shake = maxf(shake, 0.12 if dmg < 15.0 else 0.3)
		_spark(target, Color(0.7, 0.8, 1.0) if blocked else Color(1.0, 0.9, 0.5))
	if target.hp <= 0.0:
		_ko(target)

func _melee(me: Fighter, _foe: Fighter) -> void:
	Sound.play_spatial("heavy_swing" if me.kind in ["R", "K", "W"] else "swing", me.node.global_position, self, me.kind)
	me.atk_cd = float(me.stats["cd"])
	me.atk_t = 0.0
	me.melee_in = 0.09

func _resolve_melee(me: Fighter, foe: Fighter) -> void:
	var ds := (foe.s - me.s) * float(me.facing)
	var reach := float(me.stats["reach"]) + float(Data.RAD[foe.kind])
	if ds > -0.3 and ds <= reach and absf(foe.y - me.y) < 1.3:
		_damage(foe, float(me.stats["dmg"]), float(me.facing) * 0.35, true, 0.18, me.kind)

func _special(me: Fighter, _foe: Fighter) -> void:
	Sound.play_spatial("special", me.node.global_position, self, me.kind)
	me.sp_cd = float(me.stats["sp_cd"])
	me.sp_t = 0.0
	if String(me.stats["special"]) == "charge":
		me.dash_t = 0.4
		me.dash_hit = false
		_puff(me.s, 0.1, Color(0.85, 0.75, 0.55), 0.5)
	else:
		me.spec_in = 0.16

func _resolve_special(me: Fighter, foe: Fighter) -> void:
	match String(me.stats["special"]):
		"spear":
			_spawn_proj(me, "spear", 11.0, 0.0, 1.2)
		"fire":
			_spawn_proj(me, "fire", 9.0, 0.0, 1.2)
		"bomb":
			_spawn_proj(me, "bomb", 6.5, 9.0, 1.2)
		"quake":
			_spawn_proj(me, "quake", 8.0, 0.0, 0.3)
			shake = maxf(shake, 0.25)
			_puff(me.s + float(me.facing) * 0.8, 0.1, Color(0.8, 0.65, 0.4), 0.8)
		"smite":
			var p := _spawn_proj(me, "smite", 0.0, 0.0, 0.05)
			p.s = foe.s

func _do_dash(me: Fighter, foe: Fighter, delta: float) -> void:
	me.dash_t -= delta
	me.s += float(me.facing) * 14.0 * delta
	if not me.dash_hit and absf(foe.s - me.s) < float(Data.RAD[me.kind]) + float(Data.RAD[foe.kind]) + 0.2 \
			and absf(foe.y - me.y) < 1.3:
		me.dash_hit = true
		_damage(foe, float(me.stats["sp_dmg"]), float(me.facing) * 1.2, true, 0.35, me.kind, true)

func _puff(s_pos: float, y: float, col: Color, size: float) -> void:
	for i in 3:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		mi.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(col.r, col.g, col.b, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		add_child(mi)
		_place(mi, s_pos + randf_range(-0.4, 0.4), y)
		mi.scale = Vector3.ONE * size * 0.4
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "scale", Vector3.ONE * size, 0.35)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
		tw.chain().tween_callback(mi.queue_free)

func _spark(target: Fighter, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)
	_place(mi, target.s, target.y + float(Data.FIGHT_H[target.kind]) * 0.55)
	mi.scale = Vector3.ONE * 0.2
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3.ONE * 1.1, 0.12)
	tw.tween_callback(mi.queue_free)

func _make_proj_node(kind: String) -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	match kind:
		"spear":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.12, 0.12, 1.1)
			mi.mesh = bm
			mi.material_override = _glow(Color(0.85, 0.88, 0.95), 0.6)
		"fire":
			var sm := SphereMesh.new()
			sm.radius = 0.4
			sm.height = 0.8
			mi.mesh = sm
			mi.material_override = _glow(Color(1.0, 0.5, 0.1), 3.0)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.6, 0.2)
			l.omni_range = 5.0
			n.add_child(l)
		"bomb":
			var sm := SphereMesh.new()
			sm.radius = 0.32
			sm.height = 0.64
			mi.mesh = sm
			mi.material_override = _glow(Color(0.25, 0.25, 0.3), 0.2)
		"quake":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.5, 0.6, 0.35)
			mi.mesh = bm
			mi.material_override = _glow(Color(0.8, 0.6, 0.3), 1.2)
		"smite":
			var cm := CylinderMesh.new()
			cm.top_radius = 0.9
			cm.bottom_radius = 0.9
			cm.height = 0.05
			mi.mesh = cm
			mi.material_override = _glow(Color(1.0, 0.2, 0.2), 2.0)
	n.add_child(mi)
	return n

func _spawn_proj(me: Fighter, kind: String, vs: float, vy: float, h: float) -> Proj:
	var p := Proj.new()
	p.kind = kind
	p.src = me
	p.s = me.s + float(me.facing) * 0.8
	p.y = me.y + h
	p.vs = vs * float(me.facing)
	p.vy = vy
	p.dmg = float(me.stats["sp_dmg"])
	p.node = _make_proj_node(kind)
	add_child(p.node)
	_place(p.node, p.s, p.y)
	projs.append(p)
	return p

func _update_projs(delta: float) -> void:
	var dead: Array = []
	for p in projs:
		var foe := _foe_of(p.src)
		p.t += delta
		match p.kind:
			"spear", "fire":
				p.s += p.vs * delta
				if _body_hit(foe, p.s, p.y, 0.3):
					_damage(foe, p.dmg, signf(p.vs) * 0.3, true, 0.25, p.src.kind, true)
					if p.kind == "fire":
						foe.burn_t = 3.0
					dead.append(p)
				elif absf(p.s) > ARENA + 3.0:
					dead.append(p)
			"bomb":
				p.vy -= 24.0 * delta
				p.y += p.vy * delta
				p.s += p.vs * delta
				if p.y <= 0.2 or _body_hit(foe, p.s, p.y, 0.3):
					_explode(p, foe)
					dead.append(p)
			"quake":
				p.s += p.vs * delta
				if foe.y < 0.6 and absf(foe.s - p.s) < float(Data.RAD[foe.kind]) + 0.3:
					_damage(foe, p.dmg, signf(p.vs) * 0.6, true, 0.5, p.src.kind, true)
					dead.append(p)
				elif p.t > 1.2 or absf(p.s) > ARENA + 2.0:
					dead.append(p)
			"smite":
				if p.t < 0.35:
					p.s = foe.s
				if p.t >= 0.7 and not p.fired:
					p.fired = true
					_smite_strike(p, foe)
					dead.append(p)
		_place(p.node, p.s, p.y)
	for p in dead:
		projs.erase(p)
		p.node.queue_free()

func _explode(p: Proj, foe: Fighter) -> void:
	_lan_fx("bomb", [p.s, p.y, p.src.kind])
	_show_explosion(p.s, p.y, p.src.kind)
	var d := Vector2(foe.s - p.s, foe.y + float(Data.FIGHT_H[foe.kind]) * 0.5 - maxf(p.y, 0.3)).length()
	if d <= BOMB_RADIUS:
		var k := 1.0 if d <= BOMB_RADIUS * 0.5 else 0.5
		_damage(foe, p.dmg * k, signf(foe.s - p.s) * 0.8, true, 0.4, p.src.kind, true, true)

func _show_explosion(s: float, y: float, kind: String) -> void:
	Sound.play_spatial("special_impact", Vector3(0.0, maxf(y, 0.3), -s), self, kind)
	var ex := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	ex.mesh = sm
	ex.material_override = _glow(Color(1.0, 0.55, 0.1), 3.0)
	add_child(ex)
	_place(ex, s, maxf(y, 0.3))
	ex.scale = Vector3.ONE * 0.3
	var tw := create_tween()
	tw.tween_property(ex, "scale", Vector3.ONE * BOMB_RADIUS, 0.25)
	tw.tween_callback(ex.queue_free)
	var boundary := MeshInstance3D.new()
	var circle := TorusMesh.new()
	circle.inner_radius = BOMB_RADIUS * 0.95
	circle.outer_radius = BOMB_RADIUS
	boundary.mesh = circle
	boundary.rotation_degrees.z = 90.0
	var boundary_mat := _glow(Color(1.0, 0.55, 0.08, 0.95), 2.0)
	boundary_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	boundary.material_override = boundary_mat
	add_child(boundary)
	_place(boundary, s, maxf(y, 0.3))
	boundary.position.x = 0.15
	var ring_tw := create_tween().set_parallel(true)
	ring_tw.tween_property(boundary, "scale", Vector3.ONE * 1.08, 0.32)
	ring_tw.tween_property(boundary_mat, "albedo_color:a", 0.0, 0.32)
	ring_tw.chain().tween_callback(boundary.queue_free)
func _smite_strike(p: Proj, foe: Fighter) -> void:
	_lan_fx("smite", [p.s, p.src.kind])
	_show_smite(p.s, p.src.kind)
	if absf(foe.s - p.s) < 1.0 + float(Data.RAD[foe.kind]) * 0.5:
		_damage(foe, p.dmg, 0.0, true, 0.5, p.src.kind, true, true)

func _show_smite(s: float, kind: String) -> void:
	Sound.play_spatial("special_impact", Vector3(0.0, 4.5, -s), self, kind)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 9.0
	beam.mesh = cm
	beam.material_override = _glow(Color(1.0, 0.95, 0.4), 4.0)
	add_child(beam)
	_place(beam, s, 4.5)
	var tw := create_tween()
	tw.tween_property(beam, "scale", Vector3(0.1, 1.0, 0.1), 0.25)
	tw.tween_callback(beam.queue_free)
func _ko(loser: Fighter) -> void:
	if over:
		return
	over = true
	loser.hp = 0.0
	var left_won := not loser.is_white
	Sound.play_flat("victory" if left_won else "defeat")
	var winner: Fighter = _foe_of(loser)
	banner.text = "K.O.!   %s wins" % Data.NAMES[winner.kind]
	banner.visible = true
	await get_tree().create_timer(1.8).timeout
	finished.emit(left_won)

# ---------------------------------------------------------------- visuals
func _ease_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)

func _set_glow(fi: Fighter, col: Color, amt: float) -> void:
	for m in fi.mats:
		var mat: StandardMaterial3D = m
		mat.emission = col
		mat.emission_energy_multiplier = amt

func _update_visuals(delta: float) -> void:
	for fv in fighters:
		var fi: Fighter = fv
		_place(fi.node, fi.s, fi.y)
		fi.node.rotation.y = 0.0 if fi.facing == 1 else PI
		var h := float(Data.FIGHT_H[fi.kind])
		var m: Node3D = fi.model
		var lean := 0.0          # about local X: negative = forward, positive = backward
		var fwd := 0.0           # local -Z offset: negative = forward
		var up := 0.0
		var sx := 1.0
		var sy := 1.0
		var sz := 1.0
		var glow := 0.0
		var gcol := Color(1, 1, 1)
		# idle breathing
		var ph := clock * 3.2 + (0.0 if fi.is_white else 1.7)
		sy += sin(ph) * 0.02
		up += sin(ph) * 0.02
		# walking: hop + lean
		if fi.y <= 0.001 and absf(fi.vel) > 0.5 and fi.dash_t <= 0.0:
			var wk := absf(sin(clock * 15.0))
			up += wk * 0.1
			var dirn := signf(fi.vel) * float(fi.facing)   # +1 moving forward, -1 backing off
			lean += -0.07 * dirn
			sy += (wk - 0.5) * 0.05
		# airborne squash & stretch, landing squash
		if fi.y > 0.001:
			var st := clampf(absf(fi.vy) / 10.0, 0.0, 1.0)
			sy += 0.1 * st
			sx -= 0.06 * st
			sz -= 0.06 * st
		if fi.land_t > 0.0:
			var u := fi.land_t / 0.14
			sy -= 0.15 * u
			sx += 0.1 * u
			sz += 0.1 * u
		# melee attack
		if fi.atk_t < 0.34:
			var st: Dictionary = ATK_STYLE[fi.kind]
			var t := fi.atk_t
			if t < 0.09:
				var u := t / 0.09
				lean += float(st["wind"]) * u
				fwd += 0.15 * u
				sy -= 0.05 * u
			elif t < 0.2:
				var u := _ease_out((t - 0.09) / 0.11)
				lean += lerpf(float(st["wind"]), -float(st["lean"]), u)
				fwd += lerpf(0.15, -float(st["fwd"]), u)
				up += float(st["hop"]) * sin(u * PI)
				sz += 0.12 * u
			else:
				var u := (t - 0.2) / 0.14
				lean += -float(st["lean"]) * (1.0 - u)
				fwd += -float(st["fwd"]) * (1.0 - u)
		# special cast pose
		if fi.sp_t < 0.42 and String(fi.stats["special"]) != "charge":
			var t2 := fi.sp_t
			var hop := float(SP_HOP[fi.kind])
			if t2 < 0.16:
				var u := _ease_out(t2 / 0.16)
				lean += 0.4 * u
				up += hop * u
				sy += 0.05 * u
				glow = 0.9 * u
				gcol = Color(1.0, 0.8, 0.4)
			else:
				var u := (t2 - 0.16) / 0.26
				lean += lerpf(0.4, -0.3, minf(u * 2.0, 1.0)) * (1.0 - u)
				up += hop * (1.0 - u)
				glow = 0.9 * (1.0 - u)
				gcol = Color(1.0, 0.8, 0.4)
		# charge / dash
		if fi.dash_t > 0.0:
			lean += -0.6
			sz += 0.2
			sx -= 0.08
			sy -= 0.05
		# blocking
		if fi.blocking:
			sy -= 0.14
			sx += 0.05
			sz += 0.05
			lean += 0.15
			glow = maxf(glow, 0.5)
			gcol = Color(0.5, 0.8, 1.0)
		# hurt: flash, recoil, shake
		if fi.hurt > 0.0:
			var u := fi.hurt / 0.2
			lean += 0.4 * u
			fwd += 0.2 * u + randf_range(-0.04, 0.04)
			up += 0.12 * sin((1.0 - u) * PI)
			glow = maxf(glow, 1.8 * u)
			gcol = Color(1, 1, 1)
		# KO and victory
		if over:
			if fi.hp <= 0.0:
				fi.ko_t += delta
				var k := clampf(fi.ko_t / 0.5, 0.0, 1.0)
				lean = 1.55 * _ease_out(k)
				up += 0.7 * sin(clampf(fi.ko_t / 0.3, 0.0, 1.0) * PI)
				fwd = 0.6 * _ease_out(k)
				sx = 1.0
				sy = 1.0
				sz = 1.0
				glow = 0.0
			else:
				up += absf(sin(clock * 6.0)) * 0.3
				sy += 0.04 * sin(clock * 12.0)
		m.rotation.x = lerpf(m.rotation.x, lean, clampf(delta * 22.0, 0.0, 1.0))
		m.position = Vector3(0, up, fwd)
		m.scale = Vector3(h * sx, h * sy, h * sz)
		_set_glow(fi, gcol, glow)
		fi.flame.visible = fi.burn_t > 0.0 and not over
		fi.flame.scale = Vector3.ONE * (0.8 + 0.3 * sin(clock * 30.0))

func _update_camera(delta: float) -> void:
	var a: Fighter = fighters[0]
	var b: Fighter = fighters[1]
	var mid := (a.s + b.s) * 0.5 * 0.6
	var gap := absf(a.s - b.s)
	var dist := clampf(11.5 + gap * 0.4, 12.0, 15.5)
	var top := maxf(a.y, b.y) * 0.45
	var target := Vector3(dist, 3.2 + top, -mid)
	cam_base = cam_base.lerp(target, clampf(delta * 4.0, 0.0, 1.0))
	shake = maxf(shake - delta * 1.2, 0.0)
	var off := Vector3(0, randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake
	cam.position = cam_base + off
	cam.look_at(Vector3(0, 2.3 + top, -mid), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hb.offset_left = 20
	hb.offset_right = -20
	hb.offset_top = 14
	hb.add_theme_constant_override("separation", 60)
	root.add_child(hb)
	for i in 2:
		var fi: Fighter = fighters[i]
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(vb)
		var bar := ProgressBar.new()
		bar.max_value = fi.max_hp
		bar.value = fi.hp
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 28)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.3, 0.8, 0.9) if i == 0 else Color(0.95, 0.55, 0.2)
		bar.add_theme_stylebox_override("fill", sb)
		if i == 1:
			bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
		vb.add_child(bar)
		var lb := Label.new()
		lb.add_theme_font_size_override("font_size", 20)
		if i == 1:
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vb.add_child(lb)
		fi.bar = bar
		fi.info = lb
	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.add_theme_font_size_override("font_size", 64)
	banner.visible = false
	root.add_child(banner)
	var hint := Label.new()
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -40
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.text = "WHITE: %s/%s move, %s jump, %s block, %s attack, %s special     |     BLACK: %s/%s move, %s jump, %s block, %s attack, %s special" % [Controls.display_name("p1_left"), Controls.display_name("p1_right"), Controls.display_name("p1_jump"), Controls.display_name("p1_block"), Controls.display_name("p1_attack"), Controls.display_name("p1_special"), Controls.display_name("p2_left"), Controls.display_name("p2_right"), Controls.display_name("p2_jump"), Controls.display_name("p2_block"), Controls.display_name("p2_attack"), Controls.display_name("p2_special")]
	if sky_arena:
		hint.text += "   |   BLUE PADS: AUTO JUMP"
	root.add_child(hint)

func _update_hud() -> void:
	for fv in fighters:
		var fi: Fighter = fv
		fi.bar.value = fi.hp
		var sp := "READY" if fi.sp_cd <= 0.0 else "%.1fs" % fi.sp_cd
		var side := "WHITE"
		if not fi.is_white:
			side = "BLACK (AI)" if fi.ai else "BLACK"
		fi.info.text = "%s  %s   HP %d   %s: %s" % [side, Data.NAMES[fi.kind], ceili(fi.hp), fi.stats["sp_name"], sp]
