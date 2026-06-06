class_name TextBoxButton extends Button

const HOVER_BUTTON_STYLE_BOX = preload("uid://dldwn0cvgjavo")
const NORMAL_BUTTON_STYLE_BOX = preload("uid://82uktsq1bf80")
const PRESSED_BUTTON_STYLE_BOX = preload("uid://dy40agbwfa2d7")
const ACTION_HOVER_BUTTON_STYLE_BOX = preload("uid://csyw3u08762md")

var is_hovered : bool = false

## actions the option takes
var actions : int = 0 :
	set(x):
		actions = max(0,x)

func _ready() -> void:
	add_theme_stylebox_override("normal", NORMAL_BUTTON_STYLE_BOX)
	if !actions:
		add_theme_stylebox_override("hover", HOVER_BUTTON_STYLE_BOX)
	else:
		add_theme_stylebox_override("hover", ACTION_HOVER_BUTTON_STYLE_BOX)
	add_theme_stylebox_override("pressed", PRESSED_BUTTON_STYLE_BOX)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	
	mouse_entered.connect(func(): is_hovered = true)
	mouse_exited.connect(func(): is_hovered = false)

func _physics_process(delta: float) -> void:
	modulate = lerp(modulate, Color(0.346, 0.548, 1.0, 1.0) if is_hovered and actions else Color(1,1,1), 0.1)
