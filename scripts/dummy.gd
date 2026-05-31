#@tool
extends ActiveRagdoll

class_name Dummy

@export var face_texture: Texture2D:
	set(val):
		face_texture = val
		if Engine.is_editor_hint():
			update_stuff()

@export var face_texture_scale: Vector3 = Vector3(1, 1, 1):
	set(val):
		face_texture_scale = val
		if Engine.is_editor_hint():
			update_stuff()

@export var text: String:
	set(val):
		text = val
		if Engine.is_editor_hint():
			update_stuff()

@onready var face_sprite: Sprite3D = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Head/Sprite3D"
@onready var text_label: Label3D = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Head/Label3D"
@onready var health_component: HealthComponent = $HealthComponent

@onready var mouth: MeshInstance3D = $PhysicsGuy/Armature/Skeleton3D/Mouth
@onready var pupils: MeshInstance3D = $PhysicsGuy/Armature/Skeleton3D/Pupils
@onready var head: MeshInstance3D = $PhysicsGuy/Armature/Skeleton3D/Head
@onready var head_cover: MeshInstance3D = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Head/MeshInstance3D"

@onready var level: Level = get_tree().current_scene

func _ready() -> void:
	super._ready()
	update_stuff()
	bones_to_ignore.append_array([$"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Arm_R", $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Arm_L", $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_R", $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_L"])

func update_stuff() -> void:
	if face_texture:
		face_sprite.texture = face_texture
		mouth.hide()
		head.hide()
		pupils.hide()
		head_cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		face_sprite.texture = null
		mouth.show()
		head.show()
		pupils.show()
		head_cover.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	
	if text:
		text_label.text = text
	else:
		text_label.text = ""
	
	face_sprite.scale = face_texture_scale


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	const damp: float = 0.02
	
	var feet_on_floor: Array[ShapeCast3D] = feet_shapecasts.filter(func(f: ShapeCast3D) -> bool: return shapecast_is_on_floor(f))
	for i: ShapeCast3D in feet_on_floor:
		var collider: Object = i.get_collider(0)
		
		if collider is RigidBody3D:
			#collider.linear_velocity -= velocity / collider.mass
			for b: PhysicalBone3D in movement_bones:
				b.linear_velocity -= (b.linear_velocity - collider.linear_velocity) * damp
		elif collider is AnimatableBody3D:
			for b: PhysicalBone3D in movement_bones:
				b.linear_velocity -= (b.linear_velocity - collider.constant_linear_velocity) * damp
		else:
			for b: PhysicalBone3D in movement_bones:
				b.linear_velocity -= (b.linear_velocity) * damp
	animated_skeleton.global_rotation.y = -PI*0.5-Vector2(root_bone.global_position.x, root_bone.global_position.z).angle_to_point(Vector2(level.local_player.root_bone.global_position.x, level.local_player.root_bone.global_position.z))
	current_angular_spring_stiffness = default_angular_spring_stiffness * (1.0 - health_component.get_weakness_percentage()) * (1.0 - health_component.get_shock_percentage())
