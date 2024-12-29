extends HBoxContainer
class_name CustomGauge

@export var decrease_button : TouchScreenButton
@export var increase_button : TouchScreenButton

@export var step : float

signal value_changed(value : int, step : float)


var num_steps : int
var current_value : int = 4
var is_initialized : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if is_instance_valid(increase_button):
		increase_button.pressed.connect(_on_increase_pressed)
	if is_instance_valid(decrease_button):
		decrease_button.pressed.connect(_on_decrease_pressed)
		
	num_steps = get_child_count()
	setup_colors()
	update()
	is_initialized = true

func setup_colors():
	var hue_step : float = (100.0 / 360.0) / (num_steps - 1)
	for i in get_child_count():
		var bar : ColorRect = get_child(i)
		var hue : float = (100.0 / 360.0) - i * hue_step
		bar.color = Color.from_hsv(hue, 1.0, 1.0)
	
func update():
	for child in get_children():
		child.modulate.a = 0.0
	
	if current_value > 0:	
		for i in range(0, current_value):
			get_child(i).modulate.a = 1.0
	
	if is_initialized:
		value_changed.emit(current_value, step)

func _on_increase_pressed():
	current_value = clampi(current_value + 1, 0, num_steps)	
	update()
	
func _on_decrease_pressed():
	current_value = clampi(current_value - 1, 0, num_steps)
	update()
