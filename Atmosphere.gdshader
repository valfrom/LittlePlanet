shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always;

uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform float light_intensity : hint_range(0.0, 10.0, 0.01) = 1.0;
uniform float scattering_strength : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float horizon_falloff : hint_range(0.1, 10.0, 0.01) = 2.0;
uniform sampler2D day_ramp_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D dusk_ramp_texture : source_color, filter_linear, repeat_disable;

vec3 sample_ramp(sampler2D ramp, float t) {
    return texture(ramp, vec2(clamp(t, 0.0, 1.0), 0.5)).rgb;
}

void fragment() {
    vec3 view_dir = normalize(CAMERA_POSITION - WORLD_POSITION);
    vec3 normal = normalize(NORMAL);
    float horizon = pow(1.0 - abs(dot(normal, view_dir)), horizon_falloff);
    float day_mix = clamp(dot(-sun_direction, view_dir) * 0.5 + 0.5, 0.0, 1.0);

    vec3 day_color = sample_ramp(day_ramp_texture, day_mix);
    vec3 dusk_color = sample_ramp(dusk_ramp_texture, day_mix);
    vec3 color = mix(dusk_color, day_color, day_mix);

    float forward_scatter = pow(max(dot(normal, sun_direction), 0.0), scattering_strength);
    float intensity = (0.25 + horizon) * (0.5 + forward_scatter) * light_intensity;

    ALBEDO = color * intensity;
    ALPHA = clamp(horizon * scattering_strength, 0.0, 1.0);
}
