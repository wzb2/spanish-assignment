extends Dummy

const ATTACK_MOVEMENT_SPEED: float = 45
const FOLLOW_MOVEMENT_SPEED: float = 12
var movement_speed: float = FOLLOW_MOVEMENT_SPEED
const TURN_LERP_RATE: float = 0.05
const FLOATING_MOVEMENT_SPEED: float = 10
const WALK_ANIMATION_THRESHOLD_VEL: float = 0.1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var physical_bone_head: DamagableBone = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Head"

@onready var targeting_component: TargetingComponent = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Head/TargetingComponent"

var movement_vector: Vector3 = Vector3.ZERO

var on_floor: bool = false

enum State {IDLE, FOLLOWING, ATTACKING, RETREATING}

var time_in_state: float = 0

var current_state: State = State.IDLE:
	set(value):
		time_in_state = 0
		current_state = value
		

func _ready() -> void:
	super._ready()
	
	for b in physics_bones:
		targeting_component.raycast_to_player.add_exception(b)
		
	

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	#print(health_component.hp)
	upadte_state_machine()
	movement()

func movement() -> void:
	# check if is on floor
	on_floor = is_on_floor()
	#print(root_bone.linear_velocity.length())
	var strength_multiplier: float = (1.0 - min(health_component.get_weakness_percentage(), 1))
	
	var acceleration: Vector3 = movement_vector.normalized() * (movement_speed if on_floor else FLOATING_MOVEMENT_SPEED) * strength_multiplier * _delta
	
	#if acceleration:
		#animated_skeleton.global_rotation.y = lerp_angle(animated_skeleton.global_rotation.y, Vector2(acceleration.z, acceleration.x).angle(), TURN_LERP_RATE)
	
	add_movement_bone_velocity(acceleration, 0.001)
	
	const ANGULAR_STIFFNESS_SMOOTHING_WEIGHT: float = 0.004
	
	var root_bone_speed: float = root_bone.linear_velocity.length()
	
	if root_bone_speed > WALK_ANIMATION_THRESHOLD_VEL and movement_vector:
		animation_player.play("Guy - Animated/Walk")
		animation_player.speed_scale = root_bone_speed
	else:
		animation_player.play("Guy - Animated/Idle")
		animation_player.speed_scale = 1
	
	
	
	var angular_spring_stiffness_setpoint: float = default_angular_spring_stiffness * strength_multiplier
	current_angular_spring_stiffness = max(lerp(current_angular_spring_stiffness, angular_spring_stiffness_setpoint, ANGULAR_STIFFNESS_SMOOTHING_WEIGHT), 0)
	


func upadte_state_machine() -> void:
	const NOTICE_TIME: float = 1.0
	#const SEARCH_TIME: float = 15.0
	#
	#const ATTTACK_PREPARE_TIME: float = 0.5
	#const ATTTACK_TIME: float = 1.5
	#const ATTTACK_COOLDOWN: float = 1.0
	#
	#const LOOK_AHEAD_TIME: float = 0.25
	
	#const JUMP_FLOOR_ANGLE: float = deg_to_rad(5)
	#const JUMP_VEL: Vector3 = Vector3(0, 3, 0)
	
	time_in_state += _delta
	
	if health_component.is_conscious():
		match current_state:
			State.IDLE:
				movement_vector = Vector3.ZERO
				if targeting_component.current_target and targeting_component.target_visible:
						if targeting_component.target_visible_time > NOTICE_TIME:
							current_state = State.FOLLOWING
				else:
					targeting_component.select_target()
				
			State.FOLLOWING:
				movement_speed = FOLLOW_MOVEMENT_SPEED
				var pos_difference: Vector3 = targeting_component.current_target.root_bone.global_position - root_bone.global_position
				
				movement_vector = Vector3(pos_difference.x, 0, pos_difference.z).normalized()
				
				if pos_difference.length() > 20:
					current_state = State.IDLE
				elif pos_difference.length() < 7:
					current_state = State.ATTACKING
				#if asin(pos_difference.y / pos_difference.length()) >= JUMP_FLOOR_ANGLE:
					#if on_floor:
						#add_movement_bone_velocity(JUMP_VEL)
				
			State.ATTACKING:
				movement_speed = ATTACK_MOVEMENT_SPEED
				var pos_difference: Vector3 = targeting_component.current_target.root_bone.global_position - root_bone.global_position
				
				if pos_difference.length() < 1:
					current_state = State.RETREATING
					movement_vector = -Vector3(pos_difference.x, 0, pos_difference.z).normalized()
				elif pos_difference.length() > 8:
					current_state = State.FOLLOWING
			State.RETREATING:
				if time_in_state > 0.6:
					current_state = State.IDLE
			#State.AT_TARGET:
				#movement_vector = Vector3.ZERO
				#if not targeting_component.is_target_alive():
					#current_state = State.IDLE
					#targeting_component.select_target()
				#elif targeting_component.target_visible:
					#current_state = State.PREPARING_ATTACK
				#else:
					#current_state = State.SEARCHING
				#
			#State.SEARCHING:
				#movement_vector = Vector3(targeting_component.current_target_last_seen_velocity.x, 0, targeting_component.current_target_last_seen_velocity.z).normalized()
				#
				#if targeting_component.target_visible:
					#current_state = State.FOLLOWING
				#elif targeting_component.target_invisible_time > SEARCH_TIME:
					#current_state = State.IDLE
				#
			#State.PREPARING_ATTACK:
				#animated_skeleton.set_bone_pose_rotation(animated_skeleton.find_bone("Chest"), Quaternion.from_euler(Vector3(deg_to_rad(-50), 0, 0)))
				#
				#if time_in_state > ATTTACK_PREPARE_TIME:
					#current_state = State.ATTACKING
				#
			#State.ATTACKING:
				#animated_skeleton.set_bone_pose_rotation(animated_skeleton.find_bone("Chest"), Quaternion.from_euler(Vector3(deg_to_rad(75), 0, 0)))
				#
				#if time_in_state > ATTTACK_TIME:
					#current_state = State.FOLLOWING
					#animated_skeleton.set_bone_pose_rotation(animated_skeleton.find_bone("Chest"), Quaternion.from_euler(Vector3(0, 0, 0)))
		#
