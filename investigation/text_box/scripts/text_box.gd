class_name TextBox extends Control

@onready var main_text: RichTextLabel = $ColorRect/Text/MainText
@onready var options_container: HFlowContainer = $ColorRect/Text/OptionsContainer
@onready var bouncing_dots_widget: _Bouncing_Dots_Widget = $ColorRect/Text/BouncingDotsWidget

signal stand_by_changed(state: bool)
signal prompt_sound_requested(sound: AudioStream)
signal letter_sound_requested(sound: AudioStream)
signal displayed_prompt(chain_id: int, prompt: Prompt)
signal chain_added(chain_id: int, chain: PromptChain)
signal actions_used(actions: int)
signal investigation_points_added(points: int)
signal prompt_advanced()
signal items_added(item: Array[Item])
signal items_removed(item: Array[Item])

var prompt_queue : Array[Prompt]
var stand_by : bool = true :
	set(x):
		stand_by = x
		if x:
			InvestigationVars.set_option(-1)
		stand_by_changed.emit(x)
var is_writing : bool = false
var is_mouse_inside : bool = false
## used to check changes of chains
var last_chain_id : int = -1
## used to give ids to prompts
var chain_number : int = 0
## if a prompt has this chain_id, it will be skipped
var skip_chain_id : int = -1
## chain buffer for chains with "go to" prompts; clear once on stand by
var chain_buffer : Dictionary[int, PromptChain]
@export var wants_to_advance : bool = false # advance to next prompt
@export var write_time_min : float = 0.04
@export var write_time_max : float = 0.05
@export var write_time_comma : float = 0.2
@export var write_time_dot : float = 0.75

var enabled : bool = true

func _ready() -> void:
	clear_box()
	stand_by_changed.connect(func(x : bool): bouncing_dots_widget.visible = x)
	stand_by_changed.connect(func(x : bool): main_text.visible = !x)

func _physics_process(_delta: float) -> void:
	if stand_by and !prompt_queue.is_empty():
		# Try to display the next valid prompt as soon as we are idle.
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
	is_mouse_inside))) and prompt_queue.size():
		if _has_visible_options(prompt_queue[0]) == 0 and !is_writing:
			next_prompt(-1)
			await get_tree().process_frame
			prompt_advanced.emit()
		else:
			wants_to_advance = true
	if stand_by:
		wants_to_advance = false

func _wait_till_enabled() -> void:
	while not enabled:
		await get_tree().process_frame

func clear_buttons() -> void:
	for n in options_container.get_children():
		n.queue_free()

func clear_box() -> void:
	prompt_queue.clear()
	main_text.clear()
	clear_buttons()
	chain_buffer.clear()

func insert_prompt(prompt: Prompt, index: int = -1) -> void:
	if index == -1:
		prompt_queue.append(prompt)
	else:
		prompt_queue.insert(index, prompt)

## if index = -1, appends to end of queue
func insert_prompt_chain(prompt_chain: PromptChain, index: int = -1) -> void:
	_insert_prompt_chain_from_index(prompt_chain, 0, index)

func _insert_prompt_chain_from_index(prompt_chain: PromptChain, start_index: int, index: int = -1) -> void:
	if !prompt_chain:
		return
	var prompt_count := prompt_chain.prompts.size()
	if prompt_count == 0:
		return
	var start := clampi(start_index, 0, prompt_count)
	if start >= prompt_count:
		return
	var has_go_to := false
	for i in range(start, prompt_count):
		# Duplicate prompts so per-queue chain_id does not mutate shared resources.
		var p := prompt_chain.prompts[i].duplicate(true)
		p.chain_id = chain_number
		insert_prompt(p, index)
		if index != -1:
			index += 1
		if p.go_to != -1:
			has_go_to = true
	if has_go_to:
		chain_buffer.set(chain_number, prompt_chain)
	chain_added.emit(chain_number, prompt_chain)
	chain_number += 1
	if stand_by and !prompt_queue.is_empty():
		_skip_invalid_prompts(-1)
		if !prompt_queue.is_empty():
			display_prompt()

