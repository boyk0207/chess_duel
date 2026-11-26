@tool
@icon("res://addons/pyrolux_fx/icons/fireball.svg")
class_name PyroluxFireball3D
extends PyroluxEffect3D
## A flying ball of fire: a white-hot core in a wobbling flame skin, flame tongues streaming
## back along its path, and a smoke and ember trail that stays behind in the world. When it
## reaches its target (a point, the ground, or whatever a ray hits) it emits hit() and plays
## its own small burst: flash, fireball, sparks and a scorch mark on the surface.
##
##   $Fireball.launch(muzzle, target_point)
##   $Fireball.launch_direction(muzzle, -global_basis.z, 18.0)
##   Pyrolux.spawn(self, "fireball")            # fires along -Z from where it is put
##   $Fireball.hit.connect(on_fireball_hit)
##
## The burst is part of this node, so a fireball needs nothing else from the pack.

## The ball reached something. `position` is the point of impact, `normal` the surface normal
## there (the reverse of the flight direction when nothing was hit).
signal hit(position: Vector3, normal: Vector3)

## How the flight ends. TARGET: at the point given to launch(), or after travel_range.
## GROUND: at the height ground_y (good for a lobbed shot). RAYCAST: the first thing a ray
## along the path hits on collision_mask, and TARGET if it hits nothing. NONE: the ball just
## fades out and no burst is played.
enum HitMode { TARGET, GROUND, RAYCAST, NONE }

const FIREBALL: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_fireball.gdshader")
const TONGUE: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_tongue.gdshader")
const PUFF: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_puff.gdshader")
const SPARK: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_spark.gdshader")
const RING: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_ring.gdshader")
const SCORCH: Shader = preload("res://addons/pyrolux_fx/shaders/pyrolux_scorch.gdshader")

## Radius of the ball in metres.
@export_range(0.05, 5.0, 0.01, "or_greater") var ball_radius: float = _default(&"ball_radius", 0.32)
## Flight speed in metres per second.
@export_range(1.0, 200.0, 0.1, "or_greater") var speed: float = _default(&"speed", 16.0)
## Direction of flight in the node's own space, used by fire() and by autoplay.
@export var direction: Vector3 = _default(&"direction", Vector3(0.0, 0.0, -1.0))
## Downward pull in metres per second squared. 0 flies dead straight, 9.8 lobs in an arc.
@export_range(0.0, 40.0, 0.01) var arc_gravity: float = _default(&"arc_gravity", 0.0)
## How far the ball flies before it bursts when it is not aimed at a point, in metres.
@export_range(1.0, 500.0, 0.1, "or_greater") var travel_range: float = _default(&"travel_range", 24.0)

@export_group("Impact")
## What ends the flight.
@export var hit_mode: HitMode = _default(&"hit_mode", HitMode.TARGET)
## GROUND mode: the height the ball bursts at, in world metres.
@export var ground_y: float = _default(&"ground_y", 0.0)
## RAYCAST mode: the physics layers the ray looks at.
@export_flags_3d_physics var collision_mask: int = _default(&"collision_mask", 1)
## Radius of the burst in metres. 0 follows ball_radius.
@export_range(0.0, 30.0, 0.01, "or_greater") var impact_radius: float = _default(&"impact_radius", 0.0)
@export_range(0, 400, 1) var impact_flames: int = _default(&"impact_flames", 20):
	set(value):
		impact_flames = value
		_rebuild_queued = true
@export_range(0, 400, 1) var impact_sparks: int = _default(&"impact_sparks", 26):
	set(value):
		impact_sparks = value
		_rebuild_queued = true
## Burn mark left on the surface that was hit.
@export var impact_scorch: bool = _default(&"impact_scorch", true):
	set(value):
		impact_scorch = value
		_rebuild_queued = true
## Seconds the burn mark stays.
@export_range(0.0, 120.0, 0.1, "or_greater") var scorch_time: float = _default(&"scorch_time", 6.0)

