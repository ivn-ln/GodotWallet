extends VBoxContainer


signal confirmed


@onready var projects_container = $BodyContainer/ScrollContainer/ProjectsContainer
@onready var project_actions_container = $BodyContainer/ProjectActionsContainer
@onready var confirmation_dialog = $ConfirmationDialog
@onready var select_import_folder = $SelectImportFolder
@onready var select_scan_folder = $SelectScanFolder
@onready var version_confirmation_dialog = $VersionConfirmationDialog
@onready var option_sort_by = $ActionsContainer/OptionSortBy
@onready var double_click_timer = $DoubleClickTimer
const RENAME_PROJECT_POPUP = preload("res://rename_project_popup.tscn")
const CREATE_NEW_PROJECT_POPUP = preload("res://create_new_project_popup.tscn")
const MANAGE_PLUGINS_POPUP = preload("res://manage_plugins_popup.tscn")
var selected_entry = null
var projects_config: ConfigFile
var projects_array
var search_filter
var is_confirmed = false
var timer = 0.0


enum SORT{
	LAST_EDITED,
	NAME,
	CREATION_DATE,
	TAGS
}


func _ready():
	get_viewport().gui_embed_subwindows = false
	projects_config = ConfigFile.new()
	var e = projects_config.load(Globals.projects_cfg_path)
	assert(e == OK, 'Could not load projects.cfg file')
	projects_array = generate_projects_array(projects_config)
	Globals.projects_array = projects_array
	create_project_entries(projects_array)
	sort_entrys(SORT.LAST_EDITED)


func _process(delta):
	timer += delta


func generate_projects_array(projects_config):
	projects_array = []
	var project_dict
	var project_paths = projects_config.get_sections()
	var project_id = 0
	for path in project_paths:
		var project_config = ConfigFile.new()
		var project_config_path = path + '/project.godot'
		var e = project_config.load(project_config_path)
		#assert(e == OK, 'Could not load project.godot file from ' + project_config_path)
		var project_name = project_config.get_value('application', 'config/name', 'Unnamed Project')
		if project_name == null or path == null:
			continue
		var project_favorite = projects_config.get_value(path, 'favorite')
		var project_icon = project_config.get_value('application', 'config/icon', '')
		var project_features = project_config.get_value('application', 'config/features', null)
		if Globals.preferences_config.has_section(path):
			project_features[0] = Globals.preferences_config.get_value(path, "version")
		var tags_array = project_config.get_value('application', 'config/tags', [])
		project_dict = {"filepath":path, "name": project_name,
						"icon": project_icon, "favorite": project_favorite,
						"features": project_features, "id": project_id,
						"tags": tags_array}
		projects_array.append(project_dict)
		project_id += 1
	return projects_array


func create_project_entries(projects_array):
	for project in projects_array:
		var project_entry = ProjectEntry.new(project)
		project_entry.entry_selected.connect(_on_entry_selected)
		project_entry.open_project_directory.connect(_on_open_project_directory)
		project_entry.entry_favorited.connect(_on_entry_favorited)
		projects_container.add_child(project_entry)


func _on_entry_selected(project_id):
	if selected_entry != null:
		if selected_entry['id'] == project_id:
			if timer < 0.5:
				_on_button_edit_pressed()
				return
	timer = 0.0
	for entry in projects_container.get_children():
		if project_id == entry.project_id:
			selected_entry = projects_array[project_id]
			continue
		entry.entry_deselect()
	for c in project_actions_container.get_children():
		if c is Button:
			c.disabled = false


func _on_entry_favorited(filepath, is_favorite):
	projects_config.set_value(filepath, 'favorite', is_favorite)
	projects_config.save(Globals.projects_cfg_path)
	for entry in projects_container.get_children():
		if entry.project_entry.project_filepath == filepath:
			entry.project_entry.set_is_project_favorite(is_favorite)
			sort_entrys(option_sort_by.get_selected_id())
			break


func sort_entrys(sort_method=-1):
	for entry in projects_container.get_children():
		var rival_id = 0
		for rival in projects_container.get_children():
			var comparassion_codition
			match sort_method:
				SORT.LAST_EDITED:
					var project_config_path = entry.project_entry.project_filepath + '/project.godot'
					var rival_config_path = projects_container.get_child(rival_id).project_entry.project_filepath + '/project.godot'
					comparassion_codition = FileAccess.get_modified_time(project_config_path) < FileAccess.get_modified_time(rival_config_path)
				SORT.NAME:
					var rival_project_name = projects_container.get_child(rival_id).project_entry.project_name
					comparassion_codition = entry.project_entry.project_name.naturalnocasecmp_to(rival_project_name) == 1
			if comparassion_codition:
				projects_container.move_child(entry, rival_id)
			rival_id += 1
	for entry in projects_container.get_children():
		if entry.project_entry.is_favorite:
			projects_container.move_child(entry, 0)
	for entry in projects_container.get_children():
		if not entry.project_entry.is_favorite:
			continue
		var project_config_path = entry.project_entry.project_filepath + '/project.godot'
		var rival_id = 0
		for rival in projects_container.get_children():
			if not rival.project_entry.is_favorite:
				continue
			var rival_config_path = projects_container.get_child(rival_id).project_entry.project_filepath + '/project.godot'
			if FileAccess.get_modified_time(project_config_path) < FileAccess.get_modified_time(rival_config_path):
				projects_container.move_child(entry, rival_id)
			rival_id += 1
	


