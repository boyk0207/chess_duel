shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
void fragment() {
	float columns = sin(floor(UV.x*16.0)*5.7 + UV.y*24.0 - TIME*6.0);
	float wave = smoothstep(0.0,0.85,columns);
	vec3 water = mix(vec3(0.16,0.54,0.76),vec3(0.79,0.96,1.0),wave*0.78);
	ALBEDO = water;
}
