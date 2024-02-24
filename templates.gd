extends VBoxContainer


@onready var import_file_dialog = $ImportFileDialog
@onready var templates_container = $BodyContainer/ScrollContainer/TemplatesContainer
@onready var template_actions_container = $BodyContainer/TemplateActionsContainer
@onready var confirmation_dialog = $ConfirmationDialog
const EDIT_TEMPLATE_POPUP = preload("res://edit_template_popup.tscn")
const IMPORT_TEMPLATE_FROM_PROJECT_POPUP = preload("res://import_template_from_project_popup.tscn")
const TEMPLATE_ENTRY = preload("res://template_entry.tscn")
var current_template
var templates_config = ConfigFile.new()


func _ready():
	var e = templates_config.load(Globals.template_cfg_path)
	for section in templates_config.get_sections():
		var icon_path = templates_config.get_value(section, "icon")
		var display_template_name = section
		var project_file = templates_config.get_value(section, "project_path")
		var godot_version = templates_config.get_value(section, "godot_version")
		add_template(display_template_name, icon_path, project_file, godot_version)
		Globals.templates_array.append({"name": display_template_name, "path": project_file, "godot_version": godot_version})


func _on_button_import_file_pressed():
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
	if not DirAccess.dir_exists_absolute("user://Templates"):
		DirAccess.make_dir_absolute("user://Templates")
	var template_name = reader.get_files()[0]
	var project_file
	for file in reader.get_files():
		if not '.' in file:
			if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://Templates/") + file):
				DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://Templates/") + file)
		else:
			if 'project.godot' in file:
				project_file = file
			var file_access = FileAccess.open("user://Templates/" + file, FileAccess.WRITE)
			var data = reader.read_file(file)
			if file_access != null:
				file_access.store_buffer(data)
				file_access.close()
	reader.close()
	var icon_path = ""
	var display_template_name = template_name
	var version = 'Unknown'
	if project_file != null:
		var config = ConfigFile.new()
		config.load("user://Templates/" + project_file)
		icon_path = config.get_value('application', 'config/icon', '')
		display_template_name =  config.get_value('application', 'config/name', template_name)
		version = config.get_value('application', 'config/features', null)[0]
	templates_config.set_value(display_template_name, "icon", icon_path)
	var project_path = "user://Templates/" + template_name
	for template in Globals.templates_array:
		if template['path'] == project_path:
			OS.alert('Template already exists! Aborting')
			return
	templates_config.set_value(display_template_name, "project_path", project_path)
	templates_config.set_value(display_template_name, "godot_version", version)
	templates_config.set_value(display_template_name, "active", true)
	templates_config.save(Globals.template_cfg_path)
	add_template(display_template_name, icon_path, project_path, version)
	OS.alert("Import Success")
	Globals.templates_array.append({"name": display_template_name, "path": project_path, "godot_version": version})


func add_template(template_name, icon_path, template_path, godot_version):
	var template_entry = TEMPLATE_ENTRY.instantiate()
	var icon
	template_entry.project_path = template_path
	template_entry.godot_version = godot_version
	if icon_path != null:
		var project_icon_filepath = icon_path.trim_prefix('res://')
		var global_icon_filepath = template_path + project_icon_filepath
		if FileAccess.file_exists(global_icon_filepath):
			var project_image = Image.load_from_file(global_icon_filepath)
			var project_icon = ImageTexture.create_from_image(project_image)
			icon = project_icon
		else:
			icon = load(Globals.default_icon)
	else:
		icon = load(Globals.default_icon)
	templates_container.add_child(template_entry)
	template_entry.set_template_name(template_name.trim_suffix('/'))
	template_entry.set_template_icon(icon)
	template_entry.template_selected.connect(_on_template_selected)
	template_entry.template_active_changed.connect(_on_template_active_changed)


func _on_template_active_changed(template, new_active):
	if not new_active:
		for template_ in Globals.templates_array:
			if template_['path'] == template.project_path:
				Globals.templates_array.erase(template_)
				break
	else:
		Globals.templates_array.append({'name': template.template_name, 'path': template.project_path, 'godot_version': template.godot_version})


func _on_template_selected(template):
	for template_ in templates_container.get_children():
		if template == template_:
			continue
		template_.deselect()
	for action in template_actions_container.get_children():
		if action is Button:
			action.disabled = false
	current_template = template


func _on_button_browse_pressed():
	OS.shell_open("https://godotengine.org/asset-library/asset?filter=&category=8&support%5Bcommunity%5D=1&support%5Bofficial%5D=1")