func edit_project(filepath, godot_path):
	var output = []
	var arguments = ["--verbose", "--editor", "--path", filepath]
	if godot_path == null:
		return
	OS.execute(godot_path, arguments, output, false, false)
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()


func run_project(filepath, godot_path):
	var output = []
	var arguments = ["--path", filepath]
	if godot_path == null:
		return
	OS.execute(godot_path, arguments, output, false, false)
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()


func get_godot_version(filepath):
	var version
	var native_version
	for entry in projects_container.get_children():
		if entry.project_entry.project_filepath == filepath:
			version = entry.project_entry.selected_version
			native_version = entry.project_entry.project_version
			Globals.preferences_config.set_value(filepath, "version", version)
			Globals.save_prefernces()
			break
	if version == null:
		OS.alert('No suitable godot version found! Aborting')
		return null
	var version_filepath
	for version_ in Globals.versions_array:
		if version_['version'] == version:
			version_filepath = version_['path']
			break
	if version_filepath == null:
		OS.alert('No suitable godot version found! Aborting')
		return null
	var godot_path = version_filepath
	var needs_conversion = native_version in version || (native_version == '<4' and int(version[0]) < 4)
	return [godot_path, needs_conversion]


func _on_button_edit_pressed():
	var thread = Thread.new()
	var godot_version = get_godot_version(selected_entry['filepath'])
	if godot_version == null:
		return
	var godot_filepath = godot_version[0]
	if not godot_version[1]:
		version_confirmation_dialog.show()
		await confirmed
		if not is_confirmed:
			return
		is_confirmed = false
	thread.start(edit_project.bind(selected_entry['filepath'], godot_filepath))
	get_tree().quit()


func _on_button_run_pressed():
	var thread = Thread.new()
	var godot_version = get_godot_version(selected_entry['filepath'])
	if godot_version == null:
		return
	var godot_filepath = godot_version[0]
	thread.start(run_project.bind(selected_entry['filepath'], godot_filepath))


func _on_button_rename_pressed():
	var rename_project_popup = RENAME_PROJECT_POPUP.instantiate()
	rename_project_popup.set_project_name(selected_entry['name'])
	rename_project_popup.project_filepath = selected_entry['filepath']
	add_child(rename_project_popup)
	rename_project_popup.project_renamed.connect(_on_project_renamed)


func _on_project_renamed(project_filepath, new_name):
	var project_config = ConfigFile.new()
	var project_config_path = project_filepath + '/project.godot'
	var e = project_config.load(project_config_path)
	assert(e == OK, 'Could not load project.godot file from ' + project_config_path)
	project_config.set_value('application', 'config/name', new_name)
	var e_ = project_config.save(project_config_path)
	assert(e_ == OK, 'Could not save project with new name: ' + project_config_path)
	for project_dict in projects_array:
		if project_dict['filepath'] == project_filepath:
			project_dict['name'] = new_name
			for entry in projects_container.get_children():
				if entry.project_entry.project_id == project_dict['id']:
					entry.update_entry_info(project_dict)


func _on_open_project_directory(directory):
	var thread = Thread.new()
	thread.start(open_directory.bind(directory))


func open_directory(directory: String):
	var output = []
	directory = directory.replace('/', '\\')
	var cmdArguments = [directory]
	OS.execute('explorer', cmdArguments, output, false, true)


func _on_button_manage_tags_pressed():
	pass # Replace with function body.


func filter_project_entrys(filter=0, text_filter=""):
	for entry in projects_container.get_children():
		entry.show()
		var entry_id = entry.project_entry.project_id
		for project in projects_array:
			if project['id'] == entry_id:
				if text_filter.to_lower() not in project['name'].to_lower() and text_filter.to_lower() not in project['filepath'].to_lower():
					entry.hide()


func _on_button_remove_pressed():
	confirmation_dialog.show()


func remove_selected_entry():
	projects_config.erase_section(selected_entry['filepath'])
	var e_ = projects_config.save(Globals.projects_cfg_path)
	assert(e_ == OK, 'Could not save project with new name: ' + Globals.projects_cfg_path)
	for entry in projects_container.get_children():
		if entry.project_entry.project_id == selected_entry['id']:
			entry.queue_free()



func _on_button_export_pressed():
	pass # Replace with function body.


func _on_searchbar_text_changed(new_text):
	if new_text == "":
		for entry in projects_container.get_children():
			entry.show()
		return
	filter_project_entrys(0, new_text)


