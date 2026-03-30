shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, unshaded;

uniform vec4 cloud_color : source_color = vec4(0.6, 0.6, 0.65, 0.5);
uniform float hex_radius : hint_range(0.5, 2.0) = 1.15;
uniform float fade_band : hint_range(0.0, 0.6) = 0.4;
uniform float wave_amp : hint_range(0.0, 0.3) = 0.08;

// INSTANCE_CUSTOM encodes:
//   x = phase offset (0-TAU)
//   y = drift speed
//   z = breathe speed
//   w = breathe amplitude

varying vec3 world_pos_static;

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

	// Capture static world position before animation
	world_pos_static = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Breathing
	float breathe = 1.0 + breathe_amp * sin(TIME * breathe_speed + phase);
	VERTEX *= breathe;

	// Drift
	float drift_x = sin(TIME * drift_speed + phase) * 0.5;
	float drift_z = cos(TIME * drift_speed * 0.7 + phase * 1.3) * 0.5;
	VERTEX.x += drift_x;
	VERTEX.z += drift_z;
}

void fragment() {
	float phase = INSTANCE_CUSTOM.x;
	float brightness = 0.85 + hash2(vec2(phase, phase * 0.7)) * 0.3;
	ALBEDO = cloud_color.rgb * brightness;

	// Use static position for hex boundary (not drifted)
	vec2 pos = vec2(world_pos_static.x, world_pos_static.z);

	// Snap to nearest hex center (axial grid)
	float col = round(pos.x / 1.5);
	float row = round((pos.y - col * 0.866025) / 1.732);
	vec2 hex_center = vec2(col * 1.5, row * 1.732 + col * 0.866025);

	vec2 local = pos - hex_center;
	float dist = hex_distance(local);

	// Smooth wavy boundary with multiple frequencies
	float angle = atan(local.y, local.x);
	float seed = hash2(hex_center) * 6.28;
	float wave = sin(angle * 6.0 + seed) * 0.5
		+ sin(angle * 12.0 + seed * 2.3) * 0.3
		+ sin(angle * 3.0 + seed * 0.7) * 0.2;
	float wavy_radius = hex_radius + wave * wave_amp;

	float edge_fade = 1.0 - smoothstep(
		wavy_radius - fade_band, wavy_radius, dist
	);

	// Sphere falloff from blob center
	float sphere_alpha = cloud_color.a;

	ALPHA = sphere_alpha * edge_fade;
}
