extends SceneTree
## Starts the F6 sound scene, then releases audio before headless shutdown.

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var packed := load("res://scenes/tests/sound_test.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.5).timeout
	var sound := root.get_node("Sound")
	var player: AudioStreamPlayer = sound.music_players["menu"]
	var ok: bool = sound.current_music == "menu" and player.playing and player.stream is AudioStreamOggVorbis
	print("Sound scene startup: ", "PASS" if ok else "FAIL")
	scene.queue_free()
	await process_frame
	current_scene = null
	for music_player in sound.music_players.values():
		music_player.stop()
		music_player.stream = null
	player = null
	scene = null
	packed = null
	await create_timer(0.5).timeout
	quit(0 if ok else 1)
