extends Control

# We grab a reference to the button node using its path in the tree
@onready var reload_button: Button = $ReloadButton

func _ready() -> void:
	# 1. Make sure the button is hidden when the scene starts
	reload_button.visible = false
	
	# 2. Connect the button's built-in "pressed" signal to our reload function
	reload_button.pressed.connect(_on_reload_button_pressed)

# This is the receiver function for your custom signal
func _on_died_emitted() -> void:
	# Make the button pop up on screen
	reload_button.visible = true


# This runs when the player actually clicks the button
func _on_reload_button_pressed() -> void:
	# get_tree().reload_current_scene() returns an Error code (OK or FAILED).
	# Wrapping it in an 'if' statement helps catch issues if the reload fails.
	if get_tree().reload_current_scene() != OK:
		print("Error: Failed to reload the scene!")
