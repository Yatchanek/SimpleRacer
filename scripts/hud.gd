extends CanvasLayer
class_name HUD


@onready var extended_play_label: Label = %ExtendedPlayLabel
@onready var boost_indicator: TextureRect = %BoostIndicator
@onready var deboost_indicator: TextureRect = %DeboostIndicator
@onready var canister_icon: TextureRect = %CanisterIcon
@onready var low_fuel_label: Label = %LowFuelLabel
@onready var fuel_gauge: TextureRect = %FuelGauge
@onready var distance_label: Label = %DistanceLabel
@onready var best_distance_label: Label = %BestDistanceLabel
@onready var dashboard: HBoxContainer = %Dashboard

@onready var joystick: Control = %Joystick
@onready var hand: TextureRect = %Hand
@onready var dist_slider: HSlider = %DistSlider
@onready var time_label: Label = %TimeLabel

var low_fuel_tween : Tween

func _ready() -> void:
	if Globals.left_handed_mode:
		dashboard.move_child(joystick, 0)

func update_best_distance(value : float):
	best_distance_label.text = "%d" % int(value)

func update_total_distance(value : float):
	distance_label.text = "%d" % int(value)

func update_time(value : float):
	time_label.text = "%.1fs" % value
	
func update_distance(value : float):
	dist_slider.value = value

func update_fuel():
	hand.rotation_degrees = Globals.car.fuel

func show_boost_indicator(type : int, pos : Vector2):
	if type == 0:
		boost_indicator.position.x = pos.x - boost_indicator.pivot_offset.x
		blink_label(boost_indicator)
	else:
		deboost_indicator.position.x = pos.x - deboost_indicator.pivot_offset.x
		blink_label(deboost_indicator)
	
func show_canister(pos : Vector2):
	canister_icon.position.x = pos.x - canister_icon.pivot_offset.x
	blink_label(canister_icon)

func show_boost_message():
	extended_play_label.text = "Boost!"
	blink_label(extended_play_label)
	
func show_extended_play_message():
	extended_play_label.text = "Extended\nPlay!"
	blink_label(extended_play_label)	

func show_game_over_message():
	extended_play_label.text = "Game Over!"
	extended_play_label.modulate.a = 1.0
	await get_tree().create_timer(2.0).timeout
	SceneChanger.change_scene("res://scenes/title_screen.tscn")

func show_low_fuel_warning():
	if low_fuel_tween:
		low_fuel_tween.kill()
	low_fuel_tween = create_tween()
	low_fuel_tween.set_loops()
	low_fuel_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	low_fuel_tween.tween_property(low_fuel_label, "modulate:a", 1.0, 0.15)
	low_fuel_tween.parallel().tween_property(fuel_gauge, "self_modulate:a", 0.25, 0.15)
	low_fuel_tween.tween_interval(0.15)
	low_fuel_tween.tween_property(low_fuel_label, "modulate:a", 0.0, 0.15)
	low_fuel_tween.parallel().tween_property(fuel_gauge, "self_modulate:a", 1.0, 0.15)
	
func hide_low_fuel_warning():
	if low_fuel_tween:
		low_fuel_tween.kill()
	low_fuel_label.modulate.a = 0
	fuel_gauge.self_modulate.a = 1.0

func blink_label(label : Control):
	var tw : Tween = create_tween()
	tw.set_loops(3)
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.1)
	tw.tween_property(label, "modulate:a", 0.0, 0.2)
