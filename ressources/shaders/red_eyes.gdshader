shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D eyes_shape;
uniform float red_color : hint_range(0.0, 1.0) = 1.0;
uniform float alpha_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    vec4 red_color_mask = texture(eyes_shape, UV);
    float mask = red_color_mask.r;
    vec3 red_tint = vec3(1.0, 0.0, 0.0);

    // final_color mischt Original und Rot-Ton basierend auf Maske und Stärke
    vec3 final_color = mix(base_color.rgb, red_tint, mask * red_color);

    COLOR = vec4(final_color, base_color.a * alpha_strength);
}
