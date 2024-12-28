extends Sprite2D

var speed : float = 0.0
var target_speed : float

var turn_force : float

var elapsed_time : float = 0.0
var is_turning : bool = false
var turn_chance : float = 0.1
var turn_direction : int = 0
var turn_duration : float


func _ready() -> void:
	region_rect.position.x = randi_range(0, 4) * 116
	target_speed = randf_range(0.65, 0.85) * get_viewport_rect().size.y
	speed = target_speed * 0.5
	turn_force = randf_range(0.15, 0.33) * get_viewport_rect().size.x
	turn_duration = randf_range(0.2, 0.3)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	elapsed_time += delta
	if elapsed_time > turn_duration:
		elapsed_time -= turn_duration
		if turn_direction != 0:
			turn_direction = 0
			turn_duration = randf_range(0.2, 0.3)
		elif randf() < turn_chance:
			turn_direction = pow(-1, randi() % 2)
			turn_duration = randf_range(0.3, 0.5)
			
			
	speed = move_toward(speed, target_speed, 0.0175 * target_speed)
	position.y -= speed * delta
	position.x = clampf(position.x + turn_direction * turn_force * delta, 100, 980)
	rotation_degrees = lerp_angle(rotation_degrees, 10 * turn_direction, 0.15)
	if position.y < -130:
		queue_free()