@export_group("Trail")
## Flame tongues streaming backwards off the ball.
@export_range(0, 200, 1) var tongues: int = _default(&"tongues", 12):
	set(value):
		tongues = value
		_rebuild_queued = true
## Length of the tongues in ball radii.
@export_range(0.0, 20.0, 0.01) var tongue_length: float = _default(&"tongue_length", 2.4)
## How far the trail of smoke and embers reaches back, in metres. The faster the ball, the
## shorter each puff lives, so the trail is the same length at any speed.
@export_range(0.0, 60.0, 0.1, "or_greater") var trail_length: float = _default(&"trail_length", 8.0)
@export_range(0, 600, 1) var trail_smoke: int = _default(&"trail_smoke", 30):
	set(value):
		trail_smoke = value
		_rebuild_queued = true
@export_range(0, 600, 1) var trail_sparks: int = _default(&"trail_sparks", 20):
	set(value):
		trail_sparks = value
		_rebuild_queued = true

@export_group("Volley")
## Fireballs fired per trigger. Above 1 the extra ones come from internal copies of this node.
@export_range(1, 20, 1) var volley: int = _default(&"volley", 1)
## Seconds between the shots of a volley.
@export_range(0.02, 3.0, 0.01) var volley_interval: float = _default(&"volley_interval", 0.16)
## How far apart a volley spreads, in degrees.
@export_range(0.0, 45.0, 0.1) var volley_spread: float = _default(&"volley_spread", 3.0)

var _core_mat: ShaderMaterial
var _tongue_mat: ShaderMaterial
var _smoke_mat: ShaderMaterial
var _spark_mat: ShaderMaterial
var _flash_mat: ShaderMaterial
var _burst_mat: ShaderMaterial
var _burst_spark_mat: ShaderMaterial
var _scorch_mat: ShaderMaterial
var _impact_mats: Array[ShaderMaterial] = []
var _ray: RayCast3D

var _head: Transform3D = Transform3D.IDENTITY
var _from: Vector3 = Vector3.ZERO
var _v0: Vector3 = Vector3.FORWARD
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _flight: float = 1.0
var _duration: float = 4.0
var _hit_age: float = -1.0
var _hit_point: Vector3 = Vector3.ZERO
var _hit_normal: Vector3 = Vector3.UP
var _armed: bool = false
var _shot: int = 1
var _speed_used: float = 16.0

## Seconds the trail takes to stop making new particles after the ball has landed.
const TRAIL_TAIL: float = 0.4


func _class_defaults() -> Dictionary:
	return {&"light_energy": 4.0, &"light_range": 7.0, &"preview_interval": 4.0}


func is_one_shot() -> bool:
	return true


func get_duration() -> float:
	return _duration


## Flies from `from` to the point `to`. `p_speed` overrides speed when it is above 0.
func launch(from: Vector3, to: Vector3, p_speed: float = -1.0) -> void:
	_prepare(from, to - from, p_speed, true)
	_armed = true
	trigger()


## Flies from `from` along `dir` (any length) and bursts after travel_range, or earlier if the
## hit mode finds something on the way.
func launch_direction(from: Vector3, dir: Vector3, p_speed: float = -1.0) -> void:
	_prepare(from, dir, p_speed, false)
	_armed = true
	trigger()


## Fires from where the node is, along `direction` in the node's own space.
func fire() -> void:
	trigger()


## Seconds the current shot takes to reach its target.
func flight_time() -> float:
	return _flight


## Where the ball is now (the burst point once it has landed).
func head_position() -> Vector3:
	return _head.origin


