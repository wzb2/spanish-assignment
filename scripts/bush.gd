extends Area3D

class_name Bush

const RADIUS: float = 0.5

@export var fruit_scene: PackedScene
@export_range(0, 32) var fruit_count: int = 1

func _ready() -> void:
	if multiplayer.is_server():
		if fruit_scene:
			for i in fruit_count:
				var fruit: RigidBody3D = fruit_scene.instantiate()
				get_tree().current_scene.add_child(fruit, true)
				
				fruit.global_position = global_position
				
				var offset: Vector3 = Vector3.UP * RADIUS
				offset = offset.rotated(Vector3.RIGHT, 0.5 * PI * randf())
				offset = offset.rotated(Vector3.UP, randf_range(-PI, PI))
				
				fruit.global_position += offset
				
				fruit.freeze = true
				
				fruit.set_collision_layer_value(1, false)
