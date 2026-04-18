class_name _ConditionsWidget extends VBoxContainer

@onready var add: Button = $Add
@onready var remove: Button = $Remove
const CONDITION_WIDGET = preload("uid://ckhy52qfjwd46")

func parse_conditions() -> Dictionary[String, int]:
	var dict : Dictionary[String, int]
	for c in get_children():
		if c.is_in_group("condition_widget"):
			var title_text : TextEdit = c.get_child(0)
			var value_text : TextEdit = c.get_child(1)
			var title : String = title_text.text
			var value : int = value_text.text.to_int()
			dict[title] = value
	return dict

func add_conditions(conds: Dictionary[String, int]) -> void:
	for k in conds.keys():
		add_condition(k, conds[k])

func add_condition(title: String, value: int) -> void:
	var c := CONDITION_WIDGET.instantiate()
	c.get_child(0).text = title
	c.get_child(1).text = "%d" % value
	c.add_to_group("condition_widget")
	add_child(c)

func _on_adicionar_pressed() -> void:
	add_condition("", 1)

func _on_remover_pressed() -> void:
	if get_children().size() > 2:
		get_child(-1).queue_free()
