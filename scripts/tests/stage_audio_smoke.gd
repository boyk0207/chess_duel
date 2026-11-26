extends SceneTree
## Checks the board-to-duel music choice for Floating Island and another stage.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var sound := root.get_node("Sound")
	var failures := 0
	for stage_index in [0, 1]:
		var packed := load("res://scenes/main.tscn") as PackedScene
		var game := packed.instantiate()
		root.add_child(game)
		current_scene = game
		game.set("stage_idx", stage_index)
		game.chess_rules.set_fen("4k3/8/8/8/8/1p6/P7/4K3 w - - 0 1")
		game._sync_rule_visual()
		game._refresh_board_status()
		game.mode = "board"
		game.call("_start_duel", Vector2i(0, 1), Vector2i(1, 2))
		for i in 30:
			if game.get("mode") == "duel": break
			await create_timer(0.05).timeout
		var expected := "island_battle" if stage_index == 0 else "battle"
		var player: AudioStreamPlayer = sound.music_players[expected]
		var ok: bool = sound.current_music == expected and player.playing
		print("Stage %d duel music: %s (%s)" % [stage_index, "PASS" if ok else "FAIL", expected])
		if not ok:
			failures += 1
		var duel: Node
		for child in game.get_children():
			if child.has_signal("finished"):
				duel = child
				break
		if duel == null:
			failures += 1
			push_error("Stage %d duel did not start after capture cinematic" % stage_index)
			game.queue_free()
			await process_frame
			current_scene = null
			continue
		if stage_index == 0:
			duel.call("attack", 0, Vector3.FORWARD, false)
		else:
			var fighters: Array = duel.get("fighters")
			duel.call("_melee", fighters[0], fighters[1])
		var weapon_audio: AudioStreamPlayer3D = sound.one_shots[-1] as AudioStreamPlayer3D
		var swing_ok: bool = weapon_audio != null and weapon_audio.stream == sound._cue_stream("swing", "P")
		print("Stage %d pawn weapon swing: %s" % [stage_index, "PASS" if swing_ok else "FAIL"])
		if not swing_ok:
			failures += 1
		if stage_index == 0:
			duel.call("damage", 0, 7.0)
		else:
			var contact_fighters: Array = duel.get("fighters")
			duel.call("_damage", contact_fighters[1], 7.0, 0.0, true, 0.1, "P")
		var contact_audio: AudioStreamPlayer3D = sound.one_shots[-2] as AudioStreamPlayer3D
		var contact_ok: bool = contact_audio != null and contact_audio.stream == sound._cue_stream("attack", "P")
		print("Stage %d pawn contact attack: %s" % [stage_index, "PASS" if contact_ok else "FAIL"])
		if not contact_ok:
			failures += 1
		if stage_index == 1:
			var fighters_for_bomb: Array = duel.get("fighters")
			var bomb = duel.call("_spawn_proj", fighters_for_bomb[0], "bomb", 6.5, 9.0, 1.2)
			bomb.src.kind = "R"
			bomb.s = fighters_for_bomb[1].s
			bomb.y = fighters_for_bomb[1].y
			bomb.dmg = 12.0
			var prior_count: int = sound.one_shots.size()
			duel.call("_explode", bomb, fighters_for_bomb[1])
			var explosion_ok := false
			for voice in sound.one_shots.slice(prior_count):
				if voice is AudioStreamPlayer3D and voice.stream == sound._cue_stream("special_impact", "R"):
					explosion_ok = true
			print("Stage 1 bomber explosion: %s" % ["PASS" if explosion_ok else "FAIL"])
			if not explosion_ok:
				failures += 1
		game.queue_free()
		await process_frame
		current_scene = null
		game = null
		packed = null
	for music_player in sound.music_players.values():
		music_player.stop()
		music_player.stream = null
	await create_timer(0.5).timeout
	quit(0 if failures == 0 else 1)
