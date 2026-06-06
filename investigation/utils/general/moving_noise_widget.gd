class_name _MovingNoiseWidget extends TextureRect

var bg : NoiseTexture2D
@export var bg_speed : Vector2 = Vector2(0.05,0.5)
@export var default_frequency : float = 0.0049
var frequency : float
@export var fade_in_duration : float = 0.5

func _ready() -> void:
	# Cache the noise texture for animated offsets.
	bg = texture
	# animate fade in
	modulate = Color(1,1,1,0)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,1), fade_in_duration).set_ease(Tween.EASE_OUT)
	frequency = default_frequency * 1.25
	tween = get_tree().create_tween()
	tween.tween_property(self, "frequency", default_frequency, fade_in_duration * 0.5).set_ease(Tween.EASE_OUT)

var elapsed : float = 0
func _physics_process(delta: float) -> void:
	# Drift the noise offset for a subtle animated background.
	elapsed += delta
	bg.noise.set("offset", Vector2(
		sin(bg_speed.x * elapsed) * 200,
		bg_speed.y * elapsed * 10 + cos(elapsed * bg_speed.y) * 5) + Vector2.ONE * 100 * (frequency - default_frequency))
	bg.noise.set("frequency", frequency)
