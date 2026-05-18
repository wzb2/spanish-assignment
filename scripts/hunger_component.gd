extends Node

class_name HungerComponent

@export var health_component: HealthComponent

@export var max_food: float = 100

@export var starvation_per_second: float = 0.2

@export_range(0, 1) var min_food_percentage_to_heal: float = 0.75
@export_range(0, 1) var max_health_percentage_to_heal: float = 1
@export var hp_per_second: float = 1

@export_range(0, 1) var food_percentage_to_starve: float = 0.25

@export var food: float = max_food


func _process(delta: float) -> void:
	if MultiplayerManager.game_started:
		inflict_hunger(starvation_per_second * delta)
		
		if food / max_food > min_food_percentage_to_heal:
			if health_component.hp < health_component.max_hp * max_health_percentage_to_heal:
				var healing: float = hp_per_second * delta
				health_component.heal(healing)
				food -= healing
	


func inflict_hunger(amount: float) -> void:
	if MultiplayerManager.game_started:
		food -= amount
		if food < 0:
			health_component.inflict_damage(-food)
			food = 0

func feed(amount: float) -> void:
	food += amount
	if food > max_food:
		food = max_food
