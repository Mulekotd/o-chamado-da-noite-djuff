class_name _OptionsWidget extends VBoxContainer

const OPTION_WIDGET = preload("uid://yakp1hcldxl0")

func parse_options() -> Array[Option]:
	var options : Array[Option]
	for ow in get_children():
		if ow is _OptionWidget:
			options.append(ow.get_option())
	return options

func load_options(options: Array[Option]) -> void:
	for o in options:
		add_option().load_option(o)

func add_option() -> _OptionWidget:
	var ow := OPTION_WIDGET.instantiate()
	ow.add_to_group("option_widget")
	add_child(ow)
	return ow


func _on_add_pressed() -> void:
	add_option()

func _on_remove_pressed() -> void:
	if get_children().size() > 2:
		get_child(-1).queue_free()
