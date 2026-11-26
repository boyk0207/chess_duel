extends SceneTree
## Checks actual F5 scene startup rather than calling Sound.set_music directly.
func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var main := load("res://scenes/main.tscn") as PackedScene
	var game := main.instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(1.0).timeout
	var sound := root.get_node("Sound")
	var player: AudioStreamPlayer = sound.music_players["menu"]
	var ogg := player.stream as AudioStreamOggVorbis
	var ok: bool = sound.current_music == "menu" and player.playing and player.volume_db > -10.0 and ogg != null and ogg.loop and ogg.get_length() > 230.0 and game.audio_sliders.has("UI")
	print("Main menu audio: ", "PASS" if ok else "FAIL", " | playback position: ", player.get_playback_position(), " | volume dB: ", player.volume_db)
	print("Bus levels: Master=", sound.get_volume("Master"), " Music=", sound.get_volume("Music"))
	if sound.get_volume("Master") <= 0.0 or sound.get_volume("Music") <= 0.0:
		print("NOTE: saved mixer settings are muted. Use RESET AUDIO in the game.")
	game.queue_free()
	await process_frame
	current_scene = null
	for music_player in sound.music_players.values():
		music_player.stop()
		music_player.stream = null
	ogg = null
	player = null
	game = null
	main = null
	await create_timer(0.5).timeout
	quit(0 if ok else 1)
