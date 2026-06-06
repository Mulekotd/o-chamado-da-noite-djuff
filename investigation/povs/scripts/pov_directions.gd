class_name PovDirections extends Resource

## Stores a pov and one or null pov for each direction
@export var pov : Pov
@export var left   : String
@export var top    : String
@export var right  : String
@export var bottom : String
@export_range(0,1,0.001) var rotation : float = 0
## Editor-only coordinates for the POV directions widget.
@export var coords : Vector2 = Vector2.ZERO
