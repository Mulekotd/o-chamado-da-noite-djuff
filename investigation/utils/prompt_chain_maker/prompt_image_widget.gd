class_name _PromptImageWidget extends TextureRect

const POV_WIDGET = preload("uid://c6s6iskf8pk6k")
const NO_IMAGE = preload("uid://dwj11t2nw18l2")

@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog

@export var default_img : Texture2D = NO_IMAGE

signal changed(img: Texture2D)

func _ready() -> void:
	# Initialize with the chain's default image.
	texture = default_img

func load_img(img: Texture2D) -> void:
	if img:
		print(img)
		texture = img
	else:
		texture = default_img
	changed.emit(texture)

func get_img() -> Texture2D:
	if texture != NO_IMAGE:
		return texture
	else:
		return null

func change_default_img(img: Texture2D) -> void:
	if img:
		if texture == default_img:
			texture = img
		default_img = img

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		image_load_file_dialog.popup()

func _on_close_button_pressed() -> void:
	load_img(null)
	changed.emit(texture)

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	var img := load(path)
	if img is Texture2D:
		load_img(img) 
