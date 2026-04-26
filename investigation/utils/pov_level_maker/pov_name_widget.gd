class_name _PovNameWidget extends HBoxContainer

@onready var pov_name_line_edit: LineEdit = $PovNameLineEdit
@onready var pov_name_menu_button: MenuButton = $PovNameMenuButton
@export var pov_names : Array[String]
@export var pov_name : String

signal changed

func _ready() -> void:
	pov_name_menu_button.get_popup().id_pressed.connect(update_pov_name)
	pov_name_line_edit.text_changed.connect(func(x): changed.emit())

func update_pov_name(index: int):
	load_pov_name(pov_names[index])

func get_pov_name() -> String:
	return pov_name_line_edit.text

func load_pov_name(p_name: String) -> void:
	pov_name_line_edit.clear()
	pov_name_line_edit.text = p_name

func load_pov_names() -> void:
	var plm : _PovLevelMaker = get_tree().get_first_node_in_group("pov_level_maker")
	if plm:
		pov_names = (plm.get_all_pov_names())
	pov_name_menu_button.get_popup().clear()
	for pn in pov_names:
		if pn != pov_name:
			pov_name_menu_button.get_popup().add_item(pn)

func _on_pov_name_menu_button_about_to_popup() -> void:
	load_pov_names()
