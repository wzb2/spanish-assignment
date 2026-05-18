@tool
extends MeshInstance3D

class_name FloaterMesh

const FLOATER_POINT_SCENE = preload("res://scenes/floater_point.tscn")

func _ready() -> void:
	assert(get_parent() is Floater, "Parent is not Floater. Path: " + str(get_path()))
	if not Engine.is_editor_hint():
		for c: Node in get_children():
			c.reparent.call_deferred(get_parent())
		queue_free.call_deferred()
	


@export_tool_button("Generate Floater Points")
var generate_floater_points: Callable = generate_floater_points_func

func generate_floater_points_func() -> void:
	assert(mesh, "No mesh assigned to FloaterMesh in " + get_parent().get_parent().name + "/" + get_parent().name)
	
	# old method
	for s: Node in get_parent().get_children():
		if s is FloaterPoint:
			if s.is_generated:
				s.queue_free()
	
	for s: Node in get_children():
		if s is FloaterPoint:
				s.queue_free()
	
	var vertices: Array[Vector3] = []
	
	for i: int in mesh.get_surface_count():
		var array_mesh: ArrayMesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(i))
		
		var mdt: MeshDataTool = MeshDataTool.new()
		mdt.create_from_surface(array_mesh, 0)
		
		for v: int in mdt.get_vertex_count():
			var local_position: Vector3 = mdt.get_vertex(v)
			
			if not vertices.has(local_position):
				vertices.append(local_position)
			
				var floater_point: FloaterPoint = FLOATER_POINT_SCENE.instantiate()
				add_child(floater_point, true)
				floater_point.position = local_position
				floater_point.owner = get_tree().edited_scene_root
	
	print("Generated ", len(vertices), " floater points. ")
	EditorInterface.mark_scene_as_unsaved()


func _get_configuration_warnings() -> PackedStringArray:
	if not get_parent() is Floater:
		return ["Should be parented to Floater. "]
	return []

func _notification(what: int) -> void:
	if what == NOTIFICATION_PARENTED:
		update_configuration_warnings()
