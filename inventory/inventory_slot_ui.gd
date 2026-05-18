extends Panel

class_name InventorySlotUI

@onready var sprite: Sprite2D = $Sprite2D
@onready var amount_label: Label = $Label
@onready var ui_parent: InventoryUI = get_parent().get_parent().get_parent().get_parent()

var current_item: InventoryItem
var current_slot: InventorySlot

var is_hovered: bool = false

func update(slot: InventorySlot) -> void:
	#print("update with slot: ", slot.serialize())
	current_slot = slot
	if slot.item:
		current_item = slot.item
		sprite.texture = slot.item.texture
		if slot.amount > 1:
			amount_label.text = str(slot.amount)
			amount_label.show()
		else:
			amount_label.hide()
		sprite.show()
	else:
		sprite.hide()
		amount_label.hide()
		current_item = null


func _on_mouse_entered() -> void:
	is_hovered = true



func _on_mouse_exited() -> void:
	is_hovered = false
