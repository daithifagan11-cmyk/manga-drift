shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.55;
uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.0035;
uniform float film_grain_intensity : hint_range(0.0, 0.1) = 0.025;

float hash_grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);
	vec2 dir = uv - center;
	float dist = length(dir);

	// Chromatic Aberration: radial RGB separation
	vec2 ca_offset = dir * dist * chromatic_aberration;
	
	float r = texture(screen_texture, uv - ca_offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv + ca_offset).b;
	vec3 col = vec3(r, g, b);

	// Smooth radial vignette for cinematic contrast
	float vig = smoothstep(0.85, vignette_intensity, dist);
	col = mix(col * vig, col, 1.0 - vignette_opacity);

	// Animated cinematic film grain
	float grain = (hash_grain(uv + vec2(fract(TIME * 17.3), fract(TIME * 11.7))) - 0.5) * film_grain_intensity;
	col += grain;

	COLOR = vec4(col, 1.0);
}
