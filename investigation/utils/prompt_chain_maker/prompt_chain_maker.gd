extends Control

const PROMPT_WIDGET = preload("uid://cjh18gp04aw2o")
@export var save_file_dialog: FileDialog
@export var load_file_dialog: FileDialog
@export var prompts_container: VBoxContainer
@export var default_prompt_image_widget: _PromptImageWidget
@export var name_line_edit: LineEdit
@export var end_of_prompts_indicator : Control
@export var prompts_scroll_container : ScrollContainer

var prompt_buffer : Array[Prompt] = []

func _process(delta: float) -> void:
	if is_end_visible():
		if prompt_buffer:
			add_prompt(prompt_buffer.pop_front())

func load_prompt_chain(p_chain: PromptChain) -> void:
	clear_prompt_chain()
	prompt_buffer.clear()
	name_line_edit.clear()
	name_line_edit.text = p_chain.name
	default_prompt_image_widget.load_img(p_chain.default_image_path)
	prompt_buffer = p_chain.prompts.duplicate()

func save_prompt_chain(path: String) -> void:
	var p_chain := parse_prompt_chain()
	ResourceSaver.save(p_chain, path)

func parse_prompt_chain() -> PromptChain:
	var p_chain := PromptChain.new()
	p_chain.name = name_line_edit.text
	p_chain.default_image_path = default_prompt_image_widget.get_img()
	for w in prompts_container.get_children():
		if w.is_in_group("prompt_widget"):
			p_chain.prompts.append(w.parse_prompt())
	p_chain.prompts.append_array(prompt_buffer)
	return p_chain

func add_prompt(p: Prompt) -> void:
	# Add a new prompt editor widget and bind default image updates.
	var w : _PromptWidget = PROMPT_WIDGET.instantiate()
	w.add_to_group("prompt_widget")
	w.move_up_requested.connect(_on_prompt_widget_move_up_requested)
	w.move_down_requested.connect(_on_prompt_widget_move_down_requested)
	prompts_container.add_child(w)
	w.change_default_img(default_prompt_image_widget.get_img())
	w.load_prompt(p)
	default_prompt_image_widget.changed.connect(w.change_default_img)
	_update_prompt_indexes()

func _on_prompt_widget_move_up_requested(widget: _PromptWidget) -> void:
	# Reorder prompt widgets within the chain.
	var current_index := widget.get_index()
	if current_index > 0:
		prompts_container.move_child(widget, current_index - 1)
	_update_prompt_indexes()

func _on_prompt_widget_move_down_requested(widget: _PromptWidget) -> void:
	var current_index := widget.get_index()
	var last_index := prompts_container.get_child_count() - 1
	if current_index < last_index:
		prompts_container.move_child(widget, current_index + 1)
	_update_prompt_indexes()

func _update_prompt_indexes() -> void:
	var pws := prompts_container.get_children()
	var i : int = 0 
	for pw in pws:
		if pw is _PromptWidget:
			pw.index_label.text = "%d" % i
			pw.set_max_go_to(pws.size() - 1)
			i += 1

func clear_prompt_chain() -> void:
	# Remove all prompt widgets from the editor.
	for w in prompts_container.get_children():
		if w.is_in_group("prompt_widget"):
			w.queue_free()

## returns rather the end of the prompt container is visible (i.e. if more should be loaded)
func is_end_visible() -> bool:
	if end_of_prompts_indicator.global_position.y <=\
	prompts_scroll_container.global_position.y + prompts_scroll_container.size.y:
		return true
	return false

func _on_save_button_pressed() -> void:
	save_file_dialog.popup()

func _on_load_button_pressed() -> void:
	load_file_dialog.popup()

func _on_load_file_dialog_file_selected(path: String) -> void:
	var p_chain := load(path)
	if p_chain is PromptChain:
		clear_prompt_chain()
		load_prompt_chain(p_chain)

func _on_save_file_dialog_file_selected(path: String) -> void:
	save_prompt_chain(path)

func _on_add_button_pressed() -> void:
	prompt_buffer.append(Prompt.new())

signal closed(p_chain: PromptChain)
func _on_close_button_pressed() -> void:
	closed.emit(parse_prompt_chain())
	await get_tree().process_frame
	queue_free()

func _on_cancel_button_pressed() -> void:
	queue_free()
