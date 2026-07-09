extends Control

@export var investigation : _Investigation
@export var pov_level : PovLevel

@onready var telephone_overlay: TextureRect = $TelephoneOverlay
@onready var color_overlay: ColorRect = $ColorOverlay

var transitioned_to_house : bool = false
var displayed_clocks : bool = false
var transitioned_to_day_1 : bool = false

# TODO fazer telefone ficar na tela ate player clicar
# TODO fazer relogios so aparecerem quando detetive olhar
# TODO fazer transicao de casa para casa

func _ready() -> void:
	InvestigationVars.set_last_level("prologue")
		
	investigation.pov_manager.prompt_wait_time = 0
	investigation.pov_manager.load_pov_level(pov_level)
	investigation.pov_manager.prompt_wait_time = 0.5
	
	if investigation.pov_manager.current_pov.name != "telefone":
		telephone_overlay.queue_free()
	else:
		# phone ringing
		investigation.sound_manager.play_soundtrack(load("uid://dkjk3u6xy03vu"))
	
	investigation.actions_manager.modulate = Color.TRANSPARENT
	investigation.actions_manager.pos_overwrite = Vector2(480, 260)
	investigation.actions_manager.use_pos_overwrite = true
	
	color_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	color_overlay.color = Color.BLACK
	await get_tree().create_tween().tween_property(
		color_overlay, "color", Color(0,0,0,0), 1).finished
	color_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not transitioned_to_day_1 and InvestigationVars.meets_all_conditions({"entered_house" : 1}):
		_start_day1()
	
	if not transitioned_to_house and InvestigationVars.meets_all_conditions({"left_home" : 1}):
		transitioned_to_house = true
		color_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		color_overlay.color = Color.BLACK
		investigation.pov_manager.change_pov_by_name("casa longe")
		investigation.sound_manager.play_poly_sound(preload("uid://bu3uh5jn7nbvm"))
		await get_tree().create_timer(4).timeout
		await get_tree().create_tween().tween_property(
			color_overlay, "color", Color(0,0,0,0), 1).finished
		color_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if not displayed_clocks and InvestigationVars.meets_all_conditions({"display_clocks": 1}):
		displayed_clocks = true
		investigation.actions_manager.modulate = Color.WHITE
		investigation.actions_manager.use_pos_overwrite = false

func _start_day1() -> void:
	InvestigationVars.set_last_level("day1")
	color_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	color_overlay.color = Color(0,0,0,0)
	await get_tree().create_tween().tween_property(
			color_overlay, "color", Color(0,0,0,1), 3).finished
	get_tree().change_scene_to_packed(preload("res://investigation/scenes/days/day1.tscn"))

func _on_telephone_overlay_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		telephone_overlay.queue_free()
		investigation.text_box.next_prompt(-1)
		color_overlay.color = Color.WHITE
		get_tree().create_tween().tween_property(color_overlay, "color", Color.TRANSPARENT, 1)
		investigation.sound_manager.play_soundtrack(preload("uid://cv1ok2itg5os8"))
		investigation.sound_manager.play_poly_sound(preload("uid://c6fjv5k6jd2n5"))
