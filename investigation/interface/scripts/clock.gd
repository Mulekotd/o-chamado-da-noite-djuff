@tool
class_name _Clock extends Control

@export var seconds: Sprite2D
@export var minute: Sprite2D
@export var hour: Sprite2D
@export var base: Sprite2D

@export var speed : float = 1
@export var shake_factor : float = 0.003

var elapsed : float = 0
func _process(delta: float) -> void:
	seconds.rotation = (elapsed / 60) * (PI*2) * speed
	minute.rotation = (elapsed / 60 / 60) * (PI*2) * speed
	hour.rotation = (elapsed / 60 / 60 / 60) * (PI*2) * speed
	
	apply_shake()
	
	elapsed += delta

func apply_shake() -> void:
	var displacement : Vector2 = Vector2(
		randf_range(-speed + 1, speed - 1) * shake_factor,
		randf_range(-speed + 1, speed - 1) * shake_factor)
	base.position = displacement
