shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.9);
uniform float density : hint_range(20.0, 180.0) = 85.0;
uniform float line_length : hint_range(0.1, 1.0) = 0.65;
uniform float inner_radius : hint_range(0.1, 0.8) = 0.32;
uniform float outer_radius : hint_range(0.5, 2.0) = 1.05;
uniform float speed : hint_range(5.0, 60.0) = 36.0;
uniform vec2 center_offset = vec2(0.0, 0.0);

// Pseudo-random hash
float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

// 1D noise for dynamic ray jitter
float noise1d(float p) {
	float fl = floor(p);
	float fc = fract(p);
	return mix(hash(fl), hash(fl + 1.0), fc);
}

void fragment() {
	if (intensity > 0.005) {
		// Centered UV with dynamic lateral focal offset
		vec2 uv = (UV - vec2(0.5)) - center_offset;
		float dist = length(uv);
		float angle = atan(uv.y, uv.x); // -PI to PI
		
		// Normalize angle to [0..1]
		float norm_angle = (angle + 3.14159265359) / (2.0 * 3.14159265359);
		
		// Rapidly cycling time seed for animated manga streaks
		float time_seed = floor(TIME * speed);
		float ray_coord = norm_angle * density + hash(time_seed * 1.7) * 7.0;
		
		// Tapered manga ink lines
		float ray = step(0.60, fract(ray_coord));
		float ray_variation = hash(floor(ray_coord) + time_seed * 3.1);
		
		// Dynamic length based on line_length & intensity
		float dynamic_inner = mix(outer_radius * 0.9, inner_radius * (1.2 - line_length * 0.4), clamp(intensity, 0.0, 1.0));
		
		// Radial falloff: clear center, dense edges
		float rad_mask = smoothstep(dynamic_inner, outer_radius, dist);
		
		// Combine ray, distance mask, and dynamic intensity
		float alpha = ray * rad_mask * ray_variation * intensity * line_color.a;
		COLOR = vec4(line_color.rgb, alpha);
	} else {
		COLOR = vec4(0.0);
	}
}
