extends Control

@export var investigation: _Investigation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	investigation.pov_manager.load_pov_level(preload("res://investigation/days/day1/day1.tres"))
	investigation.sound_manager.play_soundtrack(preload("uid://cv1ok2itg5os8"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if InvestigationVars.meets_all_conditions({"give_puzzle_points": 1}):
		investigation._add_investigation_points(4)
		print("pontos:", InvestigationVars.get_investigation_points())
		InvestigationVars.update_variables({"give_puzzle_points": 0})
