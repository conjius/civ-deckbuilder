shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, unshaded;

uniform vec4 cloud_color : source_color = vec4(0.6, 0.6, 0.65, 0.5);

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
}

void fragment() {
	ALBEDO = cloud_color.rgb;
	ALPHA = cloud_color.a;
}
