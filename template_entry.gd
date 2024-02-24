extends PanelContainer


signal template_selected(template)
signal template_active_changed(template, new_active)


@onready var install_name = $GodotInstallEntry/MarginContainer/VBoxContainer/TopHBoxContainer/InstallName
@onready var install_icon = $GodotInstallEntry/InstallIcon
@onready var version_label = $GodotInstallEntry/MarginContainer/VBoxContainer/TopHBoxContainer/Version
@onready var select_button = $Select
var project_path
var template_name
var godot_version:
	set(value):
		godot_version = value
		if not is_node_ready():
			await ready
		version_label.text = godot_version


func set_template_name(template_name_):
	if not is_node_ready():
		await ready
	template_name = template_name_
	install_name.text = template_name


func set_template_icon(template_icon):
	if not is_node_ready():
		await ready
	install_icon.texture = template_icon


func _on_select_pressed():
	template_selected.emit(self)
	select_button.button_pressed = true


func deselect():
	select_button.button_pressed = false


func _on_check_box_toggled(toggled_on):
	template_active_changed.emit(self, toggled_on)
