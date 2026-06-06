class_name _PovCompactWidget extends TextureRect

const POV_WIDGET = preload("uid://c6s6iskf8pk6k")
const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")

var pov : Pov

signal changed
signal clone_requested(clicked_pov: Pov)

func load_pov(p: Pov) -> void:
	pov = p
	if p and p.images:
		texture = p.images[0].texture
	else:
		texture = NO_IMAGE_POV
	changed.emit()

func get_pov() -> Pov:
	return pov

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		clone_requested.emit(pov)
		accept_event()
		return
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		# Open the POV editor window for this stacked entry.
		var pw : _PovWidget = POV_WIDGET.instantiate()
		var parent_control := get_tree().get_first_node_in_group("util_parent_control") as Control
		if parent_control == null:
			parent_control = self
		if pov == null:
			pov = Pov.new()
		parent_control.add_child(pw)
		pw.call_deferred("load_pov", pov)
		pw.closed.connect(load_pov)

signal closed(p: Pov)
func _on_close_button_pressed() -> void:
	var parent_node := get_parent()
	if parent_node:
		parent_node.remove_child(self)
	closed.emit(pov)
	changed.emit()
	queue_free()
