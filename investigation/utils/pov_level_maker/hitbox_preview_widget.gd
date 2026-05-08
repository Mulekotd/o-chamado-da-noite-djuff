class_name _HitboxPreviewWidget extends MarginContainer

@onready var pov_image_r: TextureRect = $PovImageRect
@onready var hitbox_r: ColorRect = $PovImageRect/HitboxRect

var _hitbox_values: Dictionary[String, float] = {
	"left": 0.5,
	"top": 0.5,
	"right": 0.5,
	"bottom": 0.5
}

func _ready() -> void:
	pov_image_r.resized.connect(_on_pov_image_rect_resized)

func load_hitbox_preview(img: Texture2D, hitbox: Dictionary[String, float]) -> void:
	# Display the POV image and draw the hitbox overlay.
	pov_image_r.texture = img
	load_hitbox_values(
		hitbox["left"],
		hitbox["top"],
		hitbox["right"],
		hitbox["bottom"]
	)

# copiado do outro mermo dane-se
func load_hitbox_values(left: float = 0.5, top: float = 0.5, right: float = 0.5, bottom: float = 0.5) -> int:
	# Normalize and validate the hitbox before previewing.
	if right<left:
		print("ERROR: right < left")
		return -1
	if bottom<top:
		print("ERROR: bottom < top")
		return -1
	
	left   = clampf(left  , 0, 1)
	top    = clampf(top   , 0, 1)
	right  = clampf(right , 0, 1)
	bottom = clampf(bottom, 0, 1)

	_hitbox_values = {
		"left": left,
		"top": top,
		"right": right,
		"bottom": bottom
	}

	_apply_hitbox_to_rect()

	return 0

func _apply_hitbox_to_rect() -> void:
	# Convert normalized hitbox values into the preview rect.
	if pov_image_r.size.x <= 0 or pov_image_r.size.y <= 0:
		return

	hitbox_r.position.x = pov_image_r.size.x * _hitbox_values["left"]
	hitbox_r.size.x = pov_image_r.size.x * _hitbox_values["right"] - hitbox_r.position.x
	hitbox_r.position.y = pov_image_r.size.y * _hitbox_values["top"]
	hitbox_r.size.y = pov_image_r.size.y * _hitbox_values["bottom"] - hitbox_r.position.y

func _on_pov_image_rect_resized() -> void:
	_apply_hitbox_to_rect()
