extends SceneTree
## Runs embedded Host and second LAN client in one Godot process.

var failures := 0
var starts := 0
var host_commits := 0
var guest_commits := 0
var move_errors := 0
var wrong_code_errors := 0
var disconnect_notices := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	var host := root.get_node("ChessNetwork")
	host.match_started.connect(func(_room: String): starts += 1)
	host.error_received.connect(func(_message: String): disconnect_notices += 1)
	host.create_room()
	for i in 40:
		if not host.room_code.is_empty(): break
		await create_timer(0.05).timeout
	check(is_instance_valid(host.lan_host) and host.lan_host.listener.is_listening(), "game process starts embedded LAN Host")
	check(host.player_id == 1 and host.room_code.length() == 6, "Host receives room code")
	var room: String = host.room_code
	var imposter = load("res://scripts/network/multiplayer.gd").new()
	root.add_child(imposter)
	imposter.error_received.connect(func(_message: String): wrong_code_errors += 1)
	imposter.join_room("AAAAAA" if room != "AAAAAA" else "BBBBBB", "127.0.0.1")
	for i in 40:
		if wrong_code_errors > 0: break
		await create_timer(0.05).timeout
	check(wrong_code_errors == 1 and imposter.player_id == 0, "incorrect room code is rejected")
	imposter.leave_room()
	imposter.queue_free()
	var guest = load("res://scripts/network/multiplayer.gd").new()
	root.add_child(guest)
	guest.match_started.connect(func(_room: String): starts += 1)
	guest.error_received.connect(func(_message: String): move_errors += 1)
	host.move_requested.connect(func(_player: int, _from: Vector2i, _to: Vector2i): host.accept_move())
	host.move_committed.connect(func(_seq: int, _player: int, _from: Vector2i, _to: Vector2i): host_commits += 1)
	guest.move_committed.connect(func(_seq: int, _player: int, _from: Vector2i, _to: Vector2i): guest_commits += 1)
	guest.join_room(room, "127.0.0.1")
	for i in 40:
		if guest.player_id == 2: break
		await create_timer(0.05).timeout
	check(guest.player_id == 2 and guest.room_code == room, "second game client joins without external server")
	check(host.state.get("players", []).size() == 2, "both clients see two players")
	host.set_ready(true)
	guest.set_ready(true)
	for i in 40:
		var players: Array = host.state.get("players", [])
		if players.size() == 2 and players[0]["ready"] and players[1]["ready"]: break
		await create_timer(0.05).timeout
	var ready_players: Array = host.state.get("players", [])
	check(ready_players.size() == 2 and ready_players[0]["ready"] and ready_players[1]["ready"], "ready state reaches Host")
	host.start_match()
	for i in 40:
		if starts == 2: break
		await create_timer(0.05).timeout
	check(starts == 2, "start reaches Host and Join client")
	guest.request_move(Vector2i(0, 6), Vector2i(0, 5))
	for i in 40:
		if move_errors > 0: break
		await create_timer(0.05).timeout
	check(move_errors == 1, "wrong-turn move is rejected")
	host.request_move(Vector2i(0, 1), Vector2i(0, 2))
	for i in 40:
		if host_commits == 1 and guest_commits == 1: break
		await create_timer(0.05).timeout
	check(host_commits == 1 and guest_commits == 1, "first chess move reaches both games")
	guest.request_move(Vector2i(0, 6), Vector2i(0, 5))
	for i in 40:
		if host_commits == 2 and guest_commits == 2: break
		await create_timer(0.05).timeout
	check(host_commits == 2 and guest_commits == 2, "second chess move reaches both games")
	guest.leave_room()
	guest.queue_free()
	for i in 40:
		if disconnect_notices > 0: break
		await create_timer(0.05).timeout
	check(disconnect_notices == 1, "Host sees Join disconnect notice")
	host.leave_room()
	await create_timer(0.1).timeout
	check(not is_instance_valid(host.lan_host), "embedded Host stops on leave")
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("LAN lobby smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
