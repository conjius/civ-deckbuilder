shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, unshaded;

uniform vec4 cloud_color : source_color = vec4(0.6, 0.6, 0.65, 0.5);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float phase = hash(origin.xz) * 6.2832;
	float drift_speed = 0.03 + hash(origin.xz + vec2(1.0)) * 0.05;
	float breathe_speed = 0.3 + hash(origin.xz + vec2(2.0)) * 0.5;
	float breathe_amp = 0.1 + hash(origin.xz + vec2(3.0)) * 0.2;

	float breathe = 1.0 + breathe_amp * sin(TIME * breathe_speed + phase);
	VERTEX *= breathe;

	float drift_x = sin(TIME * drift_speed + phase) * 0.5;
	float drift_z = cos(TIME * drift_speed * 0.7 + phase * 1.3) * 0.5;
	VERTEX.x += drift_x;
	VERTEX.z += drift_z;
}

void fragment() {
	ALBEDO = cloud_color.rgb;
	ALPHA = cloud_color.a;
}
