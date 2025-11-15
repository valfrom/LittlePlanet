shader_type sky;
render_mode use_environment;

uniform vec3 sun_direction = vec3(0.0, 1.0, 0.0);
uniform vec3 horizon_color = vec3(1.0, 0.67, 0.35);
uniform vec3 zenith_color = vec3(0.1, 0.25, 0.55);
uniform float sun_scatter_power = 8.0;
uniform float sun_brightness = 2.5;

void sky()
{
    vec3 view_dir = normalize(SKY_COORDS);
    float horizon = clamp(1.0 - abs(view_dir.y), 0.0, 1.0);
    float sun_elevation = clamp(sun_direction.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 base = mix(horizon_color, zenith_color, sun_elevation);

    float sun_amount = max(dot(view_dir, normalize(sun_direction)), 0.0);
    sun_amount = pow(sun_amount, sun_scatter_power);

    vec3 color = base + sun_amount * sun_brightness;
    COLOR = vec4(color, 1.0);
}
