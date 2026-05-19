extends Node3D

class_name World

@export var spawn_orgin_marker: Marker3D

var water: Array[Node]

var spawn_pos: Vector3:
	get():
		return spawn_orgin_marker.global_position if spawn_orgin_marker else Vector3.ZERO

func _ready() -> void:
	water = get_tree().get_nodes_in_group("water")
