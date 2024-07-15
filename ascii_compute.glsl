#[compute]
#version 450

#define PI 3.14159265358979323846f

// declare shader parameters
// we do not need to rewrite them here so the variable is readonly
layout(set = 0, binding = 0, std430) readonly buffer custom_parameters {
	float brightness;
	float contrast;
} parameters;


// declare texture inputs
// the format should match the one we specified in the Godot script
layout(set = 0, binding = 1, rgba32f) readonly uniform image2D sobel_texture;
layout(set = 0, binding = 2, rgba32f) readonly uniform image2D lum_texture;
layout(set = 0, binding = 3, rgba32f) writeonly restrict uniform image2D output_texture;

// The code we want to execute in each invocation
void main() {
	// get texel coordinates
	ivec2 texel_coords = ivec2(gl_GlobalInvocationID.xy);

	// read pixels from input texture
	vec4 sobel_texel = imageLoad(sobel_texture, texel_coords);
	vec4 lum_texel = imageLoad(lum_texture, texel_coords);

	// write the pixels to output texture
	imageStore(output_texture, texel_coords, lum_texel);
}
