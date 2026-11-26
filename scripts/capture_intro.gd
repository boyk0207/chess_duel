extends Node3D
## Visual-only board-to-arena entrance; duel damage and board results remain authoritative.

signal finished

const Rig = preload("res://scripts/rig_factory.gd")
const Data = preload("res://scripts/data.gd")
const KINDS := ["P", "N", "B", "R", "Q", "K", "W"]
const LEADS := {
	"P": {"ready": "Walk", "strikes": ["Attack", "Attack2", "Attack3"], "step": 0.22, "pace": 1.0},
	"N": {"ready": "Run", "strikes": ["Attack2", "Attack3", "Attack"], "step": 0.37, "pace": 1.25},
	"B": {"ready": "Idle", "strikes": ["Special", "Attack", "Attack2"], "step": 0.17, "pace": 0.85},
	"R": {"ready": "Block", "strikes": ["Attack3", "Attack", "Attack2"], "step": 0.13, "pace": 0.75},
	"Q": {"ready": "DodgeForward", "strikes": ["Attack2", "Special", "Attack3"], "step": 0.31, "pace": 1.15},
	"K": {"ready": "Walk", "strikes": ["Attack3", "Attack2", "Attack"], "step": 0.16, "pace": 0.80},
	"W": {"ready": "Run", "strikes": ["Attack", "Attack3", "Special"], "step": 0.35, "pace": 1.20},
}
const COUNTERS := {
	"P": ["Attack", "Attack2", "Attack3"],
	"N": ["Attack2", "Attack3", "Attack"],
	"B": ["Special", "Attack", "Attack2"],
	"R": ["Attack3", "Attack2", "Attack"],
	"Q": ["Attack2", "Special", "Attack3"],
	"K": ["Attack3", "Attack", "Attack2"],
	"W": ["Attack", "Attack3", "Special"],
}
const RETURN_GUARDS := {
	"P": ["DodgeBack", "Block", "DodgeLeft"],
	"N": ["DodgeLeft", "DodgeBack", "Block"],
	"B": ["Block", "DodgeRight", "DodgeBack"],
	"R": ["Block", "DodgeBack", "Block"],
	"Q": ["DodgeRight", "DodgeLeft", "Block"],
	"K": ["Block", "DodgeBack", "DodgeRight"],
	"W": ["DodgeBack", "Block", "DodgeLeft"],
}
## Attacker rows, defender columns in KINDS order. These are authored responses,
## not an index formula: the same defender reads a different attack differently.
const PAIR_DEFENSE := {
	"P": ["Block", "DodgeLeft", "Special", "Block", "DodgeRight", "PerfectBlock", "Hit"],
	"N": ["DodgeBack", "Block", "Special", "Hit", "DodgeLeft", "PerfectBlock", "DodgeRight"],
	"B": ["Block", "DodgeRight", "Special", "PerfectBlock", "DodgeLeft", "Block", "Hit"],
	"R": ["Hit", "DodgeLeft", "Special", "PerfectBlock", "DodgeRight", "Block", "Hit"],
	"Q": ["DodgeBack", "DodgeRight", "Special", "Block", "PerfectBlock", "DodgeLeft", "Hit"],
	"K": ["Block", "Hit", "Special", "Block", "DodgeRight", "PerfectBlock", "DodgeBack"],
	"W": ["Hit", "DodgeBack", "Special", "PerfectBlock", "DodgeLeft", "Block", "Hit"],
}
const EXITS := {
	"P": {"style": "walk", "clip": "Walk"},
	"N": {"style": "leap", "clip": "JumpStart"},
	"B": {"style": "levitate", "clip": "Airborne"},
	"R": {"style": "march", "clip": "Walk"},
	"Q": {"style": "blink", "clip": "DodgeForward"},
	"K": {"style": "stride", "clip": "Walk"},
	"W": {"style": "charge", "clip": "Run"},
}
const STRIKE_GAP := {"P": 0.64, "N": 0.76, "B": 1.10, "R": 0.83, "Q": 1.03, "K": 0.78, "W": 0.72}

static func choreography(attacker_kind: String, defender_kind: String) -> Dictionary:
	if attacker_kind not in KINDS or defender_kind not in KINDS: return {}
	var attacker_index := KINDS.find(attacker_kind)
	var defender_index := KINDS.find(defender_kind)
	var lead: Dictionary = LEADS[attacker_kind]
	var variant := (attacker_index + defender_index) % 3
	var defense: String = PAIR_DEFENSE[attacker_kind][defender_index]
	var counter_clip := "" if defense in ["Block", "PerfectBlock", "Special"] else str(COUNTERS[defender_kind][(defender_index + attacker_index) % 3])
	var clash := 0.26 + 0.025 * float(attacker_index % 3)
	var hit := clash + 0.14
	var counter := hit + 0.20
	return {
		"pair": attacker_kind + defender_kind,
		"ready": lead["ready"],
		"strike": lead["strikes"][variant],
		"reaction": defense,
		"counter": counter_clip,
		"return_guard": str(RETURN_GUARDS[attacker_kind][(attacker_index + defender_index) % 3]) if not counter_clip.is_empty() else "",
		"exit_attacker": EXITS[attacker_kind],
		"exit_defender": EXITS[defender_kind],
		"approach": float(lead["step"]) + 0.025 * float(defender_index),
		"stagger": (0.11 + 0.025 * float(defender_index)) / float(lead["pace"]),
		"clash_at": clash,
		"hit_at": hit,
		"counter_at": counter,
		"return_at": counter + 0.17,
		"walk_at": 1.01 + 0.025 * float(defender_index % 3),
		"idle_at": 1.79 + 0.015 * float((attacker_index + defender_index) % 3),
	}

