shader_type spatial;
render_mode unshaded, world_vertex_coords, cull_disabled;

uniform float curvature = 0.0005;
uniform vec3 grass_dark = vec3(0.02, 0.2, 0.05);
uniform vec3 grass_light = vec3(0.35, 0.6, 0.2);
uniform float patch_scale = 0.15;
uniform float wind_speed = 0.8;
uniform float wind_strength = 0.25;

varying vec3 world_pos;

void vertex()
{
    world_pos = VERTEX;

    vec2 fl = VERTEX.xz - CAMERA_POSITION_WORLD.xz;
    float d = length(fl);
    VERTEX.y -= curvature * d * d;
}

float hash(vec2 p)
{
    // Cheap pseudo random generator for color breakup.
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment()
{
    vec2 p = world_pos.xz * patch_scale;

    float base_noise = smooth_noise(p);
    float detail_noise = smooth_noise(p * 4.0);

    float variation = mix(base_noise, detail_noise, 0.35);

    float wind_phase = dot(world_pos.xz, vec2(0.02, 0.04)) + TIME * wind_speed;
    float wind = sin(wind_phase) * 0.5 + 0.5;
    float wind_light = wind * wind_strength;

    float lushness = clamp(variation + wind_light, 0.0, 1.0);

    vec3 color = mix(grass_dark, grass_light, lushness);

    ALBEDO = color;
}
