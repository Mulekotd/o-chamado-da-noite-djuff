class_name PovManager extends Control

@onready var view: TextureRect = $View
@onready var left_arrow: TextureRect = $LeftFlowContainer/LeftArrow
@onready var top_arrow: TextureRect = $TopFlowContainer/TopArrow
@onready var right_arrow: TextureRect = $RightFlowContainer/RightArrow
@onready var bottom_arrow: TextureRect = $BottomFlowContainer/BottomArrow
@onready var shadow_panel: Panel = $View/ShadowPanel
@onready var digits_container: DigitsContainer = $View/DigitsContainer

const BOTTOM_ARROW = preload("uid://cm8l3y3l3dioj")
const LEFT_ARROW = preload("uid://b513u1882j8ph")
const RIGHT_ARROW = preload("uid://dlf5uc3tlxr2j")
const TOP_ARROW = preload("uid://dtdkxktq3g8yr")

const CURSORS : Dictionary[int, CursorShape] = {
	-1 : CURSOR_FORBIDDEN,
	Element.cursor_shapes.DEFAULT : CURSOR_ARROW,
	Element.cursor_shapes.POINTING_HAND : CURSOR_POINTING_HAND,
	Element.cursor_shapes.MAGNIFIER : CURSOR_HELP,
	Element.cursor_shapes.STEPS : CURSOR_MOVE,
}

signal element_clicked(element: Element)
signal prompt_chain_called(p_chain: PromptChain)
signal pov_entered()
signal sound_played(sound: AudioStream)

var pov_index : int
var current_pov : Pov
var enabled : bool = false :
	set(x):
		enabled = x
		#print("enabled = ", x)
		if enabled:
			_pan_locked = false
		update_arrows()
@export var pov_level : PovLevel
@export var arrow_hitbox : float = 16
## time to wait before showing the prompt_chain if a pov has one
@export var prompt_wait_time : float = 1
## how far the POV image pans based on mouse distance to center
@export var pan_amount : Vector2 = Vector2(12, 8)
## how quickly the POV image lerps to its pan position
@export var pan_lerp_speed : float = 10.0
## seconds for the arrow transition slide
@export var arrow_slide_duration : float = 0.3
## seconds for the arrow transition fade
@export var arrow_fade_duration : float = 0.1
## how far the POV image slides during arrow transitions (as a fraction of view size)
@export var arrow_transition_offset_scale : float = 0.35

var _view_base_pos : Vector2
var _pan_locked : bool = false
var _is_transitioning : bool = false
var _on_puzzle_pov : bool = false

func _ready() -> void:
	_sync_view_base_pos()
	_reset_shadow_panel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_view_base_pos()

func _process(_delta: float) -> void:
	_update_view_pan(_delta)

func load_pov_level(level: PovLevel) -> void:
	pov_level = level
	_update_cursor()
	enabled = true

func change_pov(pov: Pov) -> void:
	if pov != current_pov:
		current_pov = pov
		
		_on_puzzle_pov = pov is PuzzlePov
		if _on_puzzle_pov:
			digits_container.load_digits(pov)
		else:
			digits_container.clear_digits()
			
		update_view(current_pov)
		_save_last_pov(current_pov.name)
		if _has_any_valid_prompt(current_pov.prompt_chain):
			# Pause navigation while the POV's prompt chain is displayed.
			enabled = false
			await get_tree().create_timer(prompt_wait_time).timeout
			prompt_chain_called.emit(current_pov.prompt_chain)
		if current_pov.especial_behaviour:
			for s in get_parent().get_children():
				if s.name == current_pov.name + "_behaviour":
					return
			# Spawn a runtime behaviour node to allow custom POV logic.
			var n := Node.new()
			n.set_script(current_pov.especial_behaviour)
			n.name = current_pov.name + "_behaviour"
			add_sibling(n)
		if current_pov.sound:
			sound_played.emit(current_pov.sound)
	else:
		update_view()
		update_arrows()
		digits_container.update_enabled()
	
func change_pov_by_name(pov_name: String) -> void:
	change_pov(get_pov(pov_name))

func get_all_povs() -> Array[Pov]:
	var povs : Array[Pov] = []
	for dir in pov_level.pov_directions_array:
		if dir.pov:
			povs.append(dir.pov)
	for p in pov_level.puzzle_povs:
		povs.append(p)
	return povs

func get_pov_directions(pov: Pov) -> PovDirections:
	for dir in pov_level.pov_directions_array:
		if dir.pov == pov:
			return dir
	return null

func update_view(pov: Pov = current_pov) -> void:
	var img : Texture2D
	var highest := -1
	var x := -1
	for pi in pov.images:
		x = InvestigationVars.get_conditions_value(pi.conditions)
		if x > highest:
			highest = x
			img = pi.texture
	view.texture = img
	update_arrows()

