extends Node3D

class_name GrassPusher

@export var radius: float = 1.0

func _ready() -> void:
	add_to_group("grass_pushers")
