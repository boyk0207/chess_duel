extends Node3D
## Launch this scene explicitly with F6. F5 remains scenes/main.tscn.

const Data = preload("res://scripts/data.gd")
var origin: Node3D

func _ready() -> void:
	Sound.set_music("menu")
	origin = Node3D.new()
	add_child(origin)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(scroll)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	scroll.add_child(layout)
	var heading := Label.new()
	heading.text = "PHASE 3 SOUND TEST  |  F6 scene only"
	layout.add_child(heading)
	for kind in Sound.KINDS:
		var row := HBoxContainer.new()
		layout.add_child(row)
		var label := Label.new()
		label.text = Data.NAMES[kind]
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var cues := ["attack", "swing", "special", "step", "hit"]
		if kind != "P": cues.insert(3, "special_impact")
		for cue in cues:
			var button := Button.new()
			button.text = cue.capitalize()
			button.pressed.connect(_play_character.bind(cue, kind))
			row.add_child(button)
	for cue in ["wind", "waterfall", "thunder", "impactPlank_medium_001", "impactMining_003"]:
		var button := Button.new()
		button.text = cue.capitalize()
		button.pressed.connect(_play_environment.bind(cue))
		layout.add_child(button)
	for cue in ["swing", "heavy_swing", "body_hit", "heavy_hit", "block", "perfect_block", "counter", "dodge", "landing", "cast_release", "projectile_impact", "magic_impact", "shard", "victory", "defeat", "board_move", "board_capture", "ui_click"]:
		var button := Button.new()
		button.text = cue.replace("_", " ").capitalize()
		button.pressed.connect(func(): Sound.play_flat(cue))
		layout.add_child(button)
	for music in ["menu", "board", "battle", "island_battle"]:
		var button := Button.new()
		button.text = "Music: " + music
		button.pressed.connect(func(): Sound.set_music(music))
		layout.add_child(button)
	for bus_name in ["Master", "Music", "SFX", "UI", "Ambience"]:
		var row := HBoxContainer.new()
		layout.add_child(row)
		var label := Label.new()
		label.text = bus_name
		label.custom_minimum_size.x = 170
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size.x = 280
		slider.max_value = 1.0
		slider.step = 0.01
		slider.value = Sound.get_volume(bus_name)
		slider.value_changed.connect(func(v: float): Sound.set_volume(bus_name, v))
		row.add_child(slider)

func _play_character(cue: String, kind: String) -> void:
	Sound.play_flat(cue, kind)

func _play_environment(cue: String) -> void:
	if cue in ["wind", "waterfall"]:
		Sound.start_ambience(origin, Vector3(3, 0, 0), cue)
		get_tree().create_timer(5.0).timeout.connect(func(): Sound.stop_ambience(origin))
	else:
		Sound.play_spatial(cue, Vector3(3, 0, 0), origin)
