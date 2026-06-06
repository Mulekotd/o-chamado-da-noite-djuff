class_name _DigitWidget extends TextureRect

@export var index_label : Label

## distance from this node's pivot to the mouse position when beginning to drag
var drag_offset : Vector2 = Vector2.ZERO

var dragging : bool = false
var resizing : bool = false

# drag widget if mouse pressed (outside of size handle)
# resize widget if mouse dragging the size handle

func _physics_process(delta: float) -> void:
	if not Input.is_action_pressed("ui_mouse_pressed"):
		dragging = false
		resizing = false
	if dragging:
		var mouse_pos : Vector2 = get_global_mouse_position()
		global_position = mouse_pos - drag_offset
	if resizing:
		var mouse_pos : Vector2 = get_global_mouse_position()
		if Input.is_action_pressed("ui_control"):
			var original_size := texture.get_size()
			var scale : float = (mouse_pos.y - global_position.y)/texture.get_size().y
			size = original_size * scale
		else:
			size = mouse_pos - global_position

func _on_gui_input(event: InputEvent) -> void:
	if dragging or resizing: return
	if event is InputEventMouseButton and Input.is_action_pressed("ui_mouse_pressed"):
		dragging = true
		drag_offset = event.position

func _on_size_handle_gui_input(event: InputEvent) -> void:
	if dragging or resizing: return
	if event is InputEventMouseButton and Input.is_action_pressed("ui_mouse_pressed"):
		resizing = true
