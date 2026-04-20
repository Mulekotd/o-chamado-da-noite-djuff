class_name _OptionWidget extends PanelContainer

@onready var text_edit: TextEdit = $MarginContainer/VBoxContainer/HBoxContainer/TextEdit
@onready var conditions_widget: _ConditionsWidget = $MarginContainer/VBoxContainer/VBoxContainer/ConditionsWidget

func get_option() -> Option:
	var o : Option = Option.new()
	o.text = text_edit.text
	o.conditions = conditions_widget.parse_conditions()
	return o

func load_option(o: Option) -> void:
	text_edit.text = o.text
	conditions_widget.add_conditions(o.conditions)
