extends Area2D
class_name Boost

@onready var sprite_2d: Sprite2D = $Sprite2D

var type : int = 0

func _ready() -> void:
	if type == 1:
		sprite_2d.rotation = PI
		sprite_2d.modulate = Color.RED

func _physics_process(delta: float) -> void:
	position.y += Globals.car.speed * Globals.speed_ratio * delta
	if position.y > 2500:
		queue_free()
