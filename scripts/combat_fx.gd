extends Node3D
# World-space ribbons are sampled from the animated bones, not the aim reticle.
# No collision, global time scale, or game-state changes in this class.
const TRAIL_LIMIT := 10
const TRAIL_LIFE := 0.16
var trails: Dictionary = {}
var clock := 0.0

func tick(dt: float) -> void:
	clock += dt
	for id in trails:
		var entry: Dictionary = trails[id]
		var points: Array = entry["points"]
		while not points.is_empty() and clock - float(points[0]["t"]) > TRAIL_LIFE:
			points.pop_front()
		_rebuild(entry)

func sample(id: String, a: Vector3, b: Vector3, color: Color) -> void:
	if not trails.has(id):
		var node := MeshInstance3D.new()
		var geometry := ImmediateMesh.new()
		node.mesh = geometry
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		trails[id] = {"mesh": geometry, "node": node, "points": [], "color": color}
	var entry: Dictionary = trails[id]
	var points: Array = entry["points"]
	if not points.is_empty() and clock - float(points[-1]["t"]) > 0.05:
		points.clear() # Never connect two different swings with a long ribbon.
	points.append({"a": to_local(a), "b": to_local(b), "t": clock})
	while points.size() > TRAIL_LIMIT: points.pop_front()
	_rebuild(entry)

func reset_trail(id: String) -> void:
	if not trails.has(id): return
	var entry: Dictionary = trails[id]
	entry["points"].clear()
	_rebuild(entry)

func _rebuild(entry: Dictionary) -> void:
	var geometry: ImmediateMesh = entry["mesh"]
	geometry.clear_surfaces()
	var points: Array = entry["points"]
	if points.size() < 2: return
	geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for point in points:
		var fade := clampf(1.0 - (clock - float(point["t"])) / TRAIL_LIFE, 0.0, 1.0)
		var color: Color = entry["color"]
		color.a = fade * 0.20
		geometry.surface_set_color(color)
		geometry.surface_add_vertex(point["a"])
		color.a = fade * 0.85
		geometry.surface_set_color(color)
		geometry.surface_add_vertex(point["b"])
	geometry.surface_end()

func popup(point: Vector3, value: float, color: Color, word: String = "") -> void:
	var label := Label3D.new()
	label.text = word if not word.is_empty() else ("-%.1f" % value if absf(value-roundf(value)) > 0.05 else "-%d" % roundi(value))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48 if word.is_empty() else 35
	label.outline_size = 9
	label.pixel_size = 0.006
	label.modulate = color
	label.outline_modulate = Color(0.08,0.10,0.14,0.95)
	add_child(label)
	label.global_position = point
	var tw := create_tween().bind_node(label).set_parallel(true)
	tw.tween_property(label,"position",label.position + Vector3.UP*0.85,0.66).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label,"modulate:a",0.0,0.35).set_delay(0.31)
	tw.tween_property(label,"outline_modulate:a",0.0,0.35).set_delay(0.31)
	tw.chain().tween_callback(label.queue_free)

func shock_ring(point: Vector3, color: Color, size: float, duration: float = 0.28, upright: bool = false) -> void:
	var node := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.46
	torus.outer_radius = 0.51
	torus.rings = 16
	torus.ring_segments = 6
	node.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.global_position = point
	if upright:
		var cam := get_viewport().get_camera_3d()
		if cam != null and cam.global_position.distance_to(point) > 0.1:
			node.look_at(cam.global_position)
			node.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	node.scale = Vector3.ONE * 0.25
	var tw := create_tween().bind_node(node).set_parallel(true)
	tw.tween_property(node,"scale",Vector3.ONE*size,duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat,"albedo_color:a",0.0,duration)
	tw.chain().tween_callback(node.queue_free)
