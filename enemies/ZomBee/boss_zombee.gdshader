shader_type canvas_item;

render_mode blend_mix, unshaded;

uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;


// Stärke der Risse: 0 = keine, 1 = volle Sichtbarkeit
uniform float crack_strength : hint_range(0.0, 1.0);

// Rissmaske (Graustufenbild, wie du es bekommen hast)
uniform sampler2D crack_texture;

void fragment() {
	// Original-Textur (Helm)
	vec4 base_color = texture(TEXTURE, UV);

	// Rissmaske an selber Stelle (UV-Koordinaten)
	vec4 crack_mask = texture(crack_texture, UV);

	// Mische die Farben je nach crack_strength (Smooth Übergang)
	vec3 final_color = mix(base_color.rgb, crack_mask.rgb, crack_strength);

COLOR = vec4(final_color, base_color.a * alpha_strength);




}
