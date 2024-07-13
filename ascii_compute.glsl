#[compute]
#version 450

#define PI 3.14159265358979323846f

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// A binding to the buffer we create in our script
layout(set = 0, binding = 0, std430) restrict buffer MyDataBuffer {
	float data[];
}
my_data_buffer;

// layout(set = 1, binding = 0) uniform sampler2D INPUT_TEXTURE;

layout(set = 1, binding = 0, rgba32f) uniform image2D OUTPUT_TEXTURE;

// The code we want to execute in each invocation
void main() {
	// gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
	my_data_buffer.data[gl_GlobalInvocationID.x] *= PI;

	// messing with colors
	vec4 color = vec4(gl_GlobalInvocationID.x / 200.0, 1.0 - (gl_GlobalInvocationID.y / 200.0), 0.0, 0.0);
	ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
	imageStore(OUTPUT_TEXTURE, texel, color);
}
