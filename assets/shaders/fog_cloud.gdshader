shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, unshaded;

uniform vec4 cloud_color : source_color = vec4(0.6, 0.6, 0.65, 0.28);
uniform float hex_radius : hint_range(0.5, 2.0) = 1.15;
uniform float fade_band : hint_range(0.0, 0.5) = 0.3;
uniform float wave_amp : hint_range(0.0, 0.3) = 0.12;

// INSTANCE_CUSTOM encodes:
//   x = phase offset (0-TAU)
//   y = drift speed
//   z = breathe speed
//   w = breathe amplitude

varying vec3 world_pos;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hex_distance(vec2 p) {
	p = abs(p);
	return max(p.x * 0.866025 + p.y * 0.5, p.y);
}

void vertex() {
	float phase = INSTANCE_CUSTOM.x;
	float drift_speed = INSTANCE_CUSTOM.y;
	float breathe_speed = INSTANCE_CUSTOM.z;
	float breathe_amp = INSTANCE_CUSTOM.w;

	float breathe = 1.0 + breathe_amp * sin(TIME * breathe_speed + phase);
	VERTEX *= breathe;

	float drift_x = sin(TIME * drift_speed + phase) * 0.5;
	float drift_z = cos(TIME * drift_speed * 0.7 + phase * 1.3) * 0.5;
	VERTEX.x += drift_x;
	VERTEX.z += drift_z;

	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float phase = INSTANCE_CUSTOM.x;
	float brightness = 0.85 + hash2(vec2(phase, phase * 0.7)) * 0.3;
	ALBEDO = cloud_color.rgb * brightness;

	// Hex boundary with wavy edge
	vec2 hex_center = vec2(
		round(world_pos.x / 1.5) * 1.5,
		round(world_pos.z / 1.732) * 1.732
	);
	vec2 local = vec2(world_pos.x, world_pos.z) - hex_center;
	float dist = hex_distance(local);

	float angle = atan(local.y, local.x);
	float wave = sin(angle * 6.0 + hash2(hex_center) * 6.28) * wave_amp;
	float wavy_radius = hex_radius + wave;

	float edge_fade = 1.0 - smoothstep(wavy_radius - fade_band, wavy_radius, dist);

	ALPHA = cloud_color.a * edge_fade;
}
