extends Area2D
class_name PlayerCar

@onready var engine_sound: AudioStreamPlayer = $EngineSound
@onready var impact_sound: AudioStreamPlayer = $ImpactSound
@onready var get_fuel_sound: AudioStreamPlayer = $GetFuelSound

@onready var sprite: AnimatedSprite2D = $Sprite

@onready var timer: Timer = $Timer

const NORMAL_MAX_SPEED : float = 2.5
const BOOST_MAX_SPEED : float = 4.0
const DEBOOST_MAX_SPEED : float = 1.0
const EDGE_MAX_SPEED : float = 0.5
const BOOST_DURATION : float = 2.0

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
var time_up : bool = false

var pitch_effect : AudioEffectPitchShift

const MAX_FUEL : float = 270.0
var fuel : float = MAX_FUEL
var consumption_rate = MAX_FUEL / (NORMAL_MAX_SPEED * 45)
var low_fuel : bool = false
var out_of_fuel : bool = false

#var game_over : bool = false

signal got_boost
signal got_deboost
signal checkpoint_reached
signal has_low_fuel
signal enough_fuel
signal game_over

func _ready() -> void:
	sprite.speed_scale = 0.0
	set_physics_process(false)
	
func start():
	pitch_effect = AudioServer.get_bus_effect(2, 0)
	set_physics_process(true)
	engine_sound.play()
	

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
	
	if !out_of_fuel and !time_up:
		if vert_acceleration > 0 and !out_of_fuel:
			speed = move_toward(speed, max_speed, vert_acceleration * delta)

		elif is_zero_approx(vert_acceleration):
			speed = move_toward(speed, 0.0, 0.075 * delta)
	
	if out_of_fuel:
		speed = move_toward(speed, 0.0, 0.25 * delta)
		if is_zero_approx(speed):
			stop_car()
			
	elif time_up:
		speed = move_toward(speed, 0.0, delta)
		if is_zero_approx(speed):
			stop_car()

	if speed > 0.05:
		rotation_degrees = 5 * (horiz_acceleration / 512)
		position.x = clamp(position.x + horiz_acceleration * delta, 80, 1000)

	fuel = clampf(fuel - consumption_rate * speed * delta, 10, MAX_FUEL)
	if fuel < 44 and !low_fuel:
		low_fuel = true
		has_low_fuel.emit()
	if fuel <= 10:
		out_of_fuel = true
	
	pitch_effect.pitch_scale = clampf(speed * 0.75, 0.5, 2.5)
	#engine_sound.pitch_scale = clampf(speed * 0.75, 0.5, 3.0)
	sprite.speed_scale = speed / BOOST_MAX_SPEED

func stop_car():
	set_physics_process(false)
	engine_sound.stop()
	game_over.emit()		

func _on_area_entered(area: Area2D) -> void:
	if area is EnemyCar:
		if !bumped:
			impact_sound.play()
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
		area.queue_free()
		get_fuel_sound.play()
		fuel = clampf(fuel + MAX_FUEL * 0.5, 10, MAX_FUEL)
		if out_of_fuel:
			out_of_fuel = false
		if low_fuel:
			low_fuel = false
			enough_fuel.emit()
	elif area is GoalLine:
		if time_up:
			time_up = false
		checkpoint_reached.emit()
		
	else:	
		max_speed = EDGE_MAX_SPEED
		on_edge = true



func _on_area_exited(area: Area2D) -> void:
	if area is Boost:
		if area.type == 0:
			timer.start(BOOST_DURATION)
		else:
			deboosted = false

	else:
		max_speed = 2.5
		max_vert_acceleration = 0.75
		on_edge = false


func _on_timer_timeout() -> void:
	boosted = false
