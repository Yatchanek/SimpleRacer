extends Control

@onready var base: ColorRect = $Base
@onready var knob: TextureRect = $Knob


enum Type {
	HORIZONTAL,
	VERTICAL
}

@export var type : Type = Type.HORIZONTAL

var area_size : float
var deadzone_size : float = 20.0
var knob_default_position : Vector2

var touch_index : int = -1

func _ready() -> void:
	if type == Type.HORIZONTAL:
		area_size = base.size.x * 0.5
	else:
		area_size = base.size.y * 0.5
	knob_default_position = knob.position
	
	

var output : Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
	
			if is_point_inside_joystick_area(event.position) and touch_index == -1:
				update(event.position)
				touch_index = event.index
				#get_viewport().set_input_as_handled()
		elif event.index == touch_index:
			reset()
			#get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			update(event.position)
			#get_viewport().set_input_as_handled()
		

func get_base_radius() -> Vector2:
	return base.size * base.get_global_transform_with_canvas().get_scale() / 2

func is_point_inside_joystick_area(point: Vector2) -> bool:
	return get_rect().has_point(point)
	#prints(self, point.x, global_position.x, global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x))
	#var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	#var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	#return x and y

func update(touch_pos : Vector2):
	var center : Vector2 = base.global_position + get_base_radius()
	

		
	var touch_vector : Vector2 = touch_pos - center
	if type == Type.HORIZONTAL:
		touch_vector.y = 0
	else:
		touch_vector.x = 0
		
	touch_vector = touch_vector.limit_length(area_size) * base.get_global_transform_with_canvas().get_scale()
	
	if type == Type.HORIZONTAL:	
		knob.global_position.x = center.x + touch_vector.x - knob.pivot_offset.x * base.get_global_transform_with_canvas().get_scale().x
	else:	
		knob.global_position.y = center.y + touch_vector.y - knob.pivot_offset.y * base.get_global_transform_with_canvas().get_scale().y

	if touch_vector.length_squared() > deadzone_size * deadzone_size:
		output = (touch_vector - touch_vector.normalized() * deadzone_size) / (area_size - deadzone_size)
	else:
		output = Vector2.ZERO


	prints(self, output)

func reset():
	touch_index = -1
	output = Vector2.ZERO
	knob.position = knob_default_position		
