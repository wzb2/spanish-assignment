extends GameMenu

class_name EndScreen

@onready var quit_button: Button = $Control/Panel/VBoxContainer/QuitButton
@onready var leave_button: Button = $Control/Panel/VBoxContainer/LeaveButton
@onready var lose_label: Label = $Control/Panel/VBoxContainer/LoseLabel
@onready var win_label: Label = $Control/Panel/VBoxContainer/WinLabel

var game_ended: bool = false

func all_players_dead() -> bool:
	for p: Player in MultiplayerManager.players.values():
		if p.health_component.is_alive():
			return false
	return true

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		if all_players_dead() and not game_ended:
			end_game.rpc(false)


@rpc("call_local")
func end_game(win: bool) -> void:
	game_ended = true
	GameManager.close_all_menus.emit()
	
	if win:
		win_label.show()
	else:
		lose_label.show()
	
	quit_button.hide()
	leave_button.hide()
	if multiplayer.is_server():
		quit_button.show()
	else:
		leave_button.show()
	open()



func _on_quit_button_pressed() -> void:
	MultiplayerManager.close_server()


func _on_leave_button_pressed() -> void:
	MultiplayerManager.disconnect_from_server()
