extends Control

@export var investigation : _Investigation
@export var pov_level : PovLevel

# TODO fazer telefone ficar na tela ate player clicar
# TODO fazer relogios so aparecerem quando detetive olhar
# TODO fazer transicao de casa para casa

func _ready() -> void:
	investigation.pov_manager.load_pov_level(pov_level)

func _process(delta: float) -> void:
	pass
