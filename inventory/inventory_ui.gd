extends GameMenu

class_name InventoryUI

const SLOT_UI_SCENE: PackedScene = preload("res://inventory/inventory_slot_ui.tscn")

@onready var displayBox: VBoxContainer = $Control/ColorRect/VBoxContainer
@onready var displaySprite: Sprite2D = $Control/ColorRect/VBoxContainer/displaySprite
@onready var displayNameLabel: Label = $Control/ColorRect/VBoxContainer/NameLabel
@onready var displayDescriptionLabel: RichTextLabel = $Control/ColorRect/VBoxContainer/RichTextLabel

@onready var mouse_display_sprite: Sprite2D = $Control/MouseDisplaySprite
@onready var mouse_display_label: Label = $Control/MouseDisplaySprite/Label

@onready var container_slot_container: GridContainer = $Control/ColorRect/ContainerSlotGridContainer

@onready var normal_slots: Array[Node] = $Control/ColorRect/NormalSlotGridContainer.get_children()
var container_slots: Array[Node]:
	get():
		return container_slot_container.get_children()
@onready var left_hand_slot_UI: InventorySlotUI = %LeftSlotUI
@onready var right_hand_slot_UI: InventorySlotUI = %RightSlotUI

## Set in level local_player setter
var local_player: Player


var player_inventory: Inventory = Inventory.new()
var open_container_inventory: Inventory = Inventory.new()

var left_hand_slot: InventorySlot = InventorySlot.new()
var right_hand_slot: InventorySlot = InventorySlot.new()

var mouse_slot: InventorySlot = InventorySlot.new()

var mouse_pos: Vector2

enum SlotType {NONE, NORMAL, CONTAINER, LEFT_HAND, RIGHT_HAND}


func parse_description_text(item: InventoryItem) -> String:
	var text: String = item.description
	var new_text_array: PackedStringArray = text.split("$")
	var new_text: String = ""
	
	for i in range(len(new_text_array)):
		if i % 2 == 0:
			new_text += new_text_array[i]
		else:
			new_text += str(item.data.get(new_text_array[i]))
	
	return new_text


func get_slot_ui_from_id_and_type(id: int, type: SlotType) -> InventorySlotUI:
	if type == SlotType.LEFT_HAND:
		return left_hand_slot_UI
	elif type == SlotType.RIGHT_HAND:
		return right_hand_slot_UI
	elif type == SlotType.NORMAL:
		return normal_slots[int(id)]
	elif type == SlotType.CONTAINER:
		return container_slots[int(id)]
	else:
		return null


func _process(_delta: float) -> void:
	var hovered_slot_ui: InventorySlotUI = get_slot_ui_from_id_and_type(get_hovered_slot_id(), get_hovered_slot_type())
	
	if hovered_slot_ui:
		var hovered_slot: InventorySlot = hovered_slot_ui.current_slot
		if hovered_slot:
			if hovered_slot.item:
				displaySprite.texture = hovered_slot.item.texture
				displayNameLabel.text = hovered_slot.item.name
				displayDescriptionLabel.text = parse_description_text(hovered_slot.item)
				displayBox.show()
				return
	displayBox.hide()


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		close()
		
	elif Input.is_action_just_pressed("inventory"):
		if visible:
			close()
		else:
			open()
	
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#if get_slot_ui_from_id(get_hovered_slot_id()):
			if local_player:
				local_player.input_synchronizer.inventory_ui_click_rpc.rpc_id(1, get_hovered_slot_id(), get_hovered_slot_type())
		
	elif event is InputEventMouseMotion:
		mouse_pos = event.position
		
	mouse_display_sprite.texture = mouse_slot.item.texture if mouse_slot.item else null
	if mouse_slot.amount > 1:
		mouse_display_label.text = str(mouse_slot.amount)
		mouse_display_label.show()
	else:
		mouse_display_label.hide()
	mouse_display_sprite.position = mouse_pos


func _ready() -> void:
	close()
	update_all_slots()

func update_all_slots() -> void:
	update_normal_slots()
	update_open_container_slots()
	update_hand_slots()

func update_normal_slots() -> void:
	update_slots(player_inventory, normal_slots)

func update_open_container_slots() -> void:
	for s in container_slots:
		s.queue_free()
	var new_slot_uis: Array[Node] = []
	if not open_container_inventory.slots.is_empty():
		for s in open_container_inventory.slots:
			var new_slot_ui: InventorySlotUI = SLOT_UI_SCENE.instantiate()
			container_slot_container.add_child(new_slot_ui)
			new_slot_uis.append(new_slot_ui)
			
		update_slots(open_container_inventory, new_slot_uis)
	

func update_hand_slots() -> void:
	right_hand_slot_UI.update(right_hand_slot)
	left_hand_slot_UI.update(left_hand_slot)

func update_slots(inventory: Inventory, slots: Array[Node]) -> void:
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])


func get_hovered_slot_id() -> int:
	if visible:
		for i in len(normal_slots):
			if normal_slots[i].is_hovered:
				return i
		for i in len(container_slots):
			if container_slots[i].is_hovered:
				return i
	
	return int()


func get_hovered_slot_type() -> SlotType:
	if visible:
		for i in len(normal_slots):
			if normal_slots[i].is_hovered:
				return SlotType.NORMAL
		for i in len(container_slots):
			if container_slots[i].is_hovered:
				return SlotType.CONTAINER
		if left_hand_slot_UI.is_hovered:
			return SlotType.LEFT_HAND
		if right_hand_slot_UI.is_hovered:
			return SlotType.RIGHT_HAND
	
	return SlotType.NONE


func close() -> void:
	super.close()
	if local_player:
		local_player.input_synchronizer.drop_mouse_slot_rpc.rpc_id(1)
	
