extends Node3D

class_name Lobby

signal start_game

@onready var start_area: PlayerDetectionArea = $StartArea

const READY_TIME_TO_START: float = 1.0
var current_ready_time: float = 0

func _process(delta: float) -> void:
	if multiplayer.is_server():
		if start_area.all_players_in_area():
			current_ready_time += delta
		else:
			current_ready_time = 0
	
	if current_ready_time > READY_TIME_TO_START:
		start_game.emit()
		#queue_free()
	
