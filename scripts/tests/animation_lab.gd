extends Node3D

const Duel3D = preload("res://scripts/duel_3d.gd")
const Data = preload("res://scripts/data.gd")
const KINDS := ["P", "N", "B", "R", "Q", "K", "W"]
const LABELS := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King", "Warlord"]
var menu: CanvasLayer
var player_select: OptionButton
var opponent_select: OptionButton
var active: Node3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.57, 0.78)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.9, 1.0)
	env.ambient_light_energy = 0.65
	world.environment = env
	add_child(world)
	menu = CanvasLayer.new()
	add_child(menu)
	var center := CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margins := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margins.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margins)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(400, 0)
	content.add_theme_constant_override("separation", 12)
	margins.add_child(content)
	var title := Label.new()
	title.text = "CHESS DUEL | ANIMATION LAB"
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)
	var player_label := Label.new()
	player_label.text = "Your fighter"
	content.add_child(player_label)
	player_select = OptionButton.new()
	content.add_child(player_select)
	var enemy_label := Label.new()
	enemy_label.text = "AI opponent"
	content.add_child(enemy_label)
	opponent_select = OptionButton.new()
	content.add_child(opponent_select)
	for i in range(KINDS.size()):
		player_select.add_item(LABELS[i])
		opponent_select.add_item(LABELS[i])
	player_select.select(0)
	opponent_select.select(5)
	var start := Button.new()
	start.text = "START PRACTICE"
	content.add_child(start)
	start.pressed.connect(_start)
	var help := Label.new()
	help.text = "WASD / Shift / Space / Alt\nLMB attack / RMB block / Q special\nF2: return to fighter selection"
	content.add_child(help)
	var exit := Button.new()
	exit.text = "BACK TO MAIN GAME"
	content.add_child(exit)
	exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))

func _start() -> void:
	if is_instance_valid(active): return
	var duel := Duel3D.new()
	active = duel
	menu.hide()
	add_child(duel)
	duel.finished.connect(_finished)
	duel.setup(KINDS[player_select.selected], KINDS[opponent_select.selected], true, Data.STAGES[0])

func _finished(_won: bool) -> void:
	_reset()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		if is_instance_valid(active):
			call_deferred("_reset")

func _reset() -> void:
	if is_instance_valid(active):
		active.queue_free()
		active = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
