extends Area2D

signal goal_reached


func _physics_process(delta: float) -> void:
	position.y += Globals.car.speed * Globals.speed_ratio * delta
	if position.y > 2100:
		queue_free()


func _on_area_entered(_area: Area2D) -> void:
	goal_reached.emit()
