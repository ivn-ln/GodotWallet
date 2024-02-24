extends HBoxContainer


@onready var name_label = $Name
@onready var version_label = $Version
@onready var status_button = $Status
@onready var add = $Add
@onready var delete = $Delete
@onready var confirmation_dialog = $ConfirmationDialog
var plugin_name
var plugin_path
var plugin_path_abs


signal status_changed(plugin, new_status)
signal add_plugin(plugin)
signal delete_plugin(plugin)


func set_global():
	if not is_node_ready():
		await ready
	status_button.hide()
	delete.hide()
	add.show()


func set_plugin_name(plugin_name_):
	if not is_node_ready():
		await ready
	plugin_name = plugin_name_
	name_label.text = plugin_name


func set_version(version):
	if not is_node_ready():
		await ready
	version_label.text = version


func set_status(status):
	if not is_node_ready():
		await ready
	status_button.button_pressed = status


func _on_add_pressed():
	add_plugin.emit(self)


func _on_status_toggled(toggled_on):
	status_changed.emit(self, toggled_on)


func _on_delete_pressed():
	confirmation_dialog.show()


func _on_confirmation_dialog_confirmed():
	delete_plugin.emit(self)
	confirmation_dialog.hide()


func _on_confirmation_dialog_canceled():
	confirmation_dialog.hide()
