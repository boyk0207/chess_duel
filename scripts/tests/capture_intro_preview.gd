extends Node3D
## Open this scene and press F6 to review all 49 capture entrances.

const BoardScene = preload("res://scenes/board_visual.tscn")
const IntroScene = preload("res://scenes/capture_intro.tscn")
const IntroScript = preload("res://scripts/capture_intro.gd")
const Data = preload("res://scripts/data.gd")

var board: Node3D
var intro: Node3D
var attacker_index := 0
var defender_index := 0
var info: Label

func _ready() -> void:
	board = BoardScene.instantiate()
	add_child(board)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, 35, 0)
	light.light_energy = 1.5
	add_child(light)
	var camera := Camera3D.new()
	camera.fov = 43.0
	camera.position = Vector3(0, 4.5, 5.4)
	add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0), Vector3.UP)
	camera.current = true
	var ui := CanvasLayer.new()
	add_child(ui)
	info = Label.new()
	info.position = Vector2(20, 20)
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color.WHITE)
	info.add_theme_color_override("font_shadow_color", Color.BLACK)
	info.add_theme_constant_override("shadow_offset_x", 2)
	info.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(info)
	_replay()

func _replay() -> void:
	if is_instance_valid(intro): intro.queue_free()
	var a: String = IntroScript.KINDS[attacker_index]
	var d: String = IntroScript.KINDS[defender_index]
	intro = IntroScene.instantiate()
	board.get_node("Pieces").add_child(intro)
	intro.call("configure", a, true, d, false, Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, -0.8), 1.0, Vector3.FORWARD, Color.SKY_BLUE)
	var plan: Dictionary = intro.plan
	info.text = "%s vs %s  (%d / 49)\n%s → %s | %s / %s to arena\nA/D: attacker  J/L: defender  Space: replay" % [Data.NAMES[a], Data.NAMES[d], attacker_index * 7 + defender_index + 1, plan["strike"], plan["reaction"], plan["exit_attacker"]["style"], plan["exit_defender"]["style"]]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_A: attacker_index = wrapi(attacker_index - 1, 0, 7)
		KEY_D: attacker_index = wrapi(attacker_index + 1, 0, 7)
		KEY_J: defender_index = wrapi(defender_index - 1, 0, 7)
		KEY_L: defender_index = wrapi(defender_index + 1, 0, 7)
		KEY_SPACE: pass
		_: return
	_replay()
