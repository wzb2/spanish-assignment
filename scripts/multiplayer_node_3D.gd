extends Node3D

class_name MultiplayerNode3D

@export var synced_position: Vector3 = Vector3.ZERO
@export var synced_rotation: Vector3 = Vector3.ZERO

var pose_interpolator: MultiplayerPoseInterpolator = MultiplayerPoseInterpolator.new()

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		synced_position = global_position
		synced_rotation = global_rotation
	else:
		pose_interpolator.update(self, synced_position, synced_rotation, delta)
