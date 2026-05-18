extends ConsumableItem

const HEALING: float = 5
const FOOD: float = 10

func _ready() -> void:
	on_consume = func() -> void:
		last_grabbed_by_player.health_component.heal(HEALING)
		last_grabbed_by_player.hunger_component.feed(FOOD)
	super._ready()

func _on_use() -> void:
	super._on_use()
	
