extends CanvasLayer
class_name HUD


@onready var extended_play_label: Label = %ExtendedPlayLabel
@onready var boost_indicator: TextureRect = %BoostIndicator
@onready var deboost_indicator: TextureRect = %DeboostIndicator
@onready var canister_icon: TextureRect = %CanisterIcon

@onready var joystick: Control = %Joystick
@onready var hand: TextureRect = $Control/HBoxContainer/Speedometer/Hand
@onready var dist_slider: HSlider = %DistSlider
@onready var time_label: Label = %TimeLabel

func update_time(value : float):
	time_label.text = "%.1f" % value
	
func update_distance(value : float):
	dist_slider.value = value

func update_fuel():
	hand.rotation_degrees = remap(Globals.car.fuel, 0, 100, 10, 270)

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
	extended_play_label.text = "Extended Play!"
	blink_label(extended_play_label)	

func blink_label(label : Control):
	var tw : Tween = create_tween()
	tw.set_loops(3)
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.1)
	tw.tween_property(label, "modulate:a", 0.0, 0.2)
