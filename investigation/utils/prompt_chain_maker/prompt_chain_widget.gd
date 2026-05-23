class_name _PromptChainWidget extends Control

@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var edit_button: Button = $HBoxContainer/EditButton
const PROMPT_CHAIN_MAKER = preload("uid://sde7emoawly0")

var prompt_chain : PromptChain

func load_prompt_chain(p_chain: PromptChain) -> void:
	prompt_chain = p_chain
	name_label.text = prompt_chain.name

func load_prompt_chain_file(path: String) -> void:
	var p_chain := load(path)
	if p_chain is PromptChain:
		load_prompt_chain(p_chain)

func save_prompt_chain_file(path: String) -> void:
	if prompt_chain:
		ResourceSaver.save(prompt_chain, path)

func parse_prompt_chain() -> PromptChain:
	return prompt_chain

func _on_edit_button_pressed() -> void:
	# Open the prompt chain editor window.
	var pcm := PROMPT_CHAIN_MAKER.instantiate()
	# get parent util
	var p : Control = get_tree().get_first_node_in_group("util_parent_control")
	if (p == null):
		p = self
	p.add_child(pcm)
	p.move_child(pcm, p.get_child_count() - 1)
	pcm.z_as_relative = false
	pcm.z_index = 1100
	if prompt_chain:
		pcm.load_prompt_chain(prompt_chain)
	pcm.closed.connect(load_prompt_chain)
