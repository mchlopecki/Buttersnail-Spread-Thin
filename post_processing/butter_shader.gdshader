shader_type canvas_item;

group_uniforms ButterOptions;
uniform vec4 outline_color : source_color;
uniform vec4 butter_color : source_color;
group_uniforms;

uniform sampler2D screen_texture : repeat_disable, filter_linear;

void fragment() {

    COLOR = textureLod(screen_texture, UV, 0.0);
    COLOR.a = clamp(COLOR.r + COLOR.g, 0, 1);
}