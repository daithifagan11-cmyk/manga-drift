shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.08, 0.001) = 0.025;

void vertex() {
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
