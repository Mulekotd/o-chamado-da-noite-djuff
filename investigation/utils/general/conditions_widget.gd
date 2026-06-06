class_name _ConditionsWidget extends VBoxContainer

@onready var add_button: Button = $HBoxContainer/AddButton
@onready var remove_button: Button = $HBoxContainer/RemoveButton

const CONDITION_WIDGET = preload("uid://ckhy52qfjwd46")

func parse_conditions() -> Dictionary[String, int]:
	var dict : Dictionary[String, int]
	for c in get_children():
		if c.is_in_group("condition_widget"):
			var title : String = c.get_child(0).text
			var value : int = c.get_child(1).value
			dict[title] = value
	return dict

func add_conditions(conds: Dictionary[String, int]) -> void:
	for k : String in conds.keys():
		add_condition(k, conds[k])

func load_conditions(conds: Dictionary[String, int]) -> void:
	clear()
	add_conditions(conds)

func clear() -> void:
	var children = get_children()
	for c in children:
		if c.is_in_group("condition_widget"):
			c.queue_free()

func add_condition(title: String, value: int) -> void:
	var c := CONDITION_WIDGET.instantiate()
	c.get_child(0).text = title
	c.get_child(1).value = value
	c.add_to_group("condition_widget")
	add_child(c)

func _on_adicionar_pressed() -> void:
	add_condition("", 1)

func _on_remover_pressed() -> void:
	if get_children().size() > 1:
		get_child(-1).queue_free()