func _prepare(from: Vector3, vec: Vector3, p_speed: float, has_target: bool) -> void:
	var s: float = world_scale()
	_speed_used = p_speed if p_speed > 0.0 else speed
	var sp: float = maxf(_speed_used * s, 0.01)
	var d: Vector3 = vec
	if d.length_squared() < 1.0e-8:
		d = Vector3.FORWARD
	_from = from
	_has_target = has_target
	var g: float = arc_gravity * s
	if has_target:
		_target = from + d
		_flight = maxf(d.length() / sp, 0.02)
		_v0 = d / _flight + Vector3.UP * (0.5 * g * _flight)
	else:
		_target = from + d.normalized() * travel_range * s
		_flight = maxf(travel_range * s / sp, 0.02)
		_v0 = d.normalized() * sp
	var tail: float = scorch_time if impact_scorch and hit_mode != HitMode.NONE else 0.0
	_duration = float(volley - 1) * volley_interval + _flight + maxf(tail, 3.5)


func _on_trigger() -> void:
	if not _armed:
		_prepare(global_position, global_basis * direction, -1.0, false)
	_armed = false
	_hit_age = -1.0
	_hit_point = _target
	_hit_normal = -_v0.normalized()
	_shot = 1
	_velocity = _v0
	_update_head()


func _burst_radius() -> float:
	return impact_radius if impact_radius > 0.0 else ball_radius * 2.6


func _extent() -> Vector3:
	var r: float = maxf(_speed_used * 1.6, _burst_radius() * 4.0) + 2.0
	return Vector3(r, r, r)


func _emitter_transform() -> Transform3D:
	return _head


## The frame the burst sits in: +Y along the normal of the surface that was hit, so the scorch
## mark lies on it and the flames and sparks come off it.
func _impact_transform() -> Transform3D:
	var s: float = world_scale()
	var ny: Vector3 = _hit_normal if _hit_normal.length_squared() > 1.0e-8 else Vector3.UP
	ny = ny.normalized()
	var nx: Vector3 = ny.cross(Vector3.FORWARD)
	if nx.length_squared() < 1.0e-4:
		nx = ny.cross(Vector3.RIGHT)
	nx = nx.normalized()
	var nz: Vector3 = nx.cross(ny).normalized()
	return Transform3D(Basis(nx * s, ny * s, nz * s), _hit_point)


func _flying() -> bool:
	var a: float = get_age()
	return a >= 0.0 and _hit_age < 0.0 and a <= _flight


func _build() -> void:
	_impact_mats.clear()
	if _ray:
		remove_child(_ray)
		_ray.queue_free()
		_ray = null
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	_scorch_mat = make_layer(SCORCH, PyroluxMeshes.quads(1), -2) if impact_scorch else null
	_smoke_mat = make_layer(PUFF, PyroluxMeshes.quads(count_for(trail_smoke)), 0) if trail_smoke > 0 else null
	_burst_mat = make_layer(PUFF, PyroluxMeshes.quads(count_for(impact_flames)), 1) if impact_flames > 0 else null
	_tongue_mat = make_layer(TONGUE, PyroluxMeshes.strips(count_for(tongues), 1), 2) if tongues > 0 else null
	_core_mat = make_layer(FIREBALL, sphere, 3)
	_spark_mat = make_layer(SPARK, PyroluxMeshes.quads(count_for(trail_sparks)), 4) if trail_sparks > 0 else null
	_burst_spark_mat = make_layer(SPARK, PyroluxMeshes.quads(count_for(impact_sparks)), 4) if impact_sparks > 0 else null
	_flash_mat = make_layer(RING, PyroluxMeshes.quads(1), 5)
	for m: ShaderMaterial in [_scorch_mat, _burst_mat, _burst_spark_mat, _flash_mat]:
		if m != null:
			_impact_mats.append(m)
	_ray = RayCast3D.new()
	_ray.enabled = false
	_ray.top_level = true
	_ray.collide_with_areas = false
	_ray.collide_with_bodies = true
	add_child(_ray, false, Node.INTERNAL_MODE_BACK)


## Position on the flight path `t` seconds after the shot.
func _point_at(t: float) -> Vector3:
	return _from + _v0 * t + Vector3.DOWN * (arc_gravity * world_scale() * 0.5 * t * t)


