extends Node

var left_handed_mode : bool = false
var master_volume : int = 5
var effects_volume : int = 5
var engine_volume : int = 5
var music_volume : int = 5

signal settings_loaded

func _ready() -> void:
	load_settings()

func save_settings():
	var config_file : ConfigFile = ConfigFile.new()
	
	config_file.set_value("Sound Settings", "master_volume", master_volume)
	config_file.set_value("Sound Settings", "effects_volume", effects_volume)
	config_file.set_value("Sound Settings", "engine_volume", engine_volume)	
	config_file.set_value("Sound Settings", "music_volume", music_volume)
	
	config_file.save("user://settings.ini")
	
func load_settings():
	var config_file : ConfigFile = ConfigFile.new()
	var err : Error = config_file.load("user://settings.ini")
	
	if !err == OK:
		await get_tree().process_frame
		settings_loaded.emit()
		return
		
	var config_sections : PackedStringArray = config_file.get_sections()
	
	for section in config_sections:
		var config_keys : PackedStringArray = config_file.get_section_keys(section)
		for config_key in config_keys:
			set(config_key, config_file.get_value(section, config_key))	
	
	await get_tree().process_frame
	settings_loaded.emit()
