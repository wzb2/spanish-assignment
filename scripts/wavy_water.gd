@tool
extends Water

class_name WavyWater

@onready var material: ShaderMaterial = mesh.material

@onready var height_scale: float = material.get_shader_parameter("height_scale")
@onready var speed: float = material.get_shader_parameter("speed")


func get_height(pos: Vector2) -> float:
	var base_height: float = super.get_height(pos)
	var time: float = speed * Time.get_ticks_msec() / 1000.0
	
	var h: float = -abs(sin(time + pos.x + pos.y)) + 0.5
	
	return base_height + h * height_scale
	
