extends Area2D
class_name PlayerCar

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var timer: Timer = $Timer

const NORMAL_MAX_SPEED : float = 2.5
const BOOST_MAX_SPEED : float = 4.0
const DEBOOST_MAX_SPEED : float = 1.0
const EDGE_MAX_SPEED : float = 0.5

var horiz_acceleration : float = 0
var vert_acceleration : float = 0

var max_vert_acceleration : float = 0.75
var max_horiz_acceleration : float = 512

var max_speed : float = NORMAL_MAX_SPEED
var speed : float = 0

var bumped : bool = false
var boosted : bool = false
var deboosted : bool = false
var on_edge : bool = false

var fuel : float = 100.0
var consumption_rate = 0.75
var out_of_fuel : bool = false

var game_over : bool = false

signal got_boost
signal got_deboost


func _ready() -> void:
	set_physics_process(false)
	
func start():
	set_physics_process(true)
	audio_stream_player.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	horiz_acceleration = Globals.joystick.output.x * max_horiz_acceleration
	vert_acceleration = -Globals.joystick.output.y * max_vert_acceleration
	
	if max_speed > NORMAL_MAX_SPEED and !boosted:
		max_speed = move_toward(max_speed, NORMAL_MAX_SPEED, 0.75 * delta)
	
	elif max_speed < NORMAL_MAX_SPEED and !deboosted and !on_edge:
		max_speed = move_toward(max_speed, NORMAL_MAX_SPEED, 0.25 * delta)
		
	if bumped:
		speed = move_toward(speed, 0, max_vert_acceleration * 15 * delta)
		if speed < 0.1:
			speed = 0.1
			bumped = false

	elif vert_acceleration < 0:
		vert_acceleration *= 5
		speed = move_toward(speed, 0, -vert_acceleration * delta)
	
	elif vert_acceleration > 0 and !out_of_fuel:

		speed = move_toward(speed, max_speed, vert_acceleration * delta)

	elif is_zero_approx(vert_acceleration):
		speed = move_toward(speed, 0.0, 0.075 * delta)
	
	elif out_of_fuel:
		speed = move_toward(speed, 0.0, 0.2 * delta)
		if is_zero_approx(speed):
			set_physics_process(false)
			await get_tree().create_timer(1.0).timeout
			get_tree().reload_current_scene()	

	if speed > 0.05:
		rotation_degrees = 5 * (horiz_acceleration / 512)
		position.x = clamp(position.x + horiz_acceleration * delta, 80, 1000)

	fuel = clampf(fuel - consumption_rate * speed * delta, 0, 100)
	if fuel <= 0:
		out_of_fuel = true
	
	audio_stream_player.pitch_scale = max(speed, 0.5)

func _on_area_entered(area: Area2D) -> void:
	if area is EnemyCar:
		bumped = true
	elif area is Boost:
		if area.type == 0:
			boosted = true
			max_speed = BOOST_MAX_SPEED
			max_vert_acceleration = 1.5
			got_boost.emit()
		else:
			deboosted = true
			max_speed = DEBOOST_MAX_SPEED
			got_deboost.emit()
	elif area is Canister:
		fuel = clampf(fuel + 50, 0, 100)
	else:	
		max_speed = EDGE_MAX_SPEED
		on_edge = true



func _on_area_exited(area: Area2D) -> void:
	if area is Boost:
		if area.type == 0:
			timer.start()
		else:
			deboosted = false
	elif area is Canister:
		area.queue_free()
	else:
		max_speed = 2.5
		max_vert_acceleration = 0.75
		on_edge = false


func _on_timer_timeout() -> void:
	boosted = false
