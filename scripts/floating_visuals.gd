extends Node3D
# Decorative only: no collision shapes, no input, no changes to combat stats.
const RockIsland = preload("res://assets/arena/Small.glb")
const Grass = preload("res://assets/arena/meadow/SM_Grass_Tuft_A.glb")
const Flower = preload("res://assets/arena/meadow/SM_Flowers_Blue.glb")
const Rock = preload("res://assets/arena/meadow/SM_Rock_Small.glb")
const Bush = preload("res://assets/arena/meadow/SM_Bush_Wild.glb")
const WaterShader = preload("res://shaders/floating_water.gdshader")
const GroundShader = preload("res://shaders/floating_ground.gdshader")
const FloatingAssets = preload("res://scripts/floating_asset_library.gd")
var rng := RandomNumberGenerator.new()
var clouds: Array[Node3D] = []
var plants: Array[Node3D] = []
var plant_phase: Array[float] = []
var clock := 0.0
var cloud_material: StandardMaterial3D
var water_material: ShaderMaterial

func make_environment() -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("3179bb")
	sky_mat.sky_horizon_color = Color("d4efff")
	sky_mat.ground_horizon_color = Color("d4efff")
	sky_mat.ground_bottom_color = Color("7299c6")
	sky_mat.sun_angle_max = 18.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c5dcfa")
	env.ambient_light_energy = 0.62
	env.ambient_light_sky_contribution = 0.0
	env.fog_enabled = true
	env.fog_light_color = Color("b2d5ee")
	env.fog_density = 0.009
	env.fog_sky_affect = 0.0
	return env

func setup_sun(light: DirectionalLight3D) -> void:
	light.rotation_degrees = Vector3(-48, -35, 0)
	light.light_color = Color("fff0d2")
	light.light_energy = 1.15
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 50.0
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS

func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	return mat

