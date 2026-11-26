shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 grass_color : source_color = vec4(0.38,0.59,0.23,1.0);
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 cell = floor(world_pos.xz * 2.0);
	float noise = fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
	float path = smoothstep(0.7, 1.45, min(abs(world_pos.x),abs(world_pos.z)));
	vec3 green = grass_color.rgb * (0.91 + noise*0.17);
	vec3 worn = mix(green, vec3(0.57,0.49,0.30),0.20);
	ALBEDO = mix(worn, green, path);
	ROUGHNESS = 1.0;
}
