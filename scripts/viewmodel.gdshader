shader_type spatial;

uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float main_fov = 75.0;
uniform float viewmodel_fov : hint_range(30.0, 90.0) = 50.0;

void vertex() {
	float ratio = tan(radians(main_fov) * 0.5) / tan(radians(viewmodel_fov) * 0.5);
	mat4 proj = PROJECTION_MATRIX;
	proj[0][0] *= ratio;
	proj[1][1] *= ratio;
	POSITION = proj * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	POSITION.z = mix(POSITION.z, POSITION.w, 0.99);
}

void fragment() {
	ALBEDO = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}