func update_arrows() -> void:
	if not _on_puzzle_pov:
		var dir := get_pov_directions(current_pov)
		_configure_arrow(left_arrow, LEFT_ARROW, dir.left, Vector2.LEFT)
		_configure_arrow(top_arrow, TOP_ARROW, dir.top, Vector2.UP)
		_configure_arrow(right_arrow, RIGHT_ARROW, dir.right, Vector2.RIGHT)
		_configure_arrow(bottom_arrow, BOTTOM_ARROW, dir.bottom, Vector2.UP) # animation backs out
	else:
		_configure_arrow(left_arrow, LEFT_ARROW, "", Vector2.LEFT) # clear
		_configure_arrow(top_arrow, TOP_ARROW, "", Vector2.UP) # clear
		_configure_arrow(right_arrow, RIGHT_ARROW, "", Vector2.RIGHT) # clear
		_configure_arrow(bottom_arrow, BOTTOM_ARROW, current_pov.back_pov, Vector2.UP)

func _configure_arrow(arrow: TextureRect, arrow_texture: Texture2D, target_pov: String, direction: Vector2) -> void:
	# Avoid duplicate gui_input callbacks when changing POV multiple times.
	for connection in arrow.gui_input.get_connections():
		arrow.gui_input.disconnect(connection.callable)
	
	arrow.texture = null
	arrow.visible = false
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if target_pov and enabled:
		var p := get_pov(target_pov)
		#print("target_pov", " = ", target_pov)
		#print("pov found = ", p)
		#print("seta = ", "bottom" if arrow_texture == BOTTOM_ARROW else "sei la")
		if p:
			arrow.gui_input.connect(_on_arrow_gui_input.bind(p, direction))
			arrow.texture = arrow_texture
			arrow.visible = true
			arrow.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_arrow_gui_input(event: InputEvent, pov: Pov, direction: Vector2) -> void:
	if event is InputEventMouseButton and\
	event.button_index == MOUSE_BUTTON_LEFT and\
	event.pressed and\
	enabled:
		await _transition_to_pov(pov, direction)

## returns the first index of the pov direction in the pov_level that has this pov as it's mains pov and has the highest conditions value
func get_pov(name: String) -> Pov:
	var i := 0
	## highest conditions value yet
	var highest_value : float = -1
	## the most suitable pov
	var considered_pov : Pov = null
	## current conditions value
	var x : float = -1
	for p in get_all_povs():
		if p.name == name:
			if p is PuzzlePov:
				return p
			else:
				x = InvestigationVars.get_conditions_value(p.global_conditions)
				if x > highest_value:
					highest_value = x
					considered_pov = p
	return considered_pov

func _save_last_pov(p_name: String) -> void:
	InvestigationVars.set_last_pov(p_name)

## gets the first found element in the relative position [0, 1]. returns null if none found
func _get_element_in_pos(pos: Vector2) -> Element:
	for e in current_pov.elements:
		if (pos.x >= e.hitbox.left and\
			pos.x <= e.hitbox.right and\
			pos.y >= e.hitbox.top and\
			pos.y <= e.hitbox.bottom):
			return e
	return null

## gets all the elements that overlap with the mouse in the relative position [0, 1].
func _get_elements_in_pos(pos: Vector2) -> Array[Element]:
	var elements : Array[Element] = []
	for e in current_pov.elements:
		if (pos.x >= e.hitbox.left and\
			pos.x <= e.hitbox.right and\
			pos.y >= e.hitbox.top and\
			pos.y <= e.hitbox.bottom):
			elements.append(e)
	return elements

func _load_last_pov() -> void:
	var p := get_pov(InvestigationVars.get_last_pov())
	if p:
		change_pov(p)
	else:
		change_pov(get_pov(pov_level.default_pov))

func _update_cursor() -> void:
	# Cursor feedback changes based on enabled state and hitbox hover.
	var mouse_relative := _get_mouse_relative_to_view()
	if enabled:
		var element : Element = _get_element_in_pos(mouse_relative)
		if element:
			_change_cursor(CURSORS[element.cursor_shape])
		else:
			_change_cursor(CURSORS[Element.cursor_shapes.DEFAULT])
	else:
		_change_cursor(CURSORS[-1])

func _change_cursor(cursor: int) -> void:
	if mouse_default_cursor_shape != cursor:
		mouse_default_cursor_shape = cursor

func _on_gui_input(_event: InputEvent) -> void:
	_update_cursor()
	
	if !Input.is_action_just_pressed("ui_mouse_pressed") or !enabled:
		return

	var mouse_relative := _get_mouse_relative_to_view()
	
	var elements := _get_elements_in_pos(mouse_relative)
	var valid_elements : Array[Element] = []
	for e in elements:
		if (InvestigationVars.check_inventory(e.necessary_items) and\
		InvestigationVars.get_conditions_met(e.conditions)): # is valid
			valid_elements.append(e)
		else:
			if e.prompt_chain.prompts:
				_pan_locked = true
			element_clicked.emit(e)
	for e in valid_elements:
		if e.vars_to_change:
			InvestigationVars.update_variables(e.vars_to_change)
			update_view(current_pov)
		if e.sound:
			sound_played.emit(e.sound)
		if e.pov_name:
			_pan_locked = true
			var target_pov := get_pov(e.pov_name)
			if target_pov:
				if e.pov_sound:
					sound_played.emit(e.pov_sound)
				await _transition_to_pov(target_pov, Vector2.ZERO)
			else:
				change_pov_by_name(e.pov_name)
		else:
			if e.prompt_chain.prompts:
				_pan_locked = true
			element_clicked.emit(e)

