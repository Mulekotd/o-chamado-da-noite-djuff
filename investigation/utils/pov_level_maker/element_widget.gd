class_name _ElementWidget extends Control

@onready var name_line_edit: LineEdit = $ScrollContainer/Panel/MarginContainer/VBoxContainer/HeaderContainer/NameLineEdit
@onready var necessary_items_widget: _ItemsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/NecessaryItemsContainer/NecessaryItemsWidget
@onready var conditions_widget: _ConditionsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/ConditionsContainer/ConditionsWidget
@onready var prompt_chain_widget: _PromptChainWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/PromptChainContainer/PromptChainWidget
@onready var hitbox_preview_widget: _HitboxPreviewWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/HitboxPreviewWidget
@onready var pov_name_widget: _PovNameWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/HBoxContainer/PovNameWidget
@onready var vars_to_change_widget: _ConditionsWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/VarsToChangeContainer/VarsToChangeWidget
@onready var cursor_selection_widget: _CursorSelectionWidget = $ScrollContainer/Panel/MarginContainer/VBoxContainer/AtributesContainer/CursorSelectionContainer/CursorSelectionWidget

@export var pov_level : PovLevel
@export var pov_image : Texture2D
@export var pov_name : String

var hitbox : Dictionary[String, float] = {
	"left" : 0.5,
	"top" : 0.5,
	"right" : 0.5,
	"bottom" : 0.5
}

const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")
const ADJUST_HITBOX_WIDGET = preload("uid://4vvofk8yf8tk")

func _ready() -> void:
	pov_name_widget.pov_name = pov_name

func load_element(e: Element, pov_names : Array[String] = []) -> void:
	# Populate the widget controls from an Element resource.
	name_line_edit.text = e.name
	hitbox = e.hitbox.duplicate()
	hitbox_preview_widget.load_hitbox_preview(get_pov_img(), e.hitbox)
	pov_name_widget.load_pov_name(e.pov_name)
	pov_name_widget.pov_name = e.pov_name
	prompt_chain_widget.load_prompt_chain(e.prompt_chain)
	necessary_items_widget.add_items(e.necessary_items)
	conditions_widget.add_conditions(e.conditions)
	vars_to_change_widget.add_conditions(e.vars_to_change)
	cursor_selection_widget.load_cursor_shape(e.cursor_shape)

func parse_element() -> Element:
	# Build a new Element resource from the current UI state.
	var e := Element.new()
	e.name = name_line_edit.text
	e.hitbox = hitbox.duplicate()
	e.pov_name = pov_name_widget.get_pov_name()
	e.prompt_chain = prompt_chain_widget.prompt_chain
	e.necessary_items = necessary_items_widget.items
	e.conditions = conditions_widget.parse_conditions()
	e.vars_to_change = vars_to_change_widget.parse_conditions()
	e.cursor_shape = cursor_selection_widget.parse_cursor_shape()
	return e

func save_element_file(path: String) -> void:
	ResourceSaver.save(parse_element(), path)

func update_hitbox(hitbox_values : Dictionary[String, float]) -> void:
	# Store and preview the updated hitbox.
	hitbox = hitbox_values.duplicate()
	hitbox_preview_widget.load_hitbox_preview(get_pov_img(), hitbox)

func get_pov_img() -> Texture2D:
	if pov_image:
		return pov_image
	return NO_IMAGE_POV

func _on_hitbox_preview_widget_gui_input(_event: InputEvent) -> void:
	if !Input.is_action_just_pressed("ui_mouse_pressed"):
		return
	# Open the hitbox adjustment popup.
	var ahw : _AdjustHitboxWidget = ADJUST_HITBOX_WIDGET.instantiate()
	add_child(ahw)
	await get_tree().process_frame
	ahw.load_hitbox(get_pov_img(), hitbox)
	ahw.closed.connect(update_hitbox)

signal closed(element: Element)
func _on_close_button_pressed() -> void:
	closed.emit(parse_element())
	queue_free()


func _on_cancel_button_pressed() -> void:
	queue_free()
