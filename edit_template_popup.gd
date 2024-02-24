extends Window


@onready var version_options = $Control/MarginContainer/VBoxContainer/VersionOptions
@onready var line_edit = $Control/MarginContainer/VBoxContainer/LineEdit
signal template_changed(new_name, new_version)


func _ready():
	set_project_versions(Globals.versions_array)


func set_godot_version(godot_version):
	if not is_node_ready():
		await ready
	var found = false
	for i in range(version_options.item_count):
		if version_options.get_item_text(i) == godot_version:
			version_options.select(i)
			found = true
			break
	if not found:
		version_options.add_item(godot_version)
		for i in range(version_options.item_count):
			if version_options.get_item_text(i) == godot_version:
				version_options.select(i)
				found = true
				break


func set_template_name(new_name):
	if not is_node_ready():
		await ready
	line_edit.text = new_name


func set_project_versions(versions_array):
	version_options.clear()
	for version in versions_array:
		version_options.add_item(version['version'])

func _on_confirm_pressed():
	var version = version_options.get_item_text(version_options.get_selected_id())
	if version == "":
		OS.alert("Select valid godot version")
		return
	if line_edit.text == "":
		OS.alert("Enter a valid template name")
		return
	template_changed.emit(line_edit.text, version)
	queue_free()


func _on_cancel_pressed():
	queue_free()


func _on_close_requested():
	queue_free()
