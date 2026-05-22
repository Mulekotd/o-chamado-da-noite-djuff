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
	seconds.rotation = (elapsed / 60) * (PI*2)
	minute.rotation  = (elapsed / 60 / 60) * (PI*2)
	hour.rotation    = (elapsed / 60 / 60 / 60) * (PI*2)
	
	apply_shake()
	
	elapsed += delta * speed

func apply_shake() -> void:
	var displacement : Vector2 = Vector2(
		randf_range(-speed + 1, speed - 1) * shake_factor,
		randf_range(-speed + 1, speed - 1) * shake_factor)
	base.position = displacement

func copy_to_static_clock() -> void:
	$StaticClock/Seconds.rotation = seconds.rotation
	$StaticClock/Minute.rotation = minute.rotation
	$StaticClock/Hour.rotation = hour.rotation

## play animation where the static clock grows and fades out
func blow_static_clock(duration: float, scale: float) -> void:
	copy_to_static_clock()
	$StaticClock.visible = true
	$StaticClock.modulate = Color(0,0,1,1)
	$StaticClock.scale = Vector2.ONE
	var tween := get_tree().create_tween().set_ease(Tween.EASE_OUT)
	tween.tween_property($StaticClock, "scale", Vector2(scale, scale), duration)
	tween = get_tree().create_tween().set_ease(Tween.EASE_OUT)
	await tween.tween_property($StaticClock, "modulate", Color(1,1,1,0), duration).finished
	$StaticClock.visible = false
