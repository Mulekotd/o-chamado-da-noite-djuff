class_name _OptionWidget extends PanelContainer

@onready var text_edit: TextEdit = $MarginContainer/VBoxContainer/HBoxContainer/TextEdit
@onready var conditions_widget: _ConditionsWidget = $MarginContainer/VBoxContainer/VBoxContainer/ConditionsWidget
@onready var necessary_items_widget: _ItemsWidget = $MarginContainer/VBoxContainer/NecessaryItemsContainer/NecessaryItemsWidget
@onready var actions_spin_box: SpinBox = $MarginContainer/VBoxContainer/ActionsContainer/ActionsSpinBox

func get_option() -> Option:
	var o : Option = Option.new()
	o.text = text_edit.text
	o.conditions = conditions_widget.parse_conditions()
	o.necessary_items = necessary_items_widget.items
	o.actions = actions_spin_box.value
	return o

func load_option(o: Option) -> void:
	text_edit.text = o.text
	conditions_widget.add_conditions(o.conditions)
	necessary_items_widget.add_items(o.necessary_items)
	actions_spin_box.value = o.actions
