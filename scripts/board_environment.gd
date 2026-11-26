@tool
extends Node3D
## Original voxel-styled surrounding assets for the five board stages.
## All geometry is decorative, outside the 8x8 board and free of collision.

const Data = preload("res://scripts/data.gd")
const FloatingAssets = preload("res://scripts/floating_asset_library.gd")

@export_range(0, 4) var preview_stage := 0
var generated: Node3D
var materials: Dictionary = {}

func _ready() -> void:
	build(preview_stage)

func _material(color: Color, glowing: bool = false) -> StandardMaterial3D:
	var key := color.to_html(true) + ("g" if glowing else "m")
	if materials.has(key): return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.70 if not glowing else 0.26
	mat.metallic = 0.12 if not glowing else 0.35
	if glowing:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 2.0
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key] = mat
	return mat

func _mesh(parent: Node3D, name: String, geometry: Mesh, position: Vector3, color: Color, glowing: bool = false) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name
	part.mesh = geometry
	part.position = position
	part.material_override = _material(color, glowing)
	parent.add_child(part)
	return part

func _box(parent: Node3D, name: String, position: Vector3, size: Vector3, color: Color, glowing: bool = false) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	_mesh(parent, name, shape, position, color, glowing)

func _taper(parent: Node3D, name: String, position: Vector3, height: float, bottom: float, top: float, color: Color, glowing: bool = false, sides: int = 8) -> void:
	var shape := CylinderMesh.new()
	shape.height = height
	shape.bottom_radius = bottom
	shape.top_radius = top
	shape.radial_segments = sides
	_mesh(parent, name, shape, position, color, glowing)

func _halo(parent: Node3D, position: Vector3, radius: float, color: Color) -> void:
	var shape := TorusMesh.new()
	shape.inner_radius = radius * 0.84
	shape.outer_radius = radius
	_mesh(parent, "RuneHalo", shape, position, color, true)

func _island(parent: Node3D, index: int, radius: float, stage: Dictionary, rng: RandomNumberGenerator) -> Node3D:
	var island := Node3D.new()
	island.name = "SatelliteIsland_%02d" % index
	island.set_meta("footprint_radius", radius)
	parent.add_child(island)
	var angle := TAU * float(index) / 10.0 + 0.17
	var distance := 8.2 if index in [7, 8] else 9.0 + float(index % 3) * 0.8
	island.position = Vector3(cos(angle) * distance, rng.randf_range(-0.9, 0.15), sin(angle) * distance)
	_taper(island, "HangingRock", Vector3(0, -1.70, 0), 2.7, 0.30, radius * 0.94, stage["rock"])
	_taper(island, "TopSoil", Vector3(0, -0.29, 0), 0.22, radius * 0.90, radius, stage["grass"])
	_taper(island, "StoneLip", Vector3(0, -0.43, 0), 0.13, radius * 0.98, radius * 1.02, stage["frame"])
	return island

func _column(parent: Node3D, x: float, z: float, height: float, stone: Color, accent: Color) -> void:
	_box(parent, "ColumnFoot", Vector3(x, 0.08, z), Vector3(0.66, 0.22, 0.66), stone.darkened(0.12))
	_box(parent, "ColumnShaft", Vector3(x, 0.16 + height * 0.5, z), Vector3(0.43, height, 0.43), stone)
	_box(parent, "ColumnCapital", Vector3(x, 0.22 + height, z), Vector3(0.72, 0.28, 0.72), stone.lightened(0.18))
	_box(parent, "ColumnRune", Vector3(x, 0.24 + height, z), Vector3(0.39, 0.08, 0.76), accent, true)

func _arch(parent: Node3D, stone: Color, accent: Color) -> void:
	_column(parent, -0.9, 0, 1.7, stone, accent)
	_column(parent, 0.9, 0, 1.7, stone, accent)
	_box(parent, "ArchLintel", Vector3(0, 2.12, 0), Vector3(2.35, 0.42, 0.62), stone.lightened(0.10))
	_box(parent, "ArchRune", Vector3(0, 2.13, -0.33), Vector3(0.72, 0.16, 0.05), accent, true)

func _tree(parent: Node3D, leaf: Color, flower: Color, rng: RandomNumberGenerator) -> void:
	_taper(parent, "Trunk", Vector3(0, 0.90, 0), 1.8, 0.22, 0.16, Color(0.28, 0.20, 0.14), false, 6)
	for level in 3:
		var width := 1.22 - float(level) * 0.25
		_taper(parent, "VoxelCrown_%d" % level, Vector3(0, 1.55 + float(level) * 0.70, 0), 1.15, width, 0.08, leaf.lightened(float(level) * 0.06), false, 6)
	for i in 5:
		var x := rng.randf_range(-1.4, 1.4)
		var z := rng.randf_range(-1.4, 1.4)
		_box(parent, "WildFlower_%d" % i, Vector3(x, 0.07, z), Vector3(0.13, 0.13, 0.13), flower, true)

