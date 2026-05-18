extends Resource

class_name Inventory

#signal update()

@export var slots: Array[InventorySlot]

func insert(item: InventoryItem, amount: int) -> void:
	var item_slots: Array[InventorySlot] = slots.filter(func(slot: InventorySlot) -> bool: return slot.item == item and slot.amount < item.stack_size) # slots that already have the item and have room
	if item_slots.is_empty():
		var empty_slots: Array[InventorySlot] = slots.filter(func(slot: InventorySlot) -> bool: return slot.item == null)
		empty_slots[0].item = item
		empty_slots[0].amount = amount
	else:
		var remaining_slot_room: int = item.stack_size - item_slots[0].amount
		if amount > remaining_slot_room:
			var leftover_items: int = amount - remaining_slot_room
			item_slots[0].amount += remaining_slot_room
			insert(item, leftover_items)
		else:
			item_slots[0].amount += amount
	#update.emit()

## Filter must have a paramater for item, and should return true if the item should be included
func get_first_item_occurance(name: String, extra_slots: Array[InventorySlot] = Array(), filter: Callable = Callable()) -> InventoryItem:
	var slots_to_check: Array = extra_slots
	slots_to_check.append_array(slots)
	for slot: InventorySlot in slots_to_check:
		var item: InventoryItem = slot.item
		if item:
			if item.name == name:
				if filter.is_valid():
					if filter.call(item):
						return item
				else:
					print("NO TFILTER")
					return item
				
	return null


#func delete(item: InventoryItem, amount: int) -> void:
	#var item_slots: Array[InventorySlot] = slots.filter(func(slot): return slot.item == item) # slots that already have the item
	#if item_slots.is_empty():
		#print("No items to remove")
	#else:
		#item_slots[0].amount -= amount
		#if item_slots[0].amount <= 0:
			#item_slots[0].item = null
			#item_slots[0].amount = 0
	#update.emit()


func serialize() -> Array[Dictionary]:
	var serialized_slots: Array[Dictionary] = []
	
	for s: InventorySlot in slots:
		serialized_slots.append(s.serialize())
	
	return serialized_slots


static func de_serialize(serialized_inventory: Array[Dictionary]) -> Inventory:
	var new_inventory: Inventory = Inventory.new()
	
	for s: Dictionary in serialized_inventory:
		new_inventory.slots.append(InventorySlot.de_serialize(s))
	
	return new_inventory
