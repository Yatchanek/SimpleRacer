extends Area2D
class_name GoalLine

signal goal_reached


func _physics_process(delta: float) -> void:
	position.y += Globals.car.speed * Globals.speed_ratio * delta
	if position.y > 2100:
		queue_free()
