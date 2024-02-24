extends VBoxContainer


@onready var plugins_container = $BodyContainer/ScrollContainer/PluginsContainer
@onready var plugins_actions_container = $BodyContainer/PluginsActionsContainer
@onready var import_file_dialog = $ImportFileDialog
@onready var confirmation_dialog = $ConfirmationDialog
const PLUGIN_ENTRY = preload("res://plugin_entry.tscn")
var plugins_config = ConfigFile.new()
var current_plugin


func _ready():
	var e = plugins_config.load(Globals.plugin_cfg_path)
	for section in plugins_config.get_sections():
		var icon_path = plugins_config.get_value(section, "icon_path")
		var display_plugin_name = section
		var project_file = plugins_config.get_value(section, "project_path")
		var plugin_version = plugins_config.get_value(section, "plugin_version")
		var description = plugins_config.get_value(section, "description")
		var autoinstall = plugins_config.get_value(section, "autoinstall")
		add_plugin(display_plugin_name, description, icon_path, project_file, plugin_version, autoinstall)
		Globals.plugins_array.append({"name": display_plugin_name, "path": project_file, "autoinstall": autoinstall})


func _on_button_browse_online_pressed():
	OS.shell_open("https://godotengine.org/asset-library/")


func _on_button_import_pressed():
	import_file_dialog.show()


func _on_import_file_dialog_file_selected(path):
	if not ".zip" in path:
		OS.alert('Not a zip archive! Cannot import')
	var reader = ZIPReader.new()
	var e = reader.open(path)
	if e != OK:
		OS.alert("Could not unzip the file")
		reader.close()
		return
	if not DirAccess.dir_exists_absolute("user://Plugins"):
		DirAccess.make_dir_absolute("user://Plugins")
	var plugin_name = reader.get_files()[0]
	var project_file
	var project_config
	for file in reader.get_files():
		if not '.' in file:
			if not DirAccess.dir_exists_absolute("user://Plugins/" + file):
				DirAccess.make_dir_absolute("user://Plugins/" + file)
		else:
			if 'plugin.cfg' in file:
				project_file = file
			if 'project.godot' in file:
				project_config = file
			var file_access = FileAccess.open("user://Plugins/" + file, FileAccess.WRITE)
			var data = reader.read_file(file)
			if file_access != null:
				file_access.store_buffer(data)
				file_access.close()
	print(project_config)
	reader.close()
	var icon_path = ""
	var display_plugin_name = plugin_name
	var plugin_version
	var description
	if project_file != null:
		var config = ConfigFile.new()
		config.load("user://Plugins/" + project_file)
		description = config.get_value('plugin', 'description', '')
		print(description)
		print(config.get_value('plugin', 'description', ''))
		display_plugin_name =  config.get_value('plugin', 'name', plugin_name)
		plugin_version = config.get_value('plugin', 'version', '')
	else:
		OS.alert('Could not find plugin.cfg file. Aborting')
		return
	if project_config != null:
		var config = ConfigFile.new()
		var e_ = config.load("user://Plugins/" + project_config)
		icon_path = config.get_value('application', 'config/icon', '')
	plugins_config.set_value(display_plugin_name, "icon", icon_path)
	var project_path = "user://Plugins/" + plugin_name
	for plugin in Globals.plugins_array:
		if plugin['path'] == project_path:
			OS.alert('Plugin already exists! Aborting')
			return
	plugins_config.set_value(display_plugin_name, "project_path", project_path)
	plugins_config.set_value(display_plugin_name, "plugin_version", plugin_version)
	plugins_config.set_value(display_plugin_name, "icon_path", icon_path)
	plugins_config.set_value(display_plugin_name, "description", description)
	plugins_config.set_value(display_plugin_name, "autoinstall", false)
	plugins_config.save(Globals.plugin_cfg_path)
	add_plugin(display_plugin_name, description, icon_path, project_path, plugin_version)
	OS.alert("Import Success")
	Globals.plugins_array.append({"name": display_plugin_name, "path": project_path, "autoinstall": false})


func add_plugin(plugin_name, description, icon_path, plugin_path, plugin_version, autoinstall = false):
	var plugin_entry = PLUGIN_ENTRY.instantiate()
	var icon
	plugin_entry.plugin_version = plugin_version
	plugin_entry.project_path = plugin_path
	if icon_path != null:
		var project_icon_filepath = icon_path.trim_prefix('res://')
		var global_icon_filepath = plugin_path + project_icon_filepath
		if FileAccess.file_exists(global_icon_filepath):
			var project_image = Image.load_from_file(global_icon_filepath)
			var project_icon = ImageTexture.create_from_image(project_image)
			icon = project_icon
		else:
			icon = load(Globals.default_icon)
	else:
		icon = load(Globals.default_icon)
	if autoinstall:
		plugin_entry.set_autoinstall(autoinstall)
	plugins_container.add_child(plugin_entry)
	plugin_entry.set_plugin_name(plugin_name.trim_suffix('/'))
	plugin_entry.set_plugin_icon(icon)
	plugin_entry.set_plugin_description(description)
	plugin_entry.plugin_selected.connect(_on_plugin_selected)
	plugin_entry.autoinstall_changed.connect(_on_autoinstall_changed)


func _on_autoinstall_changed(plugin, new_value):
	for plugin_ in Globals.plugins_array:
		if plugin_['path'] == plugin.project_path:
			Globals.plugins_array[Globals.plugins_array.find(plugin_)]['autoinstall'] = new_value
			plugins_config.set_value(plugin.plugin_name, "autoinstall", new_value)
			plugins_config.save(Globals.plugin_cfg_path)
			break


func _on_plugin_selected(plugin):
	for plugin_ in plugins_container.get_children():
		if plugin == plugin_:
			continue
		plugin_.deselect()
	for action in plugins_actions_container.get_children():
		if action is Button:
			action.disabled = false
	current_plugin = plugin


func _on_plugin_active_changed(plugin, new_active):
	if not new_active:
		for plugin_ in Globals.plugins_array:
			if plugin_['path'] == plugin.project_path:
				Globals.plugins_array.erase(plugin_)
				break
	else:
		Globals.plugins_array.append({'name': plugin.plugin_name, 'path': plugin.project_path, 'godot_version': plugin.godot_version})


func _on_button_remove_pressed():
	confirmation_dialog.show()


func _on_confirmation_dialog_canceled():
	confirmation_dialog.hide()


func _on_confirmation_dialog_confirmed():
	for plugin in Globals.plugins_array:
		if plugin["path"] == current_plugin.project_path:
			if "." in current_plugin.project_path:
				var e = OS.move_to_trash(ProjectSettings.globalize_path(current_plugin.project_path.get_base_dir()) + '/')
				if e != OK:
					OS.alert("Could not delete the plugin from the filesystem")
			else:
				var e = OS.move_to_trash(ProjectSettings.globalize_path(current_plugin.project_path) + '/')
				if e != OK:
					OS.alert("Could not delete the plugin from the filesystem")
			plugins_config.erase_section(plugin['name'])
			plugins_config.save(Globals.plugin_cfg_path)
			Globals.plugins_array.erase(plugin)
			break
	current_plugin.queue_free()
