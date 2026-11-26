extends SceneTree
## Persistent rebinding, Settings wiring, and bomb damage boundary.

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	root.size = Vector2i(1280, 720)
	var controls := root.get_node("Controls")
	controls.reset_bindings()
	check(controls.display_name("arena_attack") == "Mouse Left", "default arena attack")
	var original_special: Dictionary = controls.bindings["arena_special"].duplicate()
	check(controls.rebind("arena_attack", "key", KEY_H, false).is_empty(), "assign keyboard to mouse action")
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_H
	check(controls.matches(key_event, "arena_attack"), "physical key event matches rebound attack")
	check(controls.rebind("arena_special", "key", KEY_H, false) == "arena_attack", "same-mode conflict swaps")
	check(controls.bindings["arena_attack"] == original_special, "old special key moved to attack")
	check(controls.rebind("arena_special", "key", KEY_ESCAPE, false) == "INVALID", "Escape stays reserved")
	check(controls.rebind("p1_attack", "mouse", MOUSE_BUTTON_LEFT) == "", "2.5D attack accepts mouse")
	check(controls.bindings["p2_attack"]["type"] == "key", "player 2 bindings independent")
	controls.rebind("arena_special", "key", KEY_H)
	var saved_bindings: Dictionary = controls.bindings.duplicate(true)
	var fresh = load("res://scripts/control_bindings.gd").new()
	root.add_child(fresh)
	check(fresh.bindings == saved_bindings, "all bindings persist after reload")
	fresh.queue_free()
	controls.reset_bindings()
	await process_frame
	var main := load("res://scenes/main.tscn") as PackedScene
	var game := main.instantiate()
	root.add_child(game)
	current_scene = game
	game.call("_show_audio_settings")
	check(game.audio_settings_panel.visible and game.keybind_buttons.size() == controls.DEFAULTS.size(), "Settings exposes every control")
	await process_frame
	var panel_rect: Rect2 = game.audio_settings_panel.get_global_rect()
	var screen_size: Vector2 = game.get_viewport().get_visible_rect().size
	check(panel_rect.position.x >= 0.0 and panel_rect.position.y >= 0.0 and panel_rect.end.x <= screen_size.x and panel_rect.end.y <= screen_size.y, "Settings panel fits viewport")
	game.call("_begin_rebind", "arena_attack")
	game.call("_input", key_event)
	check(game.rebind_pending.is_empty() and controls.bindings["arena_attack"]["code"] == KEY_H, "Settings captures new key")
	game.call("_reset_controls")
	check(controls.bindings["arena_attack"]["type"] == "mouse", "Settings reset restores defaults")
	game.queue_free()
	await process_frame
	current_scene = null
	var duel_script = load("res://scripts/duel.gd")
	var duel = duel_script.new()
	root.add_child(duel)
	duel.setup("R", "P", true, load("res://scripts/data.gd").STAGES[1])
	duel.set_process(false)
	var fighters: Array = duel.fighters
	var owner = fighters[0]
	var target = fighters[1]
	var bomb = duel._spawn_proj(owner, "bomb", 0.0, 0.0, 1.2)
	bomb.s = 0.0
	bomb.y = 0.3
	target.s = 2.0
	target.y = 0.0
	var hp_before: float = target.hp
	duel._explode(bomb, target)
	check(target.hp < hp_before, "bomb damages target inside radius")
	var visible_radius := false
	for child in duel.get_children():
		if child is MeshInstance3D and child.mesh is TorusMesh and is_equal_approx(child.mesh.outer_radius, duel.BOMB_RADIUS):
			visible_radius = true
	check(visible_radius, "visible ring matches damage radius")
	target.s = 2.5
	var outside_hp: float = target.hp
	var outside_bomb = duel._spawn_proj(owner, "bomb", 0.0, 0.0, 1.2)
	outside_bomb.s = 0.0
	outside_bomb.y = 0.3
	duel._explode(outside_bomb, target)
	check(is_equal_approx(target.hp, outside_hp), "bomb spares target outside radius")
	duel.queue_free()
	await process_frame
	var duel_3d_script = load("res://scripts/duel_3d.gd")
	var arena = duel_3d_script.new()
	root.add_child(arena)
	arena.setup("R", "P", true, load("res://scripts/data.gd").STAGES[0])
	arena.set_physics_process(false)
	await physics_frame
	for distance in [2.0, 2.7]:
		arena.resolve_attack(0, Vector3.FORWARD, true)
		var projectile: Dictionary = arena.projectiles[-1]
		var mesh: Node3D = projectile["mesh"]
		mesh.position = arena.bodies[1].position + Vector3.UP + Vector3.RIGHT * distance
		projectile["velocity"] = Vector3.ZERO
		projectile["life"] = 0.0
		var before_blast: float = arena.hp[1]
		arena.update_projectiles(0.0)
		check(arena.hp[1] < before_blast if distance < arena.BOMB_RADIUS else is_equal_approx(arena.hp[1], before_blast), "3D bomb %s radius boundary" % ["inside" if distance < arena.BOMB_RADIUS else "outside"])
	arena.queue_free()
	await process_frame
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.5).timeout
	print("Controls/bomb smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
