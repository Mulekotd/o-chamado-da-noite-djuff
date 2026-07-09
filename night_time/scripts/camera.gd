extends Camera2D

# How far away from the player the camera can look (in pixels)
@export var max_distance: float = 100.0

# How smoothly the camera moves (lower values = smoother/slower)
@export var smooth_speed: float = 5.0

# Reference to your player node
@export var player: CharacterBody2D

var shake_strength: float = 0.0
var shake_duration: float = 0.0
var shake_remaining: float = 0.0

func shake(duration: float, amount: float = 8.0) -> void:
	shake_strength += amount
	shake_duration = maxf(shake_duration, duration)
	shake_remaining = shake_duration

func _process(delta: float) -> void:
	if not player:
		return

	var shake_offset := Vector2.ZERO
	if shake_remaining > 0.0:
		shake_remaining -= delta
		shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength
		var t := 1.0 - (shake_remaining / shake_duration)
		shake_offset *= 1.0 - (t * t)
		if shake_remaining <= 0.0:
			shake_strength = 0.0
			shake_duration = 0.0
			shake_remaining = 0.0

	var mouse_offset = get_global_mouse_position() - player.global_position
	var target_offset = mouse_offset.limit_length(max_distance)
	var target_position = player.global_position + target_offset

	global_position = global_position.lerp(target_position, smooth_speed * delta) + shake_offset