func _on_button_edit_pressed():
	var edit_template_popup = EDIT_TEMPLATE_POPUP.instantiate()
	edit_template_popup.set_godot_version(current_template.godot_version)
	edit_template_popup.set_template_name(current_template.template_name)
	add_child(edit_template_popup)
	edit_template_popup.template_changed.connect(_on_template_changed)


func _on_template_changed(new_name, new_version):
	var old_name = current_template.template_name
	current_template.set_template_name(new_name)
	current_template.godot_version = new_version
	templates_config.erase_section(old_name)
	templates_config.set_value(new_name, "icon", current_template.icon_path)
	templates_config.set_value(new_name, "project_path", current_template.project_path)
	templates_config.set_value(new_name, "godot_version", new_version)
	templates_config.set_value(new_name, "active", true)
	templates_config.save(Globals.template_cfg_path)
	for template_ in Globals.templates_array:
		if template_['name'] == old_name:
			Globals.templates_array.erase(template_)
			Globals.templates_array.append({"name": new_name, "path": current_template.project_path, "godot_version": new_version})
			break


func _on_button_remove_pressed():
	confirmation_dialog.show()


func get_godot_version(version):
	var native_version
	var version_filepath
	for version_ in Globals.versions_array:
		if version_['version'] == version:
			version_filepath = version_['path']
			break
	if version_filepath == null:
		OS.alert('No suitable godot version found. Godot v' + version + ' is required. Aborting')
		return null
	var godot_path = version_filepath
	return godot_path


func run_project(filepath, godot_path):
	var output = []
	var arguments = ["--verbose", "--editor", "--path", filepath]
	if godot_path == null:
		return
	OS.execute(godot_path, arguments, output, false, false)
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()


func _on_button_import_project_pressed():
	var import_template_from_project_popup = IMPORT_TEMPLATE_FROM_PROJECT_POPUP.instantiate()
	add_child(import_template_from_project_popup)
	import_template_from_project_popup.template_imported.connect(_on_template_imported)


func _on_template_imported(template_name, project_path, icon_path, godot_version):
	templates_config.set_value(template_name, "icon", icon_path)
	templates_config.set_value(template_name, "project_path", project_path)
	templates_config.set_value(template_name, "godot_version", godot_version)
	templates_config.set_value(template_name, "active", true)
	templates_config.save(Globals.template_cfg_path)
	add_template(template_name, icon_path, project_path, godot_version)
	Globals.templates_array.append({"name": template_name, "path": project_path, "godot_version": godot_version})


func _on_button_edit_in_godot_pressed():
	if current_template.project_path == null:
		OS.alert("Template doesn't have project.godot file. Aborting")
		return
	var project_path = current_template.project_path + '/'
	if project_path == null || "project.godot" not in project_path:
		OS.alert("Template doesn't have project.godot file. Aborting")
		return
	var version = current_template.godot_version
	if version == null:
		OS.alert('Error opening template')
		return
	var godot_version = get_godot_version(version)
	if godot_version == null:
		return
	var godot_filepath = godot_version
	var thread = Thread.new()
	thread.start(run_project.bind(ProjectSettings.globalize_path(project_path).get_base_dir(), godot_filepath))


func _on_button_folder_pressed():
	var thread = Thread.new()
	thread.start(open_directory.bind(ProjectSettings.globalize_path("user://Templates")))


func open_directory(directory: String):
	if not DirAccess.dir_exists_absolute("user://Templates"):
		DirAccess.make_dir_absolute("user://Templates")
	var output = []
	directory = directory.replace('/', '\\')
	var cmdArguments = [directory]
	OS.execute('explorer', cmdArguments, output, false, true)


func _on_confirmation_dialog_confirmed():
	for template in Globals.templates_array:
		if template["path"] == current_template.project_path:
			if "." in current_template.project_path:
				var e = OS.move_to_trash(ProjectSettings.globalize_path(current_template.project_path.get_base_dir()) + '/')
				if e != OK:
					OS.alert("Could not delete the template from the filesystem")
			else:
				var e = OS.move_to_trash(ProjectSettings.globalize_path(current_template.project_path) + '/')
				if e != OK:
					OS.alert("Could not delete the template from the filesystem")
			templates_config.erase_section(template['name'])
			templates_config.save(Globals.template_cfg_path)
			Globals.templates_array.erase(template)
			break
	current_template.queue_free()


func _on_confirmation_dialog_canceled():
	confirmation_dialog.hide()
