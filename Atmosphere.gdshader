shader_type spatial;
render_mode unshaded, cull_front, depth_draw_always, blend_add;

uniform vec4 zenith_color : source_color = vec4(0.1, 0.2, 0.6, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.8, 0.4, 0.1, 1.0);
uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform float horizon_falloff : hint_range(0.1, 8.0) = 1.5;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;

void vertex() {
    VERTEX *= 1.05;
}

void fragment() {
    vec3 normal = normalize(NORMAL);
    vec3 view_dir = normalize(-VIEW);
    float horizon_amount = pow(1.0 - clamp(abs(dot(normal, view_dir)), 0.0, 1.0), horizon_falloff);
    float sun_wrap = pow(clamp(dot(normalize(-sun_direction), normal), 0.0, 1.0), 4.0);
    vec3 base_color = mix(zenith_color.rgb, horizon_color.rgb, horizon_amount);
    vec3 final_color = mix(base_color, horizon_color.rgb, sun_wrap);
    ALBEDO = final_color;
    ALPHA = clamp((horizon_amount + sun_wrap) * opacity, 0.0, 1.0);
}
