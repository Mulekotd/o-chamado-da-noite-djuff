class_name _OptionsWidget extends VBoxContainer

const OPTION_WIDGET = preload("uid://yakp1hcldxl0")

func parse_options() -> Array[String]:
	var options : Array[String]
	for o in get_children():
		if o.is_in_group("option_widget"):
			print(o)
			options.append(o.text)
	return options

func add_options(options: Array[String]) -> void:
	for o in options:
		add_option(o)

func add_option(name: String) -> void:
	var o := OPTION_WIDGET.instantiate()
	o.text = name
	o.add_to_group("option_widget")
	add_child(o)

func _on_add_pressed() -> void:
	add_option("")

func _on_remove_pressed() -> void:
	if get_children().size() > 2:
		get_child(-1).queue_free()
