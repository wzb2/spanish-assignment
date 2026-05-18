extends CanvasLayer

class_name LoadingScreen

const FADE_OUT_TIME: float = 1.0

@onready var color_rect: ColorRect = $ColorRect
@onready var progress_label: Label = $ProgressLabel

func open() -> void:
	color_rect.modulate.a = 1
	show()

func close() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(color_rect ,"modulate", Color(color_rect.modulate, 0), FADE_OUT_TIME)
	tween.tween_callback(hide)
	GameManager.loading_state = ""

func _process(_delta: float) -> void:
	if visible:
		progress_label.text = GameManager.loading_state
