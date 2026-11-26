extends SceneTree
## Checks Host authority and Join replication without opening a socket.

const Data = preload("res://scripts/data.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(ok: bool, label: String) -> void:
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run_checks() -> void:
	var Duel3D = load("res://scripts/duel_3d.gd")
	var Duel = load("res://scripts/duel.gd")
	var host3d: Variant = Duel3D.new()
	host3d.lan_role = 1
	root.add_child(host3d)
	host3d.setup("P", "R", false, Data.STAGES[0])
	host3d.set_physics_process(false)
	var guest3d: Variant = Duel3D.new()
	guest3d.lan_role = 2
	root.add_child(guest3d)
	guest3d.setup("P", "R", false, Data.STAGES[0])
	guest3d.set_physics_process(false)
	host3d.lan_receive_input({"f": true, "y": PI, "a": true})
	check(host3d.lan_remote_input.get("f", false) and host3d.lan_attack_queued, "3D Host receives Join fighter input")
	host3d.hp[1] -= 19.0
	host3d.bodies[1].position = Vector3(2, 1, -4)
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(is_equal_approx(guest3d.hp[1], host3d.hp[1]) and guest3d.bodies[1].position.is_equal_approx(host3d.bodies[1].position), "3D Join receives authoritative HP and position")
	var before_local: Vector3 = guest3d.bodies[1].position
	guest3d._lan_predict_local(1.0 / 30.0, Vector3.FORWARD, false, false, false)
	check(guest3d.bodies[1].position.z < before_local.z, "3D Join predicts own movement before next Host snapshot")
	check(JSON.stringify({"type": "duel_state", "state": host3d._lan_snapshot()}).to_utf8_buffer().size() < 4096, "3D snapshot fits LAN packet limit")
	check(is_equal_approx(guest3d.yaw, PI), "Join camera faces toward White fighter")
	host3d.ferry_x = 3.5
	host3d.crystal.show()
	host3d.crystal.position = Vector3(1, 0.8, 2)
	host3d.crystal_kind = 3
	host3d.lightning_warning = host3d.ring_at(host3d, Vector3(2, 0.07, 1), 1.8, Color.ORANGE)
	host3d.heal_ready_at = host3d.elapsed + 5.0
	var before_cracks: int = guest3d.collapses[0]["part"].get_child_count()
	host3d.collapses[0]["state"] = 1
	host3d.collapses[0]["part"].rotation.x = 0.2
	host3d.bridge_info[0]["broken"] = true
	host3d.bridge_info[0]["gap_min"] = 1.0
	host3d.bridge_info[0]["gap_max"] = 2.0
	host3d.bridge_info[0]["planks"][4].set_meta("dropping", true)
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(is_equal_approx(guest3d.ferry.position.x, 3.5) and guest3d.crystal.visible and guest3d.crystal.position.is_equal_approx(host3d.crystal.position), "3D Join receives ferry and crystal state")
	check(is_instance_valid(guest3d.lightning_warning) and guest3d.lightning_warning.position.is_equal_approx(host3d.lightning_warning.position), "3D Join receives lightning warning")
	check(is_equal_approx(guest3d.collapses[0]["part"].rotation.x, 0.2) and guest3d.bridge_info[0]["planks"][4].has_meta("dropping"), "3D Join receives island tilt and exact broken plank")
	guest3d._update_heal_visual()
	check(guest3d.collapses[0]["part"].get_child_count() > before_cracks and not guest3d.heal_ring.visible and is_equal_approx(guest3d.heal_ready_at, host3d.heal_ready_at), "3D Join renders collapse cracks and heal cooldown")
	var before_remote: Vector3 = guest3d.bodies[0].position
	host3d.bodies[0].position += Vector3(1.0, 0.0, 0.0)
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(guest3d.bodies[0].position.is_equal_approx(before_remote), "3D Join does not teleport on each fighter snapshot")
	guest3d._lan_reconcile(1.0 / 60.0)
	check(guest3d.bodies[0].position.x > before_remote.x and guest3d.bodies[0].position.x < host3d.bodies[0].position.x, "3D Join interpolates remote movement between snapshots")
	host3d.collapses[0]["part"].queue_free()
	guest3d.collapses[0]["part"].queue_free()
	await process_frame
	var collapsed_snapshot: Dictionary = host3d._lan_snapshot()
	guest3d.lan_apply_state(collapsed_snapshot)
	check(collapsed_snapshot["islands"][0][1].is_empty() and collapsed_snapshot["islands"][0][2].is_empty(), "3D LAN snapshot skips freed collapsed island")
	host3d.collapses[1]["part"].queue_free()
	await process_frame
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(guest3d.collapses[1]["part"].is_queued_for_deletion(), "3D Join removes expired island collision")
	await process_frame
	guest3d.lan_apply_state(host3d._lan_snapshot())
	host3d.elapsed = 5.0
	host3d.boost_timer = 9.0
	host3d.crystal_kind = 0
	host3d.crystal.position = Vector3(0, 0.8, 0)
	host3d.crystal.show()
	host3d.bodies[0].position = Vector3(0.9, 0.2, 0)
	host3d.bodies[1].position = Vector3(0.1, 0.2, 0)
	host3d.update_crystals(0.016)
	check(host3d.boost[1] > 0.0 and host3d.boost[0] == 0.0 and host3d.shard_icons[1].visible and not host3d.shard_icons[0].visible, "3D Host awards a contested Power Shard to the nearer Black fighter")
	var shard_snapshot: Dictionary = host3d._lan_snapshot()
	check(JSON.stringify({"type": "duel_state", "state": shard_snapshot}).to_utf8_buffer().size() < 4096, "Power Shard snapshot fits LAN packet limit")
	guest3d.lan_apply_state(shard_snapshot)
	check(guest3d.shard_icons[1].visible and not guest3d.shard_icons[0].visible and guest3d.shard_icons[1].get_parent() == guest3d.bodies[1] and guest3d.shard_icon_kind[1] == 0, "3D Join displays Power Shard above its actual owner")
	guest3d.update_shard_icons(0.25)
	var popup_remaining: float = guest3d.shard_icon_time[1]
	guest3d.lan_apply_state(shard_snapshot)
	check(guest3d.shard_icon_time[1] <= popup_remaining + 0.001, "repeated LAN state does not restart shard popup")
	host3d.crystal_kind = 1
	host3d.crystal.position = Vector3(0, 0.8, 0)
	host3d.crystal.show()
	host3d.bodies[0].position = Vector3(0.1, 0.2, 0)
	host3d.bodies[1].position = Vector3(0.9, 0.2, 0)
	host3d.update_crystals(0.016)
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(host3d.speed_boost[0] > 0.0 and guest3d.shard_icons[0].visible and guest3d.shard_icons[0].get_parent() == guest3d.bodies[0] and guest3d.shard_icon_kind[0] == 1, "3D Host and Join show a White-owned Speed Shard above White")
	var before_fx_nodes: int = guest3d.get_child_count() + guest3d.polish.get_child_count()
	var before_fx_hp: float = guest3d.hp[1]
	host3d.fx_ring(Vector3(1, 1, 0), Color.GOLD, 2.0)
	host3d.fx_popup(Vector3(1, 2, 0), 12.0, Color.WHITE)
	host3d.effect(Vector3(1, 1, 0), Color.ORANGE, 0.5)
	host3d.burst(Vector3(1, 1, 0), Color.RED, 4, 0.4)
	host3d.spear_impact(Vector3(1, 1, 0))
	host3d._lan_fx("lightning", [[1.0, 0.0, 0.0]])
	var fx_snapshot: Dictionary = host3d._lan_snapshot()
	check(JSON.stringify({"type": "duel_state", "state": fx_snapshot}).to_utf8_buffer().size() < 4096, "combat FX snapshot fits LAN packet limit")
	guest3d.lan_apply_state(fx_snapshot)
	var after_fx_nodes: int = guest3d.get_child_count() + guest3d.polish.get_child_count()
	check(after_fx_nodes > before_fx_nodes + 8 and guest3d.lan_fx_seen == host3d.lan_fx_sequence and is_equal_approx(guest3d.hp[1], before_fx_hp), "Join replays combat rings, popup, sparks and lightning without damage")
	guest3d.lan_apply_state(fx_snapshot)
	check(guest3d.get_child_count() + guest3d.polish.get_child_count() == after_fx_nodes, "repeated state does not duplicate combat effects")
	var projectile: Node3D = host3d.orb(Color.ORANGE_RED, 0.22)
	host3d.add_child(projectile)
	projectile.position = Vector3(1, 2, 3)
	host3d.projectiles.append({"mesh": projectile, "kind": "fire", "owner": 0, "velocity": Vector3.ZERO, "life": 1.0})
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(guest3d.lan_projectile_meshes.size() == 1 and guest3d.lan_projectile_meshes[0] is PyroluxFireball3D and guest3d.lan_projectile_meshes[0].visible and guest3d.lan_projectile_meshes[0].head_position().distance_to(projectile.position) < 0.5, "3D Join renders authored Host fireball FX")
	host3d.projectiles.clear()
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(not is_instance_valid(guest3d.lan_projectile_meshes[0]) or guest3d.lan_projectile_meshes[0].is_queued_for_deletion(), "3D Join removes expired projectile")
	host3d.over = true
	host3d.end_winner = 1
	host3d.hp[0] = 0.0
	guest3d.lan_apply_state(host3d._lan_snapshot())
	check(guest3d.over and not guest3d.cross.visible and guest3d.end_winner == 1, "3D Join sees Black victory state")
	guest3d._lan_guest_tick(0.25)
	check(guest3d.end_clock > 0.0 and not guest3d.shields[0].visible and not guest3d.shields[1].visible, "3D Join advances victory camera and hides combat shields")
	host3d.over = false
	host3d.hp[0] = float(host3d.stats[0]["hp"])
	for j in range(24): host3d._lan_fx("ring", [[float(j) * 0.1, 1.0, 0.0], "ffffffff", 2.0, 0.28, true])
	check(JSON.stringify({"type": "duel_state", "state": host3d._lan_snapshot()}).to_utf8_buffer().size() < 4096, "maximum retained 3D combat FX fits LAN packet limit")
	guest3d.queue_free()
	await process_frame
	host3d.guarding[1] = true
	host3d.lan_guard_age = 0.06
	var black_hp: float = host3d.hp[1]
	host3d.damage(0, 14.0)
	check(is_equal_approx(host3d.hp[1], black_hp) and host3d.counter_time[1] > 0.0, "LAN Black perfect block protects HP and arms counter")
	host3d.guarding[1] = false
	host3d.lan_dodge_time = 0.1
	host3d.damage(0, 14.0)
	check(is_equal_approx(host3d.hp[1], black_hp), "LAN Black dodge avoids damage")
	host3d.lan_dodge_time = 0.0
	host3d.bodies[1].position = host3d.bodies[0].position + Vector3(0, 0, -1.2)
	var white_hp: float = host3d.hp[0]
	check(host3d.attack(1, Vector3.BACK, false), "LAN Black fighter can start an attack")
	host3d.resolve_attack(1, Vector3.BACK, false)
	check(host3d.hp[0] < white_hp, "LAN Black fighter can damage White")
	host3d.pose_time[1] = 0.0
	host3d.pawn_pending[1] = {}
	check(host3d.attack(1, Vector3.BACK, true), "LAN Black fighter can start special")
	host3d.resolve_attack(1, Vector3.BACK, true)
	check(not host3d.projectiles.is_empty() and host3d.projectiles[-1]["kind"] == "bomb", "LAN Black Bomber special spawns bomb")
	host3d.queue_free()
	await process_frame
	var host2d: Variant = Duel.new()
	host2d.lan_role = 1
	root.add_child(host2d)
	host2d.setup("N", "B", false, Data.STAGES[1])
	host2d.set_process(false)
	var guest2d: Variant = Duel.new()
	guest2d.lan_role = 2
	root.add_child(guest2d)
	guest2d.setup("N", "B", false, Data.STAGES[1])
	guest2d.set_process(false)
	host2d.lan_receive_input({"dir": -1, "attack": true})
	var first: Dictionary = host2d._read_input(host2d.fighters[1], 0.016)
	var second: Dictionary = host2d._read_input(host2d.fighters[1], 0.016)
	check(first["dir"] == -1 and first["attack"] and not second["attack"], "2.5D Host uses edge-triggered Join input")
	host2d.lan_receive_input({"attack": false})
	host2d.lan_receive_input({"attack": true})
	host2d.lan_receive_input({"attack": false})
	check(host2d._read_input(host2d.fighters[1], 0.016)["attack"], "2.5D Host keeps quick Join button tap until simulation")
	host2d.fighters[0].hp -= 14.0
	host2d.fighters[1].s = 1.25
	guest2d.lan_apply_state(host2d._lan_snapshot())
	check(is_equal_approx(guest2d.fighters[0].hp, host2d.fighters[0].hp) and is_equal_approx(guest2d.fighters[1].s, 1.25), "2.5D Join receives authoritative duel state")
	host2d._spawn_proj(host2d.fighters[0], "fire", 9.0, 0.0, 1.2)
	guest2d.lan_apply_state(host2d._lan_snapshot())
	check(guest2d.lan_projectile_meshes.size() == 1 and guest2d.lan_projectile_meshes[0].visible and guest2d.lan_projectile_meshes[0].get_meta("lan_kind") == "fire", "2.5D Join renders matching projectile")
	host2d.projs.clear()
	guest2d.lan_apply_state(host2d._lan_snapshot())
	check(not guest2d.lan_projectile_meshes[0].visible, "2.5D Join removes expired projectile")
	var before_2d_fx: int = guest2d.get_child_count()
	var before_2d_hp: float = guest2d.fighters[1].hp
	host2d._lan_fx("bomb", [1.5, 0.3, "R"])
	host2d._lan_fx("smite", [-1.0, "B"])
	var fx2d_snapshot: Dictionary = host2d._lan_snapshot()
	guest2d.lan_apply_state(fx2d_snapshot)
	var after_2d_fx: int = guest2d.get_child_count()
	check(after_2d_fx >= before_2d_fx + 3 and guest2d.lan_fx_seen == host2d.lan_fx_sequence and is_equal_approx(guest2d.fighters[1].hp, before_2d_hp), "2.5D Join replays Bomb explosion and Smite beam without damage")
	guest2d.lan_apply_state(fx2d_snapshot)
	check(guest2d.get_child_count() == after_2d_fx, "2.5D repeated state does not duplicate explosion")
	host2d.over = true
	host2d.fighters[0].hp = 0.0
	guest2d.lan_apply_state(host2d._lan_snapshot())
	check(guest2d.over and guest2d.banner.visible and guest2d.banner.text.contains("wins"), "2.5D Join sees Black victory banner")
	host2d.queue_free()
	guest2d.queue_free()
	await process_frame
	print("LAN duel scene smoke: %d failure(s)" % failures)
	quit(0 if failures == 0 else 1)
