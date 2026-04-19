class_name TextBox extends Control

@onready var main_text: RichTextLabel = $ColorRect/Text/MainText
@onready var options_container: HFlowContainer = $ColorRect/Text/OptionsContainer

var prompt_qeue : Array[Prompt]
var stand_by : bool = true
var is_writing : bool = false
var is_mouse_inside : bool = false
var chain_number : int = 0
## if a prompt has this chain_id, it will be skipped
var skip_chain_id : int = -1
@export var wants_to_advance : bool = false # advance to next prompt
@export var write_time_min : float = 0.04
@export var write_time_max : float = 0.05
@export var write_time_comma : float = 0.5
@export var write_time_dot : float = 0.75

func _ready() -> void:
	clear_box()

func _physics_process(delta: float) -> void:
	if stand_by and !prompt_qeue.is_empty():
		# Ensure the first visible prompt also respects conditions.
		_skip_invalid_prompts(-1)
		if !prompt_qeue.is_empty():
			display_prompt()
		else:
			clear_box()
			skip_chain_id = -1
			stand_by = true

func _process(delta: float) -> void:
	if ((Input.is_action_just_pressed("ui_accept") or (Input.is_action_just_pressed("ui_mouse_pressed") and is_mouse_inside))) and prompt_qeue.size()>0:
		if prompt_qeue[0].options.size() == 0 and !is_writing:
			next_prompt(-1)
		else:
			wants_to_advance = true

func clear_buttons() -> void:
	for n in options_container.get_children():
		n.queue_free()

func clear_box() -> void:
	prompt_qeue.clear()
	main_text.clear()
	main_text.append_text("...")
	clear_buttons()
	chain_number = 0

func append_prompt(prompt: Prompt) -> void:
	prompt_qeue.append(prompt)
	
func append_prompt_chain(prompt_chain: PromptChain) -> void:
	for p in prompt_chain.prompts:
		p.chain_id = chain_number
		prompt_qeue.append(p)
	chain_number += 1
	if stand_by and !prompt_qeue.is_empty():
		_skip_invalid_prompts(-1)
		if !prompt_qeue.is_empty():
			display_prompt()

func display_prompt() -> void:
	is_writing = true
	stand_by = false
	main_text.clear()
	var current_prompt := prompt_qeue[0]
	for c in prompt_qeue[0].text:
		if current_prompt != prompt_qeue[0]:
			return
		if wants_to_advance:
			main_text.text = prompt_qeue[0].text
			wants_to_advance = false
			break
		main_text.append_text(c)
		match c:
			",": 
				await get_tree().create_timer(write_time_comma).timeout
			".": 
				await get_tree().create_timer(write_time_dot).timeout
			_:
				var delay := lerpf(write_time_min, write_time_max, randf())
				await get_tree().create_timer(delay).timeout
	is_writing = false
	
	var i = 0
	for option in prompt_qeue[0].options:
		var b = Button.new()
		b.text = option
		var name := "button_option_text_%d" % i
		b.name = name
		options_container.add_child(b)
		if options_container.get_node(name):
			b.button_down
			# avoid connecting multiple times error '-'
			if !options_container.get_node(name).is_connected("button_down", next_prompt.bind(i)):
				options_container.get_node(name).connect("button_down", next_prompt.bind(i))
		i += 1

func next_prompt(cond: int, can_end_chain: bool = true) -> void:
	# TODO transition to scene if has one
	if prompt_qeue.is_empty():
		clear_box()
		skip_chain_id = -1
		stand_by = true
		return

	var previous_prompt : Prompt = prompt_qeue.pop_front()
	if can_end_chain and previous_prompt.end_chain:
		skip_chain_id = previous_prompt.chain_id

	if can_end_chain:
		# Only mutate vars for a prompt that was actually advanced by the player.
		InvestigationVars.update_variables(previous_prompt.vars_to_change)

	if (prompt_qeue.size()): # if there is a next prompt
		if _is_prompt_valid(prompt_qeue[0], cond):
			main_text.clear()
			clear_buttons()
			display_prompt()
		else:
			next_prompt(cond, false)
	else: 
		clear_box()
		skip_chain_id = -1
		stand_by = true

func _on_mouse_entered() -> void:
	is_mouse_inside = true
func _on_mouse_exited() -> void:
	is_mouse_inside = false

func _is_prompt_valid(prompt: Prompt, cond: int) -> bool:
	# Shared prompt gate used by both first-display and next-prompt flows.
	return (prompt.condition_number == cond or prompt.condition_number == -1) and \
	InvestigationVars.check_global_conditions(prompt.global_conditions) and \
	InvestigationVars.check_inventory(prompt.necessary_items) and \
	prompt.chain_id != skip_chain_id

func _skip_invalid_prompts(cond: int) -> void:
	while !prompt_qeue.is_empty() and !_is_prompt_valid(prompt_qeue[0], cond):
		prompt_qeue.pop_front()
