extends SceneTree
## Verifies stage-specific surrounding scene assets and board clearance.

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	var scene: PackedScene = load("res://scenes/board_environment.tscn")
	var expected := ["Nature_Tree", "MagmaCore", "Obelisk", "WildFlower", "Crystal_"]
	for stage in 5:
		var environment: Variant = scene.instantiate()
		environment.preview_stage = stage
		root.add_child(environment)
		var islands: Node3D = environment.get_node("GeneratedProps")
		check(islands.get_child_count() == 10, "stage %d has ten original surrounding islands" % stage)
		var themed := false
		var clear := true
		for island in islands.get_children():
			var nearest := Vector2(clampf(island.position.x, -4.8, 4.8), clampf(island.position.z, -4.8, 4.8))
			var clearance := Vector2(island.position.x, island.position.z).distance_to(nearest)
			if clearance < float(island.get_meta("footprint_radius")) + 0.1: clear = false
			for part in island.get_children():
				if String(part.name).begins_with(expected[stage]): themed = true
		check(clear, "stage %d props remain outside board" % stage)
		check(themed, "stage %d has its own themed assets" % stage)
		if stage == 0:
			check(environment.find_children("CapitalIsleTower", "Node3D", true, false).size() == 2, "Floating Island board has two Issum-palette town towers")
			check(environment.find_children("Nature_*", "MeshInstance3D", true, false).size() >= 20, "Floating Island board uses imported nature meshes")
		environment.queue_free()
		await process_frame
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var found := false
	var board_surrounds: Node3D
	for child in game.scenery.get_children():
		if child.name == "BoardEnvironment":
			found = true
			board_surrounds = child
	check(found, "F5 scenery includes new environment scene")
	root.size = Vector2i(1280, 720)
	game.mode = "board"
	game._process(1.0)
	await process_frame
	var visible_parts := 0
	if board_surrounds != null:
		for island in board_surrounds.get_node("GeneratedProps").get_children():
			for part in island.get_children():
				if game.cam.is_position_in_frustum(part.global_position): visible_parts += 1
	check(visible_parts >= 8, "surrounding asset parts enter the board camera view")
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("Board environment smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
