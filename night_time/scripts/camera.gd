extends Camera2D

# How far away from the player the camera can look (in pixels)
@export var max_distance: float = 100.0

# How smoothly the camera moves (lower values = smoother/slower)
@export var smooth_speed: float = 5.0

# Reference to your player node
@export var player: CharacterBody2D

func _process(delta: float) -> void:
	if not player:
		return
		
	# 1. Get the vector pointing from the player to the mouse cursor
	var mouse_offset = get_global_mouse_position() - player.global_position
		
	# 2. Limit the offset so the camera doesn't pan too far away
	var target_offset = mouse_offset.limit_length(max_distance)	
	# 3. Calculate the final target position (player position + limited mouse offset)
	var target_position = player.global_position + target_offset
	
	# 4. Smoothly blend the camera's current position toward the target
	global_position = global_position.lerp(target_position, smooth_speed * delta)
