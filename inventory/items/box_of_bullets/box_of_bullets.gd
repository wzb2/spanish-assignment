extends PhysicalItem

@onready var floater: Floater = $Floater

const EMPTY_RELATIVE_DENSITY: float = 0.5
const FULL_RELATIVE_DENSITY: float = 4

func _process(delta: float) -> void:
	super._process(delta)
	if multiplayer.is_server():
		floater.relative_density = EMPTY_RELATIVE_DENSITY + item_resource.data.get("remaining_ammo") * (FULL_RELATIVE_DENSITY - EMPTY_RELATIVE_DENSITY)
