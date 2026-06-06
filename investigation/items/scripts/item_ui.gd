class_name _ItemUI extends PanelContainer

@onready var item_texture_rect: TextureRect = $ItemTextureRect

signal item_hovered(name: String)

var item : Item

func load_item(new_item: Item) -> void:
	item = new_item
	item_texture_rect.texture = item.image

func _on_gui_input(event: InputEvent) -> void:
	if item:
		item_hovered.emit(item.name)
