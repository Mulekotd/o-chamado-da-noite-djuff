class_name _Inventory extends Control

const ITEM_UI = preload("uid://xpgrehwl8fw0")

@export var transition_speed : float = 10
@export var items_container : Container
@export var inventory_container : Container
@export var item_name_label : Label

var item_uis : Array[_ItemUI]
var active : bool = false
var toggled_ever : bool = false

func _ready() -> void:
	load_items(InvestigationVars.get_inventory())

func _process(delta: float) -> void:
	if toggled_ever:
		var target_x : float = 0 if active else size.x
		inventory_container.position.x = lerpf(inventory_container.position.x, target_x, delta * transition_speed)
	else:
		inventory_container.position.x = size.x

func toggle_inventory(new_active: bool) -> void:
	active = new_active
	toggled_ever = true

func add_item(item: Item) -> _ItemUI:
	var item_ui : _ItemUI = ITEM_UI.instantiate()
	items_container.add_child(item_ui)
	item_uis.append(item_ui)
	item_ui.load_item(item)
	item_ui.item_hovered.connect(change_name_label)
	print("item ",item.name , " added")
	return item_ui

func add_items(items: Array[Item]) -> void:
	for item in items:
		add_item(item)

func clear_items() -> void:
	item_uis.clear()
	for c in items_container.get_children():
		c.queue_free

func load_items(items: Array[Item]) -> void:
	clear_items()
	add_items(items)

func remove_item(item: Item) -> void:
	for item_ui in item_uis:
		if item_ui.item == item:
			item_ui.queue_free()
			return

func remove_items(items: Array[Item]) -> void:
	for item in items:
		remove_item(item)

func get_items() -> Array[Item]:
	var items : Array[Item] = []
	for iui in item_uis:
			items.append(iui.item)
	return items

func change_name_label(name: String) -> void:
	item_name_label.text = name
