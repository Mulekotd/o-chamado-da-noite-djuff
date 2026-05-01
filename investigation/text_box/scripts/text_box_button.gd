class_name TextBoxButton extends Button

const HOVER_BUTTON_STYLE_BOX = preload("uid://dldwn0cvgjavo")
const NORMAL_BUTTON_STYLE_BOX = preload("uid://82uktsq1bf80")
const PRESSED_BUTTON_STYLE_BOX = preload("uid://dy40agbwfa2d7")

func _ready() -> void:
	add_theme_stylebox_override("normal", NORMAL_BUTTON_STYLE_BOX)
	add_theme_stylebox_override("hover", HOVER_BUTTON_STYLE_BOX)
	add_theme_stylebox_override("pressed", PRESSED_BUTTON_STYLE_BOX)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
