shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;
uniform sampler2D VIEWPORT_TEXTURE;

uniform sampler2D ascii_tex: filter_nearest;
uniform int available_columns = 10;
uniform int max_columns = 10;

uniform sampler2D ascii_edges_tex: filter_nearest;
uniform vec2 ascii_size = vec2(8.0, 8.0);
uniform bool edge_thresholding = true;
uniform float edge_threshold: hint_range(0.0, 2.0, 0.1) = 0.3;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

float luminance(vec3 color) {
	return dot(color, MONOCHROME_SCALE) - 0.001;
}

void fragment() {
	//ascii edges
	vec2 screen_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size) * SCREEN_PIXEL_SIZE * ascii_size;
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
		//COLOR = texture(ascii_tex, ascii_uv2 + vec2(col * (float(available_columns) / float(max_columns)), 0.0));
	}
	
}


