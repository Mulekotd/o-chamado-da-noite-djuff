class_name _ElementsWidget extends VBoxContainer

@onready var element_list: ItemList = $ElementList

@export var pov_image : Texture2D
var pov_name : String

const ELEMENT_WIDGET = preload("uid://bc2hdvncpbval")

var elements : Array[Element]
var selected_index : int = -1

func _physics_process(delta: float) -> void:
	# Debug: keep track of the current elements array in output.
	pass# print(elements)

func remove_element(index: int) -> void:
	elements.remove_at(index)
	element_list.remove_item(index)

func add_elements(elements: Array[Element]) -> void:
	for e in elements:
		add_element(e)

func add_element(element: Element) -> void:
	# Add element to list and show a fallback label if needed.
	elements.append(element)
	if element.name:
		element_list.add_item(element.name)
	else:
		element_list.add_item("[Elemento]")

func update_element(new_e: Element, index: int) -> void:
	remove_element(index)
	add_element(new_e)

func _on_add_pressed() -> void:
	add_element(Element.new())

func _on_remove_pressed() -> void:
	remove_element(selected_index)

func _on_element_list_item_selected(index: int) -> void:
	selected_index = index

signal opened_element
func _on_element_list_item_activated(index: int) -> void:
	opened_element.emit()
	# Spawn an element editor window and bind updates to this list entry.
	var ew : _ElementWidget = ELEMENT_WIDGET.instantiate()
	var p : Control = get_tree().get_first_node_in_group("util_parent_control")
	if (p == null):
		p = self
	p.add_child(ew)
	p.move_child(ew, p.get_child_count() - 1)
	ew.z_as_relative = false
	ew.z_index = 1000
	ew.pov_name = pov_name
	ew.pov_image = pov_image
	ew.load_element(elements[index], )
	ew.closed.connect(update_element.bind(index))
