@tool
extends MeshInstance3D

class_name Water

func _ready() -> void:
	add_to_group("water")
	

func get_height(_pos: Vector2) -> float:
	assert(mesh is PlaneMesh, "Water mesh is not PlaneMesh, Path: " + str(get_path()))
	return global_position.y + mesh.center_offset.y
	

func _get_configuration_warnings() -> PackedStringArray:
	if not mesh:
		return ["Needs mesh. "]
	if not mesh is PlaneMesh:
		return ["Mesh must be PlaneMesh. "]
	return []


func _set(property: StringName, value: Variant) -> bool:
	if property == "mesh":
		mesh = value
		update_configuration_warnings()
		return true
	return false
