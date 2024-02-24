extends PanelContainer

signal plugin_selected(plugin)
signal autoinstall_changed(plugin, new_value)

@onready var select_button = $Select
@onready var plugin_name_label = $PluginEntry/MarginContainer/VBoxContainer/PluginName
@onready var description_label = $PluginEntry/MarginContainer/VBoxContainer/Description
@onready var plugin_icon = $PluginEntry/PluginIcon
@onready var auto_install = $PluginEntry/MarginContainer/VBoxContainer/AutoInstall
var plugin_version
var project_path
var plugin_name


func set_plugin_name(plugin_name_):
	if not is_node_ready():
		await ready
	plugin_name = plugin_name_
	plugin_name_label.text = plugin_name


func set_plugin_icon(icon):
	if not is_node_ready():
		await ready
	plugin_icon.texture = icon


func deselect():
	select_button.button_pressed = false

func _on_select_pressed():
	plugin_selected.emit(self)
	select_button.button_pressed = true


func set_plugin_description(description):
	if not is_node_ready():
		await ready
	description_label.text = description
	description_label.tooltip_text = description


func _on_auto_install_toggled(toggled_on):
	autoinstall_changed.emit(self, toggled_on)


func set_autoinstall(autoinstall_):
	if not is_node_ready():
		await ready
	auto_install.button_pressed = autoinstall_
