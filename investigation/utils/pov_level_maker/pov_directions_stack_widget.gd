class_name _PovDirectionsStackWidget extends Control

@onready var povs_container: VBoxContainer = $Panel/PovsContainer

const POV_COMPACT_WIDGET = preload("res://investigation/utils/pov_level_maker/pov_compact_widget.tscn")

var pov_dir_widget : _PovDirectionsWidget

signal changed
signal clone_requested(clicked_pov: Pov)

func _connect_pov_compact_widget(pcw: _PovCompactWidget) -> void:
	pcw.changed.connect(_on_pov_compact_widget_changed)
	pcw.clone_requested.connect(_on_pov_compact_widget_clone_requested)

func _on_pov_compact_widget_changed() -> void:
	changed.emit()

func _on_pov_compact_widget_clone_requested(clicked_pov: Pov) -> void:
	clone_requested.emit(clicked_pov)

func get_povs() -> Array[Pov]:
	# Collect all POVs currently stacked under this direction.
	var povs : Array[Pov] = []
	for child in povs_container.get_children():
		if child is _PovCompactWidget:
			var pcw := child as _PovCompactWidget
			var p := pcw.get_pov()
			if p != null:
				povs.append(p)
	return povs

func parse_pov_directions_stack() -> Array[PovDirections]:
	# Mirror the base directions for each stacked POV.
	var dirs : Array[PovDirections] = []
	if pov_dir_widget == null:
		return dirs

	var base_dir := pov_dir_widget.parse_pov_directions()
	for p in get_povs():
		var dir := PovDirections.new()
		dir.pov = p
		dir.left = base_dir.left
		dir.top = base_dir.top
		dir.right = base_dir.right
		dir.bottom = base_dir.bottom
		dir.rotation = base_dir.rotation
		dir.coords = base_dir.coords
		dirs.append(dir)
	return dirs

func load_pov(p: Pov) -> void:
	var pcw : _PovCompactWidget = POV_COMPACT_WIDGET.instantiate()
	povs_container.add_child(pcw)
	_connect_pov_compact_widget(pcw)
	pcw.load_pov(p)

func pop_povs_not_named(name: String) -> Dictionary:
	# Remove POVs that do not match the main name and group them.
	var target_name := name.strip_edges()
	var grouped := {}
	for child in povs_container.get_children():
		if child is _PovCompactWidget:
			var pcw := child as _PovCompactWidget
			var p := pcw.get_pov()
			if p == null:
				continue
			var pov_name := p.name.strip_edges()
			if pov_name == target_name:
				continue
			if !grouped.has(pov_name):
				grouped[pov_name] = []
			var arr: Array = grouped[pov_name]
			arr.append(p)
			grouped[pov_name] = arr
			povs_container.remove_child(pcw)
			pcw.queue_free()
	if !grouped.is_empty():
		changed.emit()
	return grouped

func add_pov() -> void:
	# Add a blank POV entry to the stack.
	load_pov(Pov.new())
