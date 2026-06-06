class_name Element extends Resource

@export var name: String = ""
## Hitbox is normalized in POV space, values in [0,1].
@export var hitbox : Dictionary[String, float] = {
	"left" : 0.5,
	"top" : 0.5,
	"right" : 0.5,
	"bottom" : 0.5
}
@export var pov_name: String = ""
@export var prompt_chain: PromptChain = PromptChain.new()
## necessary items to go to pov
@export var necessary_items: Array[Item]
## conditions to go to pov
@export var conditions: Dictionary[String, int]
## variables to change when this element is clicked
@export var vars_to_change: Dictionary[String, int]
