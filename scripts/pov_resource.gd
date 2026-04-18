class_name Pov extends Resource

@export var name: String
@export_multiline() var description: String
@export var image: Texture2D
@export var elements: Array[Element]
#@export var arrow_povs: Dictionary[String, Pov] = {
	#"left" : null,
	#"top" : null,
	#"right" : null,
	#"bottom" : null,
#}
