class_name Item extends Resource

@export var id : String
@export var name : String
@export var image : Texture2D

func _get_custom_preview_texture() -> Texture2D:
	# Show the item icon in the editor preview.
	return image
