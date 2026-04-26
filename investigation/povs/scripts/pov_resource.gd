class_name Pov extends Resource

@export var name: String
@export_multiline() var description: String
@export var prompt_chain : PromptChain = PromptChain.new()
@export var image: Texture2D
@export var elements: Array[Element]
## this is going to be used by the manager to pick the right "version" of a pov
@export var global_conditions : Dictionary[String, int]
@export var especial_behaviour : Script
@export var sound : AudioStream
