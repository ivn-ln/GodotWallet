extends Window


signal project_created(project_name, project_filepath, project_platform)


@onready var browse_folder = $BrowseFolder
@onready var project_name_line_edit = $Control/MarginContainer/VBoxContainer/ProjectNameLineEdit
@onready var project_location_line_edit = $Control/MarginContainer/VBoxContainer/HBoxContainer/ProjectLocationLineEdit
@onready var confirm = $Control/MarginContainer/VBoxContainer/HBoxContainer2/Confirm
@onready var version_options = $Control/MarginContainer/VBoxContainer/VersionOptions
@onready var template_options = $Control/MarginContainer/VBoxContainer/TemplateOptions
@onready var error = $Control/MarginContainer/VBoxContainer/Error
var default_folder = OS.get_environment("USERPROFILE") + '\\Documents'
var project_template


func _ready():
	project_location_line_edit.text = default_folder
	confirm.grab_focus()
	set_project_versions(Globals.versions_array)
	set_template_options(Globals.templates_array)
	var num = 1
	while DirAccess.dir_exists_absolute(project_location_line_edit.text + '\\' + project_name_line_edit.text):
		project_name_line_edit.text = "New Game Project " + str(num)
		num += 1


func _on_browse_pressed():
	browse_folder.show()


func _on_browse_folder_dir_selected(dir):
	project_location_line_edit.text = dir
	confirm.disabled = false
	var num = 1
	while DirAccess.dir_exists_absolute(project_location_line_edit.text + '\\' + project_name_line_edit.text):
		project_name_line_edit.text = "New Game Project " + str(num)
		num += 1


func _on_cancel_pressed():
	queue_free()


func _on_close_requested():
	queue_free()


func _on_confirm_pressed():
	var project_name = project_name_line_edit.text
	var project_filepath = project_location_line_edit.text
	var version_to_sumbit
	for version in Globals.versions_array:
		var selected_version = version_options.get_item_text(version_options.get_selected_id())
		if version['version'] == selected_version:
			version_to_sumbit = version['path']
			break
	project_template = template_options.get_item_text(template_options.selected)
	project_created.emit(project_name, project_filepath, project_template, version_to_sumbit)


func set_project_versions(versions_array):
	version_options.clear()
	for version in versions_array:
		version_options.add_item(version['version'])


func set_template_options(templates_array):
	for template in templates_array:
		template_options.add_item(template['name'])
	


func _on_project_name_line_edit_text_changed(new_text):
	var num = 1
	if DirAccess.dir_exists_absolute(project_location_line_edit.text + '\\' + project_name_line_edit.text):
		confirm.disabled = true
		error.show()
	else:
		error.hide()
		confirm.disabled = false


func _on_project_location_line_edit_text_changed(new_text):
	confirm.disabled = false
	var num = 1
	while DirAccess.dir_exists_absolute(project_location_line_edit.text + '\\' + project_name_line_edit.text):
		project_name_line_edit.text = "New Game Project " + str(num)
		num += 1
