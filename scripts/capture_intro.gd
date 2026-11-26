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
const REACTIONS := {
	"P": ["Hit", "DodgeBack", "Block"],
	"N": ["DodgeLeft", "Hit", "DodgeBack"],
	"B": ["Block", "DodgeBack", "Hit"],
	"R": ["Hit", "Block", "Hit"],
	"Q": ["DodgeRight", "Block", "Hit"],
	"K": ["Block", "Hit", "Block"],
	"W": ["Hit", "DodgeLeft", "Block"],
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

static func choreography(attacker_kind: String, defender_kind: String) -> Dictionary:
	if attacker_kind not in KINDS or defender_kind not in KINDS: return {}
	var attacker_index := KINDS.find(attacker_kind)
	var defender_index := KINDS.find(defender_kind)
	var lead: Dictionary = LEADS[attacker_kind]
	var reaction: Array = REACTIONS[defender_kind]
	var variant := (attacker_index + defender_index) % 3
	var clash := 0.26 + 0.025 * float(attacker_index % 3)
	var hit := clash + 0.14
	var counter := hit + 0.20
	return {
		"pair": attacker_kind + defender_kind,
		"ready": lead["ready"],
		"strike": lead["strikes"][variant],
		"reaction": reaction[(attacker_index + 2 * defender_index) % 3],
		"counter": COUNTERS[defender_kind][(defender_index + attacker_index) % 3],
		"return_guard": RETURN_GUARDS[attacker_kind][(attacker_index + defender_index) % 3],
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

func configure(attacker_kind: String, attacker_white: bool, defender_kind: String, defender_white: bool, from_pos: Vector3, target_pos: Vector3, piece_scale: float, direction: Vector3, stage_color: Color) -> void:
	self.attacker_kind = attacker_kind
	self.defender_kind = defender_kind
	plan = choreography(attacker_kind, defender_kind)
	start_attacker = from_pos
	start_defender = target_pos
	var fight_direction := (target_pos - from_pos).normalized()
	approach_attacker = from_pos + fight_direction * float(plan["approach"]) * piece_scale
	stagger_defender = target_pos + fight_direction * float(plan["stagger"]) * piece_scale
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
		_play(defender_anim, str(plan["counter"]))
		phase = "counter"
	if phase == "counter" and elapsed >= float(plan["return_at"]):
		_play(attacker_anim, str(plan["return_guard"]))
		phase = "return"
	if phase == "return" and elapsed >= float(plan["walk_at"]):
		_face(attacker, exit_direction)
		_face(defender, exit_direction)
		_play(attacker_anim, "Walk")
		_play(defender_anim, "Walk")
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
		attacker.position = recoil_attacker.lerp(end_attacker, travel)
		defender.position = counter_defender.lerp(end_defender, travel)
		gate.scale = Vector3.ONE * travel
	if phase == "walk" and elapsed >= float(plan["idle_at"]):
		_play(attacker_anim, "Idle")
		_play(defender_anim, "Idle")
		phase = "arrival"
	if elapsed >= 2.0:
		phase = "done"
		finished.emit()
