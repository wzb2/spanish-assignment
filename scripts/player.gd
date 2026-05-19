extends ActiveRagdoll

class_name Player

const MOVEMENT_SPEED: float = 18
const GHOST_MOVEMENT_SPEED: float = 0.05
const AIR_SPEED: float = 8
const DAMPING: Vector3 = Vector3(0.95, 1, 0.95)
const MOUSE_SENSITIVITY: float = 0.00003

const JUMP_VELOCITY: Vector3 = Vector3(0, 3, 0)

const JUMP_VELOCITY_MULTIPLIER: Vector3 = Vector3(4, 0, 4)

const WALK_ANIMATION_THRESHOLD_VEL: float = 0.1
const METERS_PER_STEP: float = 0.5
const STEPS_PER_SECOND: float = 2.0/1.9583

const CAMERA_DEFAULT_ROTATION: Vector3 = Vector3(-PI*0.5, 0, 0)
const CAMERA_MAX_ROTATION_OFFSET: float = deg_to_rad(45)
const MAX_EYE_ROTATION: float = deg_to_rad(8)

const ARM_VERTICAL_ROTATION_OFFSET: float = deg_to_rad(20)
const DEFAULT_LEFT_ARM_GRAB_ANGLE: Quaternion = Quaternion(-1, -0.033, -0.09, 0.995)
const DEFAULT_RIGHT_ARM_GRAB_ANGLE: Quaternion = Quaternion(-1, 0.033, 0.09, 0.995)

const CAMERA_ORIGIN_SMOOTHING_WEIGHT: float = 0.3
const CAMERA_ROTATION_SMOOTHING_WEIGHT: float = 0.15

const MAX_MOUSE_MOVEMENT_FOR_BIG_ROTATION: float = 0.08

const EYE_RESET_RATE: float = 0.05

const MOVING_FAST_THRESHOLD: float = 4.5

const SAFE_ITEM_DROP_LENGTH_PERCENTAGE: float = 0.3

const ANGULAR_STIFFNESS_SMOOTHING_WEIGHT: float = 0.0015
const MOVING_FAST_STIFFNESS_VELOCITY_MULTIPLIER: float = -10000

const DROP_ITEMS_SHOCK_PERCENTAGE_THRESHOLD: float = 0.1

enum Hand {NONE, RIGHT, LEFT}

const DOMINANT_HAND: Hand = Hand.RIGHT
var non_dominant_hand: Hand:
	get():
		if DOMINANT_HAND == Hand.RIGHT:
			return Hand.LEFT
		else:
			return Hand.RIGHT

@onready var input_synchronizer: InputSynchronizer = $InputSynchronizer
@onready var invisible_to_self_meshes: Array[MeshInstance3D] = [$PhysicsGuy/Armature/Skeleton3D/Head, $PhysicsGuy/Armature/Skeleton3D/Mouth, $PhysicsGuy/Armature/Skeleton3D/Pupils]
@onready var camera: Camera3D = %Camera3D
@onready var ghost: Node3D = $Ghost


@export var id: int:
	set(value):
		id = value
		
		input_synchronizer = $InputSynchronizer
		camera = $Camera3D
		ghost = $Ghost
		
		input_synchronizer.set_multiplayer_authority(id)
		
		if multiplayer.is_server():
			update_inventory_ui_on_client()
		
		if multiplayer.get_unique_id() == id:
			for i in invisible_to_self_meshes:
				i.layers = INVISIBLE_LAYER
			camera.current = true
			
			var level: Level = get_tree().current_scene
			level.local_player = self
			
			for c: Node in ghost.get_children():
				if c is MeshInstance3D:
					c.layers = INVISIBLE_LAYER
		else:
			input_synchronizer.set_physics_process(false)
			input_synchronizer.set_process_input(false)



@onready var camera_anchor: Node3D = %CameraAnchor
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var left_shapecast: ShapeCast3D = %"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Lower Leg_L/ShapeCast3D"
@onready var right_shapecast: ShapeCast3D = %"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Lower Leg_R/ShapeCast3D"

# NOTE: grabby stuff names are correct
@onready var left_grab_joint: Joint3D = %LeftGrabJoint
@onready var right_grab_joint: Joint3D = %RightGrabJoint

