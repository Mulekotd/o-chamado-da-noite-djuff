class_name Element extends Resource

@export var name: String
@export_range(0,1,0.001) var hitbox_left   : float 
@export_range(0,1,0.001) var hitbox_top    : float
@export_range(0,1,0.001) var hitbox_right  : float
@export_range(0,1,0.001) var hitbox_bottom : float
@export var pov: Pov
@export var prompt_chain: PromptChain
@export var necessary_items: Array[Item]
@export var global_variables: Dictionary[String, int]
