extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var logo: TextureRect = $Logo
@onready var spawn_timer: Timer = $SpawnTimer
@onready var left_handed_mode_check: TextureRect = %LeftHandedModeCheck
@onready var options_container: PanelContainer = $OptionsContainer

@export var car_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneChanger.scene_changed.connect(_on_scene_changed)
	if !Globals.first_run:
		Globals.first_run = true
		animation_player.play("TitleAnimation")


func show_logo():
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_method(set_logo_radius_threshold, 0.0, 0.5, 0.5)
	
func hide_logo():
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_method(set_logo_radius_threshold, 0.5, 0.0, 0.5)	

func set_logo_radius_threshold(radius : float):
	logo.material.set_shader_parameter("threshold", radius)

func spawn_car():
	var car = car_scene.instantiate() as Sprite2D
	car.position = Vector2(randi_range(100, 980), get_viewport_rect().size.y + 250)
	add_child(car)
	spawn_timer.start(randf_range(0.5, 1.0))

func _on_start_game_button_pressed() -> void:
	if options_container.scale.x < 0.5:
		spawn_timer.stop()
		SceneChanger.change_scene("res://scenes/game.tscn")


func _on_options_button_pressed() -> void:
	animation_player.play("OpenOptions")

func _on_close_options_pressed() -> void:
	animation_player.play_backwards("OpenOptions")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	spawn_timer.start(1.0)
	

func _on_spawn_timer_timeout() -> void:
	spawn_car()

func _on_scene_changed():
	animation_player.current_animation = "TitleAnimation"
	animation_player.seek(5.5, true)
	animation_player.play()


func _on_master_volume_gauge_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))


func _on_effects_volume_gauge_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))


func _on_engine_volume_gauge_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value))


func _on_music_volume_gauge_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(3, linear_to_db(value))


func _on_left_handed_mode_check_button_released() -> void:
	left_handed_mode_check.visible = !left_handed_mode_check.visible
	Globals.left_handed_mode = !Globals.left_handed_mode
