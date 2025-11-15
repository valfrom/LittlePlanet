shader_type spatial;

uniform float curvature = 0.0005;

void vertex() {
    vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 flat = world_pos.xz - CAMERA_POSITION.xz;
    float d = length(flat);
    world_pos.y -= curvature * d * d;
    VERTEX = (INV_WORLD_MATRIX * vec4(world_pos, 1.0)).xyz;
}
