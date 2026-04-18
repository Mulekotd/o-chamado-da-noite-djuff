extends Control

@onready var main_text: RichTextLabel = $ColorRect/Text/MainText
@onready var options_container: HFlowContainer = $ColorRect/Text/OptionsContainer

var prompt_qeue : Array[Prompt]
var stand_by : bool = true
var is_writing : bool = false
var is_mouse_inside : bool = false
@export var wants_to_advance : bool = false # advance to next prompt
@export var write_time_min : float = 0.01
@export var write_time_max : float = 0.05

func _ready() -> void:
	clear_box()
	append_prompt(preload("uid://bbh3r1vylqulj"))
	append_prompt_chain(preload("uid://cgyg4xbvptlf6"))

func _physics_process(delta: float) -> void:
	if stand_by and !prompt_qeue.is_empty():
		next_prompt(-1)

func _process(delta: float) -> void:
	print(is_mouse_inside)
	if (Input.is_action_just_pressed("ui_accept") or\
		(Input.is_action_just_pressed("ui_mouse_pressed")) and is_mouse_inside) and\
		!stand_by:
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

func append_prompt(prompt: Prompt) -> void:
	prompt_qeue.append(prompt)
	
func append_prompt_chain(prompt_chain: PromptChain) -> void:
	for p in prompt_chain.prompts:
		prompt_qeue.append(p)

func display_prompt() -> void:
	is_writing = true
	var current_prompt := prompt_qeue[0]
	for c in prompt_qeue[0].text:
		if current_prompt != prompt_qeue[0]:
			return
		if wants_to_advance:
			main_text.text = prompt_qeue[0].text
			wants_to_advance = false
			break
		main_text.append_text(c)
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
			print("ACHOU O BOTAO")
			b.button_down
			options_container.get_node(name).connect("button_down", next_prompt.bind(i))
		i += 1

func next_prompt(cond: int) -> void:
	# TODO transition to scene if has one
	prompt_qeue.pop_front()
	if (prompt_qeue.size()): # if there is a next prompt
		print("TEXTO")
		if (prompt_qeue[0].condition_number != cond and\
			prompt_qeue[0].condition_number != -1):
			# TODO inventory check
			# TODO global condition check
			next_prompt(cond)
		else:
			stand_by = false
			print("PROXIMO")
			main_text.clear()
			clear_buttons()
			display_prompt()
	else: 
		clear_box()
		stand_by = true


func _on_mouse_entered() -> void:
	is_mouse_inside = true
func _on_mouse_exited() -> void:
	is_mouse_inside = false
