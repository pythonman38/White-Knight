extends ShapeCast3D

func deal_damage(damage: float) -> void:
	for collision_index in get_collision_count():
		var collider = get_collider(collision_index)
		if collider is Player or collider is Enemy:
			collider.health_component.take_damage(damage)
