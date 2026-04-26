extends Control

@onready var text_box: TextBox = $TextBox
@onready var pov_manager: PovManager = $PovManager
@onready var sound_manager: _SoundManager = $SoundManager

var chain_id_queue : Array[int]
var prompt_chain_queue : Array[PromptChain]

func _ready() -> void:
	pov_manager.element_clicked.connect(_append_prompt_chain_from_element)
	pov_manager.prompt_chain_called.connect(text_box.append_prompt_chain)
	text_box.pov_entered.connect(pov_manager.change_pov_by_name)
	text_box.stand_by_changed.connect(_update_pov_manager_enabled)
	text_box.prompt_sound_requested.connect(sound_manager.play_poly_sound)
	text_box.letter_sound_requested.connect(sound_manager.play_letter_sound)
	text_box.displayed_prompt.connect(_update_sound_manager_letter_sounds)
	text_box.chain_added.connect(_append_prompt_chain_sound)

func _update_sound_manager_letter_sounds(chain_id: int) -> void:
	print("UPDATE SOUND MANAGER LETTER SOUNDS")
	while chain_id_queue[0] != chain_id:
		chain_id_queue.pop_front()
		prompt_chain_queue.pop_front()
	if !chain_id_queue: 
		return
	sound_manager.load_letter_sounds(prompt_chain_queue[0].letter_sounds)
	
func _update_pov_manager_enabled(stand_by: bool) -> void:
	pov_manager.enabled = stand_by

func _append_prompt_chain_from_element(e: Element) -> void:
	if e.prompt_chain:
		text_box.append_prompt_chain(e.prompt_chain)

func _append_prompt_chain_sound(chain_id: int, chain: PromptChain) -> void:
	chain_id_queue.append(chain_id)
	prompt_chain_queue.append(chain)
