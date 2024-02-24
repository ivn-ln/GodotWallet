extends PanelContainer


signal entry_selected(filepath)


@onready var install_name_label = $GodotInstallEntry/MarginContainer/VBoxContainer/TopHBoxContainer/InstallName
@onready var select_button = $Select
var filepath


func set_install_name(install_name):
	if not is_node_ready():
		await ready
	install_name_label.text += install_name
	




func _on_select_pressed():
	select_button.button_pressed = true
	entry_selected.emit(filepath)


func entry_deselect():
	select_button.button_pressed = false