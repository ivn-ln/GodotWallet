extends Control

@onready var tabs_container = $MarginContainer/PanelContainer/VBoxContainer/TabsContainer
@onready var about_popup = $AboutPopup


func _on_tab_bar_tab_selected(tab):
	for c in tabs_container.get_children():
		c.hide()
	tabs_container.get_child(tab).show()


func _on_button_about_pressed():
	about_popup.show()
