class_name _PovDirectionsWidget extends Control

@onready var pov_image_rect: TextureRect = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/PovImageRect
@onready var pov_button: Button = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/PovButton
@onready var top_pov_name: LineEdit = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/DirectionsContainer/TopPovName
@onready var left_pov_name: LineEdit = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/DirectionsContainer/LeftPovName
@onready var right_pov_name: LineEdit = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/DirectionsContainer/RightPovName
@onready var bottom_pov_name: LineEdit = $VBoxContainer/VBoxContainer/VBoxContainer/Panel/VBoxContainer/MarginContainer/VBoxContainer/DirectionsContainer/BottomPovName
@onready var rotation_slider: HSlider = $VBoxContainer/VBoxContainer/RotationSlider
@onready var arrow_widget: _ArrowWidget = $VBoxContainer/ArrowWidget

const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")
const POV_WIDGET = preload("uid://c6s6iskf8pk6k")

var pov : Pov = Pov.new()
var coords : Vector2

func parse_pov_directions() -> PovDirections:
	var p_dir := PovDirections.new()
	p_dir.pov = pov
	p_dir.left = left_pov_name.text
	p_dir.top = left_pov_name.top
	p_dir.right = left_pov_name.right
	p_dir.bottom = left_pov_name.bottom
	p_dir.visualizer_coords = coords
	p_dir.visualizer_rotation = rotation_slider.value
	return p_dir

func load_pov_directions(p_dir : PovDirections) -> void:
	load_pov(p_dir.pov)
	if p_dir.left:
		left_pov_name.text = p_dir.left
	if p_dir.top:
		top_pov_name.text = p_dir.top
	if p_dir.right:
		right_pov_name.text = p_dir.right
	if p_dir.bottom:
		bottom_pov_name.text = p_dir.bottom
	coords = p_dir.visualizer_coords
	spin_arrow(p_dir.visualizer_rotation)

func load_pov(new_pov: Pov) -> void:
	pov = new_pov
	if new_pov.image:
		pov_image_rect.texture = new_pov.image
	else:
		pov_image_rect.texture = NO_IMAGE_POV
	if new_pov.name:
		pov_button.text = new_pov.name
	else:
		pov_button.text = "Pov"

## 0 to 1
func spin_arrow(value: float) -> void:
	arrow_widget.rotation_degrees = 360*value

func open_pov_widget() -> void:
	var pw : _PovWidget = POV_WIDGET.instantiate()
	var p : Control = get_tree().get_first_node_in_group("util_parent_control")
	if (p == null):
		p = self
	p.add_child(pw)
	pw.load_pov(pov)
	pw.closed.connect(load_pov)

func _on_h_slider_value_changed(value: float) -> void:
	spin_arrow(value)

func _on_pov_button_pressed() -> void:
	open_pov_widget()

func _on_pov_image_rect_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		open_pov_widget()

signal closed
func _on_close_button_pressed() -> void:
	closed.emit()
	queue_free()
