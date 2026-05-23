extends AnimatableBody3D

class_name Train

var max_speed: float = 10

@export var distance: float = 147.0
@export var speed_curve: Curve

@onready var player_detection_area: PlayerDetectionArea = $PlayerDetectionArea
@onready var starting_pos: Vector3 = global_position
var going: bool = false
@onready var target_pos: Vector3 = starting_pos + global_basis.z * distance

const READY_TIME: float = 2
var time_ready: float = 0

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if player_detection_area.all_players_in_area():
			time_ready += delta
		else:
			time_ready = 0
			
		if time_ready > READY_TIME and not going:
			going = true
		elif going:
			var dist_from_start: float = (global_position - starting_pos).length()
			var total_dist: float = (target_pos - starting_pos).length()
			
			var percent_complete: float = dist_from_start / total_dist
			constant_linear_velocity = global_basis.z * speed_curve.sample(percent_complete) * max_speed
			global_position += constant_linear_velocity * delta
			if dist_from_start > total_dist:
				constant_linear_velocity = Vector3.ZERO
				going = false
				target_pos = starting_pos
				starting_pos = global_position
				time_ready = -20
				max_speed *= -1
			
			
			#for b: Node3D in player_detection_area.get_overlapping_bodies():
				#if b is RigidBody3D or b is PhysicalBone3D:
					#b.linear_velocity += constant_linear_velocity * 0.01
				
			
			
