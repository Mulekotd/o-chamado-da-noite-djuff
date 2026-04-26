class_name _PovLevelMaker extends Control

const POV_DIRECTIONS_WIDGET = preload("uid://cwvn21yf77xpp")
const POV_DIRECTION_LINE = preload("uid://cx2wlsvbs6c56")

@onready var bg: TextureRect = $ScreenContainer/TextureRect
@onready var screen_container: Panel = $ScreenContainer
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var save_sub_resources_file_dialog: FileDialog = $SaveSubResourcesFileDialog
@onready var load_image_file_dialog: FileDialog = $LoadImageFileDialog
@onready var default_pov_name_widget: _PovNameWidget = $ScreenContainer/FooterContainer/PanelContainer/MarginContainer/DefaultPovContainer/DefaultPovNameWidget
@onready var pov_level_name_label: Label = $ScreenContainer/PanelContainer/HeaderContainer/HBoxContainer/PovLevelNameLabel
@onready var not_saved_label: Label = $ScreenContainer/PanelContainer/HeaderContainer/HBoxContainer/NotSavedLabel


var is_panning: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var view_offset: Vector2 = Vector2.ZERO
var zoom: float = 1.0
var last_saved_path: String = ""
@export var zoom_factor : float = 0.04
@export var min_zoom : float = 0.01
@export var max_zoom : float = 4
@export var widget_scale_step : float = 0.08
@export var min_widget_scale : float = 0.25
@export var max_widget_scale : float = 3.0
var current_widget_scale : float = 1.0
var _is_reconciling_dirs : bool = false
var _is_loading_level : bool = false

var dirs : Array[_PovDirectionsWidget] = []
var lines : Array[Line2D] = []
## number of points in a line
@export var line_res : int = 20

## min-x, min-y, max-x, max-y
func _get_panning_content_margins() -> Vector4:
	var content_margins := Vector4(
		0.0,
		0.0,
		bg.size.x,
		bg.size.y,
	)
	var bg_inverse := bg.get_global_transform_with_canvas().affine_inverse()
	for dir in dirs:
		if !is_instance_valid(dir):
			continue
		var dir_transform := dir.get_global_transform_with_canvas()
		var corners : Array[Vector2] = [
			Vector2.ZERO,
			Vector2(dir.size.x, 0.0),
			Vector2(0.0, dir.size.y),
			Vector2(dir.size.x, dir.size.y),
		]
		for corner in corners:
			var local_corner := bg_inverse * (dir_transform * corner)
			content_margins.x = minf(content_margins.x, local_corner.x)
			content_margins.y = minf(content_margins.y, local_corner.y)
			content_margins.z = maxf(content_margins.z, local_corner.x)
			content_margins.w = maxf(content_margins.w, local_corner.y)
	return content_margins
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	view_offset = bg.position
	screen_container.resized.connect(_on_screen_container_resized)
	save_sub_resources_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_sub_resources_file_dialog.filters = PackedStringArray()
	var on_file_selected := Callable(self, "_on_save_sub_resources_file_dialog_file_selected")
	if !save_sub_resources_file_dialog.file_selected.is_connected(on_file_selected):
		save_sub_resources_file_dialog.file_selected.connect(on_file_selected)
	# CHANGES TRIGGER NOT SAVED LABEL
	default_pov_name_widget.changed.connect(_change_saved_indicator.bind(false))
	bg.item_rect_changed.connect(_change_saved_indicator.bind(false))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_lines()
	print("DIRS: ", dirs.size())

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo and event.keycode == KEY_S and event.ctrl_pressed:
		if event.shift_pressed:
			save_file_dialog.popup()
		else:
			if last_saved_path.is_empty():
				save_file_dialog.popup()
			else:
				save_pov_level_file(last_saved_path)
		get_viewport().set_input_as_handled()

#_____________ BACKEND _________________

func parse_pov_level() -> PovLevel:
	var pl := PovLevel.new()
	pl.bg_img = bg.texture
	pl.dir_scale = current_widget_scale
	pl.default_pov = default_pov_name_widget.get_pov_name()
	for pdw in dirs:
		pl.pov_directions_array.append(pdw.parse_pov_directions())
		for stacked_dir in pdw.pov_directions_stack_widget.parse_pov_directions_stack():
			pl.pov_directions_array.append(stacked_dir)
	return pl

