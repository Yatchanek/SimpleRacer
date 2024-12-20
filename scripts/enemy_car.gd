extends Area2D
class_name EnemyCar


@onready var timer: Timer = $Timer
@onready var turn_timer: Timer = $TurnTimer
@onready var right_raycast: RayCast2D = $SideRaycasts/RightRaycast
@onready var left_raycast: RayCast2D = $SideRaycasts/LeftRaycast
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var horiz_acceleration : float = 0
var vert_acceleration : float = 0

var max_speed : float = 0
var speed : float = 0
var target_speed : float = 0
var h_steering : float = 0

var has_changed_lane : bool = false

var elapsed_time : float = 0.0

var out_of_bonds_check_started : bool = false

var turn_probability : float = 0.2
var steer_power : int

var interest : Array[float] = []
var ray_angles : Array[float] = []
var front_raycasts : Array = []
var side_raycasts : Array = []


func _ready() -> void:
	sprite.region_rect.position.x = 116 * randi_range(0, 4)
	front_raycasts = $Raycasts.get_children()
	side_raycasts = $SideRaycasts.get_children()
	if Globals.car.max_speed <= Globals.car.NORMAL_MAX_SPEED:
		max_speed = Globals.car.speed * randf_range(0.7, 0.9)
	else:
		max_speed = min(Globals.car.speed, 3.25) * randf_range(0.7, 0.9)
	speed = max_speed
	target_speed = max_speed
	interest.resize(5)
	interest.fill(0)
	for ray in front_raycasts:
		ray_angles.append(ray.rotation)
	timer.start()
	turn_timer.start(1.0)

func initialize(current_stage : int):
	turn_probability = min(0.2 + 0.1 * (current_stage - 1), 0.5)
	steer_power = min(192 + 32 * (current_stage - 1), 320)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	speed = move_toward(speed, target_speed, 0.75 * delta)		
	position.y += (Globals.car.speed - speed) * Globals.speed_ratio * delta
	
	var chosen_angle : float = get_context_steering(delta)
	
	var avoidance : float = 0.0
	
	if !is_zero_approx(chosen_angle):
		h_steering = 0.0
		avoidance += 384 * cos(chosen_angle) * sign(chosen_angle)
	
	for ray : RayCast2D in side_raycasts:
		if ray.is_colliding():
		#avoidance = 0.0
			h_steering = 0.0
			break
	
	sprite.rotation_degrees = 5 * (avoidance + h_steering) / 384
	collision_shape.rotation_degrees = sprite.rotation_degrees
	
	position.x = clampf(position.x + (h_steering + avoidance) * delta, 80.0, 1000.0)
	
	if position.y < -160 or position.y > 2150 and !out_of_bonds_check_started:
		out_of_bonds_check_started = true
		timer.start()


func get_context_steering(delta : float) -> float:
	var something_ahead : bool = false
	for i in 5:
		interest[i] = cos(front_raycasts[i].rotation)
		
	for i in 5:
		var raycast : RayCast2D = front_raycasts[i]
		if raycast.is_colliding():
			interest[i] = -0.25
			something_ahead = true
	
	var chosen_angle : float = 0		
	for i in 5:
		chosen_angle += front_raycasts[i].rotation * interest[i]
		
	chosen_angle *= 0.2
	if something_ahead:
		target_speed -= 0.75 * delta
	else:
		target_speed = max_speed
	return chosen_angle

func _on_timer_timeout() -> void:
	if position.y < -160 or position.y > 2150:
		queue_free()
	else:
		out_of_bonds_check_started = false


func _on_turn_timer_timeout() -> void:
	if !has_changed_lane:
		if randf() < turn_probability:
			h_steering = steer_power * pow(-1, randi() % 2)
			has_changed_lane = true
			turn_timer.start(randf_range(1.0, 2.5))
			
	else:
		h_steering = 0
		has_changed_lane = false
		turn_timer.start(randf_range(1.0, 1.75))
