extends Node

signal host_attempt_failed
signal added_player
signal connection_confirmed

const PLAYER = preload("res://scenes/player.tscn")
const MAIN_MENU_PATH: String = "res://scenes/main_menu.tscn"
const GAME_PATH: String = "res://levels/level.tscn"

const MAX_CLIENTS: int = 16

const LOCAL_HOST_IP: String = "127.0.0.1"

enum Mode {LOCAL, LAN, PUBLIC}

var mode: Mode = Mode.LOCAL

var port: int = 6536

var latest_game_code: String = ""

var world_path: String = "res://levels/level/world.tscn"

var game_started: bool = false

## Server side only
var players: Dictionary[int, Player]


func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_disconnected_from_server)


func wait_for_scene_load() -> void:
	while not get_tree().current_scene:
		await get_tree().process_frame


func host() -> void:
	print("Starting host")
	
	# nullable
	@warning_ignore("untyped_declaration")
	var ip = ""
	
	match mode:
		#Mode.PUBLIC:
			#ip = await UPNPManager.run_in_thread(UPNPManager.get_public_ip)
			#if ip:
				#var error: int = await UPNPManager.run_in_thread(UPNPManager.open_port)
				#if not error == OK:
					#host_attempt_failed.emit()
					#return
			#else:
				#print("Could not connect to router. Is UPnP enabled? ")
				#host_attempt_failed.emit()
				#return
		Mode.LAN:
			var ips: Array = Array(IP.get_local_addresses()).filter(func(i: String) -> bool: return JoinCode.is_valid_ipv4(i) and i.begins_with("192.168."))
			ips.append_array(Array(IP.get_local_addresses()).filter(func(i: String) -> bool: return JoinCode.is_valid_ipv4(i) and i.begins_with("10.")))
			ips.append_array(Array(IP.get_local_addresses()).filter(func(i: String) -> bool: return JoinCode.is_valid_ipv4(i) and i.begins_with("172.")))
			print(ips)
			if len(ips) > 0:
				ip = ips[0]
				print(ip)
			else:
				print("Could not find localhost IP. ")
				host_attempt_failed.emit()
				return
		Mode.LOCAL:
			ip = LOCAL_HOST_IP

	print("Join code: ", JoinCode.encode(ip, port))
	
	get_tree().change_scene_to_file(GAME_PATH)
	
	var server_peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	server_peer.create_server(port)
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	
	await wait_for_scene_load()
	
	add_player(1)
	


func join(code: String) -> void:
	get_tree().change_scene_to_file(GAME_PATH)
	
	var client_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	client_peer.create_client(JoinCode.decode_ip(code), JoinCode.decode_port(code))
	
	multiplayer.multiplayer_peer = client_peer
	


func disconnect_from_server() -> void:
	assert(not multiplayer.is_server(), "Server tried to disconnect from server")
	multiplayer.multiplayer_peer.close()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func close_server() -> void:
	assert(multiplayer.is_server(), "Tried to close server as client")
	multiplayer.multiplayer_peer.close()
	get_tree().paused = false
	#UPNPManager.close_port()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)



func add_player(id: int) -> void:
	var level: Level = get_tree().current_scene
	
	var new_player: Player = PLAYER.instantiate()
	new_player.name = str(id)
	
	level.add_child(new_player, true)
	
	new_player.id = id
	
	players.set(id, new_player)
	
	added_player.emit()
	
	load_world_on_client.rpc_id(id, world_path)


func _player_connected(id: int) -> void:
	print("Connected ", id)
	confirm_connection.rpc_id(id)
	add_player(id)
	


func _player_disconnected(id: int) -> void:
	print("Disconnected ", id)
	
	var player: Player = players.get(id)
	player.health_component.smite()
	players.erase(id)
	if not game_started:
		player.drop_hand(Player.Hand.RIGHT)
		player.drop_hand(Player.Hand.LEFT)
		player.queue_free()
	

func _on_disconnected_from_server() -> void:
	print("Connection lost! ")
	disconnect_from_server()



@rpc("call_local")
func load_world_on_client(path: String) -> void:
	ResourceLoader.load_threaded_request(path)
	world_path = path


@rpc
func confirm_connection() -> void:
	connection_confirmed.emit()
