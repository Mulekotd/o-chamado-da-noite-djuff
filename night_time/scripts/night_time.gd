extends Node2D

@export_file("*.tscn") var next_scene_path: String = "res://scenes/main_menu.tscn"

@onready var timer: Timer = $Timer
@onready var fade_screen: ColorRect = $CanvasLayer/FadeScreen

var is_fading: bool = false

func _ready() -> void:
	# Set up the fade screen to be transparent at start
	fade_screen.color = Color(0, 0, 0, 0)
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Configure and start the 5-second timer dynamically if not set in editor
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

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