func _velocity_at(t: float) -> Vector3:
	return _v0 + Vector3.DOWN * (arc_gravity * world_scale() * t)


func _update_head() -> void:
	var s: float = world_scale()
	var a: float = get_age()
	if a < 0.0:
		_head = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), global_position)
		return
	var t: float = minf(a, _hit_age) if _hit_age >= 0.0 else minf(a, _flight)
	var pos: Vector3 = _hit_point if _hit_age >= 0.0 else _point_at(t)
	var vel: Vector3 = _velocity_at(t)
	# +Y of the emitter points back down the path, so the tongues and the tail stream behind.
	var back: Vector3 = -vel.normalized() if vel.length_squared() > 1.0e-8 else Vector3.UP
	var bx: Vector3 = back.cross(Vector3.FORWARD)
	if bx.length_squared() < 1.0e-4:
		bx = back.cross(Vector3.RIGHT)
	bx = bx.normalized()
	var bz: Vector3 = bx.cross(back).normalized()
	_head = Transform3D(Basis(bx * s, back * s, bz * s), pos)
	_velocity = vel


func _tick(_delta: float) -> void:
	_update_head()
	var a: float = get_age()
	if a >= 0.0 and _hit_age < 0.0:
		_check_hit(a)
	if volley > 1 and _shot < volley and a >= float(_shot) * volley_interval:
		_spawn_extra(_shot)
		_shot += 1
	var br: float = _burst_radius()
	# A trail of a fixed length in metres: the faster the ball, the shorter each puff lives.
	var tl: float = clampf(trail_length / maxf(_speed_used, 0.5), 0.12, 4.0)
	if _core_mat:
		var m: ShaderMaterial = _core_mat
		m.set_shader_parameter("radius", ball_radius)
		m.set_shader_parameter("tail", 1.0)
		m.set_shader_parameter("wobble", 0.34)
		m.set_shader_parameter("noise_scale", 2.6)
		m.set_shader_parameter("noise_speed", 2.0)
		m.set_shader_parameter("heat", 0.95)
		m.set_shader_parameter("core_size", 0.26)
		m.set_shader_parameter("edge_breakup", 0.5)
		m.set_shader_parameter("softness", 0.34)
		m.set_shader_parameter("intensity", 0.6)
		m.set_shader_parameter("flame_opacity", 0.6)
	if _tongue_mat:
		var m: ShaderMaterial = _tongue_mat
		m.set_shader_parameter("shape", 1)
		m.set_shader_parameter("shape_size", Vector3(ball_radius * 0.8, 0.0, ball_radius * 0.8))
		m.set_shader_parameter("height", ball_radius * tongue_length)
		m.set_shader_parameter("height_var", 0.45)
		m.set_shader_parameter("width", ball_radius * 1.2)
		m.set_shader_parameter("speed", 2.4)
		m.set_shader_parameter("lean", 0.05)
		m.set_shader_parameter("inherit", 0.02)
		m.set_shader_parameter("heat", 0.9)
		m.set_shader_parameter("flame_opacity", 0.15)
		m.set_shader_parameter("edge_breakup", 0.9)
	if _smoke_mat:
		var m: ShaderMaterial = _smoke_mat
		m.set_shader_parameter("mode", 0)
		m.set_shader_parameter("kind", 2)
		m.set_shader_parameter("shape", 5)
		m.set_shader_parameter("shape_size", Vector3(ball_radius * 0.7, 0.0, 0.0))
		m.set_shader_parameter("velocity", Vector3(0.0, 0.6, 0.0))
		m.set_shader_parameter("spread_mode", 2)
		m.set_shader_parameter("spread", 0.6)
		m.set_shader_parameter("drag", 1.4)
		m.set_shader_parameter("buoyancy", ball_radius * 1.0)
		m.set_shader_parameter("lifetime", tl)
		m.set_shader_parameter("lifetime_var", 0.35)
		m.set_shader_parameter("size_start", ball_radius * 0.8)
		m.set_shader_parameter("size_end", ball_radius * 1.45)
		m.set_shader_parameter("size_curve", 0.6)
		m.set_shader_parameter("size_var", 0.4)
		m.set_shader_parameter("heat", 0.7)
		m.set_shader_parameter("heat_var", 0.3)
		m.set_shader_parameter("cool_rate", 2.8)
		m.set_shader_parameter("smoke_opacity", 0.3)
		m.set_shader_parameter("flame_opacity", 0.22)
		m.set_shader_parameter("glow_under", 0.3)
		m.set_shader_parameter("erosion", 0.75)
		m.set_shader_parameter("noise_scale", 2.0)
		m.set_shader_parameter("spin", 1.2)
		m.set_shader_parameter("tint", Color(0.85, 0.85, 0.9, 1.0))
		m.set_shader_parameter("fade_in", 0.05)
		m.set_shader_parameter("fade_out", 0.5)
		m.set_shader_parameter("noise_speed", 0.5)
		m.set_shader_parameter("turbulence", ball_radius * 0.5)
		m.set_shader_parameter("inherit", 1.0)
	if _spark_mat:
		var m: ShaderMaterial = _spark_mat
		m.set_shader_parameter("mode", 0)
		m.set_shader_parameter("kind", 1)
		m.set_shader_parameter("shape", 5)
		m.set_shader_parameter("shape_size", Vector3(ball_radius * 0.7, 0.0, 0.0))
		m.set_shader_parameter("velocity", Vector3(0.0, 1.4, 0.0))
		m.set_shader_parameter("spread_mode", 2)
		m.set_shader_parameter("drag", 1.2)
		m.set_shader_parameter("gravity", 2.5)
		m.set_shader_parameter("lifetime", tl * 0.55)
		m.set_shader_parameter("lifetime_var", 0.45)
		m.set_shader_parameter("width", 0.035 + ball_radius * 0.05)
		m.set_shader_parameter("stretch", 0.05)
		m.set_shader_parameter("heat", 1.1)
		m.set_shader_parameter("cool_rate", 1.1)
		m.set_shader_parameter("inherit", 1.0)
	if _flash_mat:
		var m: ShaderMaterial = _flash_mat
		m.set_shader_parameter("kind", 2)
		m.set_shader_parameter("facing", 1)
		m.set_shader_parameter("radius", br * 1.1)
		m.set_shader_parameter("duration", 0.24)
		m.set_shader_parameter("intensity", 1.4)
	if _burst_mat:
		var m: ShaderMaterial = _burst_mat
		m.set_shader_parameter("mode", 1)
		m.set_shader_parameter("kind", 2)
		m.set_shader_parameter("shape", 5)
		m.set_shader_parameter("shape_size", Vector3(br * 0.25, 0.0, 0.0))
		m.set_shader_parameter("spawn_offset", Vector3(0.0, br * 0.12, 0.0))
		m.set_shader_parameter("spread_mode", 1)
		m.set_shader_parameter("spread", 0.95)
		m.set_shader_parameter("velocity", Vector3(0.0, br * 2.6, 0.0))
		m.set_shader_parameter("speed_var", 0.5)
		m.set_shader_parameter("drag", 5.0)
		m.set_shader_parameter("buoyancy", br * 0.8)
		m.set_shader_parameter("turbulence", br * 0.12)
		m.set_shader_parameter("lifetime", 1.25)
		m.set_shader_parameter("lifetime_var", 0.35)
		m.set_shader_parameter("spawn_window", 0.03)
		m.set_shader_parameter("size_start", br * 0.5)
		m.set_shader_parameter("size_end", br * 0.9)
		m.set_shader_parameter("size_curve", 0.35)
		m.set_shader_parameter("heat", 1.35)
		m.set_shader_parameter("cool_rate", 1.4)
		m.set_shader_parameter("smoke_opacity", 0.8)
		m.set_shader_parameter("flame_opacity", 0.65)
		m.set_shader_parameter("fade_in", 0.02)
		m.set_shader_parameter("fade_out", 0.45)
		m.set_shader_parameter("glow_under", 0.85)
		m.set_shader_parameter("noise_speed", 0.6)
		m.set_shader_parameter("ground_y", _surface_y())
	if _burst_spark_mat:
		var m: ShaderMaterial = _burst_spark_mat
		m.set_shader_parameter("mode", 1)
		m.set_shader_parameter("kind", 0)
		m.set_shader_parameter("shape", 5)
		m.set_shader_parameter("shape_size", Vector3(br * 0.15, 0.0, 0.0))
		m.set_shader_parameter("spread_mode", 1)
		m.set_shader_parameter("spread", 0.95)
		m.set_shader_parameter("velocity", Vector3(0.0, 4.0 + br * 2.5, 0.0))
		m.set_shader_parameter("speed_var", 0.6)
		m.set_shader_parameter("drag", 1.3)
		m.set_shader_parameter("gravity", 9.8)
		m.set_shader_parameter("lifetime", 1.0)
		m.set_shader_parameter("lifetime_var", 0.5)
		m.set_shader_parameter("spawn_window", 0.05)
		m.set_shader_parameter("width", 0.03 + br * 0.01)
		m.set_shader_parameter("stretch", 0.045)
		m.set_shader_parameter("heat", 1.2)
		m.set_shader_parameter("cool_rate", 1.1)
		m.set_shader_parameter("bounce", 0.3)
		m.set_shader_parameter("ground_y", _surface_y())
	if _scorch_mat:
		var m: ShaderMaterial = _scorch_mat
		m.set_shader_parameter("radius", br * 0.95)
		m.set_shader_parameter("lifetime", scorch_time)
		m.set_shader_parameter("fade_time", minf(2.5, scorch_time * 0.4))
		m.set_shader_parameter("ember_cool", 2.5)
		m.set_shader_parameter("height_offset", 0.03)
	_update_light()


