extends Window


@onready var tree = $Control/MarginContainer/VBoxContainer/Tree
@onready var project_options = $Control/MarginContainer/VBoxContainer/ProjectOptions
@onready var line_edit = $Control/MarginContainer/VBoxContainer/LineEdit
@onready var version_options = $Control/MarginContainer/VBoxContainer/VersionOptions
var current_project_path = ""
var root
signal template_imported(display_name, project_path, icon_path, godot_version)


func _ready():
	for project in Globals.projects_array:
		project_options.add_item(project['name'])
	_on_project_options_item_selected(0)
	set_project_versions(Globals.versions_array)


func set_project_versions(versions_array):
	version_options.clear()
	for version in versions_array:
		version_options.add_item(version['version'])


func _on_tree_item_selected():
	var selected_item: TreeItem = tree.get_selected()
	if selected_item.get_child_count() > 0:
		selected_item.collapsed = selected_item.is_checked(0)
	selected_item.set_checked(0, not selected_item.is_checked(0))
	if selected_item.is_checked(0) and selected_item.get_parent() != null:
		selected_item.get_parent().set_checked(0, true)
	select_recursive(selected_item, selected_item.is_checked(0))


func select_recursive(item, is_selected):
	for child in item.get_children():
		child.set_checked(0, is_selected)
		select_recursive(child, is_selected)


func _on_close_requested():
	queue_free()


func _on_project_options_item_selected(index):
	for project in Globals.projects_array:
		if index == project['id']:
			current_project_path = project['filepath']
			generate_tree()


func generate_tree():
	tree.clear()
	root = tree.create_item()
	root.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	root.set_text(0, project_options.get_item_text(project_options.get_selected_id()))
	#root.set_checked(0, true)
	get_tree_recursive(current_project_path, root)


func get_tree_recursive(starting_dir, parent):
	for file in DirAccess.get_files_at(starting_dir):
		if '.cache' in file || file == "":
			return
		var item: TreeItem = tree.create_item(parent)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_text(0, file)
		item.set_tooltip_text(0, starting_dir + '/' + file)
	for dir in DirAccess.get_directories_at(starting_dir):
		var item: TreeItem = tree.create_item(parent)
		item.collapsed = true
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_text(0, dir)
		item.set_tooltip_text(0, starting_dir + '/' + dir)
		get_tree_recursive(starting_dir + '/' + dir, item)


func _on_tree_empty_clicked(position, mouse_button_index):
	tree.deselect_all()


func _on_cancel_pressed():
	queue_free()


func _on_confirm_pressed():
	var version = version_options.get_item_text(version_options.get_selected_id())
	if version == "":
		OS.alert("Select valid godot version")
		return
	if line_edit.text == "":
		OS.alert("Enter a valid template name")
		return
	var checked_array = []
	get_checked_recursively(root, checked_array)
	var project_name = current_project_path.split('/')[current_project_path.split('/').size() - 1]
	var project_name_custom = line_edit.text
	var project_root = 'user://Templates/' + project_name_custom
	var error_stack = []
	if DirAccess.dir_exists_absolute(project_root):
		OS.alert("Template with this name already exists")
		return
	for item in checked_array:
		var item_path = item.get_tooltip_text(0)
		var item_path_rel
		if item_path.find(project_name) != -1:
			item_path_rel = item_path.substr(item_path.find(project_name) + project_name.length())
		var abs_path = project_root + item_path_rel
		if not '.' in ProjectSettings.globalize_path(abs_path):
			var e = DirAccess.make_dir_recursive_absolute(abs_path)
			if e != OK:
				error_stack.append(item_path)
			continue
		if not DirAccess.dir_exists_absolute(abs_path.get_base_dir()):
			DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
		var e = DirAccess.copy_absolute(item_path, abs_path)
		if e != OK:
			error_stack.append(item_path)
	if not error_stack.is_empty():
		var error_message = "Couldn't copy following files:"
		var limit = 30
		var error_count = 0
		for e in error_stack:
			if error_count == 30:
				error_message += "\n" + "and more"
				break
			error_message += "\n" + e
			error_count += 1
		#OS.alert(error_message)
	template_imported.emit(project_name_custom, project_root, "", version)
	OS.alert('Template created successfully!')
	queue_free()


func get_checked_recursively(item, output):
	for item_ in item.get_children():
		if item_.is_checked(0):
			output.append(item_)
		get_checked_recursively(item_, output)