func load_pov_level(pl: PovLevel) -> void:
	_is_loading_level = true
	current_widget_scale = pl.dir_scale if pl.dir_scale > 0.0 else 1.0
	clear_level()
	default_pov_name_widget.load_pov_name(pl.default_pov)
	bg.texture = pl.bg_img
	for pd in pl.pov_directions_array:
		add_pov_directions(pd.coords)
		await dirs[-1].load_pov_directions(pd)
	_is_loading_level = false
	await get_tree().process_frame
	_reconcile_dirs_after_change()
	update_lines()

func save_pov_level_file(path) -> void:
	var pl := parse_pov_level() 
	ResourceSaver.save(pl, path)
	pov_level_name_label.text = path.get_file()
	_change_saved_indicator(true)

func load_pov_level_file(path) -> void:
	var pl := load(path)
	if pl is PovLevel:
		load_pov_level(pl)
		pov_level_name_label.text = path.get_file()
		_change_saved_indicator(true)

func _normalize_dir_path(path: String) -> String:
	var normalized := path.replace("\\", "/")
	while normalized.ends_with("/"):
		normalized = normalized.left(normalized.length() - 1)
	return normalized

func _join_path(base: String, child: String) -> String:
	if base.ends_with("/"):
		return base + child
	return base + "/" + child

func _sanitize_file_name(raw: String, fallback: String) -> String:
	var source := raw.strip_edges()
	var out := ""
	for i in range(source.length()):
		var code := source.unicode_at(i)
		if code < 32 or code == 34 or code == 42 or code == 47 or code == 58 or code == 60 or code == 62 or code == 63 or code == 92 or code == 124:
			out += "_"
		elif code == 32:
			out += "_"
		else:
			out += char(code)
	if out.is_empty():
		return fallback
	return out

func _next_counter(counters: Dictionary, key: String) -> int:
	var value := int(counters.get(key, 0))
	counters[key] = value + 1
	return value

func _resource_key(resource: Resource) -> int:
	if resource == null:
		return 0
	return resource.get_instance_id()

func _create_subresource_dirs(root_dir: String) -> Dictionary:
	var dirs := {
		"root": root_dir,
		"prompt_chains": _join_path(root_dir, "prompt_chains"),
		"elements": _join_path(root_dir, "elements"),
		"povs": _join_path(root_dir, "povs"),
		"pov_directions": _join_path(root_dir, "pov_directions")
	}
	DirAccess.make_dir_recursive_absolute(root_dir)
	DirAccess.make_dir_recursive_absolute(dirs["prompt_chains"])
	DirAccess.make_dir_recursive_absolute(dirs["elements"])
	DirAccess.make_dir_recursive_absolute(dirs["povs"])
	DirAccess.make_dir_recursive_absolute(dirs["pov_directions"])
	return dirs

func _save_prompt_chain_subresource(prompt_chain: PromptChain, sub_dirs: Dictionary, caches: Dictionary, counters: Dictionary, name_hint: String) -> PromptChain:
	if prompt_chain == null:
		return null

	var key := _resource_key(prompt_chain)
	var prompt_chain_cache: Dictionary = caches["prompt_chains"]
	if prompt_chain_cache.has(key):
		return prompt_chain_cache[key]

	var idx := _next_counter(counters, "prompt_chain")
	var file_name := "%s_%03d.tres" % [_sanitize_file_name(name_hint, "prompt_chain"), idx]
	var path := _join_path(sub_dirs["prompt_chains"], file_name)
	ResourceSaver.save(prompt_chain, path)
	var saved_prompt_chain := load(path) as PromptChain
	prompt_chain_cache[key] = saved_prompt_chain
	return saved_prompt_chain

func _save_element_subresource(element: Element, sub_dirs: Dictionary, caches: Dictionary, counters: Dictionary, name_hint: String) -> Element:
	if element == null:
		return null

	var key := _resource_key(element)
	var element_cache: Dictionary = caches["elements"]
	if element_cache.has(key):
		return element_cache[key]

	var prompt_chain_name := "%s_prompt_chain" % _sanitize_file_name(element.name, "element")
	var saved_prompt_chain := _save_prompt_chain_subresource(element.prompt_chain, sub_dirs, caches, counters, prompt_chain_name)

	var element_copy := Element.new()
	element_copy.name = element.name
	element_copy.hitbox = element.hitbox.duplicate(true)
	element_copy.pov_name = element.pov_name
	element_copy.prompt_chain = saved_prompt_chain
	element_copy.necessary_items = element.necessary_items.duplicate()
	element_copy.conditions = element.conditions.duplicate(true)

	var idx := _next_counter(counters, "element")
	var file_name := "%s_%03d.tres" % [_sanitize_file_name(name_hint, "element"), idx]
	var path := _join_path(sub_dirs["elements"], file_name)
	ResourceSaver.save(element_copy, path)
	var saved_element := load(path) as Element
	element_cache[key] = saved_element
	return saved_element

