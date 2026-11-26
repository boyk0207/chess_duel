extends Node
## Persistent mixer, music crossfades, and event-based sound effects.

const KINDS := ["P", "N", "B", "R", "Q", "K", "W"]
const ATTACK := ["blade_01", "blade_02", "blade_03", "metal_01", "metal_02", "wood_01", "wood_02"]
const SPECIAL := ["spell_01", "spell_02", "spell_fire_01", "spell_fire_02", "spell_fire_03", "spell_fire_04", "spell_fire_05"]
const HIT := ["item_wood_01", "creature_hurt_01", "item_stone_01", "metal_03", "creature_hurt_02", "stones_01", "item_wood_02"]
const DISTINCT_SFX_KINDS := ["N", "B", "R", "Q", "K", "W"]
const STEP := ["footstep_grass_000", "footstep_concrete_001", "footstep_wood_002", "footstep_snow_003", "footstep_carpet_004", "footstep_grass_002", "footstep_concrete_003"]
const CONFIG := "user://audio_settings.cfg"
const BUSES := ["Master", "Music", "SFX", "UI", "Ambience"]
const DEFAULTS := {"Master": 1.0, "Music": 0.85, "SFX": 0.85, "UI": 0.85, "Ambience": 0.45}
const UI_CUES := ["ui_click", "board_select"]
const MUSIC_PATHS := {"menu": "res://assets/audio/generated/menu.ogg", "board": "res://assets/audio/generated/board.ogg", "battle": "res://assets/audio/generated/battle.ogg", "battle_intense": "res://assets/audio/generated/battle_intense.ogg", "island_battle": "res://assets/audio/generated/island_battle.ogg", "island_battle_intense": "res://assets/audio/generated/island_battle_intense.ogg"}
const INTENSE_FOR := {"battle": "battle_intense", "island_battle": "island_battle_intense"}
const EVENTS := {
	"block": ["impactMetal_medium_001", "impactMetal_medium_004", "impactPlate_medium_002"],
	"perfect_block": ["impactBell_heavy_000", "impactBell_heavy_003"],
	"counter": ["impactPunch_heavy_001", "impactMetal_heavy_002"],
	"heavy_hit": ["impactPunch_heavy_001", "impactSoft_heavy_004"],
	"body_hit": ["impactPunch_medium_000", "impactPunch_medium_004"],
	"projectile_impact": ["impactGeneric_light_000", "impactWood_medium_002"],
	"landing": ["impactSoft_medium_003"],
	"board_move": ["impactWood_medium_002", "impactPlank_medium_001"],
	"board_capture": ["impactWood_heavy_003"],
	"board_select": ["impactGeneric_light_000"],
	"ui_click": ["impactTin_medium_002"]
}
const GENERATED := ["swing", "heavy_swing", "dodge", "shard", "victory", "defeat", "cast_release", "magic_impact", "thunder"]
var music_players: Dictionary = {}
var current_music := ""
var battle_intensity := 0.0
var ambience_players: Array[AudioStreamPlayer3D] = []
var streams: Dictionary = {}
var one_shots: Array[Node] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "SFX", "UI", "Ambience"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	var config := ConfigFile.new()
	config.load(CONFIG)
	for bus_name in BUSES:
		set_volume(bus_name, float(config.get_value("volume", bus_name, DEFAULTS[bus_name])), false)
	for key in MUSIC_PATHS:
		var source := load(MUSIC_PATHS[key]) as AudioStream
		if source == null:
			push_error("Missing music: " + MUSIC_PATHS[key])
			continue
		var player := AudioStreamPlayer.new()
		player.name = "Music_" + key
		player.bus = "Music"
		player.stream = _loop_stream(source)
		player.volume_db = -80.0
		add_child(player)
		music_players[key] = player

func _loop_stream(source: AudioStream) -> AudioStream:
	if source is AudioStreamOggVorbis:
		var ogg := source as AudioStreamOggVorbis
		ogg.loop = true
		return ogg
	if source is AudioStreamWAV:
		var wav := source.duplicate() as AudioStreamWAV
		# PCM imports plus explicit full-file endpoints avoid zero-frame loops.
		wav.loop_begin = 0
		wav.loop_end = maxi(1, roundi(wav.get_length() * wav.mix_rate))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav
	return source

func set_volume(bus_name: String, linear: float, save := true) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0: return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	if save:
		var config := ConfigFile.new()
		config.load(CONFIG)
		config.set_value("volume", bus_name, linear)
		config.save(CONFIG)

func get_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0: return 1.0
	return 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))

func reset_volumes() -> void:
	for bus_name in BUSES: set_volume(bus_name, DEFAULTS[bus_name])

func _active(key: String) -> bool:
	return key == current_music or key == INTENSE_FOR.get(current_music, "")

func set_music(key: String) -> void:
	if not music_players.has(key):
		push_warning("Unknown music: " + key)
		return
	current_music = key
	for name in music_players:
		var player: AudioStreamPlayer = music_players[name]
		if _active(name) and not player.playing:
			player.volume_db = -12.0 if name == key else -42.0
			player.play()

