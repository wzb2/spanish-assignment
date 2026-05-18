extends PhysicalItem

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		var collider: Object = state.get_contact_collider_object(0)
		if collider is DamagableBone:
			collider.hit.emit(state.get_contact_impulse(0).length()*1000)
