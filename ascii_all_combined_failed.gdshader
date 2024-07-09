shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;
uniform sampler2D VIEWPORT_TEXTURE;
uniform int _kernel: hint_range(1, 10, 1) = 5;
uniform float _sigma: hint_range(0.1, 5.0, 0.1) = 2.0;
uniform float _k: hint_range(0.1, 5.0, 0.1) = 1.6;
uniform float _k2: hint_range(0.1, 5.0, 0.1) = 1.6;
uniform float _tau: hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool _dog_thresholding = true;
uniform float _dog_threshold: hint_range(0.001, 0.1, 0.001) = 0.005;

uniform sampler2D ascii_tex: filter_nearest;
uniform int available_columns = 10;
uniform int max_columns = 10;

uniform sampler2D ascii_edges_tex: filter_nearest;
uniform vec2 ascii_size = vec2(8.0, 8.0);
uniform bool edge_thresholding = true;
uniform float edge_threshold: hint_range(0.0, 2.0, 0.1) = 0.3;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);
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

float luminance(vec3 color) {
	return dot(color, MONOCHROME_SCALE);
}

float gaussian(float sigma, float pos) {
	return (1.0 / sqrt(2.0 * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0 * sigma * sigma));
}

vec3 dog(vec2 uv, vec2 pixel_size){
	vec2 blur = vec2(0.0);
	vec2 kernalSum = vec2(0.0);
	for (int x=-_kernel; x<=_kernel; x++){
		float lum = luminance(texture(SCREEN_TEXTURE, uv + vec2(float(x), 0.0)*pixel_size).rgb);
		vec2 gauss = vec2(gaussian(_sigma, float(x)), gaussian(_sigma * _k, float(x)));
		blur += lum * gauss;
		kernalSum += gauss;
	}

	//COLOR.rg = blur / kernalSum;
	
	vec2 blur2 = vec2(0.0);
	vec2 kernalSum2 = vec2(0.0);
	for (int y=-_kernel; y<=_kernel; y++){
		float lum = luminance(texture(SCREEN_TEXTURE, uv + vec2(0.0, float(y))*pixel_size).rgb);
		vec2 gauss = vec2(gaussian(_sigma, float(y)), gaussian(_sigma * _k, float(y)));
		blur += lum * gauss;
		kernalSum += gauss;
	}
	blur /= kernalSum;
	//COLOR.rg = blur;
	
	float diff = blur.r - _tau * blur.g;
	//COLOR.rgb = vec3(diff);
	
	if (_dog_thresholding){
		if (diff >= _dog_threshold){
		diff = 1.0;
		}
	}
	vec3 dog_color = vec3(diff);
	return dog_color;
}

vec2 sobel(vec2 uv, vec2 pixel_size){
	mat3 surrounding_red;
	mat3 surrounding_green;
	for (int x = 0; x < 3; x++){
		vec3 red;
		vec3 green;
		for (int y = 0; y < 3; y++){
			vec2 new_uv = uv + vec2(float(x - 1), float(y - 1)) * pixel_size;
			red[y] = dog(new_uv, pixel_size).r;
			green[y] = dog(new_uv, pixel_size).g;
		}
		surrounding_red[x] = red;
		surrounding_green[x] = green;
	}
	float gx = dot(sobel_x[0], surrounding_red[0]) + dot(sobel_x[1], surrounding_red[1]) + dot(sobel_x[2], surrounding_red[2]);
	float gy = dot(sobel_y[0], surrounding_green[0]); + dot(sobel_y[1], surrounding_green[1]) + dot(sobel_y[2], surrounding_green[2]);
	return vec2(gx, gy);
}

void fragment() {
	vec3 og_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	//COLOR.rgb = og_color;
	
	// difference of gaussians
	vec3 dog_color = dog(SCREEN_UV, SCREEN_PIXEL_SIZE);
	//COLOR.rgb = dog_color;
	
	// sobel 
	vec2 sobel_color = sobel(SCREEN_UV, SCREEN_PIXEL_SIZE);
	//COLOR.rgb = vec3(sobel_color, 0.0);
	
	//ascii edges
	vec2 screen_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size) * SCREEN_PIXEL_SIZE * ascii_size;
	//vec4 color = texture(SCREEN_TEXTURE, screen_uv);
	//vec2 color = sobel(screen_uv, SCREEN_PIXEL_SIZE);
	//vec2 color = sobel(SCREEN_UV, SCREEN_PIXEL_SIZE);
	vec3 color = texture(SCREEN_TEXTURE, screen_uv).rgb;
	//COLOR.rgb = color;
	
	vec2 sobel_field = vec2(color.r, color.g);
	sobel_field = normalize(sobel_field);
	
	float magnitude = length(vec2(color.r, color.g));
	float theta = atan(sobel_field.g, sobel_field.r);
	if (edge_thresholding){
		if (magnitude < edge_threshold) {
			theta = 0.0 / 0.0;
		}
	}
	vec2 sobel_angle = vec2(theta, 1.0 - float(isnan(theta)));
	//COLOR.rgb = vec3(((sobel_angle.r / PI) + 1.0) / 2.0, sobel_angle.g, 0);
	
	float absTheta = abs(theta) / PI;
	int direction = -1;
	if (sobel_angle.g > 0.0){
		if ((0.0f <= absTheta) && (absTheta < 0.05f)) direction = 0; // VERTICAL
        else if ((0.9f < absTheta) && (absTheta <= 1.0f)) direction = 0;
        else if ((0.45f < absTheta) && (absTheta < 0.55f)) direction = 1; // HORIZONTAL
        else if (0.05f < absTheta && absTheta < 0.45f) direction = sign(theta) > 0.0 ? 3 : 2; // DIAGONAL 1
        else if (0.55f < absTheta && absTheta < 0.9f) direction = sign(theta) > 0.0 ? 2 : 3; // DIAGONAL 2
	}
	
	vec2 ascii_uv = fract(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size);
	ascii_uv.x = (1.0 - ascii_uv.x) / 5.0;
	
	vec3 pixellated_color = texture(VIEWPORT_TEXTURE, screen_uv).rgb;
	vec2 ascii_uv2 = fract(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size);
	ascii_uv2.x /= float(max_columns);
	float col = floor(luminance(pixellated_color) * float(available_columns)) / float(available_columns);
	
	
	
	if (direction >= 0){
		COLOR = texture(ascii_edges_tex, ascii_uv + vec2(float(direction) * 0.2 + 0.2, 0.0));
	} else {
		COLOR = texture(ascii_tex, ascii_uv2 + vec2(col * (float(available_columns) / float(max_columns)), 0.0));
	}
	
}


