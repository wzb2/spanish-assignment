extends PhysicalItem

const BULLET: PackedScene = preload("res://scenes/bullet.tscn")

const BOX_OF_BULLETS_STRING_NAME: String = "Box of Bullets"

const RELOAD_TIME: float = 2
const MAX_AMMO: int = 6

const RECOIL_FORCE: float = -12
const BULLET_FORCE: float = 25

@onready var light: OmniLight3D = $OmniLight3D
@onready var bullet_spawn_pose: Marker3D = $BulletSpawnPose

func get_current_box_of_bullets() -> InventoryItem:
	if last_grabbed_by_player:
		return last_grabbed_by_player.inventory.get_first_item_occurance(BOX_OF_BULLETS_STRING_NAME, [last_grabbed_by_player.left_hand_slot, last_grabbed_by_player.right_hand_slot], func(item: InventoryItem) -> bool: return item.data.get("remaining_ammo") > 0)
	else:
		return null
	

func _ready() -> void:
	super._ready()
	
	item_resource.data.set("remaining_ammo", MAX_AMMO)


func _process(delta: float) -> void:
	super._process(delta)
	
	var remaining_ammo: int = item_resource.data.get("remaining_ammo")
	
	if remaining_ammo == 0 and get_current_box_of_bullets():
		use_button_hold_time = RELOAD_TIME
	else:
		use_button_hold_time = 0


func _on_use() -> void:
	super._on_use()
	
	var remaining_ammo: int = item_resource.data.get("remaining_ammo")
	if remaining_ammo > 0:
		
		item_resource.data.set("remaining_ammo", remaining_ammo - 1)
		
		apply_impulse(global_basis.y * RECOIL_FORCE)
		
		var bullet: Bullet = BULLET.instantiate()
		get_tree().current_scene.add_child(bullet, true)
		bullet.global_transform = bullet_spawn_pose.global_transform
		
		bullet.apply_central_impulse(bullet_spawn_pose.global_basis.y * BULLET_FORCE)
		
		flash.rpc()


func _on_reached_use_button_hold_time() -> void:
	# reload
	var box_of_bullets: InventoryItem = get_current_box_of_bullets()
	
	if box_of_bullets:
		var box_remaining_ammo: int = box_of_bullets.data.get("remaining_ammo")
		if box_remaining_ammo > 0:
			var bullets_used: int = min(MAX_AMMO, box_remaining_ammo)
			var new_amount_of_ammo: int = box_remaining_ammo - bullets_used
			
			box_of_bullets.data.set("remaining_ammo", new_amount_of_ammo)
			
			item_resource.data.set("remaining_ammo", bullets_used)
	#last_grabbed_by_player.update_inventory_ui_on_client()

@rpc("call_local")
func flash() -> void:
	light.light_energy = 1
	light.show()
	var tween: Tween = create_tween()
	tween.tween_property(light, "light_energy", 0.5, 0.1)
	tween.tween_callback(light.hide)
