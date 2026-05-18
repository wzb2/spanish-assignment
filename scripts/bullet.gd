extends MultiplayerRigidBody

class_name Bullet


func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if body is DamagableBone:
		queue_free()
