class_name _PromptImageWidget extends TextureRect

const POV_WIDGET = preload("uid://c6s6iskf8pk6k")
const NO_IMAGE = preload("uid://dwj11t2nw18l2")

@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog

var image_path : String = ""
var default_image_path : String = ""

signal changed(img_path: String)

func _ready() -> void:
	_load_from_path(default_image_path)

func load_img(path: String) -> void:
	image_path = path
	_load_from_path(path)

func _load_from_path(path: String) -> void:
	if path:
		var tex := load(path)
		if tex is Texture2D:
			texture = tex
			return
	texture = load(default_image_path) if default_image_path else NO_IMAGE

func get_img() -> String:
	return image_path

func change_default_img(path: String) -> void:
	default_image_path = path
	if not image_path:
		_load_from_path(path)

func _on_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		image_load_file_dialog.popup()

func _on_close_button_pressed() -> void:
	load_img("")
	changed.emit(image_path)

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	load_img(path)
	changed.emit(image_path)
