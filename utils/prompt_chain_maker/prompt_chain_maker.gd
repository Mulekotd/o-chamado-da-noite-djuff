extends Control

const PROMPT_WIDGET = preload("uid://cjh18gp04aw2o")
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var prompts_container: VBoxContainer = $VBoxContainer/VScrollBar/PromptsContainer

func _ready() -> void:
	pass

func load_prompt_chain(p_chain: PromptChain) -> void:
	clear_prompt_chain()
	for p in p_chain.prompts:
		add_prompt(p)

func save_prompt_chain(path: String) -> void:
	var p_chain := PromptChain.new()
	for w in prompts_container.get_children():
		if w.is_in_group("prompt_widget"):
			p_chain.prompts.append(w.parse_prompt())
	ResourceSaver.save(p_chain, path)

func add_prompt(p: Prompt) -> void:
	var w : _PromptWidget = PROMPT_WIDGET.instantiate()
	w.add_to_group("prompt_widget")
	prompts_container.add_child(w)
	w.load_prompt(p)

func clear_prompt_chain() -> void:
	for w in prompts_container.get_children():
		if w.is_in_group("prompt_widget"):
			w.queue_free()

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
	add_prompt(Prompt.new())
