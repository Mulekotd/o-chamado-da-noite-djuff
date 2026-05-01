class_name CursorLoader extends Node

const CURSOR_ARROW = preload("uid://dyvhaeu8dd26n")
const CURSOR_BLOCKED = preload("uid://l30h2jwsv2py")
const CURSOR_HAND = preload("uid://v7ulks451ulx")
const CURSOR_MAGNIFIER = preload("uid://0uthes6vc12q")


func _ready() -> void:
	Input.set_custom_mouse_cursor(CURSOR_MAGNIFIER, Input.CURSOR_HELP, Vector2(11,11))
	Input.set_custom_mouse_cursor(CURSOR_ARROW, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(CURSOR_BLOCKED, Input.CURSOR_FORBIDDEN, Vector2(16,16))
	Input.set_custom_mouse_cursor(CURSOR_HAND, Input.CURSOR_POINTING_HAND, Vector2(4,0))
