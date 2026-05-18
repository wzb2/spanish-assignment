extends MultiplayerSynchronizer

class_name InputSynchronizer

const MOUSE_SENSITIVITY: float = 0.2

@onready var player: Player = get_parent()

@export var movement_input_vector: Vector3 = Vector3.ZERO

@export var mouse_velocity: Vector2 = Vector2.ZERO

@export var interacting: bool = false
@export var jumping: bool = false
@export var crouching: bool = false

var game_menu_open_changed: bool = false


func _ready() -> void:
	GameManager.game_menu_visibility_changed.connect(func() -> void: game_menu_open_changed = true)


func _physics_process(_delta: float) -> void:
	if not GameManager.game_menu_open:
		movement_input_vector = Vector3(Input.get_axis("left", "right"), 0, Input.get_axis("forward", "back"))
	else:
		movement_input_vector = Vector3.ZERO
	
	if GameManager.mouse_eaten:
		mouse_velocity = Input.get_last_mouse_velocity()
	else:
		mouse_velocity = Vector2.ZERO
	
	if Input.is_action_pressed("jump"):
		jumping = true
	else:
		jumping = false
	
	if Input.is_action_pressed("crouch"):
		crouching = true
	else:
		crouching = false
	
	if player.health_component.is_conscious():
		if game_menu_open_changed:
			if GameManager.game_menu_open:
				on_game_menu_opened.rpc_id(1)
			else:
				if is_multiplayer_authority(): # added if check because this gets called before the authority gets set, and it does not need to be called unless a container is open
					on_game_menu_closed.rpc_id(1)
			game_menu_open_changed = false
		
		if Input.is_action_pressed("interact") and not GameManager.game_menu_open:
			interacting = true
			#if Input.is_action_just_pressed("interact"):
				#interact_rpc.rpc_id(1)
		else:
			interacting = false
	else:
		var inventory_ui: InventoryUI = get_tree().current_scene.inventory_ui
		if inventory_ui.visible:
			inventory_ui.close()
	

func _input(event: InputEvent) -> void:
	if not GameManager.game_menu_open:
		if player.health_component.is_conscious():
			if event is InputEventMouseButton:
				on_mouse_click.rpc_id(1, event.button_index, event.pressed)
			
			if Input.is_action_just_pressed("drop"):
				drop_hand_items_rpc.rpc_id(1)
			elif Input.is_action_just_pressed("backpack"):
				backpack_button_rpc.rpc_id(1)



@rpc("call_local")
func on_mouse_click(button_index: int, pressed: bool) -> void:
	if multiplayer.is_server():
		if button_index == MOUSE_BUTTON_LEFT:
			if pressed:
				player.left_grabbing = true
			else:
				player.left_grabbing = false
				if not player.left_hand_item:
					player.release(player.left_grab_joint)
		if button_index == MOUSE_BUTTON_RIGHT:
			if pressed:
				player.right_grabbing = true
			else:
				player.right_grabbing = false
				if not player.right_hand_item:
					player.release(player.right_grab_joint)
				


@rpc("call_local")
func on_game_menu_opened() -> void:
	if multiplayer.is_server():
		player.update_inventory_ui_on_client()
		player.left_grabbing = false
		if not player.left_hand_item:
			player.release(player.left_grab_joint)
		player.right_grabbing = false
		if not player.right_hand_item:
			player.release(player.right_grab_joint)

@rpc("call_local")
func on_game_menu_closed() -> void:
	if multiplayer.is_server():
		player.open_container_inventory = null
	else:
		print("On game menu closed RPC called on client")
		


@rpc("call_local")
func drop_mouse_slot_rpc() -> void:
	if multiplayer.is_server():
		player.drop_mouse_slot()
	else:
		print("Drop mouse slot RPC called on client")


@rpc("call_local")
func inventory_ui_click_rpc(hovered_slot_id: int, hovered_slot_type: InventoryUI.SlotType) -> void:
	if multiplayer.is_server():
		player.on_inventory_ui_click(hovered_slot_id, hovered_slot_type)
	else:
		print("Inventory UI click RPC called on client")
		

@rpc("call_local")
func drop_hand_items_rpc() -> void:
	if multiplayer.is_server():
		player.drop_items_in_current_hand()
	else:
		print("Drop hand items RPC called on client")
		

@rpc("call_local")
func backpack_button_rpc() -> void:
	if multiplayer.is_server():
		player.on_backpack_button_pressed()



#@rpc("call_local")
#func interact_rpc() -> void:
	#if multiplayer.is_server():
		#player.interact()
	#else:
		#print("Interact RPC called on client")
		#