func grass_material(color: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GroundShader
	mat.set_shader_parameter("grass_color", color)
	return mat

func mesh_at(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, scale_v: Vector3 = Vector3.ONE, shadows: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	node.scale = scale_v
	if not shadows: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node

func box_at(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, shadows: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_at(parent, mesh, pos, mat, Vector3.ONE, shadows)

func prop(scene: PackedScene, parent: Node3D, pos: Vector3, size: float, animated: bool = false) -> Node3D:
	var node := scene.instantiate() as Node3D
	parent.add_child(node)
	node.position = pos
	node.scale = Vector3.ONE * size
	node.rotation.y = rng.randf_range(0.0, TAU)
	if animated:
		plants.append(node)
		plant_phase.append(rng.randf_range(0.0, TAU))
	return node

func decorate_edge(parent: Node3D, size: Vector3, grass: Color, rock: Color) -> void:
	# Existing collision top is at local y=0.4; paint the same surface.
	var top := parent.get_child(0) as MeshInstance3D
	top.material_override = grass_material(grass)
	# Layered cliff beneath the floor, parented to collapsing strip.
	box_at(parent, Vector3(size.x * 0.96, 0.85, size.z * 0.96), Vector3(0,-0.78,0), material(rock))
	box_at(parent, Vector3(size.x * 0.78, 1.0, size.z * 0.80), Vector3(0,-1.62,0), material(rock.darkened(0.18)))
	for i in range(4):
		var p := Vector3(rng.randf_range(-size.x*0.36,size.x*0.36),0.40,rng.randf_range(-size.z*0.36,size.z*0.36))
		prop(Grass if i % 2 == 0 else Flower,parent,p,0.8,true)

func decorate_satellite(parent: Node3D, index: int) -> void:
	for i in range(5):
		var p := Vector3(rng.randf_range(-3.1,3.1),0.4,rng.randf_range(-3.1,3.1))
		# Keep the bridge approach and island center clear.
		if absf(p.x) < 1.5 or absf(p.z) < 1.5: continue
		prop(Grass if i % 2 == 0 else Bush,parent,p,0.85,true)
	prop(Rock,parent,Vector3(-2.6,0.4,-2.6),0.95)
	var tree_corner := Vector3(-3.0, 0.4, 3.0) if index == 3 else Vector3(3.0, 0.4, -3.0)
	FloatingAssets.nature_prop(parent, "TreeRC1" if index % 2 == 0 else "TreeR1", tree_corner, 2.1, float(index) * 0.8)
	FloatingAssets.nature_prop(parent, "RG1", Vector3(-3.0, 0.4, -3.0), 0.65)
	FloatingAssets.nature_prop(parent, "FlowerY1" if index % 2 == 0 else "FlowerB1", Vector3(2.6, 0.4, 2.9), 0.36)

func decorate_center(parent: Node3D) -> void:
	# Do not fill the playable center with fake obstacles.
	for x in [-6.8,6.8]:
		for z in [-6.8,6.8]:
			prop(Flower,parent,Vector3(x,0.40,z),0.9,true)
			prop(Grass,parent,Vector3(x*0.90,0.40,z),0.8,true)
			FloatingAssets.nature_prop(parent, "Clump2", Vector3(x * 0.94, 0.4, z * 0.92), 0.38)

func decorate_bridge(parent: Node3D, along_x: bool) -> void:
	# Deck spans the existing 3 x 3 collision; visual-only planks.
	var deck := parent.get_child(0) as MeshInstance3D
	deck.hide()
	var wood := material(Color("aa7950"))
	var wood_dark := material(Color("855a39"))
	for i in range(8):
		var offset := -1.3125 + float(i)*0.375
		var size := Vector3(0.375,0.12,3.0) if along_x else Vector3(3.0,0.12,0.375)
		var p := Vector3(offset,0.19,0) if along_x else Vector3(0,0.19,offset)
		box_at(parent,size,p,wood if i % 3 != 0 else wood_dark)

func pad(parent: Node3D, p: Vector3) -> void:
	var stone := material(Color("374e60"))
	var glow := material(Color("47dff1"))
	glow.emission_enabled = true
	glow.emission = Color("47dff1")
	var base := CylinderMesh.new()
	base.top_radius = 0.95
	base.bottom_radius = 1.0
	base.height = 0.08
	base.radial_segments = 8
	mesh_at(parent,base,p+Vector3.UP*0.04,stone)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.62
	ring.outer_radius = 0.83
	ring.rings = 16
	ring.ring_segments = 8
	mesh_at(parent,ring,p+Vector3.UP*0.10,glow,Vector3(1,0.24,1),false)

func waterfall(parent: Node3D, pos: Vector3, angle: float, width: float, height: float) -> void:
	var plane := QuadMesh.new()
	plane.size = Vector2(width,height)
	var node := mesh_at(parent,plane,pos+Vector3.DOWN*height*0.5,water_material,Vector3.ONE,false)
	node.rotation.y = angle

func build_backdrop() -> void:
	rng.seed = 20261125
	cloud_material = material(Color("e1f2ff"))
	cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water_material = ShaderMaterial.new()
	water_material.shader = WaterShader
	var cloud_mesh := SphereMesh.new()
	cloud_mesh.radial_segments = 10
	cloud_mesh.rings = 5
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var cloud := Node3D.new()
		add_child(cloud)
		cloud.position = Vector3(cos(angle)*rng.randf_range(37.0,65.0),rng.randf_range(-17.0,-7.0),sin(angle)*rng.randf_range(37.0,65.0))
		clouds.append(cloud)
		for j in range(4):
			var p := Vector3(float(j)*3.3-5.0,rng.randf_range(-0.65,0.65),rng.randf_range(-2.0,2.0))
			mesh_at(cloud,cloud_mesh,p,cloud_material,Vector3(rng.randf_range(7.0,10.0),rng.randf_range(2.0,3.5),6.0),false)
	for i in range(8):
		var angle := TAU*float(i)/8.0+0.35
		var distance := rng.randf_range(38.0,65.0)
		var island := Node3D.new()
		add_child(island)
		island.position = Vector3(cos(angle)*distance,rng.randf_range(-5.0,5.0),sin(angle)*distance)
		var scale_v := rng.randf_range(0.36,0.68)
		var mesh := prop(RockIsland,island,Vector3.ZERO,scale_v)
		for child in mesh.find_children("*","MeshInstance3D",true,false):
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if i % 2 == 0:
			# Distant islands only: falls cannot obscure or change playable paths.
			waterfall(island,Vector3(0,-0.3,9.0*scale_v),0.0,1.1,9.0)
			waterfall(island,Vector3(9.0*scale_v,-0.3,0),PI/2,0.8,7.5)
			FloatingAssets.nature_prop(island, "TreeR1", Vector3(-1.6, 0.35, 0.4), 2.8)
		elif i in [1, 5]:
			FloatingAssets.town_tower(island, Vector3(0, 0.35, 0), 3.2)

func _process(delta: float) -> void:
	clock += delta
	for cloud in clouds:
		cloud.position.x += delta * lerpf(0.45, 3.1, storm_strength)
		if cloud.position.x > 86.0: cloud.position.x = -86.0
	for i in range(plants.size()):
		if is_instance_valid(plants[i]):
			plants[i].rotation.z = sin(clock*lerpf(2.2,6.0,storm_strength) + plant_phase[i])*lerpf(0.065,0.20,storm_strength)

var storm_strength := 0.0
func update_storm(amount: float) -> void:
	storm_strength = amount
	if cloud_material != null:
		cloud_material.albedo_color = Color("e1f2ff").lerp(Color("676f8c"),amount)