func _save_pov_subresource(pov: Pov, sub_dirs: Dictionary, caches: Dictionary, counters: Dictionary, name_hint: String) -> Pov:
	if pov == null:
		return null

	var key := _resource_key(pov)
	var pov_cache: Dictionary = caches["povs"]
	if pov_cache.has(key):
		return pov_cache[key]

	var prompt_chain_name := "%s_prompt_chain" % _sanitize_file_name(pov.name, "pov")
	var saved_prompt_chain := _save_prompt_chain_subresource(pov.prompt_chain, sub_dirs, caches, counters, prompt_chain_name)

	var pov_copy := Pov.new()
	pov_copy.name = pov.name
	pov_copy.description = pov.description
	pov_copy.prompt_chain = saved_prompt_chain
	pov_copy.image = pov.image
	pov_copy.global_conditions = pov.global_conditions.duplicate(true)
	for element in pov.elements:
		var element_name := "%s_element" % _sanitize_file_name(element.name, "element")
		var saved_element := _save_element_subresource(element, sub_dirs, caches, counters, element_name)
		if saved_element:
			pov_copy.elements.append(saved_element)

	var idx := _next_counter(counters, "pov")
	var file_name := "%s_%03d.tres" % [_sanitize_file_name(name_hint, "pov"), idx]
	var path := _join_path(sub_dirs["povs"], file_name)
	ResourceSaver.save(pov_copy, path)
	var saved_pov := load(path) as Pov
	pov_cache[key] = saved_pov
	return saved_pov

func _save_pov_direction_subresource(pov_direction: PovDirections, sub_dirs: Dictionary, caches: Dictionary, counters: Dictionary, name_hint: String) -> PovDirections:
	if pov_direction == null:
		return null

	var saved_pov := _save_pov_subresource(pov_direction.pov, sub_dirs, caches, counters, _sanitize_file_name(name_hint, "pov"))

	var pov_direction_copy := PovDirections.new()
	pov_direction_copy.pov = saved_pov
	pov_direction_copy.left = pov_direction.left
	pov_direction_copy.top = pov_direction.top
	pov_direction_copy.right = pov_direction.right
	pov_direction_copy.bottom = pov_direction.bottom
	pov_direction_copy.rotation = pov_direction.rotation
	pov_direction_copy.coords = pov_direction.coords

	var idx := _next_counter(counters, "pov_direction")
	var file_name := "%s_%03d.tres" % [_sanitize_file_name(name_hint, "pov_direction"), idx]
	var path := _join_path(sub_dirs["pov_directions"], file_name)
	ResourceSaver.save(pov_direction_copy, path)
	return load(path) as PovDirections

func save_pov_level_sub_resources(dir_path: String) -> void:
	var root_dir := _normalize_dir_path(dir_path)
	if root_dir.is_empty():
		return

	var source_level := parse_pov_level()
	var sub_dirs := _create_subresource_dirs(root_dir)
	var caches := {
		"prompt_chains": {},
		"elements": {},
		"povs": {}
	}
	var counters := {
		"prompt_chain": 0,
		"element": 0,
		"pov": 0,
		"pov_direction": 0
	}

	var saved_level := PovLevel.new()
	saved_level.bg_img = source_level.bg_img
	saved_level.dir_scale = source_level.dir_scale
	for i in range(source_level.pov_directions_array.size()):
		var direction := source_level.pov_directions_array[i]
		var pd_name := "pov_direction_%03d" % i
		var saved_direction := _save_pov_direction_subresource(direction, sub_dirs, caches, counters, pd_name)
		if saved_direction:
			saved_level.pov_directions_array.append(saved_direction)

	var level_path := _join_path(root_dir, "pov_level.tres")
	ResourceSaver.save(saved_level, level_path)

