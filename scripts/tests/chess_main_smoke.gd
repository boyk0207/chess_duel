extends SceneTree
## F5 regression for Chess Duel's integrated legal movement and combat captures.

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func wait_for_move(game: Variant) -> void:
	for i in 30:
		if not game.piece_animating and game.mode != "promotion": break
		await create_timer(0.05).timeout
	await process_frame

func set_position(game: Variant, fen: String) -> void:
	game.chess_rules.set_fen(fen)
	game._sync_rule_visual()
	game._refresh_board_status()
	game.mode = "board"

func run_checks() -> void:
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	root.size = Vector2i(1280, 720)
	game._start_local(false)
	game.mode = "board"
	await process_frame
	check(game.chess_rules.allow_warlord and game.board.size() == 32, "one Chess Duel board uses legal chess rules and keeps Warlord")
	var classic_button := false
	for button in game.menu_root.find_children("*", "Button", true, false):
		if button.text.contains("CLASSIC"): classic_button = true
	check(not classic_button and game.get_node_or_null("PromotionPicker") == null, "no separate Classic mode")
	check(Vector2i(4, 3) in game._moves(Vector2i(4, 1)) and not (Vector2i(4, 2) in game._moves(Vector2i(4, 0))), "opening pawn move legal and blocked king move excluded")
	game._process(1.0)
	var pawn_screen: Vector2 = game.cam.unproject_position(game.bv.to_global(game.bv.square_pos(Vector2i(4, 1))))
	var target_screen: Vector2 = game.cam.unproject_position(game.bv.to_global(game.bv.square_pos(Vector2i(4, 3))))
	game._click(pawn_screen)
	game._click(target_screen)
	await wait_for_move(game)
	check(game.board.has(Vector2i(4, 3)) and game.chess_rules.pieces.has(Vector2i(4, 3)) and not game.white_turn, "F5 click moves pawn and rule board together")
	set_position(game, "4r2k/8/8/8/8/8/4R3/4K3 w - - 0 1")
	check(not (Vector2i(3, 1) in game._moves(Vector2i(4, 1))), "pinned piece cannot uncover own king")
	set_position(game, "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	game._animate_move(Vector2i(4, 0), Vector2i(6, 0))
	await wait_for_move(game)
	check(game.board.has(Vector2i(6, 0)) and game.board.has(Vector2i(5, 0)) and not game.board.has(Vector2i(7, 0)), "castling moves king and rook together")
	set_position(game, "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	check(Vector2i(3, 5) in game._moves(Vector2i(4, 4)) and game._is_capture(Vector2i(4, 4), Vector2i(3, 5)), "en passant is legal capture for combat")
	game._start_duel(Vector2i(4, 4), Vector2i(3, 5))
	await create_timer(0.7).timeout
	check(game.mode == "duel" and game.pending.defender == Vector2i(3, 4), "en passant starts duel against bypassed pawn")
	var duel: Node
	for child in game.get_children():
		if child.has_signal("finished"):
			duel = child
			break
	if duel != null: duel.emit_signal("finished", true)
	await process_frame
	check(game.board.has(Vector2i(3, 5)) and not game.board.has(Vector2i(3, 4)) and not game.white_turn, "attacker duel win completes en passant capture")
	set_position(game, "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	game._start_duel(Vector2i(4, 4), Vector2i(3, 5))
	await create_timer(0.7).timeout
	duel = null
	for child in game.get_children():
		if child.has_signal("finished") and not child.is_queued_for_deletion():
			duel = child
			break
	if duel != null: duel.emit_signal("finished", false)
	await process_frame
	check(not game.board.has(Vector2i(4, 4)) and game.board.has(Vector2i(3, 4)) and not game.white_turn, "defender duel win removes attacker and changes turn")
	set_position(game, "4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	game._animate_move(Vector2i(0, 6), Vector2i(0, 7))
	for i in 30:
		if game.mode == "promotion": break
		await create_timer(0.05).timeout
	var picker: Variant = game.get_node_or_null("PromotionPicker")
	check(picker != null and picker.buttons.size() == 5 and picker.buttons.has("W"), "main game retains five promotion choices")
	if picker != null: picker._choose("W")
	await process_frame
	check(game.board.has(Vector2i(0, 7)) and game.board[Vector2i(0, 7)].t == "W" and game.chess_rules.pieces[Vector2i(0, 7)].t == "W", "Warlord promotion updates board and rules")
	game.chess_rules.reset()
	game.chess_rules.play_move(Vector2i(5, 1), Vector2i(5, 2))
	game.chess_rules.play_move(Vector2i(4, 6), Vector2i(4, 4))
	game.chess_rules.play_move(Vector2i(6, 1), Vector2i(6, 3))
	game._sync_rule_visual()
	game._refresh_board_status()
	game._apply_move(Vector2i(3, 7), Vector2i(7, 3))
	check(game.game_over and game.chess_rules.result_reason == "checkmate" and game.bv.get_node("KingWarning").get_child_count() == 2, "main game ends by checkmate with double warning")
	game._start_local(false)
	check(game.board.size() == 32 and not game.game_over, "new main match resets rule and visual boards")
	game._start_local(true)
	game.mode = "board"
	game._apply_move(Vector2i(4, 1), Vector2i(4, 3))
	game._end_turn()
	for i in 60:
		if game.white_turn and not game.piece_animating: break
		await create_timer(0.05).timeout
	check(game.white_turn and game.board.size() == game.chess_rules.pieces.size() and game.chess_rules.fullmove_number == 2, "local AI chooses a legal reply and keeps rule board aligned")
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("Chess main smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
