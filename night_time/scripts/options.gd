class_name _Options extends VBoxContainer

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var dialogue_slider: HSlider

var master_bus_index : int = AudioServer.get_bus_index("Master")
var music_bus_index : int = AudioServer.get_bus_index("Music")
var sfx_bus_index : int = AudioServer.get_bus_index("Sfx")
var dialogue_bus_index : int = AudioServer.get_bus_index("Letter Sounds")

signal sfx_requested(sfx: AudioStream)
signal dialogue_requested()
signal return_requested()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioServer.set_bus_volume_linear(master_bus_index, InvestigationVars.load_bus_volume("master"))
	AudioServer.set_bus_volume_linear(music_bus_index, InvestigationVars.load_bus_volume("music"))
	AudioServer.set_bus_volume_linear(sfx_bus_index, InvestigationVars.load_bus_volume("sfx"))
	AudioServer.set_bus_volume_linear(dialogue_bus_index, InvestigationVars.load_bus_volume("dialogue"))
	
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	dialogue_slider.value = db_to_linear(AudioServer.get_bus_volume_db(dialogue_bus_index))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(master_bus_index, value)

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(music_bus_index, value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(sfx_bus_index, value)
	
func _on_dialogue_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(dialogue_bus_index, value)

func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	sfx_requested.emit(preload("uid://dhrfmjyberbde"))
	InvestigationVars.save_bus_volume("sfx", sfx_slider.value)

func _on_dialogue_slider_drag_ended(value_changed: bool) -> void:
	for i in 4:
		dialogue_requested.emit()
		await get_tree().create_timer(0.2).timeout
	InvestigationVars.save_bus_volume("dialogue", dialogue_slider.value)

func _on_master_slider_drag_ended(value_changed: bool) -> void:
	InvestigationVars.save_bus_volume("master", master_slider.value)

func _on_music_slider_drag_ended(value_changed: bool) -> void:
	InvestigationVars.save_bus_volume("music", music_slider.value)

func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on else DisplayServer.WINDOW_MODE_WINDOWED) 
