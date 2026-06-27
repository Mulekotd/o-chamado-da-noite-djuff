extends Control

@export var investigation: _Investigation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	investigation.pov_manager.load_pov_level(preload("uid://dl3qq3hinw5cm"))
	investigation.sound_manager.play_soundtrack(preload("uid://cv1ok2itg5os8"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
