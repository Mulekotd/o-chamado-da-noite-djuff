class_name _SoundWidget extends MarginContainer

@onready var sound_button: Button = $HBoxContainer/SoundButton
@onready var load_file_dialog: FileDialog = $LoadFileDialog

@export var default_text : String = "[selecionar som]"
var sound : AudioStream

func _ready() -> void:
	sound_button.text = default_text

func load_sound(s: AudioStream) -> void:
	if !s: return
	sound = s
	sound_button.text = s.resource_path.get_file()
	print("NOME: ", s.resource_name)

func get_sound() -> AudioStream:
	return sound

func _on_sound_button_pressed() -> void:
	load_file_dialog.popup()

func _on_load_file_dialog_file_selected(path: String) -> void:
	var s := load(path)
	if s is AudioStream:
		load_sound(s)

func _on_reset_button_pressed() -> void:
	sound = null
	sound_button.text = default_text
