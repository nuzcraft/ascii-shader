extends Node

#@onready var dog_shader: ColorRect = $Control/SobelViewportContainer/SobelSubViewport/DOGLayer/DOGShader
@onready var packed_luminance_shader: ColorRect = $Control/LumViewportContainer/LumSubViewport/PackedLuminanceLayer/PackedLuminanceShader
#@onready var ascii_shader: ColorRect = $Control/SobelViewportContainer/SobelSubViewport/CombinedLayer/AsciiShader
@onready var base_sub_viewport: SubViewport = $Control/BaseViewportContainer/BaseSubViewport
@onready var sobel_sub_viewport: SubViewport = $Control/SobelViewportContainer/SobelSubViewport
@onready var lum_sub_viewport: SubViewport = $Control/LumViewportContainer/LumSubViewport
@onready var final_texture: TextureRect = $FinalTexture

@onready var dog_layer: CanvasLayer = $Control/BaseViewportContainer/BaseSubViewport/DOGLayer
@onready var sobel_layer: CanvasLayer = $Control/BaseViewportContainer/BaseSubViewport/SobelLayer

const BOWSER = preload("res://assets/bowser.jpg")
const BOWER_LUM = preload("res://assets/bower_lum.png")
const BOWSER_SOBEL = preload("res://assets/bowser_sobel.png")
const EDGES_ASCII = preload("res://assets/edgesASCII.png")
const ACEROLA_ASCII = preload("res://assets/acerola_ascii.png")

@export var image_format := Image.FORMAT_RGBAF
var image_size: Vector2
#var base_image: Image
var sobel_image: Image
var lum_image: Image
var ascii_edge_image: Image
var ascii_image: Image
# SHADER VARIABLES
@export_file("*.glsl") var shader_path: String = "res://ascii_compute.glsl"
var compute_shader: ComputeHelper
var shader_groups: Vector3i
var sobel_texture: ImageUniform
var lum_texture: SamplerUniform
var ascii_edge_texture: ImageUniform
var ascii_texture: ImageUniform
var output_texture: ImageUniform
var shader_parameters_buffer: StorageBufferUniform
var shader_parameters: Array = [0.0, 0.0]

func _ready() -> void:
	#dog_layer.hide()
	#sobel_layer.hide()
	#await RenderingServer.frame_post_draw
	#var base_texture : ViewportTexture = base_sub_viewport.get_texture()
	#dog_shader.material.set_shader_parameter("VIEWPORT_TEXTURE", base_texture)
	#packed_luminance_shader.material.set_shader_parameter("VIEWPORT_TEXTURE", base_texture)
	#ascii_shader.material.set_shader_parameter("VIEWPORT_TEXTURE", base_texture)
	#sobel_image = sobel_sub_viewport.get_texture().get_image()
	#lum_image = lum_sub_viewport.get_texture().get_image()
	
	#REGION OLD
	#var width: int = base_texture.get_width()
	#var height: int = base_texture.get_height()
	#
	## compute shader stuff
	#var rd:= RenderingServer.create_local_rendering_device()
	#
	#var shader_file := load("res://ascii_compute.glsl")
	#var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	#var shader := rd.shader_create_from_spirv(shader_spirv)
	#
	#var fmt := RDTextureFormat.new()
	#fmt.width = width
	#fmt.height = height
	#fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	#fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	#
	#var view := RDTextureView.new()
	#var output_image := Image.create(width, height, false, Image.FORMAT_RGBAF)
	#var output_tex := rd.texture_create(fmt, view, [output_image.get_data()])
	#var output_tex_uniform := RDUniform.new()
	#output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	#output_tex_uniform.binding = 0
	#output_tex_uniform.add_id(output_tex)
	#
	#var output_tex_uniform_set := rd.uniform_set_create([output_tex_uniform], shader, 0)
	#
	#var sampler_state := RDSamplerState.new()
	#var sampler = rd.sampler_create(sampler_state)
	#var sobel_image = sobel_texture.get_image()
	#sobel_image.convert(Image.FORMAT_RGBAF)
	#
	#var sampler_fmt = RDTextureFormat.new()
	#sampler_fmt.width = sobel_image.get_width()
	#sampler_fmt.height = sobel_image.get_height()
	#sampler_fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	#sampler_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	#
	#var sobel_view = RDTextureView.new()
	#var sobel_tex = rd.texture_create(sampler_fmt, sobel_view, [sobel_image.get_data()])
	#var sobel_tex_uniform := RDUniform.new()
	#sobel_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	#sobel_tex_uniform.binding = 0
	#sobel_tex_uniform.add_id(sampler)
	#sobel_tex_uniform.add_id(sobel_tex)
	##
	#var sobel_tex_uniform_set := rd.uniform_set_create([sobel_tex_uniform], shader, 1)
	#
	#var pipeline := rd.compute_pipeline_create(shader)
	#var compute_list := rd.compute_list_begin()
	#rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	#rd.compute_list_bind_uniform_set(compute_list, output_tex_uniform_set, 0)
	#rd.compute_list_bind_uniform_set(compute_list, sobel_tex_uniform_set, 1)
	#rd.compute_list_dispatch(compute_list, width / 8, height / 8, 1)
	#rd.compute_list_end()
	#
	#rd.submit()
	#rd.sync()
	#
	#var byte_data: PackedByteArray = rd.texture_get_data(output_tex, 0)
	#var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBAF, byte_data)
	#image.save_png('res://image.png')
	
	sobel_image = BOWSER_SOBEL.get_image()
	lum_image = BOWER_LUM.get_image()
	ascii_edge_image = EDGES_ASCII.get_image()
	ascii_image = ACEROLA_ASCII.get_image()
	sobel_image.convert(image_format)
	lum_image.convert(image_format)
	ascii_edge_image.convert(image_format)
	ascii_image.convert(image_format)
	
	RenderingServer.call_on_render_thread(init_shader)
	pass
	
