extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var logo: TextureRect = $Logo
@onready var spawn_timer: Timer = $SpawnTimer

@onready var options_container: PanelContainer = $OptionsContainer
@onready var left_handed_mode_check: TextureRect = %LeftHandedModeCheck
@onready var master_volume_gauge: CustomGauge = %MasterVolumeGauge
@onready var effects_volume_gauge: CustomGauge = %EffectsVolumeGauge
@onready var engine_volume_gauge: CustomGauge = %EngineVolumeGauge
@onready var music_volume_gauge: CustomGauge = %MusicVolumeGauge

@onready var swipe_sound: AudioStreamPlayer = $SwipeSound


@export var car_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_custom_mouse_cursor(load("res://graphics/cursor_car.png"), Input.CURSOR_ARROW, Vector2(9, 9))
	Settings.settings_loaded.connect(_on_settings_loaded)
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

func play_swipe_sound():
	swipe_sound.play()
	
func start_music():
	MusicManager.play_track(MusicManager.Music.TITLE_SCREEN)

func _on_start_game_button_pressed() -> void:
	if options_container.scale.x < 0.5:
		MusicManager.fade_out()
		spawn_timer.stop()
		SceneChanger.change_scene("res://scenes/game.tscn")


func _on_options_button_pressed() -> void:
	animation_player.play("OpenOptions")

func _on_close_options_pressed() -> void:
	Settings.save_settings()
	animation_player.play_backwards("OpenOptions")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	spawn_timer.start(1.0)
	

func _on_spawn_timer_timeout() -> void:
	spawn_car()

func _on_scene_changed():
	logo.hide()
	animation_player.current_animation = "TitleAnimation"
	animation_player.seek(5.5, true)
	animation_player.play()


func _on_settings_loaded():
	master_volume_gauge.current_value = Settings.master_volume
	master_volume_gauge.update()
	
	effects_volume_gauge.current_value = Settings.effects_volume
	effects_volume_gauge.update()
	
	engine_volume_gauge.current_value = Settings.engine_volume
	engine_volume_gauge.update()
	
	music_volume_gauge.current_value = Settings.music_volume
	music_volume_gauge.update()
	
	left_handed_mode_check.visible = Settings.left_handed_mode
	

func _on_master_volume_gauge_value_changed(value: int, step : float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value * step))
	Settings.master_volume = value


func _on_effects_volume_gauge_value_changed(value: int, step : float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value * step))
	Settings.effects_volume = value


func _on_engine_volume_gauge_value_changed(value: int, step : float) -> void:
	AudioServer.set_bus_volume_db(2, linear_to_db(value * step))
	Settings.engine_volume = value
	

func _on_music_volume_gauge_value_changed(value: int, step : float) -> void:
	AudioServer.set_bus_volume_db(3, linear_to_db(value * step))
	Settings.music_volume = value


func _on_left_handed_mode_check_button_released() -> void:
	left_handed_mode_check.visible = !left_handed_mode_check.visible
	Settings.left_handed_mode = !Settings.left_handed_mode
