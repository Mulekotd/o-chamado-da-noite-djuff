extends CanvasLayer

@onready var slots = [
	$HBoxContainer/Item0,
	$HBoxContainer/Item1,
	$HBoxContainer/Item2
]

const ACTIVE_COLOR = Color(1, 1, 1, 1)
const INACTIVE_COLOR = Color(0.4, 0.4, 0.4, 1)

func _ready() -> void:
	# Start with the first item selected by default
	set_selected_slot(0)

# This function can now be called by any external node
func set_selected_slot(new_index: int) -> void:
	# Safety check to keep the index within bounds
	if new_index < 0 or new_index >= slots.size():
		return 
		
	for i in range(slots.size()):
		if i == new_index:
			slots[i].modulate = ACTIVE_COLOR
			slots[i].scale = Vector2(1.1, 1.1)
		else:
			slots[i].modulate = INACTIVE_COLOR
			slots[i].scale = Vector2(1.0, 1.0)
