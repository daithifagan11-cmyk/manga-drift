shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.11, 0.12, 0.14, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float roughness : hint_range(0.0, 1.0) = 0.85;
uniform float normal_scale : hint_range(0.0, 10.0) = 3.2;
uniform vec2 uv_scale = vec2(40.0, 40.0);

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

void fragment() {
	vec2 uv = UV * uv_scale;

	// High-frequency porous asphalt grain & micro-pebbles
	float grain1 = fbm(uv * 3.5);
	float grain2 = noise2(uv * 12.0);
	vec2 bump = vec2(dFdx(grain1 + grain2 * 0.4), dFdy(grain1 + grain2 * 0.4)) * normal_scale;

	vec3 norm_offset = vec3(bump, 0.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(norm_offset, 0.0)).xyz + NORMAL);

	// Subtle aggregate color variation on dry asphalt
	float aggregate = mix(0.92, 1.08, grain1);
	ALBEDO = albedo_color.rgb * aggregate;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = 0.35;
}
