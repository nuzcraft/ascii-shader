shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

uniform sampler2D ascii_tex: filter_nearest;
uniform vec2 ascii_size = vec2(8.0, 8.0);
uniform bool thresholding = true;
uniform float threshold: hint_range(0.0, 2.0, 0.1) = 0.3;

vec2 scale(vec2 uv, float x, float y){
	mat2 scale = mat2(vec2(x,0.0), vec2(0.0,y));
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

void fragment() {
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 screen_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size) * SCREEN_PIXEL_SIZE * ascii_size ;
	if (ascii_size.x != ascii_size.y) {
		screen_uv = scale(screen_uv, 0.95, 0.95);
	}
	vec4 color = texture(SCREEN_TEXTURE, screen_uv);
	COLOR = color;
	
	vec2 sobel_field = vec2(color.r, color.g);
	sobel_field = normalize(sobel_field);
	
	float magnitude = length(vec2(color.r, color.g));
	float theta = atan(sobel_field.g, sobel_field.r);
	if (thresholding){
		if (magnitude < threshold) {
			theta = 0.0 / 0.0;
		}
	}
	vec2 sobel_angle = vec2(theta, 1.0 - float(isnan(theta)));
	COLOR.rg = vec2(((sobel_angle.r / PI) + 1.0) / 2.0, sobel_angle.g);
	
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
	
	COLOR = texture(ascii_tex, ascii_uv + vec2(float(direction) * 0.2 + 0.2, 0.0));
}
