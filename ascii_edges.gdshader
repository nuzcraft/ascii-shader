shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

float monochrome(vec3 color) {
	return dot(color, MONOCHROME_SCALE);
}

vec3 monochrome_vec3(vec3 color) {
	return vec3(monochrome(color));
}

vec3 convolution(sampler2D tex, vec2 uv, vec2 pixel_size){
	vec3 conv = vec3(0.0);
	// Gaussian blur kernel
	float gauss[25] = {
		0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625,
		0.015625, 0.0625, 0.09375, 0.0625, 0.015625, 0.0234375,
		0.09375, 0.140625, 0.09375, 0.0234375, 0.015625,
		0.0625, 0.09375, 0.0625, 0.015625, 0.00390625,
		0.015625, 0.0234375, 0.015625, 0.00390625
	};
	for (int row = 0; row < 5; row++) {
		for (int col = 0; col < 5; col++) {
			conv += monochrome_vec3(texture(tex, uv + vec2(float(col - 2), float(row - 2)) * pixel_size).rgb) * gauss[row * 5 + col];
		}
	}
	return conv;
}

void fragment() {
	
	vec3 conv = convolution(SCREEN_TEXTURE, SCREEN_UV, SCREEN_PIXEL_SIZE);
	COLOR.rgb = conv;
}

