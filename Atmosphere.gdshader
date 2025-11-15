shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_add;

uniform vec4 zenith_color : source_color = vec4(0.1, 0.2, 0.6, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.8, 0.4, 0.1, 1.0);
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform float horizon_falloff : hint_range(0.1, 8.0) = 1.5;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;
uniform float star_intensity : hint_range(0.0, 5.0) = 0.6;
uniform float star_density : hint_range(0.0, 1.0) = 0.035;

varying vec3 world_position;
varying vec3 local_direction;

void vertex() {
    VERTEX *= 1.05;
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    local_direction = normalize(VERTEX);
}

void fragment() {
    vec3 normal = normalize(NORMAL);
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
    float horizon_amount = pow(1.0 - clamp(abs(dot(normal, view_dir)), 0.0, 1.0), horizon_falloff);
    float sun_wrap = pow(clamp(dot(normalize(-sun_direction), normal), 0.0, 1.0), 4.0);
    vec3 base_color = mix(zenith_color.rgb, horizon_color.rgb, horizon_amount);
    vec3 final_color = mix(base_color, horizon_color.rgb, sun_wrap);

    // Procedurally generate twinkling stars when the sun influence is low.
    vec3 star_dir = normalize(local_direction);
    vec3 hash_position = fract(star_dir * 43758.5453);
    float hash_value = fract(dot(hash_position, vec3(12.9898, 78.233, 37.719)) * 43758.5453);
    float star_mask = step(1.0 - star_density, hash_value);
    vec3 star_color = vec3(star_intensity * star_mask);
    final_color += star_color;

    ALBEDO = final_color;
    ALPHA = clamp((horizon_amount + sun_wrap) * opacity, 0.0, 1.0);
}
