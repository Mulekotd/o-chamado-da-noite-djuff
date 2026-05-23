class_name _SymbolsContainer extends Control

const NO_SYMBOL = preload("uid://byxcwmb372yeg")
const SYMBOL_WIDGET = preload("uid://dmdlrdl74dq2f")

@export var symbols_container : Container
@export var img_load_file_dialog : FileDialog

var symbol_count : int = 0
var selected_symbol : int = -1

func add_symbol(img: Texture2D = null) -> void:
	var symbol : TextureRect = SYMBOL_WIDGET.instantiate()
	if img:
		symbol.texture = img
	else:
		symbol.texture = NO_SYMBOL
	symbol.get_child(0).text = str(symbol_count)
	symbol.gui_input.connect(load_image_file.bind(symbol_count))
	symbols_container.add_child(symbol)
	symbol_count += 1

func add_symbols(imgs: Array[Texture2D]):
	for img in imgs:
		add_symbol(img)

func parse_symbols() -> Array[Texture2D]:
	var symbols : Array[Texture2D]
	for symbol in get_tree().get_nodes_in_group("symbol_widget"):
		symbols.append(symbol.texture)
	return symbols

func _on_add_button_pressed() -> void:
	add_symbol()

func _on_remove_button_pressed() -> void:
	var nodes = get_tree().get_nodes_in_group("symbol_widget")
	if nodes:
		nodes[-1].queue_free()
		symbol_count -= 1

func get_selected_symbol() -> TextureRect:
	for symbol in get_tree().get_nodes_in_group("symbol_widget"):
		if symbol.get_child(0).text == str(selected_symbol):
			return symbol
	return null

func load_image_file(event, symbol_index: int) -> void:
	if event is InputEventMouseButton:
		selected_symbol = symbol_index
		img_load_file_dialog.popup()

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	if selected_symbol == -1 or symbol_count < 1:
		return
	var img = load(path)
	if img is Texture2D:
		var symbol = get_selected_symbol()
		if symbol:
			symbol.texture = img
			return
