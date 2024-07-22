#[compute]
#version 450

#define PI 3.14159265358979323846f

// declare shader parameters
// we do not need to rewrite them here so the variable is readonly
layout(set = 0, binding = 0, std430) readonly buffer custom_parameters {
	float width;
	float height;
} parameters;


// declare texture inputs
// the format should match the one we specified in the Godot script
layout(set = 0, binding = 1, rgba32f) readonly uniform image2D sobel_texture;
layout(set = 0, binding = 2) uniform sampler2D lum_texture;
layout(set = 0, binding = 3, rgba32f) readonly uniform image2D ascii_edge_texture;
layout(set = 0, binding = 4, rgba32f) readonly uniform image2D ascii_texture;
layout(set = 0, binding = 5, rgba32f) writeonly restrict uniform image2D output_texture;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

const vec3 MONOCHROME_SCALE = vec3(0.298912, 0.586611, 0.114478);

int edgeCount[256];

float luminance(vec3 color) {
	return dot(color, MONOCHROME_SCALE);
}

// The code we want to execute in each invocation
void main() {
	// get texel coordinates
	ivec2 texel_coords = ivec2(gl_GlobalInvocationID.xy);
	vec2 texel_resolution = vec2(parameters.width, parameters.height);
	vec2 texel_size = 1.0 / texel_resolution;
	vec2 uv = texel_coords / texel_resolution;

	vec2 pix = 8.0 * (1.0 / texel_resolution);
	vec2 uv2 = vec2(pix.x * floor(uv.x / pix.x),
					pix.y * floor(uv.y / pix.y));

	vec4 sobel_texel = imageLoad(sobel_texture, texel_coords);
	vec2 G_texel = sobel_texel.rg;
	G_texel = normalize(G_texel);
	float magnitude = length(G_texel);
	if (magnitude < 0.0) magnitude = 0.0;
	float theta = atan(G_texel.y, G_texel.x);
	bool is_sobel = bool(1 - int(isnan(theta)));

	// calc edges
	float absTheta = abs(theta) / PI;
	int direction = -1;
	if (is_sobel) {
		// quantize angel to edge direction
		if ((0.0f <= absTheta) && (absTheta < 0.05f)) direction = 0; // VERTICAL
        else if ((0.9f < absTheta) && (absTheta <= 1.0f)) direction = 0;
        else if ((0.45f < absTheta) && (absTheta < 0.55f)) direction = 1; // HORIZONTAL
        else if (0.05f < absTheta && absTheta < 0.45f) direction = sign(theta) > 0 ? 2 : 3; // DIAGONAL 1
        else if (0.55f < absTheta && absTheta < 0.9f) direction = sign(theta) > 0 ? 3 : 2; // DIAGONAL 2
	}

	int k = 0;
	for (int i=texel_coords.x - 8; i<texel_coords.x + 8; ++i){
		for (int j=texel_coords.y - 8; j<texel_coords.y + 8; ++j){
			ivec2 new_coords = ivec2(i, j);
			vec2 new_uv = new_coords / texel_resolution;
			vec2 new_uv2 = vec2(pix.x * floor(new_uv.x / pix.x),
								pix.y * floor(new_uv.y / pix.y));
			vec4 sobel_texel = imageLoad(sobel_texture, new_coords);
			vec2 G_texel = sobel_texel.rg;
			G_texel = normalize(G_texel);
			float magnitude = length(G_texel);
			if (magnitude < 0.0) magnitude = 0.0;
			float theta = atan(G_texel.y, G_texel.x);
			bool is_sobel = bool(1 - int(isnan(theta)));

			// calc edges
			float absTheta = abs(theta) / PI * 2.0;
			int direction = -1;
			if (is_sobel && new_uv2 == uv2) {
				// quantize angel to edge direction
				//if ((0.0f <= absTheta) && (absTheta < 0.05f)) direction = 0; // VERTICAL
				//else 
				if ((0.9f < absTheta) && (absTheta <= 1.0f)) direction = 0;
				//else if ((0.45f < absTheta) && (absTheta < 0.55f)) direction = 1; // HORIZONTAL
				//else if (0.05f < absTheta && absTheta < 0.45f) {
				//	if (theta > 0.0) direction = 2; else direction = 2; // DIAGONAL 1
				//}
				else if (0.55f < absTheta && absTheta < 0.9f) {
					if (theta > 0.0) direction = 3; else direction = 2; // DIAGONAL 2
				}
			}
			edgeCount[k] = direction;
			k += 1;
		}
	}

	int commonEdgeIndex = -1;
	uint buckets[4] = {0, 0, 0, 0};
	for (int i=0; i<256;++i){
		buckets[edgeCount[i]] += 1;
	}

	uint maxValue = 0;

	for (int j=0;j<4;++j){
		if (buckets[j] > maxValue){
			commonEdgeIndex = j;
			maxValue = buckets[j];
		}
	}

	if (maxValue < 8) commonEdgeIndex = -1;

	vec3 debugEdge = vec3(0);
    if (commonEdgeIndex == 0) debugEdge = vec3(1, 0, 0);
    if (commonEdgeIndex == 1) debugEdge = vec3(0, 1, 0);
    if (commonEdgeIndex == 2) debugEdge = vec3(0, 1, 1);
    if (commonEdgeIndex == 3) debugEdge = vec3(1, 1, 0);

	vec4 lum_texel = texture(lum_texture, uv2);
	float lum = luminance(lum_texel.rgb);
	lum = floor(lum * 10) - 1;
	if (lum < 0.0) {
		lum = 0.0;
	}
	lum = lum / 10.0;
	vec4 lum_color = vec4(vec3(lum), 1.0);

	ivec2 localUV;
	localUV.x = int((texel_coords.x % 8) + lum * 80);
	localUV.y = (texel_coords.y % 8);

	vec4 ascii = imageLoad(ascii_texture, localUV);

	if (commonEdgeIndex >= 0) ascii = vec4(debugEdge, 1.0);

	// write the pixels to output texture
	imageStore(output_texture, texel_coords, ascii);
}
