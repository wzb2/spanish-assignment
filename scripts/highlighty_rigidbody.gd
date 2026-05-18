extends MultiplayerRigidBody

class_name HighlightyRigidbody

@export var mesh_instances: Array[MeshInstance3D]
@export var interact_area: Area3D

var highlight_material: BaseMaterial3D = preload("res://materials/highlight_material.tres")

func _process(_delta: float) -> void:
	var level: Level = get_tree().current_scene
	var local_player: Player = level.local_player
	if local_player:
		if local_player.interact_raycast.get_collider() == interact_area:
			enable_outline()
		else:
			disable_outline()
	


func enable_outline() -> void:
	for i in mesh_instances:
		i.material_overlay = highlight_material
	
func disable_outline() -> void:
	for i in mesh_instances:
		i.material_overlay = null
