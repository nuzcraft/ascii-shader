@tool
extends Node

@onready var ascii_shader: ColorRect = $Control/CombinedLayer/AsciiShader
@onready var sub_viewport: SubViewport = $Control/SubViewportContainer/SubViewport

func _ready() -> void:
	ascii_shader.material.set_shader_parameter("VIEWPORT_TEXTURE", sub_viewport.get_texture())
	
	# compute shader stuff
	var rd:= RenderingServer.create_local_rendering_device()
	
	var shader_file := load("res://ascii_compute.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	var input := PackedFloat32Array([1,2,3,4,5,6,7,8,9,10])
	var input_bytes:= input.to_byte_array()
	
	var buffer := rd.storage_buffer_create(input_bytes.size(), input_bytes)
	
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)
	
	var uniform_set := rd.uniform_set_create([uniform], shader, 0)
	
	var fmt := RDTextureFormat.new()
	fmt.width = 200
	fmt.height = 200
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view := RDTextureView.new()
	var output_image := Image.create(200, 200, false, Image.FORMAT_RGBAF)
	var output_tex := rd.texture_create(fmt, view, [output_image.get_data()])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	
	var output_tex_uniform_set := rd.uniform_set_create([output_tex_uniform], shader, 1)
	
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_bind_uniform_set(compute_list, output_tex_uniform_set, 1)
	rd.compute_list_dispatch(compute_list, 25, 25, 1)
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	var output_bytes := rd.buffer_get_data(buffer)
	var output := output_bytes.to_float32_array()
	print("Input: ", input)
	print("Output: ", output)
	
	var byte_data: PackedByteArray = rd.texture_get_data(output_tex, 0)
	var image:= Image.create_from_data(200, 200, false, Image.FORMAT_RGBAF, byte_data)
	image.save_png('res://image.png')
	
