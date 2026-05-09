class_name _PovImagesWidget extends Control

const POV_IMAGE_WIDGET = preload("uid://bgk0a5do5pmd1")

@export var cancel_button : Button
@export var close_button : Button
@export var add_button : Button
@export var remove_button : Button
@export var pov_images_container : Container

signal closed(pov_images: Array[PovImage])

func load_pov_image(pov_image: PovImage) -> void:
	var piw : _PovImageWidget = add_pov_image_widget()
	piw.load_pov_image(pov_image)

func load_pov_images(pov_images: Array[PovImage]) -> void:
	for pi in pov_images:
		load_pov_image(pi)

func parse_pov_images() -> Array[PovImage]:
	var pis : Array[PovImage]
	for piw in pov_images_container.get_children():
		pis.append(piw.parse_pov_image())
	return pis

func remove_pov_image_widget(index : int = -1) -> void:
	pov_images_container.get_children()[index].queue_free()

func add_pov_image_widget() -> _PovImageWidget:
	var piw : _PovImageWidget = POV_IMAGE_WIDGET.instantiate()
	pov_images_container.add_child(piw)
	return piw

## removes all pov image widgets
func clear() -> void:
	while pov_images_container.get_children().size():
		remove_pov_image_widget()

func _on_close_button_pressed() -> void:
	closed.emit(parse_pov_images())
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_add_button_pressed() -> void:
	add_pov_image_widget()

func _on_remove_button_pressed() -> void:
	remove_pov_image_widget()
