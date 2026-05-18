extends CanvasLayer

class_name Hud

@onready var red: ColorRect = $Red
@onready var action_progress_bar: TextureProgressBar = $ActionProgressBar
@onready var health_bar: ProgressBar = $HealthBar
@onready var hunger_bar: ProgressBar = $HungerBar

## Set in level local_player setter
var local_player: Player

const WEAK_RED_PERCENTAGE: float = 0.31
const SHOCK_RED_MULTIPLIER: float = 3
const MAX_RED: float = 0.5

func _process(_delta: float) -> void:
	if local_player:
		health_bar.value = health_bar.max_value * local_player.health_component.hp / local_player.health_component.max_hp
		hunger_bar.value = hunger_bar.max_value * local_player.hunger_component.food / local_player.hunger_component.max_food
		
		if local_player.display_use_button_held_percentage:
			action_progress_bar.value = local_player.display_use_button_held_percentage * action_progress_bar.max_value
		else:
			action_progress_bar.value = 0
		
		var shock_percentage: float = local_player.health_component.get_shock_percentage()
		
		if local_player.health_component.is_alive():
			red.color.a = shock_percentage * SHOCK_RED_MULTIPLIER + min(local_player.health_component.get_weakness_percentage() * WEAK_RED_PERCENTAGE, WEAK_RED_PERCENTAGE)
			red.color.a = min(red.color.a, MAX_RED)
		else:
			red.color.a = 0
