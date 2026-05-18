extends CanvasLayer

class_name GameMenu

func _ready() -> void:
	GameManager.close_all_menus.connect(close)

func open() -> void:
	if not (GameManager.game_menu_open or visible):
		GameManager.game_menu_open = true
		show()

func close() -> void:
	if visible:
		hide()
		GameManager.game_menu_open = false