## The floor the burst bounces its sparks off: only when the ball hit a roughly level surface.
func _surface_y() -> float:
	if _hit_age >= 0.0 and _hit_normal.y > 0.7:
		return _hit_point.y
	return -100000.0


func _check_hit(a: float) -> void:
	if hit_mode == HitMode.NONE:
		if a >= _flight:
			_hit_age = a
			_hit_point = _point_at(_flight)
			_hit_normal = -_velocity_at(_flight).normalized()
		return
	var prev: Vector3 = _point_at(maxf(a - _step(), 0.0))
	var now: Vector3 = _point_at(a)
	if hit_mode == HitMode.GROUND and now.y <= ground_y:
		var dy: float = prev.y - now.y
		var k: float = clampf((prev.y - ground_y) / dy, 0.0, 1.0) if dy > 1.0e-6 else 0.0
		_do_hit(prev.lerp(now, k), Vector3.UP, a)
		return
	if hit_mode == HitMode.RAYCAST and _ray != null and not Engine.is_editor_hint():
		_ray.global_position = prev
		_ray.target_position = now - prev
		_ray.collision_mask = collision_mask
		_ray.force_raycast_update()
		if _ray.is_colliding():
			_do_hit(_ray.get_collision_point(), _ray.get_collision_normal(), a)
			return
	if a >= _flight:
		_do_hit(_point_at(_flight), -_velocity_at(_flight).normalized(), _flight)


