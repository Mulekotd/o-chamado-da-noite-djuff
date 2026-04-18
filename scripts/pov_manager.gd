extends Control

@onready var view: TextureRect = $View
@onready var left_arrow: TextureRect = $LeftFlowContainer/LeftArrow
@onready var top_arrow: TextureRect = $TopFlowContainer/TopArrow
@onready var right_arrow: TextureRect = $RightFlowContainer/RightArrow
@onready var bottom_arrow: TextureRect = $BottomFlowContainer/BottomArrow

const BOTTOM_ARROW = preload("uid://cm8l3y3l3dioj")
const LEFT_ARROW = preload("uid://b513u1882j8ph")
const RIGHT_ARROW = preload("uid://dlf5uc3tlxr2j")
const TOP_ARROW = preload("uid://dtdkxktq3g8yr")

@export var pov_level : PovLevel
var pov_index : int
var current_pov
@export var arrow_hitbox : float = 16

func _ready() -> void:
	change_pov(0)

func change_pov(index: int) -> void:
	pov_index = index
	current_pov = pov_level.povs[index].pov
	update_view(current_pov)
	
func update_view(pov: Pov) -> void:
	view.texture = pov.image
	update_arrows()

func update_arrows() -> void:
	var pov_direction := pov_level.povs[pov_index]
	_configure_arrow(left_arrow, LEFT_ARROW, pov_direction.left)
	_configure_arrow(top_arrow, TOP_ARROW, pov_direction.top)
	_configure_arrow(right_arrow, RIGHT_ARROW, pov_direction.right)
	_configure_arrow(bottom_arrow, BOTTOM_ARROW, pov_direction.bottom)

func _configure_arrow(arrow: TextureRect, arrow_texture: Texture2D, target_pov: Pov) -> void:
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		change_pov(index)

## returns the first index of the pov direction in the pov_level that has this pov as it's mains pov
func get_pov_index(pov: Pov) -> int:
	for i in pov_level.povs.size():
		if pov_level.povs[i].pov == pov:
			return i
	return -1

func _on_gui_input(event: InputEvent) -> void:
	if !Input.is_action_just_pressed("ui_mouse_pressed"):
		return
	print(get_local_mouse_position())
	#if get_local_mouse_position().x < arrow_hitbox and current_pov.arrow_povs["left"]:
	#	change_pov(current_pov.arrow_povs["left"])
