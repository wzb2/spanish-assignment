@tool
extends Node3D

class_name Floater

const DRAG: float = 2.5

@export var relative_density: float = 1
@export var max_bouyancy_depth: float = 1.3

@onready var parent: PhysicsBody3D = get_parent()

var floater_points: Array = []

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var gravity_vector: Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")


func update_floater_points() -> void:
	floater_points = get_children().filter(func(child: Node) -> bool: return child is FloaterPoint)

func _ready() -> void:
	assert(parent is RigidBody3D or parent is PhysicalBone3D, "Floater not parented to RigidBody3D or PhysicalBone3D. Path: " + str(get_path()))
	
	if not Engine.is_editor_hint():
		if multiplayer.is_server():
			PhysicsServer3D.body_set_force_integration_callback(parent.get_rid(), on_parent_integrate_forces)
		else:
			queue_free()
		
		update_floater_points.call_deferred()


func on_parent_integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if parent is RigidBody3D:
		if parent.freeze:
			return
	for point: FloaterPoint in floater_points:
		var depth_ratio: float = point.get_depth_ratio(max_bouyancy_depth)
		if depth_ratio != 0:
			var num_of_floater_points: int = floater_points.size()
			var bouyancy_force: Vector3 = ((depth_ratio * parent.mass * gravity * -gravity_vector) / float(num_of_floater_points)) / relative_density
			state.apply_force(bouyancy_force, point.position)
			
			var local_vel: Vector3 = state.get_velocity_at_local_position(point.position)
			var drag_accel: Vector3 = local_vel * DRAG / float(num_of_floater_points)
			var drag_force: Vector3 = drag_accel * parent.mass
			state.apply_force(-drag_force, point.position)
			



func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not (get_parent() is RigidBody3D or get_parent() is PhysicalBone3D):
		warnings.append("Should be parented to RigidBody3D or PhysicalBone3D. ")
	if len(get_children().filter(func(child: Node) -> bool: return child is FloaterPoint or (child is FloaterMesh and len(child.get_children().filter(func(c: Node) -> bool: return c is FloaterPoint)) != 0))) == 0:
		warnings.append("Has no FloaterPoints or FloaterMeshes with FloaterPoints as children. ")
	return warnings

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED or what == NOTIFICATION_CHILD_ORDER_CHANGED:
		update_configuration_warnings()
		
