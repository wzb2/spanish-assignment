extends Resource

class_name InventorySlot

@export var item: InventoryItem
@export var amount: int:
	set(value):
		if value <= 0:
			item = null
			amount = 0
		else:
			amount = value

func copy_from(other: InventorySlot) -> void:
	item = other.item
	amount = other.amount

static func swap(slot_1: InventorySlot, slot_2: InventorySlot) -> void:
	var old_slot_1: InventorySlot = slot_1.duplicate()
	
	slot_1.copy_from(slot_2)
	slot_2.copy_from(old_slot_1)
	

func serialize() -> Dictionary:
	var serialized_slot: Dictionary = {
		"amount": amount,
		"item_path": item.path if item else "",
		"item_data": item.data if item else {}
	}
	
	return serialized_slot

static func de_serialize(serialized_slot: Dictionary) -> InventorySlot:
	var new_slot: InventorySlot = InventorySlot.new()
	
	new_slot.amount = serialized_slot.get("amount")
	
	var item_path: String = serialized_slot.get("item_path")
	new_slot.item = load(item_path) if item_path else null
	
	if new_slot.item:
		new_slot.item.data = serialized_slot.get("item_data")
	
	return new_slot
