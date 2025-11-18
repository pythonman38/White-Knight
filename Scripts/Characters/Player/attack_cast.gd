extends RayCast3D

func deal_damage(damage: float, critical_chance: float) -> void:
	if not is_colliding(): return
	var is_critical = randf() <= critical_chance
	var collider = get_collider()
	if collider is Enemy:
		collider.health_component.take_damage(damage, is_critical)
	add_exception(collider)