var attacker: Node3D
var defender: Node3D
var attacker_anim: AnimationPlayer
var defender_anim: AnimationPlayer
var gate: MeshInstance3D
var start_attacker := Vector3.ZERO
var start_defender := Vector3.ZERO
var end_attacker := Vector3.ZERO
var end_defender := Vector3.ZERO
var exit_direction := Vector3.FORWARD
var elapsed := 0.0
var phase := "idle"
var plan: Dictionary = {}
var attacker_kind := ""
var defender_kind := ""
var approach_attacker := Vector3.ZERO
var stagger_defender := Vector3.ZERO
var counter_defender := Vector3.ZERO
var recoil_attacker := Vector3.ZERO
var visual_scale := 1.0
var magic_guard: MeshInstance3D
var attacker_exit_airborne := false
var defender_exit_airborne := false
var attacker_landed := false
var defender_landed := false

func configure(attacker_kind: String, attacker_white: bool, defender_kind: String, defender_white: bool, from_pos: Vector3, target_pos: Vector3, piece_scale: float, direction: Vector3, stage_color: Color) -> void:
	self.attacker_kind = attacker_kind
	self.defender_kind = defender_kind
	plan = choreography(attacker_kind, defender_kind)
	visual_scale = piece_scale
	start_attacker = from_pos
	start_defender = target_pos
	var fight_direction := (target_pos - from_pos).normalized()
	var distance := from_pos.distance_to(target_pos)
	var approach_distance: float = maxf(float(plan["approach"]) * piece_scale, distance - float(STRIKE_GAP[attacker_kind]) * piece_scale)
	approach_attacker = from_pos + fight_direction * minf(approach_distance, distance * 0.85)
	stagger_defender = target_pos + fight_direction * float(plan["stagger"]) * (0.25 if str(plan["reaction"]) in ["Block", "PerfectBlock", "Special"] else 1.0) * piece_scale
	counter_defender = target_pos - fight_direction * 0.18 * piece_scale
	recoil_attacker = approach_attacker - fight_direction * 0.10 * piece_scale
	exit_direction = Vector3(direction.x, 0.0, direction.z).normalized()
	if exit_direction.is_zero_approx(): exit_direction = Vector3.FORWARD
	var exit_center := (from_pos + target_pos) * 0.5 + exit_direction * 1.65 * piece_scale
	exit_center.x = clampf(exit_center.x, -3.6 * piece_scale, 3.6 * piece_scale)
	exit_center.z = clampf(exit_center.z, -3.6 * piece_scale, 3.6 * piece_scale)
	var sideways := Vector3(-exit_direction.z, 0.0, exit_direction.x) * 0.38 * piece_scale
	end_attacker = exit_center + sideways
	end_defender = exit_center - sideways
	attacker = Rig.build(attacker_kind, float(Data.BOARD_H[attacker_kind]) * piece_scale, not attacker_white)
	defender = Rig.build(defender_kind, float(Data.BOARD_H[defender_kind]) * piece_scale, not defender_white)
	add_child(attacker)
	add_child(defender)
	attacker.position = start_attacker
	defender.position = start_defender
	_face(attacker, start_defender - start_attacker)
	_face(defender, start_attacker - start_defender)
	attacker_anim = Rig.player(attacker)
	defender_anim = Rig.player(defender)
	_play(attacker_anim, str(plan["ready"]))
	_play(defender_anim, "Idle")
	if str(plan["reaction"]) == "Special":
		magic_guard = MeshInstance3D.new()
		var shield := SphereMesh.new()
		shield.radius = 0.45 * piece_scale
		shield.height = 0.9 * piece_scale
		shield.radial_segments = 12
		shield.rings = 4
		magic_guard.mesh = shield
		var shield_mat := StandardMaterial3D.new()
		shield_mat.albedo_color = stage_color.lightened(0.45)
		shield_mat.albedo_color.a = 0.24
		shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shield_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		shield_mat.emission_enabled = true
		shield_mat.emission = stage_color.lightened(0.45)
		magic_guard.material_override = shield_mat
		magic_guard.visible = false
		add_child(magic_guard)
	gate = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.45 * piece_scale
	ring.outer_radius = 0.56 * piece_scale
	gate.mesh = ring
	var glow := StandardMaterial3D.new()
	glow.albedo_color = stage_color.lightened(0.45)
	glow.emission_enabled = true
	glow.emission = stage_color.lightened(0.45)
	glow.emission_energy_multiplier = 2.0
	gate.material_override = glow
	gate.position = exit_center + Vector3.UP * 0.08 * piece_scale
	gate.scale = Vector3.ZERO
	add_child(gate)

