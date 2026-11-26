// The core of a flying fireball: a ball of flame with a white-hot middle, a wobbling skin and
// a teardrop tail drawn out along +em_y (the node points that axis backwards along the
// flight). The mesh is a plain unit sphere; its real place, size and shape are computed here
// from the emitter basis, so the CPU only moves the emitter. Reads as a ball from any angle
// because the brightness follows how much flame the view looks through.
shader_type spatial;
render_mode unshaded, blend_premul_alpha, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

#include "res://addons/pyrolux_fx/shaders/pyrolux_common.gdshaderinc"

uniform int seed = 1;
uniform float time = 0.0;
uniform float level = 1.0;
uniform float age = -1.0;
uniform vec3 em_origin;
uniform vec3 em_x = vec3(1.0, 0.0, 0.0);
uniform vec3 em_y = vec3(0.0, 1.0, 0.0);
uniform vec3 em_z = vec3(0.0, 0.0, 1.0);
uniform vec3 em_velocity;
uniform vec3 wind;
uniform float pixel_angle = 0.002;

// Radius of the ball in metres, before node scale.
uniform float radius = 0.35;
// Length of the tail the ball is drawn out into, in radii.
uniform float tail = 0.9;
// Depth of the wobble of the flame skin, in radii.
uniform float wobble = 0.28;
uniform float noise_scale = 2.0;
uniform float noise_speed = 1.6;
uniform int octaves = 3;
uniform float heat = 1.25;
// Share of the ball that burns white-hot in the middle.
uniform float core_size = 0.45;
// How much noise eats into the silhouette.
uniform float edge_breakup = 0.5;
uniform float flame_opacity = 0.5;
uniform float softness = 0.28;
uniform float near_fade = 0.1;
// Smallest radius on screen in pixels, so the ball still reads from far away.
uniform float min_pixels = 2.5;

uniform vec4 col_cool : source_color = vec4(0.85, 0.16, 0.02, 1.0);
uniform vec4 col_hot : source_color = vec4(1.0, 0.5, 0.08, 1.0);
uniform vec4 col_core : source_color = vec4(1.0, 0.9, 0.55, 1.0);
uniform vec4 col_smoke : source_color = vec4(0.16, 0.15, 0.15, 0.85);
uniform vec4 col_glow : source_color = vec4(1.0, 0.55, 0.2, 1.0);
uniform float emission = 2.2;
uniform float intensity = 1.0;

varying vec3 v_np;
varying float v_face;
varying float v_alpha;

void vertex() {
	float s = (length(em_x) + length(em_y) + length(em_z)) / 3.0;
	mat3 Bn = mat3(normalize(em_x), normalize(em_y), normalize(em_z));
	vec3 n0 = normalize(VERTEX + vec3(0.0, 0.0, 1.0e-6));
	v_np = n0;
	float fs = float(seed % 509);
	// The skin flows toward the tail, so the ball looks like it is being blown backwards.
	float sk = pyrolux_fbm(n0 * noise_scale * 1.3 + vec3(0.0, time * noise_speed, fs), octaves);
	float back = clamp(n0.y, 0.0, 1.0);
	vec3 shape = n0 * (1.0 + (sk - 0.5) * 2.0 * wobble);
	shape.y += back * back * tail;
	shape.xz *= mix(1.0, 0.45, back * back);
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	float dist = max(length(cam - em_origin), 0.001);
	float rr = max(radius * s, dist * pixel_angle * min_pixels);
	vec3 p = em_origin + Bn * (shape * rr);
	vec3 to_cam = cam - p;
	float pd = max(length(to_cam), 0.001);
	v_face = dot(Bn * n0, to_cam / pd);
	v_alpha = clamp(level, 0.0, 1.0) * smoothstep(near_fade * s, near_fade * s * 3.0, pd);
	VERTEX = v_alpha > 0.0 ? p : em_origin;
	NORMAL = to_cam / pd;
}

void fragment() {
	float fc = clamp(v_face, 0.0, 1.0);
	float fs = float(seed % 509);
	vec3 nc = v_np * noise_scale * 1.8 + vec3(0.0, time * noise_speed * 1.3, fs);
	float n = pyrolux_fbm(nc, octaves);
	float n2 = pyrolux_fbm(nc * 2.6 + 11.3, 2);
	// How much flame the view looks through: thick in the middle, thin and torn at the rim.
	float shell = pow(fc, 1.5);
	float field = shell * (0.55 + 0.95 * n) - edge_breakup * (1.0 - fc) * (0.5 + 0.9 * n2);
	float dens = smoothstep(0.0, softness + 0.01, field);
	float hp = heat * (0.3 + 0.8 * shell) * (0.75 + 0.5 * n);
	hp += heat * 0.5 * smoothstep(1.0 - core_size, 1.0, fc * (0.75 + 0.5 * n2));
	vec3 rgb = pyrolux_ramp(clamp(hp, 0.0, 1.15), col_cool.rgb, col_hot.rgb, col_core.rgb) * emission * intensity * dens;
	ALBEDO = rgb * v_alpha;
	ALPHA = clamp(dens * flame_opacity * v_alpha, 0.0, 1.0);
}