func _sync_view_base_pos() -> void:
	if view == null:
		view = get_node_or_null("View")
	if view == null:
		return
	_view_base_pos = view.position
	_reset_shadow_panel()


func _update_view_pan(delta: float) -> void:
	if view == null:
		return
	if size.x <= 0 or size.y <= 0:
		return
	if _pan_locked:
		return
	if _is_transitioning:
		return
	var center := size * 0.5
	var mouse_pos := get_local_mouse_position()
	var offset := Vector2.ZERO
	var is_inside := Rect2(Vector2.ZERO, size).has_point(mouse_pos)
	if is_inside:
		var normalized := Vector2(
			(mouse_pos.x - center.x) / center.x,
			(mouse_pos.y - center.y) / center.y
		)
		normalized.x = clampf(normalized.x, -1.0, 1.0)
		normalized.y = clampf(normalized.y, -1.0, 1.0)
		offset = Vector2(-normalized.x * pan_amount.x, -normalized.y * pan_amount.y)
	var target_pos := _view_base_pos + offset
	view.position = view.position.lerp(target_pos, clampf(pan_lerp_speed * delta, 0.0, 1.0))

func _get_mouse_relative_to_view() -> Vector2:
	if view == null:
		return Vector2(-1, -1)
	var view_size := view.size
	if view_size.x <= 0 or view_size.y <= 0:
		return Vector2(-1, -1)
	var mouse_pos := get_local_mouse_position()
	return Vector2(
		(mouse_pos.x - view.position.x) / view_size.x,
		(mouse_pos.y - view.position.y) / view_size.y
	)

func _transition_to_pov(pov: Pov, direction: Vector2) -> void:
	if _is_transitioning:
		return
	if view == null:
		change_pov(pov)
		return
	_is_transitioning = true
	_pan_locked = true
	var was_enabled := enabled
	enabled = false
	pov_entered.emit()

	var dir := direction.normalized()
	var slide_offset := _get_transition_offset(dir)
	var out_pos := _view_base_pos - slide_offset
	var in_pos := _view_base_pos + slide_offset

	# Slide out and fade to black before swapping the POV.
	var tween := create_tween()
	tween.tween_property(view, "position", out_pos, arrow_slide_duration)
	tween.parallel().tween_property(view, "modulate", Color(0, 0, 0, 1), arrow_fade_duration)
	if shadow_panel:
		tween.parallel().tween_property(shadow_panel, "modulate", Color(0, 0, 0, 1), arrow_fade_duration)
	await tween.finished

	view.position = in_pos
	view.modulate = Color(0, 0, 0, 1)
	if shadow_panel:
		shadow_panel.modulate = Color(0, 0, 0, 1)
	change_pov(pov)

	# Slide in and fade back to white for the new POV.
	tween = create_tween()
	tween.tween_property(view, "position", _view_base_pos, arrow_slide_duration)
	tween.parallel().tween_property(view, "modulate", Color(1, 1, 1, 1), arrow_fade_duration)
	if shadow_panel:
		tween.parallel().tween_property(shadow_panel, "modulate", Color(0, 0, 0, 0), arrow_fade_duration)
	await tween.finished

	_is_transitioning = false
	_pan_locked = false
	#print("has valid prompt, will remain disabled" if _has_any_valid_prompt(current_pov.prompt_chain) else "no valid prompt, will enable")
	if was_enabled and enabled == false and not _has_any_valid_prompt(current_pov.prompt_chain):
		enabled = true
	_reset_shadow_panel()

func _has_any_valid_prompt(p_chain : PromptChain) -> bool:
	for p : Prompt in p_chain.prompts:
		if InvestigationVars.meets_all_conditions(p.global_conditions):
			#print(p.global_conditions.keys(), " are valid, returning true")
			return true
	return false

func _reset_shadow_panel() -> void:
	if shadow_panel:
		# Keep the vignette subtle while idle.
		shadow_panel.modulate = Color(0, 0, 0, 0)

func _get_transition_offset(direction: Vector2) -> Vector2:
	return Vector2(
		absf(view.size.x) * arrow_transition_offset_scale * direction.x,
		absf(view.size.y) * arrow_transition_offset_scale * direction.y
	)

func _on_digits_container_combination_struck() -> void:
	prompt_chain_called.emit(current_pov.prompt_chain)
	update_view()

func _on_digits_container_digit_changed() -> void:
	update_view()
