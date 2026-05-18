extends PhysicalItem

class_name ConsumableItem

var on_consume: Callable

func _on_reached_use_button_hold_time() -> void:
	consume()

func _on_use() -> void:
	super._on_use()
	
	if use_button_hold_time == 0:
		consume()

func consume() -> void:
	last_grabbed_by_player.drop_hand(current_hand)
	on_consume.call()
	queue_free()
