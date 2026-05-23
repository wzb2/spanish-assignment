extends Node3D

class_name Beacon

@export_multiline var title: String = "Title"
@export_multiline var description: String = "Description"

func _ready() -> void:
	%TitleLabel.text = title
	%DescriptionLabel.text = description
	
