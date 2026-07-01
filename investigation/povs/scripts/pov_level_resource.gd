class_name PovLevel extends Resource

@export var bg_image_path : String
@export var pov_directions_array : Array[PovDirections]
@export var puzzle_povs : Array[PuzzlePov]
@export var dir_scale : float = 1.0
## POV shown on first entry when no previous POV exists.
@export var default_pov : String