func _get_subresources_export_root_from_dialog_path(path: String) -> String:
	var normalized := _normalize_dir_path(path)
	if normalized.is_empty():
		return ""
	var ext := normalized.get_extension().to_lower()
	if ext == "tres" or ext == "res":
		normalized = normalized.get_basename()
	return normalized

#_____________ FRONTEND ________________

func clear_level() -> void:
	for d in dirs:
		if is_instance_valid(d):
			d.queue_free()
	dirs.clear()
	for l in lines:
		if is_instance_valid(l):
			l.queue_free()
	lines.clear()

## amout = [0,1]
func zoom_in(amount: float, focus_pos: Vector2) -> void:
	zoom_by(amount, focus_pos)

## amout = [0,1]
func zoom_out(amount: float, focus_pos: Vector2) -> void:
	zoom_by(-amount, focus_pos)

func zoom_by(amount: float, focus_pos: Vector2) -> void:
	var old_zoom := zoom
	var new_zoom := clampf(old_zoom + amount, min_zoom, max_zoom)
	if is_equal_approx(old_zoom, new_zoom):
		return

	var world_pos := (focus_pos - view_offset) / old_zoom
	zoom = new_zoom
	view_offset = focus_pos - world_pos * new_zoom
	apply_view()

func apply_view() -> void:
	view_offset = _clamp_offset(view_offset)
	bg.scale = Vector2(zoom, zoom)
	bg.position = view_offset

func move_screen(u : Vector2) -> void:
	view_offset += u
	apply_view()

func scale_pov_widgets(delta_scale: float) -> void:
	current_widget_scale = clampf(current_widget_scale + delta_scale, min_widget_scale, max_widget_scale)
	for dir in dirs:
		dir.scale = Vector2(current_widget_scale, current_widget_scale)
		dir.update_position_from_coords()
	update_lines()

func _copy_shared_dir_values(source: _PovDirectionsWidget, target: _PovDirectionsWidget, copy_transform: bool = true) -> void:
	target.top_pov_name_widget.load_pov_name(source.top_pov_name_widget.get_pov_name())
	target.left_pov_name_widget.load_pov_name(source.left_pov_name_widget.get_pov_name())
	target.bottom_pov_name_widget.load_pov_name(source.bottom_pov_name_widget.get_pov_name())
	target.right_pov_name_widget.load_pov_name(source.right_pov_name_widget.get_pov_name())
	target.rotation_slider.set_value_no_signal(source.rotation_slider.value)
	if copy_transform:
		target.coords = source.coords
		target.scale = source.scale
		target.update_position_from_coords()

func _collect_named_dir_groups() -> Dictionary:
	var groups := {}
	for dir in dirs:
		if !is_instance_valid(dir) or dir.pov == null:
			continue
		var name := dir.pov.name.strip_edges()
		if name.is_empty():
			continue
		if !groups.has(name):
			groups[name] = []
		var arr: Array = groups[name]
		arr.append(dir)
		groups[name] = arr
	return groups

func _create_pov_directions_widget(coords: Vector2) -> _PovDirectionsWidget:
	var pdw : _PovDirectionsWidget = POV_DIRECTIONS_WIDGET.instantiate()
	pdw.anchor_left = 0
	pdw.anchor_top = 0
	pdw.anchor_right = 0
	pdw.anchor_bottom = 0
	pdw.pivot_offset = Vector2(0.5,1)
	pdw.scale = Vector2(current_widget_scale, current_widget_scale)
	pdw.coords = coords
	pdw.changed.connect(_on_dir_widget_changed.bind(pdw))
	pdw.moving.connect(_on_dir_widget_moving.bind(pdw))
	pdw.closed.connect(_on_dir_widget_closed.bind(pdw))
	pdw.clone_requested.connect(_on_dir_widget_clone_requested.bind(pdw))
	pdw.name = "pdw%d" % id
	bg.add_child(pdw)
	pdw.position = coords
	pdw.call_deferred("update_position_from_coords")
	pdw.changed.connect(_change_saved_indicator.bind(false))
	dirs.append(pdw)
	id += 1
	return pdw

func _collect_all_pov_names() -> Dictionary:
	var names := {}
	for dir in dirs:
		if !is_instance_valid(dir):
			continue
		if dir.pov != null:
			var base_name := dir.pov.name.strip_edges()
			if !base_name.is_empty():
				names[base_name] = true
		for stacked_pov in dir.pov_directions_stack_widget.get_povs():
			if stacked_pov == null:
				continue
			var stack_name := stacked_pov.name.strip_edges()
			if !stack_name.is_empty():
				names[stack_name] = true
	return names

