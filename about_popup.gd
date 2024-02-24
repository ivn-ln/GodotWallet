extends Window


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_close_requested():
	hide()


func _on_github_pressed():
	OS.shell_open('https://github.com/ivn-ln')


func _on_itch_pressed():
	OS.shell_open('https://illarn.itch.io/')
