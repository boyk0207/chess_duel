extends SceneTree
## Run in separate Godot processes with: --script res://scripts/tests/lan_two_process_smoke.gd -- host|guest

const CODE_FILE := "res://.audit_runtime/lan_two_process_code.txt"

var role := ""
var failures := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0] if not args.is_empty() else ""
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS %s: %s" % [role, label])
	else:
		failures += 1
		push_error("FAIL %s: %s" % [role, label])

func wait_for(test: Callable, attempts: int = 160) -> bool:
	for i in attempts:
		if test.call(): return true
		await create_timer(0.05).timeout
	return false

func run_checks() -> void:
	if role != "host" and role != "guest":
		push_error("Pass -- host or -- guest")
		quit(1)
		return
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var net := root.get_node("ChessNetwork")
	if role == "host":
		net.create_room(2)
		check(await wait_for(func(): return not net.room_code.is_empty()), "created embedded Host")
		var file := FileAccess.open(CODE_FILE, FileAccess.WRITE)
		check(file != null, "published room code to test file")
		if file != null:
			file.store_string(net.room_code)
			file.close()
		check(await wait_for(func(): return net.state.get("players", []).size() == 2), "Join connected from second process")
		net.set_ready(true)
		check(await wait_for(func():
			var players: Array = net.state.get("players", [])
			return players.size() == 2 and players[0]["ready"] and players[1]["ready"]), "both Ready")
		net.start_match()
	else:
		check(await wait_for(func(): return FileAccess.file_exists(CODE_FILE)), "found Host room code")
		var code := FileAccess.get_file_as_string(CODE_FILE).strip_edges()
		net.join_room(code, "127.0.0.1")
		check(await wait_for(func(): return net.player_id == 2), "joined Host process")
		net.set_ready(true)
	check(await wait_for(func(): return game.mode == "board" and game.online_match), "opened LAN board")
	check(game.stage_idx == 2, "uses Host map")
	if role == "host":
		net.request_move(Vector2i(0, 1), Vector2i(0, 2))
	else:
		check(await wait_for(func(): return game.board.has(Vector2i(0, 2)) and not game.white_turn), "received Host move")
		net.request_move(Vector2i(0, 6), Vector2i(0, 5))
	check(await wait_for(func(): return game.board.has(Vector2i(0, 2)) and game.board.has(Vector2i(0, 5)) and game.white_turn), "both moves on local board")
	await create_timer(0.3).timeout
	net.leave_room()
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("LAN two-process %s: %d failure(s)" % [role, failures])
	quit(0 if failures == 0 else 1)
