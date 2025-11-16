shader_type spatial;
render_mode world_vertex_coords;

uniform float curvature = 0.0005;
uniform float patch_scale = 0.12;
uniform float detail_scale = 0.55;
uniform float highlight_strength = 0.55;
uniform float wind_speed = 0.9;
uniform float wind_strength = 0.25;
uniform vec3 base_shadow_color = vec3(0.02, 0.17, 0.07);
uniform vec3 base_grass_color = vec3(0.07, 0.4, 0.18);
uniform vec3 tip_grass_color = vec3(0.33, 0.73, 0.31);
uniform vec3 highlight_color = vec3(0.66, 0.95, 0.62);
uniform vec3 rim_light_color = vec3(0.12, 0.5, 0.2);
uniform vec3 sun_direction = vec3(0.15, 0.9, 0.4);

varying vec3 world_pos;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex()
{
    world_pos = VERTEX;

    vec2 fl = VERTEX.xz - CAMERA_POSITION_WORLD.xz;
    float d = length(fl);
    VERTEX.y -= curvature * d * d;
}

float fbm(vec2 p)
{
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 3; i++)
    {
        total += noise(p * frequency) * amplitude;
        frequency *= 2.13;
        amplitude *= 0.5;
    }

    return total;
}

void fragment()
{
    vec2 p = world_pos.xz * patch_scale;

    float wind_wave = sin(world_pos.x * 0.3 + TIME * wind_speed) * wind_strength;
    wind_wave += cos(world_pos.z * 0.35 + TIME * wind_speed * 1.3) * wind_strength * 0.5;
    p += vec2(wind_wave, wind_wave * 0.6);

    float macro_variation = noise(p);
    float detail_variation = fbm(p / detail_scale + vec2(0.0, TIME * 0.03));
    float lushness = clamp(macro_variation * 0.5 + detail_variation * 0.5, 0.0, 1.0);

    float slope = clamp(1.0 - NORMAL.y, 0.0, 1.0);
    float tip_emphasis = smoothstep(0.5, 1.0, lushness + slope * 0.35);

    vec3 base_mix = mix(base_shadow_color, base_grass_color, lushness);
    vec3 grass = mix(base_mix, tip_grass_color, tip_emphasis);

    vec3 light_dir = normalize(sun_direction);
    float sun_wrap = clamp((dot(NORMAL, light_dir) + 0.4) / 1.4, 0.0, 1.0);
    vec3 sunlight = highlight_color * pow(sun_wrap, 3.0) * highlight_strength;

    vec3 view_dir = normalize(-VIEW);
    float rim = pow(1.0 - clamp(dot(NORMAL, view_dir), 0.0, 1.0), 2.0);
    vec3 rim_light = rim_light_color * rim * 0.5;

    vec3 final_color = grass + sunlight + rim_light;

    ALBEDO = final_color;
    ROUGHNESS = 0.75;
    METALLIC = 0.0;
    AO = clamp(1.0 - slope * 0.35, 0.2, 1.0);
}
