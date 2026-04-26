extends Control

@onready var text_box: TextBox = $TextBox
@onready var pov_manager: PovManager = $PovManager

func _ready() -> void:
	pov_manager.element_clicked.connect(_append_prompt_chain_from_element)
	pov_manager.prompt_chain_called.connect(text_box.append_prompt_chain)
	text_box.pov_entered.connect(pov_manager.change_pov_by_name)
	text_box.stand_by_changed.connect(_update_pov_manager_enabled)
	#text_box.append_prompt(preload("uid://bbh3r1vylqulj"))
	#text_box.append_prompt_chain(preload("uid://cgyg4xbvptlf6"))
	#text_box.append_prompt_chain(preload("uid://koiihvgqo2pg"))


func _update_pov_manager_enabled(stand_by: bool) -> void:
	pov_manager.enabled = stand_by

func _append_prompt_chain_from_element(e: Element) -> void:
	if e.prompt_chain:
		text_box.append_prompt_chain(e.prompt_chain)
