extends SceneTree
# Run AFTER importing assets in Godot 4.x. See docs/COMBAT_POLISH.txt.
const Data = preload("res://scripts/data.gd")
const Rig = preload("res://scripts/rig_factory.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")
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
	var duel_script = load("res://scripts/duel_3d.gd")
	if root.get_node_or_null("Sound") == null:
		var sound := AudioManager.new()
		sound.name = "Sound"
		root.add_child(sound)
	for kind in ["P","N","B","R","Q","K","W"]:
		var model := Rig.build(kind, 2.0)
		root.add_child(model)
		var anim := Rig.player(model)
		check(anim != null, kind + " AnimationPlayer")
		if anim != null:
			for clip in Rig.CLIPS:
				check(anim.has_animation(clip), kind + " " + clip)
		model.queue_free()
	await process_frame
	var duel = duel_script.new()
	root.add_child(duel)
	duel.setup("P", "K", true, Data.STAGES[0])
	duel.set_physics_process(false)
	duel.set_process_input(false)
	var before: float = duel.hp[0]
	duel.guarding[0] = true
	duel.guard_age = 0.06
	duel.damage(1, 14.0)
	check(is_equal_approx(duel.hp[0], before), "perfect block negates damage")
	check(duel.counter_time[0] > 0.0, "counter is armed")
	check(duel.hitstop_remaining > 0.0, "local hitstop armed")
	check(is_equal_approx(Engine.time_scale,1.0), "global time scale unchanged")
	duel.guarding[0] = false
	before = duel.hp[1]
	duel.damage(0, 7.0)
	check(is_equal_approx(before-duel.hp[1],8.75), "counter +25 percent")
	check(duel.counter_time[0] == 0.0, "counter spent once")
	duel.dodge_time = 0.1
	before = duel.hp[0]
	duel.damage(1,14.0)
	check(is_equal_approx(before,duel.hp[0]), "dodge immunity")
	duel.dodge_time = 0.0
	duel.combo_step[0] = 1
	duel.combo_connected[0] = true
	duel.combo_window[0] = 0.3
	check(duel.attack(0,Vector3.FORWARD,false), "queue second attack")
	check(duel.combo_active[0] == 2, "second combo clip selected")
	check(not duel.attack(0,Vector3.FORWARD,true), "no overlapping windup")
	duel.queue_free()
	await process_frame
	var bomber_duel = duel_script.new()
	root.add_child(bomber_duel)
	bomber_duel.setup("R", "K", true, Data.STAGES[0])
	bomber_duel.set_physics_process(false)
	var sound: Node = root.get_node("Sound")
	bomber_duel.damage(0, 24.0, true)
	check((sound.one_shots[-2] as AudioStreamPlayer3D).stream == sound._cue_stream("special_impact", "R"), "Bomber special contact uses explosion")
	bomber_duel.queue_free()
	await process_frame
	print("Combat smoke checks: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