func set_battle_intensity(value: float) -> void:
	battle_intensity = clampf(value, 0.0, 1.0)

func _process(delta: float) -> void:
	for key in music_players:
		var player: AudioStreamPlayer = music_players[key]
		var active := _active(key)
		if active and not player.playing and player.stream != null:
			player.play()
		var target := (-30.0 + battle_intensity * 17.0) if key in INTENSE_FOR.values() else (-8.0 if key in INTENSE_FOR else -5.0)
		player.volume_db = move_toward(player.volume_db, target if active else -80.0, delta * 65.0)
		if not active and player.playing and player.volume_db <= -79.0:
			player.stop()

func _stream(path: String) -> AudioStream:
	if not streams.has(path):
		if not ResourceLoader.exists(path):
			push_warning("Missing audio: " + path)
			return null
		streams[path] = load(path)
	return streams[path] as AudioStream

func _character_stream(cue: String, kind: String) -> AudioStream:
	var i := KINDS.find(kind)
	if i < 0: return null
	if cue == "attack":
		return _stream("res://assets/audio/generated/attack_%s.wav" % kind.to_lower())
	if cue in ["special", "hit", "special_impact"] and kind in DISTINCT_SFX_KINDS:
		return _stream("res://assets/audio/generated/%s_%s.wav" % [cue, kind.to_lower()])
	var stem := ""
	match cue:
		"attack": stem = ATTACK[i]
		"special": stem = SPECIAL[i]
		"hit": stem = HIT[i]
		"step": return _stream("res://assets/audio/kenney/%s.ogg" % STEP[i])
	if stem.is_empty(): return null
	return _stream("res://assets/audio/opengameart_rpg/%s.ogg" % stem)

func _cue_stream(cue: String, kind: String) -> AudioStream:
	if cue in ["swing", "heavy_swing"] and kind in KINDS:
		return _stream("res://assets/audio/generated/weapon_swing_%s.wav" % kind.to_lower())
	var stream := _character_stream(cue, kind)
	if stream != null: return stream
	if cue in GENERATED:
		return _stream("res://assets/audio/generated/%s.wav" % cue)
	if EVENTS.has(cue):
		var variants: Array = EVENTS[cue]
		return _stream("res://assets/audio/kenney/%s.ogg" % variants.pick_random())
	return _stream("res://assets/audio/kenney/%s.ogg" % cue)

func _gain(cue: String) -> float:
	match cue:
		"step", "ui_click", "board_select": return -15.0
		"swing", "heavy_swing", "landing": return -10.0
		"hit", "body_hit": return -7.0
		"block", "perfect_block", "counter", "heavy_hit": return -4.0
		"victory", "defeat": return -3.0
	return -7.0

func _track_voice(player: Node) -> void:
	one_shots = one_shots.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if one_shots.size() >= 32:
		one_shots.pop_front().queue_free()
	one_shots.append(player)

func play_spatial(cue: String, position: Vector3, parent: Node3D, kind := "") -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var stream := _cue_stream(cue, kind)
	if stream == null: return
	var player := AudioStreamPlayer3D.new()
	player.bus = "SFX"
	player.stream = stream
	player.volume_db = _gain(cue)
	player.pitch_scale = randf_range(0.94, 1.06) if cue not in ["victory", "defeat"] else 1.0
	player.max_distance = 55.0
	player.unit_size = 12.0
	player.panning_strength = 0.75
	player.position = parent.to_local(position)
	parent.add_child(player)
	_track_voice(player)
	player.finished.connect(player.queue_free)
	player.play()

func play_flat(cue: String, kind := "") -> void:
	var stream := _cue_stream(cue, kind)
	if stream == null: return
	var player := AudioStreamPlayer.new()
	player.bus = "UI" if cue in UI_CUES else "SFX"
	player.stream = stream
	player.volume_db = _gain(cue)
	player.pitch_scale = randf_range(0.96, 1.04) if cue not in ["victory", "defeat"] else 1.0
	add_child(player)
	_track_voice(player)
	player.finished.connect(player.queue_free)
	player.play()

func start_ambience(parent: Node3D, position: Vector3, cue: String, range_units := 40.0) -> void:
	if not is_instance_valid(parent) or not parent.is_inside_tree(): return
	var stream := _stream("res://assets/audio/generated/%s.wav" % cue)
	if stream == null: return
	ambience_players = ambience_players.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	for existing in ambience_players:
		if existing.get_parent() == parent and existing.get_meta("cue", "") == cue: return
	var player := AudioStreamPlayer3D.new()
	player.set_meta("cue", cue)
	player.bus = "Ambience"
	player.stream = _loop_stream(stream)
	player.volume_db = -14.0 if cue == "wind" else -12.0
	player.max_distance = range_units
	player.unit_size = 12.0
	player.position = parent.to_local(position)
	parent.add_child(player)
	ambience_players.append(player)
	player.play()

func stop_ambience(parent: Node3D) -> void:
	for player in ambience_players:
		if is_instance_valid(player) and player.get_parent() == parent:
			player.stop()
			player.queue_free()
	ambience_players = ambience_players.filter(func(p): return is_instance_valid(p) and p.get_parent() != parent)
