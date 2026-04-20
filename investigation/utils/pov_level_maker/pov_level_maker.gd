class_name _PovLevelMaker extends Control

const POV_DIRECTIONS_WIDGET = preload("uid://cwvn21yf77xpp")
const POV_DIRECTION_LINE = preload("uid://cx2wlsvbs6c56")

@onready var bg: TextureRect = $ScreenContainer/TextureRect
@onready var screen_container: Panel = $ScreenContainer
@onready var load_file_dialog: FileDialog = $LoadFileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var save_sub_resources_file_dialog: FileDialog = $SaveSubResourcesFileDialog
@onready var load_image_file_dialog: FileDialog = $LoadImageFileDialog


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

var dirs : Array[_PovDirectionsWidget] = []
var lines : Array[Line2D] = []
## number of points in a line
@export var line_res : int = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	view_offset = bg.position
	apply_view()
	screen_container.resized.connect(_on_screen_container_resized)
	save_sub_resources_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_sub_resources_file_dialog.filters = PackedStringArray()
	var on_file_selected := Callable(self, "_on_save_sub_resources_file_dialog_file_selected")
	if !save_sub_resources_file_dialog.file_selected.is_connected(on_file_selected):
		save_sub_resources_file_dialog.file_selected.connect(on_file_selected)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass

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
	for pdw in dirs:
		pl.pov_directions_array.append(pdw.parse_pov_directions())
	return pl

func load_pov_level(pl: PovLevel) -> void:
	clear_level()
	bg.texture = pl.bg_img
	for pd in pl.pov_directions_array:
		add_pov_directions(pd.coords)
		await dirs[-1].load_pov_directions(pd)
	await get_tree().process_frame
	update_lines()

func save_pov_level_file(path) -> void:
	var pl := parse_pov_level() 
	ResourceSaver.save(pl, path)

func load_pov_level_file(path) -> void:
	var pl := load(path)
	if pl is PovLevel:
		load_pov_level(pl)

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
	update_lines()

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
		var angle := dir.arrow_widget.rotation
		var arrow_pivot := dir.arrow_widget.size * 0.5
		var arrow_base := dir.position + dir.arrow_widget.position
		if dir.top_pov_name.text: # connect top dot
			for d in _get_dirs_with_name(dir.top_pov_name.text):
				var top_dot_center := dir.arrow_widget.dot_top.position + dir.arrow_widget.dot_top.size * 0.5
				var origin := arrow_base + arrow_pivot + (top_dot_center - arrow_pivot).rotated(angle)
				var destiny := (d.position + 
					d.arrow_widget.position + d.arrow_widget.size/2)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.left_pov_name.text: # connect left dot
			for d in _get_dirs_with_name(dir.left_pov_name.text):
				var left_dot_center := dir.arrow_widget.dot_left.position + dir.arrow_widget.dot_left.size * 0.5
				var origin := arrow_base + arrow_pivot + (left_dot_center - arrow_pivot).rotated(angle)
				var destiny := (d.position + 
					d.arrow_widget.position + d.arrow_widget.size/2)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.bottom_pov_name.text: # connect bottom dot
			for d in _get_dirs_with_name(dir.bottom_pov_name.text):
				var bottom_dot_center := dir.arrow_widget.dot_bottom.position + dir.arrow_widget.dot_bottom.size * 0.5
				var origin := arrow_base + arrow_pivot + (bottom_dot_center - arrow_pivot).rotated(angle)
				var destiny := (d.position + 
					d.arrow_widget.position + d.arrow_widget.size/2)
				for j : float in line_res:
					set_line_point_pos(li, j, origin.lerp(destiny, j/(line_res-1)))
				li += 1
		if dir.right_pov_name.text: # connect right dot
			for d in _get_dirs_with_name(dir.right_pov_name.text):
				var right_dot_center := dir.arrow_widget.dot_right.position + dir.arrow_widget.dot_right.size * 0.5
				var origin := arrow_base + arrow_pivot + (right_dot_center - arrow_pivot).rotated(angle)
				var destiny := (d.position + 
					d.arrow_widget.position + d.arrow_widget.size/2)
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
	# Generated by GitHub Copilot (GPT-5.3-Codex): right-click spawn positioning.
	var pdw : _PovDirectionsWidget = POV_DIRECTIONS_WIDGET.instantiate()
	pdw.anchor_left = 0
	pdw.anchor_top = 0
	pdw.anchor_right = 0
	pdw.anchor_bottom = 0
	pdw.pivot_offset = Vector2(0.5,1)
	pdw.scale = Vector2(current_widget_scale, current_widget_scale)
	pdw.position = coords - Vector2(pdw.size.x/2, pdw.size.y*7/8)
	pdw.coords = coords
	pdw.changed.connect(update_lines)
	pdw.moving.connect(update_lines)
	pdw.closed.connect(dirs.erase.bind(pdw))
	pdw.name = "pdw%d" % id
	bg.add_child(pdw)
	dirs.append(pdw)
	update_lines()
	id += 1

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
	var viewport_size := screen_container.size
	var content_size := bg.size * zoom

	var min_x := viewport_size.x - content_size.x
	var max_x := 0.0
	if content_size.x <= viewport_size.x:
		min_x = (viewport_size.x - content_size.x) * 0.5
		max_x = min_x

	var min_y := viewport_size.y - content_size.y
	var max_y := 0.0
	if content_size.y <= viewport_size.y:
		min_y = (viewport_size.y - content_size.y) * 0.5
		max_y = min_y

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
