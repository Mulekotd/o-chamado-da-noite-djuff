class_name _Bouncing_Dots_Widget extends HBoxContainer


var dots : Array[Control]

@export var speed: float = 1
@export var range: float = 1

func _ready() -> void:
	for c in get_children():
		dots.append(c)

func _physics_process(delta: float) -> void:
	var l := dots.size()
	var t := Time.get_ticks_msec()
	for i : float in l:
		dots[i].position.y = sin((t * speed * delta) + 2 * PI * (i/l)) * range
