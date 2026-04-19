extends Control

@onready var name_line_edit: LineEdit = $ScrollContainer/Panel/MarginContainer/VBoxContainer/HeaderContainer/NameLineEdit
@onready var description_text_edit: TextEdit = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/DescricaoContainer/DescriptionTextEdit
@onready var prompt_chain_widget: _PromptChainWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/PromptChainContainer/PromptChainWidget
@onready var elements_widget: _ElementsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/ElementsContainer/ElementsWidget
@onready var conditions_widget: _ConditionsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/ConditionsContainer/ConditionsWidget
@onready var pov_image_rect: TextureRect = $ScrollContainer/Panel/MarginContainer/VBoxContainer/PovImageRect
@onready var image_load_file_dialog: FileDialog = $ImageLoadFileDialog

const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")

func load_pov(pov: Pov) -> void:
	name_line_edit.text = pov.name
	if pov.image:
		pov_image_rect.texture = pov.image
	else:
		pov_image_rect.texture = NO_IMAGE_POV
	description_text_edit.clear()
	description_text_edit.text = pov.description
	prompt_chain_widget.load_prompt_chain(pov.prompt_chain)
	elements_widget.add_elements(pov.elements)
	conditions_widget.add_conditions(pov.global_conditions)

func parse_pov() -> Pov:
	var pov := Pov.new()
	pov.name = name_line_edit.text
	if pov_image_rect.texture != NO_IMAGE_POV:
		pov.image = pov_image_rect.texture
	pov.description = description_text_edit.text
	pov.prompt_chain = prompt_chain_widget.prompt_chain
	pov.elements = elements_widget.elements
	pov.global_conditions = conditions_widget.parse_conditions()
	return pov

signal closed(pov: Pov)
func _on_close_button_pressed() -> void:
	closed.emit(parse_pov())
	queue_free()

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	var img := Image.load_from_file(path)
	pov_image_rect.texture = ImageTexture.create_from_image(img)

func _on_pov_image_rect_gui_input(event: InputEvent) -> void:
	if !Input.is_action_just_pressed("ui_mouse_pressed"):
		return
	image_load_file_dialog.popup()
