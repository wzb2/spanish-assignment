extends Node

signal game_menu_visibility_changed
signal close_all_menus

var loading_state: String = ""

var game_menu_open: bool = false:
	set(value):
		game_menu_visibility_changed.emit()
		if value:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode.call_deferred(Input.MOUSE_MODE_CAPTURED)
		game_menu_open = value

var mouse_eaten: bool:
	get():
		return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	assert(self.get_class() == "Node", "GameManager class is " + self.get_class() + ". Path: " + str(get_path()))
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif not game_menu_open:
		if event is InputEventMouseButton:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
