extends DamagableBone

@export var immune_health_component: HealthComponent

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision3D = move_and_collide(linear_velocity * delta)
	if collision:
		var collider: Object = collision.get_collider(0)
		if collider is DamagableBone:
			if immune_health_component:
				if not (immune_health_component.non_vital_bones.has(collider) or immune_health_component.vital_bones.has(collider)):
					collider.hit.emit((linear_velocity - collider.linear_velocity).length() * 0.05)
			else:
				collider.hit.emit((linear_velocity - collider.linear_velocity).length() * 0.05)
