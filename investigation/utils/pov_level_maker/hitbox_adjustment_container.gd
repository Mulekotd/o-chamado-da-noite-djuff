extends Control

@onready var pov_image_r: TextureRect = $Panel/MarginContainer/VBoxContainer/HitboxContainer/PovImageRect
@onready var hitbox_r: ColorRect = $Panel/MarginContainer/VBoxContainer/HitboxContainer/PovImageRect/HitboxRect

signal closed(hitbox_values: Dictionary[String, float])

func get_hitbox_values() -> Dictionary[String, float]:
	var dict : Dictionary[String, float] = {
		"left" : hitbox_r.position.x/pov_image_r.size.x,
		"right" : (hitbox_r.size.x + hitbox_r.position.x) / pov_image_r.size.x,
		"top" : hitbox_r.position.y/pov_image_r.size.y,
		"bottom" : (hitbox_r.size.y + hitbox_r.position.y) / pov_image_r.size.y,
	}
	return dict

func load_hitbox_values(left: float = 0.25, top: float = 0.25, right: float = 0.75, bottom: float = 0.75) -> int:
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
	
	hitbox_r.position.x = pov_image_r.size.x*left
	hitbox_r.size.x = pov_image_r.size.x*right - hitbox_r.position.x
	hitbox_r.position.y = pov_image_r.size.y*top
	hitbox_r.size.y = pov_image_r.size.y*bottom - hitbox_r.position.y

	return 0

## find nearest vertice of hitbox. x, y are in pixels
func update_hitbox(x: float, y: float) -> void:
	var h_half := hitbox_r.position.x + hitbox_r.size.x/2
	var v_half := hitbox_r.position.y + hitbox_r.size.y/2
	var current_values : Dictionary[String,float] = get_hitbox_values()
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
	print(get_hitbox_values())

func _on_pov_image_rect_gui_input(event: InputEvent) -> void:
	if Input.is_action_pressed("ui_mouse_pressed"):
		var relative_x : float = event.position.x/pov_image_r.size.x
		var relative_y : float = event.position.x/pov_image_r.size.y
		update_hitbox(event.position.x, event.position.y)

func _on_close_button_pressed() -> void:
	closed.emit(get_hitbox_values())
	queue_free()
