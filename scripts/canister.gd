extends Area2D
class_name Canister


func _physics_process(delta: float) -> void:
	position.y += Globals.car.speed * Globals.speed_ratio * delta
	if position.y > 2200:
		queue_free()
