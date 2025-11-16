shader_type spatial;
render_mode cull_disabled, vertex_lighting;

uniform vec3 wind_direction = vec3(1.0, 0.0, 0.2);
uniform float wind_speed : hint_range(0.0, 10.0, 0.01) = 1.2;
uniform float bend_strength : hint_range(0.0, 2.0, 0.01) = 0.35;
uniform float soil_height : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform vec4 top_color : source_color = vec4(0.2, 0.66, 0.27, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.28, 0.19, 0.07, 1.0);
uniform float color_variation_strength : hint_range(0.0, 1.0, 0.01) = 0.18;
uniform float bend_variation_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

varying float v_height_ratio;
varying float v_color_variation;

void vertex() {
        float height_ratio = clamp(UV.y, 0.0, 1.0);
        v_height_ratio = height_ratio;
        float color_variation = (INSTANCE_CUSTOM.r - 0.5) * 2.0 * color_variation_strength;
        v_color_variation = color_variation;

        vec3 dir = wind_direction;
        float dir_length = length(dir);
        if (dir_length > 0.0001) {
                dir = dir / dir_length;
        } else {
                dir = vec3(0.0, 0.0, 0.0);
        }

        float bend_mul = mix(1.0 - bend_variation_strength, 1.0 + bend_variation_strength, INSTANCE_CUSTOM.g);
        float phase = INSTANCE_CUSTOM.b * TAU;
        float sway = sin(TIME * wind_speed + phase);
        float bend = sway * bend_strength * bend_mul;

        VERTEX += dir * bend * height_ratio;
        NORMAL = normalize(NORMAL + dir * bend * (0.5 + height_ratio * 0.5));
}

void fragment() {
float soil_mask = smoothstep(0.0, soil_height, v_height_ratio);
float mix_value = clamp(soil_mask + v_color_variation, 0.0, 1.0);
vec4 grass_color = mix(bottom_color, top_color, mix_value);
ALBEDO = clamp(grass_color.rgb, vec3(0.0), vec3(1.0));
ALPHA = grass_color.a;
}
