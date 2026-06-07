class_name _PovWidget extends Control

@onready var name_line_edit: LineEdit = $ScrollContainer/Panel/MarginContainer/VBoxContainer/HeaderContainer/NameLineEdit
@onready var behaviour_widget: _ScriptWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/HBoxContainer/BehaviourWidget
@onready var description_text_edit: TextEdit = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/DescricaoContainer/DescriptionTextEdit
@onready var prompt_chain_widget: _PromptChainWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/PromptChainContainer/PromptChainWidget
@onready var elements_widget: _ElementsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/ElementsContainer/ElementsWidget
@onready var conditions_widget: _ConditionsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/ConditionsContainer/ConditionsWidget
@onready var pov_image_rect: TextureRect = $ScrollContainer/Panel/MarginContainer/VBoxContainer/PovImageRect
@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog
@onready var sound_widget: _SoundWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/SoundContainer/SoundWidget

const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")
const POV_IMAGES_WIDGET = preload("uid://b2nqv18l1c3xo")

var pov_images : Array[PovImage]

func load_pov(pov: Pov) -> void:
	name_line_edit.text = pov.name
	description_text_edit.clear()
	description_text_edit.text = pov.description
	prompt_chain_widget.load_prompt_chain(pov.prompt_chain)
	elements_widget.add_elements(pov.elements)
	conditions_widget.add_conditions(pov.global_conditions)
	behaviour_widget.load_behaviour(pov.especial_behaviour)
	pov_images = pov.images
	sound_widget.load_sound(pov.sound)
	_load_preview_image()

func parse_pov() -> Pov:
	var pov := Pov.new()
	pov.name = name_line_edit.text
	pov.images = pov_images
	pov.description = description_text_edit.text
	pov.prompt_chain = prompt_chain_widget.prompt_chain
	pov.elements = elements_widget.elements
	pov.global_conditions = conditions_widget.parse_conditions()
	pov.especial_behaviour = behaviour_widget.get_behaviour()
	pov.sound = sound_widget.get_sound()
	return pov

func save_pov_file(path: String) -> void:
	ResourceSaver.save(parse_pov(), path)

func _load_pov_images(pis: Array[PovImage]) -> void:
	pov_images = pis
	_load_preview_image()

func _load_preview_image() -> void:
	if pov_images and pov_images[0].texture:
		pov_image_rect.texture = pov_images[0].texture
	else:
		pov_image_rect.texture = NO_IMAGE_POV

signal closed(pov: Pov)
func _on_close_button_pressed() -> void:
	closed.emit(parse_pov())
	queue_free()

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	# Load and assign a new POV image.
	var img := Image.load_from_file(path)
	pov_image_rect.texture = ImageTexture.create_from_image(img)

func _on_pov_image_rect_gui_input(event: InputEvent) -> void:
	if !Input.is_action_just_pressed("ui_mouse_pressed"):
		return
	var piw : _PovImagesWidget = POV_IMAGES_WIDGET.instantiate()
	piw.load_pov_images(pov_images)
	piw.closed.connect(_load_pov_images)
	var p : Control = get_tree().get_first_node_in_group("util_parent_control")
	if p:
		p.add_child(piw)
	else:
		add_child(piw)

func _on_elements_widget_opened_element() -> void:
	# Keep element editor context in sync with current POV.
	elements_widget.pov_image = pov_image_rect.texture
	elements_widget.pov_name = name_line_edit.text

func _on_cancel_button_pressed() -> void:
	queue_free()
