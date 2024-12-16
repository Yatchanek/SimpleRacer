extends Area2D

var horiz_acceleration : float = 0
var vert_acceleration : float = 0

var max_vert_acceleration : float = 0.75
var max_horiz_acceleration : float = 384

var max_speed : float = 2.5
var speed : float = 0

var bumped : bool = false
var boosted : bool = false
var deboosted : bool = false

signal got_boost
signal got_deboost


func _ready() -> void:
	set_physics_process(false)
	
func start():
	set_physics_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	horiz_acceleration = Globals.joystick.output.x * max_horiz_acceleration
	vert_acceleration = -Globals.joystick.output.y * max_vert_acceleration
	
	if max_speed > 2.5 and !boosted:
		max_speed = move_toward(max_speed, 2.5, 0.75 * delta)
	
	elif max_speed < 2.5 and !deboosted:
		max_speed = move_toward(max_speed, 2.5, 0.25 * delta)
		
	if vert_acceleration < 0 and !bumped:
		vert_acceleration *= 5
	
	if bumped:
		speed = move_toward(speed, 0, max_vert_acceleration * 15 * delta)
		if speed < 0.1:
			speed = 0.1
			bumped = false
			
	elif vert_acceleration != 0:
		speed = move_toward(speed, max_speed, vert_acceleration * delta)
		if speed < 0:
			speed = 0
	else:
		speed = move_toward(speed, 0.0, 0.05 * delta)
		

	if speed > 0.05:
		rotation_degrees = 5 * (horiz_acceleration / 512)
		position.x = clamp(position.x + horiz_acceleration * delta, 80, 1000)


func _on_area_entered(area: Area2D) -> void:
	if area is EnemyCar:
		bumped = true
	elif area is Boost:
		if area.type == 0:
			boosted = true
			max_speed = 5.0
			got_boost.emit()
		else:
			deboosted = true
			max_speed = 1.0
			got_deboost.emit()
	else:	
		max_speed = 0.5
		max_vert_acceleration = 1.75


func _on_area_exited(area: Area2D) -> void:
	if area is Boost:
		if area.type == 0:
			boosted = false
		else:
			deboosted = false
	else:
		max_speed = 2.5
		max_vert_acceleration = 0.75
