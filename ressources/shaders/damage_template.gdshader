shader_type canvas_item;

render_mode blend_mix, unshaded;

uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;


// Stärke der Risse: 0 = keine, 1 = volle Sichtbarkeit
uniform float red_color : hint_range(0.0, 1.0);

// Rissmaske (Graustufenbild, wie du es bekommen hast)
uniform sampler2D eyes_shape;

void fragment() {
	// Original-Textur (Helm)
	vec4 base_color = texture(TEXTURE, UV);

	// Rotfärbung an selber Stelle (UV-Koordinaten)
	vec4 red_color_mask = texture(eyes_shape, UV);

	// Mische die Farben je nach crack_strength (Smooth Übergang)
	vec3 final_color = mix(base_color.rgb, eyes_shape.rgb, red_color);

COLOR = vec4(final_color, base_color.a * alpha_strength);




}
