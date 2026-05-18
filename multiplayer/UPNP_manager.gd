extends Node

var upnp: UPNP = UPNP.new()

var current_open_port: int = 0

var thread: Thread = null

func run_in_thread(function: Callable) -> Variant:
	if not thread or not thread.is_alive():
		thread = Thread.new()
		thread.start(function)
		while thread.is_alive():
			await get_tree().process_frame
		
		if thread.is_started():
			return thread.wait_to_finish()
		else:
			print("UPNPManager thread has not been started but attempted to wait for its completion. ")
			return null
	else:
		print("Thread still running. ")
		return null


func get_public_ip() -> String:
	var error: int = update()
	
	if error == OK:
		var ip: String = upnp.query_external_address()
		if ip:
			return ip
			
	return ""

func open_port() -> int:
	var port: int = MultiplayerManager.port
	if not current_open_port or current_open_port == port:
		var error: int = update()
		
		if error == OK:
			var port_mapping_error: int = upnp.add_port_mapping(port, port, ProjectSettings.get_setting("application/config/name"))
			if port_mapping_error == OK:
				current_open_port = port
				print("Opened port ", port)
				return OK
			else:
				print("Couldn't open port. Error code: ", port_mapping_error)
				return port_mapping_error
		else:
			return error
	else:
		print("Attempted to forward different port while port still forwarded. ")
		return -1


func close_port() -> int:
	if current_open_port:
		var port_mapping_error: int = upnp.delete_port_mapping(current_open_port)
		if port_mapping_error == OK:
			print("Closed port ", current_open_port)
			current_open_port = 0
			return OK
		else:
			print("Couldn't close port. Error code: ", port_mapping_error)
			return port_mapping_error
	else:
		print("Couldn't close port. No current open port. ")
		return -1


func update() -> int:
	var error: int = upnp.discover()
	
	if error == OK:
		if upnp.get_gateway():
			if upnp.get_gateway().is_valid_gateway():
				return OK
			else:
				print("Invalid gateway. ")
				return UPNP.UPNP_RESULT_INVALID_GATEWAY
		else:
			print("Couldn't get UPNP gateway device. ")
			return UPNP.UPNP_RESULT_NO_GATEWAY
	else:
		print("UPNP discovery failed. Error code: ", error)
		return UPNP.UPNP_RESULT_NO_DEVICES


func _exit_tree() -> void:
	clean_up()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		clean_up()

func clean_up() -> void:
	close_port()
	if thread and thread.is_started():
		thread.wait_to_finish()
	close_port()
