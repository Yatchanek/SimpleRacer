extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var road: Sprite2D = $Road
@onready var car: PlayerCar = $Car
@onready var car_spawn_timer: Timer = $CarSpawnTimer
@onready var power_up_spawn_timer: Timer = $PowerUpSpawnTimer
@onready var goal_timer: Timer = $GoalTimer
@onready var joystick: Control = %Joystick
@onready var game_over_sound: AudioStreamPlayer = $Sounds/GameOver
@onready var extended_play_sound: AudioStreamPlayer = $Sounds/ExtendedPlay
@onready var beep_low: AudioStreamPlayer = $Sounds/BeepLow
@onready var beep_high: AudioStreamPlayer = $Sounds/BeepHigh

@onready var jam_detector: Area2D = $JamDetector
@onready var hud: HUD = $HUD


@export var enemy_car_scene : PackedScene
@export var goal_line_scene : PackedScene
@export var boost_scene : PackedScene
@export var canister_scene : PackedScene

var min_spawn_interval : float = 1.2
var max_spawn_interval : float = 2.0
var min_spawn_dist_interval : float = 3.5
var max_spawn_dist_interval : float = 6.0
var next_spawn_dist : float 
var enemy_count : int = 0
var last_boost_in : int = 0
var last_deboost_in : int = 0
var last_canister_in : int = 0

var total_dist : float = 0.0
var covered_distance: float = 0.0
var current_dist : float = 0.0

var distance_to_goal : float = 60
var goal_placed : bool = false


var car_placement_side_offset : int = 30
var car_placement_separation_offset : int

var car_spawn_spots : int = 4
var current_stage : int = 1
var max_enemies : int = 2

var next_goal : float = 0
var goal : Area2D

var previous_positions : Array[int] = []

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneChanger.scene_changed.connect(_on_scene_changed)
	set_process(false)
	Globals.speed_ratio = road.texture.get_height()
	Globals.car = car
	Globals.joystick = joystick
	distance_to_goal = 1500 / (Globals.speed_ratio * 0.01)
	hud.update_time(ceil((distance_to_goal / car.NORMAL_MAX_SPEED) * 1.25))
	if FileAccess.file_exists("user://score.sav"):
		var f : FileAccess = FileAccess.open("user://score.sav", FileAccess.READ)
		Globals.best_distance = f.get_float()
		
	hud.update_best_distance(Globals.best_distance * Globals.speed_ratio * 0.01)
	recalculate_car_placement()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dist_travelled : float = car.speed * delta
	total_dist += dist_travelled
	current_dist += dist_travelled
	covered_distance += dist_travelled
	if covered_distance >= next_spawn_dist:
		spawn_car()
		covered_distance -= next_spawn_dist
		next_spawn_dist = randf_range(min_spawn_interval, max_spawn_interval)
	road.material.set_shader_parameter("dist", total_dist)
	
	hud.update_time(goal_timer.time_left)
	hud.update_distance(current_dist / distance_to_goal)
	hud.update_total_distance(total_dist * Globals.speed_ratio * 0.01)
	hud.update_fuel()

	if distance_to_goal - current_dist < 2 and !goal_placed:
		var goal_line : Area2D = goal_line_scene.instantiate()
		goal_line.position.x = 540
		goal_line.position.y = car.position.y - (distance_to_goal - current_dist) * Globals.speed_ratio
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
	if jam_detector.get_overlapping_areas().size() > 0 or enemy_count >= max_enemies:
		return
		
	var enemy_car = enemy_car_scene.instantiate()
	enemy_car.initialize(current_stage)
	var roll : float = randf()
	var position_offset : int = get_spawn_offset()

	while previous_positions.has(position_offset):
		position_offset = get_spawn_offset()
		
	previous_positions.append(position_offset)
	if previous_positions.size() > 3:
		previous_positions.pop_front()
	enemy_car.position = Vector2(car_placement_side_offset + car_placement_separation_offset * 0.5 + position_offset * car_placement_separation_offset, -128)
	enemy_car.tree_exited.connect(_on_enemy_deleted)
	call_deferred("add_child", enemy_car)
	enemy_count += 1

