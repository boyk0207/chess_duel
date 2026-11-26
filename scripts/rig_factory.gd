extends RefCounted
# Skin/animation resources are imported as GLB scenes by Godot.
const Data = preload("res://scripts/data.gd")
const RIGS := {
	"P": preload("res://assets/rigs/P.glb"),
	"N": preload("res://assets/rigs/N.glb"),
	"B": preload("res://assets/rigs/B.glb"),
	"R": preload("res://assets/rigs/R.glb"),
	"Q": preload("res://assets/rigs/Q.glb"),
	"K": preload("res://assets/rigs/K.glb"),
	"W": preload("res://assets/rigs/W.glb")
}
const CLIPS := ["Idle", "Walk", "Run", "JumpStart", "Airborne", "Landing", "Dodge", "Block", "PerfectBlock", "Attack", "Special", "Hit", "Death", "Victory", "DodgeForward", "DodgeBack", "DodgeLeft", "DodgeRight", "Attack2", "Attack3"]
const LOOPS := ["Idle", "Walk", "Run", "Airborne", "Block"]

static func build(kind: String, height: float, black: bool = false) -> Node3D:
	var wrapper := Node3D.new()
	var scene: PackedScene = RIGS[kind]
	var instance := scene.instantiate() as Node3D
	wrapper.add_child(instance)
	wrapper.scale = Vector3.ONE * height
	var mat := StandardMaterial3D.new()
	var filename: String = Data.PARTS[kind][0]
	mat.albedo_texture = load("res://assets/%s%s.png" % [filename, "_b" if black else ""]) as Texture2D
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for child in wrapper.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		mesh.material_override = mat
		# Allow animated extremities to move outside the static mesh AABB.
		mesh.extra_cull_margin = 2.0
	wrapper.set_meta("flash_material", mat)
	var anim := player(wrapper)
	if anim != null:
		for clip in CLIPS:
			if anim.has_animation(clip):
				var resource := anim.get_animation(clip)
				resource.loop_mode = Animation.LOOP_LINEAR if clip in LOOPS else Animation.LOOP_NONE
	return wrapper

static func player(wrapper: Node3D) -> AnimationPlayer:
	var nodes := wrapper.find_children("*", "AnimationPlayer", true, false)
	return nodes[0] as AnimationPlayer if not nodes.is_empty() else null

static func skeleton(wrapper: Node3D) -> Skeleton3D:
	var nodes := wrapper.find_children("*", "Skeleton3D", true, false)
	return nodes[0] as Skeleton3D if not nodes.is_empty() else null

static func weapon(wrapper: Node3D) -> Node3D:
	var node := wrapper.find_child("Weapon", true, false)
	if node is MeshInstance3D: return node as Node3D
	for child in wrapper.find_children("*", "MeshInstance3D", true, false):
		if String(child.name).begins_with("Weapon"): return child as Node3D
	return null

static func flash(wrapper: Node3D, strength: float) -> void:
	var mat := wrapper.get_meta("flash_material") as StandardMaterial3D
	mat.emission_enabled = strength > 0.0
	mat.emission = Color(1.0, 0.65, 0.12)
	mat.emission_energy_multiplier = 1.5 * strength
