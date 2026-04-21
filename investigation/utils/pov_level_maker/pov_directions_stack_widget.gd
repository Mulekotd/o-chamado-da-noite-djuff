class_name _PovDirectionsStackWidget extends Control

@onready var povs_container: VBoxContainer = $Panel/PovsContainer

const POV_IMAGE_WIDGET = preload("uid://boyvv4inx1pxw")

var pov_dir_widget : _PovDirectionsWidget

signal changed
signal clone_requested(clicked_pov: Pov)

func _connect_pov_image_widget(piw: _PovImageWidget) -> void:
	piw.changed.connect(_on_pov_image_widget_changed)
	piw.clone_requested.connect(_on_pov_image_widget_clone_requested)

func _on_pov_image_widget_changed() -> void:
	changed.emit()

func _on_pov_image_widget_clone_requested(clicked_pov: Pov) -> void:
	clone_requested.emit(clicked_pov)

func get_povs() -> Array[Pov]:
	var povs : Array[Pov] = []
	for child in povs_container.get_children():
		if child is _PovImageWidget:
			var piw := child as _PovImageWidget
			var p := piw.get_pov()
			if p != null:
				povs.append(p)
	return povs

func parse_pov_directions_stack() -> Array[PovDirections]:
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
	var piw : _PovImageWidget = POV_IMAGE_WIDGET.instantiate()
	povs_container.add_child(piw)
	_connect_pov_image_widget(piw)
	piw.load_pov(p)

func pop_povs_not_named(name: String) -> Dictionary:
	var target_name := name.strip_edges()
	var grouped := {}
	for child in povs_container.get_children():
		if child is _PovImageWidget:
			var piw := child as _PovImageWidget
			var p := piw.get_pov()
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
			povs_container.remove_child(piw)
			piw.queue_free()
	if !grouped.is_empty():
		changed.emit()
	return grouped

func add_pov() -> void:
	load_pov(Pov.new())
