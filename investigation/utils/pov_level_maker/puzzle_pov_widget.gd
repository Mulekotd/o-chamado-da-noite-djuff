class_name _PuzzlePovWidget extends Control

const POV_IMAGES_WIDGET = preload("uid://b2nqv18l1c3xo")

var pov_images : Array[PovImage] = []
var coords : Vector2 = Vector2.ZERO
@export var pov_name_line_edit : LineEdit
@export var digits_widget : _DigitsWidget
@export var symbols_widget : _SymbolsWidget
@export var combinations_widget : _CombinationsWidget
@export var prompt_chain_widget : _PromptChainWidget
@export var conditions_widget : _ConditionsWidget
@export var image_file_dialog : FileDialog
@export var sound_widget : _SoundWidget

signal closed(PuzzlePov)

func _ready() -> void:
	symbols_widget.changed.connect(_update_digits_demo)

func load_puzzle_pov(pov: PuzzlePov) -> void:
	# name
	pov_name_line_edit.clear()
	pov_name_line_edit.text = pov.name
	# pov images
	pov_images = pov.images
	# digits
	_update_preview_image()
	if pov.symbol_paths:
		var first_path := pov.symbol_paths[0]
		if first_path:
			var tex := load(first_path)
			if tex is Texture2D:
				digits_widget.load_digits(pov.digits, tex)
			else:
				digits_widget.load_digits(pov.digits, null)
		else:
			digits_widget.load_digits(pov.digits, null)
	# symbols
	symbols_widget.load_symbols(pov.symbol_paths)
	# combinations
	combinations_widget.load_combinations(pov.combinations)
	# prompt_chain
	prompt_chain_widget.load_prompt_chain(pov.prompt_chain)
	# conditions
	conditions_widget.load_conditions(pov.global_conditions)
	# coords
	coords = pov.coords
	# sound
	sound_widget.load_sound(pov.sound)

func parse_puzzle_pov() -> PuzzlePov:
	var pov := PuzzlePov.new()
	# pov images
	pov.images = pov_images
	# name
	pov.name = pov_name_line_edit.text
	# digits
	pov.digits = digits_widget.parse_digits()
	# symbols
	pov.symbol_paths = symbols_widget.parse_symbols()
	# combinations
	pov.combinations = combinations_widget.parse_combinations()
	# prompt_chain
	pov.prompt_chain = prompt_chain_widget.parse_prompt_chain()
	# conditions
	pov.global_conditions = conditions_widget.parse_conditions()
	# coords
	pov.coords = coords
	# sound
	pov.sound = sound_widget.get_sound()
	# done
	return pov

## updates the image in the digits
func _update_digits_demo() -> void:
	for img_path : String in symbols_widget.parse_symbols():
		if img_path:
			var tex := load(img_path)
			if tex is Texture2D:
				digits_widget.set_demo_symbol(tex)
				return
	digits_widget.set_demo_symbol(null)

func _update_preview_image() -> void:
	for img in pov_images:
		if img.image_path:
			var tex := load(img.image_path)
			if tex is Texture2D:
				digits_widget.load_pov_image(tex)
				return
	digits_widget.load_pov_image(null)

func _load_pov_images(imgs: Array[PovImage]) -> void:
	pov_images = imgs
	_update_preview_image()

func _on_choose_image_button_pressed() -> void:
	var piw : _PovImagesWidget = POV_IMAGES_WIDGET.instantiate()
	piw.load_pov_images(pov_images)
	piw.closed.connect(_load_pov_images)
	var p : Control = get_tree().get_first_node_in_group("util_parent_control")
	if p:
		p.add_child(piw)
	else:
		add_child(piw)

func _on_cancel_button_pressed() -> void:
	queue_free()

func _on_close_button_pressed() -> void:
	closed.emit(parse_puzzle_pov())
	queue_free()
