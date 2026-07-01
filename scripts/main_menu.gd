extends Control

@export var sound_manager: _SoundManager

@export var background: PanelContainer
@export var assassin: TextureRect
@export var detective: TextureRect

@export var black_rect: ColorRect

@export var main_elements: VBoxContainer
@export var new_game_confirmation: VBoxContainer
@export var options_and_credits: HBoxContainer
@export var exit_confirmation: VBoxContainer

@export var continue_button: Button
@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var dialog_slider: HSlider

@export var elements_parallax_amount : float = 0.1
@export var background_parallax_amount : float = 0.1
@export var parallax_speed : float = 5
@export var fade_out_duration : float = 3

var master_bus_index : int = AudioServer.get_bus_index("Master")
var music_bus_index : int = AudioServer.get_bus_index("Music")
var sfx_bus_index : int = AudioServer.get_bus_index("Sfx")
var dialog_bus_index : int = AudioServer.get_bus_index("Letter Sounds")

var mouse_pos : Vector2 = Vector2()
var mouse_hovering : bool = false

enum tabs {
	MAIN,
	NEW_GAME_CONFIRMATION,
	OPTIONS,
	EXIT_CONFIRMATION,
}
var tab : tabs = tabs.MAIN

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	continue_button.disabled = not InvestigationVars.get_last_level()
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	dialog_slider.value = db_to_linear(AudioServer.get_bus_volume_db(dialog_bus_index))
	
	sound_manager.play_soundtrack(preload("uid://bw7v0wigbew66"))
	sound_manager.load_letter_sounds(LetterSoundsGlobal.default_sound)
	
	black_rect.color = Color(0,0,0,0)
	black_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var center := background.size / 2
	
	# main elements
	var target_pos : Vector2 = (
		(center - main_elements.size/2)
		+ (center - mouse_pos) * elements_parallax_amount * int(mouse_hovering)
	)
	if tab in [tabs.OPTIONS]: 
		target_pos.x += background.size.x
	if tab in [tabs.NEW_GAME_CONFIRMATION, tabs.EXIT_CONFIRMATION]: # show detective
		target_pos.x -= background.size.x
	main_elements.position = lerp(main_elements.position, target_pos, parallax_speed * delta)
	
	# new game confirmation
	target_pos = (
		(center - new_game_confirmation.size/2)
		+ (center - mouse_pos) * elements_parallax_amount * int(mouse_hovering)
	)
	if tab != tabs.NEW_GAME_CONFIRMATION:
		target_pos.x += background.size.x
	new_game_confirmation.position = lerp(new_game_confirmation.position, target_pos, parallax_speed * delta)
	
	# exit confirmation
	target_pos = (
		(center - exit_confirmation.size/2)
		+ (center - mouse_pos) * elements_parallax_amount * int(mouse_hovering)
	)
	if tab != tabs.EXIT_CONFIRMATION:
		target_pos.x += background.size.x
	exit_confirmation.position = lerp(exit_confirmation.position, target_pos, parallax_speed * delta)
	
	
	# options and credits
	target_pos = (
		(center - options_and_credits.size/2)
		+ (center - mouse_pos) * elements_parallax_amount * int(mouse_hovering)
	)
	if tab != tabs.OPTIONS:
		target_pos.x -= background.size.x
	options_and_credits.position = lerp(options_and_credits.position, target_pos, parallax_speed * delta)
	
	# detective and assassin
	target_pos = (
		(center - mouse_pos) * background_parallax_amount * int(mouse_hovering)
	)
	if tab in [tabs.OPTIONS]: # show detective
		target_pos.x += center.x
	if tab in [tabs.NEW_GAME_CONFIRMATION, tabs.EXIT_CONFIRMATION]: # show detective
		target_pos.x -= center.x # show assassin
	detective.position = lerp(detective.position, target_pos, parallax_speed * delta)
	assassin.position = lerp(assassin.position, target_pos, parallax_speed * delta)

func start_game(level: String) -> void:
	var scene : PackedScene = preload("uid://dd40v3jpeddb8")
	match level:
		"prologue": 
			scene = preload("uid://dd40v3jpeddb8")
		"day1":
			scene = preload("uid://jk2netpdpxow")
	get_tree().change_scene_to_packed(scene)

func _fade_out(duration: float) -> void:
	black_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	sound_manager.stop_soundtrack()
	await get_tree().create_tween().tween_property(black_rect, "color", Color.BLACK, duration).finished

func _on_continue_pressed() -> void:
	sound_manager.play_poly_sound(preload("uid://dy7tdyu6mckrd"))
	await _fade_out(fade_out_duration)
	start_game(InvestigationVars.get_last_level())

func _on_confirm_button_pressed() -> void:
	# apagar todos os saver e comecar um jogo novo
	sound_manager.play_poly_sound(preload("uid://dy7tdyu6mckrd"))
	await _fade_out(fade_out_duration)
	InvestigationVars.clear_everything()
	start_game("prologue")

func _on_new_game_pressed() -> void:
	tab = tabs.NEW_GAME_CONFIRMATION

func _on_options_pressed() -> void:
	tab = tabs.OPTIONS

func _on_exit_pressed() -> void:
	tab = tabs.EXIT_CONFIRMATION

func _on_panel_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_pos = event.position
	
func _on_panel_container_mouse_entered() -> void:
	mouse_hovering = true

func _on_panel_container_mouse_exited() -> void:
	mouse_hovering = false

func _on_return_button_pressed() -> void:
	tab = tabs.MAIN

func _on_exit_button_pressed() -> void:
	sound_manager.play_poly_sound(preload("uid://drvhdaei27mlf"))
	await _fade_out(fade_out_duration)
	get_tree().quit()

func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(music_bus_index, value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(sfx_bus_index, value)
	
func _on_dialog_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(dialog_bus_index, value)

func _on_sfx_slider_drag_ended(value_changed: bool) -> void:
	sound_manager.play_poly_sound(preload("uid://dhrfmjyberbde"))

func _on_dialog_slider_drag_ended(value_changed: bool) -> void:
	for i in 4:
		sound_manager.play_letter_sound()
		await get_tree().create_timer(0.2).timeout

func _on_master_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(master_bus_index, value)
