class_name Element extends Resource

@export var name: String
@export_range(0,1,0.001) var hitbox_left
@export_range(0,1,0.001) var hitbox_top
@export_range(0,1,0.001) var hitbox_right
@export_range(0,1,0.001) var hitbox_bottom
@export var pov: Pov
@export var prompt_chain: PromptChain
