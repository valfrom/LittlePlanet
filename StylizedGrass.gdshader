shader_type spatial;
render_mode cull_disabled, unshaded, depth_draw_alpha_prepass, vertex_lighting;

uniform vec4 top_color : source_color = vec4(0.52, 0.88, 0.5, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.12, 0.32, 0.14, 1.0);
uniform float blade_height : hint_range(0.2, 3.0, 0.01) = 1.0;
uniform float blade_curvature : hint_range(0.0, 1.5, 0.01) = 0.45;
uniform float wind_strength : hint_range(0.0, 1.0, 0.01) = 0.25;
uniform float wind_speed : hint_range(0.1, 4.0, 0.01) = 1.2;
uniform vec2 wind_direction = vec2(1.0, 0.35);
uniform float width_softness : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float tip_brightness : hint_range(0.0, 2.0, 0.01) = 1.2;

varying float v_height;
varying float v_noise;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
    v_height = clamp(UV.y, 0.0, 1.0);
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    v_noise = hash(world_pos.xz);
    float sway = sin(TIME * wind_speed + v_noise * 6.28318);
    vec2 dir = normalize(wind_direction);
    float curve = blade_curvature * v_height * v_height;
    float sway_amount = wind_strength * (0.5 + v_noise * 0.5);
    VERTEX.xz += dir * sway * sway_amount * v_height;
    VERTEX.y *= mix(0.7, 1.4, v_noise) * blade_height;
    VERTEX.x += dir.y * curve;
    VERTEX.z -= dir.x * curve;
}

void fragment() {
    float grad = pow(v_height, 1.3);
    vec3 color = mix(bottom_color.rgb, top_color.rgb, grad);
    color *= mix(1.0, tip_brightness, grad);
    color *= COLOR.rgb;
    ALBEDO = color;
    float width_mask = 1.0 - abs(UV.x * 2.0 - 1.0);
    ALPHA = smoothstep(0.0, width_softness, width_mask);
    if (ALPHA < 0.02) {
        discard;
    }
}
