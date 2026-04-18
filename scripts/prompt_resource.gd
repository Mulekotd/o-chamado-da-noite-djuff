class_name Prompt extends Resource

@export_multiline() var text : String
@export var condition_number : int = -1
@export var necessary_items : Array[Item]
@export var global_conditions : Array[String]
@export_multiline() var options : Array[String]
## if true, this prompt ends the chain it originated from.
@export var end_chain : bool = false
## this number will be overwriten by the prompt chain logic
var chain_id : int
