@tool
extends Node

@onready var ascii_shader: ColorRect = $Control/CombinedLayer/AsciiShader
@onready var sub_viewport: SubViewport = $Control/SubViewportContainer/SubViewport

func _ready() -> void:
	ascii_shader.material.set_shader_parameter("VIEWPORT_TEXTURE", sub_viewport.get_texture())
