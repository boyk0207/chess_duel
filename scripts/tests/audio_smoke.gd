extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func run_checks() -> void:
	var sound := root.get_node("Sound")
	check(AudioServer.get_bus_index("Music") >= 0, "Music bus")
	check(AudioServer.get_bus_index("SFX") >= 0, "SFX bus")
	check(AudioServer.get_bus_index("UI") >= 0, "UI bus")
	check(AudioServer.get_bus_index("Ambience") >= 0, "Ambience bus")
	for key in ["menu", "board", "battle", "battle_intense", "island_battle", "island_battle_intense"]:
		check(ResourceLoader.exists("res://assets/audio/generated/%s.ogg" % key), key + " OGG stream")
	for key in ["wind", "waterfall", "thunder"]:
		check(ResourceLoader.exists("res://assets/audio/generated/%s.wav" % key), key + " stream")
	for cue_list in [sound.ATTACK, sound.SPECIAL, sound.HIT, sound.STEP]:
		check(cue_list.size() == 7 and Dictionary_from_array(cue_list).size() == 7, "seven unique cues")
		for stem in cue_list:
			var folder := "kenney" if cue_list == sound.STEP else "opengameart_rpg"
			check(ResourceLoader.exists("res://assets/audio/%s/%s.ogg" % [folder, stem]), stem)
	sound.set_music("menu")
	check(sound.music_players["menu"].playing, "menu music starts")
	for key in sound.music_players:
		var ogg := sound.music_players[key].stream as AudioStreamOggVorbis
		check(ogg != null and ogg.loop and ogg.get_length() > 1.0, key + " OGG loop enabled")
	for cue in sound.GENERATED:
		check(ResourceLoader.exists("res://assets/audio/generated/%s.wav" % cue), cue + " generated cue")
	for cue in sound.EVENTS:
		for stem in sound.EVENTS[cue]:
			check(ResourceLoader.exists("res://assets/audio/kenney/%s.ogg" % stem), cue + " / " + stem)
	var weapon_ids := {}
	for kind in sound.KINDS:
		var weapon_stream: AudioStream = sound._cue_stream("swing", kind)
		check(weapon_stream is AudioStreamWAV and weapon_stream.get_length() < 1.0, kind + " unique weapon WAV")
		weapon_ids[weapon_stream.get_instance_id()] = true
	check(weapon_ids.size() == 7, "seven distinct weapon streams")
	var attack_ids := {}
	for kind in sound.KINDS:
		var attack_stream: AudioStream = sound._cue_stream("attack", kind)
		check(attack_stream is AudioStreamWAV and attack_stream.get_length() < 0.7, kind + " contact attack WAV")
		attack_ids[attack_stream.get_instance_id()] = true
	check(attack_ids.size() == 7, "seven distinct contact attack streams")
	check(sound._cue_stream("special", "P") is AudioStreamOggVorbis and sound._cue_stream("hit", "P") is AudioStreamOggVorbis, "Croc Soldier cues preserved")
	for cue in ["special", "hit", "special_impact"]:
		var unique_ids := {}
		for kind in sound.DISTINCT_SFX_KINDS:
			var path := "res://assets/audio/generated/%s_%s.wav" % [cue, kind.to_lower()]
			var character_stream: AudioStream = sound._cue_stream(cue, kind)
			check(ResourceLoader.exists(path) and character_stream is AudioStreamWAV and character_stream.get_length() >= 0.5 and character_stream.get_length() <= 1.1, "%s %s short WAV" % [kind, cue])
			unique_ids[character_stream.get_instance_id()] = true
		check(unique_ids.size() == 6, "six distinct " + cue + " streams")
	await create_timer(0.8).timeout
	check(sound.music_players["menu"].playing and sound.music_players["menu"].volume_db > -10.0, "menu stays active and fades in")
	sound.current_music = ""
	sound.music_players["menu"].stop()
	sound.set_music("menu")
	check(sound.music_players["menu"].playing, "menu restarts")
	sound.set_music("board")
	check(sound.music_players["board"].playing, "board music starts")
	var emitter := Node3D.new()
	root.add_child(emitter)
	sound.play_spatial("attack", Vector3.ZERO, emitter, "P")
	check(emitter.get_child_count() == 1, "3D emitter")
	sound.play_spatial("special", Vector3.ZERO, emitter, "N")
	check((emitter.get_child(1) as AudioStreamPlayer3D).stream == sound._cue_stream("special", "N"), "3D Monitor Knight special uses distinct WAV")
	sound.play_spatial("hit", Vector3.ZERO, emitter, "Q")
	check((emitter.get_child(2) as AudioStreamPlayer3D).stream == sound._cue_stream("hit", "Q"), "3D Snake God hit uses distinct WAV")
	sound.play_flat("special", "B")
	check((sound.one_shots[-1] as AudioStreamPlayer).stream == sound._cue_stream("special", "B"), "flat Snake Wizard special uses distinct WAV")
	sound.play_spatial("special_impact", Vector3.ZERO, emitter, "R")
	check((sound.one_shots[-1] as AudioStreamPlayer3D).stream == sound._cue_stream("special_impact", "R"), "3D Lizard Bomber explosion uses distinct WAV")
	sound.play_flat("ui_click")
	check((sound.one_shots[-1] as AudioStreamPlayer).bus == "UI", "menu click uses UI bus")
	sound.play_flat("board_select")
	check((sound.one_shots[-1] as AudioStreamPlayer).bus == "UI", "board select uses UI bus")
	sound.play_flat("board_move")
	check((sound.one_shots[-1] as AudioStreamPlayer).bus == "SFX", "board move stays on SFX bus")
	var sfx_volume: float = sound.get_volume("SFX")
	var ui_volume: float = sound.get_volume("UI")
	sound.set_volume("UI", 0.25, false)
	check(is_equal_approx(sound.get_volume("UI"), 0.25) and is_equal_approx(sound.get_volume("SFX"), sfx_volume), "UI volume is independent")
	sound.set_volume("UI", ui_volume, false)
	sound.set_battle_intensity(1.0)
	check(sound.battle_intensity == 1.0 and sound.music_players.size() == 6, "dynamic battle layers")
	var battle: AudioStreamPlayer = sound.music_players["battle"]
	var intense: AudioStreamPlayer = sound.music_players["battle_intense"]
	check(is_equal_approx(battle.stream.get_length(), intense.stream.get_length()), "battle layers stay equal length")
	sound.set_music("island_battle")
	var island: AudioStreamPlayer = sound.music_players["island_battle"]
	var island_intense: AudioStreamPlayer = sound.music_players["island_battle_intense"]
	check(island.playing and island_intense.playing, "Floating Island layers start")
	check(is_equal_approx(island.stream.get_length(), island_intense.stream.get_length()), "Floating Island layers stay equal length")
	sound.set_battle_intensity(0.0)
	await create_timer(0.3).timeout
	var low_intensity_db: float = island_intense.volume_db
	sound.set_battle_intensity(1.0)
	await create_timer(0.3).timeout
	check(island_intense.volume_db > low_intensity_db + 5.0, "Floating Island intensity layer rises")
	island.play(island.stream.get_length() - 0.15)
	island_intense.play(island_intense.stream.get_length() - 0.15)
	await create_timer(0.45).timeout
	check(island.playing and island_intense.playing and island.get_playback_position() < 1.0 and island_intense.get_playback_position() < 1.0, "Floating Island layers loop across end")
	sound.set_music("battle")
	check(battle.playing and intense.playing, "other stages retain battle layers")
	sound.set_music("menu")
	var menu_player: AudioStreamPlayer = sound.music_players["menu"]
	menu_player.play(menu_player.stream.get_length() - 0.15)
	await create_timer(0.45).timeout
	check(menu_player.playing and menu_player.get_playback_position() < 1.0, "menu OGG loops across end")
	emitter.queue_free()
	sound.current_music = ""
	for player in sound.music_players.values():
		player.stop()
		player.stream = null
	await process_frame
	await create_timer(0.1).timeout
	print("Audio smoke checks: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)

func Dictionary_from_array(values: Array) -> Dictionary:
	var unique := {}
	for value in values: unique[value] = true
	return unique
