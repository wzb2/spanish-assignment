extends Node

class_name HealthComponent

@export var vital_bones: Array[DamagableBone]
@export var non_vital_bones: Array[DamagableBone]

@export var consciousness_threshold: float = 0
@export var unconscious_bleed_rate: float = 25

@export var damage_acceleration_threshold: float = 0.05
@export var pointy_thing_damage_force_threshold: float = 0.04
@export var slide_damage_velocity_threshold: float = 4.75
@export var bone_damage_multiplier: float = 100
## On top of bone_damage_multiplier
@export var vital_bone_damage_multiplier: float = 2
@export var pointy_damage_multiplier: float = 10
@export var slide_damage_multiplier: float = 0.00025


@export var shock_multiplier: float = 0.5

@export var weakness_threshold: float = 25

@export var max_hp: float = 100

@export var shock_recovery_rate: float = 15

const ACCELERATION_MULTIPLIER: float = (1.0/120.0)**2

var vital_bone_prev_velocities: Array = []
var non_vital_bone_prev_velocities: Array = []

@export var hp: float = max_hp

@export var shock: float = 0:
	set(value):
		shock = max(value, 0)

func _ready() -> void:
	vital_bone_prev_velocities = vital_bones.map(func(bone: DamagableBone) -> Vector3: return bone.linear_velocity)
	non_vital_bone_prev_velocities = non_vital_bones.map(func(bone: DamagableBone) -> Vector3: return bone.linear_velocity)
	
	for i in vital_bones:
		i.hit.connect(do_pointy_thing_vital_damage)
		
	for i in non_vital_bones:
		i.hit.connect(do_pointy_thing_non_vital_damage)


func do_pointy_thing_vital_damage(force: float) -> void:
	if force > pointy_thing_damage_force_threshold:
		inflict_damage(force * pointy_damage_multiplier * vital_bone_damage_multiplier)

func do_pointy_thing_non_vital_damage(force: float) -> void:
	if force > pointy_thing_damage_force_threshold:
		inflict_damage(force * pointy_damage_multiplier)


func _physics_process(delta: float) -> void:
	if MultiplayerManager.game_started:
		var vital_bone_accelerations: Array = calculate_accelerations(vital_bones, vital_bone_prev_velocities, delta)
		inflict_damage(calculate_total_damage(vital_bone_accelerations, bone_damage_multiplier * vital_bone_damage_multiplier, damage_acceleration_threshold))
		
		var non_vital_bone_accelerations: Array = calculate_accelerations(non_vital_bones, non_vital_bone_prev_velocities, delta)
		inflict_damage(calculate_total_damage(non_vital_bone_accelerations, bone_damage_multiplier, damage_acceleration_threshold))
		
		inflict_damage(calculate_total_slide_damage(non_vital_bones, bone_damage_multiplier * slide_damage_multiplier, slide_damage_velocity_threshold, delta))
		inflict_damage(calculate_total_slide_damage(vital_bones, bone_damage_multiplier * vital_bone_damage_multiplier * slide_damage_multiplier, slide_damage_velocity_threshold, delta))
		
		if not is_conscious():
			inflict_damage(unconscious_bleed_rate * delta)
		
		shock -= shock_recovery_rate * delta
	

func calculate_total_slide_damage(bones: Array[DamagableBone], multiplier: float, threshold: float, delta: float) -> float:
	var total_damage: float = 0
	for b: DamagableBone in bones:
		if b.linear_velocity.length() > threshold:
			var collision: KinematicCollision3D = b.move_and_collide(b.linear_velocity * delta, true)
			if collision:
				if not collision.get_collider() is PhysicalBone3D:
					total_damage += b.linear_velocity.length()
	return total_damage * multiplier

func calculate_accelerations(bones: Array[DamagableBone], prev_velocities: Array, delta: float) -> Array[float]:
	var current_velocities: Array = bones.map(func(bone: DamagableBone) -> Vector3: return bone.linear_velocity)
	
	var accelerations: Array[float]
	for i in len(bones):
		accelerations.append(((current_velocities[i] - prev_velocities[i]) * ACCELERATION_MULTIPLIER / delta).length())
	
	prev_velocities.clear()
	prev_velocities.append_array(current_velocities)
	
	return accelerations

func calculate_total_damage(accelerations: Array[float], multiplier: float, threshold: float) -> float:
	var dmg: float = 0
	for a in accelerations:
		if a > threshold:
			dmg += (a - threshold)
	
	return dmg * multiplier
	


func is_conscious() -> bool:
	return hp > consciousness_threshold

func is_alive() -> bool:
	return hp > -max_hp


func get_weakness_percentage() -> float:
	return 0.0 if hp > weakness_threshold else (weakness_threshold - hp) / weakness_threshold

func get_shock_percentage() -> float:
	return shock / max_hp


func inflict_damage(amount: float) -> void:
	if MultiplayerManager.game_started:
		shock += amount * shock_multiplier
		hp -= amount

func heal(amount: float) -> void:
	hp += amount
	if hp > max_hp:
		hp = max_hp


func smite() -> void:
	hp = -max_hp
	shock = max_hp