@onready var backpack_joint: Joint3D = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Chest/BackpackJoint"

@onready var backpack_position_marker: Marker3D = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Chest/BackpackPositionMarker"

@onready var grab_joints: Dictionary[Hand, Joint3D] = {
	Hand.LEFT: left_grab_joint,
	Hand.RIGHT: right_grab_joint
}

# NOTE: left and right are swapped for all bone names

@onready var head_bone_index: int = animated_skeleton.find_bone("Head_2")
#@onready var chest_bone_index: int = animated_skeleton.find_bone("Chest")

@onready var left_eye_bone_index: int = physics_skeleton.find_bone("Eye.R")
@onready var right_eye_bone_index: int = physics_skeleton.find_bone("Eye.L")

@onready var left_upper_arm_bone_index: int = animated_skeleton.find_bone("Upper Arm.R")
@onready var right_upper_arm_bone_index: int = animated_skeleton.find_bone("Upper Arm.L")

#@onready var hip_bone_index: int = animated_skeleton.find_bone("Hip")

#@onready var movement_bones: Array[PhysicalBone3D] = [
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Hip",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Back",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Chest",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Shoulder_L",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Shoulder_R",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Leg_L",
	#%"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Leg_R"
#]
#@onready var hip_physics_bone: PhysicalBone3D = %"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Hip"

@onready var left_hand_physics_bone: PhysicalBone3D = %"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_R"
@onready var right_hand_physics_bone: PhysicalBone3D = %"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_L"


var inventory: Inventory = Inventory.new()
@export var inventory_size: int = 5
var open_container_inventory: Inventory

var left_hand_slot: InventorySlot = InventorySlot.new()
var right_hand_slot: InventorySlot = InventorySlot.new()

var mouse_slot: InventorySlot = InventorySlot.new()


@onready var interact_raycast: RayCast3D = %InteractRayCast


@export var display_use_button_held_percentage: float = 0


var angular_spring_stiffness_setpoint: float = default_angular_spring_stiffness

@onready var left_eye_default_rotation: Vector3 = physics_skeleton.get_bone_pose_rotation(left_eye_bone_index).get_euler()
@onready var right_eye_default_rotation: Vector3 = physics_skeleton.get_bone_pose_rotation(right_eye_bone_index).get_euler()

@onready var left_hand_item: InventoryItem:
	get():
		return left_hand_slot.item

@onready var right_hand_item: InventoryItem:
	get():
		return right_hand_slot.item


@onready var health_component: HealthComponent = $HealthComponent
@onready var hunger_component: HungerComponent = $HungerComponent

var walking: bool = false
var moving_fast: bool = false
var on_floor: bool = false

# NOTE: L and R bone names are swapped
var left_grabbing: bool = false
var right_grabbing: bool = false

var head_rotation: Vector3 = Vector3.ZERO
@export var camera_rotation_offset: Vector3 = Vector3.ZERO

var movement_input_vector: Vector3 = Vector3.ZERO
var mouse_movement: Vector2 = Vector2.ZERO

var was_interacting: bool = false

const INVISIBLE_LAYER: int = 2


var strength_multiplier: float:
	get():
		return (1.0 - min(health_component.get_weakness_percentage(), 1))

var shock_multiplier: float:
	get():
		return (1.0 - min(health_component.get_shock_percentage(), 1))


func update_display_use_button_held_percentage() -> void:
	var dominant_grabbed_node: Node3D = get_grabbed_node(grab_joints.get(DOMINANT_HAND))
	var non_dominant_grabbed_node: Node3D = get_grabbed_node(grab_joints.get(non_dominant_hand))
	
	if dominant_grabbed_node is PhysicalItem and dominant_grabbed_node.use_button_held_time > 0:
		display_use_button_held_percentage = dominant_grabbed_node.use_button_held_time / dominant_grabbed_node.use_button_hold_time
		
	elif non_dominant_grabbed_node is PhysicalItem and non_dominant_grabbed_node.use_button_held_time > 0:
		display_use_button_held_percentage = non_dominant_grabbed_node.use_button_held_time / non_dominant_grabbed_node.use_button_hold_time
	else:
		display_use_button_held_percentage = 0
	

