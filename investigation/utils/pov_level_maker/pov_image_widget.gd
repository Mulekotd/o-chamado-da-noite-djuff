class_name _PovImageWidget extends Control

@export var pov_image_texture_2d : TextureRect
@export var conditions_widget : _ConditionsWidget

@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog


const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")

func load_pov_image(pi: PovImage) -> void:
	_load_texture(pi.texture)
	conditions_widget.add_conditions(pi.conditions)

func parse_pov_image() -> PovImage:
	var pi : PovImage = PovImage.new()
	pi.texture = pov_image_texture_2d.texture
	pi.conditions = conditions_widget.parse_conditions()
	return pi

func _load_texture(texture: Texture2D) -> void:
	if texture:
		pov_image_texture_2d.texture = texture
	else:
		pov_image_texture_2d.texture = NO_IMAGE_POV

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	# Load and assign a new POV image.
	var img := Image.load_from_file(path)
	_load_texture(ImageTexture.create_from_image(img))

func _on_pov_image_texture_2d_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		image_load_file_dialog.popup()
		
func _on_remove_button_pressed() -> void:
	queue_free()