func _unique_pov_name(base_name: String) -> String:
	var clean_base := base_name.strip_edges()
	if clean_base.is_empty():
		clean_base = "Pov"
	var names := _collect_all_pov_names()
	if !names.has(clean_base):
		return clean_base
	var idx := 2
	while true:
		var candidate := "%s_%d" % [clean_base, idx]
		if !names.has(candidate):
			return candidate
		idx += 1
	return clean_base

func _clone_pov_resource(source: Pov) -> Pov:
	if source == null:
		return Pov.new()
	var dup := source.duplicate(true)
	if dup is Pov:
		return dup as Pov
	return Pov.new()

func _reconcile_dirs_after_change() -> void:
	if _is_reconciling_dirs:
		return
	_is_reconciling_dirs = true

	for di in range(dirs.size() - 1, -1, -1):
		if !is_instance_valid(dirs[di]):
			dirs.remove_at(di)

	var spawn_requests : Array = []
	for source in dirs:
		if !is_instance_valid(source):
			continue
		var base_name := ""
		if source.pov != null:
			base_name = source.pov.name.strip_edges()
		var extracted := source.pov_directions_stack_widget.pop_povs_not_named(base_name)
		for extracted_name in extracted.keys():
			var povs: Array = extracted[extracted_name]
			if povs.is_empty():
				continue
			spawn_requests.append({
				"source": source,
				"offset_index": spawn_requests.size(),
				"base_pov": povs[0],
				"extra_povs": povs.slice(1, povs.size())
			})

	for req in spawn_requests:
		var source := req["source"] as _PovDirectionsWidget
		var base_pov := req["base_pov"] as Pov
		if source == null or !is_instance_valid(source) or base_pov == null:
			continue
		var side_step := (source.size.x * source.scale.x) + 32.0
		var offset_index := int(req["offset_index"]) + 1
		var new_coords := source.coords + Vector2(side_step * offset_index, 0)
		var new_dir := _create_pov_directions_widget(new_coords)
		new_dir.load_pov(base_pov)
		_copy_shared_dir_values(source, new_dir, false)
		new_dir.update_position_from_coords()
		var extra_povs: Array = req["extra_povs"]
		for p in extra_povs:
			if p is Pov:
				new_dir.pov_directions_stack_widget.load_pov(p)

	var groups := _collect_named_dir_groups()
	for group_name in groups.keys():
		var group: Array = groups[group_name]
		if group.size() <= 1:
			continue

		var master := group[0] as _PovDirectionsWidget
		if master == null or !is_instance_valid(master):
			continue

		for gi in range(1, group.size()):
			var follower := group[gi] as _PovDirectionsWidget
			if follower == null or !is_instance_valid(follower):
				continue
			if follower.pov != null:
				master.pov_directions_stack_widget.load_pov(follower.pov)
			for stacked_pov in follower.pov_directions_stack_widget.get_povs():
				master.pov_directions_stack_widget.load_pov(stacked_pov)
			dirs.erase(follower)
			follower.queue_free()

	_is_reconciling_dirs = false

func _on_dir_widget_changed(_dir: _PovDirectionsWidget) -> void:
	if _is_reconciling_dirs or _is_loading_level:
		return
	_reconcile_dirs_after_change()
	update_lines()

func _on_dir_widget_moving(_dir: _PovDirectionsWidget) -> void:
	if _is_reconciling_dirs or _is_loading_level:
		return
	update_lines()

func _on_dir_widget_closed(dir: _PovDirectionsWidget) -> void:
	var previous_reconciling := _is_reconciling_dirs
	_is_reconciling_dirs = true
	if is_instance_valid(dir):
		var stacked_povs := dir.pov_directions_stack_widget.get_povs()
		if !stacked_povs.is_empty():
			var replacement := _create_pov_directions_widget(dir.coords)
			replacement.load_pov(stacked_povs[0])
			_copy_shared_dir_values(dir, replacement)
			for i in range(1, stacked_povs.size()):
				replacement.pov_directions_stack_widget.load_pov(stacked_povs[i])

	dirs.erase(dir)
	_is_reconciling_dirs = previous_reconciling
	if _is_reconciling_dirs or _is_loading_level:
		return
	_reconcile_dirs_after_change()
	update_lines()

