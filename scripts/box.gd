extends CSGMesh3D

class_name Box

const RADIUS: float = 0.5

@export var spawn_scene: PackedScene
@export_range(0, 32) var spawn_count: int = 1

func _ready() -> void:
	if multiplayer.is_server():
		if spawn_scene:
			for i in spawn_count:
				var fruit: RigidBody3D = spawn_scene.instantiate()
				get_tree().current_scene.add_child(fruit, true)
				
				fruit.global_position = global_position
				
				var offset: Vector3 = Vector3.UP * RADIUS
				offset = offset.rotated(Vector3.RIGHT, 0.5 * PI * randf())
				offset = offset.rotated(Vector3.UP, randf_range(-PI, PI))
				
				fruit.global_position += offset
				
