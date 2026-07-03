class_name _Investigation extends Control

@onready var text_box: TextBox = $TextBox
@onready var pov_manager: PovManager = $PovManager
@onready var sound_manager: _SoundManager = $SoundManager
@onready var person_display: PersonDisplay = $PersonDisplay
@onready var eye_sprite_2d: AnimatedSprite2D = $EyeSprite2D
@onready var actions_manager: ActionsManager = $ActionsManager
@onready var clock: _Clock = $Clock
@onready var moving_noise_overlay: _MovingNoiseWidget = $MovingNoiseOverlay
@onready var inventory: _Inventory = $Inventory

@export var pov_tired_overlay: Panel
@export var eye_tired_overlay: Panel

const USED_ACTION_SOUND = preload("uid://cfbtnvstp7wxl")
const NO_MORE_ACTIONS_SOUND = preload("uid://c5bngv3avhepx")

signal done_showing_clock

## if true, flashes the pov view and eye display black IF actions <= 0 AND max_actions > 0 
@export var tired_feedback: bool = true
## how fast the tired feedback flashing is
@export var tired_feedback_speed: float = 1
## what the character should say when tired
@export var tired_text : String = "Estou muito cansado, preciso ir."
## povs where the player can interact even when tired
@export var tired_whitelist : Array[String] = []

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
	pov_manager.prompt_chain_called.connect(_append_prompt_chain)
	pov_manager.pov_entered.connect(text_box.clear_box)
	pov_manager.sound_played.connect(sound_manager.play_poly_sound)
	text_box.pov_entered.connect(pov_manager.change_pov_by_name)
	text_box.stand_by_changed.connect(_update_pov_manager_enabled)
	text_box.stand_by_changed.connect(_clear_person_display)
	text_box.prompt_sound_requested.connect(sound_manager.play_poly_sound)
	text_box.letter_sound_requested.connect(sound_manager.play_letter_sound)
	text_box.displayed_prompt.connect(_update_sound_manager_letter_sounds)
	text_box.displayed_prompt.connect(_update_person_display)
	text_box.chain_added.connect(_append_prompt_chain_sound)
	text_box.actions_used.connect(_use_actions)
	text_box.prompt_advanced.connect(_on_prompt_advanced)
	text_box.items_added.connect(inventory.add_items)
	text_box.items_removed.connect(inventory.remove_items)
	text_box.investigation_points_added.connect(_add_investigation_points)
	
	clock.modulate = Color(0,0,0,0)

var ticks : int = 0
var elapsed: float = 0
var advances : int = 0
func _physics_process(delta: float) -> void:
	elapsed += delta
	ticks += 1
	# move eye in relation to mouse in pov_manager
	vision_x = lerpf(vision_x, pov_manager.get_local_mouse_position().x / pov_manager.size.x, look_speed)
	if ticks % 16 == 0: # only move in certain intervals
		eye_sprite_2d.frame = int((vision_x) * 13) * 2 + (advances / 2 % 2)
		advances += 1
	
	# sin for black (tired) overlay if tired_feedback == true
	if tired_feedback and actions_manager.max_actions > 0 and actions_manager.actions <= 0:
		var color := Color(0,0,0, sin(elapsed * tired_feedback_speed)*0.5+0.5)
		eye_tired_overlay.modulate = color
		pov_tired_overlay.modulate = color
	else:
		eye_tired_overlay.modulate = Color(0,0,0,0)
		pov_tired_overlay.modulate = Color(0,0,0,0)
	
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
	# Keep the chain queue aligned with the prompt being displayed.
	while chain_id_queue and chain_id_queue[0] != chain_id:
		chain_id_queue.pop_front()
		if not prompt_chain_queue.is_empty():
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
	clock.speed = lerpf(clock_total_speed, 0.0, factor)

func _append_prompt_chain_from_element(e: Element) -> void:
	# Clicking an element can enqueue its prompt chain.
	if e.prompt_chain:
		_append_prompt_chain(e.prompt_chain)

func _append_prompt_chain(p_chain: PromptChain) -> void:
	var tired : bool = actions_manager.max_actions > 0 and actions_manager.actions <= 0
	if tired and pov_manager.current_pov.name not in tired_whitelist:
		var prompt := Prompt.new()
		prompt.text = tired_text
		text_box.insert_prompt(prompt)
	else:
		text_box.insert_prompt_chain(p_chain)

func _append_prompt_chain_sound(chain_id: int, chain: PromptChain) -> void:
	# Cache chain meta so letter sounds can be swapped later.
	chain_id_queue.append(chain_id)
	prompt_chain_queue.append(chain)

func _on_prompt_advanced() -> void:
	if pov_manager._on_puzzle_pov:
		pov_manager.change_pov(pov_manager.current_pov)
	else:
		pov_manager.update_view()

func _add_investigation_points(points: int) -> void:
	InvestigationVars.add_investigation_points(points)
	#print("%d investigation poins added." % [points])