func _ready() -> void:
	const SPAWN_POS: Vector3 = Vector3(0, 4, 0)
	global_position = SPAWN_POS
	
	for i in inventory_size:
		inventory.slots.append(InventorySlot.new())
	
	super._ready()
	


func apply_health_effects() -> void:
	var shock_percentage: float = health_component.get_shock_percentage()
	
	if shock_percentage > DROP_ITEMS_SHOCK_PERCENTAGE_THRESHOLD or not health_component.is_alive():
		right_grabbing = false
		left_grabbing = false
		drop_hand(Hand.RIGHT)
		drop_hand(Hand.LEFT)
	


func update_ghost_mode() -> void:
	if multiplayer.is_server():
		if health_component.is_alive() || not MultiplayerManager.players.keys().has(id):
			ghost.hide()
		else:
			ghost.show()

func update_head_visibility() -> void:
	if multiplayer.get_unique_id() == id:
		if health_component.is_alive():
			if not invisible_to_self_meshes[0].layers == INVISIBLE_LAYER:
				for i in invisible_to_self_meshes:
					i.layers = INVISIBLE_LAYER
		else:
			if invisible_to_self_meshes[0].layers == INVISIBLE_LAYER:
				for i in invisible_to_self_meshes:
					i.layers = 1



func _process(delta: float) -> void:
	super._process(delta)
	update_ghost_mode()
	update_head_visibility()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if multiplayer.is_server():
		update_interact()
		apply_health_effects()
		update_animated_skeleton()
		movement()
		update_display_use_button_held_percentage()
	
	update_eye_positions()
	update_camrea_pos()
	

func get_grabbed_node(joint: Joint3D) -> Node3D:
	var joint_node: Node3D = null
	if not joint.node_b.is_empty():
		joint_node = get_node(joint.node_b)
	return joint_node


func movement() -> void:
	if health_component.is_conscious():
		ghost.global_position = root_bone.global_position + Vector3.UP
		ghost.rotation.y = camera.rotation.y
		
		on_floor = is_on_floor(func(collider: Object) -> bool: return collider != get_grabbed_node(right_grab_joint) and collider != get_grabbed_node(left_grab_joint))
		
		movement_input_vector = input_synchronizer.movement_input_vector
		var movement_vector: Vector3 = movement_input_vector.rotated(Vector3.UP, animated_skeleton.rotation.y + head_rotation.y)
		var acceleration: Vector3 = movement_vector * strength_multiplier * shock_multiplier * _delta * (MOVEMENT_SPEED if on_floor else AIR_SPEED)
		
		if on_floor and input_synchronizer.jumping:
			acceleration *= JUMP_VELOCITY_MULTIPLIER
			acceleration += (JUMP_VELOCITY * strength_multiplier * shock_multiplier)
		
		add_movement_bone_velocity(acceleration)
			
		multiply_movement_bone_velocity(DAMPING)
		
	else:
		if health_component.is_alive():
			movement_input_vector = Vector3.ZERO
		
		var movement_vector: Vector3 = input_synchronizer.movement_input_vector + Vector3(0, float(input_synchronizer.jumping) - float(input_synchronizer.crouching), 0)
		ghost.global_position += movement_vector.rotated(Vector3.UP, ghost.rotation.y) * GHOST_MOVEMENT_SPEED
		ghost.global_rotation.y += -input_synchronizer.mouse_velocity.x * MOUSE_SENSITIVITY
		ghost.global_rotation.x = clamp(ghost.rotation.x - input_synchronizer.mouse_velocity.y * MOUSE_SENSITIVITY, -PI * 0.5, PI * 0.5)
		
	
	
	moving_fast = root_bone.linear_velocity.length() > MOVING_FAST_THRESHOLD
	
	angular_spring_stiffness_setpoint = ((MOVING_FAST_STIFFNESS_VELOCITY_MULTIPLIER * root_bone.linear_velocity.length()) if moving_fast else default_angular_spring_stiffness) * strength_multiplier
	current_angular_spring_stiffness = max(lerp(current_angular_spring_stiffness, angular_spring_stiffness_setpoint, ANGULAR_STIFFNESS_SMOOTHING_WEIGHT), 0) * shock_multiplier



