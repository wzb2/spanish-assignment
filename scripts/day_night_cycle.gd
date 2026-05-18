extends Node3D

class_name DayNightCycle

@export var freeze: bool = false

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export var seconds_per_day: float = 100

@export var sun_color: Gradient = preload("res://day_night_cycle/sun_color.tres")
@export var sun_intensity: Curve = preload("res://day_night_cycle/sun_intensity.tres")

@export var moon_color: Gradient = preload("res://day_night_cycle/moon_color.tres")
@export var moon_intensity: Curve = preload("res://day_night_cycle/moon_intensity.tres")

@export var sky_top_color: Gradient = preload("res://day_night_cycle/sky_top_color.tres")
@export var sky_horizon_color: Gradient = preload("res://day_night_cycle/sky_horizon_color.tres")
@export var sky_energy_multiplier: Curve = preload("res://day_night_cycle/sky_energy_multiplier.tres")

@export var fog_energy: Curve = preload("res://day_night_cycle/fog_energy.tres")

@export var day: float = 0.25

func _ready() -> void:
	update()

func _process(delta: float) -> void:
	if not freeze:
		day += delta / seconds_per_day
		
		update()

func update() -> void:
	var time_of_day: float = day - floor(day)
	
	sun.rotation.x = time_of_day * TAU + PI * 0.5
	moon.rotation.x = time_of_day * TAU + PI * 1.5
	sun.light_color = sun_color.sample(time_of_day)
	sun.light_energy = sun_intensity.sample(time_of_day)
	
	moon.light_color = moon_color.sample(time_of_day)
	moon.light_energy = moon_intensity.sample(time_of_day)
	
	var sky_material: ProceduralSkyMaterial = world_environment.environment.sky.sky_material
	sky_material.sky_top_color = sky_top_color.sample(time_of_day)
	sky_material.sky_horizon_color = sky_horizon_color.sample(time_of_day)
	sky_material.sky_energy_multiplier = sky_energy_multiplier.sample(time_of_day)
	
	world_environment.environment.fog_light_energy = fog_energy.sample(time_of_day)
	
	sun.visible = sun.light_energy > 0
	moon.visible = moon.light_energy > 0
