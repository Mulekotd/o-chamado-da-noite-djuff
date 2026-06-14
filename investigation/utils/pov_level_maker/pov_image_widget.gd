class_name _PovImageWidget extends Control

@export var pov_image_texture_2d : TextureRect
@export var conditions_widget : _ConditionsWidget

@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog

const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")

var _image_path : String = ""

func load_pov_image(pi: PovImage) -> void:
	_image_path = pi.image_path
	_load_texture_from_path(_image_path)
	conditions_widget.add_conditions(pi.conditions)

func parse_pov_image() -> PovImage:
	var pi : PovImage = PovImage.new()
	pi.image_path = _image_path
	pi.conditions = conditions_widget.parse_conditions()
	return pi

func _load_texture_from_path(path: String) -> void:
	if path:
		var tex := load(path)
		if tex is Texture2D:
			pov_image_texture_2d.texture = tex
			return
	pov_image_texture_2d.texture = NO_IMAGE_POV

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	_image_path = path
	_load_texture_from_path(path)

func _on_pov_image_texture_2d_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		image_load_file_dialog.popup()
		
func _on_remove_button_pressed() -> void:
	queue_free()
