extends PanelContainer


@onready var tag_name = $HBoxContainer/TagName
@onready var color_rect = $HBoxContainer/ColorRect


func set_tag_name(tag):
	if not is_node_ready():
		await ready
	tag_name.text = tag.to_pascal_case()
	
