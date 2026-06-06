class_name Pov extends Resource

@export var name: String
@export_multiline() var description: String
## Prompt chain shown on entering this POV.
@export var prompt_chain : PromptChain = PromptChain.new()
@export var images: Array[PovImage]
@export var elements: Array[Element]
## this is going to be used by the manager to pick the right "version" of a pov
@export var global_conditions : Dictionary[String, int]
## Optional script injected into the scene for special behaviour.
@export var especial_behaviour : Script
## Optional sound to play when entering this POV.
@export var sound : AudioStream
