shader_type spatial;
render_mode cull_disabled, alpha_scissor;

uniform vec4 bottom_color : source_color = vec4(0.094, 0.282, 0.082, 1.0);
uniform vec4 top_color : source_color = vec4(0.58, 0.82, 0.38, 1.0);
uniform float sway_strength : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float sway_speed : hint_range(0.0, 4.0, 0.01) = 1.8;
uniform float sway_height_influence : hint_range(0.1, 4.0, 0.01) = 1.5;
uniform float tint_strength : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.35;

void vertex() {
    float phase = TIME * sway_speed + INSTANCE_CUSTOM.x * TAU;
    float sway_mask = pow(clamp(UV.y, 0.0, 1.0), sway_height_influence);
    float sway = sin(phase) * sway_strength * sway_mask;
    vec2 sway_dir = normalize(vec2(INSTANCE_CUSTOM.z * 2.0 - 1.0, INSTANCE_CUSTOM.w * 2.0 - 1.0));
    VERTEX.x += sway * sway_dir.x;
    VERTEX.z += sway * sway_dir.y;
}

void fragment() {
    float gradient = clamp(UV.y, 0.0, 1.0);
    vec3 base_color = mix(bottom_color.rgb, top_color.rgb, gradient);
    float tint = mix(1.0 - tint_strength, 1.0 + tint_strength, INSTANCE_CUSTOM.y);
    ALBEDO = base_color * tint;
    ALPHA = mix(bottom_color.a, top_color.a, gradient);
    ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}
