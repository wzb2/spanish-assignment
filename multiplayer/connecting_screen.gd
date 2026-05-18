extends CanvasLayer

@onready var connecting_label: Label = $Control/Panel/VBoxContainer/Label
@onready var warning_label: Label = $Control/Panel/VBoxContainer/WarningLabel
@onready var message_timer: Timer = $Control/MessageTimer

func _ready() -> void:
	message_timer.timeout.connect(_on_message_timer_timeout)
	GameManager.game_menu_open = true
	if not multiplayer.is_server():
		connecting_label.text = "Conecting to " + MultiplayerManager.latest_game_code
		await MultiplayerManager.connection_confirmed
	hide()
	GameManager.game_menu_open = false
	


func _on_cancel_button_pressed() -> void:
	MultiplayerManager.disconnect_from_server()
	


func _on_message_timer_timeout() -> void:
	warning_label.show()
