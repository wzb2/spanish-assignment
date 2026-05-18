extends Marker3D

class_name SpawnPlaceholder

@export var spawn_scene: PackedScene

func _ready() -> void:
	if multiplayer.is_server():
		var instantiated_scene: Node3D = spawn_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(instantiated_scene, true)
		instantiated_scene.position = position
		instantiated_scene.rotation = rotation
		
	queue_free.call_deferred()
