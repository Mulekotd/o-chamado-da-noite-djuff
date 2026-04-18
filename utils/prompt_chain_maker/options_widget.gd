extends VBoxContainer

const OPTION_WIDGET = preload("uid://yakp1hcldxl0")

func parse_options() -> Array[String]:
	var options : Array[String]
	for o in get_children():
		if o.is_in_group("option_widget"):
			options.append(o.text)
	return options

func _on_adicionar_pressed() -> void:
	var o := OPTION_WIDGET.instantiate()
	o.add_to_group("option_widget")
	add_child(o)

func _on_remover_pressed() -> void:
	print(parse_options())
	get_child(-1).queue_free()
