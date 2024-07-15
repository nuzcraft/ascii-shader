shader_type canvas_item;

uniform sampler2D VIEWPORT_TEXTURE;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

float luminance(vec3 color) {
	return dot(color, MONOCHROME_SCALE);
}

void fragment() {
	float lum = luminance(texture(VIEWPORT_TEXTURE, SCREEN_UV).rgb);
	COLOR = vec4(texture(VIEWPORT_TEXTURE, SCREEN_UV).rgb, lum);
}
