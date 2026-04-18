class_name PovDirections extends Resource

## Stores a pov and one or null pov for each direction

@export var pov : Pov
@export var left : Pov
@export var top : Pov
@export var right : Pov
@export var bottom : Pov
## this is going to be used by the manager to pick the right "version" of a pov
@export var global_conditions : Dictionary[String, int]