func update_animated_skeleton() -> void:
	var horizontal_velocity: Vector2 = Vector2(root_bone.linear_velocity.x, root_bone.linear_velocity.z)
	walking = horizontal_velocity.length() > WALK_ANIMATION_THRESHOLD_VEL and movement_input_vector
	
	var rotation_offset: float = Vector2(movement_input_vector.x, movement_input_vector.z).rotated(PI * 0.5).angle()
	
	const ROTATION_FUDGE: float = 0.2
	
	## to prevent flipping the wrong way
	const OFFSET_MULTIPLIER: float = 0.85
	
	if rotation_offset > PI*0.5 + ROTATION_FUDGE:
		rotation_offset -= PI
	elif rotation_offset < -PI*0.5 - ROTATION_FUDGE:
		rotation_offset += PI
	
	# if offset multiplier is how much turn when strafe
	rotation_offset *= OFFSET_MULTIPLIER
	
	if walking:
		animation_tree.set("parameters/TimeScale/scale", horizontal_velocity.length() * STEPS_PER_SECOND / METERS_PER_STEP)
		
		head_rotation += camera_rotation_offset * EYE_RESET_RATE
		camera_rotation_offset -= camera_rotation_offset * EYE_RESET_RATE
		
		animated_skeleton.rotation.y += head_rotation.y - rotation_offset
		head_rotation.y = rotation_offset
	else:
		animation_tree.set("parameters/TimeScale/scale", 1)
	
	mouse_movement = -input_synchronizer.mouse_velocity * MOUSE_SENSITIVITY * current_angular_spring_stiffness / default_angular_spring_stiffness
	camera_rotation_offset.y += clamp(mouse_movement.x, -MAX_MOUSE_MOVEMENT_FOR_BIG_ROTATION, MAX_MOUSE_MOVEMENT_FOR_BIG_ROTATION) if abs(head_rotation.y) > deg_to_rad(90) else mouse_movement.x
	camera_rotation_offset.x += clamp(mouse_movement.y, -MAX_MOUSE_MOVEMENT_FOR_BIG_ROTATION, MAX_MOUSE_MOVEMENT_FOR_BIG_ROTATION) if abs(head_rotation.y) > deg_to_rad(90) else mouse_movement.y
	
	var clamped_camera_rotation_offset: Vector3 = camera_rotation_offset.limit_length(CAMERA_MAX_ROTATION_OFFSET)
	
	if clamped_camera_rotation_offset != camera_rotation_offset:
		head_rotation += camera_rotation_offset - clamped_camera_rotation_offset
		
		camera_rotation_offset = clamped_camera_rotation_offset
		
	
	var clamped_head_rotation_y: float = clamp(head_rotation.y, deg_to_rad(-90), deg_to_rad(90))
	
	head_rotation.x = clamp(head_rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if head_rotation.y != clamped_head_rotation_y:
		animated_skeleton.rotate(Vector3.UP, head_rotation.y - clamped_head_rotation_y)
		
		head_rotation.y = clamped_head_rotation_y
	
	animated_skeleton.set_bone_pose_rotation(head_bone_index, Quaternion.from_euler(head_rotation))
	
	
	var arm_offset: Vector3
	arm_offset.x = camera_rotation_offset.y + head_rotation.y
	arm_offset.y = 0
	arm_offset.z = -(camera_rotation_offset.x + head_rotation.x + ARM_VERTICAL_ROTATION_OFFSET)
	animated_skeleton.set_bone_pose_rotation(left_upper_arm_bone_index, DEFAULT_LEFT_ARM_GRAB_ANGLE * Quaternion.from_euler(arm_offset))
	animated_skeleton.set_bone_pose_rotation(right_upper_arm_bone_index, DEFAULT_RIGHT_ARM_GRAB_ANGLE * Quaternion.from_euler(-arm_offset))
	

func update_eye_positions() -> void:
	var eye_rotation: Vector3 = (camera_rotation_offset / CAMERA_MAX_ROTATION_OFFSET) * MAX_EYE_ROTATION
	physics_skeleton.set_bone_pose_rotation(left_eye_bone_index, Quaternion.from_euler(left_eye_default_rotation + eye_rotation))
	physics_skeleton.set_bone_pose_rotation(right_eye_bone_index, Quaternion.from_euler(right_eye_default_rotation + eye_rotation))

func update_camrea_pos() -> void:
	if health_component.is_alive():
		camera_anchor.rotation = CAMERA_DEFAULT_ROTATION + camera_rotation_offset
		
		camera.global_transform.origin = camera.global_transform.origin.lerp(camera_anchor.global_transform.origin, 1.0 if moving_fast else CAMERA_ORIGIN_SMOOTHING_WEIGHT)
		camera.global_transform.basis = camera.global_transform.basis.slerp(camera_anchor.global_transform.basis, CAMERA_ROTATION_SMOOTHING_WEIGHT)
	else:
		camera.global_transform = ghost.global_transform


func _on_physics_skeleton_3d_skeleton_updated() -> void:
	var left_forearm_bone: DamagableBone = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_R"
	var right_forearm_bone: DamagableBone = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/PhysicalBone Forearm_L"
	var left_upper_arm_bone: DamagableBone = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Arm_R"
	var right_upper_arm_bone: DamagableBone = $"PhysicsGuy/Armature/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone Upper Arm_L"
	
	bones_to_ignore.clear()
	if not left_grabbing:
		bones_to_ignore.append(left_forearm_bone)
		bones_to_ignore.append(left_upper_arm_bone)
	
	if not right_grabbing:
		bones_to_ignore.append(right_forearm_bone)
		bones_to_ignore.append(right_upper_arm_bone)
	
	super._on_physics_skeleton_3d_skeleton_updated()


func grab(joint: Joint3D, collider: Node3D) -> void:
	if grab_joints.values().has(joint):
		if not (is_own_bone(collider) or get_grabbed_node(joint)):
			joint.node_a = joint.get_parent_node_3d().get_path()
			
			if not collider is CSGShape3D:
				joint.node_b = collider.get_path()
			else:
				joint.node_b = NodePath()

func release(joint: Joint3D) -> void:
	joint.node_a = NodePath()
	joint.node_b = NodePath()

func _on_right_grab_area_3d_body_entered(body: Node3D) -> void:
	if not body is PhysicalItem and right_grabbing and not moving_fast:
		grab(right_grab_joint, body)


func _on_left_grab_area_3d_body_entered(body: Node3D) -> void:
	if not body is PhysicalItem and left_grabbing and not moving_fast:
		grab(left_grab_joint, body)


func update_interact() -> void:
	if not was_interacting and input_synchronizer.interacting:
		interact()
		was_interacting = true
	if not input_synchronizer.interacting:
		was_interacting = false

func interact() -> void:
	var left_grabbed_node: Node3D = get_grabbed_node(left_grab_joint)
	var right_grabbed_node: Node3D = get_grabbed_node(right_grab_joint)
	
	if (left_grabbed_node is PhysicalItem and left_grabbing) or (right_grabbed_node is PhysicalItem and right_grabbing):
		if left_grabbed_node is PhysicalItem and left_grabbing:
			left_grabbed_node._on_use()
			update_inventory_ui_on_client()
		
		if right_grabbed_node is PhysicalItem and right_grabbing:
			right_grabbed_node._on_use()
			update_inventory_ui_on_client()
		
		return
		
	
	var collider: Object = interact_raycast.get_collider()
	
	if collider is Area3D:
		if collider is ContainerArea:
			open_container_inventory = collider.inventory
			call_open_client_inventory_ui_rpc()
		else:
			var viewed_node: Node3D = collider.get_parent()
			
			if viewed_node is PhysicalItem:
				pickup_items_to_hand(viewed_node)
				



func pickup_items_to_hand(pickup_node: PhysicalItem) -> void:
	var left_grabbed_node: Node3D = get_grabbed_node(left_grab_joint)
	var right_grabbed_node: Node3D = get_grabbed_node(right_grab_joint)
	
	if pickup_node.current_hand == Hand.NONE:
		if left_grabbing and not right_grabbing and not left_hand_slot.item and not left_grabbed_node:
			left_hand_slot.item = pickup_node.item_resource
			left_hand_slot.amount = 1
			#pickup_node.reparent(left_grab_joint.get_parent())
			pickup_node.set_hand_and_last_grabbed_by_player(Hand.LEFT, self)
			drop_hand(Player.Hand.LEFT)
			grab(left_grab_joint, pickup_node)
		
		if right_grabbing and not left_grabbing and not right_hand_slot.item and not right_grabbed_node:
			right_hand_slot.item = pickup_node.item_resource
			right_hand_slot.amount = 1
			#pickup_node.reparent(right_grab_joint.get_parent())
			pickup_node.set_hand_and_last_grabbed_by_player(Hand.RIGHT, self)
			drop_hand(Player.Hand.RIGHT)
			grab(right_grab_joint, pickup_node)
		
		update_inventory_ui_on_client()


func drop_items_in_current_hand() -> void:
	if left_grabbing or (left_grabbing and right_grabbing):
		drop_hand(Hand.LEFT)
		
	if right_grabbing or (left_grabbing and right_grabbing):
		drop_hand(Hand.RIGHT)
		
	update_inventory_ui_on_client()


func drop_hand(hand: Hand) -> void:
	if hand != Hand.NONE:
		var joint: Joint3D = grab_joints.get(hand)
		var grabbed_node: Node3D = get_grabbed_node(joint)
		
		if grabbed_node is PhysicalItem:
			grabbed_node._on_drop()
			
			grabbed_node.current_hand = Player.Hand.NONE
			
			release(joint)
			
			#grabbed_node.reparent(get_parent(), true)
			
			grabbed_node.current_hand = Hand.NONE
			
			if hand == Hand.LEFT:
				left_hand_slot.item = null
				left_hand_slot.amount = 0
			else:
				right_hand_slot.item = null
				right_hand_slot.amount = 0
		else:
			release(joint)
			
		update_inventory_ui_on_client()

func on_drop_item_from_inv(item: InventoryItem) -> void:
	var item_node: PhysicalItem = load(item.physical_item_path).instantiate()
	add_sibling(item_node)
	item_node.item_resource = item
	
	item_node.global_position = interact_raycast.to_global(interact_raycast.to_local(interact_raycast.get_collision_point()) * SAFE_ITEM_DROP_LENGTH_PERCENTAGE if interact_raycast.is_colliding() else interact_raycast.target_position * SAFE_ITEM_DROP_LENGTH_PERCENTAGE)



func on_move_item_from_inv_to_hand(item: InventoryItem, hand: Joint3D) -> void:
	var item_node: PhysicalItem = load(item.physical_item_path).instantiate()
	
	add_sibling(item_node, true)
	item_node.set_hand_and_last_grabbed_by_player(Hand.RIGHT if hand == grab_joints.get(Hand.RIGHT) else Hand.LEFT, self)
	item_node.item_resource = item
	
	grab(hand, item_node)


func on_move_item_from_hand_to_inv(hand: Joint3D) -> void:
	assert(get_grabbed_node(hand) is PhysicalItem, "Grabbed node is not PhyscalItem")
	
	get_grabbed_node(hand).queue_free()
	release(hand)
	


func swap_hand_and_mouse(hand_slot: InventorySlot, hand: Joint3D) -> void:
	if mouse_slot.amount <= 1:
		if hand_slot.item:
			on_move_item_from_hand_to_inv(hand)
		if mouse_slot.item:
			on_move_item_from_inv_to_hand(mouse_slot.item, hand)
		InventorySlot.swap(hand_slot, mouse_slot)
		
	elif not hand_slot.item:
		on_move_item_from_inv_to_hand(mouse_slot.item, hand)
		
		hand_slot.item = mouse_slot.item
		hand_slot.amount = 1
		
		mouse_slot.amount -= 1


func on_inventory_ui_click(hovered_slot_id: int, hovered_slot_type: InventoryUI.SlotType) -> void:
	var hovered_slot: InventorySlot = null
	
	match hovered_slot_type:
		InventoryUI.SlotType.NORMAL:
			hovered_slot = inventory.slots[int(hovered_slot_id)]
		InventoryUI.SlotType.CONTAINER:
			hovered_slot = open_container_inventory.slots[int(hovered_slot_id)]
		InventoryUI.SlotType.LEFT_HAND:
			hovered_slot = left_hand_slot
		InventoryUI.SlotType.RIGHT_HAND:
			hovered_slot = right_hand_slot
		InventoryUI.SlotType.NONE:
			if mouse_slot.item:
				on_drop_item_from_inv(mouse_slot.item)
				mouse_slot.amount -= 1
		_:
			push_error("Invalid slot type: ", hovered_slot_type)
	
	if hovered_slot:
		if hovered_slot == left_hand_slot:
			swap_hand_and_mouse(hovered_slot, left_grab_joint)
			
		elif hovered_slot == right_hand_slot:
			swap_hand_and_mouse(hovered_slot, right_grab_joint)
			
		else:
			if (hovered_slot.item and mouse_slot.item) and hovered_slot.item == mouse_slot.item:
				var remaining_room: int = hovered_slot.item.stack_size - hovered_slot.amount
				if mouse_slot.amount > remaining_room:
					hovered_slot.amount += remaining_room
					mouse_slot.amount = mouse_slot.amount - remaining_room
				else:
					hovered_slot.amount += mouse_slot.amount
					mouse_slot.amount = 0
			else:
				InventorySlot.swap(hovered_slot, mouse_slot)
			
	
	update_inventory_ui_on_client()
	

func drop_mouse_slot() -> void:
	if mouse_slot.item:
		while mouse_slot.amount > 0:
			on_drop_item_from_inv(mouse_slot.item)
			mouse_slot.amount -= 1
		update_inventory_ui_on_client()


func on_backpack_button_pressed() -> void:
	var backpack: Node3D = get_grabbed_node(backpack_joint)
	if backpack:
		release(backpack_joint)
		backpack.is_equipped = false
	else:
		var collider: Object = interact_raycast.get_collider()
		
		if collider is Area3D:
			if collider is ContainerArea:
				var collider_parent: Node3D = collider.get_parent()
				if collider_parent is Backpack:
					if not collider_parent.is_equipped:
						collider_parent.global_transform = backpack_position_marker.global_transform
						backpack_joint.node_a = backpack_joint.get_parent_node_3d().get_path()
						backpack_joint.node_b = collider_parent.get_path()
						collider_parent.is_equipped = true


func update_inventory_ui_on_client() -> void:
	if multiplayer.get_peers().has(id) or id == 1:
		if open_container_inventory:
			for p: Player in MultiplayerManager.players.values():
				if p.open_container_inventory == open_container_inventory and p != self:
					if multiplayer.get_peers().has(p.id) or p.id == 1:
						p.update_inventory_ui.rpc_id(p.id, p.inventory.serialize(), p.left_hand_slot.serialize(), p.right_hand_slot.serialize(), p.mouse_slot.serialize(), p.open_container_inventory.serialize() if p.open_container_inventory else Inventory.new().serialize())
					
		update_inventory_ui.rpc_id(id, inventory.serialize(), left_hand_slot.serialize(), right_hand_slot.serialize(), mouse_slot.serialize(), open_container_inventory.serialize() if open_container_inventory else Inventory.new().serialize())
	

# client side
@rpc("call_local")
func update_inventory_ui(serialized_inventory: Array[Dictionary], serialized_left_hand_slot: Dictionary, serialized_right_hand_slot: Dictionary, serialized_mouse_slot: Dictionary, serialized_open_container_inventory: Array[Dictionary]) -> void:
	#if multiplayer.get_peers().has(id) or id == 1:
	var inventory_ui: InventoryUI = get_tree().current_scene.inventory_ui
		
	inventory_ui.player_inventory = Inventory.de_serialize(serialized_inventory)
	inventory_ui.open_container_inventory = Inventory.de_serialize(serialized_open_container_inventory)
	inventory_ui.left_hand_slot = InventorySlot.de_serialize(serialized_left_hand_slot)
	inventory_ui.right_hand_slot = InventorySlot.de_serialize(serialized_right_hand_slot)
	inventory_ui.mouse_slot = InventorySlot.de_serialize(serialized_mouse_slot)
	
	inventory_ui.update_all_slots()



func call_open_client_inventory_ui_rpc() -> void:
	if multiplayer.get_peers().has(id) or id == 1:
		open_inventory_ui.rpc_id(id)
		#update_inventory_ui_on_client()
	

# client side
@rpc("call_local")
func open_inventory_ui() -> void:
	var inventory_ui: InventoryUI = get_tree().current_scene.inventory_ui
	
	inventory_ui.open()
