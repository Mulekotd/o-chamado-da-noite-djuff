class_name PovManager extends Control

@onready var view: TextureRect = $View
@onready var left_arrow: TextureRect = $LeftFlowContainer/LeftArrow
@onready var top_arrow: TextureRect = $TopFlowContainer/TopArrow
@onready var right_arrow: TextureRect = $RightFlowContainer/RightArrow
@onready var bottom_arrow: TextureRect = $BottomFlowContainer/BottomArrow

const BOTTOM_ARROW = preload("uid://cm8l3y3l3dioj")
const LEFT_ARROW = preload("uid://b513u1882j8ph")
const RIGHT_ARROW = preload("uid://dlf5uc3tlxr2j")
const TOP_ARROW = preload("uid://dtdkxktq3g8yr")

signal element_clicked(element: Element)
signal prompt_chain_called(p_chain: PromptChain)

@export var pov_level : PovLevel
var pov_index : int
var current_pov : Pov
var enabled : bool = true
@export var arrow_hitbox : float = 16
## time to wait before showing the prompt_chain if a pov has one
@export var prompt_wait_time : float = 1

func _ready() -> void:
	_load_last_pov()

func change_pov(index: int) -> void:
	pov_index = index
	current_pov = pov_level.pov_directions_array[index].pov
	update_view(current_pov)
	_save_last_pov(current_pov.name)
	if current_pov.prompt_chain.prompts:
		enabled = false
		await get_tree().create_timer(prompt_wait_time).timeout
		prompt_chain_called.emit(current_pov.prompt_chain)
	
func change_pov_by_name(pov_name: String) -> void:
	change_pov(get_pov_index(pov_name))
	
func update_view(pov: Pov) -> void:
	view.texture = pov.image
	update_arrows()

func update_arrows() -> void:
	var pov_direction := pov_level.pov_directions_array[pov_index]
	_configure_arrow(left_arrow, LEFT_ARROW, pov_direction.left)
	_configure_arrow(top_arrow, TOP_ARROW, pov_direction.top)
	_configure_arrow(right_arrow, RIGHT_ARROW, pov_direction.right)
	_configure_arrow(bottom_arrow, BOTTOM_ARROW, pov_direction.bottom)

func _configure_arrow(arrow: TextureRect, arrow_texture: Texture2D, target_pov: String) -> void:
	# Avoid duplicate gui_input callbacks when changing POV multiple times.
	for connection in arrow.gui_input.get_connections():
		arrow.gui_input.disconnect(connection.callable)

	if target_pov:
		var target_index := get_pov_index(target_pov)
		arrow.texture = arrow_texture
		arrow.visible = true
		arrow.mouse_filter = Control.MOUSE_FILTER_STOP
		if target_index != -1:
			arrow.gui_input.connect(_on_arrow_gui_input.bind(target_index))
	else:
		arrow.texture = null
		arrow.visible = false
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_arrow_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and\
	event.button_index == MOUSE_BUTTON_LEFT and\
	event.pressed and\
	enabled:
		change_pov(index)

## returns the first index of the pov direction in the pov_level that has this pov as it's mains pov and has all the conditions met
func get_pov_index(name: String) -> int:
	var i := 0
	for dir in pov_level.pov_directions_array:
		print(i, " : ", dir.pov.name)
		if dir.pov.name == name:
			if InvestigationVars.check_global_conditions(dir.pov.global_conditions):
				return i
		i += 1
	return -1

func _save_last_pov(p_name: String) -> void:
	print("salvou: ", p_name)
	InvestigationVars.set_last_pov(p_name)

## gets the element is the relative position [0, 1]. returns null if none found
func _get_element_in_pos(pos: Vector2) -> Element:
	for e in current_pov.elements:
		if (pos.x >= e.hitbox.left and\
			pos.x <= e.hitbox.right and\
			pos.y >= e.hitbox.top and\
			pos.y <= e.hitbox.bottom):
			return e
	return null

func _load_last_pov() -> void:
	print("tentando achar: ",InvestigationVars.get_last_pov() )
	if get_pov_index(InvestigationVars.get_last_pov()) != -1:
		print("achou last pov: ", InvestigationVars.get_last_pov())
		change_pov(get_pov_index(InvestigationVars.get_last_pov()))
	else:
		print("nao achou, carregando default.")
		change_pov(get_pov_index(pov_level.default_pov))

func _on_gui_input(_event: InputEvent) -> void:
	if !Input.is_action_just_pressed("ui_mouse_pressed") or !enabled:
		return
		
	var mouse_pos := get_local_mouse_position()
	var mouse_relative := Vector2(mouse_pos.x/size.x, mouse_pos.y/size.y)
	
	var e := _get_element_in_pos(mouse_relative)
	if e:
		if e.pov_name and\
		 InvestigationVars.check_inventory(e.necessary_items) and\
		 InvestigationVars.check_global_conditions(e.conditions):
			change_pov_by_name(e.pov_name)
		else:
			for p in e.prompt_chain.prompts:
				pass#print(p.text, " POV: ", p.pov)
			element_clicked.emit(e)
