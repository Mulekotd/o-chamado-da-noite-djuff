extends Control

const PROMPT_WIDGET = preload("uid://cjh18gp04aw2o")
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var prompts_container: VBoxContainer = $VBoxContainer/VScrollBar/PromptsContainer
@onready var name_line_edit: LineEdit = $VBoxContainer/Container/HBoxContainer/NameLineEdit
@onready var texture_rect: TextureRect = $TextureRect

var bg : NoiseTexture2D
var bg_speed : Vector2 = Vector2(0.05,0.5)

func _ready() -> void:
	bg = texture_rect.texture

var elapsed : float = 0
func _physics_process(delta: float) -> void:
	elapsed += delta
	bg.noise.set("offset", Vector2(
		sin(bg_speed.x * elapsed) * 200,
		(bg_speed.y * elapsed) * 10 + cos(elapsed * bg_speed.y) * 5
		))

func load_prompt_chain(p_chain: PromptChain) -> void:
	clear_prompt_chain()
	name_line_edit.clear()
	name_line_edit.text = p_chain.name
	for p in p_chain.prompts:
		add_prompt(p)

func save_prompt_chain(path: String) -> void:
	var p_chain := parse_prompt_chain()
	ResourceSaver.save(p_chain, path)

func parse_prompt_chain() -> PromptChain:
	var p_chain := PromptChain.new()
	p_chain.name = name_line_edit.text
	for w in prompts_container.get_children():
		if w.is_in_group("prompt_widget"):
			p_chain.prompts.append(w.parse_prompt())
	return p_chain

func add_prompt(p: Prompt) -> void:
	var w : _PromptWidget = PROMPT_WIDGET.instantiate()
	w.add_to_group("prompt_widget")
	w.move_up_requested.connect(_on_prompt_widget_move_up_requested)
	w.move_down_requested.connect(_on_prompt_widget_move_down_requested)
	prompts_container.add_child(w)
	w.load_prompt(p)

func _on_prompt_widget_move_up_requested(widget: _PromptWidget) -> void:
	var current_index := widget.get_index()
	if current_index > 0:
		prompts_container.move_child(widget, current_index - 1)

func _on_prompt_widget_move_down_requested(widget: _PromptWidget) -> void:
	var current_index := widget.get_index()
	var last_index := prompts_container.get_child_count() - 1
	if current_index < last_index:
		prompts_container.move_child(widget, current_index + 1)

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

signal closed(p_chain: PromptChain)
func _on_close_button_pressed() -> void:
	closed.emit(parse_prompt_chain())
	await get_tree().process_frame
	queue_free()