func _on_dir_widget_clone_requested(clicked_pov: Pov, dir: _PovDirectionsWidget) -> void:
	if _is_reconciling_dirs or _is_loading_level:
		return
	if dir == null or !is_instance_valid(dir):
		return

	var side_step := (dir.size.x * dir.scale.x) + 48.0
	var clone_coords := dir.coords + Vector2(side_step, 0)
	var clone_dir := _create_pov_directions_widget(clone_coords)
	_copy_shared_dir_values(dir, clone_dir, false)

	var source_pov := clicked_pov
	if source_pov == null:
		source_pov = dir.pov
	clone_dir.load_pov(_clone_pov_resource(source_pov))

	_reconcile_dirs_after_change()
	update_lines()

func _control_local_to_bg(control: Control, local_point: Vector2) -> Vector2:
	var canvas_point := control.get_global_transform_with_canvas() * local_point
	return bg.get_global_transform_with_canvas().affine_inverse() * canvas_point

func update_lines() -> void:
	for di in range(dirs.size() - 1, -1, -1):
		if !is_instance_valid(dirs[di]):
			dirs.remove_at(di)

	# reutilizar linhas, criar so se necessario
	var li : int = 0
	var i : int = 0
	while i < dirs.size():
		if li >= lines.size():
			new_line()
		
		var dir : _PovDirectionsWidget = dirs[i]
		if dir.top_pov_name_widget.get_pov_name(): # connect top dot
			for d in _get_dirs_with_name(dir.top_pov_name_widget.get_pov_name()):
				var top_dot_center := dir.arrow_widget.dot_top.position + dir.arrow_widget.dot_top.size * 0.5
				var origin := _control_local_to_bg(dir.arrow_widget, top_dot_center)
				var destiny := _control_local_to_bg(d.arrow_widget, d.arrow_widget.size * 0.5)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.left_pov_name_widget.get_pov_name(): # connect left dot
			for d in _get_dirs_with_name(dir.left_pov_name_widget.get_pov_name()):
				var left_dot_center := dir.arrow_widget.dot_left.position + dir.arrow_widget.dot_left.size * 0.5
				var origin := _control_local_to_bg(dir.arrow_widget, left_dot_center)
				var destiny := _control_local_to_bg(d.arrow_widget, d.arrow_widget.size * 0.5)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.bottom_pov_name_widget.get_pov_name(): # connect bottom dot
			for d in _get_dirs_with_name(dir.bottom_pov_name_widget.get_pov_name()):
				var bottom_dot_center := dir.arrow_widget.dot_bottom.position + dir.arrow_widget.dot_bottom.size * 0.5
				var origin := _control_local_to_bg(dir.arrow_widget, bottom_dot_center)
				var destiny := _control_local_to_bg(d.arrow_widget, d.arrow_widget.size * 0.5)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.right_pov_name_widget.get_pov_name(): # connect right dot
			for d in _get_dirs_with_name(dir.right_pov_name_widget.get_pov_name()):
				var right_dot_center := dir.arrow_widget.dot_right.position + dir.arrow_widget.dot_right.size * 0.5
				var origin := _control_local_to_bg(dir.arrow_widget, right_dot_center)
				var destiny := _control_local_to_bg(d.arrow_widget, d.arrow_widget.size * 0.5)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		i += 1
	while li < lines.size():
		lines[li].set_point_position(0, Vector2.ZERO)
		shrink_line(lines[li])
		li += 1

## make all points equal to the first
func shrink_line(line: Line2D, points : int = line_res) -> void:
	for i in line_res:
		line.set_point_position(i, line.points[0])

func new_line() -> Line2D:
	var line : Line2D = POV_DIRECTION_LINE.instantiate()
	for i in line_res:
		line.add_point(Vector2.ZERO)
	bg.add_child(line)
	lines.append(line)
	return line

func update_dir_names(index: int) -> void:
	dirs[index].pov_names = get_all_pov_names()

func set_line_point_pos(line_index: int, point_index: int, pos: Vector2) -> void:
	while line_index >= lines.size():
		new_line()
	lines[line_index].set_point_position(point_index, pos)

var id : int = 0
func add_pov_directions(coords : Vector2) -> void:
	_create_pov_directions_widget(coords)
	if _is_loading_level:
		return
	_reconcile_dirs_after_change()
	update_lines()
	_change_saved_indicator(false)

