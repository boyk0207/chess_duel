extends SceneTree
## Build and play every ordered capture entrance using the existing rig clips.

const IntroScene = preload("res://scenes/capture_intro.tscn")
const IntroScript = preload("res://scripts/capture_intro.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var checked := 0
	for attacker_kind in IntroScript.KINDS:
		for defender_kind in IntroScript.KINDS:
			var scene: Variant = IntroScene.instantiate()
			root.add_child(scene)
			scene.configure(attacker_kind, true, defender_kind, false, Vector3(-1, 0, 0), Vector3(1, 0, 0), 1.0, Vector3.FORWARD, Color.SKY_BLUE)
			var plan: Dictionary = scene.plan
			var valid: bool = plan["pair"] == attacker_kind + defender_kind and scene.attacker_anim.has_animation(plan["strike"]) and scene.defender_anim.has_animation(plan["reaction"]) and scene.defender_anim.has_animation(plan["counter"]) and scene.attacker_anim.has_animation(plan["return_guard"])
			scene._process(float(plan["clash_at"]) + 0.01)
			valid = valid and scene.phase == "clash"
			scene._process(float(plan["hit_at"]) + 0.01 - scene.elapsed)
			valid = valid and scene.phase == "hit"
			scene._process(float(plan["counter_at"]) + 0.01 - scene.elapsed)
			valid = valid and scene.phase == "counter"
			scene._process(float(plan["return_at"]) + 0.01 - scene.elapsed)
			valid = valid and scene.phase == "return"
			scene._process(float(plan["walk_at"]) + 0.01 - scene.elapsed)
			valid = valid and scene.phase == "walk" and scene.attacker_anim.current_animation == "Walk" and scene.defender_anim.current_animation == "Walk"
			scene._process(float(plan["idle_at"]) + 0.01 - scene.elapsed)
			valid = valid and scene.phase == "arrival" and scene.attacker_anim.current_animation == "Idle"
			scene._process(2.01 - scene.elapsed)
			valid = valid and scene.phase == "done" and scene.attacker.position.is_equal_approx(scene.end_attacker) and scene.defender.position.is_equal_approx(scene.end_defender)
			if not valid:
				failures += 1
				push_error("Capture intro failed for %s vs %s" % [attacker_kind, defender_kind])
			checked += 1
			scene.free()
	print("Capture intro matrix: %d matchups, %d failure(s)" % [checked, failures])
	quit(0 if failures == 0 and checked == 49 else 1)