func _face(actor: Node3D, direction: Vector3) -> void:
	actor.rotation.y = atan2(-direction.x, -direction.z)

func _play(anim: AnimationPlayer, clip: String) -> void:
	if is_instance_valid(anim) and anim.has_animation(clip): anim.play(clip)

func _travel_position(from: Vector3, to: Vector3, progress: float, style: String) -> Vector3:
	var t := smoothstep(0.0, 1.0, progress)
	match style:
		"charge": t = pow(progress, 0.75)
		"stride": t = smoothstep(0.08, 1.0, progress)
		"blink":
			t = 0.12 * progress if progress < 0.38 else (0.78 + 0.22 * smoothstep(0.55, 1.0, progress))
	var position := from.lerp(to, t)
	match style:
		"leap": position.y += sin(PI * progress) * 0.52 * visual_scale
		"levitate": position.y += sin(PI * progress) * 0.68 * visual_scale
		"march": position.y += absf(sin(TAU * 2.0 * progress)) * 0.035 * visual_scale
	return position

func _travel_actor(actor: Node3D, anim: AnimationPlayer, from: Vector3, to: Vector3, progress: float, style: String, is_attacker: bool) -> void:
	actor.position = _travel_position(from, to, progress, style)
	actor.visible = style != "blink" or progress < 0.38 or progress >= 0.55
	if style == "leap":
		if progress >= 0.24 and not (attacker_exit_airborne if is_attacker else defender_exit_airborne):
			_play(anim, "Airborne")
			if is_attacker: attacker_exit_airborne = true
			else: defender_exit_airborne = true
		if progress >= 0.84 and not (attacker_landed if is_attacker else defender_landed):
			_play(anim, "Landing")
			if is_attacker: attacker_landed = true
			else: defender_landed = true

func _process(delta: float) -> void:
	if not is_instance_valid(attacker) or phase == "done": return
	elapsed += delta
	if phase == "idle" and elapsed >= float(plan["clash_at"]):
		_play(attacker_anim, str(plan["strike"]))
		phase = "clash"
	if phase == "clash" and elapsed >= float(plan["hit_at"]):
		_play(defender_anim, str(plan["reaction"]))
		phase = "hit"
	if phase == "hit" and elapsed >= float(plan["counter_at"]):
		if not str(plan["counter"]).is_empty(): _play(defender_anim, str(plan["counter"]))
		phase = "counter"
	if phase == "counter" and elapsed >= float(plan["return_at"]):
		if not str(plan["return_guard"]).is_empty(): _play(attacker_anim, str(plan["return_guard"]))
		phase = "return"
	if phase == "return" and elapsed >= float(plan["walk_at"]):
		_face(attacker, exit_direction)
		_face(defender, exit_direction)
		_play(attacker_anim, str(plan["exit_attacker"]["clip"]))
		_play(defender_anim, str(plan["exit_defender"]["clip"]))
		phase = "walk"
	if elapsed < float(plan["clash_at"]):
		attacker.position = start_attacker.lerp(approach_attacker, smoothstep(0.0, 1.0, elapsed / float(plan["clash_at"])))
	elif elapsed < float(plan["counter_at"]):
		attacker.position = approach_attacker
		var recoil := clampf((elapsed - float(plan["hit_at"])) / 0.22, 0.0, 1.0)
		defender.position = start_defender.lerp(stagger_defender, recoil)
	elif elapsed < float(plan["walk_at"]):
		var counter_step := clampf((elapsed - float(plan["counter_at"])) / 0.22, 0.0, 1.0)
		defender.position = stagger_defender.lerp(counter_defender, counter_step)
		var evade := clampf((elapsed - float(plan["return_at"])) / 0.18, 0.0, 1.0)
		attacker.position = approach_attacker.lerp(recoil_attacker, evade)
	else:
		var travel := smoothstep(0.0, 1.0, clampf((elapsed - float(plan["walk_at"])) / (float(plan["idle_at"]) - float(plan["walk_at"])), 0.0, 1.0))
		_travel_actor(attacker, attacker_anim, recoil_attacker, end_attacker, travel, str(plan["exit_attacker"]["style"]), true)
		_travel_actor(defender, defender_anim, counter_defender, end_defender, travel, str(plan["exit_defender"]["style"]), false)
		gate.scale = Vector3.ONE * travel
	if is_instance_valid(magic_guard):
		magic_guard.visible = elapsed >= float(plan["hit_at"]) and elapsed < float(plan["walk_at"])
		magic_guard.position = defender.position + Vector3.UP * 0.45 * visual_scale
		magic_guard.scale = Vector3.ONE * (0.9 + 0.1 * sin(elapsed * 35.0))
	if phase == "walk" and elapsed >= float(plan["idle_at"]):
		attacker.visible = true
		defender.visible = true
		_play(attacker_anim, "Idle")
		_play(defender_anim, "Idle")
		phase = "arrival"
	if elapsed >= 2.0:
		phase = "done"
		finished.emit()
