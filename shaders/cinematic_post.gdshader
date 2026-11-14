shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.55;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0035;
uniform float film_grain_intensity : hint_range(0.0, 0.1) = 0.025;
uniform float rain_streaks_intensity : hint_range(0.0, 1.0) = 0.38;

float hash_grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Procedural screen-space raindrop streaks running down camera lens
vec2 get_rain_streak_refraction(vec2 uv, float t) {
	vec2 offset = vec2(0.0);
	
	// Large dripping water droplets
	vec2 grid1 = uv * vec2(18.0, 3.5);
	grid1.y += t * 1.8;
	vec2 cell1 = floor(grid1);
	float h1 = hash_grain(cell1);
	vec2 f1 = fract(grid1) - 0.5;
	
	// Droplet shape with vertical trail
	f1.y *= 1.4;
	float d1 = length(f1);
	if (h1 > 0.68 && d1 < 0.28) {
		float strength = smoothstep(0.28, 0.02, d1) * (1.0 - smoothstep(0.0, 0.28, d1));
		offset += normalize(f1 + 0.0001) * strength * 0.015;
	}

	// Fast rain streamlets / micro-streaks
	vec2 grid2 = uv * vec2(42.0, 6.0);
	grid2.y += t * 3.4;
	vec2 cell2 = floor(grid2);
	float h2 = hash_grain(cell2 + 7.3);
	vec2 f2 = fract(grid2) - 0.5;
	f2.y *= 2.0;
	float d2 = length(f2);
	if (h2 > 0.78 && d2 < 0.22) {
		float strength2 = smoothstep(0.22, 0.02, d2);
		offset += normalize(f2 + 0.0001) * strength2 * 0.009;
	}

	return offset;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);
	vec2 dir = uv - center;
	float dist = length(dir);

	// Dynamic screen-space rain streaks and droplets
	vec2 rain_refract = get_rain_streak_refraction(uv, TIME) * rain_streaks_intensity;

	// Chromatic Aberration: radial RGB separation combined with rain refraction
	vec2 ca_offset = dir * dist * chromatic_aberration;
	vec2 sample_uv = uv + rain_refract;
	
	float r = texture(screen_texture, sample_uv - ca_offset).r;
	float g = texture(screen_texture, sample_uv).g;
	float b = texture(screen_texture, sample_uv + ca_offset).b;
	vec3 col = vec3(r, g, b);

	// Subtle raindrop specular highlight sheen
	if (length(rain_refract) > 0.001) {
		col += vec3(0.06, 0.09, 0.12) * smoothstep(0.001, 0.008, length(rain_refract)) * rain_streaks_intensity;
	}

	// Smooth radial vignette for cinematic contrast
	float vig = smoothstep(0.85, vignette_intensity, dist);
	col = mix(col * vig, col, 1.0 - vignette_opacity);

	// Animated cinematic film grain
	float grain = (hash_grain(uv + vec2(fract(TIME * 17.3), fract(TIME * 11.7))) - 0.5) * film_grain_intensity;
	col += grain;

	COLOR = vec4(col, 1.0);
}
