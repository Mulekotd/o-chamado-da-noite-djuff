class_name _OptionWidget extends PanelContainer

@export var text_edit: TextEdit
@export var conditions_widget: _ConditionsWidget
@export var necessary_items_widget: _ItemsWidget
@export var actions_spin_box: SpinBox
@export var index_label: Label

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

func set_index(index: int):
	if index >= 0:
		index_label.text = str(index)
