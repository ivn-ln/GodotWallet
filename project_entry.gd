extends PanelContainer


signal entry_selected(id)
signal open_project_directory(filepath)
signal entry_favorited(filepath, is_favorite)


@onready var project_name_label = $HBoxContainer/MarginContainer/VBoxContainer/TopHBoxContainer/ProjectName
@onready var project_filepath_label = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ProjectFilepath
@onready var project_icon_texture_rect = $HBoxContainer/ProjectIcon
@onready var favorite_button = $HBoxContainer/Favorite
@onready var select_button = $Select
@onready var version_options = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Version
@onready var warning = $HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/Warning
@onready var top_hbox_container = $HBoxContainer/MarginContainer/VBoxContainer/TopHBoxContainer
var project_id = -1
var is_favorite
var project_filepath
var project_name
var project_version
var selected_version
var last_versions_array = []
const TAG = preload("res://tag.tscn")


func _process(delta):
	if last_versions_array != Globals.versions_array:
		set_project_versions(Globals.versions_array)
		last_versions_array = Globals.versions_array.duplicate()


func set_project_name(project_name_):
	if not is_node_ready():
		await ready
	project_name = project_name_
	project_name_label.text = project_name


func set_project_tags(tags_array):
	if not is_node_ready():
		await ready
	for tag in tags_array:
		var tag_inst = TAG.instantiate()
		tag_inst.set_tag_name(tag)
		top_hbox_container.add_child(tag_inst)


func set_project_icon(project_icon):
	if not is_node_ready():
		await ready
	project_icon_texture_rect.texture = project_icon


func set_project_filepath(project_filepath_):
	if not is_node_ready():
		await ready
	project_filepath = project_filepath_
	project_filepath_label.text = project_filepath


func set_is_project_favorite(is_favorite_):
	is_favorite = is_favorite_
	if not is_node_ready():
		await ready
	favorite_button.button_pressed = is_favorite


func set_project_features(project_features):
	if not is_node_ready():
		await ready
	if project_features == null:
		project_version = '<4'
		selected_version = '<4'
		await get_tree().create_timer(0.1).timeout
		show_version_warning()
		return
	project_version = project_features[0]
	await get_tree().create_timer(0.1).timeout
	show_version_warning()


func show_version_warning(index= -1):
	if index == -1:
		index = version_options.get_selected_id()
	if project_version not in version_options.get_item_text(index):
		if project_version == '<4':
			if version_options.get_item_text(version_options.get_selected_id()).length() > 0:
				var is_less_than_4 = int(version_options.get_item_text(version_options.get_selected_id())[0]) <4
				if is_less_than_4:
					warning.hide()
					return
		warning.show()
		warning.text = project_version
	else:
		warning.hide()



func _on_favorite_toggled(toggled_on):
	is_favorite = toggled_on
	if is_favorite:
		favorite_button.self_modulate = Color.WHITE
	else:
		favorite_button.self_modulate = Color.from_string("4f5864", Color.WHITE)
	if project_filepath != null:
		entry_favorited.emit(project_filepath, is_favorite)


func _on_select_pressed():
	select_button.button_pressed = true
	entry_selected.emit(project_id)


func entry_deselect():
	select_button.button_pressed = false


func _on_open_directory_pressed():
	open_project_directory.emit(project_filepath)


func set_project_versions(versions_array):
	var version_id = 1
	version_options.clear()
	version_options.add_item('')
	for version in versions_array:
		if int(version['version'][0]) < 4 and project_version != "<4":
			continue
		version_options.add_item(version['version'])
		if version['version'] == project_version:
			version_options.select(version_id)
			selected_version = version['version']
		version_id += 1

func _on_version_item_selected(index):
	selected_version = version_options.get_item_text(index)
	show_version_warning(index)
