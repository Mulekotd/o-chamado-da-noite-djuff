extends Control

@export var investigation: _Investigation

var exited_level : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	InvestigationVars.update_variables({"exited_level": 0})
	investigation.pov_manager.load_pov_level(preload("res://investigation/days/day1/day1.tres"))
	investigation.sound_manager.play_soundtrack(preload("uid://cv1ok2itg5os8"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if InvestigationVars.meets_all_conditions({"give_puzzle_points": 1}):
		investigation._add_investigation_points(4)
		print("pontos:", InvestigationVars.get_investigation_points())
		InvestigationVars.update_variables({"give_puzzle_points": 0})

func _physics_process(delta: float) -> void:
	if InvestigationVars.meets_all_conditions({"exited_level": 1}) and not exited_level:
		exited_level = true
		investigation.sound_manager.stop_soundtrack()
		await investigation.show_reversed_clock()
		get_tree().change_scene_to_packed(preload("uid://4tcvwh7s3l62"))
