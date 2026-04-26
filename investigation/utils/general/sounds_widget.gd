class_name _SoundsWidget extends VBoxContainer

@onready var item_list: ItemList = $ItemList
@onready var file_dialog: FileDialog = $FileDialog

var sounds : Array[AudioStream]

func get_sounds() -> Array[AudioStream]:
	return sounds

func add_sounds(new_sounds: Array[AudioStream]) -> void:
	for s in new_sounds:
		add_sound(s)

func add_sound(sound: AudioStream) -> void:
	sounds.append(sound)
	item_list.add_item(sound.resource_path.get_file())

func _remove_sound_by_name(sound_name: String) -> void:
	for i in sounds.size():
		if sounds[i].resource_path.get_file() == sound_name:
			sounds.pop_at(i)
			return

func _on_adicionar_pressed() -> void:
	file_dialog.popup()

func _on_remover_pressed() -> void:
	for i in item_list.get_selected_items():
		_remove_sound_by_name(item_list.get_item_text(i))
	for i in item_list.get_selected_items():
		item_list.remove_item(i)

func _on_file_dialog_file_selected(path: String) -> void:
	var sound := load(path)
	if sound is AudioStream:
		add_sound(sound)
