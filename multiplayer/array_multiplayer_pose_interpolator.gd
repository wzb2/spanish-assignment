extends Object

class_name ArrayMultiplayerPoseInterpolator

var interpolation_rate: float = 15
var interpolation_percentage: float = 1

var prev_positions: PackedVector3Array
var prev_rotations: PackedVector3Array

var target_positions: PackedVector3Array
var target_rotations: PackedVector3Array

var average_update_delta: float = 1.0/ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

var time_since_last_update: float = average_update_delta

func update(body_array: Array[Node], synchronized_positions: PackedVector3Array, synchronized_rotations: PackedVector3Array, delta: float) -> void:
	if len(synchronized_positions) == len(body_array):
		if (synchronized_positions != target_positions or synchronized_rotations != target_rotations):# and interpolation_percentage == 1.0:
			
			average_update_delta = (average_update_delta + time_since_last_update) / 2.0
			time_since_last_update = 0
			
			interpolation_rate = 1.0 / average_update_delta
			
			# Unpack and apply bone poses
			target_positions = synchronized_positions.duplicate()
			target_rotations = synchronized_rotations.duplicate()
			
			prev_positions = body_array.map(func(value: Node3D) -> Vector3: return value.global_position)
			prev_rotations = body_array.map(func(value: Node3D) -> Vector3: return value.global_rotation)
			
			interpolation_percentage = 0
			
		
		if interpolation_percentage < 1.0:
			interpolation_percentage += delta * interpolation_rate
			interpolation_percentage = min(interpolation_percentage, 1.0)
			
			time_since_last_update += delta
			
			for i: int in len(body_array):
				var body: Node3D = body_array[i]
				body.global_position = lerp(prev_positions[i], target_positions[i], interpolation_percentage)
				body.global_rotation = Basis.from_euler(prev_rotations[i]).slerp(Basis.from_euler(target_rotations[i]), interpolation_percentage).get_euler()
				
