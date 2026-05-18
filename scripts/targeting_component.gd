extends Marker3D

class_name TargetingComponent

@export var fov: float = 160.0
@export var notice_range: float = 5
@export var max_notice_range: float = 50
@export var vertical_notice_range: float = 10

var current_target: Player = null

var current_target_last_seen_pos: Vector3
var current_target_last_seen_velocity: Vector3

var target_visible_time: float = 0
var target_invisible_time: float = 0

var target_visible: bool = false

var raycast_to_player: RayCast3D = RayCast3D.new()


func add_raycast_exceptions() -> void:
	for p: Player in MultiplayerManager.players.values():
		for b: PhysicalBone3D in p.physics_bones:
			raycast_to_player.add_exception(b)
			


func _ready() -> void:
	add_child(raycast_to_player)
	
	add_raycast_exceptions()
	MultiplayerManager.added_player.connect(add_raycast_exceptions)



func _physics_process(delta: float) -> void:
	if current_target:
		if is_point_visible(current_target.root_bone.global_position):
			current_target_last_seen_pos = current_target.root_bone.global_position
			current_target_last_seen_velocity = current_target.root_bone.linear_velocity
			target_visible_time += delta
			target_invisible_time = 0
			target_visible = true
		else:
			target_invisible_time += delta
			target_visible_time = 0
			target_visible = false
	else:
		target_invisible_time = 0
		target_visible_time = 0
		target_visible = false



func is_point_visible(point: Vector3) -> bool:
	var dist: float = point.distance_to(global_position)
	var direction_to_point: Vector3 = global_position.direction_to(point)
	
	if dist < max_notice_range and abs(point.y - global_position.y) < vertical_notice_range:
		if dist < notice_range or global_basis.z.dot(direction_to_point) >= cos(deg_to_rad(fov)/2.0):
			raycast_to_player.target_position = raycast_to_player.to_local(point)
			raycast_to_player.force_raycast_update()
			if not raycast_to_player.is_colliding():
				return true
	return false


func is_player_conscious(player: Player) -> bool:
	return player.health_component.is_conscious()


func is_target_alive() -> bool:
	return is_player_conscious(current_target)


func get_visible_players() -> Array[Player]:
	var visible_players: Array[Player] = []
	
	for p: Player in MultiplayerManager.players.values():
		if is_point_visible(p.root_bone.global_position) and is_player_conscious(p):
			visible_players.append(p)
	
	visible_players.sort_custom(
		func(p1: Player, p2: Player) -> bool: 
			return global_position.distance_to(p1.global_position) < global_position.distance_to(p2.global_position)
	)
	
	return visible_players


func select_target() -> void:
	if not get_visible_players().is_empty():
		current_target = get_visible_players()[0]
	else:
		current_target = null


func select_different_target() -> void:
	var different_players: Array[Player] = get_visible_players()
	different_players.erase(current_target)
	
	if not different_players.is_empty():
		current_target = different_players[0]
	else:
		current_target = null
