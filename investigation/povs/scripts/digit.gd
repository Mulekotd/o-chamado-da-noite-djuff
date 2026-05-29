## digit to be displayed with a puzzle pov in the pov manager (during gameplay)
class_name Digit extends TextureRect

## global variable to store this digit's value
var global_var : String = ""
## current value of this digit
var curr_value : int = 0
## symbol images to show in this digit
var symbols : Array[Texture2D] = []
## total number of symbols
var total_symbols : int = 0

var enabled : bool = false

signal value_changed

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	gui_input.connect(increment_digit)
	mouse_filter = Control.MOUSE_FILTER_STOP

## applies the apropriate image according to symbols
func update_image() -> void:
	for i in total_symbols:
		if i == curr_value:
			texture = symbols[i]

## call this after assigning an apropriate parent to this node
func load_digit(d_pos: Vector2, d_size: Vector2, imgs: Array[Texture2D], var_to_change: String) -> void:
	position = d_pos
	size = d_size
	symbols = imgs
	total_symbols = imgs.size()
	global_var = var_to_change
	curr_value = InvestigationVars.get_var_value(global_var) % total_symbols
	update_image()

func increment_digit(_event) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed") and enabled:
		curr_value = (curr_value + 1) % total_symbols
		update_image()
		InvestigationVars.update_variables({global_var: curr_value})
		value_changed.emit()

func get_value() -> int:
	return curr_value