func display_prompt() -> void:
	_wait_till_enabled()
	is_writing = true
	stand_by = false
	main_text.clear()
	var current_prompt := prompt_queue[0]
	displayed_prompt.emit(prompt_queue[0].chain_id, current_prompt)
	# Typewriter effect; can be fast-forwarded by player input.
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
	
	# Build option buttons only for options that pass conditions.
	var i : int = 0
	var options := 0
	for option in prompt_queue[0].options:
		if InvestigationVars.get_conditions_value(option.conditions) != -1 and\
		InvestigationVars.check_inventory(option.necessary_items) and\
		(option.actions <= InvestigationVars.get_actions() if option.actions else true):
			var b := TextBoxButton.new()
			b.text = option.text
			b.actions = option.actions
			if option.actions:
				b.text = b.text + " [-%d AÇÃO]" % option.actions
				b.connect("button_down", actions_used.emit.bind(option.actions))
			if option.investigation_points:
				b.connect("button_down", investigation_points_added.emit.bind(option.investigation_points))
			var name := "button_option_text_%d" % i
			b.name = name
			options_container.add_child(b)
			if options_container.get_node(name):
				# avoid connecting multiple times error '-'
				if !options_container.get_node(name).is_connected("button_down", next_prompt.bind(i)):
					options_container.get_node(name).connect("button_down", next_prompt.bind(i))
			options += 1
		i += 1

## appends a prompt chain immediately after the current one
func _insert_chain_to_front(pc: PromptChain, start_index: int) -> void:
	_insert_prompt_chain_from_index(pc, start_index, 0)

signal pov_entered(p: String)
func next_prompt(cond: int, can_end_chain: bool = true) -> void:
	_wait_till_enabled()
	if prompt_queue.is_empty():
		clear_box()
		skip_chain_id = -1
		stand_by = true
		return
	if can_end_chain and cond != -1:
		InvestigationVars.set_option(cond)
	
	var previous_prompt : Prompt = prompt_queue.pop_front()
	if can_end_chain and (previous_prompt.end_chain or previous_prompt.go_to != -1):
		skip_chain_id = previous_prompt.chain_id
		if previous_prompt.go_to != -1 and chain_buffer.has(previous_prompt.chain_id):
			while prompt_queue and prompt_queue[0].chain_id == previous_prompt.chain_id:
				prompt_queue.pop_front()
			_insert_chain_to_front(chain_buffer[previous_prompt.chain_id], previous_prompt.go_to)

	if can_end_chain:
		# Apply prompt side-effects when the player advances it.
		# Only mutate vars for a prompt that was actually advanced by the player.
		InvestigationVars.update_variables(previous_prompt.vars_to_change)
		print("texto: ",previous_prompt.text)
		if previous_prompt.items_to_give:
			print("item adicionado: ", previous_prompt.items_to_give[0].name)
		InvestigationVars.append_item(previous_prompt.items_to_give)
		items_added.emit(previous_prompt.items_to_give)
		InvestigationVars.remove_item(previous_prompt.items_to_take)
		items_removed.emit(previous_prompt.items_to_take)
		
		if previous_prompt.pos_sound:
			prompt_sound_requested.emit(previous_prompt.pos_sound)
			
		if previous_prompt.pov:
			pov_entered.emit(previous_prompt.pov)
	
	if prompt_queue: # if there is a next prompt
		wants_to_advance = false
		if _is_prompt_valid(prompt_queue[0], cond):
			main_text.clear()
			clear_buttons()
			display_prompt()
			if prompt_queue[0].pre_sound:
				prompt_sound_requested.emit(prompt_queue[0].pre_sound)
			# check if this prompt's id is different than the last
			#print("last chain id: %d, new one: %d" % [last_chain_id, prompt_queue[0].chain_id])
			#if prompt_queue[0].chain_id != last_chain_id:
				#print("new chain, setting 'options' to -1")
				#InvestigationVars.set_option(-1)
			last_chain_id = prompt_queue[0].chain_id
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
	if InvestigationVars.get_conditions_value(prompt.global_conditions) == -1:
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
		if InvestigationVars.get_conditions_met(option.conditions) and\
		InvestigationVars.check_inventory(option.necessary_items) and\
		option.actions <= InvestigationVars.get_actions() if option.actions else true:
			count += 1
	return count
