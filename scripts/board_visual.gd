@tool
extends Node3D
# Editable board visual (open board_visual.tscn in the editor).
#  - Put your own 3D board model under the "Model" node. When "Model" has children,
#    the built-in island / frame is skipped.
#  - Adjust square_size / surface_y / piece_scale so the 8x8 grid and the pieces line up with your model.
#  - Turn generate_tiles off if your model already has its own squares.
# Grid: A1 corner of White is at (-3.5, 3.5) squares from this node's origin; White plays toward -Z.

@export var square_size := 1.0
@export var surface_y := 0.0
@export var piece_scale := 1.0
@export var generate_tiles := true
@export var tile_height := 0.1

var _mat_light: StandardMaterial3D
var _mat_dark: StandardMaterial3D
var _grass: StandardMaterial3D
var _rock: StandardMaterial3D
var _frame: StandardMaterial3D
var _default_look := false
var _trim: StandardMaterial3D
var _last_move_root: Node3D
var _king_warning_root: Node3D

const WHITE_ACCENT := Color(0.30, 0.83, 1.0)
const BLACK_ACCENT := Color(1.0, 0.34, 0.25)

func _ready() -> void:
	# The actual board meshes are saved in board_visual.tscn and visible in the editor.
	# Keep references so stage selection changes these same materials at runtime.
	_default_look = true
	_frame = get_node("Model/Frame").material_override
	_grass = get_node("Model/Grass").material_override
	_rock = get_node("Model/Rock").material_override
	_mat_light = get_node("Tiles/Tile_0_1").material_override
	_mat_dark = get_node("Tiles/Tile_0_0").material_override
	_build_kingdom_frame()
	_last_move_root = Node3D.new()
	_last_move_root.name = "LastMove"
	add_child(_last_move_root)
	_king_warning_root = Node3D.new()
	_king_warning_root.name = "KingWarning"
	add_child(_king_warning_root)

func pieces_root() -> Node3D:
	return get_node("Pieces")

# Local position of a square's centre (x = file 0..7, y = rank 0..7)
func square_pos(p: Vector2i) -> Vector3:
	return Vector3((p.x - 3.5) * square_size, surface_y, (3.5 - p.y) * square_size)

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m

func _add(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)

