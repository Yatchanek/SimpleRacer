extends Control

@onready var knob: TextureRect = $Knob
@onready var base: TextureRect = $Base

var knob_default_pos : Vector2

var touch_index : int = -1
var is_dragging : bool = false

var deadzone_size : float = 10.0
var area_size : float = 150.0

var output : Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if is_point_inside_joystick_area(event.position) and touch_index == -1:
				update(event.position)
				touch_index = event.index
				get_viewport().set_input_as_handled()
		elif event.index == touch_index:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			update(event.position)
			get_viewport().set_input_as_handled()
		
		

func _ready() -> void:
	knob_default_pos = knob.position

func get_base_radius() -> Vector2:
	return base.size * base.get_global_transform_with_canvas().get_scale() / 2

func is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y

func update(touch_pos : Vector2):
	var center : Vector2 = base.global_position + get_base_radius()
	var touch_vector : Vector2 = touch_pos - center
	touch_vector = touch_vector.limit_length(area_size) * base.get_global_transform_with_canvas().get_scale()
	
	knob.global_position = center + touch_vector - knob.pivot_offset * base.get_global_transform_with_canvas().get_scale()

	if touch_vector.length_squared() > deadzone_size * deadzone_size:
		is_dragging = true
		output = (touch_vector - touch_vector.normalized() * deadzone_size) / (area_size - deadzone_size)
	else:
		is_dragging = false
		output = Vector2.ZERO

func reset():
	touch_index = -1
	output = Vector2.ZERO
	is_dragging = false
	knob.position = knob_default_pos	
