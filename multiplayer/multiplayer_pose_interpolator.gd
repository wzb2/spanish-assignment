extends Object

class_name MultiplayerPoseInterpolator

var interpolation_rate: float = 15
var interpolation_percentage: float = 1

var prev_position: Vector3
var prev_rotation: Vector3

var target_position: Vector3
var target_rotation: Vector3

var average_update_delta: float = 1.0/ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var time_since_last_update: float = average_update_delta

func update(body: Node3D, synchronized_position: Vector3, synchronized_rotation: Vector3, delta: float) -> void:
	if (synchronized_position != target_position or synchronized_rotation != target_rotation):# and interpolation_percentage == 1.0:
		
		average_update_delta = (average_update_delta + time_since_last_update) / 2.0
		time_since_last_update = 0
		
		interpolation_rate = 1.0 / average_update_delta
		
		# Unpack and apply bone poses
		target_position = synchronized_position
		target_rotation = synchronized_rotation
		
		prev_position = body.global_position
		prev_rotation = body.global_rotation
		
		interpolation_percentage = 0
		
	
	if interpolation_percentage < 1.0:
		interpolation_percentage += delta * interpolation_rate
		interpolation_percentage = min(interpolation_percentage, 1.0)
		
		time_since_last_update += delta
		
		body.global_position = lerp(prev_position, target_position, interpolation_percentage)
		body.global_rotation = Basis.from_euler(prev_rotation).slerp(Basis.from_euler(target_rotation), interpolation_percentage).get_euler()
	
