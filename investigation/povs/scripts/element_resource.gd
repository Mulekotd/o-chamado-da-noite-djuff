class_name Element extends Resource

@export var name: String = ""
@export var hitbox : Dictionary[String, float] = {
	"left" : 0.5,
	"top" : 0.5,
	"right" : 0.5,
	"bottom" : 0.5
}
@export var pov_name: String = ""
@export var prompt_chain: PromptChain = PromptChain.new()
@export var necessary_items: Array[Item]
@export var conditions: Dictionary[String, int]
