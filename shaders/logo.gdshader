shader_type canvas_item;

uniform float threshold : hint_range(0.0, 0.5, 0.01) = 0.0;
const vec2 middle = vec2(0.5, 0.5);

void fragment() {
	
	vec4 color = texture(TEXTURE, UV);
	float dist = distance(UV, middle);
	if (dist > threshold) {
		color.a = 0.0;
	}
	
	COLOR = color;
}
