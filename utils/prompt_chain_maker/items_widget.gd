extends VBoxContainer

@onready var item_list: ItemList = $ItemList
@onready var adicionar: Button = $Adicionar
@onready var remover: Button = $Remover
@onready var file_dialog: FileDialog = $FileDialog

var items : Array[Item]

func _add_item(item: Item) -> void:
	items.append(item)
	item_list.add_item(item.name, item.image)

func _remove_item_by_name(name: String) -> void:
	for i in items.size():
		if items[i].name == name:
			items.pop_at(i)
			return

func _on_adicionar_pressed() -> void:
	file_dialog.popup()

func _on_remover_pressed() -> void:
	for i in item_list.get_selected_items():
		_remove_item_by_name(item_list.get_item_text(i))
	for i in item_list.get_selected_items():
		item_list.remove_item(i)


func _on_file_dialog_file_selected(path: String) -> void:
	var item := load(path)
	if item is Item:
		_add_item(item)
