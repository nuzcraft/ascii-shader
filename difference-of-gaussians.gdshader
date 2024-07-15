shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;
//uniform sampler2D VIEWPORT_TEXTURE;
uniform int _kernel: hint_range(1, 10, 1) = 5;
uniform float _sigma: hint_range(0.1, 5.0, 0.1) = 2.0;
uniform float _k: hint_range(0.1, 5.0, 0.1) = 1.6;
uniform float _k2: hint_range(0.1, 5.0, 0.1) = 1.6;
uniform float _tau: hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool _thresholding = true;
uniform float _threshold: hint_range(0.001, 0.1, 0.001) = 0.005;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

float luminance(vec3 color) {
	return dot(color, MONOCHROME_SCALE);
}

float gaussian(float sigma, float pos) {
	return (1.0 / sqrt(2.0 * PI * sigma * sigma)) * exp(-(pos * pos) / (2.0 * sigma * sigma));
}

void fragment() {
	
	//COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	vec2 blur = vec2(0.0);
	vec2 kernalSum = vec2(0.0);
	for (int x=-_kernel; x<=_kernel; x++){
		float lum = luminance(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(float(x), 0.0)*SCREEN_PIXEL_SIZE).rgb);
		vec2 gauss = vec2(gaussian(_sigma, float(x)), gaussian(_sigma * _k, float(x)));
		blur += lum * gauss;
		kernalSum += gauss;
	}

	//COLOR.rg = blur / kernalSum;
	
	vec2 blur2 = vec2(0.0);
	vec2 kernalSum2 = vec2(0.0);
	for (int y=-_kernel; y<=_kernel; y++){
		float lum = luminance(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, float(y))*SCREEN_PIXEL_SIZE).rgb);
		vec2 gauss = vec2(gaussian(_sigma, float(y)), gaussian(_sigma * _k, float(y)));
		blur += lum * gauss;
		kernalSum += gauss;
	}
	blur /= kernalSum;
	//COLOR.rg = blur;
	
	float diff = blur.r - _tau * blur.g;
	//COLOR.rgb = vec3(diff);
	
	if (_thresholding){
		if (diff >= _threshold){
		diff = 1.0;
		}
	}
	COLOR.rgb = vec3(diff);
}

