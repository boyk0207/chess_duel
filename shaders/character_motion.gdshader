shader_type spatial;
render_mode cull_disabled;
uniform sampler2D palette : source_color, filter_nearest;
uniform float clock = 0.0;
uniform float stride = 0.0;
uniform float curl = 0.0;
uniform float flash = 0.0;
uniform int species = 0;
void vertex() {
	vec3 p = VERTEX;
	// OBJ coordinates are the original normalized voxel coordinates.
	float low = 1.0 - smoothstep(0.08, 0.40, p.y);
	if (species == 1) {
		// Monitor: diagonal leg pairs plus a trailing tail.
		float side = smoothstep(-0.12, 0.12, p.x) * 2.0 - 1.0;
		float pair = side * (1.0 - 2.0 * smoothstep(-0.18, 0.18, p.z));
		float step = sin(clock) * pair;
		float feet = low * (1.0 - smoothstep(0.46, 0.67, p.z));
		p.z += step * 0.075 * feet * stride;
		p.y += max(0.0, step) * 0.055 * feet * stride;
		p.x += sin(clock * 0.65 - p.z * 4.0) * smoothstep(0.12, 0.79, p.z) * (0.025 + 0.085 * stride);
	} else if (species == 2 || species == 4 || species == 5) {
		// Serpentine silhouettes: smoothly bend the low, rear portion.
		float tail = smoothstep(-0.10, 0.48, p.z) * (1.0 - smoothstep(0.25, 0.65, p.y));
		p.x += sin(clock - p.z * 6.0) * tail * (0.012 + stride * 0.065);
		p.z -= tail * curl * 0.085;
	} else {
		// Upright voxel models: lower-body gait without detached faces.
		float leg = smoothstep(-0.09, 0.09, p.x) * 2.0 - 1.0;
		float step = sin(clock) * leg;
		float bottom = species == 6 ? 1.0 - smoothstep(0.27, 0.57, p.y) : low;
		float rear = 1.0 - smoothstep(0.14, 0.42, p.z);
		p.z += step * bottom * rear * stride * 0.062;
		p.y += max(0.0, step) * bottom * rear * stride * 0.047;
	}
	VERTEX = p;
}
void fragment() {
	vec3 tex = texture(palette, UV).rgb;
	ALBEDO = tex;
	ROUGHNESS = 0.9;
	EMISSION = vec3(1.0, 0.65, 0.12) * flash * 1.5;
}