func _on_confirmation_dialog_confirmed():
	remove_selected_entry()


func _on_confirmation_dialog_canceled():
	confirmation_dialog.hide()


func _on_button_new_pressed():
	var create_new_project_popup = CREATE_NEW_PROJECT_POPUP.instantiate()
	create_new_project_popup.project_created.connect(_on_project_created)
	add_child(create_new_project_popup)


func _on_project_created(project_name, project_filepath, project_template, godot_path):
	if godot_path == null:
		OS.alert('No godot version selected, could not create new project')
		return
	var template_path
	if project_template != null and project_template != "":
		for template in Globals.templates_array:
			if template['name'] == project_template:
				template_path = template['path']
				break
	if template_path != null:
		template_path = ProjectSettings.globalize_path(template_path)
		if '.' in template_path:
			template_path = template_path.get_base_dir()
	var plugins_folder = project_filepath.trim_suffix('/') + '\\' + project_name + '\\addons'
	var enabled_array = []
	for plugin in Globals.plugins_array:
		if plugin['autoinstall']:
			copy_template_recursive(plugin['path'] + 'addons/' + plugin['name'], plugins_folder + '\\' + plugin['name'])
			enabled_array.append('res://addons/' + plugin['name'] + '/plugin.cfg')
	var project_folder = project_filepath + '\\' + project_name
	var project_file_location = project_folder + '\\project.godot'
	DirAccess.make_dir_absolute(project_folder)
	if template_path != null:
		copy_template_recursive(template_path, project_folder)
	if not FileAccess.file_exists(project_file_location):
		var project_config = ConfigFile.new()
		project_config.set_value('application', 'config/name', project_name)
		project_config.set_value('editor_plugins', 'enabled', enabled_array)
		project_config.save(project_file_location)
	else:
		var config = ConfigFile.new()
		config.load(project_file_location)
		config.set_value('application', 'config/name', project_name)
		config.set_value('editor_plugins', 'enabled', enabled_array)
		config.save(project_file_location)
	import_folder(project_folder)
	var thread = Thread.new()
	thread.start(edit_project.bind(project_folder, godot_path))
	get_tree().quit()


func copy_template_recursive(starting_dir, destination):
	if not DirAccess.dir_exists_absolute(destination):
		DirAccess.make_dir_recursive_absolute(destination)
	for file in DirAccess.get_files_at(starting_dir):
		DirAccess.copy_absolute(starting_dir + '/' + file, destination + '\\' + file)
	for dir in DirAccess.get_directories_at(starting_dir):
		copy_template_recursive(starting_dir + '/' + dir, destination + '\\' + dir)


func _on_button_import_pressed():
	select_import_folder.show()


func _on_select_import_folder_dir_selected(dir):
	import_folder(dir)
	if get_tree() != null:
		get_tree().reload_current_scene()


func import_folder(dir):
	var project_dict
	var project_config_path = dir + '/project.godot'
	if not FileAccess.file_exists(project_config_path):
		OS.alert("Unable to import project!\nCouldn't find project.godot file in " + dir + '.')
		return
	var project_entries = projects_config.get_sections()
	for entry in project_entries:
		if entry.replace('\\', '/') == dir.replace('\\', '/'):
			OS.alert("Project is already imported!")
			return
	var e = projects_config.load(Globals.projects_cfg_path)
	assert(e == OK, 'Could not load project.godot file from ' + Globals.projects_cfg_path)
	projects_config.set_value(dir, 'favorite', false)
	var e_ = projects_config.save(Globals.projects_cfg_path.replace('\\', '/'))
	assert(e_ == OK, 'Could not save file: ' + Globals.projects_cfg_path)


func _on_button_scan_pressed():
	select_scan_folder.show()


func _on_select_scan_folder_dir_selected(dir):
	var subdirs = DirAccess.get_directories_at(dir)
	if subdirs.size() > 0:
		var project_config_path = dir + '/project.godot'
		var project_entries = projects_config.get_sections()
		var exists = false
		for entry in project_entries:
			if entry == dir:
				return
		if not FileAccess.file_exists(project_config_path):
			for dir_ in subdirs:
				_on_select_scan_folder_dir_selected(dir + '/' + dir_)
		else:
			import_folder(dir)
			if get_tree() != null:
				get_tree().reload_current_scene()


func _on_option_sort_by_item_selected(index):
	sort_entrys(index)


func _on_version_confirmation_dialog_confirmed():
	is_confirmed = true
	confirmed.emit()


func _on_version_confirmation_dialog_canceled():
	is_confirmed = false
	confirmed.emit()


func _on_button_manage_plugins_pressed():
	var manage_plugins_popup = MANAGE_PLUGINS_POPUP.instantiate()
	add_child(manage_plugins_popup)
	if selected_entry['filepath'] != null:
		manage_plugins_popup.get_plugins_from_project(selected_entry['filepath'])
