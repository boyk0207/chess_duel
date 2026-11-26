extends Node3D
# Lightweight unshaded helix ribbons and rising arrows, for the Compatibility renderer.
var rotor: Node3D
var arrows: Array[Node3D] = []
var arrow_count := 8
var radius := 1.45
var height := 7.5
var clock := 0.0

func setup(r: float, h: float) -> void:
	radius = r
	height = h
	rotor = Node3D.new()
	add_child(rotor)
	var ribbon := StandardMaterial3D.new()
	ribbon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ribbon.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ribbon.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.albedo_color = Color(0.67,0.96,1.0,0.56)
	var mesh := ImmediateMesh.new()
	for strand in range(3):
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, ribbon)
		for step in range(81):
			var t := float(step)/80.0
			var a := TAU*(2.15*t + float(strand)/3.0)
			var rad := radius * lerpf(0.56,1.0,t)
			var p := Vector3(cos(a)*rad,0.12+t*(height-0.24),sin(a)*rad)
			var width := 0.11+0.07*sin(t*PI)
			mesh.surface_add_vertex(p-Vector3.UP*width)
			mesh.surface_add_vertex(p+Vector3.UP*width)
		mesh.surface_end()
	var helix := MeshInstance3D.new()
	helix.mesh = mesh
	helix.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rotor.add_child(helix)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color("d5fbff")
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.15
	arrow_mesh.height = 0.40
	arrow_mesh.radial_segments = 5
	for j in range(arrow_count):
		var arrow := MeshInstance3D.new()
		arrow.mesh = arrow_mesh
		arrow.material_override = glow
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arrow)
		arrows.append(arrow)
	var rim := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.outer_radius = radius
	ring.inner_radius = radius*0.86
	ring.rings = 24
	ring.ring_segments = 6
	rim.mesh = ring
	rim.material_override = glow
	rim.scale.y = 0.16
	rim.position.y = 0.07
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim)
	update_visual(0.0,0.0)

func update_visual(dt: float, storm: float) -> void:
	clock += dt
	rotor.rotation.y = clock*lerpf(2.9,4.4,storm)
	for j in range(arrows.size()):
		var t := fposmod(clock*0.62+float(j)/float(arrow_count),1.0)
		var angle := TAU*(t*1.7+float(j)/float(arrow_count)) + clock*2.0
		var rad := radius*lerpf(0.52,0.91,t)
		arrows[j].position = Vector3(cos(angle)*rad,0.2+t*(height-0.4),sin(angle)*rad)
		arrows[j].scale = Vector3.ONE * (0.55+0.45*sin(t*PI))
