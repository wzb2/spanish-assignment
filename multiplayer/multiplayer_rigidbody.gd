extends RigidBody3D

class_name MultiplayerRigidBody

@export_category("Multiplayer Synchronized Stuff")
@export var synced_position: Vector3 = Vector3.ZERO
@export var synced_rotation: Vector3 = Vector3.ZERO

var pose_interpolator: MultiplayerPoseInterpolator = MultiplayerPoseInterpolator.new()

func _ready() -> void:
	if not multiplayer.is_server():
		freeze = true
		set_collision_layer_value(1, false)
	

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		synced_position = global_position
		synced_rotation = global_rotation
	else:
		pose_interpolator.update(self, synced_position, synced_rotation, delta)
