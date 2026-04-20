class_name PovDirections extends Resource

## Stores a pov and one or null pov for each direction
@export var pov : Pov
@export var left   : String
@export var top    : String
@export var right  : String
@export var bottom : String
var visualizer_coords : Vector2 = Vector2(0.5, 0.5)
var visualizer_rotation : float = 0
