class_name _PromptWidget extends MarginContainer
## USE ATTACHED

signal move_up_requested(widget: _PromptWidget)
signal move_down_requested(widget: _PromptWidget)

@onready var give_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/GiveItemsContainer/GiveItemsWidget
@onready var take_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/TakeItemsContainer/TakeItemsWidget
@onready var end_chain_widget: CheckBox = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/EndChainContainer/EndChainWidget
@onready var pov_name_widget: _PovNameWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/PovContainer/PovNameWidget
@onready var change_vars_widget: _ConditionsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/VarsToChangeContainer/ChangeVarsWidget
@onready var options_widget: _OptionsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Opcoes/OptionsWidget
@onready var necessary_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pre/GridContainer/NecessaryItemsContainer/NecessaryItemsWidget
@onready var conditions_widget: _ConditionsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pre/GridContainer/ConditionsContainer/ConditionsWidget
@onready var text_widget: TextEdit = $MarginContainer/HBoxContainer/HSplitContainer/TextContainer/TextWidget
@onready var prompt_image_widget: _PromptImageWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pre/GridContainer/PromptImageWidget
@onready var pre_sound_widget: _SoundWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Sounds/VBoxContainer/HBoxContainer/PreSoundContainer/HBoxContainer/SoundWidget
@onready var pos_sound_widget: _SoundWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Sounds/VBoxContainer/HBoxContainer/PosSoundContainer/HBoxContainer/SoundWidget
@onready var letter_sounds_widget: _LetterSoundsWidget = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Sounds/VBoxContainer/LetterSoundsWidget
@onready var index_label: Label = $MarginContainer/IndexLabel
@onready var go_to_spin_box: SpinBox = $MarginContainer/HBoxContainer/HSplitContainer/TabContainer/Pos/GridContainer/EndChainContainer/HBoxContainer/GoToSpinBox

## highest prompt index in chain
var _max_go_to : int = -1
var go_to : int = -1
var id : int

func parse_prompt() -> Prompt:
	var p := Prompt.new()
	p.text = text_widget.text
	p.necessary_items = necessary_items_widget.items
	p.global_conditions = conditions_widget.parse_conditions()
	p.options = options_widget.parse_options()
	p.end_chain = end_chain_widget.button_pressed
	p.items_to_give = give_items_widget.items
	p.items_to_take = take_items_widget.items
	p.vars_to_change = change_vars_widget.parse_conditions()
	p.pov = pov_name_widget.get_pov_name()
	p.image_path = prompt_image_widget.get_img()
	p.pre_sound = pre_sound_widget.get_sound()
	p.pos_sound = pos_sound_widget.get_sound()
	p.letter_sound = letter_sounds_widget.parse_letter_sound()
	p.go_to = go_to
	print("PARSING:\ntext: ", text_widget.text, "\nidx: ", index_label.text, "\ngo to: ",go_to)
	return p

func load_prompt(p: Prompt) -> void:
	text_widget.text = p.text
	necessary_items_widget.add_items(p.necessary_items)
	conditions_widget.add_conditions(p.global_conditions)
	options_widget.load_options(p.options)
	end_chain_widget.button_pressed = p.end_chain
	give_items_widget.add_items(p.items_to_give)
	take_items_widget.add_items(p.items_to_take)
	change_vars_widget.add_conditions(p.vars_to_change)
	pov_name_widget.load_pov_name(p.pov)
	prompt_image_widget.load_img(p.image_path)
	pos_sound_widget.load_sound(p.pos_sound)
	go_to_spin_box.value = p.go_to
	letter_sounds_widget.load_global_letter_sounds()
	letter_sounds_widget.select_letter_sound(p.letter_sound)

func change_default_img(img_path: String):
	# Update default image for prompts that do not set one.
	prompt_image_widget.change_default_img(img_path)

func set_max_go_to(max: int) -> void:
	_max_go_to = max
	go_to_spin_box.max_value = max

func _on_remove_button_pressed() -> void:
	queue_free()

func _on_move_up_button_pressed() -> void:
	move_up_requested.emit(self)

func _on_move_down_button_pressed() -> void:
	move_down_requested.emit(self)

func _on_spin_box_value_changed(value: float) -> void:
	if value != index_label.text.to_int():
		go_to = value
		print("\ntext: ", text_widget.text, "\nidx: ", index_label.text, "\ngo to: ",go_to)
	else:
		if value == go_to_spin_box.max_value:
			go_to_spin_box.value = go_to
		else:
			go_to_spin_box.value = value + (value - go_to)
			go_to = go_to_spin_box.value
			print("\ntext: ", text_widget.text, "\nidx: ", index_label.text, "\n(skipped) go to: ",go_to)
