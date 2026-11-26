@tool
extends RefCounted
## Decorative imports shared by the board backdrop and Floating Island duel arena.

const NaturePack = preload("res://assets/arena/floating_island/nature/LP_PACK_SS.fbx")
const TownPalette = preload("res://assets/arena/floating_island/issum/Main_Pallete.png")

static var _nature_meshes: Dictionary = {}

static func _nature_mesh(name: String) -> Mesh:
	if _nature_meshes.is_empty():
		var pack: Node3D = NaturePack.instantiate()
		for child in pack.get_children():
			if child is MeshInstance3D:
				_nature_meshes[child.name] = child.mesh
		pack.free()
	return _nature_meshes.get(name)

static func nature_prop(parent: Node3D, mesh_name: String, ground: Vector3, height: float, angle: float = 0.0) -> MeshInstance3D:
	var mesh := _nature_mesh(mesh_name)
	if mesh == null: return null
	var box := mesh.get_aabb()
	if box.size.y <= 0.0: return null
	var sizing := height / box.size.y
	var part := MeshInstance3D.new()
	part.name = "Nature_%s" % mesh_name
	part.mesh = mesh
	part.scale = Vector3.ONE * sizing
	part.position = ground - Vector3((box.position.x + box.size.x * 0.5) * sizing, box.position.y * sizing, (box.position.z + box.size.z * 0.5) * sizing)
	part.rotation.y = angle
	parent.add_child(part)
	return part

static func _color(value: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = value
	mat.roughness = 0.83
	return mat

static func _box(parent: Node3D, name: String, size: Vector3, place: Vector3, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = mesh
	part.material_override = mat
	part.position = place
	parent.add_child(part)

static func town_tower(parent: Node3D, ground: Vector3, height: float = 2.4) -> Node3D:
	## A small original silhouette using the supplied Issum window palette, placed outside play lanes.
	var town := Node3D.new()
	town.name = "CapitalIsleTower"
	town.position = ground
	town.scale = Vector3.ONE * (height / 2.4)
	parent.add_child(town)
	var wall := _color(Color("ad9d82"))
	var trim := _color(Color("63483c"))
	var roof := _color(Color("7b5144"))
	_box(town, "StoneBase", Vector3(1.45, 1.55, 1.36), Vector3(0, 0.78, 0), wall)
	_box(town, "TimberBelt", Vector3(1.58, 0.14, 1.48), Vector3(0, 1.49, 0), trim)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 1.12
	cap.height = 0.82
	cap.radial_segments = 4
	var cap_part := MeshInstance3D.new()
	cap_part.name = "PyramidRoof"
	cap_part.mesh = cap
	cap_part.material_override = roof
	cap_part.position = Vector3(0, 1.98, 0)
	cap_part.rotation.y = PI / 4.0
	town.add_child(cap_part)
	var atlas := AtlasTexture.new()
	atlas.atlas = TownPalette
	atlas.region = Rect2(0, 0, 180, 145)
	var window_mat := _color(Color.WHITE)
	window_mat.albedo_texture = atlas
	window_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	window_mat.emission_enabled = true
	window_mat.emission = Color("ecb86b")
	window_mat.emission_energy_multiplier = 0.5
	var facade := QuadMesh.new()
	facade.size = Vector2(1.05, 0.90)
	var window_part := MeshInstance3D.new()
	window_part.name = "IssumWindowPalette"
	window_part.mesh = facade
	window_part.material_override = window_mat
	window_part.position = Vector3(0, 0.90, -0.692)
	town.add_child(window_part)
	return town
