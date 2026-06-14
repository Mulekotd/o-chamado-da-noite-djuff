extends Control

@export var investigation : _Investigation
@export var pov_level : PovLevel
@onready var telephone_overlay: TextureRect = $TelephoneOverlay

var transitioned_to_house : bool = false

# TODO fazer telefone ficar na tela ate player clicar
# TODO fazer relogios so aparecerem quando detetive olhar
# TODO fazer transicao de casa para casa

func _ready() -> void:
	investigation.pov_manager.load_pov_level(pov_level)
	# TODO play telephone ringing

func _process(delta: float) -> void:
	if InvestigationVars.meets_all_conditions({"left_home" : 1}):
		# TODO cut to black
		# TODO fade in
		investigation.pov_manager.change_pov("house")
		transitioned_to_house = true

func _on_telephone_overlay_gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_mouse_pressed"):
		telephone_overlay.queue_free()
		# TODO play telephone sound
		# TODO stop telephone ringing
