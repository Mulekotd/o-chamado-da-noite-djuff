class_name TextBox extends Control

@onready var main_text: RichTextLabel = $ColorRect/Text/MainText
@onready var options_container: HFlowContainer = $ColorRect/Text/OptionsContainer
@onready var bouncing_dots_widget: _Bouncing_Dots_Widget = $ColorRect/Text/BouncingDotsWidget

signal stand_by_changed(state: bool)
signal prompt_sound_requested(sound: AudioStream)
signal letter_sound_requested(sound: AudioStream)
signal displayed_prompt(chain_id: int, prompt: Prompt)
signal chain_added(chain_id: int, chain: PromptChain)


var prompt_queue : Array[Prompt]
var stand_by : bool = true :
	set(x):
		stand_by = x
		stand_by_changed.emit(x)
var is_writing : bool = false
var is_mouse_inside : bool = false
var chain_number : int = 0
## if a prompt has this chain_id, it will be skipped
var skip_chain_id : int = -1
@export var wants_to_advance : bool = false # advance to next prompt
@export var write_time_min : float = 0.04
@export var write_time_max : float = 0.05
@export var write_time_comma : float = 0.2
@export var write_time_dot : float = 0.75

func _ready() -> void:
	clear_box()
	stand_by_changed.connect(func(x : bool): bouncing_dots_widget.visible = x)
	stand_by_changed.connect(func(x : bool): main_text.visible = !x)

func _physics_process(_delta: float) -> void:
	if stand_by and !prompt_queue.is_empty():
		# Ensure the first visible prompt also respects conditions.
		_skip_invalid_prompts(-1)
		if !prompt_queue.is_empty():
			display_prompt()
		else:
			clear_box()
			skip_chain_id = -1
			stand_by = true

func _process(_delta: float) -> void:
	if ((Input.is_action_just_pressed("ui_accept") or\
	(Input.is_action_just_pressed("ui_mouse_pressed") and\
	is_mouse_inside))) and\
	prompt_queue.size()>0 and\
	!stand_by:
		if _has_visible_options(prompt_queue[0]) == 0 and !is_writing:
			next_prompt(-1)
		else:
			wants_to_advance = true

func clear_buttons() -> void:
	for n in options_container.get_children():
		n.queue_free()

func clear_box() -> void:
	prompt_queue.clear()
	main_text.clear()
	main_text.append_text("...")
	clear_buttons()

func append_prompt(prompt: Prompt) -> void:
	#print(prompt.text," POV: ", prompt.pov)
	prompt_queue.append(prompt)
	
func append_prompt_chain(prompt_chain: PromptChain) -> void:
	for p in prompt_chain.prompts:
		p.chain_id = chain_number
		append_prompt(p)
	chain_added.emit(chain_number, prompt_chain)
	chain_number += 1
	if stand_by and !prompt_queue.is_empty():
		_skip_invalid_prompts(-1)
		if !prompt_queue.is_empty():
			display_prompt()

func display_prompt() -> void:
	is_writing = true
	stand_by = false
	main_text.clear()
	var current_prompt := prompt_queue[0]
	print("ADVANCED PROMPT")
	displayed_prompt.emit(prompt_queue[0].chain_id, current_prompt)
	for c in prompt_queue[0].text:
		if current_prompt != prompt_queue[0]:
			return
		if wants_to_advance:
			main_text.clear() 
			main_text.append_text(prompt_queue[0].text)
			wants_to_advance = false
			break
		main_text.append_text(c)
		letter_sound_requested.emit()
		match c:
			",": 
				await get_tree().create_timer(write_time_comma).timeout
			".": 
				await get_tree().create_timer(write_time_dot).timeout
			"?": 
				await get_tree().create_timer(write_time_dot).timeout
			"!": 
				await get_tree().create_timer(write_time_dot).timeout
			_:
				var delay := lerpf(write_time_min, write_time_max, randf())
				await get_tree().create_timer(delay).timeout
	is_writing = false
	
	var i : int = 0
	var options := 0
	for option in prompt_queue[0].options:
		if InvestigationVars.check_global_conditions(option.conditions) and\
		InvestigationVars.check_inventory(option.necessary_items):
			var b := TextBoxButton.new()
			b.text = option.text
			var name := "button_option_text_%d" % i
			b.name = name
			options_container.add_child(b)
			if options_container.get_node(name):
				# avoid connecting multiple times error '-'
				if !options_container.get_node(name).is_connected("button_down", next_prompt.bind(i)):
					options_container.get_node(name).connect("button_down", next_prompt.bind(i))
			options += 1
		i += 1

signal pov_entered(p: String)
func next_prompt(cond: int, can_end_chain: bool = true) -> void:
	if prompt_queue.is_empty():
		clear_box()
		skip_chain_id = -1
		stand_by = true
		return
	
	var previous_prompt : Prompt = prompt_queue.pop_front()
	if can_end_chain and previous_prompt.end_chain:
		skip_chain_id = previous_prompt.chain_id

	if can_end_chain:
		# Only mutate vars for a prompt that was actually advanced by the player.
		InvestigationVars.update_variables(previous_prompt.vars_to_change)
		InvestigationVars.append_item(previous_prompt.items_to_give)
		InvestigationVars.remove_item(previous_prompt.items_to_take)
		
		if previous_prompt.pos_sound:
			prompt_sound_requested.emit(previous_prompt.pos_sound)
			
		if previous_prompt.pov:
			pov_entered.emit(previous_prompt.pov)
	
	if (prompt_queue.size()): # if there is a next prompt
		wants_to_advance = false
		if _is_prompt_valid(prompt_queue[0], cond):
			main_text.clear()
			clear_buttons()
			display_prompt()
			if prompt_queue[0].pre_sound:
				prompt_sound_requested.emit(prompt_queue[0].pre_sound)
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
	if prompt.condition_number != -1 and prompt.condition_number != cond:
		return false
	if !InvestigationVars.check_global_conditions(prompt.global_conditions):
		return false
	if !InvestigationVars.check_inventory(prompt.necessary_items):
		return false
	if prompt.chain_id == skip_chain_id:
		return false
	return true

func _skip_invalid_prompts(cond: int) -> void:
	while !prompt_queue.is_empty() and !_is_prompt_valid(prompt_queue[0], cond):
		prompt_queue.pop_front()

func _has_visible_options(prompt: Prompt) -> int:
	var count := 0
	for option in prompt.options:
		if InvestigationVars.check_global_conditions(option.conditions) and\
		InvestigationVars.check_inventory(option.necessary_items):
			count += 1
	return count
