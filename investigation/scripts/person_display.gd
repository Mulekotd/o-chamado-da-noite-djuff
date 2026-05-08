class_name PersonDisplay extends TextureRect

func _ready() -> void:
	texture = null

func load_img(img: Texture2D) -> void:
	texture = img

func load_img_from_prompt(prompt: Prompt) -> void:
	# Prefer the prompt image, otherwise clear the portrait.
	if !prompt: return
	if !prompt.img: clear_img()
	load_img(prompt.img)

func clear_img() -> void:
	load_img(null)