func _crystals(parent: Node3D, base: Color, tip: Color) -> void:
	for i in 5:
		var angle := TAU * float(i) / 5.0
		var height := 1.2 + float(i % 3) * 0.55
		_taper(parent, "Crystal_%d" % i, Vector3(cos(angle) * 0.63, height * 0.5, sin(angle) * 0.63), height, 0.38, 0.02, base.lerp(tip, float(i) / 5.0), true, 6)
	_halo(parent, Vector3(0, 0.08, 0), 1.15, tip)

func _lava_vent(parent: Node3D) -> void:
	var basalt := Color(0.09, 0.08, 0.10)
	for i in 5:
		var angle := TAU * float(i) / 5.0
		var height := 1.0 + float(i % 3) * 0.45
		_taper(parent, "BasaltSpire_%d" % i, Vector3(cos(angle) * 0.78, height * 0.5, sin(angle) * 0.78), height, 0.34, 0.12, basalt, false, 6)
	_taper(parent, "MagmaCore", Vector3(0, 0.16, 0), 0.28, 0.74, 0.74, Color(1.0, 0.22, 0.035), true)
	_halo(parent, Vector3(0, 0.31, 0), 1.20, Color(1.0, 0.43, 0.08))

func _desert_relic(parent: Node3D, index: int) -> void:
	var sandstone := Color(0.72, 0.52, 0.30)
	if index % 2 == 0:
		_arch(parent, sandstone, Color(0.96, 0.73, 0.30))
	else:
		_taper(parent, "Obelisk", Vector3(0, 1.55, 0), 3.0, 0.57, 0.035, sandstone.lightened(0.12), false, 4)
		_halo(parent, Vector3(0, 0.08, 0), 1.35, Color(0.98, 0.72, 0.31))

func _waterfall(parent: Node3D, color: Color) -> void:
	_box(parent, "Waterfall", Vector3(0, -2.25, 1.30), Vector3(0.75, 3.75, 0.10), Color(color.r, color.g, color.b, 0.70), true)
	_box(parent, "Foam", Vector3(0, -4.1, 1.3), Vector3(1.5, 0.18, 0.4), Color(0.78, 0.98, 1.0, 0.78), true)

func _royal_standard(parent: Node3D, white: bool) -> void:
	var color := Color(0.30, 0.83, 1.0) if white else Color(1.0, 0.34, 0.25)
	_taper(parent, "BannerPole", Vector3(0, 1.45, 0), 2.9, 0.09, 0.07, Color(0.36, 0.34, 0.32), false, 6)
	_box(parent, "KingdomBanner", Vector3(0.44, 2.20, 0), Vector3(0.82, 1.10, 0.06), color, true)
	_box(parent, "BannerEmblem", Vector3(0.44, 2.20, -0.05), Vector3(0.22, 0.38, 0.06), Color(1.0, 0.88, 0.55), true)

func build(stage_index: int) -> void:
	if generated != null:
		generated.queue_free()
	materials.clear()
	generated = Node3D.new()
	generated.name = "GeneratedProps"
	add_child(generated)
	var stage: Dictionary = Data.STAGES[clampi(stage_index, 0, Data.STAGES.size() - 1)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 46021 + stage_index * 131
	for index in 10:
		var island := _island(generated, index, rng.randf_range(1.65, 2.15), stage, rng)
		match stage_index:
			0:
				if index in [0, 6]:
					FloatingAssets.town_tower(island, Vector3(0, -0.16, 0), 2.3)
				elif index % 3 == 0:
					_arch(island, Color(0.66, 0.65, 0.61), Color(0.44, 0.90, 1.0))
				else:
					FloatingAssets.nature_prop(island, "TreeRC1" if index % 2 == 0 else "TreeR1", Vector3(0, -0.16, 0), 2.0, float(index) * 0.7)
				FloatingAssets.nature_prop(island, "RG1", Vector3(1.05, -0.16, -0.6), 0.48)
				FloatingAssets.nature_prop(island, "FlowerY1" if index % 2 == 0 else "FlowerB1", Vector3(-1.05, -0.16, 0.6), 0.30)
				if index % 4 == 0: _waterfall(island, Color(0.35, 0.80, 1.0))
			1:
				_lava_vent(island)
			2:
				_desert_relic(island, index)
			3:
				if index % 2 == 0: _arch(island, Color(0.90, 0.87, 0.78), Color(0.90, 0.80, 0.45))
				else: _tree(island, Color(0.43, 0.67, 0.43), Color(1.0, 0.80, 0.88), rng)
				if index % 4 == 0: _waterfall(island, Color(0.65, 0.94, 1.0))
			4:
				_crystals(island, Color(0.46, 0.73, 0.93), Color(0.83, 0.98, 1.0))
		if index == 2 or index == 7:
			_royal_standard(island, index == 2)
