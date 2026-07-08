extends Label

func _process(delta) -> void:
	update_npc_count()

func update_npc_count() -> void:
	var alive_count: int = 0
	for npc in get_tree().get_nodes_in_group("npc"):
		if not ("is_dead" in npc and npc.is_dead):
			alive_count += 1
	text = "AINDA RESTAM " + str(alive_count) + " VÍTIMAS"
