extends Node3D

class_name Level

var local_player: Player:
	set(value):
		local_player = value
		inventory_ui.local_player = local_player
		hud.local_player = local_player

var ids_ready: Array[int] = []

@export var inventory_ui: InventoryUI
@export var hud: Hud
@export var day_night_cycle: DayNightCycle
@export var loading_screen: LoadingScreen
@export var lobby: Lobby
@export var terrain_grass_mesh_asset_id: int = 0
@export var max_grass_pushers: int = 32

var world: World

#func _process(_delta: float) -> void:
	#if local_player and local_player.is_inside_tree() and world:
		#var grass_pushers: Array[Node] = get_tree().get_nodes_in_group("grass_pushers")
		#var grass_material: ShaderMaterial = world.terrain.assets.get_mesh_asset(terrain_grass_mesh_asset_id).material_override
		#
		#grass_material.set_shader_parameter("num_push_objects", min(len(grass_pushers), max_grass_pushers))
		#
		#grass_pushers.sort_custom(func(p1: Node, p2: Node) -> float: return p1.global_position.distance_squared_to(local_player.camera.global_position) < p2.global_position.distance_squared_to(local_player.camera.global_position))
		#
		#grass_pushers.resize(max_grass_pushers)
		#
		#var grass_pusher_positions: Array = grass_pushers.map(func(p: Node) -> Vector3: return p.global_position if p else Vector3.ZERO)
		#var grass_pusher_radii: Array = grass_pushers.map(func(p: Node) -> float: return p.radius if p else 0.0)
		#
		#grass_material.set_shader_parameter("push_object_positions", grass_pusher_positions)
		#grass_material.set_shader_parameter("push_object_radii", grass_pusher_radii)
		
	

func all_players_ready() -> bool:
	for id: int in MultiplayerManager.players.keys():
		if not ids_ready.has(id):
			return false
	return true

func _on_lobby_start_game() -> void:
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.refuse_new_connections = true
		
		start_loading_screen.rpc()
		
		load_game_on_client.rpc()
		
		while not all_players_ready():
			await get_tree().process_frame
		
		for p: Player in MultiplayerManager.players.values():
			for b: PhysicalBone3D in p.physics_bones:
				b.global_position = world.spawn_pos + b.global_position
				b.reset_physics_interpolation()
		
		start_game.rpc()


@rpc("call_local")
func load_game_on_client() -> void:
	GameManager.loading_state = "Starting instantiate world thread"
	
	var instantiate_world_thread: Thread = Thread.new()
	instantiate_world_thread.start(instantiate_world.bind())
	
	while instantiate_world_thread.is_alive():
		#print("waiting for world instantiate")
		var progress: Array = [-1]
		var status: int = ResourceLoader.load_threaded_get_status(MultiplayerManager.world_path, progress)
		GameManager.loading_state = "Loading world, status: " + str(status) + ", progress: " + str(progress[0])
		await get_tree().process_frame
	
	world = instantiate_world_thread.wait_to_finish()
	
	add_child(world)
	
	tell_server_client_is_ready.rpc(multiplayer.get_unique_id())
	
	GameManager.loading_state = "Waiting for other players"
	


func instantiate_world() -> World:
	print("in instantiaing world thread")
	var world_scene: PackedScene = ResourceLoader.load_threaded_get(MultiplayerManager.world_path)
	GameManager.loading_state = "Instantiating world"
	return world_scene.instantiate()


@rpc("call_local")
func start_loading_screen() -> void:
	GameManager.loading_state = "Waiting for host"
	lobby.queue_free()
	
	get_tree().paused = true
	loading_screen.open()
	
	inventory_ui.close()

@rpc("call_local")
func start_game() -> void:
	MultiplayerManager.game_started = true
	
	day_night_cycle.freeze = false
	
	get_tree().paused = false
	loading_screen.close()


@rpc("any_peer", "call_local")
func tell_server_client_is_ready(id: int) -> void:
	ids_ready.append(id)