func _glow(c: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.4
	m.metallic = 0.28
	m.roughness = 0.35
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _build_kingdom_frame() -> void:
	var ornaments := Node3D.new()
	ornaments.name = "KingdomOrnaments"
	get_node("Model").add_child(ornaments)
	var sq := square_size
	_trim = _glow(Color(0.79, 0.67, 0.40))
	var stone := _mat(Color(0.19, 0.24, 0.30))
	stone.metallic = 0.28
	stone.roughness = 0.65
	for side in [-1.0, 1.0]:
		var rail := BoxMesh.new()
		rail.size = Vector3(8.38 * sq, 0.14 * sq, 0.17 * sq)
		_add(ornaments, rail, Vector3(0, surface_y + 0.06 * sq, side * 4.14 * sq), _trim)
		var rail_x := BoxMesh.new()
		rail_x.size = Vector3(0.17 * sq, 0.14 * sq, 8.38 * sq)
		_add(ornaments, rail_x, Vector3(side * 4.14 * sq, surface_y + 0.06 * sq, 0), _trim)
		var kingdom := BoxMesh.new()
		kingdom.size = Vector3(6.2 * sq, 0.12 * sq, 0.54 * sq)
		_add(ornaments, kingdom, Vector3(0, surface_y - 0.02 * sq, side * 4.51 * sq), stone)
		var accent := WHITE_ACCENT if side > 0.0 else BLACK_ACCENT
		var crest := TorusMesh.new()
		crest.inner_radius = 0.22 * sq
		crest.outer_radius = 0.34 * sq
		_add(ornaments, crest, Vector3(0, surface_y + 0.08 * sq, side * 4.49 * sq), _glow(accent))
		var stripe := BoxMesh.new()
		stripe.size = Vector3(4.8 * sq, 0.035 * sq, 0.06 * sq)
		_add(ornaments, stripe, Vector3(0, surface_y + 0.05 * sq, side * 4.68 * sq), _glow(accent))
		for x_side in [-1.0, 1.0]:
			var tower := CylinderMesh.new()
			tower.top_radius = 0.22 * sq
			tower.bottom_radius = 0.30 * sq
			tower.height = 0.62 * sq
			_add(ornaments, tower, Vector3(x_side * 4.42 * sq, surface_y + 0.23 * sq, side * 4.42 * sq), stone)
			var cap := CylinderMesh.new()
			cap.top_radius = 0.06 * sq
			cap.bottom_radius = 0.27 * sq
			cap.height = 0.25 * sq
			_add(ornaments, cap, Vector3(x_side * 4.42 * sq, surface_y + 0.65 * sq, side * 4.42 * sq), _glow(accent))

func _build_default_look(model: Node3D) -> void:
	var sq := square_size
	_frame = _mat(Color(0.78, 0.74, 0.55))
	_grass = _mat(Color(0.45, 0.62, 0.2))
	_rock = _mat(Color(0.42, 0.32, 0.24))
	var frame := BoxMesh.new()
	frame.size = Vector3(9.6 * sq, 0.3, 9.6 * sq)
	_add(model, frame, Vector3(0, surface_y - 0.2, 0), _frame)
	var grass := CylinderMesh.new()
	grass.top_radius = 8.0 * sq
	grass.bottom_radius = 7.4 * sq
	grass.height = 0.5
	_add(model, grass, Vector3(0, surface_y - 0.6, 0), _grass)
	var rock := CylinderMesh.new()
	rock.top_radius = 7.4 * sq
	rock.bottom_radius = 2.0 * sq
	rock.height = 5.0
	_add(model, rock, Vector3(0, surface_y - 3.4, 0), _rock)

func _build_tiles() -> void:
	_mat_light = _mat(Color(0.92, 0.88, 0.76))
	_mat_dark = _mat(Color(0.52, 0.47, 0.42))
	var tiles: Node3D = get_node("Tiles")
	var bm := BoxMesh.new()
	bm.size = Vector3(square_size, tile_height, square_size)
	for x in 8:
		for y in 8:
			var p := Vector2i(x, y)
			var light := (x + y) % 2 == 1
			_add(tiles, bm, square_pos(p) + Vector3(0, -tile_height * 0.5, 0), _mat_light if light else _mat_dark)

func apply_stage(st: Dictionary) -> void:
	if _mat_light != null:
		_mat_light.albedo_color = st["tile_l"]
		_mat_dark.albedo_color = st["tile_d"]
	if _default_look:
		_grass.albedo_color = st["grass"]
		_rock.albedo_color = st["rock"]
		_frame.albedo_color = st["frame"]
		_trim.albedo_color = st["frame"].lightened(0.24)
		_trim.emission = st["frame"].lightened(0.12)

func highlight(p: Vector2i, col: Color) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(col.r, col.g, col.b, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var bm := BoxMesh.new()
	bm.size = Vector3(square_size * 0.94, 0.02, square_size * 0.94)
	_add(get_node("Highlights"), bm, square_pos(p) + Vector3(0, 0.03, 0), m)

func show_selected(p: Vector2i, white: bool) -> void:
	var color := WHITE_ACCENT if white else BLACK_ACCENT
	var ring := TorusMesh.new()
	ring.inner_radius = 0.33 * square_size
	ring.outer_radius = 0.44 * square_size
	_add(get_node("Highlights"), ring, square_pos(p) + Vector3(0, 0.075 * square_size, 0), _glow(color))

func show_legal_move(p: Vector2i) -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 0.19 * square_size
	disc.bottom_radius = 0.19 * square_size
	disc.height = 0.025 * square_size
	_add(get_node("Highlights"), disc, square_pos(p) + Vector3(0, 0.055 * square_size, 0), _glow(Color(0.43, 1.0, 0.62), 0.7))

func show_capture(p: Vector2i) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34 * square_size
	ring.outer_radius = 0.46 * square_size
	_add(get_node("Highlights"), ring, square_pos(p) + Vector3(0, 0.075 * square_size, 0), _glow(Color(1.0, 0.22, 0.18)))

func mark_last_move(from: Vector2i, to: Vector2i) -> void:
	clear_last_move()
	for p in [from, to]:
		var plate := BoxMesh.new()
		plate.size = Vector3(0.86 * square_size, 0.012 * square_size, 0.86 * square_size)
		_add(_last_move_root, plate, square_pos(p) + Vector3(0, 0.021 * square_size, 0), _glow(Color(1.0, 0.76, 0.31), 0.34 if p == from else 0.48))

func clear_last_move() -> void:
	if _last_move_root == null: return
	for c in _last_move_root.get_children():
		c.queue_free()

func clear_all_marks() -> void:
	clear_highlights()
	clear_last_move()
	clear_king_warning()

func set_king_warning(p: Vector2i, mate: bool = false) -> void:
	clear_king_warning()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.39 * square_size
	ring.outer_radius = 0.50 * square_size
	_add(_king_warning_root, ring, square_pos(p) + Vector3(0, 0.12 * square_size, 0), _glow(Color(1.0, 0.13, 0.08)))
	if mate:
		var outer := TorusMesh.new()
		outer.inner_radius = 0.50 * square_size
		outer.outer_radius = 0.58 * square_size
		_add(_king_warning_root, outer, square_pos(p) + Vector3(0, 0.14 * square_size, 0), _glow(Color(1.0, 0.65, 0.15)))

func clear_king_warning() -> void:
	if _king_warning_root == null: return
	for c in _king_warning_root.get_children(): c.queue_free()

func clear_highlights() -> void:
	for c in get_node("Highlights").get_children():
		c.queue_free()

