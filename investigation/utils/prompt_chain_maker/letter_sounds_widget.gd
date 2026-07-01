class_name _LetterSoundsWidget extends Control

const LETTER_SOUND_BUTTON = preload("uid://c43m4kjrwkjy6")

@export var button_grid : GridContainer
@export var sound_manager : _SoundManager
@export var demo_sound_interval : float = 0.066
@export var demo_sound_amount : int = 16

var button_group : ButtonGroup
var selected_letter_sound : String = ""
var letter_sounds : Dictionary[String, Array]
## increment every time a new demo is played, and only play that demo if the number is still the same
var playing_sound : int = 0

func _ready() -> void:
	load_global_letter_sounds()
	button_group = ButtonGroup.new()
	button_group.allow_unpress = true

func load_global_letter_sounds() -> void:
	load_letter_sounds(LetterSoundsGlobal.sounds)

func select_letter_sound(ls: String) -> void:
	await get_tree().process_frame
	for b : Button in button_grid.get_children():
		if b.text == ls:
			selected_letter_sound = ls
			b.button_pressed = true
			break

func load_letter_sounds(lss: Dictionary[String, Array]) -> void:
	letter_sounds = lss.duplicate(true)
	for b : Button in button_grid.get_children():
		b.queue_free()
	for ls in lss.keys():
		var button : Button = LETTER_SOUND_BUTTON.instantiate()
		button.text = ls
		button.button_group = button_group
		if not button.toggled.is_connected(button_toggled.bind(ls)):
			button.toggled.connect(button_toggled.bind(ls))
		button_grid.add_child(button)

func button_toggled(toggle_on: bool, text: String) -> void:
	if toggle_on:
		selected_letter_sound = text
		print("\n-\nbutton pressed, selected_letter_sound : ", selected_letter_sound, "\n-\n")
		play_demo(text)
	else:
		await get_tree().process_frame
		if selected_letter_sound == text:
			print("\n-deselected your sound, you stupid-\n")
			selected_letter_sound = ""

func play_demo(ls: String) -> void:
	sound_manager.load_letter_sounds(letter_sounds[ls])
	playing_sound += 1
	var sound_number := playing_sound
	for i in demo_sound_amount:
		if playing_sound == sound_number and not is_queued_for_deletion():
			sound_manager.play_letter_sound()
			await get_tree().create_timer(demo_sound_interval).timeout
		else:
			break

func parse_letter_sound() -> String:
	print("\n-\nparse_letter_sound, selected_letter_sound : ", selected_letter_sound, "\n-\n")
	return selected_letter_sound
