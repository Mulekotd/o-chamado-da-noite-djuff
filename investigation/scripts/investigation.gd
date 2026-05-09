extends Control

@onready var text_box: TextBox = $TextBox
@onready var pov_manager: PovManager = $PovManager
@onready var sound_manager: _SoundManager = $SoundManager
@onready var person_display: PersonDisplay = $PersonDisplay
@onready var eye_sprite_2d: AnimatedSprite2D = $EyeSprite2D

## Tracks prompt chains so letter sounds can follow the active chain order.
var chain_id_queue : Array[int]
var prompt_chain_queue : Array[PromptChain]

func _ready() -> void:
	# Wire the main investigation flow between POVs, text box, and audio.
	pov_manager.element_clicked.connect(_append_prompt_chain_from_element)
	pov_manager.prompt_chain_called.connect(text_box.insert_prompt_chain)
	text_box.pov_entered.connect(pov_manager.change_pov_by_name)
	text_box.stand_by_changed.connect(_update_pov_manager_enabled)
	text_box.stand_by_changed.connect(_clear_person_display)
	text_box.prompt_sound_requested.connect(sound_manager.play_poly_sound)
	text_box.letter_sound_requested.connect(sound_manager.play_letter_sound)
	text_box.displayed_prompt.connect(_update_sound_manager_letter_sounds)
	text_box.displayed_prompt.connect(_update_person_display)
	text_box.chain_added.connect(_append_prompt_chain_sound)

var elapsed : int = 0
var advances : int = 0
var vision_x : float = 0.5
var look_speed : float = 0.1
func _physics_process(delta: float) -> void:
	# move eye in relation to mouse in pov_manager
	vision_x = lerpf(vision_x, pov_manager.get_local_mouse_position().x / pov_manager.size.x, look_speed)
	if elapsed % 16 == 0: # only move in certain intervals
		eye_sprite_2d.frame = int((vision_x) * 13) * 2 + (advances / 2 % 2)
		advances += 1
	elapsed += 1

func _update_person_display(chain_id: int, prompt: Prompt) -> void:
	person_display.load_img_from_prompt(prompt)

func _clear_person_display(stand_by: bool) -> void:
	if stand_by:
		person_display.clear_img()

func _update_sound_manager_letter_sounds(chain_id: int, prompt: Prompt) -> void:
	# print("UPDATE SOUND MANAGER LETTER SOUNDS: ", chain_id)
	# Keep the chain queue aligned with the prompt being displayed.
	while chain_id_queue[0] != chain_id:
		chain_id_queue.pop_front()
		prompt_chain_queue.pop_front()
	if !chain_id_queue: 
		return
	sound_manager.load_letter_sounds(prompt_chain_queue[0].letter_sounds)
	
func _update_pov_manager_enabled(stand_by: bool) -> void:
	pov_manager.enabled = stand_by

func _append_prompt_chain_from_element(e: Element) -> void:
	# Clicking an element can enqueue its prompt chain.
	if e.prompt_chain:
		text_box.insert_prompt_chain(e.prompt_chain)

func _append_prompt_chain_sound(chain_id: int, chain: PromptChain) -> void:
	# Cache chain meta so letter sounds can be swapped later.
	chain_id_queue.append(chain_id)
	prompt_chain_queue.append(chain)
