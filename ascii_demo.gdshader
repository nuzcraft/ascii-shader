shader_type canvas_item;
//render_mode unshaded;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

uniform sampler2D ascii_tex: filter_nearest;
uniform vec2 ascii_size = vec2(8.0, 16.0);
uniform int available_columns = 10;
uniform int max_columns = 16;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

vec2 scale(vec2 uv, float x, float y){
	mat2 scale = mat2(vec2(x,0.0), vec2(0.0,y));
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

void fragment() {
	//COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 screen_uv = floor(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size) * SCREEN_PIXEL_SIZE * ascii_size ;
	if (ascii_size.x != ascii_size.y) {
		screen_uv = scale(screen_uv, 0.95, 0.95);
	}
	vec4 color = texture(SCREEN_TEXTURE, screen_uv);
	//COLOR = color;
	
	vec2 ascii_uv = fract(SCREEN_UV / SCREEN_PIXEL_SIZE / ascii_size);
	ascii_uv.x = ascii_uv.x / float(max_columns);
	float col = floor(dot(color.rgb, MONOCHROME_SCALE) * float(available_columns)) / float(available_columns);
	
	COLOR = texture(ascii_tex, ascii_uv + vec2(col * (float(available_columns) / float(max_columns)), 0.0));
	
}
