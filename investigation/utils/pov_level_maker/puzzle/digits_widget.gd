class_name _DigitsWidget extends Control

const DIGIT_WIDGET = preload("uid://dtrbxva2wk8t7")
const NO_SYMBOL = preload("uid://byxcwmb372yeg")
const POV_IMAGES_WIDGET = preload("uid://b2nqv18l1c3xo")
const NO_IMAGE_POV = preload("uid://dwj11t2nw18l2")

@export var pov_image_rect : TextureRect

## image to be displayed by the digits; if is null, cant add digits.
@export var demo_symbol : Texture2D

## Array that keeps track of all the digit widgets
var digit_widgets : Array[Control] = []

func add_digit_widget() -> _DigitWidget:
	var dw : _DigitWidget = DIGIT_WIDGET.instantiate()
	dw.texture = demo_symbol
	dw.index_label.text = str(len(digit_widgets))
	digit_widgets.append(dw)
	pov_image_rect.add_child(dw)
	print(digit_widgets)
	return dw

func remove_digit_widget() -> void:
	if digit_widgets:
		var dw : _DigitWidget = digit_widgets[-1]
		digit_widgets.pop_back()
		dw.queue_free()

func parse_digits() -> Dictionary[Vector2, Vector2]:
	var digits : Dictionary[Vector2, Vector2] = {}
	for dw in digit_widgets:
		var pos := (dw.global_position - pov_image_rect.global_position)/pov_image_rect.size
		digits.set(pos, dw.size/pov_image_rect.size)
	return digits

func load_digit(digit_pos: Vector2, digit_size: Vector2) -> void:
	var dw := add_digit_widget()
	if dw:
		dw.global_position = pov_image_rect.global_position + (digit_pos * pov_image_rect.size)
		dw.size = pov_image_rect.size * digit_size

func load_digits(digits: Dictionary[Vector2, Vector2], symbol: Texture2D) -> void:
	for digit in digits.keys():
		add_digit_widget()
	set_demo_symbol(demo_symbol)

func set_demo_symbol(symbol: Texture2D):
	for dw : _DigitWidget in digit_widgets:
		if symbol:
			dw.texture = symbol
		else:
			dw.texture = NO_SYMBOL
	demo_symbol = symbol

func load_pov_image(img: Texture2D) -> void:
	if img:
		pov_image_rect.texture = img
	else:
		pov_image_rect.texture = NO_IMAGE_POV

func _on_add_button_pressed() -> void:
	add_digit_widget()
	set_demo_symbol(demo_symbol)

func _on_remove_button_pressed() -> void:
	remove_digit_widget()
	set_demo_symbol(demo_symbol)
