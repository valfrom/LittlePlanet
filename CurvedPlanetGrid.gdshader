shader_type spatial;
render_mode unshaded, world_vertex_coords;

uniform float curvature = 0.0005;
uniform float line_width = 0.02;

varying vec3 world_pos;

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
    vec2 f = fract(p);
    vec2 d = abs(f - 0.5);

    float line_x = step(0.5 - line_width, 0.5 - d.x);
    float line_y = step(0.5 - line_width, 0.5 - d.y);
    float line = max(line_x, line_y);

    vec3 base = vec3(0.05, 0.05, 0.12);
    vec3 line_color = vec3(0.9, 0.9, 0.9);

    ALBEDO = mix(base, line_color, line);
}
