class_name _PromptWidget extends MarginContainer
## USE ATTACHED

signal move_up_requested(widget: _PromptWidget)
signal move_down_requested(widget: _PromptWidget)

@onready var text_widget: TextEdit = $MarginContainer/HBoxContainer/TextContainer/TextWidget
@onready var conditions_widget: _ConditionsWidget = $MarginContainer/HBoxContainer/GridContainer/ConditionsContainer/ConditionsWidget
@onready var necessary_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/GridContainer/NecessaryItemsContainer/NecessaryItemsWidget
@onready var options_widget: _OptionsWidget = $MarginContainer/HBoxContainer/GridContainer/OptionsContainer/OptionsWidget
@onready var condition_number_widget: TextEdit = $MarginContainer/HBoxContainer/GridContainer/ConditionNumberContainer/ConditionNumberWidget
@onready var end_chain_widget: CheckBox = $MarginContainer/HBoxContainer/GridContainer/EndChainContainer/EndChainWidget
@onready var give_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/GridContainer/GiveItemsContainer/GiveItemsWidget
@onready var take_items_widget: _ItemsWidget = $MarginContainer/HBoxContainer/GridContainer/TakeItemsContainer/TakeItemsWidget
@onready var change_vars_widget: _ConditionsWidget = $MarginContainer/HBoxContainer/GridContainer/VarsToChangeContainer/ChangeVarsWidget

var id : int

func parse_prompt() -> Prompt:
	var p := Prompt.new()
	p.text = text_widget.text
	p.condition_number = condition_number_widget.text.to_int()
	p.necessary_items = necessary_items_widget.items
	p.global_conditions = conditions_widget.parse_conditions()
	p.options = options_widget.parse_options()
	p.end_chain = end_chain_widget.button_pressed
	p.items_to_give = give_items_widget.items
	p.items_to_take = take_items_widget.items
	p.vars_to_change = change_vars_widget.parse_conditions()
	return p

func load_prompt(p: Prompt) -> void:
	text_widget.text = p.text
	condition_number_widget.text = "%d" % p.condition_number
	necessary_items_widget.add_items(p.necessary_items)
	conditions_widget.add_conditions(p.global_conditions)
	options_widget.add_options(p.options)
	end_chain_widget.button_pressed = p.end_chain
	give_items_widget.add_items(p.items_to_give)
	take_items_widget.add_items(p.items_to_take)
	change_vars_widget.add_conditions(p.vars_to_change)


func _on_remove_button_pressed() -> void:
	queue_free()

func _on_move_up_button_pressed() -> void:
	move_up_requested.emit(self)

func _on_move_down_button_pressed() -> void:
	move_down_requested.emit(self)
