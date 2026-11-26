extends SceneTree
## Exercises the LAN protocol through a real main scene and its board state.

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
	var host := root.get_node("ChessNetwork")
	host.create_room(1)
	for i in 40:
		if not host.room_code.is_empty(): break
		await create_timer(0.05).timeout
	var guest = load("res://scripts/network/multiplayer.gd").new()
	root.add_child(guest)
	guest.join_room(host.room_code, "127.0.0.1")
	for i in 40:
		if guest.player_id == 2: break
		await create_timer(0.05).timeout
	host.set_ready(true)
	guest.set_ready(true)
	for i in 40:
		var players: Array = host.state.get("players", [])
		if players.size() == 2 and players[0]["ready"] and players[1]["ready"]: break
		await create_timer(0.05).timeout
	host.start_match()
	for i in 160:
		if game.mode == "board": break
		await create_timer(0.05).timeout
	check(game.mode == "board" and game.online_match, "main scene starts LAN chess board")
	check(game.stage_idx == 1 and guest.match_stage == 1, "Host map selection reaches Join client")
	host.request_move(Vector2i(0, 1), Vector2i(0, 2))
	for i in 80:
		if game.board.has(Vector2i(0, 2)) and not game.white_turn: break
		await create_timer(0.05).timeout
	check(game.board.has(Vector2i(0, 2)) and not game.board.has(Vector2i(0, 1)) and not game.white_turn, "Host pawn move updates real board")
	guest.request_move(Vector2i(0, 6), Vector2i(0, 5))
	for i in 80:
		if game.board.has(Vector2i(0, 5)) and game.white_turn: break
		await create_timer(0.05).timeout
	check(game.board.has(Vector2i(0, 5)) and not game.board.has(Vector2i(0, 6)) and game.white_turn, "Join pawn move updates Host board")
	guest.leave_room()
	guest.queue_free()
	host.leave_room()
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("LAN board smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
