class_name CursorLoader extends Node

const CURSOR_ARROW = preload("uid://dyvhaeu8dd26n")
const CURSOR_BLOCKED = preload("uid://l30h2jwsv2py")
const CURSOR_HAND = preload("uid://v7ulks451ulx")
const CURSOR_MAGNIFIER = preload("uid://0uthes6vc12q")
const CURSOR_STEPS = preload("uid://bugpiicn5hlru")
const CURSOR_AIM = preload("uid://cf4e4q7y621cy")

func _ready() -> void:
	# Register all custom cursors used by the investigation UI.
	Input.set_custom_mouse_cursor(CURSOR_MAGNIFIER, Input.CURSOR_HELP, Vector2(11,11))
	Input.set_custom_mouse_cursor(CURSOR_ARROW, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(CURSOR_BLOCKED, Input.CURSOR_FORBIDDEN, Vector2(16,16))
	Input.set_custom_mouse_cursor(CURSOR_HAND, Input.CURSOR_POINTING_HAND, Vector2(4,0))
	Input.set_custom_mouse_cursor(CURSOR_STEPS, Input.CURSOR_MOVE, Vector2(16,16))
	Input.set_custom_mouse_cursor(CURSOR_AIM, Input.CURSOR_BUSY, Vector2(8,8))
