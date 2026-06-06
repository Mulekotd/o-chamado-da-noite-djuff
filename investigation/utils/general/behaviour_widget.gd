class_name _ScriptWidget extends MarginContainer

@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var behaviour_button: Button = $HBoxContainer/BehaviourButton

@export var default_text : String = "[selecionar comportamento]"
var behaviour : Script

func _ready() -> void:
	behaviour_button.text = default_text

func load_behaviour(b: Script) -> void:
	if !b: return
	behaviour = b
	behaviour_button.text = b.new().behaviour_name
	# print("NOME: ", b.new().behaviour_name)

func get_behaviour() -> Script:
	return behaviour

func _on_script_button_pressed() -> void:
	load_file_dialog.popup()

func _on_load_file_dialog_file_selected(path: String) -> void:
	var b := load(path)
	if b is Script:
		load_behaviour(b)

func _on_reset_button_pressed() -> void:
	behaviour = null
	behaviour_button.text = default_text
