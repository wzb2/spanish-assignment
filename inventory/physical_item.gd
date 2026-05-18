extends HighlightyRigidbody

class_name PhysicalItem

@export var item_resource: InventoryItem
@export var use_button_hold_time: float = 0

## Currently does not get set after dropping an item from inv
var last_grabbed_by_player: Player = null

#var holding_use_button: bool = false
var first_interact_finished: bool = false
var use_button_held_time: float = 0

@export var current_hand: Player.Hand = Player.Hand.NONE:
	set(value):
		if multiplayer.is_server():
			freeze = false
			set_collision_layer_value(1, true)
			
			if value == Player.Hand.RIGHT:
				global_position = last_grabbed_by_player.right_grab_joint.global_position
				global_rotation = last_grabbed_by_player.right_grab_joint.global_rotation
				add_collision_exception_with(last_grabbed_by_player.right_hand_physics_bone)
				
			elif value == Player.Hand.LEFT:
				global_position = last_grabbed_by_player.left_grab_joint.global_position
				global_rotation = last_grabbed_by_player.left_grab_joint.global_rotation
				add_collision_exception_with(last_grabbed_by_player.left_hand_physics_bone)
				
			else:
				remove_collision_exception_with(last_grabbed_by_player.left_hand_physics_bone)
				remove_collision_exception_with(last_grabbed_by_player.right_hand_physics_bone)
				
		current_hand = value



func set_hand_and_last_grabbed_by_player(hand: Player.Hand, player: Player) -> void:
	last_grabbed_by_player = player
	current_hand = hand


func _ready() -> void:
	super._ready()
	if (not item_resource.data.is_empty()) and item_resource.is_original:
		item_resource = item_resource.duplicate()
		item_resource.is_original = false

func _on_drop() -> void:
	pass

func _on_use() -> void:
	#holding_use_button = true
	pass

func _on_reached_use_button_hold_time() -> void:
	pass

func reset_use_button_holding() -> void:
	use_button_held_time = 0
	#holding_use_button = false

func _process(delta: float) -> void:
	if current_hand != Player.Hand.NONE:# and is_instance_valid(last_grabbed_by_player):
		disable_outline()
		
		if multiplayer.is_server():
			var other_hand: Player.Hand = Player.Hand.LEFT if current_hand == Player.Hand.RIGHT else Player.Hand.RIGHT
			var other_hand_object: Node3D = last_grabbed_by_player.get_grabbed_node(last_grabbed_by_player.grab_joints.get(other_hand))
			var other_hand_free: bool = other_hand_object != PhysicalItem
			
			var other_hand_in_use: bool = not other_hand_free
			if other_hand_object is PhysicalItem:
				other_hand_in_use = other_hand_object.use_button_held_time != 0
			
			var hand_grabbing: bool = (current_hand == Player.Hand.LEFT and last_grabbed_by_player.left_grabbing) or (current_hand == Player.Hand.RIGHT and last_grabbed_by_player.right_grabbing)
			
			if not (first_interact_finished or last_grabbed_by_player.input_synchronizer.interacting):
				first_interact_finished = true
			
			if first_interact_finished and (current_hand == Player.DOMINANT_HAND or not other_hand_in_use) and last_grabbed_by_player.input_synchronizer.interacting and use_button_hold_time > 0 and hand_grabbing and not GameManager.game_menu_open:
				use_button_held_time += delta
				if use_button_held_time >= use_button_hold_time:
					_on_reached_use_button_hold_time()
					reset_use_button_holding()
			else:
				reset_use_button_holding()
	
	else:
		if multiplayer.is_server():
			reset_use_button_holding()
			
		super._process(delta)
		