## Length of the piece of path tested this frame, in scaled seconds.
func _step() -> float:
	return minf(0.1, maxf(_flight * 0.05, 0.004))


func _do_hit(point: Vector3, normal: Vector3, at_age: float) -> void:
	_hit_age = at_age
	_hit_point = point
	_hit_normal = normal if normal.length_squared() > 1.0e-8 else Vector3.UP
	hit.emit(_hit_point, _hit_normal)


func _update_light() -> void:
	var a: float = get_age()
	if a < 0.0:
		set_light_level(0.0)
		return
	var l: float = 0.0
	var pos: Vector3 = _head.origin
	if _hit_age < 0.0:
		l = 0.85 + 0.15 * sin(a * 21.0)
	else:
		var b: float = a - _hit_age
		l = 1.6 * exp(-b * 4.0) + 0.2 * exp(-b)
		pos = _hit_point + _hit_normal * _burst_radius() * 0.4 * world_scale()
	set_light_level(l * amount)
	var lt: OmniLight3D = get_light()
	if lt:
		lt.top_level = true
		lt.global_position = pos


func _push_common() -> void:
	super._push_common()
	var a: float = get_age()
	var flying: float = 1.0 if _flying() else 0.0
	# The trail keeps what is already in the air and stops making new particles.
	var tail: float = flying
	if _hit_age >= 0.0:
		tail = 1.0 - smoothstep(0.0, TRAIL_TAIL, a - _hit_age)
	var lv: float = effective_amount()
	if _core_mat:
		_core_mat.set_shader_parameter("level", flying * lv)
	if _tongue_mat:
		_tongue_mat.set_shader_parameter("level", flying * lv)
	for m: ShaderMaterial in [_smoke_mat, _spark_mat]:
		if m != null:
			m.set_shader_parameter("level", tail * lv)
	# The burst sits still on the surface that was hit, not on the moving ball.
	var t: Transform3D = _impact_transform()
	var d: float = _hit_age if _hit_age >= 0.0 else 1.0e9
	for m: ShaderMaterial in _impact_mats:
		m.set_shader_parameter("em_origin", t.origin)
		m.set_shader_parameter("em_x", t.basis.x)
		m.set_shader_parameter("em_y", t.basis.y)
		m.set_shader_parameter("em_z", t.basis.z)
		m.set_shader_parameter("em_velocity", Vector3.ZERO)
		m.set_shader_parameter("level", lv)
		m.set_shader_parameter("delay", d)


