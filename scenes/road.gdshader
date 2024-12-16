shader_type canvas_item;

uniform float dist;

void fragment() {
	vec2 uv = vec2(UV.x, UV.y - dist);
	
	COLOR = texture(TEXTURE, uv);
}

