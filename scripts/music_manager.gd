extends Node

@export var tracks : Array[AudioStream] = []

@onready var timer: Timer = $Timer

var current_channel : AudioStreamPlayer
var next_channel : AudioStreamPlayer

enum Music {
	TITLE_SCREEN,
	TRACK_1,
	TRACK_2
}

func _ready() -> void:
	current_channel = $Channel1
	next_channel = $Channel2
	next_channel.volume_db = -80

	
func play_track(track : Music):
	var tw : Tween
	if current_channel.playing:
		tw = create_tween()
		tw.tween_property(current_channel, "volume_db", -80, 0.5)

		await tw.finished
	
	current_channel.stream = tracks[track]
	current_channel.play()
	timer.start(current_channel.stream.get_length() - 5)
	
	tw = create_tween()
	tw.tween_property(current_channel, "volume_db", 0.0, 0.5)


func fade_out():
	var tw : Tween = create_tween()
	tw.tween_property(current_channel, "volume_db", -80, 1.0)		
	
func switch_track(next_track : Music):
	next_channel.stream = tracks[next_track]
	next_channel.play()
	var tw : Tween = create_tween()
	tw.tween_property(current_channel, "volume_db", -80, 5.0)
	tw.parallel().tween_property(next_channel, "volume_db", 0.0, 50)
	
	var temp : AudioStreamPlayer = current_channel
	current_channel = next_channel
	next_channel = temp
	

func _on_timer_timeout() -> void:
	if current_channel.stream == tracks[Music.TITLE_SCREEN]:
		switch_track(Music.TITLE_SCREEN)
	elif current_channel.stream == tracks[Music.TRACK_1]:
		switch_track(Music.TRACK_2)
	else:
		switch_track(Music.TRACK_1)
