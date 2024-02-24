extends Node

var projects_cfg_path = OS.get_data_dir() + '/Godot/projects.cfg'
var installs_cfg_path = "user://godot_installs.cfg"
var settings = {"sort": 0, "stable": true, "hide_installed": false}
var default_icon = "res://icon.svg"
var template_cfg_path = "user://templates.cfg"
var plugin_cfg_path = "user://plugins.cfg"

var versions_array = []
var templates_array = []
var projects_array = []
var plugins_array = []

var preferences_config = ConfigFile.new()
func _ready():
	if not FileAccess.file_exists("user://preferences.cfg"):
		var file = FileAccess.open("user://preferences.cfg", FileAccess.WRITE)
		file.close()
	preferences_config.load("user://preferences.cfg")


func save_prefernces():
	preferences_config.save("user://preferences.cfg")
