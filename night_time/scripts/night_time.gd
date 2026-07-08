extends Node2D

const GUNSHOT_SOUND = preload("uid://durttw3b7q0qs")
const HIT_SOUNDS = [preload("uid://diu1mxl51qk6e"), preload("uid://dyfy6atai2r1h"), preload("uid://bft6rtbeuf31h")]
const KNIFE_SOUND = preload("uid://dw45x11hrhcuh")
const RELOAD_SOUND = preload("uid://cuvetfkjnlgpn")


@export_file("*.tscn") var next_scene_path: String = "res://scenes/main_menu.tscn"

@onready var timer: Timer = $Timer
@onready var fade_screen: ColorRect = $CanvasLayer/FadeScreen
@onready var directional_light_2d: PointLight2D = $Player/DirectionalLight2D
@onready var sound_manager: _SoundManager = $SoundManager
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

@export var disco_light_speed : float = 0.1

var is_fading: bool = false

@onready var default_light_strength : float = 1

func _ready() -> void:
	# Set up the fade screen to be transparent at start
	fade_screen.color = Color(0, 0, 0, 0)
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Configure and start the 5-second timer dynamically if not set in editor
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
	# tocar musica
	sound_manager.play_soundtrack(preload("res://investigation/sounds/soundtracks/musica_noite.wav"))

	# usar som de tiro no tocador de dialogo pra timbres aleatorios pois preguica
	sound_manager.load_letter_sounds([GUNSHOT_SOUND])
	
	# npcs emitem som de atingido
	for npc in get_tree().get_nodes_in_group("npc"):
		if npc is _Npc:
			npc.hit.connect(_emit_hit_sound)

var elapsed_time : float = 0
func _physics_process(delta: float) -> void:
	elapsed_time += delta
	
	var hue := sin(elapsed_time * disco_light_speed)*0.5+0.5
	directional_light_2d.color = Color.from_hsv(hue, 1, 1)

func _on_timer_timeout() -> void:
	# If we are already transitioning, don't check anymore
	if is_fading:
		return
		
	var alive_count: int = 0
	
	for npc in get_tree().get_nodes_in_group("npc"):
		if not ("is_dead" in npc and npc.is_dead):
			alive_count += 1
		
			
	if alive_count == 0:
		_start_fade_to_black()

func _emit_hit_sound() -> void:
	if not HIT_SOUNDS:
		return
	var sound = HIT_SOUNDS[randi_range(0,len(HIT_SOUNDS)-1)]
	sound_manager.play_poly_sound(sound)

func _start_fade_to_black() -> void:
	is_fading = true
	timer.stop() # Stop checking once the trigger happens
	
	# Blocks clicks during the transition
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# Create a smooth fade transition using a Tween
	var tween: Tween = create_tween()
	tween.tween_property(fade_screen, "color", Color(0, 0, 0, 1), 1.5) # Fades over 1.5 seconds
	tween.finished.connect(_on_fade_finished)

func _on_fade_finished() -> void:
	# Change to the new scene once completely black
	var error = get_tree().change_scene_to_file(next_scene_path)
	if error != OK:
		push_error("Failed to load scene: %s" % next_scene_path)

func _on_gunshot() -> void:
	sound_manager.play_letter_sound()
	# white effect
	directional_light_2d.energy = 100
	get_tree().create_tween().tween_property(directional_light_2d, "energy", default_light_strength, 0.1)


func _on_player_knife() -> void:
	sound_manager.play_poly_sound(KNIFE_SOUND)
