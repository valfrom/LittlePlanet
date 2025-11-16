shader_type spatial;
render_mode world_vertex_coords;

uniform float curvature = 0.0005;
uniform float patch_scale = 0.08;
uniform float blade_detail_scale = 0.3;
uniform float highlight_strength = 0.35;
uniform vec3 grass_color = vec3(0.11, 0.45, 0.19);
uniform vec3 dark_grass_color = vec3(0.04, 0.23, 0.09);
uniform vec3 highlight_color = vec3(0.33, 0.6, 0.18);

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

void fragment()
{
    vec2 p = world_pos.xz;
    float macro_variation = noise(p * patch_scale);
    float blade_detail = noise(p * patch_scale / blade_detail_scale);
    float grass_mix = clamp(macro_variation * 0.6 + blade_detail * 0.4, 0.0, 1.0);

    vec3 base_color = mix(dark_grass_color, grass_color, grass_mix);

    float slope = clamp(1.0 - NORMAL.y, 0.0, 1.0);
    vec3 final_color = mix(base_color, highlight_color, slope * highlight_strength);

    ALBEDO = final_color;
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}
