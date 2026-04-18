extends VBoxContainer

@onready var adicionar: Button = $Adicionar
@onready var remover: Button = $Remover
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

func _on_adicionar_pressed() -> void:
	var c := CONDITION_WIDGET.instantiate()
	c.add_to_group("condition_widget")
	add_child(c)

func _on_remover_pressed() -> void:
	get_child(-1).queue_free()
