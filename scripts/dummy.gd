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
		head_cover.show()
	else:
		face_sprite.texture = null
		mouth.show()
		head.show()
		pupils.show()
		head_cover.hide()
	
	if text:
		text_label.text = text
	else:
		text_label.text = ""
	
	face_sprite.scale = face_texture_scale


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	add_movement_bone_velocity(Vector3.ZERO)
	current_angular_spring_stiffness = default_angular_spring_stiffness * (1.0 - health_component.get_weakness_percentage()) * (1.0 - health_component.get_shock_percentage())
