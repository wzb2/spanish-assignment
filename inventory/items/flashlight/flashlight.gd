extends PhysicalItem

@onready var lights: Node3D = %Lights
@onready var inner_light: SpotLight3D = %Lights/Light
@onready var outer_light: SpotLight3D = %Lights/Light2

## percent per second
const BATERY_DECAY_RATE: float = 0.01

func _on_use() -> void:
	%Lights.visible = not %Lights.visible

func _process(delta: float) -> void:
	super._process(delta)
	if lights.visible:
		var remaining_battery: float = max(item_resource.data.get("battery") - BATERY_DECAY_RATE * delta, 0)
		item_resource.data.set("battery", remaining_battery)
		
		inner_light.light_energy = remaining_battery ** 0.25
		outer_light.light_energy = remaining_battery ** 0.25
