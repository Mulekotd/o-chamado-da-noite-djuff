extends Node2D

@onready var label: Label = $CanvasLayer/FollowingText

# Adjust this to change how closely or far away the text stays from the actual cursor
@export var max_distance: float = 50.0

# Adjust this to change how quickly or smoothly the text moves (lower = smoother/slower)
@export var follow_speed: float = 5.0
var scene_to_load = preload("res://scenes/main_menu.tscn")

# Store the default center position of the text
var target_center: Vector2

func _ready() -> void:
	# Save the starting position of the text as its anchor center
	target_center = label.global_position

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_packed(scene_to_load)

	var mouse_pos = get_global_mouse_position()
	
	# Calculate the direction from the screen center toward the mouse
	var screen_center = get_viewport_rect().size / 2
	var dir_to_mouse = (mouse_pos - screen_center).normalized()
	
	# Determine how far the mouse is from the center, capped by our max_distance
	var dist_from_center = screen_center.distance_to(mouse_pos)
	var travel_dist = min(dist_from_center * 0.1, max_distance)
	
	# Calculate the exact target spot for the text
	var target_pos = target_center + (dir_to_mouse * travel_dist)
	
	# Smoothly slide the text toward the target spot
	label.global_position = label.global_position.lerp(target_pos, follow_speed * delta)
