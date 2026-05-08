class_name _AdjustHitboxWidget extends Control

@onready var pov_image_r: TextureRect = $Panel/MarginContainer/VBoxContainer/HitboxContainer/PovImageRect
@onready var hitbox_r: ColorRect = $Panel/MarginContainer/VBoxContainer/HitboxContainer/PovImageRect/HitboxRect

signal closed(hitbox_values: Dictionary[String, float])

var _hitbox_values: Dictionary[String, float] = {
	"left": 0.5,
	"top": 0.5,
	"right": 0.5,
	"bottom": 0.5
}

func _ready() -> void:
	pov_image_r.resized.connect(_on_pov_image_rect_resized)

func get_hitbox_values() -> Dictionary[String, float]:
	return _hitbox_values.duplicate()

func load_hitbox(img: Texture2D, hitbox: Dictionary[String, float]) -> void:
	# Load preview image and apply the current normalized hitbox.
	pov_image_r.texture = img
	load_hitbox_values(
		hitbox["left"],
		hitbox["top"],
		hitbox["right"],
		hitbox["bottom"]
	)

func load_hitbox_values(left: float = 0.5, top: float = 0.5, right: float = 0.5, bottom: float = 0.5) -> int:
	# Validate and clamp hitbox values before applying to the UI.
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
	# Convert normalized hitbox to pixel rect inside the image.
	if pov_image_r.size.x <= 0 or pov_image_r.size.y <= 0:
		return

	hitbox_r.position.x = pov_image_r.size.x * _hitbox_values["left"]
	hitbox_r.size.x = pov_image_r.size.x * _hitbox_values["right"] - hitbox_r.position.x
	hitbox_r.position.y = pov_image_r.size.y * _hitbox_values["top"]
	hitbox_r.size.y = pov_image_r.size.y * _hitbox_values["bottom"] - hitbox_r.position.y

func _on_pov_image_rect_resized() -> void:
	_apply_hitbox_to_rect()

## find nearest vertice of hitbox. x, y are in pixels
func update_hitbox(x: float, y: float) -> void:
	var h_half := hitbox_r.position.x + hitbox_r.size.x/2
	var v_half := hitbox_r.position.y + hitbox_r.size.y/2
	var current_values : Dictionary[String,float] = _hitbox_values
	# left-top quadrant
	if x <= h_half and y <= v_half:
		load_hitbox_values(
			x/pov_image_r.size.x,
			y/pov_image_r.size.y,
			current_values["right"],
			current_values["bottom"]
		)
	# left-bottom quadrant
	if x <= h_half and y > v_half:
		load_hitbox_values(
			x/pov_image_r.size.x,
			current_values["top"],
			current_values["right"],
			y/pov_image_r.size.y
		)
	# right-top quadrant
	if x > h_half and y <= v_half:
		load_hitbox_values(
			current_values["left"],
			y/pov_image_r.size.y,
			x/pov_image_r.size.x,
			current_values["bottom"]
		)
	# right-bottom quadrant
	if x > h_half and y > v_half:
		load_hitbox_values(
			current_values["left"],
			current_values["top"],
			x/pov_image_r.size.x,
			y/pov_image_r.size.y
		)

func _on_pov_image_rect_gui_input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_mouse_pressed"):
		update_hitbox(event.position.x, event.position.y)

func _on_close_button_pressed() -> void:
	closed.emit(get_hitbox_values())
	queue_free()
