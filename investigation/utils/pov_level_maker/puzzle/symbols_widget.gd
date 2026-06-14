class_name _SymbolsWidget extends Control

const NO_SYMBOL = preload("uid://byxcwmb372yeg")
const SYMBOL_WIDGET = preload("uid://dmdlrdl74dq2f")

@export var symbols_container : Container
@export var img_load_file_dialog : FileDialog

var symbol_paths : Array[String] = []
var symbol_count : int = 0
var selected_symbol : int = -1

signal changed()

func add_symbol(img_path: String = "") -> void:
	var symbol : TextureRect = SYMBOL_WIDGET.instantiate()
	if img_path:
		var tex := load(img_path)
		if tex is Texture2D:
			symbol.texture = tex
		else:
			symbol.texture = NO_SYMBOL
	else:
		symbol.texture = NO_SYMBOL
	symbol_paths.append(img_path)
	symbol.get_child(0).text = str(symbol_count)
	symbol.gui_input.connect(load_image_file.bind(symbol_count))
	symbols_container.add_child(symbol)
	symbol_count += 1
	changed.emit()

func add_symbols(paths: Array[String]) -> void:
	for p in paths:
		add_symbol(p)

func load_symbols(paths: Array[String]) -> void:
	clear()
	add_symbols(paths)

func clear() -> void:
	var children := symbols_container.get_children()
	for c in children:
		if c.is_in_group("symbol_widget"):
			c.queue_free()
	symbol_paths.clear()
	symbol_count = 0
	changed.emit()

func parse_symbols() -> Array[String]:
	return symbol_paths.duplicate()

func _on_add_button_pressed() -> void:
	add_symbol()

func _on_remove_button_pressed() -> void:
	var nodes = get_tree().get_nodes_in_group("symbol_widget")
	if nodes:
		nodes[-1].queue_free()
		symbol_count -= 1
		if symbol_paths:
			symbol_paths.pop_back()
		changed.emit()

func get_selected_symbol() -> TextureRect:
	for symbol in get_tree().get_nodes_in_group("symbol_widget"):
		if symbol.get_child(0).text == str(selected_symbol):
			return symbol
	return null

func load_image_file(event, symbol_index: int) -> void:
	if  Input.is_action_pressed("ui_mouse_pressed"):
		selected_symbol = symbol_index
		img_load_file_dialog.popup()
		changed.emit()

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	if selected_symbol == -1 or symbol_count < 1:
		return
	var img = load(path)
	if img is Texture2D:
		var symbol = get_selected_symbol()
		if symbol:
			symbol.texture = img
			# update the path in our array
			while symbol_paths.size() <= selected_symbol:
				symbol_paths.append("")
			symbol_paths[selected_symbol] = path
			changed.emit()
			return
