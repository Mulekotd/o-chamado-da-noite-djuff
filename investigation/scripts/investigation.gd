extends Control

@onready var text_box: TextBox = $TextBox
@onready var pov_manager: PovManager = $PovManager
@onready var sound_manager: _SoundManager = $SoundManager
@onready var person_display: PersonDisplay = $PersonDisplay
@onready var eye_sprite_2d: AnimatedSprite2D = $EyeSprite2D
@onready var actions_manager: ActionsManager = $ActionsManager
@onready var clock: _Clock = $Clock
@onready var moving_noise_overlay: _MovingNoiseWidget = $MovingNoiseOverlay

const USED_ACTION_SOUND = preload("uid://bfamn2x4funyi")
const NO_MORE_ACTIONS_SOUND = preload("uid://c5hv7vps3lut6")

signal done_showing_clock

## Tracks prompt chains so letter sounds can follow the active chain order.
var chain_id_queue : Array[int]
var prompt_chain_queue : Array[PromptChain]
# eye variables
var vision_x : float = 0.5
var look_speed : float = 0.1
# clock variables
var clock_total_speed : float = 1000
var clock_display_duration : float = 1
var clock_fade_duration : float = 1

func _ready() -> void:
	# Wire the main investigation flow between POVs, text box, and audio.
	pov_manager.element_clicked.connect(_append_prompt_chain_from_element)
	pov_manager.prompt_chain_called.connect(text_box.insert_prompt_chain)
	pov_manager.pov_entered.connect(text_box.clear_box)
	text_box.pov_entered.connect(pov_manager.change_pov_by_name)
	text_box.stand_by_changed.connect(_update_pov_manager_enabled)
	text_box.stand_by_changed.connect(_clear_person_display)
	text_box.prompt_sound_requested.connect(sound_manager.play_poly_sound)
	text_box.letter_sound_requested.connect(sound_manager.play_letter_sound)
	text_box.displayed_prompt.connect(_update_sound_manager_letter_sounds)
	text_box.displayed_prompt.connect(_update_person_display)
	text_box.chain_added.connect(_append_prompt_chain_sound)
	text_box.actions_used.connect(_use_actions)
	text_box.prompt_advanced.connect(pov_manager.update_view)
	
	clock.modulate = Color(0,0,0,0)

var elapsed : int = 0
var advances : int = 0
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

func _use_actions(actions: int) -> void:
	text_box.enabled = false
	InvestigationVars.add_actions(-actions)
	actions_manager.actions = InvestigationVars.get_actions()
	sound_manager.play_poly_sound(USED_ACTION_SOUND)
	_show_clock()
	await done_showing_clock
	text_box.enabled = true

func _update_sound_manager_letter_sounds(chain_id: int, prompt: Prompt) -> void:
	# print("UPDATE SOUND MANAGER LETTER SOUNDS: ", chain_id)
	# Keep the chain queue aligned with the prompt being displayed.
	while chain_id_queue[0] != chain_id:
		chain_id_queue.pop_front()
		if prompt_chain_queue:
			prompt_chain_queue.pop_front()
	if !chain_id_queue: 
		return
	if prompt.letter_sound:
		sound_manager.load_letter_sounds(LetterSoundsGlobal.sounds[prompt.letter_sound])
	else:
		sound_manager.load_letter_sounds(LetterSoundsGlobal.default_sound)
	
func _update_pov_manager_enabled(stand_by: bool) -> void:
	pov_manager.enabled = stand_by

func _show_clock() -> void:
	_update_clock()
	clock.modulate = Color(1,1,1,1)
	clock.visible = true
	moving_noise_overlay.modulate = Color(1,1,1,1)
	moving_noise_overlay.visible = true
	if (InvestigationVars.get_actions()):
		await get_tree().create_timer(clock_display_duration).timeout
		var tween : Tween 
		# turn clock invisible by fade out
		tween = get_tree().create_tween()
		tween.tween_property(clock, "modulate", Color(0,0,0,0), clock_fade_duration)
		# turn moving noise invisible by fade out
		tween = get_tree().create_tween()
		tween.tween_property(moving_noise_overlay,  "modulate", Color(0,0,0,0), clock_fade_duration)
		# done
		await tween.finished
	else:
		await get_tree().create_timer(clock_display_duration).timeout
		sound_manager.play_poly_sound(NO_MORE_ACTIONS_SOUND)
		var tween : Tween 
		# slow down clock
		tween = get_tree().create_tween()
		tween.tween_property(clock, "speed", 0, 1.4).set_ease(Tween.EASE_IN)
		await tween.finished
		# blow clock
		clock.blow_static_clock(0.75,3)
		await get_tree().create_timer(clock_display_duration).timeout
		# turn clock invisible by fade out
		tween = get_tree().create_tween()
		tween.tween_property(clock, "modulate", Color(0,0,1,0), clock_fade_duration)
		# turn moving noise invisible by fade out
		tween = get_tree().create_tween()
		tween.tween_property(moving_noise_overlay,  "modulate", Color(0,0,0,0), clock_fade_duration)
		# done
		await tween.finished
		
	clock.visible = false
	moving_noise_overlay.visible = false
	done_showing_clock.emit()

func _update_clock() -> void:
	var factor : float = float(InvestigationVars.get_actions()) / InvestigationVars.get_max_actions()
	print("FACTOR: ", factor)
	clock.speed = lerpf(clock_total_speed, 0.0, factor)

func _append_prompt_chain_from_element(e: Element) -> void:
	# Clicking an element can enqueue its prompt chain.
	if e.prompt_chain:
		text_box.insert_prompt_chain(e.prompt_chain)

func _append_prompt_chain_sound(chain_id: int, chain: PromptChain) -> void:
	# Cache chain meta so letter sounds can be swapped later.
	chain_id_queue.append(chain_id)
	prompt_chain_queue.append(chain)
