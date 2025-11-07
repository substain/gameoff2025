shader_type canvas_item;


uniform float start_min = 0.0;
uniform float start_max = 0.0;

uniform float end_min = 1.0;
uniform float end_max = 1.0;

void fragment() {
	vec4 color_start = smoothstep(start_min, start_max, vec4(UV.x));
	vec4 color_end = smoothstep(end_max, end_min, vec4(UV.x));
	if (start_min == start_max){
		color_start = vec4(1);
	}

	if (end_min == end_max){
		color_end = vec4(1);
		if (end_min == start_min && end_min == start_max){
			color_end = vec4(0);
		}
	}

	//vec4 color = max(color_start, color_end);
	vec4 color = color_start * color_end;
	//color = 1.0 - color;
	COLOR = color;
}