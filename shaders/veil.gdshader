shader_type canvas_item;

uniform float threshold : hint_range(0.0, 0.7, 0.01) = 0.0;
uniform vec3 veil_color : source_color = vec3(0.0, 0.0, 0.0);

const vec2 middle = vec2(0.5, 0.5);

void fragment() {
	float dist = distance(UV, middle);
	vec4 color = vec4(veil_color, 1.0);
	if (dist > threshold) {
		color.a = 1.0;
	}
	else {
		color.a = 0.0;
	}
	
	COLOR = color;
}

