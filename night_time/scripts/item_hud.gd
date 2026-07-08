extends CanvasLayer
# Preload the red circle asset once to save performance
const RED_CIRCLE_TEXTURE = preload("res://night_time/assets/red_circle.png")

# Assign this in the Godot editor's Inspector panel
@export var player: CharacterBody2D

@onready var slots = [
	$HBoxContainer/Item0,
	$HBoxContainer/Item1,
	$HBoxContainer/Item2
]
@onready var label = $Label

const ACTIVE_COLOR = Color(1, 1, 1, 1)
const INACTIVE_COLOR = Color(0.4, 0.4, 0.4, 1)

func _ready() -> void:
	# Start with the first item selected by default
	set_selected_slot(2)

func _process(_delta: float) -> void:
	# Only show the label when the player isn't idle
	if player:
		label.visible = player.current_action_state != 0

# This function can now be called by any external node
func set_selected_slot(new_index: int) -> void:
	# Safety check to keep the index within bounds
	if new_index < 0 or new_index >= slots.size():
		return 
	for i in range(slots.size()):
		# Safely grab the SelectionRing node inside the slot
		var ring_node = slots[i].get_node_or_null("SelectionRing") as TextureRect
		
		if i == new_index:
			slots[i].modulate = ACTIVE_COLOR
			slots[i].scale = Vector2(1.1, 1.1)
			
			# Assign the red circle texture to show it
			if ring_node:
				ring_node.texture = RED_CIRCLE_TEXTURE
		else:
			slots[i].modulate = INACTIVE_COLOR
			slots[i].scale = Vector2(1.0, 1.0)
			
			# Clear the texture to hide it
			if ring_node:
				ring_node.texture = null
