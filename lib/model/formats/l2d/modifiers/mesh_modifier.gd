extends "res://lib/model/modifier.gd"

var mesh: MeshInstance2D
@export var color_override: bool = false :
	set(v):
		mesh.set_instance_shader_parameter("color_override", v)
@export var multiply_color: Color = Color.WHITE :
	set(v):
		mesh.set_instance_shader_parameter("color_multiply", v)

@export var screen_color: Color = Color.BLACK :
	set(v):
		mesh.set_instance_shader_parameter("color_screen", v)
@export var pinnable: bool = true

func _init(m: MeshInstance2D) -> void:
	mesh = m
