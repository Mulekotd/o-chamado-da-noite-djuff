class_name Prompt extends Resource

@export_multiline() var text : String
@export var condition_number : int = -1
@export var necessary_items : Array[Item]
@export var global_conditions : Dictionary[String, int]
@export_multiline() var options : Array[String]
## if true, this prompt ends the chain it originated from.
@export var end_chain : bool = false
## items that the player receives after this prompt
@export var items_to_give : Array[Item]
## items that the player loses after this prompt
@export var items_to_take : Array[Item]
## global vars that change after this prompt
@export var vars_to_change : Dictionary[String, int]
## this number will be overwriten by the prompt chain logic
var chain_id : int
