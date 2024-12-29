extends Node

@onready var veil: ColorRect = $CanvasLayer/Veil


signal scene_changed

func change_scene(target_scene : String):
	var tw : Tween = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_method(set_veil_threshold, 0.7, 0.0, 1.0)
	#tw.tween_property(veil, "modulate:a", 1.0, 1.0)
	
	await tw.finished
	
	get_tree().change_scene_to_file(target_scene)
	
	tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	tw.tween_interval(0.5)
	tw.tween_method(set_veil_threshold, 0.0, 0.7, 1.0)
	#tw.tween_property(veil, "modulate:a", 0.0, 1.0)
	
	await tw.finished
	
	scene_changed.emit()

func set_veil_threshold(value : float):
	veil.material.set_shader_parameter("threshold", value)
