shader_type spatial;
render_mode world_vertex_coords;

uniform float curvature = 0.0005;
uniform float patch_scale = 0.14;
uniform float detail_scale = 0.45;
uniform float wind_speed = 1.0;
uniform float wind_strength = 0.35;
uniform float gust_speed = 0.45;
uniform float gust_scale = 0.6;
uniform float grass_height = 0.6;
uniform float bend_strength = 0.25;

uniform vec3 shadow_tint = vec3(0.03, 0.15, 0.07);
uniform vec3 mid_grass_tint = vec3(0.12, 0.4, 0.18);
uniform vec3 tip_grass_tint = vec3(0.52, 0.9, 0.38);
uniform vec3 highlight_tint = vec3(0.8, 0.98, 0.7);

uniform vec3 sky_ambient = vec3(0.15, 0.27, 0.35);
uniform vec3 ground_ambient = vec3(0.05, 0.08, 0.05);
uniform float ambient_strength = 0.8;

uniform vec3 sun_direction = vec3(0.15, 0.9, 0.4);
uniform vec3 sun_color = vec3(1.0, 0.95, 0.85);
uniform float wrap_light = 0.45;
uniform vec3 rim_light_color = vec3(0.25, 0.6, 0.3);
uniform float rim_strength = 0.45;
uniform float subsurface_strength = 0.35;
uniform float specular_strength = 0.12;

varying vec3 world_pos;
varying float v_tuft_mask;
varying float v_height_mix;
varying float v_bend_amount;

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

float fbm(vec2 p)
{
    float total = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++)
    {
        total += noise(p * frequency) * amplitude;
        frequency *= 2.07;
        amplitude *= 0.5;
    }

    return total;
}

vec3 apply_curvature(vec3 pos)
{
    vec2 fl = pos.xz - CAMERA_POSITION_WORLD.xz;
    float d = length(fl);
    pos.y -= curvature * d * d;
    return pos;
}

void vertex()
{
    vec3 pos = VERTEX;
    pos = apply_curvature(pos);

    float t = TIME * wind_speed;
    vec2 patch_uv = pos.xz * patch_scale;

    float tuft_noise = fbm(patch_uv * 0.55 + vec2(t * 0.17, t * 0.11));
    float tuft_mask = smoothstep(0.25, 0.75, tuft_noise);

    float gust = fbm(patch_uv * gust_scale + vec2(TIME * gust_speed, TIME * gust_speed * 0.73));
    float blade_height = mix(0.35, 1.0, tuft_mask) * (0.6 + gust * 0.4);

    float sway_phase = dot(pos.xz, vec2(0.6, 0.85));
    float sway = sin(sway_phase + TIME * wind_speed * 1.6) * wind_strength;
    float directional_sway = cos(sway_phase * 1.3 + TIME * wind_speed * 0.8) * wind_strength * 0.35;

    pos.y += blade_height * grass_height;
    pos.xz += vec2(sway, directional_sway) * bend_strength;

    VERTEX = pos;
    world_pos = VERTEX;

    v_tuft_mask = tuft_mask;
    v_height_mix = clamp(blade_height, 0.0, 1.0);
    v_bend_amount = clamp(length(vec2(sway, directional_sway)), 0.0, 1.0);
}

vec3 compute_bent_normal(float bend_amount)
{
    vec3 bend = normalize(vec3(0.3, 1.0, 0.5));
    return normalize(NORMAL + bend * bend_amount * 0.6);
}

void fragment()
{
    vec2 world_uv = world_pos.xz * patch_scale;

    float macro_variation = fbm(world_uv * 0.4);
    float color_variation = fbm(world_uv / max(0.001, detail_scale) + vec2(0.0, TIME * 0.05));
    float lushness = clamp(macro_variation * 0.4 + color_variation * 0.6, 0.0, 1.0);

    float tuft_factor = clamp(v_tuft_mask * 0.8 + lushness * 0.2, 0.0, 1.0);
    float tip_factor = clamp(v_height_mix * 0.8 + lushness * 0.3, 0.0, 1.0);

    vec3 base_mix = mix(shadow_tint, mid_grass_tint, tuft_factor);
    vec3 grass_color = mix(base_mix, tip_grass_tint, tip_factor);
    grass_color = mix(grass_color, highlight_tint, pow(tip_factor, 4.0) * 0.35);

    vec3 bent_normal = compute_bent_normal(v_bend_amount);
    vec3 light_dir = normalize(sun_direction);
    vec3 view_dir = normalize(-VIEW);

    float wrapped_ndl = clamp((dot(bent_normal, light_dir) + wrap_light) / (1.0 + wrap_light), 0.0, 1.0);
    vec3 direct = grass_color * sun_color * wrapped_ndl;

    float sky_mix = clamp(bent_normal.y * 0.5 + 0.5, 0.0, 1.0);
    vec3 ambient = mix(ground_ambient, sky_ambient, sky_mix) * ambient_strength;
    ambient *= mix(1.0, 0.65, tuft_factor);

    float rim = pow(1.0 - clamp(dot(bent_normal, view_dir), 0.0, 1.0), 3.0) * rim_strength;
    vec3 rim_light = rim_light_color * rim;

    float subsurface = pow(1.0 - clamp(dot(-light_dir, bent_normal), 0.0, 1.0), 2.0) * subsurface_strength;
    vec3 subsurface_color = tip_grass_tint * subsurface * (0.6 + 0.4 * tip_factor);

    vec3 half_vec = normalize(light_dir + view_dir);
    float specular = pow(max(0.0, dot(bent_normal, half_vec)), 32.0) * specular_strength;

    vec3 color = grass_color * ambient + direct + rim_light + subsurface_color;
    color += specular;

    float ao_mask = clamp(1.0 - tuft_factor * 0.45, 0.3, 1.0);

    ALBEDO = color;
    ROUGHNESS = 0.6;
    METALLIC = 0.0;
    AO = ao_mask;
}
