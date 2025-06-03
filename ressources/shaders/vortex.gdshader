shader_type canvas_item;

uniform float vortex_strength : hint_range(0.0, 5.0) = 2.0;
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float speed : hint_range(-10.0, 10.0) = 1.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);

    if (dist < radius) {
        float t = (radius - dist) / radius;
        float angle = vortex_strength * t * TIME * speed;
        float s = sin(angle);
        float c = cos(angle);

        // !!! Korrigierte Zeile:
        mat2 rot = mat2( vec2(c,  s),
                         vec2(-s, c) );

        uv = rot * uv;
    }

    uv += vec2(0.5);
    COLOR = texture(TEXTURE, uv);
}
