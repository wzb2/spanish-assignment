extends Control

@onready var join_code_editor: LineEdit = $VBoxContainer/JoinCode
@onready var looking_for_router_panel: Panel = $Panel

@onready var local_button: Button = $VBoxContainer/HBoxContainer/LocalButton
@onready var lan_button: Button = $VBoxContainer/HBoxContainer/LANButton
@onready var public_button: Button = $VBoxContainer/HBoxContainer/PublicButton
@onready var world_option_button: OptionButton = $VBoxContainer/WorldOptionButton
var world_option_paths: Array[String] = ["res://levels/level/world.tscn"]


func _ready() -> void:
	GameManager.game_menu_open = true
	MultiplayerManager.host_attempt_failed.connect(looking_for_router_panel.hide)
	
	match MultiplayerManager.mode:
		MultiplayerManager.Mode.LOCAL:
			local_button.button_pressed = true
			
		MultiplayerManager.Mode.LAN:
			lan_button.button_pressed = true
			
		MultiplayerManager.Mode.PUBLIC:
			public_button.button_pressed = true
		
		_:
			print("Invalid host mode")


func _on_host_pressed() -> void:
	looking_for_router_panel.show()
	MultiplayerManager.world_path = world_option_paths[world_option_button.selected]
	MultiplayerManager.host()
	

func _on_join_pressed() -> void:
	var code: String = join_code_editor.text
	if JoinCode.is_code_valid(code):
		MultiplayerManager.join(code)
		MultiplayerManager.latest_game_code = code
	else:
		print("Join code invalid. ")



func _on_join_code_text_changed(current_text: String) -> void:
	var caret_column: int = join_code_editor.caret_column
	var valid_text: String = ""
	var valid_chars: String = JoinCode.LETTERS + JoinCode.PERIOD_CHAR + JoinCode.SEPERATOR_CHAR
	var upper_text: String = current_text.to_upper()
	
	for c in upper_text:
		if valid_chars.contains(c):
			valid_text += c
	
	join_code_editor.text = valid_text
	
	if upper_text != valid_text:
		join_code_editor.caret_column = caret_column - 1
	else:
		join_code_editor.caret_column = caret_column
	


func _on_local_button_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.LOCAL
	lan_button.button_pressed = false
	public_button.button_pressed = false

func _on_lan_button_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.LAN
	local_button.button_pressed = false
	public_button.button_pressed = false

func _on_public_button_pressed() -> void:
	MultiplayerManager.mode = MultiplayerManager.Mode.PUBLIC
	lan_button.button_pressed = false
	local_button.button_pressed = false
