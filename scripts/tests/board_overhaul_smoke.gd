extends SceneTree
## Verifies Phase 4 board state and visual nodes without claiming graphical QA.

const Data = preload("res://scripts/data.gd")
const BoardVisual = preload("res://scripts/board_visual.gd")

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var visual: Variant = game.bv
	var ornaments: Node3D = visual.get_node("Model/KingdomOrnaments")
	check(ornaments.get_child_count() >= 16, "3D frame and kingdom ornaments exist")
	check(game.royal_lights.size() == 2 and game.sun.shadow_enabled and game.cam.fov == 40.0, "kingdom lighting and board camera configured")
	var white_crest := false
	var black_crest := false
	for obj in ornaments.get_children():
		if obj is MeshInstance3D and obj.mesh is TorusMesh:
			var emission: Color = obj.material_override.emission
			if emission.is_equal_approx(BoardVisual.WHITE_ACCENT): white_crest = true
			if emission.is_equal_approx(BoardVisual.BLACK_ACCENT): black_crest = true
	check(white_crest and black_crest, "white and black kingdoms have distinct crests")
	game.stage_idx = 1
	game._apply_stage(1)
	check(visual._trim.albedo_color.is_equal_approx(Data.STAGES[1]["frame"].lightened(0.24)), "board trim follows stage theme")
	game.mode = "board"
	game._process(1.0)
	var pawn_screen: Vector2 = game.cam.unproject_position(visual.to_global(visual.square_pos(Vector2i(3, 1))))
	game._click(pawn_screen)
	check(game.selected == Vector2i(3, 1), "new camera still maps screen clicks to board squares")
	game._select(Vector2i(0, 1))
	await process_frame
	check(visual.get_node("Highlights").get_child_count() == 3, "selected pawn and two legal destinations marked")
	game.chess_rules.set_fen("4k3/8/8/8/8/1p6/P7/4K3 w - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	game._select(Vector2i(0, 1))
	var capture_ring := false
	for mark in visual.get_node("Highlights").get_children():
		if mark is MeshInstance3D and mark.mesh is TorusMesh and mark.position.distance_to(visual.square_pos(Vector2i(1, 2))) < 0.2:
			capture_ring = true
	check(capture_ring, "capture square uses a separate ring")
	game._apply_move(Vector2i(0, 1), Vector2i(0, 2))
	check(visual.get_node("LastMove").get_child_count() == 2, "last move retains origin and destination")
	game._new_game()
	await process_frame
	check(visual.get_node("LastMove").get_child_count() == 0, "new match clears last move")
	game.chess_rules.set_fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	game._animate_move(Vector2i(0, 6), Vector2i(0, 7))
	for i in 30:
		if game.mode == "promotion": break
		await create_timer(0.05).timeout
	var picker: Variant = game.get_node_or_null("PromotionPicker")
	check(picker != null and game.mode == "promotion" and picker.buttons.size() == 5, "five-warrior promotion panel opens")
	if picker != null:
		picker._choose("Q")
	await process_frame
	check(game.mode == "board" and game.board[Vector2i(0, 7)].t == "Q" and not game.white_turn, "promotion choice updates board and turn")
	game._new_game()
	game.mode = "board"
	game.chess_rules.set_fen("4k3/8/8/8/8/1p6/P7/4K3 w - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	game._start_duel(Vector2i(0, 1), Vector2i(1, 2))
	check(game.mode == "capture", "capture begins with board cinematic")
	await create_timer(0.7).timeout
	check(game.mode == "duel" and not visual.visible, "cinematic hands off to duel")
	var duel: Node
	for child in game.get_children():
		if child.has_signal("finished"):
			duel = child
			break
	if duel != null:
		duel.emit_signal("finished", true)
	await process_frame
	check(game.mode == "board" and visual.visible and visual.get_node("LastMove").get_child_count() == 2, "duel returns to marked board")
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("Board overhaul smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
