class_name Option extends Resource

@export var text : String = ""
## Global conditions that must pass for this option to be visible.
@export var conditions : Dictionary[String, int] = {}
## Items required in inventory for this option to appear.
@export var necessary_items : Array[Item]
## How many Options are necessary and will be wasted with this option
@export var actions : int = 0