func _change_saved_indicator(saved: bool) -> void:
	not_saved_label.visible = !saved

func screen_to_bg_local(screen_pos: Vector2) -> Vector2:
	# Generated by GitHub Copilot (GPT-5.3-Codex): screen-space to bg-local transform.
	var screen_to_canvas: Transform2D = screen_container.get_global_transform_with_canvas()
	var bg_to_canvas: Transform2D = bg.get_global_transform_with_canvas()
	var canvas_pos: Vector2 = screen_to_canvas * screen_pos
	return bg_to_canvas.affine_inverse() * canvas_pos

func get_all_pov_names() -> Array[String]:
	var names : Array[String] 
	for d : _PovDirectionsWidget in dirs:
		if d.pov.name not in names:
			names.append(d.pov.name)
	return names
	
func _get_dirs_with_name(name: String) -> Array[_PovDirectionsWidget]:
	var arr : Array[_PovDirectionsWidget] = []
	for dir in dirs:
		if dir.pov.name == name:
			arr.append(dir)
	return arr
	
func _clamp_offset(offset: Vector2) -> Vector2:
	var content_margins : Vector4 = _get_panning_content_margins() * zoom
	var top_left := Vector2(content_margins.x, content_margins.y)
	var bottom_right := Vector2(content_margins.z, content_margins.w)
	var min_x := screen_container.size.x - bottom_right.x
	var max_x := -top_left.x
	var min_y := screen_container.size.y - bottom_right.y
	var max_y := -top_left.y

	if min_x > max_x:
		var center_x := (min_x + max_x) * 0.5
		min_x = center_x
		max_x = center_x

	if min_y > max_y:
		var center_y := (min_y + max_y) * 0.5
		min_y = center_y
		max_y = center_y

	return Vector2(
		clampf(offset.x, min_x, max_x),
		clampf(offset.y, min_y, max_y)
	)
	
func _screen_mouse_pos() -> Vector2:
	return screen_container.get_local_mouse_position()

func _on_screen_container_resized() -> void:
	apply_view()

func _on_screen_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and Input.is_action_pressed("ui_scroll_pressed"):
			is_panning = true
			last_mouse_pos = event.position
		elif !event.pressed and is_panning:
			is_panning = false
		
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			add_pov_directions(screen_to_bg_local(event.position))
		
		var ctrl_held := Input.is_physical_key_pressed(KEY_CTRL)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if ctrl_held:
				scale_pov_widgets(widget_scale_step)
			else:
				zoom_in(zoom_factor, event.position)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if ctrl_held:
				scale_pov_widgets(-widget_scale_step)
			else:
				zoom_out(zoom_factor, event.position)

	if event is InputEventMouseMotion and is_panning:
		move_screen(event.position - last_mouse_pos)
		last_mouse_pos = event.position


func _on_save_button_pressed() -> void:
	save_file_dialog.popup()

func _on_save_sub_resources_button_pressed() -> void:
	if !last_saved_path.is_empty():
		save_sub_resources_file_dialog.current_dir = last_saved_path.get_base_dir()
	save_sub_resources_file_dialog.current_file = "pov_level_export"
	save_sub_resources_file_dialog.popup()

func _on_load_button_pressed() -> void:
	load_file_dialog.popup()

func _on_load_file_dialog_file_selected(path: String) -> void:
	load_pov_level_file(path)

func _on_save_file_dialog_file_selected(path: String) -> void:
	last_saved_path = path
	save_pov_level_file(path)

func _on_save_sub_resources_file_dialog_dir_selected(dir: String) -> void:
	var folder_name := _sanitize_file_name(save_sub_resources_file_dialog.current_file, "pov_level_export")
	var root_dir := _join_path(_normalize_dir_path(dir), folder_name)
	save_pov_level_sub_resources(root_dir)

func _on_save_sub_resources_file_dialog_file_selected(path: String) -> void:
	var root_dir := _get_subresources_export_root_from_dialog_path(path)
	save_pov_level_sub_resources(root_dir)

func _on_load_image_button_pressed() -> void:
	load_image_file_dialog.popup()

func _on_image_load_file_dialog_file_selected(path: String) -> void:
	var img := Image.load_from_file(path)
	bg.texture = ImageTexture.create_from_image(img)
