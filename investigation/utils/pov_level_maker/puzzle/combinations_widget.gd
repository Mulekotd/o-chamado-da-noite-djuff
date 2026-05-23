class_name _CombinationsWidget extends Control

const COMBINATION_WIDGET = preload("uid://bh3mtqutvq84s")

@export var add_button : Button
@export var remove_button : Button

func parse_combinations() -> Dictionary[String, String]:
	var combinations : Dictionary[String, String] = {}
	for c in get_children():
		if c.is_in_group("combination_widget"):
			var key   : String = c.get_child(0).text
			var value : String = c.get_child(1).text
			if key and value:
				combinations.set(c.get_child(0).text, c.get_child(1).text)
	return combinations

func add_combination(combination: String, var_to_change: String) -> void:
	var c := COMBINATION_WIDGET.instantiate()
	c.get_child(0).text = combination
	c.get_child(1).text = var_to_change
	c.add_to_group("combination_widget")
	add_child(c)

func add_combinations(combinations: Dictionary[String, String]):
	for c in combinations.keys():
		add_combination(c, combinations[c])

func _on_add_button_pressed() -> void:
	add_combination("","")

func _on_remove_button_pressed() -> void:
	var nodes := get_tree().get_nodes_in_group("combination_widget")
	if nodes:
		nodes[-1].queue_free()
