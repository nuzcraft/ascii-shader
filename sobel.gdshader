shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

const mat3 sobel_y = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)	
);

void fragment() {
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	mat3 surrounding_red;
	mat3 surrounding_green;
	for (int x = 0; x < 3; x++){
		vec3 red;
		vec3 green;
		for (int y = 0; y < 3; y++){
			vec2 uv = SCREEN_UV + vec2(float(x - 1), float(y - 1)) * SCREEN_PIXEL_SIZE;
			red[y] = texture(SCREEN_TEXTURE, uv).r;
			green[y] = texture(SCREEN_TEXTURE, uv).g;
		}
		surrounding_red[x] = red;
		surrounding_green[x] = green;
	}
	float gx = dot(sobel_x[0], surrounding_red[0]) + dot(sobel_x[1], surrounding_red[1]) + dot(sobel_x[2], surrounding_red[2]);
	float gy = dot(sobel_y[0], surrounding_green[0]); + dot(sobel_y[1], surrounding_green[1]) + dot(sobel_y[2], surrounding_green[2]);
	COLOR.rgb = vec3(gx, gy, 0.0);
}
