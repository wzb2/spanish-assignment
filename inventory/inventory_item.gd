extends Resource

class_name InventoryItem

@export var physical_item_path: String
@export var name: String
@export_multiline var description: String
@export var texture: Texture
@export_range(1, 99) var stack_size: int = 1

## Item resource should be duplicated to use
@export var data: Dictionary[String, Variant]

## should be set to true on duplicated resources
var is_original: bool = true

@export_file("*.tres", "*.res") var path: String
