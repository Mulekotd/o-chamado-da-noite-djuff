class_name PersonDisplay extends TextureRect

@export var fade_duration : float = 1

func _ready() -> void:
	texture = null
	modulate = Color(0,0,0,0)

func load_img(img: Texture2D) -> void:
	texture = img
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,1), fade_duration)

func load_img_from_prompt(prompt: Prompt) -> void:
	# Prefer the prompt image, otherwise clear the portrait.
	if !prompt: return
	if !prompt.img: 
		clear_img()
	else:
		load_img(prompt.img)

func clear_img() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(0,0,0,0), fade_duration)
