extends RigidBody3D

@export var immune_health_component: HealthComponent

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		var collider: Object = state.get_contact_collider_object(0)
		if collider is DamagableBone:
			if immune_health_component:
				if not immune_health_component.non_vital_bones.has(collider) or immune_health_component.vital_bones.has(collider):
					collider.hit.emit(state.get_contact_impulse(0).length())
			else:
				collider.hit.emit(state.get_contact_impulse(0).length())
