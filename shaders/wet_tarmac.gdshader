shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.08, 0.09, 0.12, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.45;
uniform float roughness : hint_range(0.0, 1.0) = 0.55;
uniform float wetness : hint_range(0.0, 1.0) = 0.98;
uniform float normal_scale : hint_range(0.0, 10.0) = 4.8;
uniform vec2 uv_scale = vec2(40.0, 40.0);
uniform float ripple_speed : hint_range(0.1, 5.0) = 2.2;
uniform float ripple_density : hint_range(1.0, 60.0) = 28.0;
uniform float puddle_ratio : hint_range(0.0, 1.0) = 0.45;

// Hash function for procedural noise
float hash2(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Bilinear interpolated 2D noise
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash2(i + vec2(0.0, 0.0)), hash2(i + vec2(1.0, 0.0)), u.x),
		mix(hash2(i + vec2(0.0, 1.0)), hash2(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

// 3-Octave Fractal Brownian Motion for rich asphalt macro & micro surface
float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8));
	for (int i = 0; i < 3; i++) {
		val += amp * noise2(p);
		p = rot * p * 2.15;
		amp *= 0.48;
	}
	return val;
}

// Multi-phase procedural expanding rain ripples
vec3 get_rain_ripples(vec2 uv, float t) {
	vec2 p = uv * ripple_density;
	vec2 cell = floor(p);
	vec2 f = fract(p) - 0.5;

	float h = hash2(cell);
	float phase = fract(t * ripple_speed + h);
	float dist = length(f);

	float wave_radius = phase * 0.48;
	float wave = sin((dist - wave_radius) * 36.0) * exp(-phase * 3.5) * smoothstep(0.48, 0.05, dist);

	vec2 grad = normalize(f + 0.0001) * wave * (1.0 - phase);
	return vec3(grad * 2.0, 1.0);
}

void fragment() {
	vec2 uv = UV * uv_scale;

	// High-frequency porous asphalt grain & micro-pebbles
	float grain1 = fbm(uv * 3.5);
	float grain2 = noise2(uv * 12.0);
	vec2 bump = vec2(dFdx(grain1 + grain2 * 0.4), dFdy(grain1 + grain2 * 0.4)) * normal_scale;

	// Organic puddle depth map (crevices and depressions collect rainwater)
	float puddle_raw = fbm(uv * 0.35);
	float puddle = smoothstep(1.0 - puddle_ratio - 0.12, 1.0 - puddle_ratio + 0.12, puddle_raw);

	// Puddle meniscus / surface tension edge normal
	vec2 puddle_edge_bump = vec2(dFdx(puddle), dFdy(puddle)) * 2.5;

	// Rain ripple normal map
	vec3 ripples = get_rain_ripples(uv * 0.45, TIME);

	// Surface water streak distortion
	float streak = sin(uv.y * 8.0 + TIME * 1.5 + grain1 * 4.0) * 0.03 * wetness;

	// Blend asphalt pebble normals with smooth water puddle and ripples
	// In puddles, rough asphalt is flattened by standing water, leaving smooth mirror ripples
	vec3 norm_offset = vec3(bump * (1.0 - puddle * 0.85) + puddle_edge_bump, streak)
	                 + (ripples - vec3(0.0, 0.0, 1.0)) * (wetness * (0.3 + puddle * 0.7));

	NORMAL = normalize((VIEW_MATRIX * vec4(norm_offset, 0.0)).xyz + NORMAL);

	// Water-soaked tarmac darkening (optical light trapping in wet porous asphalt)
	float soak_darkening = mix(1.0, 0.58, clamp(puddle * 1.3, 0.0, 1.0) * wetness);
	ALBEDO = albedo_color.rgb * soak_darkening;

	// High metallic specular response for vibrant streetlamp and car brakelight reflections
	METALLIC = mix(metallic, 0.52, puddle * wetness);

	// Ultra-realistic roughness: glossy mirror puddles (0.035) vs damp textured tarmac (0.55)
	ROUGHNESS = mix(roughness, 0.035, puddle * wetness);

	// High specular sheen
	SPECULAR = 0.88;

	// Clearcoat water film layer (simulates the thin film of rainwater over asphalt)
	CLEARCOAT = wetness * 0.95;
	CLEARCOAT_ROUGHNESS = mix(0.12, 0.02, puddle);
}
