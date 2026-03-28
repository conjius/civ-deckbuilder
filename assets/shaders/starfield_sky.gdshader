shader_type sky;

uniform float star_density : hint_range(0.0, 0.01) = 0.003;
uniform float star_brightness : hint_range(0.0, 1.0) = 0.6;
uniform float glow_size : hint_range(0.0, 0.02) = 0.006;
uniform float glow_opacity : hint_range(0.0, 0.5) = 0.15;
uniform float shimmer_speed : hint_range(0.0, 1.0) = 0.3;
uniform vec3 bg_top : source_color = vec3(0.06, 0.06, 0.08);
uniform vec3 bg_bottom : source_color = vec3(0.12, 0.12, 0.14);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec2 uv = SKY_COORDS;
	vec3 bg = mix(bg_bottom, bg_top, uv.y);

	float stars = 0.0;
	float glow = 0.0;
	float cell_size = 0.015;
	vec2 grid = floor(uv / cell_size);

	for (int dx = -1; dx <= 1; dx++) {
		for (int dy = -1; dy <= 1; dy++) {
			vec2 cell = grid + vec2(float(dx), float(dy));
			float r = hash(cell);
			if (r > star_density * 100.0) continue;

			vec2 star_pos = (cell + vec2(hash(cell + 0.5), hash(cell + 1.7))) * cell_size;
			float dist = length(uv - star_pos);

			float brightness_var = hash(cell + 3.3) * 0.6 + 0.4;
			float phase = hash(cell + 7.1) * TAU;
			float shimmer = sin(TIME * shimmer_speed + phase) * 0.5 + 0.5;
			shimmer = shimmer * shimmer;
			float intensity = brightness_var * shimmer * star_brightness;

			float point = smoothstep(cell_size * 0.08, 0.0, dist) * intensity;
			stars += point;

			float g = smoothstep(glow_size, 0.0, dist) * intensity * glow_opacity;
			glow += g;
		}
	}

	COLOR = bg + vec3(stars + glow);
}
