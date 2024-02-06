shader_type spatial;
render_mode cull_disabled;

group_uniforms ShearAttributes;
uniform float horizontal_shear = 0.0;
uniform float vertical_shear = 0.0;
group_uniforms;

uniform sampler2D sprite_texture : source_color, filter_linear_mipmap_anisotropic;

void vertex() {
	float temp = VERTEX.x + (VERTEX.y * horizontal_shear);
	VERTEX.y = VERTEX.y + (VERTEX.x * vertical_shear);
	VERTEX.x = temp;
}

void fragment() {
	vec4 color = texture(sprite_texture, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
