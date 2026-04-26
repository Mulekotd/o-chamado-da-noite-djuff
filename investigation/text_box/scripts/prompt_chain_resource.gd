class_name PromptChain extends Resource

@export var name : String
@export var prompts : Array[Prompt]
@export var default_image : Texture2D
## audios to play once per letter. Will be randomized and modulated.
@export var letter_sounds : Array[AudioStream]
