extends Node3D
const Rig = preload("res://scripts/rig_factory.gd")
const KINDS := ["P", "N", "B", "R", "Q", "K", "W"]
const NAMES := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King", "Warlord"]
var fighter: OptionButton
var clips: OptionButton
var info: Label
var model: Node3D
var anim: AnimationPlayer
var black := false
var orbit := 0.0
var cam: Camera3D
var paused := false
var repeat := true
var hide_weapon := false
var bomb: Node3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.18, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.9, 1.0)
	env.ambient_light_energy = 0.85
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -35, 0)
	light.shadow_enabled = true
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(12, 0.12, 12)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -0.06
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.24, 0.28, 0.34)
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	_update_camera()
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	ui.add_child(panel)
	panel.position = Vector2(20, 20)
	var margin := MarginContainer.new()
	panel.add_child(margin)
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	var list := VBoxContainer.new()
	margin.add_child(list)
	list.custom_minimum_size.x = 290
	var title := Label.new()
	title.text = "SKELETAL CLIP VIEWER"
	title.add_theme_font_size_override("font_size", 21)
	list.add_child(title)
	fighter = OptionButton.new()
	for label in NAMES: fighter.add_item(label)
	list.add_child(fighter)
	clips = OptionButton.new()
	for label in Rig.CLIPS: clips.add_item(label)
	list.add_child(clips)
	fighter.item_selected.connect(func(_i: int): _load_fighter())
	clips.item_selected.connect(func(_i: int): _play_clip())
	var play := Button.new()
	play.text = "REPLAY CLIP"
	list.add_child(play)
	play.pressed.connect(_play_clip)
	var pause := CheckButton.new()
	pause.text = "Pause"
	list.add_child(pause)
	pause.toggled.connect(func(on: bool):
		paused = on
		if anim != null: anim.speed_scale = 0.0 if on else 1.0)
	var loop_toggle := CheckButton.new()
	loop_toggle.text = "Repeat clip"
	loop_toggle.button_pressed = true
	list.add_child(loop_toggle)
	loop_toggle.toggled.connect(func(on: bool):
		repeat = on
		_play_clip())
	var team := CheckButton.new()
	team.text = "Black team palette"
	list.add_child(team)
	team.toggled.connect(func(on: bool):
		black = on
		_load_fighter())
	var hide := CheckButton.new()
	hide.text = "Hide separate equipment"
	list.add_child(hide)
	hide.toggled.connect(func(on: bool):
		hide_weapon = on
		_update_equipment())
	info = Label.new()
	list.add_child(info)
	var hint := Label.new()
	hint.text = "Left / Right: rotate camera\nF6: run this scene"
	list.add_child(hint)
	_load_fighter()

func _load_fighter() -> void:
	if is_instance_valid(model): model.queue_free()
	bomb = null
	var kind: String = KINDS[fighter.selected]
	model = Rig.build(kind, 2.4, black)
	add_child(model)
	anim = Rig.player(model)
	var skel := Rig.skeleton(model)
	if kind == "R":
		bomb = preload("res://assets/magma_bomb.glb").instantiate() as Node3D
		if skel != null and skel.find_bone("WeaponJoint") >= 0:
			var attach := BoneAttachment3D.new()
			skel.add_child(attach)
			attach.bone_name = "WeaponJoint"
			attach.add_child(bomb)
		else:
			model.add_child(bomb)
			bomb.position = Vector3(0.32, 0.65, -0.30)
		bomb.scale = Vector3.ONE * 0.30
	info.text = "%d bones | %d imported animations" % [skel.get_bone_count() if skel != null else 0, anim.get_animation_list().size() if anim != null else 0]
	_update_equipment()
	_play_clip()

func _update_equipment() -> void:
	if not is_instance_valid(model): return
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var name_text := String(mesh.name)
		if name_text.begins_with("Weapon") or name_text.begins_with("Offhand") or name_text.begins_with("Crown"):
			mesh.visible = not hide_weapon
	if is_instance_valid(bomb): bomb.visible = not hide_weapon

func _play_clip() -> void:
	if anim == null: return
	var clip: String = Rig.CLIPS[clips.selected]
	if not anim.has_animation(clip):
		info.text = "Missing imported clip: " + clip
		return
	anim.stop()
	anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR if repeat else Animation.LOOP_NONE
	anim.play(clip)
	anim.speed_scale = 0.0 if paused else 1.0
	anim.seek(0.0, true)

func _process(dt: float) -> void:
	var direction := float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	if direction != 0.0:
		orbit += direction * dt * 1.8
		_update_camera()
	if repeat and not paused and anim != null and not anim.is_playing(): _play_clip()

func _update_camera() -> void:
	cam.position = Vector3(4.5 * sin(orbit), 2.5, -4.5 * cos(orbit))
	cam.look_at(Vector3(0, 1.1, 0), Vector3.UP)
