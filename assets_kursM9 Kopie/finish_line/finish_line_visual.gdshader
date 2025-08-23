shader_type canvas_item;

uniform sampler2D finish_line_text : repeat_enable;
uniform vec2 shape_ratio = vec2(1.0);

void fragment(){
	vec2 text_uv = (vec2(1.0, 6.0) * shape_ratio);
	float text = texture(finish_line_text, UV * text_uv + vec2(TIME * 0.1, 0.0)).a;
	// COLOR.rgb = vec3(vec2(UV.x, UV.y), 1.0);
	// COLOR.rgb = vec3(vec2(UV.y, UV.x), 1.0);
	float top_mask = floor(UV.y * text_uv.y);
	float bottom_mask = floor((1.0 - UV.y) * text_uv.y);
	float text_mask = top_mask * bottom_mask;
	
	vec2 uv = UV * shape_ratio;
	float mask = step(0.0, sin(((uv.x + uv.y) - TIME * 0.1) * PI * 4.0)) * text_mask;
	mask = max(0.0, mask + text * (1.0 - text_mask));
	COLOR.a = mix(0.2, 1.0, mask);
}