extends Node2D


@onready var road: Sprite2D = $Road
@onready var car: PlayerCar = $Car
@onready var timer: Timer = $Timer
@onready var joystick: Control = %Joystick
@onready var goal_timer: Timer = $GoalTimer
@onready var jam_detector: Area2D = $JamDetector
@onready var hud: HUD = $HUD


@export var enemy_car_scene : PackedScene
@export var goal_line_scene : PackedScene
@export var boost_scene : PackedScene
@export var canister_scene : PackedScene

var min_spawn_interval : float = 1.2
var max_spawn_interval : float = 2.0
var enemy_count : int = 0
var last_boost_in : int = 0
var last_deboost_in : int = 0
var last_canister_in : int = 0

var total_dist : float = 0.0
var current_dist : float = 0.0

var distance_to_goal : float = 60
var goal_placed : bool = false


var car_placement_side_offset : int = 30
var car_placement_separation_offset : int

var car_spawn_spots : int = 4
var current_stage : int = 1
var max_enemies : int = 4

var next_goal : float = 0
var goal : Area2D

var previous_positions : Array[int] = []

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	Globals.speed_ratio = road.texture.get_height()
	Globals.car = car
	Globals.joystick = joystick
	distance_to_goal = 1500 / (Globals.speed_ratio * 0.01)
	hud.update_time(ceil((distance_to_goal / car.NORMAL_MAX_SPEED) * 1.15))
	recalculate_car_placement()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dist_travelled : float = car.speed * delta
	total_dist += dist_travelled
	current_dist += dist_travelled
	road.material.set_shader_parameter("dist", total_dist)
	
	hud.update_time(goal_timer.time_left)
	hud.update_distance(current_dist / distance_to_goal)
	hud.update_fuel()

	if distance_to_goal - current_dist < 2 and !goal_placed:
		var goal_line : Area2D = goal_line_scene.instantiate()
		goal_line.position.x = 540
		goal_line.position.y = car.position.y - (distance_to_goal - current_dist) * Globals.speed_ratio
		goal_line.goal_reached.connect(_on_goal_reached)
		goal = goal_line
		goal_placed = true
		call_deferred("add_child", goal_line)


func recalculate_car_placement():
	car_placement_separation_offset = floori((1080 - 2 * car_placement_side_offset) / car_spawn_spots)

func spawn_boost(type : int):
	var boost = boost_scene.instantiate() as Boost
	boost.type = type
	boost.position = Vector2(randf_range(160, 920), -Globals.car.max_speed * Globals.speed_ratio * 3)
	call_deferred("add_child", boost)

	hud.show_boost_indicator(type, boost.position)
	

func spawn_canister():
	var canister = canister_scene.instantiate() as Canister
	canister.position = Vector2(randf_range(160, 920), -Globals.car.max_speed * Globals.speed_ratio * 3)
	call_deferred("add_child", canister)

	hud.show_canister(canister.position)	

func spawn_car():
	var enemy_car = enemy_car_scene.instantiate()
	enemy_car.initialize(current_stage)
	var position_offset : int = randi_range(0, car_spawn_spots - 1)
	while previous_positions.has(position_offset):
		position_offset = randi_range(0, car_spawn_spots - 1)
		
	previous_positions.append(position_offset)
	if previous_positions.size() > 2:
		previous_positions.pop_front()
	enemy_car.position = Vector2(car_placement_side_offset + car_placement_separation_offset * 0.5 + position_offset * car_placement_separation_offset, -128)
	enemy_car.tree_exited.connect(_on_enemy_deleted)
	call_deferred("add_child", enemy_car)
	enemy_count += 1	

func _on_enemy_deleted():
	enemy_count -= 1

func _on_goal_reached():
	current_dist = 0
	distance_to_goal = ceil(distance_to_goal * 1.1)
	goal_timer.start(goal_timer.time_left + ceil(distance_to_goal / car.max_speed) * 1.05)
	goal_placed = false
	min_spawn_interval = clampf(min_spawn_interval -0.2, 0.5, 1.2)
	max_spawn_interval = clampf(max_spawn_interval -0.2, 0.8, 2.0)
	current_stage += 1
	max_enemies = min(max_enemies + 1, 7)
	car_spawn_spots = min(car_spawn_spots + 1, 8)
	hud.show_extended_play_message()

func _on_timer_timeout() -> void:
	var current_time = Time.get_ticks_msec()
	if (current_time - last_boost_in > 10000 and distance_to_goal - current_dist > 4 and randf() < 0.25) or current_time - last_boost_in > 15000:
		spawn_boost(0)
		last_boost_in = current_time
	elif current_time - last_deboost_in > 15000 and distance_to_goal - current_dist > 4 and randf() < 0.25:
		spawn_boost(1)
		last_deboost_in = current_time
	
	if (car.fuel < 75 and current_time - last_canister_in > 8000 and randf() < 0.05) or (car.fuel < 10 and current_time - last_canister_in > 5000):
		spawn_canister()
		last_canister_in = current_time

	if jam_detector.get_overlapping_areas().size() > 0 or enemy_count > max_enemies:
		timer.start(randf_range(min_spawn_interval, max_spawn_interval))		
	
	elif Globals.car.speed > 0.25:	
		spawn_car()

	timer.start(randf_range(min_spawn_interval, max_spawn_interval))


func _on_goal_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	set_process(true)
	car.start()
	timer.start(2.0)
	goal_timer.start(ceil((distance_to_goal / car.NORMAL_MAX_SPEED) * 1.25))
	


func _on_car_got_boost() -> void:
	hud.show_boost_message()
