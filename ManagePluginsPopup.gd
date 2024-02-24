extends Window


const PROJECTS_PLUGIN_ENTRY = preload("res://projects_plugin_entry.tscn")
@onready var plugins_container = $Control/Control/MarginContainer/VBoxContainer/PanelContainer2/VBoxContainer/ScrollContainer/PluginsContainer
@onready var global_plugins_container = $Control/Control/MarginContainer/VBoxContainer/PanelContainer/VBoxContainer2/ScrollContainer/GlobalPluginsContainer
var project_config = ConfigFile.new()
var enabled_array_original = []
var project_config_path
var plugins_folder


func get_plugins_from_project(project_path):
	plugins_folder = project_path.trim_suffix('/') + '/addons'
	if not DirAccess.dir_exists_absolute(plugins_folder):
		get_global_plugins()
		return
	project_config_path = project_path.trim_suffix('/') + '/project.godot'
	if FileAccess.file_exists(project_config_path):
		project_config.load(project_config_path)
		enabled_array_original = project_config.get_value('editor_plugins', "enabled", [])
	for folder in DirAccess.get_directories_at(plugins_folder):
		var full_folder = plugins_folder + '/' + folder
		add_plugin(full_folder, 'res://addons/' + folder, enabled_array_original)
	get_global_plugins()


func add_plugin(folder, folder_relative, enabled_array=[], is_global = false):
	var plugins_cfg_path = folder.trim_suffix('/') + '/plugin.cfg'
	var plugins_cfg_path_relative = folder_relative.trim_suffix('/') + '/plugin.cfg'
	var plugins_cfg = ConfigFile.new()
	var e = plugins_cfg.load(plugins_cfg_path)
	if e != OK:
		print('Could not load plugin')
		return
	var plugin_name = plugins_cfg.get_value("plugin", "name")
	var plugin_version = plugins_cfg.get_value("plugin", "version")
	var projects_plugin_entry = PROJECTS_PLUGIN_ENTRY.instantiate()
	if is_global:
		projects_plugin_entry.set_global()
		global_plugins_container.add_child(projects_plugin_entry)
	else:
		plugins_container.add_child(projects_plugin_entry)
	projects_plugin_entry.set_plugin_name(plugin_name)
	projects_plugin_entry.set_version(plugin_version)
	projects_plugin_entry.plugin_path = folder_relative
	projects_plugin_entry.plugin_path_abs = folder
	projects_plugin_entry.status_changed.connect(_on_status_changed)
	projects_plugin_entry.add_plugin.connect(_on_add_plugin)
	projects_plugin_entry.delete_plugin.connect(_on_delete_plugin)
	if plugins_cfg_path_relative in enabled_array:
		projects_plugin_entry.set_status(true)


func _on_delete_plugin(plugin):
	var plugin_folder = plugin.plugin_path_abs
	OS.move_to_trash(plugin_folder)
	plugin.queue_free()


func _on_add_plugin(plugin):
	for plugin_ in plugins_container.get_children():
		if plugin_.plugin_name == plugin.plugin_name:
			OS.alert("Plugin already exists. Delete the old plugin for this to work")
	copy_plugin_recursive(plugin.plugin_path_abs, plugins_folder + '/' + plugin.plugin_name)
	OS.alert("Plugin added succesfully")
	add_plugin(plugin.plugin_path, 'res://addons/' + plugin.plugin_name)


func copy_plugin_recursive(starting_dir, destination):
	if not DirAccess.dir_exists_absolute(destination):
		DirAccess.make_dir_recursive_absolute(destination)
	for file in DirAccess.get_files_at(starting_dir):
		DirAccess.copy_absolute(starting_dir + '/' + file, destination + '\\' + file)
	for dir in DirAccess.get_directories_at(starting_dir):
		copy_plugin_recursive(starting_dir + '/' + dir, destination + '\\' + dir)


func _on_status_changed(plugin, new_status):
	var plugin_path = plugin.plugin_path + '/plugin.cfg'
	if new_status:
		if enabled_array_original.find(plugin_path) != -1:
			return
		enabled_array_original.append(plugin_path)
	else:
		var id = enabled_array_original.find(plugin_path)
		if id == -1:
			return
		enabled_array_original.remove_at(id)
	project_config.set_value('editor_plugins', 'enabled', enabled_array_original)
	project_config.save(project_config_path)

func get_global_plugins():
	for plugin in Globals.plugins_array:
		add_plugin(plugin['path'] + 'addons/' + plugin['name'], 'res://addons/' + plugin['name'], [], true)


func _on_close_requested():
	queue_free()