func get_spawn_offset() -> int:
	var position_offset : int
	
	position_offset  = randi_range(0, car_spawn_spots - 1)
		
	return position_offset

func play_low_beep():
	beep_low.play()
	
func play_high_beep():
	beep_high.play()

func _on_enemy_deleted():
	enemy_count -= 1
	spawn_car()

func _on_car_checkpoint_reached():
	current_dist = 0
	distance_to_goal = ceil(distance_to_goal * 1.1)
	goal_timer.start(goal_timer.time_left + ceil(distance_to_goal / car.NORMAL_MAX_SPEED) * 0.95)
	goal_placed = false
	min_spawn_interval = clampf(min_spawn_interval -0.1, 2.5, 3.5)
	max_spawn_interval = clampf(max_spawn_interval -0.1, 5.0, 6.0)
	current_stage += 1
	if current_stage % 3 == 0:	
		max_enemies = min(max_enemies + 1, 5)
	car_spawn_spots = min(car_spawn_spots + 1, 8)
	recalculate_car_placement()
	hud.show_extended_play_message()
	extended_play_sound.play()

func _on_timer_timeout() -> void:
	if car.speed < 0.25:
		car_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval))
		return		

	if jam_detector.get_overlapping_areas().size() > 0 or enemy_count > max_enemies:
		car_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval) / (car.speed / car.max_speed))	
		return
		

	spawn_car()
	
	car_spawn_timer.start(randf_range(min_spawn_interval, max_spawn_interval) / (car.speed / car.max_speed))

func _on_power_up_spawn_timer_timeout() -> void:
	if car.speed < 0.25:
		return
	
	var current_time = Time.get_ticks_msec()
	if (current_time - last_boost_in > 8000 and distance_to_goal - current_dist > 4 and randf() < 0.25) or current_time - last_boost_in > 11000:
		spawn_boost(0)
		last_boost_in = current_time
	elif current_time - last_deboost_in > 11000 and distance_to_goal - current_dist > 4 and randf() < 0.25:
		spawn_boost(1)
		last_deboost_in = current_time
	
	if (car.fuel < car.MAX_FUEL * 0.75 and current_time - last_canister_in > 10000 and randf() < 0.125) or (car.fuel < car.MAX_FUEL * 0.1 and current_time - last_canister_in > 5000):
		spawn_canister()
		last_canister_in = current_time	
		
	
func _on_goal_timer_timeout() -> void:
	car.time_up = true



func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	MusicManager.play_track(randi_range(MusicManager.Music.TRACK_1, MusicManager.Music.TRACK_2))
	set_process(true)
	car.start()
	next_spawn_dist = randf_range(min_spawn_dist_interval, max_spawn_dist_interval)
	#car_spawn_timer.start(2.0)
	last_boost_in = Time.get_ticks_msec()
	last_deboost_in = last_boost_in
	last_canister_in = last_boost_in
	power_up_spawn_timer.start()
	goal_timer.start(ceil((distance_to_goal / car.NORMAL_MAX_SPEED) * 1.25))
	


func _on_car_got_boost() -> void:
	hud.show_boost_message()


func _on_car_has_low_fuel() -> void:
	hud.show_low_fuel_warning()


func _on_car_enough_fuel() -> void:
	hud.hide_low_fuel_warning()


func _on_car_game_over() -> void:
	hud.show_game_over_message()
	game_over_sound.play()
	if total_dist > Globals.best_distance:
		Globals.best_distance = total_dist
		hud.update_best_distance(total_dist * Globals.speed_ratio * 0.01)
		var f : FileAccess = FileAccess.open("user://score.sav", FileAccess.WRITE)
		f.store_float(Globals.best_distance)

func _on_scene_changed():
	
	animation_player.play("StartSequence")
