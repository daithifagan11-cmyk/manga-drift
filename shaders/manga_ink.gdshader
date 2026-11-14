shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(0.82, 0.84, 0.86, 1.0);
uniform vec4 ink_shadow_color : source_color = vec4(0.03, 0.04, 0.06, 1.0);
uniform vec4 ink_highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Stepped Lighting Thresholds
uniform float highlight_threshold : hint_range(0.0, 1.0, 0.01) = 0.55;
uniform float midtone_threshold : hint_range(-0.5, 0.5, 0.01) = 0.05;
uniform float shadow_threshold : hint_range(-1.0, 0.0, 0.01) = -0.35;
uniform float step_softness : hint_range(0.001, 0.1, 0.002) = 0.02;

// Manga Halftone Screentone - disabled by default for solid crisp matte finish
uniform bool enable_screentone = false;
uniform float screentone_density : hint_range(40.0, 400.0, 5.0) = 180.0;
uniform float screentone_dot_size : hint_range(0.1, 1.0, 0.02) = 0.45;
uniform float screentone_angle_deg : hint_range(0.0, 90.0, 1.0) = 45.0;

// Toon Specular - subtle matte glint
uniform float specular_strength : hint_range(0.0, 2.0, 0.05) = 0.25;
uniform float specular_size : hint_range(0.8, 0.999, 0.005) = 0.97;

vec2 rotate_uv(vec2 uv, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return vec2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
}

float get_halftone_dot(vec2 screen_uv) {
	float rad = radians(screentone_angle_deg);
	vec2 rot = rotate_uv(screen_uv, rad);
	vec2 grid = fract(rot * screentone_density) - 0.5;
	return step(length(grid), screentone_dot_size * 0.5);
}

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 0.92;
	SPECULAR = 0.04;
}

void light() {
	float n_dot_l = dot(NORMAL, LIGHT);
	float atten = ATTENUATION;
	float raw_light = n_dot_l * atten;

	float is_highlight = smoothstep(highlight_threshold - step_softness, highlight_threshold + step_softness, raw_light);
	float is_midtone = smoothstep(midtone_threshold - step_softness, midtone_threshold + step_softness, raw_light);
	float is_lit = smoothstep(shadow_threshold - step_softness, shadow_threshold + step_softness, raw_light);

	float tone = 0.0;
	if (is_highlight > 0.5) {
		tone = 1.0;
	} else if (is_midtone > 0.5) {
		float st = enable_screentone ? get_halftone_dot(SCREEN_UV) : 0.65;
		tone = mix(0.4, 0.85, st);
	} else if (is_lit > 0.5) {
		float st = enable_screentone ? get_halftone_dot(SCREEN_UV) : 0.25;
		tone = mix(0.1, 0.4, st);
	} else {
		tone = 0.0;
	}

	vec3 half_vector = normalize(VIEW + LIGHT);
	float n_dot_h = dot(NORMAL, half_vector);
	float spec_band = step(specular_size, n_dot_h) * specular_strength * atten;

	vec3 lit_color = ALBEDO * clamp(LIGHT_COLOR * ink_highlight_color.rgb, vec3(0.0), vec3(1.0));
	vec3 shadow_color = ink_shadow_color.rgb * ALBEDO;
	
	vec3 stepped_diffuse = mix(shadow_color, lit_color, tone);
	vec3 specular_add = clamp(LIGHT_COLOR * spec_band, vec3(0.0), vec3(0.3));

	// Clamped to 0.75 maximum so white paint never exceeds HDR glow threshold
	DIFFUSE_LIGHT += clamp(stepped_diffuse + specular_add, vec3(0.0), vec3(0.75));
}
