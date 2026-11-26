extends SceneTree
## Run host and guest in separate Godot processes: --script ... -- host|guest 0..4

var role := ""
var stage := 0
var failures := 0
var code_file := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	role = args[0] if args.size() > 0 else ""
	stage = int(args[1]) if args.size() > 1 else 0
	code_file = "res://.audit_runtime/lan_pvp_code_%d.txt" % stage
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS %s %d: %s" % [role, stage, label])
	else:
		failures += 1
		push_error("FAIL %s %d: %s" % [role, stage, label])

func wait_for(test: Callable, attempts: int = 200) -> bool:
	for i in attempts:
		if test.call(): return true
		await create_timer(0.05).timeout
	return false

func run_checks() -> void:
	if role not in ["host", "guest"] or stage < 0 or stage > 4:
		push_error("Pass -- host|guest 0..4")
		quit(1)
		return
	var game: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var net := root.get_node("ChessNetwork")
	if role == "host":
		net.create_room(stage)
		check(await wait_for(func(): return not net.room_code.is_empty()), "Host created room")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.audit_runtime"))
		var file := FileAccess.open(code_file, FileAccess.WRITE)
		check(file != null, "room code file created")
		if file != null:
			file.store_string(net.room_code)
			file.close()
		check(await wait_for(func(): return net.state.get("players", []).size() == 2, 360), "Join connected")
		net.set_ready(true)
		check(await wait_for(func():
			var players: Array = net.state.get("players", [])
			return players.size() == 2 and players[0]["ready"] and players[1]["ready"]), "both Ready")
		net.start_match()
	else:
		check(await wait_for(func(): return FileAccess.file_exists(code_file)), "Host code appeared")
		var code := FileAccess.get_file_as_string(code_file).strip_edges()
		net.join_room(code, "127.0.0.1")
		check(await wait_for(func(): return net.player_id == 2), "joined Host")
		net.set_ready(true)
	check(await wait_for(func(): return game.mode == "board" and game.online_match), "LAN board started")
	check(game.stage_idx == stage, "same stage on both processes")
	game.chess_rules.set_fen("4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "host":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(4, 3), Vector2i(3, 4))
	check(await wait_for(func(): return game.mode == "duel" and is_instance_valid(game.active_lan_duel)), "capture starts PvP duel")
	check((game.active_lan_duel.get_script().resource_path == "res://scripts/duel_3d.gd") == (stage == 0), "stage selects its existing duel implementation")
	if stage == 0:
		if role == "host":
			var arena: Variant = game.active_lan_duel
			arena.boost_timer = 9.0
			arena.crystal_kind = 0
			arena.crystal.position = arena.bodies[1].position + Vector3.UP * 0.6
			arena.crystal.show()
			arena.update_crystals(0.016)
			check(arena.boost[1] > 0.0 and arena.shard_icons[1].visible, "Host awards Power Shard to Black fighter")
		else:
			check(await wait_for(func(): return game.active_lan_duel.shard_icons[1].visible and not game.active_lan_duel.shard_icons[0].visible and game.active_lan_duel.shard_icons[1].get_parent() == game.active_lan_duel.bodies[1]), "Join sees Power Shard icon above Black fighter")
	if role == "guest":
		if stage == 0: game.active_lan_duel.set_physics_process(false)
		else: game.active_lan_duel.set_process(false)
		for i in 20:
			net.send_duel_input({"f": true, "y": PI} if stage == 0 else {"dir": -1})
			await create_timer(0.025).timeout
			if stage == 0: game.active_lan_duel._lan_reconcile(0.025)
		check(await wait_for(func():
			if stage == 0: game.active_lan_duel._lan_reconcile(0.05)
			return game.active_lan_duel.bodies[1].position.z > -6.5 if stage == 0 else game.active_lan_duel.fighters[1].s < 2.7, 20), "Join sees Host-simulated fighter movement")
		if stage == 0:
			check(await wait_for(func():
				for child in game.active_lan_duel.polish.get_children():
					if child is Label3D and child.text == "LAN FX": return true
				return false, 30), "Join sees Host combat FX popup over socket")
		else:
			check(await wait_for(func(): return game.active_lan_duel.lan_fx_seen > 0, 30), "Join receives 2.5D explosion event over socket")
		if stage == 0: game.active_lan_duel.set_physics_process(true)
		else: game.active_lan_duel.set_process(true)
		if stage == 0:
			check(await wait_for(func(): return game.active_lan_duel.bodies[1].position.z > 4.0), "Join sees fighters meet")
			net.send_duel_input({"a": true, "aim": [0.0, 0.0, 1.0], "y": PI})
			check(await wait_for(func(): return game.active_lan_duel.hp[0] < float(game.active_lan_duel.stats[0]["hp"]), 40), "Join attack lowers authoritative White HP")
			await create_timer(0.45).timeout
			net.send_duel_input({"s": true, "aim": [0.0, 0.0, 1.0], "y": PI})
			check(await wait_for(func(): return game.active_lan_duel.special[1] > 0.0, 40), "Join special reaches Host and cooldown replica")
		else:
			check(await wait_for(func(): return game.active_lan_duel.fighters[1].s < 0.0), "Join sees 2.5D fighters meet")
			net.send_duel_input({"attack": true})
			check(await wait_for(func(): return game.active_lan_duel.fighters[0].hp < game.active_lan_duel.fighters[0].max_hp, 40), "Join 2.5D attack lowers authoritative White HP")
			await create_timer(0.35).timeout
			net.send_duel_input({"special": true})
			check(await wait_for(func(): return game.active_lan_duel.fighters[1].sp_cd > 0.0, 40), "Join 2.5D special cooldown reaches replica")
	else:
		check(await wait_for(func(): return game.active_lan_duel.bodies[1].position.z > -6.5 if stage == 0 else game.active_lan_duel.fighters[1].s < 2.7), "Join input moves Host fighter")
		if stage == 0: game.active_lan_duel.fx_popup(game.active_lan_duel.bodies[1].position + Vector3.UP * 2.0, 0.0, Color.GOLD, "LAN FX")
		else: game.active_lan_duel._lan_fx("bomb", [1.5, 0.3, "R"])
		if stage == 0:
			await create_timer(0.5).timeout # Drain the movement packets before the fixed melee fixture.
			game.active_lan_duel.lan_remote_input = {}
			game.active_lan_duel.lan_remote_age = 1.0
			game.active_lan_duel.bodies[1].position = game.active_lan_duel.bodies[0].position + Vector3(0, 0, -1.2)
			check(await wait_for(func(): return game.active_lan_duel.hp[0] < float(game.active_lan_duel.stats[0]["hp"]), 40), "Join attack reaches Host simulation")
			check(await wait_for(func(): return game.active_lan_duel.special[1] > 0.0, 40), "Join special starts in Host simulation")
		else:
			game.active_lan_duel.fighters[1].s = game.active_lan_duel.fighters[0].s + 1.2
			check(await wait_for(func(): return game.active_lan_duel.fighters[0].hp < game.active_lan_duel.fighters[0].max_hp, 40), "Join 2.5D attack reaches Host simulation")
			check(await wait_for(func(): return game.active_lan_duel.fighters[1].sp_cd > 0.0, 40), "Join 2.5D special starts in Host simulation")
		if stage == 0:
			game.active_lan_duel.hp[1] = 0.0
		else:
			game.active_lan_duel._ko(game.active_lan_duel.fighters[1])
	check(await wait_for(func(): return game.mode == "board" and game.board.has(Vector2i(3, 4)) and not game.board.has(Vector2i(4, 3)) and not game.white_turn, 240), "same attacker victory updates board")
	check(game.chess_rules.pieces.has(Vector2i(3, 4)) and not game.chess_rules.pieces.has(Vector2i(4, 3)), "rule board also agrees")
	game.chess_rules.set_fen("4k3/8/8/8/8/8/p7/4K3 b - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "guest":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(0, 1), Vector2i(0, 0))
	check(await wait_for(func(): return game.mode == "promotion"), "LAN pawn promotion waits for owning player")
	if role == "guest": net.choose_promotion("W")
	check(await wait_for(func(): return game.mode == "board" and game.board.has(Vector2i(0, 0)) and game.board[Vector2i(0, 0)].t == "W" and game.white_turn), "same Warlord promotion updates both boards")
	game.chess_rules.set_fen("4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "host":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(4, 3), Vector2i(3, 4))
	check(await wait_for(func(): return game.mode == "duel" and is_instance_valid(game.active_lan_duel)), "second capture opens duel")
	if role == "guest": net.send_duel_input({"g": true} if stage == 0 else {"block": true})
	else:
		if stage == 0: game.active_lan_duel.hp[0] = 0.0
		else: game.active_lan_duel._ko(game.active_lan_duel.fighters[0])
	check(await wait_for(func(): return game.mode == "board" and not game.board.has(Vector2i(4, 3)) and game.board.has(Vector2i(3, 4)) and not game.white_turn, 240), "same defender victory removes attacker")
	game.chess_rules.set_fen("4k3/8/8/8/8/8/p7/1R2K3 b - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "guest":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(0, 1), Vector2i(1, 0))
	check(await wait_for(func(): return game.mode == "duel" and is_instance_valid(game.active_lan_duel)), "promotion capture starts duel")
	if role == "guest": net.send_duel_input({"g": true} if stage == 0 else {"block": true})
	else:
		if stage == 0: game.active_lan_duel.hp[0] = 0.0
		else: game.active_lan_duel._ko(game.active_lan_duel.fighters[0])
	check(await wait_for(func(): return game.mode == "promotion", 240), "winning promotion capture waits for choice")
	if role == "guest": net.choose_promotion("W")
	check(await wait_for(func(): return game.mode == "board" and game.board.has(Vector2i(1, 0)) and game.board[Vector2i(1, 0)].t == "W" and game.white_turn), "promotion capture agrees on both boards")
	game.chess_rules.set_fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "host":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(4, 4), Vector2i(3, 5))
	check(await wait_for(func(): return game.mode == "duel" and is_instance_valid(game.active_lan_duel)), "LAN en passant capture starts duel")
	if role == "guest": net.send_duel_input({"g": true} if stage == 0 else {"block": true})
	else:
		if stage == 0: game.active_lan_duel.hp[1] = 0.0
		else: game.active_lan_duel._ko(game.active_lan_duel.fighters[1])
	check(await wait_for(func(): return game.mode == "board" and game.board.has(Vector2i(3, 5)) and not game.board.has(Vector2i(3, 4)) and not game.board.has(Vector2i(4, 4)) and not game.white_turn, 240), "en passant result agrees on both boards")
	game.chess_rules.set_fen("4k3/8/8/3p4/4P3/8/8/4K3 b - - 0 1")
	game._sync_rule_visual()
	game._refresh_board_status()
	if role == "guest":
		await create_timer(0.25).timeout
		net.request_move(Vector2i(3, 4), Vector2i(4, 3))
	check(await wait_for(func(): return game.mode == "duel" and is_instance_valid(game.active_lan_duel)), "disconnect test reaches active duel")
	if role == ("guest" if stage % 2 == 0 else "host"):
		await create_timer(0.25).timeout
		net.leave_room()
	else:
		check(await wait_for(func(): return game.mode == "menu" and not game.online_match and game.online_lobby.visible, 100), "peer returns to lobby after disconnect during duel")
		net.leave_room()
	game.queue_free()
	var sound := root.get_node("Sound")
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await create_timer(0.2).timeout
	print("LAN PvP two-process %s stage %d: %d failure(s)" % [role, stage, failures])
	quit(0 if failures == 0 else 1)
