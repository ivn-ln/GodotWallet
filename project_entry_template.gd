class_name ProjectEntry extends PanelContainer


var project_entry_packed = preload('res://project_entry.tscn')
var project_entry
var project_id
signal entry_selected(project_id)
signal open_project_directory(directory)
signal entry_favorited(filepath)


func _ready():
	self_modulate = Color.TRANSPARENT


func _init(project_dict):
	project_id = project_dict['id']
	project_entry = project_entry_packed.instantiate()
	add_child(project_entry)
	update_entry_info(project_dict)
	project_entry.project_id = project_id
	project_entry.entry_selected.connect(_on_entry_selected)
	project_entry.open_project_directory.connect(_on_open_project_directory)
	project_entry.entry_favorited.connect(_on_entry_favorited)


func update_entry_info(project_dict):
	project_entry.set_project_name(project_dict['name'])
	project_entry.set_is_project_favorite(project_dict['favorite'])
	project_entry.set_project_filepath(project_dict['filepath'])
	project_entry.set_project_features(project_dict['features'])
	project_entry.set_project_tags(project_dict['tags'])
	if project_dict['icon'] != null:
		var project_icon_filepath = project_dict['icon'].trim_prefix('res://')
		var global_icon_filepath = project_dict['filepath'] + '/' + project_icon_filepath
		if FileAccess.file_exists(global_icon_filepath):
			var project_image = Image.load_from_file(global_icon_filepath)
			var project_icon = ImageTexture.create_from_image(project_image)
			project_entry.set_project_icon(project_icon)
		else:
			project_entry.set_project_icon(load(Globals.default_icon))
			push_warning('Icon not found: ' + global_icon_filepath)
	else:
		project_entry.set_project_icon(load(Globals.default_icon))
		push_warning('Project has no icon: ' + project_dict['name'])


func _on_entry_selected(project_id):
	entry_selected.emit(project_id)


func _on_open_project_directory(directory):
	open_project_directory.emit(directory)


func entry_deselect():
	project_entry.entry_deselect()


func _on_entry_favorited(filepath, is_favorite):
	entry_favorited.emit(filepath, is_favorite)
