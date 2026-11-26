extends SceneTree
## Imported Floating Island visuals must resolve materials and remain decorative.

const NaturePack = preload("res://assets/arena/floating_island/nature/LP_PACK_SS.fbx")
const FloatingAssets = preload("res://scripts/floating_asset_library.gd")
const FloatingVisuals = preload("res://scripts/floating_visuals.gd")
const Data = preload("res://scripts/data.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	var pack: Node3D = NaturePack.instantiate()
	var mesh_count := 0
	var textured := false
	for child in pack.get_children():
		if child is MeshInstance3D:
			mesh_count += 1
			if child.name == "TreeR1":
				var mat: StandardMaterial3D = child.get_active_material(0)
				textured = mat != null and mat.albedo_texture != null
	check(mesh_count == 67 and textured, "nature FBX imports 67 meshes with gradient material")
	pack.free()
	var staging := Node3D.new()
	root.add_child(staging)
	var tree: MeshInstance3D = FloatingAssets.nature_prop(staging, "TreeR1", Vector3(3, 0.4, -3), 2.1)
	check(tree != null and absf(tree.get_aabb().size.y * tree.scale.y - 2.1) < 0.01 and tree.get_child_count() == 0, "nature tree is height-normalized and has no collision")
	var town: Node3D = FloatingAssets.town_tower(staging, Vector3.ZERO)
	var windows: MeshInstance3D = town.get_node("IssumWindowPalette")
	var window_mat: StandardMaterial3D = windows.material_override
	check(window_mat.albedo_texture is AtlasTexture and town.find_children("*", "CollisionShape3D", true, false).is_empty(), "town facade uses Issum palette with no gameplay collision")
	var visuals: Node3D = FloatingVisuals.new()
	root.add_child(visuals)
	visuals.build_backdrop()
	var imported_trees := visuals.find_children("Nature_TreeR1", "MeshInstance3D", true, false)
	var town_towers := visuals.find_children("CapitalIsleTower", "Node3D", true, false)
	check(imported_trees.size() == 4 and town_towers.size() == 2, "3D duel backdrop has nature trees and distant town towers")
	var duel = load("res://scripts/duel_3d.gd").new()
	root.add_child(duel)
	duel.setup("P", "K", true, Data.STAGES[0])
	duel.set_physics_process(false)
	duel.set_process_input(false)
	await process_frame
	var arena_imports: Array[Node] = duel.find_children("Nature_*", "MeshInstance3D", true, false)
	var visible_imports := 0
	for part in arena_imports:
		if duel.camera.is_position_in_frustum(part.global_position): visible_imports += 1
	check(arena_imports.size() >= 16 and duel.arena_parts.size() == 4 and duel.bridges.size() == 4, "3D combat retains four islands and bridges while adding visual-only imports")
	check(visible_imports > 0, "imported assets enter the 3D combat camera frustum")
	duel.queue_free()
	staging.queue_free()
	visuals.queue_free()
	await process_frame
	print("Floating asset smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
