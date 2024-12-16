extends Node2D


@onready var road: Sprite2D = $Road
@onready var car: Area2D = $Car
@onready var timer: Timer = $Timer
@onready var joystick: Control = $CanvasLayer/Control/Joystick
@onready var goal_timer: Timer = $GoalTimer
@onready var time_label: Label = %TimeLabel
@onready var jam_detector: Area2D = $JamDetector
@onready var dist_label: Label = %DistLabel
@onready var extended_play_label: Label = %ExtendedPlayLabel
@onready var boost_label: Label = %BoostLabel
@onready var deboost_label: Label = %DeboostLabel

@export var enemy_car_scene : PackedScene
@export var goal_line_scene : PackedScene
@export var boost_scene : PackedScene

var min_spawn_interval : float = 1.0
var max_spawn_interval : float = 1.5
var enemy_count : int = 0
var last_boost_in : int = 0
var last_deboost_in : int = 0

var total_dist : float = 0.0
var current_dist : float = 0.0

var distance_to_goal : float = 60
var goal_placed : bool = false


var next_goal : float = 0
var goal : Area2D

var previous_positions : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	Globals.speed_ratio = road.texture.get_height()
	Globals.car = car
	Globals.joystick = joystick
	distance_to_goal = 1500 / (Globals.speed_ratio * 0.01)
	time_label.text = "Time left: %.1fs" % ceil((distance_to_goal / car.max_speed) * 1.25)
	dist_label.text = "Checkpoint: %d" % [(distance_to_goal - current_dist) * Globals.speed_ratio * 0.01]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dist_travelled : float = car.speed * delta
	total_dist += dist_travelled
	current_dist += dist_travelled
	road.material.set_shader_parameter("dist", total_dist)

	time_label.text = "Time left: %.1fs" % goal_timer.time_left
	dist_label.text = "Checkpoint: %d" % [(distance_to_goal - current_dist) * Globals.speed_ratio * 0.01]


	if distance_to_goal - current_dist < 2 and !goal_placed:
		var goal_line : Area2D = goal_line_scene.instantiate()
		goal_line.position.x = 540
		goal_line.position.y = car.position.y - (distance_to_goal - current_dist) * Globals.speed_ratio
		goal_line.goal_reached.connect(_on_goal_reached)
		goal = goal_line
		goal_placed = true
		call_deferred("add_child", goal_line)

func blink_label(label : Label):
	var tw : Tween = create_tween()
	tw.set_loops(3)
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.1)
	tw.tween_property(label, "modulate:a", 0.0, 0.2)

func _on_enemy_deleted():
	enemy_count -= 1

func _on_goal_reached():
	current_dist = 0
	distance_to_goal = ceil(distance_to_goal * 1.1)
	goal_timer.start(goal_timer.time_left + ceil(distance_to_goal / car.max_speed) * 1.05)
	goal_placed = false
	min_spawn_interval = clampf(min_spawn_interval -0.1, 0.5, 1.0)
	max_spawn_interval = clampf(max_spawn_interval -0.1, 0.7, 1.5)
	extended_play_label.text = "Extended Play!"
	blink_label(extended_play_label)

func _on_timer_timeout() -> void:
	if jam_detector.get_overlapping_areas().size() > 0 or enemy_count > 7:
		timer.start(randf_range(min_spawn_interval, max_spawn_interval))
		return
		
	if Globals.car.speed > 0.25:
		if last_boost_in > 10 and distance_to_goal - current_dist > 4 and randf() < 0.25:
			var boost = boost_scene.instantiate() as Boost
			boost.position = Vector2(randf_range(128, 952), -Globals.car.max_speed * Globals.speed_ratio * 3)
			call_deferred("add_child", boost)
			last_boost_in = 0
			boost_label.position.x = boost.position.x - boost_label.pivot_offset.x
			blink_label(boost_label)
		elif last_deboost_in > 13 and distance_to_goal - current_dist > 4 and randf() < 0.25:
			var boost = boost_scene.instantiate() as Boost
			boost.type = 1
			boost.position = Vector2(randf_range(128, 952), -Globals.car.max_speed * Globals.speed_ratio * 3)
			call_deferred("add_child", boost)
			last_deboost_in = 0
			deboost_label.position.x = boost.position.x - boost_label.pivot_offset.x
			blink_label(deboost_label)			
		else:	
			var enemy_car = enemy_car_scene.instantiate()
			var position_offset : int = randi_range(0, 6)
			while previous_positions.has(position_offset):
				position_offset = randi_range(0, 6)
				
			previous_positions.append(position_offset)
			if previous_positions.size() > 2:
				previous_positions.pop_front()
			enemy_car.position = Vector2(29 + 73 + position_offset * 146, -128)
			enemy_car.tree_exited.connect(_on_enemy_deleted)
			call_deferred("add_child", enemy_car)
			enemy_count += 1
			last_boost_in += 1
			last_deboost_in += 1

	timer.start(randf_range(min_spawn_interval, max_spawn_interval))


func _on_goal_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	set_process(true)
	car.start()
	timer.start(2.0)
	goal_timer.start(ceil((distance_to_goal / car.max_speed) * 1.25))
	


func _on_car_got_boost() -> void:
	print("Got boost")
	extended_play_label.text = "Boost!"
	blink_label(extended_play_label)