func init_shader():
	# convert image to specified format
	#dog_layer.show()
	#sobel_layer.show()
	#$Control/LumViewportContainer.show()
	#await RenderingServer.frame_post_draw
	#sobel_image = base_sub_viewport.get_texture().get_image()
	#sobel_image.convert(image_format)
	#sobel_image.save_png("res://sobel.png")
	#lum_image = lum_sub_viewport.get_texture().get_image()
	#lum_image.convert(image_format)
	#lum_image.save_png("res://lum.png")
	#ascii_edge_image.convert(image_format)
	#ascii_image.convert(image_format)
	image_size = sobel_image.get_size()
	shader_parameters[0] = float(image_size.x)
	shader_parameters[1] = float(image_size.y)
	
	final_texture.texture = Texture2DRD.new()
	
	compute_shader = ComputeHelper.create(shader_path)
	
	sobel_texture = ImageUniform.create(sobel_image)
	lum_texture = SamplerUniform.create(lum_image)
	ascii_edge_texture = ImageUniform.create(ascii_edge_image)
	ascii_texture = ImageUniform.create(ascii_image)
	output_texture = ImageUniform.create(sobel_image)
	final_texture.texture.texture_rd_rid = output_texture.texture
	
	var x_groups = (image_size.x - 1) / 8 + 1
	var y_groups = (image_size.y - 1) / 8 + 1
	var z_groups = 1
	shader_groups = Vector3i(x_groups, y_groups, z_groups)
	
	shader_parameters_buffer = StorageBufferUniform.create(PackedFloat32Array([image_size.x, image_size.y]).to_byte_array())
	
	compute_shader.add_uniform_array([shader_parameters_buffer, sobel_texture, lum_texture, ascii_edge_texture, ascii_texture, output_texture])
	compute_shader.run(shader_groups)

func update_shader(shader_parameters):
	# sent shader_parameters to shader
	shader_parameters_buffer.update_data(PackedFloat32Array(shader_parameters).to_byte_array())
	compute_shader.run(shader_groups)
	output_texture.get_image().save_png("res://test.png")
	#var tex: Texture2D = ImageTexture.create_from_image(output_texture.get_image())
	#final_texture.texture = tex
	final_texture.texture.texture_rd_rid = output_texture.texture
	print("updating shader")

func _process(delta: float) -> void:
	RenderingServer.call_on_render_thread(update_shader)
	#REGION OLD
	#var image = load("res://image.png")
	#$Control/FinalViewportContainer/FinalSubViewport/FinalTexture.texture = image
	#pass
	
 
#func _on_timer_timeout() -> void:
	#update_shader(shader_parameters)
	#print("shader_updated")
	#$Timer.start(3)
