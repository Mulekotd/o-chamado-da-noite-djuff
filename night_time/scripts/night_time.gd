extends Node2D

const GUNSHOT_SOUND = preload("uid://durttw3b7q0qs")
const HIT_SOUNDS = [preload("uid://diu1mxl51qk6e"), preload("uid://dyfy6atai2r1h"), preload("uid://bft6rtbeuf31h")]
const KNIFE_SOUND = preload("uid://dw45x11hrhcuh")
const RELOAD_SOUND = preload("uid://cuvetfkjnlgpn")
const EMPTY_GUN_SOUND = preload("uid://pt8p2arse2p4")

@export_file("*.tscn") var next_scene_path: String = "res://scenes/credits.tscn"

@onready var timer: Timer = $Timer
@onready var fade_screen: ColorRect = $CanvasLayer/FadeScreen
@onready var directional_light_2d: PointLight2D = $Player/DirectionalLight2D
@onready var sound_manager: _SoundManager = $SoundManager
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var bloods: Node = $Bloods
@onready var camera: Camera2D = $Player/Camera
@onready var ammo_label: Label = $Player/Camera/ItemHud/HBoxContainer/Item0/AmmoLabel
@onready var player: _Player = $Player

@export var disco_light_speed : float = 0.1

var is_fading: bool = false

@onready var default_light_strength : float = 1

func _ready() -> void:
	_fade_to_transparent()
	
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
			npc.hit.connect(spawn_blood.bind(npc))
		if npc is _Enemy:
			npc.hit.connect(_emit_hit_sound)
			npc.hit.connect(spawn_blood.bind(npc))

var elapsed_time : float = 0
func _physics_process(delta: float) -> void:
	elapsed_time += delta
	
	var hue := sin(elapsed_time * disco_light_speed)*0.5+0.5
	directional_light_2d.color = Color.from_hsv(hue, 1, 1)
	
	ammo_label.text = "%d/%d" % [player.current_ammo, player.reserve_ammo]

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

func _fade_to_transparent() -> void:
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP 
	fade_screen.color = Color(0,0,0,1)
	var tween: Tween = create_tween()
	tween.tween_property(fade_screen, "color", Color(0, 0, 0, 0), 1.5) # Fades over 1.5 seconds
	await tween.finished
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _start_fade_to_black() -> void:
	is_fading = true
	timer.stop() # Stop checking once the trigger happens
	
	# Blocks clicks during the transition
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# Create a smooth fade transition using a Tween
	var tween: Tween = create_tween()
	tween.tween_property(fade_screen, "color", Color(0, 0, 0, 1), 1.5) # Fades over 1.5 seconds
	tween.finished.connect(_on_fade_finished)

## spawna um png de sangue aleatorio na posicao
func spawn_blood(origin: Node2D) -> void:
	var number : int = randi_range(1,40)
	var img : Texture2D = load("res://night_time/assets/images/blood/blood%d%d.png" % [number / 10, number % 10])
	var blood := Sprite2D.new()
	bloods.add_child(blood)
	blood.scale = Vector2.ONE * 4
	blood.texture = img
	blood.centered = true
	blood.global_position = origin.global_position

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
	camera.shake(0.3, 0.5)

func _on_player_knife() -> void:
	sound_manager.play_poly_sound(KNIFE_SOUND)

func _on_empty_gun() -> void:
	sound_manager.play_poly_sound(EMPTY_GUN_SOUND)

func _on_player_reloading() -> void:
	sound_manager.play_poly_sound(RELOAD_SOUND)
