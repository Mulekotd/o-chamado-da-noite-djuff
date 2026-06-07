class_name _CursorSelectionWidget extends Control

@export var cursor_buttons : Dictionary[Element.cursor_shapes, Button]

func load_cursor_shape(shape: Element.cursor_shapes) -> void:
	cursor_buttons[shape].button_pressed = true

func parse_cursor_shape() -> Element.cursor_shapes:
	for shape in cursor_buttons.keys():
		if cursor_buttons[shape].button_pressed:
			return shape
	return Element.cursor_shapes.POINTING_HAND