## One more shot of a volley: an internal copy of this node with the same look, aimed a little
## to the side. Its own hit() is relayed through this node.
func _spawn_extra(k: int) -> void:
	if not is_inside_tree():
		return
	var fb: PyroluxFireball3D = PyroluxFireball3D.new()
	fb.ball_radius = ball_radius
	fb.speed = speed
	fb.direction = direction
	fb.arc_gravity = arc_gravity
	fb.travel_range = travel_range
	fb.hit_mode = hit_mode
	fb.ground_y = ground_y
	fb.collision_mask = collision_mask
	fb.impact_radius = impact_radius
	fb.impact_flames = impact_flames
	fb.impact_sparks = impact_sparks
	fb.impact_scorch = impact_scorch
	fb.scorch_time = scorch_time
	fb.tongues = tongues
	fb.tongue_length = tongue_length
	fb.trail_smoke = trail_smoke
	fb.trail_sparks = trail_sparks
	fb.palette = palette
	fb.quality = quality
	fb.light_enabled = light_enabled
	fb.light_energy = light_energy
	fb.light_range = light_range
	fb.amount = amount
	fb.time_scale = time_scale
	fb.volley = 1
	fb.autoplay = false
	fb.preview_in_editor = false
	add_child(fb, false, Node.INTERNAL_MODE_BACK)
	fb.hit.connect(_relay_hit)
	var ax: Vector3 = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 0.5), rng.randf_range(-1.0, 1.0))
	if ax.length_squared() < 1.0e-6:
		ax = Vector3.UP
	var turn: float = deg_to_rad(volley_spread) * rng.randf_range(-1.0, 1.0)
	var rot: Basis = Basis(ax.normalized(), turn)
	if _has_target:
		fb.launch(_from, _from + rot * (_target - _from), _speed_used)
	else:
		fb.launch_direction(_from, rot * _v0, _speed_used)


func _relay_hit(point: Vector3, normal: Vector3) -> void:
	hit.emit(point, normal)
