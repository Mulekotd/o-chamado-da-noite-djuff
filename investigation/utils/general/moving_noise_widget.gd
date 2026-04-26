class_name _MovingNoiseWidget extends TextureRect

var bg : NoiseTexture2D
@export var bg_speed : Vector2 = Vector2(0.05,0.5)

func _ready() -> void:
	bg = texture

var elapsed : float = 0
func _physics_process(delta: float) -> void:
	elapsed += delta
	bg.noise.set("offset", Vector2(
		sin(bg_speed.x * elapsed) * 200,
		(bg_speed.y * elapsed) * 10 + cos(elapsed * bg_speed.y) * 5
		))
