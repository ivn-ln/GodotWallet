extends Window


signal project_renamed(filepath, new_name)


@onready var line_edit = $Control/PanelContainer/MarginContainer/VBoxContainer/LineEdit
@onready var confirm_button = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Confirm
@onready var previous_name_label = $Control/PanelContainer/MarginContainer/VBoxContainer/PreviousName

var project_name
var project_filepath

func set_project_name(project_name_):
	if not is_node_ready():
		await ready
	project_name = project_name_
	previous_name_label.text += project_name
	line_edit.text = project_name
	line_edit.grab_focus()
	line_edit.select_all()


func _on_close_requested():
	queue_free()


func _on_cancel_pressed():
	queue_free()


func _on_confirm_pressed():
	var new_name = line_edit.text
	project_renamed.emit(project_filepath, new_name)
	queue_free()


func _on_line_edit_text_changed(new_text):
	if len(new_text) > 0:
		confirm_button.disabled = false
	else:
		confirm_button.disabled = true
	if new_text == project_name:
		previous_name_label.hide()
	else:
		previous_name_label.show()


func _on_line_edit_text_submitted(new_text):
	_on_confirm_pressed()
