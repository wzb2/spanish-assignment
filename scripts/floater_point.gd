@tool
extends Marker3D

class_name FloaterPoint

const MAX_HEIGHT_ABOVE_PLANE: float = 2

## Deprecated. If true, will be deleted by floater meshes before generating new floater points
@export var is_generated: bool = false
@onready var level: Level = get_tree().current_scene
@onready var floater: Floater = get_parent() if get_parent() is Floater else get_parent().get_parent()

func _ready() -> void:
	assert(get_parent() is Floater or get_parent() is FloaterMesh, "Parent is not Floater or FloaterMesh. Path: " + str(get_path()))
	if not Engine.is_editor_hint():
		if not multiplayer.is_server():
			queue_free()

func get_depth_ratio(max_out_depth: float = 1) -> float:
	if level.world:
		for w: Water in level.world.water:
			var mesh: PlaneMesh = w.mesh
			var water_pos: Vector3 = w.global_position
			var water_size: Vector2 = mesh.size
			var water_half_size: Vector2 = water_size * 0.5
			
			if (abs(global_position.x - water_pos.x) < water_half_size.x or abs(global_position.z - water_pos.z) < water_half_size.y) and global_position.y - water_pos.y < MAX_HEIGHT_ABOVE_PLANE:
				return clamp((w.get_height(Vector2(global_position.x, global_position.z)) - global_position.y) / max_out_depth, 0, 1)
	return 0



func _get_configuration_warnings() -> PackedStringArray:
	if not (get_parent() is Floater or get_parent() is FloaterMesh):
		return ["Should be parented to Floater or FloaterMesh. "]
	return []

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		update_configuration_warnings()
		


#func _process(delta: float) -> void:
	#var debug_mesh_instance_3d: MeshInstance3D = $DebugMeshInstance3D
	#if debug_mesh_instance_3d.visible:
		#var material: StandardMaterial3D = debug_mesh_instance_3d.get_active_material(0)
		#if get_depth_ratio() != 0:
			#material.albedo_color = Color.BLUE
		#else:
			#material.albedo_color = Color.RED
		#
